CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_PRT
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.RMD01106  RMD01106 (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106  RMM01106 (NOLOCK) ON RMM01106.RM_ID = RMD01106.RM_ID    
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=RMM01106.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=RMM01106.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=RMD01106.product_code
	    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=sku_names.ac_code
	Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

		LEFT OUTER JOIN users  ON RMM01106.USER_CODE= USERS.USER_CODE

	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/ AND sku_xfp.product_code=rmd01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/ AND sku_current_xfp.product_code=rmd01106.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code

	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	JOIN bin SourceBin on SourceBin.bin_id=rmd01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=RMM01106.XN_ITEM_TYPE

	 LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= rmm01106.docprt_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=rmm01106.BROKER_AC_CODE

	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
    Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
  	WHERE rmm01106.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND rmm01106.cancelled=0  
	AND rmm01106.mode=1 AND isnull(rmm01106.dn_type,0) in(0,1, 2)  AND rmm01106.cancelled=0 
	AND ISNULL(party_lmp01106.ac_gst_no,'''')<>ISNULL(SourceLocation.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='PRT',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT

	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'[oh name]','''''')

	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	DECLARE @cOhColumnId VARCHAR(10)
	SELECT TOP 1 @cOhColumnId=column_id FROM #wow_xpert_rep_det where column_id='XNSOH' 

	if isnull(@cOhColumnId,'')=''
		RETURN
	
	DECLARE @nOhCount INT,@cOhCaption VARCHAR(20),@cBaseExprOh VARCHAR(MAX),@cOhFilter VARCHAR(400)

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.RMM01106  RMM01106 (NOLOCK)    
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=RMM01106.ac_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=RMM01106.ac_code
	Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	LEFT OUTER JOIN users  ON RMM01106.USER_CODE= USERS.USER_CODE

	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=rmm01106.location_code/*LEFT(rmd01106.rm_id,2)*//*Rohit 05-11-2024*/
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=RMM01106.XN_ITEM_TYPE

	 LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= rmm01106.docprt_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=rmm01106.BROKER_AC_CODE

	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	
  	WHERE rmm01106.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND rmm01106.cancelled=0  
	AND rmm01106.mode=1 AND isnull(rmm01106.dn_type,0) <> 2  AND rmm01106.cancelled=0 
	AND ISNULL(party_lmp01106.ac_gst_no,'''')<>ISNULL(SourceLocation.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]'

	update a SET xn_type='prtoh' FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
	WHERE b.xn_type='prtoh' AND a.xn_type='prt'

	
	SET @nOhCount=1
	WHILE @nOhCount<=2
	BEGIN
		
		SELECT @cBaseExprOh=@cBaseExpr,@cInsCols=null,@cBaseExprOutput=null
		
		
		SET @cOhCaption=(CASE WHEN @nOhCount=1 THEN 'Freight' ELSE 'Other_charges' END)

		SET @cOhFilter=' AND ISNULL(rmm01106.'+@cOhCaption+',0)<>0'

		EXEC SPWOW_GETXPERT_INSCOLS
		@cXntype='prtoh',
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@cHoLocId=@cHoLocId,
		@cBaseExprInput=@cBaseExprOh,
		@cOhFilter=@cOhFilter,
		@cInsCols=@cInsCols OUTPUT,
		@cBaseExprOutput=@cBaseExprOutput OUTPUT
		
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'[oh name]',''''+replace(@cOhCaption,'_',' ')+'''')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.cgst_amount)','sum(rmm01106.'+@cOhCaption+'_cgst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.sgst_amount)','sum(rmm01106.'+@cOhCaption+'_sgst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.igst_amount)','sum(rmm01106.'+@cOhCaption+'_igst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.xn_value_without_gst)','sum(rmm01106.'+@cOhCaption+'_taxable_value)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.xn_value_with_gst)','sum(rmm01106.'+@cOhCaption+'_taxable_value+rmm01106.'+@cOhCaption+'_cgst_amount+
				rmm01106.'+@cOhCaption+'_sgst_amount+rmm01106.'+@cOhCaption+'_igst_amount)')
		

		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'rmd01106.gst_percentage','rmm01106.'+@cOhCaption+'_gst_percentage')

		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'rmd01106.hsn_code','rmm01106.'+@cOhCaption+'_hsn_code')

		SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
					SELECT '+@cBaseExprOutput

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @nOhCount=@nOhCount+1
	END

	
	update #wow_xpert_rep_det SET xn_type='prt' WHERE xn_type='prtoh'
END