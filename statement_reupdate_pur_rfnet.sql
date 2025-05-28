create table #tmppur (row_id varchar(50),rfnet_calc numeric(10,2))


select a.mrr_id,a.total_amount,b.rfnet,a.receipt_dt into #tmpdiff from  pim01106 a (nolock)
join 
(select a.mrr_id,sum(rfnet) rfnet from  pid01106 a (nolock) 
 join pim01106 b (nolock) on a.mrr_id=b.mrr_id
 where inv_mode=1 group by a.mrr_id)
b on a.mrr_id=b.mrr_id
where inv_mode=1 and cancelled=0 and  abs(a.total_amount-b.rfnet)>0
AND receipt_dt>='2020-04-01'


declare @cMrrid varchar(50),@dRecdt datetime,@nTotAmount NUMERIC(10,2),@cRowId VARCHAR(50),@NSUMRFNET numeric(10,2)
while exists (select top 1 mrr_id from  #tmpdiff)
begin
	

	select top 1 @cmrrid=mrr_id,@dRecdt=receipt_dt,@nTotAmount=total_amount from  #tmpdiff
	ORDER BY receipt_dt

	print 'Calculating rfnet for MrrId :'+@cmrrid+' dated :'+convert(varchar,@dRecdt,113)

	INSERT #tmppur (row_id,rfnet_calc)

	select a.row_id,
				DBO.FN_GETRFNETVALUE( A.PURCHASE_PRICE-(a.PIMDiscountAmount/a.invoice_quantity)+
				CASE WHEN B.BILL_LEVEL_TAX_METHOD=1 THEN  (A.TAX_AMOUNT/A.INVOICE_QUANTITY)
				+(ISNULL(A.IGST_AMOUNT,0)/A.INVOICE_QUANTITY)+(ISNULL(A.CGST_AMOUNT,0)/A.INVOICE_QUANTITY)+(ISNULL(A.SGST_AMOUNT,0)/A.INVOICE_QUANTITY) 
				+(ISNULL(A.Gst_Cess_Amount ,0)/A.INVOICE_QUANTITY)
				ELSE 0 END
				, A.INVOICE_QUANTITY, B.SUBTOTAL,
				( 
				--D.TAX_AMOUNT + 
				B.FREIGHT + 
				ISNULL(B.FREIGHT_IGST_AMOUNT ,0)+ISNULL(B.FREIGHT_CGST_AMOUNT ,0)+ISNULL(B.FREIGHT_SGST_AMOUNT ,0)+
				B.OTHER_CHARGES +b.tcs_amount+ 
				ISNULL(B.OTHER_CHARGES_IGST_AMOUNT ,0)+ISNULL(B.OTHER_CHARGES_CGST_AMOUNT ,0)+ISNULL(B.OTHER_CHARGES_SGST_AMOUNT ,0)+
				B.ROUND_OFF - ISNULL(B.POSTTAXDISCOUNTAMOUNT,0)+B.EXCISE_DUTY_AMOUNT)) rfnet_calc
				FROM pid01106 A (nolock)
				JOIN pim01106 B (nolock) ON A.MRR_ID = B.MRR_ID
	  where b.mrr_id=@cMrrId

	  print 'Updating rfnet for MrrId :'+@cmrrid+' dated :'+convert(varchar,@dRecdt,113)
	  update a with (rowlock) set rfnet=b.rfnet_calc FROM pid01106 a 
	  JOIN #tmpPur b on a.row_id=b.row_id
	  WHERE a.rfnet<>b.rfnet_calc
	  
	  
	  SELECT @NSUMRFNET = SUM(RFNET) FROM pid01106 (NOLOCK) WHERE mrr_id=@cMrrid 
	  SELECT TOP 1 @CROWID = ROW_ID FROM pid01106 (NOLOCK) WHERE mrr_id=@cMrrid 
	  IF @NSUMRFNET <> @nTotAmount
	  BEGIN
			PRINT 'UPDRFNET after diff for MrrId :'+@cmrrid+' dated :'+convert(varchar,@dRecdt,113)
			UPDATE pid01106 WITH (rowLOCK) SET RFNET = RFNET + ( @nTotAmount - @NSUMRFNET ) 
			WHERE   row_id=@CROWID
	 END


	  DELETE FROM #tmpdiff where mrr_id=@cMrrid
	  delete from #tmppur
end
