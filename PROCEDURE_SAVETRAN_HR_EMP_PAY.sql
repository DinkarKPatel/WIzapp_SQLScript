CREATE PROCEDURE SAVETRAN_HR_EMP_PAY
 @NSPID INT
-- WITH ENCRYPTION
AS
BEGIN
	DECLARE @CTEMP_HR_EMP_PAY VARCHAR(100),@CDBNAME VARCHAR(100),@CSTEP VARCHAR(10),
			@CCMD NVARCHAR(MAX),@TEMPTABLE VARCHAR(100),@CERRMSG VARCHAR(MAX),@CPAY_NAME VARCHAR(100),
			@CFINAL_HR_EMP_PAY VARCHAR(100),@CCOLNAME VARCHAR(100)
	DECLARE @TPAY_NAME TABLE (PAY_NAME VARCHAR(100))
	DECLARE @CWRONG_COLU TABLE (COL VARCHAR(100))		
	
	DECLARE  @TRESULT TABLE(TYPE VARCHAR(100),MESSAGE VARCHAR(MAX),VALUE VARCHAR(100))		
	
	SET @CSTEP = 10
	SET @CDBNAME = DB_NAME()
	SET @CTEMP_HR_EMP_PAY = 'TEMP_HR_EMP_PAY_'+LTRIM(RTRIM(STR(@NSPID)))
	SET @CFINAL_HR_EMP_PAY = 'FINAL_HR_EMP_PAY_'+LTRIM(RTRIM(STR(@NSPID)))
	
	BEGIN TRY
		BEGIN TRAN	
		SET @CSTEP = 20	
		SET @CCMD = N'IF OBJECT_ID('''+@CFINAL_HR_EMP_PAY+''',''U'') IS NOT NULL 
						DROP TABLE '+@CFINAL_HR_EMP_PAY+'
		CREATE TABLE '+@CFINAL_HR_EMP_PAY+'(REF_ID VARCHAR(10),XN_MONTH INT,XN_YEAR INT,PAY_NAME VARCHAR(100),AMOUNT NUMERIC(14,2))
		'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 40
		SET @CCMD = N'SELECT NAME AS COL FROM SYS.COLUMNS WHERE OBJECT_ID = OBJECT_ID('''+@CTEMP_HR_EMP_PAY+''',''U'') AND NAME LIKE ''[F][0-9]%'''
		INSERT INTO @CWRONG_COLU
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 60
		WHILE EXISTS (SELECT TOP 1 * FROM @CWRONG_COLU)
		BEGIN
			SELECT TOP 1 @CCOLNAME = COL FROM @CWRONG_COLU
			
			SET @CCMD = N'IF EXISTS (SELECT TOP 1 * FROM '+@CTEMP_HR_EMP_PAY+' WHERE ['+@CCOLNAME+'] IS NOT NULL)
							PRINT ''OK''
						ELSE
							ALTER TABLE '+@CTEMP_HR_EMP_PAY+'
							DROP COLUMN '+@CCOLNAME+''
			PRINT @CCMD				
			EXEC SP_EXECUTESQL @CCMD
			DELETE TOP (1) FROM @CWRONG_COLU	
		END 
		
		SET @CSTEP = 80
		SET @CCMD = N' INSERT INTO '+@CFINAL_HR_EMP_PAY+' (REF_ID,XN_MONTH,XN_YEAR,PAY_NAME)
						SELECT DISTINCT REF_ID,XN_MONTH,XN_YEAR,B.NAME AS PAY_NAME FROM '+@CTEMP_HR_EMP_PAY+' A CROSS JOIN 
						(SELECT NAME FROM SYS.COLUMNS WHERE OBJECT_ID = OBJECT_ID('''+@CTEMP_HR_EMP_PAY+''',''U'') AND 
						NAME NOT IN(''REF_ID'',''EMP_NAME'',''XN_MONTH'',''XN_YEAR''))B'
		PRINT @CCMD	
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CCMD = N'SELECT DISTINCT PAY_NAME FROM '+@CFINAL_HR_EMP_PAY+'' 
		PRINT @CCMD
		INSERT INTO @TPAY_NAME
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 100
		WHILE EXISTS (SELECT TOP 1 * FROM @TPAY_NAME)
		BEGIN
			SELECT TOP 1 @CPAY_NAME = PAY_NAME FROM @TPAY_NAME
			
			SET @CCMD= N'UPDATE A SET A.AMOUNT = B.['+@CPAY_NAME+'] FROM '+@CFINAL_HR_EMP_PAY+' A 
						JOIN  '+@CTEMP_HR_EMP_PAY+' B 
						ON A.REF_ID = B.REF_ID AND A.XN_MONTH= B.XN_MONTH AND A.XN_YEAR = B.XN_YEAR AND A.PAY_NAME = '''+@CPAY_NAME+''''
			
			PRINT @CCMD
			EXEC SP_EXECUTESQL 	@CCMD	
			DELETE TOP (1) FROM @TPAY_NAME
		END
		
	
		SET @CSTEP = 120
		SET @CCMD = N'SELECT ''ALERT'' AS TYPE,''EMP ID NOT FOUND'' AS MESSAGE, A.REF_ID AS VALUE FROM '+@CFINAL_HR_EMP_PAY+' A
					LEFT OUTER JOIN EMP_MST B ON A.REF_ID = B.REF_ID WHERE B.REF_ID IS NULL'
		PRINT @CCMD
		
		INSERT INTO @TRESULT
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 140
		SET @CCMD = N'SELECT ''ALERT'' AS TYPE,''PAY NAME NOT FOUND'' AS MESSAGE, A.PAY_NAME AS VALUE FROM '+@CFINAL_HR_EMP_PAY+' A
					LEFT OUTER JOIN EMP_PAY B ON A.PAY_NAME = B.PAY_NAME WHERE B.PAY_NAME IS NULL'
		PRINT @CCMD
		INSERT INTO @TRESULT
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 160
		IF EXISTS (SELECT TOP 1 * FROM @TRESULT)
			GOTO EXIT_PROC
		
		SET @CSTEP = 180	
		SET @CCMD = N'ALTER TABLE '+@CFINAL_HR_EMP_PAY+'
					  ADD PAY_ID VARCHAR(7),EMP_ID CHAR(7)'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 200
		SET @CCMD = N'UPDATE A SET A.EMP_ID = B.EMP_ID FROM '+@CFINAL_HR_EMP_PAY+' A 
						JOIN EMP_MST B ON A.REF_ID = B.REF_ID'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		
		SET @CSTEP = 220
		SET @CCMD = N'UPDATE A SET A.PAY_ID = B.PAY_ID FROM '+@CFINAL_HR_EMP_PAY+' A 
						JOIN EMP_PAY B ON A.PAY_NAME = B.PAY_NAME'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 240
		SET @CCMD = N'UPDATE A SET A.AMOUNT = B.AMOUNT FROM HR_EMP_PAY A 
					  JOIN '+@CFINAL_HR_EMP_PAY+' B ON 
					  A.EMP_ID = B.EMP_ID AND A.XN_MONTH = B.XN_MONTH AND 
					  A.XN_YEAR = B.XN_YEAR AND A.PAY_ID = B.PAY_ID' 
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 260
		SET @CCMD = N'SELECT A.EMP_ID,A.XN_MONTH,A.XN_YEAR,A.PAY_ID,ISNULL(A.AMOUNT,0) FROM '+@CFINAL_HR_EMP_PAY+' A
					  LEFT OUTER JOIN HR_EMP_PAY B ON 
					  A.EMP_ID = B.EMP_ID AND A.XN_MONTH = B.XN_MONTH AND 
					  A.XN_YEAR = B.XN_YEAR AND A.PAY_ID = B.PAY_ID
					  WHERE B.EMP_ID IS NULL AND B.XN_MONTH IS NULL AND 
					  B.XN_YEAR IS NULL AND  B.PAY_ID IS NULL AND ISNULL(A.AMOUNT,0)<>0 '
		PRINT @CCMD
		
		
		INSERT HR_EMP_PAY	( EMP_ID, XN_MONTH, XN_YEAR, PAY_ID, AMOUNT )  
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP = 280
		PRINT 'GIVE SUCCESS'
		INSERT INTO @TRESULT
		SELECT 'SUCCESS' AS TYPE,'' AS MESSAGE,'' AS VALUE 

	END TRY
	BEGIN CATCH
		SET @CERRMSG = 'P:SAVETRAN_HR_EMP_PAY STEP:-'+@CSTEP+', MESSAGE: '+ERROR_MESSAGE()
		
		INSERT INTO @TRESULT (TYPE,MESSAGE,VALUE)
		SELECT 'ERROR' AS TYPE,@CERRMSG AS MESSAGE,'' AS VALUE 
	END CATCH
	EXIT_PROC:
	
		IF @@TRANCOUNT>0 AND EXISTS (SELECT TOP 1 * FROM @TRESULT WHERE TYPE <> 'SUCCESS')
			ROLLBACK
		ELSE
		BEGIN
			COMMIT
			SET @CCMD = N'IF OBJECT_ID('''+@CFINAL_HR_EMP_PAY+''',''U'') IS NOT NULL
							  DROP TABLE '+@CFINAL_HR_EMP_PAY+'
						  IF OBJECT_ID('''+@CTEMP_HR_EMP_PAY+''',''U'')	IS NOT NULL
							  DROP TABLE '+@CTEMP_HR_EMP_PAY+''
			PRINT @CCMD
			--EXEC SP_EXECUTESQL @CCMD				   
		END
		SELECT DISTINCT * FROM @TRESULT		
END
