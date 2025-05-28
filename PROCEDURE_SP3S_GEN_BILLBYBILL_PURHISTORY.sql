CREATE PROCEDURE SP3S_GEN_BILLBYBILL_PURHISTORY
AS
BEGIN

    SELECT CONVERT(VARCHAR(40),'') pur_mrr_id,b.ac_code,a.ref_no,SUM(CASE WHEN a.x_type='Cr' THEN amount ELSE -amount END) pending_amt
	INTO #tmpBBPur
	FROM bill_by_bill_ref a (NOLOCK) 	
	JOIN vd01106 b (NOLOCK) ON a.vd_id=b.vd_id
	JOIN vm01106 c (NOLOCK) ON c.vm_id=b.vm_id
	WHERE cancelled=0
	GROUP BY a.ref_no,b.ac_code
	HAVING SUM(CASE WHEN a.x_type='Cr' THEN amount ELSE -amount END)<>0

	UPDATE a SET pur_mrr_id=e.memo_id FROM #tmpBBPur a
	JOIN bill_by_bill_ref b (NOLOCK) ON a.REF_NO=b.REF_NO
	JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id  AND c.ac_code=a.ac_code
	JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
	JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id
	WHERE e.xn_type='PUR' AND d.cancelled=0

	DELETE FROM #tmpBBPur WHERE pur_mrr_id=''

	SELECT b.ac_code,b.ref_no,b.pur_mrr_id,product_code,SUM(quantity) pur_qty INTO #tmpPur FROM pid01106 a (NOLOCK) 
	JOIN #tmpBBPur b ON a.mrr_id=b.pur_mrr_id
	JOIN pim01106 c (NOLOCK) ON c.mrr_id=a.mrr_id
	WHERE ISNULL(xn_item_type,0) IN (0,1)
	GROUP BY b.ac_code,b.ref_no,b.pur_mrr_id,product_code
	
