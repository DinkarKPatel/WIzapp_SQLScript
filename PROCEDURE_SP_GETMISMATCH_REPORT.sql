CREATE PROCEDURE SP_GETMISMATCH_REPORT
--WITH ENCRYPTION
AS
BEGIN
	SELECT ISNULL(A.DEPT_ID,B.DEPT_ID) AS DEPT_ID,ISNULL(A.XN_TYPE,B.XN_TYPE) AS XN_TYPE,  
		 ISNULL(A.XN_ID,B.XN_ID) AS XN_ID,ISNULL(A.XN_NET,0) AS [LOC_NET],ISNULL(B.XN_NET,0) AS [HO_NET] ,
		 ISNULL(A.XN_QTY,0) AS [LOC_QTY],ISNULL(B.XN_QTY,0)  AS [HO_QTY]
		 ,ISNULL(A.CANCELLED,0) AS [LOC_CANCEL],ISNULL(B.CANCELLED,0) AS [HO_CANCEL]
		 ,LOC.DEPT_ID+ ' ' +LOC.DEPT_NAME AS [DEPT_NAME]
	FROM  LOC_DTRECON  B  
	JOIN LOCATION LOC ON LOC.DEPT_ID=B.DEPT_ID
	LEFT OUTER JOIN VW_LOCDTRECON  A ON A.DEPT_ID=B.DEPT_ID AND A.XN_TYPE=B.XN_TYPE AND A.XN_ID=B.XN_ID  
	WHERE ((ISNULL(A.XN_TYPE,B.XN_TYPE) IN ('CHI','CHO','CNC','OPS') AND ISNULL(A.XN_QTY,0)<>ISNULL(B.XN_QTY,0))  
	OR (ISNULL(A.XN_TYPE,B.XN_TYPE) NOT IN ('CHI','CHO','CNC','OPS','IRT') AND   
	(ISNULL(A.XN_NET,0)<>ISNULL(B.XN_NET,0) OR A.DEPT_ID IS  NULL))  
	OR (B.XN_TYPE IN ('IRT') AND ISNULL(A.XN_QTY,0)<>ISNULL(B.XN_QTY,0))  
	OR ISNULL(A.CANCELLED,0)<>ISNULL(B.CANCELLED,0))
	
	SELECT DISTINCT A.DEPT_ID,'DLR' AS XN_TYPE,CONVERT(VARCHAR(10),A.XN_DT,112) AS XN_ID ,C.DEPT_ID+' '+C.DEPT_NAME AS [DEPT_NAME]
	FROM  VW_LOCDTRECON  A
	JOIN LOCATION C ON C.DEPT_ID=A.DEPT_ID
	LEFT OUTER JOIN LOC_DTRECON B ON A.DEPT_ID=B.DEPT_ID AND A.XN_TYPE=B.XN_TYPE AND A.XN_ID=B.XN_ID
	WHERE B.XN_ID IS NULL

END
