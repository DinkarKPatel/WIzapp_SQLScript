CREATE PROCEDURE SP_BUYERSORDER_WSL_7
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
	SELECT PARA4_CODE, PARA4_NAME FROM PARA4 (NOLOCK)  
	WHERE PARA4_NAME <> '' AND INACTIVE = 0     
	ORDER BY PARA4_NAME  
END