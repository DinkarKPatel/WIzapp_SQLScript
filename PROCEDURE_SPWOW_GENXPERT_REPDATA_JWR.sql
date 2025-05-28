CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_JWR
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)=''
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX)
	

	SELECT @cBaseExpr='[LAYOUT_COLS]   from [DATABASE].dbo.jobwork_receipt_det jobwork_receipt_det (NOLOCK)       
	JOIN  [DATABASE].dbo.jobwork_receipt_mst jobwork_receipt_mst (NOLOCK) ON jobwork_receipt_det.receipt_id = jobwork_receipt_mst.receipt_id      
	JOIN  [DATABASE].dbo.prd_agency_mst PAM (NOLOCK) ON jobwork_receipt_mst.agency_code = PAM.agency_code   
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=jobwork_receipt_det.PRODUCT_CODE
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=  jobwork_receipt_mst.location_code/*LEFT(jobwork_receipt_mst.receipt_id,2)*//*Rohit 05-11-2024*/
	JOIN bin SourceBin on SourceBin.bin_id=jobwork_receipt_det.bin_id
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=jobwork_receipt_mst.location_code/*LEFT(jobwork_receipt_mst.receipt_id,2)*//*Rohit 05-11-2024*/

	Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=jobwork_receipt_mst.location_code/*LEFT(jobwork_receipt_mst.receipt_id,2)*//*Rohit 05-11-2024*/
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=PAM.ac_code
	LEFT OUTER JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=PAM.ac_code
	LEFT OUTER JOIN area  party_area on party_lmp01106.area_code=party_area.area_code
	LEFT OUTER JOIN city  party_city on party_city.city_code=party_area.city_code
	LEFT OUTER JOIN state  party_state on party_state.state_code=party_city.state_code


	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code

		LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 


		JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code	
	JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=supplier_lm01106.ac_code
	JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code



	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=1
	JOIN JOBWORK_ISSUE_DET jwidet (NOLOCK) ON jwidet.ROW_ID=jobwork_receipt_det.REF_ROW_ID    
    JOIN JOBWORK_ISSUE_MST jwimst (NOLOCK) ON jwimst.ISSUE_ID = jwidet.ISSUE_ID  
  	WHERE jobwork_receipt_mst.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND jobwork_receipt_mst.cancelled=0 
	AND jwimst.ISSUE_TYPE=1  	 AND isnull(jwimst.WIP,0)=0 AND jwimst.ISSUE_TYPE=1 
	AND ISNULL(SKU_NAMES.sku_ITEM_TYPE,0) IN(0,1) AND ISNULL(non_receivable,0)=0 
	--AND ISNULL(jwimst.ISSUE_MODE,0)<>1 
	 AND [WHERE]       
	group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='JWR',
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