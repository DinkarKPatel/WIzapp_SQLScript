CREATE PROCEDURE SP_RETAILSALE_25--(LocId 3 digit change only increased the parameter width by Sanjay:30-10-2024)
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
	  SELECT * FROM dtm where wizclip_discount <> 1 and isnull(inactive,0)=0
end
