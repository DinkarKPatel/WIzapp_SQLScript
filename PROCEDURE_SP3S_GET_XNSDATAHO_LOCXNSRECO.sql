CREATE PROCEDURE SP3S_GET_XNSDATAHO_LOCXNSRECO
@NMODE NUMERIC(1,0)
AS
BEGIN
	 DECLARE @cCmd NVARCHAR(MAX) 
	 
	 IF @NMODE=1 ---- Compare Year wise Data
	 BEGIN
		 SET @CCMD=N'SELECT dept_id,xn_year,xn_type,SUM(XN_QTY) AS XN_QTY,SUM(xn_amount) AS xn_amount
		 
		 FROM 
		 ( 
		 SELECT a.dept_id,''OPS'' AS xn_type,
		 YEAR(A.xn_dt) as xn_year,  
		 SUM(A.QUANTITY_OB) AS XN_QTY,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM OPS01106 A WITH (NOLOCK)  
		 JOIN PR_YEAR_DATA_POS c (NOLOCK) ON A.DEPT_ID=c.DEPT_ID AND YEAR(A.XN_DT)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON A.DEPT_ID=pr_upto.DEPT_ID 
		 WHERE c.xn_type=''OPS''
		 GROUP BY a.dept_id,YEAR(A.xn_dt)
		 
		 UNION ALL  
		 SELECT b.location_code AS dept_id,''PRDXFR'' AS xn_type, 
		 YEAR(b.memo_dt) as xn_year,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM PRD_STK_TRANSFER_DTM_DET  A WITH (NOLOCK)    
		 JOIN PRD_STK_TRANSFER_DTM_MST B WITH (NOLOCK)   ON A.MEMO_ID = B.MEMO_ID   
		 JOIN PR_YEAR_DATA_POS c (NOLOCK) ON c.DEPT_ID=B.DEPT_ID AND YEAR(b.memo_DT)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON B.DEPT_ID=pr_upto.DEPT_ID
		 WHERE c.xn_type=''prdxfr'' AND B.CANCELLED=0  AND b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt)
		 
		 -- INTER BIN CHALLAN (OUT)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCO'' AS xn_type,
		 YEAR(b.memo_dt) as xn_year,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN PR_YEAR_DATA_POS c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.memo_dt)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE c.xn_type=''DCO'' AND B.CANCELLED=0   AND b.memo_dt<=pr_upto.upto_dt AND b.cancelled=0 
		 GROUP BY b.location_Code,YEAR(b.memo_dt)
		   
		 -- INTER BIN CHALLAN (IN)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCI'' AS xn_type,
		   YEAR(b.memo_dt),   
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN PR_YEAR_DATA_POS c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.memo_dt)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE c.xn_type=''DCI'' AND ISNULL(B.RECEIPT_DT,'''')<>''''  AND b.receipt_dt<=pr_upto.upto_dt
		 AND b.cancelled=0
		 GROUP BY b.location_Code,YEAR(b.memo_dt)
		       
		 -- PURCHASE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END)  AS xn_type,  
		 YEAR(b.receipt_dt), 
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM PID01106 A (NOLOCK)  
		 JOIN PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID  
		 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year FROM PR_YEAR_DATA_POS c (NOLOCK) WHERE  c.xn_type IN (''PUR'',''CHI'') 
		 ) c ON c.DEPT_ID=b.dept_id AND YEAR(b.receipt_DT)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON B.DEPT_ID=pr_upto.DEPT_ID
		 WHERE pim_ref.mrr_id IS NULL
		 AND b.cancelled=0 AND b.pim_mode<>6  AND b.receipt_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.receipt_dt),(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END) 
		 	 
		 
		 -- PURCHASE RETURN  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) AS xn_type,YEAR(b.rm_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RMD01106 A (NOLOCK)  
		 JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year FROM PR_YEAR_DATA_POS c (NOLOCK) WHERE c.xn_type IN (''PRT'',''CHO'')
		 ) c  ON c.DEPT_ID=b.location_Code AND YEAR(b.rm_DT)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE b.cancelled=0  AND B.DN_TYPE IN (0,1)  AND b.rm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.rm_dt),(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) 
		 
		 ---DEBIT NOTE PACK SLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DNPI'' AS xn_type,
		 YEAR(b.ps_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM DNPS_DET A (NOLOCK)
		 JOIN DNPS_MST B (NOLOCK) ON A.ps_id = B.ps_id
		 JOIN PR_YEAR_DATA_POS c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.ps_DT)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE c.xn_type=''DNPI'' AND b.cancelled=0  AND b.ps_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.ps_dt)	 	 
		 
		 UNION ALL
		 SELECT b.location_Code AS dept_id,''DNPR'' AS xn_type,YEAR(b.rm_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM rmd01106 A (NOLOCK)
		 JOIN rmm01106 B (NOLOCK) ON A.rm_id = B.rm_id
		 JOIN PR_YEAR_DATA_POS c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.rm_DT)=c.XN_YEAR
		 JOIN dnps_mst d (NOLOCK) ON d.ps_ID = a.ps_ID 
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE c.xn_type=''DNPR'' AND B.CANCELLED = 0 AND d.cancelled=0  AND b.rm_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.rm_dt)
		 	 
		 ---RETAIL SALE   
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END) AS xn_type,
		 YEAR(b.cm_dt),
		 SUM(ABS(A.QUANTITY)) as xn_qty,SUM(ABS(rfnet)) AS xn_amount
		 FROM CMD01106 A (NOLOCK)  
		 JOIN CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year FROM PR_YEAR_DATA_POS c (NOLOCK) WHERE c.xn_type IN (''SLS'',''SLR'')
		 ) c ON c.DEPT_ID=b.location_Code AND YEAR(b.cm_DT)=c.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE b.cancelled=0  AND b.cm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.cm_dt),(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END)
		 	 
		  -- RETAIL SALE -PACKING SLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''RPS'' AS xn_type, 
		 YEAR(b.cm_dt),
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RPS_DET A (NOLOCK)  
		 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.cm_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type=''RPS'' AND b.cancelled=0  
		 AND ISNULL(B.REF_CM_ID,'''')=''''  AND b.cm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.cm_dt)
		 
		 -- APPROVAL ISSUE  
		  UNION ALL  
		 SELECT b.location_Code AS dept_id, ''APP'' AS xn_type,YEAR(b.memo_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APD01106 A   
		 JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type=''APP'' AND b.cancelled=0  AND b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt)	 
		 
		 -- APPROVAL RETURN  
		 UNION ALL  
		 SELECT c.location_Code AS dept_id,''APR'' AS xn_type,YEAR(c.memo_dt),
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APPROVAL_RETURN_DET A   
		 JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
		 JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=c.location_Code AND YEAR(c.memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON c.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type=''APR'' AND c.cancelled=0  AND c.memo_dt<=pr_upto.upto_dt
		 GROUP BY c.location_Code,YEAR(c.memo_dt)	 	 

		-- CANCELLATION/UNCANCELLATION
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END) AS xn_type,YEAR(b.cnc_memo_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ICD01106 A WITH (NOLOCK)    
		 JOIN ICM01106 B WITH (NOLOCK)   ON B.CNC_MEMO_ID = A.CNC_MEMO_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year FROM PR_YEAR_DATA_POS c (NOLOCK) WHERE c.xn_type IN (''CNC'',''UNC'')
		 ) d ON d.DEPT_ID=b.location_Code AND YEAR(b.cnc_memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE b.cancelled=0  AND STOCK_ADJ_NOTE=0  AND b.cnc_memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END),YEAR(b.cnc_memo_dt)
		 	   
		 --WHOLESALE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END)  AS xn_type,YEAR(b.inv_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IND01106 A (NOLOCK)  
		 JOIN INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year FROM PR_YEAR_DATA_POS c (NOLOCK) WHERE c.xn_type IN (''WSL'',''CHO'')
		 ) d ON d.DEPT_ID=b.location_Code AND YEAR(b.inv_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE b.cancelled=0   AND b.inv_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.inv_dt),(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END) 
		 	 
		 --WHOLESALE PACKSLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPI'' AS xn_type,YEAR(b.ps_dt),
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM wps_det A (NOLOCK)  
		 JOIN wps_mst B (NOLOCK) ON A.ps_id = B.ps_id  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.ps_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''WPI'') AND b.cancelled=0  AND b.ps_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.ps_dt)

		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPR'' AS xn_type,YEAR(b.inv_dt),
		 SUM(a.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ind01106 A (NOLOCK)  
		 JOIN inm01106 B (NOLOCK) ON A.inv_id = B.inv_id  
		 JOIN wps_mst c (NOLOCK) ON c.ps_id=a.ps_id
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.inv_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''WPR'') AND b.cancelled=0 AND c.cancelled=0  AND b.inv_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.inv_dt)
		 	 
		 --WHOLESALE CREDIT NOTE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END)  AS xn_type,
		 (CASE WHEN mode=2 THEN  YEAR(b.receipt_dt) else  YEAR(b.cn_dt) end) ,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM CND01106 A (NOLOCK)  
		 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year FROM PR_YEAR_DATA_POS c (NOLOCK) WHERE c.xn_type IN (''WSR'',''CHI'')
		 ) d   ON d.DEPT_ID=b.billed_from_dept_id AND YEAR(b.cn_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE b.cancelled=0 AND B.CN_TYPE<>2 AND ((mode=2 AND b.receipt_dt<=pr_upto.upto_dt and b.receipt_Dt<>'''') OR (mode=1 AND b.cn_dt<=pr_upto.upto_dt))
		 GROUP BY b.location_Code,(CASE WHEN mode=2 THEN  YEAR(b.receipt_dt) else  YEAR(b.cn_dt) end),(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END) 

		 -- GENERATION OF NEW BAR CODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,YEAR(b.irm_memo_dt),
		  ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.irm_memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''PFI'') AND b.irm_memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.irm_memo_dt)
		  
		 -- GENERATION OF NEW BAR CODES IN SPLIT COMBINE
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,YEAR(b.memo_dt),
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCF01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''PFI'') AND b.cancelled=0  AND A.PRODUCT_CODE<>''''  AND b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt)
		  
		 -- CONSUMPTION OF OLD BARCODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''CIP'' AS xn_type,YEAR(b.irm_memo_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount 
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.irm_memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''CIP'')  AND A.new_PRODUCT_CODE<>''''  AND b.irm_memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.irm_memo_dt)
		  
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,YEAR(b.memo_dt),
		 ABS(SUM(A.QUANTITY+ADJ_QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCC01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0  AND A.PRODUCT_CODE<>'''' AND b.memo_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.memo_dt)
		 
		 -- JOB WORK ISSUE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWI'' AS xn_type,YEAR(b.issue_dt),  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM JOBWORK_ISSUE_DET A (NOLOCK)  
		 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.issue_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''JWI'') AND b.cancelled=0 AND b.issue_type=1 AND b.issue_dt<=pr_upto.upto_dt
		 AND ISNULL(B.WIP,0)=0
		 GROUP BY b.location_Code,YEAR(b.issue_dt)
		   
		 -- JOB WORK RECEIPT  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWR'' AS xn_type,YEAR(b.receipt_dt),
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
		 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
		 JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=A.PRODUCT_CODE  
		 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
		 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  
		 JOIN PR_YEAR_DATA_POS f (NOLOCK) ON f.DEPT_ID=b.location_Code AND YEAR(b.receipt_DT)=f.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE f.xn_type IN (''JWR'') AND b.cancelled=0  AND  E.ISSUE_TYPE=1 AND b.receipt_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.receipt_dt)
		 	 
		 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)	  
		 UNION ALL 
		 SELECT b.location_Code AS dept_id,''SCF'' AS xn_type,YEAR(b.receipt_dt),
		 SUM((CASE WHEN b2.barcode_coding_scheme=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN
		 (
			SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,sku.barcode_coding_scheme,COUNT(*) AS [TOTAL_QTY]
			FROM SNC_BARCODE_DET a (NOLOCK)
			JOIN sku (NOLOCK) ON sku.product_code=a.product_code
			GROUP BY REFROW_ID,a.PRODUCT_CODE,sku.barcode_coding_scheme
		 )B2 ON A.ROW_ID = B2.ROW_ID
		 JOIN ARTICLE A1 ON A1.ARTICLE_CODE=A.ARTICLE_CODE
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.receipt_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''SCF'') AND b.cancelled=0  AND B2.PRODUCT_CODE<>'''' AND b.receipt_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.receipt_dt)
		 
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)  
		UNION ALL   
		SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,YEAR(b.receipt_dt),
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.receipt_DT)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND b.receipt_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.receipt_dt)

		 -- GRN PACKSLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''GRNPS'' AS xn_type,YEAR(b.memo_dt),
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM GRN_PS_DET A (NOLOCK)  
		 JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN PR_YEAR_DATA_POS d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_dt)=d.XN_YEAR
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''GRNPS'') AND b.cancelled=0 AND b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt)
		) a
		GROUP BY dept_id,xn_year,xn_type'
	END
		
	ELSE
	IF @NMODE=2  ---- Compare Month wise Data
	BEGIN
		 SET @CCMD=N'SELECT dept_id,xn_month,xn_year,xn_type,SUM(XN_QTY) as xn_qty,SUM(xn_amount) AS xn_amount
	 
		 FROM 
		 ( 
		 SELECT a.dept_id,''OPS'' AS xn_type,
		 YEAR(A.xn_dt) as xn_year,
		 MONTH(A.xn_dt) as xn_month,  
		 SUM(A.QUANTITY_OB) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM OPS01106 A WITH (NOLOCK)  
		 JOIN pr_month_data_pos c (NOLOCK) ON A.DEPT_ID=c.DEPT_ID AND YEAR(A.XN_DT)=c.XN_YEAR AND MONTH(a.xn_Dt)=c.xn_month
		 
		 WHERE c.xn_type=''OPS''
		 GROUP BY a.dept_id,YEAR(A.xn_dt),MONTH(a.xn_dt)
		 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''PRDXFR'' AS xn_type, 
		 YEAR(b.memo_dt) as xn_year,  
		 MONTH(b.memo_dt) as xn_month,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM PRD_STK_TRANSFER_DTM_DET  A WITH (NOLOCK)    
		 JOIN PRD_STK_TRANSFER_DTM_MST B WITH (NOLOCK)   ON A.MEMO_ID = B.MEMO_ID   
		 JOIN pr_month_data_pos c (NOLOCK) ON c.DEPT_ID=B.DEPT_ID AND YEAR(b.memo_DT)=c.XN_YEAR AND MONTH(b.memo_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE c.xn_type=''prdxfr'' AND B.CANCELLED=0   AND b.memo_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)
		 
		 -- INTER BIN CHALLAN (OUT)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCO'' AS xn_type,
		 YEAR(b.memo_dt) as xn_year,MONTH(b.memo_dt) as xn_month,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN pr_month_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.memo_dt)=c.XN_YEAR AND MONTH(b.memo_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE c.xn_type=''DCO'' AND B.CANCELLED=0   AND b.memo_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)
		   
		 -- INTER BIN CHALLAN (IN)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCI'' AS xn_type,
		 YEAR(b.memo_dt) as xn_year,MONTH(b.memo_dt) as xn_month,
		  SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN pr_month_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.memo_dt)=c.XN_YEAR AND MONTH(b.memo_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE c.xn_type=''DCI'' AND ISNULL(B.RECEIPT_DT,'''')<>''''   AND b.memo_dt<=pr_upto.upto_dt AND b.cancelled=0
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)
		       
		 -- PURCHASE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END)  AS xn_type,  
		 YEAR(b.receipt_dt) as xn_year,MONTH(b.receipt_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM PID01106 A (NOLOCK)  
		 JOIN PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID  
		 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year,xn_month FROM pr_month_data_pos c (NOLOCK) WHERE  c.xn_type IN (''PUR'',''CHI'') 
		 ) c ON c.DEPT_ID=b.dept_id AND YEAR(b.receipt_DT)=c.XN_YEAR AND MONTH(b.receipt_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE pim_ref.mrr_id IS NULL
		 AND b.cancelled=0 AND b.pim_mode<>6   AND b.receipt_dt<=pr_upto.upto_dt AND b.receipt_Dt<>''''
		 GROUP BY b.location_Code,YEAR(b.receipt_dt),MONTH(b.receipt_dt),(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END) 
		 	 
		 
		 -- PURCHASE RETURN  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) AS xn_type,YEAR(b.rm_dt),MONTH(b.rm_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RMD01106 A (NOLOCK)  
		 JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year,xn_month FROM pr_month_data_pos c (NOLOCK) WHERE c.xn_type IN (''PRT'',''CHO'')
		 ) c  ON c.DEPT_ID=b.location_Code AND YEAR(b.rm_DT)=c.XN_YEAR AND MONTH(b.rm_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE b.cancelled=0  AND B.DN_TYPE IN (0,1)  AND b.rm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.rm_dt),MONTH(b.rm_dt),(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) 
		 
		 ---DEBIT NOTE PACK SLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DNPI'' AS xn_type,
		 YEAR(b.ps_dt),MONTH(b.ps_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM DNPS_DET A (NOLOCK)
		 JOIN DNPS_MST B (NOLOCK) ON A.ps_id = B.ps_id
		 JOIN pr_month_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.ps_DT)=c.XN_YEAR AND MONTH(b.ps_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE c.xn_type=''DNPI'' AND b.cancelled=0  AND b.ps_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.ps_dt),MONTH(b.ps_dt)	 	 
		 
		 UNION ALL
		 SELECT b.location_Code AS dept_id,''DNPR'' AS xn_type,YEAR(b.rm_dt),MONTH(b.rm_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM rmd01106 A (NOLOCK)
		 JOIN rmm01106 B (NOLOCK) ON A.rm_id = B.rm_id
		 JOIN pr_month_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND YEAR(b.rm_DT)=c.XN_YEAR AND MONTH(b.rm_dt)=c.xn_month
		 JOIN dnps_mst d (NOLOCK) ON d.ps_ID = a.ps_ID 
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE c.xn_type=''DNPR'' AND B.CANCELLED = 0 AND d.cancelled=0   AND b.rm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.rm_dt),MONTH(b.rm_dt)
		 	 
		 ---RETAIL SALE   
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END) AS xn_type,
		 YEAR(b.cm_dt),MONTH(b.cm_dt) as xn_month,
		 SUM(ABS(A.QUANTITY)) as xn_qty,SUM(ABS(rfnet)) AS xn_amount
		 FROM CMD01106 A (NOLOCK)  
		 JOIN CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year,xn_month FROM pr_month_data_pos c (NOLOCK) WHERE c.xn_type IN (''SLS'',''SLR'')
		 ) c ON c.DEPT_ID=b.location_Code AND YEAR(b.cm_DT)=c.XN_YEAR AND MONTH(b.cm_dt)=c.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE b.cancelled=0  AND b.cm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.cm_dt),MONTH(b.cm_dt),(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END)
		 	 
		  -- RETAIL SALE -PACKING SLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''RPS'' AS xn_type, 
		 YEAR(b.cm_dt),MONTH(b.cm_dt) as xn_month,
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RPS_DET A (NOLOCK)  
		 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.cm_DT)=d.XN_YEAR AND MONTH(b.cm_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type=''RPS'' AND b.cancelled=0  
		 AND ISNULL(B.REF_CM_ID,'''')=''''  AND b.cm_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.cm_dt),MONTH(b.cm_dt)
		 
		 -- APPROVAL ISSUE  
		  UNION ALL  
		 SELECT b.location_Code AS dept_id, ''APP'' AS xn_type,YEAR(b.memo_dt),MONTH(b.memo_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APD01106 A   
		 JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_DT)=d.XN_YEAR AND MONTH(b.memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type=''APP'' AND b.cancelled=0  AND b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)	 
		 
		 -- APPROVAL RETURN  
		 UNION ALL  
		 SELECT c.location_Code AS dept_id,''APR'' AS xn_type,YEAR(c.memo_dt),MONTH(c.memo_dt) as xn_month,
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APPROVAL_RETURN_DET A   
		 JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
		 JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=c.location_Code AND YEAR(c.memo_DT)=d.XN_YEAR AND MONTH(c.memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON c.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type=''APR'' AND c.cancelled=0  AND c.memo_dt<=pr_upto.upto_dt
		 GROUP BY c.location_Code,YEAR(c.memo_dt),MONTH(c.memo_dt)	 	 

		-- CANCELLATION/UNCANCELLATION
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END) AS xn_type,
		 YEAR(b.cnc_memo_dt),MONTH(b.cnc_memo_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ICD01106 A WITH (NOLOCK)    
		 JOIN ICM01106 B WITH (NOLOCK)   ON B.CNC_MEMO_ID = A.CNC_MEMO_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year,xn_month FROM pr_month_data_pos c (NOLOCK) WHERE c.xn_type IN (''CNC'',''UNC'')
		 ) d ON d.DEPT_ID=b.location_Code AND YEAR(b.cnc_memo_DT)=d.XN_YEAR AND MONTH(b.cnc_memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE b.cancelled=0  AND STOCK_ADJ_NOTE=0  AND b.cnc_memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END),YEAR(b.cnc_memo_dt),MONTH(b.cnc_memo_dt)
		 	   
		 --WHOLESALE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END)  AS xn_type,
		 YEAR(b.inv_dt),MONTH(b.inv_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IND01106 A (NOLOCK)  
		 JOIN INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year,xn_month FROM pr_month_data_pos c (NOLOCK) WHERE c.xn_type IN (''WSL'',''CHO'')
		 ) d ON d.DEPT_ID=b.location_Code AND YEAR(b.inv_DT)=d.XN_YEAR AND MONTH(b.inv_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE b.cancelled=0  AND b.inv_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.inv_dt),MONTH(b.inv_dt),(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END) 
		 	 
		 --WHOLESALE PACKSLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPI'' AS xn_type,YEAR(b.ps_dt),MONTH(b.ps_dt) as xn_month,
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM wps_det A (NOLOCK)  
		 JOIN wps_mst B (NOLOCK) ON A.ps_id = B.ps_id  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.ps_DT)=d.XN_YEAR AND MONTH(b.ps_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''WPI'') AND b.cancelled=0  AND b.ps_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.ps_dt),MONTH(b.ps_dt)

		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPR'' AS xn_type,YEAR(b.inv_dt),MONTH(b.inv_dt) as xn_month,
		 SUM(a.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ind01106 A (NOLOCK)  
		 JOIN inm01106 B (NOLOCK) ON A.inv_id = B.inv_id  
		 JOIN wps_mst c (NOLOCK) ON c.ps_id=a.ps_id
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.inv_DT)=d.XN_YEAR AND MONTH(b.inv_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''WPR'') AND b.cancelled=0 AND c.cancelled=0  AND b.inv_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.inv_dt),MONTH(b.inv_dt)
		 	 
		 --WHOLESALE CREDIT NOTE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END)  AS xn_type,
		 (CASE WHEN mode=2 THEN YEAR(b.receipt_dt) else YEAR(b.cn_dt) END),
		 (CASE WHEN mode=2 THEN month(b.receipt_dt) else month(b.cn_dt) END) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM CND01106 A (NOLOCK)  
		 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_year,xn_month FROM pr_month_data_pos c (NOLOCK) WHERE c.xn_type IN (''WSR'',''CHI'')
		 ) d   ON d.DEPT_ID=b.billed_from_dept_id AND YEAR(b.cn_DT)=d.XN_YEAR AND MONTH(b.cn_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE b.cancelled=0  AND B.CN_TYPE<>2   AND
		 ((mode=2 and  b.receipt_dt<=pr_upto.upto_dt and b.receipt_dt<>'''') or (mode=1 and b.cn_dt<=pr_upto.upto_dt))
		 GROUP BY b.location_Code,(CASE WHEN mode=2 THEN YEAR(b.receipt_dt) else YEAR(b.cn_dt) END),
		 (CASE WHEN mode=2 THEN month(b.receipt_dt) else month(b.cn_dt) END),(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END) 

		 -- GENERATION OF NEW BAR CODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,YEAR(b.irm_memo_dt),MONTH(b.irm_memo_dt) as xn_month,
		  ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.irm_memo_DT)=d.XN_YEAR AND MONTH(b.irm_memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''PFI'') and  b.irm_memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.irm_memo_dt),MONTH(b.irm_memo_dt)
		  
		 -- GENERATION OF NEW BAR CODES IN SPLIT COMBINE
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,YEAR(b.memo_dt),MONTH(b.memo_dt) as xn_month,
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCF01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_DT)=d.XN_YEAR AND MONTH(b.memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''PFI'') AND b.cancelled=0  AND A.PRODUCT_CODE<>''''  and  b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)
		  
		 -- CONSUMPTION OF OLD BARCODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''CIP'' AS xn_type,YEAR(b.irm_memo_dt),MONTH(b.irm_memo_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount 
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.irm_memo_DT)=d.XN_YEAR AND MONTH(b.irm_memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''CIP'')  AND A.new_PRODUCT_CODE<>''''  and  b.irm_memo_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.irm_memo_dt),MONTH(b.irm_memo_dt)
		  
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,YEAR(b.memo_dt),MONTH(b.memo_dt) as xn_month,
		 ABS(SUM(A.QUANTITY+ADJ_QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCC01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_DT)=d.XN_YEAR AND MONTH(b.memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0  AND A.PRODUCT_CODE<>''''  and  b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)
		 
		 -- JOB WORK ISSUE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWI'' AS xn_type,YEAR(b.issue_dt),MONTH(b.issue_dt) as xn_month,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM JOBWORK_ISSUE_DET A (NOLOCK)  
		 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.issue_DT)=d.XN_YEAR AND MONTH(b.issue_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''JWI'') AND b.cancelled=0 AND b.issue_type=1  and  b.issue_dt<=pr_upto.upto_dt
		 AND ISNULL(B.WIP,0)=0
		 GROUP BY b.location_Code,YEAR(b.issue_dt),MONTH(b.issue_dt)
		   
		 -- JOB WORK RECEIPT  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWR'' AS xn_type,YEAR(b.receipt_dt),MONTH(b.receipt_dt) as xn_month,
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
		 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
		 JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=A.PRODUCT_CODE  
		 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
		 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  
		 JOIN pr_month_data_pos f (NOLOCK) ON f.DEPT_ID=b.location_Code AND YEAR(b.receipt_DT)=f.XN_YEAR AND MONTH(b.receipt_dt)=f.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE f.xn_type IN (''JWR'') AND b.cancelled=0  AND  E.ISSUE_TYPE=1 and  b.receipt_dt<=pr_upto.upto_dt 
		 GROUP BY b.location_Code,YEAR(b.receipt_dt),MONTH(b.receipt_dt)
		 	 
		 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)	  
		 UNION ALL 
		 SELECT b.location_Code AS dept_id,''SCF'' AS xn_type,YEAR(b.receipt_dt),MONTH(b.receipt_dt) as xn_month,
		 SUM((CASE WHEN b2.barcode_coding_scheme=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN
		 (
			SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,sku.barcode_coding_scheme,COUNT(*) AS [TOTAL_QTY]
			FROM SNC_BARCODE_DET a (NOLOCK)
			JOIN sku (NOLOCK) ON sku.product_code=a.product_code
			GROUP BY REFROW_ID,a.PRODUCT_CODE,sku.barcode_coding_scheme
		 )B2 ON A.ROW_ID = B2.ROW_ID
		 JOIN ARTICLE A1 ON A1.ARTICLE_CODE=A.ARTICLE_CODE
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.receipt_DT)=d.XN_YEAR AND MONTH(b.receipt_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID 
		 WHERE d.xn_type IN (''SCF'') AND b.cancelled=0  AND B2.PRODUCT_CODE<>'''' and  b.receipt_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.receipt_dt),MONTH(b.receipt_dt)
		 
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)  
		UNION ALL   
		SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,YEAR(b.receipt_dt),MONTH(b.receipt_dt) as xn_month,
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.receipt_DT)=d.XN_YEAR AND MONTH(b.receipt_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0 AND A.PRODUCT_CODE<>''''  and  b.receipt_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.receipt_dt),MONTH(b.receipt_dt)

		 -- GRN PACKSLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''GRNPS'' AS xn_type,YEAR(b.memo_dt),MONTH(b.memo_dt) as xn_month,
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM GRN_PS_DET A (NOLOCK)  
		 JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_month_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND YEAR(b.memo_dt)=d.XN_YEAR AND MONTH(b.memo_dt)=d.xn_month
		 JOIN PR_UPTODATE pr_upto ON b.location_Code=pr_upto.DEPT_ID
		 WHERE d.xn_type IN (''GRNPS'') AND b.cancelled=0 and  b.memo_dt<=pr_upto.upto_dt
		 GROUP BY b.location_Code,YEAR(b.memo_dt),MONTH(b.memo_dt)
		) a
		GROUP BY dept_id,xn_year,xn_month,xn_type'
	
	END

	ELSE
	IF @NMODE=3  ---- Compare Date wise Data
	BEGIN
		 SET @CCMD=N'SELECT dept_id,xn_dt,xn_type,SUM(XN_QTY) as xn_qty,SUM(xn_amount) AS xn_amount
	 
		 FROM 
		 ( 
		 SELECT a.dept_id,''OPS'' AS xn_type,
		 A.xn_dt,
		 SUM(A.QUANTITY_OB) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM OPS01106 A WITH (NOLOCK)  
		 JOIN pr_date_data_pos c (NOLOCK) ON A.DEPT_ID=c.DEPT_ID AND A.XN_DT=c.XN_dt
		 WHERE c.xn_type=''OPS''
		 GROUP BY a.dept_id,A.xn_dt
		 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''PRDXFR'' AS xn_type, 
		 b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM PRD_STK_TRANSFER_DTM_DET  A WITH (NOLOCK)    
		 JOIN PRD_STK_TRANSFER_DTM_MST B WITH (NOLOCK)   ON A.MEMO_ID = B.MEMO_ID   
		 JOIN pr_date_data_pos c (NOLOCK) ON c.DEPT_ID=B.DEPT_ID AND b.memo_DT=c.XN_dt
		 WHERE c.xn_type=''prdxfr'' AND B.CANCELLED=0  
		 GROUP BY b.location_Code,b.memo_dt
		 
		 -- INTER BIN CHALLAN (OUT)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCO'' AS xn_type,
		 b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN pr_date_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND b.memo_DT=c.XN_dt
		 WHERE c.xn_type=''DCO'' AND B.CANCELLED=0  
		 GROUP BY b.location_Code,b.memo_dt
		   
		 -- INTER BIN CHALLAN (IN)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCI'' AS xn_type,
		 b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN pr_date_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND b.memo_DT=c.XN_dt
		 WHERE c.xn_type=''DCI'' AND ISNULL(B.RECEIPT_DT,'''')<>'''' AND b.cancelled=0
		 GROUP BY b.location_Code,b.memo_dt
		       
		 -- PURCHASE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END)  AS xn_type,  
		 b.receipt_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM PID01106 A (NOLOCK)  
		 JOIN PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID  
		 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_dt FROM pr_date_data_pos c (NOLOCK) WHERE  c.xn_type IN (''PUR'',''CHI'') 
		 ) c ON c.DEPT_ID=b.dept_id AND b.receipt_DT=c.XN_dt
		 WHERE pim_ref.mrr_id IS NULL
		 AND b.cancelled=0 AND b.pim_mode<>6
		 GROUP BY b.location_Code,b.receipt_dt,(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END) 
		 	 
		 
		 -- PURCHASE RETURN  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) AS xn_type,
		 b.rm_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RMD01106 A (NOLOCK)  
		 JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
		 JOIN 
		 (SELECT distinct dept_id,xn_dt FROM pr_date_data_pos c (NOLOCK) WHERE c.xn_type IN (''PRT'',''CHO'')
		 ) c  ON c.DEPT_ID=b.location_Code AND b.rm_DT=c.XN_dt
		 WHERE b.cancelled=0  AND B.DN_TYPE IN (0,1)
		 GROUP BY b.location_Code,b.rm_dt,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) 
		 
		 ---DEBIT NOTE PACK SLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DNPI'' AS xn_type,
		 b.ps_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM DNPS_DET A (NOLOCK)
		 JOIN DNPS_MST B (NOLOCK) ON A.ps_id = B.ps_id
		 JOIN pr_date_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND b.ps_DT=c.XN_dt
		 WHERE c.xn_type=''DNPI'' AND b.cancelled=0
		 GROUP BY b.location_Code,b.ps_dt
		 
		 UNION ALL
		 SELECT b.location_Code AS dept_id,''DNPR'' AS xn_type,b.rm_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM rmd01106 A (NOLOCK)
		 JOIN rmm01106 B (NOLOCK) ON A.rm_id = B.rm_id
		 JOIN pr_date_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND b.rm_DT=c.XN_dt
		 JOIN dnps_mst d (NOLOCK) ON d.ps_ID = a.ps_ID 
		 WHERE c.xn_type=''DNPR'' AND B.CANCELLED = 0 AND d.cancelled=0 
		 GROUP BY b.location_Code,b.rm_dt
		 	 
		 ---RETAIL SALE   
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END) AS xn_type,
		 b.cm_dt,  
		 SUM(ABS(A.QUANTITY)) as xn_qty,SUM(ABS(rfnet)) AS xn_amount
		 FROM CMD01106 A (NOLOCK)  
		 JOIN CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID  
		 JOIN 
		 (SELECT distinct dept_id,xn_dt FROM pr_date_data_pos c (NOLOCK) WHERE c.xn_type IN (''SLS'',''SLR'')
		 ) c ON c.DEPT_ID=b.location_Code AND b.cm_DT=c.XN_dt
		 WHERE b.cancelled=0
		 GROUP BY b.location_Code,b.cm_dt,(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END)
		 	 
		  -- RETAIL SALE -PACKING SLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''RPS'' AS xn_type, 
		 b.cm_dt,  
		  SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RPS_DET A (NOLOCK)  
		 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.cm_DT=d.XN_dt
		 WHERE d.xn_type=''RPS'' AND b.cancelled=0  
		 AND ISNULL(B.REF_CM_ID,'''')=''''
		 GROUP BY b.location_Code,b.cm_dt
		 
		 -- APPROVAL ISSUE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id, ''APP'' AS xn_type,b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APD01106 A   
		 JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.memo_DT=d.XN_dt
		 WHERE d.xn_type=''APP'' AND b.cancelled=0
		 GROUP BY b.location_Code,b.memo_dt
		 
		 -- APPROVAL RETURN  
		 UNION ALL  
		 SELECT c.location_Code AS dept_id,''APR'' AS xn_type,c.memo_dt,  
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APPROVAL_RETURN_DET A   
		 JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
		 JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=c.location_Code AND c.memo_DT=d.XN_dt
		 WHERE d.xn_type=''APR'' AND c.cancelled=0
		 GROUP BY c.location_Code,c.memo_dt

		-- CANCELLATION/UNCANCELLATION
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END) AS xn_type,
		 b.cnc_memo_dt,SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ICD01106 A WITH (NOLOCK)    
		 JOIN ICM01106 B WITH (NOLOCK)   ON B.CNC_MEMO_ID = A.CNC_MEMO_ID  
		 JOIN 
		 (SELECT distinct dept_id,xn_dt FROM pr_date_data_pos c (NOLOCK) WHERE c.xn_type IN (''CNC'',''UNC'')
		 ) d ON d.DEPT_ID=b.location_Code AND b.cnc_memo_DT=d.XN_dt
		 WHERE b.cancelled=0  AND STOCK_ADJ_NOTE=0
		 GROUP BY b.location_Code,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END),b.cnc_memo_dt
		 	   
		 --WHOLESALE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END)  AS xn_type,
		 b.inv_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IND01106 A (NOLOCK)  
		 JOIN INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID  
		 JOIN 
		 (SELECT distinct dept_id,xn_dt FROM pr_date_data_pos c (NOLOCK) WHERE c.xn_type IN (''WSL'',''CHO'')
		 ) d ON d.DEPT_ID=b.location_Code AND b.inv_DT=d.XN_dt
		 WHERE b.cancelled=0 
		 GROUP BY b.location_Code,b.inv_dt,(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END) 
		 	 
		 --WHOLESALE PACKSLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPI'' AS xn_type,b.ps_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM wps_det A (NOLOCK)  
		 JOIN wps_mst B (NOLOCK) ON A.ps_id = B.ps_id  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.ps_DT=d.XN_dt
		 WHERE d.xn_type IN (''WPI'') AND b.cancelled=0
		 GROUP BY b.location_Code,b.ps_dt

		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPR'' AS xn_type,b.inv_dt,  
		 SUM(a.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ind01106 A (NOLOCK)  
		 JOIN inm01106 B (NOLOCK) ON A.inv_id = B.inv_id  
		 JOIN wps_mst c (NOLOCK) ON c.ps_id=a.ps_id
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.inv_DT=d.XN_dt
		 WHERE d.xn_type IN (''WPR'') AND b.cancelled=0 AND c.cancelled=0
		 GROUP BY b.location_Code,b.inv_dt
		 	 
		 --WHOLESALE CREDIT NOTE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END)  AS xn_type,
		 b.cn_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM CND01106 A (NOLOCK)  
		 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID  
		 JOIN 
		 (SELECT distinct dept_id,xn_dt FROM pr_date_data_pos c (NOLOCK) WHERE c.xn_type IN (''WSR'',''CHI'')
		 ) d   ON d.DEPT_ID=b.billed_from_dept_id AND b.cn_DT=d.XN_dt
		 WHERE b.cancelled=0 AND B.CN_TYPE<>2  
		 GROUP BY b.location_Code,b.cn_dt,(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END) 

		 -- GENERATION OF NEW BAR CODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,b.irm_memo_dt,  
		  ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.irm_memo_DT=d.XN_dt
		 WHERE d.xn_type IN (''PFI'')
		 GROUP BY b.location_Code,b.irm_memo_dt
		  
		 -- GENERATION OF NEW BAR CODES IN SPLIT COMBINE
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,b.memo_dt,  
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCF01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.memo_DT=d.XN_dt
		 WHERE d.xn_type IN (''PFI'') AND b.cancelled=0  AND A.PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.memo_dt
		  
		 -- CONSUMPTION OF OLD BARCODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''CIP'' AS xn_type,b.irm_memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount 
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.irm_memo_DT=d.XN_dt
		 WHERE d.xn_type IN (''CIP'')  AND A.new_PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.irm_memo_dt
		  
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,b.memo_dt,  
		 ABS(SUM(A.QUANTITY+ADJ_QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCC01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.memo_DT=d.XN_dt
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0  AND A.PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.memo_dt
		 
		 -- JOB WORK ISSUE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWI'' AS xn_type,b.issue_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM JOBWORK_ISSUE_DET A (NOLOCK)  
		 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.issue_DT=d.XN_dt
		 WHERE d.xn_type IN (''JWI'') AND b.cancelled=0 AND b.issue_type=1
		 AND ISNULL(B.WIP,0)=0
		 GROUP BY b.location_Code,b.issue_dt
		   
		 -- JOB WORK RECEIPT  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWR'' AS xn_type,b.receipt_dt,  
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
		 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
		 JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=A.PRODUCT_CODE  
		 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
		 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  
		 JOIN pr_date_data_pos f (NOLOCK) ON f.DEPT_ID=b.location_Code AND b.receipt_DT=f.XN_dt
		 WHERE f.xn_type IN (''JWR'') AND b.cancelled=0  AND  E.ISSUE_TYPE=1 
		 GROUP BY b.location_Code,b.receipt_dt
		 	 
		 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)	  
		 UNION ALL 
		 SELECT b.location_Code AS dept_id,''SCF'' AS xn_type,b.receipt_dt,  
		 SUM((CASE WHEN b2.barcode_coding_scheme=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN
		 (
			SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,sku.barcode_coding_scheme,COUNT(*) AS [TOTAL_QTY]
			FROM SNC_BARCODE_DET a (NOLOCK)
			JOIN sku (NOLOCK) ON sku.product_code=a.product_code
			GROUP BY REFROW_ID,a.PRODUCT_CODE,sku.barcode_coding_scheme
		 )B2 ON A.ROW_ID = B2.ROW_ID
		 JOIN ARTICLE A1 ON A1.ARTICLE_CODE=A.ARTICLE_CODE
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.receipt_DT=d.XN_dt
		 WHERE d.xn_type IN (''SCF'') AND b.cancelled=0  AND B2.PRODUCT_CODE<>''''
		 GROUP BY b.location_Code,b.receipt_dt
		 
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)  
		UNION ALL   
		SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,b.receipt_dt,  
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.receipt_DT=d.XN_dt
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.receipt_dt

		 -- GRN PACKSLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''GRNPS'' AS xn_type,b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM GRN_PS_DET A (NOLOCK)  
		 JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_date_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND b.memo_DT=d.XN_dt
		 WHERE d.xn_type IN (''GRNPS'') AND b.cancelled=0
		 GROUP BY b.location_Code,b.memo_dt
		) a
		GROUP BY dept_id,xn_dt,xn_type'
	
	END

	ELSE 
	IF @NMODE=4    ---- Compare Memo wise Data
	BEGIN
		 SET @CCMD=N'SELECT dept_id,xn_id,xn_type,xn_dt,SUM(XN_QTY) as xn_qty,SUM(xn_amount) AS xn_amount
	 
		 FROM 
		 ( 
		 SELECT b.location_Code AS dept_id,''PRDXFR'' AS xn_type, 
		 ''PRD''+b.memo_id as xn_id,xn_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM PRD_STK_TRANSFER_DTM_DET  A WITH (NOLOCK)    
		 JOIN PRD_STK_TRANSFER_DTM_MST B WITH (NOLOCK)   ON A.MEMO_ID = B.MEMO_ID   
		 JOIN pr_memo_data_pos c (NOLOCK) ON c.DEPT_ID=B.DEPT_ID AND ''PRDXFR''+b.memo_id=c.XN_id
		 WHERE c.xn_type=''prdxfr'' AND B.CANCELLED=0  
		 GROUP BY b.location_Code,xn_dt,b.memo_id
		 
		 -- INTER BIN CHALLAN (OUT)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCO'' AS xn_type,
		 ''FLR''+b.memo_id,b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN pr_memo_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND ''DCO''+b.memo_id=c.XN_id
		 WHERE c.xn_type=''DCO'' AND B.CANCELLED=0  
		 GROUP BY b.location_Code,b.memo_dt,b.memo_id
		   
		 -- INTER BIN CHALLAN (IN)
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DCI'' AS xn_type,
		 ''FLR''+b.memo_id,b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM FLOOR_ST_DET  A (NOLOCK)  
		 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
		 JOIN pr_memo_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND ''DCI''+b.memo_id=c.XN_id
		 WHERE c.xn_type=''DCI'' AND ISNULL(B.RECEIPT_DT,'''')<>'''' AND b.cancelled=0
		 GROUP BY b.location_Code,b.memo_dt,b.memo_id
		       
		 -- PURCHASE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END)  AS xn_type,  
		 ''PIM''+b.mrr_id,b.receipt_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM PID01106 A (NOLOCK)  
		 JOIN PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID  
		 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_id FROM pr_memo_data_pos c (NOLOCK) WHERE  c.xn_type IN (''PUR'',''CHI'') 
		 ) c ON c.DEPT_ID=b.dept_id AND ''PIM''+b.mrr_id=c.XN_id
		 WHERE pim_ref.mrr_id IS NULL
		 AND b.cancelled=0 AND b.pim_mode<>6
		 GROUP BY b.location_Code,b.mrr_id,b.receipt_dt,(CASE WHEN b.inv_mode=2 THEN ''CHI'' ELSE ''PUR'' END) 
		 	 
		 
		 -- PURCHASE RETURN  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) AS xn_type,
		 ''RMM''+b.rm_id,b.rm_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM RMD01106 A (NOLOCK)  
		 JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_id FROM pr_memo_data_pos c (NOLOCK) WHERE c.xn_type IN (''PRT'',''CHO'')
		 ) c  ON c.DEPT_ID=b.location_Code AND ''RMM''+b.rm_id=c.XN_id
		 WHERE b.cancelled=0  AND B.DN_TYPE IN (0,1)
		 GROUP BY b.location_Code,b.rm_id,b.rm_dt,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END) 
		 
		 ---DEBIT NOTE PACK SLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''DNPI'' AS xn_type,
		 ''DNPI''+b.ps_id,b.ps_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM DNPS_DET A (NOLOCK)
		 JOIN DNPS_MST B (NOLOCK) ON A.ps_id = B.ps_id
		 JOIN pr_memo_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND ''DNPI''+b.ps_id=c.XN_id
		 WHERE c.xn_type=''DNPI'' AND b.cancelled=0
		 GROUP BY b.location_Code,b.ps_dt,b.ps_id
		 
		 UNION ALL
		 SELECT b.location_Code AS dept_id,''DNPR'' AS xn_type,''DNPR''+b.rm_id,b.rm_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM rmd01106 A (NOLOCK)
		 JOIN rmm01106 B (NOLOCK) ON A.rm_id = B.rm_id
		 JOIN pr_memo_data_pos c (NOLOCK) ON c.DEPT_ID=b.location_Code AND ''DNPR''+b.rm_id=c.XN_id
		 JOIN dnps_mst d (NOLOCK) ON d.ps_ID = a.ps_ID 
		 WHERE c.xn_type=''DNPR'' AND B.CANCELLED = 0 AND d.cancelled=0 
		 GROUP BY b.location_Code,b.rm_dt,b.rm_id
		 	 
		 ---RETAIL SALE   
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END) AS xn_type,
		 ''CMM''+b.cm_id,b.cm_dt,  
		 SUM(ABS(A.QUANTITY)) as xn_qty,SUM(ABS(rfnet)) AS xn_amount
		 FROM CMD01106 A (NOLOCK)  
		 JOIN CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_id FROM pr_memo_data_pos c (NOLOCK) WHERE c.xn_type IN (''SLS'',''SLR'')
		 ) c ON c.DEPT_ID=b.location_Code AND ''CMM''+b.cm_id=c.XN_id
		 WHERE b.cancelled=0
		 GROUP BY b.location_Code,b.cm_id,b.cm_dt,(CASE WHEN quantity>0 THEN ''SLS'' ELSE ''SLR'' END)
		 
		 -- APPROVAL ISSUE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id, ''APP'' AS xn_type,''APM''+b.memo_id,b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APD01106 A   
		 JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''APM''+b.memo_id=d.XN_id
		 WHERE d.xn_type=''APP'' AND b.cancelled=0
		 GROUP BY b.location_Code,b.memo_dt,b.memo_id
		 
		 -- APPROVAL RETURN  
		 UNION ALL  
		 SELECT c.location_Code AS dept_id,''APR'' AS xn_type,''APR''+c.memo_id,c.memo_dt,  
		   SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM APPROVAL_RETURN_DET A   
		 JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
		 JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=c.location_Code AND ''APR''+c.memo_id=d.XN_id
		 WHERE d.xn_type=''APR'' AND c.cancelled=0
		 GROUP BY c.location_Code,c.memo_dt,c.memo_id

		-- CANCELLATION/UNCANCELLATION
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END) AS xn_type,
		 ''ICM''+b.cnc_memo_id,b.cnc_memo_dt,SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ICD01106 A WITH (NOLOCK)    
		 JOIN ICM01106 B WITH (NOLOCK)   ON B.CNC_MEMO_ID = A.CNC_MEMO_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_id FROM pr_memo_data_pos c (NOLOCK) WHERE c.xn_type IN (''CNC'',''UNC'')
		 ) d ON d.DEPT_ID=b.location_Code AND ''ICM''+b.cnc_memo_id=d.XN_id
		 WHERE b.cancelled=0  AND STOCK_ADJ_NOTE=0
		 GROUP BY b.location_Code,(CASE WHEN cnc_type=1 THEN ''CNC''ELSE ''UNC'' END),b.cnc_memo_dt,b.cnc_memo_id
		 	   
		 --WHOLESALE INVOICE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END)  AS xn_type,
		 ''INM''+b.inv_id,b.inv_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IND01106 A (NOLOCK)  
		 JOIN INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_id FROM pr_memo_data_pos c (NOLOCK) WHERE c.xn_type IN (''WSL'',''CHO'')
		 ) d ON d.DEPT_ID=b.location_Code AND ''INM''+b.inv_id=d.XN_id
		 WHERE b.cancelled=0 
		 GROUP BY b.location_Code,b.inv_id,b.inv_dt,(CASE WHEN inv_mode=2 THEN ''CHO'' ELSE ''WSL'' END) 
		 	 
		 --WHOLESALE PACKSLIP  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPI'' AS xn_type,''WPI''+b.ps_id,b.ps_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM wps_det A (NOLOCK)  
		 JOIN wps_mst B (NOLOCK) ON A.ps_id = B.ps_id  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''WPI''+b.ps_id=d.XN_id
		 WHERE d.xn_type IN (''WPI'') AND b.cancelled=0
		 GROUP BY b.location_Code,b.ps_dt,b.ps_id

		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''WPR'' AS xn_type,''INM''+b.inv_id,b.inv_dt,  
		 SUM(a.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM ind01106 A (NOLOCK)  
		 JOIN inm01106 B (NOLOCK) ON A.inv_id = B.inv_id  
		 JOIN wps_mst c (NOLOCK) ON c.ps_id=a.ps_id
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''INM''+b.inv_id=d.XN_id
		 WHERE d.xn_type IN (''WPR'') AND b.cancelled=0 AND c.cancelled=0
		 GROUP BY b.location_Code,b.inv_dt,b.inv_id
		 	 
		 --WHOLESALE CREDIT NOTE  
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END)  AS xn_type,
		 ''CNM''+b.cn_id,b.cn_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM CND01106 A (NOLOCK)  
		 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID  
		 JOIN 
		 (SELECT DISTINCT dept_id,xn_id FROM pr_memo_data_pos c (NOLOCK) WHERE c.xn_type IN (''WSR'',''CHI'')
		 ) d   ON d.DEPT_ID=b.billed_from_dept_id AND ''CNM''+b.cn_id=d.XN_id
		 WHERE b.cancelled=0 AND B.CN_TYPE<>2  
		 GROUP BY b.location_Code,b.cn_id,b.cn_dt,(CASE WHEN mode=2 THEN ''CHI'' ELSE ''WSR'' END) 

		 -- GENERATION OF NEW BAR CODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,''IRM''+b.irm_memo_id,b.irm_memo_dt,  
		  ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''IRM''+b.irm_memo_iD=d.XN_id
		 WHERE d.xn_type IN (''PFI'')
		 GROUP BY b.location_Code,b.irm_memo_dt,b.irm_memo_id
		  
		 -- GENERATION OF NEW BAR CODES IN SPLIT COMBINE
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''PFI'' AS xn_type,''SCM''+b.memo_id,b.memo_dt,  
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCF01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''SCM''+b.memo_iD=d.XN_id
		 WHERE d.xn_type IN (''PFI'') AND b.cancelled=0  AND A.PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.memo_dt,b.memo_id
		  
		 -- CONSUMPTION OF OLD BARCODES IN RATE REVISION  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''CIP'' AS xn_type,''IRM''+b.irm_memo_id,b.irm_memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount 
		 FROM IRD01106 A (NOLOCK)  
		 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''IRM''+b.irm_memo_iD=d.XN_id
		 WHERE d.xn_type IN (''CIP'')  AND A.new_PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.irm_memo_dt,b.irm_memo_id
		  
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,''SCM''+b.memo_id,b.memo_dt,  
		 ABS(SUM(A.QUANTITY+ADJ_QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SCC01106 A (NOLOCK)  
		 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''SCM''+b.memo_iD=d.XN_id
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0  AND A.PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.memo_dt,b.memo_id
		 
		 -- JOB WORK ISSUE  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWI'' AS xn_type,''JWI''+b.issue_id,b.issue_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM JOBWORK_ISSUE_DET A (NOLOCK)  
		 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''JWI''+b.issue_id=d.XN_id
		 WHERE d.xn_type IN (''JWI'') AND b.cancelled=0 AND b.issue_type=1
		 AND ISNULL(B.WIP,0)=0
		 GROUP BY b.location_Code,b.issue_dt,b.issue_id
		   
		 -- JOB WORK RECEIPT  
		 UNION ALL   
		 SELECT b.location_Code AS dept_id,''JWR'' AS xn_type,''JWR''+b.receipt_id,b.receipt_dt,  
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
		 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
		 JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=A.PRODUCT_CODE  
		 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
		 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  
		 JOIN pr_memo_data_pos f (NOLOCK) ON f.DEPT_ID=b.location_Code AND ''JWR''+b.receipt_iD=f.XN_id
		 WHERE f.xn_type IN (''JWR'') AND b.cancelled=0  AND  E.ISSUE_TYPE=1 
		 GROUP BY b.location_Code,b.receipt_dt,b.receipt_id
		 	 
		 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)	  
		 UNION ALL 
		 SELECT b.location_Code AS dept_id,''SCF'' AS xn_type,''SNC''+b.memo_id,b.receipt_dt,  
		 SUM((CASE WHEN b2.barcode_coding_scheme=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN
		 (
			SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,sku.barcode_coding_scheme,COUNT(*) AS [TOTAL_QTY]
			FROM SNC_BARCODE_DET a (NOLOCK)
			JOIN sku (NOLOCK) ON sku.product_code=a.product_code
			GROUP BY REFROW_ID,a.PRODUCT_CODE,sku.barcode_coding_scheme
		 )B2 ON A.ROW_ID = B2.ROW_ID
		 JOIN ARTICLE A1 ON A1.ARTICLE_CODE=A.ARTICLE_CODE
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''SNC''+b.memo_iD=d.XN_id
		 WHERE d.xn_type IN (''SCF'') AND b.cancelled=0  AND B2.PRODUCT_CODE<>''''
		 GROUP BY b.location_Code,b.receipt_dt,b.memo_id
		 
		 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)  
		UNION ALL   
		SELECT b.location_Code AS dept_id,''SCC'' AS xn_type,''SNC''+b.memo_id,b.receipt_dt,  
		 ABS(SUM(A.QUANTITY)) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount
		 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
		 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''SNC''+b.memo_iD=d.XN_id
		 WHERE d.xn_type IN (''SCC'') AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' 
		 GROUP BY b.location_Code,b.receipt_dt,b.memo_id

		 -- GRN PACKSLIP 
		 UNION ALL  
		 SELECT b.location_Code AS dept_id,''GRNPS'' AS xn_type,''GRNPSIN''+b.memo_id,b.memo_dt,  
		 SUM(A.QUANTITY) as xn_qty,CONVERT(NUMERIC(14,2),0) AS xn_amount  
		 FROM GRN_PS_DET A (NOLOCK)  
		 JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		 JOIN pr_memo_data_pos d (NOLOCK) ON d.DEPT_ID=b.location_Code AND ''GRNPSIN''+b.memo_iD=d.XN_id
		 WHERE d.xn_type IN (''GRNPS'') AND b.cancelled=0
		 GROUP BY b.location_Code,b.memo_dt,b.memo_id
		) a
		GROUP BY dept_id,xn_id,xn_type,xn_dt'
	
	END
	
	PRINT 'Insert Data for REco mode:'+str(@nMode)
	PRINT @cCmd	
	
--	select @cCmd
	EXEC SP_EXECUTESQL @cCmd	
END
