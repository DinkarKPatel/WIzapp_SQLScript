create PROCEDURE SAVETRAN_BOMUOM_MASTER          
@NMODE   INT, --(0)-INSERT, (2) - UPDATE             
@UOMNAME VARCHAR(100),                
@UOMCODE VARCHAR(7),                            
@ISACTIVE BIT,            
@STATUS INT OUTPUT
AS                                   
BEGIN                    
    
DECLARE @CSTEP VARCHAR(20),@CERRMSG VARCHAR(1000)
SET @CSTEP=00    
BEGIN TRY    
BEGIN TRANSACTION   

 DECLARE @CDEPT_ID VARCHAR(4),@CMEMO_PREFIX VARCHAR(10)
 
 select @CDEPT_ID=value  from config where config_option ='Ho_location_id'

 SET @CMEMO_PREFIX=@CDEPT_ID
  
                     
SET @STATUS=0         
  IF (@NMODE=1)               
	BEGIN                        
		IF NOT EXISTS(SELECT * FROM PPC_BOM_UOM WHERE CONVERSION_UOM_NAME=@UOMNAME)          
		BEGIN                                         
		DECLARE @CNEW_UOM_CODE VARCHAR(10)                  
		                                
		LBLNEWCODE:                  
		EXEC GETNEXTKEY @CTABLENAME='PPC_BOM_UOM'                  
			   ,@CCOLNAME='CONVERSION_UOM_CODE'                  
			   ,@NWIDTH='7'                  
			   ,@CPREFIX=@CMEMO_PREFIX                  
			   ,@NLZEROS=1                  
			   ,@CFINYEAR=''                  
			   ,@NROWCOUNT=0                  
			   ,@CNEWKEYVAL=@CNEW_UOM_CODE OUTPUT                   
		 
		 IF EXISTS (SELECT TOP 1 'U' FROM PPC_BOM_UOM WHERE CONVERSION_UOM_CODE=@CNEW_UOM_CODE)     
		 GOTO  LBLNEWCODE                        
		                       
		  INSERT PPC_BOM_UOM(CONVERSION_UOM_CODE,CONVERSION_UOM_NAME,INACTIVE)VALUES (@CNEW_UOM_CODE,@UOMNAME,@ISACTIVE)                                  
		  SET @STATUS=1                                
		END                          
		ELSE     
			BEGIN                            
			   SET @STATUS=0      
			   SET @CERRMSG='BOM UOM ALREADY EXISTS'                           
			END            
	END        
  ELSE IF (@NMODE=2)          
	BEGIN        
		UPDATE PPC_BOM_UOM SET CONVERSION_UOM_NAME=@UOMNAME,INACTIVE=@ISACTIVE WHERE CONVERSION_UOM_CODE=@UOMCODE        
		SET @STATUS=1        
	END        
  ELSE IF (@NMODE=0)          
	BEGIN        
		DELETE FROM PPC_BOM_UOM WHERE CONVERSION_UOM_CODE=@UOMCODE        
		SET @STATUS=1        
	END                   
END TRY    
BEGIN CATCH     
 SET @CERRMSG='SAVETRAN_BOMUOM_MASTER: STEP - '+ISNULL(@CSTEP,'')+', MESSAGE - '+ERROR_MESSAGE()     
END CATCH    
    
END_PROC:    
    
IF @@TRANCOUNT>0      
 BEGIN      
  IF ISNULL(@CERRMSG,'')=''     
   COMMIT TRANSACTION      
  ELSE      
   ROLLBACK      
 END                               
	SELECT @CERRMSG AS ERRMSG,ISNULL(@STATUS,0) AS PKEY                               
END
