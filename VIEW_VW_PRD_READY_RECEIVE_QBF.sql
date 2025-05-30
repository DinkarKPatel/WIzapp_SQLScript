CREATE VIEW VW_PRD_READY_RECEIVE_QBF  

AS       
SELECT  T3.AC_NAME AS MST_AC_NAME  ,T1.MEMO_NO AS MST_MEMO_NO ,T1.MEMO_DT  AS MST_MEO_DT   ,T1.REMARKS   AS MST_REMARKS  ,
WO.MEMO_NO AS MST_WO_NO,   
T1.MEMO_ID,  T1.AC_CODE    ,T1.MEMO_NO    ,T1.MEMO_DT    ,T1.SUBTOTAL    ,T1.REMARKS    ,T1.CANCELLED    
,T1.USER_CODE    ,T1.FIN_YEAR      
,T2.PRODUCT_UID,T2.QUANTITY    ,T2.RATE    ,T2.ROW_ID      
,T3.AC_NAME    ,T3.ALIAS    ,T3.HEAD_CODE    ,T3.CLOSING_BALANCE    ,T3.CLOSING_BALANCE_CR_DR    ,T3.PRINT_LEDGER      
,T3.PRINT_NAME    ,T3.AREA_CODE    ,T3.CITY_CODE    ,T3.STATE_CODE    ,T3.CREDIT_DAYS    ,T3.BILL_BY_BILL      
,T3.BROKER_COMM_PERCENT    ,T3.CREDIT_LIMIT    ,T3.CST_PERCENTAGE    ,T3.PAN_NO    ,T3.GLN_NO    ,T3.MP_PERCENTAGE    ,T3.MRP_CALC_MODE      
,T3.TDS_CODE    ,T3.INV_RATE_TYPE    ,T3.OUTSTATION_PARTY    ,T3.SALES_AC_CODE      

,T6.PARA1_CODE  ,P1.PARA1_NAME      
,T6.PARA2_CODE  ,P2.PARA2_NAME    
,T6.PARA3_CODE  ,P3.PARA3_NAME    
,T6.PURCHASE_PRICE    ,T6.RECEIPT_DT,T6.DT_CREATED    ,T6.WS_PRICE    ,T6.CHALLAN_NO      
,T7.CODING_SCHEME    ,T7.UOM_CODE    ,T7.PARA1_SET    ,T7.PARA2_SET    ,T7.INACTIVE      
,T7.SKU_CODE    ,T7.SUB_SECTION_CODE    ,T7.DISCON    ,T7.WHOLESALE_PRICE    ,T7.WSP_PERCENTAGE      
,T7.MIN_PRICE    ,T7.STOCK_NA    ,T7.ARTICLE_TYPE    ,T7.CREATED_ON    ,T7.ARTICLE_GROUP_CODE      
,T7.GENERATE_BARCODES_WITHARTICLE_PREFIX    ,T7.ARTICLE_GEN_MODE    ,T7.ARTICLE_PRD_MODE    ,T7.ARTICLE_SET_CODE      
,T7.OH_PERCENTAGE    ,T7.OH_AMOUNT    ,T8.SECTION_CODE    ,T8.MFG_CATEGORY    ,COM.COMPANY_CODE    
FROM PRD_READY_RECEIVE_MST T1      
JOIN PRD_READY_RECEIVE_DET T2 ON T1.MEMO_ID = T2.MEMO_ID      
JOIN LMV01106 T3 ON T3.AC_CODE = T1.AC_CODE      
JOIN PRD_SKU T6 ON T6.PRODUCT_UID = T2.PRODUCT_UID      
JOIN ARTICLE T7 ON T7.ARTICLE_CODE=T6.ARTICLE_CODE      
JOIN SECTIOND T8 ON T8.SUB_SECTION_CODE=T7.SUB_SECTION_CODE      
JOIN SECTIONM T9 ON T9.SECTION_CODE=T8.SECTION_CODE      
JOIN PARA1 P1 ON P1.PARA1_CODE=T6.PARA1_CODE      
JOIN PARA2 P2 ON P2.PARA2_CODE=T6.PARA2_CODE      
JOIN PARA3 P3 ON P3.PARA3_CODE=T6.PARA3_CODE      
JOIN PARA4 P4 ON P4.PARA4_CODE=T6.PARA4_CODE      
JOIN PARA5 P5 ON P5.PARA5_CODE=T6.PARA5_CODE      
JOIN PARA6 P6 ON P6.PARA6_CODE=T6.PARA6_CODE      
    
JOIN UOM ON UOM.UOM_CODE = T7.UOM_CODE      
LEFT OUTER JOIN COMPANY COM ON 1=1 AND COM.COMPANY_CODE='01'      
   LEFT OUTER JOIN PRD_WO_MST AS WO ON WO.MEMO_ID=T1.WORK_ORDER_ID
