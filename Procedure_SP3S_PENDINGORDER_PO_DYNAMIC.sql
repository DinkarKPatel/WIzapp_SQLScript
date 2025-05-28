create PROCEDURE SP3S_PENDINGORDER_PO_DYNAMIC
(
	@CWHERE NVARCHAR(MAX)='',
	@dlogindt DateTime='',
	@cdept_id varchar(5)='h1',
	@BCALLEDFORPOMATERIAL BIT=0
)
AS
BEGIN



if @BCALLEDFORPOMATERIAL=1
begin

EXEC SP3S_PENDINGORDER_PO_MATERIAL @CWHERE,@DLOGINDT,@CDEPT_ID
RETURN

end


	DECLARE @CSIZE VARCHAR(MAX),@CSIZE_SUM VARCHAR(MAX),@CSIZE_SUM_TOTAL VARCHAR(MAX),@CCMD NVARCHAR(MAX),
	@CSIZE_ZERO NVARCHAR(MAX),@cJoinstr VARCHAR(MAX),@cConfigCols VARCHAR(2000),@cColList VARCHAR(2000),
	@cStep VARCHAR(5),@cErrormsg VARCHAR(1000),@cCurLocId VARCHAR(4),@cColListCodes varchar(2000),
	@cDONOT_CHKORDER_APPROVAL varchar(10)

