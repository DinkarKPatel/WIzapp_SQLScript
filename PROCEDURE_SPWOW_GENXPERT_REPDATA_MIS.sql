
CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_MIS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
 AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
 

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.BOM_ISSUE_DET BOM_ISSUE_DET (NOLOCK)       
	JOIN  [DATABASE].dbo.BOM_ISSUE_MST BOM_ISSUE_MST (NOLOCK) ON BOM_ISSUE_DET.issue_id = BOM_ISSUE_MST.issue_id      	
   JOIN  [DATABASE].dbo.prd_agency_mst PAM (NOLOCK) ON BOM_ISSUE_MST.agency_code = PAM.agency_code 
	 join SKU_NAMES (NOLOCK) ON sku_names.product_code=BOM_ISSUE_DET.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id= BOM_ISSUE_MST.location_code/*LEFT(BOM_ISSUE_MST.issue_id,2)*//*Rohit 05-11-2024*/
	JOIN bin SourceBin on SourceBin.bin_id=BOM_ISSUE_DET.BIN_ID
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id= BOM_ISSUE_MST.location_code/*LEFT(BOM_ISSUE_MST.issue_id,2)*//*Rohit 05-11-2024*/
    LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=PAM.ac_code
	LEFT OUTER JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=PAM.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code

	 Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id= BOM_ISSUE_MST.location_code/*LEFT(BOM_ISSUE_MST.issue_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

		LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
		
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=sku_names.sku_item_type
  	WHERE BOM_ISSUE_MST.issue_dt BETWEEN [DFROMDT] AND [DTODT]  AND BOM_ISSUE_MST.cancelled=0 
	AND ISNULL(BOM_ISSUE_MST.ISSUE_TYPE,0)= 0
	 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='MIS',
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

  

 