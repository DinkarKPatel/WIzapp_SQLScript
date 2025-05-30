
-- FUNCTION TO GET VS VD_ID FOR A GIVEN VD_ID
-- THE VD_ID WITH MAXIMUM AMOUNT OF REVERSE XN_TYPE WILL BE RETURNED
CREATE FUNCTION FN_ACT_GETREVERSEVD
(
	@CVDID VARCHAR(40)
)
RETURNS VARCHAR(40)
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CVMID VARCHAR(40), @CXTYPE VARCHAR(10), @CRETVDID VARCHAR(40)
	SELECT @CVMID = VM_ID, @CXTYPE = X_TYPE FROM VD01106 WHERE VD_ID = @CVDID
	SELECT TOP 1 @CRETVDID = VD_ID FROM VD01106 WHERE VM_ID = @CVMID AND X_TYPE <> @CXTYPE ORDER BY (DEBIT_AMOUNT + CREDIT_AMOUNT) DESC
	RETURN @CRETVDID
END
--**************************************** END OF FUNCTION FN_ACT_GETREVERSEVD