BEGIN TRY
	SET @cStep='10'

	SELECT TOP 1 @cCurLocId=value FROM config (NOLOCK) WHERE config_option='location_id'
	select @cDONOT_CHKORDER_APPROVAL=value  from config where config_option ='DONOT_CHKORDER_APPROVAL'
	
	SET @CDONOT_CHKORDER_APPROVAL=ISNULL(@CDONOT_CHKORDER_APPROVAL,'')
	
	PRINT @CWHERE
	SET @CWHERE=REPLACE(@CWHERE,'`','''')
	
	SELECT	c.row_id ord_row_id,c.quantity order_qty,c.quantity pending_po_qty,
	CONVERT(VARCHAR(200),'') ARTICLE_NO,CONVERT(VARCHAR(200),'') ARTICLE_NAME,CONVERT(VARCHAR(200),a.product_code) product_code,
	CONVERT(VARCHAR(200),'') section_name,CONVERT(VARCHAR(200),'') sub_section_name,
	para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
	CONVERT(varchar(9),'') para1_code,CONVERT(varchar(9),'') para2_code,CONVERT(varchar(9),'') para3_code,CONVERT(varchar(9),'') para4_code,
	CONVERT(varchar(9),'') para5_code,CONVERT(varchar(9),'') para6_code,CONVERT(varchar(9),'') article_code,
	CONVERT(varchar(9),'') section_code,CONVERT(varchar(9),'') sub_section_code,
	c.row_id unq_id,cast('' as varchar(20)) as hsn_code,
	pl_qty=cast(0 as numeric (10,3)),
	po_qty=cast(0 as numeric (10,3)),
	INV_QTY=cast(0 as numeric (10,3))
	 INTO #PENDINGBUYERORDER	
	 FROM sku_names a (NOLOCK)
	 JOIN pmt01106 b (NOLOCK) ON a.product_Code=b.product_code
	 JOIN buyer_order_det c (NOLOCK) ON c.product_code=a.product_Code
	 WHERE 1=2

	 
	SELECT	b.quantity_in_stock order_qty
	,b.quantity_in_stock pending_po_qty,
	CONVERT(VARCHAR(200),'') ARTICLE_NO,CONVERT(VARCHAR(200),'') ARTICLE_NAME,CONVERT(VARCHAR(200),'') product_code,
	CONVERT(VARCHAR(200),'') section_name,CONVERT(VARCHAR(200),'') sub_section_name,
	para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
	para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,article_code,section_code,sub_section_code,
	a.unq_id,cast('' as varchar(20)) as hsn_code,b.quantity_in_stock stock_qty,
	pl_qty=cast(0 as numeric (10,3)),
	po_qty=cast(0 as numeric (10,3)),
	INV_QTY=cast(0 as numeric (10,3))
	 INTO #PENDINGBUYERORDER_stock	
	 FROM #PENDINGBUYERORDER a
	 JOIN pmt01106 b (NOLOCK) ON 1=1
	 WHERE 1=2

	 SET @cJoinstr=' 1=1 '
	SET @cStep='20'

	IF EXISTS (SELECT TOP 1 column_name FROM CONFIG_BUYERORDER (NOLOCK) WHERE isnull(open_key,0)=1
				and column_name='PRODUCT_CODE')
		SET @cConfigCols='a.product_code'
	ELSE
		SELECT @cConfigCols = coalesce(@cConfigCols+',','')+'a.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK) 
		WHERE isnull(open_key,0)=1

	SET @cStep='25'
	SELECT @cJoinstr=@cJoinstr+
		(CASE WHEN charindex('product_code',@cConfigCols)>0 THEN  ' AND b.product_code=c.product_code ' ELSE '' END)+	
	    (CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ' AND b.section_name=c.section_name ' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ' AND b.sub_section_name=c.sub_section_name ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 THEN  ' AND b.article_no=c.article_no ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_Name',@cConfigCols)>0 THEN  ' AND b.article_name=c.article_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ' AND b.para1_name=c.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ' AND b.para2_name=c.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)

	SELECT @cJoinstr=@cJoinstr+(CASE WHEN charindex(column_name,@cConfigCols)>0 THEN  ' AND b.'+column_name+
	'=c.'+column_name ELSE '' END)
	FROM config_attr WHERE table_caption<>''
	
	SET @cColList='a.ord_row_id'
	SET @cStep='30'			
	SELECT @cColList=@cColList+
		(CASE WHEN charindex('product_code',@cConfigCols)>0 THEN  ',a.product_code' ELSE '' END)+
		(CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ',a.section_name' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ',a.sub_section_name ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 THEN  ',a.article_no ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NAME',@cConfigCols)>0 THEN  ',a.article_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',a.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',a.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',a.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',a.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',a.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',a.para6_name ' ELSE '' END)
	
	SET @cStep='35'
	SELECT @cColList=@cColList+(CASE WHEN charindex(column_name,@cConfigCols)>0 THEN  ',a.'+column_name ELSE '' END)
	FROM config_attr WHERE table_caption<>''


	SET @cColListCodes=REPLACE(REPLACE(REPLACE(@cColList,'_name','_code'),'_no','_code'),'a.ord_row_id,','')

		
	SET @cStep='40'
		SET @CCMD=N'
		SELECT '''' unq_id,'+REPLACE(REPLACE(@cColList,'a.',''),'ord_row_id','row_id')+','+
		@cColListCodes+',a.quantity as order_qty,
		(A.QUANTITY-(CASE WHEN MEMO_TYPE=1 THEN (ISNULL(A.PO_QTY,0)+ISNULL(a.INV_QTY,0)) ELSE (ISNULL(A.PL_QTY,0)+ISNULL(a.PO_QTY,0)) END)) pending_qty,
		ARTICLE.hsn_code,
		CASE WHEN ISNULL(A.PL_QTY,0)>0 THEN  ISNULL(A.PL_QTY,0)-ISNULL(A.INV_QTY,0) ELSE 0 END AS PL_QTY,
		a.po_qty,
		a.INV_QTY
		FROM BUYER_ORDER_DET A (NOLOCK)
		JOIN BUYER_ORDER_MST (NOLOCK) ON A.ORDER_ID = BUYER_ORDER_MST.ORDER_ID
		JOIN LM01106 (NOLOCK) ON BUYER_ORDER_MST.AC_CODE = LM01106.AC_CODE
		JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE = A.ARTICLE_CODE
		JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE = A.PARA1_CODE
		JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE = A.PARA2_CODE
		JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE = A.PARA3_CODE
		JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE = A.PARA4_CODE
		JOIN PARA5 (NOLOCK) ON PARA5.PARA5_CODE	= A.PARA5_CODE
		JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE = A.PARA6_CODE
		JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE = ARTICLE.SUB_SECTION_CODE
		JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE = SECTIOND.SECTION_CODE
		LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=a.attr1_KEY_CODE      
		LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=a.attr2_KEY_CODE      
		LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=a.attr3_KEY_CODE      
		LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=a.attr4_KEY_CODE      
		LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=a.attr5_KEY_CODE      
		LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=a.attr6_KEY_CODE      
		LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=a.attr7_KEY_CODE      
		LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=a.attr8_KEY_CODE      
		LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=a.attr9_KEY_CODE      
		LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=a.attr10_KEY_CODE      
		LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=a.attr11_KEY_CODE      
		LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=a.attr12_KEY_CODE      
		LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=a.attr13_KEY_CODE      
		LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=a.attr14_KEY_CODE      
		LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=a.attr15_KEY_CODE      
		LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=a.attr16_KEY_CODE      
		LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=a.attr17_KEY_CODE      
		LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=a.attr18_KEY_CODE      
		LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=a.attr19_KEY_CODE      
		LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=a.attr20_KEY_CODE      
		LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=a.attr21_KEY_CODE      
		LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=a.attr22_KEY_CODE      
		LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=a.attr23_KEY_CODE      
		LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=a.attr24_KEY_CODE      
		LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=a.ATTR25_KEY_CODE
		WHERE  BUYER_ORDER_MST.MEMO_TYPE in(1,2) 
		AND (approvedlevelno=99 or '''+rtrim(ltrim(str(@CDONOT_CHKORDER_APPROVAL)))+'''=''1'')
		and BUYER_ORDER_MST.DELIVERY_DT>='''+convert(varchar(10),@DLOGINDT,121)+'''
		and case when  isnull(BUYER_ORDER_MST.WBO_FOR_DEPT_ID,'''')<>'''' then BUYER_ORDER_MST.WBO_FOR_DEPT_ID else BUYER_ORDER_MST.DEPT_ID end ='''+@cdept_id+'''
		AND A.QUANTITY-(CASE WHEN MEMO_TYPE=1 THEN (ISNULL(A.PO_QTY,0)+ISNULL(a.INV_QTY,0)) ELSE (ISNULL(A.PL_QTY,0)+ISNULL(a.PO_QTY,0)) END)>0
		AND BUYER_ORDER_MST.CANCELLED = 0  AND ISNULL(BUYER_ORDER_MST.Short_close,0) = 0 AND '
		+ 
		(CASE WHEN ISNULL(@CWHERE,'')='' THEN ' 1=1 ' ELSE ISNULL(@CWHERE,'') END)
		
		

		SET @cStep='45'
		SET @cCmd=N'INSERT INTO #PENDINGBUYERORDER (unq_id,'+REPLACE(@cColList,'a.','')+','+
		replace(@cColListCodes,'a.','')+',order_qty,pending_po_qty,hsn_code,pl_qty,po_qty,INV_QTY)'+@ccmd
		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD

	
	
	
		SET @cStep='47'
		SET @cCmd=N'INSERT INTO #PENDINGBUYERORDER_stock (unq_id,'+REPLACE(REPLACE(@cColList,'a.ord_row_id,',''),'a.','')+','+
					REPLACE(@cColListCodes,'a.','')+',
					order_qty,pending_po_qty,hsn_code,stock_qty,pl_qty,po_qty,INV_QTY)
					SELECT '''' unq_id,'+REPLACE(@cColList,'a.ord_row_id,','')+','+
					@cColListCodes+',
					SUM(order_qty) order_qty,SUM(pending_po_qty) pending_po_qty,a.hsn_code,0 AS stock_qty,
					sum(isnull(a.pl_qty,0)) as pl_qty,
					sum(isnull(a.po_qty,0)) as po_qty,
					sum(isnull(a.INV_QTY,0)) as INV_QTY
					FROM #PENDINGBUYERORDER a GROUP BY a.hsn_code,'+REPLACE(@cColList,'a.ord_row_id,','')+','+
					@cColListCodes

		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD

         SET @cStep='50'

		 	
	--select * into PENDINGBUYERORDER from #PENDINGBUYERORDER

	--select * into PENDINGBUYERORDER_STOCK from #PENDINGBUYERORDER_STOCK

       
				SET @CSTEP='50'
				SET @CCMD=N'UPDATE B SET STOCK_QTY=C.STOCK_QTY-ISNULL(B.PL_QTY,0)
				FROM #PENDINGBUYERORDER_STOCK B
				JOIN
				(  

					SELECT '+REPLACE(@CCOLLIST,'A.ORD_ROW_ID,','')+',SUM(QUANTITY_IN_STOCK) AS STOCK_QTY
					FROM SKU_NAMES A (NOLOCK)
					JOIN PMT01106 B (NOLOCK) ON B.PRODUCT_CODE=A.PRODUCT_CODE
					 WHERE B.DEPT_ID='''+@CCURLOCID+''' AND B.BIN_ID<>''999''
					GROUP BY '+REPLACE(@CCOLLIST,'A.ORD_ROW_ID,','')+' HAVING SUM(QUANTITY_IN_STOCK)>0 
				)C  ON '+@CJOINSTR+''
				PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD

		
    
		
		
		SET @cStep='52'
		UPDATE #PENDINGBUYERORDER_stock SET unq_id=CONVERT(VARCHAR(40),NEWID()) 

		SET @cStep='55'
		SET @cCmd=N' UPDATE b SET  unq_id=c.unq_id FROM #PENDINGBUYERORDER b
		JOIN #PENDINGBUYERORDER_stock c on '+@cJoinStr
		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD



		SET @cStep='60'
		SET @cCmd=N'SELECT CONVERT(BIT,0) CHK, unq_id,'+REPLACE(@cColList,'a.ord_row_id,','')+','+@cColListCodes+',
		            sum(order_qty) as order_qty,
					sum(pl_qty) as picklist_qty,
					sum(po_qty) as po_qty,
					sum(INV_QTY) as inv_qty,
		            sum(stock_qty) as stock_qty,
				    SUM(pending_po_qty) qty_required,
					--SUM(pending_po_qty) pending_po_qty,
					CONVERT(NUMERIC(10,2),0) current_po_qty_total, a.hsn_code
					FROM  #PENDINGBUYERORDER_stock a
					GROUP BY a.hsn_code,unq_id,'+REPLACE(@cColList,'a.ord_row_id,','')+','+@cColListCodes+ ' ORDER BY '+REPLACE(@cColList,'a.ord_row_id,','')
		EXEC SP_EXECUTESQL @CCMD

		SET @cStep='70'
		SET @CCMD=N'SELECT CONVERT(BIT,0) CHK,unq_id,ac_name customer_name,
		ORDER_DT,ORDER_NO,'+@cColList+',
		order_qty,
		isnull(a.pl_qty,0) as picklist_qty,
		isnull(a.po_qty,0) as po_qty,
		isnull(a.inv_qty,0) as inv_qty,
		pending_po_qty as qty_required,
	--	pending_po_qty,
		CONVERT(NUMERIC(10,2),0) AS current_po_qty,ord_row_id as DET_UNQ_ID
		FROM #PENDINGBUYERORDER a 
		JOIN buyer_order_det b (NOLOCK) ON a.ord_row_id=b.row_id
		JOIN buyer_order_mst c (NOLOCK) ON c.order_id=b.order_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code ORDER BY '+REPLACE(@cColList,'a.ord_row_id,','')
		print @CCMD
		EXEC SP_EXECUTESQL @CCMD

		GOTO END_PROC	
END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_PENDINGORDER_PO_DYNAMIC at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT ISNULL(@cErrormsg,'') errmsg


	--in case of ean barcod pick only article wise if configure article size or article colur barcode pick wrong 
	-- if required changes Please discuss (dinkar 2023-01-06)
	;WITH CTE
	AS
	(
		select ROW_NUMBER() OVER (PARTITION BY A.ARTICLE_CODE ORDER BY b.ARTICLE_NO) SR_NO,A.ARTICLE_CODE,B.ARTICLE_NO,A.PRODUCT_CODE 
		FROM SKU A
		JOIN ARTICLE B ON B.article_code=A.article_code
		JOIN #PENDINGBUYERORDER A1 ON A1.article_code=B.article_code 
		WHERE A.barcode_coding_scheme=1
		AND isnull(B.GEN_EAN_CODES,0) =0
		AND CHARINDEX('@',A.product_code,1)<=0
	)
	SELECT * INTO #PENDINGBUYERORDER_PC FROM CTE WHERE SR_NO=1

	--SELECT 1 as ABC,* FROM #PENDINGBUYERORDER_PC

	SELECT A.ORD_ROW_ID ,ORDER_QTY ,A.PENDING_PO_QTY  ,A.ARTICLE_NO ,A.PARA1_NAME ,A.PARA2_NAME ,A.PARA3_NAME ,A.PARA4_NAME ,A.PARA5_NAME ,A.PARA6_NAME ,
	      CASE WHEN  ISNULL(ART_DET.WS_PRICE,0)>0 THEN ART_DET.WS_PRICE ELSE ART.wholesale_price  END  AS WHOLESALE_PRICE,
		  CASE WHEN  ISNULL(ART_DET.MRP,0)>0 THEN ART_DET.MRP ELSE ART.MRP  END AS MRP,
		  CASE WHEN  ISNULL(ART_DET.purchase_price,0)>0 THEN ART_DET.purchase_price ELSE CASE WHEN ISNULL(ART.purchase_price,0)=0 THEN ART.Gross_purchase_price ELSE ART.purchase_price END   END AS purchase_price,
		  CASE WHEN  ISNULL(ART_DET.purchase_price,0)>0 THEN ART_DET.purchase_price ELSE ART.Gross_purchase_price  END AS Gross_purchase_price,
		   A.HSN_CODE,A.UNQ_ID ,
	       ISNULL(A.PARA1_CODE,'0000000') AS PARA1_CODE,
		   ISNULL(A.PARA2_CODE,'0000000') AS PARA2_CODE,
		   ISNULL(A.PARA3_CODE,'0000000') AS PARA3_CODE,
		   ISNULL(A.PARA4_CODE,'0000000') AS PARA4_CODE,
		   ISNULL(A.PARA5_CODE,'0000000') AS PARA5_CODE,
		   ISNULL(A.PARA6_CODE,'0000000') AS PARA6_CODE,
		   SD.SUB_SECTION_NAME ,SM.SECTION_NAME ,UOM.UOM_NAME ,ord_row_id as DET_UNQ_ID,
		   isnull(a1.attr1_key_name,'') as attr1_key_name,isnull(a2.attr2_key_name,'') as attr2_key_name,isnull(a3.attr3_key_name,'') as attr3_key_name,
		   isnull(a4.attr4_key_name,'') as attr4_key_name,isnull(a5.attr5_key_name,'') as attr5_key_name,isnull(a6.attr6_key_name,'') as attr6_key_name,
		   isnull(a7.attr7_key_name,'') as attr7_key_name,isnull(a8.attr8_key_name,'') as attr8_key_name,isnull(a9.attr9_key_name,'') as attr9_key_name,
		   isnull(a10.attr10_key_name,'') as attr10_key_name,isnull(a11.attr11_key_name,'') as attr11_key_name,isnull(a12.attr12_key_name,'') as attr12_key_name,
		   isnull(a13.attr13_key_name,'') as attr13_key_name,isnull(a14.attr14_key_name,'') as attr14_key_name,isnull(a15.attr15_key_name,'') as attr15_key_name,
		   isnull(a16.attr16_key_name,'') as attr16_key_name,isnull(a17.attr17_key_name,'') as attr17_key_name,isnull(a18.attr18_key_name,'') as attr18_key_name,
		   isnull(a19.attr19_key_name,'') as attr19_key_name,isnull(a20.attr20_key_name,'') as attr20_key_name,isnull(a21.attr21_key_name,'') as attr21_key_name,
		   isnull(a22.attr22_key_name,'') as attr22_key_name,isnull(a23.attr23_key_name,'') as attr23_key_name,isnull(a24.attr24_key_name,'') as attr24_key_name,
		   isnull(a25.attr25_key_name,'') as attr25_key_name,uom.uom_type,ART.gen_ean_codes,ART.CODING_SCHEME
		   ,ISNULL(PC.PRODUCT_CODE,'') AS PRODUCT_CODE
	FROM #PENDINGBUYERORDER A
	JOIN ARTICLE ART (NOLOCK) ON A.ARTICLE_CODE =ART.ARTICLE_CODE 
	LEFT OUTER JOIN #PENDINGBUYERORDER_PC PC ON PC.article_code=ART.article_code
	LEFT JOIN ART_DET (NOLOCK) ON A.article_code =art_det .article_code AND A.para2_code =art_det .para2_code 
	JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =art.SUB_SECTION_CODE 
	join uom (nolock) on uom.uom_code =art.uom_code 
	join sectionm sm (nolock) on sm.section_code =sd.section_code 
	Left join ARTICLE_FIX_ATTR fix_attr(nolock) on fix_attr.article_code =art.article_code 
	LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=fix_attr.attr1_KEY_CODE      
	LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=fix_attr.attr2_KEY_CODE      
	LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=fix_attr.attr3_KEY_CODE      
	LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=fix_attr.attr4_KEY_CODE      
	LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=fix_attr.attr5_KEY_CODE      
	LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=fix_attr.attr6_KEY_CODE      
	LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=fix_attr.attr7_KEY_CODE      
	LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=fix_attr.attr8_KEY_CODE      
	LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=fix_attr.attr9_KEY_CODE      
	LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=fix_attr.attr10_KEY_CODE      
	LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=fix_attr.attr11_KEY_CODE      
	LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=fix_attr.attr12_KEY_CODE      
	LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=fix_attr.attr13_KEY_CODE      
	LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=fix_attr.attr14_KEY_CODE      
	LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=fix_attr.attr15_KEY_CODE      
	LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=fix_attr.attr16_KEY_CODE      
	LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=fix_attr.attr17_KEY_CODE      
	LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=fix_attr.attr18_KEY_CODE      
	LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=fix_attr.attr19_KEY_CODE      
	LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=fix_attr.attr20_KEY_CODE      
	LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=fix_attr.attr21_KEY_CODE      
	LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=fix_attr.attr22_KEY_CODE      
	LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=fix_attr.attr23_KEY_CODE      
    LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=fix_attr.attr24_KEY_CODE      
	LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=fix_attr.ATTR25_KEY_CODE
	
	

END
