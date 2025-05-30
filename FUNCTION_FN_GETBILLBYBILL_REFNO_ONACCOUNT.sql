CREATE FUNCTION FN_GETBILLBYBILL_REFNO_ONACCOUNT(@CACCODE CHAR(10))
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @CRETREFNO VARCHAR(100),@BLOOP BIT
	
	
	
	SET @BLOOP=1
	
	WHILE @BLOOP=1
	BEGIN
		SELECT @CRETREFNO=LEFT(REF_NO,10)  FROM VW_GENNEWID
		
		IF NOT EXISTS (SELECT TOP 1 REF_NO FROM BILL_BY_BILL_REF a (NOLOCK) 
					   JOIN vd01106 b (NOLOCK) ON a.vd_id=b.vd_id	
							WHERE REF_NO=@CRETREFNO AND ac_code=@CACCODE)
			BREAK 
	END	
	
	RETURN @CRETREFNO
END
