CREATE PROCEDURE SAVETRAN_PRD_PRT
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				INT=0,
	@CMEMONOPREFIX		VARCHAR(50)='',
	@CFINYEAR			VARCHAR(10)='',
	@CMACHINENAME		VARCHAR(100)='',
	@CWINDOWUSERNAME	VARCHAR(100)='',
	@CWIZAPPUSERCODE	VARCHAR(10)='0000000',
	@CMEMOID			VARCHAR(40)='',
	@NPRTMODE			INT=1,-- 1.SINGLE DEBIT NOTE,2.MULTIPLE DEBIT NOTE
	@CPRTCONFIGMODE		VARCHAR(2)='1', -- 1.PARTY & BILL NO. WISE 2.PARTY WISE,
	@NAPPROVEMODE		NUMERIC(1,0)=0,
	@CCOMPUTERIP		VARCHAR(20)='',
	@CLOCID				VARCHAR(2)=''
)
--WITH ENCRYPTION
AS
BEGIN
	-- @NUPDATEMODE:	1- NEW PURCHASE RETURN ADDED, 
	--					2- NOT APPLICABLE, 
	--					3- CURRENT PURCHASE RETURN CANCELLED, 
	--					4- EXISTING PURCHASE RETURN EDITED

	DECLARE @CTEMPDBNAME			VARCHAR(100),
			@CMASTERTABLENAME		VARCHAR(100),
			@CDETAILTABLENAME		VARCHAR(100),
			@CTEMPMASTERTABLENAME	VARCHAR(100),
			@CTEMPDETAILTABLENAME	VARCHAR(100),
			@CTEMPMASTERTABLE		VARCHAR(100),
			@CTEMPDETAILTABLE		VARCHAR(100),
			@CTEMPMULTIDNTABLENAME	VARCHAR(200),
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
			@BNEGSTOCKFOUND BIT,
			@CNEXTACCODE CHAR(10),@CNEXTBILLNO VARCHAR(30),@CSTATUSMSG VARCHAR(1000),
			@CFIRSTDNNO VARCHAR(20),@CLASTDNNO VARCHAR(20),@NMULTIDNCNT INT,@CNEXTFORMID CHAR(7),@CCURLOCID VARCHAR(5),
			@CBATCHNOVAL VARCHAR(10),@CDNACCODE CHAR(10),@NOPENINGBAL NUMERIC(14,2),@DDNDATE DATETIME,
			@NDNSUPPLIERAMOUNT NUMERIC(10,2),@BDRACCOUNTSTATUSCHECKED BIT,@BCANCELLED BIT,
			@BCHECKACSTATUS BIT
			

	DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100),STATUSMSG VARCHAR(1000))
	DECLARE @STOCKCHECKC TABLE ( PRODUCT_UID VARCHAR(50), DEPARTMENT_ID VARCHAR(7), QUANTITY NUMERIC(10,3) )

	SELECT @NSTEP = 0,@NMULTIDNCNT=0	-- SETTTING UP ENVIRONMENT
	
	SET @BCHECKACSTATUS=0
	
	SET @CTEMPDBNAME = ''
	
	SET	@NSTEP = 2
	
	SET @CMASTERTABLENAME	= 'PRD_RMM01106'
	SET @CDETAILTABLENAME	= 'PRD_RMD01106'
		
	SET @CTEMPMASTERTABLENAME	= 'TEMP_PRD_RMM01106_'+LTRIM(RTRIM(STR(@NSPID)))
	SET @CTEMPDETAILTABLENAME	= 'TEMP_PRD_RMD01106_'+LTRIM(RTRIM(STR(@NSPID)))
	
	SET @CTEMPMASTERTABLE	= @CTEMPDBNAME + @CTEMPMASTERTABLENAME
	SET @CTEMPDETAILTABLE	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME

	
	SET	@NSTEP = 3

	SELECT TOP 1 @CCURLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'

	
	BEGIN TRY	

		BEGIN TRANSACTION

		IF ISNULL(@CLOCID,'')=''
			SELECT @CLOCATIONID		= [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
		ELSE
			SELECT @CLOCATIONID=@CLOCID
		
		SELECT @CHODEPTID		= [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'		
		
	
		IF @NUPDATEMODE = 3					
			GOTO LBLSTART
		
		IF @NUPDATEMODE=4
			GOTO LBLAPPROVEPRT
					
		IF OBJECT_ID('TEMPDB..#TMPDNSUPPLIER','U') IS NOT NULL
			DROP TABLE #TMPDNSUPPLIER
		
		SELECT AC_CODE,CONVERT(BIT,0) AS CANCELLED INTO #TMPDNSUPPLIER FROM LM01106 WHERE 1=2	
		
		LBLGENMULTIDN:
		--IF @NPRTMODE=2
		--BEGIN	
		--	IF ISNULL(@CNEXTACCODE,'')=''
		--	BEGIN
		--		SET	@NSTEP = 4
				
									
		--		SET @CTEMPMULTIDNTABLENAME	= 'TEMP_RMD01106_MULTI_'+LTRIM(RTRIM(STR(@NSPID)))
					
		--		SET @CCMD=N'IF OBJECT_ID('''+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+''',''U'') IS NOT NULL
		--						DROP TABLE 	'+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME
		--		EXEC SP_EXECUTESQL @CCMD

		--		SET @CCMD=N'IF OBJECT_ID('''+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+'_ORG'',''U'') IS NOT NULL
		--						DROP TABLE 	'+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+'_ORG'
		--		EXEC SP_EXECUTESQL @CCMD
								
		--		SET	@NSTEP = 5
				
		--		SET @CCMD=N'SELECT * INTO '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+' FROM '+@CTEMPDETAILTABLE
		--		PRINT @CCMD
		--		EXEC SP_EXECUTESQL @CCMD

		--		SET @CCMD=N'SELECT * INTO '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+'_ORG FROM '+@CTEMPDETAILTABLE
		--		EXEC SP_EXECUTESQL @CCMD

		--		-- GENERATING NEW MULTIPLE DEBIT NOTE BATCH NO		
		--		SET @NSAVETRANLOOP=0
		--		WHILE @NSAVETRANLOOP=0
		--		BEGIN
		--			SET	@NSTEP = 7
		--			EXEC GETNEXTKEY @CMASTERTABLENAME,'BATCH_NO',7,@CCURLOCID, 1,@CFINYEAR,0, @CBATCHNOVAL OUTPUT   
					
		--			SET	@NSTEP = 10
		--			SET @CCMD=N'IF EXISTS ( SELECT BATCH_NO FROM RMM01106 WHERE BATCH_NO='''+@CBATCHNOVAL+''' 
		--									AND FIN_YEAR = '''+@CFINYEAR+''' )
		--							SET @NLOOPOUTPUT=0
		--						ELSE
		--							SET @NLOOPOUTPUT=1'
		--			PRINT @CCMD
		--			EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT
		--		END

		--		IF @CBATCHNOVAL IS NULL  
		--		BEGIN
		--			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT BATCH NO....'	
		--			  GOTO END_PROC  		
		--		END

		--		SET @CCMD=N'SELECT DISTINCT B.AC_CODE,0 AS CANCELLED FROM '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+' A 
		--					JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE'
							
		--		INSERT #TMPDNSUPPLIER			
		--		EXEC SP_EXECUTESQL @CCMD			
		--	END
			
			
		--	SET	@NSTEP = 12
			
		--	SET @CNEXTACCODE=''
				
		--	SET @CCMD=N' SELECT TOP 1 @CNEXTACCODEOUT=B.AC_CODE,@CNEXTBILLNOOUT=B.INV_NO,@CNEXTFORMIDOUT=B.FORM_ID
		--				 FROM '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+' A JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE'				
		--	EXEC SP_EXECUTESQL @CCMD,N'@CNEXTACCODEOUT CHAR(10) OUTPUT,@CNEXTBILLNOOUT VARCHAR(30) OUTPUT,
		--					   @CNEXTFORMIDOUT CHAR(7) OUTPUT	',@CNEXTACCODEOUT=@CNEXTACCODE OUTPUT,
		--					   @CNEXTBILLNOOUT=@CNEXTBILLNO OUTPUT,@CNEXTFORMIDOUT=@CNEXTFORMID OUTPUT
			
		--	IF ISNULL(@CNEXTACCODE,'')=''
		--	BEGIN
		--		SET @CLASTDNNO=@CMEMONOVAL
				
		--		-- AFTER SUCCESSFUL SAVING , JUST DROP THE TEMP TABLES CREATED BY APPLICATION
		--		SET @NSTEP = 14
		
				
		--		GOTO END_PROC
		--	END
			
		--	SET	@NSTEP = 15
			
		--	SET @NMULTIDNCNT=@NMULTIDNCNT+1
					
		--	SET @CCMD=N'DROP TABLE '+@CTEMPDETAILTABLE
		--	EXEC SP_EXECUTESQL @CCMD
			
		--	SET	@NSTEP = 17
			
		--	SET @CCMD=N'SELECT A.* INTO '+@CTEMPDETAILTABLE+' FROM '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+' A JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
		--				 WHERE B.AC_CODE='''+@CNEXTACCODE+''''+(CASE WHEN @CPRTCONFIGMODE='2' THEN '' ELSE
		--			   ' AND B.INV_NO='''+@CNEXTBILLNO+'''' END)	 
		--	EXEC SP_EXECUTESQL @CCMD
			
		--	SET	@NSTEP = 19
			
		--	SET @CCMD=N' DELETE FROM '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+' WHERE PRODUCT_CODE IN (SELECT PRODUCT_CODE FROM '+
		--			     @CTEMPDETAILTABLE+')'
		--	EXEC SP_EXECUTESQL @CCMD
			
		--	SET	@NSTEP = 21
			
		--	SET @CCMD=N'UPDATE '+@CTEMPMASTERTABLE+' SET AC_CODE='''+@CNEXTACCODE+''',FORM_ID='''+@CNEXTFORMID+''',
		--				BATCH_NO='''+@CBATCHNOVAL+''',SUBTOTAL=B.SUBTOTAL,DISCOUNT_AMOUNT=B.DISCOUNT_AMOUNT,
		--				TAX_AMOUNT=B.TAX_AMOUNT,
		--				DISCOUNT_PERCENTAGE=(CASE WHEN B.SUBTOTAL<>0 THEN (B.DISCOUNT_AMOUNT/B.SUBTOTAL)*100 ELSE 0 END),
		--				TAX_PERCENTAGE=(CASE WHEN B.SUBTOTAL<>0 THEN (B.TAX_AMOUNT/(B.SUBTOTAL-B.DISCOUNT_AMOUNT))*100 ELSE 0 END),
		--				OTHER_CHARGES=B.OTHER_CHARGES,FREIGHT=B.FREIGHT,
		--				TOTAL_AMOUNT=B.SUBTOTAL-B.DISCOUNT_AMOUNT+B.TAX_AMOUNT+B.OTHER_CHARGES+B.FREIGHT,
		--				EXCISE_DUTY_AMOUNT=B.EXCISE_DUTY_AMOUNT  
 	--					FROM (SELECT SUM(B.PURCHASE_PRICE*QUANTITY) AS SUBTOTAL,SUM(QUANTITY) AS QUANTITY,
		--					  SUM(ISNULL(C.DISCOUNT_AMOUNT,0)*A.QUANTITY) AS DISCOUNT_AMOUNT,
		--					  SUM(ISNULL(C.TAX_AMOUNT,0)*A.QUANTITY) AS TAX_AMOUNT,
		--					  SUM(ISNULL(C.OTHER_CHARGES,0)*A.QUANTITY) AS OTHER_CHARGES,
		--					  SUM(ISNULL(C.FREIGHT,0)*A.QUANTITY) AS FREIGHT,
		--					  SUM(ISNULL(C.EXCISE_DUTY_AMOUNT,0)*A.QUANTITY) AS [EXCISE_DUTY_AMOUNT]
		--					  FROM '+@CTEMPDETAILTABLE+' A JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
		--					  LEFT OUTER JOIN SKU_OH C ON C.PRODUCT_CODE=B.PRODUCT_CODE) B'						  						
		--	PRINT @CCMD							  
		--	EXEC SP_EXECUTESQL @CCMD
			
		--END
		
		--ELSE
		--BEGIN
		--	SET @CCMD=N'SELECT A.AC_CODE,0 AS CANCELLED FROM '+@CTEMPMASTERTABLE+' A '
			
						
		--	INSERT #TMPDNSUPPLIER			
		--	EXEC SP_EXECUTESQL @CCMD			
		--END
		
		
		
		---- CHECK FOR OVERALL DEBIT BALANCE OF SUPPLIER BASED UPON WHICH 
		---- THAT SUPPLIER'S DEBIT NOTE WILL BE SAVED AS CANCELLED IN CASE OF MULTIPLE DEBITNOTES
		---- AND NOT ALLOWED TO SAVE IN CASE OF SINGLE DEBIT NOTE
		
		IF @BCHECKACSTATUS=0  OR @BDRACCOUNTSTATUSCHECKED=1
			GOTO LBLSTART
			 
		SET @CCMD=N'SELECT TOP 1 @DDNDATEOUT=RM_DT FROM '+@CTEMPMASTERTABLE
		EXEC SP_EXECUTESQL @CCMD,N'@DDNDATEOUT DATETIME OUTPUT',@DDNDATEOUT=@DDNDATE OUTPUT
		
		DECLARE SUPPLIERCUR CURSOR FOR SELECT AC_CODE FROM #TMPDNSUPPLIER
		OPEN SUPPLIERCUR
		FETCH NEXT FROM SUPPLIERCUR INTO @CDNACCODE
		WHILE @@FETCH_STATUS=0
		BEGIN
			SELECT @NOPENINGBAL=0 --- Use alternative of fn_act_closing
			--commented use of function as it will slow down our cloud (28-01-2021)
			
			IF @NPRTMODE=2
				SET @CCMD=N'SELECT @NDNSUPPLIERAMOUNTOUT= B.SUBTOTAL-B.DISCOUNT_AMOUNT+B.TAX_AMOUNT+B.OTHER_CHARGES+B.FREIGHT
							FROM (SELECT SUM(B.PURCHASE_PRICE*QUANTITY) AS SUBTOTAL,SUM(QUANTITY) AS QUANTITY,
							  SUM(ISNULL(C.DISCOUNT_AMOUNT,0)*A.QUANTITY) AS DISCOUNT_AMOUNT,
							  SUM(ISNULL(C.TAX_AMOUNT,0)*A.QUANTITY) AS TAX_AMOUNT,
							  SUM(ISNULL(C.OTHER_CHARGES,0)*A.QUANTITY) AS OTHER_CHARGES,
							  SUM(ISNULL(C.FREIGHT,0)*A.QUANTITY) AS FREIGHT
							  FROM '+@CTEMPDBNAME+@CTEMPMULTIDNTABLENAME+'_ORG A JOIN PRD_SKU B ON A.PRODUCT_UID=B.PRODUCT_UID
							  LEFT OUTER JOIN PRD_SKU_OH C ON C.PRODUCT_UID=B.PRODUCT_UID
							  WHERE B.AC_CODE='''+@CDNACCODE+''') B'						  						
			ELSE
				SET @CCMD=N'SELECT @NDNSUPPLIERAMOUNTOUT= TOTAL_AMOUNT FROM '+@CTEMPMASTERTABLE
			
			EXEC SP_EXECUTESQL @CCMD,N'@NDNSUPPLIERAMOUNTOUT NUMERIC(14,2) OUTPUT',@NDNSUPPLIERAMOUNTOUT=@NDNSUPPLIERAMOUNT OUTPUT			  
			
			IF @NOPENINGBAL+@NDNSUPPLIERAMOUNT>0
			BEGIN
				IF @NPRTMODE=2
					UPDATE #TMPDNSUPPLIER SET CANCELLED=1 WHERE AC_CODE=@CDNACCODE
				ELSE
				BEGIN
					SET @CERRORMSG='A/C BALANCE OF SUPPLIER GOING NEGATIVE :'+ISNULL(@CDNACCODE,'NULL DNACCODE')+'-'+
									ISNULL(@CCURLOCID,'NULLLOCID')+'-'+
									ISNULL(CONVERT(VARCHAR,@DDNDATE,110),'NULLDATE')+'-'+LTRIM(RTRIM(STR(@NOPENINGBAL)))+'-'+
									LTRIM(RTRIM(STR(@NDNSUPPLIERAMOUNT)))+' .....CANNOT PROCEED' 	
					GOTO END_PROC
				END	
			END
			
			SET @BDRACCOUNTSTATUSCHECKED=1
			FETCH NEXT FROM SUPPLIERCUR INTO @CDNACCODE
		END
		CLOSE SUPPLIERCUR
		DEALLOCATE SUPPLIERCUR
		
		LBLSTART:
		
		SET @CERRORMSG			= ''
		SET @LDONOTUPDATESTOCK	= 0
		SET @CKEYFIELD1			= 'RM_ID'
		SET @CMEMONO			= 'RM_NO'
		SET @NMEMONOLEN			= 10
		
		IF @NUPDATEMODE<>3 
		BEGIN
			SET @NSTEP = 24
			
			--EXEC SP_VALIDATEXN_BEFORESAVE 'PRT',@NSPID,'0000000',@NUPDATEMODE,@CCMDOUTPUT OUTPUT,@BNEGSTOCKFOUND OUTPUT
			--IF ISNULL(@CCMDOUTPUT,'') <> ''
			--BEGIN
			--	SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION ON TEMP DATA FAILED : ' + @CCMDOUTPUT + '...'
			--	GOTO END_PROC
			--END
		END

LBLCHKCANCEL:	
		
		IF @NUPDATEMODE = 3 AND ISNULL(@CMEMOID,'') = ''
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID REQUIRED IF CALLED FROM CANCELLATION'
			GOTO END_PROC  		
		END
		
		SET @NSTEP = 26
		
		-- GETTING DEPT_ID FROM TEMP MASTER TABLE
		SET @CCMD = 'SELECT @CMEMODEPTID = LEFT(RM_NO,2) FROM ' 
					+ (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME ELSE @CTEMPMASTERTABLE END )
		
		EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(2) OUTPUT', 
						   @CMEMODEPTID OUTPUT
		IF (@CMEMODEPTID IS NULL )
		BEGIN
			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'
			  GOTO END_PROC  		
		END

		-- START UPDATING XN TABLES	
		IF @NUPDATEMODE = 1 -- ADDMODE	
		BEGIN	
			
			-- GENERATING NEW DEBIT NOTE NO		
			SET @NSAVETRANLOOP=0
			WHILE @NSAVETRANLOOP=0
			BEGIN
				
				SET @NSTEP = 28		-- GENERATING NEW KEY

				EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,
								@CFINYEAR,0, @CMEMONOVAL OUTPUT   
				
				PRINT @CMEMONOVAL
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

			-- GENERATING NEW JOB ORDER ID
			SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
				  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'
				  GOTO END_PROC
			END

			SET @NSTEP = 40		-- UPDATING NEW ID INTO TEMP TABLES

			-- UPDATING NEWLY GENERATED JOB ORDER NO AND JOB ORDER ID IN PIM AND PID TEMP TABLES
			SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' + 
						@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''''
			EXEC SP_EXECUTESQL @CCMD
		
			SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''''
			EXEC SP_EXECUTESQL @CCMD
			
			IF @NPRTMODE=2 AND ISNULL(@CFIRSTDNNO,'')=''
				SET @CFIRSTDNNO=@CMEMONOVAL

		END					-- END OF ADDMODE
		ELSE				-- CALLED FROM EDITMODE
		BEGIN				-- START OF EDITMODE
		
			SET @NSTEP = 50		-- GETTING ID INFO FROM TEMP TABLE

			-- GETTING JOB ORDER ID WHICH IS BEING EDITED
			SET @CCMD = 'SELECT @CKEYFIELDVAL1 = ' + @CKEYFIELD1 + ', @CMEMONOVAL = ' + @CMEMONO + ' FROM ' 
						+ (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME + ' WHERE RM_ID = ''' + @CMEMOID + '''' 
								ELSE @CTEMPMASTERTABLE END )

			EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT', 
							   @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT
			IF (@CKEYFIELDVAL1 IS NULL ) OR (@CMEMONOVAL IS NULL )
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'
				  GOTO END_PROC  		
			END
			
			SET @NSTEP = 55		-- STORING OLD STATUS OF BARCODES 

			INSERT @STOCKCHECKC ( PRODUCT_UID, DEPARTMENT_ID, QUANTITY )
			SELECT A.PRODUCT_UID,B.DEPARTMENT_ID, SUM(A.QUANTITY) AS QUANTITY 
			FROM PRD_RMD01106 A 
			JOIN PRD_RMM01106 B ON B.RM_ID=A.RM_ID
			WHERE B.RM_ID = @CKEYFIELDVAL1
			GROUP BY A.PRODUCT_UID, B.DEPARTMENT_ID
			
	
			IF @NUPDATEMODE = 3			
			BEGIN
			
				SET @NSTEP = 60
			
				-- UPDATING SENTTOHO FLAG
				SET @CCMD = N'UPDATE ' + @CMASTERTABLENAME + ' SET CANCELLED = 1,SENT_TO_HO = 0, POSTEDINAC = 0,LAST_UPDATE=GETDATE() 
							  WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''''
				EXEC SP_EXECUTESQL @CCMD
				
			END
			
			ELSE
			BEGIN	
				SET @NSTEP = 65
				-- UPDATING SENTTOHO FLAG
				SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET SENT_TO_HO = 0, POSTEDINAC = 0,LAST_UPDATE=GETDATE() '
				EXEC SP_EXECUTESQL @CCMD
								
				-- ENTRY IN AUDIT TRAIL (ONLY WHEN USER EXPLICITLY CLICKED ON EDIT BUTTON)
				SET @NSTEP = 70		-- AUDIT TRIAL ENTRY
			
						
	 		--	 EXEC AUDITLOGENTRY
				--  @CXNTYPE		= 'PRT'
				--, @CXNID		= @CKEYFIELDVAL1
				--, @CDEPTID		= @CMEMODEPTID
				--, @CCOMPUTERNAME= @CMACHINENAME
				--, @CWINUSERNAME = @CWINDOWUSERNAME
				--, @CWIZUSERCODE = @CWIZAPPUSERCODE

			END
			
			-- REVERTING BACK THE STOCK OF PMT W.R.T CURRENT ISSUE
			SET @NSTEP = 80		-- REVERTING STOCK
			
			PRINT 'DEBIT NOTE ID :'+@CKEYFIELDVAL1
			EXEC UPDATEPMT_PRD 
				  @CXNTYPE			= 'PRT'
				, @CXNNO			= @CMEMONOVAL
				, @CXNID			= @CKEYFIELDVAL1
				, @NREVERTFLAG		= 1
				, @NALLOWNEGSTOCK	= 0
				, @NCHKDELBARCODES	= 1
				, @NUPDATEMODE		= @NUPDATEMODE
				, @CCMD				= @CCMDOUTPUT OUTPUT
			
			IF (@NUPDATEMODE = 3) 
			BEGIN
				IF @CCMDOUTPUT <> ''
				BEGIN
					SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT....'
					SET @BNEGSTOCKFOUND=1				
					EXEC SP_EXECUTESQL @CCMDOUTPUT
				END
					
				GOTO LBLVALIDATE
			END
		END					-- END OF EDITMODE

		SET @NSTEP = 95
		
		-- RECHECKING IF ID IS STILL LATER
		IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
			GOTO END_PROC
		END

		
		-- UPDATING MASTER TABLE (PIM01106) FROM TEMP TABLE
		SET @NSTEP = 100		-- UPDATING MASTER TABLE
			
		SET @CCMD=N'UPDATE '+@CTEMPMASTERTABLE+' SET DN_TYPE=1 WHERE DN_TYPE NOT IN (1,2)'
		EXEC SP_EXECUTESQL @CCMD

		SET @NSTEP = 103		-- UPDATING MASTER TABLE
			
		SET @CCMD=N'UPDATE '+@CTEMPMASTERTABLE+' SET PARTY_DEPT_ID=(CASE WHEN PARTY_DEPT_ID='''' THEN NULL ELSE PARTY_DEPT_ID END)'
		EXEC SP_EXECUTESQL @CCMD
		
		SET @NSTEP=105
		
		SET @CCMD=N'UPDATE A  SET CANCELLED=B.CANCELLED,REMARKS=(CASE WHEN B.CANCELLED=1 THEN
					''CANCELLED IN MULTIPLE DEBIT NOTE SAVING DUE TO NET DEBIT BALANCE STANDING...'' ELSE REMARKS END)
					 FROM '+@CTEMPMASTERTABLE+' A
					JOIN #TMPDNSUPPLIER B ON A.AC_CODE=B.AC_CODE '
		EXEC SP_EXECUTESQL @CCMD						
		
		SET @NSTEP=110
		
		SET @CCMD=N'SELECT @BCANCELLEDOUT=CANCELLED FROM '+@CTEMPMASTERTABLE
		EXEC SP_EXECUTESQL @CCMD,N'@BCANCELLEDOUT BIT OUTPUT',@BCANCELLEDOUT=@BCANCELLED OUTPUT
		
		SET @NSTEP=125
		
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPMASTERTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1

		-- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE
		SET @NSTEP = 130		-- UPDATING TRANSACTION TABLE

		-- UPDATING ROW_ID IN TEMP TABLES
		SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
					  WHERE LEFT(ROW_ID,5) = ''LATER'''
		EXEC SP_EXECUTESQL @CCMD

		-- DELETING EXISTING ENTRIES FROM PID01106 TABLE WHERE ROW_ID NOT FOUND IN TEMPTABLE
		SET @NSTEP = 135		-- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES

		SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME + ' 
					WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''
					AND ROW_ID IN 
					(
						SELECT A.ROW_ID 
						FROM ' + @CDETAILTABLENAME + ' A 
						LEFT OUTER JOIN ' + @CTEMPDETAILTABLE + ' B ON A.ROW_ID = B.ROW_ID
						WHERE A.' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''
						AND   B.ROW_ID IS NULL
					)'
		EXEC SP_EXECUTESQL @CCMD

		-- INSERTING/UPDATING THE ENTRIES IN PRD_JID TABLE FROM TEMPTABLE
		SET @NSTEP = 140		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES

		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME
			, @CKEYFIELD1	= 'ROW_ID'
			, @BALWAYSUPDATE = 1

		SET @NSTEP=142

	
		LBLUPDATEPMT:		
		IF @BCANCELLED=0
		BEGIN		
			
			-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
			SET @NSTEP = 145		-- UPDATING PMT TABLE
			
			EXEC UPDATEPMT_PRD 
				  @CXNTYPE			= 'PRT'
				, @CXNNO			= @CMEMONOVAL
				, @CXNID			= @CKEYFIELDVAL1
				, @NREVERTFLAG		= 0
				, @NALLOWNEGSTOCK	= 0
				, @NCHKDELBARCODES	= 1
				, @NUPDATEMODE		= @NUPDATEMODE
				, @CCMD				= @CCMDOUTPUT OUTPUT
			
			IF @CCMDOUTPUT <> ''
			BEGIN
				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT....'
				-- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'
				
				PRINT @CCMDOUTPUT
				EXEC SP_EXECUTESQL @CCMDOUTPUT
				
				SET @BNEGSTOCKFOUND=1
				
				GOTO END_PROC
			END
			
			-- RECHECKING FOR NEGATIVE STOCK FOR OLD BARCODES
			IF @NUPDATEMODE <> 1
			BEGIN
				SET @NSTEP = 150		
				IF EXISTS ( SELECT A.PRODUCT_UID FROM PRD_PMT A
							JOIN @STOCKCHECKC B ON A.PRODUCT_UID = B.PRODUCT_UID
												AND A.DEPARTMENT_ID = B.DEPARTMENT_ID 
							WHERE A.QUANTITY_IN_STOCK < 0 )
				BEGIN
					SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT (DELETED ITEMS)...'
					GOTO END_PROC
				END
			END
		END
		
		SET @NSTEP = 155
		DECLARE @NSUBTOTAL NUMERIC(14,2),@NTAX NUMERIC(10,2)
		
		
		-- UPDATING TOTALS IN RMM TABLE
		UPDATE A SET SUBTOTAL = ISNULL( B.SUBTOTAL ,0 )
		FROM PRD_RMM01106 A LEFT OUTER JOIN
		( 	
			SELECT	RM_ID, SUM(QUANTITY*PURCHASE_PRICE) AS SUBTOTAL
			FROM PRD_RMD01106 
			WHERE RM_ID = @CKEYFIELDVAL1
			GROUP BY RM_ID  
		) B ON  A.RM_ID = B.RM_ID  
		WHERE A.RM_ID = @CKEYFIELDVAL1

		UPDATE PRD_RMM01106 SET DISCOUNT_AMOUNT = ROUND(SUBTOTAL*DISCOUNT_PERCENTAGE/100,0)
		WHERE RM_ID= @CKEYFIELDVAL1
		
		SET @NSTEP = 160
		SELECT @NSUBTOTAL=SUBTOTAL FROM PRD_RMM01106 WHERE RM_ID= @CKEYFIELDVAL1
							
				
		UPDATE PRD_RMD01106 SET ITEM_TAX_PERCENTAGE=B.TAX_PERCENTAGE 
		FROM FORM B WHERE B.FORM_ID=PRD_RMD01106.ITEM_FORM_ID
		
		SET @NSTEP = 165
				
		
		
		UPDATE PRD_RMD01106 SET ITEM_TAX_AMOUNT = ((PURCHASE_PRICE*QUANTITY)-(PURCHASE_PRICE*QUANTITY*
		B.DISCOUNT_PERCENTAGE/100)+(((EXCISE_DUTY_AMOUNT+EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT)
		/@NSUBTOTAL)*PURCHASE_PRICE*QUANTITY))*PRD_RMD01106.ITEM_TAX_PERCENTAGE/100
		FROM PRD_RMM01106 B WHERE B.RM_ID=PRD_RMD01106.RM_ID AND PRD_RMD01106.RM_ID= @CKEYFIELDVAL1 AND PURCHASE_PRICE<>0
		AND QUANTITY<>0
					
					
		
		IF NOT EXISTS (SELECT TOP 1 PRODUCT_UID FROM PRD_RMD01106 WHERE RM_ID= @CKEYFIELDVAL1)
		BEGIN
			SET @NSTEP = 170
			UPDATE PRD_RMM01106 SET OTHER_CHARGES=0,EXCISE_DUTY_AMOUNT=0,FREIGHT=0
			WHERE RM_ID= @CKEYFIELDVAL1
		END
		
		
		SELECT @NTAX=SUM(ITEM_TAX_AMOUNT) FROM PRD_RMD01106 WHERE RM_ID=@CKEYFIELDVAL1
		
		SET @NSTEP = 180		
		UPDATE PRD_RMM01106 SET ROUND_OFF=ROUND((SUBTOTAL +ISNULL(@NTAX,0) +  OTHER_CHARGES + 
					 EXCISE_DUTY_AMOUNT+EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+FREIGHT ) - DISCOUNT_AMOUNT,0)-
					 (SUBTOTAL+ISNULL(@NTAX,0)+OTHER_CHARGES+FREIGHT+EXCISE_DUTY_AMOUNT+EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT-DISCOUNT_AMOUNT)
		WHERE RM_ID=@CKEYFIELDVAL1
		
		
			
		SET @NSTEP=190
		
		UPDATE PRD_RMM01106 SET TAX_AMOUNT=ISNULL(@NTAX,0),TOTAL_AMOUNT=(SUBTOTAL +ISNULL(@NTAX,0) +  OTHER_CHARGES + 
					 FREIGHT+EXCISE_DUTY_AMOUNT+EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+ROUND_OFF) - DISCOUNT_AMOUNT
		WHERE RM_ID=@CKEYFIELDVAL1
		

		EXEC UPDATERFNET_PRD 'PRT',@CKEYFIELDVAL1	
				
		LBLVALIDATE:		
		-- VALIDATING ENTRIES 
		SET @NSTEP = 200		-- VALIDATING ENTRIES

		EXEC VALIDATEXN_PRD_PRT			 
			 @CXNID	= @CKEYFIELDVAL1
			, @NUPDATEMODE = @NUPDATEMODE
			, @CERRORMSG		= @CCMDOUTPUT OUTPUT

		IF @CCMDOUTPUT <> ''
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION FAILED : ' + @CCMDOUTPUT + '...'
			GOTO END_PROC
		END
		
		--IF @NPRTMODE=2
		--	GOTO LBLGENMULTIDN
		
		GOTO END_PROC
		
LBLAPPROVEPRT:
		
		
		
		GOTO END_PROC
				
	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		
		GOTO END_PROC
	END CATCH
	
END_PROC:
	
	PRINT 'LAST STEP : '+STR(@NSTEP)	
	--IF @NPRTMODE=2
	--	SET @CSTATUSMSG=LTRIM(RTRIM(STR(@NMULTIDNCNT)))+' NO. OF DEBIT NOTES ('+@CFIRSTDNNO+'-'+@CLASTDNNO+') GENERATED'
	--SELECT * FROM PRD_PMT WHERE PRODUCT_UID='44CF81C5-E808-4979-9C85-EA4DC793FDD8'	
			
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''
			COMMIT TRANSACTION
			--ROLLBACK
		ELSE
			ROLLBACK	
	END	
	
	IF CURSOR_STATUS('GLOBAL','SUPPLIERCUR') IN (0,1)
	BEGIN
		CLOSE SUPPLIERCUR
		DEALLOCATE SUPPLIERCUR
	END
	
	IF ISNULL(@BNEGSTOCKFOUND,0)=0
	BEGIN
		INSERT @OUTPUT ( ERRMSG, MEMO_ID,STATUSMSG)
				VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,''),ISNULL(@CSTATUSMSG,'') )

		SELECT * FROM @OUTPUT	
	END	
	
    SET @CCMD = N'IF OBJECT_ID( ''' + @CTEMPDETAILTABLENAME + ''',''U'') IS NOT NULL
                  DROP TABLE ' + @CTEMPDETAILTABLENAME
	EXEC SP_EXECUTESQL @CCMD
	

    SET @CCMD = N'IF OBJECT_ID( ''' + @CTEMPMASTERTABLE + ''',''U'') IS NOT NULL
                  DROP TABLE ' + @CTEMPMASTERTABLE
	EXEC SP_EXECUTESQL @CCMD	

END						
------------------------------------------------------ END OF PROCEDURE SAVETRAN_PRD_PRT
