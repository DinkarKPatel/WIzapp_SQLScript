CREATE PROCEDURE SP3S_DEFAULT_PAYMENT_MST
AS
BEGIN
	SELECT paymode_code,paymode_name FROM PAYMODE_MST
	WHERE PAYMODE_CODE IN (
	'0000000','0000001','0000002','0000003','0000004','0000005','0000006',
	'CMR0001','TPL0001','GVC0001','GVADJW8','PYTGUPI','EDC0001','EDC0002',
	'EDC0003','EDC0004','EDC0005','EDC0006','EDC0007','EDC0008')
END