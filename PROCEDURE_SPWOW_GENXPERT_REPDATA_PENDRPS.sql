CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_PENDRPS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cInsCols VARCHAR(MAX),
	@cBaseExprOutput VARCHAR(MAX)

	
	SELECT @cBaseExpr='[LAYOUT_COLS] from [DATABASE].dbo.RPS_DET RPS_DET (NOLOCK)    
	JOIN  [DATABASE].dbo.RPS_MST  (NOLOCK) ON RPS_DET.CM_ID = RPS_MST.CM_ID        
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=RPS_MST.location_code/*LEFT(RPS_MST.cm_id,2)*//*Rohit 05-11-2024*/
	Left outer join cmm01106 (NOLOCK)  ON RPS_MST.ref_cm_id = cmm01106.cm_id 
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
    LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=RPS_MST.location_code/*LEFT(RPS_MST.cm_id,2)*//*Rohit 05-11-2024*/ AND sku_xfp.product_code=RPS_DET.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=RPS_MST.location_code/*LEFT(RPS_MST.cm_id,2)*//*Rohit 05-11-2024*/ AND sku_current_xfp.product_code=RPS_DET.product_code	
	LEFT OUTER JOIN users  ON RPS_MST.USER_CODE= USERS.USER_CODE
	left OUTER JOIN custdym party_custdym on party_custdym.customer_code=rps_mst.customer_code
	left OUTER JOIN area  party_area on party_custdym.area_code=party_area.area_code
	left OUTER JOIN city  party_city on party_city.city_code=party_area.city_code
	left OUTER JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=rps_det.product_code
	Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=RPS_MST.location_code/*LEFT(RPS_MST.cm_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code
	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=sku_names.ac_code
	Left Outer JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer  JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
	LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
	LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
	LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
	LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=1
	JOIN bin SourceBin on SourceBin.bin_id=rps_det.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=RPS_MST.location_code/*LEFT(RPS_MST.cm_id,2)*//*Rohit 05-11-2024*/
	LEFT JOIN employee employee1 (NOLOCK) ON employee1.emp_code=rps_det.emp_code
	LEFT JOIN employee employee2 (NOLOCK) ON employee2.emp_code=rps_det.emp_code1
	LEFT JOIN employee employee3 (NOLOCK) ON employee3.emp_code=rps_det.emp_code2
	Left outer Join CUST_ATTR_NAMES  (Nolock) on  CUST_ATTR_NAMES.Customer_code= party_custdym.customer_code
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
  	WHERE RPS_MST.cm_dt BETWEEN ''1900-01-01'' AND [DTODT] AND rps_mst.cancelled=0  
	AND CMM01106.CM_ID  IS NULL AND  [WHERE]       
	group by [GROUPBY]'




	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='PRPS',
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