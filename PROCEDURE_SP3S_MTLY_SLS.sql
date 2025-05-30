CREATE PROCEDURE SP3S_MTLY_SLS
(
	 @DPROCESS DATETIME
	,@BREPROCESS BIT=0
	,@CMSID VARCHAR(50) OUTPUT
	,@CERRMSG VARCHAR(500) OUTPUT
)	
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CALERT VARCHAR(500),@CSTEP VARCHAR(5),@CCURFINYEAR VARCHAR(10)
	   ,@CPREFINYEAR VARCHAR(10),@DPREPROCESS DATETIME,@CEXID VARCHAR(50)
	   ,@CSAID VARCHAR(50),@CPRESAID VARCHAR(50),@CERRMSGOUT VARCHAR(1000)

BEGIN TRY
	SET @CSTEP=00
	SET @CCURFINYEAR='01'+DBO.FN_GETFINYEAR(@DPROCESS)
	SET @CPREFINYEAR='0'+@CCURFINYEAR-1  
	SET @CPREFINYEAR='0'+@CPREFINYEAR
	SET @DPREPROCESS=DATEADD(YY,-1,@DPROCESS)
	--CHECK POINT 1
	--SELECT 	@DPROCESS,@CCURFINYEAR,@CPREFINYEAR,@DPREPROCESS
	SET @CSTEP=10
	IF ISNULL(@DPROCESS,'')=''
	BEGIN
		SET @CERRMSG='P:SP3S_MTLY_SLS,STEP:'+@CSTEP+',MESSAGE: PROCESS DATE CANNOT BE BLANK....'
		GOTO EXIT_PROC
	END
	
	SET @CSTEP=40
	SELECT TOP 1 @CMSID=PROCESS_ID FROM MTLY_SLS_MST WHERE PROCESS_DT=@DPROCESS
	
	SET @CSTEP=50
	IF @BREPROCESS=1 AND ISNULL(@CMSID,'')<>''
	BEGIN
		DELETE MTLY_SLS_DET WHERE PROCESS_ID=@CMSID
		DELETE MTLY_SLS_MST WHERE PROCESS_ID=@CMSID
	END
	ELSE IF @BREPROCESS=0 AND ISNULL(@CMSID,'')=''
	BEGIN
		SET @CALERT='MONTHLY SALE IS NOT BUILT FOR THIS DATE!! WOULD YOU LIKE TO PROCESS IT NOW?'
		--GOTO EXIT_PROC
	END
	ELSE IF @BREPROCESS=0 AND ISNULL(@CMSID,'')<>''
		GOTO EXIT_PROC
	
	SET @CSTEP=60
	IF OBJECT_ID('TEMPDB..#SLS','U') IS NOT NULL
		DROP TABLE #SLS
	
	SET @CSTEP=70
	SELECT 	 'CUR' AS XN_TYPE
			,CMM.FIN_YEAR
			,LOC.DEPT_ID
			,MONTH(CMM.CM_DT) AS MONTH
			,(SUM(CMD.RFNET)) AS AMOUNT
	INTO #SLS		
	FROM CMM01106 CMM (NOLOCK)  
	JOIN CMD01106 CMD (NOLOCK) ON CMM.CM_ID=CMD.CM_ID
	JOIN LOCATION LOC (NOLOCK) ON CMM.location_Code =LOC.DEPT_ID
	WHERE LOC.INACTIVE=0 AND CM_DT<=@DPROCESS AND FIN_YEAR=@CCURFINYEAR AND CMM.CANCELLED=0 AND CM_MODE=1  
	GROUP BY LOC.DEPT_ID,MONTH(CMM.CM_DT),FIN_YEAR  	
	UNION ALL
	SELECT 	 'PRE' AS XN_TYPE
			,CMM.FIN_YEAR
			,LOC.DEPT_ID
			,MONTH(CMM.CM_DT) AS MONTH
			,(SUM(CMD.RFNET)) AS AMOUNT
	FROM CMM01106 CMM (NOLOCK)  
	JOIN CMD01106 CMD (NOLOCK) ON CMM.CM_ID=CMD.CM_ID
	JOIN LOCATION LOC (NOLOCK) ON CMM.location_Code=LOC.DEPT_ID
	WHERE LOC.INACTIVE=0 AND CM_DT<=@DPREPROCESS AND FIN_YEAR=@CPREFINYEAR AND CMM.CANCELLED=0 AND CM_MODE=1  
	GROUP BY LOC.DEPT_ID,MONTH(CMM.CM_DT),FIN_YEAR
	
	SET @CSTEP=80
	SET @CMSID='MS'+CONVERT(VARCHAR(40),NEWID())
	
	SET @CSTEP=90
	IF EXISTS(SELECT TOP 1 'U' FROM #SLS)
	BEGIN
		  INSERT MTLY_SLS_MST	( PROCESS_ID, PROCESS_DT)  
		  SELECT @CMSID AS PROCESS_ID,@DPROCESS AS PROCESS_DT
		 
		  INSERT MTLY_SLS_DET	( PROCESS_ID, XN_TYPE, FIN_YEAR, DEPT_ID, MONTH, AMOUNT)  
		  SELECT @CMSID AS PROCESS_ID,XN_TYPE,FIN_YEAR,DEPT_ID,MONTH,AMOUNT 
		  FROM #SLS
	END
	
END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP3S_MTLY_SLS,STEP:'+@CSTEP+',MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:

END
--END OF PROCEDURE - SP3S_MTLY_SLS
