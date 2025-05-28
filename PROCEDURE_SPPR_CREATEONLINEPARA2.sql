CREATE PROC SPPR_CREATEONLINEPARA2            
@NMODE   INT, --(0)-INSERT, (2) - UPDATE             
@PARANAME VARCHAR(100),      
@PARATABLENAME VARCHAR(100)      
                  
AS                                   
BEGIN                    
                       
      
 DECLARE @CNEW_PARA_CODE VARCHAR(10)       
      
IF (@NMODE=1)               
      
      
IF @PARATABLENAME='PARA2' BEGIN         
                    
IF NOT EXISTS(SELECT * FROM PARA1 WHERE PARA1_NAME=@PARANAME)          
                       
 BEGIN         
                  
                 
EXEC GETNEXTKEY @CTABLENAME='PARA2'                 
       ,@CCOLNAME='PARA2_CODE'                  
       ,@NWIDTH='7'                  
       ,@CPREFIX='P0'                  
       ,@NLZEROS=1                  
       ,@CFINYEAR=''                  
       ,@NROWCOUNT=0                  
       ,@CNEWKEYVAL=@CNEW_PARA_CODE OUTPUT                   
                         
       SELECT @CNEW_PARA_CODE                  
                   
                
                      
  INSERT PARA2(PARA2_CODE, PARA2_NAME,INACTIVE, LAST_UPDATE, ALIAS,  PARA2_ORDER, PARA2_SET, REMARKS, BL_PARA2_NAME, LAST_MODIFIED_ON)      
  VALUES (@CNEW_PARA_CODE,@PARANAME,0,GETDATE(),'',0,'','','',GETDATE())                                  
      
    END                          
           
END        
       
   
      
END
