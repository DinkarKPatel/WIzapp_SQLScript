CREATE PROCEDURE SP3S_MANUALCOUNT_VARIANCE
@cSetupid VARCHAR(20)='',
@dRepDt DATETIME,
@cLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cHoLocId VARCHAR(5),@cCurLocid VARCHAR(5),@bHoLoc BIT,@cStkExpr varchar(2000),@cSourcetable VARCHAR(400),
			@cCollist varchar(2000),@cCmd NVARCHAR(MAX),@bErrorFound BIT,@bImportMode BIT,@cJoinstr VARCHAR(2000),@cRepCols VARCHAR(1000),
			@cAttrColName VARCHAR(200),@cFilter VARCHAR(4000),@cAttrName VARCHAR(200),@cPmtTable VARCHAR(200),@cMemoId VARCHAR(40)
		
	--SET @cPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dRepDt-1,112)
    SET @cPmtTable='PMt01106'
	
	SELECT a.*,b.location_code  as dept_id,b.STK_COUNT_SETUP_ID,computer_stock as ho_computer_stock,convert(bit,0) as ho_entry  
	INTO #RepManualStock
	FROM MANUAL_STOCK_COUNT_XN_DET a (NOLOCK) 
	join MANUAL_STOCK_COUNT_XN_MST b on 1=2

	DECLARE @tMemos TABLE (STK_COUNT_SETUP_ID varCHAR(10),filter varchar(4000))
	DECLARE @tConfigAttr TABLE (attr_column_name varchar(200))


	INSERT @tMemos (STK_COUNT_SETUP_ID,filter)
	SELECT DISTINCT a.STK_COUNT_SETUP_ID,filter FROM MANUAL_STOCK_COUNT_XN_MST a (NOLOCK) 
	JOIN STOCK_COUNT_SETUP_MST b (NOLOCK) ON b.STK_COUNT_SETUP_ID=a.STK_COUNT_SETUP_ID
	WHERE memo_dt=@dRepDt AND (b.location_code=@cLocId OR @cLocId='')

	WHILE EXISTS (SELECT TOP 1 * from @tMemos)
	BEGIN
		SELECT TOP 1 @cSetupid=STK_COUNT_SETUP_ID,@cFilter=Filter FROM @tMemos

		SET @cCollist=NULL

		if isnull(@cFilter,'')= ''
		Set @cFilter='1=1'

		SELECT @cCollist = coalesce(@cColList+',','')+col_value from STOCK_COUNT_SETUP_col_list  
		WHERE STK_COUNT_SETUP_ID=@cSetupid 
		SET @cJoinstr=' 1=1 '
		
		SELECT @cJoinstr=@cJoinstr+(CASE WHEN charindex('SECTION_NAME',@cColList)>0 THEN  ' AND b.section_name=c.section_name ' ELSE '' END)+
			(CASE WHEN charindex('SUB_SECTION_NAME',@cColList)>0 THEN  ' AND b.sub_section_name=c.sub_section_name ' ELSE '' END)+
			(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ' AND b.article_no=c.article_no ' ELSE '' END)+
			(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' AND b.para1_name=c.para1_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ' AND b.para2_name=c.para2_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)

		SELECT @cRepCols='isnull(b.STK_COUNT_SETUP_ID,c.STK_COUNT_SETUP_ID) as STK_COUNT_SETUP_ID,
						  isnull(b.STK_COUNT_SETUP_name,c.STK_COUNT_SETUP_name) as STK_COUNT_SETUP_name'+
			(CASE WHEN charindex('SECTION_NAME',@cColList)>0 THEN  ',ISNULL(b.section_name,c.section_name) as section_name' ELSE '' END)+
			(CASE WHEN charindex('SUB_SECTION_NAME',@cColList)>0 THEN  ',ISNULL(b.sub_section_name,c.sub_section_name) as sub_section_name ' ELSE '' END)+
			(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ',ISNULL(b.article_no,c.article_no) as article_no ' ELSE '' END)+
			(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',ISNULL(b.para1_name,c.para1_name) as para1_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ',ISNULL(b.para2_name,c.para2_name) as para2__name ' ELSE '' END)+
			(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',ISNULL(b.para3_name,c.para3_name) as para3__name ' ELSE '' END)+
			(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',ISNULL(b.para4_name,c.para4_name) as para4__name ' ELSE '' END)+
			(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',ISNULL(b.para5_name,c.para5_name) as para5__name ' ELSE '' END)+
			(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',ISNULL(b.para6_name,c.para6_name) as para6_name ' ELSE '' END)


		INSERT @tConfigAttr (attr_column_name)
		SELECT column_name from CONFIG_ATTR where table_caption<>''

		WHILE EXISTS (select * from @tConfigAttr)
		BEGIN
			SELECT top 1 @cAttrColName=ATTR_COLUMN_NAME from @tConfigAttr
			
			IF charindex(@cAttrColName,@cColList)>0
				SELECT @cJoinstr=@cJoinstr+' AND b.'+@cAttrColName+'=c.'+@cAttrColName,
					   @cRepCols=@cRepCols+',ISNULL(b.'+@cAttrColName+',c.'+@cAttrColName+') as '+@cAttrColName

			DELETE FROM @tConfigAttr where attr_column_name=@cAttrColName
		END

		SET  @cCmd = N' INSERT #RepManualStock (memo_id,row_id,STK_COUNT_SETUP_ID,dept_id,'+@cCollist+',ho_computer_stock,computer_stock,physical_stock,ho_entry)
						SELECT '''' ,row_id,STK_COUNT_SETUP_ID,b.location_code as dept_id,'+@cCollist+',0 as ho_computer_stock,computer_stock,physical_stock,0 as ho_entry
						from MANUAL_STOCK_COUNT_XN_DET a (NOLOCK)
						JOIN MANUAL_STOCK_COUNT_XN_mst b (NOLOCK) ON a.memo_id=b.memo_id
						WHERE memo_dt='''+convert(varchar,@dRepDt,110)+''' AND STK_COUNT_SETUP_ID='''+@cSetupId+''''
		print @cCmd
		EXEC SP_EXECUTESQL @cCmd 


		SET  @cCmd = N' INSERT #RepManualStock (memo_id,row_id,STK_COUNT_SETUP_ID,dept_id,'+@cCollist+',ho_computer_stock,ho_entry,computer_stock,physical_stock)
					SELECT '''','''','''+@cSetupId+''',dept_id,'+@cCollist+',SUM(quantity_in_stock) as ho_computer_stock,1 as ho_entry,0 as computer_stock,0 as physical_stock
					from '+@cPmtTable+' a (NOLOCK)
					JOIN sku_names b ON a.product_code=b.product_code
					WHERE dept_id IN (SELECT distinct location_code FROM MANUAL_STOCK_COUNT_XN_MST (NOLOCK)
										WHERE memo_dt='''+convert(varchar,@dRepDt,110)+''') 
					AND	 '+@cFilter+' 
					GROUP BY dept_id,'+@cColList
		print @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cCmd=N'select state as [Location State],city as [Location City],area_name as [Location Area],
		loc.dept_id as [Location Id],loc.dept_name as [Location Name],
		loc.dept_alias as [Location Alias],'+@cRepCols+',
		--isnull(b.ho_computer_stock,0) as [Computer Stock at HO],
		isnull(c.computer_stock,0) as [Computer Stock at POS],
		isnull(c.physical_stock,0) as [Stock Count at POS],
		(isnull(c.computer_stock,0)-isnull(c.physical_stock,0)) as [Stock Count POS Veriance]
		--(isnull(c.computer_stock,0)-isnull(b.ho_computer_stock,0)) as [POS Count HO Veriance]
		from 
		(Select a.*,STK_COUNT_SETUP_NAME from #RepManualStock a
		 JOIN stock_count_setup_mst b on a.STK_COUNT_SETUP_ID=b.STK_COUNT_SETUP_ID  where ho_entry=1) b
		full outer join 
		(Select a.*,STK_COUNT_SETUP_NAME from #RepManualStock a
		 JOIN stock_count_setup_mst b on a.STK_COUNT_SETUP_ID=b.STK_COUNT_SETUP_ID  where ho_entry=0) c ON '+@cJoinstr+'
		 JOIN location loc (NOLOCK) ON loc.dept_id=isnull(b.dept_id,c.dept_id)
		 JOIN area (NOLOCK) ON area.area_code=loc.area_code
		 JOIN city (NOLOCK) ON city.city_code=area.city_code
		 JOIN state (NOLOCK) ON state.state_code=city.state_code
		 ORDER BY 1,2,3,4'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		TRUNCATE TABLE #RepManualStock

		DELETE FROM @tMemos where STK_COUNT_SETUP_ID=@cSetupid
	END

END
