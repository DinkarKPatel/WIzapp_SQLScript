CREATE PROCEDURE SP_CREATEXNRECONDATA
@CTARGETPATH VARCHAR(MAX),
@NMODE INT=1,
@DLASTRUNDT DATETIME=''
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CTARGETDB VARCHAR(200),@CCURLOCID VARCHAR(5),@CHOLOCID VARCHAR(5),@BPROCEED BIT,@CKEYFIELD VARCHAR(200),
			@CCMD NVARCHAR(MAX),@NSTEP INT,@CDISTINCTSTR VARCHAR(50),@CTEMPTABLENAME VARCHAR(200),@CCHILDPARANAME VARCHAR(200),
			@CTARGETTABLENAME VARCHAR(200),@CSENDTABLENAME VARCHAR(200),@CSENDTEMPTABLENAME VARCHAR(500),@CERRORMSG VARCHAR(MAX),
			@CPARENTTABLENAME VARCHAR(200),@CPARENTPARANAME VARCHAR(200),@CWHERECLAUSE VARCHAR(200),@CMEMODTCOL VARCHAR(100),
			@CJOINSTR VARCHAR(MAX),@BFIRST BIT,@CTABLENAME VARCHAR(200),@CSENDCOLS VARCHAR(2000),@CXNTYPE VARCHAR(10),
			@CMASTERTABLENAME VARCHAR(200),@CADDWHERECLAUSE VARCHAR(1000),@CCMDSTR VARCHAR(MAX),@CSEARCHSTR VARCHAR(MAX),
			@CREPLACESTR VARCHAR(MAX),@CTARGETDBNAME VARCHAR(100),@CBACKUPFILE VARCHAR(MAX),@CFILEPATH VARCHAR(500),
			@CMASTERTABLEKEYFIELD VARCHAR(200),@CSENDMASTERTABLE VARCHAR(300),@CSENDXNTYPE VARCHAR(10),@DLASTXNDT DATETIME,
			@DLASTXNDTPARA DATETIME,@NRECCOUNT INT

	
	SELECT TOP 1 @CCURLOCID=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'
	SELECT TOP 1 @CHOLOCID=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'
	
	IF @CCURLOCID=@CHOLOCID
		GOTO END_PROC

	SET @CTARGETDBNAME='WIZAPP3S_RECON_'+@CCURLOCID+@CHOLOCID					
	SET @CTARGETDB=@CTARGETDBNAME+'.DBO.'
			
	SET @BPROCEED=0
	
	BEGIN TRY
	
		IF @NMODE=2
			GOTO LBLACK

		IF @NMODE=3
			GOTO LBLRESEND
			
		IF EXISTS (SELECT TOP 1 DEPT_ID FROM XNRECON_LOG (NOLOCK) WHERE SENT_ID=RECON_ID AND DEPT_ID=@CCURLOCID)
			OR NOT EXISTS (SELECT TOP 1 DEPT_ID FROM XNRECON_LOG (NOLOCK) WHERE  DEPT_ID=@CCURLOCID)
			SET @BPROCEED=1
		
		IF @BPROCEED=0
		BEGIN
			IF EXISTS (SELECT TOP 1 DEPT_ID FROM XNRECON_LOG (NOLOCK) WHERE DEPT_ID=@CCURLOCID AND ISNULL(SENT_STATUS,0)=0)
				GOTO LBLRESEND
				
			GOTO END_PROC
		END
				
		DECLARE @TRETMSG TABLE  (TABLENAME VARCHAR(200),CMDSTR VARCHAR(1000),TARGETTABLENAME VARCHAR(500),
								 ERRMSG VARCHAR(MAX))		

			
		DECLARE @TCMD TABLE  (TABLENAME VARCHAR(200),CMDSTR VARCHAR(MAX))
		
	
		SET @NSTEP=10
		
		
		IF CURSOR_STATUS('GLOBAL','DTRCUR') IN (0,1)
		BEGIN
			CLOSE DTRCUR
			DEALLOCATE DTRCUR
		END
		
		SET @DLASTXNDT=''
		DECLARE DTRCUR CURSOR FOR  SELECT XN_TYPE,TABLENAME,MEMODTCOL FROM RECONMSTTABLEINFO
		OPEN DTRCUR
				
		FETCH NEXT FROM DTRCUR INTO @CXNTYPE,@CTABLENAME,@CMEMODTCOL
		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @NSTEP=15	
			SELECT @DLASTXNDTPARA='',@CWHERECLAUSE='',@CMASTERTABLEKEYFIELD=''
			
			SELECT TOP 1 @CMASTERTABLEKEYFIELD=KEYFIELD,@CWHERECLAUSE=WHERECLAUSE FROM XNSINFO (NOLOCK) 
			WHERE TABLENAME=@CTABLENAME AND XN_TYPE=@CXNTYPE
			
			SET @CWHERECLAUSE=ISNULL(@CWHERECLAUSE,'')
			
		    SET @CADDWHERECLAUSE=@CWHERECLAUSE+(CASE WHEN @CWHERECLAUSE<>'' THEN ' AND ' ELSE '' END)+
								' LEFT('+@CTABLENAME+'.'+@CMASTERTABLEKEYFIELD+',2)'+
								' IN (SELECT DEPT_ID FROM LOCATION WHERE MAJOR_DEPT_ID='''+@CCURLOCID+''')'+
							   (CASE WHEN @CXNTYPE='XNSPUR' THEN ' AND (PIM01106.RECEIPT_DT<>'''')'
									 WHEN @CXNTYPE='XNSPO' THEN ' AND POM01106.APPROVED=1 '
									 ELSE '' END) 			
			SET @CCMD=N'SELECT TOP 1 @DLASTXNDTPARA='+@CMEMODTCOL+' FROM '+@CTABLENAME+'
						WHERE '+@CMEMODTCOL+' BETWEEN ''2012-04-01'' AND '''+CONVERT(VARCHAR,@DLASTRUNDT,110)+''' AND
						ISNULL(SENT_FOR_RECON,0)=0 AND '+@CADDWHERECLAUSE+
						' ORDER BY '+@CMEMODTCOL
			PRINT @CCMD					
			EXEC SP_EXECUTESQL @CCMD,N'@DLASTXNDTPARA DATETIME OUTPUT',@DLASTXNDTPARA OUTPUT
			
			SET @NSTEP=20	
			SET @DLASTXNDTPARA=ISNULL(@DLASTXNDTPARA,'')
			
			IF @DLASTXNDTPARA<>'' AND (@DLASTXNDTPARA<@DLASTXNDT OR @DLASTXNDT='')
			BEGIN
				SET @DLASTXNDT=@DLASTXNDTPARA
			END
				
			FETCH NEXT FROM DTRCUR INTO @CXNTYPE,@CTABLENAME,@CMEMODTCOL
		END
		
		CLOSE DTRCUR
		DEALLOCATE DTRCUR		
		
		IF @DLASTXNDT=''
			GOTO END_PROC


		IF EXISTS (SELECT TOP 1 NAME FROM SYS.DATABASES (NOLOCK) WHERE NAME=@CTARGETDBNAME)
		BEGIN
			SET @NSTEP=22
			EXEC KILLCONNECTIONSTODB @CTARGETDBNAME
			
			SET @NSTEP=25
			SET @CCMD=N'DROP DATABASE '+@CTARGETDBNAME
			EXEC SP_EXECUTESQL @CCMD 
		END	
		
		DECLARE @CDBNAME VARCHAR(100)
		SET @CDBNAME=DB_NAME()

		
		SET @NSTEP=30	

		SELECT @CFILEPATH=PHYSICAL_NAME FROM SYS.MASTER_FILES WHERE DATABASE_ID=DB_ID(@CDBNAME) AND TYPE_DESC='ROWS'
		SET @CFILEPATH=REVERSE(RIGHT(REVERSE(@CFILEPATH),(LEN(@CFILEPATH)-CHARINDEX('\',REVERSE(@CFILEPATH),1))+1))
		
		SET @NSTEP=35
		
		SET @CCMD=N' CREATE DATABASE ' + @CTARGETDBNAME + ' ON '+
		' ( NAME = ' + @CTARGETDBNAME + ', ' + 
		'  FILENAME = ''' + @CFILEPATH + '\' + @CTARGETDBNAME + '.MDF'' ) ' + 
		' LOG ON ' + 
		' ( NAME = ' + @CTARGETDBNAME + '_LOG, ' + 
		'  FILENAME = ''' + @CFILEPATH + '\' + @CTARGETDBNAME + '_LOG.LDF'' )'

		PRINT @CCMD

		EXEC SP_EXECUTESQL @CCMD
			
		DECLARE DTRCUR CURSOR FOR   
		SELECT A.TABLENAME, KEYFIELD, PARENT_TABLENAME, PARENT_PARA_NAME,  
		CHILD_PARA_NAME,TEMP_TABLE_NAME,B.MEMODTCOL,A.XN_TYPE,B.TABLENAME,WHERECLAUSE
		FROM XNSINFO A JOIN RECONMSTTABLEINFO B ON A.XN_TYPE=B.XN_TYPE
		ORDER BY A.XN_TYPE,XNS_SENDING_ORDER,B.TABLENAME  
		
		SET @NSTEP=40	 
		PRINT 'START SEND-1'  
		
				
		OPEN DTRCUR  
		FETCH NEXT FROM DTRCUR INTO @CTABLENAME, @CKEYFIELD, @CPARENTTABLENAME, @CPARENTPARANAME, @CCHILDPARANAME,
									@CTEMPTABLENAME,@CMEMODTCOL,@CXNTYPE,@CMASTERTABLENAME,@CWHERECLAUSE
		WHILE @@FETCH_STATUS=0  
		BEGIN  
			  PRINT 'DROPPING TABLE...' + @CTABLENAME  
			  
			  SET @NSTEP=50	  
			  PRINT 'CHECK SENDING :'+@CXNTYPE+'-'+@CTABLENAME+'-'+@CTEMPTABLENAME+'-'+@CPARENTTABLENAME  
			   
			  SET @CTEMPTABLENAME=ISNULL(@CTEMPTABLENAME,'')
			  
			  SELECT TOP 1 @CMASTERTABLEKEYFIELD=KEYFIELD FROM XNSINFO (NOLOCK) WHERE XN_TYPE=@CXNTYPE
			  AND TABLENAME=@CMASTERTABLENAME
			  
			  --PRINT ISNULL(@CJOINSTR,'NULL JOINSTR')  
			  SET @CTARGETTABLENAME = (CASE WHEN ISNULL(@CTEMPTABLENAME,'')='' THEN @CTABLENAME ELSE @CTEMPTABLENAME END)
			  			  
	  		 
			    
			  SELECT @CSENDTABLENAME=@CTABLENAME,@CSENDTEMPTABLENAME=@CTEMPTABLENAME,@BFIRST=1 ,@CCMD='',
					 @CSENDMASTERTABLE=@CMASTERTABLENAME,@CSENDXNTYPE=@CXNTYPE 
			  
			  SET @NSTEP=60	  
			  
			  WHILE @@FETCH_STATUS=0 AND @CTABLENAME=@CSENDTABLENAME  AND @CMASTERTABLENAME=@CSENDMASTERTABLE
			  AND @CXNTYPE=@CSENDXNTYPE
			  
			  BEGIN  
				   
				   SET @NSTEP=70	 	
				   
				   SET @CJOINSTR = ''
				   SELECT @CJOINSTR = DBO.FN_CREATEALLXNSJOINSTR(@CXNTYPE,@CTABLENAME,@CPARENTTABLENAME,@CPARENTPARANAME,'',@CWHERECLAUSE,'')
				   			   

				   SET @CJOINSTR = ISNULL(@CJOINSTR,'')  
				     
				   PRINT '@CJOINSTR ' + @CJOINSTR  
				   SET @CSENDCOLS = @CTABLENAME+'.*'  
				   
				   SET @NSTEP=80	   
				   IF @CXNTYPE='XNSATD'  
						SET @CDISTINCTSTR=''  
				   ELSE  
						SET @CDISTINCTSTR=' DISTINCT '  
				   
				   
				   SET @CWHERECLAUSE=ISNULL(@CWHERECLAUSE,'')
				   
								
	   			   SET @CADDWHERECLAUSE=(CASE WHEN RIGHT(@CJOINSTR,4)='TMP_' THEN '' 
	   			   ELSE ((CASE WHEN  @CWHERECLAUSE='' AND CHARINDEX('WHERE',@CJOINSTR)=0 THEN ' WHERE ' ELSE  ' AND ' END)+
	   			   'ISNULL('+@CMASTERTABLENAME+'.SENT_FOR_RECON,0)=0 AND CONVERT(VARCHAR,'+@CMASTERTABLENAME+'.'+@CMEMODTCOL+',110)='''+CONVERT(VARCHAR,@DLASTXNDT,110)+'''') END) 
					
				   IF RIGHT(@CJOINSTR,4)<>'TMP_'	
					   SET @CADDWHERECLAUSE=@CADDWHERECLAUSE+(CASE WHEN @CADDWHERECLAUSE='' THEN ' WHERE ' ELSE ' AND ' END)+
											(CASE WHEN @CXNTYPE='XNSCHI' THEN 'SUBSTRING(RIGHT('+@CMASTERTABLENAME+'.CHALLAN_ID,10),3,2)'
												 ELSE 'LEFT('+@CMASTERTABLENAME+'.'+@CMASTERTABLEKEYFIELD+',2)' END)+
											' IN (SELECT DEPT_ID FROM LOCATION WHERE MAJOR_DEPT_ID='''+@CCURLOCID+''')'+
										   (CASE WHEN @CXNTYPE='XNSPUR' THEN ' AND (PIM01106.RECEIPT_DT<>'''')'
												 WHEN @CXNTYPE='XNSPO' THEN ' AND POM01106.APPROVED=1 '
												 ELSE '' END) 	
	   			   
	   			   SET @CJOINSTR=(CASE WHEN RIGHT(@CJOINSTR,4)='TMP_' THEN SUBSTRING(@CJOINSTR,1,LEN(@CJOINSTR)-4) ELSE @CJOINSTR END)
	   			   
				   IF NOT EXISTS (SELECT TOP 1 TABLENAME FROM @TCMD WHERE TABLENAME=@CSENDTABLENAME)
					   AND @BFIRST=1
					   SET @CCMD = 'SELECT '+@CDISTINCTSTR+@CSENDCOLS+' INTO '+@CTARGETDB+@CTARGETTABLENAME+  
									' FROM ' + @CTABLENAME + @CJOINSTR +@CADDWHERECLAUSE
				   ELSE
					   SET @CCMD = @CCMD + ' UNION ' + CHAR(13) + 'SELECT '+@CDISTINCTSTR+ @CTABLENAME + '.* FROM ' + 
					   @CTABLENAME + @CJOINSTR+@CADDWHERECLAUSE
				           
				   
				   SET @BFIRST=0		    
									  
				   LBLNEXTTABLE:  
				   
				   SET @NSTEP=90
				     
				   FETCH NEXT FROM DTRCUR INTO @CTABLENAME, @CKEYFIELD, @CPARENTTABLENAME, @CPARENTPARANAME,
				   @CCHILDPARANAME,  @CTEMPTABLENAME ,@CMEMODTCOL,@CXNTYPE,@CMASTERTABLENAME,@CWHERECLAUSE
			   
			  END  
			  
			  SET @NSTEP=100
			  
			  IF NOT EXISTS (SELECT TOP 1 TABLENAME FROM @TCMD WHERE TABLENAME=@CTARGETTABLENAME)
				  INSERT @TCMD (TABLENAME,CMDSTR)
				  SELECT @CTARGETTABLENAME,@CCMD
			  ELSE
				  UPDATE @TCMD SET CMDSTR=CMDSTR+' '+@CCMD
				  WHERE  TABLENAME=@CTARGETTABLENAME 
			  
			  
			    
		END	  

			  
	    SET @NSTEP=110
				  
	    CLOSE DTRCUR
	    DEALLOCATE DTRCUR		
		
		IF CURSOR_STATUS('GLOBAL','CMDCUR') IN (0,1)
		BEGIN
			CLOSE CMDCUR
			DEALLOCATE CMDCUR
		END

		BEGIN TRANSACTION
				
		SET @NSTEP=120
		
		DECLARE @TTEMPTABLES TABLE (TABLENAME VARCHAR(200))
						
		DECLARE CMDCUR CURSOR FOR SELECT A.TABLENAME,CMDSTR FROM @TCMD A
		JOIN XNSINFO C ON C.PARENT_TABLENAME='TMP_'+A.TABLENAME
		ORDER BY XNS_SENDING_ORDER
				
		OPEN CMDCUR
		FETCH NEXT FROM CMDCUR INTO @CTABLENAME,@CCMDSTR
		WHILE @@FETCH_STATUS=0
		BEGIN
			PRINT 'CREATING DATA FOR TEMP TABLE :'+@CTABLENAME
			
			SET @NSTEP=130	
			IF EXISTS (SELECT TOP 1 TABLENAME FROM @TTEMPTABLES WHERE TABLENAME=@CTABLENAME)
				GOTO LBLNEXT
				
			INSERT INTO @TTEMPTABLES
			SELECT @CTABLENAME
			
			SET @CTEMPTABLENAME='TMP_'+@CTABLENAME+'_'+LTRIM(RTRIM(STR(@@SPID))) 				
			
			IF OBJECT_ID(@CTEMPTABLENAME,'U') IS NOT NULL
			BEGIN
				SET @NSTEP=140
				SET @CCMD=N'DROP TABLE '+@CTEMPTABLENAME
				EXEC SP_EXECUTESQL @CCMD
			END
			
			SET @NSTEP=145
			
			SELECT @CSEARCHSTR='INTO '+@CTARGETDB+@CTABLENAME,
				   @CREPLACESTR='INTO '+@CTEMPTABLENAME
			
			SET @CCMD=REPLACE(@CCMDSTR,@CSEARCHSTR,@CREPLACESTR)
			
			SET @CCMD=REPLACE(@CCMD,'EMPLOYEE_HEAD','EMPLOYEE')
			
			PRINT ISNULL(@CCMD,'NULL TEMPCMD')
			EXEC SP_EXECUTESQL @CCMD  			
			
			LBLNEXT:
			
			FETCH NEXT FROM CMDCUR INTO @CTABLENAME,@CCMDSTR
		END
		
		CLOSE CMDCUR
		DEALLOCATE CMDCUR
		

		SET @NSTEP=148
		SET @CCMD=N'CREATE TABLE '+@CTARGETDB+'RECONXNSINFO (TABLENAME VARCHAR(200) NOT NULL,RECCOUNT INT NOT NULL)'
		EXEC SP_EXECUTESQL @CCMD

		DECLARE CMDCUR CURSOR FOR SELECT TABLENAME,CMDSTR FROM @TCMD
		OPEN CMDCUR
		FETCH NEXT FROM CMDCUR INTO @CTABLENAME,@CCMD
		WHILE @@FETCH_STATUS=0
		BEGIN
			PRINT 'CREATING DATA FOR TABLE :'+@CTABLENAME
			SET @NSTEP=150

			
			SET @CCMD=REPLACE(@CCMD,'EMPLOYEE_HEAD','EMPLOYEE')
						
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD  			
			
			SET @CCMD=N'IF EXISTS (SELECT TOP 1 * FROM '+@CTARGETDB+@CTABLENAME+')
							SELECT @NRECCOUNT=COUNT(*) FROM '+@CTARGETDB+@CTABLENAME+'
						ELSE
							SET @NRECCOUNT=0'
			EXEC SP_EXECUTESQL @CCMD,N'@NRECCOUNT INT OUTPUT',@NRECCOUNT OUTPUT
			
			SET @NSTEP=152
			SET @CCMD=N'INSERT '+@CTARGETDB+'RECONXNSINFO (TABLENAME,RECCOUNT)
						SELECT '''+@CTABLENAME+''','+LTRIM(RTRIM(STR(@NRECCOUNT)))
			EXEC SP_EXECUTESQL @CCMD			

							
			SET @NSTEP=155
			SET @CCMD=N'ALTER TABLE '+@CTARGETDB+@CTABLENAME+' ADD RECON_NEWID INT IDENTITY'
			PRINT @CCMD		   
			EXEC SP_EXECUTESQL @CCMD

									
			FETCH NEXT FROM CMDCUR INTO @CTABLENAME,@CCMD
		END
		
		CLOSE CMDCUR
		DEALLOCATE CMDCUR
		
		SET @NSTEP=160

		DECLARE CMDCUR CURSOR FOR SELECT TABLENAME,XN_TYPE FROM RECONMSTTABLEINFO
		OPEN CMDCUR
		FETCH NEXT FROM CMDCUR INTO @CTABLENAME,@CXNTYPE
		WHILE @@FETCH_STATUS=0
		BEGIN
			PRINT 'UPDATING SENT FOR RECON COLUMN FOR TABLE :'+@CTABLENAME
			SET @NSTEP=170
			
			SET @CTARGETTABLENAME=@CTARGETDB+@CTABLENAME
			
			SELECT TOP 1 @CKEYFIELD=KEYFIELD FROM XNSINFO (NOLOCK) WHERE XN_TYPE=@CXNTYPE AND TABLENAME=@CTABLENAME
			
			IF OBJECT_ID(@CTARGETTABLENAME,'U') IS NOT NULL
			BEGIN
				SET @CCMD='UPDATE '+@CTABLENAME+' SET SENT_FOR_RECON=1 FROM '+@CTARGETTABLENAME+' B
						   WHERE B.'+@CKEYFIELD+'='+@CTABLENAME+'.'+@CKEYFIELD+' AND B.LAST_UPDATE='+@CTABLENAME+'.LAST_UPDATE'
							
				PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD  			
			END
			
			FETCH NEXT FROM CMDCUR INTO @CTABLENAME,@CXNTYPE
		END
		
		CLOSE CMDCUR
		DEALLOCATE CMDCUR
		
		SET @NSTEP=180
		DECLARE @NSENTID INT
		
		SELECT @NSENTID=MAX(SENT_ID) FROM XNRECON_LOG (NOLOCK) WHERE DEPT_ID=@CCURLOCID
		
		SET  @NSENTID=ISNULL(@NSENTID,0)+1
		
		SET @NSTEP=190
		
		IF NOT EXISTS (SELECT TOP 1 * FROM XNRECON_LOG (NOLOCK) WHERE DEPT_ID=@CCURLOCID)
			INSERT XNRECON_LOG	( DEPT_ID, SENT_ID, SENT_DT, RECON_ID )  
			SELECT @CCURLOCID AS DEPT_ID,@NSENTID AS SENT_ID,GETDATE() AS SENT_DT,0 AS RECON_ID
		ELSE
			UPDATE XNRECON_LOG SET SENT_ID=@NSENTID,SENT_STATUS=NULL,SENT_DT=GETDATE() WHERE DEPT_ID=@CCURLOCID

		
		SET @NSTEP=200
		SET @CCMD=N'SELECT * INTO '+@CTARGETDB+'XNRECON_LOG FROM XNRECON_LOG WHERE DEPT_ID='''+@CCURLOCID+''''
		EXEC SP_EXECUTESQL @CCMD

		
		COMMIT TRANSACTION
		
		SET @NSTEP=215
		INSERT @TRETMSG
		SELECT TABLENAME,'SELECT * FROM '+@CTARGETDB+TABLENAME AS CMDSTR,@CTARGETDB+TABLENAME AS TARGETTABLENAME,
		'' AS ERRMSG FROM @TCMD
		UNION 
		SELECT 'XNRECON_LOG' AS TABLENAME,'SELECT * FROM '+@CTARGETDB+'XNRECON_LOG' AS CMDSTR,
		@CTARGETDB+'XNRECON_LOG' AS TARGETTABLENAME,'' AS ERRMSG
		UNION 
		SELECT 'RECONXNSINFO' AS TABLENAME,'SELECT * FROM '+@CTARGETDB+'RECONXNSINFO' AS CMDSTR,
		@CTARGETDB+'RECONXNSINFO' AS TARGETTABLENAME,'' AS ERRMSG
		
		GOTO END_PROC

LBLACK:
		
		SET @NSTEP=220
		BEGIN TRANSACTION
		
		UPDATE XNRECON_LOG SET SENT_STATUS=1,SENT_DT=GETDATE() WHERE DEPT_ID=@CCURLOCID
		 
		GOTO END_PROC

LBLRESEND:
		
		PRINT 'RESEND DATA'
		SET @NSTEP=230
		IF CURSOR_STATUS('GLOBAL','CMDCUR') IN (0,1)
		BEGIN
			CLOSE CMDCUR
			DEALLOCATE CMDCUR
		END
		
		SET @NSTEP=235
		
		IF OBJECT_ID('TEMPDB..#TMPLIST','U') IS NOT NULL
			DROP TABLE #TMPLIST
		
		SELECT TABLENAME INTO #TMPLIST FROM XNSINFO (NOLOCK) WHERE 1=2
		
		
		SET @NSTEP=240
	
		SET @CCMD=N'IF EXISTS (SELECT NAME FROM '+@CTARGETDB+'SYSOBJECTS (NOLOCK) WHERE XTYPE=''U'' AND NAME=''RECONXNSINFO'')
						SELECT A.NAME FROM '+@CTARGETDB+'SYSOBJECTS A (NOLOCK) 
						JOIN '+@CTARGETDB+'RECONXNSINFO B ON A.NAME=B.TABLENAME WHERE XTYPE=''U''
						UNION
						SELECT ''RECONXNSINFO''
						UNION
						SELECT ''XNRECON_LOG''
					ELSE
						SELECT A.NAME FROM '+@CTARGETDB+'SYSOBJECTS A (NOLOCK)  WHERE XTYPE=''U'''	
					
		PRINT @CCMD
		
		INSERT #TMPLIST
		EXEC SP_EXECUTESQL @CCMD	
		
		SET @NSTEP=250
		INSERT @TRETMSG
		SELECT TABLENAME,'SELECT * FROM '+@CTARGETDB+TABLENAME AS CMDSTR,@CTARGETDB+TABLENAME AS TARGETTABLENAME,'' AS ERRMSG FROM #TMPLIST
	
		GOTO END_PROC
								
	END TRY
	
	BEGIN CATCH
		SELECT @CERRORMSG='PROCEDURE SP_CREATEXNRECONDATA : STEP: '+STR(@NSTEP)+' LINE NO. :'+
		ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE')+'MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')
		

		GOTO END_PROC
	END CATCH

	
	
END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')=''
			COMMIT TRANSACTION
		ELSE
			ROLLBACK	
	END				
	
	IF NOT EXISTS (SELECT TOP 1 TABLENAME FROM @TRETMSG) AND ISNULL(@CERRORMSG,'')<>''
		INSERT @TRETMSG
		SELECT '' AS TABLENAME,'' AS CMDSTR,'' AS TARGETTABLENAME,ISNULL(@CERRORMSG,'')
		
	SELECT * FROM @TRETMSG		
	
END
