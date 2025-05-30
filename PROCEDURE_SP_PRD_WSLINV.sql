CREATE PROCEDURE SP_PRD_WSLINV     
    
 @NQUERYID NUMERIC (3,0) ,    
 @CMEMOID VARCHAR(MAX) = '',    
 @CWHERE1 VARCHAR(500) = '',    
 @NNAVMODE NUMERIC(1,0) = 0,    
 @CWHERE2 NVARCHAR(MAX)=''    
-- --WITH ENCRYPTION
   
AS    
BEGIN    
    
DECLARE @CCMD NVARCHAR(4000)    
DECLARE @CLOC_ID VARCHAR(5)    
DECLARE @CHO_ID  VARCHAR(5)    
DECLARE @BCO_OWNED BIT    
DECLARE @BPUR_LOC BIT    
DECLARE @BPOS BIT    
    
SET @BPOS=1    
SET @BCO_OWNED=0    
SET @BPUR_LOC=0    
    
SELECT @CLOC_ID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
    
SELECT @CHO_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'    
    
SELECT @BCO_OWNED=(CASE WHEN ISNULL(LOC_TYPE,0)=1 THEN 1 ELSE 0 END ) FROM LOCATION WHERE DEPT_ID=@CLOC_ID    
    
SELECT @BPUR_LOC=(CASE WHEN ISNULL(PUR_LOC,0)=1 THEN 1 ELSE 0 END ) FROM LOCATION WHERE DEPT_ID=@CLOC_ID    
    
IF @CLOC_ID<>@CHO_ID    
 SET @BPOS=0    
     
IF @NQUERYID = 1    
GOTO LBLNAVIGATE    
    
ELSE IF @NQUERYID = 2    
GOTO LBLGETMASTER    
    
ELSE IF @NQUERYID = 3    
GOTO LBLGETDETAIL    
    
ELSE IF @NQUERYID = 4    
GOTO LBLFORMS    
    
ELSE IF @NQUERYID = 5    
GOTO LBLCUSTOMER    
    
ELSE IF @NQUERYID = 6    
GOTO LBLSTOCKDETAILS    
   
ELSE IF @NQUERYID = 8    
GOTO LBLREPORTS    
    
ELSE IF @NQUERYID = 9    
GOTO LBLPRODUCTCODELIST    
    
ELSE IF @NQUERYID = 10   
GOTO LBLITVDETAILS  
  
ELSE IF @NQUERYID = 11    
GOTO LBLWOLIST  
  
ELSE IF @NQUERYID=12  
GOTO LBLWORKORDERDETAILLIST  

ELSE IF @NQUERYID=13
GOTO LBLPSMST

ELSE IF @NQUERYID=14  
GOTO LBLPSDET

ELSE IF @NQUERYID=15    
GOTO LBLPAYMENTDETAILS    
  
ELSE IF @NQUERYID=16    
GOTO LBLPAYMODEMST   
---------     
ELSE    
GOTO LAST    
LBLNAVIGATE:      
 EXECUTE SP_NAVIGATE 'PRD_INM01106',@NNAVMODE,@CMEMOID,@CWHERE2,'INV_NO','INV_DT','INV_ID',@CWHERE1      
GOTO LAST    
    
LBLGETMASTER:      
  SELECT T1.*,T2.USERNAME,T3.FORM_NAME,T4.AC_NAME,T4.ADDRESS0,T4.ADDRESS1,T4.ADDRESS2,     
  T4.AREA_NAME,T4.CITY,T4.[STATE],T4.PINCODE, T5.EMP_NAME,ISNULL(T6.DEPT_NAME,'') AS DEPT_NAME  ,  
  WO.MEMO_NO  
  FROM PRD_INM01106 T1     
  LEFT OUTER JOIN USERS T2  ON T1.USER_CODE = T2.USER_CODE    
  LEFT OUTER JOIN FORM T3  ON T3.FORM_ID = T1.FORM_ID    
  JOIN LMV01106 T4 ON T4.AC_CODE = T1.AC_CODE    
  LEFT OUTER JOIN EMPLOYEE T5 ON T5.EMP_CODE = T1.EMP_CODE    
  LEFT OUTER JOIN LOCATION T6 ON T6.DEPT_ID = T1.PARTY_DEPT_ID   
  LEFT OUTER JOIN PRD_WO_MST WO ON   WO.MEMO_ID=T1.REF_WO_ID  
  WHERE T1.INV_ID = @CMEMOID    
      
GOTO LAST    
    
LBLGETDETAIL:  
IF OBJECT_ID('TEMPDB..##DET','U') IS NOT NULL  
  DROP TABLE ##DET   
  SELECT T1.*,ROW_NUMBER() OVER(ORDER BY ARTICLE_NO) AS S_NO,  B.ARTICLE_CODE, B.ARTICLE_NO, 
  B.ARTICLE_NAME, S.PARA1_CODE, C.PARA1_NAME, S.PARA2_CODE, D.PARA2_NAME, S.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,         
   B.CODING_SCHEME,  B.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,      
  S.PURCHASE_PRICE, S.WS_PRICE,  '' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
  S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE,      
  PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
  B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],S.DT_CREATED AS [SKU_DT_CREATED],      
  B.STOCK_NA,((T1.QUANTITY*T1.RATE)-T1.DISCOUNT_AMOUNT) AS AMOUNT,    
  T1.QUANTITY AS PREVQTY,J.FORM_NAME,S.PRODUCT_CODE   INTO ##DET
  FROM PRD_IND01106 T1    
  LEFT OUTER JOIN PRD_PMT P ON T1.PRODUCT_UID = P.PRODUCT_UID AND P.DEPARTMENT_ID=T1.DEPT_ID      
  JOIN PRD_SKU S ON S.PRODUCT_UID = T1.PRODUCT_UID       
  JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE        
  JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
  JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE      
  JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE        
  JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE        
  JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE        
  JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE        
  JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE        
  JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE        
  JOIN UOM   E ON B.UOM_CODE = E.UOM_CODE     
  JOIN FORM J ON T1.ITEM_FORM_ID= J.FORM_ID     
  WHERE T1.INV_ID = @CMEMOID  
  
  SELECT * FROM ##DET
    
	SELECT ROW_NUMBER() OVER(ORDER BY ARTICLE_NO) AS S_NO,'' AS PRODUCT_UID, ARTICLE_CODE, RATE,
	SUM(A.QUANTITY) AS QUANTITY,SUM(A.QUANTITY) AS PREVQTY,SUM(DISCOUNT_PERCENTAGE) AS DISCOUNT_PERCENTAGE,SUM(DISCOUNT_AMOUNT) AS DISCOUNT_AMOUNT
	,'' AS DEPT_ID,ARTICLE_NO, ARTICLE_NAME, PARA1_CODE,  '' AS ROW_ID,    
	PARA1_NAME, PARA2_CODE, PARA2_NAME, PARA3_CODE, PARA3_NAME, UOM_NAME, CODING_SCHEME, 0 AS QUANTITY_IN_STOCK,      
	0 AS PURCHASE_PRICE, 0 AS  MRP,0 AS WS_PRICE, '' AS SCHEME_ID,  SECTION_NAME, SUB_SECTION_NAME, PARA4_CODE,PARA5_CODE,PARA6_CODE,      
	PARA4_NAME,PARA5_NAME,PARA6_NAME,UOM_CODE,ISNULL(UOM_TYPE,0) AS [UOM_TYPE], FORM_NAME,   STOCK_NA,0 AS SALE_RATE, 
	
	0  AS DISCOUNT_PERCENTAGE,0 AS DISCOUNT_AMOUNT,ITEM_FORM_ID,ITEM_TAX_PERCENTAGE,SUM(ISNULL(ITEM_TAX_AMOUNT,0)) AS ITEM_TAX_AMOUNT,
	SUM(ISNULL(AMOUNT,0)) AS AMOUNT,A.PRODUCT_CODE  
	FROM ##DET A
	GROUP BY  ARTICLE_CODE, ARTICLE_NO, ARTICLE_NAME, PARA1_CODE,  PARA1_NAME, PARA2_CODE, PARA2_NAME, 
	PARA3_CODE, PARA3_NAME, UOM_NAME, CODING_SCHEME, SECTION_NAME, 
	SUB_SECTION_NAME, PARA4_CODE,PARA5_CODE,PARA6_CODE, PARA4_NAME,PARA5_NAME,PARA6_NAME,UOM_CODE,
	ISNULL(UOM_TYPE,0) , FORM_NAME,   STOCK_NA,ITEM_FORM_ID,ITEM_TAX_PERCENTAGE,RATE,A.PRODUCT_CODE 
 
  
      
 GOTO LAST    
    
