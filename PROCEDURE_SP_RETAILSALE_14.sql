CREATE PROCEDURE SP_RETAILSALE_14-- (LocId 3 digit change by Sanjay:30-10-2024)
(  
	 @CQUERYID			NUMERIC(2),  
	 @CWHERE			VARCHAR(MAX)='',  
	 @CFINYEAR			VARCHAR(5)='',  
	 @CDEPTID			VARCHAR(4)='',  
	 @NNAVMODE			NUMERIC(2)=1,  
	 @CWIZAPPUSERCODE	VARCHAR(10)='',  
	 @CREFMEMOID		VARCHAR(40)='',  
	 @CREFMEMODT		DATETIME='',  
	 @BINCLUDEESTIMATE	BIT=1,  
	 @CFROMDT			DATETIME='',  
	 @CTODT				VARCHAR(50)='',
	 @bCardDiscount		BIT=0,
	 @cCustCode			VARCHAR(15)=''
) 
AS  
BEGIN  
  SELECT A.*, B.*, '' AS CUSTOMER_NAME, '' AS CREDIT_CARD_NAME , C.USERNAME, '' AS ADDRESS,  
  ISNULL(ST.STATE,'') AS [STATE],ISNULL(AR.AREA_NAME,'') AS  AREA,  
    ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE,CAST(0 AS BIT) AS CREDIT_REFUND,  
    CAST(0 AS NUMERIC(10,2)) AS CASH_AMOUNT,CONVERT(NUMERIC(14,2), 0) AS PAYBACK,A.HOLD_ID,  
    A.LOGIN_ID,A.SESSION_ID,
   ISNULL(X.emp_code,'0000000') AS [emp_code],ISNULL(x.emp_code1,'0000000')  AS [emp_code1],ISNULL(x.emp_code2,'0000000') as [emp_code2],
   ISNULL(x.emp_name,'') AS [emp_name],ISNULL(x.emp_name1,'') AS [emp_name1],ISNULL(x.emp_name2,'') AS [emp_name2]  ,
  -- ,CONVERT(NUMERIC(14,3),
   --(CASE WHEN (a.subtotal+ISNULL(a.subtotal_r,0))<>0 THEN (a.discount_amount*100)/ (a.subtotal+ISNULL(a.subtotal_r,0)) 
  -- ELSE 0 END)) as [DISCOUNT_PERCENTAGE_CALC]
   
   A.DISCOUNT_PERCENTAGE AS [DISCOUNT_PERCENTAGE_CALC],A.hbd_location_code as location_code
  FROM CMM_HOLD A   (NOLOCK)  
  LEFT OUTER JOIN CUSTDYM B  (NOLOCK) ON B.CUSTOMER_CODE=A.CUSTOMER_CODE   
  LEFT OUTER JOIN AREA AR  (NOLOCK)		ON AR.AREA_CODE=B.AREA_CODE  
  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE  
  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE  
  JOIN USERS C ON C.USER_CODE=A.USER_CODE  
  LEFT OUTER JOIN
  (
	SELECT TOP 1 hold_id,e1.emp_code,e2.emp_code  AS [emp_code1],e3.emp_code as [emp_code2],e1.emp_name AS [emp_name]
	,e2.emp_name AS [emp_name1],e3.emp_name AS [emp_name2]
	FROM cmd_hold a (NOLOCK)
	JOIN employee e1 (NOLOCK) ON e1.emp_code=a.emp_code
	JOIN employee e2 (NOLOCK) ON e2.emp_code=a.emp_code1
	JOIN employee e3 (NOLOCK) ON e3.emp_code=a.emp_code2
	WHERE a.HOLD_ID=@CWHERE AND (a.emp_code<>'0000000' OR a.emp_code2<>'0000000' OR a.emp_code2<>'0000000')
  )x ON X.hold_id=a.hold_id
  WHERE  A.HOLD_ID=@CWHERE   AND A.hbd_location_code= @CDEPTID  
end
