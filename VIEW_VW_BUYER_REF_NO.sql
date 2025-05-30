CREATE VIEW  VW_BUYER_REF_NO
AS
	SELECT   A.PRODUCT_CODE ,D.REF_NO ,MST.MEMO_NO AS JOBCARD_NO ,MST.MEMO_DT AS JOBCARD_DT
	FROM ORD_PLAN_BARCODE_DET A
	JOIN ORD_PLAN_DET B ON A.REFROW_ID =B.ROW_ID 
	JOIN ORD_PLAN_MST MST ON MST.MEMO_ID =B.MEMO_ID 
	LEFT JOIN BUYER_ORDER_DET C ON B.WOD_ROW_ID =C.ROW_ID 
	LEFT JOIN BUYER_ORDER_MST D ON C.ORDER_ID =D.ORDER_ID 
	WHERE MST.CANCELLED =0 AND ISNULL(D.CANCELLED,0) =0
	GROUP BY   A.PRODUCT_CODE ,D.REF_NO ,MST.MEMO_NO ,MST.MEMO_DT 

	