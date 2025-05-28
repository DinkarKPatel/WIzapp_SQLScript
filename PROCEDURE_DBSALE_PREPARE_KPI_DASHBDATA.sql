create PROCEDURE DBSALE_PREPARE_KPI_DASHBDATA				
@dFromDt DATETIME,
@dToDt DATETIME
AS
BEGIN
	set datefirst 1 

	DECLARE @dStartDt DATETIME,@cFinYear varchar(5),@dLastYearDt DATETIME,@cLastFinYear VARCHAR(5),@dSourceDt DATETIME,@nDays NUMERIC(5,0),
			@nCnt NUMERIC(1,0),@cFilter VARCHAR(400),@cWeekStartDt varchar(10),@cWeekStartDtLy VARCHAR(10),@cStartDt VARCHAR(10),
			@cMonthStartDt VARCHAR(10),@cMonthStartDtLy VARCHAR(10),@cFinYearStartDt varchar(10),@cFinYearStartDtlY VARCHAR(10),
			@cQtrFromDt VARCHAR(10),@cQtrFromDtLy varchAr(10),@cStartDtLy VARCHAR(10),@cFilterLy VARCHAR(400),@cBaseCol VARCHAR(10),
			@cCmd NVARCHAR(MAX),@cStep VARCHAR(4),@cErrormsg VARCHAR(1000),@nLoop NUMERIC(1,0),@nWeekNo NUMERIC(2,0),@cWeekStr VARCHAR(200)
--PRGEN_DEFINE_WEEKS

BEGIN TRY	
	SET @cErrormsg=''
	
	SET @cStep='10'
	SET @nLoop=1
	
	
	SET @cStep='20'	
	IF OBJECT_ID('tempdb..#tmpSaleDb','u') IS NOT NULL
		DROP TABLE #tmpSaleDb
	
	print 'create tmpsaledb'
	SELECT *,cy_ytd as ppval,CONVERT(numeric(2,0),0) as week_no,db_dt as week_start_dt,db_dt as week_end_dt
	INTO #tmpSaleDb FROM dbsale_1 WHERE 1=2
	
	print 'created tmpsaledb'
	
