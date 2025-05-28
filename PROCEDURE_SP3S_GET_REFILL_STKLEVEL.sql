CREATE PROCEDURE SP3S_GET_REFILL_STKLEVEL
@nMode numeric(1,0),
@cPlanId VARCHAR(40)
AS
BEGIN
	DECLARE @cColList VARCHAR(max),@cRepCols VARCHAR(2000),@cRepColsIns VARCHAR(2000),@cJoinStr varchar(max),@cCmd NVARCHAR(MAX),
			@cFromDt VARCHAR(10),@cToDt VARCHAR(10),@cPmtTable VARCHAR(200),@cGitTable VARCHAR(200),@cHoLocId varCHAR(4),
			@nDays NUMERIC(3,0),@cStep VARCHAR(10),@cErrormsg VARCHAR(MAX),@dFromDt DATETIME,@dToDt DATETIME,
			@cPeriodFromDt VARCHAR(10),@cPeriodToDt VARCHAR(10),@dToDay DATETIME,@cFilter VARCHAR(MAX),
			@nPeriodMode NUMERIC(1,0),@cBoJoinstr VARCHAR(max),@cRepBoMstCols VARCHAR(MAX),@cTargetLocId VARCHAR(4),
			@cRepBoMstJoinStr VARCHAR(MAX),@nSrno NUMERIC(4,0),@nTopSrno NUMERIC(4,0),@cStkPickingWhere VARCHAR(20)

