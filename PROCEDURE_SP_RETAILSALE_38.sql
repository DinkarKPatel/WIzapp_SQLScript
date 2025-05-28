CREATE PROCEDURE SP_RETAILSALE_38--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
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

	SELECT TOP 1 applicable_for_privilege_customer FROM scheme_setup_det a
	JOIN scheme_setup_mst b ON a.memo_no=b.memo_no WHERE @CREFMEMODT BETWEEN applicable_from_dt AND applicable_to_dt
	AND applicable_for_privilege_customer=1
	
end
