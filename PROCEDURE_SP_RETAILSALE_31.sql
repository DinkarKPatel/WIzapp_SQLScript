CREATE PROCEDURE SP_RETAILSALE_31--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
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
	DECLARE @cErrormsg VARCHAR(MAX)
	
	EXEC SP_GETCARD_DISCOUNT_PERCETAGE
	@CCUSTOMERCODE=@cwhere,
	@dRefMemoDt=@CREFMEMODT,
	@cParaCode=@CREFMEMOID,
	@bPickCardDiscforSoldItems=1,
	@cErrormsg=@cErrormsg OUTPUT
	
	IF ISNULL(@cErrormsg,'')<>''
		SELECT @cErrormsg AS errmsg

end
