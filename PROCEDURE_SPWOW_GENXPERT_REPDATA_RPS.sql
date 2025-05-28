CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_RPS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.rps_det rps_det (NOLOCK)       
	JOIN  [DATABASE].dbo.rps_mst rps_mst (NOLOCK) ON rps_det.cm_id = rps_mst.cm_id      
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=rps_det.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id= rps_mst.location_code/*LEFT(rps_mst.cm_id,2)*//*Rohit 05-11-2024*/
	JOIN bin SourceBin on SourceBin.bin_id=rps_det.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=rps_mst.location_code/*LEFT(rps_mst.cm_id,2)*//*Rohit 05-11-2024*/

	    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=rps_mst.location_code/*LEFT(rps_mst.cm_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	LEFT OUTER JOIN custdym customer_custdym on customer_custdym.customer_code=rps_mst.customer_code
	LEFT OUTER JOIN area  customer_area on customer_custdym.area_code=customer_area.area_code
	LEFT OUTER JOIN city  customer_city on customer_city.city_code=customer_area.city_code
	LEFT OUTER JOIN state  customer_state on customer_state.state_code=customer_city.state_code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

  	WHERE rps_mst.cm_dt BETWEEN [DFROMDT] AND [DTODT]  AND rps_mst.cancelled=0 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='RPS',
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