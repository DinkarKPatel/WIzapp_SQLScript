CREATE PROCEDURE SPACT_IMPORT_LEDGEROB
@cTableName		VARCHAR(100)='',
@cFinYear		VARCHAR(20),
@cFinYear_date	 VARCHAR(20)
AS

BEGIN

	DECLARE @DATE DATETIME,@ACCOUNT VARCHAR(100),@DEBIT VARCHAR(100),@CREDIT VARCHAR(100),@NRR VARCHAR(1000),
			@CPREFIXVALUE VARCHAR(10),@TYPE VARCHAR(100),@CDEPT_ID VARCHAR(10),@NSAVETRANLOOP BIT,@CMEMONOVAL VARCHAR(100),
			@CERRORMSG VARCHAR(max),@CVMNO VARCHAR(10),@CVMID VARCHAR(40),
			@cVoucherCode VARCHAR(100),@WIZVCHTYPE VARCHAR(100),@cRowId VARCHAR(50),@cMemoNo varchar(500),
			@minvchno numeric(12,0),@maxvchno numeric(12,0),@vchno varchar(1000),@nstep varchar(100),@bRetVal BIT,@cCMD NVARCHAR(MAX)
	
	SET @cErrormsg=''
	
BEGIN TRY
	
	set @nstep=0
	
		        
	IF OBJECT_ID ('TEMPDB..#TMPVOUCHER','U') IS NOT NULL
	   DROP TABLE #TMPVOUCHER

CREATE TABLE #TMPVOUCHER(memo_dt DATETIME,memo_no VARCHAR(100),xn_type VARCHAR(100),ac_name VARCHAR(100),VS_AC_CODE  VARCHAR(100),CREDIT  NUMERIC(14,2),DEBIT NUMERIC(14,2)
,ROW_ID  VARCHAR(100),CC  VARCHAR(100))
	
	
	SET @cCMD=N'select '''+ @cFinYear_date +''' as memo_dt,REF_NO as memo_no,
	[vouchertype] as xn_type,[ACCOUNTNAME] as ac_name,isnull(b.ac_code,'''') as vs_ac_code,
	(CASE WHEN [vouchertype]=''PURCHASE'' THEN abs(amount) ELSE 0 END) AS CREDIT,
	(CASE WHEN [vouchertype]=''DEBIT NOTE'' THEN ABS(amount) ELSE 0 END) AS DEBIT,
	CONVERT(VARCHAR(40),NEWID()) as row_id,
	[costcenter] as cc
	--into #TMPVOUCHER 
	--select *
	from '+ @cTableName +' a
	left outer join lm01106 b on a.[Against Ledger]=b.ac_name where [invoice date] is not null'
		
		PRINT @cCMD
		INSERT INTO  #TMPVOUCHER(memo_dt ,memo_no ,xn_type ,ac_name ,VS_AC_CODE  ,CREDIT  ,DEBIT ,ROW_ID  ,CC  )
		EXEC SP_EXECUTESQL @cCMD
		--SELECT * FROM #TMPVOUCHER 
	set @nstep=5
		
	
	--select * from gst_accounts_config_det_1 where xn_type='pur'
	
	BEGIN TRANSACTION  
	--SELECT  CONFIG_OPTION,VALUE  FROM config  WHERE config_option ='LOCATION_ID'
	--UPDATE config SET VALUE='04'  WHERE config_option ='LOCATION_ID'
	--UPDATE config SET VALUE='HO'  WHERE config_option ='LOCATION_ID'
	
	SELECT  @CDEPT_ID=value   FROM config  WHERE config_option ='LOCATION_ID'
	--SELECT  @CDEPT_ID=value   FROM config  WHERE config_option ='ALLOW_FOC_QUANTITY'
	
	SET @bRetVal=1
	WHILE @bRetVal=1

	BEGIN

		set @nstep=10
		SET @cRowId=''
		
		SELECT TOP 1 @cRowId=row_id FROM #TMPVOUCHER 

		SELECT TOP 1 @TYPE=xn_type,@Date=memo_dt,@WIZVCHTYPE=xn_type,@cMemoNo=memo_no 
		FROM #TMPVOUCHER WHERE row_id=@cRowId
		
		IF ISNULL(@cRowId,'')=''
			GOTO END_PROC
			
		SET @vchno=''
		
		set @nstep=20
		SET @CPREFIXVALUE = LEFT(@TYPE,1)+@CDEPT_ID

		
		SELECT TOP  1 @cVoucherCode=VOUCHER_CODE  FROM vchtype WHERE VOUCHER_TYPE=@WIZVCHTYPE
	    
		IF ISNULL(@cVoucherCode,'')=''
		BEGIN
			SET @CERRORMSG = 'PLEASE DEFINE VOUCHER TYPE...'    
			GOTO END_PROC
		END	
		
		SET @nstep=30
		SET @NSAVETRANLOOP=0
		WHILE @NSAVETRANLOOP=0    
		BEGIN					    
			EXEC GETNEXTVCHNO  
			@DVCHDT=@DATE,
			@CVCHCODE=@cVoucherCode,
			@NMODE=1,
			@NWIDTH=10,
			@CCOMPANYCODE='01',
			@CPREFIX=@CPREFIXVALUE,
			@CNEWKEYVAL=@CMEMONOVAL OUTPUT 
									     
			IF ISNULL(@CMEMONOVAL,'')=''
			BEGIN
				SET @CERRORMSG = 'MESSAGE: ERROR GENERATING MEMO_NO...'    
				GOTO END_PROC
			END
									     
			SET @NSAVETRANLOOP=1
		END				 

