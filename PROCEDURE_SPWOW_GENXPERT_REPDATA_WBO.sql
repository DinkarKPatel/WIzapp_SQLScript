CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_WBO
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)='',
@bCalledfromStkAnalysis BIT=0
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT,
	@cGitTable VARCHAR(200)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from BUYER_ORDER_DET (NOLOCK)       
	JOIN BUYER_ORDER_MST (NOLOCK) ON BUYER_ORDER_MST.ORDER_ID=BUYER_ORDER_DET.ORDER_ID
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=BUYER_ORDER_MST.location_code/*left(BUYER_ORDER_MST.order_no,2)*//*Rohit 05-11-2024*/
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	
	
	LEFT JOIN location targetLocation on targetLocation.dept_id=BUYER_ORDER_MST.dept_id
	Left Outer  JOIN area  targetLocation_area on targetLocation_area.area_code=targetLocation.area_code
	Left Outer  JOIN city  targetLocation_city on targetLocation_city.city_code=targetLocation_area.city_code
	Left Outer  JOIN state  targetLocation_state on targetLocation_state.state_code=targetLocation_city.state_code



	
	
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=BUYER_ORDER_DET.product_code

    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=BUYER_ORDER_MST.dept_id   
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code

	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=BUYER_ORDER_MST.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=BUYER_ORDER_MST.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code

	JOIN bin SourceBin on SourceBin.bin_id=''000''
	LEFT JOIN para1 replaceablepara1 on replaceablepara1.para1_code=buyer_order_det.replaceable_para1_code
	LEFT JOIN season_mst on season_mst.Season_Id=buyer_order_mst.season_id
	
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=SourceLocation.dept_id

	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) ON XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=1 

  	WHERE buyer_order_mst.order_dt  BETWEEN [DFROMDT] AND [DTODT] and buyer_order_mst.cancelled=0   
	AND ISNULL(BUYER_ORDER_MST.SHORT_CLOSE,0) <> 1
	AND [WHERE]  group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='WBO',
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
