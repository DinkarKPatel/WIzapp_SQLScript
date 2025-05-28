CREATE PROCEDURE SP3S_XPERTREPORT_GETCOLSEXPR
@cRepId CHAR(10),
@cRepType VARCHAR(20)='',
@cXnType VARCHAR(100),
@cFilterRepId CHAR(10),
@cXpertrepCode VARCHAR(5),
@bMtdXntype BIT=0,
@bYtdXntype BIT=0,
@cInputFilter VARCHAR(MAX),
@cInsCols VARCHAR(MAX) output,
@cLayoutCols VARCHAR(MAX) output,
@cGrpCols VARCHAR(MAX) OUTPUT,
@cJoinStr VARCHAR(MAX) output,
@cOutputFilter VARCHAR(MAX) OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	
	DECLARE @cMstCols VARCHAR(2000),@cCalcCols VARCHAR(2000),@cStep VARCHAR(10),@cColName varchar(500),@cJoiningTableAlias VARCHAR(50),
	@cJoiningTable varchar(200),@cJoiningCol VARCHAR(200),@cKeyField VARCHAR(200),@bLayOutCol BIT,@cColExpr VARCHAR(200),
	@cJoinExpr VARCHAR(400),@cColHeader VARCHAR(200),@cBoPcCol VARCHAR(100),@cBoXntype VARCHAR(100),@cSearchCol VARCHAR(50),
	@cAddnlJoin VARCHAR(1000),@bXnhistory bit,@cColNameLocId VARCHAR(50)

