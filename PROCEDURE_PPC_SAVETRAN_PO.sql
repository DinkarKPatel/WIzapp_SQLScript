CREATE PROCEDURE PPC_SAVETRAN_PO
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				INT,
	@CMEMONOPREFIX		VARCHAR(50),
	@CFINYEAR			VARCHAR(10),	
	@CXNMEMOID			VARCHAR(40)='',
	@NAPPROVEMODE		NUMERIC(1,0)=0,
	@CLOCID				VARCHAR(2)='',
	@CUSER_CODE         VARCHAR(10)=''
)
----WITH ENCRYPTION
AS
BEGIN
	-- @NUPDATEMODE:	1- NEW PUR ADDED, 
	--					2- NEW BOX ADDED TO EXISTING PUR, 
	--					3- CURRENT PUR CANCELLED, 
	--					4- EXISTING PUR EDITED

	DECLARE @CTEMPDBNAME			VARCHAR(100),
			@CMASTERTABLENAME		VARCHAR(100),
			@CINTERMIDIATETABLENAME		VARCHAR(100),
			@CTEMPITERMIDIATETABLENAME	VARCHAR(100),
			@CTEMPITERMIDIATETABLE	VARCHAR(100),
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
			@CMEMODEPTID			VARCHAR(2),
			@CLOCATIONID			VARCHAR(2),
			@CHODEPTID				VARCHAR(2),
			@CCMD					NVARCHAR(4000),
			@CCMDOUTPUT				NVARCHAR(4000),
			@NSAVETRANLOOP			BIT,
			@NSTEP					INT,
			@LENABLETEMPDATABASE	BIT,
			--DECLARE VARIABLE BY JAI RAM
			@CPOTERMSMASTER         VARCHAR(50),
			@CPOTERMSTEMP           VARCHAR(50)

	DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))

	SET @NSTEP = 0		-- SETTTING UP ENVIRONMENT

	
	SET @CTEMPDBNAME = ''

	SET @CMASTERTABLENAME	= 'PPC_POM01106'
	SET @CDETAILTABLENAME1	= 'PPC_POD01106'
	--CHANGE BY JAI RAM KUMAR
	SET @CPOTERMSMASTER='PPC_PO_TERMS'
	SET @CPOTERMSTEMP='PO_PPC_PO_TERMS_UPLOAD'

	
	--SET @CDETAILTABLENAME2	= 'MOH01106'

	--SET @CTEMPMASTERTABLENAME	= 'TEMP_PRD_POM01106_'+LTRIM(RTRIM(STR(@NSPID)))
	--SET @CTEMPDETAILTABLENAME1	= 'TEMP_PRD_POD01106_'+LTRIM(RTRIM(STR(@NSPID)))
	--SET @CTEMPITERMIDIATETABLENAME	= 'TEMP_PRD_PO_WSL_'+LTRIM(RTRIM(STR(@NSPID)))	
	--SET @CTEMPDETAILTABLENAME2	= 'TEMP_MOH01106_'+LTRIM(RTRIM(STR(@NSPID)))
	SET @CTEMPMASTERTABLE	='PO_PPC_POM01106_UPLOAD'
	SET @CTEMPDETAILTABLE1	= 'PO_PPC_POD01106_UPLOAD'

	
	SET @CERRORMSG			= ''
	SET @LDONOTUPDATESTOCK	= 0
	SET @CKEYFIELD1			= 'PO_ID'
	SET @CMEMONO			= 'PO_NO'
	
	
	IF ISNULL(@CLOCID,'')=''
		SELECT @CLOCATIONID		= [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	ELSE
		SELECT @CLOCATIONID=@CLOCID
	
	SELECT @CHODEPTID		= [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'		
	
    IF ISNULL(@CMEMONOPREFIX,'')=''
    SET @CMEMONOPREFIX=@CLOCATIONID
    
	BEGIN TRY
	BEGIN TRANSACTION
		
		IF @NUPDATEMODE=4
			GOTO LBLAPPROVEPO
			
		IF @NUPDATEMODE = 3			
		BEGIN
			SET @NSTEP = 10
			
			IF @CXNMEMOID=''
			BEGIN
				SET @CERRORMSG='MEMO ID REQUIRED FOR CANCELLATION........CANNOT PROCEED'
				GOTO END_PROC
			END
			
						
			IF OBJECT_ID ('TEMPDB..#TMPPO','U') IS NOT NULL
			   DROP TABLE #TMPPO
			 
			SELECT DISTINCT A.PO_ID  
			INTO #TMPPO
			FROM PPC_POD01106 A JOIN PPC_POM01106 B ON A.PO_ID=B.PO_ID
			JOIN PPC_PID01106 C ON A.ROW_ID =C.PO_ROW_ID 
			JOIN PPC_PIM01106 D ON C.MRR_ID=D.MRR_ID
			WHERE D.CANCELLED =0 AND B.PO_ID=@CXNMEMOID

            IF EXISTS (SELECT TOP 1 'U' FROM #TMPPO)
            BEGIN
                 SET @CERRORMSG='PURCHASE HAS BEEN GENERATED........CANNOT CANCELLED'
				 GOTO END_PROC
            END

			SET @NSTEP = 13
			-- UPDATING SENTTOHO FLAG
			SET @CCMD = N' UPDATE ' + @CMASTERTABLENAME + ' SET CANCELLED = 1,LAST_UPDATE=GETDATE() ' + 
						N' WHERE ' + @CKEYFIELD1 + ' = ''' + @CXNMEMOID + ''' '
			--PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CKEYFIELDVAL1=@CXNMEMOID
			
			GOTO END_PROC
		END
		
		
		
		SET @NSTEP=15
		
		-- GETTING DEPT_ID FROM TEMP MASTER TABLE
		SET @CCMD = 'SELECT @CMEMODEPTID = DEPT_ID, @CKEYFIELDVAL1 = PO_ID FROM ' + @CTEMPMASTERTABLE +' WHERE SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
		EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(2) OUTPUT, @CKEYFIELDVAL1 VARCHAR(50) OUTPUT', 
								  @CMEMODEPTID OUTPUT, @CKEYFIELDVAL1 OUTPUT
		IF (@CMEMODEPTID IS NULL )
		BEGIN
			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED...'
			  --SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'
			  GOTO END_PROC  		
		END
		
		SET @NMEMONOLEN	= LEN(@CMEMONOPREFIX)+6
		
		-- START UPDATING XN TABLES	
		IF @NUPDATEMODE = 1 -- ADDMODE	
		BEGIN	

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
											AND FIN_YEAR = '''+@CFINYEAR+'''  )
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

				-- GENERATING NEW PO ID
				SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))
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

				-- UPDATING NEWLY GENERATED PO NO AND PO ID IN POM AND POD TEMP TABLES
				SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' + 
							@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE   SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
				EXEC SP_EXECUTESQL @CCMD
			
				SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE  SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
				EXEC SP_EXECUTESQL @CCMD
				
				
				--CHENGES BY JAI RAM KUMAR
                SET @CCMD = 'UPDATE ' + @CPOTERMSTEMP + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE  SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
				EXEC SP_EXECUTESQL @CCMD				
				--
		
			END
			
			

		END					-- END OF ADDMODE
		ELSE				-- CALLED FROM EDITMODE
		BEGIN				-- START OF EDITMODE
		
			SET @NSTEP = 50		-- GETTING ID INFO FROM TEMP TABLE

			-- GETTING PO_ID WHICH IS BEING EDITED
			SET @CCMD = 'SELECT @CKEYFIELDVAL1 = PO_ID, @CMEMONOVAL = PO_NO FROM ' + @CTEMPMASTERTABLE +' WHERE   SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
			EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT', 
							   @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT
							   
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO END_PROC
				END

			
			SET @NSTEP = 60		-- UPDATING SENT_TO_HO FLAG TEMP TABLE
			
			-- UPDATING SENTTOHO FLAG
			SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET LAST_UPDATE=GETDATE() WHERE   SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CCMD = 'UPDATE ' + @CPOTERMSTEMP + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE  SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''' '
		    EXEC SP_EXECUTESQL @CCMD		
				
		END					-- END OF EDITMODE

		SET @NSTEP = 95

		-- CHECK WETHER THE MEMO ID IS STILL LATER
		IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
			GOTO END_PROC
		END
		
		DECLARE @FILTER VARCHAR(MAX)
	    SET @FILTER=' B.SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
	    

		-- UPDATING MASTER TABLE (PIM01106) FROM TEMP TABLE
		SET @NSTEP = 100		-- UPDATING MASTER TABLE

		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = @CTEMPMASTERTABLE
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@FILTER
			
	   ---CHANGE BY JAI RAM 
	    SET @CCMD='DELETE FROM '+@CPOTERMSMASTER+' WHERE PO_ID='''+@CKEYFIELDVAL1+''''
	    EXEC SP_EXECUTESQL @CCMD
	    
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = @CPOTERMSTEMP
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CPOTERMSMASTER
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
			,@CFILTERCONDITION=@FILTER
	    
	    
			
		-- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE
		SET @NSTEP = 110		-- UPDATING TRANSACTION TABLE

			-- UPDATING ROW_ID IN TEMP TABLES
			SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
						  WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID='''+LTRIM(RTRIM(STR(@NSPID)))+''''
			EXEC SP_EXECUTESQL @CCMD

			-- DELETING EXISTING ENTRIES FROM PID01106 TABLE WHERE ROW_ID NOT FOUND IN TEMPTABLE
			SET @NSTEP = 114		-- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES
            
            
            IF @NUPDATEMODE =2
            BEGIN
				IF OBJECT_ID ('TEMPDB..#TMPPOEDIT','U') IS NOT NULL
				   DROP TABLE #TMPPOEDIT
				   
				
				SELECT ROW_ID,SUM(QUANTITY) AS PO_QTY,PI_QTY 
				INTO #TMPPOEDIT
				FROM PPC_POM01106 A
				JOIN PPC_POD01106 B ON A.PO_ID=B.PO_ID
				LEFT JOIN
				(
				 SELECT PO_ROW_ID ,SUM(QUANTITY) AS PI_QTY
				 FROM PPC_PID01106 A
				 JOIN PPC_PIM01106 B ON A.MRR_ID=B.MRR_ID
				 WHERE B.CANCELLED=0
				 GROUP BY PO_ROW_ID
				
				) PID ON B.ROW_ID=PID.PO_ROW_ID 
				WHERE A.CANCELLED=0
				AND A.PO_ID=@CKEYFIELDVAL1
				GROUP BY ROW_ID,PI_QTY
				HAVING ISNULL(PI_QTY,0)>SUM(QUANTITY)
				
				 IF EXISTS (SELECT TOP 1 'U' FROM #TMPPOEDIT)
				BEGIN
					 SET @CERRORMSG='PURCHASE HAS BEEN GENERATED........PLEASE CHECK'
					 GOTO END_PROC
				END
            
                DECLARE @NEDITAPPROVESTATUS  INT,@NEDITNONAPPROVESTATUS INT,@NAPPROVE INT
                
                SELECT @NAPPROVE=ISNULL(APPROVED,0) FROM PPC_POM01106 WHERE PO_ID=@CKEYFIELDVAL1
                IF @NAPPROVE IS NULL
                SET @NAPPROVE=0
                
				SELECT @NEDITAPPROVESTATUS=A.VALUE  
				FROM USER_ROLE_DET A
				JOIN USER_ROLE_MST B ON A.ROLE_ID =B.ROLE_ID 
				JOIN USERS USR ON USR.ROLE_ID =B.ROLE_ID 
				WHERE GROUP_NAME='PURCHASE' AND FORM_NAME ='PO.ASPX'
				AND FORM_OPTION='APPROVE'   
				AND USR.USER_CODE =@CUSER_CODE AND  @CUSER_CODE<>'0000000'
				
				
               IF ISNULL(@NAPPROVE,0)=1 AND ISNULL(@NEDITAPPROVESTATUS,0)<>1
               BEGIN
                   SET @CERRORMSG='USER DOES NOT ACCESS TO ALLOW APPROVED PO..'
				   GOTO END_PROC
               END
               
            
            
            END
			   
			SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME1 + ' 
						WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''' ' 
			EXEC SP_EXECUTESQL @CCMD

			-- INSERTING/UPDATING THE ENTRIES IN PID01106 TABLE FROM TEMPTABLE
			SET @NSTEP = 115		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES

           
			EXEC UPDATEMASTERXN 
				  @CSOURCEDB	= ''
				, @CSOURCETABLE = @CTEMPDETAILTABLE1
				, @CDESTDB		= ''
				, @CDESTTABLE	= @CDETAILTABLENAME1
				, @CKEYFIELD1	= 'ROW_ID'
				, @BALWAYSUPDATE = 1
				,@CFILTERCONDITION=@FILTER
			
			SET @NSTEP = 120		-- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES
			-- UPDATING ROW_ID IN TEMP TABLES
	
         ---CHANGE BY JAI RAM 
			SET @CCMD='DELETE FROM '+@CPOTERMSMASTER+' WHERE PO_ID='''+@CKEYFIELDVAL1+''''
			EXEC SP_EXECUTESQL @CCMD
		    
			EXEC UPDATEMASTERXN 
				  @CSOURCEDB	= ''
				, @CSOURCETABLE = @CPOTERMSTEMP
				, @CDESTDB		= ''
				, @CDESTTABLE	= @CPOTERMSMASTER
				, @CKEYFIELD1	= @CKEYFIELD1
				, @BALWAYSUPDATE = 1
				,@CFILTERCONDITION=@FILTER


								
		GOTO END_PROC

LBLAPPROVEPO:

		IF @CXNMEMOID=''
		BEGIN
			SET @CERRORMSG='MEMO ID REQUIRED FOR APPROVAL......CANNOT PROCEED'
			GOTO END_PROC
		END
		
		SET @NSTEP = 180
		DECLARE @NAPPROVALSTATUS NUMERIC(1,0)
		
		
		--SELECT * FROM PPC_MODULES WHERE GROUP_NAME='PURCHASE' AND FORM_NAME ='PO.ASPX'
		--AND  FORM_OPTION='APPROVE'
		IF @CUSER_CODE='0000000'
		SET @NAPPROVALSTATUS=1
		ELSE
		SELECT @NAPPROVALSTATUS=A.VALUE  FROM USER_ROLE_DET A
		JOIN USER_ROLE_MST B ON A.ROLE_ID =B.ROLE_ID 
		JOIN USERS USR ON USR.ROLE_ID =B.ROLE_ID 
		WHERE GROUP_NAME='PURCHASE' AND FORM_NAME ='PO.ASPX'
		AND  FORM_OPTION='APPROVE' AND USR.USER_CODE =@CUSER_CODE
		
		IF ISNULL(@NAPPROVALSTATUS,0)=1 
		BEGIN
		UPDATE PPC_POM01106 SET  APPROVED=1,LAST_UPDATE=GETDATE(),APPROVED_BY=@CUSER_CODE
		WHERE PO_ID=@CXNMEMOID
		END
		ELSE
		BEGIN
             SET @CERRORMSG='USER HAS NOT ACCESS TO APPROVE PO.'
			 GOTO END_PROC
		END
			
		 
				
 		SET @CKEYFIELDVAL1=@CXNMEMOID
		
		GOTO END_PROC
		
		
	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
				
		GOTO END_PROC
	END CATCH
	
END_PROC:

	
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''
		   BEGIN  
			COMMIT TRANSACTION
		   END
		ELSE
			ROLLBACK
	END

	INSERT @OUTPUT ( ERRMSG, MEMO_ID)
			VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,'') )

	SELECT * FROM @OUTPUT
	
	SELECT @CMEMONOVAL AS PO_NO, @CKEYFIELDVAL1 AS PO_ID
	
	IF @CERRORMSG=''
	BEGIN
	    DELETE FROM PO_PPC_POM01106_UPLOAD WHERE SP_ID=LTRIM(RTRIM(STR(@NSPID)))
	    DELETE FROM PO_PPC_POD01106_UPLOAD WHERE SP_ID=LTRIM(RTRIM(STR(@NSPID)))
	    DELETE FROM PO_PPC_PO_TERMS_UPLOAD WHERE SP_ID=LTRIM(RTRIM(STR(@NSPID)))
	END
	
END						
------------------------------------------------------ END OF PROCEDURE SAVETRAN_PO
