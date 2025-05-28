
if exists (select top 1  'u' from BUYER_ORDER_MST where cancelled=0)
and not exists (select top 1 'u' from SalesOrderProcessing (nolock) )
begin



            if object_id ('tempdb..#tmpOrder','U') is not null
			   drop table #tmpOrder

            PRINT 'STEP 10: Order Quantity -'+convert(varchar,getdate(),113)

			SELECT cast('Order' as varchar(100)) XnType ,
			       cast(A.ORDER_ID as varchar(50)) Memoid,A.ORDER_ID RefMemoid,  B.ARTICLE_CODE,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE ,
			       SUM(B.QUANTITY   ) AS QTY
			into #tmpOrder
			FROM BUYER_ORDER_MST A (nolock)
			JOIN BUYER_ORDER_DET B (nolock) ON A.ORDER_ID =B.ORDER_ID 
			WHERE A.CANCELLED =0
			GROUP BY A.ORDER_ID ,A.ORDER_ID ,  B.ARTICLE_CODE,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE 

			PRINT 'STEP 20: Against Order Picklist Quantity -'+convert(varchar,getdate(),113)

			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			SELECT 'OrderPicklist' XnType ,A.MEMO_ID Memoid,C.ORDER_ID RefMemoid,  C.ARTICLE_CODE,C.PARA1_CODE ,C.PARA2_CODE ,C.PARA3_CODE,
				   SUM(A.QUANTITY) AS PICKLIST_QTY
			FROM PLD01106 A (NOLOCK)
			JOIN PLM01106 B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
			JOIN BUYER_ORDER_DET C (NOLOCK) ON A.ORD_ROW_ID =C.ROW_ID 
			join BUYER_ORDER_MST d (nolock) on d.order_id =c.order_id 
			WHERE B.CANCELLED =0 AND ISNULL(A.ORD_ROW_ID,'')<>''
			GROUP BY A.MEMO_ID ,C.ORDER_ID ,  C.ARTICLE_CODE,C.PARA1_CODE ,C.PARA2_CODE ,C.PARA3_CODE 
			Union all
			SELECT 'OrderPicklist' XnType ,A.MEMO_ID Memoid,b.ORDER_ID RefMemoid,  a.ARTICLE_CODE,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE,
				   SUM(A.QUANTITY) AS PICKLIST_QTY
			FROM PLD01106 A (NOLOCK)
			JOIN PLM01106 B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
			WHERE B.CANCELLED =0 AND ISNULL(A.ORD_ROW_ID,'')='' and isnull(b.order_id,'') <>''
			GROUP BY A.MEMO_ID ,b.ORDER_ID ,  a.ARTICLE_CODE,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE 

			PRINT 'STEP 30: one more Entry Picklist Quantity (refmemoid memoid same) -'+convert(varchar,getdate(),113)

			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			SELECT 'PickList' XnType ,A.MEMO_ID Memoid,a.MEMO_ID RefMemoid,  a.ARTICLE_CODE,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE,
				   SUM(A.QUANTITY) AS PICKLIST_QTY
			FROM PLD01106 A (NOLOCK)
			JOIN PLM01106 B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
			WHERE B.CANCELLED =0 
			and isnull(a.ARTICLE_CODE,'')<>''
			GROUP BY A.MEMO_ID , a.ARTICLE_CODE,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE 

			PRINT 'STEP 40: Against Picklist Packslip -'+convert(varchar,getdate(),113)

			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			select 'PLPackSlip' XnType ,A.ps_id Memoid,c.MEMO_ID RefMemoid,  d.ARTICLE_CODE,d.PARA1_CODE ,d.PARA2_CODE ,d.PARA3_CODE,
							   SUM(A.QUANTITY) AS PICKLIST_QTY
			from wps_det A (nolock)
			join wps_mst b (nolock) on a.ps_id =b.ps_id 
			join PLD01106  c on a.PICK_LIST_ROW_ID  =c.row_id 
			join sku d on a.PRODUCT_CODE =d.product_code 
			where  b.cancelled=0 
			and PICK_LIST_ROW_ID<>''
			--and isnull(d.ARTICLE_CODE,'')=''
			and ENTRY_MODE =4
			group by A.ps_id,c.MEMO_ID ,  d.ARTICLE_CODE,d.PARA1_CODE ,d.PARA2_CODE ,d.PARA3_CODE

			PRINT 'STEP 50: Against order Packslip -'+convert(varchar,getdate(),113)

			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			select 'OrderPackSlip' XnType ,A.ps_id Memoid,c.order_id RefMemoid,  c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE,
							   SUM(A.QUANTITY) AS PICKLIST_QTY
			from wps_det A (nolock)
			join wps_mst b (nolock) on a.ps_id =b.ps_id 
			join BUYER_ORDER_DET c on a.BO_DET_ROW_ID =c.row_id 
			where  b.cancelled=0 
			and bo_det_row_id<>''
			and ENTRY_MODE =3
			group by A.ps_id,c.order_id ,  c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE


			PRINT 'STEP 60: Against order Invoice -'+convert(varchar,getdate(),113)

			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			select 'OrderInvoice' XnType ,A.inv_id Memoid,c.order_id RefMemoid,  c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE,
							   SUM(A.QUANTITY) AS Invoice_QTY
			from Ind01106 A (nolock)
			join inm01106 b (nolock) on a.INV_ID =b.INV_ID 
			join BUYER_ORDER_DET c on a.BO_DET_ROW_ID =c.row_id 
			where  b.cancelled=0 
			and bo_det_row_id<>''
			and ENTRY_MODE =3
			group by A.inv_id,c.order_id ,  c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE

			PRINT 'STEP 70: Order Shortclose -'+convert(varchar,getdate(),113)
			
			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			SELECT 'ORDERSHORTCLOSE' XNTYPE ,MEMOID, REFMEMOID ,ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,PARA3_CODE ,
			       SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END) AS SHORTCLOSEQTY
			FROM #TMPORDER A
			JOIN BUYER_ORDER_MST B ON A.REFMEMOID=B.ORDER_ID 
			WHERE XNTYPE IN('ORDER','ORDERPICKLIST','ORDERPACKSLIP','ORDERINVOICE')
			AND ISNULL(B.SHORT_CLOSE,0) =1
			GROUP BY MEMOID, REFMEMOID ,ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,PARA3_CODE 
			HAVING SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END) >0

			PRINT 'STEP 80: PicklIst Shortclose -'+convert(varchar,getdate(),113)

			INSERT INTO #TMPORDER(XNTYPE,MEMOID ,REFMEMOID,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,QTY )
			SELECT 'PLShortClose' XNTYPE ,REFMEMOID MEMOID, REFMEMOID ,ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,PARA3_CODE ,
			       SUM(CASE WHEN XNTYPE ='PickList' THEN QTY ELSE -QTY END) AS SHORTCLOSEQTY
			FROM #TMPORDER A
			JOIN PLM01106  B ON A.REFMEMOID=B.MEMO_ID  
			WHERE XNTYPE IN('PickList','PLPackSlip')
			AND ISNULL(B.SHORT_CLOSE,0) =1
			GROUP BY MEMOID, REFMEMOID ,ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,PARA3_CODE 
			HAVING SUM(CASE WHEN XNTYPE ='PickList' THEN QTY ELSE -QTY END) >0

			INSERT SalesOrderProcessing	(XnType,RefMemoId,MemoId, ArticleCode,  Para1Code, Para2Code, Para3Code, Qty )  
			select XnType,RefMemoId,MemoId,ARTICLE_CODE ArticleCode, PARA1_CODE Para1Code,PARA2_CODE Para2Code,PARA3_CODE Para3Code, Qty
			from #TMPORDER


			PRINT 'STEP 100: order PicklIst setoff  first come firt serve process which has to be allocate without order  -'+convert(varchar,getdate(),113)

		
			
			IF OBJECT_ID('TEMPDB..#TMPpicklist','U') IS NOT NULL
			   DROP TABLE #TMPpicklist

			SELECT a.memo_id, A.AC_CODE ,B.ARTICLE_CODE ,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE ,
			       SUM(QUANTITY) AS PICKLISTQTY
				   into #TMPPICKLIST
			FROM PLM01106 A
			JOIN PLD01106 B ON A.MEMO_ID=B.MEMO_ID 
			WHERE A.CANCELLED =0 
			AND ISNULL(B.ORD_ROW_ID,'')='' and isnull(a.order_id,'')=''
			GROUP BY a.memo_id,A.AC_CODE ,B.ARTICLE_CODE ,B.PARA1_CODE ,B.PARA2_CODE ,B.PARA3_CODE 



			IF OBJECT_ID('TEMPDB..#tmppldetails','U') IS NOT NULL
			   DROP TABLE #tmppldetails

			;with cte as
			(
			select  memo_id ,AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,PICKLISTQTY ,
			        1 as Srno
			from #TMPPICKLIST
			union all
			select memo_id ,AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,PICKLISTQTY ,
			        Srno=Srno+1 
			from cte   
	        WHERE SrNo<PICKLISTQTY
			)

			select memo_id ,AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,PICKLISTQTY,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #tmppldetails from cte
			option (maxrecursion 32767);

			;with cte as
			(
			select *,sr= row_number() over(partition by AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code 
			order by memo_id )from #tmppldetails
			)
			Update cte set srno =sr 

			if object_id ('tempdb..#tmppl','U') is not null
			   drop table #tmppl


			select AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code 
			into #tmppl
			from #tmppldetails
			group by AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code 

			IF OBJECT_ID('TEMPDB..#TMPPENDINGORDER','U') IS NOT NULL
			   DROP TABLE #TMPPENDINGORDER

			SELECT AC_CODE =bm.ac_code,
			       REFMEMOID ,ARTICLECODE ARTICLE_CODE ,PARA1CODE PARA1_CODE ,PARA2CODE PARA2_CODE ,PARA3CODE PARA3_CODE ,
			       SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END) AS ORDERQTY,
				   SrNo =cast(0 as numeric(10,0)),cumm_qty =cast(0 as numeric(14,3))
				   INTO #TMPPENDINGORDER
			FROM SalesOrderProcessing A with (nolock)
			join BUYER_ORDER_MST bm (nolock) on a.RefMemoId =bm.order_id 
			join #tmppl b on a.articlecode=b.article_code and a.Para1Code =b.para1_code and a.Para2Code =b.para2_code and a.Para3Code =b.para3_code 
			and bm.ac_code =b.AC_CODE
			WHERE XNTYPE IN('ORDER','ORDERPICKLIST','ORDERSHORTCLOSE','ORDERPACKSLIP','ORDERINVOICE')
			GROUP BY bm.ac_code,REFMEMOID ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE 
			HAVING SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END)>0


			IF OBJECT_ID('TEMPDB..#tmporddetails','U') IS NOT NULL
			   DROP TABLE #tmporddetails

			;with cteord as
			(
			select  RefMemoid ,AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,ORDERQTY ,
			        1 as Srno
			from #TMPPENDINGORDER
			union all
			select RefMemoid ,AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,ORDERQTY ,
			        Srno=Srno+1 
			from cteord   
	        WHERE SrNo<ORDERQTY
			)

			select RefMemoid ,AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,ORDERQTY,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #tmporddetails 
			from cteord
			 option (maxrecursion 32767);

			 ;with cte as
			(
			select *,sr= row_number() over(partition by AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code 
			order by refmemoid )from #tmporddetails
			)
			Update cte set srno =sr 

			INSERT SalesOrderProcessing	(XnType,RefMemoId,MemoId, ArticleCode,  Para1Code, Para2Code, Para3Code, Qty )  
			
			SELECT 'orderpicklist' XnType,B.REFMEMOID  ,A.MEMO_ID 
			       ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE ,
				   SUM(A.QTY) AS QTY
			FROM #TMPPLDETAILS A
			JOIN #TMPORDDETAILS B ON A.AC_CODE =B.AC_CODE
			AND A.ARTICLE_CODE=B.ARTICLE_CODE 
			AND A.PARA1_CODE=B.PARA1_CODE 
			AND A.PARA2_CODE=B.PARA2_CODE 
			AND A.PARA3_CODE=B.PARA3_CODE 
			AND A.SRNO=B.SRNO 
			GROUP BY A.MEMO_ID ,A.ARTICLE_CODE ,
			A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE ,B.REFMEMOID


			PRINT 'STEP 110:  PicklIst packslip  setoff  first come firt serve process which has to be allocate without Picklist  -'

			

		   IF OBJECT_ID('TEMPDB..#TMPWPSITEM','U') IS NOT NULL
			   DROP TABLE #TMPWPSITEM

			select b.ac_code, A.ps_id Memoid, c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE,
				   SUM(A.QUANTITY) AS packslip_QTY
			 into #TMPWPSITEM
			from wps_det A (nolock)
			join wps_mst b (nolock) on a.ps_id =b.ps_id 
			join sku c on a.product_code=c.product_code
			where  b.cancelled=0 
			and isnull(a.bo_det_row_id,'')=''
			and ENTRY_MODE =3
			group by b.ac_code,A.ps_id ,  c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE

			
			IF OBJECT_ID('TEMPDB..#TMPP_wps_order','U') IS NOT NULL
			   DROP TABLE #TMPP_wps_order

			;with cteWPSITEM as
			(
			select ac_code,  Memoid  ,Article_code ,PARA1_CODE ,para2_code ,para3_code ,packslip_QTY  ,
			        1 as Srno
			from #TMPWPSITEM
			union all
			select ac_code, Memoid  ,Article_code ,PARA1_CODE ,para2_code ,para3_code ,packslip_QTY ,
			        Srno=Srno+1 
			from cteWPSITEM   
	        WHERE SrNo<packslip_QTY
			)

			select ac_code, Memoid  ,Article_code ,PARA1_CODE ,para2_code ,para3_code,packslip_QTY,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #TMPP_wps_order 
			from cteWPSITEM
		    option (maxrecursion 32767);


			 ;with cte as
			(
			select *,sr= row_number() over(partition by ac_code,  Article_code ,PARA1_CODE ,para2_code ,para3_code 
			order by Memoid )from #TMPP_wps_order
			)
			Update cte set srno =sr 

			--buyer order packslip

			
	  
	  IF OBJECT_ID('TEMPDB..#TMPPENDINGORDER_wps','U') IS NOT NULL
			   DROP TABLE #TMPPENDINGORDER_wps

			SELECT ACCODE =mst.ac_code,
			       REFMEMOID ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE ,
			       SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END) AS ORDERQTY,
				   SrNo =cast(0 as numeric(10,0)),cumm_qty =cast(0 as numeric(14,3))
				   INTO #TMPPENDINGORDER_wps
			FROM SalesOrderProcessing A (nolock)
			join buyer_order_mst mst (nolock) on a.REFMEMOID=mst.order_id
			join
			(
			select ac_code, Article_code ,PARA1_CODE ,para2_code ,para3_code  from #TMPP_wps_order
			group by ac_code,Article_code ,PARA1_CODE ,para2_code ,para3_code 
			) b on a.Articlecode=b.article_code and a.para1code=b.para1_code and a.para2code=b.para2_code
			and a.para3code=b.para3_code and mst.ac_code=b.ac_code
			WHERE XNTYPE IN('ORDER','ORDERPICKLIST','ORDERSHORTCLOSE','ORDERPACKSLIP','ORDERINVOICE')
			GROUP BY mst.ac_code, REFMEMOID ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE 
			HAVING SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END)>0





			IF OBJECT_ID('TEMPDB..#tmpordWPS','U') IS NOT NULL
			   DROP TABLE #tmpordWPS

			;with cteord as
			(
			select  RefMemoid ,ACCODE ,Articlecode ,para1code ,para2code ,para3code ,ORDERQTY ,
			        1 as Srno
			from #TMPPENDINGORDER_wps
			union all
			select RefMemoid ,ACCODE ,Articlecode ,para1code ,para2code ,para3code ,ORDERQTY ,
			        Srno=Srno+1 
			from cteord   
	        WHERE SrNo<ORDERQTY
			)

			select RefMemoid ,ACCODE ,Articlecode ,para1code ,para2code ,para3code ,ORDERQTY,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #tmpordWPS 
			from cteord
			 option (maxrecursion 32767);

			 ;with cte as
			(
			select *,sr= row_number() over(partition by ACCODE ,Articlecode ,para1code ,para2code ,para3code 
			order by refmemoid )from #tmpordWPS
			)
			Update cte set srno =sr 

			INSERT SalesOrderProcessing	(XnType,RefMemoId,MemoId, ArticleCode,  Para1Code, Para2Code, Para3Code, Qty )  
			select 'OrderPackSlip' XnType,B.REFMEMOID  ,A.MEMOID 
			       ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE ,
				   SUM(A.QTY) AS QTY 
			from #TMPP_wps_order A
			join #tmpordWPS b on a.article_code =b.ArticleCode and a.para1_code =b.Para1Code 
			and a.para2_code =b.Para2Code and a.para3_code =b.Para3Code and a.SrNo =b.SrNo and a.ac_code=b.accode
			group by B.REFMEMOID  ,A.MEMOID ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE 


			--packslip settlement


           IF OBJECT_ID('TEMPDB..#TMPPENDINGPL','U') IS NOT NULL
			   DROP TABLE #TMPPENDINGPL

			SELECT b.AC_CODE , REFMEMOID ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE ,
			       SUM(CASE WHEN XNTYPE ='PickList' THEN QTY ELSE -QTY END) AS PicklistQTY
				   INTO #TMPPENDINGPL
			FROM SalesOrderProcessing A (nolock)
			join plm01106 b (nolock) on a.RefMemoId =b.MEMO_ID
			WHERE XNTYPE IN('PickList','PLPackSlip','PLShortClose')
			GROUP BY b.AC_CODE ,REFMEMOID ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE 
			HAVING SUM(CASE WHEN XNTYPE ='PickList' THEN QTY ELSE -QTY END)>0



			IF OBJECT_ID('TEMPDB..#TMPWPS','U') IS NOT NULL
			   DROP TABLE #TMPWPS

			select b.ac_code , A.ps_id Memoid, c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE,
				   SUM(A.QUANTITY) AS packslip_QTY
				   into #TMPWPS
			from wps_det A (nolock)
			join wps_mst b (nolock) on a.ps_id =b.ps_id 
			join sku c (nolock) on a.PRODUCT_CODE =c.product_code 
			where  b.cancelled=0 
			and ISNULL(PICK_LIST_ROW_ID,'')=''
			and ENTRY_MODE =4
			group by b.ac_code ,A.ps_id ,  c.ARTICLE_CODE,c.PARA1_CODE ,c.PARA2_CODE ,c.PARA3_CODE


		    
			IF OBJECT_ID('TEMPDB..#TMPPLWPS','U') IS NOT NULL
			   DROP TABLE #TMPPLWPS

			;with cteord as
			(
			select ac_code,  RefMemoid  ,Articlecode ,para1code ,para2code ,para3code ,PicklistQTY  ,
			        1 as Srno
			from #TMPPENDINGPL
			union all
			select ac_code,  RefMemoid  ,Articlecode ,para1code ,para2code ,para3code ,PicklistQTY ,
			        Srno=Srno+1 
			from cteord   
	        WHERE SrNo<PicklistQTY
			)

			select ac_code,  RefMemoid  ,Articlecode ,para1code ,para2code ,para3code ,PicklistQTY,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #TMPPLWPS 
			from cteord
		    option (maxrecursion 32767);

			 ;with cte as
			(
			select *,sr= row_number() over(partition by ac_code,  Articlecode ,para1code ,para2code ,para3code 
			order by refmemoid )from #TMPPLWPS
			)
			Update cte set srno =sr 


			IF OBJECT_ID('TEMPDB..#TMPWPSdet','U') IS NOT NULL
			   DROP TABLE #TMPWPSdet

			;with ctewps as
			(
			select ac_code,  memoid  ,Article_code ,para1_code ,para2_code ,para3_code ,packslip_QTY   ,
			        1 as Srno
			from #TMPWPS
			union all
			select ac_code,  memoid  ,Article_code ,para1_code ,para2_code ,para3_code ,packslip_QTY ,
			        Srno=Srno+1 
			from ctewps   
	        WHERE SrNo<packslip_QTY
			)

			select ac_code,  memoid  ,Article_code ,para1_code ,para2_code ,para3_code ,packslip_QTY,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #TMPWPSdet 
			from ctewps
		    option (maxrecursion 32767);

			 ;with cte as
			(
			select *,sr= row_number() over(partition by ac_code,  Article_code ,para1_code ,para2_code ,para3_code 
			order by memoid )from #TMPWPSdet
			)
			Update cte set srno =sr 

			INSERT SalesOrderProcessing	(XnType,RefMemoId,MemoId, ArticleCode,  Para1Code, Para2Code, Para3Code, Qty )  
			select 'PLPACKSLIP' XnType,B.REFMEMOID  ,A.MEMOID 
			       ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE ,
				   SUM(A.QTY) AS QTY 
			from #TMPWPSdet A
			join #TMPPLWPS b on a.article_code =b.ArticleCode and a.para1_code =b.Para1Code 
			and a.para2_code =b.Para2Code and a.para3_code =b.Para3Code and a.SrNo =b.SrNo and a.ac_code =b.AC_CODE 
			group by B.REFMEMOID  ,A.MEMOID ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE 



END

