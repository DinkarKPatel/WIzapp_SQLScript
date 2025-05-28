CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_CONSLS
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cInsCols VARCHAR(MAX),
	@cBaseExprOutput VARCHAR(MAX)
	
	DECLARE @cAgeingSlabJoinStr VARCHAR(1500),@cAgeColExpr VARCHAR(200)
	SET @cAgeingSlabJoinStr=''

	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det WHERE column_id='ageing_2')
	BEGIN
		SELECT TOP 1 @cAgeColExpr=REPLACE(col_expr,'[todate]',''''+convert(varchar,@dToDt,112)+'''') FROM wow_xpert_report_cols_expressions (NOLOCK) WHERE column_id='C0236'
		SET @cAgeColExpr=REPLACE(@cAgeColExpr,'avg(','(')

		SET @cAgeingSlabJoinStr=' LEFT JOIN #tmpAgeSlabs saleAgeSlabs ON '+@cAgeColExpr+' BETWEEN saleAgeSlabs.fromDays and saleAgeSlabs.toDays'
	END

	SELECT @cBaseExpr='[LAYOUT_COLS] from [DATABASE].dbo.CMD_CONS CMD_CONS (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106 CMM01106 (NOLOCK) ON CMD_CONS.CM_ID = cmm01106.CM_ID  	
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	   
	LEFT OUTER JOIN users  ON CMM01106.USER_CODE= USERS.USER_CODE	
	JOIN custdym party_custdym on party_custdym.customer_code=cmm01106.customer_code
	JOIN area  party_area on party_custdym.area_code=party_area.area_code
	JOIN city  party_city on party_city.city_code=party_area.city_code
	JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=cmd_cons.product_code

	Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=CMM01106.location_code AND sku_xfp.product_code=CMD_CONS.PRODUCT_CODE
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code
	

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
	JOIN bin SourceBin on SourceBin.bin_id=''000''
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=cmm01106.location_code	
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	Left outer Join CUST_ATTR_NAMES  (Nolock) on  CUST_ATTR_NAMES.Customer_code= party_custdym.customer_code
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= CMM01106.party_state_code
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id '+@cAgeingSlabJoinStr+	' 
	WHERE cmm01106.cm_dt BETWEEN [DFROMDT] AND [DTODT] AND cmm01106.cancelled=0 AND  [WHERE]       
	group by [GROUPBY]'



	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='CON_SLS',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT

	print 'Anil '+ isnull(@cBaseExprOutput,'')

	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

    Select  @cBaseExpr= null ,@cInsCols=NULL,@cBaseExprOutput=null


	SELECT @cBaseExpr='[LAYOUT_COLS] from [DATABASE].dbo.sls_delivery_cons CMD_CONS (NOLOCK)    
	JOIN  [DATABASE].dbo.sls_delivery_mst CMM01106 (NOLOCK) ON CMD_CONS.memo_id = cmm01106.memo_id  
	
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

   
	LEFT OUTER JOIN users  ON USERS.USER_CODE= ''0000000''
	
	JOIN custdym party_custdym on party_custdym.customer_code=cmm01106.customer_code
	JOIN area  party_area on party_custdym.area_code=party_area.area_code
	JOIN city  party_city on party_city.city_code=party_area.city_code
	JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=cmd_cons.product_code

	Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
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
	JOIN bin SourceBin on SourceBin.bin_id=cmm01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=cmm01106.location_code	
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	Left outer Join CUST_ATTR_NAMES  (Nolock) on  CUST_ATTR_NAMES.Customer_code= party_custdym.customer_code
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id '+@cAgeingSlabJoinStr+	' 
	WHERE cmm01106.memo_dt BETWEEN [DFROMDT] AND [DTODT] AND cmm01106.cancelled=0  AND [WHERE]       
	group by [GROUPBY]'



	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='CON_SLS',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT

	print 'Anil 2 '+ isnull(@cBaseExprOutput,'')

	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd





END