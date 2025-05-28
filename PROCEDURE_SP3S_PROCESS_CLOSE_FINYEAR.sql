CREATE PROCEDURE SP3S_PROCESS_CLOSE_FINYEAR
@nQueryId NUMERIC(1,0),
@dCurrentDate DATETIME='',
@cFinYearPara VARCHAR(5)=''
as
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cActBkpTable VARCHAR(50),@cFinYear VARCHAR(5),@dMinVoucherDt DATETIME,
			@cErrormsg VARCHAR(500),@dMaxVoucherDt DATETIME,@cMaxFinYear VARCHAR(5)
	
	SET @cErrormsg=''
	IF @nQueryId=1
	BEGIN
		SELECT @dMinVoucherDt=min(voucher_dt) FROM  vm01106 (NOLOCK) WHERE cancelled=0

		IF @dMinVoucherDt IS NULL
		BEGIN
			SET @cErrormsg='Year Closing module is available only for Accounts Data users....Please check'		
			GOTO END_PROC
		END

		SELECT TOP 1 name INTO #tmpBkptables FROM  sys.tables where left(name,17)='accounts_xns_bkp_'
		ORDER BY name DESC

		SELECT @cFinYear=RIGHT(name,5) FROM #tmpBkptables

		IF @cFinYear IS NOT NULL
		BEGIN
			SET @dMinVoucherDt=DATEADD(YY,1,dbo.FN_GETFINYEARDATE(@cFinYear,2))
		END

		SET @cMaxFinYear='01'+dbo.FN_GETFINYEAR(DATEADD(YY,-1,@dCurrentDate))

		SET @dMaxVoucherDt=dbo.FN_GETFINYEARDATE(@cMaxFinYear,2)

		DECLARE @tFinYear TABLE (fin_year_display VARCHAR(10),fin_year VARCHAR(10))

		select @dMinVoucherDt,@dMaxVoucherDt
		WHILE @dMinVoucherDt<=@dMaxVoucherDt
		BEGIN
			INSERT @tFinYear (fin_year,fin_year_display)
			select '01'+dbo.FN_GETFINYEAR(@dMinVoucherDt),dbo.FN_GETFINYEARSTR(@dMinVoucherDt)

			SET @dMinVoucherDt=DATEADD(YY,1,@dMinVoucherDt)
		END		

		SELECT * FROM  @tFinYear
	END
	ELSE
	IF @nQueryId=2
	BEGIN
		EXEC SP3S_CLOSE_FINYEAR
		@cFinYear=@cFinyearPara,
		@cErrormsg=@cErrormsg OUTPUT
		
		GOTO END_PROC
	END

END_PROC:

	IF @nQueryId=2 OR ISNULL(@cErrormsg,'')<>''
		SELECT @cErrormsg AS errmsg
END