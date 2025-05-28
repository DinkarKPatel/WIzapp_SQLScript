CREATE PROC [DBO].[SAVETRAN_CITY_MASTER1]            
@CITYNAME VARCHAR(100),                
@CITYCODE VARCHAR(7),             
@STATECODE VARCHAR(7),   
  
@COMPANYCODE VARCHAR(10),  
@ISACTIVE BIT,            
@STATUS INT OUTPUT  
  
AS                                   
BEGIN                    
    
DECLARE @CERRMSG VARCHAR(1000)  
                     
SET @STATUS=0                               
IF NOT EXISTS(SELECT * FROM CITY WHERE CITY=@CITYNAME)          
BEGIN                                         
       
DECLARE @CNEW_CITY_CODE VARCHAR(10)                  
           
LBLNEWCODE:                  
EXEC GETNEXTKEY @CTABLENAME='CITY'                  
       ,@CCOLNAME='CITY_CODE'                  
       ,@NWIDTH='7'                  
       ,@CPREFIX='P0'                  
       ,@NLZEROS=1                  
       ,@CFINYEAR=''                  
       ,@NROWCOUNT=0                  
       ,@CNEWKEYVAL=@CNEW_CITY_CODE OUTPUT                   
                               
                       
INSERT INTO CITY(CITY_CODE,CITY,LAST_UPDATE,STATE_CODE,INACTIVE,DISTT_CODE,COMPANY_CODE )VALUES(@CNEW_CITY_CODE, @CITYNAME, GETDATE(), @STATECODE, @ISACTIVE, '0000000', @COMPANYCODE)            
SET @STATUS=1                                
END                          
ELSE     
BEGIN                            
   SET @STATUS=0      
   SET @CERRMSG='CITY ALREADY EXISTS'   
END  
SELECT @CERRMSG,ISNULL(@STATUS,0)AS CITYKEY  
END
