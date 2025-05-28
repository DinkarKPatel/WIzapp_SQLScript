CREATE PROCEDURE SP3S_EOSSSOR_AUDIT_REPORT
@dFromDt DATETIME,
@dToDt DATETIME
AS
BEGIN
--Supplier,Scheme,SOR Basis,Qty Sold,MRP Value,Total Discount,Actual NRV,Card Discount,
--Self Borne Discount,Manual Discount,Claim Base,Margin %,Margin Amount,
--Output GST,Input GST,Payment Amount,Margin% wrt Actual NRV
	
	SELECT * FROM 
	(
	SELECT 1 disp_order,ac_name [Supplier],eoss_scheme_name [Eoss Scheme],sor_terms_name [Sor Terms],SUM(cmd.quantity) [Qty Sold],SUM(mrp_value) [Mrp Value],
	SUM(a.discount_amount) [Total Discount],SUM(rfnet) [Actual NRV],SUM(a.card_discount_amount) [Card Discount],
	SUM(CASE WHEN ISNULL(dtm_type,0)<>2 THEN cmm_discount_amount ELSE 0 END) AS [Self Borne Discount],
	SUM(CASE WHEN cmd.manual_discount=1 OR manual_dp=1 THEN basic_discount_amount ELSE 0 END) [Manual Discount],
	sum(claimed_base_value) [Claim Base],gm_per [Margin %],
	SUM(claimed_base_gm_value) [Margin Amount],SUM(output_gst) [Output GST],
	SUM(input_gst) [Input GST],SUM(a.net_payable) [Payment Amount],
	(case when SUM(cmd.rfnet)<>0 THEN  convert(numeric(10,2),
	ROUND((SUM(claimed_base_gm_value)/SUM(cmd.rfnet))*100,2)) else 0 end) [Margin% wrt Actual NRV]
	FROM eosssord a (NOLOCK) 
	JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	JOIN sor_terms_mst c (NOLOCK) ON c.sor_terms_code=a.sor_terms_code
	JOIN lm01106 d (NOLOCK) ON d.ac_code=b.ac_code
	JOIN cmd01106 cmd (NOLOCK) ON cmd.row_id=a.cmd_row_id
	JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_id=cmd.cm_id
	JOIN dtm (NOLOCK) ON dtm.dt_code=cmm.dt_code
	where memo_dt between @dFromDt AND @dToDt AND b.cancelled=0
	GROUP BY ac_name,eoss_scheme_name,sor_terms_name,gm_per

	UNION ALL
	SELECT 2 disp_order,ac_name,'Totals:' eoss_scheme_name,'' sor_terms_name,SUM(cmd.quantity) [Qty Sold],SUM(mrp_value) [Mrp Value],
	SUM(a.discount_amount) [Total Discount],SUM(rfnet) [Actual NRV],SUM(a.card_discount_amount) [Card Discount],
	SUM(CASE WHEN ISNULL(dtm_type,0)<>2 THEN cmm_discount_amount ELSE 0 END) AS [Self Borne Discount],
	SUM(CASE WHEN cmd.manual_discount=1 OR manual_dp=1 THEN basic_discount_amount ELSE 0 END) [Manual Discount],
	sum(claimed_base_value) [Claim Base],0 [Margin %],
	SUM(claimed_base_gm_value) [Margin Amount],SUM(output_gst) [Output GST],
	SUM(input_gst) [Input GST],SUM(a.net_payable) [Payment Amount],
	(case when SUM(cmd.rfnet)<>0 THEN  convert(numeric(10,2),
	ROUND((SUM(claimed_base_gm_value)/SUM(cmd.rfnet))*100,2)) else 0 end) [Margin% wrt Actual NRV]
	FROM eosssord a (NOLOCK) 
	JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	JOIN sor_terms_mst c (NOLOCK) ON c.sor_terms_code=a.sor_terms_code
	JOIN lm01106 d (NOLOCK) ON d.ac_code=b.ac_code
	JOIN cmd01106 cmd (NOLOCK) ON cmd.row_id=a.cmd_row_id
	JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_id=cmd.cm_id
	JOIN dtm (NOLOCK) ON dtm.dt_code=cmm.dt_code
	where memo_dt between @dFromDt AND @dToDt AND b.cancelled=0
	GROUP BY ac_name
	) a
	order by [Supplier],disp_order,[Eoss Scheme],[Sor Terms]

	SELECT * FROM  
	(
	SELECT ac_name [Supplier],1 disp_order,eoss_scheme_name [Eoss Scheme],sor_terms_name [Sor Terms],
	cmm.cm_dt [Bill Date],cmm.cm_no [Bill no.],a.product_code [Item Code],SUM(cmd.quantity) [Qty Sold],SUM(mrp_value) [Mrp Value],
	SUM(a.discount_amount) [Total Discount],SUM(rfnet) [Actual NRV],SUM(a.card_discount_amount) [Card Discount],
	SUM(CASE WHEN ISNULL(dtm_type,0)<>2 THEN cmm_discount_amount ELSE 0 END) AS [Self Borne Discount],
	SUM(CASE WHEN cmd.manual_discount=1 OR manual_dp=1 THEN basic_discount_amount ELSE 0 END) [Manual Discount],
	sum(claimed_base_value) [Claim Base],gm_per [Margin %],
	SUM(claimed_base_gm_value) [Margin Amount],SUM(output_gst) [Output GST],
	SUM(input_gst) [Input GST],SUM(a.net_payable) [Payment Amount],a.cmd_row_id,
	(case when SUM(cmd.rfnet)<>0 THEN  convert(numeric(10,2),
	ROUND((SUM(claimed_base_gm_value)/SUM(cmd.rfnet))*100,2)) else 0 end) [Margin% wrt Actual NRV]
	FROM eosssord a (NOLOCK) 
	JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	JOIN sor_terms_mst c (NOLOCK) ON c.sor_terms_code=a.sor_terms_code
	JOIN lm01106 d (NOLOCK) ON d.ac_code=b.ac_code
	JOIN cmd01106 cmd (NOLOCK) ON cmd.row_id=a.cmd_row_id
	JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_id=cmd.cm_id
	JOIN dtm (NOLOCK) ON dtm.dt_code=cmm.dt_code
	where memo_dt between @dFromDt AND @dToDt AND b.cancelled=0
	GROUP BY ac_name,eoss_scheme_name,sor_terms_name,gm_per,cmm.cm_dt,cmm.cm_no,a.cmd_row_id,a.product_code

	UNION ALL
	SELECT ac_name,2 disp_order,'Totals:' eoss_scheme_name,'' sor_terms_name,'' cm_dt,'' cm_no,'' product_code,SUM(cmd.quantity) [Qty Sold],SUM(mrp_value) [Mrp Value],
	SUM(a.discount_amount) [Total Discount],SUM(rfnet) [Actual NRV],SUM(a.card_discount_amount) [Card Discount],
	SUM(CASE WHEN ISNULL(dtm_type,0)<>2 THEN cmm_discount_amount ELSE 0 END) AS [Self Borne Discount],
	SUM(CASE WHEN cmd.manual_discount=1 OR manual_dp=1 THEN basic_discount_amount ELSE 0 END) [Manual Discount],
	sum(claimed_base_value) [Claim Base],0 [Margin %],
	SUM(claimed_base_gm_value) [Margin Amount],SUM(output_gst) [Output GST],
	SUM(input_gst) [Input GST],SUM(a.net_payable) [Payment Amount],''  cmd_row_id,
	(case when SUM(cmd.rfnet)<>0 THEN  convert(numeric(10,2),
	ROUND((SUM(claimed_base_gm_value)/SUM(cmd.rfnet))*100,2)) else 0 end) [Margin% wrt Actual NRV]
	FROM eosssord a (NOLOCK) 
	JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	JOIN sor_terms_mst c (NOLOCK) ON c.sor_terms_code=a.sor_terms_code
	JOIN lm01106 d (NOLOCK) ON d.ac_code=b.ac_code
	JOIN cmd01106 cmd (NOLOCK) ON cmd.row_id=a.cmd_row_id
	JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_id=cmd.cm_id
	JOIN dtm (NOLOCK) ON dtm.dt_code=cmm.dt_code
	where memo_dt between @dFromDt AND @dToDt AND b.cancelled=0
	GROUP BY ac_name
	) a
	order by [Supplier],disp_order,[Eoss Scheme],[Sor Terms],[Bill Date],[Bill no.]
END
