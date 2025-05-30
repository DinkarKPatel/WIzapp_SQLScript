CREATE PROCEDURE SP3S_POPULATE_CUSTOMERCRM_CUBE
AS
BEGIN
	
BEGIN TRY	
	DECLARE @CRFDBNAME VARCHAR(200),@CCMD NVARCHAR(MAX),@CTABLENAME VARCHAR(300),@CSTEP VARCHAR(5),@CERRORMSG VARCHAR(MAX)
	
    --as discuss with sir reove this Proc due to after run this this proc slow Process of all adatabase 
	goto END_PROC
	SET @CERRORMSG=''
		
	SET @CRFDBNAME = DB_NAME()+'_pmt.DBO.'
    

	

	SET @CSTEP='10'
	SET @CTABLENAME=@CRFDBNAME+'CUSTOMER_CRM'

	IF OBJECT_ID (@CTABLENAME,'U') IS NULL
	   GOTO END_PROC
	
	SET @CCMD=N'TRUNCATE TABLE '+@CTABLENAME
	EXEC SP_EXECUTESQL @CCMD
	
	SET @CSTEP='20'
	SET @CCMD=N'INSERT '+@CTABLENAME+'	(DEPT_ID,DEPT_NAME, CUSTOMER_ID, MOBILE, CUSTOMER_CODE, CUSTOMER_NAME, DT_BIRTH, DT_ANNIVERSARY, DT_CARD_ISSUE, 
	DT_CARD_EXPIRY, CARD_NO, AREA_NAME, CITY, STATE, PIN, ADDRESS0, ADDRESS1, ADDRESS2, ADDRESS9, PHONE1, PHONE2, EMAIL, 
	DATE_OF_FIRST_VISIT, DATE_OF_LAST_VISIT, NO_OF_VISITS, TOTAL_SPEND, FIRST_VISIT_STORE_ID, LAST_VISIT_STORE_ID, 
	DAYS_SINCE_LAST_VISIT, AFD, ATS, ABS,CM_ID, CM_NO, CM_DT, PRODUCT_CODE, CAL_QUANTITY, MRP,CAL_NET_DISCOUNT_AMOUNT,
	NET_DISCOUNT_PERCENTAGE, CAL_NRV, SECTION_NAME, SUB_SECTION_NAME, ARTICLE_NO, PARA1_NAME, 
	PARA2_NAME, PARA3_NAME, PARA4_NAME, PARA5_NAME, PARA6_NAME )  
	SELECT LOC.DEPT_ID,LOC.DEPT_NAME,USER_CUSTOMER_CODE AS  CUSTOMER_ID, MOBILE,B.CUSTOMER_CODE,CUSTOMER_FNAME+'' ''+CUSTOMER_LNAME AS CUSTOMER_NAME,
	DT_BIRTH, DT_ANNIVERSARY, DT_CARD_ISSUE, DT_CARD_EXPIRY,
	CARD_NO, AREA_NAME, CITY, STATE, PIN, ADDRESS0,CD.ADDRESS1, CD.ADDRESS2, ADDRESS9, PHONE1, PHONE2, EMAIL, 
	'''' AS DATE_OF_FIRST_VISIT,'''' AS DATE_OF_LAST_VISIT,0 AS NO_OF_VISITS,0 AS TOTAL_SPEND,'''' AS FIRST_VISIT_STORE_ID, 
	'''' AS LAST_VISIT_STORE_ID,0 AS DAYS_SINCE_LAST_VISIT,0 AS AFD,0 AS ATS,0 AS ABS,A.CM_ID, CM_NO, CM_DT, A.PRODUCT_CODE, 
	QUANTITY, A.MRP,(A.DISCOUNT_AMOUNT+A.CMM_DISCOUNT_AMOUNT) AS CAL_NET_DISCOUNT_AMOUNT,0 AS NET_DISCOUNT_PERCENTAGE,
	A.RFNET AS NRV, C.SECTION_NAME, C.SUB_SECTION_NAME, C.ARTICLE_NO, C.PARA1_NAME, 
	C.PARA2_NAME, C.PARA3_NAME, C.PARA4_NAME, C.PARA5_NAME, C.PARA6_NAME FROM 
	CMD01106 A (NOLOCK) JOIN CMM01106 B (NOLOCK) ON A.CM_ID=B.CM_ID
	JOIN SKU_NAMES C (NOLOCK) ON C.PRODUCT_CODE=A.PRODUCT_CODE
	JOIN CUSTDYM CD (NOLOCK) ON CD.CUSTOMER_CODE=B.CUSTOMER_CODE
	JOIN AREA (NOLOCK) ON AREA.AREA_CODE=CD.AREA_CODE
	JOIN CITY (NOLOCK) ON CITY.CITY_CODE=AREA.CITY_CODE
	JOIN STATE (NOLOCK) ON STATE.STATE_CODE=CITY.STATE_CODE
	JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID=B.Location_code
	WHERE B.CUSTOMER_CODE NOT IN ('''',''000000000000'')'
	
	SET @CSTEP='25'
	EXEC SP_EXECUTESQL @CCMD
	print @CCMD
	
	SET @CSTEP='30'
	SET @CCMD=N'UPDATE A SET DATE_OF_LAST_VISIT=B.DATE_OF_LAST_VISIT,DATE_OF_FIRST_VISIT=B.DATE_OF_FIRST_VISIT,
	DAYS_SINCE_LAST_VISIT=B.DAYS_SINCE_LAST_VISIT,NO_OF_VISITS=B.NO_OF_VISITS,AFD=B.AFD,ATS=B.ATS,[ABS]=B.[ABS],
	TOTAL_SPEND=B.TOTAL_SPEND,NET_DISCOUNT_PERCENTAGE=
	(CASE WHEN MRP=0 OR CAL_QUANTITY=0 THEN 0 ELSE ROUND((CAL_NET_DISCOUNT_AMOUNT/(MRP*CAL_QUANTITY))*100,2) END) FROM '+@CTABLENAME+' A 
	JOIN (SELECT A.CUSTOMER_CODE,MIN(A.CM_DT) AS DATE_OF_FIRST_VISIT,MAX(A.CM_DT) AS DATE_OF_LAST_VISIT,
		  DATEDIFF(DD,MAX(A.CM_DT),GETDATE())	AS DAYS_SINCE_LAST_VISIT,COUNT(distinct A.CM_dt) AS NO_OF_VISITS,
		  (DATEDIFF(DD,MIN(A.CM_DT),MAX(A.CM_DT))/COUNT(A.CM_ID)) AS AFD,
		  SUM(NET_AMOUNT) AS TOTAL_SPEND,SUM(TOTAL_QUANTITY)/COUNT(A.CM_ID) AS [ABS],
		  (SUM(NET_AMOUNT)/COUNT(A.CM_ID)) AS ATS
		  FROM CMM01106 A JOIN '+@CTABLENAME+' B ON A.CM_ID=B.CM_ID
		  GROUP BY A.CUSTOMER_CODE) B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE'
	
	SET @CSTEP='35'
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD
	
	SET @CSTEP='40'
	SET @CCMD=N'UPDATE A SET FIRST_VISIT_STORE_ID=(SELECT TOP 1 location_code FROM CMM01106 WHERE CUSTOMER_CODE=A.CUSTOMER_CODE
	AND CM_DT=A.DATE_OF_FIRST_VISIT),
	LAST_VISIT_STORE_ID=(SELECT TOP 1 location_code FROM CMM01106 WHERE CUSTOMER_CODE=A.CUSTOMER_CODE
	AND CM_DT=A.DATE_OF_LAST_VISIT) FROM '+@CTABLENAME+' A '

	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD

	SET @CSTEP='45'
	SET @CCMD=N'UPDATE A SET DT_CARD_ISSUE=(SELECT TOP 1 CARD_ISSUE_DT FROM ARC01106 WHERE CUSTOMER_CODE=A.CUSTOMER_CODE
											AND ARCT=5 AND ISNULL(CARD_ISSUE_DT,'''')<>'''' ORDER BY CARD_ISSUE_DT) FROM '+@CTABLENAME+' A '
	PRINT @CCMD	
	EXEC SP_EXECUTESQL @CCMD
	
	SET @CCMD=N'UPDATE '+@CTABLENAME+' SET MEMBERSHIP_YEARS=DATEDIFF(YY,DT_CARD_ISSUE,GETDATE()),
				MEMBERSHIP_DAYS=DATEDIFF(DD,DT_CARD_ISSUE,GETDATE())'
	SET @CSTEP='50'
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD
				
END TRY		

BEGIN CATCH
	SET @CERRORMSG='ERROR IN PROCEDURE SP3S_POPULATE_CUSTOMERCRM_CUBE AT STEP#'+@CSTEP+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
	SELECT ISNULL(@CERRORMSG,'') AS ERRMSG	
END

