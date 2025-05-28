create PROCEDURE SP3S_VALIDATE_INV_PICKLIST_QTY_new
@cInvId VARCHAR(50),
@nUpdatemode numeric(2,0),
@nSpId varchar(50),
@cCurLocId varchar(5)='',
@NBOXUPDATEMODE		NUMERIC(3,0)=0,
@bOrderValidationFailed BIT OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN

   goto  END_PROC
    declare @cXntype varchar(10)
	set @cXntype='WSL'
	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-1'+@cXntype
	SET @bOrderValidationFailed=0

BEGIN TRY
	DECLARE @cStep VARCHAR(5),@cCmd NVARCHAR(MAX),@cUploadTable VARCHAR(200),
			@nEntrymode NUMERIC(1,0),@cInvoiceMstTable VARCHAR(200),@cInvoiceDetTable VARCHAR(200),@cAc_code VARCHAR(50)
	
	
	
	SET @cStep='125.10'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1	 	  


	CREATE TABLE #BUYERORDER (inv_qty NUMERIC(10,2),stock_qty NUMERIC(10,2),order_qty NUMERIC(10,2),
	pending_pl_qty NUMERIC(10,2),article_no varchar(300),section_name varchar(300),sub_section_name varchar(300),
	para1_name varchar(300),para2_name varchar(300),para3_name varchar(300),para4_name varchar(300),
	para5_name varchar(300),para6_name varchar(300),article_code CHAR(9),section_code  CHAR(7),
	sub_section_code  CHAR(7),para1_code CHAR(9),para2_code CHAR(9),para3_code CHAR(9),para4_code CHAR(9),
	para5_code CHAR(9),para6_code CHAR(9))

	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-2'
   
	SET @cStep='125.15'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	IF @cXntype='WSL' AND @nUpdatemode IN (1,2)
		SELECT @nEntrymode=entry_mode,@cAc_code=Ac_code FROM wsl_inm01106_upload (NOLOCK) WHERE sp_id=@nSpId 		
	ELSE
	IF @cXntype='WSL' AND @nUpdatemode NOT IN (1,2)
		SELECT @nEntrymode=entry_mode,@cAc_code=Ac_code FROM inm01106 (NOLOCK) WHERE inv_id=@cInvId  		
	
		
	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-3:'+@cInvId

	

	set @cStep='125.22'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	IF NOT EXISTS (SELECT TOP 1 order_id FROM buyer_order_mst (NOLOCK) where  cancelled=0)
		RETURN

	
	IF NOT EXISTS (SELECT TOP 1 'u' FROM #ORDERSETOFF ) AND @cXntype='WSL'
		RETURN
	
	
	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-4:'+@nSpId


	 IF @nEntrymode IN (1,3)
	 BEGIN
		SET @cStep='125.40'
		EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1

		INSERT INTO #BUYERORDER (stock_qty,order_qty,pending_pl_qty,inv_qty,
					Article_code,para1_code,para2_code,para3_code)

		SELECT 0 as stock_qty, 0 as order_qty,0 pending_pl_qty,SUM(QTY) inv_qty,a.Article_code,a.para1_code,a.para2_code,a.para3_code
		FROM #ORDERSETOFF a (NOLOCK)
		GROUP BY a.Article_code,a.para1_code,a.para2_code,a.para3_code
		having SUM(QTY)<>0

		
		Update a set article_no =b.article_no ,para1_name =p1.para1_name ,
		      para2_name =p2.para2_name ,para3_name=p3.para3_name 
		from #BUYERORDER A
		join article b (nolock) on a.article_code =b.article_code 
		join para1 p1  (nolock) on p1.para1_code =a.para1_code 
		join para2 p2 (nolock) on p2.para2_code =a.para2_code 
		join para3 p3 (nolock) on p3.para3_code =a.para3_code 


		IF EXISTS (SELECT TOP 1 'U' FROM #BUYERORDER WHERE inv_qty<0) and @nEntrymode=3
		BEGIN
		     
			 SELECT a.*,abs(b.inv_qty) as Inv_qty 
			   into #tmpInvoice
			 FROM SALESORDERPROCESSING A (NOLOCK)
			 join #BUYERORDER b on a.ArticleCode =b.article_code and a.Para1Code =b.para1_code and a.Para2Code =b.para2_code and para3_code =b.para3_code 
			 WHERE MEMOID =@CINVID and inv_qty <0


	

			 IF OBJECT_ID('TEMPDB..#tmpinvreduce','U') IS NOT NULL
			   DROP TABLE #tmpinvreduce

			;with cteInvRed as
			(
			select  RefMemoid  ,Articlecode ,para1code ,para2code ,para3code,Qty ,Inv_qty ,
			        1 as Srno
			from #tmpInvoice
			union all
			select RefMemoid  ,Articlecode ,para1code ,para2code ,para3code,Qty ,Inv_qty ,
			        Srno=Srno+1 
			from cteInvRed   
	        WHERE SrNo<Qty
			)

			SELECT REFMEMOID  ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE ,INV_QTY,
			       1 AS QTY ,CAST(0 AS NUMERIC(5,0)) AS SRNO
			INTO #TMPINVREDUCE 
			FROM CTEINVRED
			OPTION (MAXRECURSION 32767);

		   ;with cte as
			(
			select *,sr= row_number() over(partition by Articlecode ,para1code ,para2code ,para3code 
			order by REFMEMOID )from #TMPINVREDUCE
			)
			Update cte set srno =sr 

			
		
			;with cte_InvDetails As
			(
			select REFMEMOID  ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE ,
			       sum(QTY) as QTY
			from #TMPINVREDUCE 
			where SRNO <=Inv_qty 
			group by REFMEMOID  ,ARTICLECODE ,PARA1CODE ,PARA2CODE ,PARA3CODE
			)

			Update a set Qty=a.Qty-b.Qty FROM SALESORDERPROCESSING A (NOLOCK)
			join cte_InvDetails b on a.REFMEMOID=b.REFMEMOID and 
			a.ARTICLECODE=b.ARTICLECODE and a.PARA1CODE=b.PARA1CODE and a.PARA2CODE =b.PARA2CODE 
			and a.PARA3CODE =b.PARA3CODE 
			WHERE MEMOID =@CINVID

			if exists (select top 1 'ú' FROM SALESORDERPROCESSING A (NOLOCK) WHERE MEMOID =@CINVID AND QTY=0 AND XNTYPE='ORDERINVOICE')
			DELETE A FROM SALESORDERPROCESSING A (NOLOCK) WHERE MEMOID =@CINVID AND QTY=0 AND XNTYPE='ORDERINVOICE'



		END
	END


	
	IF @nEntrymode in(3)
	BEGIN
	
		SET @cStep='125.20'

			IF OBJECT_ID('TEMPDB..#TMPPENDINGORDER','U') IS NOT NULL
			   DROP TABLE #TMPPENDINGORDER

			SELECT AC_CODE =bm.ac_code,
			       REFMEMOID ,ARTICLECODE ARTICLE_CODE ,PARA1CODE PARA1_CODE ,PARA2CODE PARA2_CODE ,PARA3CODE PARA3_CODE ,
			       SUM(CASE WHEN XNTYPE ='ORDER' THEN QTY ELSE -QTY END) AS ORDERQTY
				   INTO #TMPPENDINGORDER
			FROM SalesOrderProcessing A with (nolock)
			join BUYER_ORDER_MST bm (nolock) on a.RefMemoId =bm.order_id 
			join #BUYERORDER b on a.articlecode=b.article_code and a.Para1Code =b.para1_code and a.Para2Code =b.para2_code and a.Para3Code =b.para3_code 
			and bm.ac_code =@cAc_code
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

			--Invoice Details Normalize

			IF OBJECT_ID('TEMPDB..#tmpInvdetails','U') IS NOT NULL
			   DROP TABLE #tmpInvdetails

			;with cteInv as
			(
			select @cAc_code AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,inv_qty ,
			        1 as Srno
			from #BUYERORDER
			where inv_qty>0
			union all
			select  AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,inv_qty ,
			        Srno=Srno+1 
			from cteInv   
	        WHERE SrNo<inv_qty
			)

			select  AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code ,inv_qty,
			       1 as Qty ,cast(0 as numeric(5,0)) as SrNo
			into #tmpInvdetails 
			from cteInv
			option (maxrecursion 32767);

		    ;with cte as
			(
			select *,sr= row_number() over(partition by AC_CODE ,Article_code ,para1_code ,para2_code ,para3_code 
			order by AC_CODE )from #tmpInvdetails
			)
			Update cte set srno =sr 


			

			IF EXISTS (SELECT TOP 1'U'   FROM #TMPINVDETAILS A
			LEFT JOIN #TMPORDDETAILS  B ON A.AC_CODE =B.AC_CODE AND A.ARTICLE_CODE =B.ARTICLE_CODE AND A.PARA1_CODE =B.PARA1_CODE 
			AND A.PARA2_CODE =B.PARA2_CODE AND A.PARA3_CODE =B.PARA3_CODE and a.srno=b.srno
			WHERE B.QTY IS NULL)
			BEGIN
			    SET @cErrormsg='Invoice quantity cannot be more that pending order qty..'

				select art.Article_no ,p1.para1_name ,p2.para2_name ,para3_name,
				       0 stock_qty,0 order_qty,0  [Allocate Stock],
				       sum(a.Qty) as inv_qty,@cErrormsg as errmsg,'' as memo_id
				FROM #TMPINVDETAILS A
		  	    LEFT JOIN #TMPORDDETAILS  B ON A.AC_CODE =B.AC_CODE AND A.ARTICLE_CODE =B.ARTICLE_CODE AND A.PARA1_CODE =B.PARA1_CODE 
			    AND A.PARA2_CODE =B.PARA2_CODE AND A.PARA3_CODE =B.PARA3_CODE and a.para3_code=b.para3_code and a.srno=b.srno
				join article art (nolock) on art.article_code =a.article_code 
				join para1 p1 (nolock) on p1.para1_code =a.para1_code
				join para2 p2 (nolock) on p2.para2_code =a.para2_code
				join para3 p3 (nolock) on p3.para3_code =a.para3_code
				WHERE B.QTY IS NULL
				group by art.article_no ,p1.para1_name ,p2.para2_name,para3_name
			   
			   
				SET @bOrderValidationFailed=1

				goto END_PROC

			END


			if not exists (select top 1 'ú' from SalesOrderProcessing (nolock) where MemoId =@CINVID and XnType ='OrderInvoice')
			begin

			   INSERT SalesOrderProcessing	(XnType,RefMemoId,MemoId, ArticleCode,  Para1Code, Para2Code, Para3Code, Qty )  
				select 'OrderInvoice' XnType,B.REFMEMOID  ,@cInvId MEMOID 
					   ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE ,
					   SUM(A.QTY) AS QTY 
				from #TMPINVDETAILS A
				join #tmporddetails b on a.article_code =b.Article_Code and a.para1_code =b.Para1_Code 
				and a.para2_code =b.Para2_Code and a.para3_code =b.Para3_Code and a.SrNo =b.SrNo and a.ac_code=b.AC_CODE
				group by B.REFMEMOID   ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE 


			end
			else
			begin
			          

				select 'OrderInvoice' XnType,B.REFMEMOID  ,@cInvId MEMOID 
					   ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE ,
					   SUM(A.QTY) AS QTY 
				into #tmpsalesorder
				from #TMPINVDETAILS A
				join #tmporddetails b on a.article_code =b.Article_Code and a.para1_code =b.Para1_Code 
				and a.para2_code =b.Para2_Code and a.para3_code =b.Para3_Code and a.SrNo =b.SrNo and a.ac_code=b.AC_CODE
				group by B.REFMEMOID   ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE 


				Update a set Qty =(CASE WHEN @NBOXUPDATEMODE=1 THEN A.Qty ELSE 0 END)+  b.Qty 
				from SalesOrderProcessing A (nolock)
				join #tmpsalesorder b on a.RefMemoId =b.RefMemoId and a.MemoId =b.MEMOID and a.ArticleCode =b.article_code 
				and a.para1code =b.Para1_Code 
				and a.para2code =b.Para2_Code and a.para3code =b.Para3_Code

				INSERT SalesOrderProcessing	(XnType,RefMemoId,MemoId, ArticleCode,  Para1Code, Para2Code, Para3Code, Qty )  
				select A.XnType,A.RefMemoId,A.MemoId, A.Article_Code,  A.Para1_Code, A.Para2_Code,A. Para3_Code, A.Qty
				from #tmpsalesorder A
				LEFT OUTER JOIN SalesOrderProcessing B (NOLOCK) ON a.RefMemoId =b.RefMemoId and a.MemoId =b.MEMOID and a.Article_Code =b.articlecode 
				and a.para1_code =b.Para1Code 
				and a.para2_code =b.Para2Code and a.para3_code =b.Para3Code
				WHERE B.MemoId IS NULL

			end

 
	END	

	
	IF @nEntrymode=1
	BEGIN
	
		SET @cStep='125.42'	

	     	Update a set  stock_qty=c.stock_qty FROM 
			#BUYERORDER a JOIN 
			(
			 SELECT a.article_Code,a.para1_code,a.para2_code,a.para3_code,
				   SUM(e.quantity_in_stock) stock_qty 
			  FROM pmt01106 e (NOLOCK) 
			  JOIN sku a (NOLOCK) ON e.product_code=a.product_code
			  join #BUYERORDER c on  a.article_Code=c.article_code and a.para1_code=c.para1_code and a.para2_code=c.para2_code
			  and a.para3_Code=c.para3_code
			  group by a.article_Code,a.para1_code,a.para2_code,a.para3_code
					 ) c on a.article_Code=c.article_code and a.para1_code=c.para1_code and a.para2_code=c.para2_code
					 and a.para3_Code=c.para3_code
					

		EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1

		UPDATE a SET pending_pl_qty=c.pending_pl_qty FROM 
					#BUYERORDER a JOIN 
		(
			select a.articleCode,a.para1code,a.para2code,a.para3code,
					SUM(CASE WHEN XNTYPE='PLPACKSLIP' THEN  QTY ELSE -qty END  ) as pending_pl_qty
			FROM SalesOrderProcessing A (nolock)
			join #BUYERORDER b on a.articleCode=b.article_code and a.para1code=b.para1_code and a.para2code=b.para2_code
			and a.para3Code=b.para3_code
			WHERE XNTYPE IN('plPackSlip','plInvoice','PLShortClose') 
			and Qty >0
			GROUP BY Articlecode ,para1code ,para2code ,para3Code
			having SUM(CASE WHEN XNTYPE='PLPACKSLIP' THEN  QTY ELSE -qty END  )>0
			) c on a.article_Code=c.articlecode and a.para1_code=c.para1code and a.para2_code=c.para2code
		 and a.para3_Code=c.para3code



		IF EXISTS (SELECT TOP 1 * FROM #BUYERORDER WHERE isnull(inv_qty,0)>(isnull(stock_qty,0)-isnull(pending_pl_qty,0)) AND isnull(pending_pl_qty,0)>0)
		BEGIN
			SET @cStep='125.47'
			EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
			SET @cErrormsg='Invoice quantity cannot be more that Pick List pending qty..'
			SET @cCmd=N'SELECT Article_no,para1_name,para2_name,para3_name,stock_qty,order_qty,pending_pl_qty [Allocate Stock],inv_qty,
						(inv_qty-(isnull(stock_qty,0)-isnull(pending_pl_qty,0))) variance,
						'''+@cErrormsg+''' errmsg,'''' memo_id FROM 
						#BUYERORDER WHERE isnull(inv_qty,0)>(isnull(stock_qty,0)-isnull(pending_pl_qty,0)) 
						AND isnull(pending_pl_qty,0)>0'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
			SET @bOrderValidationFailed=1
		END
	END
	
	GOTO END_PROC
END TRY

BEGIN CATCH
	
	SET @cErrormsg='Error in Procedure SP3S_VALIDATE_INV_PICKLIST_QTY_new at Step#'+@cStep+' '+error_message()
	print 'enter catch of SP3S_VALIDATE_INV_PICKLIST_QTY_new'+@cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:

END