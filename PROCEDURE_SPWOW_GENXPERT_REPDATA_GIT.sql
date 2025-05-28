CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_GIT
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)='',
@bCalledfromStkAnalysis BIT=0
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),
	@cGrpCols VARCHAR(MAX),	@cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT,
	@cGitTable VARCHAR(200),@CutOff datetime

	select @CutOff= isnull(value,'1900-01-01') from config (NOLOCK)  where config_option like '%GIT_CUT_OFF_DATE%'

	IF ISNULL(@CutOff,'1900-01-01') <= '1900-01-01'
	SET @CutOff= '1900-01-01'

	
	SELECT 'WSL'+a.inv_id memo_id,a.inv_dt xn_dt,a.inv_no xn_no,a.party_dept_id dept_id,LEFT(a.inv_id,2) sourceLocId,a.TARGET_BIN_ID bin_id,a.REMARKS as gitremarks 
	into #tmpGitProcess 
	FROM inm01106 a (NOLOCK) 
	LEFT OUTER JOIN pim01106 b (NOLOCK) ON a.inv_id=b.inv_id  AND b.cancelled=0 AND b.receipt_dt<=@dToDt AND b.receipt_dt<>''
	WHERE a.cancelled=0 AND a.inv_dt<=@dToDt and a.inv_dt > @CutOff  AND a.inv_mode=2 AND (b.mrr_id IS NULL OR b.receipt_dt>@dToDt)
		
	INSERT #tmpGitProcess (memo_id,xn_dt,xn_no,dept_id,sourceLocId,bin_id,gitremarks)
	SELECT 'PRT'+a.rm_id,rm_dt,a.rm_no,a.party_dept_id,LEFT(a.rm_id,2) sourceLocId,a.TARGET_BIN_ID bin_id,a.REMARKS 
	FROM rmm01106 a (NOLOCK) 
	LEFT OUTER JOIN cnm01106 b (NOLOCK) ON a.rm_id=b.rm_id AND b.cancelled=0 AND b.receipt_dt<=@dToDt  AND b.receipt_dt<>''
	JOIN location c (NOLOCK) ON c.dept_id=a.party_dept_id
	WHERE a.cancelled=0 AND a.rm_dt<=@dToDt and a.rm_dt > @CutOff AND a.mode=2 AND (b.rm_id IS NULL OR b.receipt_dt>@dToDt)


	select b.xn_dt,b.xn_no,b.dept_id,b.sourceLocId,b.memo_id,b.bin_id, product_code,b.gitremarks,sum(quantity) git_qty 
	into #tmpGitLocs from ind01106 a (NOLOCK) 
	JOIN #tmpGitProcess b ON a.inv_id=substring(b.memo_id,4,len(memo_id))
	WHERE left(b.memo_id,3)='WSL'
	GROUP BY b.xn_dt,b.xn_no,b.dept_id,b.sourceLocId,b.memo_id,b.bin_id, product_code,b.gitremarks
	UNION ALL
	select b.xn_dt,b.xn_no,b.dept_id,b.sourceLocId,b.memo_id,b.bin_id,product_code,b.gitremarks,sum(quantity) git_qty from rmd01106 a (NOLOCK) 
	JOIN #tmpGitProcess b ON a.rm_id=substring(b.memo_id,4,len(memo_id))
	WHERE left(b.memo_id,3)='PRT'
	GROUP BY b.xn_dt,b.xn_no,b.dept_id,b.sourceLocId,b.memo_id,b.bin_id, product_code,b.gitremarks

	SET @cGitTable='#tmpGitLocs'

	SELECT @cBaseExpr='[LAYOUT_COLS]   from '+@cGitTable+' gitlocs (NOLOCK)       
	JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=gitlocs.dept_id   
	JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

	JOIN location TargetLocation on TargetLocation.dept_id=gitlocs.sourceLocId
	JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code
	JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code
	JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code
	join SKU_NAMES (NOLOCK) ON sku_names.product_code=gitlocs.product_code

    Left Outer join BARCODEWISE_EOSS_SCHEMES_INFO EOSSSCH (NOLOCK) ON EOSSSCH.location_id=gitlocs.dept_id   
	and EOSSSCH.PRoduct_code= SKU_NAMES.Product_Code

	JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code

	JOIN bin SourceBin on SourceBin.bin_id=gitlocs.bin_id
	JOIN bin TargetBin on TargetBin.bin_id=gitlocs.bin_id
	LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id=gitlocs.dept_id AND sku_xfp.product_code=gitlocs.product_code
	LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id=gitlocs.dept_id AND sku_current_xfp.product_code=gitlocs.product_code
	left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code
	
	JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=gitlocs.dept_id

	LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	
	LEFT JOIN inm01106 (NOLOCK) ON inm01106.inv_id=substring(gitlocs.memo_id,4,len(memo_id)) AND left(gitlocs.memo_id,3)=''WSL''
	LEFT OUTER JOIN  PARCEL_MST pmst_inm (NOLOCK)  ON  pmst_inm.PARCEL_MEMO_ID= inm01106.docwsl_parcel_memo_id 

	LEFT JOIN rmm01106 (NOLOCK) ON rmm01106.rm_id=substring(gitlocs.memo_id,4,len(memo_id)) AND left(gitlocs.memo_id,3)=''PRT'' 
	LEFT OUTER JOIN  PARCEL_MST pmst_rmm (NOLOCK)  ON  pmst_rmm.PARCEL_MEMO_ID= rmm01106.docprt_parcel_memo_id 

	LEFT OUTER JOIN ANGM  ON coalesce(pmst_inm.ANGADIA_CODE,pmst_rmm.ANGADIA_CODE)= ANGM.ANGADIA_CODE
    
	LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 
	LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) ON XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=1 

	Left outer Join gst_state_mst (nolock) on gst_state_mst.gst_state_code= TargetLocation.gst_state_code
	Left outer Join gst_state_mst supplier_gst_state (nolock) on supplier_gst_state.gst_state_code= supplier_lmp01106.ac_gst_state_code
	Left outer Join gst_state_mst Location_gst_state (nolock) on Location_gst_state.gst_state_code= sourcelocation.gst_state_code
	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id




  	WHERE  [WHERE]  group by [GROUPBY]'

	EXEC SPWOW_GETXPERT_INSCOLS
	@cXntype='GIT',
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
