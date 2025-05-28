CREATE PROCEDURE SP3SPAYMENTADVICE
(  
  @CVMID VARCHAR(40)=''  
)  
AS  
BEGIN


	 DECLARE @DVOUCHERDT DATETIME,@CPARTYACCODE CHAR(10),@CBankCashHeads VARCHAR(2000)
	   
	 
	SELECT @CBankCashHeads	=	DBO.FN_ACT_TRAVTREE( '0000000013' )
	SELECT @CBankCashHeads	=	@CBankCashHeads+','+dbo.FN_ACT_TRAVTREE('0000000014')
	SELECT @CBankCashHeads	=	@CBankCashHeads+','+dbo.FN_ACT_TRAVTREE('0000000022')
	 
	 SELECT @DVOUCHERDT=VOUCHER_DT FROM VM01106 WHERE VM_ID=@CVMID  
   
	IF OBJECT_ID('TEMPDB..#tmpLM','U') IS NOT NULL
		DROP TABLE TEMPDB..#tmpLM
	
	 SELECT  LM.AC_NAME,LMP.ADDRESS0,LMP.ADDRESS1,LMP.ADDRESS2,area.AREA_NAME,CITY.CITY,area.PINCODE,STATE,LMP.PHONES_R,LMP.PHONES_O,  
		LMP.PHONES_FAX,LMP.CST_NO,LMP.TIN_NO,CO.COMPANY_NAME,CO.ADDRESS1 AS CADDRESS1,CO.ADDRESS2 AS CADDRESS2,  
		co_area.area_name+' CITY - '+CO.CITY +', '+ 'STATE - '+CO.STATE +', '+ 'PIN - '+CO.PIN AS CCITY,  
		CO.PHONES_FAX AS CPHONES_FAX,CO.TIN_NO AS CTIN_NO,CO.CIN AS CCIN,CO.LOGO_PATH,BANK.BANK_NAME,  
		BANK.NARRATION,@DVOUCHERDT AS VOUCHER_DT,BANK.CREDIT_AMOUNT AS PAID_AMOUNT,CO.EMAIL_ID,LMP.Ac_gst_no,
		vm.VOUCHER_NO,bank.chq_no,bank.pay_mode,ISNULL(bank.chq_dt,vm.VOUCHER_DT) AS chq_dt,C.VD_ID
	INTO #tmpLM
	FROM LM01106 LM   
	 JOIN LMP01106 LMP ON LMP.AC_CODE=LM.AC_CODE  
	 JOIN VD01106 C  (NOLOCK) ON C.AC_CODE = LM.AC_CODE  
	 JOIN COMPANY CO (NOLOCK) ON CO.COMPANY_CODE='01'  
	 LEFT JOIN  area co_area (NOLOCK) ON co_area.area_code=co.area_code
	 JOIN AREA ON AREA.AREA_CODE=LMP.AREA_CODE  
	 JOIN CITY ON CITY.CITY_CODE=AREA.CITY_CODE  
	 JOIN vm01106 vm (NOLOCK) ON vm.vm_id=c.vm_id
	 LEFT OUTER JOIN 
	 (
		SELECT AC_NAME AS BANK_NAME,NARRATION,A.CREDIT_AMOUNT,
		(CASE WHEN chq_pay_mode=2 THEN 'Online' ELSE 'Cheque' END) pay_mode,ISNULL(cd.chq_leaf_no,online_chq_ref_no) chq_no,
		a.open_cheque_dt as  chq_dt
		FROM VD01106 A   
		JOIN LM01106 B ON A.AC_CODE=B.AC_CODE  
		LEFT JOIN  VD_CHQBOOK vc ON vc.vd_id=a.vd_id
		LEFT JOIN  ChqBook_D cd (NOLOCK) ON cd.row_id=vc.chqbook_row_id
		WHERE VM_ID=@CVMID AND ISNULL(ref_vd_id,'')='' AND 
		CHARINDEX(B.HEAD_CODE,@CBankCashHeads)>0 
	 )BANK ON 1=1
	 WHERE vm.VM_ID=@CVMID AND LMP.BILL_BY_BILL=1 
	 AND ISNULL(C.REF_VD_ID,'')=''
     

	 SELECT CAST(0 AS INT) AS SR_NO ,CAST('' AS VARCHAR(100)) AS AC_NAME,CAST('' AS VARCHAR(100)) AS VD_ID,CAST('' AS VARCHAR(100)) AS REF_VD_ID
	 INTO #tmpLM_DUP
	 WHERE 1=2
	 if (SELECT COUNT(*) FROM #tmpLM GROUP BY AC_NAME HAVING COUNT(*)>1)>0           
	 BEGIN
		;WITH DUPLICATE_LM
		AS
		(
			SELECT ROW_NUMBER() OVER (PARTITION BY AC_NAME ORDER BY AC_NAME) AS SR_NO , AC_NAME,VD_ID,VD_ID AS REF_VD_ID FROM #tmpLM
		)
		INSERT INTO #tmpLM_DUP(SR_NO , AC_NAME,VD_ID,REF_VD_ID)
		SELECT SR_NO , AC_NAME,VD_ID,REF_VD_ID
		FROM DUPLICATE_LM
		WHERE SR_NO>1

		DELETE FROM #tmpLM WHERE vd_id in (SELECT VD_ID FROM #tmpLM_DUP)	
		
		UPDATE a SET ref_vd_id=b.VD_ID
		FROM #tmpLM_DUP  a
		JOIN #tmpLM b ON b.AC_NAME=a.AC_NAME
	 END
	 
	


	select b.ac_code,a.ref_no bb_ref_no, (CASE WHEN  ISNULL(org_bill_no,'')='' THEN  a.ref_no else org_bill_no END) org_bill_no,
	(CASE WHEN ISNULL(org_bill_dt,'')='' THEN c.voucher_dt else org_bill_dt END) org_bill_dt,
	SUM(CASE WHEN ISNULL(ref_vd_id,'')<>'' THEN 0 WHEN ISNULL(org_bill_amount,0)=0 THEN amount else  org_bill_amount end) org_bill_amount ,
	CONVERT(NUMERIC(10,2),0) balance_amount,
	SUM(case when a.x_type='Dr' then amount else 0 end) debit_amount,
	SUM(case when a.x_type='Cr' then amount else 0 end) credit_amount,
	SUM(CASE WHEN ISNULL(ref_vd_id,'')<>'' THEN 0 ELSE cd_base_amount END) cd_base_amount,
	CONVERT(NUMERIC(6,2),0) cd_percentage,SUM(cd_amount) cd_amount,
	SUM(CASE WHEN a.x_type='Dr' THEN amount---(CASE WHEN ISNULL(cd_posted,0)<>1 THEN cd_amount ELSE 0 END) 
			  ELSE -amount--+(CASE WHEN ISNULL(cd_posted,0)<>1 THEN cd_amount ELSE 0 END) 
			  END) paid_amount,
	(case when a.x_type='Dr' THEN 'PUR' Else 'D/N' END) type,a.vd_id,convert(numeric(10,2),0) tds_amount,
	(CASE WHEN a.x_type='Dr' THEN 'Cr' ELSE 'Dr' END) org_x_type,PUR_VENDOR_BILL_DT
	INTO #tmpBB
	from  bill_by_bill_ref a 
	join vd01106 b on a.vd_id=b.vd_id
	JOIN vm01106 c (NOLOCK) ON c.vm_id=b.vm_id
	where b.vm_id=@cVmId AND ISNULL(b.ref_vd_id,'')=''
	GROUP BY b.ac_code,a.ref_no,(CASE WHEN  ISNULL(org_bill_no,'')='' THEN  a.ref_no else org_bill_no END),
	(CASE WHEN ISNULL(org_bill_dt,'')='' THEN c.voucher_dt else org_bill_dt END),
	(case when a.x_type='Dr' THEN 'PUR' Else 'D/N' END),a.VD_ID,
	(CASE WHEN a.x_type='Dr' THEN 'Cr' ELSE 'Dr' END),PUR_VENDOR_BILL_DT


	UPDATE #tmpBB SET org_bill_amount=org_bill_amount*-1,cd_base_amount=cd_base_amount*-1,cd_amount=cd_amount*-1
	WHERE org_x_type='DR'

	UPDATE  a SET cd_percentage=b.cd_percentage 
	FROM #tmpBB a
	JOIN bill_by_bill_ref b ON a.bb_ref_no=b.ref_no
	JOIN  vd01106 c (NOLOCK) ON c.vd_id=b.vd_id
	WHERE c.vm_id=@cVmId AND ISNULL(c.ref_vd_id,'')='' 

	UPDATE  a SET tds_amount=b.pur_tds_amount
	FROM #tmpBB a
	JOIN bill_by_bill_ref b ON a.bb_ref_no=b.ref_no
	JOIN  vd01106 c (NOLOCK) ON c.vd_id=b.vd_id AND c.AC_CODE=a.AC_CODE
	JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
	WHERE ISNULL(b.pur_tds_amount,0)<>0 AND d.cancelled=0

	SELECT a.org_bill_no,(CASE WHEN ISNULL(b.org_bill_no,'')='' THEN voucher_no ELSE b.org_bill_no END) adj_memo_no,voucher_dt, (CASE WHEN b.x_type='Cr' THEN amount ELSE 0 END) credit_amount,
	(CASE WHEN b.x_type='Dr' THEN amount ELSE 0 END) debit_amount,c.narration,CONVERT(VARCHAR(200),ISNULL(b.adj_remarks,'')) vs_ac_name,
	c.vd_id ,a.vd_id AS ref_vd_id ,c.ac_code,bb_ref_no,a.org_x_type
	INTO #tmpbbHist 
	FROM  #tmpbb a
	JOIN bill_by_bill_ref b (NOLOCK) ON a.bb_ref_no=b.ref_no
	JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id AND c.ac_code=a.ac_code-- AND a.VD_ID=c.REF_VD_ID
	JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
	WHERE voucher_dt<=@DVOUCHERDT AND d.vm_id<>@CVMID AND d.cancelled=0

	--select * from #tmpbbHist

	UPDATE a SET vs_ac_name=lm.ac_name 
	FROM  #tmpbbHist a
	JOIN vd01106 b (NOLOCK) ON b.ref_vd_id=a.ref_vd_id 
	JOIN  lm01106 lm (NOLOCK) ON lm.ac_code=b.ac_code
	WHERE lm.ac_code<>a.ac_code --AND isnull(a.ref_vd_id,'')<>''


	UPDATE  a SET balance_amount=b.balance_amount FROM  #tmpBB a
	JOIN  
	(
		SELECT bb_ref_no,SUM(credit_amount-debit_amount) balance_amount 
		FROM #tmpbbHist 
		GROUP BY bb_ref_no
	)b ON a.bb_ref_no=b.bb_ref_no


	UPDATE a SET vd_id=b.REF_VD_ID
	FROM #tmpBB  a
	JOIN #tmpLM_DUP b ON b.VD_ID=a.VD_ID

	UPDATE a SET a.ref_vd_id=b.REF_VD_ID
	FROM #tmpbbHist  a
	JOIN #tmpLM_DUP b ON b.VD_ID=a.VD_ID


	select * from #tmpLM
	
	SELECT * FROM #tmpBB
	order by org_bill_dt,org_bill_no,org_bill_amount desc

	SELECT org_bill_no,adj_memo_no,voucher_dt,credit_amount,debit_amount,narration,vs_ac_name,ref_vd_id as vd_id FROM #tmpBBHist
	order by voucher_dt,org_bill_no,(CASE WHEN org_x_type='Cr' THEN debit_amount ELSE credit_amount END)

	IF EXISTS(SELECT 'U' FROM SYS.TABLES WHERE NAME ='TPAYMENTADVICE' AND DATEDIFF(d,create_date,getdate())<>0)
  		DROP TABLE TPAYMENTADVICE

	IF  OBJECT_ID('TPAYMENTADVICE','U') IS NULL	
	BEGIN
		select * 
		INTO TPAYMENTADVICE
		from #tmpLM
		WHERE 1=2
   END

   IF EXISTS(SELECT 'U' FROM SYS.TABLES WHERE NAME ='TPAYMENTADVICE1' AND DATEDIFF(d,create_date,getdate())<>0)
  		DROP TABLE TPAYMENTADVICE1

	IF  OBJECT_ID('TPAYMENTADVICE1','U') IS NULL	
	BEGIN
		select * 
		INTO TPAYMENTADVICE1
		from #tmpBB
		WHERE 1=2
   END

   IF EXISTS(SELECT 'U' FROM SYS.TABLES WHERE NAME ='TPAYMENTADVICE2' AND DATEDIFF(d,create_date,getdate())<>0)
  		DROP TABLE TPAYMENTADVICE2

	IF  OBJECT_ID('TPAYMENTADVICE2','U') IS NULL	
	BEGIN
		select * 
		INTO TPAYMENTADVICE2
		from #tmpBBHist
		WHERE 1=2
   END

ENDPROC:  
  
END  
--END OF PROCEDURE - SP3SPAYMENTADVICE
