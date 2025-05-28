create PROCEDURE SP3S_REP_TDSLIST
@dFromDt DATETIME,
@dToDt DATETIME
AS
BEGIN

		select a.receipt_id ,sum( isnull(igst_amount,0)+isnull(cgst_amount,0)+isnull(sgst_amount,0)) as Gst_amount 
		    into #tmpRecGst
		from jobwork_receipt_mst a (NOLOCK)
		join jobwork_receipt_det b (NOLOCK) on a.receipt_id=b.receipt_id
		WHERE challan_dt BETWEEN @dFromDt AND @dToDt AND ISNULL(a.tds,0)<>0 AND A.cancelled=0
		group by a.receipt_id 

	SELECT CONVERT(VARCHAR(5),'PUR') xn_type,mrr_id memo_id,
	(CASE WHEN ISNULL(xn_item_type,1) IN (0,1) 
	THEN COALESCE(cmp1.company_name,cmp2.company_name,b.dept_name)
	ELSE COALESCE(cmp3.company_name,cmp4.company_name,e.dept_name) END) AS [Company_Name],
	(CASE WHEN ISNULL(xn_item_type,1) IN (0,1) THEN COALESCE(cmp1.pan_no,cmp2.pan_no)
		  ELSE  COALESCE(cmp3.pan_no,cmp4.pan_no) END) 	[Company_Pan_no],ac_name,
	(CASE WHEN ISNULL(ac_gst_no,'')<>'' THEN substring(ac_gst_no,3,10) ELSE d.pan_no END)  as [Party_Pan_No],
	TDS_Name [TDS_Section],bill_dt [Date],bill_no [Bill_no],total_amount [Bill_Amount],
	(CASE WHEN ISNULL(a.tds_amount,0)<>0 THEN  (subtotal-discount_amount) ELSE a.GOODS_TDS_BASEAMOUNT END) AS [TDS_Applicable_Amount],
	(CASE WHEN ISNULL(a.tds_amount,0)<>0 THEN ts.TDS_Percentage ELSE a.GOODS_TDS_PERCENTAGE END) [TDS_Pct],
	isnull(tds_amount,0)+isnull(GOODS_TDS_AMOUNT,0) [TDS_Amt],
	0 Edu_Cess,(isnull(tds_amount,0)+isnull(GOODS_TDS_AMOUNT,0)) Total_TDS
	FROM  pim01106 a (NOLOCK)
	JOIN location b (NOLOCK) ON a.dept_id=b.dept_id
	LEFT JOIN location e (NOLOCK) ON e.dept_id=a.Pur_For_Dept_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN lmp01106 d (NOLOCK) ON d.ac_code=a.ac_code
	LEFT JOIN TDS_Section ts (NOLOCK) ON ts.tds_code=a.tds_code
	LEFT JOIN loc_accounting_company cmp1 (NOLOCK) ON cmp1.pan_no=SUBSTRING(b.loc_gst_no,3,10)
	LEFT JOIN loc_accounting_company cmp2 (NOLOCK) ON cmp2.pan_no=b.pan_no
	LEFT JOIN loc_accounting_company cmp3 (NOLOCK) ON cmp3.pan_no=SUBSTRING(e.loc_gst_no,3,10)
	LEFT JOIN loc_accounting_company cmp4 (NOLOCK) ON cmp4.pan_no=e.pan_no
	WHERE bill_challan_mode=0 AND A.CANCELLED =0 AND bill_dt BETWEEN @dFromDt AND @dToDt AND (ISNULL(a.tds_amount,0)+ISNULL(a.goods_tds_amount,0))<>0

	UNION ALL
	SELECT CONVERT(VARCHAR(5),'JWR') xn_type,a.receipt_id memo_id,COALESCE(cmp1.company_name,cmp2.company_name,dept_name)  [Company Name],
	COALESCE(cmp1.pan_no,cmp2.pan_no,d.pan_no) [Company Pan no],ac_name,
	(CASE WHEN ISNULL(ac_gst_no,'')<>'' THEN substring(ac_gst_no,3,10) ELSE d.pan_no END)  as [Party Pan No],
	TDS_Name [TDS Section],challan_dt [Date],challan_no [Bill no],net_amount [Bill Amount],
	(net_amount-(det.Gst_amount)) [TDS Applicable Amount],ts.TDS_Percentage [TDS %],tds [TDS Amt],
	0 Edu_Cess,tds Total_TDS
	FROM  jobwork_receipt_mst a (NOLOCK)
	join #tmpRecGst det on a.receipt_id =det.receipt_id 
	JOIN location b (NOLOCK) ON a.location_Code =b.dept_id
	JOIN prd_agency_mst pam (NOLOCK) ON pam.agency_code=a.agency_code
	JOIN lm01106 c (NOLOCK) ON c.ac_code=pam.ac_code
	JOIN lmp01106 d (NOLOCK) ON d.ac_code=pam.ac_code
	JOIN TDS_Section ts (NOLOCK) ON ts.tds_code=a.tds_code
	LEFT JOIN loc_accounting_company cmp1 (NOLOCK) ON cmp1.pan_no=SUBSTRING(b.loc_gst_no,3,10)
	LEFT JOIN loc_accounting_company cmp2 (NOLOCK) ON cmp2.pan_no=b.pan_no
	WHERE challan_dt BETWEEN @dFromDt AND @dToDt AND ISNULL(a.tds,0)<>0 AND A.cancelled=0

	UNION ALL
	SELECT CONVERT(VARCHAR(5),'JRNL') xn_type,'' memo_id,COALESCE(cmp1.company_name,cmp2.company_name,dept_name)  [Company Name],
	COALESCE(cmp1.pan_no,cmp2.pan_no,l.pan_no) [Company Pan no],ac_name,
	(CASE WHEN ISNULL(ac_gst_no,'')<>'' THEN substring(ac_gst_no,3,10) ELSE lmp.pan_no END)  as [Party Pan No],
	TDS_Name [TDS Section],d.voucher_dt [Date],d.voucher_no [Bill no],
	((CASE WHEN C.DEBIT_AMOUNT>0 THEN -1 ELSE 1 END )*ISNULL(a.tds_bill_amount,0)) as [Bill Amount],
	((CASE WHEN C.DEBIT_AMOUNT>0 THEN -1 ELSE 1 END )*ISNULL(a.tds_applicable_amount,0)) [TDS Applicable Amount],
	a.tds_per [TDS %],
	(CASE WHEN C.DEBIT_AMOUNT>0 THEN -1 ELSE 1 END )*a.tds_amt [TDS Amt],edu_amt Edu_Cess,
	((CASE WHEN C.DEBIT_AMOUNT>0 THEN -1 ELSE 1 END )*(a.tds_amt+edu_amt)) Total_TDS

	FROM VDT01106 a (NOLOCK)
	JOIN TDS_SECTION b (NOLOCK) ON a.tds_code=b.tds_code 
	JOIN vd01106 c (NOLOCK) ON a.vd_id=c.vd_id 
	JOIN VM01106 d (NOLOCK) ON c.vm_id=d.vm_id 
	JOIN LM01106 e (NOLOCK) ON c.ac_code=e.ac_code 
	LEFT OUTER JOIN LMP01106 lmp (NOLOCK) ON lmp.ac_code=e.ac_code 
	LEFT OUTER JOIN  POSTACT_VOUCHER_LINK vl (NOLOCK) ON vl.vm_id=d.vm_id
	JOIN location l ON l.dept_id=c.cost_center_dept_id  
	LEFT JOIN loc_accounting_company cmp1 (NOLOCK) ON cmp1.pan_no=SUBSTRING(l.loc_gst_no,3,10)
	LEFT JOIN loc_accounting_company cmp2 (NOLOCK) ON cmp2.pan_no=l.pan_no
	WHERE d.CANCELLED =0  AND d.Voucher_dt between @dFromDt and @dToDt
	AND vl.vm_id IS NULL AND ISNULL(a.tds_amt,0)<>0

	ORDER BY [Company_Name],[tds_section]
	--UPDATE a SET [GST AMOUNT]=b.gst_amount FROM #tmpTdsRep a
	--JOIN (SELECT mrr_id,sum(igst_amount+cgst_amount+sgst_amount) gst_amount FROM  pid01106 a (NOLOCK)
	--	  JOIN #tmpTdsRep b ON a.mrr_id=b.memo_id
	--	  WHERE xn_type='PUR' GROUP BY mrr_id) b ON a.memo_id=b.mrr_id
	--WHERE xn_type='PUR'

	--UPDATE a SET [GST AMOUNT]=b.gst_amount FROM #tmpTdsRep a
	--JOIN (SELECT receipt_id,sum(igst_amount+cgst_amount+sgst_amount) gst_amount FROM  jobwork_receipt_det a (NOLOCK)
	--	  JOIN #tmpTdsRep b ON a.receipt_id=b.memo_id
	--	  WHERE xn_type='JWR' GROUP BY receipt_id) b ON a.memo_id=b.receipt_id
	--WHERE xn_type='JWR'
	
--	SELECT * FROM  #tmpTdsRep
END
