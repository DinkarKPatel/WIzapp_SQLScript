CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_ARS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.wowArsDet wowArsDet (NOLOCK)       
	JOIN  [DATABASE].dbo.wowArsmst wowArsmst (NOLOCK) ON wowArsDet.memoId = wowArsmst.memoId      
	JOIN article (NOLOCK) ON article.article_code=wowArsDet.articleCode
	JOIN para1 (NOLOCK) ON para1.para1_code=wowArsDet.para1Code
	JOIN para2 (NOLOCK) ON para2.para2_code=wowArsDet.para2Code
	LEFT OUTER  JOIN para3 (NOLOCK) ON para3.para3_code=wowArsDet.para3Code
	left outer JOIN art_names sku_names (NOLOCK) ON sku_names.article_code=article.article_code
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=wowArsmst.locId
	JOIN bin SourceBin on SourceBin.bin_id=''000''
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=wowArsmst.locId    
	--LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
	--LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
	--LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
	--LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
	--LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	--JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	--Left Outer JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	--Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	--Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	--Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code 	 	
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=1
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   
  	WHERE (wowArsmst.memoDt BETWEEN [DFROMDT] AND [DTODT])
	AND  wowArsmst.cancelled=0 	AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='ARS',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT



	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA1_name','para1.para1_name')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA1_ALIAS','para1.ALIAS')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA2_name','para2.para2_name')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA2_ALIAS','para2.ALIAS')
    Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA3_name','para3.para3_name')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA3_ALIAS','para3.ALIAS')
    Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA4_name','para4.para4_name')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA5_name','para5.para5_name')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.stock_na','article.stock_na')
	Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'sku_names.para2_order','para2.para2_order')
	
	
	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

END