CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_CNPS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.cnps_det cnps_det (NOLOCK)       
	JOIN  [DATABASE].dbo.cnps_mst cnps_mst (NOLOCK) ON cnps_det.PS_ID = cnps_mst.PS_ID      
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=cnps_det.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=LEFT(cnps_mst.PS_ID,2) 
	JOIN bin SourceBin on SourceBin.bin_id=cnps_det.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=LEFT(cnps_mst.PS_ID,2)

	    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=LEFT(cnps_mst.PS_ID,2)
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=cnps_mst.ac_code
	Left Outer JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=cnps_mst.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
   Left Outer 	JOIN state  party_state on party_state.state_code=party_city.state_code

	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=cnps_mst.XN_ITEM_TYPE

  	WHERE cnps_mst.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND cnps_mst.cancelled=0 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='CNPS',
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