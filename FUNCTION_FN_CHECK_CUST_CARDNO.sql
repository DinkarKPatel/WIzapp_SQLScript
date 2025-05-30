CREATE FUNCTION FN_CHECK_CUST_CARDNO
(
@CCARD_NO VARCHAR(50),
@CUSTOMER_CODE VARCHAR(12)
)
RETURNS BIT
AS
BEGIN
          DECLARE @LRETVAL BIT
	      SET @LRETVAL = 1
  
  IF EXISTS(SELECT TOP 1'U' FROM CONFIG WHERE CONFIG_OPTION='CHK_DUP_CARD_NO' AND VALUE='1')
	BEGIN
	
	  IF EXISTS(SELECT CARD_NO FROM CUSTDYM WHERE CARD_NO=@CCARD_NO AND CUSTOMER_CODE<>@CUSTOMER_CODE
	   AND ISNULL(CARD_NO,'')<>'')
	   SET @LRETVAL=0
	       
	END
			    	
         RETURN @LRETVAL
END
