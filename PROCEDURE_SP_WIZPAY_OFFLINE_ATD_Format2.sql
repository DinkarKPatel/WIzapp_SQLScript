CREATE PROC SP_WIZPAY_OFFLINE_ATD_FORMAT2  
(  
 @CFROM DATETIME,  
 @CTODT DATETIME,  
 @CWHERE VARCHAR(50)  
)  
AS  
BEGIN  
	SELECT 
	A.LOCATION_ID, B.DEPT_NAME,CONVERT(VARCHAR,IST_TIME,110) AS ATD_DATE,
	MST.EMP_ID,
	EMP_TITLE + ' ' + EMP_FNAME + ' ' + EMP_LNAME AS EMP_NAME,
	(CASE WHEN ISNULL(ATD_MODE,0)=1 THEN 'Y' ELSE 'N' END) AS ATD_MODE
	FROM EMP_WPAYATT A
	JOIN LOCATION B ON A.LOCATION_ID= B.DEPT_ID  
	JOIN EMP_MST MST ON MST.EMP_ID=A.EMP_ID
	WHERE (A.LOCATION_ID= @CWHERE OR @CWHERE = '') AND  IST_TIME BETWEEN @CFROM AND @CTODT 
	AND  ATD_MODE=1 
  
END
