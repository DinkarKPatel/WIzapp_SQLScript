CREATE PROCEDURE SP3S_GETFINYEAR_LASTPMTXNDT 
@dXndt DATETIME,
@cDtSuffix VARCHAR(50) OUTPUT
AS
BEGIN
	DECLARE @tPmtTable varchar(300),@bFound BIT,@dXnDtPara DATETIME,@cCmd NVARCHAR(MAX),
	@cPmtDb VARCHAR(200),@tPmtTableOut VARCHAR(200),@tPmtTableName VARCHAR(100)
	
	SET @dXnDtPara=@dXnDt
	SET @bFound=0

	SET @cDtSuffix=CONVERT(VARCHAR,@dXnDt,112)

	SET @cPmtDb=DB_NAME()+'_PMT'

	SET @tPmtTableName='pmtlocs_'+@cDtSuffix
	SET @tPmtTable=@cPmtDb+'.DBO.'+@tPmtTableName
		
	IF OBJECT_ID(@tPmtTable,'u') IS NULL
	BEGIN
		SET @cCmd=N'SELECT TOP 1  @tPmtTableOut=name FROM '+@cPmtDb+'.sys.tables (NOLOCK) WHERE left(name,8)=''pmtlocs_''
					AND name<'''+@tPmtTableName+''' ORDER BY name desc'
		PRINT @cCmd	
		EXEC SP_EXECUTESQL @cCmd,N'@tPmtTableOut VARCHAR(200) OUTPUT',@tPmtTableOut OUTPUT

		IF @tPmtTableOut IS NOT NULL
			SET @cDtSuffix=RIGHT(@tPmttableOut,8)

	END

END
