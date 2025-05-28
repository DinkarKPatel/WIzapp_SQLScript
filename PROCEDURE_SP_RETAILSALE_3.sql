CREATE PROCEDURE SP_RETAILSALE_3
(  
	 @CQUERYID			NUMERIC(2),  
	 @CWHERE			VARCHAR(MAX)='',
	 @CFINYEAR			VARCHAR(5)='',  
	 @CDEPTID			VARCHAR(4)='',  
	 @NNAVMODE			NUMERIC(2)=1,  
	 @CWIZAPPUSERCODE	VARCHAR(10)='',  
	 @CREFMEMOID		VARCHAR(40)='',  
	 @CREFMEMODT		DATETIME='',  
	 @BINCLUDEESTIMATE	BIT=1,  
	 @CFROMDT			DATETIME='',  
	 @CTODT				VARCHAR(50)='',
	 @bCardDiscount		BIT=0,
	 @cCustCode			VARCHAR(15)=''
) 
AS  
BEGIN  

	DECLARE @bAllowPatchedView BIT
	SELECT @bAllowPatchedView =VALUE FROM USER_ROLE_DET A (NOLOCK)--ADDED
				JOIN USERS B (NOLOCK)--ADDED
				ON A.ROLE_ID=B.ROLE_ID 
				WHERE USER_CODE=@CWIZAPPUSERCODE 
				AND FORM_NAME='FRMSALE' 
				AND FORM_OPTION='ALLOW_VIEW_PATCH_DATA'		

	IF OBJECT_ID('TEMPDB..#TMPCMM_PATCH','U') IS NOT NULL
		DROP TABLE #TMPCMM_PATCH
	SELECT CM_ID,subtotal ,subtotal_r,DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT,NET_AMOUNT,round_off 
	INTO #TMPCMM_PATCH FROM CMM01106 WHERE 1=2

	INSERT INTO #TMPCMM_PATCH(CM_ID,subtotal ,subtotal_r,DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT,NET_AMOUNT,round_off )
	SELECT A.CM_ID,subtotal ,subtotal_r,DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT,NET_AMOUNT,round_off 
	FROM CMM01106 A
	WHERE (ISNULL(A.patchup_run,0)=0 OR (ISNULL(A.patchup_run,0)=1 AND ISNULL(@bAllowPatchedView,0)=1)) AND cm_id=@CWHERE 

	INSERT INTO #TMPCMM_PATCH(CM_ID,subtotal ,subtotal_r,DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT,NET_AMOUNT,round_off )
	SELECT A.CM_ID,ISNULL(A.old_subtotal ,0),ISNULL(A.old_subtotal_r,0),ISNULL(A.old_DISCOUNT_PERCENTAGE,0),ISNULL(A.old_DISCOUNT_AMOUNT,0),ISNULL(A.old_NET_AMOUNT,0),ISNULL(A.old_round_off ,0)
	FROM CMM01106 A
	WHERE ISNULL(patchup_run,0)=1 AND ISNULL(@bAllowPatchedView,0)=0  AND cm_id=@CWHERE 

	DECLARE @bPaid	BIT
	SET @bPaid=0
	IF EXISTS (SELECT TOP 1 A.CM_ID 
				FROM cmm01106 a (NOLOCK)
				JOIN DSD01106 B (NOLOCK) ON b.cm_id=a.cm_id
				JOIN dsm01106 C (NOLOCK) ON C.ds_id=B.ds_id
				WHERE a.cancelled=0 AND C.cancelled=0 
				AND A.cm_id=@cWhere)
	SET @bPaid=1  
	
  SELECT  C2.subtotal ,C2.subtotal_r,C2.DISCOUNT_PERCENTAGE,C2.DISCOUNT_AMOUNT,C2.NET_AMOUNT,C2.round_off, ISNULL(LOC.Enable_EInvoice,0) AS Enable_EInvoice,
  A.*, B.*, '' AS CUSTOMER_NAME, '' AS CREDIT_CARD_NAME , C.USERNAME, '' AS ADDRESS,  
  ISNULL(ST.STATE,'') AS [STATE],ISNULL(AR.AREA_NAME,'') AS  AREA,  
    ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE,  
    CAST((CASE WHEN ISNULL(CMR.CM_ID,'')<>'' THEN 1 ELSE 0 END) AS BIT) AS CREDIT_REFUND,  
    '' AS HOLD_ID,'' AS LOGIN_ID,'' AS SESSION_ID  
    ,CAST((ISNULL(gst,0)+isnull(tax,0)) AS NUMERIC(14,2)) as [TOTAL_TAX]  ,CAST(ISNULL(gst,0) AS NUMERIC(14,2)) as [TOTAL_gst]  ,ISNULL(D.username,'') as [EDT_USERNAME],
   ISNULL(X.emp_code,'0000000') AS [emp_code],ISNULL(x.emp_code1,'0000000')  AS [emp_code1],
   ISNULL(x.emp_code2,'0000000') as [emp_code2],ISNULL(x.emp_name,'') AS [emp_name],
   ISNULL(x.emp_name1,'') AS [emp_name1],ISNULL(x.emp_name2,'') AS [emp_name2],dtm.dt_name,
   b1.AC_NAME,ISNULL(BIN.BIN_NAME,'') AS [BIN_NAME],
   CONVERT(NUMERIC(14,2),ISNULL(C2.subtotal,0) +ISNULL(C2.subtotal_r,0)) as [SUBTOTAL_T],
   --CONVERT(NUMERIC(14,3),(CASE WHEN (a.subtotal+a.subtotal_r)<>0 THEN (a.discount_amount*100)/ (a.subtotal+a.subtotal_r) ELSE 0 END)) as [DISCOUNT_PERCENTAGE_CALC],
   C2.DISCOUNT_PERCENTAGE as [DISCOUNT_PERCENTAGE_CALC],
   '' AS [DELAY],
   CONVERT(NUMERIC(14,2),0) AS CASH_AMOUNT, CONVERT(NUMERIC(14,2),0)  AS CC_AMOUNT, CONVERT(NUMERIC(14,2),0)  AS CREDIT_AMOUNT, 
   CONVERT(NUMERIC(14,2),0)  AS CN_AMOUNT,	CONVERT(NUMERIC(14,2),0)  AS [OTHER_AMOUNT],
	@bPaid AS [Paid],gst.gst_state_name AS PARTY_STATE_NAME,CAST('' AS varchar(40)) AS SP_ID
	, ISNULL(B.cus_gst_no,'')+ISNULL(LMP.Ac_gst_no,'') AS [PARTY_GST_NO],CAST('' AS VARCHAR(40)) AS manual_scheme_setup_memo_no,ISNULL(D11.USERNAME,'') AS validation_bypassed_user_name
	,'' AS OLD_ECOUPON_ID
		
  FROM CMM01106 A  (NOLOCK)  
  JOIN #TMPCMM_PATCH C2 ON C2.cm_id=A.cm_id
  JOIN CUSTDYM B  (NOLOCK) ON B.CUSTOMER_CODE=A.CUSTOMER_CODE   
  JOIN LOCATION LOC  (NOLOCK) ON LOC.dept_id=A.LOCATION_CODE
  JOIN lm01106 b1  (NOLOCK) ON b1.ac_code=a.ac_code 
  LEFT OUTER JOIN LMP01106 LMP  (NOLOCK) ON B1.AC_CODE=LMP.AC_CODE     
  LEFT OUTER JOIN DTM  (NOLOCK) ON DTM.dt_code=A.DT_CODE
  LEFT OUTER JOIN BIN  (NOLOCK) ON BIN.BIN_ID=ISNULL(A.BIN_ID,'000')  
  LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=B.AREA_CODE  
  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE  
  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE  
  LEFT OUTER JOIN gst_state_mst gst on A.party_state_code=gst.gst_state_code
  LEFT OUTER JOIN CMR01106 CMR  (NOLOCK) ON CMR.CM_ID=A.CM_ID    
  JOIN USERS C  (NOLOCK) ON C.USER_CODE=A.USER_CODE  
  LEFT OUTER JOIN USERS D  (NOLOCK) ON D.USER_CODE=A.edt_user_code
  LEFT OUTER JOIN USERS D11  (NOLOCK) ON D11.USER_CODE=A.validation_bypassed_user_code
  LEFT OUTER JOIN
  (
	SELECT SUM(TAX_AMOUNT) as [TAX] ,SUM(isnull(igst_amount,0)+isnull(cgst_amount,0)+isnull(sgst_amount,0)) as [GST] ,cm_id	FROM cmd01106 a (NOLOCK)
	WHERE tax_method=2 AND cm_id=@CWHERE 
	GROUP BY cm_id
  )x1 ON X1.cm_id=a.cm_id  
  LEFT OUTER JOIN
  (
	SELECT TOP 1 cm_id,e1.emp_code,e2.emp_code  AS [emp_code1],e3.emp_code as [emp_code2],e1.emp_name AS [emp_name]
	,e2.emp_name AS [emp_name1],e3.emp_name AS [emp_name2]
	FROM cmd01106 a (NOLOCK)
	JOIN employee e1 (NOLOCK) ON e1.emp_code=a.emp_code
	JOIN employee e2 (NOLOCK) ON e2.emp_code=a.emp_code1
	JOIN employee e3 (NOLOCK) ON e3.emp_code=a.emp_code2
	WHERE a.cm_id=@CWHERE AND (a.emp_code<>'0000000' OR a.emp_code2<>'0000000' OR a.emp_code2<>'0000000')
  )x ON X.cm_id=a.cm_id
  WHERE  A.CM_ID=@CWHERE  

end
