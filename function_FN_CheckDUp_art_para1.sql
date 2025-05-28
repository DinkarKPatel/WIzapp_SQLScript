create FUNCTION FN_CheckDUp_art_para1
( @cRowId varchar(40)) 
 RETURNS bit 
 AS 
BEGIN  
	DECLARE @lRetVal bit,@cArticle_code char(10),@creplaceable_para1_code char(9)
			  
	SET @lRetVal = 1    

	SELECT @cArticle_code=article_code ,@creplaceable_para1_code=replaceable_para1_code from art_para1 (nolock)
	WHERE row_id=@cRowId
	
	IF ISNULL(@creplaceable_para1_code,'') not in('','0000000')
	BEGIN
		IF EXISTS ( SELECT TOP 1 article_code FROM art_para1 a  (nolock)
					WHERE a.article_code= @cArticle_code AND replaceable_para1_code=@creplaceable_para1_code
					and a.row_id<>@cRowId )
			SET @lRetVal=0
	
	END
	
	RETURN @lRetVal 
 END 




		