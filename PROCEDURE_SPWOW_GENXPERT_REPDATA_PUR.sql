CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_PUR
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@cDateFilterCol VARCHAR(100)
	
	SET @cDateFilterCol='mrr_dt'
	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_mst WHERE xpert_rep_code='R1')
		SET @cDateFilterCol='receipt_dt'

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.PID01106 PID01106 (NOLOCK)       
	JOIN  [DATABASE].dbo.PIM01106 PIM01106 (NOLOCK) ON PIM01106.MRR_ID = PID01106.MRR_ID       
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=PIM01106.dept_id   
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.ref_converted_mrntobill_mrrid=pim01106.mrr_id   
	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=PIM01106.ac_code
	Left Outer JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=pim01106.ac_code
    Left Outer 	JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=pid01106.product_code
    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=PIM01106.dept_id   
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code
	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=pim01106.ac_code
	Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
	LEFT JOIN lm01106 oem on  oem.ac_code=pim01106.SHIPPING_FROM_AC_CODE
	JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=pim01106.ac_code
	JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code

	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=pim01106.dept_id AND sku_xfp.product_code=pid01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=pim01106.dept_id AND sku_current_xfp.product_code=pid01106.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code


	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= pim01106.docwsl_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	LEFT OUTER JOIN users  ON PIM01106.USER_CODE= USERS.USER_CODE
	LEFT OUTER JOIN Employee  ON PIM01106.emp_code= Employee.emp_code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

		LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=pim01106.BROKER_AC_CODE

	JOIN bin SourceBin on SourceBin.bin_id=pim01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pim01106.dept_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=pim01106.XN_ITEM_TYPE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 

	
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	  Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
  	WHERE pim01106.'+@cDateFilterCol+' BETWEEN [DFROMDT] AND [DTODT]  
	AND pim01106.inv_mode=1 
	AND ISNULL(supplier_lmp01106.ac_gst_no,'''')<>ISNULL(SourceLocation.loc_gst_no,'''') 
	AND pim01106.cancelled=0 AND 
	PID01106.product_code<>''''
	AND pim_conv.mrr_id IS NULL AND [WHERE]       
	group by [GROUPBY]'



	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='pur',
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

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.PIM01106 PIM01106 (NOLOCK)       
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=PIM01106.dept_id   
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.ref_converted_mrntobill_mrrid=pim01106.mrr_id   
	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=PIM01106.ac_code
	Left Outer JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=pim01106.ac_code
    Left Outer 	JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code

	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= pim01106.docwsl_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
	LEFT OUTER JOIN users  ON PIM01106.USER_CODE= USERS.USER_CODE
	LEFT OUTER JOIN Employee  ON PIM01106.emp_code= Employee.emp_code
	LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=pim01106.BROKER_AC_CODE

	JOIN bin SourceBin on SourceBin.bin_id=pim01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pim01106.dept_id
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=pim01106.XN_ITEM_TYPE
		
	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= SourceLocation.gst_state_code
	  Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id

  	WHERE pim01106.'+@cDateFilterCol+' BETWEEN [DFROMDT] AND [DTODT]  AND pim01106.inv_mode=1 AND pim01106.cancelled=0 AND 
	pim_conv.mrr_id IS NULL AND [WHERE]       
	group by [GROUPBY]'

	update a SET xn_type='PUROH' FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
	WHERE b.xn_type='PUROH' AND a.xn_type='PUR'

	
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

	
	update #wow_xpert_rep_det SET xn_type='PUR' WHERE xn_type='PUROH'
END