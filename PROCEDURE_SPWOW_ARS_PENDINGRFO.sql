CREATE PROCEDURE SPWOW_ARS_PENDINGRFO
@cSeasonId VARCHAR(10)='',
@cArsMemoId VARCHAR(40)='',
@cFilterLocs VARCHAR(2000)='',
@cFilterItems VARCHAR(max)='',
@cAroSourceLocId VARCHAR(4)='',
@bGeneratePickList BIT=0,
@cErrormsg  VARCHAR(MAX) OUTPUT
AS
BEGIN


	DECLARE @cCmd NVARCHAR(MAX),@cToDt VARCHAR(10),@cExtraMasterCols VARCHAR(200),@cJoinExtraCols VARCHAR(200),@cStep VARCHAR(10),
	@cText varchar(500),@cHoLocId VARCHAR(5)

	SET @cErrormsg=''

BEGIN TRY
	
	SET @cStep='10'
	CREATE TABLE #tmplocs (locId CHAR(2),memoId VARCHAR(50),seasonId VARCHAR(10),period_from DATETIME,whLoc BIT)

	declare @NSPID varchar(40)=newid()
	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'


	SET @cFilterLocs=replace(@cFilterLocs,'deptid','dept_id')
	SET @cFilterLocs=replace(@cFilterLocs,'deptname','dept_name')

	set @cText = 'ArsId:'+@cArsMemoId+':FilterLocs:'+@cFilterLocs+':FilterItems:'+@cFilterItems

	EXEC SP_CHKXNSAVELOG 'ARS_RFO',@cStep,0,@NSPID,@cText,0

	if @cFilterLocs='' AND @cArsMemoId<>''
		set @cFilterLocs='am.memoId='''+@cArsMemoId+''''

	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	SET @cCmd=N'select am.memoId, am.seasonId, am.locid,period_from,0 whloc  from wowArsMst am (NOLOCK)
				JOIN wowArsLocSetupWeekdays wa (nolock) on wa.locid=am.locid 
				JOIN season_mst s (nolock) on s.season_id=am.seasonid
				JOIN location loc (NOLOCK) ON loc.dept_id=am.locId 
				JOIN area (NOLOCK) ON area.area_code=loc.area_code
				JOIN city (NOLOCK) ON city.city_code=area.city_code
				JOIN state (NOLOCK) ON state.state_code=city.state_code
				LEFT JOIN mstposcategory cat (NOLOCK) ON cat.categorycode=loc.categorycode
				where '+@cFilterLocs

	PRINT @cCmd
	INSERT INTO #tmplocs (memoId,seasonId,locId,period_from,whloc)					
	EXEC SP_EXECUTESQL @cCmd


	INSERT INTO #tmpLocs (memoId,seasonId,locId,period_from,whLoc)	
	SELECT '' memoId,'' seasonId,dept_id locId,'' period_from,isnull(primary_source_for_aro,0) whLoc
	FROM location a (NOLOCK) LEFT JOIN #tmplocs b ON a.dept_id=b.locId
	WHERE b.locId IS NULL and primary_source_for_aro=1 

	SET @cStep='20'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	SELECT DISTINCT article_no,art.article_code
	INTO #tmpArticles FROM wowArsdet a (NOLOCK)
	JOIN #tmpLocs loc ON loc.memoId=a.memoId JOIN article art (NOLOCK) ON art.article_code=a.articleCode

	create index ind_article_no on #tmpArticles (article_no)

	CREATE TABLE #tmpSlsStockData (locId CHAR(2),articleNo VARCHAR(200),colour VARCHAR(100),size VARCHAR(100),slsQty NUMERIC(10,2),stockQty NUMERIC(10,2))

	CREATE TABLE #tmpWhStockData (articleNo VARCHAR(200),colour VARCHAR(100),size VARCHAR(100),stockQty NUMERIC(10,2),adjStockQty NUMERIC(10,2))

	SET @cStep='30'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	SET @cToDt=CONVERT(VARCHAR,GETDATE(),110)

	SET @cFilterItems=REPLACE(@cFilterItems,'sku_names.','sn.')

	--if @@spid=191
	--begin
	--	select 'check #tmplocs',* from #tmplocs
	--	select 'check #tmpArticles',* from #tmpArticles
	--end

	SET @cCmd=N'SELECT locId,articleNo,colour,size,SUM(slsQty) slsQty,SUM(stockQty) stockQty FROM  
	(SELECT loc.locId,sn.article_no articleNo,sn.para1_name colour,sn.para2_name size,sum(quantity) slsQty,CONVERT(NUMERIC(14,2),0) stockQty
	FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id  join #tmplocs loc on loc.locid=  B.location_code/*left(b.cm_id,2)*//*Rohit 05-11-2024*/
	JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
	JOIN #tmpArticles art ON art.article_no=sn.article_no  WHERE whLoc=0 AND  b.cm_dt BETWEEN period_from AND '''+@cToDt+''''+@cFilterItems+
	' AND b.cancelled=0 GROUP BY loc.locId,sn.article_no,sn.para1_name,sn.para2_name
	UNION ALL 
	SELECT dept_id locId,sn.article_no articleNo,sn.para1_name para1Name,sn.para2_name,0 slsQty,sum(quantity_in_stock) stockQty  FROM pmt01106 pmt
	(NOLOCK) JOIN  #tmplocs loc on loc.locid=pmt.DEPT_ID JOIN sku_names sn (NOLOCK) ON sn.product_code=pmt.product_code 
	JOIN #tmpArticles art ON art.article_no=sn.article_no WHERE whLoc=0 '+@cFilterItems+' AND quantity_in_stock>0 
	GROUP BY dept_id,sn.article_no,sn.para1_name,sn.para2_name) a  GROUP BY locId,articleNo,colour,size'

	PRINT @cCmd

	INSERT INTO #tmpSlsStockData (locId ,articleNo ,colour ,size ,slsQty ,stockQty)
	EXEC SP_EXECUTESQL @cCmd

	--if @@spid=329
	--begin
	--	select 'check #tmpSlsStockData',* from #tmpSlsStockData
	--end


	IF @cArsMemoId<>'' AND @bGeneratePickList=1
	BEGIN
		
		SET @cStep='35'
		SET @cCmd=N'SELECT sn.article_no articleNo,sn.para1_name para1Name,sn.para2_name,sum(quantity_in_stock) stockQty  FROM pmt01106 pmt
		(NOLOCK) JOIN  #tmplocs loc on loc.locid=pmt.DEPT_ID JOIN sku_names sn (NOLOCK) ON sn.product_code=pmt.product_code 
		JOIN #tmpArticles art ON art.article_no=sn.article_no WHERE dept_id='''+@cAroSourceLocId+''''+@cFilterItems+' AND quantity_in_stock>0 
		GROUP BY sn.article_no,sn.para1_name,sn.para2_name'

		PRINT @cCmd

		INSERT INTO #tmpWhStockData (articleNo ,colour ,size ,stockQty)
		EXEC SP_EXECUTESQL @cCmd

		
	--if @@spid=329
	--begin
	--	select 'check b4 #tmpWhStockData',* from #tmpWhStockData
	--end


		SELECT  article_No articleNo,para1_name para1Name,para2_name para2Name,SUM(CASE WHEN xntype='pickList' THEN Qty ELSE -Qty END) AS pendingQty
        INTO #tmpPendingPickList FROM salesOrderProcessing a (NOLOCK)
		JOIN #tmpArticles b ON b.article_code=a.ArticleCode
		JOIN para1 p1 (NOLOCK) ON p1.para1_code=a.Para1Code
		JOIN para2 p2 (NOLOCK) ON p2.para2_code=a.Para2Code
		JOIN plm01106 plm (NOLOCK) ON plm.MEMO_ID=a.RefMemoId
		JOIN buyer_order_mst bo (NOLOCK) ON bo.order_id=plm.order_id
        WHERE bo.WBO_FOR_DEPT_ID=@cAroSourceLocId AND xntype IN ('pickList','plPackSlip','plInvoice','PlShortClose')
        GROUP BY article_No,para1_Name,para2_Name
        HAVING SUM(CASE WHEN xntype='pickList' THEN Qty ELSE -Qty END)>0

		UPDATE a SET stockQty=stockQty-b.pendingQty FROM #tmpWhStockData a 
		JOIN #tmpPendingPickList b ON b.articleNo=a.articleNo AND a.colour=b.para1Name AND a.size=b.para2Name

			
	--if @@spid=329
	--begin
	--	select 'check after updating picklist #tmpWhStockData',* from #tmpWhStockData
	--end

	END

	SET @cStep='40'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	SELECT @cExtraMasterCols=''''' sectionName,'''' subSectionName,',@cJoinExtraCols=''

	
	if @cArsMemoId<>''
		SELECT @cExtraMasterCols='section_name sectionName,sub_section_name subSectionName,'

	SET @cJoinExtraCols='JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code' +
                    ' JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code'
	
	
	SELECT b.memoId,section_name sectionName,sub_section_name subSectionName, size_set_name sizeSetName, b.locId,dept_name locName,city,state,CategoryCode locCategory,
	art.article_no articleNo,p1.para1_name colour,
    p2.para2_name size,p2.para2_order para2Order,reorderLevel,maxStockLevel,plannedQty,maxStockPct, convert(numeric(7,2),0) daysOfStock,
    convert(numeric(10,2),0) slsQty,convert(numeric(10,2),0) gitQty,convert(numeric(10,2),0) stockQty,
    convert(numeric(10,2),0) suggestedRefillQty,convert(numeric(7,2),0) sellThru,convert(numeric(10,2),0) ordersInHand,
    convert(numeric(10,2),0) userRefillQty,CONVERT(numeric(10,2),0) whStockQty,convert(varchar(10),'') article_code,
	convert(varchar(10),'') para1_code INTO  #tmpArsData FROM wowArsDet a 
	JOIN wowArsMst b (NOLOCK) ON a.memoId=b.memoId 
	JOIN article art (NOLOCK) ON art.article_Code=a.articleCode
	JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
	JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
	join location loc(NOLOCK) ON loc.dept_id=b.locId
	JOIN area (NOLOCK) ON area.area_code=loc.area_code
	JOIN city (NOLOCK) ON city.CITY_CODE=area.city_code
	JOIN state (NOLOCK) ON state.state_code=city.state_code
	LEFT JOIN size_set_mst sz (NOLOCK) ON sz.size_set_code=art.size_set_code
	JOIN para1 p1 (NOLOCK) ON p1.para1_code=a.para1Code JOIN para2 p2(NOLOCK) ON p2.para2_code=a.para2Code
	WHERE 1=2

	SET @cStep='50'
	SET @cFilterItems=REPLACE(@cFilterItems,'sn.','')
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	SET @cCmd=N'SELECT b.memoId,' + @cExtraMasterCols + 'ISNULL(size_set_name,'''') sizeSetName, b.locId,dept_name locName,city,state,CategoryCode locCategory,'+
					' art.article_no articleNo,p1.para1_name colour,' +
                    ' p2.para2_name size,isnull(p2.para2_order,0) para2Order,reorderLevel,maxStockLevel,plannedQty,maxStockPct, 0 daysOfStock,' +
                    ' 0 slsQty,0 gitQty,0 stockQty,0 suggestedRefillQty,0 sellThru,0 ordersInHand,' +
                    ' 0 userRefillQty FROM wowArsDet a (NOLOCK) ' +
                    ' JOIN wowArsMst b (NOLOCK) ON a.memoId=b.memoId JOIN  #tmplocs l on l.locid=b.locId AND b.seasonId=l.seasonId' +
                    ' JOIN article art (NOLOCK) ON art.article_Code=a.articleCode' +
					' LEFT JOIN size_set_mst sz (NOLOCK) ON sz.size_set_code=isnull(art.size_set_code,'''') ' + @cJoinExtraCols +
                    ' JOIN para1 p1 (NOLOCK) ON p1.para1_code=a.para1Code JOIN para2 p2(NOLOCK) ON p2.para2_code=a.para2Code' +
                    ' JOIN location loc(NOLOCK) ON loc.dept_id=b.locId JOIN area (NOLOCK) ON area.area_code=loc.area_code' +
                    ' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code' +
                    ' WHERE 1=1 ' + @cFilterItems + ' ORDER BY b.locId'
	
	PRINT @cCmd
	INSERT INTO #tmpArsData (memoId,sectionName,subSectionName, sizeSetName, locId,locName,city,state,locCategory,articleNo,colour,size,para2Order,reorderLevel,maxStockLevel,plannedQty,
	maxStockPct,daysOfStock,slsQty,gitQty,stockQty,suggestedRefillQty,sellThru,ordersInHand,userRefillQty)
	EXEC SP_EXECUTESQL @cCmd


	SET @cStep='60'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	DECLARE @cGitCutoffDate VARCHAR(10) 

	SELECT @cGitCutoffDate=value FROM config(NOLOCK) WHERE config_option='GIT_CUT_OFF_DATE'
	SET @cGitCutoffDate=ISNULL(@cGitCutoffDate,'')

	SELECT a.inv_id,convert(varchar(50),'') rm_id,a.party_dept_id dept_id
	into #tmpGitProcess 
	FROM inm01106 a (NOLOCK) 
	JOIN #tmpLocs loc on loc.locId=a.party_dept_id
	LEFT OUTER JOIN pim01106 b (NOLOCK) ON a.inv_id=b.inv_id  AND b.cancelled=0  AND b.receipt_dt<>''
	WHERE  a.cancelled=0 AND a.inv_dt > @cGitCutoffDate  AND a.inv_mode=2 AND b.mrr_id IS NULL

	SET @cStep='70'
    PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	INSERT #tmpGitProcess (rm_id,dept_id,inv_id)
	SELECT a.rm_id,a.party_dept_id,'' inv_id
	FROM rmm01106 a (NOLOCK) 
	JOIN #tmpLocs loc on loc.locId=a.party_dept_id
	LEFT OUTER JOIN cnm01106 b (NOLOCK) ON a.rm_id=b.rm_id AND b.cancelled=0 AND  b.receipt_dt<>''
	JOIN location c (NOLOCK) ON c.dept_id=a.party_dept_id
	WHERE a.cancelled=0 AND  a.rm_dt > @cGitCutoffDate AND a.mode=2 AND b.rm_id IS NULL
	
	SET @cStep='75'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	select article_no articleNo,para1_name colour,para2_name size,b.dept_id locId,sum(quantity) gitQty 
	into #tmpGitLocs from ind01106 a (NOLOCK) 
	JOIN #tmpGitProcess b ON a.inv_id=b.inv_id
	JOIN sku_names sn (NOLOCK) ON sn.PRODUCT_CODE=a.PRODUCT_CODE
	WHERE b.inv_id<>''
	GROUP BY article_no,para1_name,para2_name,b.dept_id

	SET @cStep='80'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)	
	INSERT INTO #tmpGitLocs (articleNo,colour,size,locId,gitQty)
	select article_no articleNo,para1_name colour,para2_name size,b.dept_id locId,sum(quantity) gitQty  from rmd01106 a (NOLOCK) 
	JOIN #tmpGitProcess b ON a.rm_id=b.rm_id
	JOIN sku_names sn (NOLOCK) ON sn.PRODUCT_CODE=a.PRODUCT_CODE
	WHERE b.rm_id<>''
	GROUP BY article_no,para1_name,para2_name,b.dept_id

	--if @@spid=739
	--	select 'check git',* from #tmpGitLocs where articleno='Ml-3004w24' order by colour

	SET @cStep='90'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	CREATE TABLE #tmpPndingOrders (locId cHAR(2),articleNo  VARCHAR(200),colour VARCHAR(100),size VARCHAR(100),pendingQty NUMERIC(10,2))

	SET @cFilterItems=REPLACE(@cFilterItems,'article_no','art.article_no')
	SET @cCmd=N'select locId,article_no articleNo,para1_name colour,para2_name size,sum(pendingOrderQty) pendingOrderQty
	FROM 
	(select bo.dept_id locId,article.article_no,para1_name,para2_name,SUM(CASE WHEN A.XNTYPE = ''ORDER'' THEN QTY ELSE - 1 * Qty END)as pendingOrderQty 
     FROM SalesOrderProcessing A with(nolock) 
     JOIN buyer_order_mst bo(NOLOCK) ON bo.order_id = a.RefMemoId 
     JOIN #tmplocs locs on locs.locId=bo.dept_id JOIN #tmpArticles art ON art.article_code=a.articleCode
     JOIN article (NOLOCK) ON article.article_code = a.ArticleCode 
     JOIN  sectiond sd (NOLOCK) ON sd.sub_section_code=article.sub_section_code
     JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code 
     JOIN para1 p1(NOLOCK) ON p1.para1_code = a.Para1Code 
     JOIN para2 p2(NOLOCK) ON p2.para2_code = a.Para2Code 
     WHERE  XNTYPE IN(''ORDER'',''OrderPickList'',  ''ORDERPACKSLIP'', ''ORDERINVOICE'', ''orderShortClose'')'+ 
        @cFilterItems + 'GROUP BY bo.dept_id ,article.article_no, para1_name, para2_name 
         HAVING SUM(CASE WHEN A.XNTYPE = ''ORDER'' THEN QTY ELSE - 1 * Qty END) > 0
	 UNION ALL	
	 select bo.dept_id locId,article.article_no,para1_name,para2_name,SUM(CASE WHEN A.XNTYPE = ''Picklist'' THEN QTY ELSE - 1 * Qty END)as pendingOrderQty 
     FROM SalesOrderProcessing A with(nolock) 
	 JOIN plm01106 plm(NOLOCK) ON plm.memo_id = a.RefMemoId 
     JOIN buyer_order_mst bo(NOLOCK) ON bo.order_id = plm.order_id
     JOIN #tmplocs locs on locs.locId=bo.dept_id JOIN #tmpArticles art ON art.article_code=a.articleCode
     JOIN article (NOLOCK) ON article.article_code = a.ArticleCode 
     JOIN  sectiond sd (NOLOCK) ON sd.sub_section_code=article.sub_section_code
     JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code 
     JOIN para1 p1(NOLOCK) ON p1.para1_code = a.Para1Code 
     JOIN para2 p2(NOLOCK) ON p2.para2_code = a.Para2Code 
     WHERE  XNTYPE IN(''picklist'', ''plPackSlip'',''plInvoice'',''PlShortClose'')'+ 
        @cFilterItems + 'GROUP BY bo.dept_id ,article.article_no, para1_name, para2_name 
         HAVING SUM(CASE WHEN A.XNTYPE = ''picklist'' THEN QTY ELSE - 1 * Qty END) > 0
	 ) a	GROUP BY locId,article_no, para1_name, para2_name  '

	PRINT @cCmd

	INSERT INTO #tmpPndingOrders (locId,articleNo ,colour,size ,pendingQty)
	EXEC SP_EXECUTESQL @cCmd


	SET @cStep='100'
	--select 'check tmpArticles',* from #tmpArticles
	--select 'check tmpLocs',* from #tmpLocs

	SET @cFilterItems=REPLACE(@cFilterItems,'art.article_no','sn.article_no')
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)	
	SET @cCmd=N'select locId,article_no articleNo,para1_name colour, para2_name size,sum(pendingWpsQty) pendingOrderQty 
    from  ( SELECT  locs.locId locId, article_no,para1_name,para2_name,  
    SUM(quantity) as pendingWpsQty FROM wps_det a (NOLOCK) JOIN wps_mst b (NOLOCK) ON a.ps_id=b.ps_id 
        JOIN sku_names sn(NOLOCK) ON sn.product_code=a.product_code  
        JOIN #tmplocs locs on locs.locId=b.party_dept_id 
        WHERE ISNULL(B.WSL_INV_ID,'''')=''''' + @cFilterItems + ' and cancelled=0  
        GROUP BY locs.locId,article_no,para1_name,para2_name ) a  
        group by locId,article_no ,para1_name ,para2_name'
	
	PRINT @cCmd
	INSERT INTO #tmpPndingOrders (locId,articleNo ,colour,size ,pendingQty)
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='105'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	UPDATE a SET slsQty=b.slsQty,stockQty=b.stockQty FROM #tmpArsData a
	JOIN #tmpSlsStockData b ON a.locId=b.locId AND a.articleNo=b.articleNo AND a.colour=b.colour AND a.size=b.size

	UPDATE a SET gitQty=b.gitQty FROM #tmpArsData a
	JOIN (SELECT locId,articleNo,colour,size,SUM(GITQTY) gitqty FROM #tmpGitLocs GROUP BY locId,articleNo,colour,size) b
	ON a.locId=b.locId AND a.articleNo=b.articleNo AND a.colour=b.colour AND a.size=b.size


	SET @cStep='110'

	UPDATE a SET ordersInHand=b.ordersInHand  FROM #tmpArsData a
	JOIN (SELECT locId,articleNo,colour,size,SUM(pendingQty) ordersInHand FROM #tmpPndingOrders GROUP BY locId,articleNo,colour,size) b
	ON a.locId=b.locId AND a.articleNo=b.articleNo AND a.colour=b.colour AND a.size=b.size

	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	DECLARE @nSeasonDays INT
	SELECT TOP 1 @nSeasonDays=datediff(dd,a.period_from,convert(date,getdate())) 
	FROM season_mst a (NOLOCK) JOIN #tmplocs b on a.season_Id=b.seasonId

	UPDATE #tmpArsData SET suggestedRefillQty=maxStockLevel-(stockQty+gitQty+ordersInHand),userRefillQty=maxStockLevel-(stockQty+gitQty+ordersInHand)
	WHERE (stockQty+gitQty+ordersInHand)<=ceiling(maxStockLevel*reorderLevel/100)

	IF @cArsMemoId<>'' AND @bGeneratePickList=1
	BEGIN
		
		--select count(*) beforewhstock from #tmpArsData where suggestedRefillQty>0
		UPDATE a SET  whStockQty=b.stockQty FROM #tmpArsData a
		JOIN #tmpWhStockData b  ON a.articleNo=b.articleNo AND a.colour=b.colour AND a.size=b.size
	
		UPDATE #tmpArsData SET userRefillQty=ISNULL(whStockQty,0) WHERE suggestedRefillQty>ISNULL(whStockQty,0)

		UPDATE #tmpArsData SET whStockQty=0 where whStockQty IS NULL

		DELETE FROM #tmpArsData WHERE locid+articleno+colour not in (select distinct locId+articleno+colour from  #tmpArsData where suggestedRefillQty>0 )

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpArsData WHERE whStockQty>0)
		BEGIN
			SET @cErrormsg='Picklist cannot be genrated as no stock available in Warehouse...'
			GOTO End_proc
		END

		--select count(*) afterwhstock from #tmpArsData
    END


	--if @@spid=57
	--	select 'check from #tmpArsData',* from #tmpArsData

	SET @cStep='120'
	PRINT 'Processing Refill Orders Step#'+@cStep+':'+convert(varchar,getdate(),113)
	IF @cArsMemoId=''
	BEGIN
		
		SELECT memoId, locId, locName, city, state, locCategory,convert(numeric(7,2),0) sellThru,convert(numeric(20,2),0) daysOfStock,
		sum(suggestedRefillQty) suggestedRefillQty, sum(userRefillQty) userRefillQty, sum(slsQty) slsQty, sum(stockQty) stockQty, sum(maxStockLevel) maxStockLevel,
		sum(ordersInHand) ordersInHand , sum(gitQty) gitQty, sum(plannedQty) plannedQty into #tmpFinalArs FROM 
		#tmpArsData WHERE locId in (select locId from #tmpArsData where suggestedRefillQty>0)
		GROUP BY locId,memoId, locName, city, state, locCategory

		UPDATE #tmpFinalArs SET 
		daysOfStock=(CASE WHEN slsQty/@nSeasonDays>0 THEN ceiling(stockQty/(slsQty/@nSeasonDays)) ELSE 0 END),
		sellThru=(CASE WHEN slsQty>0 THEN round(slsqty*100/(slsqty+stockQty),0) ELSE 0 END)

		SELECT * from #tmpFinalArs ORDER BY suggestedRefillQty desc
	END
	ELSE
	BEGIN
		UPDATE #tmpArsData SET whStockQty=isnull(whStockQty,0), daysOfStock=(CASE WHEN slsQty/@nSeasonDays>0 THEN ceiling(stockQty/(slsQty/@nSeasonDays)) ELSE 0 END),
		sellThru=(CASE WHEN slsQty>0 THEN round(slsqty*100/(slsqty+stockQty),0) ELSE 0 END)
		WHERE locId+articleNo+colour in (select locId+articleNo+colour from #tmpArsData where suggestedRefillQty>0)

		UPDATE #tmpArsData SET article_code=b.article_code FROM article b 
		where b.article_no=#tmpArsData.articleNo

		UPDATE #tmpArsData SET para1_code=b.para1_code FROM para1 b 
		where b.para1_name=#tmpArsData.colour

		UPDATE #tmpArsData SET size=replace(size,'.','_')+'_'+b.para2_code FROM para2 b 
		where b.para2_name=#tmpArsData.size

		SELECT * from #tmpArsData WHERE articleNo+colour in (select articleNo+colour from #tmpArsData where suggestedRefillQty>0)
		ORDER BY sizeSetName
	END

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_ARS_PENDINGRFO at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH


END_PROC:
	
	PRINT 'Processing Refill Orders Step#50'+convert(varchar,getdate(),113)		

END