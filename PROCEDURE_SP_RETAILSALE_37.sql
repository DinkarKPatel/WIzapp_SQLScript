CREATE PROCEDURE SP_RETAILSALE_37--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
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
	
	SELECT CAST(0 AS BIT) as enablediscvoucher
	RETURN
	DECLARE @cGvSchemeCode VARCHAR(50)
	
	SELECT TOP 1 @cGvSchemeCode=a.scheme_code FROM gv_scheme_mst a JOIN gv_scheme_locs b ON a.scheme_code=b.scheme_code
	WHERE b.dept_id=@cDeptId AND @cFromDt BETWEEN applicable_from_dt AND applicable_to_dt
	AND mode=2

    SELECT (CASE WHEN ISNULL(@cGvSchemeCode,'')='' THEN 0 ELSE 1 END) as enablediscvoucher
    
end
