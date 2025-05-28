CREATE PROC [DBO].[SAVETRAN_JOB_MASTER]            
@NMODE   INT, --(1)-INSERT, (2) - UPDATE  (0) - DELETE           
@JOBNAME VARCHAR(100),                
@JOBCODE VARCHAR(7),      
@JOBRATE DECIMAL(18,2),       
      
@PERDAYS DECIMAL(18,2),       
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
			IF NOT EXISTS(SELECT * FROM JOBS WHERE JOB_NAME=@JOBNAME)                                 
			 BEGIN                                             
				DECLARE @CNEW_JOB_CODE VARCHAR(10)                             
			               
				   EXEC GETNEXTKEY @CTABLENAME='JOBS'                  
					   ,@CCOLNAME='JOB_CODE'                  
					   ,@NWIDTH='7'                  
					   ,@CPREFIX='D0'                  
					   ,@NLZEROS=1                  
					   ,@CFINYEAR=''                  
					   ,@NROWCOUNT=0                  
					   ,@CNEWKEYVAL=@CNEW_JOB_CODE OUTPUT                   
				   SET @CSTEP='20'                                        
				  INSERT JOBS(LAST_UPDATE, JOB_RATE_BASIS, INACTIVE, JOB_CODE, JOB_NAME, COMPANY_CODE, PER_DAYS, JOBRATE)      
				  VALUES (GETDATE(),1,@ISACTIVE,@CNEW_JOB_CODE,@JOBNAME,'D0',@PERDAYS,@JOBRATE)                                  
				 SET @STATUS=1                                
				END                          
			ELSE 
				BEGIN                            
				 SET @STATUS=0                             
				END  
			GOTO END_PROC          
		END 
		       
	ELSE IF (@NMODE=2)          
		BEGIN  
			SET @CSTEP='30'      
			UPDATE JOBS SET JOB_NAME=@JOBNAME,JOBRATE=@JOBRATE,INACTIVE=@ISACTIVE,PER_DAYS=@PERDAYS WHERE JOB_CODE=@JOBCODE        
			SET @STATUS=1  
			GOTO END_PROC      
		END 
		
	ELSE IF (@NMODE=0)          
		BEGIN  
			SET @CSTEP='40'      
			DELETE FROM JOBS WHERE JOB_CODE=@JOBCODE        
			SET @STATUS=1  
			GOTO END_PROC      
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
