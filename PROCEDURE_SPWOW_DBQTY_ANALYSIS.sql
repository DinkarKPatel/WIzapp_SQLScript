CREATE PROCEDURE SPWOW_DBQTY_ANALYSIS
@dFromDt DATETIME,
@dToDt DATETIME,
@cPriceCategoryGrpCode VARCHAR(10)=''
AS
BEGIN
	DECLARE @nOpsQty NUMERIC(20,2),@cCmd NVARCHAR(MAX),@nLoop INT,@cStep VARCHAR(4),@cLayOutCols NVARCHAR(max),@cGrpCols VARCHAR(1000),@cImageCols VARCHAR(1000),
			@cImageGrpCols VARCHAR(400),@cDbColName VARCHAR(100),@nSpId VARCHAR(40),@cFilter VARCHAR(500),
			@cTable VARCHAR(200),@cColHeader VARCHAR(200),@cOpsExpr VARCHAR(1000),@cErrormsg varchar(1000),@cXntypeStr VARCHAR(2000),@cCbsExpr VARCHAR(2000)

BEGIN TRY
	SET @cStep='10'
	
	set @nSpId=newid()

	DECLARE @tMasterCols TABLE (masterColName VARCHAR(200),dbColName VARCHAR(200))

	SELECT * INTO #tmpXntypes from wow_XPERT_XNTYPeS_alias WHERE XN_TYPE_alias not in ('STKQTY','Stock')  order by xntypeOrder

	SELECT fromn fromMrp,ton toMrp,category_name INTO #priceCategory FROM catgrpdet (NOLOCK) WHERE GROUP_CODE=@cPriceCategoryGrpCode

	exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0

	INSERT INTO @tMasterCols (masterColName,dbColName)
	SELECT 'Location Id','a.dept_id'
	UNION ALL
	SELECT'Location Name','dept_name'
	UNION ALL
	SELECT 'Section Name','sku_names.section_name'
	UNION ALL
	SELECT 'SubSection Name','sku_names.sub_section_name'
	UNION ALL
	SELECT 'Article no.','sku_names.article_no'
	UNION ALL
	SELECT 'OEM Supplier','sku_names.oem_ac_name'
	UNION ALL
	SELECT 'Supplier','sku_names.ac_name'
	UNION ALL
	SELECT 'Mrr no.','sku_names.pur_mrr_no'	
	UNION ALL
	SELECT 'MRP','sku_names.mrp'	
	UNION ALL
	SELECT 'Price Category','category_name'	
	UNION ALL
	SELECT 'Shelf Ageing','shelfAgeingSlab'	
	UNION ALL
	SELECT 'Purchase Ageing','purAgeingSlab'	

	SELECT @cLayOutCols=N'oem_ac_name [OEM Supplier],ac_name [Supplier],pur_mrr_no [Mrr no.],a.dept_id [Location Id],dept_name [Location Name],
	section_name [Section Name],sub_section_name [SubSection Name],article_no [Article no.],MRP,category_name [Price Category]',
	@cGrpCols=N'oem_ac_name,ac_name,pur_mrr_no,a.dept_id,dept_name,section_name,sub_section_name,article_no,MRP,category_name'
	   	
	SET @cStep='40'
	exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0
	SELECT @cImageCols=(CASE WHEN section=1 THEN 'Section Name,' ELSE '' END)+(CASE WHEN sub_section=1 THEN 'SubSection Name,' ELSE '' END)+
	(CASE WHEN article=1 THEN 'Article no.,' ELSE '' END)+(CASE WHEN para1=1 THEN 'para1Name,' ELSE '' END)+(CASE WHEN para2=1 THEN 'para2Name,' ELSE '' END)+
	(CASE WHEN para3=1 THEN 'para3Name,' ELSE '' END)+(CASE WHEN para4=1 THEN 'para4Name,' ELSE '' END)+(CASE WHEN para5=1 THEN 'para5Name,' ELSE '' END)+
	(CASE WHEN para6=1 THEN 'para6Name,' ELSE '' END) FROM image_info_config a (NOLOCK)
	

	SET @cStep='42'
	CREATE TABLE #tmpAgeSlabs (fromDays INT,toDays INT,slabName VARCHAR(100),srno int)
	EXEC SPWOW_PREPARE_AGEINGSLABS

	DECLARE @cStepMsg varchar(50)
	SET @nLoop=1
	WHILE @nLoop<=32
	BEGIN
		SET @cStep='45'
		set @cStepMsg='Loop:'+ltrim(rtrim(str(@nLoop)))

		exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,@cStepMsg,0
		IF @nLoop<=7
		BEGIN
			SET @cColHeader=''
			SELECT TOP 1 @cColHeader=value FROM config (NOLOCK) WHERE config_option='para'+ltrim(rtrim(str(@nLoop)))+'_caption'
			IF ISNULL(@cColHeader,'')=''
				SET @cColHeader='para'+ltrim(rtrim(str(@nLoop)))+'Name'
			ELSE
				SET @cImageCols=REPLACE(@cImageCols,'para'+ltrim(rtrim(str(@nLoop)))+'name',@cColHeader)

			SET @cDbColName='sku_names.para'+ltrim(rtrim(str(@nLoop)))+'_Name'
		END
		ELSE
		BEGIN
			SELECT @cTable='attr'+ltrim(rtrim(str(@nLoop-7)))+'_mst'

			IF NOT EXISTS (SELECT TOP 1 column_name FROM config_attr (NOLOCK) WHERE table_name=@cTable AND table_caption<>'')
				GOTO lblNext
			
			SET @cDbColName='sku_names.attr'+ltrim(rtrim(str(@nLoop-7)))+'_key_Name'
			SELECT TOP 1 @cColHeader=table_caption FROM config_attr (NOLOCK) WHERE table_name=@cTable AND table_caption<>''
		END

		INSERT INTO @tMasterCols (masterColName,dbColName)
		SELECT @cColHeader,@cDbColName

		SELECT @cLayOutCols=@cLayOutCols+','+(CASE WHEN @nLoop<=7  THEN 'para'+ltrim(rtrim(str(@nLoop)))+'_name' else 'attr'+ltrim(rtrim(str(@nLoop-7)))+'_key_Name' END)+' ['+@cColHeader+']',
		@cGrpCols=@cGrpCols+','+(CASE WHEN @nLoop<=7  THEN 'para'+ltrim(rtrim(str(@nLoop)))+'_name' else 'attr'+ltrim(rtrim(str(@nLoop-7)))+'_key_Name' END)
	
	lblNext:
		SET @nLoop=	@nLoop+1
	END
	
	SET @cStep='50'
	exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0
	SELECT @cXntypeStr=COALESCE(@cXntypeStr+',','')+'['+xn_type+']' from #tmpXnTypes 

	--select @cXntypeStr XntypeStr
	SELECT @cCbsExpr=COALESCE(@cCbsExpr,'')+(CASE WHEN xnTypemode=1 THEN '+' ELSE '-' END) +'isnull(['+xn_type+'],0)'from #tmpXnTypes
	

	--if @@spid=309
	--	select @cCbsExpr cCbsExpr
	
	--SET @cStep='55'
	--exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0
	--SET @cCmd=N'select  a.img_id, CAST('''' AS XML).value(''xs:base64Binary(sql:column("prod_image"))'', ''VARCHAR(MAX)'') AS Base64String
	--FROM '+DB_NAME()+'_image..image_info a (NOLOCK) join #tmpImgIds b on a.img_id=b.barcode_img_id'

	--INSERT INTO #tmpImages (img_id,itemImage)
	--EXEC SP_EXECUTESQL @cCmd

	SET @cStep='60'
	exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0
	DECLARE @cXnTypesExpr VARCHAR(200)
	SET @cXnTypesExpr='(''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
				''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',
				''OLOAQ'',''CNPI'',''SNC_PFI'')'

	SET @cOpsExpr='sum(case when a.xn_type in '+@cXnTypesExpr+'	then 1 else -1 end * a.xn_qty)'
	
	DECLARE @cReferDailyPmt VARCHAR(2),@bGetPmtFromApp BIT,@cPmtOpsTableName VARCHAR(200),@dFromDtLastMonthEndDt DATETIME,
	@dToMonthEndDt DATETIME,@bFetchPmtontheFly BIT,@cFromDtPara VARCHAR(20),@cTodtPara VARCHAR(20)


	
	SET @bFetchPmtontheFly=0
	SELECT TOP 1 @cReferDailyPmt=value FROM config (NOLOCK) WHERE config_option='PMT_BUILD_DATEWISE'

	SET @cStep='65'
	SET @cReferDailyPmt=ISNULL(@cReferDailyPmt,'')
	SET @dFromDtLastMonthEndDt=DATEADD(DAY, -DAY(@dFromDt), CAST(@dFromDt AS DATE))
	SET @dToMonthEndDt=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dToDt) + 1, 0))

	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty,CONVERT(NUMERIC(10,0),0) purchase_ageing_days,CONVERT(NUMERIC(10,0),0) shelf_ageing_days into #pmtops from pmt01106 where 1=2
	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtcbs from pmt01106 where 1=2

	SET @cFilter=' ISNULL(Sku_Names.Sku_Er_Flag,0) IN (0 , 1 )   AND  ISNULL(SKU_NAMES.sku_item_type,1) IN (0,1) '
	IF @cReferDailyPmt<>'1'
	BEGIN
		
	
		IF (@dFromDt-1)<>@dFromDtLastMonthEndDt
			 SET @bFetchPmtontheFly=1

		SELECT @cPmtOpsTableName=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dFromDtLastMonthEndDt,112)
		
		SET @cStep='70'
		IF @bFetchPmtontheFly=1
		BEGIN
			print 'Fetching Xns for Opening stock on the fly'
			SET @cStep='80'
			
			DECLARE @tErrmsg TABLE (errmsg varchar(max))



			exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY
			@dFromDt=@dFromDt,
			@dToDt=@dFromDt,
			@bUpdateOpsXnsOnly=1,
			@cFilterPara=@cFilter,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
		END
		else
		begin
			print 'No need to fetch pmt on the fly'
		end
	END
	ELSE
	BEGIN
		SELECT @cPmtOpsTableName=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dFromdt-1,112)
	END

	SET @cStep='85'

	PRINT 'Fetching transactions for the period'
	CREATE TABLE #tmpXnsCbs (dept_id VARCHAR(4),product_code VARCHAR(50),bin_id VARCHAR(10),xn_qty NUMERIC(20,3),xn_type VARCHAR(20),
							 purchase_ageing_days NUMERIC(10,0),shelf_ageing_days NUMERIC(10,0))

	SELECT @cFromDtPara=CONVERT(VARCHAR,@dFromDt,112),@cToDtPara=CONVERT(VARCHAR,@dToDt,112)
	EXEC SPWOW_GETXNSDATA_OBSCBSCALC 
	@dFromDt=@cFromDtPara,
	@dToDt=@cToDtPara,
	@bCalledFromDbQty=1,
	@cFilter=@cFilter,
    @cErrormsg=@cErrormsg OUTPUT
	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	
	SET @nLoop=1

	WHILE @nLoop<=3
	BEGIN
		SET @cTable=(CASE WHEN @nLoop=1 THEN @cPmtOpsTableName WHEN @nLoop=2 THEN '#pmtops' ELSE '#tmpXnsCbs' END)

		SET @cCmd=N'UPDATE A SET purchase_ageing_days = (CASE WHEN isnull(purchase_receipt_dt,'''')='''' then 1 when 
					ABS(DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+''') END),
					shelf_ageing_days=(CASE WHEN isnull(sx.receipt_Dt,'''')='''' then 1 when  ABS(DATEDIFF(dd,sx.receipt_Dt,'''+
					convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,sx.receipt_Dt,'''+convert(varchar,GETDATE(),110)+''')  END)
		FROM '+@cTable+' A (nolock)
		LEFT JOIN  sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id
		JOIN sku_names sn (nolock) on sn.product_code=a.product_code
		WHERE '+(CASE WHEN @nLoop<>3 THEN 'ISNULL(a.cbs_qty,0)<>0 AND ' else '' end)+'A.BIN_ID<>''999'' AND (ISNULL(purchase_ageing_days,0)=0 OR ISNULL(shelf_ageing_days,0)=0)'
		print @CcMD
		EXEC SP_EXECUTESQL @cCmd

		SET @nLoop=@nLoop+1
	END

	--if @@spid=119
	--	select 'check #tmpxnscbs',* from  #tmpxnscbs
	--select * into tmpxnscbs from #tmpxnscbs

	--select * into tmppriceCategory from #priceCategory

	--select * into tmpxntypes from  #tmpxntypes

	SET @cStep='87'
	SET @cCmd=N'SELECT '+@cLayOutCols+',convert(varchar(max),'''') image,barcode_img_id,ISNULL(x.xn_type,a.xn_type) xntype, 
			     s1.slabName shelfAgeingSlab,s2.slabName purAgeingSlab,ABS(sum(xn_qty)) xnQty INTO #tmpXnsDetails 
				 FROM #tmpXnsCbs a '+
			  ' JOIN  sku_names sn (NOLOCK) ON sn.product_code=a.product_code'+
			  ' JOIN location loc (NOLOCK) ON  loc.dept_id=a.dept_id LEFT JOIN #priceCategory pc ON sn.mrp BETWEEN pc.fromMrp AND pc.toMrp '+
			  ' LEFT JOIN #tmpXnTypes x (NOLOCK) ON x.XN_TYPE_alias=a.xn_Type '+
			  ' LEFT JOIN sku_xfp sx (NOLOCK) ON sx.product_code=sn.product_code AND sx.dept_id=a.dept_id'+
			  ' JOIN #tmpAgeSlabs s1 ON a.shelf_ageing_days between S1.fromdays AND s1.todays '+
			  ' JOIN #tmpAgeSlabs s2 ON a.purchase_ageing_days between S2.fromdays AND s2.todays '+
			  ' group by '+@cGrpCols+',barcode_img_id,s1.slabName,s2.slabName,ISNULL(x.xn_type,a.xn_type)


				SELECT a.xnType,isnull(b.xn_type_alias,a.xntype) xntypeAlias,b.xntypeOrder,b.xntypeMode,
				 SUM(CASE WHEN isnull(b.xn_type_alias,a.xntype) in '+@cXnTypesExpr+' then xnQty else 0 end) inwardsQty
				,ABS(SUM(CASE WHEN isnull(b.xn_type_alias,a.xntype) NOT in '+@cXnTypesExpr+' then xnQty else 0 end)) outwardsQty
				FROM (SELECT b.xn_type xntype,sum(cbs_qty) xnQty from '+@cPmtOpsTableName+' a  JOIN #tmpXntypes b on b.XN_TYPE_alias=''OPS'' 
				      JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code WHERE '+@cFilter+
					  ' group by b.xn_type
					  UNION ALL 
					  SELECT b.xn_type xntype,sum(cbs_qty) xnQty from #pmtops a  JOIN #tmpXntypes b on b.XN_TYPE_alias=''OPS'' 
					  group by b.xn_type
					  UNION ALL 
					  SELECT xntype,sum(xnQty) from #tmpXnsDetails group by xntype) a
			    LEFT JOIN #tmpXnTypes b (NOLOCK) ON b.xn_type=a.xnType
				GROUP BY a.xnType,isnull(b.xn_type_alias,a.xntype),b.xntypeOrder,b.xntypeMode
				ORDER BY b.xntypeOrder
	
				SELECT a.*,'+@cCbsExpr+' [Closing Stock] FROM 
				(
				SELECT * FROM  
				(
				SELECT '+@cLayOutCols+',convert(varchar(max),'''') image,barcode_img_id img_id,x.xn_type xntype,
				s1.slabName shelfAgeingSlab,s2.slabName purAgeingSlab,sum(cbs_qty) xnQty 
			    FROM '+@cPmtOpsTableName+' a (NOLOCK)
				JOIN  sku_names (NOLOCK) ON sku_names.product_code=a.product_code'+
			  ' JOIN location loc (NOLOCK) ON  loc.dept_id=a.dept_id LEFT JOIN #priceCategory pc ON sku_names.mrp BETWEEN pc.fromMrp AND pc.toMrp '+
			  ' JOIN #tmpAgeSlabs s1 ON a.shelf_ageing_days between S1.fromdays AND s1.todays '+
			  ' JOIN #tmpAgeSlabs s2 ON a.purchase_ageing_days between S2.fromdays AND s2.todays '+
			  ' LEFT JOIN sku_xfp sx (NOLOCK) ON sx.product_code=sku_names.product_code AND sx.dept_id=a.dept_id'+
			  ' JOIN #tmpXnTypes x ON x.XN_TYPE_alias=''OPS'' WHERE '+@cFilter+
			  ' group by '+@cGrpCols+',s1.slabName,s2.slabName,barcode_img_id,x.xn_type
			    UNION ALL 
				SELECT '+@cLayOutCols+',convert(varchar(max),'''') image,barcode_img_id img_id,x.xn_type xntype,
				s1.slabName shelfAgeingSlab,s2.slabName purAgeingSlab,sum(cbs_qty) xnQty 
			    FROM #pmtops a (NOLOCK)
				JOIN  sku_names sn (NOLOCK) ON sn.product_code=a.product_code'+
			  ' JOIN #tmpAgeSlabs s1 ON a.shelf_ageing_days between S1.fromdays AND s1.todays '+
			  ' JOIN #tmpAgeSlabs s2 ON a.purchase_ageing_days between S2.fromdays AND s2.todays '+
			  ' JOIN location loc (NOLOCK) ON  loc.dept_id=a.dept_id LEFT JOIN #priceCategory pc ON sn.mrp BETWEEN pc.fromMrp AND pc.toMrp '+
			  ' LEFT JOIN sku_xfp sx (NOLOCK) ON sx.product_code=sn.product_code AND sx.dept_id=a.dept_id'+
			  ' JOIN #tmpXnTypes x ON x.XN_TYPE_alias=''OPS'''+
			  ' group by '+@cGrpCols+',s1.slabName,s2.slabName,barcode_img_id,x.xn_type
			    UNION ALL 
				SELECT * FROM #tmpXnsDetails
				) a '+
			  ' PIVOT (SUM(xnqty) for xnType in ('+@cXntypeStr+')) as pvt )a  '+
			   ' DROP TABLE #pmtOps DROP TABLE #tmpXnsDetails'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd


	
	SET @cStep='90'
	exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0
	SELECT * FROM @tMasterCols


	if len(@cImageCols)>1
		SET @cImageCols=SUBSTRING(@cImageCols,1,len(@cImageCols)-1)

	SELECT @cImageCols imageCols

	SET @cStep='100'
	exec sp_chkxnsavelog 'qtyAnalysis',@cStep,0,@nSpId,'',0
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_DBQTY_ANALYSIS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	IF ISNULL(@cErrormsg,'')<>''
		SELECT @cErrormsg ERRMSG
END