CREATE PROCEDURE SP_BUYERSORDER_WSL_4
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
	SELECT A.PARA1_CODE, A.PARA1_NAME FROM PARA1 A (NOLOCK)      
	WHERE PARA1_NAME <> '' AND INACTIVE = 0     
	ORDER BY A.PARA1_NAME    
END