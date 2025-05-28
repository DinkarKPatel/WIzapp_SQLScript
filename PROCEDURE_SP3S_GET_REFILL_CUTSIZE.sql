CREATE PROCEDURE SP3S_GET_REFILL_CUTSIZE
@nMode numeric(1,0),
@cTargetLocId VARCHAR(4)=''
AS
BEGIN
	DECLARE @cColList VARCHAR(max),@cRepCols VARCHAR(2000),@cRepColsIns VARCHAR(2000),@cJoinStr varchar(max),@cCmd NVARCHAR(MAX),
			@cFromDt VARCHAR(10),@cToDt VARCHAR(10),@cPmtTable VARCHAR(200),@cGitTable VARCHAR(200),@cHoLocId VARCHAR(4),
			@nDays NUMERIC(3,0),@cStep VARCHAR(10),@cErrormsg VARCHAR(MAX),@dFromDt DATETIME,@dToDt DATETIME,
			@cPeriodFromDt VARCHAR(10),@cPeriodToDt VARCHAR(10),@dToDay DATETIME,@cFilter VARCHAR(MAX),
			@nPeriodMode NUMERIC(1,0),@nPlanDays NUMERIC(4,0),@cBoJoinstr VARCHAR(max),@cRepBoMstCols VARCHAR(MAX),
			@cRepBoMstJoinStr VARCHAR(MAX),@nSrno NUMERIC(4,0),@nTopSrno NUMERIC(4,0),@cStkPickingWhere VARCHAR(20)

