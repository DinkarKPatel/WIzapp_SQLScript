CREATE VIEW VW_WL_WSLINV_QBF

AS   
SELECT T1.INV_ID ,  
T1.INV_DT AS MST_INV_DT,  
T1.INV_NO AS MST_INV_NO,  
T1.SUBTOTAL AS MST_SUBTOTAL,  
T1.DISCOUNT_PERCENTAGE AS MST_DISCOUNT_PERCENTAGE ,  
T1.DISCOUNT_AMOUNT AS MST_DISCOUNT_AMOUNT ,  
T1.FREIGHT AS MST_FREIGHT ,  
T1.OTHER_CHARGES AS MST_OTHER_CHARGES ,  
T1.NET_AMOUNT AS MST_NET_AMOUNT ,  
T1.REMARKS AS MST_REMARKS ,  
T1.GRLR_DATE AS MST_GRLR_DATE ,  
T1.BANDALS AS MST_BANDALS ,  
T1.THROUGH AS MST_THROUGH ,  
T1.INSURANCE AS MST_INSURANCE ,   
T1.OCTROI_PERCENTAGE AS MST_OCTROI_PERCENTAGE,  
T1.OCTROI_AMOUNT AS MST_OCTROI_AMOUNT,  
T1.PARTY_DA_NO AS MST_PARTY_DA_NO ,  
T1.PARTY_PO_NO AS MST_PARTY_PO_NO ,  
T1.MANUAL_INV_NO AS MST_MANUAL_INV_NO, 
T1.INV_TYPE ,
T1.INV_TYPE AS MST_INV_TYPE,
T1.XFER_TYPE,
T1.XFER_TYPE AS MST_XFER_TYPE, 
T2.PRODUCT_CODE ,  
T2.QUANTITY,  
T2.RATE,  
T2.DISCOUNT_PERCENTAGE,  
T2.DISCOUNT_AMOUNT,  
T2.QUANTITY*T2.NET_RATE AS AMOUNT,  
T3.AC_NAME AS MST_AC_NAME,   
T5.EMP_NAME AS MST_EMP_NAME,  
ARTICLE_NO,  
S.MRP,T1.INV_MODE AS MST_INV_MODE ,
SECTION_NAME ,
SUB_SECTION_NAME,
PARA1_NAME ,
PARA2_NAME ,
PARA3_NAME ,
PARA4_NAME ,
PARA5_NAME ,
PARA6_NAME ,
S.PRODUCT_NAME,
T2.BOX_NO,
T2.BOX_DT ,
T2.ITEM_TAX_AMOUNT AS MST_TAX_AMOUNT,
T2.ITEM_TAX_AMOUNT ,
T2.ITEM_TAX_PERCENTAGE ,
T1.MEMO_PREFIX AS MST_MEMO_PREFIX,
T1.EXCISE_ACCESSIBLE_AMOUNT AS MST_EXCISE_ACCESSIBLE_AMOUNT,
T1.EXCISE_ACCESSIBLE_PERCENTAGE  AS MST_EXCISE_ACCESSIBLE_PERCENTAGE,
T1.EXCISE_DUTY_AMOUNT AS  MST_EXCISE_DUTY_AMOUNT,
T1.EXCISE_DUTY_PERCENTAGE  AS MST_EXCISE_DUTY_PERCENTAGE,
T1.EXCISE_EDU_CESS_AMOUNT AS MST_EXCISE_EDU_CESS_AMOUNT,
T1.EXCISE_EDU_CESS_PERCENTAGE  AS MST_EXCISE_EDU_CESS_PERCENTAGE,
T1.EXCISE_HEDU_CESS_PERCENTAGE AS MST_EXCISE_HEDU_CESS_PERCENTAGE,
T1.EXCISE_HEDU_CESS_AMOUNT AS MST_EXCISE_HEDU_CESS_AMOUNT,
T1.ROUND_OFF AS MST_ROUND_OFF,
ISNULL(T7.DT_NAME,'') AS MST_DT_NAME,
T8.DEPT_NAME AS MST_DEPT_NAME,
T9.EMP_NAME AS MST_EMP_NAME1,  
T10.EMP_NAME AS MST_EMP_NAME2,
T9.EMP_NAME AS EMP_NAME1,    
T10.EMP_NAME AS EMP_NAME2,  
T5.EMP_NAME,
T1.MEMO_TYPE,
T2.SCHEME_QUANTITY,
T2.INVOICE_QUANTITY,  
PSM.PS_NO,
PSM.PS_DT,
T1.FIN_YEAR AS MST_FIN_YEAR,
T1.MEMO_TYPE AS MST_MEMO_TYPE,
T1.ENTRY_MODE AS MST_ENTRY_MODE,
T1.PAY_MODE AS MST_PAY_MODE,
T1.LOTTYPE AS MST_LOTTYPE,
T1.TAXFORM_STORAGE_MODE AS MST_TAXFORM_STORAGE_MODE,
T1.BILL_LEVEL_TAX_METHOD AS MST_BILL_LEVEL_TAX_METHOD,
T2.NET_RATE, FORM_NAME,T1.LOCATION_CODE
FROM INM01106 T1  
JOIN IND01106 T2 ON T1.INV_ID = T2.INV_ID  
LEFT OUTER JOIN LMV01106 T3 ON T3.AC_CODE = T1.AC_CODE  
LEFT OUTER JOIN EMPLOYEE T5 ON T5.EMP_CODE = T2.EMP_CODE  
--LEFT OUTER JOIN PMV01106 T6 ON T6.PRODUCT_CODE = T2.PRODUCT_CODE  --- OPTIMIZATION AFTER REMOVING VIEWS
LEFT OUTER JOIN DTM T7 ON T1.DT_CODE = T7.DT_CODE   
LEFT OUTER JOIN LOCATION T8 ON T8.DEPT_ID = T1.PARTY_DEPT_ID 
LEFT OUTER JOIN EMPLOYEE T9 ON T9.EMP_CODE = T2.EMP_CODE1
LEFT OUTER JOIN EMPLOYEE T10 ON T9.EMP_CODE = T2.EMP_CODE2
LEFT OUTER JOIN WPS_DET PSD ON PSD.PS_ID=T2.PS_ID
LEFT OUTER JOIN WPS_MST PSM ON PSM.PS_ID=PSD.PS_ID
LEFT OUTER JOIN FORM  ON FORM.FORM_ID=T2.ITEM_FORM_ID
JOIN SKU S ON S.PRODUCT_CODE=T2.PRODUCT_CODE
JOIN ARTICLE B ON S.ARTICLE_CODE = B.ARTICLE_CODE  
JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE
JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE
JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE  
JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE  
JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE  
JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE  
JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE  
JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE
