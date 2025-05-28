CREATE PROCEDURE SP3S_GETLOCSKUBUILD_BARCODES
@cDbName VARCHAR(300)='',
@dLastBuildLupd DATETIME=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@dlastDtChanged DATETIME


	IF @dLastBuildLupd=''
		SET @dLastBuildLupd='2000-01-01'
				
	SET @cCmd=N'
	SELECT product_code FROM '+@cDbName+'pid01106 a (NOLOCK) JOIN '+@cDbName+'pim01106 b ON a.mrr_id=b.mrr_id
	WHERE ISNULL(quantity_last_update,'''')>='''+convert(varchar,@dLastBuildLupd,113)+''' AND inv_mode=1
	UNION ALL
	SELECT product_code from '+@cDbName+'IND01106 a (NOLOCK) JOIN '+@cDbName+'pim01106 b ON a.inv_id=b.inv_id
	WHERE ISNULL(quantity_last_update,'''')>='''+convert(varchar,@dLastBuildLupd,113)+''' AND inv_mode=2'

	print @cCmd
	
	INSERT INTO #tDiffPc (product_code)
	EXEC SP_EXECUTESQL	@cCmd

END