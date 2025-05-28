CREATE PROCEDURE SP3S_REINIT_PMTDB
@cDbname VARCHAR(200)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @dCurDt DATETIME,@cFinyear varchar(5),@dCutOffDate datetime,@cCmd NVARCHAR(MAX),@cPmtDt VARCHAR(10),
			@cPmtDbName VARCHAR(200),@cTableName  VARCHAR(200),@cNewPmtDbName VARCHAR(200),@cStep VARCHAR(5),
			@cOldPmtDt VARCHAR(10),@cFileNamesuffix VARCHAR(20),@dLastCutoffdateProcessed DATETIME

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	SET @dCurDt=CONVERT(DATE,GETDATE())

	IF @cDbName='' AND DB_NAME()<>'master'
		SET @cDbname=DB_NAME()

	SELECT @cPmtDbName=@cDbname+'_pmt',@cNewPmtDbName=@cDbname+'_pmt_new'

	SET @cStep='20'
	set @cFinyear='01'+dbo.FN_GETFINYEAR(DATEADD(YY,-1,@dCurDt))
	set @dCutoffDate = DBO.FN_GETFINYEARDATE(@cFinyear,1)

	CREATE TABLE #tmpPmtTables (tableName varchar(200),monthendTable BIT)

	SET @cStep='30'
	SET @cCmd=N'SELECT  name FROM '+@cPmtDbName+'.sys.tables (NOLOCK) WHERE ISDATE(RIGHT(name,8))=1'

	print @cCmd

	INSERT INTO #tmpPmtTables (tableName)
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='40'
	UPDATE #tmpPmtTables SET monthendTable=1 WHERE DAY(DATEADD(DD,1,CONVERT(DATE,RIGHT(tablename,8))))=1

	SELECT TOP 1 @dLastCutoffdateProcessed=ISNULL(value,'') FROM  config (NOLOCK) 
	WHERE config_option='pmtreinit_cutoff_date_processed'


	SET @dLastCutoffdateProcessed=ISNULL(@dLastCutoffdateProcessed,'')

	IF NOT EXISTS (SELECT TOP 1 tablename FROM  #tmpPmtTables WHERE NOT (ISNULL(monthendTable,0)=1  OR CONVERT(DATE,RIGHT(tablename,8))>=@dCutOffDate))
		OR @dCutOffDate=@dLastCutoffdateProcessed
		GOTO END_PROC

	delete FROM  #tmpPmtTables WHERE NOT (ISNULL(monthendTable,0)=1  OR CONVERT(DATE,RIGHT(tablename,8))>=@dCutOffDate)
	OR CONVERT(DATE,RIGHT(tablename,8))<='2018-04-01'

	SET @cStep='50'

	SET @cFileNamesuffix=left(CONVERT(VARCHAR(40),NEWID()),10)

	EXEC SP3S_CREATE_PMTDB
	@cDbPara=@cDbname,
	@cPmtDbPara=@cNewPmtDbName,
	@cFileNamesuffix=@cFileNamesuffix

	SET @cOldPmtDt=''

	WHILE EXISTS (SELECT TOP 1 tablename FROM #tmpPmtTables)
	BEGIN
		SET @cStep='60'
		SELECT TOP 1 @cTableName=tablename from #tmpPmtTables ORDER BY right(tablename,8)

		SET @cPmtDt=right(@cTableName,8)
		PRINT 'Transferring data for Date :'+@cPmtDt

		SET @cCmd=N'SELECT * INTO  '+@cNewPmtDbName+'.dbo.'+@cTableName+' FROM '+@cPmtDbName+'.dbo.'+@cTableName
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='70'

		IF @cTableName LIKE '%pmtlocs%'
			EXEC  SP3S_CREATE_LOCWISEPMTXNS_STRU
			@cDbName=@cDbName,
			@dXnDt=@cPmtDt,
			@bInsPmt=0,
			@bDonotChkDb=1,
			@bCalledFromReinit=1,
			@cPmtDbName=@cNewPmtDbName

		DELETE FROM #tmpPmtTables where tableName=@cTableName
	end

	SET @cStep='80'
	SET @cCmd=N'alter database '+ @cPmtDbName+' modify name='+@cPmtDbName+'_OLD'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='90'
	SET @cCmd=N'alter database '+ @cNewPmtDbName+' modify name='+@cPmtDbName
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='100'

	IF EXISTS (SELECT TOP 1 value FROM config (NOLOCK) WHERE config_option='pmtreinit_cutoff_date_processed')
		UPDATE config SET value=CONVERT(VARCHAR,@dCutOffDate,112) WHERE config_option='pmtreinit_cutoff_date_processed'
	ELSE
		 INSERT config	( config_option, CTRL_NAME, Description, GROUP_NAME, last_update, OPT_SR_NO, REMARKS, row_id, SET_AT_HO, 
		 value, VALUE_TYPE )  
		 SELECT 'pmtreinit_cutoff_date_processed' config_option,null CTRL_NAME,'Pmt REbuild Cutoff Date processed' Description, 
		 null GROUP_NAME,getdate() last_update,null OPT_SR_NO,null REMARKS,newid() row_id,0 SET_AT_HO, 
		 CONVERT(VARCHAR,@dCutOffDate,112) value,null VALUE_TYPE 



	SET @cCmd=N'DROP DATABASE '+@cPmtDbName+'_OLD'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_REINIT_PMTDB at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:


END
