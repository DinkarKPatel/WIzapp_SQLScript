CREATE PROCEDURE SP3S_UPDATESCHEME_BARCODES_INFO
AS
BEGIN
	DECLARE @DXNDT DATETIME,@cStep VARCHAR(5),@CSCHEMENAME varchar (500)

	SET @DXNDT=CONVERT(DATE,GETDATE())

BEGIN TRY
	SET @cStep='10'

	TRUNCATE TABLE BARCODEWISE_EOSS_SCHEMES_INFO
	SET @cStep='15'
	PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)

	INSERT BARCODEWISE_EOSS_SCHEMES_INFO	(location_id,product_code,Eoss_Scheme_Name,Eoss_Discount_pct,Eoss_Discount_amt,Eoss_Category ) 	
	SELECT g.dept_id, A.PRODUCT_CODE,b.scheme_name eoss_scheme_name, (CASE WHEN b.disc_method=1 THEN a.discount_percentage WHEN b.disc_method=2 THEN 
	round(((sku.mrp-a.net_price)/sku.mrp)*100,2) ELSE ROUND((a.discount_amount/sku.mrp)*100,2) END) ,
	(CASE WHEN b.disc_method=1 THEN round((sku.mrp*a.discount_percentage/100),2) WHEN b.disc_method=2 THEN 
	 (sku.mrp-a.net_price) ELSE a.discount_amount END),'Discounted' eoss_category
	FROM SCHEME_SETUP_SLSBC A (NOLOCK)  
	JOIN SCHEME_SETUP_DET B (NOLOCK) ON B.ROW_ID=A.SCHEME_SETUP_DET_ROW_ID  
	JOIN SCHEME_SETUP_MST C (NOLOCK) ON  C.MEMO_NO= B.MEMO_NO  
	JOIN SCHEME_SETUP_LOC G (NOLOCK) ON G.MEMO_NO=C.MEMO_NO  
	JOIN sku_names sku (NOLOCK) ON sku.product_code=a.product_code
	WHERE b.scheme_mode=1 AND B.FILTER_MODE=2 AND C.INACTIVE=0 AND @DXNDT BETWEEN c.applicable_from_dt AND c.applicable_to_dt
	AND loc_applicable_mode=2

	SET @cStep='20'
	PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
	INSERT BARCODEWISE_EOSS_SCHEMES_INFO	(location_id,product_code,Eoss_Scheme_Name,Eoss_Discount_pct,Eoss_Discount_amt,Eoss_Category ) 	
	SELECT g.dept_id,a.PRODUCT_CODE,b.scheme_name Eoss_Scheme_Name,(CASE WHEN b.disc_method=1 THEN a.discount_percentage WHEN b.disc_method=2 THEN 
	round(((sku.mrp-a.net_price)/sku.mrp)*100,2) ELSE ROUND((a.discount_amount/sku.mrp)*100,2) END) ,
	(CASE WHEN b.disc_method=1 THEN round((sku.mrp*a.discount_percentage/100),2) WHEN b.disc_method=2 THEN 
	 (sku.mrp-a.net_price) ELSE a.discount_amount END),'Discounted'  Eoss_Category
	FROM SCHEME_SETUP_SLSBC A (NOLOCK)  
	JOIN SCHEME_SETUP_DET B (NOLOCK) ON B.ROW_ID=A.SCHEME_SETUP_DET_ROW_ID  
	JOIN SCHEME_SETUP_MST C (NOLOCK) ON  C.MEMO_NO= B.MEMO_NO  
	JOIN location G (NOLOCK) ON 1=1
	JOIN sku_names sku (NOLOCK) ON sku.product_code=a.product_code
	LEFT JOIN BARCODEWISE_EOSS_SCHEMES_INFO bci (nolock) on bci.location_id=g.dept_id AND bci.product_code=a.product_code
	WHERE b.scheme_mode=1 AND B.FILTER_MODE=2 AND C.INACTIVE=0 AND @DXNDT BETWEEN c.applicable_from_dt AND c.applicable_to_dt
	AND loc_applicable_mode=1 AND bci.product_code IS NULL

	SET @cStep='22'
	INSERT BARCODEWISE_EOSS_SCHEMES_INFO	(location_id,product_code,Eoss_Scheme_Name,Eoss_Discount_pct,Eoss_Discount_amt,Eoss_Category ) 	
	SELECT g.dept_id,a.PRODUCT_CODE,b.scheme_name Eoss_Scheme_Name,0 ,0,'Discounted'  Eoss_Category
	FROM SCHEME_SETUP_SLSBC A (NOLOCK)  
	JOIN SCHEME_SETUP_DET B (NOLOCK) ON B.ROW_ID=A.SCHEME_SETUP_DET_ROW_ID  
	JOIN SCHEME_SETUP_MST C (NOLOCK) ON  C.MEMO_NO= B.MEMO_NO  
	JOIN location G (NOLOCK) ON 1=1
	JOIN sku_names sku (NOLOCK) ON sku.product_code=a.product_code
	LEFT JOIN BARCODEWISE_EOSS_SCHEMES_INFO bci (nolock) on bci.location_id=g.dept_id AND bci.product_code=a.product_code
	WHERE b.scheme_mode=2 AND B.FILTER_MODE=2 AND C.INACTIVE=0 AND @DXNDT BETWEEN c.applicable_from_dt AND c.applicable_to_dt
	AND loc_applicable_mode=1 AND bci.product_code IS NULL

	SET @cStep='25'
	INSERT BARCODEWISE_EOSS_SCHEMES_INFO	(location_id,product_code,Eoss_Scheme_Name,Eoss_Discount_pct,Eoss_Discount_amt,Eoss_Category ) 	
	SELECT g.dept_id,a.PRODUCT_CODE,b.scheme_name Eoss_Scheme_Name,0 ,0,'Discounted'  Eoss_Category
	FROM SCHEME_SETUP_SLSBC_GET A (NOLOCK)  
	JOIN SCHEME_SETUP_DET B (NOLOCK) ON B.ROW_ID=A.SCHEME_SETUP_DET_ROW_ID  
	JOIN SCHEME_SETUP_MST C (NOLOCK) ON  C.MEMO_NO= B.MEMO_NO  
	JOIN scheme_Setup_loc G (NOLOCK) ON g.memo_no=b.memo_no
	JOIN sku_names sku (NOLOCK) ON sku.product_code=a.product_code
	LEFT JOIN BARCODEWISE_EOSS_SCHEMES_INFO bci (nolock) on bci.location_id=g.dept_id AND bci.product_code=a.product_code
	WHERE b.scheme_mode=2 AND B.GET_FILTER_MODE=2 AND C.INACTIVE=0 AND @DXNDT BETWEEN c.applicable_from_dt AND c.applicable_to_dt
	AND loc_applicable_mode=2 AND bci.product_code IS NULL

	SET @cStep='30'
	PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
	SELECT DISTINCT A.ROW_ID,A.SCHEME_NAME,PROCESSING_ORDER,a.promotional_scheme_id,
	FILTER_MODE,ISNULL(GET_FILTER_MODE,0) AS GET_FILTER_MODE,A.SCHEME_MODE,A.DISC_METHOD,A.DISCOUNT_PERCENTAGE,
	A.NET_PRICE,A.DISCOUNT_AMOUNT,A.BUY_FILTER_CRITERIA,A.GET_FILTER_CRITERIA,D.MEMO_NO,MEMO_PROCESSING_ORDER,d.loc_applicable_mode
	INTO #TMPNONBCSCHEMES
	FROM SCHEME_SETUP_DET A (NOLOCK)
	JOIN SCHEME_SETUP_MST D (NOLOCK) ON D.MEMO_NO=A.MEMO_NO
	WHERE @DXNDT BETWEEN D.APPLICABLE_FROM_DT AND D.APPLICABLE_TO_DT AND (A.SCHEME_MODE=2 OR A.FILTER_MODE<>2) 
	AND D.INACTIVE=0 AND LEFT(a.promotional_scheme_id,4)<>'SCHB'
	ORDER BY D.MEMO_PROCESSING_ORDER,D.MEMO_NO DESC,PROCESSING_ORDER
	

	--select 'check #TMPNONBCSCHEMES',* from #TMPNONBCSCHEMES

	SET @cStep='40'
	PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
	DECLARE @bFlag BIT,@NFILTERMODE INT,@NGETFILTERMODE INT,@NSCHEMEMODE INT,
	@DISC_METHOD VARCHAR(2),@NNETPRICE NUMERIC(10,2),@NDISCAMT NUMERIC(10,2),@cFilter VARCHAR(MAX),@cBuyFilter VARCHAR(MAX),@cGetFilter VARCHAR(MAX),
	@cCmd NVARCHAR(MAX),@DISCOUNT_PERCENTAGE NUMERIC(10,2),@nLocApplicableMode INT,@cMemoNo varchar(20),@CJOINSTRBUY VARCHAR(MAX),
	@CJOINSTRGET VARCHAR(MAX),@cErrormsg VARCHAR(MAX),@cSchemeRowId VARCHAR(50),@cPromoSchemeId VARCHAR(10),@nSchemeLoop INT,@nLoop INT

	
	SET @cStep='44'
	SELECT distinct product_code,dept_id INTO #tmppmt FROM pmt01106 (NOLOCK)
	where quantity_in_stock>0

	SET @cStep='47'
	INSERT INTO #tmppmt (dept_id,product_code)
	SELECT distinct b.dept_id, a.product_code FROM pid01106 a (NOLOCK) 
	JOIN pim01106 b (NOLOCK) ON a.mrr_id=b.mrr_id
	LEFT JOIN #tmppmt c ON c.product_code=a.product_code  AND c.DEPT_ID=b.dept_id
	WHERE b.receipt_dt>=DATEADD(MM,-6,GETDATE()) AND c.product_code IS NULL
	
	INSERT INTO #tmppmt (dept_id,product_code)
	SELECT distinct b.party_dept_id, a.product_code FROM ind01106 a (NOLOCK) 
	JOIN inm01106 b (NOLOCK) ON a.inv_id=b.inv_id
	JOIN pim01106 m (NOLOCK) ON m.inv_id=b.inv_id
	LEFT JOIN #tmppmt c ON c.product_code=a.product_code AND c.DEPT_ID=b.party_dept_id
	WHERE m.receipt_dt>=DATEADD(MM,-6,GETDATE()) AND c.product_code IS NULL

	--if @@spid=524
	--	select 'check #tmppmt',* from #tmppmt where product_code='KK252367@00180373802'

	CREATE INDEX id_tmppmt on #tmppmt (product_code)

	WHILE EXISTS (SELECT TOP 1 row_id FROM #TMPNONBCSCHEMES)
	BEGIN
		SET @cStep='50'
		PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
		SELECT TOP 1 @cSchemeRowId=row_id, @NSCHEMEMODE=ISNULL(SCHEME_MODE,0),@DISCOUNT_PERCENTAGE=ISNULL(DISCOUNT_PERCENTAGE,0),@cPromoSchemeId=promotional_scheme_id,
		@DISC_METHOD=ISNULL(DISC_METHOD,0),@NNETPRICE=ISNULL(NET_PRICE,0),@nFiltermode=filter_mode,@NGETFILTERMODE=get_filter_mode,
		@NDISCAMT=ISNULL(DISCOUNT_AMOUNT,0),@cBuyFilter=ISNULL(BUY_FILTER_CRITERIA,''),@cGetFilter=ISNULL(GET_FILTER_CRITERIA,''),
		@nLocApplicableMode=loc_applicable_mode,@cSchemeName=scheme_name ,@cMemoNo=memo_no
		FROM #TMPNONBCSCHEMES
		ORDER BY MEMO_PROCESSING_ORDER,MEMO_NO DESC,PROCESSING_ORDER
		

		PRINT 'Processing data for Scheme :'+@cSchemeName
		SET @nSchemeLoop=(CASE WHEN @cPromoSchemeId='SCH0015' THEN 2 ELSE 1 END)

		IF @NFILTERMODE=1 --- FILTER BASED
		BEGIN
			SET @cStep='52'
			PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
			SET @nLoop=1
			WHILE @nLoop<= @nSchemeLoop
			BEGIN
				SET @cFilter=(CASE WHEN @nLoop=1 THEN @cBuyFilter ELSE @cGetFilter END)

				SET @CFILTER = REPLACE(@cFilter,'INV_NO','PURCHASE_BILL_NO')
				SET @CFILTER = REPLACE(@CFILTER,'INV_DT','PURCHASE_BILL_DT')

				IF isnull(@CFILTER,'') =''
				 Set @CFILTER= '1=1'

				--if @cSchemename='cb20'
				--select @CSCHEMENAME,@nSchemeMode,@DISC_METHOD,@DISCOUNT_PERCENTAGE,@NNETPRICE,@NDISCAMT,@nLocApplicableMode,@cMemoNo
				SET @cStep='55'	
				PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
				SET @CCMD=N'SELECT DISTINCT  c.dept_id, itv.PRODUCT_CODE,'''+@CSCHEMENAME+''' Eoss_Scheme_Name,'+
							(CASE WHEN @nSchemeMode=1 THEN '(CASE WHEN '+@DISC_METHOD+'=1 THEN '+STR(@DISCOUNT_PERCENTAGE,10,2)+' WHEN '+@DISC_METHOD+'=2 THEN 
								round(((itv.mrp-'+str(@NNETPRICE,10,2)+')/itv.mrp)*100,2) ELSE ROUND(('+str(@NDISCAMT,10,2)+'/itv.mrp)*100,2) END)' 
								ELSE '0' END)+' Eoss_Discount_pct ,'+
							(CASE WHEN @nSchemeMode=1 THEN '(CASE WHEN '+@DISC_METHOD+'=1 THEN round((itv.mrp*'+str(@DISCOUNT_PERCENTAGE,6,2)+'/100),2) 
									WHEN '+@DISC_METHOD+'=2 THEN (itv.mrp-'+str(@NNETPRICE,10,2)+') ELSE '+STR(@NDISCAMT,10,2)+' END)' ELSE '0' END)+ 
									' Eoss_Discount_amt,''Discounted'' Eoss_Category
								FROM #tmppmt pmt JOIN sku_names itv (NOLOCK) ON itv.product_code=pmt.product_code '+ (CASE WHEN @nLocApplicableMode=1 THEN 
								' JOIN location c (NOLOCK) ON c.dept_id=c.dept_id ' ELSE ' join SCHEME_SETUP_LOC  c (NOLOCK) on c.memo_no='''+ @cMemoNo+''' and c.dept_id=pmt.dept_id' END)+
								' LEFT JOIN BARCODEWISE_EOSS_SCHEMES_INFO b (NOLOCK) ON b.product_code=pmt.product_code and b.location_id=c.dept_id
								WHERE '+  @CFILTER +' AND itv.mrp>0 AND b.product_code IS NULL'
				
				PRINT 'aNIL' + @cCmd

				INSERT BARCODEWISE_EOSS_SCHEMES_INFO(location_id,product_code,Eoss_Scheme_Name,Eoss_Discount_pct,Eoss_Discount_amt,Eoss_Category )
				EXEC SP_EXECUTESQL @cCmd

				SET @nLoop=@nLoop+1
			END
		END
		ELSE
		IF @NFILTERMODE=6 or (@cPromoSchemeId='SCH0015' AND (@NGETFILTERMODE=3 OR @NFILTERMODE=3))
		BEGIN
			SET @cStep='60'
			PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
			EXEC SP3S_EOSS_GETSCHEMES_PARA_COMBINATION
			@SCHEME_SETUP_DET_ROW_ID=@cSchemeRowId,
			@CJOINSTRBUY=@CJOINSTRBUY OUTPUT,
			@CJOINSTRGET=@CJOINSTRGET OUTPUT,
			@CERRORMSG=@CERRORMSG OUTPUT
					

			IF ISNULL(@CERRORMSG,'')<>''
				GOTO END_PROC

			SET @nSchemeLoop=(CASE WHEN @cPromoSchemeId='SCH0015' THEN 2 ELSE 1 END)
			
			SET @nLoop=1
			WHILE @nLoop<=@nSchemeLoop
			BEGIN
				
				IF @cPromoSchemeId='SCH0015' 
				BEGIN
					IF ((@nLoop=1 AND @NFILTERMODE<>3) OR (@nLoop=2 AND @NGETFILTERMODE<>3))
						Continue
				END

				SET @cStep='70'
				PRINT 'Running step#'+@cStep+'@'+convert(varchar,getdate(),113)
				SET @CCMD=N'SELECT DISTINCT c.dept_id, itv.PRODUCT_CODE,'''+@CSCHEMENAME+''' Eoss_Scheme_Name,'+
							(CASE WHEN @nSchemeMode=1 THEN '(CASE WHEN sc.discount_mode=1 THEN sc.discount_figure 
							WHEN sc.discount_mode=2 THEN 
								round(((itv.mrp-sc.discount_figure)/itv.mrp)*100,2) ELSE ROUND((sc.discount_figure/itv.mrp)*100,2) END)' ELSE '0' END)+' Eoss_Discount_pct ,'+
							(CASE WHEN @nSchemeMode=1 THEN '(CASE WHEN sc.discount_mode=1 THEN round((itv.mrp*sc.discount_figure/100),2) 
									WHEN sc.discount_mode=2 THEN (itv.mrp-sc.discount_figure) ELSE sc.discount_figure END) ' ELSE '0' END)+
									' Eoss_Discount_amt,''Discounted'' Eoss_Category
								FROM #tmppmt pmt JOIN sku_names itv (NOLOCK) ON itv.product_code=pmt.product_code '+@cJoinStrBuy+
								(CASE WHEN @nLocApplicableMode=1 THEN ' JOIN location c (NOLOCK) ON c.dept_id=c.dept_id ' 
									  ELSE ' join SCHEME_SETUP_LOC  c (NOLOCK) on c.memo_no='''+ @cMemoNo+''' and c.dept_id=pmt.dept_id' END)+
								' LEFT JOIN BARCODEWISE_EOSS_SCHEMES_INFO b (NOLOCK) ON b.product_code=pmt.product_code and b.location_id=c.dept_id
								WHERE sc.scheme_Setup_det_row_id='''+@cSchemeRowId+''' AND itv.mrp>0 AND b.product_code IS NULL'
				
				PRINT	@cCmd
				INSERT BARCODEWISE_EOSS_SCHEMES_INFO(location_id,product_code,Eoss_Scheme_Name,Eoss_Discount_pct,Eoss_Discount_amt,Eoss_Category )
				EXEC SP_EXECUTESQL @cCmd
			
				SET @nLoop=@nLoop+1
			END
		END

		DELETE FROM #TMPNONBCSCHEMES where row_id=@cSchemeRowId
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATESCHEME_BARCODES_INFO at Scheme Name :' + ISNULL(@CSCHEMENAME,'')+ ' Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT ISNULL(@cErrormsg,'') errmsg
END



