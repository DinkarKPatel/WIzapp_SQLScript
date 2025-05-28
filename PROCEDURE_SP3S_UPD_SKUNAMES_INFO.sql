create PROCEDURE SP3S_UPD_SKUNAMES_INFO
@bRunOptimizedProcess BIT=0,
@cCutOffTime VARCHAR(100)='',
@bCalledFromReBuild BIT=0,
@nSpId NUMERIC(5,0)=0
AS
BEGIN
	
	DECLARE @cCmd NVARCHAR(MAX),@cDiffTable VARCHAR(MAX),@cWc VARCHAR(MAX),@nRowsUpdated INT,@nLoop INT,@cJoinStr VARCHAR(300)

	IF @nSpId=0 AND @bRunOptimizedProcess=0
		SET @nSpId=@@SPID

		SELECT B.ARTICLE_CODE ,B.PARA2_CODE ,MAX(ISNULL(BOXWEIGHT,0)) as BOXWEIGHT
		    into #TMP_ART_DET
		FROM OPT_SKU_DIFF A (NOLOCK) 
		JOIN ART_DET B (NOLOCK) ON A.MASTER_CODE =B.ROW_ID 
		WHERE MASTER_TABLENAME='ART_DET' AND A.LAST_UPDATE<=@CCUTOFFTIME 
		AND ISNULL(BOXWEIGHT,0)<>0
		GROUP BY B.ARTICLE_CODE ,B.PARA2_CODE

	SET @nLoop=1
	IF @bRunOptimizedProcess=1
		SELECT @bCalledFromReBuild =1,@nLoop=2
	
	WHILE @nLoop>0
	BEGIN
		SELECT @cDiffTable=(CASE WHEN @bRunOptimizedProcess=1 AND @nLoop=2 THEN 'opt_sku_diff' ELSE 'sku_diff' END),
		@cJoinStr=(CASE WHEN @bRunOptimizedProcess=1 AND @nLoop=2 THEN ' sdf.master_code=a.product_code ' ELSE ' sdf.product_code=a.product_code ' END),
		@cWc='WHERE '+(CASE WHEN @bRunOptimizedProcess=1 AND @nLoop=2 THEN ' sdf.master_tablename=''sku'' AND sdf.last_update<='''+@cCutOffTime+'''' ELSE 'sp_id='+LTRIM(RTRIM(STR(@@spid))) END)





		IF @nLoop=2 AND NOT EXISTS (SELECT TOP 1 master_code FROM opt_sku_diff (NOLOCK) WHERE master_tablename='sku' and last_update<=@cCutOffTime)
			GOTO lblNext

		  
	  --- Did this change as per requirement of a client agst Ticket#0223-00146
	  --- Previously we had removed this in caluclation of LC as per confirmation by all Support Seniors (Date:20-02-2023)
	  DECLARE @cConsiderTaxAsPartofLc VARCHAR(2)
	  
	  SELECT TOP 1 @cConsiderTaxAsPartofLc=value from config (NOLOCK) where config_option='considerTaxAsPartofLc' 

	  SET @cConsiderTaxAsPartofLc=ISNULL(@cConsiderTaxAsPartofLc,'')
         
		 ---(Tax is not part of LC as per confirmation by All Senior Support ( Sanjay : 01-11-2022))
		SET @cCmd=N'SELECT A.PRODUCT_CODE
		,(A.PURCHASE_PRICE+ISNULL(SKU_OH.OTHER_CHARGES,0) +  ISNULL(SKU_OH.ROUND_OFF,0) + ISNULL(SKU_OH.FREIGHT,0) + 
		ISNULL(SKU_OH.EXCISE_DUTY_AMOUNT,0)+ISNULL(SKU_OH.VALUE_ADD,0)+ISNULL(SKU_OH.CustomdutyAmt,0)'+
		(CASE WHEN @cConsiderTaxAsPartofLc='1' then '+isnull(sku_oh.tax_amount,0)' else '' end)+') as lc
		,(a.PURCHASE_PRICE + (CASE WHEN ISNULL(FF.POST_TAX_SEPARATELY,0) =0 AND isnull(FF.FORM_ID,'''') NOT IN (''0000000'','''') 
					THEN ISNULL(SKU_OH.TAX_AMOUNT,0) ELSE 0 END) +
					ISNULL(SKU_OH.EXCISE_DUTY_AMOUNT,0) +ISNULL(SKU_OH.VALUE_ADD,0)+ISNULL(sku_oh.depreciation,0) )
					AS pp
		,(a.PURCHASE_PRICE + (CASE WHEN  ISNULL(FF.POST_TAX_SEPARATELY,0) =0 AND  ISNULL(FF.FORM_ID,'''') NOT IN (''0000000'','''')
					THEN ISNULL(SKU_OH.TAX_AMOUNT,0) ELSE 0 END) +
					ISNULL(SKU_OH.EXCISE_DUTY_AMOUNT,0) +ISNULL(SKU_OH.VALUE_ADD,0) )
					AS PP_WO_DP
		,A.MRP,A.WS_PRICE,article.ARTICLE_NO,article.ARTICLE_NAME,ARTICLE.STOCK_NA,article.alias as article_alias
		,sectionm.SECTION_NAME,sectionm.alias as section_alias,sectionm.item_type as sku_item_type
		,sectiond.SUB_SECTION_NAME,sectiond.alias as SUB_SECTION_alias
		,p1.PARA1_NAME,p2.PARA2_NAME,p3.PARA3_NAME,p4.PARA4_NAME,p5.PARA5_NAME,p6.PARA6_NAME,P7.para7_name
		,A1.ATTR1_KEY_NAME,A2.ATTR2_KEY_NAME,A3.ATTR3_KEY_NAME,A4.ATTR4_KEY_NAME,A5.ATTR5_KEY_NAME      
		,A6.ATTR6_KEY_NAME,A7.ATTR7_KEY_NAME,A8.ATTR8_KEY_NAME,A9.ATTR9_KEY_NAME,A10.ATTR10_KEY_NAME      
		,A11.ATTR11_KEY_NAME,A12.ATTR12_KEY_NAME,A13.ATTR13_KEY_NAME,A14.ATTR14_KEY_NAME,A15.ATTR15_KEY_NAME      
		,A16.ATTR16_KEY_NAME,A17.ATTR17_KEY_NAME,A18.ATTR18_KEY_NAME,A19.ATTR19_KEY_NAME,A20.ATTR20_KEY_NAME      
		,A21.ATTR21_KEY_NAME,A22.ATTR22_KEY_NAME,A23.ATTR23_KEY_NAME,A24.ATTR24_KEY_NAME,A25.ATTR25_KEY_NAME      	  
		,LM01106.AC_NAME,LM01106.ALIAS supplier_alias,p1.alias as para1_alias,p1.para1_set, p2.alias as para2_alias,p2.para2_set, p3.alias as para3_alias,p4.alias as para4_alias
		,p5.alias as para5_alias,p6.alias as para6_alias,p2.para2_order,a.ac_code,A.INV_DT AS PURCHASE_BILL_DT,
		A.INV_NO AS PURCHASE_BILL_NO,a.receipt_dt as purchase_receipt_Dt,a.batch_no,a.expiry_dt,uom.uom_name,ua.uom_name as alternate_uom_name,
		a.alt_uom_conversion_factor,a.challan_no purchase_challan_no,a.gst_percentage purchase_gst_percentage,isnull(sku_oh.tax_amount,0) purchase_gst_amount,
		a.hsn_code ,a.barcode_coding_scheme ,article.article_desc ,
		 (CASE WHEN isnull(SECTIONM.ITEM_TYPE,0) in(0,1) THEN ''INV''   WHEN SECTIONM.ITEM_TYPE =2 THEN ''CONS'' WHEN SECTIONM.ITEM_TYPE =3 THEN ''ASSESTS'' 
					 WHEN SECTIONM.ITEM_TYPE =4 THEN ''SERVICE'' ELSE  '''' END) AS  SKU_ITEM_TYPE_DESC,
		isnull(a.er_flag,0) as er_flag,a.Fix_mrp ,a.basic_purchase_price,a.vendor_ean_no ,uom.uom_type,
		ISNULL(ART_DET.BOXWEIGHT,ARTICLE.BOXWEIGHT) AS BOXWEIGHT,ISNULL(a.SHIPPING_FROM_AC_CODE,'''') oem_ac_code,
		ISNULL(oem_lm.ac_name,'''') oem_ac_name,loc.pan_no purloc_pan_no,A.PUR_MRR_NO,ISNULL(ARTICLE.ARTICLE_PACK_SIZE,1) AS SN_ARTICLE_PACK_SIZE,
		a.Pur_Broker_Ac_code,bklm.AC_NAME Pur_Broker_Ac_Name
		INTO #SKU_NAMES
		FROM SKU A (NOLOCK) LEFT OUTER JOIN SKU_OH  (NOLOCK) ON A.PRODUCT_CODE=SKU_OH.PRODUCT_CODE 
		JOIN '+@cDiffTable+' sdf (NOLOCK) ON '+@cJoinStr+'
		JOIN LM01106 (NOLOCK) ON LM01106.AC_CODE=A.AC_CODE
		JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=A.ARTICLE_CODE
		JOIN uom (NOLOCK) ON uom.uom_code=article.uom_code
		LEFT JOIN uom ua (NOLOCK) ON ua.uom_code=a.alternate_uom_code
		LEFT JOIN FORM FF (NOLOCK) ON FF.FORM_ID=A.FORM_ID
		JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE
		JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE=SECTIOND.SECTION_CODE
		JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_CODE=A.PARA1_CODE      
		JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_CODE=A.PARA2_CODE    
		JOIN PARA3 P3 (NOLOCK) ON P3.PARA3_CODE=A.PARA3_CODE      
		JOIN PARA4 P4 (NOLOCK) ON P4.PARA4_CODE=A.PARA4_CODE      
		JOIN PARA5 P5 (NOLOCK) ON P5.PARA5_CODE=A.PARA5_CODE      
		JOIN PARA6 P6 (NOLOCK) ON P6.PARA6_CODE=A.PARA6_CODE  
		LEFT JOIN PARA7 P7 (NOLOCK) ON P7.PARA7_CODE=A.PARA7_CODE  
		LEFT JOIN LM01106 oem_lm (NOLOCK) ON oem_lm.AC_CODE=A.SHIPPING_FROM_AC_CODE
		LEFT JOIN ARTICLE_FIX_ATTR AF (NOLOCK) ON AF.ARTICLE_CODE=A.ARTICLE_CODE
		LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=AF.ATTR1_KEY_CODE      
		LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=AF.ATTR2_KEY_CODE      
		LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=AF.ATTR3_KEY_CODE      
		LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=AF.ATTR4_KEY_CODE      
		LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=AF.ATTR5_KEY_CODE      
		LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=AF.ATTR6_KEY_CODE      
		LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=AF.ATTR7_KEY_CODE      
		LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=AF.ATTR8_KEY_CODE      
		LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=AF.ATTR9_KEY_CODE      
		LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=AF.ATTR10_KEY_CODE      
		LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=AF.ATTR11_KEY_CODE      
		LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=AF.ATTR12_KEY_CODE      
		LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=AF.ATTR13_KEY_CODE      
		LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=AF.ATTR14_KEY_CODE      
		LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=AF.ATTR15_KEY_CODE      
		LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=AF.ATTR16_KEY_CODE      
		LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=AF.ATTR17_KEY_CODE      
		LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=AF.ATTR18_KEY_CODE      
		LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=AF.ATTR19_KEY_CODE      
		LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=AF.ATTR20_KEY_CODE      
		LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=AF.ATTR21_KEY_CODE      
		LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=AF.ATTR22_KEY_CODE      
		LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=AF.ATTR23_KEY_CODE      
		LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=AF.ATTR24_KEY_CODE      
		LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=AF.ATTR25_KEY_CODE  
		LEFT OUTER JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.product_code
		LEFT JOIN #TMP_ART_DET ART_DET ON ART_DET.ARTICLE_CODE=A.ARTICLE_CODE AND ART_DET.PARA2_CODE=A.PARA2_CODE
		LEFT JOIN location loc(NOLOCK) ON loc.dept_id=a.purchaseLocId
		LEFT JOIN LM01106 BKLM (NOLOCK) ON BKLM.AC_CODE=A.PUR_BROKER_AC_CODE
		'+@cWc+'
	   	   	
		UPDATE a SET LC=S.LC,PP=S.PP,PP_WO_DP=S.PP_WO_DP,  MRP=S.MRP,WS_PRICE=S.WS_PRICE,sku_item_type=s.sku_item_type
		,PURCHASE_BILL_DT=s.PURCHASE_BILL_DT,PURCHASE_BILL_NO=s.PURCHASE_BILL_no
		,purchase_receipt_Dt=s.purchase_receipt_Dt,STOCK_NA=S.STOCK_NA
		,ARTICLE_NO=S.ARTICLE_NO,ARTICLE_NAME=S.ARTICLE_NAME,SECTION_NAME=S.SECTION_NAME
		,SUB_SECTION_NAME=S.SUB_SECTION_NAME,AC_NAME=S.AC_NAME,AC_CODE=S.AC_CODE
		,PARA1_NAME=S.PARA1_NAME,PARA2_NAME=S.PARA2_NAME,para1_set=s.para1_set,para2_order=s.para2_order,para2_set=s.para2_set,PARA3_NAME=S.PARA3_NAME,PARA4_NAME=S.PARA4_NAME,
		PARA5_NAME=S.PARA5_NAME,PARA6_NAME=S.PARA6_NAME,PARA7_NAME=S.PARA7_NAME
		,ATTR1_KEY_NAME=ISNULL(S.ATTR1_KEY_NAME,''''), ATTR2_KEY_NAME=ISNULL(S.ATTR2_KEY_NAME,''''), ATTR3_KEY_NAME=ISNULL(S.ATTR3_KEY_NAME,''''), ATTR4_KEY_NAME=ISNULL(S.ATTR4_KEY_NAME,''''), ATTR5_KEY_NAME=ISNULL(S.ATTR5_KEY_NAME,'''')
		
		,ATTR6_KEY_NAME=ISNULL(s.ATTR6_KEY_NAME,''''), ATTR7_KEY_NAME=ISNULL(S.ATTR7_KEY_NAME,''''), ATTR8_KEY_NAME=ISNULL(S.ATTR8_KEY_NAME,''''), ATTR9_KEY_NAME=ISNULL(S.ATTR9_KEY_NAME,''''), ATTR10_KEY_NAME=ISNULL(S.ATTR10_KEY_NAME,'''')
		
		,ATTR11_KEY_NAME=ISNULL(S.ATTR11_KEY_NAME,''''), ATTR12_KEY_NAME=ISNULL(S.ATTR12_KEY_NAME,''''), ATTR13_KEY_NAME=ISNULL(S.ATTR13_KEY_NAME,''''), ATTR14_KEY_NAME=ISNULL(S.ATTR14_KEY_NAME,''''), ATTR15_KEY_NAME=ISNULL(S.ATTR15_KEY_NAME,'''')
		,ATTR16_KEY_NAME=S.ATTR16_KEY_NAME,ATTR17_KEY_NAME=S.ATTR17_KEY_NAME, ATTR18_KEY_NAME=S.ATTR18_KEY_NAME, ATTR19_KEY_NAME=S.ATTR19_KEY_NAME, ATTR20_KEY_NAME=S.ATTR20_KEY_NAME
		
		,ATTR21_KEY_NAME=S.ATTR21_KEY_NAME, ATTR22_KEY_NAME=S.ATTR22_KEY_NAME
		,ATTR23_KEY_NAME=S.ATTR23_KEY_NAME, ATTR24_KEY_NAME=S.ATTR24_KEY_NAME 
		,ATTR25_KEY_NAME=S.ATTR25_KEY_NAME,supplier_alias=s.supplier_alias,para1_alias=s.para1_alias,para2_alias=s.para2_alias
		,para3_alias=s.para3_alias,para4_alias=s.para4_alias,para5_alias=s.para5_alias,para6_alias=s.para6_alias
		,article_alias=s.article_alias,section_alias=s.section_alias,SUB_SECTION_alias=S.SUB_SECTION_alias
		,batch_no=s.batch_no,expiry_dt=s.expiry_dt,uom=s.uom_name,alternate_uom_name=s.alternate_uom_name,
		alt_uom_conversion_factor=s.alt_uom_conversion_factor,purchase_challan_no=s.purchase_challan_no,
		purchase_gst_percentage=s.purchase_gst_percentage,purchase_gst_amount=s.purchase_gst_amount
		,sn_hsn_code =s.hsn_code ,sn_barcode_coding_scheme =s.barcode_coding_scheme ,sn_article_desc =s.article_desc 
		,SKU_ITEM_TYPE_DESC= s.SKU_ITEM_TYPE_DESC,vendor_ean_no=s.vendor_ean_no
		,sku_er_flag=s.er_flag ,Fix_mrp=s.Fix_mrp ,basic_purchase_price=s.basic_purchase_price
		,SN_Uom_type=s.Uom_type,boxWeight=S.boxWeight,oem_ac_code=s.oem_ac_code,oem_ac_name=s.oem_ac_name,purloc_pan_no=s.purloc_pan_no,PUR_MRR_NO=s.PUR_MRR_NO
		,a.SN_ARTICLE_PACK_SIZE=S.SN_ARTICLE_PACK_SIZE 
		,a.Pur_Broker_Ac_code=s.Pur_Broker_Ac_code,Pur_Broker_Ac_Name=s.Pur_Broker_Ac_Name
		
		FROM sku_names a JOIN #sku_names s ON a.product_code=s.product_code'
	

		PRINT @cCmd +' AAA'
		EXEC SP_EXECUTESQL @cCmd



	lblNext:	
		SET @nLoop=@nLoop-1
	END


	SET @nRowsUpdated=@@ROWCOUNT

	IF @bCalledFromReBuild=1
		INSERT INTO #tRows
		SELECT @nRowsUpdated
END
