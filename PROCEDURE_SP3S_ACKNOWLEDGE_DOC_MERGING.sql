create PROCEDURE SP3S_ACKNOWLEDGE_DOC_MERGING
@CXNTYPEPARA VARCHAR(20)='',
@CREQXNID VARCHAR(50),
@cAcklastUpdate VARCHAR(30),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN

BEGIN TRY
	
	DECLARE @cStep VARCHAR(4)

	
	SET @cStep='10'
	SET @cErrormsg =''

	--- As per anil sugestion, Acknowledge it with last_update as Application is not able to handle 
		---- the date returned due to its format getting changed
	IF @CXNTYPEPARA IN ('DOCWSL')
	BEGIN
		SET @cStep='20' 
		UPDATE INM01106 WITH (ROWLOCK) SET doc_synch_last_update=last_update 
		WHERE inv_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA IN ('DOCPRT')
	BEGIN
		SET @cStep='30'
		UPDATE RMM01106 WITH (ROWLOCK) SET doc_synch_last_update=last_update
		WHERE rm_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA='DOCPO'
	BEGIN	
		SET @cStep='40'
		UPDATE POM01106 WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE po_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA='DOCPUR'
	BEGIN		
		SET @cStep='50'
		UPDATE PIM01106 WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE mrr_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA='DOCGV'
	BEGIN		
		SET @cStep='60'
		UPDATE GV_STKXFER_MST WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE memo_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA='DOCPCO'
	BEGIN		
		SET @cStep='70'
		UPDATE PCO_MST WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE memo_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA='DOCASN'
	BEGIN
		SET @cStep='80'
		UPDATE ASN_MST WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE memo_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA='DOCWBO'
	BEGIN		
		SET @cStep='90'
		UPDATE BUYER_ORDER_MST WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE order_id=@CREQXNID
	END
	ELSE
	IF @CXNTYPEPARA IN ('DOCMRP')
	BEGIN
		SET @cStep='100'
		UPDATE locskusp WITH (ROWLOCK) SET sent_to_location=1
		WHERE dept_id=@CREQXNID AND SENT_TO_LOCATION = 0 
	END
	ELSE
	IF @CXNTYPEPARA IN ('DOCDNPF')
	BEGIN
		SET @cStep='110'
		UPDATE DebitNote_Proforma_MST WITH (ROWLOCK) SET doc_synch_last_update=@cAcklastUpdate 
		WHERE Memo_Id=@CREQXNID
		
	END
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_ACKNOWLEDGE_DOC_MERGING at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
END