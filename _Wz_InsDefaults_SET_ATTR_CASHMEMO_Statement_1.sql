INSERT INTO SET_ATTR_CASHMEMO(CHK,ATTRIBUTES,SR_NO,LAST_UPDATE)
SELECT 0 AS [CHK], X.ATTRIBUTES ,X.SR_NO,GETDATE()
FROM 
(
	SELECT 1 AS SR_NO,'ARTICLE_NO' AS ATTRIBUTES
	UNION
	SELECT 2 AS SR_NO,'SECTION' AS ATTRIBUTES
	UNION
	SELECT 3 AS SR_NO,'SUB SECTION' AS ATTRIBUTES
	UNION
	SELECT 4 AS SR_NO,'PARA1' AS ATTRIBUTES
	UNION
	SELECT 5 AS SR_NO,'PARA2' AS ATTRIBUTES
	UNION
	SELECT 6 AS SR_NO,'PARA3' AS ATTRIBUTES
	UNION
	SELECT 7 AS SR_NO,'PARA4' AS ATTRIBUTES
	UNION
	SELECT 8 AS SR_NO,'PARA5' AS ATTRIBUTES
	UNION
	SELECT 9 AS SR_NO,'PARA6' AS ATTRIBUTES
)X
LEFT OUTER JOIN SET_ATTR_CASHMEMO B ON X.SR_NO=B.SR_NO
WHERE B.SR_NO IS NULL



UPDATE A SET A.ATTRIBUTES=X.ATTRIBUTES
FROM SET_ATTR_CASHMEMO A
JOIN 
(
	SELECT 1 AS SR_NO,'ARTICLE_NO' AS ATTRIBUTES
	UNION
	SELECT 2 AS SR_NO,'SECTION' AS ATTRIBUTES
	UNION
	SELECT 3 AS SR_NO,'SUB SECTION' AS ATTRIBUTES
	UNION
	SELECT 4 AS SR_NO,'PARA1' AS ATTRIBUTES
	UNION
	SELECT 5 AS SR_NO,'PARA2' AS ATTRIBUTES
	UNION
	SELECT 6 AS SR_NO,'PARA3' AS ATTRIBUTES
	UNION
	SELECT 7 AS SR_NO,'PARA4' AS ATTRIBUTES
	UNION
	SELECT 8 AS SR_NO,'PARA5' AS ATTRIBUTES
	UNION
	SELECT 9 AS SR_NO,'PARA6' AS ATTRIBUTES
)X ON X.SR_NO=A.SR_NO

