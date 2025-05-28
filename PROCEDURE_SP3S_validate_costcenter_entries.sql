CREATE PROCEDURE SP3S_VALIDATE_COSTCENTER_ENTRIES--(LocId 3 digit change by Sanjay:26-11-2024 left changes by concerned developer)
@NMODE NUMERIC(1,0),
@NSPID varchar(50)='',
@CVMID VARCHAR(50)='',
@BsKIPeRROR BIT=0,
@CERRORMSG VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @NCNT INT,@CCMD NVARCHAR(MAX),@BLOOP BIT,@CSTEP VARCHAR(4),@cVmLocId VARCHAR(4),@cCostCenterDeptId VARCHAR(4),
	@cVmCostCenterAcCode CHAR(10),@cCostCenterAcCode CHAR(10),@nHoAmount NUMERIC(20,2)
	
BEGIN TRY	
	SET @CSTEP='10'
	
	SET @CERRORMSG=''
	
	IF @NMODE=1
		SET @CCMD=N'SELECT @NCNT=COUNT(DISTINCT COST_CENTER_DEPT_ID) FROM VCH_VD01106_UPLOAD (nolock)
					WHERE sp_id='''+LTRIM(RTRIM(@NSPID))+''''
	ELSE
		SET @CCMD=N'SELECT @NCNT=COUNT(DISTINCT COST_CENTER_DEPT_ID) FROM VD01106 (NOLOCK) WHERE VM_ID='''+@CVMID+''''
	
	SET @CSTEP='15'
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD,N'@NCNT INT OUTPUT',@NCNT=@NCNT OUTPUT
	
	IF @nMode=2
	BEGIN
		SET @CSTEP='16'
		DELETE FROM VD01106 WITH (ROWLOCK) WHERE VM_ID=@CVMID AND ISNULL(autoentry,0)=1
	END	

	IF @NCNT=1
		RETURN

	
	SET @CSTEP='18'
	DECLARE @tValidate TABLE (ac_code CHAR(10))
	
	IF @NMODE=1
		SET @CCMD=N'SELECT a.ac_code FROM VCH_VD01106_UPLOAD A (NOLOCK) 
					JOIN location b (NOLOCK) ON a.ac_code=b.dept_ac_code
					WHERE SP_ID='''+LTRIM(RTRIM(@NSPID))+''''
	ELSE
		SET @CCMD=N'SELECT a.ac_code FROM VD01106 a (NOLOCK) 
					JOIN location b (NOLOCK) ON a.ac_code=b.dept_ac_code
					WHERE VM_ID='''+@CVMID+''''
	
	PRINT @CCMD
	
	SET @CSTEP='20'
	INSERT @tValidate (ac_code)
	EXEC SP_EXECUTESQL @CCMD
	
	DELETE  FROM @tValidate
	
	SET @CSTEP='35'
	
	IF @NMODE=1
		SELECT TOP 1 @cCostCenterDeptId=a.cost_center_dept_id FROM VCH_VD01106_UPLOAD A (NOLOCK)
					JOIN location b (NOLOCK) ON a.cost_center_dept_id=b.dept_id
					WHERE SP_ID=@NSPID AND b.dept_ac_code='0000000000'
	ELSE
		SELECT TOP 1 @cCostCenterDeptId=a.cost_center_dept_id FROM VD01106 a (NOLOCK) 
					JOIN location b (NOLOCK) ON a.cost_center_dept_id=b.dept_id
					WHERE VM_ID=@CVMID AND b.dept_ac_code='0000000000'
	
	IF ISNULL(@cCostCenterDeptId,'')<>''
	BEGIN
		SET @CSTEP='45'
		SET @CERRORMSG=STR(@NMODE)+':Blank a/c found against Cost Center LocId:'+@cCostCenterDeptId+'....Please check'
		GOTO END_PROC
	END			
	
	print 'enter cost center step#'+@cStep
	
	IF @NMODE=1
		GOTO END_PROC
		
	SELECT TOP 1 @cVmLocId=dept_id FROM vm01106 (NOLOCK) WHERE vm_id=@cVmId
	
	IF ISNULL(@cVmLocId,'')=''
	BEGIN
		SET @CERRORMSG='Entry Location cannot be blank for Multi Cost Center Vouchers...Please check'
		GOTO END_PROC
	END	

	SET @CSTEP='50'
	
	--select @cVmLocId,@cVmId
		
	SELECT vm_id,COST_CENTER_DEPT_ID,SUM(DEBIT_AMOUNT-CREDIT_AMOUNT) NET_AMOUNT
	INTO #TMPCOSTCENTERLOOP	FROM VD01106 (NOLOCK) WHERE VM_ID=@CVMID
	AND cost_center_dept_id<>@cVmLocId
	GROUP BY vm_id,COST_CENTER_DEPT_ID
	HAVING SUM(DEBIT_AMOUNT-CREDIT_AMOUNT)<>0
	
	
	SET @CSTEP='60'
	print 'enter cost center step#'+@cStep
		
	DECLARE @CVDID1 VARCHAR(40),@CVDID2 VARCHAR(40),@CXTYPE VARCHAR(5),@CVSXTYPE VARCHAR(5),@NVSCREDIT NUMERIC(14,2),
			@NVSDEBIT NUMERIC(14,2),@nCcNetAmt NUMERIC(14,2)
	
	SET @CSTEP='65'
		
	SET @BLOOP=0
	
	--select 'check FROM #TMPCOSTCENTERLoop a ',* FROM #TMPCOSTCENTERLoop a 
			
	
	WHILE @BLOOP=0
	BEGIN
		SET @CSTEP='80'
		print 'enter cost center step#'+@cStep
		SET @cCostCenterDeptId=''
		SELECT TOP 1 @nCcNetAmt=net_amount,@cCostCenterDeptId=cost_center_dept_id
		FROM #TMPCOSTCENTERLoop a 
		JOIN location b ON a.cost_center_dept_id=b.dept_id
		

		IF ISNULL(@cCostCenterDeptId,'')=''
			BREAK

		SET @CSTEP='90'		
		SELECT @cVmCostCenterAcCode=(CASE WHEN SUBSTRING(b.loc_gst_no,3,10)<>SUBSTRING(a.loc_gst_no,3,10)
		AND ISNULL(a.invoice_control_ac_code,'') NOT IN ('','0000000000')
		THEN a.invoice_control_ac_code ELSE a.dept_ac_code END),
		@cCostCenterAcCode=(CASE WHEN SUBSTRING(b.loc_gst_no,3,10)<>SUBSTRING(a.loc_gst_no,3,10)
		AND ISNULL(b.invoice_control_ac_code,'') NOT IN ('','0000000000')
		THEN b.invoice_control_ac_code ELSE b.dept_ac_code END)
		FROM location a (NOLOCK)
		JOIN location b (NOLOCK) ON 1=1
		WHERE a.dept_id=@cVmLocId AND b.dept_id=@cCostCenterDeptId	

		SET @CSTEP='95'
		SELECT @cVdId1=NEWID(),@cVdId2=NEWID()

		print 'enter cost center step#'+@cStep
		INSERT vd01106	( AC_CODE, autoentry, CHK_RECON, chq_pay_mode, company_code, control_ac, 
		cost_center_ac_code, cost_center_dept_id,DEBIT_AMOUNT, CREDIT_AMOUNT, LAST_UPDATE, 
		NARRATION, online_chq_ref_no, open_cheque_dt, open_cheque_no, RECON_DT, 
		secondary_narration, vat_entry, VD_ID, VM_ID, VS_AC_CODE, X_TYPE )  
		SELECT @cCostCenterAcCode ac_code,1 autoentry,0 CHK_RECON,0 chq_pay_mode,'01' company_code, 
		1 control_ac,dept_ac_CODE cost_center_ac_code,@cVmLocId cost_center_dept_id, 
		(CASE WHEN @nCcNetAmt<0 THEN 0 ELSE @nCcNetAmt END) DEBIT_AMOUNT, 
		(CASE WHEN @nCcNetAmt<0 THEN abs(@nCcNetAmt) ELSE 0 END) CREDIT_AMOUNT, GETDATE() LAST_UPDATE, 
		'Auto Balancing entry for Cost Center:'+@cCostCenterDeptId as NARRATION,'' online_chq_ref_no, 
		'' open_cheque_dt,'' open_cheque_no,'' RECON_DT,'' secondary_narration,0 vat_entry, 
		@cVdId1 VD_ID, VM_ID,@cVmCostCenterAcCode VS_AC_CODE,
		(CASE WHEN @nCcNetAmt<0 THEN 'Cr' ELSE 'Dr' END) X_TYPE 
		FROM #TMPCOSTCENTERLOOP a JOIN location b ON a.cost_center_dept_id=b.dept_id
		WHERE a.cost_center_dept_id=@cCostCenterDeptId

		SET @CSTEP='100'
		INSERT vd01106	( AC_CODE, autoentry, CHK_RECON, chq_pay_mode, company_code, control_ac, 
		cost_center_ac_code, cost_center_dept_id, DEBIT_AMOUNT, CREDIT_AMOUNT, LAST_UPDATE, 
		NARRATION, online_chq_ref_no, open_cheque_dt, open_cheque_no, RECON_DT, 
		secondary_narration, vat_entry, VD_ID, VM_ID, VS_AC_CODE, X_TYPE )  
		SELECT @cVmCostCenterAcCode ac_code,1 autoentry,0 CHK_RECON,0 chq_pay_mode,'01' company_code, 
		1 control_ac,dept_ac_CODE cost_center_ac_code,a.cost_center_dept_id, 
		(CASE WHEN @nCcNetAmt>0 THEN 0 ELSE abs(@nCcNetAmt) END) CREDIT_AMOUNT, 
		(CASE WHEN @nCcNetAmt>0 THEN @nCcNetAmt ELSE 0 END) DEBIT_AMOUNT, GETDATE() LAST_UPDATE, 
		'Auto Balancing entry for Cost Center:'+b.dept_id as NARRATION,'' online_chq_ref_no, 
		'' open_cheque_dt,'' open_cheque_no,'' RECON_DT,'' secondary_narration,0 vat_entry, 
		@cVdId2 VD_ID, VM_ID,@cCostCenterAcCode VS_AC_CODE,
		(CASE WHEN @nCcNetAmt<0 THEN 'Dr' ELSE 'Cr' END) X_TYPE 
		FROM #TMPCOSTCENTERLOOP a JOIN location b ON 1=1
		WHERE a.cost_center_dept_id=@cCostCenterDeptId AND b.dept_id=@cVmLocId


		print 'insert bb against cost center entries'
		SET @CSTEP='105'
		INSERT INTO bill_by_bill_ref
		(VD_ID,bb_row_id,REF_NO,AMOUNT,LAST_UPDATE,X_TYPE,CR_DAYS,due_dt)
		SELECT A.VD_ID,newid() bb_row_id,DBO.FN_GETBILLBYBILL_REFNO_ONACCOUNT(A.AC_CODE) AS REF_NO,
		(A.CREDIT_AMOUNT+A.DEBIT_AMOUNT) AS AMOUNT,GETDATE() AS LAST_UPDATE
				,(CASE WHEN A.CREDIT_AMOUNT>0 THEN 'CR' ELSE 'DR' END) AS X_TYPE
				,ISNULL(D.CREDIT_DAYS,0) AS CR_DAYS,DATEADD(DD,ISNULL(D.CREDIT_DAYS,0),b.voucher_dt) AS due_dt
		FROM vd01106 A (NOLOCK)
		JOIN vm01106 B (NOLOCK) ON A.VM_ID=B.VM_ID 
		JOIN LM01106 C ON C.AC_CODE=A.AC_CODE
		LEFT OUTER JOIN LMP01106 D ON D.AC_CODE=A.AC_CODE
		WHERE a.vd_id IN (@cVdId1,@cVdId2) AND 
		isnull(d.bill_by_bill,0)=1

		

		print 'End insert bb against cost center entries'
		DELETE FROM #TMPCOSTCENTERLoop WHERE cost_center_dept_id=@cCostCenterDeptId
	END	
	
	--select 'check final cost center entry',cost_center_dept_id,ac_name,debit_amount,credit_amount,narration
	--from  vd01106 a (nolock) join lm01106 b (nolock) on a.ac_code=b.ac_code
	--where vm_id='JM9CF5FA60-A3A1-4E81-BCC6-410583976C1D'
				
END TRY			

BEGIN CATCH
	SET @CERRORMSG='ERROR IN SP3S_VALIDATE_COSTCENTER_ENTRIES AT STEP#'+@CSTEP+' '+ERROR_MESSAGE()
	GOTO END_PROC 
END CATCH

END_PROC:
	
END
---------------- END OF PROCEDURE SP3S_VALIDATE_COSTCENTER_ENTRIES
