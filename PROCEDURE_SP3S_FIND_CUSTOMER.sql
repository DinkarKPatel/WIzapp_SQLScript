CREATE PROCEDURE SP3S_FIND_CUSTOMER
( 
	@CWHERE   VARCHAR(MAX)=''
)
 AS
 BEGIN
	SELECT TOP 25 CUSTOMER_CODE, USER_CUSTOMER_CODE, ISNULL(PRX.PREFIX_NAME,'') AS  CUSTOMER_TITLE, 
			CUSTOMER_FNAME, CUSTOMER_LNAME, CUSTOMER_FNAME +' '+CUSTOMER_LNAME AS CUSTOMER_NAME,     
			ISNULL(ST.STATE,'') AS [STATE],ADDRESS1, ADDRESS2,ISNULL(AR.AREA_NAME,'') AS  AREA,    
			ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE, PHONE1,     
			PHONE2, MOBILE, EMAIL,A.AREA_CODE,ADDRESS9,A.CARD_NO,A.INACTIVE ,A.PRIVILEGE_CUSTOMER,
			A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  A.DT_BIRTH,A.FLAT_DISC_CUSTOMER ,A.REF_CUSTOMER_CODE ,
			A.LOCATION_ID    
	FROM CUSTDYM A   (NOLOCK)  
	LEFT OUTER JOIN PREFIX PRX (NOLOCK) ON PRX.PREFIX_CODE=A.PREFIX_CODE 
	LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
	LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
	LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE    
	WHERE A.INACTIVE=0 AND CUSTOMER_CODE<>'000000000000' AND  (LTRIM(RTRIM(CUSTOMER_FNAME)) <>'' OR LTRIM(RTRIM(CUSTOMER_LNAME))<>'') AND   
	(USER_CUSTOMER_CODE LIKE @CWHERE+'%' OR (CUSTOMER_FNAME +' '+CUSTOMER_LNAME) LIKE +'%'+@CWHERE+'%' OR    
	MOBILE LIKE @CWHERE+'%' OR PHONE1 LIKE @CWHERE+'%' OR PHONE2 LIKE @CWHERE+'%' OR EMAIL LIKE @CWHERE+'%'     
	OR CARD_NO LIKE @CWHERE+'%' ) 
	ORDER BY CUSTOMER_FNAME,CUSTOMER_LNAME
	
END
