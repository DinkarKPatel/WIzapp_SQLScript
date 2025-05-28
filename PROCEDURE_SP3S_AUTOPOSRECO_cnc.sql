CREATE PROCEDURE SP3S_AUTOPOSRECO_cnc
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

		INSERT INTO #auto_posreco_data_upload (cancelled,memo_dt,memo_id,quantity,XN_TYPE,LAST_UPDATE)
		SELECT TOP 5000 cancelled,cnc_memo_dt memo_dt,CNC_MEMO_ID  memo_id,
		ISNULL(total_quantity,0) as quantity,'CNC' as XN_TYPE,a.LAST_UPDATE
		FROM icm01106 A WITH (NOLOCK)
		WHERE a.CNC_memo_dt>@cCutoffDate AND LEFT(a.CNC_MEMO_ID,2)=@cLocIdPara AND ISNULL(auto_posreco_last_update,'')<>a.last_update
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
		LEFT OUTER JOIN icm01106 b (NOLOCK)	ON a.memo_id=b.CNC_MEMO_ID
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND (a.quantity<>ISNULL(b.TOTAL_QUANTITY,0) OR 
		a.cancelled<>ISNULL(b.cancelled ,0)	OR a.memo_dt<>ISNULL(b.cnc_memo_dt,''''))'

		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @nMode=3
	BEGIN
		SET @cStep='60'
		UPDATE B SET auto_posreco_last_update=a.last_update
		FROM icm01106 B (NOLOCK) JOIN #auto_posreco_data_upload a (NOLOCK) ON a.memo_id=b.CNC_MEMO_ID 
		WHERE a.xn_type='CNC'

		SET @cStep='70'
		UPDATE B SET HO_SYNCH_LAST_UPDATE=''
		FROM icm01106 B (NOLOCK) JOIN #auto_posreco_data_mismatch a (NOLOCK) ON a.memo_id=b.CNC_MEMO_ID 
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETPOSRECO_cnc_DATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END