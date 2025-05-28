CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_GRP_PUR
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)='',
@bCalledfromStkAnalysis BIT=0
AS
BEGIN

	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT,
	@cCurLocId VARCHAR(5),@cSourceDetTable VARCHAR(200),@cSourceLocJoinstr VARCHAR(200),@cSourceDetAlias VARCHAR(20),@cXntypeSearch VARCHAR(40)

	SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'

	SELECT @cSourceDetTable=(CASE WHEN @cCurLocId=@cHoLocId THEN '.dbo.IND01106 PID01106' ELSE '.dbo.PID01106 PID01106' END),
	@cSourceLocJoinstr=(CASE WHEN @cCurLocId=@cHoLocId THEN '.inv_id=PID01106.inv_id' ELSE '.mrr_id=PID01106.mrr_id' END)


	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE]'+@cSourceDetTable+' (NOLOCK)       
	JOIN  [DATABASE].dbo.PIM01106 PIM01106 (NOLOCK) ON PIM01106'+@cSourceLocJoinstr+
	' JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=pim01106.dept_id
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=pid01106.product_code	
    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=PIM01106.Dept_ID
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code
	JOIN location TargetLocation on TargetLocation.dept_id=left(pim01106.inv_id,2)
	JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code

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



	JOIN bin SourceBin on SourceBin.bin_id=pim01106.bin_id
	JOIN bin TargetBin on TargetBin.bin_id=pim01106.bin_id

	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pim01106.dept_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=pim01106.XN_ITEM_TYPE
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=pim01106.dept_id AND sku_xfp.product_code=pid01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=pim01106.dept_id AND sku_current_xfp.product_code=pid01106.product_code
  	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code


	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= pim01106.docwsl_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 

	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= TargetLocation.gst_state_code
    Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
    Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
	LEFT OUTER JOIN USERS ON USERS.USER_CODE= PIM01106.USER_CODE
	WHERE pim01106.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND 
	pim01106.inv_mode=2  AND pim01106.cancelled=0 
	AND [WHERE]       
	group by [GROUPBY]'
		
	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='GRP_PUR',
	@dFromDt=@dFromDt,
	@dToDt=@dToDt,
	@cHoLocId=@cHoLocId,
	@cBaseExprInput=@cBaseExpr,
	@cInsCols=@cInsCols OUTPUT,
	@cBaseExprOutput=@cBaseExprOutput OUTPUT

	--- Special case because data of Group Purchase is being fetched from ind01106 instead of pid01106
	--- in case of Reporting is done from Head office..
	IF @cCurLocId=@cHoLocId
	BEGIN
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'pimdiscountamount','inmdiscountamount')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'pid01106.Gross_purchase_price','pid01106.rate')
    END


	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'[oh name]','''''')
	SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
				SELECT '+@cBaseExprOutput

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	--- Special case where Client is making Direct purchase from a Party having same gst no. as that of Location

	
	SELECT @cSourceDetTable='.dbo.PID01106 PID01106',@cSourceLocJoinstr='.mrr_id=PID01106.mrr_id'

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE]'+@cSourceDetTable+' (NOLOCK)       
	JOIN  [DATABASE].dbo.PIM01106 PIM01106 (NOLOCK) ON PIM01106'+@cSourceLocJoinstr+
	' JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=pim01106.dept_id
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=pid01106.product_code	
    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=PIM01106.Dept_ID
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code
	LEFT JOIN location TargetLocation on TargetLocation.dept_id=PIM01106.DEPT_ID
	LEFT JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	LEFT JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	LEFT JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code

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



	JOIN bin SourceBin on SourceBin.bin_id=pim01106.bin_id
	JOIN bin TargetBin on TargetBin.bin_id=pim01106.bin_id

	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pim01106.dept_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=pim01106.XN_ITEM_TYPE
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=pim01106.dept_id AND sku_xfp.product_code=pid01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=pim01106.dept_id AND sku_current_xfp.product_code=pid01106.product_code
  	

	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= pim01106.docwsl_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 

		Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= TargetLocation.gst_state_code
    Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	  Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id   
	  	LEFT OUTER JOIN USERS ON USERS.USER_CODE= PIM01106.USER_CODE
	WHERE pim01106.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND 
	(pim01106.inv_mode=1 AND ISNULL(supplier_lmp01106.ac_gst_no,'''')=ISNULL(SourceLocation.loc_gst_no,'''')  )  AND pim01106.cancelled=0 
	AND [WHERE]       
	group by [GROUPBY]'
	
	SET @cInsCols=null

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='GRP_PUR',
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
	
	SELECT TOP 1 @cXntypeSearch=xn_type FROM wow_xpert_xntypes_alias WHERE xn_type_alias='grp_pur'

	DECLARE @nOhCount INT,@cOhCaption VARCHAR(20),@cBaseExprOh VARCHAR(MAX),@cOhFilter VARCHAR(400)
	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.PIM01106 PIM01106 (NOLOCK)   
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=pim01106.dept_id
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	
	JOIN location TargetLocation on TargetLocation.dept_id=left(pim01106.inv_id,2)
	JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code
	   	  
	JOIN bin SourceBin on SourceBin.bin_id=pim01106.bin_id
	JOIN bin TargetBin on TargetBin.bin_id=pim01106.bin_id

	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pim01106.dept_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=pim01106.XN_ITEM_TYPE
	
	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= pim01106.docwsl_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= TargetLocation.gst_state_code
    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
    Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
	LEFT OUTER JOIN USERS ON USERS.USER_CODE= PIM01106.USER_CODE
	WHERE pim01106.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND 
	pim01106.inv_mode=2  AND pim01106.cancelled=0 
	AND [WHERE]       
	group by [GROUPBY]'

	update a SET xn_type='PUROH' FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
	WHERE b.xn_type='PUROH' AND a.xn_type='GRP_PUR'

	
	SET @nOhCount=1
	WHILE @nOhCount<=2
	BEGIN
		
		SELECT @cBaseExprOh=@cBaseExpr,@cInsCols=null,@cBaseExprOutput=null
				
		SET @cOhCaption=(CASE WHEN @nOhCount=1 THEN 'Freight' ELSE 'Other_charges' END)

		SET @cOhFilter=' AND ISNULL(pim01106.'+@cOhCaption+',0)<>0'

		EXEC SPWOW_GETXPERT_INSCOLS
		@cXntype='PUROH',
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@cHoLocId=@cHoLocId,
		@cBaseExprInput=@cBaseExprOh,
		@cOhFilter=@cOhFilter,
		@cXntypeSearch=@cXntypeSearch,
		@cInsCols=@cInsCols OUTPUT,
		@cBaseExprOutput=@cBaseExprOutput OUTPUT
		
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'[oh name]',''''+replace(@cOhCaption,'_',' ')+'''')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(pid01106.cgst_amount)','sum(pim01106.'+@cOhCaption+'_cgst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(pid01106.sgst_amount)','sum(pim01106.'+@cOhCaption+'_sgst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(pid01106.igst_amount)','sum(pim01106.'+@cOhCaption+'_igst_amount)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(pid01106.xn_value_without_gst)','sum(pim01106.'+@cOhCaption+'_taxable_value)')
		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(pid01106.xn_value_with_gst)','sum(pim01106.'+@cOhCaption+'_taxable_value+pim01106.'+@cOhCaption+'_cgst_amount+
						pim01106.'+@cOhCaption+'_sgst_amount+pim01106.'+@cOhCaption+'_igst_amount)')
		

		SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'pid01106.gst_percentage','pim01106.'+@cOhCaption+'_gst_percentage')
				SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'pid01106.hsn_code','pim01106.'+@cOhCaption+'_hsn_code')


		SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
					SELECT '+@cBaseExprOutput

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @nOhCount=@nOhCount+1
	END

	
	update #wow_xpert_rep_det SET xn_type='GRP_PUR' WHERE xn_type='PUROH'
END