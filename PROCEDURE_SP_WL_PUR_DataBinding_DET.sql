CREATE PROCEDURE SP_WL_PUR_DATABINDING_DET--(LocId 3 digit change by Sanjay:04-11-2024)
(  
	@CMRRID VARCHAR(100)
) 
--WITH ENCRYPTION
AS  
BEGIN  
   DECLARE @nInvMode NUMERIC(1,0),@cCurLocId VARCHAR(4),@cHoLocId VARCHAR(4),@bServerLoc BIT,@cInvId VARCHAR(40),
   @cCmd NVARCHAR(MAX)
   

   SELECT @cHoLocId = value FROM config (NOLOCK) WHERE config_option='ho_location_id'
   SELECT @cCurLocId = DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 

   SELECT @nInvMode=inv_mode,@bServerLoc=ISNULL(server_loc,0),@cInvId=a.inv_id,@cCurLocId=(CASE WHEN isnull(@cCurLocId,'')='' then a.location_code ELSE @cCurLocId END)
   FROM pim01106 a (NOLOCK) JOIN location b (NOLOCK) ON A.location_Code=b.dept_id
   WHERE mrr_id=@cMrrId

 

   IF OBJECT_ID('TEMPDB..#TMPFCRATE','U') IS NOT NULL
       DROP TABLE #TMPFCRATE

   
    SELECT ROW_ID =CAST('' AS VARCHAR(100)),CAST(0 AS NUMERIC(14,2)) AS FC_NET,CAST(0 AS NUMERIC(14,2)) AS FC_GST_PERCENTAGE,CAST(0 AS INT) AS FC_TAX_METHOD,CAST(0 AS BIT) AS IS_IGST,
	       CAST(0 AS NUMERIC(14,2)) AS FC_XN_VALUE_WITHOUT_GST,CAST(0 AS NUMERIC(10,2)) AS FC_IGST_AMOUNT,CAST(0 AS NUMERIC(10,2)) AS FC_CGST_AMOUNT,
		   CAST(0 AS NUMERIC(10,2)) AS FC_SGST_AMOUNT,CAST(0 AS NUMERIC(14,2)) AS FC_XN_VALUE_WITH_GST
	   INTO #TMPFCRATE
	 WHERE 1=2

	IF EXISTS ( SELECT 1 'U' FROM CONFIG WHERE CONFIG_OPTION='ENABLE_MULTI_CURRENCY' AND VALUE='1')
	begin
	      
		  EXEC SP3S_CALCULATE_FCNET_PUR @CMRRID,1,@CCURLOCID
	end
	
	--SELECT @bServerLoc, @cHoLocId,@cCurLocId, @nInvMode
   IF (@bServerLoc=1 OR @cHoLocId=@cCurLocId) AND @nInvMode=2
   BEGIN
  
		SET @cCmd=N'SELECT B.BIN_ID,SECTION_NAME, SUB_SECTION_NAME,LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),
		LEN(A.PRODUCT_CODE ))) AS PRODUCT_CODE, sn.uom as uom_name, PARA1_NAME,    
		PARA2_NAME,PARA3_NAME,PARA4_NAME,PARA5_NAME,PARA6_NAME,ARTICLE_NO,     
		ARTICLE_NAME,1 AS CODING_SCHEME,A.*,a.net_rate as Purchase_price,
		A.net_rate * A.INVOICE_QUANTITY AS ''AMOUNT''  ,  
		'''' AS [ART_DT_CREATED],'''' AS [PARA3_DT_CREATED],  
		'''' AS [SKU_DT_CREATED],0 as GEN_EAN_CODES,     
		'''' AS OTHER_XN_PRODUCT_CODE,0 as PARA2_ORDER,0 as SIZE_RATE_DIFF ,0 as SIZE_CENTER_POINT, 
		A.QUANTITY AS [ORG_QUANTITY],0 AS [STK_QUANTITY],sn.STOCK_NA,
		'''' as FORM_NAME,sn.mrp as FIX_MRP,article_name as PRODUCT_NAME,0 as FIX_PRICE_ARTICLE,0 AS  MODE,
		article_alias,'''' AS AREA_UOM_NAME,0 AS SQUARE_UNIT,0 AS BASE_UNIT,
		'''' AS FROM_UOM_NAME,'''' AS TO_UOM_NAME,
		0 as AREA_WISE_RATE_APPLICABLE,sn.MRP AS SKU_MRP,'''' as ONLINE_BAR_CODE,
		0 as  SKU_MP ,  0 as SKU_MD ,0 AS [PMT_QUANTITY], '''' AS  PO_ID,
		'''' as BOX_ID,  '''' AS SP_ID,SUB_SECTION_ALIAS,SECTION_ALIAS
		,0 as  RATE_REVISED,0 as PERISHABLE,A.PRODUCT_CODE AS ORG_PRODUCT_CODE,
		(SUBSTRING(A.PRODUCT_CODE,CHARINDEX(''@'',A.PRODUCT_CODE)+1,15)) AS BATCH_LOT_NO,'''' AS P1_SET,'''' AS P2_SET,
		a.row_id AS old_row_id
    
	   ,attr1_key_name,attr2_key_name,attr3_key_name,attr4_key_name,attr5_key_name,attr6_key_name,
	   attr7_key_name,attr8_key_name,attr9_key_name,attr10_key_name,attr11_key_name,attr12_key_name,
	   attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,
	   attr19_key_name,attr20_key_name,attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,
		attr25_key_name
		
	   FROM IND01106 A (NOLOCK) 
	   JOIN inm01106 b (NOLOCK) ON a.inv_id=b.inv_id
	   JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	   WHERE a.inv_id='''+@cInvId+''''
   END
   ELSE
   BEGIN
		SET @cCmd=N''

		IF @nInvMode=1
		   SET @cCmd=N'SELECT K.SECTION_NAME, J.SUB_SECTION_NAME,LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE ))) AS PRODUCT_CODE, I.*, C.PARA1_NAME,    
			D.PARA2_NAME,E.PARA3_NAME,F.PARA4_NAME,G.PARA5_NAME,H.PARA6_NAME,B.ARTICLE_NO,     
			B.ARTICLE_NAME,B.CODING_SCHEME, A.*,A.PURCHASE_PRICE * A.INVOICE_QUANTITY AS ''AMOUNT''  ,  
			ISNULL(B.DT_CREATED,'''') AS [ART_DT_CREATED],ISNULL(E.DT_CREATED,'''') AS [PARA3_DT_CREATED],  
			ISNULL(SKU.DT_CREATED,'''') AS [SKU_DT_CREATED],B.GEN_EAN_CODES,     
			'''' AS OTHER_XN_PRODUCT_CODE,D.PARA2_ORDER, B.SIZE_RATE_DIFF ,B.SIZE_CENTER_POINT, 
			A.QUANTITY AS [ORG_QUANTITY],CAST(0 AS NUMERIC(10,2)) AS [STK_QUANTITY],B.STOCK_NA,
			FORM.FORM_NAME,B.FIX_MRP,  SKU.PRODUCT_NAME,B.FIX_PRICE_ARTICLE,CONVERT(NUMERIC(2),0) AS  MODE,
			B.ALIAS AS ARTICLE_ALIAS,
			(FROM_UOM_NAME+ '' - '' +TO_UOM_NAME) AS AREA_UOM_NAME,
			ISNULL(AR_UOM.SQUARE_UNIT,0) AS SQUARE_UNIT,
			ISNULL(AR_UOM.BASE_UNIT,0) AS BASE_UNIT,
			ISNULL(AR_UOM.FROM_UOM_NAME,'''') AS FROM_UOM_NAME,
			ISNULL(AR_UOM.TO_UOM_NAME,'''') AS TO_UOM_NAME,
			B.AREA_WISE_RATE_APPLICABLE,SKU.MRP AS SKU_MRP,SKU.ONLINE_PRODUCT_CODE AS ONLINE_BAR_CODE,
			(CASE WHEN xn_item_type=1 THEN CAST((CASE WHEN A.PURCHASE_PRICE>0 THEN (SKU.MRP - A.PURCHASE_PRICE) * 100 / A.PURCHASE_PRICE 
				  ELSE 0 END  ) AS NUMERIC(10,2)) ELSE 0 END) AS SKU_MP ,  
			(CASE WHEN xn_item_type=1 THEN CAST((CASE WHEN SKU.MRP>0 THEN (SKU.MRP - A.PURCHASE_PRICE) * 100 / SKU.MRP ELSE 0 END  ) 
				AS NUMERIC(10,2)) ELSE 0 END) AS SKU_MD ,
			CAST(0 AS NUMERIC(10,2)) AS [PMT_QUANTITY], CAST('''' AS VARCHAR(50)) AS PO_ID,
			A.BOX_ID,  CAST('''' AS varchar(50)) AS SP_ID,J.ALIAS AS SUB_SECTION_ALIAS,K.ALIAS AS SECTION_ALIAS
			,CAST(0 AS BIT)AS RATE_REVISED   ,B.PERISHABLE,A.PRODUCT_CODE AS ORG_PRODUCT_CODE,
			(SUBSTRING(A.PRODUCT_CODE,CHARINDEX(''@'',A.PRODUCT_CODE)+1,15)) AS BATCH_LOT_NO,'''' AS P1_SET,'''' AS P2_SET,
			a.row_id AS old_row_id
    
				,AT1.attr1_key_name,AT2.attr2_key_name,AT3.attr3_key_name,AT4.attr4_key_name,AT5.attr5_key_name,AT6.attr6_key_name,
		   AT7.attr7_key_name,AT8.attr8_key_name,AT9.attr9_key_name,AT10.attr10_key_name,AT11.attr11_key_name,AT12.attr12_key_name,
		   AT13.attr13_key_name,AT14.attr14_key_name,AT15.attr15_key_name,AT16.attr16_key_name,AT17.attr17_key_name,AT18.attr18_key_name,
		   AT19.attr19_key_name,AT20.attr20_key_name,AT21.attr21_key_name,AT22.attr22_key_name,AT23.attr23_key_name,AT24.attr24_key_name,
			AT25.attr25_key_name , ARTICLE_DESC
			,B.alt_uom_conversion_factor,B.alternate_uom_applicable,B.alternate_uom_code,B.conversion_factor_mode,B2.UOM_NAME AS alternate_uom_name
			,B.MRP_RESTRICTION,B.MRP_RESTRICTION_FROM,B.MRP_RESTRICTION_TO
		 FROM PID01106 A (NOLOCK)   
		 JOIN Pim01106 pm (NOLOCK) ON pm.mrr_id=a.mrr_id
		 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE = B.ARTICLE_CODE     
		 JOIN PARA1 C (NOLOCK) ON A.PARA1_CODE = C.PARA1_CODE    
		 JOIN PARA2 D (NOLOCK) ON A.PARA2_CODE = D.PARA2_CODE    
		 JOIN PARA3 E (NOLOCK) ON A.PARA3_CODE = E.PARA3_CODE    
		 JOIN PARA4 F (NOLOCK) ON A.PARA4_CODE = F.PARA4_CODE    
		 JOIN PARA5 G (NOLOCK) ON A.PARA5_CODE = G.PARA5_CODE    
		 JOIN PARA6 H (NOLOCK) ON A.PARA6_CODE = H.PARA6_CODE    
		 JOIN UOM I (NOLOCK) ON B.UOM_CODE = I.UOM_CODE   
		 LEFT JOIN UOM B2 ON b.alternate_uom_code= B2.UOM_CODE 
		 JOIN SECTIOND J (NOLOCK) ON B.SUB_SECTION_CODE = J.SUB_SECTION_CODE    
		 JOIN SECTIONM K (NOLOCK) ON J.SECTION_CODE = K.SECTION_CODE 
		 JOIN FORM (NOLOCK) ON FORM.FORM_ID=A.FORM_ID 
		 LEFT OUTER JOIN SKU(NOLOCK) ON SKU.PRODUCT_CODE=A.PRODUCT_CODE  
		 LEFT OUTER JOIN STANDARD_UOM AR_UOM (NOLOCK) ON A.AREA_UOM_CODE= AR_UOM.UOM_CODE 
		LEFT OUTER JOIN article_fix_attr ATTR  (NOLOCK) ON B.article_code = ATTR.ARTICLE_CODE 
		LEFT OUTER JOIN attr1_mst at1 (NOLOCK) ON at1.attr1_key_code=ATTR.attr1_key_code
		LEFT OUTER JOIN attr2_mst at2 (NOLOCK) ON at2.attr2_key_code=ATTR.attr2_key_code
		LEFT OUTER JOIN attr3_mst at3 (NOLOCK) ON at3.attr3_key_code=ATTR.attr3_key_code
		LEFT OUTER JOIN attr4_mst at4 (NOLOCK) ON at4.attr4_key_code=ATTR.attr4_key_code
		LEFT OUTER JOIN attr5_mst at5 (NOLOCK) ON at5.attr5_key_code=ATTR.attr5_key_code
		LEFT OUTER JOIN attr6_mst at6 (NOLOCK) ON at6.attr6_key_code=ATTR.attr6_key_code
		LEFT OUTER JOIN attr7_mst at7 (NOLOCK) ON at7.attr7_key_code=ATTR.attr7_key_code
		LEFT OUTER JOIN attr8_mst at8 (NOLOCK) ON at8.attr8_key_code=ATTR.attr8_key_code
		LEFT OUTER JOIN attr9_mst at9 (NOLOCK) ON at9.attr9_key_code=ATTR.attr9_key_code
		LEFT OUTER JOIN attr10_mst at10 (NOLOCK) ON at10.attr10_key_code=ATTR.attr10_key_code
		LEFT OUTER JOIN attr11_mst at11 (NOLOCK) ON at11.attr11_key_code=ATTR.attr11_key_code
		LEFT OUTER JOIN attr12_mst at12 (NOLOCK) ON at12.attr12_key_code=ATTR.attr12_key_code
		LEFT OUTER JOIN attr13_mst at13 (NOLOCK) ON at13.attr13_key_code=ATTR.attr13_key_code
		LEFT OUTER JOIN attr14_mst at14 (NOLOCK) ON at14.attr14_key_code=ATTR.attr14_key_code
		LEFT OUTER JOIN attr15_mst at15 (NOLOCK) ON at15.attr15_key_code=ATTR.attr15_key_code
		LEFT OUTER JOIN attr16_mst at16 (NOLOCK) ON at16.attr16_key_code=ATTR.attr16_key_code
		LEFT OUTER JOIN attr17_mst at17 (NOLOCK) ON at17.attr17_key_code=ATTR.attr17_key_code
		LEFT OUTER JOIN attr18_mst at18 (NOLOCK) ON at18.attr18_key_code=ATTR.attr18_key_code
		LEFT OUTER JOIN attr19_mst at19 (NOLOCK) ON at19.attr19_key_code=ATTR.attr19_key_code
		LEFT OUTER JOIN attr20_mst at20 (NOLOCK) ON at20.attr20_key_code=ATTR.attr20_key_code
		LEFT OUTER JOIN attr21_mst at21 (NOLOCK) ON at21.attr21_key_code=ATTR.attr21_key_code
		LEFT OUTER JOIN attr22_mst at22 (NOLOCK) ON at22.attr22_key_code=ATTR.attr22_key_code
		LEFT OUTER JOIN attr23_mst at23 (NOLOCK) ON at23.attr23_key_code=ATTR.attr23_key_code
		LEFT OUTER JOIN attr24_mst at24 (NOLOCK) ON at24.attr24_key_code=ATTR.attr24_key_code
		LEFT OUTER JOIN attr25_mst at25(NOLOCK) ON at25.attr25_key_code=ATTR.attr25_key_code
		 WHERE A.MRR_ID = '''+@CMRRID+''' AND ISNULL(A.PRODUCT_CODE,'''')=''''  UNION '
		 
    
		
		SET @cCmd=@cCmd+N'
		SELECT SECTION_NAME, SUB_SECTION_NAME,LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),
		LEN(A.PRODUCT_CODE ))) AS PRODUCT_CODE ,uom.*, PARA1_NAME,    
		sn.PARA2_NAME,sn.PARA3_NAME,PARA4_NAME,PARA5_NAME,PARA6_NAME,art.ARTICLE_NO,     
		art.ARTICLE_NAME, art.CODING_SCHEME, A.*,A.PURCHASE_PRICE * A.INVOICE_QUANTITY AS ''AMOUNT''  ,  
		'''' AS [ART_DT_CREATED],'''' AS [PARA3_DT_CREATED],  
		'''' AS [SKU_DT_CREATED],art.GEN_EAN_CODES,     
		'''' AS OTHER_XN_PRODUCT_CODE,p2.PARA2_ORDER, art.SIZE_RATE_DIFF ,art.SIZE_CENTER_POINT, 
		A.QUANTITY AS [ORG_QUANTITY],CAST(0 AS NUMERIC(10,2)) AS [STK_QUANTITY],art.STOCK_NA,
		'''' as FORM_NAME,art.FIX_MRP,  art.article_name as PRODUCT_NAME,art.FIX_PRICE_ARTICLE,CONVERT(NUMERIC(2),0) AS  MODE,
		art.ALIAS AS ARTICLE_ALIAS,
		(FROM_UOM_NAME+ '' - '' +TO_UOM_NAME) AS AREA_UOM_NAME,
		ISNULL(AR_UOM.SQUARE_UNIT,0) AS SQUARE_UNIT,
		ISNULL(AR_UOM.BASE_UNIT,0) AS BASE_UNIT,
		ISNULL(AR_UOM.FROM_UOM_NAME,'''') AS FROM_UOM_NAME,
		ISNULL(AR_UOM.TO_UOM_NAME,'''') AS TO_UOM_NAME,
		art.AREA_WISE_RATE_APPLICABLE,Sn.MRP AS SKU_MRP,'''' AS ONLINE_BAR_CODE,
		(CASE WHEN xn_item_type=1 THEN CAST((CASE WHEN A.PURCHASE_PRICE>0 THEN (sn.mrp - A.PURCHASE_PRICE) * 100 / A.PURCHASE_PRICE 
			 ELSE 0 END  ) AS NUMERIC(10,2)) ELSE 0 END) AS SKU_MP ,  
		(CASE WHEN xn_item_type=1 THEN CAST((CASE WHEN sn.mrp>0 THEN (sn.mrp - A.PURCHASE_PRICE) * 100 / sn.mrp 
			 ELSE 0 END  ) AS NUMERIC(10,2)) ELSE 0 END) AS SKU_MD ,
	   ISNULL(PMT01106.QUANTITY_IN_STOCK,0) AS [PMT_QUANTITY] ,CAST('''' AS VARCHAR(50)) AS PO_ID  ,
	   A.BOX_ID  ,CAST('''' AS varchar(50)) AS SP_ID ,SUB_SECTION_ALIAS,SECTION_ALIAS
	   ,CAST(0 AS BIT) as rate_revised,art.PERISHABLE,A.PRODUCT_CODE AS ORG_PRODUCT_CODE,
		(SUBSTRING(A.PRODUCT_CODE,CHARINDEX(''@'',A.PRODUCT_CODE)+1,15)) AS BATCH_LOT_NO,'''' AS P1_SET,'''' AS P2_SET,
  		a.row_id AS old_row_id,attr1_key_name,attr2_key_name,attr3_key_name,attr4_key_name,attr5_key_name,attr6_key_name,
	   attr7_key_name,attr8_key_name,attr9_key_name,attr10_key_name,attr11_key_name,attr12_key_name,
	   attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,
	   attr19_key_name,attr20_key_name,attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,
		attr25_key_name  , ARTICLE_DESC
		,art.alt_uom_conversion_factor,art.alternate_uom_applicable,art.alternate_uom_code,art.conversion_factor_mode,B2.UOM_NAME AS alternate_uom_name
		,Art.MRP_RESTRICTION,Art.MRP_RESTRICTION_FROM,Art.MRP_RESTRICTION_TO
	   FROM PID01106 A (NOLOCK)   
	   JOIN Pim01106 pm (NOLOCK) ON pm.mrr_id=a.mrr_id
		 JOIN SKU_names sn (NOLOCK) ON Sn.PRODUCT_CODE=A.PRODUCT_CODE
		 JOIN article art (nolock) on art.article_code=a.article_code
		 JOIN para2 p2 (nolock) on p2.para2_code=a.para2_code
		 JOIN uom (NOLOCK) ON uom.uom_code=art.uom_code
		 LEFT JOIN UOM B2 ON Art.alternate_uom_code= B2.UOM_CODE 
		 LEFT OUTER JOIN PMT01106 (NOLOCK) ON Sn.PRODUCT_CODE=PMT01106.PRODUCT_CODE AND A.BIN_ID= PMT01106.BIN_ID AND PM.location_code= pmt01106 .DEPT_ID and isnull(PMT01106.bo_order_id,'''')=''''
		 LEFT OUTER JOIN STANDARD_UOM AR_UOM (NOLOCK) ON A.AREA_UOM_CODE= AR_UOM.UOM_CODE 
		WHERE A.MRR_ID = '''+@CMRRID+''' AND ISNULL(A.PRODUCT_CODE,'''')<>''''     
 		ORDER BY BOX_NO,SRNO,A.PRODUCT_CODE'                    
	END

	print @cCmd
	EXEC SP_EXECUTESQL @cCmd
END      