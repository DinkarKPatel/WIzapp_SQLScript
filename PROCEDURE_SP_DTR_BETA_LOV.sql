CREATE PROCEDURE SP_DTR_BETA_LOV
(
  @QUERYID INT,
  @CWHERE VARCHAR(MAX)
)
--WITH ENCRYPTION
AS
BEGIN
IF @QUERYID=1
   GOTO LBLCUSTOMER
ELSE
GOTO LAST

LBLCUSTOMER:  
 DECLARE @T1 NUMERIC(10)  
 SET @CWHERE=(CASE WHEN ISNULL(@CWHERE,'')='' THEN '000000000000' ELSE @CWHERE END)
  
 SELECT @T1=COUNT(CUSTOMER_CODE) FROM CUSTDYM  WHERE (USER_CUSTOMER_CODE=@CWHERE  OR CUSTOMER_CODE=@CWHERE)
   
 IF ISNULL(@T1,0)=1   
 BEGIN   
  SELECT CUSTOMER_CODE, USER_CUSTOMER_CODE, ISNULL(PRX.PREFIX_NAME,'') AS CUSTOMER_TITLE, CUSTOMER_FNAME, CUSTOMER_LNAME,     
  ISNULL(ST.STATE,'') AS [STATE],ADDRESS1, ADDRESS2,ISNULL(AR.AREA_NAME,'') AS  AREA,    
  ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE, PHONE1,     
  PHONE2, MOBILE, EMAIL,A.AREA_CODE,ADDRESS9,A.CARD_NO,A.INACTIVE ,A.PRIVILEGE_CUSTOMER,
  A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  A.DT_BIRTH,A.FLAT_DISC_CUSTOMER,A.REF_CUSTOMER_CODE,A.LOCATION_ID
  FROM CUSTDYM A   (NOLOCK)
  LEFT OUTER JOIN PREFIX PRX (NOLOCK) ON PRX.PREFIX_CODE=A.PREFIX_CODE
  LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE    
  WHERE A.INACTIVE=0 AND (A.USER_CUSTOMER_CODE=@CWHERE  OR A.CUSTOMER_CODE=@CWHERE)   
 END  
 ELSE  
 BEGIN   
  SELECT CUSTOMER_CODE, USER_CUSTOMER_CODE, ISNULL(PRX.PREFIX_NAME,'') AS  CUSTOMER_TITLE, CUSTOMER_FNAME, CUSTOMER_LNAME,     
  ISNULL(ST.STATE,'') AS [STATE],ADDRESS1, ADDRESS2,ISNULL(AR.AREA_NAME,'') AS  AREA,    
  ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE, PHONE1,     
  PHONE2, MOBILE, EMAIL,A.AREA_CODE,ADDRESS9,A.CARD_NO,A.INACTIVE ,A.PRIVILEGE_CUSTOMER,
  A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  A.DT_BIRTH,A.FLAT_DISC_CUSTOMER ,A.REF_CUSTOMER_CODE ,A.LOCATION_ID    
  FROM CUSTDYM A   (NOLOCK)  
  LEFT OUTER JOIN PREFIX PRX (NOLOCK) ON PRX.PREFIX_CODE=A.PREFIX_CODE 
  LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE    
  WHERE A.INACTIVE=0 AND CUSTOMER_CODE<>'000000000000' AND     
  (USER_CUSTOMER_CODE LIKE @CWHERE+'%' OR CUSTOMER_FNAME LIKE @CWHERE+'%' OR CUSTOMER_LNAME LIKE @CWHERE+'%' OR    
  MOBILE LIKE @CWHERE+'%' OR PHONE1 LIKE @CWHERE+'%' OR PHONE2 LIKE @CWHERE+'%' OR EMAIL LIKE @CWHERE+'%'     
  OR CARD_NO LIKE @CWHERE+'%' OR REPLACE(CUSTOMER_FNAME+CUSTOMER_LNAME,' ','') LIKE REPLACE(@CWHERE,' ','')+'%'  )    
 END  
 LAST:
 END
