CREATE PROCEDURE SP3S_GETFILTEREDMASTERS_POS
@cLocId VARCHAR(4),
@cMasterColExpr NVARCHAR(MAX),
@cModiFiedColAlias VARCHAR(100),
@cLastModifiedon VARCHAR(40)='',
@cMasterName VARCHAR(100)='',
@bReturnLastModifiedDateOnly BIT=0,
@cAttrJoin VARCHAR(MAX)='',
@cUnpivotExpr VARCHAR(1000)=''
AS
BEGIN
	DECLARE @ccmd NVARCHAR(MAX),@cColExpr NVARCHAR(MAX),@cModifiedColExpr VARCHAR(200)

	IF LEFT(@cMasterColExpr,4)='ATTR'
	BEGIN
		IF @bReturnLastModifiedDateOnly=1
			SET @cMasterName=@cModiFiedColAlias
		ELSE
			SET @cAttrJoin=' left JOIN '+@cMasterName+' (NOLOCK) ON '+@cMasterColExpr+'='+REPLACE(@cMasterColExpr,@cMasterName,'article_fix_attr')
	END

	IF @bReturnLastModifiedDateOnly=1
		SELECT @cColExpr=@cMasterColExpr,@cModifiedColExpr=''
	ELSE
		SELECT @cColExpr='distinct '+@cMasterColExpr,@cModifiedColExpr=','''+@cModiFiedColAlias+''''

	SET @cCmd=N'select '+@cColExpr+@cModifiedColExpr+' from ind01106 a (nolock) 
	join sku (nolock) on sku.product_Code=a.PRODUCT_CODE
	LEFT JOIN sku_oh (NOLOCK) ON sku_oh.product_code=a.PRODUCT_CODE
	JOIN article (NOLOCK) ON article.article_code=sku.article_code
	JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=article.sub_section_code
	JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code
	JOIN para1 (NOLOCK) ON para1.para1_code=sku.para1_code
	JOIN para2 (NOLOCK) ON para2.para2_code=sku.para2_code
	JOIN para3 (NOLOCK) ON para3.para3_code=sku.para3_code
	JOIN para4 (NOLOCK) ON para4.para4_code=sku.para4_code
	JOIN para5 (NOLOCK) ON para5.para5_code=sku.para5_code
	JOIN para6 (NOLOCK) ON para6.para6_code=sku.para6_code
	LEFT JOIN para7 (NOLOCK) ON para7.para7_code=sku.para7_code
	join lm01106 (NOLOCK) ON lm01106.ac_code=sku.ac_code
	left join lmp01106 (NOLOCK) ON lmp01106.ac_code=sku.ac_code
	JOIN inm01106 e (nolock) on e.INV_ID=a.INV_ID
	LEFT JOIN article_fix_attr (NOLOCK) ON article_fix_attr.article_code=article.article_code '+@cAttrJoin+
	' where e.party_dept_id='''+@cLocId+''' AND e.inv_mode=2  AND '+
	(CASE WHEN @bReturnLastModifiedDateOnly=0 THEN  @cModiFiedColAlias+'.last_modified_on>'''+@cLastModifiedon+'''' ELSE '1=1' END)

	IF @bReturnLastModifiedDateOnly=1
		SET @cCmd=' With originalData as ('+@cCmd+N') '+@cUnpivotExpr+' AS UnpivotedData
					GROUP BY TableName'
	
	PRINT @cCmd

	INSERT INTO #tmpMasterValues (masterValue,masterName)
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'select '+@cColExpr+@cModifiedColExpr+' from pid01106 a (nolock) 
	join sku (nolock) on sku.product_Code=a.PRODUCT_CODE
	JOIN sku_oh (NOLOCK) ON sku_oh.product_code=a.PRODUCT_CODE
	JOIN article (NOLOCK) ON article.article_code=sku.article_code
	JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=article.sub_section_code
	JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code
	JOIN para1 (NOLOCK) ON para1.para1_code=sku.para1_code
	JOIN para2 (NOLOCK) ON para2.para2_code=sku.para2_code
	JOIN para3 (NOLOCK) ON para3.para3_code=sku.para3_code
	JOIN para4 (NOLOCK) ON para4.para4_code=sku.para4_code
	JOIN para5 (NOLOCK) ON para5.para5_code=sku.para5_code
	JOIN para6 (NOLOCK) ON para6.para6_code=sku.para6_code
	LEFT JOIN para7 (NOLOCK) ON para7.para7_code=sku.para7_code
	join lm01106 (NOLOCK) ON lm01106.ac_code=sku.ac_code
	left join lmp01106 (NOLOCK) ON lmp01106.ac_code=sku.ac_code
	LEFT JOIN article_fix_attr (NOLOCK) ON article_fix_attr.article_code=article.article_code '+@cAttrJoin+
	' JOIN pim01106 e (nolock) on e.mrr_id=a.mrr_id '+
	(CASE WHEN @bReturnLastModifiedDateOnly=0 then ' LEFT JOIN #tmpMasterValues mst ON mst.masterValue='+@cMasterColExpr ELSE '' END)+
	' where e.dept_id='''+@cLocId+''' AND e.inv_mode=1  AND '+
	(CASE WHEN @bReturnLastModifiedDateOnly=0 THEN @cModiFiedColAlias+'.last_modified_on>'''+@cLastModifiedon+''' AND mst.masterValue IS NULL'  ELSE '1=1' END)


	IF @bReturnLastModifiedDateOnly=1
		SET @cCmd=' With originalData as ('+@cCmd+N') '+@cUnpivotExpr+' AS UnpivotedData
					GROUP BY TableName'

	PRINT @cCmd
	INSERT INTO #tmpMasterValues (masterValue,masterName)
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'select '+@cColExpr+@cModifiedColExpr+' from ops01106 a (nolock) 
	join sku (nolock) on sku.product_Code=a.PRODUCT_CODE
	JOIN sku_oh (NOLOCK) ON sku_oh.product_code=a.PRODUCT_CODE
	JOIN article (NOLOCK) ON article.article_code=sku.article_code
	JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=article.sub_section_code
	JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code
	JOIN para1 (NOLOCK) ON para1.para1_code=sku.para1_code
	JOIN para2 (NOLOCK) ON para2.para2_code=sku.para2_code
	JOIN para3 (NOLOCK) ON para3.para3_code=sku.para3_code
	JOIN para4 (NOLOCK) ON para4.para4_code=sku.para4_code
	JOIN para5 (NOLOCK) ON para5.para5_code=sku.para5_code
	JOIN para6 (NOLOCK) ON para6.para6_code=sku.para6_code
	LEFT JOIN para7 (NOLOCK) ON para7.para7_code=sku.para7_code
	join lm01106 (NOLOCK) ON lm01106.ac_code=sku.ac_code
	left join lmp01106 (NOLOCK) ON lmp01106.ac_code=sku.ac_code
	LEFT JOIN article_fix_attr (NOLOCK) ON article_fix_attr.article_code=article.article_code '+@cAttrJoin+
	(CASE WHEN @bReturnLastModifiedDateOnly=0 then ' LEFT JOIN #tmpMasterValues mst ON mst.masterValue='+@cMasterColExpr ELSE '' END)+
	' where a.dept_id='''+@cLocId+''' AND '+
	(CASE WHEN @bReturnLastModifiedDateOnly=0 THEN @cModiFiedColAlias+'.last_modified_on>'''+@cLastModifiedon+''' AND mst.masterValue IS NULL' ELSE '1=1' END)


	IF @bReturnLastModifiedDateOnly=1
		SET @cCmd=' With originalData as ('+@cCmd+N') '+@cUnpivotExpr+' AS UnpivotedData
					GROUP BY TableName'
	PRINT @cCmd
	INSERT INTO #tmpMasterValues (masterValue,masterName)
	EXEC SP_EXECUTESQL @cCmd

	--select 'check #tmpMasterValues',* from #tmpMasterValues
END