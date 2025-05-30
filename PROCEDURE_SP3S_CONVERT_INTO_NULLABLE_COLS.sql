CREATE PROCEDURE SP3S_CONVERT_INTO_NULLABLE_COLS
(
	@cTABLE NVARCHAR(100)
)
AS
BEGIN
	--DECLARE @cTABLE NVARCHAR(100)
	--SET @cTABLE='SLS_CMD01106_UPLOAD'
	DECLARE @cCMD NVARCHAR(MAX),@cCOLUMN_NAME  NVARCHAR(MAX),@cdbname NVARCHAR(MAX),@cTableName NVARCHAR(MAX)

	IF OBJECT_ID('TEMPDB..#DBLIST','U') IS NOT NULL
		DROP TABLE #DBLIST

	IF OBJECT_ID('TEMPDB..#ABC','U') IS NOT NULL
		DROP TABLE #ABC
			
	CREATE TABLE #ABC (DONE BIT, TABLE_NAME NVARCHAR(100),COLUMN_NAME NVARCHAR(100),EXPR NVARCHAR(100))
			
	CREATE TABLE #DBLIST (DB_DONE BIT, dbname NVARCHAR(100))		
	
	INSERT INTO #DBLIST (DB_DONE , dbname )
	select CAST(0 AS BIT) AS DB_DONE,name as dbname 
	from sys.databases 
	where state=0 AND name NOT LIKE '%IMAGE' 
	AND name NOT LIKE '%TEMP' 
	AND name NOT LIKE '%RFOPT'
	AND name NOT LIKE '%PMT'
	AND Database_ID>4
	AND name not like 'WIZCLIP%'
	AND NAME NOT LIKE '%STRUCOMP'
	
	
	WHILE EXISTS(SELECT TOP 1 dbname FROM #DBLIST WHERE DB_DONE=0)
	BEGIN
		SELECT TOP 1 @cdbname= dbname FROM #DBLIST WHERE DB_DONE=0
			--SET @cCMD=N'USE '+ @cdbname
			--PRINT @cCMD
			--EXEC SP_EXECUTESQL @cCMD

		SET @cCMD=N'SELECT CAST(0 AS BIT) AS DONE, TABLE_NAME,COLUMN_NAME--,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_SCALE 
		,''ALTER TABLE '+@cdbname+'..'' + TABLE_NAME+'' ALTER COLUMN ''+COLUMN_NAME +'' ''+  DATA_TYPE+CASE WHEN DATA_TYPE IN (''CHAR'',''varchar'') THEN ''(''+CAST(CASE WHEN CHARACTER_MAXIMUM_LENGTH =-1 THEN 4000 ELSE CHARACTER_MAXIMUM_LENGTH END AS VARCHAR(50))+'')''
		WHEN DATA_TYPE IN (''BIT'',''datetime'',''int'') THEN '''' WHEN DATA_TYPE in (''numeric'') THEN ''(''+CAST(NUMERIC_PRECISION AS VARCHAR(50))+'',''+CAST(NUMERIC_SCALE AS VARCHAR(50))+'')'' ELSE '''' END AS EXPR
		FROM '+@cdbname+'.INFORMATION_SCHEMA.COLUMNS where table_name='''+@cTABLE+'''
		AND IS_NULLABLE=''NO'' AND DATA_TYPE<>''timestamp'''
		
		PRINT @cCMD
		
		INSERT INTO #ABC(DONE , TABLE_NAME ,COLUMN_NAME ,EXPR )
		EXEC SP_EXECUTESQL @cCMD
		
		WHILE EXISTS(SELECT TOP 1 COLUMN_NAME FROM #ABC WHERE DONE=0)
		BEGIN
			SELECT TOP 1 @cCMD=EXPR,@cTableName=TABLE_NAME,@cCOLUMN_NAME=COLUMN_NAME FROM #ABC  WHERE DONE=0
			PRINT @cCMD
			EXEC SP_EXECUTESQL @cCMD
			
			UPDATE #ABC SET DONE=1 WHERE COLUMN_NAME=@cCOLUMN_NAME AND TABLE_NAME=@cTableName
		END

		UPDATE #DBLIST SET DB_DONE=1 WHERE dbname=@cdbname
	END
END