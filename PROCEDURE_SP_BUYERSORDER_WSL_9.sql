CREATE PROCEDURE SP_BUYERSORDER_WSL_9
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
	SELECT PARA6_CODE, PARA6_NAME FROM PARA6 (NOLOCK)  
	WHERE PARA6_NAME <> ''   AND INACTIVE = 0  
	ORDER BY PARA6_NAME
END