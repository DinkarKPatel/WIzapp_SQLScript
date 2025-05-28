CREATE PROCEDURE SPWOW_VALIDATE_WPSQTY_SOP
@cMemoId VARCHAR(40)
AS
BEGIN
	
    INSERT xnsavelog	( sp_id, start_time, step, step_msg, xn_type )  
	SELECT 	  @@spid sp_id,getdate() start_time,'177' step,'VALIDATE_WPSQTY_SOP_new' step_msg,'wowwps' xn_type 

	--if @cMemoId='WC01124000WC-2609'
		select a.articlecode,a.para1code,a.para2code,a.para3Code, article_no,para1_name,para2_name,para3_name,a.qty,isnull(b.qty,0) sop_qty 
		into #tmpDiff 
		from
		(
			select c.article_code articlecode,c.para1_code para1Code,c.para2_code para2Code,c.para3_code para3Code, 
			sum(quantity) qty,count(distinct box_no) boxcnt 
			from wps_det a 
			join wps_mst b on a.ps_id=b.ps_id
			JOIN sku c (NOLOCK) ON c.product_code=a.product_code
			 where  a.ps_id=@cMemoId 
			 group by c.article_code ,c.para1_code,c.para2_code,c.para3_code
		) a
		 left join 
		(
			select articlecode,para1code,para2code,para3code,sum(qty) qty  
			from  SalesOrderProcessing (NOLOCK) 
	  		 where xntype='plpackslip' AND  memoid=@cMemoId
			 group by memoid,articlecode,para1code,para2code,para3code
		) b on a.articlecode=b.articlecode and a.para1code=b.para1code
	     and a.para2code=b.para2code  and a.para3code=b.para3code
		 JOIN article art (NOLOCK) ON art.article_code=a.articlecode
		 JOIN para1 p1 (NOLOCK) ON p1.para1_code=a.para1code
		 JOIN para2 p2 (NOLOCK) ON p2.para2_code=a.para2code
		 JOIN para3 p3 (NOLOCK) ON p3.para3_code=a.para3code
	     

	 if exists (select top 1 * from #tmpDiff where qty<>sop_qty)
		select * from #tmpDiff
	 else
	 begin
		DECLARE @cAcCode CHAR(10)

		SELECT TOP 1 @cAcCode=ac_code FROM wps_mst (NOLOCK) WHERE ps_id=@cMemoId

		select b.article_no,b.para1_name,b.para2_name,b.para3_name, a.ArticleCode,a.Para1Code,a.Para2Code,a.Para3Code,sum(case when xntype='picklist' then a.qty else -a.qty end) pendingqty
		from salesorderprocessing a 
		join #tmpDiff b on b.articleCode=a.ArticleCode and b.para1Code=a.Para1Code and b.para2Code=a.Para2Code and b.para3Code=a.Para3Code
		JOIN plm01106 plm (NOLOCK) ON plm.MEMO_ID=a.RefMemoId
		where plm.ac_code=@cAcCode AND xntype in ('picklist','plpackslip','plinvoice','plshortclose')
		group by b.article_no,b.para1_name,b.para2_name,b.para3_name,a.ArticleCode,a.Para1Code,a.Para2Code,a.Para3Code
		having sum(case when xntype='picklist' then a.qty else -a.qty end)<0
		
	 end

	--else
	--	select a.ps_id,a.qty,isnull(b.qty,0) sop_qty from
	--	(select ps_dt,a.ps_id,sum(quantity) qty from wps_det a join wps_mst b on a.ps_id=b.ps_id
	--	 where  a.ps_id=@cMemoId group by ps_dt,a.ps_id) a
	--	 left join 
	--	(select memoid,sum(qty) qty  from  SalesOrderProcessing (NOLOCK) where xntype='plpackslip' and memoid=@cMemoId
	--	group by memoid) b on a.ps_id=b.MemoId
	--	where 1=2

		
END
