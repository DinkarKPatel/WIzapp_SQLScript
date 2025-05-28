CREATE PROCEDURE SP3S_AUTOPOSRECO_PUR
@nMode NUMERIC(1,0),
@cLocIdPara CHAR(2)='',
@cCutoffDate VARCHAR(20),
@cErrormsg VARCHAR(MAX) OUTPUT,
@bDataFound BIT OUTPUT
AS
BEGIN
BEGIN TRY
	DECLARE @cStep VARCHAR(4),@nRows NUMERIC(20,0),@cCmd NVARCHAR(MAX)

	SET @cStep='10'
	SET @bDataFound=0
	SET @cErrormsg=''
	
	IF @nMode=1
	BEGIN
		TRUNCATE TABLE #auto_posreco_data_upload

		SET @cStep='20'

		INSERT INTO #auto_posreco_data_upload (cancelled,memo_dt,memo_id,amount,quantity,XN_TYPE,LAST_UPDATE,mode,entry_type)
		
		SELECT TOP 5000 cancelled,receipt_dt memo_dt,mrr_id  memo_id,total_amount as amount,
		ISNULL(total_quantity,0) as quantity,'PUR' as XN_TYPE,a.LAST_UPDATE,a.inv_mode,0 ENTRY_TYPE
		FROM pim01106 A WITH (NOLOCK)
		WHERE a.receipt_dt>@cCutoffDate AND LEFT(a.mrr_id,2)=@cLocIdPara AND ISNULL(auto_posreco_last_update,'')<>a.last_update
		AND (a.inv_mode<>2 OR a.receipt_dt<>'')
		SET @nRows=@@rowcount

		IF @nRows>0
		BEGIN
			SET @bDataFound=1
		END
	END
	ELSE
	IF @nMode=2
	BEGIN
		SET @cCmd=N'SELECT a.memo_id FROM ##auto_posreco_data_upload_'+@cLocIdPara+' a 
		LEFT OUTER JOIN pim01106 b (NOLOCK)	ON a.memo_id=b.mrr_id
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND (a.quantity<>ISNULL(b.TOTAL_QUANTITY,0) OR a.amount<>isnull(b.total_amount,0) OR
		a.cancelled<>ISNULL(b.cancelled ,0)	OR a.memo_dt<>ISNULL(b.receipt_dt,''''))'

		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @nMode=3
	BEGIN
		SET @cStep='60'
		UPDATE B SET auto_posreco_last_update=a.last_update
		FROM pim01106 B (NOLOCK) JOIN #auto_posreco_data_upload a (NOLOCK) ON a.memo_id=b.mrr_id 
		WHERE a.xn_type='PUR'

		SET @cStep='70'
		UPDATE B SET HO_SYNCH_LAST_UPDATE=''
		FROM pim01106 B (NOLOCK) JOIN #auto_posreco_data_mismatch a (NOLOCK) ON a.memo_id=b.mrr_id 
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETPOSRECO_PUR_DATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END