CREATE PROCEDURE SPDB_RFCC_REPORT
@dFromDt DATETIME,
@dToDt DATETIME,
@cSetupIdParastr VARCHAR(1000)=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cWhereClause VARCHAR(1000),@cSetupId VARCHAR(10),@cErrormsg VARCHAR(MAX)

	SET @cWhereClause=(CASE WHEN @cSetupIdParaStr='' THEN ' where 1=1 ' ELSE ' WHERE setup_id IN  ('+@cSetupIdParastr+')' END)

	SET @cWhereClause=@cWhereClause+' AND dashboard_mode=2 '

	CREATE TABLE #tRfCcSetups (setup_id CHAR(7),setup_name VARCHAR(200),filter_desc VARCHAR(2000),
							   raw_para VARCHAR(200),processed BIT)

	SET @cCmd=N'INSERT #tRfCcSetups (setup_id,setup_name,filter_desc,raw_para,processed)
				 SELECT setup_id,setup_name,filter_description,raw_para,0 as processed
				 FROM pos_dynamic_dashboard_setup '+@cWhereClause+' oRDER BY setup_id'
	
	print @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SELECT *,ROW_NUMBER() OVER (ORDER BY setup_id) as srno FROM #tRfCcSetups	

	WHILE EXISTS (SELECT * FROM #tRfCcSetups WHERE processed=0)
	BEGIN
		SELECT TOP 1 @cSetupId=setup_id FROM #tRfCcSetups WHERE processed=0
		ORDER BY setup_id 

		EXEC SPDB_RFCC_ANALYSIS
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@cSetupIdPara=@cSetupId,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
		
		UPDATE #tRfCcSetups SET processed=1 WHERE setup_id=@cSetupId				
	END


END_PROC:
	IF isnull(@cErrormsg,'')<>''
		SELECT isnull(@cErrormsg,'') as errmsg

END