lblStart:
	
	IF EXISTS (SELECT TOP 1 db_dt FROM dbsale_1 (NOLOCK) WHERE db_dt BETWEEN @dFromDt AND @dToDt)
		DELETE FROM dbsale_1 WITH (ROWLOCK)  WHERE db_dt BETWEEN @dFromDt AND @dToDt
	
	IF  EXISTS (SELECT TOP 1 db_dt FROM dbsale_2 (NOLOCK) WHERE db_dt BETWEEN @dFromDt AND @dToDt)
		DELETE FROM dbsale_2 WITH (ROWLOCK)  WHERE  db_dt BETWEEN @dFromDt AND @dToDt
	
	
	SET @dStartDt=@dFromDt
	
	WHILE @dStartDt<=@dToDt
	BEGIN
		SET @cStep='30'	
		SET @cFinYear='01'+DBO.FN_GETFINYEAR(@dStartDt)

		SET @dLastYearDt=DATEADD(YY,-1,@dStartDt)
		SET @cLastFinYear='01'+DBO.FN_GETFINYEAR(@dLastYearDt) 
			
		
		SELECT @cWeekStartDt = CONVERT(VARCHAR,CONVERT(DATE,DATEADD(dd, -(DATEPART(WEEKDAY, @dStartDt)-1),DATEADD(dd, DATEDIFF(dd, 0, @dStartDt), 0))),112),
		@cWeekStartDtLy = CONVERT(VARCHAR,CONVERT(DATE,DATEADD(dd, -(DATEPART(WEEKDAY, @dLastYearDt)-1),DATEADD(dd, DATEDIFF(dd, 0, @dLastYearDt), 0))),112),
		@cMonthStartDt =  CONVERT(VARCHAR,@dStartDt-DAY(@dStartDt)+1,112),
		@cMonthStartDtLy = CONVERT(VARCHAR,@dLastYearDt-DAY(@dLastYearDt)+1,112),
		@cStartDt=CONVERT(VARCHAR,@dStartDt,112),
		@cStartDtLy=CONVERT(VARCHAR,@dLastYearDt,112),
		@cFinYearStartDt=CONVERT(VARCHAR,DBO.FN_GETFINYEARDATE(@cFinyear,1),112),
		@cFinYearStartDtlY=CONVERT(VARCHAR,DBO.FN_GETFINYEARDATE(@cLastFinYear,1),112),
		@cQtrFromDt = CONVERT(VARCHAR,DATEADD(qq, DATEDIFF(qq, 0, @dStartDt), 0),112),
		@cQtrFromDtLY = CONVERT(VARCHAR,DATEADD(qq, DATEDIFF(qq, 0,@dLastYearDt), 0),112)
		
		SET @nCnt=1
		SET @cStep='40'	
		WHILE @nCnt<=5
		BEGIN
			
			
			print 'Enter for Date: '+@cStartDt+' filter : '+str(@nCnt)
			
			SELECT @cFilter=(CASE WHEN @nCnt=1 THEN ' CM_DT='''+CONVERT(VARCHAR,@dStartDt,110)+''''
							   WHEN @nCnt=2 THEN ' CM_DT BETWEEN  '''+@cWeekStartDt+''' AND '''+@cStartDt+''''
							   WHEN @nCnt=3 THEN ' CM_DT BETWEEN  '''+@cMOnthStartDt+''' AND '''+@cStartDt+''''
							   WHEN @nCnt=4 THEN ' CM_DT BETWEEN  '''+@cQtrFromDt+''' AND '''+@cStartDt+''''
							   ELSE ' CM_DT BETWEEN  '''+@cFinYearStartDt+''' AND '''+@cStartDt+'''' END),
				   @cFilterLy=(CASE WHEN @nCnt=1 THEN ' CM_DT='''+CONVERT(VARCHAR,@dLastYearDt,110)+''''
							   WHEN @nCnt=2 THEN ' CM_DT BETWEEN  '''+@cWeekStartDtLy+''' AND '''+@cStartDtLy+''''
							   WHEN @nCnt=3 THEN ' CM_DT BETWEEN  '''+@cMOnthStartDtLy+''' AND '''+@cStartDtLy+''''
							   WHEN @nCnt=4 THEN ' CM_DT BETWEEN  '''+@cQtrFromDtLy+''' AND '''+@cStartDtLy+''''
							   ELSE ' CM_DT BETWEEN  '''+@cFinYearStartDtLy+''' AND '''+@cStartDtLy+'''' END),
				   @cBaseCol = (CASE WHEN @nCnt=1 THEN 'ftd'
									 WHEN @nCnt=2 THEN 'wtd'
									 WHEN @nCnt=3 THEN 'mtd'
									 WHEN @nCnt=4 THEN 'qtd'
									 ELSE 'ytd' END)				   	
			
			--IF @nLoop=2
			--	SELECT @nWeekNo=DATEPART(WW,@dStartDt),@cWeekStr=','+str(@nWeekNo)+','''+@cWeekStartDt+''','''+@cStartDt+''''
			--ELSE
			--	SELECT @nWeekNo=0,@cWeekStr=',0,'''','''''
													
			SET @cStep='50'					    	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+',ppval,cogs,fdn,discountdebit)
			SELECT ''SALE'',b.location_code as dept_id,'''+@cStartDt+''',SUM(rfnet) as cy_ytd,
			SUM((a.quantity*(ISNULL(sord.net_payable,c.pp)-isnull(fdn.pp,0)))-((CASE WHEN ISNULL(a.sor_terms_code,'''')<>'''' 
				 THEN basic_discount_amount ELSE 0 END)+(CASE WHEN ISNULL(dtm.dtm_type,0)=2 
				 THEN a.cmm_discount_amount ELSE 0 END))) AS  ppval,
			SUM(a.quantity*c.pp) as cogs,sum(a.quantity*isnull(fdn.pp,0)) as fdn,
			SUM((CASE WHEN ISNULL(a.sor_terms_code,'''')<>'''' 
				 THEN basic_discount_amount ELSE 0 END)+(CASE WHEN ISNULL(dtm.dtm_type,0)=2 
				 THEN a.cmm_discount_amount ELSE 0 END)) as discountdebit
			FROM cmd01106 a (NOLOCK) 
			JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
			JOIN sku_names c (NOLOCK) ON c.product_Code=a.PRODUCT_CODE
			JOIN dtm (NOLOCK) ON dtm.dt_code=b.dt_code
			LEFT OUTER JOIN 
			(SELECT b.cm_no,b.cm_dt,product_code,SUM(net_payable) as net_payable FROM 
				eosssord sord (NOLOCK) 
				JOIN eosssorm sorm (NOLOCK) ON sorm.memo_id=sord.memo_id 
				JOIN cmm01106 b (NOLOCK) ON sord.cm_no=b.cm_no and sord.cm_dt=b.cm_dt
				WHERE '+REPLACE(@cFilter,'cm_dt','b.cm_dt')+' AND sorm.cancelled=0		
				GROUP BY b.cm_no,b.cm_dt,product_code												
			) sord ON sord.product_code=a.product_code AND sord.cm_no=b.cm_no AND sord.cm_dt=b.cm_dt

			LEFT OUTER JOIN 
			(SELECT a.product_code,SUM(purchase_price) as pp FROM 
				rmd01106 a (NOLOCK) 
				JOIN rmm01106 b (NOLOCK) ON a.rm_id=b.rm_id 
				JOIN (SELECT a.product_code FROM cmd01106 a (NOLOCK) 
				JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				join RMD01106 C (NOLOCK) ON c.product_code=a.product_code
				JOIN rmm01106 d (NOLOCK) ON d.rm_id=c.rm_id
				WHERE '+@cFilter+' and b.cancelled=0 AND d.dn_type=2
				GROUP BY a.product_code) c on c.product_code=a.product_code
				WHERE  b.cancelled=0 AND dn_type=2		
				GROUP BY a.product_code												
			) fdn ON fdn.product_code=a.product_code
			
			where '+REPLACE(@cFilter,'cm_dt','b.cm_dt')+'  AND CANCELLED=0
			GROUP BY b.location_code'
			
--			if @nCnt in (2,3,4)
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
			
			
			SET @cStep='60'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+',ppval,cogs,fdn,discountdebit)
			SELECT ''SALE'',b.location_code as dept_id,'''+@cStartDt+''',SUM(rfnet) as ly_'+@cBaseCol+',
			SUM((a.quantity*(ISNULL(sord.net_payable,c.pp)-isnull(fdn.pp,0)))-((CASE WHEN ISNULL(a.sor_terms_code,'''')<>'''' 
				 THEN basic_discount_amount ELSE 0 END)+(CASE WHEN ISNULL(dtm.dtm_type,0)=2 
				 THEN a.cmm_discount_amount ELSE 0 END))) as ppval,
			SUM(a.quantity*c.pp) as cogs,sum(a.quantity*isnull(fdn.pp,0)) as fdn,
			SUM((CASE WHEN ISNULL(a.sor_terms_code,'''')<>'''' 
				 THEN basic_discount_amount ELSE 0 END)+(CASE WHEN ISNULL(dtm.dtm_type,0)=2 
				 THEN a.cmm_discount_amount ELSE 0 END)) as discountdebit				 
			FROM cmd01106 a (NOLOCK) 
			JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
			JOIN sku_names c (NOLOCK) ON c.product_Code=a.PRODUCT_CODE
			JOIN dtm (NOLOCK) ON dtm.dt_code=b.dt_code
			LEFT OUTER JOIN 
			(SELECT b.cm_no,b.cm_dt,product_code,SUM(net_payable) as net_payable FROM 
				eosssord sord (NOLOCK) 
				JOIN eosssorm sorm (NOLOCK) ON sorm.memo_id=sord.memo_id 
				JOIN cmm01106 b (NOLOCK) ON sord.cm_no=b.cm_no and sord.cm_dt=b.cm_dt
				WHERE '+REPLACE(@cFilterLy,'cm_dt','b.cm_dt')+' AND sorm.cancelled=0		
				GROUP BY b.cm_no,b.cm_dt,product_code												
			) sord ON sord.product_code=a.product_code AND sord.cm_no=b.cm_no AND sord.cm_dt=b.cm_dt

			LEFT OUTER JOIN 
			(SELECT a.product_code,SUM(purchase_price) as pp FROM 
				rmd01106 a (NOLOCK) 
				JOIN rmm01106 b (NOLOCK) ON a.rm_id=b.rm_id 
				JOIN (SELECT a.product_code FROM cmd01106 a (NOLOCK) 
				JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				join RMD01106 C (NOLOCK) ON c.product_code=a.product_code
				JOIN rmm01106 d (NOLOCK) ON d.rm_id=c.rm_id
				WHERE '+@cFilterLy+' and b.cancelled=0 AND d.dn_type=2
				GROUP BY a.product_code) c on c.product_code=a.product_code
				WHERE  b.cancelled=0 AND dn_type=2		
				GROUP BY a.product_code												
			) fdn ON fdn.product_code=a.product_code
			
			where '+REPLACE(@cFilterLy,'cm_dt','b.cm_dt')+'  AND CANCELLED=0
			GROUP BY b.location_code'
									
--		if @nCnt in (2,3,4)
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
							
			SET @cStep='70'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+',ly_'+@cBaseCol+')
			SELECT ''GP'', dept_id,'''+@cStartDt+''',(CASE WHEN cy_'+@cBaseCol+'<>0 and ppval<>0 THEN  ((cy_'+@cBaseCol+'-ppval)/ppval)*100 ELSE 0 end)  as cy_'+@cBaseCol+',
			(CASE WHEN ly_'+@cBaseCol+'<>0 and ppval<>0 THEN  ((ly_'+@cBaseCol+'-ppval)/ppval)*100 ELSE 0 end)  as ly_'+@cBaseCol+'
			FROM #tmpSaleDb WHERE kpi_name=''SALE'''

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			IF @nCnt=1
			BEGIN
				SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+',ly_'+@cBaseCol+')
				SELECT ''PROFIT'', dept_id,'''+@cStartDt+''',(CASE WHEN cy_'+@cBaseCol+'<>0 THEN  (cy_'+@cBaseCol+'-ppval) ELSE 0 end)  as cy_'+@cBaseCol+',
				(CASE WHEN ly_'+@cBaseCol+'<>0 THEN  (ly_'+@cBaseCol+'-ppval) ELSE 0 end)  as ly_'+@cBaseCol+'
				FROM #tmpSaleDb WHERE kpi_name=''SALE'''

				if @nCnt in (2,3,4)
				print @cCmd
				
				EXEC SP_EXECUTESQL @cCmd
				
			end

						
			SET @cStep='80'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+')
			SELECT ''BILL COUNT'',location_code as dept_id,'''+@cStartDt+''',COUNT(cm_id) as cy_'+@cBaseCol+'
			FROM cmm01106  (NOLOCK) 
			where '+@cFilter+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='90'					
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+')
			SELECT ''BILL COUNT'',location_code as dept_id,'''+@cStartDt+''',COUNT(cm_id) as cy_'+@cBaseCol+'
			FROM cmm01106  (NOLOCK) 
			where '+@cFilterLy+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='100'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+')
			SELECT ''Units Sold'',location_code as dept_id,'''+@cStartDt+''',SUM(total_quantity) as cy_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilter+'  AND CANCELLED=0			
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='110'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+')
			SELECT ''Units Sold'',location_code as dept_id,'''+@cStartDt+''',SUM(total_quantity) as ly_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilterLy+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='120'		
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+')
			SELECT ''ABS'',location_code as dept_id,'''+@cStartDt+''',SUM(total_quantity)/COUNT(*) as cy_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilter+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='130'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+')
			SELECT ''ABS'',location_code as dept_id,'''+@cStartDt+''',SUM(total_quantity)/COUNT(*) as ly_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilterLy+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='140'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+')
			SELECT ''ATS'',location_code as dept_id,'''+@cStartDt+''',SUM(NET_AMOUNT-atd_charges)/COUNT(*) as cy_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilter+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='150'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+')
			SELECT ''ATS'',location_code as dept_id,'''+@cStartDt+''',SUM(NET_AMOUNT-atd_charges)/COUNT(*) as ly_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilterLy+'  AND CANCELLED=0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='160'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+')
			SELECT ''ASP'',location_code as dept_id,'''+@cStartDt+''',SUM(NET_AMOUNT-atd_charges)/SUM(TOTAL_QUANTITY) as cy_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilter+'  AND CANCELLED=0 and total_quantity<>0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='170'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+')
			SELECT ''ASP'',location_code as dept_id,'''+@cStartDt+''',SUM(NET_AMOUNT-atd_charges)/SUM(TOTAL_QUANTITY) as ly_'+@cBaseCol+'
			FROM cmm01106 (NOLOCK) 
			where '+@cFilterLy+'  AND CANCELLED=0 and total_quantity<>0
			GROUP BY location_code'

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='180'	
			SET @dSourceDt=(CASE WHEN @nCnt=1 THEN DATEADD(DD,-1,@dStartDt)
								 WHEN @nCnt=2 THEN CONVERT(DATE,@cWeekStartDt)
								 WHEN @nCnt=3 THEN CONVERT(DATE,@cMOnthStartDt)
								 WHEN @nCnt=4 THEN CONVERT(DATE,@cQtrFromDt)
								 ELSE CONVERT(DATE,@cFinYearStartDt) END)
								 
			SET @nDays=DATEDIFF(DD,@dSourceDt-1,@dStartDt)
			
			SET @cStep='190'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+',ly_'+@cBaseCol+')
			SELECT ''ADS (NRV)'',dept_id,'''+@cStartDt+''',cy_'+@cBaseCol+'/'+str(@nDays)+' as cy_'+@cBaseCol+',ly_'+@cBaseCol+'/'+str(@nDays)+' as ly_'+@cBaseCol+'
			FROM #tmpSaleDb
			where kpi_name=''SALE''' 

			if @nCnt in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='200'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+',ly_'+@cBaseCol+')
			SELECT ''ADS PSF (NRV)'',a.dept_id,'''+@cStartDt+''',
			cy_'+@cBaseCol+'/area_covered as cy_'+@cBaseCol+',
			ly_'+@cBaseCol+'/area_covered as ly_'+@cBaseCol+'
			FROM #tmpSaleDb a JOIN LOCATION b ON a.dept_id=b.dept_id
			where kpi_name=''ADS (NRV)'' AND ISNULL(area_covered,0)<>0'
			
			if @nCnt in (2,3,4)
			print @cCmd

			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='210'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,cy_'+@cBaseCol+')
			SELECT ''Total Discount'',b.location_code as dept_id,'''+@cStartDt+''',SUM(a.discount_amount+cmm_discount_amount)
			as cy_'+@cBaseCol+'
			FROM cmd01106 a (NOLOCK) 
			JOIN cmm01106 b (NOLOCK) on a.cm_id=b.cm_id
			where '+@cFilter+'  AND CANCELLED=0
			GROUP BY b.location_code'

			if @nCnt not in (2,3,4)
			print @cCmd
			
			EXEC SP_EXECUTESQL @cCmd
			
			SET @cStep='220'	
			SET @cCmd=N'INSERT #tmpSaleDb (kpi_name,dept_id,db_dt,ly_'+@cBaseCol+')
			SELECT ''Total Discount'',b.location_code as dept_id,'''+@cStartDt+''',SUM(a.discount_amount+cmm_discount_amount)
			as ly_'+@cBaseCol+'
			FROM cmd01106 a (NOLOCK) 
			JOIN cmm01106 b (NOLOCK) on a.cm_id=b.cm_id
			where '+@cFilterLy+'  AND CANCELLED=0
			GROUP BY b.location_code'
			
			if @nCnt not in (2,3,4)
			print @cCmd

			EXEC SP_EXECUTESQL @cCmd
			
			SET @nCnt=@nCnt+1
		END
		
lblInsDbSale:
		SET @cStep='230'	
	
			INSERT dbsale_1	( db_dt, dept_id, kpi_name,cy_ftd, cy_mtd, cy_qtd, cy_wtd, cy_ytd,  ly_ftd, ly_mtd, ly_qtd, ly_wtd, ly_ytd )  
			SELECT 	db_dt, dept_id, kpi_name,SUM(cy_ftd) as cy_ftd, SUM(cy_mtd) as cy_mtd, SUM(cy_qtd) as cy_qtd , SUM(cy_wtd) as cy_qtd ,
			SUM(cy_ytd) as cy_ytd , SUM(ly_ftd) as ly_ftd , SUM(ly_mtd) as ly_mtd, SUM(ly_qtd) as ly_qtd , SUM(ly_wtd) as ly_qtd , 
			SUM(ly_ytd) as ly_ytd
			
			FROM #tmpSaleDb where kpi_name NOT IN ('PROFIT') GROUP BY db_dt, dept_id, kpi_name

			INSERT dbsale_2	( dept_id, kpi_name,db_Dt,value )  
			SELECT 	dept_id, kpi_name,@dStartDt as db_dt,SUM(cy_ftd) as cy_ftd
			FROM #tmpSaleDb WHERE kpi_name IN ('SALE','PROFIT')
			GROUP BY dept_id, kpi_name
		
		
			
--		select * from #tmpSaleDb		
		TRUNCATE TABLE #tmpSaleDb
		SET @dStartDt=@dStartDt+1
	END
	
	GOTO END_PROC
END TRY		

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPDB_PREPARE_SALEDB_1 at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:	
	SELECT ISNULL(@cErrormsg,'') as errmsg
END