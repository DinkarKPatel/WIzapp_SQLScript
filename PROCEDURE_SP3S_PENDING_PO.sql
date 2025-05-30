CREATE PROCEDURE SP3S_PENDING_PO
(
	 @DFROMDATE DATETIME
	,@DTODATE   DATETIME
	,@CAC_CODE VARCHAR(10)='' /*FOR A SUPPLIER OR ALL SUPPLIER*/
	,@CARTICLE_CODE VARCHAR(10)='' /*FOR AN ARTICLE OR ALL ARTICLES*/
	,@BSUMMARY BIT=0,
	@CLOC VARCHAR(10)=''
)
--WITH ENCRYPTION
AS
BEGIN
/*
FOR THE PASSED DATE RANGE, ALL PO'S WOULD BE SCANNED FOR THE SUPPLIER WITH 
TOTAL ORDER QUANTITY AGAINST UNIQUE ARTICLE,COLOR,SIZE COMBINATION AND PURCHASE DONE AGAINST THESE ARTICLES WOULD BE 
SCANNED AND PENDING ARTICLES WITH LAST PO NO AND PO DT WOULD BE RETURNED.
*/

DECLARE @CPARA1_CODE VARCHAR(10),@CPARA2_CODE VARCHAR(10),@CPO_NO VARCHAR(10)
	   ,@DPODT DATETIME

IF OBJECT_ID('TEMPDB..#PO_PI','U') IS NOT NULL
	DROP TABLE #PO_PI
	
IF OBJECT_ID('TEMPDB..#PENDING_PO','U') IS NOT NULL
	DROP TABLE #PENDING_PO
	
IF OBJECT_ID('TEMPDB..#ARTICLE_CURSOR','U') IS NOT NULL
	DROP TABLE #ARTICLE_CURSOR

SELECT POM.DEPT_ID,POM.AC_CODE,POD.ARTICLE_CODE,POD.PARA1_CODE,POD.PARA2_CODE,SUM(POD.QUANTITY) AS PO_QTY
	  ,SUM(ISNULL(POD.PI_QTY,0)) AS PI_QTY
INTO #PO_PI	  
FROM POM01106 POM(NOLOCK)
JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
WHERE POM.CANCELLED=0 AND (@CAC_CODE='' OR POM.AC_CODE=@CAC_CODE) AND POM.PO_DT BETWEEN @DFROMDATE AND @DTODATE
AND (@CARTICLE_CODE='' OR POD.ARTICLE_CODE=@CARTICLE_CODE) AND (@CLOC='' OR POM.DEPT_ID=@CLOC)
GROUP BY POM.DEPT_ID,POM.AC_CODE,POD.ARTICLE_CODE,POD.PARA1_CODE,POD.PARA2_CODE

SELECT DEPT_ID,AC_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PO_QTY,PI_QTY,(PO_QTY-PI_QTY) AS PENDING_PO_QTY
	  ,CONVERT(VARCHAR(10),'') AS PO_NO,CONVERT(DATETIME,'') AS PO_DT
INTO #PENDING_PO
FROM #PO_PI
WHERE PI_QTY<PO_QTY

SELECT DEPT_ID,AC_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE 
INTO #ARTICLE_CURSOR
FROM #PENDING_PO

