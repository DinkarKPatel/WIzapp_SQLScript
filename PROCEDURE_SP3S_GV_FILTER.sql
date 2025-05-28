CREATE PROCEDURE SP3S_GV_FILTER
(
	@DFROM_DT DATETIME
	,@DTO_DT DATETIME
	,@Collection VARCHAR(100)=''
	,@CANCELLED NUMERIC(1)=2--0 FOR UN-CANCELLED 1 FOR CANCELLED 2 FOR ALL
	,@LOC VARCHAR(5)=''
	,@nMode NUMERIC(1)=0
	,@nValidationSource NUMERIC(1)=0
	,@nStatus NUMERIC(1)=0
)
AS
BEGIN
	DECLARE @cHO_ID VARCHAR(5)
	
	SELECT @cHO_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'
	
	;WITH MST_MODE
	AS
	(
		SELECT 1 AS MODE,'Sellable' MODE_NAME
		UNION
		SELECT 2 AS MODE,'Freebies' MODE_NAME
	)
	,MST_VALIDATION_SOURCE
	AS
	(
		SELECT 1 AS VALIDATION_SOURCE,'Through HO' VALIDATION_SOURCE_NAME
		UNION
		SELECT 2 AS VALIDATION_SOURCE,'Through WizClip' VALIDATION_SOURCE_NAME
	)
	,MST
	AS
	(
		SELECT a.memo_no,CONVERT(VARCHAR(20),a.memo_dt,105) AS MEMO_DT,a.memo_id,a1.MODE_NAME mode,a.user_code,cancelled=(CASE a.cancelled WHEN 1 THEN 'Yes' ELSE 'No' END),
		a.validity_days,a.remarks,validate_with_eoss=(CASE a.validate_with_eoss WHEN 1 THEN 'Yes' ELSE 'No' END),
		a2.VALIDATION_SOURCE_NAME validation_source,allow_partial_redemption=(CASE a.allow_partial_redemption WHEN 1 THEN 'Yes' ELSE 'No' END),a.GV_COLLECTION_NAME,
		b.username ,c.scheme_name  ,A.location_code
		FROM GV_GEN_MST A (NOLOCK)
		JOIN USERS B (NOLOCK) ON B.USER_CODE=A.USER_CODE
		JOIN MST_MODE A1 ON A1.MODE=A.mode
		JOIN MST_VALIDATION_SOURCE A2 ON A2.validation_source =A.validation_source
		left outer join scheme_setup_det c (nolock) on A.scheme_id = c.row_id 
		WHERE (A.memo_dt BETWEEN @DFROM_DT AND @DTO_DT)
		AND (@CANCELLED=2 OR A.CANCELLED=@CANCELLED) 
		AND (@Collection='' OR A.memo_id=@Collection) 
		--AND (@LOC='' OR left(A.memo_id,2)=@LOC) 
		AND (@nMode=0 OR A.mode=@nMode)
		AND (@nValidationSource=0 OR A.validation_source=@nValidationSource)
	)
	,ARC
	AS
	(
		SELECT B.ADV_REC_NO AS GV_SOLD_MEMO_NO,CONVERT(VARCHAR(20),B.ADV_REC_DT ,105) AS GV_SOLD_MEMO_DT,B.REMARKS,
		/*,QUANTITYB.AMOUNT,B.DISCOUNT_AMOUNT,B.NET_AMOUNT,B.DISCOUNT_PERCENTAGE,*/
		A.ADV_REC_ID,GV_SRNO AS SOLD_GV_SRNO,DENOMINATION AS GV_SOLD_AMOUNT,B.location_Code AS GV_DEPT_ID,C.dept_alias AS ARC_DEPT_ALIAS
		FROM ARC_GVSALE_DETAILS A (NOLOCK)
		JOIN ARC01106 B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
		LEFT OUTER JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=B.location_Code
		WHERE B.CANCELLED=0 AND B.ARCT=4
	)
	,DET
	AS
	(
		SELECT A.memo_id,ISNULL(B.gv_srno, A.gv_srno) AS gv_srno,ISNULL(B.gv_scratch_no,A.gv_scratch_no) AS gv_scratch_no,
		A.denomination,A.discount_amount,A.quantity,c.Dept_id AS redeemed_at_dept_id,CONVERT(VARCHAR(20),D.CM_DT,105) AS redeemed_on,B.memo_id AS redemption_cm_id,
		B.AMOUNT AS gv_amount,
		D.cm_no,c.dept_id+'-'+C.DEPT_NAME AS DEPT_NAME
		,(CASE WHEN B.gv_srno IS NULL AND ARC.SOLD_GV_SRNO IS NULL THEN 'NOT ISSUED' WHEN B.gv_srno IS NULL  AND ARC.SOLD_GV_SRNO IS NOT NULL THEN 'ISSUED/SOLD'  WHEN B.gv_srno IS NOT NULL THEN 'REDEEMED' ELSE 'OPEN' END) AS GV_STATUS
		,ARC.*,C.dept_alias AS redeemed_at_dept_alias
		FROM GV_GEN_DET A (NOLOCK)
		JOIN MST ON MST.memo_id=A.memo_id
		LEFT OUTER JOIN paymode_xn_det B (NOLOCK) ON B.GV_SRNO=A.GV_SRNO AND B.xn_type='SLS'
		LEFT OUTER JOIN CMM01106 D (NOLOCK) ON D.cm_id=B.memo_ID
		LEFT OUTER JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=D.location_Code
		LEFT OUTER JOIN ARC ON ARC.SOLD_GV_SRNO=A.gv_srno
		WHERE (@nStatus IN (0,4) OR (@nStatus=1 AND B.gv_srno IS NULL AND ARC.SOLD_GV_SRNO IS NULL) OR (@nStatus=2 AND B.gv_srno IS NULL  AND ARC.SOLD_GV_SRNO IS NOT NULL)  OR (@nStatus=3 AND B.gv_srno IS NOT NULL))
		--A.gv_srno='GVDM20115'
	)
	,GV_AT
	AS
	(
		SELECT ISNULL(Z.dept_id,M.location_code) AS DEPT_ID,D.gv_srno ,ISNULL(Z.memo_id,M.memo_id) AS MEMO_ID,ISNULL(Z.memo_dt,M.memo_dt) as MEMO_DT,
		ISNULL(Z.GV_AT_DEPT_ALIAS,LOC.dept_alias) AS GV_AT_DEPT_ALIAS
		from DET D
		JOIN MST M ON M.memo_id=D.memo_id
		JOIN LOCATION LOC (NOLOCK) ON LOC.dept_id=LEFT(M.memo_id,2)
		LEFT OUTER JOIN
		(
			SELECT * FROM
			(
			select ROW_NUMBER() OVER (PARTITION BY a.gv_srno ORDER BY a.gv_srno,memo_dt desc,a.last_update desc) AS SRNO,B.target_dept_id AS DEPT_ID,a.gv_srno ,
			a.memo_id,b.memo_dt,LOC.dept_alias AS GV_AT_DEPT_ALIAS
			from GV_STKXFER_DET a (NOLOCK)
			JOIN GV_STKXFER_MST b (NOLOCK) ON b.memo_id=a.memo_id
			JOIN pmt_gv_mst c ON C.gv_srno=a.gv_srno
			JOIN DET D ON D.gv_srno=A.gv_srno
			JOIN LOCATION LOC (NOLOCK) ON LOC.dept_id=b.target_dept_id
			WHERE b.cancelled=0 
		
			--AND c.quantity_in_stock=0
			--AND isnull(b.receipt_dt,'')<>''
			--AND A.gv_srno='GVDM20115'
		
			)X 
			WHERE X.SRNO=1
		)Z ON Z.gv_srno=D.gv_srno
	)
	,GV_GIT
	AS
	(
		SELECT * FROM
		(
		select ROW_NUMBER() OVER (PARTITION BY a.gv_srno ORDER BY a.gv_srno,memo_dt desc) AS SRNO,B.target_dept_id AS DEPT_ID,a.gv_srno ,a.memo_id,b.memo_dt
		,'CHALLAN OUT FOR '+B.target_dept_id AS GV_STATUS
		from GV_STKXFER_DET a (NOLOCK)
		JOIN GV_STKXFER_MST b (NOLOCK) ON b.memo_id=a.memo_id
		JOIN pmt_gv_mst c ON C.gv_srno=a.gv_srno
		JOIN DET D ON D.gv_srno=A.gv_srno
		WHERE b.cancelled=0 AND isnull(b.receipt_dt,'')=''
		AND (@nStatus=0 OR @nStatus=4)
		--AND A.gv_srno='GVDM20115'
		)X 
		WHERE X.SRNO=1
	)
	SELECT MST.* ,DET.gv_srno,DET.gv_scratch_no,DET.denomination,DET.discount_amount,DET.quantity,
		DET.redeemed_at_dept_id,DET.redeemed_on,DET.redemption_cm_id,DET.gv_amount,
		DET.cm_no AS REDEMPTION_CM_NO,DET.DEPT_NAME,ISNULL(GV_GIT.GV_STATUS,DET.GV_STATUS) AS GV_STATUS,DET.GV_SOLD_AMOUNT,DET.GV_SOLD_MEMO_NO,
		DET.GV_SOLD_MEMO_DT,
		ISNULL(GV_AT.DEPT_ID ,DET.GV_DEPT_ID)  AS GV_DEPT_ID ,
		 ISNULL(GV_AT.GV_AT_DEPT_ALIAS,DET.ARC_DEPT_ALIAS) AS GV_DEPT_ALIAS
		 ,DET.redeemed_at_dept_alias
	FROM MST
	JOIN DET ON DET.memo_id=MST.memo_id
	LEFT OUTER JOIN GV_AT ON GV_AT.gv_srno=DET.gv_srno --AND GV_AT.SRNO=1
	LEFT OUTER JOIN GV_GIT ON GV_GIT.gv_srno=DET.gv_srno --AND GV_GIT.SRNO=1
	

	--WHERE @nStatus<>4 OR (@nStatus=4 AND GV_GIT.gv_srno IS NOT  NULL)
	ORDER BY MST.memo_dt,MST.memo_id,  DET.GV_SRNO
END

/*
;WITH GV_AT
AS
(
	select ROW_NUMBER() OVER (PARTITION BY a.gv_srno ORDER BY a.gv_srno,memo_dt) AS SRNO,LEFT(A.memo_id,2) AS DEPT_ID,a.gv_srno ,a.memo_id,b.memo_dt
	from GV_STKXFER_DET a
	JOIN GV_STKXFER_MST b ON b.memo_id=a.memo_id
	JOIN pmt_gv_mst c ON C.gv_srno=a.gv_srno
	WHERE b.cancelled=0 AND c.quantity_in_stock=0
)
SELECT * FROM GV_AT
ORDER BY gv_srno--,srno
*/