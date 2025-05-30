CREATE PROCEDURE SP_BUYERSORDER_WSL_19
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
	DECLARE @CCMD NVARCHAR(MAX)
	SET @CCMD = N'SELECT CONVERT(BIT,1) AS BILLCHECK,B.TMD_ROW_ID,C.ATTRIBUTE_CODE,C.ATTRIBUTE_NAME,C.ATTRIBUTE_GROUP ,B.*
		FROM ATTRM (NOLOCK) C 
		JOIN TDD01106 (NOLOCK) B ON   C.ATTRIBUTE_CODE = B.ATTRIBUTE_CODE
		JOIN BUYER_ORDER_DET (NOLOCK) A ON B.TMD_ROW_ID = A.ROW_ID
		WHERE C.ATTRIBUTE_TYPE = 5 AND C.INACTIVE = 0 
		AND A.ORDER_ID = '''+@CMEMOID+''''
		
		IF @NNAVMODE = 1
		BEGIN
			SET @CCMD = @CCMD + N' UNION
			SELECT CONVERT(BIT,CASE WHEN ISNULL(D.TMD_ROW_ID,'''') = '''' THEN 0 ELSE 1 END ) AS BILLCHECK,
			A.ROW_ID AS TMD_ROW_ID
			,C.ATTRIBUTE_CODE,C.ATTRIBUTE_NAME,C.ATTRIBUTE_GROUP
			,B.*
			FROM BUYER_ORDER_DET (NOLOCK) A 
			LEFT OUTER JOIN TDD01106 (NOLOCK) B ON B.TMD_ROW_ID = A.ROW_ID AND 1=2
			CROSS JOIN ATTRM (NOLOCK) C 
			LEFT OUTER JOIN
				(SELECT B.TMD_ROW_ID,C.ATTRIBUTE_CODE FROM ATTRM (NOLOCK) C 
				 JOIN TDD01106 (NOLOCK) B ON   C.ATTRIBUTE_CODE = B.ATTRIBUTE_CODE
				 JOIN BUYER_ORDER_DET (NOLOCK) A ON B.TMD_ROW_ID = A.ROW_ID
				 WHERE C.ATTRIBUTE_TYPE = 5 AND C.INACTIVE = 0
				 AND A.ORDER_ID = '''+@CMEMOID+''' ) D 
				 ON A.ROW_ID = D.TMD_ROW_ID AND C.ATTRIBUTE_CODE = D.ATTRIBUTE_CODE
			WHERE C.ATTRIBUTE_TYPE = 5 AND C.INACTIVE = 0  AND 
			A.ORDER_ID = '''+@CMEMOID+''' AND 
			CONVERT(BIT,CASE WHEN ISNULL(D.TMD_ROW_ID,'''') = '''' THEN 0 ELSE 1 END ) = 0'
		END
		
		
	PRINT @CCMD      
    EXECUTE SP_EXECUTESQL @CCMD   
END