--	select 'check tmppur', * FROM #TMPPUR where pur_mrr_id='010112200000001-001369'
	SELECT a.ac_code,a.ref_no, A.pur_mrr_id,CONVERT(NUMERIC(6,0),0) cr_days,convert(date,'') due_date,CONVERT(NUMERIC(6,2),0) cd_percentage,
	CONVERT(NUMERIC(10,2),0) cd_base_amount,ISNULL(PRT_QTY,0) AS PRT_QTY,ISNULL(A.PUR_QTY ,0) AS PUR_QTY,
	CAST(ISNULL(SLS_QTY,0) AS NUMERIC(18,2)) AS SLS_QTY,CAST(ISNULL(SLS_QTY,0)*sn.pp AS NUMERIC(14,2))  AS SLS_COST_PRICE
	INTO #TMPPURDETAILS
	FROM #TMPPUR A
	LEFT JOIN
	(
	SELECT A.PRODUCT_CODE ,
			SUM(A.QUANTITY) AS PRT_QTY
		FROM #TMPPUR TMP
		JOIN RMD01106 A (NOLOCK) ON TMP.PRODUCT_CODE =A.PRODUCT_CODE 
		JOIN RMM01106 B (NOLOCK) ON A.RM_ID =B.RM_ID 
		WHERE B.CANCELLED =0
		AND B.MODE =1
	GROUP BY A.PRODUCT_CODE
	) B ON  A.PRODUCT_CODE =B.PRODUCT_CODE 
		
	LEFT JOIN
	(
	    SELECT A.PRODUCT_CODE, SUM(A.SLS_QTY) AS SLS_QTY
		FROM 
		(
		SELECT  A.PRODUCT_CODE ,
				SUM(CMD.QUANTITY) AS SLS_QTY 
		FROM #TMPPUR A
		JOIN CMD01106 CMD (NOLOCK) ON A.PRODUCT_CODE =CMD.PRODUCT_CODE 
		JOIN CMM01106 CMM (NOLOCK) ON CMD.CM_ID =CMM.CM_ID 
		WHERE CMM.CANCELLED =0
		GROUP BY A.PRODUCT_CODE
		UNION ALL
		SELECT A.PRODUCT_CODE ,
				SUM(IND.QUANTITY) AS SLS_QTY 
		FROM #TMPPUR A
		JOIN IND01106 IND (NOLOCK) ON A.PRODUCT_CODE =IND.PRODUCT_CODE 
		JOIN INM01106  INM (NOLOCK) ON IND.INV_ID =INM.INV_ID 
		WHERE INM.CANCELLED =0
		AND INM.INV_MODE =1
		GROUP BY A.PRODUCT_CODE
		union all
		SELECT A.PRODUCT_CODE ,
			SUM((-1)*cnd.QUANTITY) AS SLS_QTY 
		FROM #TMPPUR A
		JOIN cnd01106 cnd (NOLOCK) ON A.PRODUCT_CODE =cnd.PRODUCT_CODE 
		JOIN cnm01106  cnm (NOLOCK) ON cnd.cn_id =cnm.cn_id 
		WHERE cnm.CANCELLED =0
		AND cnm.mode =1
		GROUP BY A.PRODUCT_CODE
		) A
		GROUP BY A.PRODUCT_CODE
	) C ON  A.PRODUCT_CODE =C.PRODUCT_CODE 
	LEFT JOIN SKU_names sn(NOLOCK) ON C.PRODUCT_CODE=Sn.PRODUCT_CODE


	--select 'check tmppurdetails', * FROM #TMPPURdetails where pur_mrr_id='010112200000001-001369'
	
	
	UPDATE a SET cd_percentage=b.cd_percentage,cd_base_amount=b.cd_base_amount,due_date=b.due_dt
	FROM #TMPPURDETAILS a 	
	JOIN bill_by_bill_ref b (NOLOCK) ON a.REF_NO=b.REF_NO
	JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id  AND c.ac_code=a.ac_code
	JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
	JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id
	WHERE e.xn_type='PUR' AND d.cancelled=0

	---- Has to run following 3 steps in special case found at RoopKala 
	---- Where One Bill is partially adjusted in Debit note  and Cd_base_amount is zero and non zero 
	---- in two separate rows resulting in Duplicate rows insertion in the Table Bill_by_bill_inv_status
	---- and Bills start coming double in Ledger and Payment window (DAte:31-12-2021 Ticket#12-2360)

	UPDATE a SET cd_percentage=b.cd_percentage
	FROM #TMPPURDETAILS a 	
	JOIN #TMPPURDETAILS b ON a.pur_mrr_id=b.pur_mrr_id
	WHERE (ISNULL(a.cd_percentage,0)=0 AND ISNULL(b.cd_percentage,0)<>0)

	UPDATE a SET cd_base_amount=b.cd_base_amount
	FROM #TMPPURDETAILS a 	
	JOIN #TMPPURDETAILS b ON a.pur_mrr_id=b.pur_mrr_id
	WHERE (ISNULL(a.cd_base_amount,0)=0 AND ISNULL(b.cd_base_amount,0)<>0)
		
	UPDATE a SET due_date=b.due_date
	FROM #TMPPURDETAILS a 	
	JOIN #TMPPURDETAILS b ON a.pur_mrr_id=b.pur_mrr_id
	WHERE (ISNULL(a.cd_base_amount,0)=0 AND ISNULL(b.cd_base_amount,0)<>0)

		
	TRUNCATE TABLE bill_by_bill_inv_status


	INSERT bill_by_bill_inv_status	(pur_mrr_id,mrr_no,pur_total_amount,
	cr_days,due_date,pur_qty,prt_qty,SLS_QTY,SLS_PP,clearance_pct)
	SELECT  A.pur_mrr_id,a.mrr_no,a.pur_total_amount, datediff(dd,a.bill_dt,a.due_date) cr_days,
	a.due_date,a.PUR_QTY,a.PRT_QTY,a.SLS_QTY,a.sls_pp,
		CAST( CASE WHEN (NET_PUR_QTY)<>0 THEN 
				(ISNULL(A.SLS_QTY,0)*100)/(NET_PUR_QTY)
				ELSE 0 END AS NUMERIC(10,2)) AS CLEARENCE_PCT
	FROM
	(
	SELECT A.pur_mrr_ID,b.BILL_DT,b.mrr_no ,b.bill_no,a.cd_percentage,
			a.cd_base_amount,a.due_date,
			b.total_amount pur_total_amount,
			SUM(A.PUR_QTY) AS PUR_QTY,
			SUM(A.PRT_QTY) AS PRT_QTY,
			SUM(A.PUR_QTY-A.PRT_QTY) AS NET_PUR_QTY,
			SUM(A.SLS_QTY) AS SLS_QTY,
			SUM(ISNULL(SLS_COST_PRICE,0)) AS SLS_pp
	FROM #TMPPURDETAILS A
	JOIN pim01106 b (NOLOCK) ON b.mrr_id=a.pur_mrr_id
	GROUP BY A.pur_MRR_ID,b.bill_no,b.BILL_dt,mrr_no,a.cd_percentage,
	a.cd_base_amount,a.due_date,b.total_amount
	) A

END