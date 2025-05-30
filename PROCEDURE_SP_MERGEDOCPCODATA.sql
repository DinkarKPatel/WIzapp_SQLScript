CREATE PROCEDURE SP_MERGEDOCPCODATA
(
	@CXNID VARCHAR(50)
)
--WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		
		DECLARE @CERRORMSG VARCHAR(1000),@CCURDEPTID CHAR(2),@CHODEPTID CHAR(2),@CCMD NVARCHAR(MAX),
				@CXNMASTERTABLENAME VARCHAR(100),@BPROCEED BIT,@CTABLENAME VARCHAR(100),@CMASTERKEYFIELD VARCHAR(100),
				@CKEYFIELD VARCHAR(100),@CPARENTTABLENAME VARCHAR(100),@CPARENTPARANAME VARCHAR(100),@CCHILDPARANAME VARCHAR(100),
				@CWHERECLAUSE VARCHAR(100),@CJOINSTR VARCHAR(1000),@CMEMOID VARCHAR(100),@CFINYEAR VARCHAR(100),
				@NGRPCHARS INT,@NSERIESCHARS INT,@BSERIESBROKEN BIT,@CPREVMEMOID VARCHAR(40),@CMERGETABLENAME VARCHAR(50),
				@CFIRSTMEMOID VARCHAR(40),@NPREVMEMOID INT,@NMEMONOLEN INT,@CRETCMD NVARCHAR(MAX),
				@CDELCHILDTABLENAME VARCHAR(100),@CDELCHILDPARANAME VARCHAR(100),@CDELPARENTPARANAME VARCHAR(100),
				@CORIGINALTABLENAME VARCHAR(100),@NLOCTYPE INT,@BDONOTMERGE BIT,@CRFXNTYPE VARCHAR(10),
				@BINSERTONLY BIT,@BLINKEDMASTER BIT,@BPURLOC BIT,@CSOURCELOCID CHAR(2),@BSOURCEPURLOC BIT,
				@CMISSINGMEMOID VARCHAR(40),@CGRPCODE VARCHAR(20),@BRETVAL BIT,@NPREVNO INT,@CPREVNO VARCHAR(20),
				@BEMPHEADSUPDATED BIT,@CFILTERCONDITION VARCHAR(100),@CTABLEPREFIX VARCHAR(100),@CXNTYPE VARCHAR(10),
				@NXNSMERGINGORDER INT,@NSTEP INT,@CUNQCOLUMNNAME1 VARCHAR(100),@CUNQCOLUMNNAME2 VARCHAR(100),
				@CKEYFIELD2 VARCHAR(100),@CSOURCETEMPTABLE VARCHAR(100),@CKEYFIELD3 VARCHAR(100)
		
		SET @NSTEP=10
		
		DECLARE @TRETMSG TABLE(MEMO_ID VARCHAR(40),ERRMSG VARCHAR(MAX))
		
		SELECT @CCURDEPTID=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'
		
		BEGIN TRANSACTION
		
		SET @CCMD=N'IF OBJECT_ID(''TMP_DOCPCO_PCI_MST_'+LTRIM(RTRIM(@CXNID))+''',''U'') IS NULL
					SET @BPROCEEDOUT=0'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD,N'@BPROCEEDOUT BIT OUTPUT',@BPROCEEDOUT=@BPROCEED OUTPUT
		
		IF @BPROCEED=0
		BEGIN	
			SET @CERRORMSG='NO DATA FOUND TO BE MERGED FOR PETTY CASH EXPENSE.'
			GOTO LBLLAST
		END	
		
		SET @CCMD=N'IF NOT EXISTS(SELECT TOP 1 MEMO_ID FROM TMP_DOCPCO_PCI_MST_'+LTRIM(RTRIM(@CXNID))+'
								  WHERE SUBSTRING(MEMO_NO,3,2) ='''+@CCURDEPTID+''')
					SET @BPROCEEDOUT=0'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD,N'@BPROCEEDOUT BIT OUTPUT',@BPROCEEDOUT=@BPROCEED OUTPUT
		
		IF @BPROCEED=0
		BEGIN	
			SET @CERRORMSG='NO DATA FOUND TO BE MERGED FOR PETTY CASH EXPENSE FOR THIS LOCATION.'
			GOTO LBLLAST
		END	
			
		SELECT @CERRORMSG='',@BPROCEED=1,@NMEMONOLEN=10,@CRETCMD='',@CMEMOID='',@CXNTYPE='DOCPCO',@BEMPHEADSUPDATED=0
		
		SET @CTABLEPREFIX='TMP_DOCPCO'
		
		SET @NSTEP=20
		
		SET @CFILTERCONDITION=''

		SELECT @NLOCTYPE=LOC_TYPE,@BPURLOC=PUR_LOC FROM LOCATION (NOLOCK) WHERE DEPT_ID=@CCURDEPTID
		
		SET @CMEMOID='TMP_DOCPCO'
	
	LBLMERGEBEFORE:
		--- DELETING ENTRIES FROM TEMP TABLE WHICH ARE NOT RELEVANT FOR CURRENT LOCATION
		SET @NSTEP=30		
		SET @CCMD=N'DELETE FROM TMP_DOCPCO_PCI_MST_'+LTRIM(RTRIM(@CXNID))+' WHERE SUBSTRING(MEMO_NO,3,2)<>'''+@CCURDEPTID+''''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP=40		
		---ALREADY RECEIVED PETTY CASH SHOULD NOT BE SHOWN IN GIT..
		SET @CCMD=N'UPDATE A SET RECEIPT_DT=B.RECEIPT_DT FROM TMP_DOCPCO_PCI_MST_'+LTRIM(RTRIM(@CXNID))+' A JOIN PCI_MST B ON A.MEMO_ID=B.MEMO_ID'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP=45		
		---ALREADY RECEIVED PETTY CASH SHOULD NOT BE SHOWN IN GIT..
		SET @CCMD=N'UPDATE A SET REFLIFTID=NULL,SHIFT_ID=NULL FROM TMP_DOCPCO_PCI_MST_'+LTRIM(RTRIM(@CXNID))+' A'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
	LBLMERGE:
		
		SET @NSTEP=70
		
		IF CURSOR_STATUS('GLOBAL','MERGECUR') IN (0,1)  
		BEGIN  
		   CLOSE MERGECUR  
		   DEALLOCATE MERGECUR  
		END  
		
		--- NOW, UPDATE TRANSACTIONS DATA ONE BY ONE
		DECLARE MERGECUR CURSOR FOR 
		SELECT  DISTINCT TABLENAME, KEYFIELD,LINKED_MASTER,XNS_MERGING_ORDER 
		FROM XNSINFO (NOLOCK) 
		WHERE XN_TYPE = @CXNTYPE 
		AND   XNS_MERGING_ORDER <> 99 
		ORDER BY XNS_MERGING_ORDER
		
		OPEN MERGECUR
		FETCH NEXT FROM MERGECUR INTO @CTABLENAME,@CKEYFIELD,@BLINKEDMASTER,@NXNSMERGINGORDER		
		WHILE @@FETCH_STATUS=0
		BEGIN
			
			SET @CTABLENAME=(CASE WHEN @CTABLENAME='PCO_MST' THEN 'PCI_MST' ELSE @CTABLENAME END)
			
			SET @NSTEP=80	
			
			LBLSTARTMERGE:
			SET @BPROCEED=1
			
			SET @CCMD=N'IF NOT EXISTS (SELECT NAME FROM SYSOBJECTS WHERE NAME=''TMP_' + @CXNTYPE + '_' + @CTABLENAME + '_' + LTRIM(RTRIM(@CXNID))+''')
							SET @BPROCEEDOUT=0'
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD,N'@BPROCEEDOUT BIT OUTPUT',@BPROCEEDOUT=@BPROCEED OUTPUT
			
			SET @NSTEP=90
			
			IF @BPROCEED=0
				GOTO LBLMERGENEXT
		
			SET @BINSERTONLY=0
			
			SET @NSTEP=100		
			
				SELECT @CKEYFIELD2='',@CKEYFIELD3='',@BINSERTONLY=0
			
			SET @CSOURCETEMPTABLE=@CTABLEPREFIX+'_'+ @CTABLENAME + '_' + LTRIM(RTRIM(@CXNID))
			
			EXEC UPDATEMASTERXN_MERGING
			@CSOURCEDB='',
			@CSOURCETABLE=@CSOURCETEMPTABLE,
			@CDESTDB='',
			@CDESTTABLE=@CTABLENAME,
			@CKEYFIELD1=@CKEYFIELD,
			@CKEYFIELD2=@CKEYFIELD2,
			@CKEYFIELD3=@CKEYFIELD3,
			@LINSERTONLY=@BINSERTONLY,
			@LUPDATEONLY=0,
			@BALWAYSUPDATE=1,
			@CFILTERCONDITION='',
			@CERRORMSG = @CERRORMSG OUTPUT 
					
			IF @CERRORMSG<>''
				BREAK
			
			SET @NSTEP=80
			
			LBLMERGENEXT:
			
			FETCH NEXT FROM MERGECUR INTO @CTABLENAME,@CKEYFIELD,@BLINKEDMASTER,@NXNSMERGINGORDER		
		END
		CLOSE MERGECUR
		DEALLOCATE MERGECUR
			
		SET @NSTEP=90
		
		-- DELETING FROM TEMP TABLES
		
		EXEC SP_DROPTEMPTABLES_XNS @CXNTYPE,0,@CXNID,'TMP_DOCPCO'
		
		SET @CRETCMD='SELECT '''+@CMEMOID+''' AS MEMO_ID,'''+@CERRORMSG+''' AS ERRMSG'	
		
	LBLLAST:
		
		SET @NSTEP=100
		
		--- ON SUCCESSFUL MERGING , DELETE ENTRY FROM XN HISTORY 		
		IF @CERRORMSG=''
		BEGIN
			IF @@TRANCOUNT>0
			BEGIN
				PRINT 'SUCCESS'
				COMMIT TRANSACTION
			END	
		END
		ELSE
		BEGIN
			IF @@TRANCOUNT>0
				ROLLBACK 	
		END	
		
		SET @NSTEP=110
		
		INSERT @TRETMSG
		SELECT 'DOCPCO',@CERRORMSG
		
		SELECT * FROM @TRETMSG
		
		
	END TRY
	BEGIN CATCH
		
		PRINT 'UNTRAPPED ERROR'		
		SELECT @CERRORMSG='PROCEDURE : '+ISNULL(ERROR_PROCEDURE(),'SP_MERGEDOCPCODATA')+'STEP: '+STR(@NSTEP)+' LINE NO. :'+
		ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE')+'MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')
		
		SET @CRETCMD='SELECT '''' AS MEMO_ID,'''''+@CERRORMSG+''''' AS ERRMSG'
		
		PRINT 'RETURN VALUE : '+ISNULL(@CRETCMD,'NULL RETCMD')+@CMEMOID
		--EXEC SP_EXECUTESQL @CRETCMD
		
		INSERT @TRETMSG
		SELECT 'DOCPCO',@CERRORMSG
		
		SELECT * FROM @TRETMSG
		
		
		IF @@TRANCOUNT>0
			ROLLBACK		

		IF CURSOR_STATUS('GLOBAL','MERGECUR') IN (0,1)
		BEGIN
			CLOSE MERGECUR
			DEALLOCATE MERGECUR
		END
		
		EXEC SP_DROPTEMPTABLES_XNS @CXNTYPE,0,@CXNID,'TMP_DOCPCO'	
	END CATCH
END
--- END OF CREATING PROCEDURE SP_MERGEDOCPCODATA