WHILE EXISTS(SELECT TOP 1 'U' FROM #ARTICLE_CURSOR)
BEGIN
	SELECT TOP 1 @CAC_CODE=AC_CODE,@CARTICLE_CODE=ARTICLE_CODE,@CPARA1_CODE=PARA1_CODE,@CPARA2_CODE=PARA2_CODE
	FROM #ARTICLE_CURSOR
	
	SELECT TOP 1 @CPO_NO=POM.PO_NO,@DPODT=POM.PO_DT 
	FROM POM01106 POM(NOLOCK)
	JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
	WHERE POM.CANCELLED=0 AND POM.AC_CODE=@CAC_CODE AND POM.PO_DT BETWEEN @DFROMDATE AND @DTODATE
	AND POD.ARTICLE_CODE=@CARTICLE_CODE AND POD.PARA1_CODE=@CPARA1_CODE AND POD.PARA2_CODE=@CPARA2_CODE
	ORDER BY POM.PO_DT DESC
	
	UPDATE #PENDING_PO SET PO_NO=@CPO_NO,PO_DT=@DPODT
	WHERE AC_CODE=@CAC_CODE AND ARTICLE_CODE=@CARTICLE_CODE AND PARA1_CODE=@CPARA1_CODE AND PARA2_CODE=@CPARA2_CODE

	DELETE #ARTICLE_CURSOR WHERE AC_CODE=@CAC_CODE AND ARTICLE_CODE=@CARTICLE_CODE AND PARA1_CODE=@CPARA1_CODE AND PARA2_CODE=@CPARA2_CODE
END

IF @BSUMMARY=0
BEGIN
	SELECT (L.DEPT_ID + ' ' +  L.DEPT_NAME) AS DEPT_NAME, LM.AC_NAME AS SUPPLIER,ART.ARTICLE_NO,P1.PARA1_NAME AS COLOR,P2.PARA2_NAME AS SIZE
		  ,CONVERT(NUMERIC(18,2),PP.PO_QTY) AS PO_QTY,CONVERT(NUMERIC(18,2),PP.PI_QTY) AS PI_QTY
		  ,CONVERT(NUMERIC(18,2),PP.PENDING_PO_QTY) AS PENDING_PO_QTY,PP.PO_NO AS LAST_PO_NO,
		  CONVERT(VARCHAR,PP.PO_DT,105) AS LAST_PO_DT
	FROM #PENDING_PO PP
	JOIN LM01106 LM(NOLOCK) ON PP.AC_CODE=LM.AC_CODE
	JOIN ARTICLE ART(NOLOCK) ON PP.ARTICLE_CODE=ART.ARTICLE_CODE
	JOIN PARA1 P1(NOLOCK) ON PP.PARA1_CODE=P1.PARA1_CODE
	JOIN PARA2 P2(NOLOCK) ON PP.PARA2_CODE=P2.PARA2_CODE
	JOIN LOCATION L ON PP.DEPT_ID= L.DEPT_ID
	ORDER BY LM.AC_NAME,ART.ARTICLE_NO,P1.PARA1_NAME,P2.PARA2_ORDER
END
ELSE 
BEGIN
	SELECT (L.DEPT_ID + ' ' +  L.DEPT_NAME) AS DEPT_NAME,LM.AC_NAME AS SUPPLIER,CONVERT(NUMERIC(18,2),SUM(PP.PO_QTY)) AS PO_QTY
	,CONVERT(NUMERIC(18,2),SUM(PP.PI_QTY)) AS PI_QTY,CONVERT(NUMERIC(18,2),SUM(PP.PENDING_PO_QTY)) AS PENDING_PO_QTY
	
	FROM #PENDING_PO PP
	JOIN LM01106 LM(NOLOCK) ON PP.AC_CODE=LM.AC_CODE
	JOIN ARTICLE ART(NOLOCK) ON PP.ARTICLE_CODE=ART.ARTICLE_CODE
	JOIN PARA1 P1(NOLOCK) ON PP.PARA1_CODE=P1.PARA1_CODE
	JOIN PARA2 P2(NOLOCK) ON PP.PARA2_CODE=P2.PARA2_CODE
	JOIN LOCATION L ON PP.DEPT_ID= L.DEPT_ID
	GROUP BY (L.DEPT_ID + ' ' +  L.DEPT_NAME), LM.AC_NAME
	ORDER BY (L.DEPT_ID + ' ' +  L.DEPT_NAME) ,LM.AC_NAME
END

END
--END OF PROCEDURE - SP3S_PENDING_PO
