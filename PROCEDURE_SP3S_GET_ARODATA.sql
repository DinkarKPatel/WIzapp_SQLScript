CREATE PROCEDURE SP3S_GET_ARODATA--(LocId 3 digit change by Sanjay:05-11-2024)
@dFromDt DATETIME='',
@dToDt DATETIME='',
@cFilter VARCHAR(MAX)='',
@nMode NUMERIC(1,0)=0
AS
BEGIN
	DECLARE @cColList VARCHAR(max),@cRepCols VARCHAR(2000),@cRepColsIns VARCHAR(2000),@cJoinStr varchar(max),@cCmd NVARCHAR(MAX),
			@cFromDt VARCHAR(10),@cToDt VARCHAR(10),@cPmtTable VARCHAR(200),@cHoLocId VARCHAR(4),
			@nDays NUMERIC(3,0),@cStep VARCHAR(4),@cErrormsg VARCHAR(MAX),
			@cPeriodFromDt VARCHAR(10),@cPeriodToDt VARCHAR(10)

BEGIN TRY	
--select * into ARO_PLAN_LINK_LOC_test from #ARO_PLAN_LINK_LOC
	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
	SET @cFilter=(CASE WHEN ISNULL(@cFilter,'')='' THEN ' 1=1 ' ELSE @cFilter END)

	SET @cStep='10'
	SET @cErrormsg=''
	

	SELECT @cFromDt=CONVERT(VARCHAR,DATEADD(YY,-1,@dFromDt),112),
			@cToDt=CONVERT(VARCHAR,DATEADD(YY,-1,@dToDt),112)
	
	
	SELECT @cPeriodFromDt=CONVERT(VARCHAR,@dFromDt,112),
		   @cPeriodToDt=CONVERT(VARCHAR,@dToDt,112)

	SET @cStep='20'
	SET @cPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,getdate()-1,112)
	
	IF @nMode<>2
		SELECT * INTO #config_buyerorder from CONFIG_BUYERORDER  where isnull(open_key,0)=1 and column_name<>'para2_name'	
		SET @cCollist=NULL
	
	SET @cJoinstr = ' b.dept_id = c.dept_id '

	SELECT @cCollist = coalesce(@cColList+',','')+column_name from #config_buyerorder

	SET @cStep='30'
	SELECT @cJoinstr=@cJoinstr+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ' AND b.article_no=c.article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' AND b.para1_name=c.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)

	SELECT @cJoinstr=@cJoinstr+(CASE WHEN charindex(column_name,@cColList)>0 THEN  ' AND b.'+column_name+'=c.'+column_name ELSE '' END)
	FROM config_attr WHERE table_caption<>''
	
	SET @cStep='40'			
	SELECT @cRepCols='c.dept_id'+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ',c.article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',c.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',c.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',c.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',c.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',c.para6_name ' ELSE '' END)

	SELECT @cRepCols=@cRepCols+(CASE WHEN charindex(column_name,@cColList)>0 THEN  ',c.'+column_name ELSE '' END)
	FROM config_attr WHERE table_caption<>''

	SELECT @cRepColsIns=REPLACE(@cRepCols,'c.','')
	

	SET @nDays=DATEDIFF(dd,@dFromDt,@dToDt)	
	
	IF @nMode=2 --- Called from Import 
		GOTO lblProcess

	SELECT * INTO #aro_plan_det FROM aro_plan_det WHERE 1=2
	
	IF @nMode=0 --- Callled from application for blank dataset required for  Manual Import
		GOTO LAST

	SET @cStep='50'
		SET @cCmd=N'INSERT #aro_plan_det (plan_id,'+@cRepColsIns+',MBQ,reorder_stock_days,growth_factor,safety_level,
					row_id,sale_qty,target_daily_sale,target_plan_stock,wh_stock,period_sale_qty)
					SELECT ''later'' as plan_id, '+@cRepCols+',0 as mbq,reorder_stock_days,growth_factor,safety_level,
					NEWID() AS row_id,c.sale_qty,0 as target_daily_sale,0 as target_plan_stock,
					isnull(b.wh_stock,0),isnull(l.sale_qty,0) as period_sale_qty
					FROM 
					(
					SELECT '+replace(@cRepColsIns,'dept_id','b.location_code as dept_id')+',
					reorder_stock_days,d.growth_factor,d.SAFETY_FACTOR as safety_level,
					sum(quantity) as sale_qty,0 as target_plan_stock
					FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id		
					JOIN sku_names c (NOLOCK) ON c.product_code=a.product_code
					JOIN location loc (NOLOCK) ON loc.dept_id=b.location_code
					join loc_view (NOLOCK) ON loc.dept_id=loc_view.dept_id
					JOIN #ARO_PLAN_LINK_LOC d ON d.dept_id=b.location_code
					WHERE cm_dt between '''+@cFromDt+''' AND '''+@cToDt+''' and CANCELLED=0 AND '+@cFilter+'
					GROUP BY '+replace(@cRepColsIns,'dept_id','b.location_code')+',
					reorder_stock_days,d.growth_factor,d.SAFETY_FACTOR
					) c
					LEFT OUTER JOIN 
					(SELECT '+replace(@cRepColsIns,'dept_id','c.dept_id') +',sum(cbs_qty) as wh_stock
					 FROM '+@cPmtTable+' a (NOLOCK)
					 JOIN sku_names b (NOLOCK) ON b.product_code=a.product_code 
					 JOIN location c (NOLOCK) ON c.dept_id=a.dept_id
					 join loc_view (NOLOCK) ON c.dept_id=loc_view.dept_id
					 JOIN #ARO_PLAN_LINK_LOC d ON d.dept_id=a.dept_id
					 WHERE '+@cFilter+' AND (c.pur_loc=1 OR c.dept_id='''+@cHoLocId+''') 
					 GROUP BY '+replace(@cRepColsIns,'dept_id','c.dept_id')+'
					 ) b on '+@cJoinStr+'
					 LEFT OUTER JOIN 
					(
					SELECT '+replace(@cRepColsIns,'dept_id','b.location_code as dept_id')+',
					sum(quantity) as sale_qty
					FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id		
					JOIN sku_names c (NOLOCK) ON c.product_code=a.product_code
					JOIN location loc (NOLOCK) ON loc.dept_id=b.location_code
					join loc_view (NOLOCK) ON loc.dept_id=loc_view.dept_id
					JOIN #ARO_PLAN_LINK_LOC d ON d.dept_id=b.location_code
					WHERE cm_dt between '''+@cPeriodFromDt+''' AND '''+@cPeriodToDt+''' and CANCELLED=0 AND '+@cFilter+'
					GROUP BY '+replace(@cRepColsIns,'dept_id','b.location_code')+'
					) l on '+replace(@cJoinStr,'b.','l.')

		PRINT @cCmd	
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='60'

		UPDATE #aro_plan_det SET target_plan_sale=CEILING(sale_qty+(sale_qty*isnull(growth_factor,0)/100)) 
		UPDATE #aro_plan_det SET target_plan_sale=CEILING(target_plan_sale+(target_plan_sale*isnull(safety_level,0)/100)) 

