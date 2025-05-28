create PROCEDURE SPWOW_GENXPERT_REPDATA_WBOPEN
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)='',
@bCalledfromStkAnalysis BIT=0
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT,
	@cGitTable VARCHAR(200),@cinmJoin varchar(100)
	

   --drop table if exists  #tmporderreport
    set @cinmJoin=''

   PRINT 'Step#1:'+convert(varchar,getdate(),113)
	SELECT   RefMemoId ,a.Articlecode ,a.para1code ,a.para2code ,a.para3Code,
			 SUM(CASE WHEN A.XNTYPE='ORDER' THEN QTY ELSE 0 END ) AS OrderQty,
			 SUM(CASE WHEN A.XNTYPE='ORDERPICKLIST' THEN QTY ELSE 0 END ) as pickListQty,
			 SUM(CASE WHEN A.XNTYPE='ORDERPACKSLIP' THEN QTY ELSE 0 END ) as orderPackSlipQty,
			 SUM(CASE WHEN A.XNTYPE='orderInvoice' THEN QTY ELSE 0 END ) as orderInvoiceQty,
			 cast(0 as numeric(14,3)) as plPackSlipQty,
			 cast(0 as numeric(14,3)) as plInvoiceQty,
			 cast (0 as numeric (14,3)) as pendingPickListQty,
			 cast (0 as numeric (14,3)) as plShortCloseQty,
			 isnull(c.plannedQty,0) as plannedQty,
			 isnull(c.maxStockLevel,0) as maxStockLevel,
			 SUM(CASE WHEN A.XNTYPE='orderShortClose' THEN QTY ELSE 0 END ) as orderShortCloseQty,
			 SUM(CASE WHEN A.XNTYPE='ORDER' THEN QTY ELSE -1*Qty END )  as pendingOrderQty
		
	into #tmporder
	FROM SalesOrderProcessing A with (nolock)
	JOIN buyer_order_mst b (NOLOCK) ON b.order_id=a.RefMemoId
	LEFT JOIN wowArsDet c (NOLOCK) ON c.memoId=b.aro_plan_id AND c.articleCode=a.ArticleCode AND c.para1Code=a.Para1Code
	WHERE  XNTYPE IN('ORDER','ORDERPICKLIST','ORDERPACKSLIP','ORDERINVOICE','orderShortClose')
	and Qty>0 and b.CANCELLED =0
	GROUP BY RefMemoId,a.Articlecode ,a.para1code ,a.para2code,a.para3code,isnull(c.plannedQty,0),isnull(c.maxStockLevel,0)

	PRINT 'Step#2:'+convert(varchar,getdate(),113)
	insert into #tmporder(RefMemoId,Articlecode,para1code,para2code,para3Code,OrderQty,pickListQty,orderPackSlipQty,orderInvoiceQty,
			   plPackSlipQty,plInvoiceQty,orderShortCloseQty,pendingOrderQty,pendingPickListQty,plShortCloseQty,plannedQty,maxStockLevel)
	SELECT  PLM01106.order_id ,Articlecode ,para1code ,para2code ,para3Code,
			0 AS OrderQty,
			0 as pickListQty,
			0 as orderPackSlipQty,
			0 as orderInvoiceQty,
			SUM(CASE WHEN XNTYPE='PLPACKSLIP' THEN  QTY ELSE 0 END  ) as plPackSlipQty,
			cast(0 as numeric(14,3)) as plInvoiceQty,
			0 as OrderShortClose,
			0  as pendingOrderQty,
			0 as pendingPickListQty,
			SUM(CASE WHEN XNTYPE='PLShortClose' THEN  QTY ELSE 0 END  )  as plShortCloseQty,0 plannedQty,0 maxStockLevel
	FROM SalesOrderProcessing A (nolock)
	join PLM01106  (nolock) on a.RefMemoId =PLM01106.MEMO_ID 
	WHERE XNTYPE IN('plPackSlip','plInvoice','PLShortClose') and Qty >0
	and PLM01106 .CANCELLED =0
	GROUP BY PLM01106.order_id ,Articlecode ,para1code ,para2code ,para3Code


	----select XnType from SalesOrderProcessing
	----group by XnType

	PRINT 'Step#3:'+convert(varchar,getdate(),113)
	select RefMemoId,Articlecode,para1code,para2code,para3Code,
	       sum(OrderQty) as OrderQty,
		   sum(pickListQty) as pickListQty,
		   sum(orderPackSlipQty) as orderPackSlipQty,
		   sum(orderInvoiceQty) as orderInvoiceQty,
		   sum(plPackSlipQty) as plPackSlipQty,
		   sum(plInvoiceQty) as plInvoiceQty,
		   sum(orderShortCloseQty) as orderShortCloseQty,
		   sum(OrderQty-(orderPackSlipQty+orderInvoiceQty+plPackSlipQty+orderShortCloseQty))  pendingOrderQty,
		   sum(pickListQty-(plPackSlipQty+plShortCloseQty)) pendingPickListQty,
		   sum(plShortCloseQty) as plShortCloseQty,plannedQty,maxStockLevel 
	into #tmporderreport
	from #tmporder
	group by RefMemoId,Articlecode,para1code,para2code,para3Code,plannedQty,maxStockLevel 
	
	
