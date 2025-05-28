CREATE PROCEDURE SP3S_BILL_BY_BILL_VCHADJ --(LocId 3 digit change by Sanjay:04-11-2024)
(
 @CAC_CODE VARCHAR(20)='',
 @CVMID VARCHAR(40)='',
 @nUpdateMode NUMERIC(1,0)=0,
 @cCompanyPanNo	VARCHAR(50)='',
 @bSHowOnAccountEntries BIT=0,
 @bShowCdBasedEntriesOnly BIT=0
)
AS
BEGIN
  
   		SELECT DEPT_ID INTO #TMPLOCLIST FROM LOCATION WHERE 1=2
		
		IF OBJECT_ID('TEMPDB..#TMPBB','U') IS NOT NULL
			DROP TABLE #TMPBB
		
		INSERT #TMPLOCLIST
		SELECT DEPT_ID FROM location (NOLOCK) WHERE SUBSTRING(loc_gst_no,3,10)=@cCompanyPanNo
		
		SELECT @CAC_CODE AS AC_CODE,AC_NAME,REF_NO AS DISPLAY_REF_NO,
					CONVERT(VARCHAR(40),'') AS VD_ID,REF_NO,ABS(AMOUNT) AS AMOUNT,ABS(AMOUNT_forex) AS AMOUNT_forex,
					GETDATE() AS LAST_UPDATE,(CASE WHEN AMOUNT>0 THEN 'DR' ELSE 'CR' END) AS X_TYPE,
					CONVERT(INT,0) AS CR_DAYS,CONVERT(VARCHAR(100),'') AS REMARKS,CONVERT(VARCHAR(100),'') AS ADJ_REMARKS,
					CONVERT(VARCHAR(50),NEWID()) AS BB_ROW_ID,convert(bit,0) cd_posted,
					CONVERT(VARCHAR(40),'') AS VM_ID,CONVERT(BIT,0) AS SELECTED,a.ADJ_AMT,a.ADJ_AMT_forex,
					A.CREDIT_AMOUNT,A.DEBIT_AMOUNT,A.CREDIT_AMOUNT_forex,A.DEBIT_AMOUNT_forex,CONVERT(DATE,'') as due_date,CONVERT(VARCHAR(40),'') PUR_MRR_ID,
					convert(varchar(4),'') cost_center_dept_id,CONVERT(NUMERIC(10,2),0) cd_base_amount,
					CONVERT(NUMERIC(6,2),0) cd_percentage,CONVERT(NUMERIC(10,2),0) cd_amount,
					convert(date,'') bill_dt,convert(int,0) over_due_days,CONVERT(NUMERIC(10,2),0) pur_total_amount,
					convert(varchar(100),'') org_bill_no,convert(date,'') org_bill_dt,convert(numeric(14,2),0) org_bill_amount,
					CONVERT(NUMERIC(10,2),0) ignore_cd_base_amount,CONVERT(NUMERIC(14,2),0) prev_adj_amt,convert(datetime,'') PUR_VENDOR_BILL_DT,
					convert(numeric(10,2),0) org_bill_taxable_value

		INTO #TMPADJBILLS
		FROM 
		(
		SELECT AC_NAME,A.REF_NO,SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT ELSE -A.AMOUNT END)-isnull(e.adj_amt,0) AS AMOUNT
		,SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT_forex ELSE -A.AMOUNT_forex END)-isnull(e.adj_amt_forex,0) AS AMOUNT_forex
		,SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT ELSE 0 END) AS DEBIT_AMOUNT
		,SUM(CASE WHEN A.X_TYPE='CR' THEN A.AMOUNT ELSE 0 END) AS CREDIT_AMOUNT
		,SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT_forex ELSE 0 END) AS DEBIT_AMOUNT_forex
		,SUM(CASE WHEN A.X_TYPE='CR' THEN A.AMOUNT_forex ELSE 0 END) AS CREDIT_AMOUNT_forex
		,ISNULL(e.adj_amt,0) ADJ_AMT,ISNULL(e.adj_amt_forex,0) ADJ_AMT_forex
		FROM BILL_BY_BILL_REF A (NOLOCK)    
		JOIN VD01106 C (NOLOCK) ON A.VD_ID=C.VD_ID   
		JOIN VM01106 D (NOLOCK) ON C.VM_ID=D.VM_ID   
		JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE
		JOIN #TMPLOCLIST l ON l.dept_id=c.cost_center_dept_id
		LEFT JOIN 
		(SELECT b.ac_code,a.ref_no,SUM(CASE WHEN a.x_type='Dr' THEN a.amount ELSE a.amount*-1 END) adj_amt
		,SUM(CASE WHEN a.x_type='Dr' THEN a.amount_forex ELSE a.amount_forex*-1 END) adj_amt_forex FROM bill_by_bill_ref a (NOLOCK)
		JOIN vd01106 b (NOLOCK) ON a.VD_ID=b.VD_ID
		JOIN VM01106 c (NOLOCK) ON c.VM_ID=b.vm_id
		WHERE b.VM_ID=@CVMID group by b.ac_code,A.REF_NO) e ON e.ref_no=a.ref_no AND e.AC_CODE=c.AC_CODE
		WHERE c.ac_code=@CAC_CODE AND d.cancelled=0
		GROUP BY AC_NAME,A.REF_NO,isnull(e.adj_amt,0),isnull(e.adj_amt_forex,0)
		HAVING ABS(SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT ELSE -A.AMOUNT END))>0 OR sum(ISNULL(e.adj_amt,0))<>0
		) A			 
		--- Changed this code as Ticket of  Greenways #09-2129 (Bills with paise not coming in Payment windwow)
		--- HAVING ABS(SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT ELSE -A.AMOUNT END))>=1

	   IF @bSHowOnAccountEntries=0
		   DELETE a   FROM #TMPADJBILLS A  
		   JOIN BILL_BY_BILL_REF B ON A.REF_NO=B.REF_NO  
		   JOIN VD01106 C ON C.VD_ID=B.VD_ID AND C.AC_CODE=A.AC_CODE  
		   JOIN lm01106 d ON d.ac_code=c.ac_code
		   JOIN vm01106 e (NOLOCK) ON e.vm_id=c.vm_id
		   JOIN  location loc (NOLOCK) ON loc.dept_ac_code=c.ac_code
		   WHERE loc.sor_loc=1 AND b.on_account=1 AND e.cancelled=0
		
		DECLARE @CDEBTORHEADS VARCHAR(MAX),@CCREDITORHEADS VARCHAR(MAX),@cHeadCode CHAR(10)

		SELECT TOP 1 @cHeadCode=head_code FROM lm01106 (NOLOCK) WHERE ac_code=@CAC_CODE

		SELECT @CDEBTORHEADS = DBO.FN_ACT_TRAVTREE( '0000000018' ),  
		@CCREDITORHEADS = DBO.FN_ACT_TRAVTREE( '0000000021' )   

		UPDATE #TMPADJBILLS SET prev_adj_amt=(CASE WHEN x_type='Dr'	THEN credit_amount else debit_amount END)

		UPDATE a SET cd_posted=isnull(b.cd_posted,0),due_date=b.due_dt,
		CR_DAYS=(CASE WHEN ISNULL(b.due_dt,'')<>'' THEN datediff(dd,d.VOUCHER_DT,b.due_dt) ELSE b.CR_DAYS END),
		cost_center_dept_id=c.cost_center_dept_id,cd_base_amount=b.cd_base_amount,cd_percentage=b.cd_percentage,
		cd_amount=(CASE WHEN b.cd_posted=0 AND b.Cd_base_amount>0 AND b.Cd_percentage>0 AND ISNULL(b.org_bill_amount,0)<>0
						THEN round(((a.amount+isnull(b.ignore_cd_base_amount,0))/b.org_bill_amount)*b.Cd_base_amount*b.Cd_percentage/100,0)
				        ELSE round(b.cd_base_amount*b.Cd_percentage/100,2) END),
		ignore_cd_base_amount=ISNULL(b.ignore_cd_base_amount,0),
		over_due_days=DATEDIFF(dd,b.due_dt,convert(date,getdate())),org_bill_amount=b.org_bill_amount,org_bill_dt=b.org_bill_dt,
		org_bill_no=b.org_bill_no
		FROM #TMPADJBILLS a
		JOIN bill_by_bill_ref b (NOLOCK) ON a.REF_NO=b.REF_NO
		JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id AND a.ac_code=c.ac_code
		JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
		LEFT JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id AND e.XN_TYPE='PUR'
		WHERE d.cancelled=0
		/*Rohit 26-12-2024 
			#1045 Bigshop Ranchi - Payment Advise Problem 
			#1023 Tkt.1224-01633 BIGSHOP RANCHI Payment advoice wrong ref dt
			AND a.x_type='Cr' AND b.x_type='Cr' 
		*/ 
		AND e.MEMO_ID IS NULL
		
		print 'update cd amount for pur'
		UPDATE a SET pur_mrr_id=e.memo_id,cd_posted=isnull(b.cd_posted,0),due_date=b.due_dt,
		CR_DAYS=(CASE WHEN ISNULL(b.due_dt,'')<>'' THEN datediff(dd,d.VOUCHER_DT,b.due_dt) ELSE b.CR_DAYS END),
		cost_center_dept_id=c.cost_center_dept_id,cd_base_amount=b.cd_base_amount,cd_percentage=b.cd_percentage,
		cd_amount=(CASE WHEN b.cd_posted=0 AND b.Cd_base_amount>0 AND b.Cd_percentage>0 
						THEN round(((a.amount+ISNULL(i.ignore_cd_base_amount,0))/(CASE WHEN ISNULL(b.org_bill_amount,0)=0 
						THEN pim.total_amount ELSE b.org_bill_amount END))*b.Cd_base_amount*b.Cd_percentage/100,0)
				        ELSE round(b.cd_base_amount*b.Cd_percentage/100,2) END),
		ignore_cd_base_amount=ISNULL(i.ignore_cd_base_amount,0),
		pur_total_amount=pim.total_amount,bill_dt=pim.bill_dt,org_bill_taxable_value=b.org_bill_taxable_value,
		over_due_days=DATEDIFF(dd,b.due_dt,convert(date,getdate())),
		org_bill_no=pim.bill_no,org_bill_dt=pim.bill_dt,org_bill_amount=b.org_bill_amount,PUR_VENDOR_BILL_DT=b.PUR_VENDOR_BILL_DT
		FROM #TMPADJBILLS a
		JOIN bill_by_bill_ref b (NOLOCK) ON a.REF_NO=b.REF_NO
		JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id  AND c.ac_code=a.ac_code
		JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
		JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id
		JOIN pim01106 pim (NOLOCK) ON pim.mrr_id=e.memo_ID
		LEFT JOIN 
		(SELECT b.ac_code,a.ref_no,SUM(ISNULL(a.ignore_cd_base_amount,0)) ignore_cd_base_amount FROM bill_by_bill_ref a (NOLOCK)
		 JOIN vd01106 b (NOLOCK) ON a.vd_id=b.vd_id
		 JOIN vm01106 c (NOLOCK) ON c.vm_id=b.vm_id
		 JOIN #TMPADJBILLS d ON d.ref_no=a.ref_no AND d.AC_CODE=b.AC_CODE
		 JOIN postact_voucher_link e (NOLOCK) ON e.vm_id=c.vm_id
		 WHERE cancelled=0 AND e.XN_TYPE='PUR' AND ISNULL(a.ignore_cd_base_amount,0)<>0
		 GROUP BY b.ac_code,a.REF_NO) i ON i.REF_NO=a.REF_NO AND i.AC_CODE=a.AC_CODE
		WHERE e.xn_type='PUR' AND d.cancelled=0 AND b.x_type='Cr'

		print 'update cd amount for other than pur'
		UPDATE a SET cost_center_dept_id=c.cost_center_dept_id,cd_posted=ISNULL(b.cd_posted,0),
		bill_dt=d.voucher_dt,cd_base_amount=b.cd_base_amount,cd_percentage=b.cd_percentage,
		cd_amount=(CASE WHEN b.cd_posted=0 THEN ROUND((a.amount/ISNULL(rmm.total_amount,inm.net_amount))*b.Cd_base_amount*b.Cd_percentage/100,0)
					    ELSE ROUND(b.Cd_base_amount*b.Cd_percentage/100,2) END),
		pur_total_amount=rmm.total_amount,due_date=d.VOUCHER_DT,
		org_bill_no=b.org_bill_no,org_bill_dt=b.org_bill_dt,org_bill_amount=b.org_bill_amount,org_bill_taxable_value=b.org_bill_taxable_value
		FROM #TMPADJBILLS a
		JOIN bill_by_bill_ref b (NOLOCK) ON a.REF_NO=b.REF_NO
		JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id  AND c.ac_code=a.ac_code
		JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
		LEFT JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id
		LEFT JOIN rmm01106 rmm (NOLOCK) ON rmm.rm_id=e.memo_id
		LEFT JOIN inm01106 inm (NOLOCK) ON inm.inv_id=e.memo_id
		WHERE d.cancelled=0 AND ISNULL(e.xn_type,'') IN ('WSL','PRT')
		AND ISNULL(a.org_bill_no,'')=''

		--if @@spid=428
		--	select 'check tmpadjbills', * from #tmpadjbills
		
		print 'update bb row_id'
		UPDATE A SET BB_ROW_ID=(SELECT TOP 1 b.BB_ROW_ID FROM BILL_BY_BILL_REF B
								  JOIN VD01106 C ON C.VD_ID=B.VD_ID	
								  JOIN VM01106 D ON D.VM_ID=C.VM_ID
								  JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE
								  WHERE B.REF_NO=A.REF_NO AND C.AC_CODE=A.AC_CODE
								  AND CANCELLED=0
								  ORDER BY VOUCHER_DT
								 ) FROM  #TMPADJBILLS A
		WHERE isnull(bill_dt,'')=''

		UPDATE a SET DUE_DATE= (CASE WHEN isnull(b.due_dt,'')='' THEN  DATEADD(DAY,b.CR_DAYS,d.voucher_dT) ELSE b.due_dt END) ,
		CR_DAYS=(CASE WHEN ISNULL(b.due_dt,'')<>'' THEN datediff(dd,d.VOUCHER_DT,b.due_dt) ELSE b.CR_DAYS END),
		bill_dt=d.voucher_dt,cd_base_amount=b.cd_base_amount,pur_total_amount=(CASE WHEN ISNULL(pur_total_amount,0)=0
		THEN B.cd_base_amount ELSE pur_total_amount END),cost_center_dept_id=c.cost_center_dept_id,
		org_bill_amount=(CASE WHEN isnull(a.org_bill_amount,0)=0 THEN b.cd_base_amount ELSE a.org_bill_amount END)
		FROM #TMPADJBILLS a JOIN bill_by_bill_ref b ON a.bb_row_id=b.bb_row_id
		JOIN vd01106 c ON c.vd_id=b.vd_id
		JOIN  vm01106 d ON d.vm_id=c.vm_id

		UPDATE #TMPADJBILLS SET bb_row_id=newid(),display_ref_no=(CASE WHEN ISDATE(RIGHT(REF_NO,8))=1 AND 
		SUBSTRING(REVERSE(REF_NO),9,1)='/' THEN LEFT(REF_NO,LEN(REF_NO)-9) ELSE DISPLAY_REF_NO END)

		SELECT x_type as type,
		(a.amount-(CASE WHEN ISNULL(cd_posted,0)=0 AND ISNULL(a.cd_amount,0)<>0 THEN a.cd_amount ELSE 0 END)) as net_amt, 
		a.*,b.pur_qty,prt_qty,SLS_QTY,SLS_PP,clearance_pct,loc.dept_id+'-'+dept_name as dept_name,CONVERT(BIT,0) manual_cd,
		a.display_ref_no bill_no,a.prev_adj_amt,a.PUR_VENDOR_BILL_DT
		FROM #TMPADJBILLS a
		LEFT JOIN bill_by_bill_inv_status b ON a.PUR_MRR_ID=b.pur_mrr_id
		LEFT JOIN location loc (NOLOCK) ON loc.dept_id=a.cost_center_dept_id
		WHERE (@bShowCdBasedEntriesOnly=0 or a.org_bill_taxable_value<>0)
		--(Pending Bill amount/Actual Bill amlount)*Cd_base_amount*Cd_pct/100
END