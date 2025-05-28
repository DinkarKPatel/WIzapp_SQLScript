CREATE PROCEDURE SPDB_PRFC_ANALYSIS_REPORT
@dFromDt DATETIME,
@dToDt DATETIME,
@cSetupIdParastr VARCHAR(1000)=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cWhereClause VARCHAR(1000),@cSetupId VARCHAR(10),@cErrormsg VARCHAR(MAX)

	SET @cWhereClause=(CASE WHEN @cSetupIdParaStr='' THEN ' where dashboard_mode=3 ' ELSE ' WHERE setup_id IN  ('+@cSetupIdParastr+')' END)

	DECLARE @tPrFcSetups TABLE (setup_id CHAR(7),setup_name VARCHAR(200),filter_desc VARCHAR(2000),
							    start_rowno numeric(5,0),end_rowno numeric(5,0),raw_para VARCHAR(200),processed bit)

	CREATE TABLE #tPRfcRepData  (setup_id char(7),para_name VARCHAR(500),nrv NUMERIC(20,2),profit NUMERIC(20,2),
								 asd NUMERIC(20,0),sell_thru NUMERIC(10,2),cbs_qty NUMERIC(20,2), abcd_score numeric(4,0),
								 nrv_rank numeric(4,0),profit_rank NUMERIC(4,0),asd_rank numeric(4,0),
								 sell_thru_rank numeric(4,0),abcd_percentage numeric(6,2),abcd_category varchar(200),
								 row_no INT IDENTITY)


	SET @cCmd=N'SELECT setup_id,setup_name,filter_description,0 start_rowno,0 end_rowno,raw_para,0 as processed
				 FROM pos_dynamic_dashboard_setup '+@cWhereClause
	
	INSERT @tPrFcSetups (setup_id,setup_name,filter_desc,start_rowno,end_rowno,raw_para,processed)
	EXEC SP_EXECUTESQL @cCmd

	IF NOT EXISTS (SELECT TOP 1 * FROM new_app_login_info (NOLOCK) WHERE spid=@@spid)
		INSERT new_app_login_info	( BIN_ID, COMPUTER_NAME, DEPT_ID, LAST_UPDATE, LOGIN_NAME, PROCESS_ID, SPID, 
		STATIC_IP, WINDOW_USER_NAME )  
		SELECT top 1 '000' BIN_ID,'' COMPUTER_NAME,value as DEPT_ID,getdate() LAST_UPDATE,'' LOGIN_NAME, 
		0 PROCESS_ID,@@spid SPID,'' STATIC_IP, 
		'' WINDOW_USER_NAME FROM config where config_option='ho_location_id'
	ELSE
		UPDATE new_app_login_info WITH (ROWLOCK) SET dept_id=(select top 1 value from config (nolock)
		where config_option='ho_location_id') where spid=@@spid

	WHILE EXISTS (SELECT * FROM @tPrFcSetups WHERE processed=0)
	BEGIN
		SELECT TOP 1 @cSetupId=setup_id FROM @tPrFcSetups WHERE processed=0 ORDER BY setup_id


		EXEC SPDB_PERFORMANCE_ANALYSIS
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@cSetupIdPara=@cSetupId,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC

		UPDATE a SET start_rowno=isnull(b.start_rowno,0),end_rowno=isnull(b.end_rowno,0),processed=1
		FROM @tPrFcSetups a LEFT OUTER JOIN (SELECT setup_id,min(row_no) as start_rowno,max(row_no) as end_rowno
			  FROM 	#tPRfcRepData where setup_id=@cSetupId GROUP BY setup_id) b ON a.setup_id=b.setup_id
		where a.setup_id=@cSetupId
				

	END

END_PROC:
	IF isnull(@cErrormsg,'')<>''
		SELECT isnull(@cErrormsg,'') as errmsg
	ELSE
	BEGIN
		SELECT *,ROW_NUMBER() OVER (ORDER BY setup_id) as srno FROM @tPrFcSetups
		SELECT * FROM #tPRfcRepData ORDER BY setup_id,abcd_score desc,nrv desc,asd,sell_thru desc
	END
END