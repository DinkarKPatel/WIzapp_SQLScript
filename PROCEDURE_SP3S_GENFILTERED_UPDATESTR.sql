CREATE PROCEDURE SP3S_GENFILTERED_UPDATESTR
@cSpId VARCHAR(40),
@cInsSpId VARCHAR(45),
@cTableName VARCHAR(200),
@cUploadTableName VARCHAR(200),
@cKeyfield VARCHAR(200),
@cSpIdCol VARCHAR(30)='SP_ID',
@bDonotChkLastUpdate BIT=0,
@cSkipCols VARCHAR(2000)='',
@bCalledfromMirrorMerging BIT=0,
@bUpdSavetranTable BIT=0
AS
BEGIN
	DECLARE	@cColName VARCHAR(500),@cDatatype VARCHAR(30),@cCmd NVARCHAR(MAX),@cUpdateColsOut VARCHAR(300),
	@cUpdateCols VARCHAR(4000),@cWhereClause VARCHAR(300),@cJoinStr VARCHAR(300),@cNUllException VARCHAR(10)

	DECLARE @tCols TABLE (column_name VARCHAR(1000),DATA_TYPE VARCHAR(100))

	INSERT @tCols 
	SELECT column_name,DATA_TYPE FROM INF_SCHEMA_COLUMNS (NOLOCK) WHERE table_name=@cTableName
	AND column_name NOT IN ('TS','HO_SYNCH_LAST_UPDATE','last_modified_on','PUMA_HO_SYNCH_LAST_UPDATE')

	IF @cSpIdCol='sp_id' OR  @bCalledfromMirrorMerging=1
		SELECT @cWhereClause=' a.'+@cSpIdCol+' IN ('''+@cSpId+''','''+LEFT(@cSpId,38)+'ZZZ'') AND b.'+@cSpIdCol+'='''+@cInsSpId+'''',
			   @cJoinStr=' a.'+@cKeyfield+'=b.'+@cKeyfield
	ELSE
		SELECT @cWhereClause=' b.'+@cKeyfield+'='''+@cSpId+'''',@cJoinStr=' a.'+@cKeyfield+'=b.'+@cKeyfield+'+LEFT(b.'+@cKeyfield+',2)'

	SET @cUpdateCols=''
	WHILE EXISTS (SELECT TOP 1 column_name FROM @tCols)
	BEGIN
		SELECT @cColName=column_name,@cDatatype=data_type FROM @tCols


		IF @cDatatype<>'TIMESTAMP' AND (@cColName<>'last_update' OR @bDonotChkLastUpdate=0) AND @cColName<>@cSpIdCol
		AND CHARINDEX(@cSkipCols,@cColName)=0
		BEGIN
			SET @cUpdateColsOut=''

			SET @cNUllException=(CASE WHEN @cDatatype IN ('NUMERIC','INT','DECIMAL') THEN '0' ELSE '''''' END)

			SET @cCmd=N'SELECT @cUpdateColsOut='''+@cColName+'=B.'+@cColName+
			--','+
			--		(CASE WHEN @cDatatype IN ('VARCHAR','CHAR','DATETIME') THEN ''''''''''
			--	   ELSE '0' END)+')'''
			''' FROM '+@cUploadTableName+' a (NOLOCK)
			JOIN '+@cUploadTableName+' b (NOLOCK) ON '+@cJoinStr+' 
			WHERE '+@cWhereClause+' AND ISNULL(A.'+@cColName+','+@cNUllException+')<>ISNULL(b.'+@cColName+','+@cNUllException+')'

			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd,N'@cUpdateColsOut VARCHAR(4000) OUTPUT',@cUpdateColsOut=@cUpdateColsOut OUTPUT

		 
	
			IF @cUpdateColsOut<>''
				SET @cUpdateCols=@cUpdateCols+(CASE WHEN @cUpdateCols<>'' THEN ',' ELSE '' END)+@cUpdateColsOut

				
		END

		DELETE FROM @tCols WHERE column_name=@cColName
	END


	IF RIGHT(@cUploadTableName,7)='_mirror'
		UPDATE savetran_updcols_updatestr WITH (ROWLOCK) SET updatestr=@cUpdateCols WHERE sp_id=LTRIM(RTRIM(STR(@@SPID))) AND tablename=@cTableName
	else
		UPDATE savetran_updcols_updatestr WITH (ROWLOCK) SET updatestr=@cUpdateCols WHERE sp_id=@cSpId AND tablename=@cTableName
END