NewVMNo:

		SET @CVMNO=@CDEPT_ID+left(convert(varchar(40),newid()),8)
	    
	    
		if exists(select top 1 'u' from VM01106 where fin_year=@cFinYear and VM_NO=@CVMNO) 
			goto NewVMNo
								
		SET @CVMID=@CDEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))) 
		
		if exists(select top 1 'u' from VM01106 where   VM_id=@CVMID) 
			SET @CVMID=@CDEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))) 
	 
		set @nstep=50

		INSERT VM01106	( Audited_user_code, Audited_dt, sr_no, mrr_list, sent_for_recon, edt_user_code, VM_ID, VOUCHER_NO, VOUCHER_DT, VOUCHER_CODE, DRTOTAL, CRTOTAL, BILL_NO, CASH_VOUCHER, BILL_DT, BILL_TYPE, REF_NO, LAST_UPDATE, company_code, sale_voucher, dept_id, sent_to_ho, bill_id, fin_year, cancelled, FREEZE, quantity, angadia_code, lr_no, lr_dt, bill_ac_code, approved, uploaded_to_activstream, REF_VM_ID, user_code, op_entry, MEMO, REMINDER_DAYS, sms_sent, attachment_file, vm_no, ApprovedLevelNo )  
		SELECT 	  Audited_user_code='', Audited_dt='1900-01-01', sr_no=0, 
		mrr_list='', sent_for_recon=0, edt_user_code='', VM_ID=@CVMID, VOUCHER_NO=@CMEMONOVAL, 
		VOUCHER_DT=memo_dt, VOUCHER_CODE=@cVoucherCode, DRTOTAL=CREDIT+DEBIT,
		CRTOTAL=CREDIT+DEBIT, 
		BILL_NO=@vchno, CASH_VOUCHER=0, BILL_DT=memo_dt, 
		BILL_TYPE=@TYPE, ----CHECK
		REF_NO='OPENING VOUCHER-CREDITORS', LAST_UPDATE=GETDATE (), 
		company_code='01', sale_voucher=0, dept_id=@CDEPT_ID, sent_to_ho=0, bill_id='', fin_year=@cFinYear, 
		cancelled=0, FREEZE=0, quantity=0, angadia_code='', 
		lr_no='', lr_dt='1900-01-01', bill_ac_code='', approved=0, 
		uploaded_to_activstream=0, REF_VM_ID='', user_code='0000000', op_entry=0, MEMO=0, 
		REMINDER_DAYS=0, sms_sent=0, attachment_file='', vm_no=@CVMNO, ApprovedLevelNo =0
		FROM #TMPVOUCHER WHERE row_id=@cRowId
		--select * FROM #TMPVOUCHER
		
		set @nstep=60
		INSERT VD01106	( VD_ID, VM_ID, AC_CODE, NARRATION, CREDIT_AMOUNT, DEBIT_AMOUNT, X_TYPE, VS_AC_CODE, CHK_RECON, RECON_DT, LAST_UPDATE, company_code, autoentry, control_ac, vat_entry, secondary_narration, cost_center_ac_code, cost_center_dept_id )  
		 SELECT VD_ID=@CDEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))), 
		 VM_ID=@CVMID, AC_CODE=b.ac_code,NARRATION=ISNULL(@WIZVCHTYPE+' against Memo no.:'+@cMemono+' Dated :'+CONVERT(varchar,@Date,105),''),
		 CREDIT_AMOUNT=CREDIT, 
		 DEBIT_AMOUNT=debit, X_TYPE=(case when credit<>0 then 'CR' else 'Dr' end), VS_AC_CODE='0000000000', CHK_RECON=0, RECON_DT='1900-01-01', 
		 LAST_UPDATE=GETDATE (), company_code='01', autoentry=0, control_ac=0, vat_entry=0, secondary_narration='', 
		 cost_center_ac_code='0000000000', 
		 cost_center_dept_id=cc FROM #TMPVOUCHER A 
		 JOIN LM01106 B ON A.ac_name=B.AC_NAME 
		 WHERE A.row_id=@cRowId
		

		
		set @nstep=70
		INSERT VD01106	( VD_ID, VM_ID, AC_CODE, NARRATION, CREDIT_AMOUNT, DEBIT_AMOUNT, X_TYPE, VS_AC_CODE, CHK_RECON, RECON_DT, LAST_UPDATE, company_code, autoentry, control_ac, vat_entry, secondary_narration, cost_center_ac_code, cost_center_dept_id )  
		 SELECT VD_ID=@CDEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))), 
		 VM_ID=@CVMID, AC_CODE=a.vs_ac_code, NARRATION=ISNULL(@WIZVCHTYPE+' against Memo no.:'+@cMemono+' Dated :'+CONVERT(varchar,@Date,105),''),
		 CREDIT_AMOUNT=debit, DEBIT_AMOUNT=credit, X_TYPE=(case when credit<>0 then 'DR' else 'Cr' end), VS_AC_CODE='0000000000', CHK_RECON=0, RECON_DT='1900-01-01', 
		 LAST_UPDATE=GETDATE (), company_code='01', autoentry=0, control_ac=0, vat_entry=0, secondary_narration='', 
		 cost_center_ac_code='0000000000', 
		 cost_center_dept_id=cc FROM #TMPVOUCHER A 
		 WHERE A.row_id=@cRowId 
		
		 set @nstep=80
		 INSERT bill_by_bill_ref	( VD_ID, REF_NO, AMOUNT, LAST_UPDATE, X_TYPE, CR_DAYS, Remarks, adj_remarks,
		 payment_adj_ref_no, bb_row_id )  
		 SELECT VD_ID,@cMemoNo AS REF_NO,debit_amount+credit_amount as AMOUNT,GETDATE() AS LAST_UPDATE,
		 (CASE WHEN CREDIT_AMOUNT>0 THEN 'Cr' ELSE 'Dr' END) AS X_TYPE,0 AS CR_DAYS,'OB' AS Remarks,
		 '' as adj_remarks,'' as payment_adj_ref_no,newid() as bb_row_id FROM vd01106 a
		 JOIN LMp01106 b ON a.AC_CODE=b.AC_CODE
		 WHERE vm_id=@CVMID and bill_by_bill=1
	 
		 DELETE FROM #TMPVOUCHER WHERE row_id=@cRowId
		 --select * FROM #TMPVOUCHER WHERE row_id=@cRowId
		 
	END  
	
	
	goto end_proc
		 
END TRY

BEGIN CATCH
	SET @cErrormsg='Error at step #'+str(@nstep)+ERROR_MESSAGE()

	goto end_proc
END CATCH

END_PROC:
	
	
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@cErrormsg,'')=''
			COMMIT
		ELSE
			ROLLBACK	
	END		
	
	SELECT ISNULL(@cErrormsg,'') as errmsg
END