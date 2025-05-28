CREATE PROCEDURE SP3S_CANCEL_AUTOVOUCHERS
@cXntype VARCHAR(15),
@cMemoId VARCHAR(50)
AS
BEGIN
	---Removed this as per discussion between Ved and Sir because we will not cancel the voucher through Posting only (Date:28-01-2022)
	RETURN

END