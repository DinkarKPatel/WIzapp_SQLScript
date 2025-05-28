CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_SLS
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

	SELECT @cBaseExpr='[LAYOUT_COLS] from [DATABASE].dbo.CMD01106 (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106  (NOLOCK) ON cmd01106.CM_ID = cmm01106.CM_ID        
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	  JOIN state  TargetLocation_state on TargetLocation_state.state_code=SourceLocation_city.state_code
		JOIN location TargetLocation (NOLOCK) ON TargetLocation.dept_id=cmm01106.location_code/*LEFT(cmm01106.@cKeyField,2)*//*Rohit 05-11-2024*/
		JOIN city  Targetlocation_city on Targetlocation_city.city_code=SourceLocation_area.city_code
		


    LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/ AND sku_xfp.product_code=cmd01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/ AND sku_current_xfp.product_code=cmd01106.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code

	LEFT OUTER JOIN users  ON CMM01106.USER_CODE= USERS.USER_CODE
	LEFT JOIN dtm cmd_dtm(NOLOCK) ON cmd_dtm.dt_code=cmd01106.last_cmm_dt_code
	LEFT JOIN dtm cmm_dtm(NOLOCK) ON cmm_dtm.dt_code=cmm01106.dt_code

	JOIN custdym party_custdym on party_custdym.customer_code=cmm01106.customer_code
	left outer JOIN area  party_area on party_custdym.area_code=party_area.area_code
	left outer JOIN city  party_city on party_city.city_code=party_area.city_code
	left outer  JOIN gst_state_mst  party_state on party_state.gst_state_code=cmm01106.party_state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=cmd01106.product_code

	    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=sku_names.ac_code
	Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
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
	JOIN bin SourceBin on SourceBin.bin_id=cmd01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=CMM01106.LOCATION_CODE
	LEFT JOIN employee employee1 (NOLOCK) ON employee1.emp_code=cmd01106.emp_code
	LEFT JOIN employee employee2 (NOLOCK) ON employee2.emp_code=cmd01106.emp_code1
	LEFT JOIN employee employee3 (NOLOCK) ON employee3.emp_code=cmd01106.emp_code2
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	Left outer Join CUST_ATTR_NAMES  (Nolock) on  CUST_ATTR_NAMES.Customer_code= party_custdym.customer_code
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= CMM01106.party_state_code
	LEFT OUTER JOIN weekno_dates (NOLOCK) on weekno_dates.xn_year= DATEPART(year,cmm01106.cm_dt) AND weekno_dates.week_no=  DATEPART(WEEKDAY,CMM01106.CM_DT)
	  Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id '+@cAgeingSlabJoinStr+
	  

  	' WHERE cmm01106.cm_dt BETWEEN [DFROMDT] AND [DTODT] AND cmm01106.cancelled=0 AND  cmd01106.quantity>0 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='SLS',
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