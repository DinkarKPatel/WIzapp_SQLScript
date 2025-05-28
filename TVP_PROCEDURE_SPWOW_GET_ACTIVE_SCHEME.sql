CREATE PROCEDURE SPWOW_GET_ACTIVE_SCHEME
(
 @dXnDt datetime='',
 @cLocId varchar(5)=''/*Rohit 01-11-2024*/,
 @bCalledForFlatDiscount BIT=0,
 @tblActiveSchemes tvpActiveBarCodeschemes readonly,
 @tblBarCodes tvpBarCodes readonly,
 @nQueryId INT=1
)
AS
BEGIN
	--declare @dXnDt datetime='2023-04-18',@cLocId char(2)='01'


IF @nQueryId=1
	GOTO lblActiveTitles
ELSE
IF @nQueryId=2
	GOTO lblBarcodeBaseTitles

lblActiveTitles:

	declare @cCurLocId VARCHAR(4),@cHoLocId VARCHAR(4)

	SELECT distinct isnull(memoProcessingOrder,0) memoProcessingOrder,isnull(titleProcessingOrder,0) titleProcessingOrder, a.schemeRowId ,a.buyFilterRepId,
	a.buyFilterCriteria, a.getFilterCriteria,a.getFilterRepId,buyFilterCriteria_exclusion,
	a.buyFilterMode, a.getFilterMode,a.schemeName,isnull(a.schemebuyType,0) buytype,
	a.schemeMode,CONVERT(BIT,(CASE WHEN a.schemeMode=1 AND a.buyFilterMode=2 
	THEN 1 ELSE 0 END)) barcodewise_flat_scheme ,a.incrementalScheme,isnull(donot_distribute_weighted_avg_disc_bngn,0) donot_distribute_weighted_avg_disc_bngn,
	a.setTotalQty,isnull(a.wizclip_based_scheme,0) wizclip_based_scheme,isnull(schemeApplicableLevel,1) schemeApplicableLevel,
	isnull(a.addnlGetFilterCriteria,'') addnlGetFilterCriteria,weekday_wise_applicable,a.applicable_on_friday,a.applicable_on_monday,a.applicable_on_tuesday,
	a.applicable_on_wednesday,a.applicable_on_thursday,a.applicable_on_saturday,a.applicable_on_sunday,l.applicableFromDt,l.applicableToDt,a.happy_hours_applicable
	into #tActiveTitles
	from wow_SchemeSetup_Title_Det a  (NOLOCK)
	JOIN wow_SchemeSetup_mst b  (NOLOCK) ON a.setupId=b.setupId
	LEFT JOIN wow_SchemeSetup_locs l (NOLOCK) ON l.schemeRowId=a.schemeRowId AND l.locationId=@cLocId
	LEFT JOIN wow_schemesetup_happyhours hh (NOLOCK) ON hh.schemerowid=a.schemerowid
	WHERE (@dXnDt BETWEEN l.applicableFromDt AND l.applicableToDt OR @dXnDt='') AND (b.locApplicableMode=1  OR l.schemeRowId IS NOT NULL) 
	AND ISNULL(a.inactive,0)=0
	AND NOT (a.schemeMode=2 AND a.buyFilterMode=2) 
	
	


	
	IF EXISTS (SELECT TOP 1 * FROM #tActiveTitles WHERE ISNULL(weekday_wise_applicable,0)=1)
	BEGIN
		DELETE FROM #tActiveTitles WHERE ISNULL(weekday_wise_applicable,0)=1 AND ((DateName(w,@dXnDt)='Sunday' and isnull(applicable_on_sunday,0)=0) OR
		(DateName(w,@dXnDt)='Monday' and isnull(applicable_on_monday,0)=0) OR (DateName(w,@dXnDt)='Tuesday' and isnull(applicable_on_tuesday,0)=0) OR
		(DateName(w,@dXnDt)='Wednesday' and isnull(applicable_on_wednesday,0)=0) OR (DateName(w,@dXnDt)='Thursday' and isnull(applicable_on_thursday,0)=0) OR
		(DateName(w,@dXnDt)='Friday' and isnull(applicable_on_friday,0)=0) OR (DateName(w,@dXnDt)='Saturday' and isnull(applicable_on_saturday,0)=0)) 
	END

	select * from #tActiveTitles  ORDER BY titleProcessingOrder DESC
	--for json path

	SELECT DISTINCT a.schemeRowId,getQty,buyFromRange,buyToRange,discountPercentage,discountAmount,netPrice,rowId,
	addnlgetQty,addnldiscountPercentage,addnldiscountAmount,a.schemegetType getType,happy_hours_applicable from wow_SchemeSetup_slabs_Det a  (NOLOCK)
	JOIN #tActiveTitles b ON b.schemeRowId=a.schemeRowId
	--for json path

	select a.schemeRowId,section_name,sub_Section_name,article_no,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
	a.discountPercentage flat_discountPercentage,a.discountAmount flat_discountAmount,a.netPrice flat_netPrice,
	convert(bit,0) buybc,convert(bit,0) getbc,0 targettype,happy_hours_applicable from wow_SchemeSetup_para_combination_flat a
	JOIN #tActiveTitles b ON a.schemeRowId=b.schemeRowId
	UNION ALL
	select a.schemeRowId,section_name,sub_Section_name,article_no,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
	0 flat_discountPercentage,0 flat_discountAmount,0 flat_netPrice,
	convert(bit,1) buybc,convert(bit,0) getbc,0 targettype,happy_hours_applicable from wow_SchemeSetup_para_combination_buy a
	JOIN #tActiveTitles b ON a.schemeRowId=b.schemeRowId
	UNION ALL
	select a.schemeRowId,section_name,sub_Section_name,article_no,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
	0 flat_discountPercentage,0 flat_discountAmount,0 flat_netPrice,
	convert(bit,0) buybc,convert(bit,1) getbc,targettype,happy_hours_applicable from wow_SchemeSetup_para_combination_get a
	JOIN #tActiveTitles b ON a.schemeRowId=b.schemeRowId

	SELECT a.*,happy_hours_applicable FROM wow_SchemeSetup_para_combination_config a
	JOIN #tActiveTitles b ON a.schemeRowId=b.schemeRowId
	
	SELECT a.product_code,a.schemeRowId,convert(bit,1) flatdiscount,convert(bit,0) buybc,convert(bit,0) getbc,
	a.discountPercentage flat_discountPercentage,a.discountAmount flat_discountAmount,
	a.netPrice flat_netprice,0 flat_addnl_discountpercentage,
	convert(int,0) schemeMode,convert(bit,0) getbcAddnl
	from wow_SchemeSetup_slsbc_flat a (NOLOCK)
	JOIN wow_SchemeSetup_slabs_Det c (NOLOCK) ON c.schemeRowId=a.schemeRowId
	WHERE 1=2
	
	SELECT a.schemerowId,from_time,to_time from  wow_schemesetup_happyhours a 
	JOIN #tActiveTitles b ON a.schemeRowId=b.schemeRowId
	UNION ALL
	SELECT a.schemerowId,from_time,to_time from  wow_schemesetup_happyhours a 
	JOIN wow_schemesetup_locs b ON a.schemeRowId=b.schemeRowId
	where b.locationId=@cLocId AND @dXnDt BETWEEN b.applicableFromDt AND b.applicableToDt

	GOTO lblLast

