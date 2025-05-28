CREATE PROCEDURE SP3S_CHKMISSING_PMTLOCS
AS
BEGIN
BEGIN TRY
	DECLARE @cPmtTableNameXnDt VARCHAR(500),@dFromDt DATETIME,@dToDt DATETIME,@cFinYear VARCHAR(5),@dFinYearFromDt DATETIME,
	@bNotFound BIT,@dFromDtRet DATETIME,@cErromrsg VARCHAR(1000),@cStep VARCHAR(4), @cRetDt VARCHAR(20),@cCmd NVARCHAR(MAX)

	SET @cStep='10'
	SET @dFromDtRet=''
	SET @dToDt=DATEADD(DD,-1,CONVERT(DATE,GETDATE()))
	SET @cFinYear='01'+dbo.fn_getfinyear(@dToDt)

	SET @cStep='20'
	SET @dFinYearFromDt=DBO.FN_GETFINYEARDATE(@cFinYear,1)
	SET @dFromDtRet=DATEADD(YY,-1,@dFinyearFromDt)

	SET @bNotFound=0

	SET @cStep='30'
	SET @dFromDt=@dFromDtRet

	WHILE @dFromDt<=@dToDt
	BEGIN
		SET @cStep='40'
		SET @cPmtTableNameXnDt=DB_NAME()+'_pmt..pmtlocs_'+CONVERT(VARCHAR,@dFromDt,112)
		IF OBJECT_ID(@cPmtTableNameXnDt,'U') IS NULL
		BEGIN
			SET @cStep='50'
			SET @bNotFound=1
			BREAK
		END

		SET @dFromDt=@dFromDt+1
	END

	SET @cStep='60'
	IF @bNotFound=0
		SET @dFromDtRet=''
	

	SET @cPmtTableNameXnDt=DB_NAME()+'_pmt..pmtlocs_'+CONVERT(VARCHAR,GETDATE(),112)
	IF OBJECT_ID(@cPmtTableNameXnDt,'U') IS NULL
	BEGIN
		SET @cStep='70'

		SET @CCMD=N'SELECT product_code,bin_id,dept_id,quantity_in_stock as cbs_qty,CONVERT(NUMERIC(15,2),0) AS cbp,
		            CHALLAN_RECEIPT_DT=CAST('''' AS DATETIME), CONVERT(NUMERIC(10,2),0) AS xfer_price, CONVERT(NUMERIC(10,2),0) AS current_xfer_price
		INTO '+@cPmtTableNameXnDt+' FROM pmt01106 WHERE 1=2'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErromrsg='Error in Procedure 	SP3S_CHKMISSING_PMTLOCS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
	IF ISNULL(@cErromrsg,'')=''
	BEGIN
		IF ISNULL(@dFromDtRet,'')=''
			SET @cRetDt=''
		ELSE
			SET @cRetDt=CONVERT(VARCHAR,@dFromDtRet,23)
	END
	SELECT ISNULL(@cErromrsg,'') as errmsg,ISNULL(@cRetDt,'') AS start_dt
END
