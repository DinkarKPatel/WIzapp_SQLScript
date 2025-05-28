CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_CNC
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.icd01106 icd01106 (NOLOCK)       
	JOIN  [DATABASE].dbo.icm01106 icm01106 (NOLOCK) ON icd01106.cnc_memo_ID = icm01106.cnc_memo_ID      
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=icd01106.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=icm01106.location_code
	JOIN bin SourceBin on SourceBin.bin_id=icd01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=icm01106.location_code

    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=icm01106.location_code 
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

   JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=icm01106.location_code AND sku_xfp.product_code=icd01106.PRODUCT_CODE
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=icm01106.location_code AND sku_current_xfp.product_code=icd01106.PRODUCT_CODE
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=icm01106.XN_ITEM_TYPE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
  	WHERE (icm01106.cnc_memo_dt BETWEEN [DFROMDT] AND [DTODT])
	 AND icm01106.cnc_type=1   AND ISNULL(icm01106.stock_adj_note,0)=0 AND icm01106.cancelled=0 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='CNC',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT


	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

END