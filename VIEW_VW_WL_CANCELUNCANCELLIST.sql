CREATE VIEW VW_WL_CANCELUNCANCELLIST

 AS         
SELECT 
A.CNC_MEMO_ID AS MEMO_ID,
A.CNC_MEMO_NO AS 'MEMO_NO',
A.CNC_MEMO_DT AS 'MEMO_DT',
(CASE WHEN A.CNC_TYPE=1 THEN 'CANCELLATION' ELSE 'UNCANCELLATION' END) AS 'MEMO_TYPE',
A.REMARKS AS 'REMARKS',
ISNULL(ICD.TOTQTY,0) AS 'TOTAL_QUANTITY',
ISNULL(ICD.TOTMRPVAL,0) AS 'TOTAL_MRP_VALUE'

FROM ICM01106 A (NOLOCK) 

LEFT OUTER JOIN 
( SELECT CNC_MEMO_ID, SUM(QUANTITY) AS TOTQTY, SUM(B.MRP*QUANTITY) AS TOTMRPVAL FROM ICD01106 A
  JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE GROUP BY CNC_MEMO_ID ) 
ICD ON A.CNC_MEMO_ID = ICD.CNC_MEMO_ID

WHERE A.CANCELLED = 0    
--*************************************** END OF VIEW VW_WL_CANCELUNCANCELLIST
