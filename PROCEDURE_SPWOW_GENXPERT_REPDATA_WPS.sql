CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_WPS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.WPS_DET wps_det (NOLOCK)       
	JOIN  [DATABASE].dbo.WPS_mst wps_mst (NOLOCK) ON wps_det.PS_ID = wps_mst.PS_ID       
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=wps_det.PRODUCT_CODE
	

	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=wps_mst.location_code/*LEFT(wps_mst.PS_ID,2) *//*Rohit 05-11-2024*/    
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	LEFT JOIN location TargetLocation on TargetLocation.dept_id=wps_mst.party_dept_id
	LEFT JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	LEFT JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	LEFT JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code



	JOIN bin SourceBin on SourceBin.bin_id=wps_det.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=wps_mst.location_code/*LEFT(wps_mst.PS_ID,2) *//*Rohit 05-11-2024*/

	 Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=wps_mst.location_code/*LEFT(wps_mst.PS_ID,2) *//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	Left outer JOIN lm01106 party_lm01106 on party_lm01106.ac_code=wps_mst.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=wps_mst.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code

	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code


    LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code

	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=wps_mst.XN_ITEM_TYPE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
    Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	LEFT OUTER JOIN users  ON wps_mst.USER_CODE= USERS.USER_CODE
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=wps_mst.location_code/*LEFT(wps_mst.PS_ID,2) *//*Rohit 05-11-2024*/ AND sku_xfp.product_code=wps_det.product_code
  	WHERE wps_mst.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND wps_mst.cancelled=0 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='WPI',
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