BEGIN TRY	

	--Need to maintain column plan_id or anyone else to distinguish entries made on the fly for maintaining size ratio
	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

	
	SET @cStep='10'
	SELECT * INTO #config_buyerorder from CONFIG_BUYERORDER  where isnull(open_key,0)=1

	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SET @cErrormsg=''
	
	SET @cFilter=(CASE WHEN ISNULL(@cFilter,'')='' THEN ' 1=1 ' ELSE @cFilter END)
	
	SET @cFilter=REPLACE(@cFilter,'article_no','sn.article_no')
	SET @cFilter=REPLACE(@cFilter,'para1_name','sn.para1_name')
	SET @cFilter=REPLACE(@cFilter,'para3_name','sn.para3_name')
	SET @cFilter=REPLACE(@cFilter,'para4_name','sn.para4_name')
	SET @cFilter=REPLACE(@cFilter,'para5_name','sn.para5_name')
	SET @cFilter=REPLACE(@cFilter,'para6_name','sn.para6_name')
	SET @cFilter=REPLACE(@cFilter,'sub_section_name','sn.sub_sect_name')
	SET @cFilter=REPLACE(@cFilter,'section_name','sn.section_name')
	SET @cFilter=REPLACE(@cFilter,'sn.sub_sect_name','sn.sub_section_name')
	SET @cFilter=REPLACE(@cFilter,'ac_name','sn.ac_name')


	SET @cToDt=CONVERT(VARCHAR,getdate(),112)

	IF @nPeriodMode=1
		SELECT @cFromDt=CONVERT(VARCHAR,@dFromDt,112)
	ELSE
		SELECT @cFromDt=CONVERT(VARCHAR,DATEADD(DD,-@nPlanDays,GETDATE()),112)
	
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
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 AND @nMode<>3 THEN  ' AND b.para2_name=c.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)

	SET @cStep='35'			
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
	
	IF @nMode=1
	BEGIN
		SET @cStep='37'			
		SET @cCmd=N'INSERT #aro_refill_plan (plan_id,'+@cRepColsIns+',physical_stock,excess_qty,row_id,cut_size)
					 SELECT '''','+replace(@cRepCols,'c.dept_id','a.dept_id') +',
					 sum(quantity_in_stock) as physical_stock,sum(quantity_in_stock) as excess_qty,CONVERT(VARCHAR(40),'''') as row_id,
					 0 cut_size
					 FROM '+@cPmtTable+' a (NOLOCK)
					 JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
					 JOIN location loc (NOLOCK) ON loc.dept_id=a.dept_id
					 JOIN sku (NOLOCK) ON sku.product_code=a.product_code
					 JOIN article art (NOLOCK) ON art.article_code=sku.article_code
					 WHERE  '+@cFilter+' and art.para2_set=1 
					 GROUP BY '+replace(replace(@cRepCols,'c.dept_id','a.dept_id'),'c.','sn.')

					 
		PRINT @cCmd	
		EXEC SP_EXECUTESQL @cCmd
		
		SET @cStep='37.5'			
		UPDATE #aro_refill_plan SET row_id=CONVERT(VARCHAR(40),NEWID())

		--- Shall retain this step later on		
		--IF EXISTS (SELECT TOP 1 row_id FROM #aro_refill_plan)
		--BEGIN
		--	SELECT DISTINCT dept_id,article_code,para1_code INTO #tmpBrokenSizeLoc FROM  #aro_refill_plan

		--	SET @cCmd=N'INSERT #aro_refill_plan ('+@cRepColsIns+',physical_stock,excess_qty,row_id)
		--				 SELECT '+replace(@cRepCols,'c.dept_id','a.dept_id') +',
		--				 0 as physical_stock,0 as excess_qty,CONVERT(VARCHAR(40),NEWID()) as row_id
		--				 FROM art_det a (NOLOCK)
		--				 JOIN article art (NOLOCK) ON art.article_code=sku.article_code
		--				 JOIN #tmpBrokenSizeLoc bl ON 1=1
		--				 LEFT JOIN #aro_refill_plan c ON c.article_code=a.article_code AND a.para1_code=b.para1_code AND a.para2_code=b.para2_code  
		--				 AND c.dept_id=bl.dept_id
		--				 WHERE  '+@cFilter+' and art.para2_set=1  AND c.article_code IS NULL
		--				 GROUP BY '+replace(replace(@cRepCols,'c.dept_id','a.dept_id'),'c.','sn.')
		--	PRINT @cCmd	
		--	EXEC SP_EXECUTESQL @cCmd
		--END

		SET @cStep='42'		
		PRINT 'Finding Cut size Articles'

		
		--if @@spid=74
		--	select 'check aro_refill_plan b4 cut size check',* from #aro_refill_plan  where article_no='T113'
		--	and dept_id='03'
		--	order by article_no,para1_name,para2_name
		
		
		---Color change
		UPDATE a SET cut_size=1,short_qty=1 FROM #aro_refill_plan a JOIN #aro_refill_plan b ON a.article_no=b.article_no AND 
		a.para1_name=b.para1_name AND a.dept_id=b.dept_id
		JOIN location loc (NOLOCK) ON loc.dept_id=a.dept_id
		WHERE b.physical_stock>0 AND a.physical_stock=0 AND  a.dept_id<>@cHoLocId AND loc.pur_loc=0

		--if @@spid=74
		--	select 'check aro_refill_plan after cut size check',* from #aro_refill_plan where para1_name is not null
		--	and cut_size=1 and dept_id='03' --and article_no='avk1685' 
		--	order by article_no,para1_name,para2_name

		--select 'check-1',* from #aro_refill_plan where dept_id='02' and physical_stock=0 
		--and  dept_id='02' and  article_no='MEN SHIRT' and para1_name like '%SKY%'
		--order by article_no -- article_no='MEN SHIRT' and para1_name='SKY BLUE'
		
		PRINT 'Deleting those articles for which Broken sizes are not there'
		SET @cStep='42.5'			
		---Color change
		DELETE a FROM #aro_refill_plan a LEFT JOIN #aro_refill_plan b ON a.article_no=b.article_no 
		AND a.para1_name=b.para1_name AND b.cut_size=1
		--JOIN #aro_refill_plan c ON a.article_no=b.article_no AND a.dept_id=b.dept_id
		WHERE  b.article_no IS NULL

		--select 'check-2',* from #aro_refill_plan  where dept_id='gn' and article_no='avk1685'
		PRINT 'Deleting those article sizes for which Broken sizes are not there'
		SET @cStep='45'			
		-----Color change
		--DELETE a FROM #aro_refill_plan a JOIN #aro_refill_plan b ON a.article_no=b.article_no AND a.dept_id=b.dept_id
		--AND a.para1_name=b.para1_name
		--WHERE ISNULL(b.cut_size,0)=1 AND ISNULL(a.cut_size,0)=0

		
		--select 'check-3',* from #aro_refill_plan  where dept_id='gn' and article_no='avk1685'
		

		SET @cStep='52'				
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		SET @cCmd=N'UPDATE c SET pending_wps_qty = b.pending_wps_qty 
					FROM #aro_refill_plan c
					JOIN (SELECT '+replace(@cRepColsIns,'dept_id','b.party_dept_id as dept_id') +',sum(quantity) as pending_wps_qty
					 FROM wps_det a (NOLOCK)
					 JOIN wps_mst b (NOLOCK) ON a.ps_id=b.ps_id
					 JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
					 JOIN location c (NOLOCK) ON c.dept_id=b.party_dept_id
					 WHERE ISNULL(b.wsl_inv_id,'''')='''' AND cancelled=0 AND '+@cFilter+' 
					 GROUP BY '+replace(@cRepColsIns,'dept_id','b.party_dept_id')+'
					 ) b on '+@cJoinStr

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
					 WHERE '+@cFilter+'  
					 GROUP BY '+replace(@cRepColsIns,'dept_id','a.dept_id')+'
					 ) b on '+@cJoinStr

		PRINT @cCmd	
		EXEC SP_EXECUTESQL @cCmd

		SET @nDays=DATEDIFF(dd,convert(date,@cFromDt),convert(date,@cToDt))

		IF @nDays<=0
			SET @nDays=1

	
		SET @cStep='56'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)	

		DECLARE @cFilter1 varchar(max)

		SET @cFilter1 = @cColList


		SET @cStep='58'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)	
		SELECT inv_mode,(CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')<>''
					 THEN WBO_FOR_DEPT_ID ELSE b.location_code END) AS source_dept_id,b.location_code target_dept_id,
		article_code,para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,sum(a.gross_quantity-isnull(a.inv_qty,0)) as pending_order_qty
		INTO #tmpOrders FROM buyer_order_det a (NOLOCK)
		JOIN buyer_order_mst b (NOLOCK) ON a.order_id=b.order_id
		JOIN location c (NOLOCK) ON c.dept_id=b.location_code
		WHERE cancelled=0 AND (a.quantity-ISNULL(a.inv_qty,0))>0 
		GROUP BY inv_mode,(CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')<>''
		THEN WBO_FOR_DEPT_ID ELSE b.location_code END), b.location_code,article_code,para1_code,para2_code,
		para3_code,para4_code,para5_code,para6_code
	
		SET @cStep='58.5'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)	
		SELECT inv_mode,source_dept_id,target_dept_id,article_no,para1_name,para2_name,
		para3_name,para4_name,para5_name,para6_name,
		SUM(pending_order_qty) pending_order_qty INTO #tmpPendingOrders FROM #tmpOrders  a
		JOIN article art (NOLOCK) ON art.article_code=a.article_code
		JOIN PARA1 p1 (NOLOCK) ON p1.para1_code=a.para1_code
		JOIN PARA2 p2 (NOLOCK) ON p2.para2_code=a.para2_code
		JOIN PARA3 p3 (NOLOCK) ON p3.para3_code=a.para3_code
		JOIN PARA4 p4 (NOLOCK) ON p4.para4_code=a.para4_code
		JOIN PARA5 p5 (NOLOCK) ON p5.para5_code=a.para5_code
		JOIN PARA6 p6 (NOLOCK) ON p6.para6_code=a.para6_code
		GROUP BY inv_mode,source_dept_id,target_dept_id,article_no,para1_name,para2_name,
		para3_name,para4_name,para5_name,para6_name
		
		--select * from #tmpPendingOrders
		SET @cStep='60'				
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

		SET @cStep='62'				
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


		--if @@spid=199
		--	select 'check short-2',dept_id,final_stock,article_no,para1_name,para2_name, physical_stock,
		--	pending_order_in_qty,pending_order_out_qty,git_qty,pending_wps_qty
		--	from #aro_refill_plan where  dept_id='h1' and article_no='MENS SHIRT V1' and para1_name='BLACK'

		SET @cStep='65'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		UPDATE #aro_refill_plan SET final_stock=ISNULL(physical_stock,0)+isnull(git_qty,0)+isnull(pending_wps_qty,0)+
		isnull(pending_order_in_qty,0)-isnull(pending_order_out_qty,0)
		

		--if @@spid=1189
		--	select 'check short-3',dept_id,final_stock,article_no,para1_name,para2_name, physical_stock,
		--	pending_order_in_qty,pending_order_out_qty,git_qty,pending_wps_qty
		--	from #aro_refill_plan where  dept_id='01' -- where cut_size=1 --and final_stock>=0
		--	and article_no='BAG001' and para1_name='BLACK'
		SET @cStep='67'

		--select 'check-4',* from #aro_refill_plan where cut_size=1
		
		--select 'check-4 before deleting ',* from #aro_refill_plan where  dept_id='02' and  article_no='MEN SHIRT' and para1_name like '%SKY%'

		DELETE FROM #aro_refill_plan where ISNULL(final_stock,0)>0 and ISNULL(cut_size,0)=1
		
		--MEN SHIRT	 SKY BLUE

		--if @@spid=74
		--	select 'check-5',* from #aro_refill_plan where dept_id='03'


		IF EXISTS (SELECT TOP 1 * FROM #aro_refill_plan WHERE cut_size=1)
		BEGIN
			SET @cStep='68.2'
			EXEC SP3S_GET_ARO_SIZERATIO_FOR_CUTSIZE
			@cRepColsIns=@cRepColsIns,
			@cRepCols=@cRepCols,
			@cRepBoMstJoinStr=@cRepBoMstJoinStr,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
		END
		--if @@spid=224
		--	select 'check short',dept_id,article_no,para1_name,para2_name, physical_stock,pending_order_in_qty,pending_order_out_qty,git_qty,pending_wps_qty
		--	from #aro_refill_plan where cut_size=1
		
		SET @cStep='69'
		SELECT a.DEPT_ID,DEPT_NAME,dept_alias,AREA_NAME,CITY,STATE,b.lead_days,SUM(short_qty) AS short_qty 
		FROM #aro_refill_plan a
		JOIN location b (NOLOCK) ON a.dept_id=b.dept_id
		JOIN area c (NOLOCK) ON c.area_code=b.area_code
		JOIN city d (NOLOCK) ON d.city_code=c.city_code
		JOIN state e (NOLOCK) ON e.state_code=d.state_code
		WHERE cut_size=1 

		GROUP BY a.DEPT_ID,DEPT_NAME,dept_alias,AREA_NAME,CITY,STATE,lead_days
		ORDER BY dept_id


		
		RETURN
	END

	IF @nMode=2
	BEGIN	
		SET @cStep='85'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		
		UPDATE a SET qtypicked=0,excess_qty=(CASE WHEN excess_qty>0 AND pur_loc=0 AND a.dept_id<>@cHoLocId THEN excess_qty-1
		ELSE excess_qty END) FROM #aro_refill_plan a
		JOIN location b ON a.dept_id=b.dept_id

		
		
		SELECT DISTINCT a.dept_id,(CASE WHEN a.dept_id=@cHoLocId THEN 1 WHEN pur_loc=1 THEN 2 ELSE 3 END) sno
		INTO #tmpSourceLocs FROM location a
		 LEFT JOIN AROLOCS_LINK b ON a.dept_id=b.FEEDING_DEPT_ID
		 WHERE a.dept_id<>@cTargetLocId AND (ISNULL(b.DEPT_ID,'')=@cTargetLocId OR ISNULL(a.primary_source_for_aro,0)=1)
		
		
		DECLARE @cExcessQtyLoc VARCHAR(4),@bFlag BIT
		SET @cStep='86.2'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		SELECT DISTINCT a.dept_id,CONVERT(NUMERIC(2,0),0) SRNO INTO #tmpExcessLoc FROM  #aro_refill_plan a 
		JOIN  #tmpSourceLocs b ON a.dept_id=b.dept_id
		JOIN location c ON c.dept_id=a.dept_id
		WHERE ISNULL(excess_qty,0)<>0

		SET @cStep='86.23'
		INSERT INTO #tmpExcessLoc (dept_id,srno)
		SELECT a.dept_id,0 FROM #tmpSourceLocs a
		LEFT JOIN #tmpExcessLoc b ON a.dept_id=b.dept_id
		WHERE b.SRNO IS NULL


		--if @@spid=1189
		--	select 'check ##tmpExcessLoc',* from #tmpExcessLoc

		SET @cStep='86.6'
		UPDATE a SET srno=(CASE WHEN ISNULL(primary_source_for_aro,0)=1 THEN 1 ELSE 2 END) FROM #tmpExcessLoc a 
		JOIN location b ON a.dept_id=b.dept_id
		
		SELECT @nTopSrno=MIN(srno) from #tmpExcessLoc
		


		WHILE EXISTS (SELECT TOP 1 * FROM #tmpExcessLoc)
		BEGIN
			SET @cStep='87.2'
				print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
			SELECT TOP 1 @cExcessQtyLoc=dept_id,@nSrno=srno FROM #tmpExcessLoc ORDER BY srno 
			
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
			AND ISNULL(b.excess_qty,0)<>0 '
			PRINT @cCmd		
			EXEC SP_EXECUTESQL @cCmd

			SET @cStep='88.2'
			DELETE FROM #tmpExcessLoc WHERE dept_id=@cExcessQtyLoc
		END
		
		---- Replace rest of Items with Buyer order qty picked up from  Primary Source for ARO
		---- If no stock found for any item from any Location
		IF EXISTS (SELECT TOP 1 DEPT_ID FROM #aro_refill_plan WHERE dept_id=@cTargetLocId AND ISNULL(qtypicked,0)<short_qty)
		BEGIN
			SELECT TOP 1 @cExcessQtyLoc=dept_id FROM location (NOLOCK) WHERE dept_id<>@cTargetLocId
			AND ISNULL(primary_source_for_aro,0)=1
			
			SET @cStep='89'
				print 'Running  missing Excess Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
			SET @cCmd=N'INSERT #aro_refill_plan (plan_id,'+@cRepColsIns+',physical_stock,excess_qty,row_id)
				 SELECT ''later'', '+REPLACE(replace(@cRepCols,'c.dept_id',''''+@cExcessQtyLoc+''''),'sn.','a.') +',
				 0 as physical_stock,(a.short_qty-ISNULL(a.qtypicked,0)) as excess_qty,'''' as row_id
				 FROM #aro_refill_plan a (NOLOCK)
				 left outer JOIN #aro_refill_plan d ON '+replace(replace(replace(@cJoinstr,'b.dept_id = c.dept_id','d.dept_id = '''+@cExcessQtyLoc+''''),'b.','D.'),'c.','a.')+'
				 WHERE  a.dept_id='''+@cTargetLocId+''' AND ISNULL(a.qtypicked,0)<a.short_qty AND d.article_no is null '

			PRINT ISNULL(@cCmd,'null aro ins')		
			EXEC SP_EXECUTESQL @cCmd

		END
	END --- @nMode=2 Ends here
	
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
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 AND @nMode<>3  THEN  ',a.para2_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',a.para3_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',a.para4_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',a.para5_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',a.para6_code ' ELSE '' END)
	
	DECLARE @cSourceLocsOrd VARCHAR(1000), @cSourceLocsStk VARCHAR(1000),@cSourceLocsCols VARCHAR(MAX)
	
	SET @cStep='97'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)

   IF @nMode=2
   BEGIN
		--select 'check refill',* FROM #aro_refill_plan a
		--			   WHERE ISNULL(excess_qty,0)<>0 AND a.dept_id<>@cTargetLocId
		SELECT @cSourceLocsCols=coalesce(@cSourceLocsCols+',','')+
		quotename(dept_id+'_stock')+' as '+quotename(dept_id+'_stock')+','+quotename(dept_id+'_order')+'  
		as '+quotename('Refill_from_'+dept_id)
		from #tmpSourceLocs A
		---- Cannot use order by here because on using that String just takes only one location

		SELECT @cSourceLocsOrd=coalesce(@cSourceLocsOrd+',','')+quotename(dept_id+'_order')+','+
		quotename(dept_id+'_stock') from 
		#tmpSourceLocs	 a
	
		--if @@spid=1189
		--	select 'check excess stock', * from #aro_refill_plan where excess_qty<>0
   END

	SET @cStep='99'
	--select @cColList cColList,@cColListCodes cColListCodes,@cNewJoinStr cNewJoinStr,@cSourceLocsCols
	DECLARE @cColListCaption1 VARCHAR(2000),@cColListCaption2 VARCHAR(2000)
	SELECT @cColListCaption1=NULL,@cColListCaption2=NULL

	SELECT @cColListCaption1 = coalesce(@cColListCaption1+',','')+'a.'+COLUMN_NAME+' as ['+ISNULL(DBO.fn_get_paracaption(COLUMN_NAME),column_name)+']'
	from #CONFIG_BUYERORDER WHERE (COLUMN_NAME<>'para2_name' OR @nMode<>3)

	SELECT @cColListCaption2 = coalesce(@cColListCaption2+',','')+'a.['+ISNULL(DBO.fn_get_paracaption(COLUMN_NAME),column_caption)+']'
	from #CONFIG_BUYERORDER

	DECLARE @cAddJoin VARCHAR(MAX),@cAddCols VARCHAR(MAX)

	SELECT @cAddJoin = ' JOIN article art (NOLOCK) ON art.article_no=a.article_no
						 JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
						 JOIN  sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
						 LEFT JOIN article_fix_attr af (NOLOCK) ON af.article_code=art.article_code '
	
	SET @cStep='101'
	SELECT @cAddJoin=@cAddJoin+
	' LEFT  JOIN  '+table_name+' ON '+table_name+'.'+replace(column_name,'_name','_code')+'=af.'+replace(column_name,'_name','_code')
	FROM config_attr WHERE table_caption<>''	
	
	SELECT @cAddCols=',section_name,sub_section_name'
	SELECT @cAddCols=@cAddCols+','+table_name+'.'+column_name+' as ['+table_caption+']'
	FROM config_attr WHERE table_caption<>''	

	--if @@spid=199
	--	select 'check FINAL',dept_id,article_no,para1_name,para2_name,qtypicked,short_qty, physical_stock,pending_order_in_qty,
	--	pending_order_out_qty,git_qty,pending_wps_qty,excess_qty
	--	from #aro_refill_plan where article_no='MENS SHIRT V1' and para1_name='BLACK' --and para2_name='26'
	
	--select 'check @cSourceLocsOrd', @cSourceLocsOrd ,@cAddJoin
	SET @cStep='102'
	print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	
	IF @nMode=2
	BEGIN
	
		SET @cStep='110'
		SET @cCmd=N'WITH cteORders as 
					(SELECT dept_id,'+@cColList+REPLACE(@cColListCodes1,'a.','')+',ISNULL(qtypicked,0) qtypicked,
					row_id,physical_stock,pending_order_in_qty,pending_order_out_qty,pending_wps_qty,git_qty,
					final_stock,short_qty,isnull(qtypicked,0) user_adj_qty,excess_qty,row_number() over 
					 (partition by dept_id,'+@cColList+',short_qty,excess_qty ORDER BY dept_id) as rno
					 FROM #aro_refill_plan a '+@cNewJoinStr+'
					)
				
					select a.dept_id,'+@cColListCaption1+@cAddCols+@cColListCodes2+',a.row_id,
					a.physical_stock,a.pending_order_in_qty,a.pending_order_out_qty,a.pending_wps_qty,a.git_qty,
					a.final_stock,a.short_qty,user_adj_qty,CONVERT(NUMERIC(10,2),0) adj_qty,a.qtypicked,
					a.excess_qty,a.short_qty Final_refill_qty,'+@cSourceLocsCols+' 

					 from 
					(SELECT * FROM cteOrders a 
					 WHERE rno=1 AND dept_id='''+@cTargetLocId+''' AND isnull(short_qty,0)>0
					)  a '+@cAddJoin+'

					LEFT JOIN 
					(SELECT * FROM  
					(
					SELECT '+REPLACE(@cColList,'a.','')+',(CASE WHEN col=''excess_qty'' THEN source_dept_id_ord ELSE
					source_dept_id_stk END) col,dept_id,value from
					(
					SELECT '''+@cTargetLocId+''' as dept_id,a.dept_id+''_order'' as source_dept_id_ord,
					a.dept_id+''_stock'' as source_dept_id_stk,'+
					@cColList+',isnull(excess_qty,0) as excess_qty ,ISNULL(final_stock,0) physical_stock
					FROM cteOrders a
					JOIN #tmpSourceLocs b ON a.dept_id=b.dept_id  WHERE  rno=1 
					) t
					unpivot
					(value for col in (excess_qty,physical_stock)
					) unpiv
					) a
					PIVOT
					(sum(value) for col in ('+@cSourceLocsOrd+')) as pvt_tble_1
					) b on '+REPLACE(@cJoinStr,'c.','a.')+
					'ORDER BY '+@cColList
	
		print isnull(@cCmd,'nullcmd')
		EXEC SP_EXECUTESQL @cCmd						

		SET @cStep='115'
		SET @cCmd=N'SELECT dept_id,p2.PARA2_NAME'+REPLACE(@cColListCodes1,'a.','')+',ISNULL(qtypicked,0) qtypicked,
					CONVERT(NUMERIC(10,2),0) adj_qty,	
					row_id FROM #aro_refill_plan a '+@cNewJoinStr
		print @cCmd
		EXEC SP_EXECUTESQL @cCmd						
	END

	ELSE
	IF @nMode=3 ---- Return Size Xtab Format requirement of VenusSr
	BEGIN
		SET @cStep='120'
		DECLARE @cPara2Names VARCHAR(MAX)
		select @cPara2Names=COALESCE(@cPara2Names+',','')+'['+para2_name+']' from  
		(select distinct para2_name from #aro_refill_plan where para2_name not in ('','\')) a

		SET @cStep='125'
		SET @cCmd=N'WITH cteORders as 
					(SELECT dept_id,'+@cColList+REPLACE(@cColListCodes1,'a.','')+',ISNULL(qtypicked,0) qtypicked,
					row_id,isnull(physical_stock,0) physical_stock ,ISNULL(pending_order_in_qty,0) pending_order_in_qty,
					ISNULL(pending_order_out_qty,0) pending_order_out_qty,ISNULL(pending_wps_qty,0) pending_wps_qty ,ISNULL(git_qty,0) git_qty ,     
					ISNULL(final_stock,0) final_stock,ISNULL(short_qty,0) short_qty ,isnull(qtypicked,0) user_adj_qty,
					ISNULL(excess_qty,0) suggested_refill,row_number() over 
					 (partition by dept_id,'+@cColList+',short_qty,excess_qty ORDER BY dept_id) as rno
					 FROM #aro_refill_plan a '+@cNewJoinStr+'
					)
				
					select a.dept_id,'+@cColListCaption1+@cAddCols+@cColListCodes2+',a.row_id,
					(CASE WHEN b.col=''physical_stock'' THEN 1 WHEN b.col=''pending_order_in_qty'' THEN 2 WHEN b.col=''pending_order_out_qty'' THEN 3
					  WHEN b.col=''pending_wps_qty'' THEN 4  WHEN b.col=''git_qty'' THEN 5 WHEN b.col=''final_stock'' THEN 6
					  WHEN b.col=''suggested_refill'' THEN 7 ELSE 8 END) col_order,b.*

					FROM 
					(SELECT * FROM cteOrders a 
					 WHERE rno=1 AND dept_id='''+@cTargetLocId+''' AND isnull(short_qty,0)>0
					)  a '+@cAddJoin+'

					LEFT JOIN 
					(SELECT * FROM  
					(
					SELECT '+REPLACE(@cColList,'a.','')+',col,dept_id,value from
					(
					SELECT '''+@cTargetLocId+''' as dept_id,'+
					@cColList+',physical_stock,pending_order_in_qty,
					pending_order_out_qty,pending_wps_qty,git_qty,final_stock,short_qty,user_adj_qty,suggested_refill
					FROM cteOrders a
					WHERE  rno=1 
					) t
					unpivot
					(value for col in ([physical_stock],[pending_order_in_qty],[pending_order_out_qty],[pending_wps_qty],[git_qty],
									   [final_stock],[user_adj_qty],[suggested_refill])
					) unpiv
					) a
					PIVOT
					(sum(value) for para2_name in ('+@cPara2Names+')) as pvt_tble_1
					) b on '+REPLACE(@cJoinStr,'c.','a.')+
					'ORDER BY '+REPLACE(@cColList,',a.para2_name','')+',col_order'
	

		print isnull(@cCmd,'nullcmd')
		EXEC SP_EXECUTESQL @cCmd						
		
	END

	--PRINT @cCmd
	GOto END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_REFILL_CUTSIZE at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

IF ISNULL(@cErrormsg,'')<>''
	SELECT @cErrormsg as errmsg
END
