CREATE PROCEDURE SP3S_AUTOPOSRECO_dnps
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
		SELECT TOP 5000 cancelled,ps_dt memo_dt,ps_id  memo_id,
		ISNULL(total_quantity,0) as quantity,'dnps' as XN_TYPE,a.LAST_UPDATE
		FROM dnps_mst A WITH (NOLOCK)
		WHERE a.ps_dt>@cCutoffDate AND  LEFT(a.ps_id,2)=@cLocIdPara AND ISNULL(auto_posreco_last_update,'')<>a.last_update
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
		LEFT OUTER JOIN dnps_mst b (NOLOCK)	ON a.memo_id=b.ps_id
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND (a.quantity<>ISNULL(b.TOTAL_QUANTITY,0) OR 
		a.cancelled<>ISNULL(b.cancelled ,0)	OR a.memo_dt<>ISNULL(b.ps_dt,''''))'

		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @nMode=3
	BEGIN
		SET @cStep='60'
		UPDATE B SET auto_posreco_last_update=a.last_update
		FROM dnps_mst B (NOLOCK) JOIN #auto_posreco_data_upload a (NOLOCK) ON a.memo_id=b.ps_id 
		WHERE a.xn_type='dnps'

		SET @cStep='70'
		UPDATE B SET HO_SYNCH_LAST_UPDATE=''
		FROM dnps_mst B (NOLOCK) JOIN #auto_posreco_data_mismatch a (NOLOCK) ON a.memo_id=b.ps_id 
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETPOSRECO_DNPS_DATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END