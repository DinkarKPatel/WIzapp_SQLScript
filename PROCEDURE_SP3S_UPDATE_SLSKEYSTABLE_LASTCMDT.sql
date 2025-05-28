CREATE PROCEDURE SP3S_UPDATE_SLSKEYSTABLE_LASTCMDT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cTableName VARCHAR(200),@nPrefixLen NUMERIC(3,0),@cLocId VARCHAR(4),
			@cTrgName VARCHAR(100)

	SELECT TOP 1 @cLocId=value FROM config (NOLOCK) WHERE config_option='location_id'
	
	SELECT name as tablename INTO #keysTable FROM sys.tables a (NOLOCK)
	WHERE LEFT(name,8)='keys_cmm' and len(ltrim(rtrim(name)))>=9

	WHILE EXISTS (SELECT TOP 1 * FROM  #keysTable)
	BEGIN
		SELECT TOP 1 @cTableName=tablename FROM #keysTable

		IF NOT EXISTS (SELECT TOP 1 column_name FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK)
						WHERE table_name=@ctableName AND column_name='last_cm_dt')
		BEGIN
			SET @cCmd=N'ALTER TABLE '+@ctableName+' ADD last_cm_dt DATETIME'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END
		
		IF EXISTS (SELECT name from sys.triggers (NOLOCK) where parent_id=object_id(@cTableName))
		BEGIN
			SELECT @cTrgName=name from sys.triggers (NOLOCK) where parent_id=object_id(@cTableName)

			SET @cCmd=N'DROP TRIGGER '+@cTrgName
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END

		EXEC SP3S_CREATE_TRG_KEYSCMM
		@cKeysTable=@cTableName
				
		SET @cCmd=N'UPDATE a SET last_cm_dt=b.cm_dt FROM '+@ctableName+' a (NOLOCK)
					JOIN cmm01106 b (NOLOCK) ON a.lastkeyval=b.cm_no AND a.finyear=b.fin_year
					JOIN location c (NOLOCK) ON c.dept_id=B.LOCATION_CODE
					WHERE c.dept_id='''+@cLocId+''' OR c.server_loc=1'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		
		DELETE FROM #keysTable WHERE tablename=@cTableName
	END
END