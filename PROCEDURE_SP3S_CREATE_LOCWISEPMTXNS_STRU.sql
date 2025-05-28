CREATE PROCEDURE SP3S_CREATE_LOCWISEPMTXNS_STRU
@cDbName VARCHAR(400)='',
@dXnDt DATETIME,
@bInsPmt BIT=0,
@bCrtIndex BIT=0,
@bDonotChkDb BIT=0,
@cPmtDbName VARCHAR(400)='',
@bCalledfromReinit BIT=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@CFILEPATH VARCHAR(500),@cPmtTableNameXnDt VARCHAR(200),
	@cPrevPmtTableNameXnDt VARCHAR(200),@cPmtTableXnDt VARCHAR(100),@cRecoveryModel SQL_VARIANT,@cStep VARCHAR(10)

	SET @cStep='115.1'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

	IF @cDbName=''
		SET @cDbName=db_name()
	ELSE
		SET @cDbName=REPLACE(@cDbName,'.dbo.','')

	IF @cPmtDbName=''
		SET @cPmtDbName=@cDbName+'_PMT'

	IF @bDonotChkDb=0
	BEGIN

		SET @cStep='115.2'
		PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SELECT @CFILEPATH=PHYSICAL_NAME FROM SYS.MASTER_FILES WHERE DATABASE_ID=DB_ID(@cDbName) AND TYPE_DESC='ROWS'
		SET @CFILEPATH=REVERSE(RIGHT(REVERSE(@CFILEPATH),(LEN(@CFILEPATH)-CHARINDEX('\',REVERSE(@CFILEPATH),1))+1))

			SET @cStep='115.3'
		PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SET @CCMD=N'IF NOT EXISTS(SELECT TOP 1 * FROM SYS.DATABASES WHERE NAME='''+@cPmtDbName+''') 
			BEGIN
				CREATE DATABASE ' + @cPmtDbName + ' ON '+
				' ( NAME = ' + @cPmtDbName + ', ' + 
				'  FILENAME = ''' + @CFILEPATH  + @cPmtDbName + '.MDF'' ) ' + 
				' LOG ON ' + 
				' ( NAME = ' + @cPmtDbName + '_LOG, ' + 
				'  FILENAME = ''' + @CFILEPATH  + @cPmtDbName + '_LOG.LDF'' )
			END	
			'
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD

	
		SET @cStep='115.4'
		PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SELECT @cRecoveryModel=DATABASEPROPERTYEX(@cPmtDbName, N'RECOVERY')

		IF @cRecoveryModel<>'SIMPLE' AND object_id('master.dbo.cloud_dbinfo','u') is null
		BEGIN
			SET @cCmd=N'ALTER DATABASE '+@cPmtDbName+' SET RECOVERY SIMPLE'
			EXEC SP_EXECUTESQL @CCMD
		END
	END

	SET @cStep='115.5'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

	SET @cPmtTableXnDt='pmtlocs_'+CONVERT(VARCHAR,@dXnDt,112)

	SET @cPmtTableNameXnDt=@cPmtDbName+'..pmtlocs_'+CONVERT(VARCHAR,@dXnDt,112)
	IF OBJECT_ID(@cPmtTableNameXnDt,'U') IS NULL
	BEGIN
	SET @cStep='115.6'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SET @CCMD=N'SELECT product_code,bin_id,dept_id,quantity_in_stock as cbs_qty,CONVERT(NUMERIC(30,2),0) AS cbp,
		                   challan_receipt_dt=CAST('''' AS DATETIME),CONVERT(NUMERIC(10,2),0) AS xfer_price, 
						   CONVERT(NUMERIC(5,0),0) AS shelf_ageing_days,CONVERT(NUMERIC(5,0),0) AS purchase_ageing_days
		INTO '+@cPmtTableNameXnDt+' FROM '+@cDbName+'.dbo.pmt01106 WHERE 1=2'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
			   		
	SET @cStep='115.7'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_PMT'+CONVERT(VARCHAR,@dXnDt,112)+
		' ON '+@cPmtTableNameXnDt+' ([dept_id])
		INCLUDE ([product_code],[bin_id],[cbs_qty])'
		print @cCmd
		 EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @bCrtIndex=1
	BEGIN
	SET @cStep='115.8'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		DECLARE @cIndexName VARCHAR(200)

		DECLARE @tIndList TABLE (ind_name VARCHAR(200))

		SET @cCmd=N' use '+@cPmtDbName+' ; SELECT  distinct I.[name] AS [index_name]
					FROM sys.[tables] AS T  
					  INNER JOIN sys.[indexes] I ON T.[object_id] = I.[object_id]  
					  INNER JOIN sys.[index_columns] IC ON I.[object_id] = IC.[object_id] 
					  INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id] 
					WHERE T.[is_ms_shipped] = 0 and I.[type_desc] <> ''HEAP'' and t.name='''+@cPmtTableXnDt+''''

		PRINT @cCmd

		INSERT @tIndList (ind_name)
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='115.9'
		PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		WHILE EXISTS (SELECT TOP 1 * FROM @tIndList)
		BEGIN
			SELECT TOP 1 @cIndexName=ind_name FROM @tIndList
			SET @cStep='115.10'
			PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

			SET @cCmd=N' use '+@cPmtDbName+' ; DROP INDEX '+@cPmtTableXnDt+'.'+@cIndexName

			PRINT @cCMD

			EXEC SP_EXECUTESQL @cCmd

			DELETE FROM @tIndList WHERE ind_name=@cIndexName
		END

		SET @cStep='115.11'
		PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_PMT'+CONVERT(VARCHAR,@dXnDt,112)+
		' ON '+@cPmtTableNameXnDt+' ([dept_id])
		INCLUDE ([product_code],[bin_id],[cbs_qty])'
		print @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	IF @bCalledfromReinit=1
	BEGIN
		SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_PMT'+CONVERT(VARCHAR,@dXnDt,112)+
		' ON '+@cPmtTableNameXnDt+' ([dept_id])
		INCLUDE ([product_code],[bin_id],[cbs_qty])'
		print @cCmd
		 EXEC SP_EXECUTESQL @cCmd
	END

	IF @bInsPmt=1
	BEGIN
	SET @cStep='115.12'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SET @cPrevPmtTableNameXnDt=@cPmtDbName+'..pmtlocs_'+CONVERT(VARCHAR,@dXnDt-1,112)

		SET @cCmd=N'TRUNCATE TABLE '+@cPmtTableNameXnDt
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	SET @cStep='115.13'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

		SET @cCmd=N'INSERT '+@cPmtTableNameXnDt+'(product_code,bin_id,dept_id,cbs_qty)
					SELECT product_code,bin_id,dept_id,cbs_qty FROM '+@cPrevPmtTableNameXnDt+' (NOLOCK)'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='115.14'
	PRINT 'Running Step#'+@cStep+':'+convert(varchar(20),getdate(),113)

END