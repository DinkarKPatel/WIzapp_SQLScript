CREATE FUNCTION FN_CheckARTBOM 
(  
 @cArticleCode varchar(10),  
 @cbom_article_code varchar(10),  
 @cjob_code varchar(10)  
) RETURNS bit AS 
 BEGIN  
	 
	  DECLARE @lRetVal bit
	  set @lRetVal=1
	  IF EXISTS ( SELECT article_code        FROM art_bom       WHERE article_code 		= @cArticleCode       
	  AND bom_article_code    = @cbom_article_code and JOB_CODE = @cjob_code and ISNULL(job_code,'0000000')<>'0000000'
	  group by article_code having COUNT(*)>1  )    
	  SET @lRetVal = 0  
	 
 RETURN @lRetVal 
 END 
