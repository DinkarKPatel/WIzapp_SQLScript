					 
IF NOT EXISTS ( SELECT PAYMODE_CODE FROM PAYMODE_MST WHERE PAYMODE_CODE = 'CMR0001' )
BEGIN	
	UPDATE PAYMODE_MST SET PAYMODE_NAME='CREDIT REFUND['+LTRIM(RTRIM(PAYMODE_CODE))+']' WHERE PAYMODE_NAME='CREDIT REFUND'					 
	
	INSERT PAYMODE_MST( PAYMODE_CODE, PAYMODE_NAME, PAYMODE_GRP_CODE, CREDIT_LIMIT, 
						COMMISSION_PERCENTAGE, LAST_UPDATE,  SERVICE_TAX_PERCENTAGE, 
						INACTIVE, CURRENCY_CONVERSION_RATE, COMMISSION_PERCENTAGE_PAYABLE, 
						 AC_CODE,COMMISSION_AC_CODE )  
	VALUES ( 'CMR0001','CREDIT REFUND',	'0000004',0.00,0.000, GETDATE(),  0.00, 0, 1.00, 0.00, 
						 '0000000000', '0000000000')						 
END
ELSE
	UPDATE PAYMODE_MST SET PAYMODE_GRP_CODE='0000004' WHERE PAYMODE_CODE = 'CMR0001'
	
		
