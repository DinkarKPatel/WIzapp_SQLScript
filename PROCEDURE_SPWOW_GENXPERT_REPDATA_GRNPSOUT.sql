CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_GRNPSOUT
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
 AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
 

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.GRN_PS_DET GRN_PS_DET (NOLOCK)       
	JOIN  [DATABASE].dbo.GRN_PS_MST GRN_PS_MST (NOLOCK) ON GRN_PS_DET.MEMO_ID = GRN_PS_MST.MEMO_ID    
	JOIN [DATABASE].dbo.PIM01106 PIM01106 (NOLOCK) ON PIM01106.MRR_ID = GRN_PS_MST.REF_CONVERTED_MRR_ID 
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=GRN_PS_DET.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=LEFT(GRN_PS_MST.memo_id,2) 
	JOIN bin SourceBin on SourceBin.bin_id=GRN_PS_DET.BIN_ID
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=LEFT(GRN_PS_MST.memo_id,2) 
	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=GRN_PS_MST.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=GRN_PS_MST.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
	LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
	LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
	LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
	LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=sku_names.sku_item_type
  	WHERE pim01106.mrr_dt BETWEEN [DFROMDT] AND [DTODT]  AND pim01106.cancelled=0 
	AND GRN_PS_DET.PRODUCT_CODE<>'''' AND pim01106.RECEIPT_DT<>''''   AND ISNULL(pim01106.PIM_MODE,0)=6  
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='GRNPSOUT',
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

  

 