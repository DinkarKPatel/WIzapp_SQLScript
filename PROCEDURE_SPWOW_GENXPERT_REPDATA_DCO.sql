CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_DCO ----(LocId 3 digit change by Sanjay:25-11-2024 left by concerned developer)
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
 AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
 
      
	   
	
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.FLOOR_ST_DET FLOOR_ST_DET (NOLOCK)       
	JOIN  [DATABASE].dbo.FLOOR_ST_MST FLOOR_ST_MST (NOLOCK) ON FLOOR_ST_DET.MEMO_ID = FLOOR_ST_MST.MEMO_ID      	
	 join SKU_NAMES (NOLOCK) ON sku_names.product_code=FLOOR_ST_DET.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=FLOOR_ST_MST.LOCATION_CODE

	    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=FLOOR_ST_MST.LOCATION_CODE
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN bin SourceBin on SourceBin.bin_id=FLOOR_ST_DET.SOURCE_BIN_ID
	JOIN bin targetBin on targetBin.bin_id=FLOOR_ST_DET.ITEM_TARGET_BIN_ID
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=FLOOR_ST_MST.LOCATION_CODE
	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=sku_names.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=sku_names.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code

	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=FLOOR_ST_MST.location_code AND sku_xfp.product_code=FLOOR_ST_DET.PRODUCT_CODE
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code
	
	LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code

	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	LEFT OUTER JOIN USERS ON USERS.USER_CODE= FLOOR_ST_MST.USER_CODE
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id

	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=sku_names.sku_item_type
  	WHERE FLOOR_ST_MST.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND FLOOR_ST_MST.cancelled=0 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='DCO',
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

  

 