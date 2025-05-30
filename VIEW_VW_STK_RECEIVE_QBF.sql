CREATE VIEW VW_STK_RECEIVE_QBF 

AS 
	SELECT  CONVERT(CHAR(10),T1.MEMO_DT,105) AS MST_MEMO_DATE 
	,ISNULL(T6.MEMO_NO,'') AS MST_WORK_ORDER_MEMO_NO
	,T3.DEPARTMENT_NAME AS SOURCE_DEPARTMENT_NAME
	,T3.DEPARTMENT_NAME AS MST_SOURCE_DEPARTMENT_NAME
	,T33.DEPARTMENT_NAME AS TARGET_DEPARTMENT_NAME
	,CASE WHEN T1.CANCELLED =0 THEN '' ELSE 'CANCELLED' END AS CANCELLED
	,(CASE WHEN T6.MEMO_DT <> '' THEN CONVERT(CHAR(10),ISNULL(T6.MEMO_DT,''),105) ELSE ''  END) AS WORK_ORDER_DATE
	,ISNULL(T6.REF_NO,'') AS WORK_ORDER_REFNO
	,ART.ARTICLE_NO,ART.ARTICLE_NAME,ART.ARTICLE_CODE,ART.ARTICLE_DESC
	,U.UOM_NAME 
	,DET.QUANTITY
	,PARA1.PARA1_NAME ,PARA2.PARA2_NAME,PARA3.PARA3_NAME ,PARA4.PARA4_NAME,SKU.PRODUCT_CODE
	, T1.MEMO_NO
	, T1.MEMO_NO AS MST_MEMO_NO
	,CONVERT(CHAR(10),T1.MEMO_DT,105) AS MEMO_DT
	,T1.MEMO_ID,T1.SOURCE_DEPARTMENT_ID
	,T1.SOURCE_DEPARTMENT_ID AS DEPARTMENT_ID
	,SEC.SECTION_NAME,SSEC.SUB_SECTION_NAME
	,COMP.CIN,COMP.PAN_NO,COMP.EMAIL_ID,COMP.PWD,COMP.STATE,COMP.COUNTRY,COMP.MOBILE
	,COMP.CONTACT_NAME,COMP.TDS_AC_NO,COMP.COMPANY_CODE,COMP.COMPANY_NAME,COMP.ALIAS,COMP.ADDRESS1
	,COMP.ADDRESS2,COMP.CITY,COMP.TIN_NO,COMP.TAN_NO,COMP.PHONES_FAX,COMP.CST_NO,COMP.CST_DT,COMP.SST_NO
	,COMP.SST_DT,COMP.ADDRESS9,COMP.AREA_CODE,COMP.PRINT_ADDRESS,COMP.WORKABLE,COMP.PIN
	,COMP.WEB_ADDRESS,COMP.POLICY_NO,COMP.GST_NO
	FROM PRD_STK_RECEIVE_MST T1 
	JOIN PRD_STK_RECEIVE_DET DET ON DET.MEMO_ID = T1.MEMO_ID
	JOIN PRD_SKU SKU ON SKU .PRODUCT_UID =DET.PRODUCT_UID
	JOIN ARTICLE ART ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE 
	JOIN UOM U ON ART.UOM_CODE = U.UOM_CODE 
	JOIN PARA1 ON PARA1.PARA1_CODE = SKU.PARA1_CODE
	JOIN PARA2 ON PARA2.PARA2_CODE = SKU.PARA2_CODE
	JOIN PARA3 ON PARA3.PARA3_CODE = SKU.PARA3_CODE
	JOIN PARA4 ON PARA4.PARA4_CODE = SKU.PARA4_CODE
	JOIN SECTIOND SSEC ON SSEC.SUB_SECTION_CODE = ART.SUB_SECTION_CODE 
	JOIN SECTIONM SEC ON SEC.SECTION_CODE  = SSEC.SECTION_CODE  
	JOIN PRD_DEPARTMENT_MST T3 ON T3.DEPARTMENT_ID = T1.SOURCE_DEPARTMENT_ID
	JOIN PRD_DEPARTMENT_MST T33 ON T33.DEPARTMENT_ID = T1.TARGET_DEPARTMENT_ID
	JOIN PRD_WO_MST T6 ON DET.REF_WO_ID= T6.MEMO_ID
	JOIN COMPANY COMP ON COMP.COMPANY_CODE='01'
