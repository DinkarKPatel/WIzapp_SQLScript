CREATE PROCEDURE SP3S_AUTOPOSRECO_SNC
@nMode NUMERIC(1,0),
@cLocIdPara CHAR(2)='',
@cCutoffDate VARCHAR(20)='',
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

		INSERT INTO #auto_posreco_data_upload (cancelled,memo_dt,memo_id,quantity,XN_TYPE,LAST_UPDATE,entry_type)
		SELECT TOP 5000 cancelled,receipt_dt receipt_dt,memo_ID  memo_id,
		ISNULL(total_quantity,0) as quantity,'SNC' as XN_TYPE,a.LAST_UPDATE,1 entry_type
		FROM snc_mst A WITH (NOLOCK)
		WHERE a.receipt_dt>@cCutoffDate AND LEFT(a.memo_ID,2)=@cLocIdPara AND ISNULL(auto_posreco_last_update,'')<>a.last_update
		
		UNION ALL
		SELECT TOP 5000 cancelled,receipt_dt receipt_dt,memo_ID  memo_id,
		ISNULL(total_consumed_quantity,0) as quantity,'SNC' as XN_TYPE,a.LAST_UPDATE,2 entry_type
		FROM snc_mst A WITH (NOLOCK)
		WHERE a.receipt_dt>@cCutoffDate AND LEFT(a.memo_ID,2)=@cLocIdPara AND ISNULL(auto_posreco_last_update,'')<>a.last_update

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
		LEFT OUTER JOIN snc_mst b (NOLOCK)	ON a.memo_id=b.memo_ID
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND a.entry_type=1 AND (a.quantity<>ISNULL(b.TOTAL_QUANTITY,0) OR 
		a.cancelled<>ISNULL(b.cancelled ,0)	OR a.memo_dt<>ISNULL(b.receipt_dt,''''))
		UNION
		SELECT a.memo_id FROM ##auto_posreco_data_upload_'+@cLocIdPara+' a 
		LEFT OUTER JOIN snc_mst b (NOLOCK)	ON a.memo_id=b.memo_ID
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND  a.entry_type=2 AND a.quantity<>ISNULL(b.total_consumed_quantity,0)'

		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @nMode=3
	BEGIN
		SET @cStep='60'
		UPDATE B SET auto_posreco_last_update=a.last_update
		FROM snc_mst B (NOLOCK) JOIN #auto_posreco_data_upload a (NOLOCK) ON a.memo_id=b.memo_ID 
		WHERE a.xn_type='SNC'

		SET @cStep='70'
		UPDATE B SET HO_SYNCH_LAST_UPDATE=''
		FROM snc_mst B (NOLOCK) JOIN #auto_posreco_data_mismatch a (NOLOCK) ON a.memo_id=b.memo_ID 
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETPOSRECO_SNC_DATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END