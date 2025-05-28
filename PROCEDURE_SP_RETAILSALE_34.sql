CREATE PROCEDURE SP_RETAILSALE_34--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
(  
	 @CQUERYID			NUMERIC(2)=0,  
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
	SELECT b.cm_no,b.cm_dt,a.*,CAST('' AS VARCHAr(20)) MOBILE,CAST('' AS VARCHAr(20)) CUSTOMER_CODE 
	FROM coupon_redemption_info A
	JOIN cmm01106 b on a.cm_id=b.cm_id
	WHERE A.cm_id=@cwhere
end