lblProcess:
		SET @cStep='62'
		UPDATE #aro_plan_det SET target_daily_sale=target_plan_sale/@nDays
	
		UPDATE #aro_plan_det SET target_plan_stock=CEILING(target_daily_sale*reorder_stock_days),
								 suggested_plan_stock=CEILING(target_daily_sale*reorder_stock_days)

LAST:
	SET @cStep='65'
	DECLARE @cAddJoin VARCHAR(MAX),@cAddCols VARCHAR(MAX)

	SELECT @cAddJoin = ' JOIN article art (NOLOCK) ON art.article_no=a.article_no
						 JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
						 JOIN  sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
						 LEFT JOIN article_fix_attr af (NOLOCK) ON af.article_code=art.article_code '

	SELECT @cAddJoin=@cAddJoin+
	' LEFT JOIN  '+table_name+' ON '+table_name+'.'+replace(column_name,'_name','_code')+'=af.'+replace(column_name,'_name','_code')
	FROM config_attr WHERE table_caption<>''	
	
	SELECT @cAddCols=',sm.section_name,sd.sub_section_name'
	SELECT @cAddCols=@cAddCols+','+table_name+'.'+column_name+' as ['+table_caption+']'
	FROM config_attr WHERE table_caption<>''	
	
	--if @@spid=455
	--	select @cRepCols,@cAddcols,@cAddjoin,@cRepColsIns

	SET @cStep='70'
	SET @cCmd=N'SELECT '''' as errmsg,'+REPLACE(@cRepCols,'c.','a.')+@cAddCols+',
		sale_qty,growth_factor,safety_level,MBQ,target_plan_sale,target_daily_sale,reorder_stock_days,
		row_id,target_plan_stock,suggested_plan_stock
		FROM #aro_plan_det a ' +@cAddJoin+'
		ORDER BY '+@cRepColsIns
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOto END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_ARODATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

IF ISNULL(@cErrormsg,'')<>''
	SELECT @cErrormsg as errmsg
END