lblBarcodeBaseTitles:

	
	IF @bCalledForFlatDiscount=1
	BEGIN
		SELECT a.product_code,a.schemeRowId,b.schemeName,
		a.discountPercentage flat_discountPercentage,a.discountAmount flat_discountAmount,a.netPrice flat_netprice,
		0 flat_addnl_discountpercentage
		from wow_SchemeSetup_slsbc_flat a (NOLOCK)
		JOIN wow_SchemeSetup_Title_Det b (NOLOCK) ON a.schemeRowId=b.schemeRowId
		JOIN @tblBarCodes d ON d.product_Code=a.product_Code
		JOIN @tblActiveSchemes e on e.schemeRowId=a.schemeRowId
	END
	ELSE
	BEGIN

	
		SELECT product_code,schemeRowId,convert(bit,0) flatdiscount,max((case when buybc=1 THEN 1 ELSE 0 END)) buybc,
		max((case when getbc=1 THEN 1 ELSE 0 END)) getbc,0 flat_discountPercentage,0 flat_discountAmount,0 flat_netprice,0 flat_addnl_discountpercentage,
		convert(int,0) schemeMode,0 getbcAddnl
		FROM 
		(
		SELECT d.product_code,a.schemeRowId,convert(bit,1) buybc,convert(bit,0) getbc,convert(bit,0) getbcAddnl
		from wow_SchemeSetup_slsbc_buy a (NOLOCK)
		JOIN @tblActiveSchemes b ON a.schemeRowId=b.schemeRowId
		JOIN wow_SchemeSetup_slabs_Det c (NOLOCK) ON c.schemeRowId=a.schemeRowId
		JOIN wow_schemesetup_title_det t (NOLOCK) ON t.schemeRowId=a.schemeRowId
		JOIN @tblBarCodes d ON LEFT(d.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',d.PRODUCT_CODE)-1,-1),LEN(d.PRODUCT_CODE )))=a.product_code
		WHERE buyFilterMode=2 

		UNION ALL
		SELECT d.product_code,a.schemeRowId,convert(bit,0) buybc,convert(bit,(case when isnull(targetType,0)<>2 then 1 else 0 end)) getbc,
		convert(bit,(case when isnull(targetType,0)=2 then 1 else 0 end)) getbcAddnl
		from wow_SchemeSetup_slsbc_get a (NOLOCK)
		JOIN @tblActiveSchemes b ON a.schemeRowId=b.schemeRowId
		JOIN wow_SchemeSetup_slabs_Det c (NOLOCK) ON c.schemeRowId=a.schemeRowId
		JOIN wow_schemesetup_title_det t (NOLOCK) ON t.schemeRowId=a.schemeRowId
		JOIN @tblBarCodes d ON LEFT(d.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',d.PRODUCT_CODE)-1,-1),LEN(d.PRODUCT_CODE )))=a.product_code
		WHERE getFilterMode=2 
		) a 
		GROUP BY product_code,schemeRowId
	END

	GOTO lblLast

lblLast:

END
