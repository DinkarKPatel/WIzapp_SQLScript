CREATE PROCEDURE SP3S_INSNEWCOLS_PENDINGDOCS
AS
BEGIN

	SELECT tablename INTO  #tmpTab FROM xnsinfo	 where 1=2

	DECLARE @cCmd NVARCHAR(MAX),@cPmtDbname VARCHAR(200),@bColnotFound BIT,@cDocName VARCHAR(40)


	SET @cPmtDbname=DB_NAME()+'_PMT.'

	DECLARE @tDocs TABLE (doc_name VARCHAR(40))

	INSERT INTO @tDocs (doc_name)
	SELECT 'gitlocs'
	UNION
	SELECT 'WIPSTOCK'
	UNION
	SELECT 'PENDING_APPROVALS'
	UNION
	SELECT 'PENDING_JOBWORK'
	UNION
	SELECT 'PENDING_RPS'
	UNION
	SELECT 'PENDING_WPS'
	UNION
	SELECT 'PENDING_DNPS'
	UNION
	SELECT 'PENDING_CNPS'
	
	WHILE EXISTS (SELECT TOP 1 * FROM @tDocs)
	BEGIN
		SELECT TOP 1 @cDocName=doc_name FROM @tDocs

		SET @cCmd=N'SELECT a.table_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.TABLES a (NOLOCK)
					left join '+@cPmtDbname+'INFORMATION_SCHEMA.columns b (NOLOCK) on a.table_name=b.table_name
					and b.column_name=''bin_id'' 
					where a.table_name like ''%'+@cDocName+'%'' and b.column_name is null  ORDER BY a.table_name'
	
		print @cCmd
		INSERT #tmptab 
		EXEC SP_EXECUTESQL @cCmd

		DECLARE @bFlag BIT,@cTableName VARCHAR(200)

		SET @bFlag=0
		WHILE @bFlag=0
		BEGIN
			SET @cTableName=''
			SELECT TOP 1 @cTableName=TABLENAME FROM #tmpTab order by tablename
		
			IF ISNULL(@cTableName,'')=''
				BREAK
				
		
			SET @cCmd=N'ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD bin_id varchar(50)'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		
			DELETE FROM #tmpTab WHERE tablename=@cTableName
		END

		SET @cCmd=N'SELECT a.table_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.TABLES a
				left join '+@cPmtDbname+'INFORMATION_SCHEMA.columns b on a.table_name=b.table_name
				and b.column_name=''xn_party_code'' 
				where a.table_name like ''%'+@cDocName+'%'' and b.column_name is null  ORDER BY a.table_name'
	
		print @cCmd
		INSERT #tmptab 
		EXEC SP_EXECUTESQL @cCmd

		SET @bFlag=0
		WHILE @bFlag=0
		BEGIN
			SET @cTableName=''
			SELECT TOP 1 @cTableName=TABLENAME FROM #tmpTab order by tablename
		
			IF ISNULL(@cTableName,'')=''
				BREAK
				
			
			IF LEFT(@cTableName,7)<>'gitlocs'
			BEGIN
				SET @cCmd=N'ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD memo_id varchar(50)'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END

			SET @cCmd=N'ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD xn_party_code varchar(50)'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd

			SET @cCmd=N'ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD xn_no varchar(40)'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd

			SET @cCmd=N'ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD xn_dt DATETIME'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd		
			DELETE FROM #tmpTab WHERE tablename=@cTableName
		END

		DELETE FROM @tDocs WHERE  doc_name=@cDocName
	END

END
