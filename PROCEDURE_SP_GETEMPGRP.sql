CREATE PROCEDURE SP_GETEMPGRP

AS
BEGIN
	SELECT A.EMP_GRP_CODE,A.EMP_GRP_NAME,A.EMP_CODE,A.EMP_NAME,A.EMP_ALIAS,ISNULL(B.CHK,0) AS CHK ,GETDATE() AS [LAST_UPDATE] 
	FROM
	(
		SELECT A.EMP_GRP_CODE,A.EMP_GRP_NAME,B.EMP_CODE,B.EMP_NAME,B.EMP_ALIAS,CONVERT(BIT,0) AS [CHK]
		FROM EMPLOYEE_GRP A,EMPLOYEE B
		WHERE B.INACTIVE=0 AND A.INACTIVE=0  AND B.EMP_NAME <> ''
	)A
	LEFT OUTER JOIN 
	(
		SELECT A.EMP_GRP_CODE,C.EMP_GRP_NAME,A.EMP_CODE,D.EMP_NAME,D.EMP_ALIAS ,CONVERT(BIT,1) AS [CHK]
		FROM EMP_GRP_LINK A		
		JOIN EMPLOYEE_GRP C ON C.EMP_GRP_CODE=A.EMP_GRP_CODE
		JOIN EMPLOYEE D ON A.EMP_CODE=D.EMP_CODE
		WHERE  C.INACTIVE=0 AND D.INACTIVE=0 AND D.EMP_NAME <> ''
	)B ON A.EMP_GRP_CODE=B.EMP_GRP_CODE AND A.EMP_CODE=B.EMP_CODE
	WHERE A.EMP_GRP_CODE<>'0000000'
	ORDER BY EMP_GRP_NAME,CHK DESC ,EMP_NAME
END
