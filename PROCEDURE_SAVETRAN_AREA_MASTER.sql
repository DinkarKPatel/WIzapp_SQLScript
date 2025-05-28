CREATE PROC [DBO].[SAVETRAN_AREA_MASTER]            
@AREANAME VARCHAR(100),                
@AREACODE VARCHAR(7),    
@CITYCODE VARCHAR(7),             
@PINCODE VARCHAR(15),  
@COMPANYCODE VARCHAR(10),  
@ISACTIVE BIT,            
@STATUS INT OUTPUT  
  
AS                                   
BEGIN                    
    
DECLARE @CERRMSG VARCHAR(1000)  
                     
SET @STATUS=0                               
IF NOT EXISTS(SELECT * FROM AREA WHERE AREA_NAME=@AREANAME)          
BEGIN                                         
       
DECLARE @CNEW_AREA_CODE VARCHAR(10)                  
           
LBLNEWCODE:                  
EXEC GETNEXTKEY @CTABLENAME='AREA'                  
       ,@CCOLNAME='AREA_CODE'                  
       ,@NWIDTH='7'                  
       ,@CPREFIX='P0'                  
       ,@NLZEROS=1                  
       ,@CFINYEAR=''                  
       ,@NROWCOUNT=0                  
       ,@CNEWKEYVAL=@CNEW_AREA_CODE OUTPUT                   
                               
                       
 INSERT AREA(CITY_CODE,LAST_UPDATE,INACTIVE,COMPANY_CODE,AREA_CODE,AREA_NAME,PINCODE )VALUES(@CITYCODE,GETDATE(),@ISACTIVE,@COMPANYCODE, @CNEW_AREA_CODE, @AREANAME ,@PINCODE)  
            
SET @STATUS=1   
SET @CERRMSG='RECORD SAVE'                                
END                          
ELSE     
BEGIN                            
   SET @STATUS=0      
   SET @CERRMSG='AREA ALREADY EXISTS'   
END  
SELECT @CERRMSG,ISNULL(@STATUS,0)AS AREAKEY  
END