BEGIN TRY	
	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

	
	SET @cStep='10'
	SELECT * INTO #config_buyerorder from CONFIG_BUYERORDER  where isnull(open_key,0)=1 
	ORDER BY sr_no

	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cErrormsg=''
	SELECT @dFromDt=applicable_from_dt,@dToDt = applicable_to_dt,@cFilter=filter,@cTargetLocId=target_dept_id
	FROM LOC_STOCK_LEVEL_MST (NOLOCK) WHERE memo_id=@cPlanId
	
	SET @cFilter=(CASE WHEN ISNULL(@cFilter,'')='' THEN ' 1=1 ' ELSE @cFilter END)
	
	SET @cFilter=REPLACE(@cFilter,'article_no','sn.article_no')
	SET @cFilter=REPLACE(@cFilter,'para1_name','sn.para1_name')
	SET @cFilter=REPLACE(@cFilter,'para2_name','sn.para2_name')
	SET @cFilter=REPLACE(@cFilter,'para3_name','sn.para3_name')
	SET @cFilter=REPLACE(@cFilter,'para4_name','sn.para4_name')
	SET @cFilter=REPLACE(@cFilter,'para5_name','sn.para5_name')
	SET @cFilter=REPLACE(@cFilter,'para6_name','sn.para6_name')
	SET @cFilter=REPLACE(@cFilter,'sub_section_name','sn.sub_sect_name')
	SET @cFilter=REPLACE(@cFilter,'section_name','sn.section_name')
	SET @cFilter=REPLACE(@cFilter,'sn.sub_sect_name','sn.sub_section_name')
	SET @cFilter=REPLACE(@cFilter,'ac_name','sn.ac_name')


	SET @cToDt=CONVERT(VARCHAR,getdate(),112)

	SELECT @cFromDt=CONVERT(VARCHAR,@dFromDt,112)
	
	SET @cStep='23'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	
	SELECT @cPmtTable='pmt01106',@cGitTable='#tmpGitDetails'
	
	IF @nMode=1
	BEGIN
		CREATE TABLE #tmpGitProcess (memo_id VARCHAR(50),quantity NUMERIC(10,2),memo_dt datetime,tat_days numeric(5,0))
		CREATE TABLE #tmpGitDetails (memo_id VARCHAR(50),product_code varchar(50),git_qty NUMERIC(10,2),
									 bin_id varchar(50),git_pp numeric(10,2),dept_id varchar(4),xn_party_code VARCHAR(50),
									 XN_NO VARCHAR(50),xn_dt DATETIME)
	
		EXEC SP3S_GET_PENDING_GITLOCS 
		@dXnDt=@cToDt,
		@bCalledFromARO=1

	END
		
	SET @cCollist=NULL
	
	SET @cJoinstr = ' b.dept_id = c.dept_id '
	

	SELECT @cCollist = coalesce(@cColList+',','')+'a.'+COLUMN_NAME from #CONFIG_BUYERORDER

	SET @cStep='30'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SELECT @cJoinstr=@cJoinstr+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ' AND b.article_no=c.article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' AND b.para1_name=c.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ' AND b.para2_name=c.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)

	SET @cStep='40'			
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SELECT @cRepCols='c.dept_id'+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ',sn.article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',sn.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ',sn.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',sn.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',sn.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',sn.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',sn.para6_name ' ELSE '' END)

	SELECT @cRepColsIns=REPLACE(REPLACE(@cRepCols,'sn.',''),'c.',''),
		   @cRepBoMstCols=	REPLACE(REPLACE(@cRepCols,'c.dept_id,',''),'sn.','c.'),
		   @cRepBoMstJoinStr=	REPLACE(@cJoinstr,' b.dept_id = c.dept_id ',' 1=1 ')
	
	SET @cCmd=N'UPDATE a SET physical_stock=isnull(b.stock_qty,0)
			FROM #aro_refill_plan a
			left OUTER JOIN 
			(SELECT '+replace(@cRepColsIns,'dept_id','c.dept_id') +',sum(quantity_in_stock) as stock_qty
				FROM '+@cPmtTable+' a (NOLOCK)
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
				JOIN location c (NOLOCK) ON c.dept_id=a.dept_id
				JOIN  LOC_STOCK_LEVEL_MST d ON d.target_dept_id=a.dept_id
				WHERE '+@cFilter+' and  d.memo_id='''+@cPlanId+''' AND quantity_in_stock>0
				GROUP BY '+replace(@cRepColsIns,'dept_id','c.dept_id')+'
				HAVING sum(quantity_in_stock)>0
				) b on '+replace(@cJoinStr,'c.','a.')

	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='54'				
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cCmd=N'UPDATE c SET git_qty = b.git_qty 
				FROM #aro_refill_plan c
				JOIN (SELECT '+replace(@cRepColsIns,'dept_id','a.dept_id') +',sum(git_qty) as git_qty
					FROM '+@cGitTable+' a
					JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
					JOIN location c (NOLOCK) ON c.dept_id=a.dept_id
					JOIN  LOC_STOCK_LEVEL_MST d ON d.target_dept_id=a.dept_id
					WHERE '+@cFilter+'  and  d.memo_id='''+@cPlanId+'''
					GROUP BY '+replace(@cRepColsIns,'dept_id','a.dept_id')+'
					) b on '+@cJoinStr

	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='54.5'				
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cCmd=N'UPDATE c SET pending_wps_qty = b.pending_wps_qty 
				FROM #aro_refill_plan c
				JOIN (SELECT '+replace(@cRepColsIns,'dept_id','b.party_dept_id as dept_id') +',sum(quantity) as pending_wps_qty
					FROM wps_det a (NOLOCK)
					JOIN wps_mst b (NOLOCK) ON a.ps_id=b.ps_id
					JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
					JOIN location c (NOLOCK) ON c.dept_id=b.party_dept_id
					JOIN  LOC_STOCK_LEVEL_MST d ON d.target_dept_id=a.dept_id
					WHERE '+@cFilter+'  and  
					ISNULL(b.wsl_inv_id,'''')='''' AND d.memo_id='''+@cPlanId+''' AND cancelled=0 AND '+@cFilter+' 
					GROUP BY '+replace(@cRepColsIns,'dept_id','b.party_dept_id')+'
					) b on '+@cJoinStr

	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='55.5'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)	
	SELECT inv_mode,(CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')<>''
					THEN WBO_FOR_DEPT_ID ELSE b.location_code END) AS source_dept_id,b.location_code target_dept_id,
	a.ArticleCode article_code,a.Para1Code para1_code,a.Para2Code para2_code,a.Para3Code para3_code,
	'' para4_code,'' para5_code,'' para6_code,
	 SUM(CASE WHEN A.XNTYPE='ORDER' THEN QTY ELSE -1*Qty END )  as pending_order_qty
	INTO #tmpOrders FROM SalesOrderProcessing A with (nolock)
	JOIN buyer_order_mst b (NOLOCK) ON a.RefMemoId=b.order_id
	JOIN location c (NOLOCK) ON c.dept_id=b.location_code
	JOIN  LOC_STOCK_LEVEL_MST d ON d.target_dept_id=b.location_code
	WHERE d.memo_id=@cPlanId AND cancelled=0 AND ISNULL(b.short_close,0)=0
	AND XNTYPE IN('ORDER','ORDERPICKLIST','ORDERPACKSLIP','ORDERINVOICE','orderShortClose','PLPACKSLIP')
	GROUP BY inv_mode,(CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')<>''
	THEN WBO_FOR_DEPT_ID ELSE b.location_code END),b.location_code,a.ArticleCode,a.Para1Code,a.Para2Code,a.Para3Code
	having SUM(CASE WHEN A.XNTYPE='ORDER' THEN QTY ELSE -1*Qty END )>0
	
	SET @cStep='55.8'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)	
	SELECT inv_mode,source_dept_id,target_dept_id,article_no,para1_name,para2_name,
	para3_name,'' para4_name,'' para5_name,'' para6_name,
	SUM(pending_order_qty) pending_order_qty INTO #tmpPendingOrders FROM #tmpOrders  a
	JOIN article art (NOLOCK) ON art.article_code=a.article_code
	JOIN PARA1 p1 (NOLOCK) ON p1.para1_code=a.para1_code
	JOIN PARA2 p2 (NOLOCK) ON p2.para2_code=a.para2_code
	JOIN PARA3 p3 (NOLOCK) ON p3.para3_code=a.para3_code
	GROUP BY inv_mode,source_dept_id,target_dept_id,article_no,para1_name,para2_name,para3_name
		
	--SELECT 'check orders', b.target_dept_id as dept_id,article_no ,para1_name ,para2_name ,
	--				sum(pending_order_qty) as pending_order_qty
	--				FROM #tmpPendingOrders b
	--				WHERE  ISNULL(inv_mode,0)=2 and article_no='ART-LOT5'
	--				GROUP BY b.target_dept_id,article_no ,para1_name ,para2_name 

	--select * from #tmpPendingOrders
	SET @cStep='56.2'				
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cCmd=N'UPDATE c SET pending_order_in_qty = b.pending_order_qty 
				FROM #aro_refill_plan c
				JOIN (SELECT '+replace(@cRepColsIns,'dept_id','b.target_dept_id as dept_id') +',
					sum(pending_order_qty) as pending_order_qty
					FROM #tmpPendingOrders b
					WHERE  ISNULL(inv_mode,0)=2
					GROUP BY '+replace(@cRepColsIns,'dept_id','b.target_dept_id')+'
					) b on '+@cJoinStr

	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='56.8'				
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cCmd=N'UPDATE c SET pending_order_out_qty = b.pending_order_qty 
				FROM #aro_refill_plan c
				JOIN (SELECT '+replace(@cRepColsIns,'dept_id','b.source_dept_id AS dept_id') +',
					sum(pending_order_qty) as pending_order_qty
					FROM #tmpPendingOrders b
					GROUP BY '+replace(@cRepColsIns,'dept_id','b.source_dept_id')+'
					) b on '+@cJoinStr

	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='57.2'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)	
	SET @cCmd=N'INSERT #aro_refill_plan (plan_id,'+@cRepColsIns+',physical_stock,excess_qty,row_id)
				SELECT '''' as plan_id,'+replace(@cRepCols,'c.dept_id','a.dept_id') +',
				sum(quantity_in_stock) as physical_stock,sum(quantity_in_stock) as excess_qty,'''' as row_id
				FROM '+@cPmtTable+' a (NOLOCK)
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
				JOIN location loc (NOLOCK) ON loc.dept_id=a.dept_id
				LEFT JOIN AROLOCS_LINK b (NOLOCK) ON b.feeding_dept_id=a.dept_id
				WHERE '+@cFilter+'  and (ISNULL(b.dept_id,'''')='''+@cTargetLocId+''' OR ISNULL(loc.primary_source_for_aro,0)=1)
				AND a.dept_id<>'''+@cTargetLocId+'''
				GROUP BY '+replace(replace(@cRepCols,'c.dept_id','a.dept_id'),'c.','sn.')+'
				HAVING sum(quantity_in_stock)<>0'
	PRINT @cCmd	
	EXEC SP_EXECUTESQL @cCmd



	DECLARE @cFilter1 varchar(max)

	SET @cFilter1 = @cColList
	SET @cStep='65'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	UPDATE #aro_refill_plan SET final_stock=ISNULL(physical_stock,0)+isnull(git_qty,0)+isnull(pending_wps_qty,0)+
											isnull(pending_order_in_qty,0)-isnull(pending_order_out_qty,0)
	WHERE plan_id=@cPlanId 

	SET @cStep='75'

	UPDATE #aro_refill_plan SET short_qty=target_plan_stock-final_stock
	WHERE plan_id=@cPlanId AND dept_id=@cTargetLocId
	AND (target_plan_stock-(target_plan_stock*ISNULL(stock_level_percentage,0)/100)-final_stock)>0
	
	UPDATE #aro_refill_plan SET qtypicked=0
		
	IF EXISTS (SELECT TOP 1 * FROM #aro_refill_plan a JOIN article b on a.article_no=b.article_no WHERE ISNULL(ARTICLE_PACK_SIZE,0)>1)
	BEGIN
		UPDATE a SET short_qty=short_qty+(CASE WHEN (short_qty%ARTICLE_PACK_SIZE)>=article_pack_size/2 THEN ARTICLE_PACK_SIZE-(short_qty%ARTICLE_PACK_SIZE) else 
		(short_qty%ARTICLE_PACK_SIZE)*-1 END) FROM #aro_refill_plan a JOIN article b on a.article_no=b.article_no
		WHERE ISNULL(ARTICLE_PACK_SIZE,0)>1 and short_qty>0
	END

	SELECT DISTINCT  a.dept_id,(CASE WHEN a.dept_id=@cHoLocId THEN 1 WHEN pur_loc=1 THEN 2 ELSE 3 END) sno
	INTO #tmpSourceLocs FROM location a
	LEFT JOIN AROLOCS_LINK b ON a.dept_id=b.FEEDING_DEPT_ID
	WHERE a.dept_id<>@cTargetLocId AND (ISNULL(b.DEPT_ID,'')=@cTargetLocId OR ISNULL(a.primary_source_for_aro,0)=1)
	
	IF NOT EXISTS (SELECT TOP 1 dept_id FROM #tmpSourceLocs)
	begin
		set @cErrormsg='No location other than Target Location marked as Primary Source for ARO...Please Check'
		GOTO END_PROC
	end
		
	DECLARE @cExcessQtyLoc VARCHAR(4),@bFlag BIT
	SET @cStep='86.2'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)

	SELECT DISTINCT a.dept_id,CONVERT(NUMERIC(2,0),0) SRNO INTO #tmpExcessLoc FROM  #aro_refill_plan a 
	JOIN  #tmpSourceLocs b ON a.dept_id=b.dept_id
	JOIN location c ON c.dept_id=a.dept_id

	--select 'check #tmpExcessLoc', * from #tmpExcessLoc
	SET @cStep='86.6'
	UPDATE a SET srno=(CASE WHEN ISNULL(primary_source_for_aro,0)=1 THEN 1 ELSE 2 END) FROM #tmpExcessLoc a 
	JOIN location b ON a.dept_id=b.dept_id
		
	SELECT @nTopSrno=MIN(srno) from #tmpExcessLoc
		
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpExcessLoc)
	BEGIN
		SET @cStep='87.2'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		SELECT TOP 1 @cExcessQtyLoc=dept_id,@nSrno=srno FROM #tmpExcessLoc ORDER BY srno DESC
			
		---- Just pick the Pending Refill qty If Stock picking location is Primary Source of ARO
		SET @cStkPickingWhere=(CASE WHEN @nTopSrno=@nSrno THEN ' OR 1=1' ELSE '' END)
			
		SET @cCmd=N'UPDATE c SET excess_qty=(CASE WHEN c.excess_qty+ISNULL(b.qtypicked,0)>b.short_qty '+@cStkPickingWhere+' 
		THEN b.short_qty-ISNULL(b.qtypicked,0) ELSE c.excess_qty END)
		FROM #aro_refill_plan c
		JOIN #aro_refill_plan b ON '+@cRepBoMstJoinStr+'
		WHERE c.dept_id='''+@cExcessQtyLoc+''' AND b.dept_id='''+@cTargetLocId+'''
		AND (ISNULL(c.excess_qty,0)<>0 '+@cStkPickingWhere+') AND ISNULL(b.short_qty,0)<>0'
		PRINT @cCmd		
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='87.7'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		SET @cCmd=N'UPDATE c SET qtypicked=c.qtypicked+b.excess_qty
		FROM #aro_refill_plan c
		JOIN #aro_refill_plan b ON '+@cRepBoMstJoinStr+'
		WHERE b.dept_id='''+@cExcessQtyLoc+''' AND c.dept_id='''+@cTargetLocId+'''
		AND ISNULL(b.excess_qty,0)<>0 AND c.short_qty<>0'
		PRINT @cCmd		
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='88.2'
		DELETE FROM #tmpExcessLoc WHERE dept_id=@cExcessQtyLoc
	END
	
	DECLARE @cNewJoinStr VARCHAR(MAX)
	SET @cStep='95'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SELECT @cNewJoinStr=
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 OR charindex('ARTICLE_Name',@cColList)>0 THEN  ' JOIN article art (NOLOCK) ON art.article_no=a.article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' JOIN para1 p1 ON p1.para1_name=a.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ' JOIN para2 p2 ON p2.para2_name=a.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' JOIN para3 p3 ON p3.para3_name=a.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' JOIN para4 p4 ON p4.para4_name=a.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' JOIN para5 p5 ON p5.para5_name=a.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' JOIN para6 p6 ON p6.para6_name=a.para6_name ' ELSE '' END)

	DECLARE @cColListCodes1 VARCHAR(MAX),@cColListCodes2 VARCHAR(MAX)
	
	SELECT @cColListCodes1=
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 OR charindex('article_name',@cColList)>0
					 THEN  ',a.article_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',p1.para1_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ',p2.para2_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',p3.para3_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',p4.para4_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',p5.para5_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',p6.para6_code ' ELSE '' END),
		@cColListCodes2= (CASE WHEN charindex('ARTICLE_NO',@cColList)>0 OR charindex('article_name',@cColList)>0
					 THEN  ',a.article_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',a.para1_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ',a.para2_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',a.para3_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',a.para4_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',a.para5_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',a.para6_code ' ELSE '' END)
	
	DECLARE @cSourceLocsOrd VARCHAR(1000), @cSourceLocsStk VARCHAR(1000),@cSourceLocsCols VARCHAR(MAX)
	
	SET @cStep='97'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	 
	--select 'check refill',* FROM #aro_refill_plan a
	--			   WHERE ISNULL(excess_qty,0)<>0 AND a.dept_id<>@cTargetLocId
	SELECT @cSourceLocsCols=coalesce(@cSourceLocsCols+',','')+
	quotename(dept_id+'_stock')+' as '+quotename(dept_id+'_stock')+',
	(CASE WHEN a.short_qty<>0 THEN '+quotename(dept_id+'_order')+' ELSE 0 END) 
	as '+quotename('Refill_from_'+dept_id)
	from #tmpSourceLocs A
	---- Cannot use order by here because on using that String just takes only one location

	SELECT @cSourceLocsOrd=coalesce(@cSourceLocsOrd+',','')+quotename(dept_id+'_order')+','+
	quotename(dept_id+'_stock') from 
	#tmpSourceLocs	 a
	
	--if @@spid=204
	--	select 'check excess stock', * from #aro_refill_plan where excess_qty<>0

	SET @cStep='99'
	--select @cColList cColList,@cColListCodes cColListCodes,@cNewJoinStr cNewJoinStr,@cSourceLocsCols
	DECLARE @cColListCaption1 VARCHAR(2000),@cColListCaption2 VARCHAR(2000)
	SELECT @cColListCaption1=NULL,@cColListCaption2=NULL

	SELECT @cColListCaption1 = coalesce(@cColListCaption1+',','')+'a.'+COLUMN_NAME+' as ['+ISNULL(DBO.fn_get_paracaption(COLUMN_NAME),column_name)+']'
	from #CONFIG_BUYERORDER

	SELECT @cColListCaption2 = coalesce(@cColListCaption2+',','')+'a.['+ISNULL(DBO.fn_get_paracaption(COLUMN_NAME),column_caption)+']'
	from #CONFIG_BUYERORDER

	DECLARE @cAddJoin VARCHAR(MAX),@cAddCols VARCHAR(MAX)

	SELECT @cAddJoin = ' JOIN article art (NOLOCK) ON art.article_no=a.article_no
						 JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
						 JOIN  sectionm sm (NOLOCK) ON sm.section_code=sd.section_code'
	
	SET @cStep='101'
	--SELECT @cAddJoin=@cAddJoin+
	--' LEFT  JOIN  '+table_name+' ON '+table_name+'.'+replace(column_name,'_name','_code')+'=af.'+replace(column_name,'_name','_code')
	--FROM config_attr WHERE table_caption<>''	
	
	SELECT @cAddCols=',section_name,sub_section_name'
	--SELECT @cAddCols=@cAddCols+','+table_name+'.'+column_name+' as ['+table_caption+']'
	--FROM config_attr WHERE table_caption<>''	

	---Removed this check for now as per Ticket of Amartex and discussion between Pankaj and Sir (Date :31-10-2022 , Ticket#09-2571)
	--IF NOT EXISTS (SELECT TOP 1 DEPT_ID FROM #aro_refill_plan WHERE isnull(short_qty,0)>0)
	--BEGIN
	--	SET @cErrormsg='No shortage exists for selected Plan...'
	--	GOTO END_PROC
	--END

	SET @cStep='102'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cCmd=N'WITH cteORders as 
				(SELECT DISTINCT dept_id,'+@cColList+REPLACE(@cColListCodes1,'a.','')+',ISNULL(qtypicked,0) qtypicked,
				row_id,target_plan_stock,physical_stock,git_qty,stock_level_percentage,
				ISNULL(pending_order_in_qty,0) pending_order_in_qty,
					ISNULL(pending_order_out_qty,0) pending_order_out_qty,ISNULL(pending_wps_qty,0) pending_wps_qty,
				final_stock,short_qty,CONVERT(NUMERIC(10,2),0) user_refill_qty,excess_qty,row_number() over 
				 (partition by dept_id,'+@cColList+',short_qty,excess_qty ORDER BY dept_id) as rno
				 FROM #aro_refill_plan a '+@cNewJoinStr+'
				)
				
				select a.dept_id,'+@cColListCaption1+@cAddCols+@cColListCodes2+',a.row_id,
				a.physical_stock,a.git_qty,pending_order_in_qty,pending_order_out_qty,pending_wps_qty,	a.final_stock,a.target_plan_stock,stock_level_percentage,a.short_qty,user_refill_qty User_Adj_Qty,
				CONVERT(NUMERIC(10,2),0) adj_qty,qtypicked,a.excess_qty,a.short_qty Final_refill_qty,'+
				@cSourceLocsCols+' 
				 from 
				(SELECT * FROM cteOrders a 
				 WHERE rno=1 AND dept_id='''+@cTargetLocId+''' --AND isnull(short_qty,0)>0 (Commented for now agst Ticket#09-2571)
				)  a '+@cAddJoin+'

				LEFT JOIN 
				(SELECT * FROM  
				(
				SELECT '+REPLACE(@cColList,'a.','')+',(CASE WHEN col=''excess_qty'' THEN source_dept_id_ord ELSE
				source_dept_id_stk END) col,dept_id,value from
				(
				SELECT '''+@cTargetLocId+''' as dept_id,a.dept_id+''_order'' as source_dept_id_ord,
				a.dept_id+''_stock'' as source_dept_id_stk,'+
				@cColList+',isnull(excess_qty,0) as excess_qty ,ISNULL(physical_stock,0) physical_stock
				FROM cteOrders a
				JOIN #tmpSourceLocs b ON a.dept_id=b.dept_id  WHERE  rno=1 
				) t
				unpivot
				(value for col in (EXCESS_QTY,physical_stock)
				) unpiv
				) a
				PIVOT
				(sum(value) for col in ('+@cSourceLocsOrd+')) as pvt_tble_1
				) b on '+REPLACE(@cJoinStr,'c.','a.')+
				'ORDER BY '+@cColList
	
	print isnull(@cCmd,'nullcmd')
	EXEC SP_EXECUTESQL @cCmd						

	SET @cStep='105'
	SET @cCmd=N'SELECT dept_id'+(CASE WHEN CHARINDEX('para2_name',@cColList)>0 THEN ',P2.para2_name' ELSE '' end)+
				REPLACE(@cColListCodes1,'a.','')+',ISNULL(qtypicked,0) qtypicked,
				CONVERT(NUMERIC(10,2),0) adj_qty,	
				row_id FROM #aro_refill_plan a '+@cNewJoinStr
	print @cCmd
	EXEC SP_EXECUTESQL @cCmd						

	GOto END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_REFILL_stklevel at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

IF ISNULL(@cErrormsg,'')<>''
	SELECT @cErrormsg as errmsg
END