CREATE VIEW VW_ISSUERM_PRINT
AS

	SELECT A.ISSUE_ID , A.ISSUE_NO ,A.ISSUE_DT , B.PRODUCT_CODE ,
		   D.RM_PRODUCT_CODE ,
		   D.QUANTITY,D.WASTAGE_QUANTITY,D.AVG_QUANTITY,D.PURCHASE_PRICE,
		   ART.ARTICLE_NO ,
		   SD.SUB_SECTION_NAME ,SM.SECTION_NAME 
	FROM JOBWORK_ISSUE_MST A 
	JOIN JOBWORK_ISSUE_DET B ON A.ISSUE_ID =B.ISSUE_ID 
	JOIN
	(
	  SELECT D.PRODUCT_CODE AS RM_PRODUCT_CODE,
			 D.QUANTITY,D.WASTAGE_QUANTITY,D.AVG_QUANTITY,D.PURCHASE_PRICE,
			 C.PRODUCT_CODE ,
			 SR=ROW_NUMBER () OVER (PARTITION BY C.PRODUCT_CODE ORDER BY A.RECEIPT_DT DESC,A.MEMO_ID DESC  )
	  FROM SNC_MST  A
	  JOIN SNC_DET B ON A.MEMO_ID =B.MEMO_ID 
	  JOIN SNC_BARCODE_DET  C ON B.ROW_ID =C.REFROW_ID 
	  JOIN SNC_CONSUMABLE_DET D ON A.MEMO_ID =D.MEMO_ID 
	  WHERE A.CANCELLED =0
	) D ON B.PRODUCT_CODE =D.PRODUCT_CODE AND D.SR =1
	JOIN SKU ON SKU.PRODUCT_CODE =D.RM_PRODUCT_CODE 
	JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
	JOIN SECTIOND SD ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 
	JOIN SECTIONM SM ON SM.SECTION_CODE =SD.SECTION_CODE