BEGIN TRY	

	SET @cStep='10'
	SELECT @cJoinStr='',@cErrormsg='',@cGrpCols='',@cBoXntype=''	


	print 'enter getcolsexpr for'+@cXntype

	IF @cXpertrepCode<>'R1'
		SELECT @cInsCols='[transaction type]',@cLayoutCols=''''+@cXnType+''''
	ELSE
		SELECT @cInsCols=NULL,@cLayoutCols=NULL

	SELECT @bXnhistory=xn_history FROM #rep_mst

	IF @cXnType='Buyer Order Pendency'
	BEGIN
		SET @cStep='12'
		SELECT TOP 1 @cBoPcCol=column_name FROM config_buyerorder (NOLOCK) WHERE open_key=1
		AND column_name='product_code'

		IF ISNULL(@cBoPcCol,'')=''
			SET @cBoXntype='OrdWoSku'
	END

	SET @cStep='14.3'
	SELECT DISTINCT a.col_expr as colname,joining_table,joining_column,keyfield,a.col_header,joining_table_alias,addnl_join
	into #tmpLayoutCols  
	FROM transaction_analysis_MASTER_COLS a (NOLOCK)
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	WHERE (a.xn_type IN (REPLACE(@cXnType,'(oh)',''))) AND a.col_expr<>'xn_type' and a.rep_type=@cRepType
	AND (a.joining_table<>'sku_names' OR RIGHT(@cXnType,4)<>'(oh)' )
	AND NOT (a.COL_HEADER='Item Code' AND RIGHT(@cXnType,4)='(oh)')
	
	INSERT #tmpLayoutCols (colname,joining_table,joining_column,keyfield,col_header,joining_table_alias,addnl_join)
	select DISTINCT a.col_expr as colname,a.joining_table,a.joining_column,a.keyfield,a.col_header,
	a.joining_table_alias,a.addnl_join
	FROM transaction_analysis_MASTER_COLS a (NOLOCK)
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	left join #tmpLayoutCols c on c.COL_HEADER=a.COL_HEADER
	WHERE a.xn_type IN ('common') AND a.col_expr<>'xn_type' and c.COL_HEADER IS NULL
	and a.rep_type=@cRepType
	AND (a.joining_table<>'sku_names' OR RIGHT(@cXnType,4)<>'(oh)') 
	AND NOT (a.COL_HEADER='Item Code' AND RIGHT(@cXnType,4)='(oh)')


	--select  DISTINCT 'check cols for purchase', (CASE WHEN a.xn_type<>@cXnType THEN '0' else  a.col_expr END) as colname,a.col_header
	--FROM transaction_analysis_calculative_COLS a (NOLOCK)
	--JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	--left join #tmpLayoutCols c on c.COL_HEADER=a.COL_HEADER
	--WHERE (a.xn_type IN (@cXnType) OR @cXpertrepCode='R1')  AND a.col_expr<>'xn_type' AND left(a.col_expr,2)<>'OH' 
	--and a.col_expr NOT LIKE '%SUM(%' and a.col_expr NOT LIKE '%AVG(%' AND c.COL_HEADER IS NULL 
	--and a.rep_type=@cRepType
	
	INSERT #tmpLayoutCols (colname,col_header)
	select DISTINCT a.col_expr as colname,a.col_header
	FROM transaction_analysis_calculative_COLS a (NOLOCK)
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	left join #tmpLayoutCols c on c.COL_HEADER=a.COL_HEADER
	WHERE (a.xn_type IN (@cXnType) OR @cXpertrepCode='R1')  AND a.col_expr<>'xn_type' AND left(a.col_expr,2)<>'OH' 
	and a.col_expr NOT LIKE '%SUM(%' and a.col_expr NOT LIKE '%AVG(%' AND c.COL_HEADER IS NULL 
	and a.rep_type=@cRepType AND ((@bMtdXntype=0 AND @bYtdXntype=0 AND RIGHT(b.key_col,3) NOT IN ('MTD','YTD')) OR  
	(@bMtdXntype=1 AND RIGHT(b.key_col,3) IN ('MTD')) OR (@bYtdXntype=1 AND RIGHT(b.key_col,3) IN ('YTD')))
	AND isnull(multi_column_based,0)=0

	INSERT #tmpLayoutCols (colname,col_header)
	select DISTINCT a.col_expr as colname,a.col_header
	FROM transaction_analysis_calculative_COLS a (NOLOCK)
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	left join #tmpLayoutCols c on c.COL_HEADER=a.COL_HEADER
	WHERE a.xn_type IN ('common') AND a.col_expr<>'xn_type' and a.col_expr NOT LIKE '%SUM(%'  and c.COL_HEADER IS NULL
	and a.rep_type=@cRepType AND a.col_expr NOT IN ('Payment_Groups','Payment_Modes')
	AND ((@bMtdXntype=0 AND @bYtdXntype=0 AND RIGHT(b.key_col,3) NOT IN ('MTD','YTD')) OR  
	(@bMtdXntype=1 AND RIGHT(b.key_col,3) IN ('MTD')) OR (@bYtdXntype=1 AND RIGHT(b.key_col,3) IN ('YTD')))
	AND isnull(multi_column_based,0)=0

	--if @cxntype like '%(oh)%'
	--	select 'check layoutcols',* from  #tmpLayoutCols

	SET @cStep='15'
	select cattr as colname INTO #tmpFilterCols from rep_filter (NOLOCK) a
	JOIN Xpert_filter_Mst b on a.rep_id=b.rep_id  where b.Filter_id=@cFilterRepId
	AND cattr<>'xn_type'
	UNION
	select cattr as colname from rep_filter (NOLOCK) a
	WHERE a.rep_id=@cRepId 	AND cattr<>'xn_type'


	SELECT @cColNameLocId=keyfield FROM transaction_analysis_master_cols where xn_type=@cXntype
	AND  col_expr='dept_alias' and rep_type=@cRepType

	IF @cColNameLocId IS NULL
		SELECT TOP 1 @cColNameLocId=keyfield FROM transaction_analysis_master_cols where xn_type=@cXntype
		AND  col_header IN ('Location Id','Transaction Location Id') and rep_type=@cRepType

	SET @cStep='20'
	IF @cColNameLocId IS NOT NULL
		SET @cJoinstr=' LEFT JOIN #loc_view ON #loc_view.dept_id='+@cColNameLocId

	SELECT @cInsCols=COALESCE(@cInsCols+',','')+'['+b.COL_HEADER+']',
	@cLayoutCols=COALESCE(@cLayoutCols+',','')+(CASE 
	WHEN ISNULL(joining_table_alias,'')<>''	AND CHARINDEX(joining_table_alias,a.col_expr)=0 
	THEN joining_table_alias+'.' 
	WHEN ISNULL(joining_table,'')<>'' AND CHARINDEX(joining_table,a.col_expr)=0 AND ISNULL(joining_table_alias,'')=''
	THEN JOINING_TABLE+'.' ELSE '' END)+a.COL_expr 
	FROM  transaction_analysis_MASTER_COLS a (NOLOCK)
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	WHERE a.xn_type IN (REPLACE(@cXnType,'(oh)',''))  AND a.col_expr<>'xn_type'  AND a.xn_type<>'Common'
	and a.rep_type=@cRepType AND (a.joining_table<>'sku_names' OR RIGHT(@cXnType,4)<>'(oh)')
	AND NOT (a.COL_HEADER='Item Code' AND RIGHT(@cXnType,4)='(oh)')


	--if  @@spid=1046 and @cXntype='Retail Sale'
	--	select 'First level', @cInscols,@cRepType rep_type,@cXnType xn_type,@cLayoutCols

	SET @cStep='23'
	SELECT @cInsCols=COALESCE(@cInsCols+',','')+'['+b.COL_HEADER+']',
	 @cLayoutCols=COALESCE(@cLayoutCols+',','')+(CASE 
	WHEN ISNULL(a.joining_table_alias,'')<>''	AND CHARINDEX(a.joining_table_alias,a.col_expr)=0 
	THEN a.joining_table_alias+'.' 
	WHEN ISNULL(a.joining_table,'')<>'' AND CHARINDEX(a.joining_table,a.col_expr)=0 AND ISNULL(a.joining_table_alias,'')='' 
	THEN a.JOINING_TABLE+'.' ELSE '' END)+a.COL_expr 
	FROM transaction_analysis_MASTER_COLS a
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	left join  transaction_analysis_MASTER_COLS c (NOLOCK) ON c.col_name=b.key_col  AND c.rep_type=a.rep_type  
	AND c.xn_type=REPLACE(@cXnType,'(oh)','')
	WHERE a.xn_type  IN ('common') AND a.col_expr<>'xn_type'
	AND c.col_expr IS NULL	and a.rep_type=@cRepType AND (a.joining_table<>'sku_names' OR RIGHT(@cXnType,4)<>'(oh)')
		 AND NOT (a.COL_HEADER='Item Code' AND RIGHT(@cXnType,4)='(oh)')

	--if  @@spid=1046 and @cXntype='Retail Sale'
	--	select '2nd level', @cInscols,@cRepType rep_type,@cXnType xn_type,@cLayoutCols
		
	IF RIGHT(@cXnType,4)<>'(oh)' -- have to put this condition becasue of Error in Reports having column Transaction qty ,transaction value at mrp etc.
	BEGIN
		SET @cStep='25'
		SELECT @cInsCols=@cInsCols+',['+b.COL_HEADER+']',
		@cLayoutCols=@cLayoutCols+','+(CASE WHEN a.xn_type<>@cXnType THEN '0' else  a.col_expr END) 
		+(CASE WHEN b.key_col IN ('OBS','CBS') THEN ' as '+b.key_col ELSE '' END)
		FROM transaction_analysis_calculative_COLS a
		JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
		WHERE (a.xn_type=@cXnType)  and a.rep_type=@cRepType AND a.col_expr NOT IN ('Payment_Groups','Payment_Modes')
		AND ((@bMtdXntype=0 AND @bYtdXntype=0 AND RIGHT(b.key_col,3) NOT IN ('MTD','YTD')) OR  
		(@bMtdXntype=1 AND RIGHT(b.key_col,3) IN ('MTD')) OR (@bYtdXntype=1 AND RIGHT(b.key_col,3) IN ('YTD')))
		AND isnull(multi_column_based,0)=0
		
