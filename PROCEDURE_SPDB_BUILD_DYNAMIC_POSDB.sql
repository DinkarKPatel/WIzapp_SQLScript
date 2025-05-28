CREATE PROCEDURE SPDB_BUILD_DYNAMIC_POSDB
@dFromDt DATETIME='',
@dToDt DATETIME='',
@cSetupIdPara VARCHAR(10)=''
WITH ENCRYPTION
AS
BEGIN
	DECLARE @dCutoffDate DATETIME,@cErrormsg VARCHAR(MAX),@cDashBoardDbName VARCHAR(300),
	@CFILEPATH VARCHAR(500),@CCMD NVARCHAR(MAX),@CCMD1 NVARCHAR(MAX),@cDbTableNameXnDt VARCHAR(200),@bLoop BIT,@cSetupId VARCHAR(10),
	@cParaName VARCHAR(max),@cFilter VARCHAR(MAX),@cPmtTableName VARCHAR(500),@dLyXnDt DATETIME,
	@cFinyear VARCHAR(5),@cPrevFinyear VARCHAR(5),@cMonth VARCHAR(3),@cPrevPmtTableName VARCHAR(200),
	@bDonotPopData BIT,@dFinyearFromDt DATETIME,@NDAYSCNT NUMERIC(5,2),@NdAYScNTSTD NUMERIC(5,2),@cStep varchar(5),@cSetupName VARCHAR(300),
	@dFirstDateCurMonth DATETIME,@NdAYScNTMTD NUMERIC(5,2),@cHavingFilter VARCHAR(500),@cOrgHavingFilter VARCHAR(500),@dSeasondEndDt DATETIME,
	@cWC VARCHAR(1000),@cPrevWC VARCHAR(1000),@nInnerLoop NUMERIC(1,0),@bSeasonApplicable BIT,@dMonthFromDt DATETIME,@cGrpParaname VARCHAR(200),
	@dAdiFromDt DATETIME,@nCntLoop NUMERIC(1,0),@bFirstAdi BIT,@cAdiInsCols VARCHAR(1000),@cAdiInsColsVal VARCHAR(1000),
	@cAdiUpdCols VARCHAR(1000),@cAdiColsVal VARCHAR(100),@dMinXndt DATETIME,@dFirstPurDt DATETIME,@dFirstSaleDt DATETIME,@cText VARCHAR(500),
	@nEndLoopCnt NUMERIC(1,0) ,@cDtFilter VARCHAR(500),@dStartBuildDt DATETIME,@cGrpExpr VARCHAR(400),@cSorTable VARCHAR(200),
	@cHoLocId CHAR(2)
	
