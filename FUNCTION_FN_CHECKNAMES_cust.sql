CREATE FUNCTION FN_CHECKNAMES_cust 
(  @CCustCODE VARCHAR(12),  @Cmobile VARCHAR(50),  @CUSerCustomerCode VARCHAR(50)) 
RETURNS BIT 
AS 
BEGIN
	DECLARE @LRETVAL BIT  
	SET @LRETVAL = 1    
    
	IF EXISTS ( SELECT customer_CODE FROM custdym  WHERE  user_customer_code = @CUSerCustomerCode  AND customer_code <> @CCustCODE AND user_customer_code not in ('','0000000000','000000000000'))    
			SET @LRETVAL = 0 
	ELSE
	IF EXISTS ( SELECT customer_CODE FROM custdym  WHERE  mobile = @Cmobile  AND customer_code <> @CCustCODE AND mobile not in (''))    
			SET @LRETVAL = 0 

	 RETURN @LRETVAL 
END 