--if  @@spid=1046 and @cXntype='Retail Sale'
--			select '3rd level',@bMtdXntype MtdXntype,@bytdXntype ytdXntype, @cInscols,@cRepType rep_type,@cXnType xn_type,@cLayoutCols

		SELECT @cInsCols=@cInsCols+(CASE WHEN  CHARINDEX('['+b.COL_HEADER+']',@cInsCols)=0 THEN ',['+b.COL_HEADER+']' 
											ELSE '' END),
		@cLayoutCols=COALESCE(@cLayoutCols+',','')+a.COL_expr
		FROM transaction_analysis_calculative_COLS a
		JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
		left join  transaction_analysis_calculative_COLS c (NOLOCK) ON c.col_name=b.key_col AND c.xn_type=@cXnType AND c.rep_type=@cRepType
		WHERE  a.xn_type IN ('common') AND c.col_expr IS NULL
		and a.rep_type=@cRepType AND a.col_expr NOT IN ('Payment_Groups','Payment_Modes')
		AND ((@bMtdXntype=0 AND @bYtdXntype=0 AND RIGHT(b.key_col,3) NOT IN ('MTD','YTD')) OR  
		(@bMtdXntype=1 AND RIGHT(b.key_col,3) IN ('MTD')) OR (@bYtdXntype=1 AND RIGHT(b.key_col,3) IN ('YTD')))
		AND isnull(a.multi_column_based,0)=0 AND (RIGHT(@cXnType,4)<>'(oh)' OR a.col_header LIKE '%gst%')

	END

	--if  @@spid=1046 and @cXntype='Retail Sale'
	--	select '4th level', @cInscols,@cRepType rep_type,@cXnType xn_type,@cLayoutCols

	delete  from #tmpLayoutCols where colname in ('','''','''''','''''''','0')


	--if @@spid=93 AND @cXntype='Purchase(OH)'
	--	select 'check layout',* from #tmpLayoutCols --where col_header like '%gst%'

	IF CHARINDEX('sku_names',@cJoinstr)=0  AND @cBoXntype='' AND RIGHT(@cXnType,4)<>'(oh)'
	BEGIN
		print 'Enter joining expression for sku_names for Buyer Order'

		DECLARE @cReptypeItemCode VARCHAR(20)
		SET @cStep='70'
		SET @cJoiningTable=''
		SET @cKeyField=''

		SET @cReptypeItemCode=@cRepType

		IF @cRepType='SMRY' 
		BEGIN
			IF EXISTS (SELECT TOP 1 a.col_name	FROM transaction_analysis_calculative_COLS a
					   JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
					   WHERE a.col_expr LIKE '%sku_names%') 
			 OR EXISTS (SELECT TOP 1 a.col_name	FROM transaction_analysis_master_COLS a
					   JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
					   WHERE a.col_expr LIKE '%sku_names%') 
			SET @cReptypeItemCode='DETAIL'
		END

		--if @@spid=63
		--	select 'check @cReptypeItemCode',@cReptypeItemCode

		SELECT TOP 1 @cKeyField=col_expr FROM  transaction_analysis_master_COLS (NOLOCK)
		WHERE (xn_type IN (@cXnType) )  AND col_header='Item Code' and rep_type=@cReptypeItemCode			

		IF ISNULL(@cKeyField,'')=''
			SELECT TOP 1 @cKeyField=col_expr FROM  transaction_analysis_master_COLS (NOLOCK)
			WHERE xn_type='Common' AND col_header='Item Code' and rep_type=@cReptypeItemCode			

			
		IF ISNULL(@cKeyField,'')<>''
			SET @cJoinstr=@cJoinStr+' '+'join sku_names (NOLOCK) ON sku_names.product_code='+@cKeyField
	END


	--if @@spid=673
	--	select 'check cjoin str before tmplayout',@cJOinstr joinstr


	WHILE EXISTS (SELECT TOP 1 * FROM #tmpLayoutCols)
	BEGIN
		SELECT @cJoiningCol='',@cJoiningTable='',@cJoinExpr=''

		SET @cStep='30'
		select top 1 @cColName=colname,@cJoiningTableAlias=isnull(joining_table_alias,''), 
		@cJoiningTable=joining_table,@cJoiningCol=joining_column,@cKeyField=keyfield,
		@cColHeader=col_header,@cAddnlJoin=ISNULL(addnl_join,'')
		from #tmpLayoutCols

		--IF @cColHeader LIKE '%gst%amount%' OR @cColHeader LIKE '%taxable%'
		--	GOTO lblNext

		SET @cStep='40'
		SELECT 	@cGrpCols=@cGrpCols+(CASE WHEN @cGrpCols<>'' THEN ',' ELSE '' END)+(case 
		when isnull(@cJoiningTableAlias,'')<>'' and charindex(@cJoiningTableAlias,@cColName)=0  
		THEN @cJoiningTableAlias+'.' 
		when isnull(@cJoiningTable,'')<>'' and charindex(@cJoiningTable,@cColName)=0 AND isnull(@cJoiningTableAlias,'')='' 
		THEN @cJoiningTable+'.' 
		else '' end)+@cColName

		IF @cJoiningTable='sku_names' 
			GOTO lblNext

		IF @cJoiningCol LIKE '%attr%' AND CHARINDEX('article_fix_attr',@cJoinstr)=0
			SET @cJoinstr=@cJoinStr+' JOIN article_fix_attr (NOLOCK) ON article.article_code=article_fix_attr.article_code '
		
		IF isnull(@cJoiningTable,'')<>''
			SET @cJoinExpr='LEFT JOIN '+@cJoiningTable+' '+@cJoiningTableAlias+' (NOLOCK) ON '+
				(CASE WHEN @cJoiningTableAlias<>'' THEN @cJoiningTableAlias ELSE @cJoiningTable END)+'.'+@cJoiningCol+'='+@cKeyField
				
		IF (@cJoiningCol<>'' AND CHARINDEX(@cJoinExpr,@cJoinstr)=0) OR
		   (@cAddnlJoin<>'' AND CHARINDEX(@cAddnlJoin,@cJoinstr)=0)
			SET @cJoinstr=@cJoinStr+' '+ISNULL(@cAddnlJoin,'')+ ' '+ISNULL(@cJoinExpr,'')
		
lblNext:
		--IF @@SPID=131
		--	SELECT 'join expr after col:'+@cColHeader,@cJoiningTable ,@cJoinExpr,@cJoinstr

		DELETE FROM #tmpLayoutCols WHERE colname=@cColName AND col_header=@cColHeader
	END

	--if @@spid=673
	--	select 'check cjoin str after tmplayout',@cJOinstr joinstr

	SET @cOutputFilter=@cInputFilter


		--IF @@SPID=673
		--	SELECT 'Check #tmpFilterCols',* from #tmpFilterCols

	SET @cOutputFilter=REPLACE(@cOutputFilter,'loc_view','#loc_view')

	WHILE EXISTS (SELECT TOP 1 * FROM #tmpFilterCols)
	BEGIN
		SET @cStep='50'
		SELECT @cJoiningTable='',@cColExpr='' 

		SELECT TOP 1 @cColName=colname FROM #tmpFilterCols

	--- Had to remove this (OR @cXpertrepCode='R1') becasue Problem comes of wrong join of location table randomly with left(memo_id,2) column
	--- if user takes the Location id/name as layout/filter column (Sanjay:24-06-2022 SUmangal ticket#06-1629)
		SELECT TOP 1 @cJoiningTable=joining_table,@cJoiningTableAlias=ISNULL(joining_table_alias,''),
		@cKeyField=keyfield,@cJoiningCol=joining_column,@cColExpr=a.col_expr,@cAddnlJoin=addnl_join
		FROM transaction_analysis_MASTER_COLS a (NOLOCK) WHERE a.xn_type IN (@cXnType)   ---OR @cXpertrepCode='R1')
		AND (col_expr=@cColName OR col_expr=joining_table+'.'+@cColName) and a.rep_type=@cRepType

		IF ISNULL(@cColExpr,'')=''
			SELECT TOP 1 @cJoiningTable=joining_table,@cJoiningTableAlias=ISNULL(joining_table_alias,''),
			@cKeyField=keyfield,@cJoiningCol=joining_column,@cColExpr=a.col_expr,@cAddnlJoin=addnl_join
			FROM transaction_analysis_MASTER_COLS a (NOLOCK) WHERE xn_type='Common'
			AND (col_expr=@cColName OR col_expr=joining_table+'.'+@cColName) and a.rep_type=@cRepType

		IF ISNULL(@cColExpr,'')=''
			SELECT TOP 1 @cJoiningTable=joining_table,@cJoiningTableAlias=ISNULL(joining_table_alias,''),
			@cKeyField=keyfield,@cJoiningCol=joining_column,@cColExpr=a.col_expr,@cAddnlJoin=addnl_join
			FROM transaction_analysis_MASTER_COLS a (NOLOCK) WHERE (a.xn_type IN (@cXnType)) -- OR @cXpertrepCode='R1') 
			AND (col_name=@cColName OR col_name=joining_table+'.'+@cColName) and a.rep_type=@cRepType

		IF ISNULL(@cColExpr,'')=''
			SELECT TOP 1 @cJoiningTable=joining_table,@cJoiningTableAlias=ISNULL(joining_table_alias,''),
			@cKeyField=keyfield,@cJoiningCol=joining_column,@cColExpr=a.col_expr,@cAddnlJoin=addnl_join
			FROM transaction_analysis_MASTER_COLS a (NOLOCK) WHERE xn_type='Common'
			AND (col_name=@cColName OR col_name=joining_table+'.'+@cColName) and a.rep_type=@cRepType
		
		SET @cAddnlJoin=ISNULL(@cAddnlJoin,'')

		SET @cStep='60'
		IF ((CHARINDEX(@cJoiningTable,@cJoinstr)=0 AND @cJoiningTable<>'') OR 
			(@cJoiningTableAlias<>'' AND CHARINDEX(@cJoiningTableAlias,@cJoinstr)=0) OR
			 (@cAddnlJoin<>'' AND CHARINDEX(@cAddnlJoin,@cJoinstr)=0))
			AND ISNULL(@cJoiningTable,'') NOT IN ('','SKU_NAMES')
			SET @cJoinstr=@cJoinStr+ISNULL(@cAddnlJoin,'')+' '+'join '+@cJoiningTable+' '+@cJoiningTableAlias+' (NOLOCK) ON '+
			(CASE WHEN @cJoiningTableAlias<>'' THEN @cJoiningTableAlias ELSE @cJoiningTable END)+'.'+@cJoiningCol+'='+@cKeyField

		--if @@spid=61
		--	select @cColname,@cJoiningTableAlias,@cColExpr,@cJoiningTable
		--if @@spid=99
		--	select @cOutputFilter output_filter_before_replacing,@cColName
		
		SET @cOutputFilter=REPLACE(@cOutputFilter,'A.'+@cColName,@cColName)
		--SET @cOutputFilter=REPLACE(@cOutputFilter,'loc_view.'+@cColName,@cColName)

		--if @@spid=74
		--	select 'loc_view.'+@cColName,@cOutputFilter,CHARINDEX('loc_view.'+@cColName,@cOutputFilter)
		IF CHARINDEX('loc_view.'+@cColName,@cOutputFilter)=0------- Have to put this condition because Application is giving loc_view.column name as part of Filter
										  ---- if we try to replace the major_dept_id with col_expr , it gives error
			SET @cOutputFilter=REPLACE(@cOutputFilter,@cColName,
			(CASE WHEN @cJoiningTableAlias<>'' AND CHARINDEX(@cJoiningTableAlias,@cColExpr)=0
				  AND CHARINDEX(@cJoiningTableAlias+'.'+@cColExpr,@cOutputFilter)=0	THEN @cJoiningTableAlias+'.'
				  WHEN @cJoiningTable<>''  AND CHARINDEX(@cJoiningTable,@cColExpr)=0
				  AND CHARINDEX(@cJoiningTable+'.'+@cColExpr,@cOutputFilter)=0 THEN @cJoiningTable+'.'	ELSE '' END)+@cColExpr)

		--if @@spid=99
		--	select @cOutputFilter output_filter_after_replace_1,@cColName

		SET @cOutputFilter=REPLACE(@cOutputFilter,'sku_names.'+@cColName,@cColName)

		--if @@spid=99
		--	select @cOutputFilter output_filter_after_replace_2,@cColName

		DELETE FROM #tmpFilterCols WHERE colname=@cColName
	END
	
	--if @@spid=673
	--	select 'check cjoin str after filtercols',@cJOinstr joinstr


	IF (CHARINDEX('sku_xfp',@cJoinstr)=0 OR @cXpertrepCode='R1') AND @cBoXntype=''
	BEGIN
		SET @cStep='80'
		SET @cJoiningTable=''
		
		DECLARE @bXfpcJoinFound BIT
		SET @bXfpcJoinFound =0

		IF CHARINDEX('sku_xfp',@cJoinstr)>0
			SET @bXfpcJoinFound =1	
		
		IF @bXfpcJoinFound=0
		BEGIN
			SELECT TOP 1 @cJoiningTable='sku_xfp'
			FROM transaction_analysis_calculative_COLS a (NOLOCK)
			JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
			WHERE (a.xn_type IN (@cXnType) )  and (a.col_expr like '%sxfp%' OR a.col_expr like '%sku_xfp%') and a.rep_type=@cRepType

			IF ISNULL(@cJoiningTable,'')=''
				SELECT TOP 1 @cJoiningTable='sku_xfp'
				FROM transaction_analysis_calculative_COLS a (NOLOCK)
				JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
				WHERE xn_type='Common' and (a.col_expr like '%sxfp%' OR a.col_expr like '%sku_xfp%') and a.rep_type=@cRepType

			IF ISNULL(@cJoiningTable,'')<>''
			BEGIN
				SET @cSearchCol=(CASE WHEN @cRepType='POPEND' THEN 'Receiving Location Id' WHEN @cXpertrepCode='R1' THEN 'Location Id' 
									  ELSE 'Transaction Location Id' END)

				SELECT @cKeyField=col_expr FROM transaction_analysis_master_COLS a (NOLOCK)
				WHERE (a.xn_type IN (@cXnType) )  AND  a.col_header=@cSearchCol and a.rep_type=@cRepType

				DECLARE @cPcKeyField VARCHAR(100)
				SELECT @cPcKeyField=col_expr FROM transaction_analysis_master_COLS a (NOLOCK)
				WHERE (a.xn_type IN (@cXnType) )  AND  a.col_header='Item Code' and a.rep_type=@cRepType

				IF ISNULL(@cPcKeyField,'')=''
					SET @cPcKeyField='a.product_code'
		    
				--IF @@spid=673
				--	select @cJoinstr before_sxfp_join,@cSearchCol,@cXnType,@cKeyField

				SET @cJoinstr=@cJoinStr+' '+'LEFT join sku_xfp sxfp (NOLOCK) ON sxfp.product_code='+@cPcKeyField+' AND sxfp.dept_id= '+@cKeyField

				--IF @@spid=91
				--	select @cJoinstr after_sxfp_join

			END
		END

		ELSE
		IF @bXfpcJoinFound=1
		BEGIN
			SET @cSearchCol=(CASE WHEN @cRepType='POPEND' THEN 'Receiving Location Id' WHEN @cXpertrepCode='R1' THEN 'Location Id' 
									ELSE 'Transaction Location Id' END)

			SELECT @cKeyField=col_expr FROM transaction_analysis_master_COLS a (NOLOCK)
			WHERE (a.xn_type IN (@cXnType) )  AND  a.col_header=@cSearchCol and a.rep_type=@cRepType


			--IF @@spid=673
			--	select 'sxfpfound', @cJoinstr before_sxfp_join,@cSearchCol,@cXnType,@cKeyField

			SET @cJoinstr=replace(@cJoinstr,'sxfp.dept_id=a.dept_id','sxfp.dept_id= '+@cKeyField)
		END
	END
	
	--if @@spid=673
	--	select 'check cjoin str after sxfp',@cJOinstr joinstr

	IF @bXnhistory=1
	BEGIN
		
		DECLARE @cXnIdCOl VARCHAR(100)

		SET @cInsCols=@cInsCols+',xn_mode,xn_id'
		IF EXISTS (SELECT TOP 1 xn_type FROM transaction_analysis_expr (NOLOCK) WHERE xn_type=@cXnType )
			SELECT @cLayoutCols=@cLayoutCols+','+ltrim(rtrim(xn_mode))
			FROM transaction_analysis_expr (NOLOCK) WHERE xn_type=@cXnType 
		ELSE
			SET @cLayoutCols=@cLayoutCols+',1'
		
		SELECT TOP 1 @cXnIdCOl=col_expr FROM transaction_analysis_master_COLS (NOLOCK)
		WHERE xn_type=@cXnType AND REP_TYPE=@cRepType AND col_header='Transaction Id'

		SET @cLayoutCols=@cLayoutCols+ISNULL(','+@cXnIdCOl,',''''')
		SET @cGrpCols=@cGrpCols+ISNULL(','+@cXnIdCOl,'')
	END

	IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='Transaction_Month_Name')
	BEGIN
		DECLARE @cXnMonthCOl VARCHAR(500)
		SELECT TOP 1 @cXnMonthCOl=col_expr FROM transaction_analysis_master_COLS (NOLOCK)
		WHERE xn_type=@cXnType AND REP_TYPE=@cRepType AND col_name='Transaction_Month_Name'

		SET @cInsCols=@cInsCols+',xn_month_id'
		SET @cXnMonthCOl=REPLACE(REPLACE(@cXnMonthCOl,'DATENAME(month,','left(convert(varchar,'),')',',112),6)')
		
		--left(convert(varchar, getdate(), 112),6)
		SET @cLayoutCols=@cLayoutCols+','+@cXnMonthCOl
		SET @cGrpCols=@cGrpCols+','+@cXnMonthCOl
	END
	
	IF @bXnhistory=1 AND @cXnType='Retail PackSlip'
		SET @cOutputFilter=@cOutputFilter+' AND ISNULL(b.ref_cm_id,'''')='''''

	IF ISNULL(@cOutputFilter,'')<>''
		SET @cOutputFilter=' ('+@cOutputFilter+') '

	IF @cInsCols is null
		SET @cInsCols='[transaction type]'

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_XPERTREPORT_GETCOLSEXPR at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END