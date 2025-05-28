CREATE PROCEDURE SP3S_GETMANUAL_ACCOUNTS_CBS
@dXnDt DATETIME,
@bRetLocWise BIT=0,
@nCbp NUMERIC(20,2) OUTPUT,
@bEntryFound BIT OUTPUT
AS
BEGIN
	DECLARE @cFinYear VARCHAR(5)

	SET @nCbp=NULL
	SET @bEntryFound=0

	IF NOT (DATEPART(DD,@dXnDt)=31 AND DATEPART(MM,@dXnDt)=3)
		RETURN

	SET @cFinYear='01'+DBO.FN_GETFINYEAR(@dXnDt)

	SELECT @nCbp=SUM(closing_stock_value_pp) FROM year_wise_act_cbsstk_det a (NOLOCK)
	JOIN #locListc b ON a.dept_id=b.dept_id
	JOIN year_wise_act_cbsstk_mst c (NOLOCK) ON c.fin_year=a.fin_year
	WHERE a.fin_year=@cFinYear AND c.mode=1
		
	IF @nCbp IS NOT NULL
		SET @bEntryFound=1
	
	IF @bRetLocWise=1 AND @bEntryFound=1
	BEGIN
		INSERT #year_wise_cbs	( dept_id,cbp )  
		SELECT a.dept_id,a.closing_stock_value_pp
		FROM year_wise_act_cbsstk_det a (NOLOCK)
		JOIN #locListc b ON a.dept_id=b.dept_id
		JOIN year_wise_act_cbsstk_mst c (NOLOCK) ON c.fin_year=a.fin_year
		WHERE a.fin_year=@cFinYear AND c.mode=1
	END
END