--select * from  #tmporderreport where RefMemoId='01250000000001kv000013'
	 IF EXISTS (SELECT TOP 1 'U' FROM #WOW_XPERT_REP_DET 
	           WHERE COLUMN_ID IN('C1452','C1453'))
    begin
        
        SELECT A.REFMEMOID , INM01106.INV_DT  ,INM01106.inv_no ,INM01106.TOTAL_QUANTITY
             into #tmpinm
        FROM #tmporderreport A
        JOIN SalesOrderProcessing  B (NOLOCK) ON A.REFMEMOID=B.REFMEMOID 
        JOIN WPS_MST (NOLOCK) ON B.MemoId  =WPS_MST .PS_ID   
        JOIN INM01106 (NOLOCK) ON INM01106 .INV_ID  =WPS_MST.WSL_INV_ID
        WHERE B.XNTYPE in('orderpackslip')
        group by A.REFMEMOID , INM01106.INV_DT  ,INM01106.inv_no ,INM01106.TOTAL_QUANTITY
        union all
        SELECT A.REFMEMOID , INM01106.INV_DT  ,INM01106.inv_no ,INM01106.TOTAL_QUANTITY
        FROM #tmporderreport A
        JOIN SalesOrderProcessing  B (NOLOCK) ON A.REFMEMOID=B.REFMEMOID 
        JOIN INM01106 (NOLOCK) ON INM01106 .INV_ID  =b.MemoId 
        WHERE B.XNTYPE in('orderinvoice')
        group by A.REFMEMOID , INM01106.INV_DT  ,INM01106.inv_no ,
		INM01106.TOTAL_QUANTITY
        
        
        set @cinmJoin=' Left join #tmpinm inm on inm.REFMEMOID =#tmporderreport.REFMEMOID  '
    
    end
    
	--PRINT 'Step#4:'+convert(varchar,getdate(),113)
	--UPDATE a SET plannedQty=c.plannedQty,maxStockLevel=c.maxStockLevel from #tmporderreport a
	--JOIN buyer_order_mst b (NOLOCK) ON b.order_id=a.RefMemoId
	--JOIN wowArsDet c (NOLOCK) ON c.memoId=b.aro_plan_id AND c.articleCode=a.ArticleCode AND c.para1Code=a.Para1Code
	--AND c.para2Code=a.Para2Code

	--if @@spid=429
	--	select 'check #tmporderreport',* from  #tmporderreport WHERE ISNULL(plannedqty,0)>0

	
	PRINT 'Step#5:'+convert(varchar,getdate(),113)
	SELECT @cBaseExpr='[LAYOUT_COLS]   from #tmporderreport (NOLOCK)       
	JOIN article (NOLOCK) ON article.article_code=#tmporderreport.articleCode
	JOIN para1 (NOLOCK) ON para1.para1_code=#tmporderreport.para1Code
	JOIN para2 (NOLOCK) ON para2.para2_code=#tmporderreport.para2Code
	JOIN para3 (NOLOCK) ON para3.para3_code=#tmporderreport.para3Code
	Left outer join art_det  (NOLOCK) ON  article.article_code =art_det.article_code and   art_det.para2_code=#tmporderreport.para2Code 
	left outer JOIN art_names sku_names (NOLOCK) ON sku_names.article_code=#tmporderreport.articleCode
    JOIN BUYER_ORDER_MST (NOLOCK) ON BUYER_ORDER_MST.ORDER_ID=#tmporderreport.refmemoId 
	left outer JOIN season_mst on season_mst.Season_Id=buyer_order_mst.season_id
	left outer JOIN employee employee1 on employee1.emp_code=buyer_order_mst.SALE_EMP_CODE
	LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=BUYER_ORDER_MST.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=BUYER_ORDER_MST.ac_code
	Left Outer JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	left JOIN location TargetLocation (NOLOCK) ON TargetLocation.dept_id=BUYER_ORDER_MST.dept_id	
	JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code	'+
	@cinmJoin+
	' WHERE [WHERE]  group by [GROUPBY] '


	PRINT 'Step#6:'+convert(varchar,getdate(),113)

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='WBOPEN',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT


	PRINT 'Step#7:'+convert(varchar,getdate(),113)
	PRINT @cBaseExprOutput

	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'Sku_Names.Article_Alias','article.alias')
	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'Sku_Names.para1_Alias','para1.alias')
	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'Sku_Names.para2_Alias','para2.alias')
	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'Sku_Names.para3_Alias','para3.alias')

	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END