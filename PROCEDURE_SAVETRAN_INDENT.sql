CREATE PROCEDURE SAVETRAN_INDENT
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				INT,
	@CMEMONOPREFIX		VARCHAR(50),
	@CFINYEAR			VARCHAR(10),
	@CMACHINENAME		VARCHAR(100)='',
	@CWINDOWUSERNAME	VARCHAR(100)='',
	@CWIZAPPUSERCODE	VARCHAR(10)='0000000',
	@CXNMEMOID			VARCHAR(40)='',
	@CLOCID				VARCHAR(2)='',
	@BGEN_BARCODE		BIT=0	
)
--WITH ENCRYPTION
AS
BEGIN
    DECLARE @CTEMPDBNAME			VARCHAR(100),
			@CMASTERTABLENAME		VARCHAR(100),
			@CDETAILTABLENAME1		VARCHAR(100),

			@CTEMPMASTERTABLENAME	VARCHAR(100),
			@CTEMPDETAILTABLENAME1	VARCHAR(100),

			@CTEMPMASTERTABLE		VARCHAR(100),
			@CTEMPDETAILTABLE1		VARCHAR(100),

			@CERRORMSG				VARCHAR(500),
			@LDONOTUPDATESTOCK		BIT,
			@CKEYFIELD1				VARCHAR(50),
			@CKEYFIELDVAL1			VARCHAR(50),
			@CMEMONO				VARCHAR(20),
			@NMEMONOLEN				NUMERIC(20,0),
			@CMEMONOVAL				VARCHAR(50),
			@CMEMODEPTID			VARCHAR(2),
			@CLOCATIONID			VARCHAR(2),
			@CHODEPTID				VARCHAR(2),
			@CCMD					NVARCHAR(4000),
			@CCMDOUTPUT				NVARCHAR(4000),
			@NSAVETRANLOOP			BIT,
			@NSTEP					INT,
			@LENABLETEMPDATABASE	BIT,
			@NBLANKROW              INT,
			@CPARTY_GSTN_NO VARCHAR(50),@CPARTYSTATECODE VARCHAR(50),@NPARTYTYPE INT,@DORDERDT DATETIME

	DECLARE @CTEMPTABLE VARCHAR(100),@CTEMPTABLE1 VARCHAR(100),@CTEMPTABLE2 VARCHAR(100),@BUNIQUE_CODING_EXISTS BIT
	   ,@CSERIAL_NO CHAR(10),@CROW_ID VARCHAR(50),@BNORMALIZE BIT,@NQUANTITY NUMERIC(10,3)
	   ,@BGEN_PCODE BIT
	   ,@CFIN_PREFIX VARCHAR(2),@CORD_PREFIX VARCHAR(3),@CMEMO_SERIES VARCHAR(10),@CBARCODE_SERIES VARCHAR(10)
	   ,@CBARCODE_PREFIX VARCHAR(20),@CNEWPRODUCT_CODE VARCHAR(50)
	   ,@BBARCODE_EXISTS BIT,@CNEW_ROWID VARCHAR(50),@CCUR_LOC_ID VARCHAR(2)
	
	

	  IF ISNULL(@CLOCID,'')=''
		SELECT @CCUR_LOC_ID	= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
    	ELSE
		SELECT @CCUR_LOC_ID=@CLOCID


	    IF ISNULL(@CCUR_LOC_ID,'')=''
		 BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' LOCATION ID CAN NOT BE BLANK  '  
			GOTO END_PROC    
		 END

	SET @CMEMONOPREFIX=@CCUR_LOC_ID+@CCUR_LOC_ID
	
	DECLARE @OUTPUT TABLE(ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))

	SET @NSTEP = 0		-- SETTTING UP ENVIRONMENT
	SET @CTEMPDBNAME = ''
	
	SET @CMASTERTABLENAME	= 'INDENT_MST'
	SET @CDETAILTABLENAME1	= 'INDENT_DET'
	
	SET @CTEMPMASTERTABLENAME	= 'WBO_LOC_'+@CMASTERTABLENAME+'_UPLOAD'
	SET @CTEMPDETAILTABLENAME1	= 'WBO_LOC_'+@CDETAILTABLENAME1+'_UPLOAD'
	
	SET @CTEMPMASTERTABLE	= @CTEMPDBNAME + @CTEMPMASTERTABLENAME
	SET @CTEMPDETAILTABLE1	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME1
		
	SET @CERRORMSG			= ''
	SET @LDONOTUPDATESTOCK	= 0
	SET @CKEYFIELD1			= 'INDENT_ID'
	SET @CMEMONO			= 'INDENT_NO'
	SET @NMEMONOLEN			= 10
	
	IF ISNULL(@CLOCID,'')=''
		SELECT @CLOCATIONID	= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
	ELSE
		SELECT @CLOCATIONID=@CLOCID
    
    SELECT @CHODEPTID = [VALUE] FROM CONFIG WHERE  CONFIG_OPTION='HO_LOCATION_ID'		

	BEGIN TRANSACTION
	
	BEGIN TRY
	    --WHEN ROW IS BLANK
	     SET @NSTEP=5
	    
	     SET @CCMD = 'IF OBJECT_ID ('''+@CTEMPDETAILTABLE1+''',''U'') IS NOT NULL
	     BEGIN
		    DELETE FROM ' + @CTEMPDETAILTABLE1 +' WHERE ISNULL(ARTICLE_CODE,'''')=''''    
		 END '  
		 PRINT @CCMD 
		 EXEC SP_EXECUTESQL @CCMD
		 
		SET @NSTEP = 10	

		IF ISNULL(@CXNMEMOID,'') = '' AND @NUPDATEMODE IN (3,4)
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID REQUIRED '
			GOTO END_PROC  		
		END
			
		SET @NSTEP = 17
		
		-- GETTING DEPT_ID FROM TEMP MASTER TABLE
		SET @CCMD = 'SELECT @CMEMODEPTID = DEPT_ID, @CKEYFIELDVAL1 = INDENT_ID FROM ' + @CTEMPMASTERTABLE
		EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(2) OUTPUT, @CKEYFIELDVAL1 VARCHAR(50) OUTPUT', 
								  @CMEMODEPTID OUTPUT, @CKEYFIELDVAL1 OUTPUT
        
		IF (@CMEMODEPTID IS NULL)
		    BEGIN
			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED...'
			  GOTO END_PROC  		
		    END
		
		-- START UPDATING XN TABLES	
		IF @NUPDATEMODE = 1 -- ADDMODE	
		BEGIN	

		   IF ISNULL(@CLOCATIONID,'')=''
		 BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' LOCATION ID CAN NOT BE BLANK  '  
			GOTO END_PROC    
		 END
			SET @NSTEP = 20		-- GENERATING NEW KEY
			
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
			BEGIN
				-- GENERATING NEW MRR_NO		
				SET @NSAVETRANLOOP=0
				WHILE @NSAVETRANLOOP=0
				BEGIN
					EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,
									@CFINYEAR,0, @CMEMONOVAL OUTPUT   
					
					SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM '+@CMASTERTABLENAME+' 
											WHERE '+@CMEMONO+'='''+@CMEMONOVAL+''' 
											AND FIN_YEAR = '''+@CFINYEAR+''' )
									SET @NLOOPOUTPUT=0
								ELSE
									SET @NLOOPOUTPUT=1'
					PRINT @CCMD
					EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT
				END

				IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'	
					  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'
					  GOTO END_PROC  		
				END

				SET @NSTEP = 30		-- GENERATING NEW ID

				-- GENERATING NEW ORDER ID
				SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))
				IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO END_PROC
				END
				
				SET @NSTEP = 40		-- UPDATING NEW ID INTO TEMP TABLES

				-- UPDATING NEWLY GENERATED PO NO AND PO ID IN ORDER MST AND ORDER DET TEMP TABLES
				SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' + 
							@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='+CAST(@NSPID AS VARCHAR)
				PRINT @CCMD							
				EXEC SP_EXECUTESQL @CCMD
			
				SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+'''
				WHERE SP_ID='+CAST(@NSPID AS VARCHAR)
				PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD
			END
		END-- END OF ADDMODE--@UPDATEMODE=1
		
		ELSE-- CALLED FROM EDITMODE
		BEGIN
			SET @NSTEP = 50
			-- GETTING ORDER_ID WHICH IS BEING EDITED
			SET @CCMD = 'SELECT @CKEYFIELDVAL1 = INDENT_ID, @CMEMONOVAL = INDENT_NO FROM ' + @CTEMPMASTERTABLE
			EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT', 
							   @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT
							   
			SET @NSTEP = 55
			IF (@CKEYFIELDVAL1 IS NULL ) OR (@CMEMONOVAL IS NULL )
			   BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'
				  GOTO END_PROC  		
			   END

			SET @NSTEP = 60		-- UPDATING SENT_TO_HO FLAG TEMP TABLE
			SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET SENT_TO_HO = 0,LAST_UPDATE=GETDATE() '
			EXEC SP_EXECUTESQL @CCMD
			
			IF ISNULL(@CERRORMSG,'')<>''
				GOTO END_PROC
		END-- END OF EDITMODE

		SET @NSTEP = 65
		SET @CCMD='MERGE ['+@CMASTERTABLENAME+'] T
		USING (SELECT * FROM ['+@CTEMPMASTERTABLE+'] WHERE SP_ID='+CAST(@NSPID AS VARCHAR)+') S ON T.['+@CKEYFIELD1+']=S.['+@CKEYFIELD1+']
		WHEN MATCHED THEN UPDATE SET T.EDITED = S.EDITED,  T.LAST_UPDATE =  ISNULL( S.LAST_UPDATE, ''''),  T.INDENT_DT =  ISNULL( S.INDENT_DT, ''''),  T.CANCELLED =  ISNULL( S.CANCELLED, 0),  T.SENT_TO_HO =  ISNULL( S.SENT_TO_HO, 0),  T.SENT =  ISNULL( S.SENT, 0),  T.APPROVED =  ISNULL( S.APPROVED, 0),  T.SMS_SENT =  ISNULL( S.SMS_SENT, 0),  T.FIN_YEAR =  ISNULL( S.FIN_YEAR, ''''),  T.REMARKS =  ISNULL( S.REMARKS, ''''),  T.COMPANY_CODE =  ISNULL( S.COMPANY_CODE, ''''),  T.USER_CODE =  ISNULL( S.USER_CODE, ''''),  T.DEPT_ID =  ISNULL( S.DEPT_ID, ''''),  T.EDT_USER_CODE =  ISNULL( S.EDT_USER_CODE, ''''),  T.INDENT_NO =  ISNULL( S.INDENT_NO, '''')
		WHEN NOT MATCHED THEN INSERT (EDITED,LAST_UPDATE,INDENT_DT,CANCELLED,SENT_TO_HO,SENT,APPROVED,SMS_SENT,INDENT_ID,FIN_YEAR,REMARKS,COMPANY_CODE,USER_CODE,DEPT_ID,EDT_USER_CODE,INDENT_NO) VALUES (S.EDITED,ISNULL( S.LAST_UPDATE, ''''),ISNULL( S.INDENT_DT, ''''),ISNULL( S.CANCELLED, 0),ISNULL( S.SENT_TO_HO, 0),ISNULL( S.SENT, 0),ISNULL( S.APPROVED, 0),ISNULL( S.SMS_SENT, 0),ISNULL( S.INDENT_ID, ''''),ISNULL( S.FIN_YEAR, ''''),ISNULL( S.REMARKS, ''''),ISNULL( S.COMPANY_CODE, ''''),ISNULL( S.USER_CODE, ''''),ISNULL( S.DEPT_ID, ''''),ISNULL( S.EDT_USER_CODE, ''''),ISNULL( S.INDENT_NO, ''''));'
		--PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP = 66
		SET @CCMD = N'DECLARE  @DETROW TABLE ( OLD_ROW_ID	VARCHAR(40), NEW_ROW_ID	VARCHAR(40))
		INSERT @DETROW 
		SELECT ROW_ID,''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID()) AS NEW_ROW_ID FROM ' + @CTEMPDETAILTABLE1 + ' WHERE  LEFT(ROW_ID,5) = ''LATER''
		UPDATE A SET A.ROW_ID = B.NEW_ROW_ID FROM ' + @CTEMPDETAILTABLE1 + ' A JOIN @DETROW B ON A.ROW_ID = B.OLD_ROW_ID'
		--PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP = 67		-- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES
		SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME1 + ' 
					WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''
					AND ROW_ID NOT IN (SELECT ROW_ID FROM ' + @CTEMPDETAILTABLE1 + ')'
		--PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP = 70
		SET @CCMD='MERGE ['+@CDETAILTABLENAME1+'] T
		USING (SELECT * FROM ['+@CTEMPDETAILTABLE1+'] WHERE SP_ID='+CAST(@NSPID AS VARCHAR)+') S ON T.[ROW_ID]=S.[ROW_ID]
		WHEN MATCHED THEN UPDATE SET T.LAST_UPDATE =  ISNULL( S.LAST_UPDATE, ''''),  T.QUANTITY =  ISNULL( S.QUANTITY, 0),  T.INDENT_ID =  ISNULL( S.INDENT_ID, ''''),  T.REMARKS =  ISNULL( S.REMARKS, ''''),  T.PARA1_CODE =  ISNULL( S.PARA1_CODE, ''''),  T.PARA2_CODE =  ISNULL( S.PARA2_CODE, ''''),  T.ARTICLE_CODE =  ISNULL( S.ARTICLE_CODE, '''')
		WHEN NOT MATCHED THEN INSERT (LAST_UPDATE,QUANTITY,INDENT_ID,ROW_ID,REMARKS,PARA1_CODE,PARA2_CODE,ARTICLE_CODE) VALUES (ISNULL( S.LAST_UPDATE, ''''),ISNULL( S.QUANTITY, 0),ISNULL( S.INDENT_ID, ''''),ISNULL( S.ROW_ID, ''''),ISNULL( S.REMARKS, ''''),ISNULL( S.PARA1_CODE, ''''),ISNULL( S.PARA2_CODE, ''''),ISNULL( S.ARTICLE_CODE, ''''));'
		--PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	
		GOTO END_PROC
	END TRY
	
	BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		GOTO END_PROC
	END CATCH
	
END_PROC:
	UPDATE indent_mst WITH (ROWLOCk) SET last_update=getdate() WHERE indent_id=@CKEYFIELDVAL1

   IF @@TRANCOUNT>0
   BEGIN
      IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''
         BEGIN
               COMMIT TRANSACTION
		 END
	  ELSE
		 ROLLBACK
	  END
	
	  INSERT @OUTPUT ( ERRMSG, MEMO_ID) VALUES (ISNULL(@CERRORMSG,''),ISNULL(@CKEYFIELDVAL1,''))

	  SELECT * FROM @OUTPUT	

	  DELETE WBO_LOC_INDENT_MST_UPLOAD WHERE SP_ID=@NSPID
	  DELETE WBO_LOC_INDENT_DET_UPLOAD WHERE SP_ID=@NSPID
   END		
-----END OF PROCEDURE SAVETRAN_INDENT
