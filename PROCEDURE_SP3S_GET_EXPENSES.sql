CREATE PROCEDURE SP3S_GET_EXPENSES
(
	 @DPROCESS DATETIME
	,@CREPID VARCHAR(10)  
	,@BREPROCESS BIT=0
)
--WITH ENCRYPTION
AS
BEGIN
DECLARE @CERRMSG VARCHAR(500),@CALERT VARCHAR(500),@CSTEP VARCHAR(5),@CCURFINYEAR VARCHAR(10)
	   ,@CPREFINYEAR VARCHAR(10),@DPREPROCESS DATETIME,@CEAID VARCHAR(50),@CEXID VARCHAR(50)
	   ,@CMSID VARCHAR(50),@CERRMSGOUT VARCHAR(1000),@CFILTER VARCHAR(1000),@CTSQL NVARCHAR(MAX)
	   ,@NDIVFACTOR NUMERIC(18,4),@CDIVFACTOR VARCHAR(18)

BEGIN TRY
	SET @CSTEP=00
	SET @CCURFINYEAR='01'+DBO.FN_GETFINYEAR(@DPROCESS)
	SET @CPREFINYEAR='0'+@CCURFINYEAR-1  
	SET @CPREFINYEAR='0'+@CPREFINYEAR
	SET @DPREPROCESS=DATEADD(YY,-1,@DPROCESS)
	SELECT @NDIVFACTOR=DBO.FN3S_GETDBCONFIG('DIV_FACTOR')
	--CHECK POINT 1
	--SELECT 	@DPROCESS,@CCURFINYEAR,@CPREFINYEAR,@DPREPROCESS
	SET @CSTEP=10
	IF ISNULL(@DPROCESS,'')=''
	BEGIN
		SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE: PROCESS DATE CANNOT BE BLANK....'
		GOTO EXIT_PROC
	END
	
	SET @CSTEP=40
	SELECT TOP 1 @CEAID=PROCESS_ID FROM EXP_ANLS_MST WHERE PROCESS_DT=@DPROCESS
	
	SET @CSTEP=50
	IF @BREPROCESS=1 AND ISNULL(@CEAID,'')<>''
	BEGIN
		DELETE EXP_ANLS_DET WHERE PROCESS_ID=@CEAID
		DELETE EXP_ANLS_MST WHERE PROCESS_ID=@CEAID
	END
	ELSE IF @BREPROCESS=0 AND ISNULL(@CEAID,'')=''
	BEGIN
		SET @CALERT='EXPENSE ANALYSIS IS NOT BUILT FOR THIS DATE!! WOULD YOU LIKE TO PROCESS IT NOW?'
		SELECT @CALERT AS ALERT
		GOTO EXIT_PROC
	END
	ELSE IF @BREPROCESS=0 AND ISNULL(@CEAID,'')<>''
		GOTO EXIT_PROC
	
	SET @CSTEP=60
	EXEC SP3S_MTLY_SLS @DPROCESS,0,@CMSID OUTPUT,@CERRMSGOUT OUTPUT
	SET @CSTEP=70
	IF ISNULL(@CERRMSGOUT,'')<>''
	BEGIN
			SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE: '+@CERRMSGOUT
			GOTO EXIT_PROC 
	END	
	ELSE IF ISNULL(@CMSID,'')='' 
	BEGIN
		SET @CSTEP=80
		EXEC SP3S_MTLY_SLS @DPROCESS,@BREPROCESS,@CMSID OUTPUT,@CERRMSGOUT OUTPUT	
			
		IF ISNULL(@CERRMSGOUT,'')<>''
		BEGIN 
			SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE:'+(CASE WHEN ISNULL(@CERRMSGOUT,'')='' THEN 'ERROR PROCESSING SALE DATA FROM CURRENT YEAR....' ELSE @CERRMSGOUT END)
			GOTO EXIT_PROC 
		END
	END
	
	SET @CSTEP=120
	BEGIN
		EXEC SP3S_EXPENSE_ANALYSIS @DPROCESS,0,@CEXID OUTPUT,@CERRMSGOUT OUTPUT
		IF ISNULL(@CERRMSGOUT,'')<>''
		BEGIN
			SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE: '+@CERRMSGOUT
			GOTO EXIT_PROC 
		END
		ELSE IF ISNULL(@CEXID,'')=''
		BEGIN
			EXEC SP3S_EXPENSE_ANALYSIS @DPROCESS,@BREPROCESS,@CEXID OUTPUT,@CERRMSGOUT OUTPUT	
			SET @CSTEP=130	
			IF ISNULL(@CERRMSGOUT,'')<>''
			BEGIN
				SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE: '+@CERRMSGOUT
				GOTO EXIT_PROC 
			END		
		END
	END	
	
	SET @CSTEP=140	
	IF OBJECT_ID('TEMPDB..#DEPTS','U') IS NOT NULL
		DROP TABLE #DEPTS
	SET @CSTEP=150	
	CREATE TABLE #DEPTS(DEPT_ID VARCHAR(5))
	
	SET @CSTEP=160	
	INSERT 	#DEPTS(DEPT_ID)
	--SELECT DISTINCT DEPT_ID FROM MTLY_SLS_DET WHERE PROCESS_ID=@CMSID 
	--UNION
	SELECT DISTINCT DEPT_ID FROM EXPENSE_DET WHERE PROCESS_ID=@CEXID
	
	SET @CSTEP=170
	IF EXISTS(SELECT TOP 1 'U' FROM #DEPTS)
	BEGIN
		SET @CSTEP=180
		SET @CEAID='EA'+CONVERT(VARCHAR(40),NEWID())
		
		SET @CSTEP=230
		 INSERT EXP_ANLS_MST	( PROCESS_ID, PROCESS_DT)  
		 SELECT @CEAID AS PROCESS_ID,@DPROCESS AS PROCESS_DT
		
		SET @CSTEP=240 
		  INSERT EXP_ANLS_DET	( PROCESS_ID,XN_TYPE, DEPT_ID,MONTH, MONTH_NAME, EXP_CODE, EXP_NAME, FIN_YEAR, EXP_AMOUNT,SALE_AMOUNT, EXP_MOM_PCT
								, EXP_SLS_PCT, ES_MOM_PCT)  
		  SELECT @CEAID AS PROCESS_ID,ED.XN_TYPE,LOC.DEPT_ID AS DEPT_ID,ED.MONTH,ED.MONTH_NAME,ED.AC_CODE AS EXP_CODE,ED.AC_NAME AS EXP_NAME
		 ,ED.FIN_YEAR AS FIN_YEAR,ED.EXPENSE_AMOUNT AS EXP_AMOUNT,CS.AMOUNT AS SALE_AMOUNT,0 AS EXP_MOM_PCT
		 ,(CASE WHEN ISNULL(CS.AMOUNT,0)<>0 
		 --AND ED.EXPENSE_AMOUNT>0 
		 THEN (ED.EXPENSE_AMOUNT/CS.AMOUNT)*100 
		        ELSE 0 END) AS EXP_SLS_PCT
		,0 AS ES_MOM_PCT
		 FROM #DEPTS LOC
		 LEFT JOIN EXPENSE_DET ED (NOLOCK) ON ED.DEPT_ID=LOC.DEPT_ID AND ED.PROCESS_ID=@CEXID
		 LEFT JOIN MTLY_SLS_DET CS (NOLOCK) ON ED.DEPT_ID=CS.DEPT_ID AND ED.XN_TYPE=CS.XN_TYPE AND ED.FIN_YEAR=CS.FIN_YEAR AND ED.MONTH=CS.MONTH AND CS.PROCESS_ID=@CMSID 
		 
		SET @CSTEP=250
		EXEC SP3S_CALC_MOM @CEAID,'EXP_ANLS',@CERRMSGOUT OUTPUT
		IF ISNULL(@CERRMSGOUT,'')<>''
		BEGIN
			SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE: '+@CERRMSGOUT
				GOTO EXIT_PROC 
		END  
	END
	ELSE 
	BEGIN
		SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE: COULDNOT FIND DATA FOR THIS DATE'
				GOTO EXIT_PROC 
	END	
	
END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP3S_GET_EXPENSES,STEP:'+@CSTEP+',MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:
	IF ISNULL(@CERRMSG,'')<>'' 
		SELECT @CERRMSG AS ERRMSG
	ELSE IF ISNULL(@CEAID,'')<>''
	BEGIN
		SELECT @CFILTER=FILTER FROM MGMT_REPS WHERE REP_ID=@CREPID AND REPORT_TYPE=3
		SET @CFILTER=ISNULL(@CFILTER,'')
		
		SET @CDIVFACTOR=@NDIVFACTOR			
		SET @CTSQL=N'SELECT ED.XN_TYPE,LOC_VIEW.STATE,LOC_VIEW.CITY,ED.DEPT_ID,LOC_VIEW.DEPT_NAME,ED.EXP_NAME
					,DBO.FN3S_DSPL_FIN_YEAR(FIN_YEAR) AS FIN_YEAR,ED.MONTH_NAME
					,CONVERT(NUMERIC(18),ED.EXP_AMOUNT/'+@CDIVFACTOR+') AS EXP_AMOUNT
					,CONVERT(NUMERIC(18),ED.EXP_MOM_PCT) AS EXP_MOM_PCT
					,CONVERT(NUMERIC(18),ED.EXP_SLS_PCT) AS EXP_SLS_PCT
					,CONVERT(NUMERIC(18),ED.ES_MOM_PCT) AS  ES_MOM_PCT
					 FROM EXP_ANLS_DET ED (NOLOCK)
					 JOIN LOC_VIEW (NOLOCK) ON ED.DEPT_ID=LOC_VIEW.DEPT_ID
					 WHERE PROCESS_ID='''+@CEAID+''''+(CASE WHEN @CFILTER='' THEN '' ELSE ' AND'+@CFILTER END) 
		PRINT @CTSQL
		EXEC SP_EXECUTESQL @CTSQL 			 
	END
		
END
--END OF PROCEDURE - SP3S_GET_EXPENSES
