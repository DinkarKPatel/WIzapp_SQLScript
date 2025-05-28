CREATE PROCEDURE SP3S_GET_ARO_SIZERATIO_FOR_CUTSIZE--(LocId 3 digit change by Sanjay:05-11-2024)
@cRepColsIns VARCHAR(MAX),
@cRepCols VARCHAR(MAX),
@cRepBoMstJoinStr varchar(max),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cColList VARCHAR(1000),@cStep VARCHAR(10),@cRowId VARCHAR(40),@cArticleNo VARCHAR(400),@cCmd NVARCHAR(MAX),
	@bSizeSet BIT,@cArtDetRowId VARCHAR(40),@cSubSectionCode VARCHAR(10),@nSumRatio NUMERIC(3,0),@cArticleCode VARCHAR(10),
	@nFinalQtyPicked NUMERIC(10,2),@cStkPickingWhere VARCHAR(100),@nTopSrno NUMERIC(2,0),@nSrNo NUMERIC(2,0),@cRepColsOld varchar(max),
	@cSourceLocId varchar(4),@cPara1Name VARCHAR(100),@cPara1Code CHAR(7),@cPara2Name VARCHAR(100),@cDeptId VARCHAR(4)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	
	--select @cRepColsIns RepColsIns ,@cRepCols RepCols

	--select 'check sizeratio-1',* from #aro_refill_plan where dept_id='gn' and article_no='avk1685' 

	SELECT @cCollist = coalesce(@cColList+',','')+column_name from config_buyerorder (NOLOCK)
	WHERE OPEN_KEY=1 and COLUMN_NAME<>'para2_name'

	SELECT article_no, para2_ratio,para2_name,convert(numeric(10,2),0) qty,CONVERT(NUMERIC(3,0),0) sumratio INTO #sizeRatio 
	FROM art_det a JOIN para2 b ON a.para2_code=b.para2_code
	join article c on c.article_Code=a.article_code WHERE 1=2



		INSERT INTO #sizeRatio (article_no,para2_ratio,para2_name)
		SELECT b.article_no,a.para2_ratio,para2_name from art_det a (NOLOCK)
		JOIN article b (NOLOCK) ON a.article_code=b.article_code
		JOIN para2 c (NOLOCK) ON c.para2_code=a.para2_code
		where b.article_no in (SELECT d.article_no FROM #aro_refill_plan d WHERE ISNULL(short_qty,0)>0 AND ISNULL(cut_size,0)=1)
		AND b.para2_Set=1

		SET @cStep='20'
		update #sizeRatio set para2_ratio=1 WHERE ISNULL(PARA2_RATIO,0)=0
		
		UPDATE a SET sumratio=b.sumratio FROM #sizeRatio a
		JOIN (SELECT c.article_no,sum(para2_ratio) sumratio FROM #sizeRatio c
			  GROUP BY c.article_no) b ON a.article_no=b.article_no
	
	SET @cRepColsOld=@cRepCols
	SET @cStep='30'
	WHILE EXISTS (SELECT top 1 dept_id FROM #aro_refill_plan WHERE ISNULL(sizeratioapplied,0)=0 AND plan_id<>'sizeratio' and isnull(short_qty,0)>0 AND isnull(CUT_SIZE,0)=1)
	BEGIN
		--select 'check sizeratio-2',* from #aro_refill_plan where  dept_id='02' and  article_no='MEN SHIRT' and para1_name like '%SKY%'

		SELECT TOP 1 @cRowId=row_id,@cDeptId=dept_id, @cArticleNo=article_no,@cPara1Name=para1_name,@cDeptId=dept_id FROM #aro_refill_plan WHERE 
		ISNULL(sizeratioapplied,0)=0 AND plan_id<>'sizeratio' AND ISNULL(short_qty,0)>0 AND isnull(CUT_SIZE,0)=1
		
		SET @cStep='40'

		--if @cArticleNo like '%MEN SHIRT%' and @cPara1name like '%sky%'
		--select 'check sizeratio-2',* from #aro_refill_plan where  dept_id='02' and  article_no='MEN SHIRT' and para1_name like '%SKY%'

		
		--if @cArticleNo like '%MEN SHIRT%' and @cPara1name like '%sky%'
		--select 'check sizeratio-3',@cArtDetRowId ArtDetRowId, * from #aro_refill_plan where  dept_id='02' and  article_no='MEN SHIRT' and para1_name like '%SKY%'

		
		--if @cArticleNo like '%MEN SHIRT%' and @cPara1name like '%sky%'
		--begin
		--select 'check sizeratio-4',* from #aro_refill_plan where  dept_id='02' and  article_no='MEN SHIRT' and para1_name like '%SKY%'
		--select para2_name,'check #sizeRatio table',a.* from #sizeRatio a where article_no=@cArticleNo 
		--end

		SET @cStep='50'
		
		SELECT	@cRepCols=REPLACE(@cRepColsOld,',sn.PARA1_NAME',','''+@cPara1Name+'''')

		SET @cCmd=N'INSERT #aro_refill_plan (plan_id,'+@cRepColsIns+',row_id,short_qty)
				SELECT DISTINCT ''SIZERATIO'' as plan_id,'+REPLACE(replace(@cRepCols,'c.dept_id',''''+@cDeptId+''''),
				'sn.','a.') +',	newid() as row_id,a.para2_ratio	FROM #sizeRatio a
				LEFT JOIN #aro_refill_plan b (NOLOCK) ON a.article_no=b.article_no AND a.para2_name=b.para2_name AND b.para1_name='''+@cPara1Name+'''
				AND b.dept_id='''+@cDeptId+'''
				WHERE a.article_no='''+@cArticleNo+''' AND  b.article_no IS NULL'

		if @cArticleNo like '%MEN SHIRT%' and @cPara1name like '%sky%'
		PRINT ISNULL(@cCmd,'null aro ins')		

		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='55'
		UPDATE a SET short_qty=	(para2_ratio-ISNULL(a.final_stock,0))
		FROM #aro_refill_plan a JOIN #sizeratio b ON a.article_no=b.article_no AND a.para2_name=b.para2_name
		WHERE a.article_no=@cArticleNo AND a.para1_name=@cPara1Name AND dept_id=@cDeptId AND (para2_ratio-ISNULL(a.final_stock,0))>0

		SET @cStep='60'
		UPDATE #aro_refill_plan SET sizeratioapplied=1,qtyapplied=0,cut_size=1
		WHERE article_no=@cArticleNo AND para1_name=@cPara1Name and dept_id=@cDeptId AND plan_id<>'SIZERATIO'
		AND ISNULL(short_qty,0)<>0

		--if @cArticleNo like '%avk1685%' and @cDeptId='gn' -- and @cPara1name like '%sky%'
		--begin
		--select 'check sizeratio-5',* from #aro_refill_plan where  dept_id='gn' and  article_no='avk1685' --and para1_name like '%SKY%'
		
		--end

	END

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_ARO_SIZERATIO_FOR_CUTSIZE at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH


END_PROC:
END
