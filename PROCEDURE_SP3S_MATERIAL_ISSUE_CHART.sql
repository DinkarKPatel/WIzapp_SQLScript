CREATE PROCEDURE SP3S_MATERIAL_ISSUE_CHART
(
 @DASONDATE DATETIME='2019-07-18',
 @REF_NO VARCHAR(100)='',  
 @BUYER_NAME VARCHAR(100)='',  
 @CORDER_NO VARCHAR(100)='',  
 @JOBCARD_NO VARCHAR(100)='', 
 @AGENCY_NAME	VARCHAR(100)=''  
 )
AS
BEGIN

;WITH BOM_ISSUE_SUMMARY
	AS
	(
		SELECT B.ARTICLE_CODE AS FG_ARTICLE_CODE, B.MEMO_NO,B.MEMO_DT,
		 B.ISSUE_ID ,B.ISSUE_NO ,B.ISSUE_DT ,
		A.*,B.MEMO_ID AS ORD_PLAN_MEMO_ID,B.ROW_ID AS ORD_PLAN_DET_ROW_ID,
		B.ISSUED_QTY,
		CONVERT(NUMERIC(14,2),((A.AVG_QUANTITY+A.ADD_AVG_QUANTITY) * B.ISSUED_QTY)) AS REQ_QTY,
		b.REC_QTY
		FROM ORD_PLAN_BOM_DET A (NOLOCK)
		JOIN
		(
			SELECT D.MEMO_NO ,D.MEMO_DT, 
			       A1.ISSUE_ID , A.JOB_CODE,
			       A1.ISSUE_NO ,A1.ISSUE_DT ,
			       D.MEMO_ID,C.ROW_ID,C.ARTICLE_CODE,
			       C.PARA1_CODE,C.PARA2_CODE,
			SUM(A.QUANTITY) AS ISSUED_QTY,
			SUM(ISNULL(REC_QTY,0)) AS REC_QTY
			FROM JOBWORK_ISSUE_DET A (NOLOCK)
			JOIN JOBWORK_ISSUE_MST A1 (NOLOCK) ON A1.ISSUE_ID=A.ISSUE_ID
			LEFT JOIN
			(
			 select REF_ROW_ID,SUM(QUANTITY) AS REC_QTY
			 FROM jobwork_receipt_det A (NOLOCK)
			 JOIN jobwork_receipt_mst B (NOLOCK) ON A.receipt_id =B.RECEIPT_ID
			 WHERE B.cancelled =0
			 GROUP BY REF_ROW_ID
			) REC ON REC.ref_row_id =A.ROW_ID 
			JOIN ORD_PLAN_BARCODE_DET B (NOLOCK) ON B.PRODUCT_CODE=A.PRODUCT_CODE
			JOIN ORD_PLAN_DET C (NOLOCK) ON C.ROW_ID=B.REFROW_ID
			JOIN ORD_PLAN_MST D (NOLOCK) ON D.MEMO_ID=C.MEMO_ID
			WHERE D.CANCELLED=0 AND A1.cancelled=0
			and(@JOBCARD_NO='' or d.MEMO_ID  =@JOBCARD_NO)
			and (@AGENCY_NAME='' or a1.agency_code =@AGENCY_NAME)
			GROUP BY D.MEMO_NO ,D.MEMO_DT,A1.ISSUE_ID ,D.MEMO_ID,C.ROW_ID, 
			C.ARTICLE_CODE,C.PARA1_CODE,C.PARA2_CODE,A.JOB_CODE,A1.ISSUE_NO ,A1.ISSUE_DT
		)B ON B.ROW_ID=A.REF_ROW_ID and a.JOB_CODE =b.job_code 
					
	)
	
	SELECT T.MEMO_NO AS JOBCARD_NO,T.MEMO_DT AS JOBCARD_DT,
	       ARTFG.ARTICLE_NO ,FGU.UOM_NAME AS FG_UOM,
	       SUM(T.ISSUED_QTY) AS NO_OF_PCS,
	       B.ARTICLE_NO ,SD.SUB_SECTION_NAME  ,I.UOM_NAME  ,
	       ISNULL(T.AVG_QUANTITY,0)+ISNULL(T.ADD_AVG_QUANTITY,0) AS AVG_QUANTITY,
	       JOBS .JOB_NAME AS ISSUE_FOR,
	       SUM(REQ_QTY) AS REQ_QTY,
	       T.ISSUE_DT,
	       t.ISSUE_NO challan_no,
	       X.AGENCY_NAME AS VENDOR_NAME,
	       SUM(ISNULL(T.ISSUED_QTY,0)) as ISSUED_QTY,
	       SUM(ISNULL(T.REC_QTY,0)) as REC_QTY,
	       CONVERT(NUMERIC(10,2),SUM(ISNULL(T.ISSUED_QTY,0)-ISNULL(T.REC_QTY,0))) AS PENDING_QTY,
	       
	       CASE WHEN (SUM(ISNULL(X.ISSUED_QTY,0))=0 or SUM(ISNULL(T.ISSUED_QTY,0)-ISNULL(T.REC_QTY,0))=0 ) THEN 0
	       ELSE  CONVERT(NUMERIC(10,2),(SUM(ISNULL(T.ISSUED_QTY,0)-ISNULL(T.REC_QTY,0))*(ISNULL(T.AVG_QUANTITY,0)+ISNULL(T.ADD_AVG_QUANTITY,0)))) END AS PENDING_MATERIAL
	      -- CONVERT(NUMERIC(10,2),SUM(REQ_QTY)-SUM(ISNULL(X.ISSUED_QTY,0))) AS BALANCE
	FROM BOM_ISSUE_SUMMARY T
	JOIN ARTICLE B (NOLOCK) ON T.ARTICLE_CODE = B.ARTICLE_CODE  
	JOIN SECTIOND SD (NOLOCK) ON SD.sub_section_code =B.sub_section_code       
	JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE=T.JOB_CODE       
	JOIN UOM I (NOLOCK) ON B.UOM_CODE = I.UOM_CODE        
	LEFT OUTER JOIN UOM_CONVERSION UC (NOLOCK) ON UC.UOM_CODE=I.UOM_CODE
    LEFT OUTER JOIN BOM_UOM BU (NOLOCK) ON BU.CONVERSION_UOM_CODE=UC.CONVERSION_UOM_CODE
    JOIN ARTICLE ARTFG ON ARTFG .ARTICLE_CODE =T.FG_ARTICLE_CODE 
    JOIN UOM FGU (NOLOCK) ON ARTFG.UOM_CODE = FGU.UOM_CODE 
    LEFT OUTER JOIN
	(
		SELECT A5.ISSUE_DT,A5.ISSUE_NO ,AM.AGENCY_NAME, 
		    A1.MEMO_ID, A1.REF_ROW_ID,A1.ARTICLE_CODE,A1.PARA1_CODE,A1.PARA2_CODE,
		SUM(A6.QUANTITY) AS ISSUED_QTY
		FROM BOM_ISSUE_DET A4 (NOLOCK) 
		JOIN BOM_ISSUE_MST A5  (NOLOCK) ON A5.ISSUE_ID=A4.ISSUE_ID
		JOIN BOM_ISSUE_REF A6  (NOLOCK) ON A5.ISSUE_ID=A6.BOM_ISSUE_ID AND A4.ROW_ID=A6.BOM_DET_ROW_ID
		JOIN ORD_PLAN_BOM_DET A1  (NOLOCK) ON A1.ROW_ID=A6.ORD_PLAN_BOM_DET_ROW_ID
		JOIN PRD_AGENCY_MST AM ON AM.AGENCY_CODE =A5.AGENCY_CODE 
		WHERE A5.CANCELLED=0 --AND A1.MEMO_ID='AK0111900000AK00000061'
		GROUP BY A5.ISSUE_DT,A5.ISSUE_NO,AM.AGENCY_NAME ,A1.MEMO_ID,  
		A1.REF_ROW_ID,A1.ARTICLE_CODE,A1.PARA1_CODE,A1.PARA2_CODE--,A6.ORD_PLAN_BOM_DET_ROW_ID
	)X ON X.REF_ROW_ID=T.ORD_PLAN_DET_ROW_ID	AND X.MEMO_ID=T.ORD_PLAN_MEMO_ID
	AND X.ARTICLE_CODE=T.ARTICLE_CODE AND X.PARA1_CODE=T.PARA1_CODE AND X.PARA2_CODE=T.PARA2_CODE      
	GROUP BY T.MEMO_NO ,T.MEMO_DT ,ARTFG.ARTICLE_NO,FGU.UOM_NAME  ,B.ARTICLE_NO ,SD.SUB_SECTION_NAME,I.UOM_NAME ,
	ISNULL(T.AVG_QUANTITY,0)+ISNULL(T.ADD_AVG_QUANTITY,0),JOBS .JOB_NAME,
	t.ISSUE_DT,t.ISSUE_NO ,X.AGENCY_NAME

	
	
END