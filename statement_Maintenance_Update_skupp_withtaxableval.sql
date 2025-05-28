if not exists (select top 1 product_code from  sku (NOLOCK) WHERE old_purchase_price IS not NULL)
BEGIN
	update a set xn_value_without_gst=(a.purchase_price-(a.purchase_price*b.discount_percentage/100)-
	(CASE WHEN bill_level_tax_method=2 THEN A.TAX_AMOUNT ELSE 0 end))*invoice_quantity
	from pid01106 a WITH (ROWLOCK)
	JOIN pim01106 b (NOLOCK) ON b.mrr_id=a.mrr_id
	join sku_names c (nolock) on c.product_code=a.product_code
	WHERE (b.receipt_dt<'2017-07-01'  OR BILL_DT<'2017-07-01')
	AND isnull(igst_amount,0)=0 AND ISNULL(cgst_amount,0)=0 AND inv_mode=1
	
	DECLARE @CFREIGHT_ADD_IN_PP VARCHAR(5)
	SELECT @CFREIGHT_ADD_IN_PP=value  FROM CONFIG (NOLOCK) WHERE config_option ='FREIGHT_ADD_IN_PP'

	UPDATE sku set old_purchase_price=purchase_price where old_purchase_price IS NULL


	--SELECT product_code,round(sum(xn_value_without_gst/invoice_quantity+(CASE WHEN ISNULL(@CFREIGHT_ADD_IN_PP,'')='1' THEN ISNULL(c.FREIGHT,0) ELSE 0 END )
	--	 +isnull(c.excise_duty_amount,0))/SUM(invoice_quantity),2) AVG_PP
	--INTO #tmpDup FROM pid01106 a (NOLOCK) 
	--JOIN pim01106 b (NOLOCK) ON a.mrr_id=b.mrr_id
	--JOIN sku_oh c (NOLOCK) on c.product_code=sku.product_code
	--WHERE inv_mode=1 AND cancelled=0 
	--GROUP BY product_code HAVING count(product_code)>1

	update sku set purchase_price=(b.xn_value_without_gst/b.invoice_quantity)+
		 (CASE WHEN ISNULL(@CFREIGHT_ADD_IN_PP,'')='1' THEN ISNULL(c.FREIGHT,0) ELSE 0 END )
		 +isnull(c.excise_duty_amount,0)
	FROM SKU WITH (ROWLOCK)
	JOIN pid01106 b (NOLOCK) ON b.product_code=sku.product_code
	JOIN sku_oh c (NOLOCK) on c.product_code=sku.product_code
	JOIN  pim01106 d (NOLOCK) ON d.mrr_id=b.mrr_id
	WHERE inv_mode=1 and isnull(b.invoice_quantity,0)<>0 and sku.product_code<>''
	AND sku.purchase_price<>((b.xn_value_without_gst/b.invoice_quantity)+
		 (CASE WHEN ISNULL(@CFREIGHT_ADD_IN_PP,'')='1' THEN ISNULL(c.FREIGHT,0) ELSE 0 END )
		 +isnull(c.excise_duty_amount,0))
END


