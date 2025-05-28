CREATE PROCEDURE SPWOW_GENXPERT_RETAILSALE_PAYMENTSUMMARY
@nViewPaymodeType INT,
@cRepTempTable VARCHAR(300),
@cPaymentTableName VARCHAR(300),
@cRunCmd NVARCHAR(MAX)
AS
BEGIN
	CREATE TABLE #tCmIds (cm_id VARCHAR(50))

	CREATE TABLE #tPaymodes (payModeName varchar(100))
	
	DECLARE @cCmd NVARCHAR(MAX),@cPaymodesStr VARCHAR(1000)
	
	SET @cCmd=N'SELECT DISTINCT cm_id FROM '+@cRepTempTable

	INSERT INTO #tCmIds (cm_id)
	EXEC SP_EXECUTESQL @cCmd

	IF @nViewPaymodeType=1
	BEGIN	
		INSERT INTO #tPaymodes
		select distinct paymode_name from paymode_xn_det a (NOLOCK) JOIN #tCmIds b ON a.memo_id=b.cm_id
		JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
		ORDER BY 1

	END
	ELSE
	BEGIN
		INSERT INTO #tPaymodes
		select distinct paymode_grp_name from paymode_xn_det a (NOLOCK) JOIN #tCmIds b ON a.memo_id=b.cm_id
		JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
		JOIN paymode_grp_mst d (NOLOCK) ON d.paymode_grp_code=c.paymode_grp_code
		ORDER BY 1
	END

	SELECT @cPaymodesStr=coalesce(@cPaymodesStr+',','')+'['+payModeName+']' from #tPaymodes

	SET @cPaymentTableName='tempdb.dbo.##xpertrepdata_payments_'+LTRIM(RTRIM(STR(@@SPID)))
	IF OBJECT_ID(@cPaymentTableName,'U') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE  '+@cPaymentTableName
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @nViewPaymodeType=1
		SET @cCmd=N'SELECT cm_id,'+@cPaymodesStr+' INTO '+@cPaymentTableName+' FROM 
		(SELECT cm_id,paymode_name,sum(amount) amount from paymode_xn_det a (NOLOCK) JOIN #tCmIds b ON a.memo_id=b.cm_id
		JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
		GROUP BY cm_id,paymode_name) a PIVOT (SUM(amount)
		FOR paymode_name IN ('+@cPaymodesStr+')) as pvt'
	ELSE
		SET @cCmd=N'SELECT cm_id,'+@cPaymodesStr+' INTO '+@cPaymentTableName+' FROM 
		(SELECT cm_id,paymode_grp_name,sum(amount) amount from paymode_xn_det a (NOLOCK) JOIN #tCmIds b ON a.memo_id=b.cm_id
		JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
		JOIN paymode_grp_mst d (NOLOCK) ON d.paymode_grp_code=c.paymode_grp_code
		GROUP BY cm_id,paymode_grp_name) a PIVOT (SUM(amount)
		FOR paymode_grp_name IN ('+@cPaymodesStr+')) as pvt'

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	--SET @cCmd=N' select a.*,'+@cPaymodesStr+' from '+@cRepTempTable+' a LEFT JOIN '+@cPaymentTableName+' b ON a.cm_id=b.cm_id'
	--EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=REPLACE(@cRunCmd,'[paymodesData]',@cPaymodesStr)
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'DROP TABLE  '+@cPaymentTableName
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END