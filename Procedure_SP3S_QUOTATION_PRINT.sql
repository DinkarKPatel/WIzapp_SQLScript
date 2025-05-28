CREATE PROCEDURE SP3S_QUOTATION_PRINT
(
	@cMemoID VARCHAR(50)
)
AS      
BEGIN
  
  SELECT ROW_ID =CAST('' AS VARCHAR(100)),CAST(0 AS NUMERIC(14,2)) AS FC_NET,CAST(0 AS NUMERIC(14,2)) AS FC_GST_PERCENTAGE,CAST(0 AS INT) AS FC_TAX_METHOD,CAST(0 AS BIT) AS IS_IGST,
	       CAST(0 AS NUMERIC(14,2)) AS FC_XN_VALUE_WITHOUT_GST,CAST(0 AS NUMERIC(10,2)) AS FC_IGST_AMOUNT,CAST(0 AS NUMERIC(10,2)) AS FC_CGST_AMOUNT,
		   CAST(0 AS NUMERIC(10,2)) AS FC_SGST_AMOUNT,CAST(0 AS NUMERIC(14,2)) AS FC_XN_VALUE_WITH_GST
	       INTO #TMPFCRATE
	       WHERE 1=2

			--IF EXISTS ( SELECT 1 'U' FROM CONFIG WHERE CONFIG_OPTION='ENABLE_MULTI_CURRENCY' AND VALUE='1')
			--begin
			--	  EXEC SP3S_CALCULATE_FCNET_PURQT @CWHERE,1
			--end
	

		SELECT  R.*,A.*,B.ac_name, B.PRINT_NAME,  
  B.ADDRESS0,B.ADDRESS1,B.ADDRESS2,B.AREA_NAME,B.PINCODE,B.CITY,B.[STATE],B.CST_NO,B.CST_DT,B.SST_NO,B.SST_DT,B.TIN_NO,  
  B.TIN_DT,B.PHONES_R,B.PHONES_O,B.PHONES_FAX,B.MOBILE,B.E_MAIL,B.TAX_CODE,B.CREDIT_LIMIT,B.PAN_NO,B.GLN_NO, CAST(0 AS NUMERIC(14,0)) AS SERIAL_NO,'' as DT_CREATED,0 as GEN_EAN_CODES,    
		 ARTICLE_NO, ARTICLE_NAME, art.coding_scheme as coding_scheme,  0 as PARA1_SET, 0 as PARA2_SET,'0000000' as UOM_CODE, 
		i.uom_name as UOM_NAME, 1 as UOM_TYPE,  
		 PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME, PARA5_NAME, PARA6_NAME, STOCK_NA,0 as GEN_EAN_CODES,    
		 '' AS JRD_ROW_ID, '' AS JID_ROW_ID, '' AS JOD_ROW_ID , 0 as PARA2_ORDER,
		 SUB_SECTION_NAME,SECTION_NAME,  '' AS [ART_DT_CREATED],'' AS [PARA3_DT_CREATED],        
		  '' AS [SKU_DT_CREATED],    '' AS OTHER_XN_PRODUCT_CODE, 0 as SIZE_RATE_DIFF ,0 as SIZE_CENTER_POINT,    
		'' as FORM_NAME,ARTICLE_NAME AS PRODUCT_NAME ,'' AS PI_PO_ROW_ID ,
		0 as FIX_PRICE_ARTICLE,art.alias ARTICLE_ALIAS ,'' as ONLINE_PRODUCT_CODE,sd.alias SUB_SECTION_ALIAS,
		 sm.alias SECTION_ALIAS,'' as BUYER_ORDER_REMARKS,0 as P1_SET,0 AS P2_SET,
		 isnull(a1.attr1_key_name,'') as attr1_key_name,isnull(a2.attr2_key_name,'') as attr2_key_name,isnull(a3.attr3_key_name,'') as attr3_key_name,
		 isnull(a4.attr4_key_name,'') as attr4_key_name,isnull(a5.attr5_key_name,'') as attr5_key_name,isnull(a6.attr6_key_name,'') as attr6_key_name,
		 isnull(a7.attr7_key_name,'') as attr7_key_name,isnull(a8.attr8_key_name,'') as attr8_key_name,isnull(a9.attr9_key_name,'') as attr9_key_name,
		 isnull(a10.attr10_key_name,'') as attr10_key_name,isnull(a11.attr11_key_name,'') as attr11_key_name,isnull(a12.attr12_key_name,'') as attr12_key_name,
		 isnull(a13.attr13_key_name,'') as attr13_key_name,isnull(a14.attr14_key_name,'') as attr14_key_name,isnull(a15.attr15_key_name,'') as attr15_key_name,
		 isnull(a16.attr16_key_name,'') as attr16_key_name,isnull(a17.attr17_key_name,'') as attr17_key_name,isnull(a18.attr18_key_name,'') as attr18_key_name,
		 isnull(a19.attr19_key_name,'') as attr19_key_name,isnull(a20.attr20_key_name,'') as attr20_key_name,isnull(a21.attr21_key_name,'') as attr21_key_name,
		 isnull(a22.attr22_key_name,'') as attr22_key_name,isnull(a23.attr23_key_name,'') as attr23_key_name,isnull(a24.attr24_key_name,'') as attr24_key_name,
		 isnull(a25.attr25_key_name,'') as attr25_key_name
	   ,art.PERISHABLE,'' as BATCH_NO, 
	    cast('' as Datetime) as Expiry_Dt,article_desc,CAST(0 AS NUMERIC(14,2)) AS TAX_AMOUNT,
	    TMP.FC_NET PURQT_FC_NET ,TMP.FC_XN_VALUE_WITHOUT_GST,TMP.FC_IGST_AMOUNT,TMP.FC_CGST_AMOUNT,TMP.FC_SGST_AMOUNT,TMP.FC_XN_VALUE_WITH_GST
		,Art.alt_uom_conversion_factor,Art.alternate_uom_applicable,Art.alternate_uom_code,Art.conversion_factor_mode,B2.UOM_NAME AS alternate_uom_name
		FROM quotation_det A  (NOLOCK)   
		JOIN quotation_mst R (NOLOCK) ON R.PQ_ID=A.PQ_ID
		JOIN LMV01106 B (NOLOCK) ON R.AC_CODE = B.AC_CODE  
		LEFT JOIN #TMPFCRATE TMP ON TMP.ROW_id=a.row_id
		LEFT OUTER JOIN ARTICLE art   (NOLOCK) ON A.ARTICLE_CODE = art.ARTICLE_CODE     
		LEFT OUTER JOIN PARA1 p1     (NOLOCK) ON A.PARA1_CODE = p1.PARA1_CODE    
		LEFT OUTER JOIN PARA2 p2     (NOLOCK) ON A.PARA2_CODE = p2.PARA2_CODE     
		LEFT OUTER JOIN PARA3 p3    (NOLOCK) ON A.PARA3_CODE = p3.PARA3_CODE     
		LEFT OUTER JOIN PARA4 p4     (NOLOCK) ON A.PARA4_CODE = p4.PARA4_CODE     
		LEFT OUTER JOIN PARA5 p5     (NOLOCK) ON A.PARA5_CODE = p5.PARA5_CODE     
		LEFT OUTER JOIN PARA6 p6     (NOLOCK) ON A.PARA6_CODE = p6.PARA6_CODE     
		LEFT OUTER JOIN UOM I       (NOLOCK) ON art.UOM_CODE = I.UOM_CODE     
		LEFT JOIN UOM B2 ON A.alternate_uom_code= B2.UOM_CODE 
		LEFT OUTER JOIN SECTIOND sd  (NOLOCK) ON art.SUB_SECTION_CODE = sd.SUB_SECTION_CODE   
		LEFT OUTER JOIN SECTIONM sm  (NOLOCK) ON sd.SECTION_CODE = sm.SECTION_CODE   
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
		WHERE A.PQ_ID = @cMemoID
		ORDER BY  A.SRNO


END  
