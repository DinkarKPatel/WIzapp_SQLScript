CREATE PROCEDURE SP3S_EOSS_SOR_LIST
@dFromDt DATETIME,
@dToDt DATETIME 
AS
BEGIN
	SELECT (CASE WHEN AgnstSupplier=1 THEN ac_name ELSE loc.dept_id+'-'+loc.dept_name END) Party, 
				st.sor_terms_name AS sor_terms_DESC,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,
				(CASE WHEN SUM(taxable_value)<>0 THEN convert(numeric(6,2),ROUND((SUM(claimed_base_value*gm_per/100)/SUM(taxable_value))*100 ,2))
					  ELSE 0 END) margin_pct_taxable,gm_per,sum(claimed_base_value) claimed_base_value,
				convert(numeric(10,2),SUM(claimed_base_value*gm_per/100)) claimed_base_gm_value,
				SUM(output_gst) output_gst,
				SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,
				convert(numeric(6,2),(CASE WHEN SUM(taxable_value+output_gst)<>0 THEN 
				ROUND((SUM(claimed_base_value*gm_per/100)/SUM(taxable_value+output_gst))*100,2)
				ELSE 0 END)) final_margin_pct
	FROM eosssord a (NOLOCK)
	JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	left join sor_terms_mst st (nolock) on st.sor_terms_code=a.sor_terms_code
	LEFT JOIN location loc (NOLOCK) ON loc.dept_id=b.party_dept_id
	LEFT JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=b.AC_CODE
	WHERE memo_dt between @dFromDt AND @dToDt
	GROUP BY (CASE WHEN AgnstSupplier=1 THEN ac_name ELSE loc.dept_id+'-'+loc.dept_name END),st.sor_terms_name,gm_per
	ORDER BY 1,2,3
END
