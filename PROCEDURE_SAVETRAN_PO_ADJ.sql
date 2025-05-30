create PROCEDURE SAVETRAN_PO_ADJ--(LocId 3 digit change by Sanjay:06-11-2024)
(
	@NUPDATEMODE		NUMERIC(1,0)=1,
	@NSPID				VARCHAR(50),
	@CMEMONOPREFIX		VARCHAR(50),
	@CFINYEAR			VARCHAR(10),
	@CMACHINENAME		VARCHAR(100)='',
	@CWINDOWUSERNAME	VARCHAR(100)='',
	@CWIZAPPUSERCODE	VARCHAR(10)='0000000',
	@CXNMEMOID			VARCHAR(40)='',
	@CCOMPUTERIP		VARCHAR(20)=''
)
--WITH ENCRYPTION
AS
BEGIN
	-- @NUPDATEMODE:	1- NEW PO ADJUSTMENT ADDED, 
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
			@CLOCATIONID			VARCHAR(4),
			@CHODEPTID				VARCHAR(4),
			@CCMD					NVARCHAR(4000),
			@CCMDOUTPUT				NVARCHAR(4000),
			@NSAVETRANLOOP			BIT,
			@NSTEP					INT

	DECLARE @OUTPUT TABLE(ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))

	SET @NSTEP = 0		-- SETTTING UP ENVIRONMENT
	SET @CTEMPDBNAME = ''

	SET @CMASTERTABLENAME	= 'PO_ADJ_MST'
	SET @CDETAILTABLENAME1	= 'PO_ADJ_DET'

	SET @CTEMPMASTERTABLENAME	= 'PO_PO_ADJ_MST_UPLOAD'
	SET @CTEMPDETAILTABLENAME1	= 'PO_PO_ADJ_DET_UPLOAD'

	SET @CTEMPMASTERTABLE	= @CTEMPDBNAME + @CTEMPMASTERTABLENAME
	SET @CTEMPDETAILTABLE1	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME1
	
	SET @CERRORMSG			= ''
	SET @LDONOTUPDATESTOCK	= 0
	SET @CKEYFIELD1			= 'MEMO_ID'
	SET @CMEMONO			= 'MEMO_NO'
	SET @NMEMONOLEN			= 10
	 
  IF @NUPDATEMODE IN (1,2)
	SELECT @CLOCATIONID =LOCATION_CODE  FROM PO_PO_ADJ_MST_UPLOAD (NOLOCK) WHERE sp_id=@NSPID
  ELSE
    SELECT @CLOCATIONID =LOCATION_CODE  FROM PO_ADJ_MST (NOLOCK) WHERE memo_ID=@CXNMEMOID
  
		
	SELECT @CHODEPTID		= [VALUE] FROM CONFIG WHERE  CONFIG_OPTION='HO_LOCATION_ID'		

	SELECT PO_ID ,ADJ_QUANTITY 
	      INTO #TMPPOADJ 
	FROM POD01106  (NOLOCK) WHERE 1=2

	BEGIN TRY
		
		BEGIN TRANSACTION
			
		SET @NSTEP=15
		
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
				-- GENERATING NEW PO_ADJ_NO		
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

				SET @NSTEP = 30		-- GENERATING NEW ID
				-- GENERATING NEW PO ID
				SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
				
				IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO END_PROC
				END
				
				SET @NSTEP = 35
				-- CHECK WETHER THE MEMO ID IS STILL LATER
				IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO END_PROC
				END

				SET @NSTEP = 40		-- UPDATING NEW ID INTO TEMP TABLES

				-- UPDATING NEWLY GENERATED PO_ADJ_NO AND PO_ADJ_ID IN MASTER AND DETAIL TEMP TABLES
				SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' + 
							@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID =''' + @NSPID+''''

                PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD
			
				SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID =''' + @NSPID+''''
				
				PRINT @CCMD
				
				EXEC SP_EXECUTESQL @CCMD
				
			END

		END					-- END OF ADDMODE

		SET @NSTEP = 50
		-- CHECK WETHER THE MEMO ID IS STILL LATER
		IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
			GOTO END_PROC
		END

		-- UPDATING MASTER TABLE (PO_ADJ_MST) FROM TEMP TABLE
		SET @NSTEP = 60		-- UPDATING MASTER TABLE

		 DECLARE @CWHERECLAUSE VARCHAR(1000)
      SET @CWHERECLAUSE = ' SP_ID='+LTRIM(RTRIM((@NSPID)))

		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPMASTERTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@CWHERECLAUSE
			
			-- UPDATING TRANSACTION TABLE (PO_ADJ_DET) FROM TEMP TABLE
			SET @NSTEP = 70		-- UPDATING TRANSACTION TABLE

			-- UPDATING ROW_ID IN TEMP TABLES
			SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
						  WHERE LEFT(ROW_ID,5) = ''LATER''  AND SP_ID= ''' + @NSPID  + ''''
			EXEC SP_EXECUTESQL @CCMD
			-- INSERTING/UPDATING THE ENTRIES IN PO_ADJ_DET TABLE FROM TEMPTABLE
			SET @NSTEP = 80		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES
			EXEC UPDATEMASTERXN 
				  @CSOURCEDB	= @CTEMPDBNAME
				, @CSOURCETABLE = @CTEMPDETAILTABLENAME1
				, @CDESTDB		= ''
				, @CDESTTABLE	= @CDETAILTABLENAME1
				, @CKEYFIELD1	= 'ROW_ID'
				, @BALWAYSUPDATE = 1
				,@CFILTERCONDITION=@CWHERECLAUSE


				UPDATE POD SET ADJ_QUANTITY =ISNULL(POD.ADJ_QUANTITY,0)+ISNULL(A.ADJ_QUANTITY,0)
				FROM PO_ADJ_DET A (NOLOCK)
				JOIN POD01106 POD (NOLOCK) ON A.PO_ROW_ID =POD.ROW_ID 
				WHERE MEMO_ID=@CKEYFIELDVAL1

				INSERT INTO #TMPPOADJ(PO_ID ,ADJ_QUANTITY )
				SELECT  POD.PO_ID,SUM(A.ADJ_QUANTITY) AS ADJ_QUANTITY 
				FROM PO_ADJ_DET A (NOLOCK)
				JOIN POD01106 POD (NOLOCK) ON A.PO_ROW_ID =POD.ROW_ID 
				WHERE MEMO_ID=@CKEYFIELDVAL1
				GROUP BY POD.PO_ID

				UPDATE A SET TOTAL_ADJ_QUANTITY=ISNULL(A.TOTAL_ADJ_QUANTITY,0)+ISNULL(B.ADJ_QUANTITY,0)
				FROM POM01106 A (NOLOCK)
				JOIN #TMPPOADJ B ON A.PO_ID =B.PO_ID 
				
				
			  INSERT INTO PURCHASEORDERPROCESSINGNEW(XNTYPE,ROWID,REFROWID,QTY)
			  SELECT 'POADJUSTMENT' AS XNTYPE, a.ROW_ID ROWID,a.PO_ROW_ID  REFROWID,a.ADJ_QUANTITY 
			  FROM PO_ADJ_DET A (NOLOCK)
			  where memo_id=@CKEYFIELDVAL1
	  
			
				
			     
	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
				
		GOTO END_PROC
	END CATCH
	
END_PROC:
        UPDATE PO_ADJ_MST SET LAST_UPDATE=GETDATE () WHERE MEMO_ID=@CKEYFIELDVAL1
		UPDATE PO_ADJ_MST SET HO_SYNCH_LAST_UPDATE='' WHERE MEMO_ID=@CKEYFIELDVAL1
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

	 SET @CCMD = N'DELETE FROM  PO_PO_ADJ_DET_UPLOAD WHERE SP_ID= '''+@NSPID +''''
		
	 EXEC SP_EXECUTESQL @CCMD

	  SET @CCMD = N'DELETE FROM  PO_PO_ADJ_MST_UPLOAD WHERE SP_ID= '''+@NSPID +''''
		
	 EXEC SP_EXECUTESQL @CCMD

	
	--EXEC SP_DROPTEMPTABLES_XNS 'XNSPO_ADJ',@NSPID
	
END						-- END OF SAVETRAN_PO_ADJ
------------------------------------------------------ END OF SAVETRAN_PO_ADJ


