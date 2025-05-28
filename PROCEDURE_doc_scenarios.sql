CREATE PROCEDURE doc_scenarios
AS
BEGIN
	---Debit note/Wholesale
	/* 1. In this Scenario , User changes the Discount at Bill level in Editmode of Memo and adds New Pack slip/Box
		  where gst columns of previous box/Pack slip in the same memo also need to be updated agst Discount change.
		  We have to make two copies of previous data where one copy has older data & 2nd copy need to have data
		  in which gst columns will be recalculated . We shall compare these two copies to get the changed columns
		  based upon whihc Final update statement will be generated for detail table.
	*/
	RETURN
END