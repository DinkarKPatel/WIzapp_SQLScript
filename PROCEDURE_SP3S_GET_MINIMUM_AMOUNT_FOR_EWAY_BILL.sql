CREATE PROCEDURE SP3S_GET_MINIMUM_AMOUNT_FOR_EWAY_BILL
(
	@cSourceDeptID			VARCHAR(10),
	@cTargetGSTStateCode	VARCHAR(10)
)
AS
BEGIN
	DECLARE @cSourceGSTStateCode	VARCHAR(10),@nAmount NUMERIC(14,2)
	
	select @cSourceGSTStateCode=gst_state_code from location where dept_id=@cSourceDeptID

	select @nAmount =(CASE WHEN gst_state_code=@cTargetGSTStateCode THEN EWAY_BILL_AMOUNT_LOCAL ELSE EWAY_BILL_AMOUNT_INTERSTATE END) from gst_state_mst(NOLOCK) WHERE  gst_state_code=ISNULL(@cSourceGSTStateCode,'')

	SELECT ISNULL(@nAmount,0) AS MINIMUM_AMOUNT_FOR_EWAY_BILL
END