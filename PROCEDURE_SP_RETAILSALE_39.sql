CREATE PROCEDURE SP_RETAILSALE_39--(LocId 3 digit change by Sanjay:06-11-2024)
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
		SELECT a.*,c.article_no,c.article_name ,d.quantity_in_stock
	FROM CMD_CONS a (NOLOCK)
	JOIN SKU b  (NOLOCK) ON b.product_code=a.product_code
	JOIN ARTICLE c  (NOLOCK) ON c.article_code=b.article_code
	JOIN CMM01106 m (NOLOCK) ON m.cm_id=a.cm_id
	LEFT OUTER JOIN PMT01106 d  (NOLOCK) ON d.product_code=b.product_code and a.bin_id =d.BIN_ID and d.DEPT_ID =m.location_Code
	WHERE a.cm_id=@cwhere
	

end
