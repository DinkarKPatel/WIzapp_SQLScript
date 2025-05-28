CREATE PROCEDURE SP3S_UPDPPCOL_PMTLOCS
AS
BEGIN
	IF OBJECT_ID('tempdb..#tmpTab','u') IS NOT NULL
		DROP TABLE #tmpTab

	SELECT tablename INTO  #tmpTab FROM xnsinfo	 where 1=2

	DECLARE @cCmd NVARCHAR(MAX),@cPmtDbname VARCHAR(200),@bColnotFound BIT

	SET @cPmtDbname=DB_NAME()+'_PMT.'

	SET @cCmd=N'SELECT table_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.TABLES ORDER BY table_name'

	INSERT #tmptab 
	EXEC SP_EXECUTESQL @cCmd

	DECLARE @bFlag BIT,@cTableName VARCHAR(200)

	SET @bFlag=0
	WHILE @bFlag=0
	BEGIN
		SET @cTableName=''
		SELECT TOP 1 @cTableName=TABLENAME FROM #tmpTab
		
		IF ISNULL(@cTableName,'')=''
			BREAK
				
		
		SET @cCmd=N'IF NOT EXISTS (SELECT TOP 1 column_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.COLUMNS 
					WHERE table_name='''+@cTableName+''' AND COLUMN_NAME=''CBP'')
					BEGIN
						ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD CBP NUMERIC(14,2)
					END'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd


		SET @cCmd=N'UPDATE a SET cbp=a.cbs_qty*b.pp FROM '+@cPmtDbname+'dbo.'+@cTableName+' a
					JOIN sku_names b ON a.product_code=b.product_code'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd			
				
		DELETE FROM #tmpTab WHERE tablename=@cTableName
	END

END
