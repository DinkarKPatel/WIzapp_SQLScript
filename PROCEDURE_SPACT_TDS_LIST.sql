CREATE PROCEDURE SPACT_TDS_LIST
(
	@nQueryID INT,
	@nSpId NUMERIC(5,0)=0, 
	@dFromDt DATETIME='',      
	@dToDt DATETIME='',    
	@cAcCodePara CHAR(10)='',    
	@ctds_code VARCHAR(20)='',    
	@cVoucherCode VARCHAR(20)=''
)
AS
BEGIN

	IF OBJECT_ID('tempdb..#locListC','u') IS NOT NULL    
	  DROP TABLE #locListC    
    
	  CREATE TABLE #locListC (dept_id CHAR(2))    
    
	 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
	  INSERT #locListC    
	  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId    
	 ELSE    
	  INSERT #locListC    
	  SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)    

	--  SELECT * FROM #locListC
	IF @nQueryID=1
	BEGIN
		SELECT a.tds_per, a.tds_amt, a.surcharge_per, a.surcharge_amt, 
		a.edu_per,a.edu_amt, a.tds_code, a.vd_id, a.tds_ac_code, 
		ROUND(a.tds_amt + a.surcharge_amt+ a.edu_amt,0,0) as Total, 
		b.tds_name, CASE WHEN c.x_type='Dr' THEN debit_amount ELSE c.credit_amount END as Amount,
		d.voucher_dt, f.voucher_type
		,(CASE WHEN d.DRTOTAL<>(CASE WHEN c.x_type='Dr' THEN debit_amount ELSE c.credit_amount END) THEN d.DRTOTAL ELSE (CASE WHEN c.x_type='Dr' THEN debit_amount ELSE c.credit_amount END) END) as [total_amount] 
		,e.*,lmp.* ,ISNULL(d.BILL_NO,'')  AS [BILL_NO]
		FROM VDT01106 a (NOLOCK)
		JOIN TDS_SECTION b (NOLOCK) ON a.tds_code=b.tds_code 
		JOIN vd01106 c (NOLOCK) ON a.vd_id=c.vd_id 
		JOIN VM01106 d (NOLOCK) ON c.vm_id=d.vm_id 
		JOIN LM01106 e (NOLOCK) ON c.ac_code=e.ac_code 
		LEFT OUTER JOIN LMP01106 lmp (NOLOCK) ON lmp.ac_code=e.ac_code 
		JOIN VCHTYPE f (NOLOCK) ON d.voucher_code = f.Voucher_code 
		JOIN #locListC l ON l.dept_id=c.cost_center_dept_id  
		WHERE d.CANCELLED =0  AND (d.Voucher_dt between @dFromDt and @dToDt) 
		AND (@ctds_code='' OR b.TDS_Code=@ctds_code)
		AND (@cAcCodePara='' OR c.ac_code=@cAcCodePara)
		AND (@cVoucherCode='' OR f.VOUCHER_CODE=@cVoucherCode)
		ORDER BY e.ac_name 
	END
	ELSE IF @nQueryID=2
	BEGIN
		SELECT tds_code, tds_name FROM tds_section (NOLOCK) WHERE TDS_code<>'0000000' ORDER BY tds_name
	END
	ELSE IF @nQueryID=3
	BEGIN
		SELECT ac_name, ac_code,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ac_name,'.',''),'@',''),' ',''),'_',''),'(',''),')',''),'-','') AS parse_ac_name 
		FROM LM01106 (NOLOCK) 
		WHERE ac_name <> '' 
		ORDER BY ac_name
	END
	ELSE IF @nQueryID=4
	BEGIN
		SELECT voucher_code, voucher_type FROM vchtype (NOLOCK) WHERE voucher_code in('0000000002','0000000003')
	END

END