LBLFORMS:       
  IF(@CWHERE1 = '1')    
   SELECT * FROM FORM WHERE FORM_ID <> '0000000' AND EXCISE_ACCESSIBLE_PERCENTAGE > 0    
   AND INACTIVE=0    
  ELSE    
   SELECT * FROM FORM WHERE FORM_ID <> '0000000' AND EXCISE_ACCESSIBLE_PERCENTAGE = 0    
   AND INACTIVE=0    
GOTO LAST    
    
LBLCUSTOMER:      
 
  --DECLARE @CHEADCODESTR VARCHAR(1000),@CHEADCODESTR1 VARCHAR(1000)  
  --SELECT @CHEADCODESTR = DBO.FN_ACT_TRAVTREE('0000000018')    
  --SELECT @CHEADCODESTR1 = DBO.FN_ACT_TRAVTREE('0000000021')    
  --SELECT AC_CODE, AC_NAME, ADDRESS0,ADDRESS1,ADDRESS2 AREA_NAME , CITY, [STATE], PINCODE ,    
  --ISNULL(DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE    
  --FROM LMV01106      
  --WHERE ((CHARINDEX(HEAD_CODE,@CHEADCODESTR)>0 OR CHARINDEX(HEAD_CODE,@CHEADCODESTR1)>0)    
  --OR ALLOW_CREDITOR_DEBTOR=1) AND AC_CODE <>'0000000000'    
  --AND INACTIVE=0    
  --ORDER BY AC_NAME  
  
  DECLARE @CHEADCODESTR VARCHAR(1000),@CHEADCODESTR1 VARCHAR(1000)    
  SELECT @CHEADCODESTR = DBO.FN_ACT_TRAVTREE('0000000018')  
 
  SELECT AC_CODE, AC_NAME, ADDRESS0,ADDRESS1,ADDRESS2 AREA_NAME , CITY, [STATE], PINCODE ,      
  ISNULL(DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE      
  FROM LMV01106        
  WHERE (CHARINDEX(HEAD_CODE,@CHEADCODESTR)>0 OR (ALLOW_CREDITOR_DEBTOR=1))      
  AND AC_CODE <>'0000000000'   AND INACTIVE=0      
  ORDER BY AC_NAME  
         

GOTO LAST    
    
   
LBLSTOCKDETAILS:    
 SELECT T1.*,T1.PRODUCT_UID, B.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, S.PARA1_CODE,      
 C.PARA1_NAME, S.PARA2_CODE, D.PARA2_NAME, S.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,         
 T1.DEPARTMENT_ID, B.CODING_SCHEME,  B.INACTIVE, T1.QUANTITY_IN_STOCK,      
 S.PURCHASE_PRICE,  S.MRP,S.WS_PRICE,  '' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
 S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE,      
 PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
 B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],S.DT_CREATED AS [SKU_DT_CREATED],      
 B.STOCK_NA  
 FROM PRD_PMT T1    
 JOIN PRD_SKU S ON T1.PRODUCT_UID = S.PRODUCT_UID       
 JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE        
 JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
 JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE      
 JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE        
 JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE        
 JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE        
 JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE        
 JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE        
 JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE        
 JOIN UOM   E ON B.UOM_CODE = E.UOM_CODE       
 WHERE T1.QUANTITY_IN_STOCK > 0    
GOTO LAST    
    
  
    
LBLREPORTS:      
 SELECT * FROM VW_WL_PRD_WSLINV WHERE MST_MEMO_NO = @CMEMOID      
GOTO LAST    
    
LBLPRODUCTCODELIST:      
  SELECT DISTINCT T3.ARTICLE_NO,T1.PRODUCT_UID,T4.SUB_SECTION_NAME,P1.PARA1_NAME,P2.PARA2_NAME,  
  T5.SECTION_NAME,T3.ARTICLE_CODE   ,T1.PURCHASE_PRICE AS RATE,T1.PRODUCT_CODE,T2.QUANTITY_IN_STOCK      
  FROM PRD_SKU T1     
  LEFT OUTER JOIN PRD_PMT T2 ON T1.PRODUCT_UID = T2.PRODUCT_UID    
  JOIN ARTICLE T3 ON T1.ARTICLE_CODE = T3.ARTICLE_CODE    
  JOIN SECTIOND T4 ON T3.SUB_SECTION_CODE = T4.SUB_SECTION_CODE    
  JOIN PARA1 P1 ON P1.PARA1_CODE=T1.PARA1_CODE  
  JOIN PARA2 P2 ON P2.PARA2_CODE=T1.PARA2_CODE  
  JOIN SECTIONM T5 ON T5.SECTION_CODE = T4.SECTION_CODE    
  WHERE T1.PRODUCT_UID <> '' AND T2.QUANTITY_IN_STOCK > 0 AND T2.DEPARTMENT_ID='DEF0000'   
  ORDER BY T3.ARTICLE_NO       
 GOTO LAST    
     
     
LBLITVDETAILS:       
  SELECT S1.PRODUCT_UID,T1.RATE AS PURCHASE_PRICE,B1.ARTICLE_NO,B1.ARTICLE_NAME,B1.CODING_SCHEME,    
  D.SECTION_NAME,C1.SUB_SECTION_NAME,E.PARA1_NAME,F.PARA2_NAME ,F.PARA2_ORDER,G.PARA3_NAME,    
  H.PARA4_NAME,I.PARA5_NAME,J.PARA6_NAME,B1.ARTICLE_DESC,K.AC_NAME,S1.INV_NO,S1.INV_DT,K.ALIAS,    
  UOM.UOM_NAME,T1.QUANTITY,S1.MRP,S1.WS_PRICE,T1.DISCOUNT_PERCENTAGE,T1.DISCOUNT_AMOUNT,    
  B.FORM_ID,C.FORM_NAME,C.TAX_PERCENTAGE,T1.RATE AS PURCHASE_PRICE   
  FROM PRD_IND01106 T1    
  JOIN PRD_INM01106 B  ON B.INV_ID=T1.INV_ID    
  JOIN FORM C ON C.FORM_ID=B.FORM_ID    
  JOIN LOCATION LOC ON LOC.DEPT_ID=B.PARTY_DEPT_ID    
  JOIN PRD_SKU S1 ON S1.PRODUCT_UID=T1.PRODUCT_UID       
  JOIN ARTICLE B1 ON B1.ARTICLE_CODE = S1.ARTICLE_CODE      
  JOIN SECTIOND C1 ON C1.SUB_SECTION_CODE = B1.SUB_SECTION_CODE      
  JOIN SECTIONM D ON D.SECTION_CODE = C1.SECTION_CODE      
  LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON B1.ARTICLE_CODE = ATTR.ARTICLE_CODE 
LEFT OUTER JOIN ATTR1_MST AT1 (NOLOCK) ON AT1.ATTR1_KEY_CODE=ATTR.ATTR1_KEY_CODE
LEFT OUTER JOIN ATTR2_MST AT2 (NOLOCK) ON AT2.ATTR2_KEY_CODE=ATTR.ATTR2_KEY_CODE
LEFT OUTER JOIN ATTR3_MST AT3 (NOLOCK) ON AT3.ATTR3_KEY_CODE=ATTR.ATTR3_KEY_CODE
LEFT OUTER JOIN ATTR4_MST AT4 (NOLOCK) ON AT4.ATTR4_KEY_CODE=ATTR.ATTR4_KEY_CODE
LEFT OUTER JOIN ATTR5_MST AT5 (NOLOCK) ON AT5.ATTR5_KEY_CODE=ATTR.ATTR5_KEY_CODE
LEFT OUTER JOIN ATTR6_MST AT6 (NOLOCK) ON AT6.ATTR6_KEY_CODE=ATTR.ATTR6_KEY_CODE
LEFT OUTER JOIN ATTR7_MST AT7 (NOLOCK) ON AT7.ATTR7_KEY_CODE=ATTR.ATTR7_KEY_CODE
LEFT OUTER JOIN ATTR8_MST AT8 (NOLOCK) ON AT8.ATTR8_KEY_CODE=ATTR.ATTR8_KEY_CODE
LEFT OUTER JOIN ATTR9_MST AT9 (NOLOCK) ON AT9.ATTR9_KEY_CODE=ATTR.ATTR9_KEY_CODE
LEFT OUTER JOIN ATTR10_MST AT10 (NOLOCK) ON AT10.ATTR10_KEY_CODE=ATTR.ATTR10_KEY_CODE
LEFT OUTER JOIN ATTR11_MST AT11 (NOLOCK) ON AT11.ATTR11_KEY_CODE=ATTR.ATTR11_KEY_CODE
LEFT OUTER JOIN ATTR12_MST AT12 (NOLOCK) ON AT12.ATTR12_KEY_CODE=ATTR.ATTR12_KEY_CODE
LEFT OUTER JOIN ATTR13_MST AT13 (NOLOCK) ON AT13.ATTR13_KEY_CODE=ATTR.ATTR13_KEY_CODE
LEFT OUTER JOIN ATTR14_MST AT14 (NOLOCK) ON AT14.ATTR14_KEY_CODE=ATTR.ATTR14_KEY_CODE
LEFT OUTER JOIN ATTR15_MST AT15 (NOLOCK) ON AT15.ATTR15_KEY_CODE=ATTR.ATTR15_KEY_CODE
LEFT OUTER JOIN ATTR16_MST AT16 (NOLOCK) ON AT16.ATTR16_KEY_CODE=ATTR.ATTR16_KEY_CODE
LEFT OUTER JOIN ATTR17_MST AT17 (NOLOCK) ON AT17.ATTR17_KEY_CODE=ATTR.ATTR17_KEY_CODE
LEFT OUTER JOIN ATTR18_MST AT18 (NOLOCK) ON AT18.ATTR18_KEY_CODE=ATTR.ATTR18_KEY_CODE
LEFT OUTER JOIN ATTR19_MST AT19 (NOLOCK) ON AT19.ATTR19_KEY_CODE=ATTR.ATTR19_KEY_CODE
LEFT OUTER JOIN ATTR20_MST AT20 (NOLOCK) ON AT20.ATTR20_KEY_CODE=ATTR.ATTR20_KEY_CODE
LEFT OUTER JOIN ATTR21_MST AT21 (NOLOCK) ON AT21.ATTR21_KEY_CODE=ATTR.ATTR21_KEY_CODE
LEFT OUTER JOIN ATTR22_MST AT22 (NOLOCK) ON AT22.ATTR22_KEY_CODE=ATTR.ATTR22_KEY_CODE
LEFT OUTER JOIN ATTR23_MST AT23 (NOLOCK) ON AT23.ATTR23_KEY_CODE=ATTR.ATTR23_KEY_CODE
LEFT OUTER JOIN ATTR24_MST AT24 (NOLOCK) ON AT24.ATTR24_KEY_CODE=ATTR.ATTR24_KEY_CODE
LEFT OUTER JOIN ATTR25_MST AT25(NOLOCK) ON AT25.ATTR25_KEY_CODE=ATTR.ATTR25_KEY_CODE     
  JOIN PARA1 E ON E.PARA1_CODE = S1.PARA1_CODE      
  JOIN PARA2 F ON F.PARA2_CODE = S1.PARA2_CODE      
  JOIN PARA3 G ON G.PARA3_CODE = S1.PARA3_CODE      
  JOIN PARA4 H ON H.PARA4_CODE = S1.PARA4_CODE      
  JOIN PARA5 I ON I.PARA5_CODE = S1.PARA5_CODE      
  JOIN PARA6 J ON J.PARA6_CODE = S1.PARA6_CODE      
  JOIN LM01106 K ON K.AC_CODE=S1.AC_CODE       
  JOIN UOM ON UOM.UOM_CODE=B1.UOM_CODE    
  WHERE T1.INV_ID = @CMEMOID    
     
GOTO LAST    
  
  
LBLWOLIST:  
 SELECT MEMO_ID,MEMO_NO FROM PRD_WO_MST WHERE  CANCELLED=0  AND MARK_AS_COMPLETED=1
   
GOTO LAST  
  
LBLWORKORDERDETAILLIST:  
  
  
DECLARE @CQUERY1 NVARCHAR(MAX)--, @CMEMOID VARCHAR(50),@CWHERE1 VARCHAR(50)  
  
SET @CQUERY1 = N' SELECT CAST(0 AS BIT) AS CHCK,A.ARTICLE_CODE AS [COMPONENT_CODE]  
, B.ARTICLE_NO AS [COMPONENT_NAME]  
,B1.ARTICLE_NO,B1.ARTICLE_NAME  
,P11.PARA1_NAME ,P21.PARA2_NAME   
,D.AVG_QTY   
, E.PRODUCT_UID,E.ARTICLE_CODE AS ARTICLE_CODE,E.PARA1_CODE ,E.PARA2_CODE  
,P1.PARA1_NAME AS COM_COLOR,P2.PARA2_NAME AS COM_SIZE ,(C.QUANTITY * D.AVG_QTY) AS QUANTITY ,F.QUANTITY_IN_STOCK  
,CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN E.MRP ELSE E.PURCHASE_PRICE END AS RATE,  E.MRP ,E.WS_PRICE,  
 CAST(0 AS NUMERIC) AS DISCOUNT_PERCENTAGE,CAST(0 AS NUMERIC) AS DISCOUNT_AMOUNT, E.TAX_AMOUNT AS ITEM_TAX_AMOUNT,  
 E.FORM_ID AS ITEM_FORM_ID,G.FORM_NAME,G.TAX_PERCENTAGE AS ITEM_TAX_PERCENTAGE,D.ROW_ID +''-''+ C.ROW_ID AS ROW_ID  
, B.UOM_CODE,H.UOM_NAME, (ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN E.MRP ELSE E.PURCHASE_PRICE END)) AS AMOUNT,
SM.SECTION_NAME,SD.SUB_SECTION_NAME  
FROM PRD_WO_DET A  
JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE  
JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID  
JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID  
  