BEGIN TRY		
	SET @cStep='10'
	SET @cErrormsg=''
	
	SET @dStartBuildDt=@dFromDt
	IF NOT EXISTS (SELECT TOP 1 * FROM pos_dynamic_dashboard_setup)
	BEGIN
		GOTO END_PROC
	END
	
	IF @cSetupIdPara='KYB0001' AND @dFromDt=''
		SET @dFromDt=CONVERT(DATE,GETDATE()-1)

	IF NOT EXISTS (SELECT TOP 1 * FROM new_app_login_info (NOLOCK) WHERE spid=@@spid)
		INSERT new_app_login_info	( BIN_ID, COMPUTER_NAME, DEPT_ID, LAST_UPDATE, LOGIN_NAME, PROCESS_ID, SPID, 
		STATIC_IP, WINDOW_USER_NAME )  
		SELECT top 1 '000' BIN_ID,'' COMPUTER_NAME,value as DEPT_ID,getdate() LAST_UPDATE,'' LOGIN_NAME, 
		0 PROCESS_ID,@@spid SPID,'' STATIC_IP, 
		'' WINDOW_USER_NAME FROM config where config_option='ho_location_id'
	ELSE
		UPDATE new_app_login_info WITH (ROWLOCK) SET dept_id=(select top 1 value from config (nolock)
		where config_option='ho_location_id') where spid=@@spid
	
	SELECT TOP 1 @cHoLocId=value FROM config where config_option='ho_location_id'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	IF @dToDt='' 
		SET @dToDt=CONVERT(DATE,GETDATE()-1)	

	IF (@cSetupIdPara<>'' OR @dFromDt='') AND @cSetupIdPara<>'KYB0001'
	BEGIN
		SELECT @dFirstPurDt=MIN(receipt_Dt) from pim01106 where receipt_Dt<>''
		SELECT @dFirstSaleDt=MIN(cm_Dt) from CMM01106

		IF ISNULL(@dFirstPurDt,'')<ISNULL(@dFirstSaleDt,'') AND ISNULL(@dFirstPurDt,'')<>''
			SET @dMinXndt=@dFirstPurDt
		ELSE
			SET @dMinXndt=@dFirstSaleDt

		SELECT @dCutoffDate=DATEADD(YY,-1,CONVERT(DATE,GETDATE()-1))
		SELECT @cFinyear='01'+DBO.FN_GETFINYEAR(@dCutoffDate)
		SET @dCutoffDate=CONVERT(DATE,DBO.FN_GETFINYEARDATE(@CFINYEAR,1),110)

		SET @dFromDt=(CASE WHEN @dCutoffDate<@dMinXndt THEN @dMinXndt ELSE @dCutoffDate END)
	END
	
		
	SET @cStep='13'
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	IF @dFromDt<'2018-04-01'
		SET @dFromDt='2018-04-01'
		
	IF @dToDt<@dFromDt
		SET @dToDt=@dFromDt
	
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	IF OBJECT_ID('tempdb..#tmpDbSetup','U') IS NOT NULL
		DROP TABLE #tmpDbSetup

	SELECT setup_id,para_name,filter_criteria,setup_name,additional_filter_criteria INTO #tmpDbSetup 
	FROM pos_dynamic_dashboard_setup WHERE 1=2
	
	SELECT convert(char(2),'') dept_id,ytd_value as gross_profit,ytd_value as net_profit,ytd_value as sales
	INTO #tProfit from  pos_dynamic_dbdata (NOLOCK) WHERE 1=2

	SET @cStep='14.5'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
	SET @bLoop=0
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
		
	DECLARE @dSeasonStartDt DATETIME,@nDisplayMode NUMERIC(1,0),@CStdStr VARCHAR(MAX),@cPrevStdStr VARCHAR(MAX),
	@CMtdStr VARCHAR(MAX),@cPrevMtdStr VARCHAR(MAX),@cYtdStr VARCHAR(MAX),@cPrevYtdStr VARCHAR(MAX)


	IF OBJECT_ID('tempdb..#pos_dynamic_dbdata','u') IS NOT NULL
		DROP TABLE #pos_dynamic_dbdata
	
	SET @cStep='14.8'
	CREATE TABLE #pos_dynamic_dbdata (setup_id VARCHAR(10) NOT NULL,db_dt DATETIME,mtd_ytd NUMERIC(1,0),para_name varchar(1000),
						sold_qty NUMERIC(38,2),cbs_stk NUMERIC(38,2),cbp NUMERIC(38,2),nrv numeric(38,2),no_of_bills numeric(38,2),
						net_sale_pp NUMERIC(38,2),SELL_THRU numeric(38,2),adi numeric(38,2),tpy numeric(38,2),
						days_of_stock numeric(38,0),profit_amt numeric(38,2),
						profit_pct numeric(20,2),gmroi numeric(20,2),[abs] numeric(20,2),ATS NUMERIC(14,2),
						asd numeric(20,2),taxable_value NUMERIC(14,2),
						discount_sale_ratio numeric(20,2),wizclip_discount_sale_ratio numeric(20,2),
						asp numeric(20,2),ads_nrv numeric(20,2),ads_nrv_psf numeric(20,2),total_discount numeric(20,2),wizclip_discount numeric(20,2),wizclip_sale NUMERIC(20,2),wizclip_sale_contribution NUMERIC(20,2),
						nrv_psfpd NUMERIC(20,2),profit_psfpd NUMERIC(20,2),old_stock NUMERIC(20,2),
						new_stock NUMERIC(20,2),ageing_purchase NUMERIC(20,2))

	IF OBJECT_ID('tempdb..#pos_dynamic_dbdata_partial','u') IS NOT NULL
		DROP TABLE #pos_dynamic_dbdata_partial
	
	SET @cStep='15.2'
	CREATE TABLE #pos_dynamic_dbdata_partial (setup_id VARCHAR(10) NOT NULL,mtd_ytd NUMERIC(1,0),para_name varchar(1000),
						sold_qty NUMERIC(20,2),nrv numeric(20,2),no_of_bills numeric(20,2),
						net_sale_pp NUMERIC(20,2),asd numeric(20,2),slr_qty numeric(20,2),taxable_value numeric(20,2),
						total_discount numeric(20,2),wizclip_discount numeric(20,2),wizclip_sale numeric(20,2) )
								

	SET @bSeasonApplicable=0
	
	IF EXISTS (SELECT TOP 1 * FROM POS_DB_SEASONS)
		SET @bSeasonApplicable=1
		
	SELECT @nCntLoop=1,@nEndLoopCnt=1
	
	SET @cStep='15.6'
	EXEC SP3S_BUILDADICOLS_NEW @dFromDt,@dToDt,@cSetupIdPara
	
	SET @nEndLoopCnt=1
	
	SET @cStep='18'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	CREATE TABLE #tSor (sor_tablename varchar(200),errmsg varchar(500))
	
	DECLARE @cExpenseHeads VARCHAR(2000),@cSaleHeads VARCHAR(2000),@cBankHeads VARCHAR(2000),
	@cCashHeads VARCHAR(2000),@cDebtorHeads VARCHAR(4000),@cCreditorHeads VARCHAR(4000)

	
	SELECT @cExpenseHeads=dbo.FN_ACT_TRAVTREE('0000000008')+','+dbo.FN_ACT_TRAVTREE('0000000025'),
	@cBankHeads=dbo.FN_ACT_TRAVTREE('0000000013'),@cSaleHeads=dbo.FN_ACT_TRAVTREE('0000000030'),
	@cCashHeads=dbo.FN_ACT_TRAVTREE('0000000014'),@cDebtorHeads=dbo.FN_ACT_TRAVTREE('0000000018'),
	@cCreditorHeads=dbo.FN_ACT_TRAVTREE('0000000021')

	SELECT head_code INTO #tmpExpheads FROM hd01106 WHERE charindex(head_code,@cExpenseHeads)>0

	SELECT head_code INTO #tmpBankheads FROM hd01106 WHERE charindex(head_code,@cBankHeads)>0

	SELECT head_code INTO #tmpSaleheads FROM hd01106 WHERE charindex(head_code,@cSaleHeads)>0

	SELECT head_code INTO #tmpCashheads FROM hd01106 WHERE charindex(head_code,@cCashHeads)>0

	SELECT head_code INTO #tmpDebtorheads FROM hd01106 WHERE charindex(head_code,@cDebtorHeads)>0

	SELECT head_code INTO #tmpCreditorheads FROM hd01106 WHERE charindex(head_code,@cCreditorHeads)>0

	UPDATE eosssorm SET dashboard_built=1	WHERE @dFromDt BETWEEN PERIOD_FROM AND PERIOD_TO
			
	print 'start picking sor'
	exec SP3S_PENDING_EOSS_SOR
	@DFROMDT=@dFromDt,
	@DTODT=@dToDt,
	@cLoginDeptId=@cHoLocId

	print 'end picking sor'

	SELECT @cSorTable=sor_tablename,@cErrormsg=errmsg FROM  #tSor

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	
	--SELECT @cSorTable='sor_pay_'+ltrim(rtrim(str(@@spid)))

	SET @cStep='18.5'
	SET @cCmd=N'UPDATE a SET net_payable=c.net_payable FROM cmd01106 a WITH (ROWLOCK)
				JOIN cmm01106 b (NOLOCK) ON b.cm_id=a.cm_id
				JOIN '+@cSorTable+' c ON c.cm_no=b.cm_no AND c.cm_dt=b.cm_dt AND c.product_code=a.product_code'
	EXEC SP_EXECUTESQL @cCmd

	WHILE @nCntLoop<=@nEndLoopCnt
	BEGIN
						
		WHILE @dFromDt<=@dToDt
		BEGIN
			SET @cSetupId=''
			
			
			SELECT @dSeasonStartDt=from_dt FROM pos_db_seasons WHERE month(@dFromDt) BETWEEN month(from_dt) AND month(to_Dt)
			AND day(@dFromDt) BETWEEN day(from_dt) AND day(to_Dt)
	
			SET @cStep='22'
			EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

			INSERT #tmpDbSetup	(  setup_id,filter_criteria, para_name,setup_name ) 
			SELECT 	  setup_id,filter_criteria, para_name,setup_name FROM pos_dynamic_dashboard_setup
			WHERE setup_id=@cSetupIdPara OR (@cSetupIdPara='' AND dashboard_mode=1) or setup_id='KYB0001' 
			
			SELECT @cPmtTableName=DB_NAME()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dFromDt,112)

			DELETE a FROM pos_dynamic_dbdata a JOIN #tmpDbSetup b ON a.setup_id=b.setup_id
			WHERE db_dt=@dFromDt
			
			SET @cStep='25'
			print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
			
			SET @cStep='41'
			EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

			SET @cSetupId=''
			WHILE EXISTS (SELECT TOP 1 * FROm #tmpDbSetup)
			BEGIN
				SELECT TOP 1 @cSetupId=setup_id,@cParaName=para_name,@cFilter=filter_criteria,@cSetupname=setup_name,
				@cOrgHavingFilter=ISNULL(additional_filter_criteria,'')
				FROM #tmpDbSetup
						
				IF ISNULL(@cSetupId,'')=''
					BREAK		
				
				IF @cFilter=''
					SET @cFilter='1=1'
				
				IF @cSetupId='KYB0001'
					SELECT @cFilter=@cFilter+' AND isnull(sku_item_type,0) IN (0,1)',@cParaName='dept_id'

				SET @cGrpParaname=@cParaName

				IF @cParaName='dept_name'
					SELECT @cParaName='location.dept_id+''-''+dept_name',@cGrpParaname='location.dept_id,dept_name'
				ELSE
				IF @cParaName='dept_id'
					SELECT @cParaName='location.dept_id',@cGrpParaName='location.dept_id'
				ELSE
				IF @cParaName='POSDB_PRICECATEGORY'
					SELECT @cParaName='category_name',@cGrpParaname='CATEGORY_NAME',@cFilter=' sn.mrp BETWEEN mrp_from AND mrp_to'
					
				SET @cFilter=REPLACE(@cFilter,'dept_id','location.dept_id')
									
				print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
				
				SELECT @dLyXnDt=DATEADD(YY,-1,@dFromDt),@cMonth=LTRIM(RTRIM(STR(MONTH(@dFromDt))))
				SELECT @cFinyear='01'+DBO.FN_GETFINYEAR(@dFromDt),@cPrevFinyear='01'+DBO.FN_GETFINYEAR(@dLyXnDt)
								
				SET @dMonthFromDt=DATEADD(DAY, -(DAY(@dFromDt)), @dFromDt)+1
				
				SET @cStep='44'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				SET @dFinyearFromDt=CONVERT(DATE,DBO.FN_GETFINYEARDATE(@CFINYEAR,1),110)
				
				SELECT @cMtdStr=N'b.fin_year='''+@cFinyear+''' AND  MONTH(b.cm_dt)='+@cMonth+' AND b.cm_dt<='''+CONVERT(VARCHAR,@dFromDt,110)+'''',
						@cPrevMtdStr=N'b.fin_year='''+@cPrevFinyear+''' AND  MONTH(b.cm_dt)='+@cMonth+' AND b.cm_dt<='''+CONVERT(VARCHAR,@dFromDt,110)+'''',
						@NdAYScNTMTD=DAY(@dFromDt)

				SELECT @dSeasonStartDt=from_dt FROM pos_db_seasons WHERE month(@dFromDt) BETWEEN month(from_dt) AND month(to_Dt)
				AND day(@dFromDt) BETWEEN day(from_dt) AND day(to_Dt)

				SET @dSeasonStartDt=DATEADD(YY,DATEDIFF(YY,@dSeasonStartDt,@dFinyearFromDt),@dSeasonStartDt)
				
				SET @NdAYScNTSTD=DAtediff(dd,@dSeasonStartDt,@dFromDt)+1

				SELECT @cStdStr=N' b.cm_dt BETWEEN '''+CONVERT(VARCHAR,@dSeasonStartDt,110)+''' AND '''+CONVERT(VARCHAR,@dFromDt,110)+'''',
						@cPrevStdStr=N' b.cm_dt BETWEEN '''+CONVERT(VARCHAR,DATEADD(yy,-1,@dSeasonStartDt),110)+''' AND '''+CONVERT(VARCHAR,DATEADD(yy,-1,@dFromDt),110)+''''
				 

				SELECT @cYtdStr=N'b.fin_year='''+@cFinyear+'''  AND b.cm_dt<='''+CONVERT(VARCHAR,@dFromDt,110)+'''',
				@cPrevYtdStr=N'b.fin_year='''+@cPrevFinyear+''' AND b.cm_dt<='''+CONVERT(VARCHAR,@dLyXnDt,110)+''''
								 
				SET @cStep='48'		
				print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
													
				print 'Populating Dashboard data for Setup :'+@cSetupname+' Dated:'+convert(varchar,@dFromDt,113)				
				SET @cHavingFilter=(CASE WHEN @cOrgHavingFilter<>'' THEN ' HAVING '+@cOrgHavingFilter ELSE '' END)
				
				
				SELECT @nInnerLoop=(CASE WHEN @cSetupid='KYB0001' THEN 3 ELSE 1 END)

				SELECT @cGrpExpr=' GROUP BY '+@cGrpParaname

				WHILE @nInnerLoop<=3
				BEGIN
						
					SELECT @cWC=(CASE WHEN @nInnerLoop=1 THEN @CMtdsTR WHEN @nInnerLoop=2 THEN @CStdsTR  ELSE  @CYtdsTR end)
						
					SET @cStep='55'
					EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

					DECLARE @cKybStr VARCHAR(1000),@cKybStrCols varchar(200)
					SET @cKybStr=(CASE WHEN @cSetupId='KYB0001' THEN ',SUM(cmm_discount_amount+a.discount_amount) as total_discount,
									SUM(CASE WHEN ecoupon_id<>'''' then cmm_discount_amount ELSE 0 END) AS wizclip_discount,
									SUM(CASE WHEN ecoupon_id<>'''' then rfnet ELSE 0 END) AS wizclip_sale'
									ELSE ',0 as total_discount,0 as wizclip_discount,0 as wizclip_sale' END)

					print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
					SET @CCMD=N'SELECT '''+@cSetupId+''' as setup_id,'+str(@nInnerLoop)+' AS mtd_ytd,'+@cParaName+' as para_name,
								SUM(a.quantity) AS sold_qty,SUM(rfnet) AS nrv,SUM(xn_value_without_gst) AS taxable_value,
								SUM(WeightedQtyBillCount) AS no_of_bills,
								SUM(a.quantity*((ISNULL(net_payable,sn.pp)/quantity)-isnull(fdn.pp,0))) AS net_sale_pp,
								sum(case when quantity>0 then selling_days*quantity else 0 end) as asd,
								SUM(case when quantity<0 then abs(quantity) else 0 end) as slr_qty'+
								@cKybStr+'
								FROM cmd01106 a (NOLOCK) 
								JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
								JOIN sku_names sn (NOLOCK) ON a.product_code=sn.product_code
								JOIN dtm (NOLOCK) ON dtm.dt_code=b.dt_code
								JOIN location (NOLOCK) On location.dept_id=LEFT(b.cm_id,2)
								LEFT OUTER JOIN 
								(SELECT product_code,SUM(purchase_price) as pp FROM 
									rmd01106 a (NOLOCK) 
									JOIN rmm01106 b (NOLOCK) ON a.rm_id=b.rm_id 
									WHERE cancelled=0 AND dn_type=2		
									GROUP BY product_code												
								) fdn ON fdn.product_code=a.product_code
								--LEFT OUTER JOIN pos_db_pricecategory pdp (NOLOCK) ON 1=1							
								WHERE '+@cWC+' AND b.cancelled=0
								AND '+@cFilter+@cGrpExpr+@cHavingFilter
						
					PRINT @cCmd
					INSERT #pos_dynamic_dbdata_partial (setup_id,mtd_ytd,para_name,sold_qty,nrv,taxable_value,no_of_bills,
					net_sale_pp,asd,slr_qty,total_discount,wizclip_discount,wizclip_sale)
					EXEC SP_EXECUTESQL @cCmd
					---- We have to run this step because of exact calculation required for KYB for all Locations
					---- which comes wrong if we apply further aggregation of data collected Location wise in above query					
					IF @nInnerLoop=3 AND @cSetupId='KYB0001'
					BEGIN
						print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
						SET @CCMD=N'SELECT '''+@cSetupId+''' as setup_id,'+str(@nInnerLoop)+' AS mtd_ytd,''All'' as para_name,
									SUM(quantity) as sold_qty,0 slr_qty,
									sum(case when quantity>0 then selling_days*quantity else 0 end) as asd
									FROM cmd01106 a (NOLOCK) 
									JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
									WHERE '+@cWC+' AND b.cancelled=0'
						
						PRINT @cCmd
						INSERT #pos_dynamic_dbdata_partial (setup_id,mtd_ytd,para_name,sold_qty,slr_qty,asd)
						EXEC SP_EXECUTESQL @cCmd
						
					END
						
					SET @nInnerLoop=@nInnerLoop+1
				END
						
				SET @cStep='60'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				INSERT #pos_dynamic_dbdata (setup_id,db_dt,mtd_ytd,para_name,sold_qty,nrv,taxable_value,no_of_bills,net_sale_pp,
				asd,total_discount,wizclip_discount,wizclip_sale)
				SELECT setup_id,@dFromDt as db_dt,mtd_ytd,para_name,SUM(sold_qty),SUM(nrv),SUM(taxable_value),SUM(no_of_bills),
				SUM(net_sale_pp),sum(asd)/(CASE WHEN sum(sold_qty+slr_qty)>0 then sum(sold_qty+slr_qty) else 1 end),
				sum(total_discount),sum(wizclip_discount),sum(wizclip_sale)
				FROM #pos_dynamic_dbdata_partial
				GROUP BY setup_id,mtd_ytd,para_name

				TRUNCATE TABLE #pos_dynamic_dbdata_partial

				SET @cStep='62'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
					
				SELECT @NDAYSCNT=DATEDIFF(DD,@dFinyearFromDt,@dFromDt)+1
					
					
				SELECT @nInnerLoop=(CASE WHEN @cSetupid='KYB0001' THEN 3 ELSE 1 END)

				WHILE @nInnerLoop<=3
				BEGIN
					SET @cStep='65'
					EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

						
					set @cDtFilter=(CASE WHEN @nInnerloop=1 THEN REPLACE(@cMtdStr,'cm_dt','xn_dt')
									WHEN @nInnerloop=2 THEN REPLACE(@cStdStr,'cm_dt','xn_dt')
									ELSE REPLACE(@cYtdStr,'cm_dt','xn_dt') END)

					SET @cCmd=N'UPDATE a SET adi=b.adi  FROM #pos_dynamic_dbdata a
					JOIN  (SELECT para_name,AVG(cbp) AS adi
							FROM adicumcbp b (NOLOCK)
							WHERE '+@cDtFilter+'
							GROUP BY para_name) b ON b.para_name=a.para_name
							WHERE mtd_ytd='+ltrim(rtrim(str(@nInnerLoop)))

					PRINT @cCmd
					EXEC SP_EXECUTESQL @cCmd		

					SET @cStep='67'
					SET @cCmd=N'UPDATE a SET cbs_stk=b.cbs_stk  FROM #pos_dynamic_dbdata a
					JOIN  (SELECT '+@cParaName+' as para_name,sum(cbs_qty) AS cbs_stk
							FROM '+@cPmtTableName+' b (NOLOCK)
							JOIN sku_names sn (NOLOCk) ON sn.product_code=b.product_code
							JOIN location (NOLOCK) ON location.dept_id=b.dept_id
							WHERE '+@cFilter+@cgrpExpr+'
							) b ON b.para_name=a.para_name
							WHERE mtd_ytd='+ltrim(rtrim(str(@nInnerLoop)))

					PRINT @cCmd
					EXEC SP_EXECUTESQL @cCmd	
						
						
					print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)

					SET @nInnerLoop=@nInnerLoop+1					
				END
					
				SET @cStep='70'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				set @cText='Start step:'+ @cStep+' '+convert(varchar,getdate(),113)+' :'+str(isnull(@nDayscnt,0))+':'+
				str(isnull(@NdAYScNTMTD,0))+':'+str(isnull(@NdAYScNTSTD,0))+':'+convert(varchar,@dSeasonStartDt,110)
					
				print @cText
					
				UPDATE #pos_dynamic_dbdata SET 
				sell_thru=(CASE WHEN (sold_qty+cbs_stk)<>0 THEN (sold_qty/(sold_qty+cbs_stk))*100.0 ELSE 0 END)
				,profit_pct=(CASE WHEN nrv<>0 THEN ((nrv-net_sale_pp)/nrv)*100.0 else 0 end)
				,profit_amt=(nrv-net_sale_pp) 
				,GMROI=(CASE WHEN adi<>0 THEN ((nrv-net_sale_pp)*365.0/(ADI*convert(numeric(20,2),
				(CASE WHEN mtd_ytd=1 
				THEN @NdAYScNTMTD WHEN mtd_ytd=2 THEN @NdAYScNTSTD else @NDAYSCNT END))))*100.0 else 0 end)
				,TPY=(CASE WHEN ADI<>0 THEN (convert(numeric(20,2),net_sale_pp)*365.0)/(convert(numeric(20,2),ADI)*convert(numeric(20,2),@NDAYSCNT)) else 0 end)
				,[abs]=(CASE WHEN no_of_bills<>0 THEN (convert(numeric(20,2),sold_qty)/convert(numeric(20,2),no_of_bills)) else 0 end)
				,ats=(CASE WHEN no_of_bills<>0 THEN (convert(numeric(20,2),nrv)/convert(numeric(20,2),no_of_bills)) else 0 end)
				,days_of_stock=(CASE WHEN sold_qty<>0 THEN ROUND(cbs_stk/(sold_qty/(CASE WHEN mtd_ytd=1 
				THEN @NdAYScNTMTD WHEN mtd_ytd=2 THEN @NdAYScNTSTD else @NDAYSCNT END)),0) else 0 end)

				--if @dFromDt='2019-09-18'
				--	select 'check kpi',* from #pos_dynamic_dbdata where para_name='BLACK BERRY MOHAN' 

				SET @cStep='73'
				print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)+' :'+str(@nDayscnt)
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'ABS' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN 
				CONVERT(NUMERIC(20,2),[abs]) ELSE CONVERT(NUMERIC(20,2),0) END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  CONVERT(NUMERIC(20,2),[abs]) ELSE CONVERT(NUMERIC(20,2),0) END) as Ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[abs]) ELSE CONVERT(NUMERIC(20,2),0) END) as Std_value
					
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='75'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'ATS' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  [ats] ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  [ats] ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[aTs]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='77'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'SELL THRU' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  sell_thru ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  sell_thru ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[SELL_THRU]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='79'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'PROFIT AMOUNT' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  profit_amt ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  profit_amt ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[PROFIT_AMT]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='81'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'PROFIT%' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  profit_pct ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  profit_pct ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[PROFIT_PCT]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='83'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'GMROI' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  GMROI ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  GMROI ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[GMROI]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='85'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'TPY' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=2 THEN  TPY ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  TPY ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[TPY]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='87'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'ADI' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  CONVERT(NUMERIC(20,2),ADI) ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  CONVERT(NUMERIC(20,2),ADI) ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[adi]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='89'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'Days of Stock' AS kpi_name,para_name,
				SUM(CASE WHEN mtd_ytd=1 THEN  days_of_stock ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  days_of_stock ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[days_of_stock]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='91'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'SALE' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  NRV ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  NRV ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[nrv]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='95'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'No. of Bills' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  no_of_bills ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  no_of_bills ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[no_of_bills]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
			
				SET @cStep='98'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'Sale Qty' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  sold_qty ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  sold_qty ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[sold_qty]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='102'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'Cost of Goods Sold' AS kpi_name,para_name,SUM(CASE WHEN mtd_ytd=1 THEN  net_sale_pp ELSE 0 END) as mtd_value,
				SUM(CASE WHEN mtd_ytd=3 THEN  net_sale_pp ELSE 0 END) as ytd_value,
				SUM(CASE WHEN mtd_ytd=2 THEN  CONVERT(NUMERIC(20,2),[net_sale_pp]) ELSE CONVERT(NUMERIC(20,2),0) END) as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
					
				SET @cStep='105'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'NRV_COLOR_CODE' AS kpi_name,para_name,0 as mtd_value,1 AS ytd_value,
				0 as std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='107'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'GMROI_COLOR_CODE' AS kpi_name,para_name,0 as mtd_value,1 AS ytd_value,0 std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name

				SET @cStep='109'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
				SELECT setup_id,db_Dt,'PROFIT_COLOR_CODE' AS kpi_name,para_name,0 as mtd_value,1 AS ytd_value,0 std_value
				FROM #pos_dynamic_dbdata
				GROUP BY setup_id,db_Dt,para_name
																													
				SET @cStep='112'	
				print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)

				SET  @cCmd=N'SELECT '''+@cSetupId+''' as setup_id,'''+CONVERT(VARCHAR,@dFromDt,110)+''' as xn_Dt,
				''STOCK'' AS kpi_name,'+@cParaName+' as para_name,
				SUM(cbs_qty) as ytd_value FROM '+@cPmtTableName+' a (NOLOCK)
				JOIN sku_names sn(NOLOCK) ON sn.product_code=a.product_code
				LEFT OUTER JOIN pos_db_pricecategory pdp (NOLOCK) ON 1=1
				JOIN location (NOLOCK) ON location.dept_id=a.dept_id
				JOIN #pos_dynamic_dbdata b ON b.para_name='+(CASE WHEN @cSetupId<>'KYB0001' THEN 'sn.' ELSE '' END)+
				@cparaName+' WHERE '+@cFilter+@cGrpExpr
				
				PRINT @cCmd
				SET @cStep='112.5'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,ytd_value)
				EXEC SP_EXECUTESQL @cCmd
				
				IF @cSetupId='KYB0001'
				BEGIN
					SET @cStep='112.7'
					EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

					UPDATE a SET discount_sale_ratio=(total_discount/nrv)*100,
					wizclip_discount_sale_ratio=(wizclip_discount/nrv)*100,
					asp=nrv/sold_qty,
					ads_nrv=nrv/@NDAYSCNT,
					ads_nrv_psf = (CASE WHEN isnull(area_covered,0)<>0 THEN  (nrv/@NDAYSCNT)/isnull(area_covered,0) else 0 end),
					nrv_psfpd = (CASE WHEN isnull(area_covered,0)<>0 THEN  (nrv/@NDAYSCNT)/isnull(area_covered,0) else 0 end),
					profit_psfpd = (CASE WHEN isnull(area_covered,0)<>0 THEN  (profit_amt/@NDAYSCNT)/isnull(area_covered,0) else 0 end),
					Wizclip_Sale_Contribution=(CASE WHEN nrv<>0 THEN (Wizclip_Sale/nrv)*100 ELSE 0 END)
					FROM #pos_dynamic_dbdata a
					JOIN location b (NOLOCK) ON a.para_name=b.dept_id

					SET @cStep='112.9'
					EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

					SET  @cCmd=N'INSERT INTO #pos_dynamic_dbdata (setup_id,para_name,db_dt,old_stock,new_stock,ageing_purchase)
					SELECT '''+@cSetupId+''' as setup_id,'+@cParaName+','''+convert(varchar,@dFromDt,112)+''' as db_dt,
					SUM(CASE WHEN DATEDIFF(dd,sku.receipt_dt,'''+CONVERT(varchar,@dFromdt,112)+''')>180 THEN 
					cbs_qty ELSE 0 END) as old_stock,SUM(CASE WHEN DATEDIFF(dd,sku.receipt_dt,'''+
					CONVERT(varchar,@dFromDt,112)+''')<=180 THEN cbs_qty ELSE 0 END) as new_stock,
					SUM(cbs_qty*DATEDIFF(dd,sku.receipt_dt,'''+CONVERT(varchar,@dFromDt,112)+'''))/SUM(cbs_qty)
					FROM '+@cPmtTableName+' a (NOLOCK)
					JOIN sku_names sn(NOLOCK) ON sn.product_code=a.product_code
					JOIN sku (NOLOCK) ON sku.product_code=a.product_code
					LEFT OUTER JOIN pos_db_pricecategory pdp (NOLOCK) ON 1=1
					JOIN location (NOLOCK) ON location.dept_id=a.dept_id
					WHERE '+@cFilter+@cGrpExpr
				
					PRINT @cCmd
					SET @cStep='113.2'
					EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
					EXEC SP_EXECUTESQL @cCmd

				
					SET  @cCmd=N'INSERT INTO #pos_dynamic_dbdata (setup_id,para_name,db_dt,ageing_purchase)
					SELECT '''+@cSetupId+''' as setup_id,''ALL'' AS para_name,'''+convert(varchar,@dFromDt,112)+''' as db_dt,
					SUM(cbs_qty*DATEDIFF(dd,sku.receipt_dt,'''+CONVERT(varchar,@dFromDt,112)+'''))/SUM(cbs_qty)
					FROM '+@cPmtTableName+' a (NOLOCK)
					JOIN sku_names sn(NOLOCK) ON sn.product_code=a.product_code
					JOIN sku (NOLOCK) ON sku.product_code=a.product_code
					LEFT OUTER JOIN pos_db_pricecategory pdp (NOLOCK) ON 1=1
					WHERE '+@cFilter
				
					PRINT @cCmd
					SET @cStep='115'
					EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
					EXEC SP_EXECUTESQL @cCmd
					
					DELETE FROM #tProfit

					EXEC SPDB_GET_GPNP
					@dRepDt = @dFromDt,
					@cFinyear=@cFinYear


					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,mtd_value,ytd_value,Std_value)
					SELECT @cSetupId as setup_id,a.dept_id as para_name,@dFromDt as db_dt,'GP' as kpi_name,0 mtd_value,
					gross_profit as ytd_value,0 std_value
					FROM #tProfit a JOIN location (NOLOCK) ON a.dept_id=location.dept_id
					UNION ALL
					SELECT @cSetupId as setup_id,a.dept_id as para_name,@dFromdt as db_dt,'NP' as kpi_name,0 mtd_value,
					net_profit as ytd_value,0 std_value
					FROM #tProfit a JOIN location  (NOLOCK) ON a.dept_id=location.dept_id
						
					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,ytd_value)
					SELECT @cSetupId as setup_id,location.dept_id  as para_name,@dFromDt AS db_dt,'Expense' as kpi_name,
					a.expense from
					(
					SELECT cost_center_dept_id as dept_id,SUM(debit_amount-credit_amount) as expense FROM vd01106 a(NOLOCK)
					JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
					JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
					JOIN #tmpExpHeads d ON d.head_code=c.head_code
					where voucher_dt between @dFinyearFromDt AND @dFromDt 
					AND CANCELLED=0
					GROUP BY cost_center_dept_id
					) a	
					JOIN location (NOLOCK) ON location.dept_id=a.dept_id
					
					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,ytd_value)
					SELECT @cSetupId as setup_id,location.dept_id  as para_name,@dFromDt AS db_dt,
					'Account Sales' as kpi_name,a.sales
					FROM #tProfit a
					JOIN location (NOLOCK) on a.dept_id=location.dept_id
					
					SET @cStep='117'
					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,ytd_value)
					SELECT @cSetupId as setup_id,location.dept_id,@dFromDt as db_dt,'Cash in Hand' as kpi_name,
					SUM(debit_amount-credit_amount) FROM vd01106 a(NOLOCK)
					JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
					JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
					JOIN #tmpCashHeads d ON d.head_code=c.head_code
					JOIN location (NOLOCK) ON location.dept_id=a.cost_center_dept_id
					where voucher_dt <=@dFromDt AND CANCELLED=0
					GROUP BY location.dept_id

					SET @cStep='118.2'
					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,ytd_value)
					SELECT @cSetupId as setup_id,location.dept_id as para_name,@dFromDt as db_dt,'Funds in Bank' as kpi_name,
					SUM(debit_amount-credit_amount) FROM vd01106 a(NOLOCK)
					JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
					JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
					JOIN #tmpBankHeads d ON d.head_code=c.head_code
					JOIN location (NOLOCK) ON location.dept_id=a.cost_center_dept_id
					where voucher_dt<=@dFromDt AND CANCELLED=0
					GROUP BY location.dept_id

					SET @cStep='119'
					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,ytd_value)
					SELECT @cSetupId as setup_id,location.dept_id as para_name,@dFromDt AS db_dt,'Accounts Payable' as kpi_name,
					SUM(credit_amount-debit_amount) FROM vd01106 a(NOLOCK)
					JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
					JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
					JOIN #tmpCreditorHeads d ON d.head_code=c.head_code
					JOIN location (NOLOCK) ON location.dept_id=a.cost_center_dept_id
					where voucher_dt <=@dFromDt  AND CANCELLED=0
					GROUP BY location.dept_id

					SET @cStep='120'
					INSERT INTO pos_dynamic_dbdata (setup_id,para_name,db_dt,kpi_name,ytd_value)
					SELECT @cSetupId as setup_id,location.dept_id as para_name,@dFromDt as db_dt,'Accounts Receivable' as kpi_name,
					SUM(debit_amount-credit_amount) FROM vd01106 a(NOLOCK)
					JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
					JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
					JOIN #tmpDebtorHeads d ON d.head_code=c.head_code
					JOIN location (NOLOCK) ON location.dept_id=a.cost_center_dept_id
					where voucher_dt <=@dFromDt AND CANCELLED=0
					GROUP BY location.dept_id

					--select 'check data',* FROM #pos_dynamic_dbdata a

					SET @cStep='121'
					INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
					SELECT setup_id,db_Dt,'Wizclip Discount' AS kpi_name,para_name,
					0 as mtd_value,wizclip_discount as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata a
					WHERE ISNULL(wizclip_discount,0)<>0
					UNION ALL
					SELECT setup_id,db_Dt,'Total Discount' AS kpi_name,para_name,
					0 as mtd_value,total_discount as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata WHERE ISNULL(total_discount,0)<>0
					UNION ALL
					SELECT setup_id,db_Dt,'Wizclip Sale' AS kpi_name,para_name,
					0 as mtd_value,wizclip_sale as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata WHERE ISNULL(wizclip_sale_contribution,0)<>0
					UNION ALL
					SELECT setup_id,db_Dt,'New Stock' AS kpi_name,para_name,
					0 as mtd_value,new_stock as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata WHERE ISNULL(new_stock,0)<>0
					UNION ALL
					SELECT setup_id,db_Dt,'Closing Stock' AS kpi_name,para_name,
					0 as mtd_value,cbs_stk as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata WHERE ISNULL(cbs_stk,0)<>0
					UNION ALL
					SELECT setup_id,db_Dt,'Old Stock' AS kpi_name,para_name,
					0 as mtd_value,old_stock as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata WHERE ISNULL(old_stock,0)<>0
					
					SET @cStep='121.3'
					INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
					SELECT a.setup_id,a.db_Dt,'Ageing(Purchase)' AS kpi_name,a.para_name,
					0 as mtd_value,(ageing_purchase) as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata a (NOLOCK) 
					JOIN pos_dynamic_dbdata b (NOLOCK) ON a.db_dt=b.db_dt and a.setup_id=b.setup_id
					AND a.para_name=b.para_name
					WHERE ISNULL(ageing_purchase,0)<>0 AND b.kpi_name='stock'
					AND a.para_name<>'ALL'
					UNION ALL
					SELECT a.setup_id,a.db_Dt,'Ageing(Purchase)' AS kpi_name,a.para_name,
					0 as mtd_value,(ageing_purchase) as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata a (NOLOCK) 
					WHERE ISNULL(ageing_purchase,0)<>0
					AND a.para_name='ALL'

					SET @cStep='121.7'
					INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,mtd_value,ytd_value,Std_value)
					SELECT a.setup_id,a.db_Dt,'ASD' AS kpi_name,a.para_name,
					0 as mtd_value,asd as ytd_value,0 as std_value
					FROM #pos_dynamic_dbdata a (NOLOCK) 
					WHERE ISNULL(asd,0)<>0

					SET @cStep='121.9'
					INSERT INTO pos_dynamic_dbdata (setup_id,db_dt,kpi_name,para_name,ytd_value)
					SELECT @cSetupId as setup_id,@dFromDt as db_dt,'Active Sq. ft. Area' as kpi_name,
					a.dept_id as para_name,(isnull(area_covered,0)) ytd_value FROM location a (nolock) 
					JOIN (SELECT LEFT(cm_id,2) as dept_id,min(cm_dt) as min_cm_dt from cmm01106 (nolock)
						  where cancelled=0 and cm_dt<=@dFromDt GROUP BY left(cm_id,2)) b ON a.dept_id=b.dept_id
					where ISNULL(area_covered,0)<>0
				END
							
				TRUNCATE TABLE #pos_dynamic_dbdata									

				SET @cStep='122'
				EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
				DELETE FROM  #tmpDbSetup WHERE setup_id=@cSetupId					
			
			END


			SET @cStep='123'
			DELETE FROM posdb_pmtstk_log WHERE xn_dt=@dFromDt

			SET @cCmd=N'INSERT posdb_pmtstk_log (xn_dt,dept_id,cbs_qty)
						SELECT '''+convert(varchar,@dFromDt,110)+''' as xn_dt,dept_id,sum(cbs_qty) as cbs_qty FROM '+@cPmtTableName+' (NOLOCK)	
						GROUP BY dept_id'
			EXEC SP_EXECUTESQL @cCmd

			SET @dFromDt=@dFromDt+1	
			set @cStep='125'
			print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
							
		END	
	
		SET @nCntLoop=@nCntLoop+1

	
		set @cStep='127'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		;with cteDUp
		as
		(select *,ROW_NUMBER() over (PARTITION by setup_id,db_dt,para_name,kpi_name ORDER by kpi_name) as rno from pos_dynamic_dbdata)
		delete from cteDUp where rno>1
		
		set @cStep='130'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		TRUNCATE TABLE #tmpDbSetup

		INSERT #tmpDbSetup	(  setup_id,filter_criteria, para_name,setup_name ) 
		SELECT 	  setup_id,filter_criteria, para_name,setup_name FROM pos_dynamic_dashboard_setup
		WHERE setup_id=@cSetupIdPara OR @cSetupIdPara=''
				
		DELETE a FROM pos_dynamic_dbdata_summary a JOIN #tmpDbSetup b ON a.setup_id=b.setup_id
		WHERE db_dt=@dFromDt
				

		UPDATE a SET min_value=b.min_value,max_value=b.max_value,avg_value=b.avg_value,total_value=b.total_value,total_records=b.total_records FROM 
		pos_dynamic_dbdata_summary a
		JOIN 
		(SELECT setup_id,kpi_name,db_dt,min(ytd_value) as min_value,MAX(ytd_value) as max_value,
		avg(ytd_value) as avg_value,SUM(ytd_value) as total_value,COUNT(*) as total_records FROM 
		pos_dynamic_dbdata (NOLOCK) WHERE db_dt BETWEEN @dFromDt AND @dToDt
		AND kpi_name IN ('SALE','GMROI','PROFIT AMOUNT')
		GROUP BY setup_id,kpi_name,db_dt) b
		ON a.setup_id=b.setup_id AND a.kpi_name=b.kpi_name AND a.db_Dt=b.db_dt
		
		set @cStep='147'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		INSERT INTO pos_dynamic_dbdata_summary (setup_id,kpi_name,db_dt,min_value,max_value,avg_value,total_value,total_records)
		SELECT a.setup_id,a.kpi_name,a.db_dt,a.min_value,a.max_value,a.avg_value ,A.total_value,A.total_records
		FROM 
		(SELECT setup_id,kpi_name,db_dt,min(ytd_value) as min_value,MAX(ytd_value) as max_value,
		avg(ytd_value) as avg_value,SUM(ytd_value) as total_value,COUNT(*) as total_records FROM 
		pos_dynamic_dbdata (NOLOCK) WHERE db_dt BETWEEN @dFromDt AND @dToDt
		AND kpi_name IN ('SALE','GMROI','PROFIT AMOUNT')
		
		GROUP BY setup_id,kpi_name,db_dt) a
		LEFT OUTER JOIN pos_dynamic_dbdata_summary b ON a.setup_id=b.setup_id AND 
		a.kpi_name=b.kpi_name AND a.db_Dt=b.db_dt
		WHERE b.kpi_name IS NULL

		set @cStep='149'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		update a SET ytd_value=(CASE WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 0 and 25 then 1
		WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 26 and 50 then 2
		WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 51 and 75 then 3 ELSE 4 END)
		from pos_dynamic_dbdata a 
		JOIN pos_dynamic_dbdata_summary b ON a.setup_id=b.setup_id and A.db_dt=B.DB_DT
		JOIN 
		(select setup_id,para_name,db_Dt,ROW_NUMBER() over (partition by setup_id,db_dt order by ytd_value desc) as rank_no from 
		 pos_dynamic_dbdata where kpi_name='SALE'
		 AND db_dt BETWEEN @dFromDt AND @dToDt ) c on c.setup_id=a.setup_id and c.para_name=a.para_name AND c.db_dt=a.db_dt
		 where a.kpi_name='nrv_color_code' AND B.KPI_NAME='SALE'


		set @cStep='155'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		update a SET ytd_value=(CASE WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 0 and 25 then 1
		WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 26 and 50 then 2
		WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 51 and 75 then 3 ELSE 4 END)
		from pos_dynamic_dbdata a 
		JOIN pos_dynamic_dbdata_summary b ON a.setup_id=b.setup_id and A.db_dt=B.DB_DT
		JOIN 
		(select setup_id,para_name,db_Dt,ROW_NUMBER() over (partition by setup_id,db_dt order by ytd_value desc) as rank_no from 
		 pos_dynamic_dbdata where kpi_name='GMROI' 
		 AND db_dt BETWEEN @dFromDt AND @dToDt) c on c.setup_id=a.setup_id and c.para_name=a.para_name AND c.db_dt=a.db_dt
		 where a.kpi_name='GMROI_color_code' AND B.KPI_NAME='gmroi'
		 
		set @cStep='160'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		update a SET ytd_value=(CASE WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 0 and 25 then 1
		WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 26 and 50 then 2
		WHEN  ROUND((C.rank_no/b.total_records)*100,0) BETWEEN 51 and 75 then 3 ELSE 4 END)
		from pos_dynamic_dbdata a 
		JOIN pos_dynamic_dbdata_summary b ON a.setup_id=b.setup_id and A.db_dt=B.DB_DT
		JOIN 
		(select setup_id,para_name,db_Dt,ROW_NUMBER() over (partition by setup_id,db_dt order by ytd_value desc) as rank_no from 
		 pos_dynamic_dbdata where kpi_name='PROFIT AMOUNT' 
		 AND db_dt BETWEEN @dFromDt AND @dToDt) c on c.setup_id=a.setup_id and c.para_name=a.para_name AND c.db_dt=a.db_dt
		 where a.kpi_name='PROFIT_color_code' AND B.KPI_NAME='PROFIT AMOUNT'

	END	 	 	  
							
	SET @cStep='165'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
	
	EXEC SPDB_build_PENDENCYDASHBOARD @cErrormsg OUTPUT

	IF NOT EXISTS (SELECT TOP 1 VALUE FROM config where config_option='cutoff_date_dashboard_rebuild')
		INSERT CONFIG	( config_option, value, row_id, last_update,  REMARKS )  
		SELECT 'cutoff_date_dashboard_rebuild' as config_option,GETDATE() as value,'' as row_id,
		GETDATE() as last_update,'' as REMARKS 
	ELSE
		UPDATE config SET value=GETDATE() WHERE config_option='cutoff_date_dashboard_rebuild'
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPDB_BUILD_DYNAMIC_POSDB at step#'+@cStep+' '+ERROR_MESSAGE()
END CATCH

END_PROC:
	SELECT @cErrormsg AS errmsg		
END
