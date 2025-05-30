CREATE PROCEDURE PRD_PENDING_MATERIAL    
(    
@MEMOID VARCHAR(50),    
@COMPONENTCODE VARCHAR(50)    
)    
    
AS    
DECLARE @ARTICLECODE VARCHAR(20),@REQ_MEMOID VARCHAR(50)    
--SET @REQ_MEMOID = (SELECT DISTINCT MEMO_ID FROM PRD_AGENCY_ISSUE_MATERIAL_DET WHERE REF_PRD_WORKORDER_MEMOID     
--= @MEMOID)    
  
BEGIN   

   SELECT  DISTINCT CAST('0' AS BIT) AS CHK,B.MEMO_ID,A.AVG_QTY,A.BOM_ARTICLE_CODE AS ARTICLE_CODE,A.ROW_ID,E.QUANTITY*A.AVG_QTY AS REQ_QTY,D.AGENCY_NAME,
E1.ARTICLE_CODE  AS COMPONENT_CODE,    
F.UOM_CODE,B.MEMO_NO,F.ARTICLE_NO,E.PARA1_CODE AS COM_PARA1_CODE,E.PARA2_CODE AS COM_PARA2_CODE,G.UOM_NAME AS UOM,'0.00' AS ISSUE_QTY   
FROM PRD_WO_ART_BOM A      
JOIN PRD_WO_SUB_DET E ON A.REF_ROW_ID = E.REF_ROW_ID 
JOIN PRD_WO_DET E1 ON E1.ROW_ID = E.REF_ROW_ID 
JOIN
(
	SELECT B.MEMO_NO, A.MEMO_ID, B.REF_AGENCY_CODE ,A.REF_PRD_WORKORDER_MEMOID 
	FROM PRD_AGENCY_ISSUE_MATERIAL_DET A
	JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID =B.MEMO_ID
	WHERE B.CANCELLED =0 AND A.REF_PRD_WORKORDER_MEMOID = @MEMOID  
	--AND A.REF_COMPONENT_ARTICLE_CODE = 'HO0000337' 
	GROUP BY B.MEMO_NO, A.MEMO_ID,B.REF_AGENCY_CODE ,A.REF_PRD_WORKORDER_MEMOID 
) B ON E1.MEMO_ID =B.REF_PRD_WORKORDER_MEMOID 
LEFT JOIN
(
	SELECT A.MEMO_ID, B.REF_AGENCY_CODE ,A.REF_PRD_WORKORDER_MEMOID ,A.REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE 
	FROM PRD_AGENCY_ISSUE_MATERIAL_DET A
	JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID =B.MEMO_ID 
	JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=A.PRODUCT_UID 
	WHERE B.CANCELLED =0 AND A.REF_PRD_WORKORDER_MEMOID = @MEMOID  
	AND A.REF_COMPONENT_ARTICLE_CODE = @COMPONENTCODE 
	GROUP BY A.MEMO_ID,B.REF_AGENCY_CODE ,A.REF_PRD_WORKORDER_MEMOID ,A.REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE 
	UNION
	SELECT A.REF_ISSUE_ID, B.REF_AGENCY_CODE ,A.REF_PRD_WORKORDER_MEMOID ,A.REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE 
	FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING  A
	JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING  B ON A.MEMO_ID =B.MEMO_ID 
	JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=A.PRODUCT_UID 
	WHERE B.CANCELLED =0 AND A.REF_PRD_WORKORDER_MEMOID = @MEMOID  
	AND A.REF_COMPONENT_ARTICLE_CODE = @COMPONENTCODE 
	GROUP BY A.REF_ISSUE_ID,B.REF_AGENCY_CODE ,A.REF_PRD_WORKORDER_MEMOID ,A.REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE 
) B1 ON B.MEMO_ID =B1.MEMO_ID AND B.REF_PRD_WORKORDER_MEMOID =B1.REF_PRD_WORKORDER_MEMOID 
AND E1.ARTICLE_CODE=B1.REF_COMPONENT_ARTICLE_CODE
AND A.BOM_ARTICLE_CODE =B1.ARTICLE_CODE 
JOIN PRD_AGENCY_MST D ON D.AGENCY_CODE = B.REF_AGENCY_CODE    
JOIN ARTICLE F ON F.ARTICLE_CODE = A.BOM_ARTICLE_CODE    
JOIN UOM G ON G.UOM_CODE = F.UOM_CODE    
WHERE E1.MEMO_ID = @MEMOID  
AND E1.ARTICLE_CODE=@COMPONENTCODE
 AND B1.ARTICLE_CODE IS NULL  
 
--SELECT  DISTINCT CAST('0' AS BIT) AS CHK,C.MEMO_ID,A.AVG_QTY,A.BOM_ARTICLE_CODE AS ARTICLE_CODE,A.ROW_ID,E.QUANTITY*A.AVG_QTY AS REQ_QTY,D.AGENCY_NAME,B.REF_COMPONENT_ARTICLE_CODE AS COMPONENT_CODE,    
--F.UOM_CODE,C.MEMO_NO,F.ARTICLE_NO,E.PARA1_CODE AS COM_PARA1_CODE,E.PARA2_CODE AS COM_PARA2_CODE,G.UOM_NAME AS UOM,'0.00' AS ISSUE_QTY   
--FROM PRD_WO_ART_BOM A    
--JOIN PRD_AGENCY_ISSUE_MATERIAL_DET B ON A.REF_ROW_ID = B.REF_ROW_ID    
--JOIN PRD_AGENCY_ISSUE_MATERIAL_MST C ON C.MEMO_ID = B.MEMO_ID    
--JOIN PRD_WO_SUB_DET E ON A.REF_ROW_ID = E.REF_ROW_ID    
--JOIN PRD_AGENCY_MST D ON D.AGENCY_CODE = C.REF_AGENCY_CODE    
--JOIN ARTICLE F ON F.ARTICLE_CODE = A.BOM_ARTICLE_CODE    
--JOIN UOM G ON G.UOM_CODE = F.UOM_CODE    
--WHERE B.REF_PRD_WORKORDER_MEMOID = @MEMOID    
--AND B.REF_COMPONENT_ARTICLE_CODE = @COMPONENTCODE    
--AND A.BOM_ARTICLE_CODE IN    
--(SELECT A.BOM_ARTICLE_CODE FROM PRD_WO_ART_BOM A    
--JOIN PRD_AGENCY_ISSUE_MATERIAL_DET B    
--ON A.REF_ROW_ID = B.REF_ROW_ID    
--WHERE REF_COMPONENT_ARTICLE_CODE = @COMPONENTCODE AND REF_PRD_WORKORDER_MEMOID = @MEMOID    
--AND A.BOM_ARTICLE_CODE NOT IN    
--(SELECT ARTICLE_CODE FROM PRD_AGENCY_ISSUE_MATERIAL_REQ_DET 
--WHERE MEMO_ID IN (SELECT DISTINCT MEMO_ID FROM PRD_AGENCY_ISSUE_MATERIAL_DET WHERE REF_PRD_WORKORDER_MEMOID     
--= @MEMOID)    
-- AND COMPONENT_CODE = @COMPONENTCODE))    
END
