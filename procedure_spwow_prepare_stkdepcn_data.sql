CREATE procedure spwow_prepare_stkdepcn_data
@dXnDt DATETIME,
@nMode NUMERIC(1,0),
@cPmtTable VARCHAR(200)
as
begin
	DECLARE @cCmd NVARCHAR(MAX)

	IF NOT EXISTS (SELECT TOP 1 * FROM year_wise_cbsstk_depcn_mst)
		RETURN

	DECLARE @cFinyear VARCHAR(10),@dPmtDate DATETIME
	SET @cFinyear='01'+(CASE WHEN @nMode=1 OR NOT(MONTH(@dXnDt)=3 AND DAY(@dXnDt)=31) THEN dbo.fn_getfinyear(DATEADD(yy,-1,@dXnDt))
						ELSE dbo.fn_getfinyear(@dXnDt) END)
	
	IF @nMode=1
		SET @dPmtDate=@dXnDt-1
	ELSE
		SET @dPmtDate=@dXndt

	--select 'Fin year',@cFinyear
	

	SET @cCmd=N';with cteDepcn
	as
	(SELECT a.product_code,prev_depcn_value,a.depcn_value,fin_year,
	 row_number() over (partition by a.product_code order by fin_year desc) rno
	 FROM year_wise_cbsstk_depcn_det a (NOLOCK)
	 JOIN '+@cPmtTable+' b (NOLOCK) ON a.product_code=b.product_code
	 WHERE fin_year<='''+@cFinyear+'''
	)
	INSERT INTO #tmpStkDepcn (product_code,depcn_value,mode)
	SELECT product_code,isnull(prev_depcn_value,0)+depcn_value,'+str(@nMode)+
	' FROM cteDepcn WHERE rno=1'

	print @cCmd
	exec sp_executesql @cCmd
end