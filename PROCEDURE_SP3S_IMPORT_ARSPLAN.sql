CREATE PROCEDURE SP3S_IMPORT_ARSPLAN
@nSpId NUMERIC(10,0),
@dFromDt DATETIME,
@dToDt DATETIME
AS
BEGIN

BEGIN TRY
	DECLARE @cErrormsg VARCHAR(MAX),@cStep VARCHAR(5),@cLocIdnotPlanned VARCHAR(5),@cMstnotFound VARCHAR(200),
	@cColList VARCHAR(2000),@cCmd NVARCHAR(MAX),@nCntLoop NUMERIC(2,0),@cTrappedErrormsg VARCHAR(500),
	@cParaName VARCHAR(100),@cParaCaption VARCHAR(100),@cErrCmd NVARCHAR(1000),@cSearchTable VARCHAR(100)

	SET @cStep='10'
	IF NOT EXISTS (SELECT TOP 1 sp_id FROM ##ars_import (NOLOCK) WHERE sp_id=@nSpId)
	BEGIN
		SET @cErrormsg='No data found to process...Please check'
		GOTO END_PROC
	END

	SELECT * INTO #config_buyerorder from CONFIG_BUYERORDER  where isnull(open_key,0)=1 and column_name<>'para2_name'	
	SET @cCollist=NULL
	
	
	SET @cStep='20'
	SELECT TOP 1 @cLocIdnotPlanned=a.dept_id FROM ##ars_import a (NOLOCK)
	LEFT JOIN #ARO_PLAN_LINK_LOC b (NOLOCK) ON a.dept_id=b.dept_id 
	WHERE a.sp_id=@nSpId AND b.dept_id IS NULL

	IF ISNULL(@cLocIdnotPlanned,'')<>''
	BEGIN
		SET @cErrormsg='Location Id :'+@cLocIdnotPlanned +' is not part of ARS Plan...Please check'
		GOTO END_PROC
	END

	SET @cStep='30'
	DECLARE @cAddJoin VARCHAR(MAX),@cAddCols VARCHAR(MAX)

	SELECT @cAddJoin = ' JOIN article art (NOLOCK) ON art.article_no=a.article_no
						 JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
						 JOIN  sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
						 JOIN article_fix_attr af (NOLOCK) ON af.article_code=art.article_code '

	SELECT @cAddJoin=@cAddJoin+
	' LEFT JOIN  '+table_name+' ON '+table_name+'.'+replace(column_name,'_name','_code')+'=af.'+replace(column_name,'_name','_code')
	FROM config_attr WHERE table_caption<>''	
	
	SET @cStep='40'
	SELECT @cAddCols=',sm.section_name,sd.sub_section_name'
	SELECT @cAddCols=@cAddCols+','+table_name+'.'+column_name+' as ['+table_caption+']'
	FROM config_attr WHERE table_caption<>''	

	SELECT @cCollist = coalesce(@cColList+',','')+'a.'+column_name from #config_buyerorder

	SET @cStep='45'
	IF EXISTS (SELECT TOP 1 sp_id FROM ##ars_import (NOLOCK) WHERE sp_id=@nSpId and ISNULL(target_plan_sale,0)=0)
	BEGIN
		SET @cTrappedErrormsg='Invalid Target Plan sale defined...Please check'
		SET @cErrCmd=N'SELECT '''+@cTrappedErrormsg+''' errmsg,'+@cCollist+' FROM ##ars_import a (NOLOCK)
					LEFT JOIN ARTICLE b (NOLOCK) ON a.article_no=b.article_no
					WHERE a.sp_id='+str(@nSpId)+' and ISNULL(target_plan_sale,0)=0'
		GOTO END_PROC
	END

	SET @cStep='50'
	SELECT TOP 1 @cMstnotFound=a.article_no FROM ##ars_import a (NOLOCK)
	LEFT JOIN ARTICLE b (NOLOCK) ON a.article_no=b.article_no
	WHERE a.sp_id=@nSpId AND b.article_no IS NULL

	
	IF @cMstnotFound IS NOT NULL
	BEGIN
		SET @cTrappedErrormsg='Article no. not found'
		SET @cErrCmd=N'SELECT '''+@cTrappedErrormsg+''' errmsg,'+@cCollist+',target_plan_sale FROM ##ars_import a (NOLOCK)
					LEFT JOIN ARTICLE b (NOLOCK) ON a.article_no=b.article_no
					WHERE a.sp_id='+str(@nSpId)+' AND b.article_no IS NULL'
		GOTO END_PROC
	END

	SET @nCntLoop=1

	WHILE @nCntLoop<=6
	BEGIN
		SET @cStep='60'
		SElect @cSearchTable='para'+ltrim(rtrim(str(@nCntLoop)))

		SET @cParaName=@cSearchTable+'_name'

		IF CHARINDEX(@cParaName,@cColList)>0
		BEGIN
			SET @cStep='70'
			SELECT @cParaCaption=value FROM config (NOLOCK) WHERE config_option=REPLACE(@cParaName,'_name','_caption')

			SET @cCmd=N'IF EXISTS (SELECT TOP 1 a.'+@cParaName+' FROM ##ars_import a (NOLOCK)
									LEFT JOIN '+@cSearchTable+' b (NOLOCK) ON a.'+@cParaName+'=b.'+@cParaName+'
									WHERE a.sp_id='+str(@nSpId)+' AND b.'+@cParaName+' IS NULL)
							SET @cErrCmd=N''SELECT '''''+@cParaCaption+' not found '''' errmsg,'+@cCollist+',target_plan_sale 
								FROM ##ars_import a (NOLOCK)
								LEFT JOIN '+@cSearchTable+' b (NOLOCK) ON a.'+@cParaname+'=b.'+@cParaName+'
								WHERE a.sp_id='+str(@nSpId)+' AND b.'+@cParaname+' IS NULL''
						ELSE
							SET @cErrCmd='''''
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd,N'@cErrCmd nvarchar(1000) output',@cErrCmd OUTPUT

			IF @cErrCmd<>''
				GOTO END_PROC
		END

		SET @nCntLoop=@nCntLoop+1
	END

	SET @cStep='75'

	IF OBJECT_ID('tempdb..#aro_plan_det','u') IS NOT NULL
		DROP TABLE #aro_plan_det

	select * into #aro_plan_det FROM aro_plan_det where 1=2

	DECLARE @cRepCols VARCHAR(1000),@cRepColsIns varchar(1000)
	SELECT @cRepCols='a.dept_id'+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ',article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',para6_name ' ELSE '' END)

	SET @cStep='80'
	SELECT @cRepCols=@cRepCols+(CASE WHEN charindex(column_name,@cColList)>0 THEN  ',c.'+column_name ELSE '' END)
	FROM config_attr WHERE table_caption<>''

	SELECT @cRepColsIns=REPLACE(@cRepCols,'c.','')
	
	
	SET @cCmd=N'INSERT #aro_plan_det (plan_id,'+@cRepColsIns+',reorder_stock_days,mbq,
				growth_factor,safety_level,row_id,sale_qty,target_daily_sale,target_plan_stock,wh_stock,period_sale_qty,target_plan_sale)
				SELECT ''later'' as plan_id, '+@cRepCols+',ISNULL(b.reorder_stock_days,0) reorder_stock_days,a.mbq,
				a.growth_factor,a.safety_level,''later''+left(convert(varchar(38),newid()),35) row_id,0 sale_qty,0 target_daily_sale,
				0 target_plan_stock,0 wh_stock,0 period_sale_qty,target_plan_sale FROM 
				##ars_import a (NOLOCK)
				LEFT JOIN #aro_plan_link_loc b ON a.dept_id=b.dept_id
				WHERE sp_id='+str(@nSpId)
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='90'
	EXEC SP3S_GET_ARODATA
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@nMode=2

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_IMPORT_ARSPLAN at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	IF ISNULL(@cErrormsg,'')<>''
		SELECT ISNULL(@cErrormsg,'') errmsg
	ELSE
	IF ISNULL(@cErrCmd,'')<>''
	BEGIN
		EXEC SP_EXECUTESQL @cErrCmd
	END
END