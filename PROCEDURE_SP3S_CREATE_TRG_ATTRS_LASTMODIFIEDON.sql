CREATE PROCEDURE SP3S_CREATE_TRG_ATTRS_LASTMODIFIEDON
AS
BEGIN

	DECLARE @cTableName VARCHAR(100),@cCmd NVARCHAR(MAX),@cTrgname VARCHAR(200),@cAttrname VARCHAR(50),
			@cColName VARCHAR(200),@cColNameCode VARCHAR(200)
	
	SELECT table_name,column_name INTO #tmpAttr from config_attr
	
	WHILE EXISTS (SELECT TOP 1 table_name FROM #tmpAttr)
	BEGIN
		SELECT TOP 1 @cTableName=table_name,@cColName=column_name,@cColNameCode=REPLACE(column_name,'_name','_code')
		FROM #tmpAttr
		
		SET @cTrgName='TRG_UPD_'+ltrim(rtrim(REPLACE(@cTableName,'_mst','')))+'_last_MODIFIED_ON'
		print 'check trigger for existense of :'+@cTrgName
		IF EXISTS (SELECT name FROM sys.triggers (NOLOCK) WHERE name=@cTrgName)
		BEGIN
			SET @cCmd=N'DROP TRIGGER '+@cTrgname
			EXEC SP_EXECUTESQL @cCmd
		END

		SET @cCmd=N'CREATE TRIGGER '+@cTrgname+' ON '+@cTableName+'
		FOR UPDATE
		AS
		BEGIN

			INSERT INTO opt_sku_diff (master_tablename,master_code)
			SELECT '''+@cTableName+''',a.'+@cColNameCode+' FROM DELETED a
			JOIN INSERTED b ON b.'+@cColNameCode+'=a.'+@cColNameCode+'
			LEFT JOIN  opt_sku_diff df (NOLOCK) ON df.master_code=a.'+@cColNameCode+' AND df.master_tablename='''+@cTableName+'''
			where (a.'+@cColName+'<>b.'+@cColName+') and df.master_code is null

			IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
				RETURN

			UPDATE '+@cTableName+' SET LAST_MODIFIED_ON=GETDATE() 
			FROM DELETED B WHERE B.'+@cColNameCode+'='+@cTableName+'.'+@cColNameCode+'
			AND ('+@cTableName+'.'+@cColName+'<>b.'+@cColName+' OR '+@cTableName+'.'+REPLACE(@cColName,'_key_name','_alias')
			+'<>b.'+REPLACE(@cColName,'_key_name','_alias')+' OR  '+@cTableName+'.'+REPLACE(@cColName,'_key_name','_inactive')+
			'<>b.'+REPLACE(@cColName,'_key_name','_inactive')+') 
		END '
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		DELETE FROM #tmpAttr where table_name=@cTableName
	END
END
