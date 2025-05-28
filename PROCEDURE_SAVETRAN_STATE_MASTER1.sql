CREATE PROC [DBO].[SAVETRAN_STATE_MASTER1]        
@STATENAME VARCHAR(100),                
@STATECODE VARCHAR(7),  
@COMPANYCODE VARCHAR(10),  
@ISACTIVE BIT,            
@STATUS INT OUTPUT  
  
AS                                   
BEGIN                    
    
DECLARE @CERRMSG VARCHAR(1000)  
                     
SET @STATUS=0                               
IF NOT EXISTS(SELECT * FROM STATE WHERE STATE=@STATENAME)          
BEGIN                                         
       
DECLARE @CNEW_STATE_CODE VARCHAR(10)                  
           
LBLNEWCODE:                  
EXEC GETNEXTKEY @CTABLENAME='STATE'                  
       ,@CCOLNAME='STATE_CODE'                  
       ,@NWIDTH='7'                  
       ,@CPREFIX='P0'                  
       ,@NLZEROS=1                  
       ,@CFINYEAR=''                  
       ,@NROWCOUNT=0                  
       ,@CNEWKEYVAL=@CNEW_STATE_CODE OUTPUT     
                       
                               
                       
  INSERT INTO STATE(STATE_CODE, STATE, LAST_UPDATE, REGION_CODE, INACTIVE, COMPANY_CODE )VALUES(@CNEW_STATE_CODE, @STATENAME, GETDATE(), '0000000', @ISACTIVE, @COMPANYCODE)  
            
SET @STATUS=1   
SET @CERRMSG='SUCCESSFULLY INSERTED'                               
END                          
ELSE     
BEGIN                            
   SET @STATUS=0      
   SET @CERRMSG='STATE ALREADY EXISTS'   
END  
SELECT @CERRMSG,ISNULL(@STATUS,0)AS STATEKEY  
END
