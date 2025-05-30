create PROCEDURE SP_MERGEMSTACTDATA  
(  
 @CXNTYPE VARCHAR(20),
 @NSPID INT  
)  
--WITH ENCRYPTION
AS  
BEGIN  
   
  --(dinkar) Replace  left(memoid,2) to Location_code 
	  DECLARE @CERRORMSG VARCHAR(1000),@CCURDEPTID CHAR(4),@CHODEPTID CHAR(4),@CCMD NVARCHAR(MAX),  
		@CXNMASTERTABLENAME VARCHAR(100),@BPROCEED BIT,@CTABLENAME VARCHAR(100),@CMASTERKEYFIELD VARCHAR(100),  
		@CKEYFIELD VARCHAR(100),@CPARENTTABLENAME VARCHAR(100),@CPARENTPARANAME VARCHAR(100),@CCHILDPARANAME VARCHAR(100),  
		@CWHERECLAUSE VARCHAR(100),@CJOINSTR VARCHAR(1000),@CMEMOID VARCHAR(100),@CFINYEAR VARCHAR(100),  
		@NGRPCHARS INT,@NSERIESCHARS INT,@BSERIESBROKEN BIT,@CPREVMEMOID VARCHAR(40),@CMERGETABLENAME VARCHAR(50),  
		@CFIRSTMEMOID VARCHAR(40),@NPREVMEMOID INT,@NMEMONOLEN INT,@CRETCMD NVARCHAR(MAX),  
		@CDELCHILDTABLENAME VARCHAR(100),@CDELCHILDPARANAME VARCHAR(100),@CDELPARENTPARANAME VARCHAR(100),  
		@CORIGINALTABLENAME VARCHAR(100),@NLOCTYPE INT,@BDONOTMERGE BIT,@CRFXNTYPE VARCHAR(10),@BHOLOC BIT,  
		@BINSERTONLY BIT,@BLINKEDMASTER BIT,@BPURLOC BIT,@CSOURCELOCID CHAR(2),@BSOURCEPURLOC BIT,  
		@CMISSINGMEMOID VARCHAR(40),@CGRPCODE VARCHAR(20),@BRETVAL BIT,@NPREVNO INT,@CPREVNO VARCHAR(20),  
		@BEMPHEADSUPDATED BIT,@CFILTERCONDITION VARCHAR(100),@CTABLEPREFIX VARCHAR(100),
		@BUPDPURINFO BIT,@CUNQCOLUMNNAME1 VARCHAR(100),@CUNQCOLUMNNAME2 VARCHAR(100),@NXNSMERGINGORDER INT,  
		@BLMDATAEXISTS BIT,@NSTEP INT,@CTEMPLMTABLE VARCHAR(100),@CTEMPHDTABLE VARCHAR(100),@CTEMPREGIONTABLE VARCHAR(100),
		@CTEMPAREATABLE VARCHAR(100),@CTEMPCITYTABLE VARCHAR(100),@CTEMPSTATETABLE VARCHAR(100),@CSTATECODE CHAR(7),
		@CTEMPLMPTABLE VARCHAR(100),@CTEMPSMTABLE VARCHAR(100),@CTEMPSDTABLE VARCHAR(100),@CTEMPLOCTABLE VARCHAR(100),
		@CTEMPFORMTABLE	VARCHAR(100),@CTEMPNRMTABLE VARCHAR(100),@CSOURCETEMPTABLE VARCHAR(200),			  
	    @EXCLUDE_SUNDRY_CREDITORS BIT,@BMIRRORINGENABLED BIT	    
	   
	    
	  BEGIN TRANSACTION  
	    
	  SET @NSTEP = 10  
	  DECLARE @TRETMSG TABLE  (MEMO_ID VARCHAR(40),ERRMSG VARCHAR(MAX))  
	   
	  BEGIN TRY  
	       
	  SELECT @CERRORMSG='',@BPROCEED=1,@NMEMONOLEN=10,@CRETCMD='',@CMEMOID='',@BEMPHEADSUPDATED=0  
	    
	  SET @CTABLEPREFIX='TMP_MSTACT' 
	  SET @BINSERTONLY=0
	 
	  SET @NSTEP = 15    


	  SELECT @CCURDEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'  
	  SELECT @CHODEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'    
	    	    
	  SELECT @NLOCTYPE=LOC_TYPE,@BPURLOC=PUR_LOC FROM LOCATION (NOLOCK) WHERE DEPT_ID=@CCURDEPTID  


	  IF EXISTS (SELECT TOP 1 CONFIG_OPTION FROM CONFIG WHERE 
				   CONFIG_OPTION='MIRROR_SERVER_IP' AND VALUE<>'')
			SET @BMIRRORINGENABLED=1
	  ELSE
			SET @BMIRRORINGENABLED=0

	  IF @BMIRRORINGENABLED=1
	  BEGIN
			SET @CERRORMSG='LOCATION MASTER MERGING SHIFTED TO MIRRORSERVICE....'
			GOTO LBLLAST
	  END
	  
	  IF @NLOCTYPE<>1
	  BEGIN
		SET @CERRORMSG='ACCOUNTS MASTER CANNOT BE MERGED AT NON-COMPANY OWNED LOCATIONS.....'
		GOTO LBLLAST
	  END
  
	  SET @NSTEP = 20  
	    
	  SET @CCMD=N'IF OBJECT_ID(''TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID)))+''',''U'') IS NOT NULL  
		  SELECT @BLMDATAEXISTSOUT=1   
		 ELSE  
		  SELECT @BLMDATAEXISTSOUT=0'  
	  EXEC SP_EXECUTESQL @CCMD,N'@BLMDATAEXISTSOUT BIT OUTPUT',@BLMDATAEXISTSOUT=@BLMDATAEXISTS OUTPUT  
	    
	  IF @BLMDATAEXISTS=0  
	  BEGIN  
	   SET @NSTEP = 23  
	     
	   SET @CERRORMSG='NO LEDGER DATA FOUND TO BE MERGED'  
	   GOTO LBLLAST  
	  END  
	    
	  SET @NSTEP = 26  
	           
	  IF @CCURDEPTID=@CHODEPTID  
	   SET @BHOLOC=1  
	    
	  /*IF TARGET IS LOCATION AND ITS UPD_PURINFO IS 0 THEN SUNDRY CREDITORS SHOULD NOT BE MERGED*/
	  IF @BHOLOC=0
		IF EXISTS(SELECT TOP 1 'U' FROM LOCATION WHERE DEPT_ID=@CCURDEPTID AND UPD_PURINFO=0 AND PUR_LOC=0)
			SET @EXCLUDE_SUNDRY_CREDITORS=1  
	 	    
   	  SELECT TOP 1 @CXNMASTERTABLENAME=TABLENAME,@CMASTERKEYFIELD=KEYFIELD FROM XNSINFO (NOLOCK) WHERE XN_TYPE=@CXNTYPE  
	  AND XNS_MERGING_ORDER NOT IN (0,99)  ORDER BY XNS_SENDING_ORDER  
	    
	  SET @NSTEP = 40  
	    
	  SET @CXNMASTERTABLENAME=ISNULL(@CXNMASTERTABLENAME,'')  
	    
	  SET @CMEMOID='MSTACT'  
	    
	  LBLMERGEBEFORE:  
	    
	    
	  SET @NSTEP=150

	  SET @CTEMPFORMTABLE='TMP_MSTACT_FORM_'+LTRIM(RTRIM(STR(@NSPID)))
	  IF OBJECT_ID(@CTEMPFORMTABLE,'U') IS NOT NULL
	  BEGIN
		  SET @NSTEP=160
		  SET @CCMD=N'UPDATE F SET F.FORM_NAME=F.FORM_NAME+''(''+F.FORM_ID+'')''
							  FROM FORM F 
							  JOIN TMP_MSTACT_FORM_'+LTRIM(RTRIM(STR(@NSPID)))+' TF ON TF.FORM_NAME=F.FORM_NAME AND  F.FORM_ID<>TF.FORM_ID'		
		  PRINT @CCMD
		  EXEC SP_EXECUTESQL @CCMD 
		 
		  SET @NSTEP=160
		  SET @CCMD=N'UPDATE A SET PURCHASE_AC_CODE=ISNULL(B.PURCHASE_AC_CODE,''0000000000''),
					SALE_AC_CODE=ISNULL(B.SALE_AC_CODE,''0000000000''),TAX_AC_CODE=ISNULL(B.TAX_AC_CODE,''0000000000''),
					PUR_RETURN_AC_CODE=ISNULL(B.PUR_RETURN_AC_CODE,''0000000000''),
					SALE_RETURN_AC_CODE=ISNULL(B.SALE_RETURN_AC_CODE,''0000000000''),
					EXCISE_DUTY_AC_CODE=ISNULL(B.EXCISE_DUTY_AC_CODE,''0000000000''),
					EXCISE_EDU_CESS_AC_CODE=ISNULL(B.EXCISE_EDU_CESS_AC_CODE,''0000000000''),
					EXCISE_HEDU_CESS_AC_CODE=ISNULL(B.EXCISE_HEDU_CESS_AC_CODE,''0000000000'')
					FROM '+@CTEMPFORMTABLE+' A
					LEFT OUTER JOIN FORM B ON A.FORM_ID=B.FORM_ID'
		  EXEC SP_EXECUTESQL @CCMD
		  
 	  END 

	  IF OBJECT_ID('TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
	  BEGIN
			SET @CCMD=N'UPDATE TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID)))+' SET COMPANY_CODE=''01'''
			EXEC SP_EXECUTESQL @CCMD
	  END

	  IF OBJECT_ID('TMP_MSTACT_LMP01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
	  BEGIN
			SET @CCMD=N'UPDATE TMP_MSTACT_LMP01106_'+LTRIM(RTRIM(STR(@NSPID)))+' SET COMPANY_CODE=''01'''
			EXEC SP_EXECUTESQL @CCMD
	  END	  
	  
	   
	  LBLDELENTRIES:  
	  DELETE FROM LM_TERMS 
	    
	  --- FIRSTLY, DELETE OLDER ENTRIES FROM THE TRANSACTIONS  
	  IF @EXCLUDE_SUNDRY_CREDITORS=1
		BEGIN
			IF OBJECT_ID('TMP_MSTACT_LMP01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
			   AND OBJECT_ID('TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
			   AND OBJECT_ID('TMP_MSTACT_HD01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
			BEGIN
				SET @CCMD='DELETE TLMP FROM TMP_MSTACT_LMP01106_'+LTRIM(RTRIM(STR(@NSPID))) +' S
					   JOIN TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID))) +' SL ON S.AC_CODE=SL.AC_CODE
					   JOIN TMP_MSTACT_HD01106_'+LTRIM(RTRIM(STR(@NSPID))) +' SH ON SH.HEAD_CODE=SL.HEAD_CODE
					   JOIN TMP_MSTACT_HD01106_'+LTRIM(RTRIM(STR(@NSPID))) +' SHH ON SHH.HEAD_CODE=SH.MAJOR_HEAD_CODE
					   WHERE SHH.HEAD_NAME=''SUNDRY CREDITORS'''
				EXEC SP_EXECUTESQL @CCMD	   
			END			
			
			IF OBJECT_ID('TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
				AND OBJECT_ID('TMP_MSTACT_HD01106_'+LTRIM(RTRIM(STR(@NSPID))),'U') IS NOT NULL  
			BEGIN
				SET @CCMD='DELETE TLMP FROM TMP_MSTACT_LM01106_'+LTRIM(RTRIM(STR(@NSPID))) +' SL 
					   JOIN TMP_MSTACT_HD01106_'+LTRIM(RTRIM(STR(@NSPID))) +' SH ON SH.HEAD_CODE=SL.HEAD_CODE
					   JOIN TMP_MSTACT_HD01106_'+LTRIM(RTRIM(STR(@NSPID))) +' SHH ON SHH.HEAD_CODE=SH.MAJOR_HEAD_CODE
					   WHERE SHH.HEAD_NAME=''SUNDRY CREDITORS'''
				EXEC SP_EXECUTESQL @CCMD	   
			END			
		END 
	    
	  SET @NSTEP = 152
	 
	 LBLMERGE:  
	    
	  SET @CFILTERCONDITION=''  
	    
	  SET @NSTEP = 165  
	  
	  IF CURSOR_STATUS('GLOBAL','MERGECUR') IN (0,1)  
	  BEGIN  
	   CLOSE MERGECUR  
	   DEALLOCATE MERGECUR  
	  END  
	    
	  --- NOW, UPDATE TRANSACTIONS DATA ONE BY ONE  
	  DECLARE MERGECUR CURSOR FOR   
	  SELECT DISTINCT TABLENAME, KEYFIELD,XNS_MERGING_ORDER  
	  FROM XNSINFO   
	  WHERE XN_TYPE ='MSTACT'-- @CXNTYPE   
	  AND   XNS_MERGING_ORDER <> 99  
	  ORDER BY XNS_MERGING_ORDER  
	    
	  OPEN MERGECUR  
	  FETCH NEXT FROM MERGECUR INTO @CTABLENAME,@CKEYFIELD,@NXNSMERGINGORDER  
	  WHILE @@FETCH_STATUS=0  
	  BEGIN  
	     
	   SET @NSTEP = 168   
	     
	   LBLSTARTMERGE:  
	   SET @BPROCEED=1  
	     
	   SET @CCMD=N'IF NOT EXISTS (SELECT NAME FROM SYSOBJECTS WHERE NAME=''TMP_' + @CXNTYPE + '_' + @CTABLENAME + '_' + LTRIM(RTRIM(STR(@NSPID)))+''')  
		   SET @BPROCEEDOUT=0'  
	     
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD,N'@BPROCEEDOUT BIT OUTPUT',@BPROCEEDOUT=@BPROCEED OUTPUT  
	     
	     
	   IF @BPROCEED=0  
		GOTO LBLMERGENEXT 
		 
	   IF @CTABLENAME='LM01106'
	   BEGIN
			SET @NSTEP = 170  
			
			SET @CCMD='UPDATE ['+@CTABLEPREFIX+'_' + @CTABLENAME + '_' + LTRIM(RTRIM(STR(@NSPID)))+']
					   SET COMPANY_CODE=''01'' WHERE ISNULL(COMPANY_CODE,'''')= '''''
			PRINT @CCMD  
			EXEC SP_EXECUTESQL @CCMD,N'@CERRORMSGOUT VARCHAR(1000) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT  
	   END  
	     
	   IF  EXISTS (SELECT TABLENAME FROM MST_UNQ  (NOLOCK) WHERE TABLENAME=@CTABLENAME)  
	   BEGIN  
			SET @NSTEP = 175
		      
			SELECT @CUNQCOLUMNNAME1=PRIMARY_COLUMNNAME FROM MST_UNQ (NOLOCK) WHERE TABLENAME=@CTABLENAME   
			SELECT @CUNQCOLUMNNAME2=SECONDARY_COLUMNNAME FROM MST_UNQ (NOLOCK) WHERE TABLENAME=@CTABLENAME  
		      
			SET @CCMD=N'UPDATE '+@CTABLENAME+' SET '+@CUNQCOLUMNNAME1+'='+@CTABLENAME+'.'+@CUNQCOLUMNNAME1+'+''_''+'+  
			   @CTABLENAME+'.'+@CKEYFIELD+' FROM [TMP_'+@CXNTYPE + '_' + @CTABLENAME + '_' +  
				LTRIM(RTRIM(STR(@NSPID)))+'] B  WHERE B.'+@CUNQCOLUMNNAME1+'='+@CTABLENAME+'.'+  
				@CUNQCOLUMNNAME1+(CASE WHEN @CUNQCOLUMNNAME2<>'' THEN ' AND B.'+@CUNQCOLUMNNAME2+  
				'='+@CTABLENAME+'.'+@CUNQCOLUMNNAME2 ELSE '' END)+' AND B.'+@CKEYFIELD+'<>'+@CTABLENAME+'.'+@CKEYFIELD  
			PRINT @CCMD        
			EXEC SP_EXECUTESQL @CCMD          
	   END  
	     
	   SET @NSTEP = 180   

			SET @CSOURCETEMPTABLE = @CTABLEPREFIX+'_' + @CTABLENAME + '_' + LTRIM(RTRIM(STR(@NSPID)))
			
			IF @CTABLENAME='HD01106'
			BEGIN
				SET @CFILTERCONDITION=' B.HEAD_CODE IN (SELECT DISTINCT MAJOR_HEAD_CODE FROM '+@CSOURCETEMPTABLE+')'
				
				EXEC UPDATEMASTERXN_MERGING
				@CSOURCEDB='',
				@CSOURCETABLE=@CSOURCETEMPTABLE,
				@CDESTDB='',
				@CDESTTABLE=@CTABLENAME,
				@CKEYFIELD1=@CKEYFIELD,
				@CKEYFIELD2='',
				@CKEYFIELD3='',
				@LINSERTONLY=0,
				@BALWAYSUPDATE=1,
				@CFILTERCONDITION=@CFILTERCONDITION,
				@CERRORMSG=@CERRORMSG OUTPUT
			END
			
			
			SET @CFILTERCONDITION=''
			
			SET @NSTEP=75
			
			EXEC UPDATEMASTERXN_MERGING
			@CSOURCEDB='',
			@CSOURCETABLE=@CSOURCETEMPTABLE,
			@CDESTDB='',
			@CDESTTABLE=@CTABLENAME,
			@CKEYFIELD1=@CKEYFIELD,
			@CKEYFIELD2='',
			@CKEYFIELD3='',
			@LINSERTONLY=@BINSERTONLY,
			@LUPDATEONLY=0,
			@BALWAYSUPDATE=1,
			@CFILTERCONDITION=@CFILTERCONDITION,
			@CERRORMSG=@CERRORMSG OUTPUT		
			
		
	   
	   SET @NSTEP = 185     
	   IF @CERRORMSG<>''  
		BREAK  
	       
	   LBLMERGENEXT:  
	     
	   FETCH NEXT FROM MERGECUR INTO @CTABLENAME,@CKEYFIELD,@NXNSMERGINGORDER  
	  END  
	  CLOSE MERGECUR  
	  DEALLOCATE MERGECUR  
	      
	  -- DELETING FROM TEMP TABLES  
	    
	  SET @NSTEP = 190   
	    
	  EXEC SP_DROPTEMPTABLES_XNS @CXNTYPE,@NSPID  
	  
	     
	  SET @CRETCMD='SELECT '''+@CMEMOID+''' AS MEMO_ID,'''+@CERRORMSG+''' AS ERRMSG'   
	    
	 LBLLAST:  
	    
	  SET @NSTEP = 200  
	  --- ON SUCCESSFUL MERGING , DELETE ENTRY FROM XN HISTORY     
	  IF @CERRORMSG=''  
	   DELETE FROM XN_HISTORY WHERE XN_TYPE=@CXNTYPE AND MEMO_ID=@CMEMOID  
	  ELSE  
	  BEGIN  
		   IF @@TRANCOUNT>0  
				ROLLBACK    
	  END   
	    
	  SET @NSTEP = 210  
	    
	  IF @CRETCMD=''  
	   SET @CRETCMD='SELECT '''' AS MEMO_ID,'''+@CERRORMSG+''' AS ERRMSG'  
	    
	  PRINT 'RETURN VALUE : '+ISNULL(@CRETCMD,'NULL RETCMD')  
	  EXEC SP_EXECUTESQL @CRETCMD  
	    
	   
	 END TRY  
	  
	 BEGIN CATCH  
	  
	  IF @@TRANCOUNT>0  
	   ROLLBACK     
	    
	  PRINT 'UNTRAPPED ERROR'    
	       
	  DECLARE @CERRORPROCNAME VARCHAR(100),@CLINENO VARCHAR(5),@CERRTEXT VARCHAR(MAX)  
	    
	  SELECT @CERRORPROCNAME=ISNULL(ERROR_PROCEDURE(),'NULL P'),@CLINENO=ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE'),  
	  @CERRTEXT='STEP : '+LTRIM(RTRIM(STR(@NSTEP)))+' '+ISNULL(ERROR_MESSAGE(),'NULL MSG')  
	    
	  
	  --SELECT @CERRORMSG='PROCEDURE : '+@CERRORPROCNAME+' LINE NO. :'+@CLINENO+' MSG :'+@CERRTEXT  
	    
	  SELECT @CERRORMSG=@CERRTEXT  
	    
	  INSERT @TRETMSG  
	  SELECT 'MSTACT' AS MEMO_ID,@CERRORMSG  
	    
	  SELECT * FROM @TRETMSG  
	  
	  IF CURSOR_STATUS('GLOBAL','MERGECUR') IN (0,1)  
	  BEGIN  
		   CLOSE MERGECUR  
		   DEALLOCATE MERGECUR  
	  END  
	    
	     
	 END CATCH  
	  
	 EXEC SP_DROPTEMPTABLES_XNS @CXNTYPE,@NSPID,'','TMP_MSTACT'       
	 
	 IF @@TRANCOUNT>0  
	 BEGIN  
		  PRINT 'SUCCESS'  
		  COMMIT TRANSACTION  
	 END   
    
END  
--- 'END OF CREATING PROCEDURE SP_MERGEMSTACTDATA'
