CREATE PROCEDURE SP_BUYERSORDER_WSL_32
@CMEMOID VARCHAR(40),  
@CWHERE VARCHAR(500),  
@CFINYEAR VARCHAR(10),  
@NNAVMODE NUMERIC(2,0),
@CARTICLECODE CHAR(9)='',  
@CPARA2CODE CHAR(7)='',
@DTWHERE DATETIME ='',
@cLocId VARCHAR(5)=''
--WITH ENCRYPTION
 
AS    
BEGIN 
SELECT A.article_no,A.article_name ,'BOM Not Specified' AS [Message]
	FROM ARTICLE	A
	JOIN BUYER_ORDER_DET B ON B.article_code=A.article_code
	LEFT OUTER JOIN ART_BOM C ON C.article_code=A.article_code
	WHERE C.article_code IS NULL AND B.order_id=@CMEMOID
	GROUP BY A.article_no,A.article_name,A.article_code
END