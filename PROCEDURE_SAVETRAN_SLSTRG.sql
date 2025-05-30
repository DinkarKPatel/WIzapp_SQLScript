CREATE PROCEDURE SAVETRAN_SLSTRG
(
	@NUPDATEMODE		NUMERIC(1,0),  --- 1-ADD,2-EDIT,3-CANCELLED,4-HANDOVER
	@NSPID				INT,
	@CFINYEAR			VARCHAR(10),
	@CMEMONOPREFIX      VARCHAR(10),
	@MEMOID             VARCHAR(22)=''
)
AS
BEGIN
	--changes by Dinkar in location id varchar(4)..
	DECLARE @CTEMPDBNAME			VARCHAR(100),
			@CMASTERTABLENAME		VARCHAR(100),
			@CDETAILTABLENAME1		VARCHAR(100),
			@CDETAILTABLENAME2		VARCHAR(100),
			@CTEMPMASTERTABLENAME	VARCHAR(100),
			@CTEMPDETAILTABLENAME1	VARCHAR(100),
			@CTEMPDETAILTABLENAME2	VARCHAR(100),
			@CTEMPMASTERTABLE		VARCHAR(100),
			@CTEMPDETAILTABLE1		VARCHAR(100),
			@CTEMPDETAILTABLE2		VARCHAR(100),
			@CERRORMSG				VARCHAR(500),
			@CKEYFIELD1				VARCHAR(50),
			@CKEYFIELDVAL1			VARCHAR(50),
			@CMEMONO				VARCHAR(20),
			@NMEMONOLEN				NUMERIC(20,0),
			@CMEMONOVAL				VARCHAR(50),
			@CMEMODEPTID			VARCHAR(2),
			@CLOCATIONID			VARCHAR(4),
			@CHODEPTID				VARCHAR(4),
			@CCMD					NVARCHAR(4000),
			@NSAVETRANLOOP			BIT,
			@NSTEP					INT,
			@LENABLETEMPDATABASE	BIT,@cLocId char(2)
			

	DECLARE @OUTPUT TABLE (ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))
	
	--SET @CMEMONOPREFIX='GP'

	SET @NSTEP = 10		-- SETTTING UP ENVIRONMENT

	
	SET @CTEMPDBNAME = ''

	SET @CMASTERTABLENAME	= 'SLSTARGET_MST'
	SET @CDETAILTABLENAME1	= 'SLSTARGET_DET'
	SET @CDETAILTABLENAME2  = 'SLSTARGET_SETUP'
	
	SET @CTEMPMASTERTABLENAME	= 'SLSTRG_SLSTARGET_MST_UPLOAD'
	SET @CTEMPDETAILTABLENAME1	= 'SLSTRG_SLSTARGET_DET_UPLOAD'
    SET @CTEMPDETAILTABLENAME2=   'SLSTRG_SLSTARGET_SETUP_UPLOAD'
	
	
	SET @CTEMPMASTERTABLE	=  @CTEMPMASTERTABLENAME
	SET @CTEMPDETAILTABLE1	=  @CTEMPDETAILTABLENAME1
    SET @CTEMPDETAILTABLE2  =  @CTEMPDETAILTABLENAME2
	
	SET @CERRORMSG			= ''
	SET @CKEYFIELD1			= 'MEMO_ID'
	SET @CMEMONO			= 'MEMO_NO'
	SET @NMEMONOLEN			= 10
	
	
    SELECT @CLOCID=LOCATION_CODE FROM SLSTRG_SLSTARGET_MST_UPLOAD (nolock) WHERE SP_ID=@NSPID  

   	IF @cLocId=''
		SELECT @CLOCATIONID		= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
    ELSE
		SET @CLOCATIONId=@cLocId
    
    IF ISNULL(@CMEMONOPREFIX,'')=''
    SET @CMEMONOPREFIX=@CLOCATIONID

	BEGIN TRANSACTION
	BEGIN TRY
	
	 SET @NSTEP = 151
	IF  @NUPDATEMODE IN (3) AND ISNULL(@MEMOID,'')=''
	BEGIN
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID SHOULD NOT BE EMPTY....'
	    GOTO END_PROC
	END
	
	
	     SET @NSTEP = 151
	    IF @NUPDATEMODE=3
	    BEGIN
	       UPDATE SLSTARGET_MST SET CANCELLED=1 WHERE MEMO_ID=@MEMOID
	       GOTO END_PROC
	      
	    END
			
		SET @NSTEP = 40
		
		SET @CCMD = 'SELECT  @CKEYFIELDVAL1 = MEMO_ID FROM ' + @CTEMPMASTERTABLE +'
		 WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
		EXEC SP_EXECUTESQL @CCMD, N' @CKEYFIELDVAL1 VARCHAR(50) OUTPUT', 
								  @CKEYFIELDVAL1 OUTPUT
		-- START UPDATING XN TABLES	
		IF @NUPDATEMODE = 1 -- ADDMODE	
		BEGIN	

		IF ISNULL(@CLOCATIONID,'')=''
		 BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' LOCATION ID CAN NOT BE BLANK  '  
			GOTO END_PROC    
		 END
			SET @NSTEP = 50		-- GENERATING NEW KEY
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
					  GOTO END_PROC  		
				END

				SET @NSTEP = 60		-- GENERATING NEW ID

				-- GENERATING NEW ORDER ID
				SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
				
				IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO END_PROC
				END
				
				SET @NSTEP = 70
				-- CHECK WETHER THE MEMO ID IS STILL LATER
				IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO END_PROC
				END

				SET @NSTEP = 80		-- UPDATING NEW ID INTO TEMP TABLES

				-- UPDATING NEWLY GENERATED MEMO NO AND MEMO ID IN BUYER ORDER MST AND BUYER ORDER DET TEMP TABLES
				SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' + 
							@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
				PRINT @CCMD		
				EXEC SP_EXECUTESQL @CCMD
				
				SET @NSTEP = 90
				SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
				PRINT @CCMD	
				EXEC SP_EXECUTESQL @CCMD
			    
			    
				SET @NSTEP = 90
				SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE2 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
				PRINT @CCMD	
				EXEC SP_EXECUTESQL @CCMD
			
			
				SET @CCMD = N'UPDATE '+ @CTEMPDETAILTABLE1 + ' SET ROW_ID = NEWID() WHERE  SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
				PRINT @CCMD	
				EXEC SP_EXECUTESQL @CCMD
			
			    SET @CCMD = N'UPDATE '+ @CTEMPDETAILTABLE2 + ' SET ROW_ID = NEWID() WHERE  SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
				PRINT @CCMD	
				EXEC SP_EXECUTESQL @CCMD
			
				
				
	    END
		END					-- END OF ADDMODE
		ELSE				-- CALLED FROM EDITMODE
		BEGIN				-- START OF EDITMODE
			SET @NSTEP = 110		-- GETTING ID INFO FROM TEMP TABLE
			
			-- GETTING ORDER_ID WHICH IS BEING EDITED
			SET @CCMD = 'SELECT @CKEYFIELDVAL1 = MEMO_ID, @CMEMONOVAL = MEMO_NO FROM ' + @CTEMPMASTERTABLE +' WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
			EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT', 
							   @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT
			IF (@CKEYFIELDVAL1 IS NULL ) OR (@CMEMONOVAL IS NULL )
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'
				  GOTO END_PROC  		
			END
			
			SET @NSTEP = 120		-- UPDATING SENT_TO_HO FLAG TEMP TABLE
			
			SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE LEFT(MEMO_ID,5) = ''LATER'' AND SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
			PRINT @CCMD	
			EXEC SP_EXECUTESQL @CCMD
			
            SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE2 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE LEFT(MEMO_ID,5) = ''LATER'' AND SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
			PRINT @CCMD	
			EXEC SP_EXECUTESQL @CCMD
			
			SET @NSTEP = 130	
			SET @CCMD = N'UPDATE '+ @CTEMPDETAILTABLE1 + ' SET ROW_ID = NEWID() WHERE  SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
			PRINT @CCMD	
			EXEC SP_EXECUTESQL @CCMD
			
			
			SET @CCMD = N'UPDATE '+ @CTEMPDETAILTABLE2 + ' SET ROW_ID = NEWID() WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
			PRINT @CCMD	
			EXEC SP_EXECUTESQL @CCMD
	
			DELETE  FROM SLSTARGET_DET WHERE MEMO_ID=@CKEYFIELDVAL1
			DELETE FROM SLSTARGET_SETUP WHERE MEMO_ID=@CKEYFIELDVAL1
		
	    END					-- END OF EDITMODE
	    
	   
        
        DECLARE @FILTER VARCHAR(MAX)
	    SET @FILTER=' B.SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
		SET @NSTEP = 150
		
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPMASTERTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@FILTER
			
		
		SET @NSTEP = 160		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES

		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME1
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME1
			, @CKEYFIELD1	= @CKEYFIELD1
			, @CKEYFIELD2	= 'ROW_ID'
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@FILTER
			
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME2
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME2
			, @CKEYFIELD1	= @CKEYFIELD1
			, @CKEYFIELD2	= 'ROW_ID'
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@FILTER
			
			
			IF NOT  EXISTS (SELECT TOP 1 'U' FROM SLSTARGET_DET WHERE MEMO_ID =@CKEYFIELDVAL1)
			SET @CERRORMSG='DETAILS NOT AVAILABLE PLEASE CHECK'
			
		    IF NOT  EXISTS (SELECT TOP 1 'U' FROM SLSTARGET_SETUP WHERE MEMO_ID =@CKEYFIELDVAL1)
			SET @CERRORMSG='SET UP NOT AVAILABLE PLEASE CHECK'
			

	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		GOTO END_PROC
	END CATCH
	
END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' 
		BEGIN
			 	COMMIT TRANSACTION
		END
		ELSE
			ROLLBACK
	END
	
	INSERT @OUTPUT ( ERRMSG, MEMO_ID)
		VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,'') )

	SELECT * FROM @OUTPUT	
	
	
	---DROPPING TEMP TABLES
	IF ISNULL(@CERRORMSG,'') = ''
	BEGIN
	   DELETE FROM SLSTRG_SLSTARGET_MST_UPLOAD WHERE SP_ID=LTRIM(RTRIM(STR(@NSPID)))
	   DELETE FROM SLSTRG_SLSTARGET_DET_UPLOAD WHERE SP_ID=LTRIM(RTRIM(STR(@NSPID)))	
	   DELETE FROM SLSTRG_SLSTARGET_SETUP_UPLOAD WHERE SP_ID=LTRIM(RTRIM(STR(@NSPID)))	
    END
    
 
END						
------------- END OF PROCEDURE SAVETRAN_SLSTRG		-----------------------------------------
