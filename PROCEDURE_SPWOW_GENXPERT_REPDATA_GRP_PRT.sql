CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_GRP_PRT --(lOC 3 DIGIT CHANGE BY sANJAY :22-11-2024 (LEFT CHANGES OF LEFT(rm_ID,2) BY OTHER DEVELOPER)
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)='',
@bCalledfromStkAnalysis BIT=0
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT,@cXntypeSearch VARCHAR(40)

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.RMD01106  RMD01106 (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106  RMM01106 (NOLOCK) ON RMM01106.RM_ID = RMD01106.RM_ID    
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=RMM01106.location_code
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	JOIN location TargetLocation on TargetLocation.dept_id=rmm01106.party_dept_id
	JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code
	
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=RMD01106.product_code
	left join CNM01106 cim (NOLOCK) ON cim.rm_id=rmm01106.rm_id and cim.CANCELLED =0

	 Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=rmm01106.party_dept_id
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	
	JOIN bin SourceBin on SourceBin.bin_id=rmd01106.bin_id
	JOIN bin TargetBin on TargetBin.bin_id=rmM01106.target_bin_id
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=RMM01106.location_code AND sku_xfp.product_code=rmd01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=RMM01106.location_code AND sku_current_xfp.product_code=rmd01106.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code

	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=RMM01106.location_code
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=RMM01106.XN_ITEM_TYPE
	 LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= rmm01106.docprt_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= TargetLocation.gst_state_code
    Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
  	WHERE rmm01106.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND rmm01106.cancelled=0  
	AND rmm01106.mode=2 AND rmm01106.cancelled=0 AND [WHERE]    
	group by [GROUPBY]'

	SET @cXnType=(CASE WHEN @bCalledfromStkAnalysis=1 THEN 'STOCK' ELSE 'GRP_PRT' END)

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='GRP_PRT',
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
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=RMM01106.location_code
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	JOIN location TargetLocation on TargetLocation.dept_id=rmm01106.party_dept_id
	JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code
	
	left join CNM01106 cim (NOLOCK) ON cim.rm_id=rmm01106.rm_id
	
	JOIN bin TargetBin on TargetBin.bin_id=rmM01106.target_bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=RMM01106.location_code
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=RMM01106.XN_ITEM_TYPE
	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= rmm01106.docprt_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= TargetLocation.gst_state_code
    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
  	WHERE rmm01106.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND rmm01106.cancelled=0  
	AND rmm01106.mode=2 AND rmm01106.cancelled=0 AND [WHERE]    
	group by [GROUPBY]'

	update a SET xn_type='prtoh' FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
	WHERE b.xn_type='prtoh' AND a.xn_type='grp_prt'

	
	SELECT TOP 1 @cXntypeSearch=xn_type FROM wow_xpert_xntypes_alias WHERE xn_type_alias='grp_prt'
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
		@cXntypeSearch=@cXntypeSearch,
		@cInsCols=@cInsCols OUTPUT,
		@cBaseExprOutput=@cBaseExprOutput OUTPUT
		
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'[oh name]',''''+replace(@cOhCaption,'_',' ')+'''')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.cgst_amount)','sum(rmm01106.'+@cOhCaption+'_cgst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.sgst_amount)','sum(rmm01106.'+@cOhCaption+'_sgst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.igst_amount)','sum(rmm01106.'+@cOhCaption+'_igst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.xn_value_without_gst)','sum(rmm01106.'+@cOhCaption+'_taxable_value)')
		SET  @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(rmd01106.xn_value_with_gst)','sum(rmm01106.'+@cOhCaption+'_taxable_value+rmm01106.'+@cOhCaption+'_cgst_amount+
				rmm01106.'+@cOhCaption+'_sgst_amount+rmm01106.'+@cOhCaption+'_igst_amount)')
		

		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'rmd01106.gst_percentage','rmm01106.'+@cOhCaption+'_gst_percentage')

	   SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'rmd01106.hsn_code','rmm01106.'+@cOhCaption+'_hsn_code')


		SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
					SELECT '+@cBaseExprOutput

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @nOhCount=@nOhCount+1
	END

	
	update #wow_xpert_rep_det SET xn_type='grp_prt' WHERE xn_type='prtoh'
END