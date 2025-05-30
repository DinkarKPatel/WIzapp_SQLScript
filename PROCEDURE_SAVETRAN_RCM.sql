CREATE PROCEDURE SAVETRAN_RCM
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				VARCHAR(50),
	@CMEMONOPREFIX		VARCHAR(50),
	@CFINYEAR			VARCHAR(10),
	@CXNMEMOID			VARCHAR(40)=''
)
----WITH ENCRYPTION
AS
BEGIN
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
			@LDONOTUPDATESTOCK		BIT,
			@CKEYFIELD1				VARCHAR(50),
			@CKEYFIELDVAL1			VARCHAR(50),
			@CMEMONO				VARCHAR(20),
			@NMEMONOLEN				NUMERIC(20,0),
			@CMEMONOVAL				VARCHAR(50),
			@CMEMODEPTID			VARCHAR(4),
			@CHODEPTID				VARCHAR(4),
			@CCMD					NVARCHAR(4000),
			@CCMDOUTPUT				NVARCHAR(4000),
			@NSAVETRANLOOP			BIT,
			@NSTEP					INT

	DECLARE @OUTPUT TABLE (ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))

	SET @NSTEP = 10		-- SETTTING UP ENVIRONMENT

	SET @CTEMPDBNAME = ''

	SET @CMASTERTABLENAME	= 'RCM01106'
	SET @CDETAILTABLENAME1	= 'RCD01106'
	SET @CDETAILTABLENAME2	= 'RCM_PUR_EXPENSE'
	
	
	
	SET @CTEMPMASTERTABLENAME	= 'RCM_RCM01106_UPLOAD'
	SET @CTEMPDETAILTABLENAME1	= 'RCM_RCD01106_UPLOAD'
    SET @CTEMPDETAILTABLENAME2	= 'RCM_RCM_PUR_EXPENSE_UPLOAD'
	
	
	SET @CTEMPMASTERTABLE	= @CTEMPDBNAME + @CTEMPMASTERTABLENAME
	SET @CTEMPDETAILTABLE1	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME1
	SET @CTEMPDETAILTABLE2	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME2
	
	SET @CERRORMSG			= ''
	SET @LDONOTUPDATESTOCK	= 0
	SET @CKEYFIELD1			= 'MEMO_ID'
	SET @CMEMONO			= 'MEMO_NO'
	SET @NMEMONOLEN			= 10
	

	BEGIN TRANSACTION
	
	BEGIN TRY
		
		SET @NSTEP = 20

		IF ISNULL(@CXNMEMOID,'') = '' AND @NUPDATEMODE IN (3)
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID REQUIRED '
			GOTO END_PROC  		
		END
		
		IF @NUPDATEMODE=3
		BEGIN
			SET @NSTEP = 30		
			UPDATE RCM01106 SET CANCELLED=1 WHERE MEMO_ID =@CXNMEMOID
			DELETE FROM RCM_PUR_EXPENSE WHERE RCM_MEMO_ID=@CXNMEMOID
			GOTO END_PROC
		END
		
		SET @NSTEP = 40
		
		--GETTING DEPT_ID FROM TEMP MASTER TABLE
		SET @CCMD = 'SELECT  @CKEYFIELDVAL1 = '+@CKEYFIELD1+' FROM ' + @CTEMPMASTERTABLE +' WHERE SP_ID ='''+@NSPID +''' '
		EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT',@CKEYFIELDVAL1 OUTPUT
		

		-- START UPDATING XN TABLES
		IF @NUPDATEMODE = 1 -- ADDMODE	
		BEGIN	
			SET @NSTEP = 50		-- GENERATING NEW KEY
			
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
				SET @CKEYFIELDVAL1 = @CMEMONOPREFIX + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CMEMONOPREFIX + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
			
				
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
							@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+@NSPID+''' '
				PRINT @CCMD		
				EXEC SP_EXECUTESQL @CCMD
				
				SET @NSTEP = 90
				SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID ='''+@NSPID+''' '
				PRINT @CCMD	
				EXEC SP_EXECUTESQL @CCMD
				
				SET @NSTEP = 100
				SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET ROW_ID = NEWID() WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID='''+@NSPID+''' '
				PRINT @CCMD	
				EXEC SP_EXECUTESQL @CCMD
				

			
		END					-- END OF ADDMODE
		ELSE				-- CALLED FROM EDITMODE
		BEGIN				-- START OF EDITMODE
			
			SET @NSTEP = 110		-- GETTING ID INFO FROM TEMP TABLE
			
			SET @CKEYFIELDVAL1 = @CXNMEMOID
			
			IF (@CKEYFIELDVAL1 IS NULL ) 
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'
				  GOTO END_PROC  		
			END
			
			SET @NSTEP = 120		
			
			SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE LEFT(MEMO_ID,5) = ''LATER'' AND SP_ID='''+@NSPID+''' '
			PRINT @CCMD	
			EXEC SP_EXECUTESQL @CCMD
			
			SET @NSTEP = 130
			SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET ROW_ID = NEWID() WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID ='''+@NSPID+''' '
			PRINT @CCMD	
			EXEC SP_EXECUTESQL @CCMD
			
			
			
	    END					-- END OF EDITMODE
	    
	    
	--   SELECT @CKEYFIELDVAL1,@CTEMPDETAILTABLE2
	    
	    SET @NSTEP = 140
		SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE2 + ' SET RCM_MEMO_ID = '''+@CKEYFIELDVAL1+''' WHERE RCM_MEMO_ID=''LATER'' AND SP_ID ='''+@NSPID+'''  '
		PRINT @CCMD	
		EXEC SP_EXECUTESQL @CCMD
	    
		 DECLARE @CWHERECLAUSE VARCHAR(1000)
		 SET @CWHERECLAUSE=' AND SP_ID='''+ LTRIM(RTRIM((@NSPID)))+''''
		SET @NSTEP = 150
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPMASTERTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@CWHERECLAUSE
			
		
		SET @NSTEP = 160		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES

		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME1
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME1
			, @CKEYFIELD1	= 'ROW_ID'
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@CWHERECLAUSE
		
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME2
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME2
			, @CKEYFIELD1	= 'XN_TYPE'
			, @CKEYFIELD2	= 'RCM_MEMO_ID'
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@CWHERECLAUSE
			
		
		
		--UPDATE A SET TOTAL_REVERSE_CHARGES = B.NET+
		--ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE,0)+ISNULL(A.OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(A.OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(A.OTHER_CHARGES_SGST_AMOUNT,0),
		--ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE,0)+ISNULL(A.OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(A.OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(A.OTHER_CHARGES_SGST_AMOUNT,0)
		--FROM RCM01106 A
		--JOIN 
		--(
		-- SELECT  MEMO_ID ,SUM(XN_VALUE_WITH_GST) AS NET
		-- FROM RCD01106 
		-- WHERE MEMO_ID =@CKEYFIELDVAL1
		-- GROUP BY MEMO_ID
		--) B ON A.MEMO_ID =B.MEMO_ID 
		--WHERE A.MEMO_ID=@CKEYFIELDVAL1	
			
			
	
			
	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'P:- SAVETRAN_RCM STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		GOTO END_PROC
	END CATCH
	
END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''
			COMMIT TRANSACTION
		ELSE
			ROLLBACK
	END
	
	INSERT @OUTPUT ( ERRMSG, MEMO_ID)
		VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,'') )

	SELECT * FROM @OUTPUT	
	
	DELETE A FROM RCM_RCM01106_UPLOAD A (NOLOCK) WHERE SP_ID =@NSPID 
	DELETE A FROM RCM_RCD01106_UPLOAD A (NOLOCK) WHERE SP_ID =@NSPID 
	DELETE A FROM RCM_RCM_PUR_EXPENSE_UPLOAD A (NOLOCK) WHERE SP_ID =@NSPID 

	
    
END						
------------------------------------------------------ END OF PROCEDURE SAVETRAN_RCM
