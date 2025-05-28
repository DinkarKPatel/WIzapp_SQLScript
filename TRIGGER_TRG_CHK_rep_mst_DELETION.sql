CREATE TRIGGER TRG_CHK_rep_mst_DELETION ON REP_MST
FOR DELETE
AS
BEGIN
	IF EXISTS (SELECT TOP 1 rep_code FROM DELETED WHERE rep_code='SSU01')
	BEGIN
		IF EXISTS (SELECT TOP 1 memo_no FROM scheme_Setup_det a (NOLOCK) JOIN DELETED b ON a.repid=b.rep_id)
		BEGIN
			RAISERROR('Reference entry found in Scheme setup Title..Cannot delete Filter',16,1)
			ROLLBACK
		END
	END
END
