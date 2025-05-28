CREATE PROC SAVETRAN_SIZEGROUP_MASTER        
@NMODE   INT, --(0)-INSERT, (2) - UPDATE         
@GROUPNAME VARCHAR(100),            
@GROUPCODE VARCHAR(7),  
@GROUPREMARKS VARCHAR(500),    
@ALIAS VARCHAR(500),   
@ISACTIVE BIT,        
@STATUS INT OUTPUT                
AS                               
BEGIN                                  
	SET @STATUS=0  
	DECLARE @CERRORMSG VARCHAR(500)='',@CSTEP VARCHAR(10)=''
	
	BEGIN TRY  
	BEGIN TRANSACTION  
			IF (@NMODE=1)               
				BEGIN   
					SET @CSTEP='10'                   
					IF NOT EXISTS(SELECT * FROM PPC_SIZEGROUP WHERE SIZEGROUP_NAME=@GROUPNAME)                           
					BEGIN                                    
						DECLARE @CNEW_SIZEGROUP_CODE VARCHAR(10)                           
						EXEC GETNEXTKEY @CTABLENAME='PPC_SIZEGROUP'              
					   ,@CCOLNAME='SIZEGROUP_CODE'              
					   ,@NWIDTH='7'              
					   ,@CPREFIX='00'              
					   ,@NLZEROS=1              
					   ,@CFINYEAR=''              
					   ,@NROWCOUNT=0              
					   ,@CNEWKEYVAL=@CNEW_SIZEGROUP_CODE OUTPUT               
						                     
						SELECT @CNEW_SIZEGROUP_CODE              
					     SET @CSTEP='20'            
						INSERT PPC_SIZEGROUP(SIZEGROUP_CODE,SIZEGROUP_NAME,REMARKS,INACTIVE,LAST_UPDATE,ALIAS)  
						VALUES (@CNEW_SIZEGROUP_CODE,@GROUPNAME,@GROUPREMARKS,@ISACTIVE,GETDATE(),@ALIAS)                              
						SET @STATUS=1                            
					END                      
					ELSE 
					BEGIN                        
					 SET @STATUS=0                         
					END        
				END 
				   
			ELSE IF (@NMODE=2)      
				BEGIN  
					SET @CSTEP='30'        
					UPDATE PPC_SIZEGROUP SET SIZEGROUP_NAME=@GROUPNAME,REMARKS=@GROUPREMARKS,INACTIVE=@ISACTIVE,ALIAS=@ALIAS WHERE SIZEGROUP_CODE=@GROUPCODE    
					SET @STATUS=1    
				END  
				
			ELSE IF (@NMODE=0)      
				BEGIN  
					SET @CSTEP='40'        
					DELETE FROM PPC_SIZEGROUP WHERE SIZEGROUP_CODE=@GROUPCODE    
					SET @STATUS=1    
				END   
		END TRY
		BEGIN CATCH
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		END CATCH
		
	END_PROC:
	IF @@TRANCOUNT>0
		BEGIN
			IF ISNULL(@CERRORMSG,'')='' 
				COMMIT TRANSACTION
			ELSE
				ROLLBACK
		END	                                                                         
	SELECT ISNULL(@STATUS,0) AS PKEY ,@CERRORMSG AS ERRMSG         	                                                          
END
