IF NOT EXISTS (SELECT TOP 1 * FROM year_wise_act_cbsstk_mst)
BEGIN
	INSERT year_wise_act_cbsstk_mst	( fin_year, mode )  
	SELECT DISTINCT '01'+dbo.FN_GETFINYEAR(xn_dt) as fin_year,1 mode
	FROM month_wise_cbs (nolock) where DATEPART(DD,xn_dt)=31 AND DATEPART(MM,xn_dt)=3
	
	INSERT year_wise_act_cbsstk_det	( closing_stock_value_pp, dept_id, fin_year )  
	SELECT cbp closing_stock_value_pp, dept_id,'01'+dbo.FN_GETFINYEAR(xn_dt) fin_year FROM month_wise_cbs
	where DATEPART(DD,xn_dt)=31 AND DATEPART(MM,xn_dt)=3
END

