CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_APR
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)



	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.approval_return_det approval_return_det (NOLOCK)       
	JOIN  [DATABASE].dbo.approval_return_mst approval_return_mst (NOLOCK) ON approval_return_mst.MEMO_ID = approval_return_det.MEMO_ID  
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=approval_return_det.APD_PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=approval_return_mst.dept_id   
	JOIN bin SourceBin on SourceBin.bin_id=approval_return_det.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=LEFT(approval_return_mst.MEMO_ID,2)
	  Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=LEFT(approval_return_mst.MEMO_ID,2)
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=approval_return_mst.ac_code
	LEFT OUTER JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=approval_return_mst.ac_code
	LEFT OUTER JOIN area  lmparty_area on party_lmp01106.area_code=lmparty_area.area_code
	LEFT OUTER JOIN city  lmparty_city on lmparty_city.city_code=lmparty_area.city_code
	LEFT OUTER JOIN state  lmparty_state on lmparty_state.state_code=lmparty_city.state_code
	
	LEFT OUTER JOIN custdym party_custdym on party_custdym.customer_code=approval_return_mst.CUSTOMER_CODE
	LEFT OUTER JOIN area  party_area on party_custdym.area_code=party_area.area_code
	LEFT OUTER JOIN city  party_city on party_area.city_code=party_city.city_code
	LEFT OUTER JOIN state  party_state on party_city.state_code=party_state.state_code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

	Left Outer JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
	   
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=supplier_lm01106.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
	LEFT OUTER JOIN USERS ON USERS.USER_CODE= approval_return_mst.USER_CODE
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=approval_return_mst.XN_ITEM_TYPE
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=approval_return_mst.location_Code AND sku_xfp.product_code=approval_return_det.APD_PRODUCT_CODE
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=approval_return_mst.location_Code AND sku_current_xfp.product_code=approval_return_det.APD_PRODUCT_CODE
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
  	WHERE approval_return_mst.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND approval_return_mst.cancelled=0   
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='APR',
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