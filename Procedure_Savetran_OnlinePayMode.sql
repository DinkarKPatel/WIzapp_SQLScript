CREATE	Procedure Savetran_OnlinePayMode--(LocId 3 digit change by Sanjay:06-11-2024)
(
  @CPAYMODENAME varchar(100),
  @CLOCATIONID varchar(4),
  @CERRORMSG varchar(1000) output

)
as
begin
      
	  Declare @CERRMSG varchar(1000),@CPAYMODEVAL varchar(10)

BEGIN TRY             
 
        
		lblGenPaymode:


		        EXEC DBO.GETNEXTKEY 'PAYMODE_MST', 'paymode_code', 7, @CLOCATIONID, 1, '', 2, @CPAYMODEVAL OUTPUT 

					IF @CPAYMODEVAL IS NULL  OR @CPAYMODEVAL LIKE '%LATER%'
					BEGIN
						  SET @CERRORMSG = ' ERROR CREATING NEW PAYMODE ....'	
						  GOTO END_PROC  		
					END

					IF  EXISTS (SELECT TOP 1 'U' FROM PAYMODE_MST WITH (NOLOCK) WHERE PAYMODE_NAME =@CPAYMODENAME)
					    GOTO LBLGENPAYMODE

					 INSERT paymode_mst	( ac_code, commission_ac_code, commission_percentage, commission_percentage_payable, credit_limit, currency_conversion_rate, inactive, last_update, paymode_code, paymode_grp_code, paymode_name, service_tax_percentage )  
					 SELECT 	'0000000000'  ac_code,'0000000000' commission_ac_code, 0 commission_percentage,0 commission_percentage_payable, 
					            0 credit_limit,0 currency_conversion_rate,0 inactive,getdate() last_update,@CPAYMODEVAL paymode_code,'0000002' paymode_grp_code, 
								@CPAYMODENAME paymode_name,0 service_tax_percentage 
					
	
END TRY                        
                         
BEGIN CATCH                       
  PRINT 'ENTER CATCH BLOCK'                     
  SET @CERRMSG='Savetran_OnlinePayMode  MESSAGE - '+ERROR_MESSAGE()                                   
  GOTO END_PROC                         
END CATCH                        
                         
END_PROC:         



 end