CREATE PROCEDURE SP3S_GET_ARO_SIZERATIO_WISE_PICKUPQTY--(LocId 3 digit change by Sanjay:05-11-2024)
@cTargetLocId VARCHAR(4),
@cRepColsIns VARCHAR(MAX),
@cRepCols VARCHAR(MAX),
@cRepBoMstJoinStr varchar(max),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cColList VARCHAR(1000),@cStep VARCHAR(10),@cRowId VARCHAR(40),@cArticleNo VARCHAR(400),@cCmd NVARCHAR(MAX),
	@bSizeSet BIT,@cArtDetRowId VARCHAR(40),@cSubSectionCode VARCHAR(10),@nSumRatio NUMERIC(3,0),@cArticleCode VARCHAR(10),
	@nFinalQtyPicked NUMERIC(10,2),@cStkPickingWhere VARCHAR(100),@nTopSrno NUMERIC(2,0),@nSrNo NUMERIC(2,0),
	@cSourceLocId VARCHAR(4)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	SELECT @cCollist = coalesce(@cColList+',','')+column_name from config_buyerorder (NOLOCK)
	WHERE OPEN_KEY=1 and COLUMN_NAME<>'para2_name'

	SELECT a.para2_code,para2_ratio,convert(numeric(10,2),0) qty INTO #sizeRatio 
	FROM art_det a  WHERE 1=2

	--if @@spid=204
	--	select 'check b4 size ratio',* FROM #aro_refill_plan WHERE dept_id=@cTargetLocId AND ISNULL(sizeratioapplied,0)=0

	SET @cStep='20'
	WHILE EXISTS (SELECT top 1 dept_id FROM #aro_refill_plan WHERE dept_id=@cTargetLocId AND plan_id<>'SIZERATIO' and ISNULL(sizeratioapplied,0)=0 and isnull(short_qty,0)>0)
	BEGIN
		SELECT TOP 1 @cRowId=row_id,@cArticleNo=article_no FROM #aro_refill_plan WHERE dept_id=@cTargetLocId 
		AND plan_id<>'SIZERATIO' AND ISNULL(sizeratioapplied,0)=0 AND ISNULL(short_qty,0)>0
		
		DELETE FROM #sizeRatio
		
		SET @cStep='30'
		SELECT @cArtDetRowId='',@cSubSectionCode=''
		SELECT TOP 1 @cArtDetRowId=a.row_id,@cArticleCode=A.article_code from art_det a JOIN  article b (NOLOCK) on a.article_code=b.article_code
		WHERE article_no=@cArticleNo

		IF ISNULL(@cArtDetRowId,'')<>''
			INSERT INTO #sizeRatio (para2_code,para2_ratio)
			SELECT para2_code,para2_ratio from art_det where article_code=@cArticleCode
		ELSE
		BEGIN
			SET @cStep='40'
			SELECT TOP 1 @cSubSectionCode=a.sub_section_code FROM article a (NOLOCK)
			JOIN sectiondpara2 sd (NOLOCK) ON sd.sub_section_code=a.sub_section_code
			WHERE article_no=@cArticleNo

			IF ISNULL(@cSubSectionCode,'')<>''
				INSERT INTO #sizeRatio (para2_code,para2_ratio)
				SELECT para2_code,ISNULL(para2_ratio,0) from sectiondpara2 where Sub_Section_Code=@cSubSectionCode
			ELSE
				INSERT INTO #sizeRatio (para2_code,para2_ratio)
				SELECT para2_code,1 as para2_ratio from para2 where para2_code='0000000'

		END
		
		SET @cStep='50'
		update #sizeRatio set para2_ratio=1 WHERE ISNULL(PARA2_RATIO,0)=0
		
		SELECT @nSumRatio=sum(para2_ratio) from #sizeRatio

		SET @cCmd=N'SELECT TOP 1 @cSourceLocId=c.dept_id from  #aro_refill_plan c 
		JOIN #aro_refill_plan b ON '+@cRepBoMstJoinStr+'
		WHERE b.row_id='''+@cRowId+''' AND ISNULL(c.excess_qty,0)<>0 '

		EXEC SP_EXECUTESQL @cCmd,N' @cSourceLocId VARCHAR(4) OUTPUT', @cSourceLocId output

		SET @cCmd=N'INSERT #aro_refill_plan (plan_id,'+@cRepColsIns+',para2_name,qtypicked,row_id,sale_qty,target_daily_sale,actual_daily_sale)
				SELECT ''SIZERATIO'' as plan_id,'+REPLACE(replace(@cRepCols,'c.dept_id',''''+@cSourceLocId+''''),
				'sn.','a.') +',p2.para2_name,
				ROUND(((a.qtypicked+a.final_stock)/'+str(@nSumRatio)+')*b.para2_ratio,0) qtypicked,
				'''+@cRowId+''' as row_id,0 sale_qty,0 target_daily_sale,0 actual_daily_sale
				FROM #aro_refill_plan a (NOLOCK),#sizeRatio b
				JOIN para2 p2 ON p2.para2_code=b.para2_code
				WHERE  a.dept_id='''+@cTargetLocId+''' AND a.row_id='''+@cRowId+''''

		PRINT ISNULL(@cCmd,'null aro ins')		
		EXEC SP_EXECUTESQL @cCmd
		
		SET @cStep='60'
		SELECT @nFinalQtyPicked=SUM(qtypicked) from #aro_refill_plan WHERE row_id=@cRowId AND plan_id='sizeratio'

		UPDATE #aro_refill_plan SET sizeratioapplied=1,qtypicked=@nFinalQtyPicked,qtyapplied=0
		WHERE row_id=@cRowId and plan_id<>'SIZERATIO'
	END

	DECLARE @cExcessQtyLoc VARCHAR(4),@bFlag BIT
	SET @cStep='70'
		print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
	SELECT DISTINCT a.dept_id,CONVERT(NUMERIC(2,0),0) SRNO INTO #tmpExcessLoc FROM  #aro_refill_plan a 
	JOIN  #tmpSourceLocs b ON a.dept_id=b.dept_id
	JOIN location c ON c.dept_id=a.dept_id
	WHERE ISNULL(excess_qty,0)<>0 

	SET @cStep='75'
	UPDATE a SET srno=(CASE WHEN ISNULL(primary_source_for_aro,0)=1 THEN 1 ELSE 2 END) FROM #tmpExcessLoc a 
	JOIN location b ON a.dept_id=b.dept_id
		
	SELECT @nTopSrno=MIN(srno) from #tmpExcessLoc
		
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpExcessLoc)
	BEGIN
		SET @cStep='80'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		SELECT TOP 1 @cExcessQtyLoc=dept_id,@nSrno=srno FROM #tmpExcessLoc ORDER BY srno DESC
			
		---- Just pick the Pending Refill qty If Stock picking location is Primary Source of ARO
		SET @cStkPickingWhere=(CASE WHEN @nTopSrno=@nSrno THEN ' OR 1=1' ELSE '' END)
		
		--if @@spid=487
		--	select 'check b4 applying', excess_qty,short_qty,dept_id,* from #aro_refill_plan 
		--	where article_no='M-012'
		
		SET @cCmd=N'UPDATE c SET excess_qty=(CASE WHEN (b.qtypicked-ISNULL(b.qtyapplied,0))>c.excess_qty AND '+
		(CASE WHEN @nTopSrno=@nSrno THEN '1=2' else '1=1' END)+' THEN c.excess_qty ELSE b.qtypicked-ISNULL(b.qtyapplied,0) END)
		FROM #aro_refill_plan c
		JOIN #aro_refill_plan b ON '+@cRepBoMstJoinStr+'
		WHERE c.dept_id='''+@cExcessQtyLoc+''' AND b.dept_id='''+@cTargetLocId+'''
		AND (ISNULL(c.excess_qty,0)<>0 '+@cStkPickingWhere+') AND ISNULL(b.short_qty,0)<>0'
		PRINT @cCmd		
		EXEC SP_EXECUTESQL @cCmd

		--if @@spid=487
		--	select 'check after applying 1', excess_qty,short_qty,dept_id,* from #aro_refill_plan 
		--	where article_no='M-012'

		SET @cStep='85'
			print 'Running  Ari Refill #'+@cStep+' '+CONVERT(VARCHAR,GETDATE(),113)
		SET @cCmd=N'UPDATE c SET qtyapplied=c.qtyapplied+b.excess_qty
		FROM #aro_refill_plan c
		JOIN #aro_refill_plan b ON '+@cRepBoMstJoinStr+'
		WHERE b.dept_id='''+@cExcessQtyLoc+''' AND c.dept_id='''+@cTargetLocId+'''
		AND ISNULL(b.excess_qty,0)<>0 '
		PRINT @cCmd		
		EXEC SP_EXECUTESQL @cCmd

		--if @@spid=487
		--	select 'check after applying 2', excess_qty,short_qty,dept_id,* from #aro_refill_plan 
		--	where article_no='M-012'

		SET @cStep='88'
		DELETE FROM #tmpExcessLoc WHERE dept_id=@cExcessQtyLoc
	END

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_ARO_SIZERATIO_WISE_PICKUPQTY at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH


END_PROC:
END