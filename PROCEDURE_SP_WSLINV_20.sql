CREATE procEDURE SP_WSLINV_20--(LocId 3 digit change only increased the parameter width by Sanjay:04-11-2024)
	@CMEMOID	VARCHAR(40) = '',
	@CWHERE1	VARCHAR(500) = '',
	@NNAVMODE	NUMERIC(1,0) = 0,
	@CWHERE2	NVARCHAR(MAX)='',
	@DMEMODT DATETIME='',
	@CLOCID		VARCHAR(4)=''
----WITH ENCRYPTION
AS
BEGIN
	IF (@NNAVMODE = 1)
	BEGIN
		SELECT CONVERT(BIT,0) AS CHK,(X.QUANTITY-ISNULL(Y.QTY,0)) AS PENDING_QUANTITY
		,X.QUANTITY AS QUANTITY ,X.ROW_ID,X.MEMO_ID AS PICK_LIST_ID,BOM.ORDER_ID,BOM.ORDER_NO
		,ART.ARTICLE_NO,SD.SUB_SECTION_NAME,SM.SECTION_NAME,P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME
		,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,ART.ARTICLE_CODE AS PICKLIST_ARTICLE_CODE ,
		P1.PARA1_CODE AS PICKLIST_PARA1_CODE ,P2.PARA2_CODE AS PICKLIST_PARA2_CODE,X.ROW_ID AS PICK_LIST_ROW_ID 
		FROM PLD01106 X
		LEFT OUTER JOIN 
		(
			SELECT A.ROW_ID AS PICKLIST_ROW_ID,SUM(B.QUANTITY) AS QTY 
			FROM PLD01106 A 
		    JOIN IND01106 B ON A.ROW_ID=B.PICK_LIST_ROW_ID 
		 --   AND A.ARTICLE_CODE=B.PICKLIST_ARTICLE_CODE
			--AND A.PARA1_CODE=B.PICKLIST_PARA1_CODE AND A.PARA2_CODE=B.PICKLIST_PARA2_CODE
			JOIN INM01106 C ON B.INV_ID = C.INV_ID
			WHERE C.CANCELLED = 0 
			AND C.AC_CODE=@CWHERE1
			GROUP BY A.ROW_ID
		)Y ON X.ROW_ID = Y.PICKLIST_ROW_ID
		JOIN PLM01106 Z ON X.MEMO_ID = Z.MEMO_ID
		JOIN BUYER_ORDER_DET BOM1 ON X.ORD_ROW_ID = BOM1.ROW_ID
		JOIN BUYER_ORDER_MST BOM ON BOM1.ORDER_ID = BOM.ORDER_ID
		JOIN ARTICLE ART ON ART.ARTICLE_CODE =BOM1.ARTICLE_CODE
		JOIN SECTIOND SD ON SD.SUB_SECTION_CODE = ART.SUB_SECTION_CODE
		JOIN SECTIONM SM ON SM.SECTION_CODE = SD.SECTION_CODE
		JOIN PARA1 P1 ON BOM1.PARA1_CODE = P1.PARA1_CODE
		JOIN PARA2 P2 ON BOM1.PARA2_CODE = P2.PARA2_CODE
		JOIN PARA3 P3 ON ART.PARA3_CODE = P3.PARA3_CODE
		JOIN PARA4 P4 ON ART.PARA4_CODE = P4.PARA4_CODE
		JOIN PARA5 P5 ON ART.PARA5_CODE = P5.PARA5_CODE
		JOIN PARA6 P6 ON ART.PARA6_CODE = P6.PARA6_CODE
		WHERE BOM.MEMO_TYPE=2 AND Z.CANCELLED = 0 AND BOM.AC_CODE = @CWHERE1  AND (X.QUANTITY-ISNULL(Y.QTY,0))>0
		
	END
	ELSE
	BEGIN
		SELECT  CONVERT(BIT,(CASE WHEN Y.PICKLIST_ROW_ID IS NULL THEN 0 ELSE 1 END)) AS CHK
		,(X.PICK_LIST_QTY+ADD_QTY-ISNULL(Y.QTY,0)-ISNULL(Y1.QTY,0)) AS PENDING_QUANTITY,X.PICK_LIST_QTY+ADD_QTY AS QUANTITY 
		,X.ROW_ID,X.PICK_LIST_ID,BOM.ORDER_ID,BOM.ORDER_NO
		,ART.ARTICLE_NO,SD.SUB_SECTION_NAME,SM.SECTION_NAME,P1.PARA1_NAME,P2.PARA2_NAME
		,P3.PARA3_NAME,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME ,X.ARTICLE_CODE AS PICKLIST_ARTICLE_CODE 
		,X.PARA1_CODE AS PICKLIST_PARA1_CODE ,X.PARA2_CODE AS PICKLIST_PARA2_CODE 
		FROM WSL_PICKLIST_DET X
		LEFT OUTER JOIN 
		(
			SELECT A.ROW_ID AS PICKLIST_ROW_ID,SUM(B.QUANTITY) AS QTY 
			FROM WSL_PICKLIST_DET A 
			JOIN IND01106 B ON A.PICK_LIST_ID=B.PICK_LIST_ID AND A.ARTICLE_CODE=B.PICKLIST_ARTICLE_CODE
			AND A.PARA1_CODE=B.PICKLIST_PARA1_CODE AND A.PARA2_CODE=B.PICKLIST_PARA2_CODE
			JOIN INM01106 C ON B.INV_ID = C.INV_ID
			WHERE C.CANCELLED = 0 AND C.INV_ID = @CMEMOID
			GROUP BY A.ROW_ID
		) Y ON X.ROW_ID = Y.PICKLIST_ROW_ID
		LEFT OUTER JOIN 
		(
			SELECT A.ROW_ID AS PICKLIST_ROW_ID,SUM(B.QUANTITY) AS QTY 
			FROM WSL_PICKLIST_DET A 
		    JOIN IND01106 B ON A.PICK_LIST_ID=B.PICK_LIST_ID AND A.ARTICLE_CODE=B.PICKLIST_ARTICLE_CODE
			AND A.PARA1_CODE=B.PICKLIST_PARA1_CODE AND A.PARA2_CODE=B.PICKLIST_PARA2_CODE
			JOIN INM01106 C ON B.INV_ID = C.INV_ID
			WHERE C.CANCELLED = 0 AND C.AC_CODE=@CWHERE1 AND C.INV_ID <> @CMEMOID
			GROUP BY A.ROW_ID
		)Y1 ON X.ROW_ID = Y1.PICKLIST_ROW_ID
		JOIN WSL_PICKLIST_MST Z ON X.PICK_LIST_ID = Z.PICK_LIST_ID
		JOIN BUYER_ORDER_MST BOM ON X.ORDER_ID = BOM.ORDER_ID
		JOIN ARTICLE ART ON ART.ARTICLE_CODE =X.ARTICLE_CODE
		JOIN SECTIOND SD ON SD.SUB_SECTION_CODE = ART.SUB_SECTION_CODE
		JOIN SECTIONM SM ON SM.SECTION_CODE = SD.SECTION_CODE
		JOIN PARA1 P1 ON X.PARA1_CODE = P1.PARA1_CODE
		JOIN PARA2 P2 ON X.PARA2_CODE = P2.PARA2_CODE
		JOIN PARA3 P3 ON ART.PARA3_CODE = P3.PARA3_CODE
		JOIN PARA4 P4 ON ART.PARA4_CODE = P4.PARA4_CODE
		JOIN PARA5 P5 ON ART.PARA5_CODE = P5.PARA5_CODE
		JOIN PARA6 P6 ON ART.PARA6_CODE = P6.PARA6_CODE
		WHERE Z.CANCELLED = 0 AND Z.AC_CODE = @CWHERE1
		AND X.PICK_LIST_QTY+X.ADD_QTY > ISNULL(Y1.QTY,0)
	END
END