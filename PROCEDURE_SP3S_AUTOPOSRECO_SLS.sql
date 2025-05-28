create PROCEDURE SP3S_AUTOPOSRECO_SLS
@nMode NUMERIC(1,0),
@cLocIdPara CHAR(2)='',
@cCutoffDate VARCHAR(40),
@cErrormsg VARCHAR(MAX) OUTPUT,
@bDataFound BIT OUTPUT
AS
BEGIN
BEGIN TRY
	DECLARE @cStep VARCHAR(4),@nRows1 NUMERIC(20,0),@nRows2 NUMERIC(20,0),@cCmd NVARCHAR(MAX)

	SET @cStep='10'
	SET @bDataFound=0
	SET @cErrormsg=''
	
	IF @nMode=1
	BEGIN
		TRUNCATE TABLE #auto_posreco_data_upload

		SET @cStep='20'

		INSERT INTO #auto_posreco_data_upload (cancelled,memo_dt,memo_id,amount,quantity,XN_TYPE,LAST_UPDATE,
		paymode_code,entry_type)
		SELECT TOP 5000 cancelled,cm_dt memo_dt,cm_id  memo_id,net_amount as amount,
		total_quantity as quantity,'SLS' as XN_TYPE,a.LAST_UPDATE,CONVERT(CHAR(7),'') AS paymode_code,
		1 AS entry_type
		FROM cmm01106 A WITH (NOLOCK)
		WHERE a.cm_dt>@cCutoffDate AND LEFT(a.cm_id,2)=@cLocIdPara AND ISNULL(auto_posreco_last_update,'')<>a.last_update
		SET @nRows1=@@rowcount

		SET @cStep='30'
		INSERT #auto_posreco_data_upload (CANCELLED,memo_dt,memo_id,amount,quantity,xn_type,last_update,
		paymode_code,entry_type)
		SELECT 0 as cancelled,'' as memo_dt,a.memo_id,SUM(a.amount) amount,0 quantity,'SLS' XN_TYPE,
		''  LAST_UPDATE,a.paymode_code,2 ENTRY_TYPE
		FROM paymode_xn_det a (NOLOCK)
		JOIN #auto_posreco_data_upload b (NOLOCK) ON a.memo_id=b.memo_id AND a.xn_type=b.xn_type
		GROUP BY a.memo_id,a.paymode_code

		SET @cStep='40'
		INSERT INTO #auto_posreco_data_upload (cancelled,memo_dt,memo_id,amount,quantity,XN_TYPE,LAST_UPDATE,
		paymode_code,entry_type)
		SELECT TOP 5000 cancelled,a.cm_dt memo_dt,a.cm_id  memo_id,0 as amount,
		b.total_quantity as quantity,'SLS' as XN_TYPE,a.LAST_UPDATE,CONVERT(CHAR(7),'') AS paymode_code,
		3 AS entry_type
		FROM cmm01106 A WITH (NOLOCK)
		JOIN (SELECT a.cm_id,SUM(a.quantity) total_quantity FROM cmd_cons a (NOLOCK)
		      JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
			  WHERE b.cm_dt>@cCutoffDate AND LEFT(a.cm_id,2)=@cLocIdPara 
			  AND ISNULL(auto_posreco_cons_last_update,'')<>b.last_update
			  GROUP BY a.cm_id
             ) b ON a.cm_id=b.cm_id
			 
		SET @nRows2=@@rowcount


		IF @nRows1>0 OR @nRows2>0
		BEGIN
			SET @bDataFound=1
		END
	END
	ELSE
	IF @nMode=2
	BEGIN
		SET @cStep='50'
		SET @cCmd=N'SELECT a.memo_id FROM ##auto_posreco_data_upload_'+@cLocIdPara+' a 
		LEFT OUTER JOIN cmm01106 b (NOLOCK)	ON a.memo_id=b.cm_id
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND a.entry_type=1 AND (a.quantity<>ISNULL(b.TOTAL_QUANTITY,0) OR a.amount<>ISNULL(b.net_amount,0) OR 
		a.cancelled<>ISNULL(b.cancelled ,0)	OR a.memo_dt<>ISNULL(b.cm_dt,''''))
		UNION
		SELECT ISNULL(a.memo_id,b.memo_id) as memo_id FROM ##auto_posreco_data_upload_'+@cLocIdPara+' a 
		FULL OUTER JOIN 
		(SELECT ''SLS'' AS xn_type,a.memo_id,a.paymode_code,SUM(a.amount) amount from paymode_xn_det a (NOLOCK)
		 JOIN ##auto_posreco_data_upload_'+@cLocIdPara+' b ON a.memo_id=b.memo_id
		 WHERE entry_type=2 AND a.xn_type=''SLS''
		 GROUP BY a.memo_id,a.paymode_code
		) b ON a.memo_id=b.memo_id AND a.xn_type=b.xn_type AND a.paymode_code=b.paymode_code
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND a.entry_type=2 AND (a.memo_id IS NULL OR b.memo_id IS NULL OR a.amount<>b.amount)
		
		UNION
		SELECT ISNULL(a.memo_id,b.memo_id) as memo_id FROM ##auto_posreco_data_upload_'+@cLocIdPara+' a 
		FULL OUTER JOIN 
		(SELECT ''SLS'' AS xn_type,a.cm_id memo_id,SUM(a.quantity) total_quantity from cmd_cons a (NOLOCK)
		 JOIN ##auto_posreco_data_upload_'+@cLocIdPara+' b ON a.cm_id=b.memo_id
		 WHERE entry_type=3
		 GROUP BY a.cm_id
		) b ON a.memo_id=b.memo_id AND a.xn_type=b.xn_type
		WHERE a.memo_dt>'''+@cCutoffDate+''' AND a.entry_type=3 AND (a.memo_id IS NULL OR b.memo_id IS NULL 
		OR a.quantity<>b.total_quantity)
		'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @nMode=3
	BEGIN
		SET @cStep='60'
		UPDATE B SET auto_posreco_last_update=a.last_update,auto_posreco_cons_last_update=a.last_update
		FROM cmm01106 B (NOLOCK) JOIN #auto_posreco_data_upload a (NOLOCK) ON a.memo_id=b.cm_id 
		WHERE a.xn_type='SLS' AND entry_type IN  (1,3)

		SET @cStep='70'
		UPDATE B SET HO_SYNCH_LAST_UPDATE=''
		FROM cmm01106 B (NOLOCK) JOIN #auto_posreco_data_mismatch a (NOLOCK) ON a.memo_id=b.cm_id 
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETPOSRECO_SLS_DATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH


END_PROC:
END

