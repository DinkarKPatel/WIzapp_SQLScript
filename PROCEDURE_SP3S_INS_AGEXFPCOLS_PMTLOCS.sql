CREATE PROCEDURE SP3S_INS_AGEXFPCOLS_PMTLOCS
AS
BEGIN
	SELECT tablename INTO  #tmpTab FROM xnsinfo	 where 1=2


BEGIN TRY
	DECLARE @cHoLocId VARCHAR(5),@cCurLocId VARCHAR(5),@dPmtDate DATETIME,@cStep VARCHAR(5),@cErrormsg VARCHAR(MAX)

	SET @cStep='10'
	SELECT TOP 1 @cHoLocId=value FROM config(nolock) WHERE config_option='ho_location_id'
	SELECT TOP 1 @cCurLocId=value FROM config(nolock) WHERE config_option='location_id'

	UPDATE CONFIG set GROUP_NAME='' WHERE config_option='INS_AGEXFPCOLS_PMTLOCS'
	
	IF @cHoLocId<>@cCurLocId
		RETURN
	
	SET @cStep='20'
	DECLARE @tError TABLE (errmsg varchar(max))

	DECLARE @cCmd NVARCHAR(MAX),@cPmtDbname VARCHAR(200),@bColnotFound BIT

	SET @cPmtDbname=DB_NAME()+'_PMT.'

	SET @cCmd=N'SELECT table_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.TABLES
				where left(table_name,7)=''pmtlocs'' AND isdate(right(table_name,8))=1 ORDER BY table_name'

	INSERT #tmptab 
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='30'
	DECLARE @bFlag BIT,@cTableName VARCHAR(200)

	SET @bFlag=0
	WHILE @bFlag=0
	BEGIN
		SET @cTableName=''
		SELECT TOP 1 @cTableName=TABLENAME FROM #tmpTab
		

		IF ISDATE(RIGHT(@cTableName,8))=1
		BEGIN
			PRINT 'CHECKING FOR tablename :'+@cTableName
			IF CONVERT(DATE,RIGHT(@cTableName,8))<='2020-03-31'
			BEGIN
				IF CONVERT(DATE,RIGHT(@cTableName,8))<='2015-03-31'
				BEGIN
					SET @cCmd=N'DROP TABLE '+@cPmtDbname+'dbo.'+@cTableName
					PRINT @cCmd
					EXEC SP_EXECUTESQL @cCmd
				END

				GOTO lblNext		
			END
		END

		SET @cStep='40'
		IF ISNULL(@cTableName,'')=''
			BREAK
				
		
		SET @cCmd=N'IF NOT EXISTS (SELECT TOP 1 column_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.COLUMNS (NOLOCK)  
					WHERE table_name='''+@cTableName+''' AND COLUMN_NAME=''shelf_ageing_days'')
					BEGIN
						ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD shelf_ageing_days NUMERIC(5,0)
					END'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='50'
		SET @cCmd=N'IF NOT EXISTS (SELECT TOP 1 column_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.COLUMNS (NOLOCK)  
					WHERE table_name='''+@cTableName+''' AND COLUMN_NAME=''purchase_ageing_days'')
					BEGIN
						ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD purchase_ageing_days NUMERIC(5,0)
					END'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd		

		SET @cStep='60'
		SET @cCmd=N'IF NOT EXISTS (SELECT TOP 1 column_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.COLUMNS (NOLOCK) 
					WHERE table_name='''+@cTableName+''' AND COLUMN_NAME=''xfer_price'')
					BEGIN
						ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD xfer_price NUMERIC(10,2)
					END'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd		

		SET @cStep='70'
		SET @cCmd=N'IF NOT EXISTS (SELECT TOP 1 column_name FROM '+@cPmtDbname+'INFORMATION_SCHEMA.COLUMNS (NOLOCK)  
					WHERE table_name='''+@cTableName+''' AND COLUMN_NAME=''challan_receipt_dt'')
					BEGIN
						ALTER TABLE '+@cPmtDbname+'dbo.'+@cTableName+' ADD challan_receipt_dt DATETIME
					END'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd		
		

		SET @cStep='80'
		SET @dPmtDate=CONVERT(DATE,RIGHT(@cTableName,8))

		PRINT 'Updating Transfer Price columns in Pmtlocs'
		
		--- THis process running slow..need to optimize it Because it increased log of many databases upto 60 gb
		--- on the Cloud (19-10-2021)
		--INSERT INTO @tError (errmsg)
		--EXEC SP3S_UPDATE_AGEINGXFP_PMTLOCS
		--@dFromDt=@dPmtDate,
		--@dToDt=@dPmtDate,
		--@bCalledFromPostMonitor=1

		--select top 1 @cErrormsg=errmsg from @tError
		--if @cErrormsg<>''
		--	GOTO END_pROC
		
lblNext:
		DELETE FROM @tError
		DELETE FROM #tmpTab WHERE tablename=@cTableName
	END
	GOTO END_PROC
	
END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_INS_AGEXFPCOLS_PMTLOCS at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT @cErrormsg ERRMSG

END