CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_APP
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.APD01106 APD01106 (NOLOCK)       
	JOIN  [DATABASE].dbo.APM01106 APM01106 (NOLOCK) ON APM01106.MEMO_ID = APD01106.MEMO_ID  
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=APD01106.product_code
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=APM01106.dept_id   
	JOIN bin SourceBin on SourceBin.bin_id=APD01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=LEFT(APM01106.MEMO_ID,2)

  Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=LEFT(APM01106.MEMO_ID,2)
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=APM01106.ac_code
	LEFT OUTER JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=APM01106.ac_code
	LEFT OUTER JOIN area  LMparty_area on party_lmp01106.area_code=LMparty_area.area_code
	LEFT OUTER JOIN city  LMparty_city on LMparty_city.city_code=LMparty_area.city_code
	LEFT OUTER JOIN state  LMparty_state on LMparty_state.state_code=LMparty_city.state_code	
	
	LEFT OUTER JOIN custdym party_custdym on party_custdym.customer_code=APM01106.CUSTOMER_CODE	
	LEFT OUTER JOIN area  party_area on party_custdym.area_code=party_area.area_code
	LEFT OUTER JOIN city  party_city on party_city.city_code=party_area.city_code
	LEFT OUTER JOIN state  party_state on party_state.state_code=party_city.state_code

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

	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=APM01106.XN_ITEM_TYPE
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=LEFT(APM01106.MEMO_ID,2) AND sku_xfp.product_code=APD01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=LEFT(APM01106.MEMO_ID,2) AND sku_current_xfp.product_code=APD01106.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code

	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	LEFT OUTER JOIN USERS ON USERS.USER_CODE= APM01106.USER_CODE
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id

  	WHERE APM01106.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND APM01106.cancelled=0   
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='APP',
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