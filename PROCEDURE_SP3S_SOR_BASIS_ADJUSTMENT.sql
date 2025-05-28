CREATE PROCEDURE SP3S_SOR_BASIS_ADJUSTMENT
(
	@NQID				NUMERIC(2), 
	@CFROMDT			DATETIME='',  
	@CTODT				DATETIME='',
	@BPending			INT=-1 ,
	@bSOR_PARTY			INT=0,
	@cWhere VARCHAR(40)='',
	@NNAVMODE	NUMERIC(1,0)=0,
	@cRefMemoNo VARCHAR(20)='',
	@cFinYear VARCHAR(5)=''
)
AS
BEGIN
	IF @nQId=1
		GOTO lblPending
	ELSE
	IF @nQId=2
		GOTO lblSorLov
	ELSE
	IF @NQID=3
		GOTO lblNAV
	ELSE IF @NQID=4
		GOTO lblMST
	ELSE IF @NQID=5
		GOTO lblDET


lblPending:
	SELECT SKU.PRODUCT_CODE,a.row_id,LM.AC_NAME
	INTO #SKU
	FROM  CMD01106  A  (NOLOCK) 
	JOIN CMM01106 CMM (NOLOCK) ON CMM.CM_ID=A.CM_ID
	JOIN SKU  (NOLOCK) ON SKU.PRODUCT_CODE=A.PRODUCT_CODE
	JOIN dtm (NOLOCK) ON dtm.dt_code=cmm.dt_code
	LEFT OUTER JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=SKU.ac_code  
	JOIN location loc (NOLOCK) ON loc.dept_id=CMM.location_Code 
	WHERE (CMM.cm_dt BETWEEN @CFROMDT AND @CTODT)
		AND CMM.CANCELLED=0 
	AND ((ISNULL(A.basic_discount_amount,0)+isnull(a.cmm_discount_amount,0))<>0   OR a.manual_discount<>0 OR a.Manual_DP<>0)
	AND ISNULL(A.slsdet_row_id,'')='' 
	and (((ISNULL(A.basic_discount_amount,0)+isnull(a.cmm_discount_amount,0))<>isnull(a.cmm_discount_amount,0)
			OR dtm.DTM_TYPE=2) OR a.manual_discount<>0 OR a.Manual_DP<>0)
	AND @BPending>=0 
	AND (@BPending<>1 OR ISNULL(A.sor_terms_code,'') in ('','000'))
	AND (@bSOR_PARTY=0 OR (@bSOR_PARTY<=2 AND ISNULL(lm.sor_party,0)=(@bSOR_PARTY-1))
	     OR (@bSOR_PARTY=3  AND loc.sor_loc=1))

	SELECT ROW_NUMBER() OVER (ORDER BY CMM.CM_DT, A.ROW_ID) AS SRNO, A.SR_NO AS SRNO,  
	'later' row_id,sn.*,CONVERT(VARCHAr(40),'') AS SP_ID,CMM.CM_NO,CMM.CM_DT,CMM.REMARKS AS CMM_REMARKS,
	(CASE WHEN ISNULL(A.sor_terms_code,'')='' THEN '000' ELSE a.sor_terms_code END) AS old_sor_terms_code,
	ISNULL(DTM.dt_name,'') AS dt_name,
	convert(varchar(40),'LATER') row_id,a.row_id cmd_row_id,convert(varchar(40),'LATER') memo_id,
	(CASE WHEN ISNULL(A.sor_terms_code,'')='' THEN '000' ELSE a.sor_terms_code END) AS new_sor_terms_code,
	isnull(e.sor_terms_name,'') old_sor_terms_name,isnull(e.sor_terms_name,'') new_sor_terms_name,
	a.cmm_discount_amount,a.discount_amount,a.discount_percentage


	FROM  CMD01106  A  (NOLOCK) 
	JOIN CMM01106 CMM (NOLOCK) ON CMM.CM_ID=A.CM_ID
	LEFT OUTER JOIN DTM (NOLOCK) ON DTM.dt_code=CMM.DT_CODE
	JOIN #SKU SKU (NOLOCK) ON SKU.row_id=a.ROW_ID
	JOIN sku_names SN (NOLOCK) ON SN.PRODUCT_CODE=A.PRODUCT_CODE  
	LEFT JOIN  sor_terms_mst e (NOLOCK) ON e.sor_terms_code=a.sor_terms_code

	ORDER BY CMM.CM_DT, A.ROW_ID
	
	GOTO LAST
lblSorLov:
	SELECT CAST('000' AS VARCHAR(5)) AS new_SOR_TERMS_CODE,'---SELECT---' AS SOR_TERMS_NAME		,'---SELECT---' AS SOR_TERMS_CODE
	UNION ALL
	SELECT SOR_TERMS_CODE as new_SOR_TERMS_CODE ,SOR_TERMS_NAME,SOR_TERMS_CODE  FROM SOR_TERMS_MST WHERE sor_terms_name<>''
	and sor_terms_code  in ('MRP','NRV','TAX')
	ORDER BY SOR_TERMS_NAME 

	GOTO LAST

lblNav:
	EXECUTE SP_NAVIGATE 'sor_basis_adjustment_mst',@NNAVMODE,@CREFMEMONO,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID','',1  
	GOTO LAST

lblMst:
	SELECT username,a.* FROM sor_basis_adjustment_mst a (NOLOCK)
	JOIN  users b (NOLOCK) ON b.user_code=a.user_code
	WHERE memo_id=@cWhere

	GOTO LAST
lblDet:
	
	SELECT a.*,c.*,D.CM_NO,D.CM_DT,e.sor_terms_name old_sor_terms_name,f.sor_terms_name new_sor_terms_name,
	ROW_NUMBER() OVER (ORDER BY d.CM_DT, A.ROW_ID) AS SRNO,ISNULL(DTM.dt_name,'') AS dt_name,
	isnull(e.sor_terms_name,'') old_sor_terms_name,isnull(e.sor_terms_name,'') new_sor_terms_name,
	b.cmm_discount_amount,b.discount_amount,b.discount_percentage,quantity,net,b.basic_discount_percentage,
	b.card_discount_percentage,b.basic_discount_amount,b.basic_discount_amount ,D.REMARKS AS cmm_remarks
	FROM sor_basis_adjustment_det a (NOLOCK)
	JOIN cmd01106 b (NOLOCK) ON b.ROW_ID=a.cmd_row_id
	JOIN CMM01106 D (NOLOCK) ON B.CM_ID= D.CM_ID
	JOIN  sku_names c (NOLOCK) ON c.product_Code=b.PRODUCT_CODE
	JOIN  sor_terms_mst e (NOLOCK) ON e.sor_terms_code=a.old_sor_terms_code
	JOIN  sor_terms_mst f (NOLOCK) ON f.sor_terms_code=a.new_sor_terms_code
	LEFT JOIN dtm (NOLOCK) ON dtm.dt_code=d.dt_code
	WHERE memo_id=@cWhere

	GOTO LAST
LAST:

END
