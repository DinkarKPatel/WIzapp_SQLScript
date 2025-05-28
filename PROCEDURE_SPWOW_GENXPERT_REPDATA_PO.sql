CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_PO
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@cDateFilterCol VARCHAR(100)
		

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.POD01106 POD01106 (NOLOCK)       
	JOIN  [DATABASE].dbo.POM01106 POM01106 (NOLOCK) ON POM01106.PO_ID = POD01106.PO_ID       
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=POM01106.Location_CODE   
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=POM01106.ac_code
	Left Outer JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=POM01106.ac_code
    Left Outer 	JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=pod01106.product_code
    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=POM01106.dept_id   
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code
	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=POM01106.ac_code
	Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
	LEFT JOIN lm01106 oem on  oem.ac_code=pom01106.SHIPPING_FROM_AC_CODE
	JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=POM01106.ac_code
	JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code	
	LEFT OUTER JOIN users  ON POM01106.USER_CODE= USERS.USER_CODE
	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code


	JOIN bin SourceBin on SourceBin.bin_id=pom01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pom01106.dept_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=pom01106.XN_ITEM_TYPE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
		
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
	WHERE POM01106.PO_DT BETWEEN [DFROMDT] AND [DTODT]  AND pom01106.cancelled=0 AND 
	[WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='PO',
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