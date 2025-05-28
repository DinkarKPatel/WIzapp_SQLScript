CREATE PROCEDURE SPWOW_GETXPERT_INSCOLS
@dFromDt DATETIME,
@dToDt DATETIME,
@cXntype VARCHAR(100),
@cBaseExprInput VARCHAR(MAX),
@cHoLocId VARCHAR(5),
@cLayOutColsPARA VARCHAR(MAX)='',
@cInsColsPARA VARCHAR(MAX)='',
@cXnTypeSearch VARCHAR(20)='',
@cOhFilter VARCHAR(400)='',
@cInsCols VARCHAR(MAX) OUTPUT,
@cBaseExprOutput VARCHAR(MAX) OUTPUT
AS
BEGIN
	
	DECLARE @cLayoutCols VARCHAR(MAX),@cGrpCols VARCHAR(MAX),@cXpertRepCode VARCHAR(10),@bRetainStockLayoutCols BIT,@cFromDt varchar(20),
	@cColSuffix VARCHAR(20),@cFilter VARCHAR(MAX),@cPeriodBase varchar(10),@cNumericColIdPrefix VARCHAR(5),@bComparePeriodEntry BIT,
	@bComparisonPeriodFound BIT,@nRepItemType NUMERIC(1,0),@bCalculateTotalsForXtab BIT,@cOrderColumnId VARCHAR(10),@bShowImage BIT,@cOrgXnType VARCHAR(100)
	
	SELECT TOP 1 @cXpertRepCode=xpert_rep_code,@bShowImage=ISNULL(show_image,0) FROM #wow_xpert_rep_mst
	
	SET @cOrgXnType=@cXntype
	   
	IF LEFT(@cOrgXnType,5)='STOCK'
		SET @cXntype='Stock'
	
	IF @cXnTypeSearch=''
		SELECT TOP 1 @cXntypeSearch=xn_type FROM wow_xpert_xntypes_alias WHERE xn_type_alias=(CASE WHEN RIGHT(@cXntype,2)='OH' 
		THEN SUBSTRING(@cXntype,1,len(@cXntype)-2) ELSE @cXntype END)
		
	SELECT TOP 1 @cPeriodBase=base,@bCalculateTotalsForXtab=ISNULL(calculate_totals_for_xtab,0),@bComparePeriodEntry=ISNULL(process_compare_period,0)
	FROM #tmpPeriodBase 
	WHERE ISNULL(processed,0)=0 OR ISNULL(calculate_totals_for_xtab,0)=1


	IF EXISTS (SELECT TOP 1 * FROM #tmpPeriodBase WHERE ISNULL(comparison_period_found,0)=1)
		SET @bComparisonPeriodFound=1
	ELSE
		SET @bComparisonPeriodFound=0

	SET @cNumericColIdPrefix=(CASE WHEN @cPeriodBase='YTD' THEN 'Y' WHEN @cPeriodBase='MTD' THEN 'M' ELSE 'C' END)

	SET @cOrderColumnId=''
	IF @bCalculateTotalsForXtab=1
	BEGIN
		SELECT TOP 1 @cOrderColumnId = b.order_by_column_id FROM #wow_xpert_rep_det a
		JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
		WHERE a.dimension=1

		SET @cOrderColumnId=ISNULL(@cOrderColumnId,'')
	END
	
	SET @bRetainStockLayoutCols=0
	--IF @@spid=82 AND @cXntype='PUR'
	--	select @cNumericColIdPrefix NumericColPrefix,@cBaseExprInput BaseExprInput

	IF @cXpertRepCode NOT IN ('R1','R6')
	BEGIN
		SELECT 	@cLayoutCols=COALESCE(@cLayoutCols+',','')+col_expr,
		@cInsCols=COALESCE(@cInsCols+',','')+'['+col_header+']' 
		FROM 
		(SELECT DISTINCT (CASE WHEN @bCalculateTotalsForXtab=1 AND (c.dimension=1 or a.column_id=@cOrderColumnId) THEN '''ZZZTotal'''
		WHEN (a.col_mode=2 AND LEFT(a.column_id,1)=@cNumericColIdPrefix) OR a.col_mode=1 
		THEN c.col_expr ELSE '0' END) col_expr,c.col_header FROM  wow_xpert_report_cols_expressions a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
		JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id AND c.xn_type=b.xn_type
		LEFT JOIN wow_xpert_report_cols_xntypewise d (NOLOCK) ON d.ref_column_id=b.column_id
		WHERE b.xn_type=@cXntype AND d.column_id IS NULL --AND a.column_id NOT LIKE '%ageing%'
		
		) a
		
	
		SELECT @cGrpCols=COALESCE(@cGrpCols+',','')+c.col_expr
		FROM  wow_xpert_report_cols_expressions a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
		JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id AND c.xn_type=b.xn_type
		LEFT JOIN wow_xpert_report_cols_xntypewise d (NOLOCK) ON d.ref_column_id=b.column_id
		WHERE b.xn_type=@cXntype AND a.col_mode=1 AND d.column_id IS NULL-- AND a.column_id NOT LIKE '%ageing%'
		AND (@bCalculateTotalsForXtab=0 OR (c.dimension=0 AND c.column_id<>@cOrderColumnId)) AND a.column_id<>'xnsoh'



		SELECT @cInscols=@cInsCols+',[Transaction type]',@cLayoutCols=@cLayoutCols+','''+@cXntypeSearch+''''
	END
    ELSE
	BEGIN
		IF @cOrgXntype NOT IN ('STOCK')
		BEGIN
			PRINT 'ENTER EVALUATE INSCOLS EXPRESSION FOR '+@cXnType
			SELECT 	@cLayoutCols=COALESCE(@cLayoutCols+',','')+col_expr,
				@cInsCols=COALESCE(@cInsCols+',','')+'['+col_header+']' 
				FROM 
				(SELECT DISTINCT (CASE WHEN @bCalculateTotalsForXtab=1 AND (c.dimension=1 or a.column_id=@cOrderColumnId) THEN '''ZZZTotal'''
				WHEN (a.col_mode=2 AND LEFT(a.column_id,1)=@cNumericColIdPrefix) OR a.col_mode=1 
				THEN (CASE WHEN c.column_id='C1074' THEN 'cmd01106.scheme_name' WHEN c.column_id='C1075' THEN 'cmd01106.basic_discount_percentage'
				WHEN c.column_id='C1076' THEN 'sum(cmd01106.basic_discount_amount)' ELSE c.col_expr END) ELSE '0' END) col_expr,c.col_header 
				FROM  wow_xpert_report_cols_expressions a (NOLOCK)
				JOIN wow_xpert_report_cols_xntypewise b (NOLOCK) ON a.column_id=b.column_id
				JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id
				LEFT JOIN wow_xpert_report_cols_xntypewise d (NOLOCK) ON d.ref_column_id=c.column_id
				LEFT JOIN wow_xpert_derivedcols_link l (NOLOCK) ON l.ref_column_id=c.column_id
				WHERE (b.xn_type=@cXntype or (@cXpertRepCode='R1' AND LEFT(a.column_id,1) IN ('Y','M'))) AND d.column_id IS NULL
				AND l.column_id IS NULL --AND a.column_id NOT LIKE '%ageing%'
			) a

			

		END
		ELSE IF @cOrgXnType='Stock' AND @cXpertRepCode='R6'
		BEGIN
		    
			SELECT @cLayoutCols=null,@cInsCols=null
			print 'Fetch all master paras for Eoss based Stock REport'
			SELECT 	@cLayoutCols=COALESCE(@cLayoutCols+',','')+col_expr,
			@cInsCols=COALESCE(@cInsCols+',','')+'['+col_header+']' 
			FROM 
			(SELECT DISTINCT (CASE WHEN (a.col_mode=2 AND LEFT(a.column_id,1)=@cNumericColIdPrefix) OR a.col_mode=1 
			THEN c.col_expr ELSE '0' END) col_expr,c.col_header FROM  wow_xpert_report_cols_expressions a
			JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
			JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id
			WHERE b.xn_type='stock' AND (a.col_mode=1 OR a.col_expr like '%cbs%')
			) a

			SELECT 	@cLayoutCols=COALESCE(@cLayoutCols+',','')+col_expr,
			@cInsCols=COALESCE(@cInsCols+',','')+'['+col_header+']' 
			from 
			(
			SELECT col_expr,replace(a.col_expr,'sku_names.','') col_header FROM  wow_xpert_report_cols_expressions a
			WHERE a.invmasterpara=1
			) a




			IF EXISTS (SELECT TOP 1 *  FROM #tmpStkRepMode WHERE pmtstk_mode=2) AND CONVERT(DATE,GETDATE())=@dToDt 
				SET @cLayoutCols=replace(@cLayoutCols,'cbs_qty','quantity_in_stock')


		
			SELECT @cGrpCols=COALESCE(@cGrpCols+',','')+a.col_expr FROM wow_xpert_report_cols_expressions a
			WHERE a.invmasterpara=1
		END
		ELSE
		BEGIN
			SELECT @cLayoutCols=@cLayOutColsPARA,@cInsCols=@cInsColsPARA
			SET @bRetainStockLayoutCols=1
		END
	     
		IF NOT (@cOrgXnType<>'Stock' AND @cXpertRepCode='R6') 	
			SELECT @cGrpCols=COALESCE(@cGrpCols+',','')+c.col_expr 
			FROM  wow_xpert_report_cols_expressions a
			JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
			JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id
			LEFT JOIN wow_xpert_report_cols_xntypewise d (NOLOCK) ON d.ref_column_id=c.column_id
			WHERE b.xn_type=@cXntype  AND d.column_id IS NULL
			AND a.col_mode=1 AND (@bCalculateTotalsForXtab=0 OR (c.dimension=0 AND c.column_id<>@cOrderColumnId))
			AND (@bRetainStockLayoutCols=0 OR a.column_id<>'ageing_2')
		ELSE
			SELECT @cGrpCols=COALESCE(@cGrpCols+',','')+(CASE WHEN c.column_id='C1074' THEN 'cmd01106.scheme_name' WHEN c.column_id='C1075' THEN 'cmd01106.basic_discount_percentage'
				ELSE c.col_expr END)
			FROM  wow_xpert_report_cols_expressions a
			JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
			JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id
			LEFT JOIN wow_xpert_report_cols_xntypewise d (NOLOCK) ON d.ref_column_id=c.column_id
			WHERE b.xn_type=@cXntype  AND d.column_id IS NULL
			AND a.col_mode=1 AND (@bCalculateTotalsForXtab=0 OR (c.dimension=0 AND c.column_id<>@cOrderColumnId))
			AND (@bRetainStockLayoutCols=0 OR a.column_id<>'ageing_2')
	END
	



	--if @@spid=107
	--	select 'check layout columns',@cXntype Xntype, @cOrgXnType OrgXnType, @cLayoutCols cLayoutCols,@cInsCols InsCols

	--- Need to take random image of an Item e.g. If Base for Image defining is Article+Color and User takes
	--- only Article no. in the Report , the report gives multiple records against one article because of 
	--- having multiple images for different colors..That's why applying max on this column gives a random image
	--- This is done after discussion of Kamalpreet/Pankaj with Sir as per Ticket #03-1063 for client JDS Design (Date:20-03-2023)
	IF @bShowImage=1
		SELECT @cInscols=@cInsCols+',img_id',@cLayoutCols=@cLayoutCols+',max(sku_names.barcode_img_id)'
	
	IF @bComparisonPeriodFound=1
	BEGIN
		IF @bComparePeriodEntry=1
			SELECT @cInsCols=@cInsCols+',[Period Base]',@cLayoutCols=@cLayoutCols+',''PERIOD2'''
		ELSE
			SELECT @cInsCols=@cInsCols+',[Period Base]',@cLayoutCols=@cLayoutCols+',''PERIOD1'''
	END

	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[LAYOUT_COLS]',@cLayoutCols)
	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[GROUPBY]',@cGrpCols)

	EXEC SPWOW_PROCESS_XPERT_FILTEREXPR
	@cXntype=@cXntype,
	@cFilter=@cFilter OUTPUT

	
	IF @cFilter=''
		SET @cFilter=' 1=1 '
	
	IF @cOhFilter<>''
		SET @cFilter=@cFilter+@cOhFilter
		
	IF ISNULL(@nRepItemType,0)=0
		SET @nRepItemType=1
	
	--IF @cXpertRepCode<>'R3'
	--	SET @cFilter=@cFilter+' AND ISNULL(XN_ITEM_TYPE_DESC_mst.xn_item_type,0) IN ('+(CASE WHEN @nRepItemType=1 THEN '0,1' ELSE LTRIM(RTRIM(STR(@nRepItemType))) END)+')' 
	
	IF @cOrgXnType='STOCK' 
	BEGIN
		IF EXISTS (SELECT TOP 1 *  FROM #tmpStkRepMode WHERE pmtstk_mode=2) 
			SET @cFilter=@cFilter+' AND pmt_cbs.'+(CASE WHEN @dToDt=CONVERT(DATE,GETDATE()) THEN 'quantity_in_stock' ELSE 'cbs_qty' END)+'<>0'
	END

	IF @cNumericColIdPrefix='M'
		SET @dFromDt=LTRIM(RTRIM(STR(YEAR(@dToDt))))+'-'+LTRIM(RTRIM(STR(MONTH(@dToDt))))+'-01'		
	ELSE
	IF @cNumericColIdPrefix='Y'
		SET @dFromDt=dbo.FN_GETFINYEARDATE('01'+ltrim(rtrim(str(dbo.fn_getfinyear(@dToDt)))),1)
	
	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[WHERE]',@cFilter)
	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[DFROMDT]',''''+CONVERT(VARCHAR,@dFromDt,110)+'''')
	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[DTODT]',''''+CONVERT(VARCHAR,@dToDt,110)+'''')
	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[DATABASE].','')
	SET @cBaseExprInput=REPLACE(@cBaseExprInput,'[GHOLOCATION]',''''+@cHoLocId+'''')

	SET @cBaseExprOutput=@cBaseExprInput

END