CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_TTM
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
 AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
 

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.TRANSFER_TO_TRADING_DET  (NOLOCK)       
	JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_mst (NOLOCK) ON TRANSFER_TO_TRADING_DET.MEMO_ID = TRANSFER_TO_TRADING_mst.MEMO_ID      	
   	 join SKU_NAMES (NOLOCK) ON sku_names.product_code=TRANSFER_TO_TRADING_DET.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id= TRANSFER_TO_TRADING_mst.location_code/*LEFT(TRANSFER_TO_TRADING_mst.MEMO_ID,2)*//*Rohit 05-11-2024*/
	JOIN bin SourceBin on SourceBin.bin_id=''000''
	  Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=TRANSFER_TO_TRADING_mst.location_code/*LEFT(TRANSFER_TO_TRADING_mst.MEMO_ID,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=TRANSFER_TO_TRADING_mst.location_code/*LEFT(TRANSFER_TO_TRADING_mst.MEMO_ID,2)*//*Rohit 05-11-2024*/
    LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=sku_names.ac_code
	LEFT OUTER JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=sku_names.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code


	   LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

		LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 

	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=sku_names.sku_item_type
  	WHERE TRANSFER_TO_TRADING_mst.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND TRANSFER_TO_TRADING_mst.cancelled=0 
	AND TRANSFER_TO_TRADING_det.PRODUCT_CODE <> ''''
	 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='TTM',
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

  

 