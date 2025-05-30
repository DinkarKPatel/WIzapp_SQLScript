CREATE VIEW VW_WL_RATEREVISIONLIST 

AS         

SELECT 
A.IRM_MEMO_DT AS 'MEMO_DT', 
A.IRM_MEMO_ID AS 'MEMO_ID', 
A.IRM_MEMO_NO AS 'MEMO_NO', 
A.REMARKS AS 'REMARKS', 
(CASE WHEN A.REVISION_TYPE=1 THEN 'RATE REVISION' ELSE ' TAG PRINTING' END) AS 'REVISION_TYPE', 
(CASE WHEN A.TYPE=1 THEN 'MANUAL' ELSE 'AUTO' END) AS 'REVISION_MODE',
ISNULL(B.TOTAL_QUANTITY,0) AS TOTAL_QUANTITY  
FROM IRM01106 A
LEFT OUTER JOIN
(SELECT IRM_MEMO_ID,SUM(QUANTITY) AS TOTAL_QUANTITY FROM IRD01106
 GROUP BY IRM_MEMO_ID ) B ON A.IRM_MEMO_ID = B.IRM_MEMO_ID
