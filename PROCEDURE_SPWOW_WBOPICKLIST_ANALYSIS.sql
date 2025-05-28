create PROCEDURE SPWOW_WBOPICKLIST_ANALYSIS
@cLocId VARCHAR(4),
@cSeasonId VARCHAR(10),
@cAcCode CHAR(10)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT
	


	if object_id('tempdb..#tmporderreport','u') is not null
	   drop table #tmporderreport

	SELECT   RefMemoId ,Articlecode ,para1code ,para2code ,para3Code,
			 SUM(CASE WHEN A.XNTYPE='ORDER' THEN QTY ELSE 0 END ) AS OrderQty,
			 SUM(CASE WHEN A.XNTYPE='ORDERPACKSLIP' THEN QTY ELSE 0 END ) as orderPackSlipQty,
			 SUM(CASE WHEN A.XNTYPE='orderInvoiceQty' THEN QTY ELSE 0 END ) as orderInvoiceQty,
			 SUM(CASE WHEN A.XNTYPE='orderShortCloseQty' THEN QTY ELSE 0 END ) as orderShortCloseQty,
			 cast(0 as numeric(14,3)) as plPackSlipQty,
			 cast(0 as numeric(14,3)) as plInvoiceQty,
			 cast (0 as numeric (14,3)) as pendingPickListQty,
			 cast (0 as numeric (14,3)) as pendingOrderQty
		
	into #tmporderreport
	FROM SalesOrderProcessing A with (nolock)
	JOIN buyer_order_mst b (NOLOCK) ON b.order_id=a.RefMemoId
	WHERE XNTYPE IN('ORDER','ORDERPICKLIST','ORDERPACKSLIP','ORDERINVOICE','OrderShortClose')
	AND b.wbo_for_dept_id=@cLocId AND b.season_id=@cSeasonId AND (b.ac_code=@cAcCode OR @cAcCode='')
	GROUP BY RefMemoId,Articlecode ,para1code ,para2code,para3code
	

	insert into #tmporderreport(RefMemoId,Articlecode,para1code,para2code,para3Code,OrderQty,orderPackSlipQty,orderInvoiceQty,
			   plPackSlipQty,plInvoiceQty,orderShortCloseQty,pendingOrderQty,pendingPickListQty)
	SELECT  PLM01106.order_id ,Articlecode ,para1code ,para2code ,para3Code,
			0 AS OrderQty,
			0 as orderPackSlipQty,
			0 as orderInvoiceQty,
			SUM(CASE WHEN xntype='plPackSlip' then  QTY else 0  end) as plPackSlipQty,
			SUM(CASE WHEN xntype='plinvoice' then  QTY else 0  end) as plInvoiceQty,
			0 as OrderShortClose,
			0  as pendingOrderQty,
		    SUM(CASE WHEN A.XNTYPE='picklist' THEN QTY ELSE -Qty END )  as pendingPickListQty

	FROM SalesOrderProcessing A (nolock)
	join PLM01106  (nolock) on a.RefMemoId =PLM01106.MEMO_ID 
	JOIN buyer_order_mst b (NOLOCK) ON b.order_id=PLM01106.order_id
	WHERE XNTYPE IN('PICKLIST','PLPACKSLIP','PLINVOICE','PLShortClose')
	AND b.wbo_for_dept_id=@cLocId AND b.season_id=@cSeasonId AND (b.ac_code=@cAcCode OR @cAcCode='')
	GROUP BY PLM01106.order_id ,Articlecode ,para1code ,para2code ,para3Code

	SELECT article_no,sum(quantity_in_stock) stockQty INTO #tmpStock FROM pmt01106 a (NOLOCK) 
	JOIN sku_names b (NOLOCK) ON a.product_code=b.product_Code
	WHERE dept_id=@cLocId 
	GROUP BY article_no
	having sum(quantity_in_stock)<>0



	SELECT buyer_order_mst.order_no saleOrderNo,buyer_order_mst.order_dt saleOrderDate, ac_name buyerName,sku_names.article_no articleNo,para1.para1_name para1Name,
	para2.para2_name para2Name,para3.para3_name para3Name,
	sum(OrderQty) OrderQty,sum(a.orderPackSlipQty+a.orderInvoiceQty+a.plPackSlipQty+a.plInvoiceQty) DispatchQty,sum(orderShortCloseQty) orderShortCloseQty,
	sum(OrderQty-(a.orderPackSlipQty+a.orderInvoiceQty+a.plPackSlipQty+a.plInvoiceQty+orderShortCloseQty)) pendingOrderQty,sum(pendingPickListQty) pendingPickListQty,
	ISNULL(stk.stockQty,0) stockQty from #tmporderreport a
	JOIN para1 (NOLOCK) ON para1.para1_code=a.para1Code
	JOIN para2 (NOLOCK) ON para2.para2_code=a.para2Code
	JOIN para3 (NOLOCK) ON para3.para3_code=a.para3Code
	JOIN art_names sku_names (NOLOCK) ON sku_names.article_code=a.articleCode
    JOIN BUYER_ORDER_MST (NOLOCK) ON BUYER_ORDER_MST.ORDER_ID=a.refmemoId 
	JOIN season_mst on season_mst.Season_Id=buyer_order_mst.season_id
	LEFT JOIN #tmpStock stk ON stk.article_no=sku_names.article_no 
	LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=BUYER_ORDER_MST.ac_code
	left JOIN location TargetLocation (NOLOCK) ON TargetLocation.dept_id=BUYER_ORDER_MST.dept_id
	GROUP BY buyer_order_mst.order_no,buyer_order_mst.order_dt,ac_name,sku_names.article_no,para1.para1_name,para2.para2_name,para3.para3_name,ISNULL(stk.stockQty,0)
	

END