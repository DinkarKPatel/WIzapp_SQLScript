CREATE PROCEDURE SP3S_PROCESS_LOCWISEPMTINDEXES
@dFromDt DATETIME,
@dToDt DATETIME,
@nMode numeric(1,0)=2

AS
BEGIN
	DECLARE @CCMD NVARCHAR(MAX),@cPmtTableNameXnDt VARCHAR(MAX),@cIndexName varchar(200),@cDbName VARCHAR(300)
	
	SET @cDbName=DB_NAME()+'_PMT'
	
	WHILE @dFromDt<=@dToDt
	BEGIN
		SELECT @cPmtTableNameXnDt='pmtlocs_'+CONVERT(VARCHAR,@dFromDt,112),@cIndexName='IND_PMTLOCS_'+convert(varchar,@dFromDt,112)

		PRINT 'Processing indexes for Date:'+convert(varchar,@dFromDt,113)
		IF @nMode in (0,1)
		begin
			set @cCmd=N'use '+@cDbName+';IF EXISTS (SELECT NAME FROM SYS.INDEXES WHERE NAME='''+@cIndexName+''')
							DROP INDEX '+@cPmtTableNameXnDt+'.'+@cIndexName

			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		end

		IF @nMode in (0,2)
		begin
			SET @CCMD=N'USE '+@cDbName+'; IF EXISTS (SELECT TOP 1 * from information_schema.tables where table_name='''+@cPmtTableNameXnDt+''')
											CREATE NONCLUSTERED INDEX '+@cIndexName+' ON '+@cPmtTableNameXnDt+' ([dept_id])
						INCLUDE ([product_code],[bin_id],[cbs_qty])'
		
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		end

		SET @dFromDt=@dFromDt+1	
	END
END	