JOIN ARTICLE B1 ON D.BOM_ARTICLE_CODE=B1.ARTICLE_CODE  
JOIN PRD_SKU E ON E.ARTICLE_CODE=D.BOM_ARTICLE_CODE AND D.PARA1_CODE=E.PARA1_CODE  AND D.PARA2_CODE=E.PARA2_CODE '  
SET @CQUERY1 = @CQUERY1+ N' JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B1.SUB_SECTION_CODE  
JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE  
JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID'
IF ISNULL(@NNAVMODE,0)=0
BEGIN
	SET @CQUERY1 = @CQUERY1+ N' AND QUANTITY_IN_STOCK >0  '
END
SET @CQUERY1 = @CQUERY1+ N' JOIN PARA1 P1 ON P1.PARA1_CODE=E.PARA1_CODE  
JOIN PARA2 P2 ON P2.PARA2_CODE=E.PARA2_CODE  
JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE    
JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE    
  
JOIN FORM G ON G.FORM_ID=E.FORM_ID    
JOIN UOM H ON H.UOM_CODE=B.UOM_CODE '  
   
SET @CQUERY1 = @CQUERY1+ N' WHERE A.MEMO_ID= '''+@CMEMOID+''' AND (E.WORK_ORDER_ID='''+@CMEMOID+''' OR E.WORK_ORDER_ID='''') AND DEPARTMENT_ID='''+@CWHERE1+'''  '  
  
SET @CQUERY1 = @CQUERY1+ N' ORDER BY COMPONENT_NAME, COM_COLOR,COM_SIZE,ARTICLE_NO,PARA1_NAME'  
PRINT @CQUERY1  
EXEC SP_EXECUTESQL @CQUERY1   
  
  
   
SELECT DISTINCT CAST(0 AS BIT) AS CHCK,A.ARTICLE_CODE AS [COMPONENT_CODE]  
, B.ARTICLE_NO AS [COMPONENT_NAME]  
,B1.ARTICLE_NO,B1.ARTICLE_NAME  
,P11.PARA1_NAME AS COM_COLOR,P21.PARA2_NAME AS COM_SIZE   
,D.AVG_QTY   
, E.PRODUCT_UID,E.ARTICLE_CODE AS ARTICLE_CODE,E.PARA1_CODE ,E.PARA2_CODE  
,P1.PARA1_NAME, P2.PARA2_NAME,(C.QUANTITY * D.AVG_QTY) AS QUANTITY ,F.QUANTITY_IN_STOCK,E.PURCHASE_PRICE AS RATE,  E.MRP ,E.WS_PRICE,  
 CAST(0 AS NUMERIC) AS DISCOUNT_PERCENTAGE,CAST(0 AS NUMERIC) AS DISCOUNT_AMOUNT, E.TAX_AMOUNT AS ITEM_TAX_AMOUNT,  
 E.FORM_ID AS ITEM_FORM_ID,G.FORM_NAME,G.TAX_PERCENTAGE AS ITEM_TAX_PERCENTAGE,D.ROW_ID,  
 B.UOM_CODE,H.UOM_NAME, (QUANTITY*E.PURCHASE_PRICE) AS AMOUNT,SM.SECTION_NAME,SD.SUB_SECTION_NAME  
FROM PRD_WO_DET A  
JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE  
JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID  
JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID  
JOIN ARTICLE B1 ON D.BOM_ARTICLE_CODE=B1.ARTICLE_CODE  
JOIN PRD_SKU E ON E.ARTICLE_CODE=D.BOM_ARTICLE_CODE AND D.PARA1_CODE=E.PARA1_CODE AND D.PARA2_CODE=E.PARA2_CODE    
JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B1.SUB_SECTION_CODE  
JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE  
JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID AND QUANTITY_IN_STOCK >0  
JOIN PARA1 P1 ON P1.PARA1_CODE=E.PARA1_CODE  
JOIN PARA2 P2 ON P2.PARA2_CODE=E.PARA2_CODE  
JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE    
JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE    
  
JOIN FORM G ON G.FORM_ID=E.FORM_ID    
JOIN UOM H ON H.UOM_CODE=B.UOM_CODE   
WHERE 1=2    
    
GOTO LAST  
  
  
LBLPSMST:  
   
 IF OBJECT_ID('TEMPDB..#TMPWPS','U') IS NOT NULL  
  DROP TABLE #TMPWPS  
    
    SELECT DISTINCT ISNULL(A.PS_ID,'') AS PS_ID INTO #TMPWPS 
    FROM PRD_IND01106 A (NOLOCK) 
    JOIN PRD_INM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID    
    WHERE B.AC_CODE=@CWHERE1 AND B.ENTRY_MODE=@NNAVMODE AND CANCELLED=0  
  
     SELECT CAST(0 AS BIT) AS BILLCHECK, B.PS_ID,B.PS_NO,B.PS_DT,CAST(SUBSTRING(B.PS_NO,4,10) AS NUMERIC(10,0)) AS SR,  
           SUM(QUANTITY) AS TOTAL_QTY,    
           CAST('' AS NVARCHAR(10)) AS SRNO ,B.REMARKS    
    FROM PRD_PS_DET A (NOLOCK)    
    JOIN PRD_PS_MST B (NOLOCK) ON A.PS_ID= B.PS_ID     
    LEFT OUTER JOIN #TMPWPS C ON C.PS_ID=B.PS_ID  
    WHERE B.AC_CODE=@CWHERE1  AND CANCELLED=0 AND C.PS_ID IS NULL  
    GROUP BY  B.PS_ID,B.PS_NO,B.PS_DT ,B.REMARKS   
    ORDER BY SR   
  
 GOTO LAST  
   
LBLPSDET: 


 IF OBJECT_ID('TEMPDB..##PS','U') IS NOT NULL  
  DROP TABLE ##PS 
	DECLARE @CQUERY NVARCHAR(MAX)
SET @CQUERY= N' SELECT T1.*,ROW_NUMBER() OVER(ORDER BY ARTICLE_NO) AS S_NO, B.ARTICLE_CODE, B.ARTICLE_NO, 
		B.ARTICLE_NAME, S.PARA1_CODE, C.PARA1_NAME, S.PARA2_CODE, D.PARA2_NAME, S.PARA3_CODE, F.PARA3_NAME, 
		E.UOM_NAME, MST.DEPT_ID, B.CODING_SCHEME,  B.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,      
		S.PURCHASE_PRICE,  S.MRP,S.WS_PRICE,  '''' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
		S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE, PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,S.DT_CREATED AS [SKU_DT_CREATED], 
		ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE], B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],
		B.STOCK_NA,((ISNULL(T1.QUANTITY,'''')* ISNULL(T1.RATE,''''))-ISNULL(T1.DISCOUNT_AMOUNT,'''')) AS AMOUNT,    
		T1.QUANTITY AS PREVQTY,J.FORM_NAME INTO ##PS  
  FROM PRD_PS_DET T1    
  JOIN PRD_PS_MST MST ON MST.PS_ID=T1.PS_ID
  LEFT OUTER JOIN PRD_PMT P ON T1.PRODUCT_UID = P.PRODUCT_UID AND MST.DEPARTMENT_ID=P.DEPARTMENT_ID 
  JOIN PRD_SKU S ON S.PRODUCT_UID = T1.PRODUCT_UID           JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE        
  JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
  JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE      
  JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE				 JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE        
  JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE				 JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE        
  JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE				 JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE        
  JOIN UOM   E ON B.UOM_CODE = E.UOM_CODE					 JOIN FORM J ON T1.ITEM_FORM_ID= J.FORM_ID     
  WHERE T1.PS_ID IN ('+@CMEMOID+') AND MST.CANCELLED=0'
  PRINT @CQUERY    
 EXEC SP_EXECUTESQL @CQUERY
 SELECT * FROM ##PS
   
SELECT ROW_NUMBER() OVER(ORDER BY ARTICLE_NO) AS S_NO, ARTICLE_CODE, ARTICLE_NO, ARTICLE_NAME, PARA1_CODE,      
PARA1_NAME, PARA2_CODE, PARA2_NAME, PARA3_CODE, PARA3_NAME, UOM_NAME, CODING_SCHEME, 0 AS QUANTITY_IN_STOCK,      
0 AS PURCHASE_PRICE, 0 AS  MRP,0 AS WS_PRICE,  SECTION_NAME, SUB_SECTION_NAME, PARA4_CODE,PARA5_CODE,PARA6_CODE,      
PARA4_NAME,PARA5_NAME,PARA6_NAME,UOM_CODE,ISNULL(UOM_TYPE,0) AS [UOM_TYPE], FORM_NAME,   STOCK_NA, NEWID() AS ROW_ID
,SUM(A.QUANTITY) AS QUANTITY,SUM(A.QUANTITY) AS PREVQTY,SALE_RATE AS RATE,SALE_RATE ,
0  AS DISCOUNT_PERCENTAGE,0 AS DISCOUNT_AMOUNT,ITEM_FORM_ID,TAX_PERCENTAGE,SUM(TAX_AMOUNT) AS TAX_AMOUNT,SUM(AMOUNT) AS AMOUNT
FROM ##PS A
GROUP BY  ARTICLE_CODE, ARTICLE_NO, ARTICLE_NAME, PARA1_CODE,  PARA1_NAME, PARA2_CODE, PARA2_NAME, 
PARA3_CODE, PARA3_NAME, UOM_NAME, CODING_SCHEME,  SECTION_NAME, 
SUB_SECTION_NAME, PARA4_CODE,PARA5_CODE,PARA6_CODE, PARA4_NAME,PARA5_NAME,PARA6_NAME,UOM_CODE,
ISNULL(UOM_TYPE,0) , FORM_NAME,   STOCK_NA,ITEM_FORM_ID,TAX_PERCENTAGE,TAX_AMOUNT,SALE_RATE
 
  
GOTO LAST  
 
LBLPAYMENTDETAILS:    
  
  EXEC SP_PRD_PYMTDETAILS 1,'WSL',@CMEMOID    
  GOTO LAST    
    
LBLPAYMODEMST:      
  
  EXEC SP_PRD_PYMTDETAILS 2,'','',''    
  GOTO LAST  
    
LAST:    
END   

--CREATE PROCEDURE SP_PRD_WSLINV     
    
-- @NQUERYID NUMERIC (3,0) ,    
-- @CMEMOID VARCHAR(MAX) = '',    
-- @CWHERE1 VARCHAR(500) = '',    
-- @NNAVMODE NUMERIC(1,0) = 0,    
-- @CWHERE2 NVARCHAR(MAX)=''    
    
--AS    
--BEGIN    
    
--DECLARE @CCMD NVARCHAR(4000)    
--DECLARE @CLOC_ID VARCHAR(5)    
--DECLARE @CHO_ID  VARCHAR(5)    
--DECLARE @BCO_OWNED BIT    
--DECLARE @BPUR_LOC BIT    
--DECLARE @BPOS BIT    
    
--SET @BPOS=1    
--SET @BCO_OWNED=0    
--SET @BPUR_LOC=0    
    
--SELECT @CLOC_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'    
    
--SELECT @CHO_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'    
    
--SELECT @BCO_OWNED=(CASE WHEN ISNULL(LOC_TYPE,0)=1 THEN 1 ELSE 0 END ) FROM LOCATION WHERE DEPT_ID=@CLOC_ID    
    
--SELECT @BPUR_LOC=(CASE WHEN ISNULL(PUR_LOC,0)=1 THEN 1 ELSE 0 END ) FROM LOCATION WHERE DEPT_ID=@CLOC_ID    
    
--IF @CLOC_ID<>@CHO_ID    
-- SET @BPOS=0    
     
--IF @NQUERYID = 1    
--GOTO LBLNAVIGATE    
    
--ELSE IF @NQUERYID = 2    
--GOTO LBLGETMASTER    
    
--ELSE IF @NQUERYID = 3    
--GOTO LBLGETDETAIL    
    
--ELSE IF @NQUERYID = 4    
--GOTO LBLFORMS    
    
--ELSE IF @NQUERYID = 5    
--GOTO LBLCUSTOMER    
    
--ELSE IF @NQUERYID = 6    
--GOTO LBLSTOCKDETAILS    
   
--ELSE IF @NQUERYID = 8    
--GOTO LBLREPORTS    
    
--ELSE IF @NQUERYID = 9    
--GOTO LBLPRODUCTCODELIST    
    
--ELSE IF @NQUERYID = 10   
--GOTO LBLITVDETAILS  
  
--ELSE IF @NQUERYID = 11    
--GOTO LBLWOLIST  
  
--ELSE IF @NQUERYID=12  
--GOTO LBLWORKORDERDETAILLIST  

--ELSE IF @NQUERYID=13
--GOTO LBLPSMST

--ELSE IF @NQUERYID=14  
--GOTO LBLPSDET

--ELSE IF @NQUERYID=15    
--GOTO LBLPAYMENTDETAILS    
  
--ELSE IF @NQUERYID=16    
--GOTO LBLPAYMODEMST   
-----------     
--ELSE    
--GOTO LAST    
--LBLNAVIGATE:      
-- EXECUTE SP_NAVIGATE 'PRD_INM01106',@NNAVMODE,@CMEMOID,@CWHERE2,'INV_NO','INV_DT','INV_ID',@CWHERE1      
--GOTO LAST    
    
--LBLGETMASTER:      
--  SELECT T1.*,T2.USERNAME,T3.FORM_NAME,T4.AC_NAME,T4.ADDRESS0,T4.ADDRESS1,T4.ADDRESS2,     
--  T4.AREA_NAME,T4.CITY,T4.[STATE],T4.PINCODE, T5.EMP_NAME,ISNULL(T6.DEPT_NAME,'') AS DEPT_NAME  ,  
--  WO.MEMO_NO  
--  FROM PRD_INM01106 T1     
--  LEFT OUTER JOIN USERS T2  ON T1.USER_CODE = T2.USER_CODE    
--  LEFT OUTER JOIN FORM T3  ON T3.FORM_ID = T1.FORM_ID    
--  JOIN LMV01106 T4 ON T4.AC_CODE = T1.AC_CODE    
--  LEFT OUTER JOIN EMPLOYEE T5 ON T5.EMP_CODE = T1.EMP_CODE    
--  LEFT OUTER JOIN LOCATION T6 ON T6.DEPT_ID = T1.PARTY_DEPT_ID   
--  LEFT OUTER JOIN PRD_WO_MST WO ON   WO.MEMO_ID=T1.REF_WO_ID  
--  WHERE T1.INV_ID = @CMEMOID    
      
--GOTO LAST    
    
--LBLGETDETAIL:    
--  SELECT T1.*,ROW_NUMBER() OVER(ORDER BY ARTICLE_NO) AS S_NO,    
--  T1.PRODUCT_UID, B.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, S.PARA1_CODE,      
--  C.PARA1_NAME, S.PARA2_CODE, D.PARA2_NAME, S.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,         
--  T1.DEPT_ID, B.CODING_SCHEME,  B.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,      
--  S.PURCHASE_PRICE,  S.MRP,S.WS_PRICE,  '' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
--  S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE,      
--  PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
--  B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],S.DT_CREATED AS [SKU_DT_CREATED],      
--  B.STOCK_NA,((T1.QUANTITY*T1.RATE)-T1.DISCOUNT_AMOUNT) AS AMOUNT,    
--  T1.QUANTITY AS PREVQTY,J.FORM_NAME   
--  FROM PRD_IND01106 T1    
--  LEFT OUTER JOIN PRD_PMT P ON T1.PRODUCT_UID = P.PRODUCT_UID AND P.DEPARTMENT_ID=T1.DEPT_ID      
--  JOIN PRD_SKU S ON S.PRODUCT_UID = T1.PRODUCT_UID       
--  JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE        
--  JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
--  JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE      
--  JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE        
--  JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE        
--  JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE        
--  JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE        
--  JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE        
--  JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE        
--  JOIN UOM   E ON B.UOM_CODE = E.UOM_CODE     
--  JOIN FORM J ON T1.ITEM_FORM_ID= J.FORM_ID     
--  WHERE T1.INV_ID = @CMEMOID   
      
-- GOTO LAST    
    
--LBLFORMS:       
--  IF(@CWHERE1 = '1')    
--   SELECT * FROM FORM WHERE FORM_ID <> '0000000' AND EXCISE_ACCESSIBLE_PERCENTAGE > 0    
--   AND INACTIVE=0    
--  ELSE    
--   SELECT * FROM FORM WHERE FORM_ID <> '0000000' AND EXCISE_ACCESSIBLE_PERCENTAGE = 0    
--   AND INACTIVE=0    
--GOTO LAST    
    
--LBLCUSTOMER:      
 
--  DECLARE @CHEADCODESTR VARCHAR(1000),@CHEADCODESTR1 VARCHAR(1000)  
--  SELECT @CHEADCODESTR = DBO.FN_ACT_TRAVTREE('0000000018')    
--  SELECT @CHEADCODESTR1 = DBO.FN_ACT_TRAVTREE('0000000021')    
--  SELECT AC_CODE, AC_NAME, ADDRESS0,ADDRESS1,ADDRESS2 AREA_NAME , CITY, [STATE], PINCODE ,    
--  ISNULL(DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE    
--  FROM LMV01106      
--  WHERE ((CHARINDEX(HEAD_CODE,@CHEADCODESTR)>0 OR CHARINDEX(HEAD_CODE,@CHEADCODESTR1)>0)    
--  OR ALLOW_CREDITOR_DEBTOR=1) AND AC_CODE <>'0000000000'    
--  AND INACTIVE=0    
--  ORDER BY AC_NAME         

--GOTO LAST    
    
   
--LBLSTOCKDETAILS:    
-- SELECT T1.*,T1.PRODUCT_UID, B.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, S.PARA1_CODE,      
-- C.PARA1_NAME, S.PARA2_CODE, D.PARA2_NAME, S.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,         
-- T1.DEPARTMENT_ID, B.CODING_SCHEME,  B.INACTIVE, T1.QUANTITY_IN_STOCK,      
-- S.PURCHASE_PRICE,  S.MRP,S.WS_PRICE,  '' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
-- S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE,      
-- PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
-- B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],S.DT_CREATED AS [SKU_DT_CREATED],      
-- B.STOCK_NA  
-- FROM PRD_PMT T1    
-- JOIN PRD_SKU S ON T1.PRODUCT_UID = S.PRODUCT_UID       
-- JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE        
-- JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
-- JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE      
-- JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE        
-- JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE        
-- JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE        
-- JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE        
-- JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE        
-- JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE        
-- JOIN UOM   E ON B.UOM_CODE = E.UOM_CODE       
-- WHERE T1.QUANTITY_IN_STOCK > 0    
--GOTO LAST    
    
  
    
--LBLREPORTS:      
-- SELECT * FROM VW_WL_PRD_WSLINV WHERE MST_MEMO_NO = @CMEMOID      
--GOTO LAST    
    
--LBLPRODUCTCODELIST:      
--  SELECT DISTINCT T3.ARTICLE_NO,T1.PRODUCT_UID,T4.SUB_SECTION_NAME,P1.PARA1_NAME,P2.PARA2_NAME,  
--  T5.SECTION_NAME,T3.ARTICLE_CODE   ,T1.PURCHASE_PRICE AS RATE      
--  FROM PRD_SKU T1     
--  LEFT OUTER JOIN PRD_PMT T2 ON T1.PRODUCT_UID = T2.PRODUCT_UID    
--  JOIN ARTICLE T3 ON T1.ARTICLE_CODE = T3.ARTICLE_CODE    
--  JOIN SECTIOND T4 ON T3.SUB_SECTION_CODE = T4.SUB_SECTION_CODE    
--  JOIN PARA1 P1 ON P1.PARA1_CODE=T1.PARA1_CODE  
--  JOIN PARA2 P2 ON P2.PARA2_CODE=T1.PARA2_CODE  
--  JOIN SECTIONM T5 ON T5.SECTION_CODE = T4.SECTION_CODE    
--  WHERE T1.PRODUCT_UID <> '' AND T2.QUANTITY_IN_STOCK > 0 AND T2.DEPARTMENT_ID='DEF0000'   
--  ORDER BY T3.ARTICLE_NO       
-- GOTO LAST    
     
     
--LBLITVDETAILS:       
--  SELECT S1.PRODUCT_UID,T1.RATE AS PURCHASE_PRICE,B1.ARTICLE_NO,B1.ARTICLE_NAME,B1.CODING_SCHEME,    
--  D.SECTION_NAME,C1.SUB_SECTION_NAME,E.PARA1_NAME,F.PARA2_NAME ,F.PARA2_ORDER,G.PARA3_NAME,    
--  H.PARA4_NAME,I.PARA5_NAME,J.PARA6_NAME,B1.ARTICLE_DESC,K.AC_NAME,S1.INV_NO,S1.INV_DT,K.ALIAS,    
--  UOM.UOM_NAME,T1.QUANTITY,S1.MRP,S1.WS_PRICE,T1.DISCOUNT_PERCENTAGE,T1.DISCOUNT_AMOUNT,    
--  B.FORM_ID,C.FORM_NAME,C.TAX_PERCENTAGE,T1.RATE AS PURCHASE_PRICE    
--  FROM PRD_IND01106 T1    
--  JOIN PRD_INM01106 B  ON B.INV_ID=T1.INV_ID    
--  JOIN FORM C ON C.FORM_ID=B.FORM_ID    
--  JOIN LOCATION LOC ON LOC.DEPT_ID=B.PARTY_DEPT_ID    
--  --BY ROHIT JOIN ITV01106 T2 ON T1.PRODUCT_UID = T2.PRODUCT_UID     
--  JOIN PRD_SKU S1 ON S1.PRODUCT_UID=T1.PRODUCT_UID       
--  JOIN ARTICLE B1 ON B1.ARTICLE_CODE = S1.ARTICLE_CODE      
--  JOIN SECTIOND C1 ON C1.SUB_SECTION_CODE = B1.SUB_SECTION_CODE      
--  JOIN SECTIONM D ON D.SECTION_CODE = C1.SECTION_CODE      
--  JOIN PARA1 E ON E.PARA1_CODE = S1.PARA1_CODE      
--  JOIN PARA2 F ON F.PARA2_CODE = S1.PARA2_CODE      
--  JOIN PARA3 G ON G.PARA3_CODE = S1.PARA3_CODE      
--  JOIN PARA4 H ON H.PARA4_CODE = S1.PARA4_CODE      
--  JOIN PARA5 I ON I.PARA5_CODE = S1.PARA5_CODE      
--  JOIN PARA6 J ON J.PARA6_CODE = S1.PARA6_CODE      
--  JOIN LM01106 K ON K.AC_CODE=S1.AC_CODE       
--  JOIN UOM ON UOM.UOM_CODE=B1.UOM_CODE    
--  WHERE T1.INV_ID = @CMEMOID    
     
--GOTO LAST    
  
  
--LBLWOLIST:  
-- SELECT MEMO_ID,MEMO_NO FROM PRD_WO_MST WHERE  CANCELLED=0  AND MARK_AS_COMPLETED=1
   
--GOTO LAST  
  
--LBLWORKORDERDETAILLIST:  
  
  
--DECLARE @CQUERY1 NVARCHAR(MAX)--, @CMEMOID VARCHAR(50),@CWHERE1 VARCHAR(50)  
  
--SET @CQUERY1 = N' SELECT CAST(0 AS BIT) AS CHCK,A.ARTICLE_CODE AS [COMPONENT_CODE]  
--, B.ARTICLE_NO AS [COMPONENT_NAME]  
--,B1.ARTICLE_NO,B1.ARTICLE_NAME  
--,P11.PARA1_NAME ,P21.PARA2_NAME   
--,D.AVG_QTY   
--, E.PRODUCT_UID,E.ARTICLE_CODE AS ARTICLE_CODE,E.PARA1_CODE ,E.PARA2_CODE  
--,P1.PARA1_NAME AS COM_COLOR,P2.PARA2_NAME AS COM_SIZE ,(C.QUANTITY * D.AVG_QTY) AS QUANTITY ,F.QUANTITY_IN_STOCK  
--,CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN E.MRP ELSE E.PURCHASE_PRICE END AS RATE,  E.MRP ,E.WS_PRICE,  
-- CAST(0 AS NUMERIC) AS DISCOUNT_PERCENTAGE,CAST(0 AS NUMERIC) AS DISCOUNT_AMOUNT, E.TAX_AMOUNT AS ITEM_TAX_AMOUNT,  
-- E.FORM_ID AS ITEM_FORM_ID,G.FORM_NAME,G.TAX_PERCENTAGE AS ITEM_TAX_PERCENTAGE,D.ROW_ID +''-''+ C.ROW_ID AS ROW_ID  
--, B.UOM_CODE,H.UOM_NAME, (ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN E.MRP ELSE E.PURCHASE_PRICE END)) AS AMOUNT,
--SM.SECTION_NAME,SD.SUB_SECTION_NAME  
--FROM PRD_WO_DET A  
--JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE  
--JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID  
--JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID  
  
--JOIN ARTICLE B1 ON D.BOM_ARTICLE_CODE=B1.ARTICLE_CODE  
--JOIN PRD_SKU E ON E.ARTICLE_CODE=D.BOM_ARTICLE_CODE AND D.PARA1_CODE=E.PARA1_CODE  AND D.PARA2_CODE=E.PARA2_CODE '  
--SET @CQUERY1 = @CQUERY1+ N' JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B1.SUB_SECTION_CODE  
--JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE  
--JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID'
--IF ISNULL(@NNAVMODE,0)=0
--BEGIN
--	SET @CQUERY1 = @CQUERY1+ N' AND QUANTITY_IN_STOCK >0  '
--END
--SET @CQUERY1 = @CQUERY1+ N' JOIN PARA1 P1 ON P1.PARA1_CODE=E.PARA1_CODE  
--JOIN PARA2 P2 ON P2.PARA2_CODE=E.PARA2_CODE  
--JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE    
--JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE    
  
--JOIN FORM G ON G.FORM_ID=E.FORM_ID    
--JOIN UOM H ON H.UOM_CODE=B.UOM_CODE '  
   
--SET @CQUERY1 = @CQUERY1+ N' WHERE A.MEMO_ID= '''+@CMEMOID+''' AND (E.WORK_ORDER_ID='''+@CMEMOID+''' OR E.WORK_ORDER_ID='''') AND DEPARTMENT_ID='''+@CWHERE1+'''  '  
  
--SET @CQUERY1 = @CQUERY1+ N' ORDER BY COMPONENT_NAME, COM_COLOR,COM_SIZE,ARTICLE_NO,PARA1_NAME'  
--PRINT @CQUERY1  
--EXEC SP_EXECUTESQL @CQUERY1   
  
  
   
--SELECT DISTINCT CAST(0 AS BIT) AS CHCK,A.ARTICLE_CODE AS [COMPONENT_CODE]  
--, B.ARTICLE_NO AS [COMPONENT_NAME]  
--,B1.ARTICLE_NO,B1.ARTICLE_NAME  
--,P11.PARA1_NAME AS COM_COLOR,P21.PARA2_NAME AS COM_SIZE   
--,D.AVG_QTY   
--, E.PRODUCT_UID,E.ARTICLE_CODE AS ARTICLE_CODE,E.PARA1_CODE ,E.PARA2_CODE  
--,P1.PARA1_NAME, P2.PARA2_NAME,(C.QUANTITY * D.AVG_QTY) AS QUANTITY ,F.QUANTITY_IN_STOCK,E.PURCHASE_PRICE AS RATE,  E.MRP ,E.WS_PRICE,  
-- CAST(0 AS NUMERIC) AS DISCOUNT_PERCENTAGE,CAST(0 AS NUMERIC) AS DISCOUNT_AMOUNT, E.TAX_AMOUNT AS ITEM_TAX_AMOUNT,  
-- E.FORM_ID AS ITEM_FORM_ID,G.FORM_NAME,G.TAX_PERCENTAGE AS ITEM_TAX_PERCENTAGE,D.ROW_ID,  
-- B.UOM_CODE,H.UOM_NAME, (QUANTITY*E.PURCHASE_PRICE) AS AMOUNT,SM.SECTION_NAME,SD.SUB_SECTION_NAME  
--FROM PRD_WO_DET A  
--JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE  
--JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID  
--JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID  
--JOIN ARTICLE B1 ON D.BOM_ARTICLE_CODE=B1.ARTICLE_CODE  
--JOIN PRD_SKU E ON E.ARTICLE_CODE=D.BOM_ARTICLE_CODE AND D.PARA1_CODE=E.PARA1_CODE AND D.PARA2_CODE=E.PARA2_CODE    
--JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B1.SUB_SECTION_CODE  
--JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE  
--JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID AND QUANTITY_IN_STOCK >0  
--JOIN PARA1 P1 ON P1.PARA1_CODE=E.PARA1_CODE  
--JOIN PARA2 P2 ON P2.PARA2_CODE=E.PARA2_CODE  
--JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE    
--JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE    
  
--JOIN FORM G ON G.FORM_ID=E.FORM_ID    
--JOIN UOM H ON H.UOM_CODE=B.UOM_CODE   
--WHERE 1=2    
    
--GOTO LAST  
  
  
--LBLPSMST:  
   
-- IF OBJECT_ID('TEMPDB..#TMPWPS','U') IS NOT NULL  
--  DROP TABLE #TMPWPS  
    
--    SELECT DISTINCT ISNULL(A.PS_ID,'') AS PS_ID INTO #TMPWPS 
--    FROM PRD_IND01106 A (NOLOCK) 
--    JOIN PRD_INM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID    
--    WHERE B.AC_CODE=@CWHERE1 AND B.ENTRY_MODE=@NNAVMODE AND CANCELLED=0  
  
--     SELECT CAST(0 AS BIT) AS BILLCHECK, B.PS_ID,B.PS_NO,B.PS_DT,CAST(SUBSTRING(B.PS_NO,4,10) AS NUMERIC(10,0)) AS SR,  
--           SUM(QUANTITY) AS TOTAL_QTY,    
--           CAST('' AS NVARCHAR(10)) AS SRNO ,B.REMARKS    
--    FROM PRD_PS_DET A (NOLOCK)    
--    JOIN PRD_PS_MST B (NOLOCK) ON A.PS_ID= B.PS_ID     
--    LEFT OUTER JOIN #TMPWPS C ON C.PS_ID=B.PS_ID  
--    WHERE B.AC_CODE=@CWHERE1  AND CANCELLED=0 AND C.PS_ID IS NULL  
--    GROUP BY  B.PS_ID,B.PS_NO,B.PS_DT ,B.REMARKS   
--    ORDER BY SR   
  
-- GOTO LAST  
   
--LBLPSDET:  
--	DECLARE @CQUERY NVARCHAR(MAX)
--SET @CQUERY= N' SELECT T1.*,ROW_NUMBER() OVER(ORDER BY ARTICLE_NO) AS S_NO,    
--  T1.PRODUCT_UID, B.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, S.PARA1_CODE,      
--  C.PARA1_NAME, S.PARA2_CODE, D.PARA2_NAME, S.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,         
--  MST.DEPT_ID, B.CODING_SCHEME,  B.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,      
--  S.PURCHASE_PRICE,  S.MRP,S.WS_PRICE,  '''' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
--  S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE,      
--  PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
--  B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],S.DT_CREATED AS [SKU_DT_CREATED],      
--  B.STOCK_NA,((ISNULL(T1.QUANTITY,'''')* ISNULL(T1.RATE,''''))-ISNULL(T1.DISCOUNT_AMOUNT,'''')) AS AMOUNT,    
--  T1.QUANTITY AS PREVQTY,J.FORM_NAME   
--  FROM PRD_PS_DET T1    
--  JOIN PRD_PS_MST MST ON MST.PS_ID=T1.PS_ID
--  LEFT OUTER JOIN PRD_PMT P ON T1.PRODUCT_UID = P.PRODUCT_UID AND MST.DEPARTMENT_ID=P.DEPARTMENT_ID 
--  JOIN PRD_SKU S ON S.PRODUCT_UID = T1.PRODUCT_UID       
--  JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE        
--  JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
--  JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE      
--  JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE        
--  JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE        
--  JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE        
--  JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE        
--  JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE        
--  JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE        
--  JOIN UOM   E ON B.UOM_CODE = E.UOM_CODE     
--  JOIN FORM J ON T1.ITEM_FORM_ID= J.FORM_ID     
--  WHERE T1.PS_ID IN ('+@CMEMOID+') AND MST.CANCELLED=0'
--  PRINT @CQUERY    
-- EXEC SP_EXECUTESQL @CQUERY
 
-- GOTO LAST  
 
--LBLPAYMENTDETAILS:    
  
--  EXEC SP_PYMTDETAILS 1,'WSL',@CMEMOID    
--  GOTO LAST    
    
--LBLPAYMODEMST:      
  
--  EXEC SP_PYMTDETAILS 2,'','',''    
--  GOTO LAST  
    
--LAST:    
--END
