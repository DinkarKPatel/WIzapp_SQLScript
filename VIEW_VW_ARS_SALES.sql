CREATE VIEW VW_ARS_SALES  
AS  
SELECT /*LEFT(M.CM_ID,2)*//*Rohit 04-11-2024*/M.location_Code DEPT_ID
,M.CM_DT XN_DT
,D.PRODUCT_CODE
,SUM(QUANTITY)SALES_QTY
,'SALE' XN_MODE,0 STOCK_QTY,0 GIT_QTY  
FROM CMM01106 M (NOLOCK) JOIN CMD01106 D (NOLOCK) ON M.CM_ID=D.CM_ID  
WHERE M.CANCELLED=0   
GROUP BY /*LEFT(M.CM_ID,2)*//*Rohit 04-11-2024*/M.location_Code,M.CM_DT ,D.PRODUCT_CODE