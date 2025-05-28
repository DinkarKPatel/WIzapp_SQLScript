CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_WSL
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.IND01106 IND01106 (NOLOCK)       
	JOIN  [DATABASE].dbo.INM01106 INM01106 (NOLOCK) ON INM01106.INV_ID = IND01106.INV_ID       
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=INM01106.dept_id   
		JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=INM01106.location_code/*LEFT(inm01106.inv_id,2)*//*Rohit 05-11-2024*/ AND sku_xfp.product_code=ind01106.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=INM01106.location_code/*LEFT(inm01106.inv_id,2)*//*Rohit 05-11-2024*/ AND sku_current_xfp.product_code=ind01106.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code

	LEFT OUTER JOIN users  ON INM01106.USER_CODE= USERS.USER_CODE
	
	Left Outer JOIN location TargetLocation on TargetLocation.dept_id=inm01106.party_dept_id
	Left Outer  JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	Left Outer  JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	Left Outer  JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code
		
	JOIN lm01106 party_lm01106 on party_lm01106.ac_code=INM01106.ac_code
	Left outer JOIN Hd01106 party_Hdd on party_lm01106.head_code = party_Hdd.Head_code
	Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=INM01106.ac_code
    Left Outer 	JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
    Left Outer 	JOIN city  party_city on party_city.city_code=party_area.city_code
	Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=IND01106.product_code
	Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=INM01106.location_code/*LEFT(inm01106.inv_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	Left Outer JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
	LEFT JOIN lmv01106 shipping on  shipping.ac_code=INM01106.SHIPPING_AC_CODE
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code

	JOIN bin SourceBin on SourceBin.bin_id=IND01106.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=INM01106.location_code/*LEFT(INM01106.INV_ID,2)*//*Rohit 05-11-2024*/
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=INM01106.XN_ITEM_TYPE
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 


	LEFT JOIN employee employee1 (NOLOCK) ON employee1.emp_code=ind01106.emp_code
	LEFT JOIN employee employee2 (NOLOCK) ON employee2.emp_code=ind01106.emp_code1
	LEFT JOIN employee employee3 (NOLOCK) ON employee3.emp_code=ind01106.emp_code2
	LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= inm01106.docwsl_parcel_memo_id 
	LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE

	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=inm01106.BROKER_AC_CODE
	 Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
	  Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
	    Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= TargetLocation.gst_state_code
		Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id

  	WHERE INM01106.inv_dt BETWEEN [DFROMDT] AND [DTODT]  AND INM01106.inv_mode=1 AND INM01106.cancelled=0 AND [WHERE]       
	group by [GROUPBY]'

	
	   
	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='WSL',
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

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.INM01106 INM01106 (NOLOCK)       
		JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=INM01106.dept_id   
		JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
		JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
		JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
		LEFT OUTER JOIN users  ON INM01106.USER_CODE= USERS.USER_CODE
	
		Left Outer JOIN location TargetLocation on TargetLocation.dept_id=inm01106.party_dept_id
		Left Outer  JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
		Left Outer  JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
		Left Outer  JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code
		
		JOIN lm01106 party_lm01106 on party_lm01106.ac_code=INM01106.ac_code
		Left outer JOIN Hd01106 party_Hdd on party_lm01106.head_code = party_Hdd.Head_code
		Left Outer  JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=INM01106.ac_code
		Left Outer 	JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
		Left Outer 	JOIN city  party_city on party_city.city_code=party_area.city_code
		Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code
	
		LEFT JOIN lmv01106 shipping on  shipping.ac_code=INM01106.SHIPPING_AC_CODE
		JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=INM01106.location_code
		LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=INM01106.XN_ITEM_TYPE
	
		LEFT OUTER JOIN  PARCEL_MST  ON  PARCEL_MST.PARCEL_MEMO_ID= inm01106.docwsl_parcel_memo_id 
		LEFT OUTER JOIN ANGM  ON PARCEL_MST.ANGADIA_CODE= ANGM.ANGADIA_CODE
		LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=inm01106.BROKER_AC_CODE
		Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= party_lmp01106.ac_gst_state_code
		Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= TargetLocation.gst_state_code

  		WHERE INM01106.inv_dt BETWEEN [DFROMDT] AND [DTODT]  AND INM01106.inv_mode=1 AND INM01106.cancelled=0 AND [WHERE]       
		group by [GROUPBY]'
	
	
		update a SET xn_type='WSLOH' FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
		WHERE b.xn_type='WSLOH' AND a.xn_type='WSL'

	
		SET @nOhCount=1
		WHILE @nOhCount<=4
		BEGIN
		
			SELECT @cBaseExprOh=@cBaseExpr,@cInsCols=null,@cBaseExprOutput=null
		
		
			SET @cOhCaption=(CASE WHEN @nOhCount=1 THEN 'Freight' WHEN @nOhCount=2 THEN 'Other_charges' WHEN @nOhCount=3 THEN 'Insurance'
			ELSE 'Packing' END)

			SET @cOhFilter=' AND ISNULL(inm01106.'+@cOhCaption+',0)<>0'

			EXEC SPWOW_GETXPERT_INSCOLS
			@cXntype='WSLOH',
			@dFromDt=@dFromDt,
			@dToDt=@dToDt,
			@cHoLocId=@cHoLocId,
			@cBaseExprInput=@cBaseExprOh,
			@cOhFilter=@cOhFilter,
			@cInsCols=@cInsCols OUTPUT,
			@cBaseExprOutput=@cBaseExprOutput OUTPUT
		
			SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'[oh name]',''''+replace(@cOhCaption,'_',' ')+'''')
			SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(ind01106.cgst_amount)','sum(inm01106.'+@cOhCaption+'_cgst_amount)')
			SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(ind01106.sgst_amount)','sum(inm01106.'+@cOhCaption+'_sgst_amount)')
			SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(ind01106.igst_amount)','sum(inm01106.'+@cOhCaption+'_igst_amount)')
			SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(ind01106.xn_value_without_gst)','sum(inm01106.'+@cOhCaption+'_taxable_value)')
			SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'sum(ind01106.xn_value_with_gst)','sum(inm01106.'+@cOhCaption+'_taxable_value+inm01106.'+@cOhCaption+'_cgst_amount+
				inm01106.'+@cOhCaption+'_sgst_amount+inm01106.'+@cOhCaption+'_igst_amount)')
		
		  	SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'ind01106.gst_percentage','inm01106.'+@cOhCaption+'_gst_percentage')

					SET @cBaseExprOutput=REPLACE(@cBaseExprOutput,'ind01106.hsn_code','inm01106.'+@cOhCaption+'_hsn_code')


			SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
						SELECT '+@cBaseExprOutput

			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd

			SET @nOhCount=@nOhCount+1
		END

	
		update #wow_xpert_rep_det SET xn_type='WSL' WHERE xn_type='WSLOH'

END