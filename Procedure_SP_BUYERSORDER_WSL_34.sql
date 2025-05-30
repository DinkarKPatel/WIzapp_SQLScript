CREATE PROCEDURE SP_BUYERSORDER_WSL_34
@CMEMOID VARCHAR(40),  
@CWHERE VARCHAR(500),  
@CFINYEAR VARCHAR(10),  
@NNAVMODE NUMERIC(2,0),
@CARTICLECODE CHAR(9)='',  
@CPARA2CODE CHAR(7)='',
@DTWHERE DATETIME ='',
@cLocId VARCHAR(5)=''

AS    
BEGIN 

IF OBJECT_ID('TEMPDB..#TMPBO','U') IS NOT NULL
		DROP TABLE #TMPBO

        SELECT R.AC_CODE, B.ARTICLE_NAME,  
		0 AS SERIAL_NO,    
		B.ARTICLE_NO,C.PARA1_NAME,D.PARA2_NAME,D.PARA2_ORDER,C.PARA1_ORDER ,  E.PARA3_NAME,
		cast(sum(A.QUANTITY * A.WS_PRICE) AS NUMERIC(14,2)) AS AMOUNT,
		B.UOM_CODE,UOM.UOM_NAME,UOM.UOM_TYPE,B.DT_CREATED,  
		B.CODING_SCHEME,B.PARA1_SET,B.PARA2_SET, B.ALIAS AS ARTICLE_ALIAS,
		EMP.EMP_NAME AS ITEM_EMP_NAME,
		EMP1.EMP_NAME AS ITEM_MERCHANT_NAME ,
		SR=ROW_NUMBER() OVER (PARTITION BY A.ORDER_ID, B.ARTICLE_NO,C.PARA1_NAME,PARA2_ORDER ORDER BY A.ORDER_ID, B.ARTICLE_NO,C.PARA1_NAME,PARA2_ORDER),
		F.PARA4_NAME,G.PARA5_NAME,H.PARA6_NAME,SD.SUB_SECTION_NAME ,SM.SECTION_NAME ,ANGADIA_NAME,FC_NAME,
		A.Angadia_code,A.article_code,
		A.ATTR1_KEY_CODE,A.ATTR2_KEY_CODE,A.ATTR3_KEY_CODE,A.ATTR4_KEY_CODE,A.ATTR5_KEY_CODE,A.ATTR6_KEY_CODE,A.ATTR7_KEY_CODE,A.ATTR8_KEY_CODE,A.ATTR9_KEY_CODE,A.ATTR10_KEY_CODE,
		A.ATTR11_KEY_CODE,A.ATTR12_KEY_CODE,A.ATTR13_KEY_CODE,A.ATTR14_KEY_CODE,A.ATTR15_KEY_CODE,A.ATTR16_KEY_CODE,A.ATTR17_KEY_CODE,A.ATTR18_KEY_CODE,A.ATTR19_KEY_CODE,A.ATTR20_KEY_CODE,
		A.ATTR21_KEY_CODE,A.ATTR22_KEY_CODE,A.ATTR23_KEY_CODE,A.ATTR24_KEY_CODE,A.ATTR25_KEY_CODE,
		SUM(A.CGST_AMOUNT) AS CGST_AMOUNT,
		SUM(A.IGST_AMOUNT) AS IGST_AMOUNT,
		SUM(A.discount_amount) AS discount_amount,
		SUM(A.PL_QTY) AS PL_QTY,
		SUM(A.quantity) AS quantity,
		SUM(A.INV_QTY) AS INV_QTY,
		SUM(A.SGST_AMOUNT) AS SGST_AMOUNT,
		SUM(A.XN_VALUE_WITH_GST) AS XN_VALUE_WITH_GST,
		SUM(A.XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
		SUM(A.adj_qty) AS adj_qty,
		A.discount_percentage,A.fc_code,A.From_mrp,A.GROSS_QUANTITY,A.gross_wsp,A.Gst_Cess_Amount,
		A.Gst_Cess_Percentage,A.GST_PERCENTAGE,A.HSN_CODE,A.item_delivery_dt,A.ITEM_EMP_CODE,A.ITEM_MERCHANT_CODE,
		GETDATE() AS last_update,
		A.manual_discount,A.ONLINE_PRODUCT_CODE,A.order_id,A.para1_code,A.REMARKS,A.rfnet,
		'' AS row_id,A.SECTION_CODE,A.SUB_SECTION_CODE,A.to_mrp,A.ws_price,A.product_code ,
		A.PARA3_CODE,A.PARA4_CODE ,A.PARA5_CODE ,A.PARA6_CODE ,0 AS SR_NO
	    INTO #TMPBO
		FROM BUYER_ORDER_DET A  (NOLOCK)   	 
		JOIN SKU S ON A.PRODUCT_CODE   = S.PRODUCT_CODE
		JOIN ARTICLE B (NOLOCK)  ON S.ARTICLE_CODE = B.ARTICLE_CODE 
		JOIN SECTIOND SD (NOLOCK) ON  SD.SUB_SECTION_CODE =B.SUB_SECTION_CODE 
		JOIN SECTIONM SM (NOLOCK) ON  SM.SECTION_CODE=  SD.SECTION_CODE 
		LEFT OUTER JOIN PARA1 C (NOLOCK)  ON S.PARA1_CODE = C.PARA1_CODE      
		LEFT OUTER JOIN PARA2 D (NOLOCK)  ON S.PARA2_CODE = D.PARA2_CODE  
		LEFT OUTER JOIN PARA3 E (NOLOCK)  ON S.PARA3_CODE = E.PARA3_CODE
		LEFT OUTER JOIN PARA4 F (NOLOCK)  ON S.PARA4_CODE = F.PARA4_CODE
		LEFT OUTER JOIN PARA5 G (NOLOCK)  ON S.PARA5_CODE = G.PARA5_CODE
		LEFT OUTER JOIN PARA6 H (NOLOCK)  ON S.PARA6_CODE = H.PARA6_CODE  
		JOIN UOM (NOLOCK) ON UOM.UOM_CODE=B.UOM_CODE         
		JOIN BUYER_ORDER_MST R ON R.ORDER_ID= A.ORDER_ID 
		LEFT OUTER JOIN EMPLOYEE EMP (NOLOCK) ON EMP.EMP_CODE=A.ITEM_EMP_CODE   
		LEFT OUTER JOIN EMPLOYEE EMP1 (NOLOCK) ON EMP1.EMP_CODE=A.ITEM_MERCHANT_CODE  
		LEFT OUTER JOIN ANGM ANG (NOLOCK) ON ANG.ANGADIA_CODE=A.ANGADIA_CODE
		LEFT OUTER JOIN FC  (NOLOCK) ON FC.FC_CODE=A.FC_CODE
		WHERE A.ORDER_ID = @CMEMOID 
		GROUP BY R.AC_CODE, B.ARTICLE_NAME,    
		B.ARTICLE_NO,C.PARA1_NAME,D.PARA2_NAME,D.PARA2_ORDER,C.PARA1_ORDER ,  E.PARA3_NAME,
		B.UOM_CODE,UOM.UOM_NAME,UOM.UOM_TYPE,B.DT_CREATED,  
		B.CODING_SCHEME,B.PARA1_SET,B.PARA2_SET, B.ALIAS ,
		EMP.EMP_NAME ,EMP1.EMP_NAME ,F.PARA4_NAME,G.PARA5_NAME,H.PARA6_NAME,SD.SUB_SECTION_NAME ,SM.SECTION_NAME ,ANGADIA_NAME,FC_NAME,
		A.Angadia_code,A.article_code,
		A.ATTR1_KEY_CODE,A.ATTR2_KEY_CODE,A.ATTR3_KEY_CODE,A.ATTR4_KEY_CODE,A.ATTR5_KEY_CODE,A.ATTR6_KEY_CODE,A.ATTR7_KEY_CODE,A.ATTR8_KEY_CODE,A.ATTR9_KEY_CODE,A.ATTR10_KEY_CODE,
		A.ATTR11_KEY_CODE,A.ATTR12_KEY_CODE,A.ATTR13_KEY_CODE,A.ATTR14_KEY_CODE,A.ATTR15_KEY_CODE,A.ATTR16_KEY_CODE,A.ATTR17_KEY_CODE,A.ATTR18_KEY_CODE,A.ATTR19_KEY_CODE,A.ATTR20_KEY_CODE,
		A.ATTR21_KEY_CODE,A.ATTR22_KEY_CODE,A.ATTR23_KEY_CODE,A.ATTR24_KEY_CODE,A.ATTR25_KEY_CODE,
		A.discount_percentage,A.fc_code,A.From_mrp,A.GROSS_QUANTITY,A.gross_wsp,A.Gst_Cess_Amount,
		A.Gst_Cess_Percentage,A.GST_PERCENTAGE,A.HSN_CODE,A.item_delivery_dt,A.ITEM_EMP_CODE,A.ITEM_MERCHANT_CODE,
		A.manual_discount,A.ONLINE_PRODUCT_CODE,A.order_id,A.para1_code,
		A.REMARKS,A.rfnet,A.SECTION_CODE,A.SUB_SECTION_CODE,A.to_mrp,A.ws_price,A.product_code ,
		A.PARA3_CODE,A.PARA4_CODE ,A.PARA5_CODE ,A.PARA6_CODE


	
	SELECT A.ARTICLE_NAME,A.ORDER_ID,A.PARA1_CODE,A.QUANTITY
	,A.ROW_ID,A.LAST_UPDATE,A.WS_PRICE,A.RFNET,A.ARTICLE_CODE
	,A.GROSS_WSP,A.DISCOUNT_PERCENTAGE,A.DISCOUNT_AMOUNT,A.REMARKS
	,A.PRODUCT_CODE,A.MANUAL_DISCOUNT,A.PARA3_CODE,A.ONLINE_PRODUCT_CODE
	,A.ITEM_EMP_CODE,A.ITEM_MERCHANT_CODE,A.SERIAL_NO,A.ARTICLE_NO,A.PARA1_NAME,
	A.PARA2_NAME,A.PARA2_ORDER,A.PARA1_ORDER,A.PARA3_NAME,A.AMOUNT,A.UOM_CODE,A.UOM_NAME,A.UOM_TYPE
	,A.DT_CREATED,A.CODING_SCHEME,A.PARA1_SET,A.PARA2_SET,A.ARTICLE_ALIAS,A.ITEM_EMP_NAME,
	A.ITEM_MERCHANT_NAME,A.ADJ_QTY,A.SR_NO,A.HSN_CODE,A.GST_PERCENTAGE ,A.XN_VALUE_WITHOUT_GST ,A.XN_VALUE_WITH_GST ,
	A.IGST_AMOUNT ,A.CGST_AMOUNT ,A.SGST_AMOUNT ,
	A.SR,
	A.QUANTITY AS CUMM_SUM,
	0 AS  TYPE,
	CAST(0 AS INT) AS SP_ID,A.GROSS_QUANTITY,A.PL_QTY,A.INV_QTY,
	A.PARA4_CODE ,A.PARA4_NAME ,
	A.PARA5_CODE ,A.PARA5_NAME ,
	A.PARA6_CODE ,A.PARA6_NAME, sub_section_name ,section_name
	,ISNULL(A1.ATTR1_KEY_NAME,'') as ATTR1_KEY_NAME   ,ISNULL(A2.ATTR2_KEY_NAME,'')  as ATTR2_KEY_NAME
	,ISNULL(A3.ATTR3_KEY_NAME,'') as ATTR3_KEY_NAME  ,ISNULL(A4.ATTR4_KEY_NAME,'') as ATTR4_KEY_NAME
	,ISNULL(A5.ATTR5_KEY_NAME,'') as ATTR5_KEY_NAME,ISNULL(A6.ATTR6_KEY_NAME,'') as ATTR6_KEY_NAME
	,ISNULL(A7.ATTR7_KEY_NAME,'')  ATTR7_KEY_NAME ,ISNULL(A8.ATTR8_KEY_NAME,'')  ATTR8_KEY_NAME
	,ISNULL(A9.ATTR9_KEY_NAME,'')  ATTR9_KEY_NAME ,ISNULL(A10.ATTR10_KEY_NAME,'') ATTR10_KEY_NAME
	,ISNULL(A11.ATTR11_KEY_NAME,'') ATTR11_KEY_NAME,ISNULL(A12.ATTR12_KEY_NAME,'') ATTR12_KEY_NAME
	,ISNULL(A13.ATTR13_KEY_NAME,'') ATTR13_KEY_NAME ,ISNULL(A14.ATTR14_KEY_NAME,'') ATTR14_KEY_NAME
	,ISNULL(A15.ATTR15_KEY_NAME,'') ATTR15_KEY_NAME     
	,ISNULL(A16.ATTR16_KEY_NAME,'') ATTR16_KEY_NAME,ISNULL(A17.ATTR17_KEY_NAME,'') ATTR17_KEY_NAME
	,ISNULL(A18.ATTR18_KEY_NAME,'') ATTR18_KEY_NAME,ISNULL(A19.ATTR19_KEY_NAME,'') ATTR19_KEY_NAME
	,ISNULL(A20.ATTR20_KEY_NAME,'')  ATTR20_KEY_NAME  ,ISNULL(A21.ATTR21_KEY_NAME,'') ATTR21_KEY_NAME
	 ,ISNULL(A22.ATTR22_KEY_NAME,'') as ATTR22_KEY_NAME,ISNULL(A23.ATTR23_KEY_NAME,'') as ATTR23_KEY_NAME
	 ,ISNULL(A24.ATTR24_KEY_NAME,'') ATTR24_KEY_NAME,ISNULL(A25.ATTR25_KEY_NAME,'')  ATTR25_KEY_NAME     	  
	 ,a.ATTR1_KEY_CODE,a.ATTR2_KEY_CODE,a.ATTR3_KEY_CODE,a.ATTR4_KEY_CODE,a.ATTR5_KEY_CODE
     ,a.ATTR6_KEY_CODE,a.ATTR7_KEY_CODE,a.ATTR8_KEY_CODE,a.ATTR9_KEY_CODE,a.ATTR10_KEY_CODE
	 ,a.ATTR11_KEY_CODE,a.ATTR12_KEY_CODE,a.ATTR13_KEY_CODE,a.ATTR14_KEY_CODE,a.ATTR15_KEY_CODE
     ,a.ATTR16_KEY_CODE,a.ATTR17_KEY_CODE,a.ATTR18_KEY_CODE,a.ATTR19_KEY_CODE,a.ATTR20_KEY_CODE
     ,a.ATTR21_KEY_CODE,a.ATTR22_KEY_CODE,a.ATTR23_KEY_CODE,a.ATTR24_KEY_CODE,a.ATTR25_KEY_CODE
     ,a.SUB_SECTION_CODE,a.SECTION_CODE,a.From_mrp,a.to_mrp,A.Gst_Cess_Amount ,A.Gst_Cess_Percentage 
	 ,Angadia_name,fc_name,A.Angadia_code,fc_code,item_delivery_dt
	FROM #TMPBO A
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
	ORDER BY A.SR_NO

END