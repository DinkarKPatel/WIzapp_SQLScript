CREATE PROCEDURE SP3S_CHECKNAMES_cust 
@CCustCODE VARCHAR(12),  
@Cmobile VARCHAR(50),  
@CUSerCustomerCode VARCHAR(50) 
AS 
BEGIN
	DECLARE @LRETVAL BIT,@cCustomerName VARCHAR(300),@cOtherCustCode CHAR(12),@cErrormsg VARCHAR(500) 

	SET @LRETVAL = 1    
    
	SELECT TOP 1  @cCustomerName=customer_fname+' '+customer_lname,@cOtherCustCode=customer_code
	FROM custdym  WHERE  user_customer_code = @CUSerCustomerCode  AND customer_code <> @CCustCODE 
	AND user_customer_code not in ('','0000000000','000000000000') AND INACTIVE=0

	IF ISNULL(@cOtherCustCode,'')<>''
	BEGIN
		SET @cErrormsg='Duplicate Customer found with Name :'+@cCustomerName+' with Customer code:'+@cOtherCustCode+
						' having same Customer Id....Cannot save'
		GOTO END_PROC
	END

	SELECT TOP 1  @cCustomerName=customer_fname+' '+customer_lname,@cOtherCustCode=customer_code
	FROM custdym  WHERE  MOBILE = @CUSerCustomerCode  AND customer_code <> @CCustCODE 
	AND user_customer_code not in ('','0000000000','000000000000') AND INACTIVE=0

	IF ISNULL(@cOtherCustCode,'')<>''
	BEGIN
		SET @cErrormsg='Duplicate Customer found with Name :'+@cCustomerName+' with Customer code:'+@cOtherCustCode+
						' having Mobile no. same as Current Customer Id....Cannot save'
		GOTO END_PROC
	END

	SELECT TOP 1  @cCustomerName=customer_fname+' '+customer_lname,@cOtherCustCode=customer_code
	FROM custdym  WHERE  mobile = @Cmobile  AND customer_code <> @CCustCODE 
	AND mobile not in ('') AND INACTIVE=0

	IF ISNULL(@cOtherCustCode,'')<>''
	BEGIN
		SET @cErrormsg='Duplicate Customer found with Name :'+@cCustomerName+' with Customer code:'+@cOtherCustCode+
						' having same Mobile no....Cannot save'
		GOTO END_PROC
	END	

	SELECT TOP 1  @cCustomerName=customer_fname+' '+customer_lname,@cOtherCustCode=customer_code
	FROM custdym  WHERE  user_customer_code = @Cmobile  AND customer_code <> @CCustCODE 
	AND mobile not in ('') AND INACTIVE=0

	IF ISNULL(@cOtherCustCode,'')<>''
	BEGIN
		SET @cErrormsg='Duplicate Customer found with Name :'+@cCustomerName+' with Customer code:'+@cOtherCustCode+
						' having  Customer Id same as Current Mobile no....Cannot save'
		GOTO END_PROC
	END	

END_PROC:
	
	SELECT ISNULL(@cErrormsg,'') as errmsg
END 


