CREATE PROCEDURE SP3S_UPDATE_SISLOC_SALEVAL_DIFFERENCES
@nSpId VARCHAR(40),
@cRetainExcelNrv VARCHAR(5)
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)

	IF @cRetainExcelNrv='1'
		UPDATE SLS_CMD01106_UPLOAD WITH (ROWLOCK) SET sisloc_itemnet_difference=((mrp*quantity)-ROUND(mrp*quantity*discount_percentage/100,2))-net,
		sisloc_gst_difference=(net-(xn_value_without_gst+ROUND(xn_value_without_gst*gst_percentage/100,2)))
		WHERE sp_id=@nSpId
	ELSE
		UPDATE SLS_CMD01106_UPLOAD WITH (ROWLOCK) SET sisloc_itemnet_difference=((sisloc_mrp*quantity)-ROUND(sisloc_mrp*quantity*sisloc_eoss_discount_percentage/100,2))-sis_net,
		sisloc_gst_difference=(sis_net-(sisloc_taxable_value+ROUND(sisloc_taxable_value*gst_percentage/100,2)))
		WHERE sp_id=@nSpId
	
END
