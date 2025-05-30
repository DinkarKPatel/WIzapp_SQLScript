CREATE PROCEDURE SP_RETAILSALE_29--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
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
	SELECT TOP 1 A.CM_ID 
	FROM CAMPAIGN_CMM A (NOLOCK)
	JOIN CMM01106 B (NOLOCK) ON A.CM_ID= B.CM_ID 
	JOIN CUSTDYM C (NOLOCK) ON B.CUSTOMER_CODE = C.CUSTOMER_CODE
	WHERE C.CUSTOMER_CODE <> '000000000000' AND C.PRIVILEGE_CUSTOMER =1 
	AND B.CM_ID = @CWHERE

end
