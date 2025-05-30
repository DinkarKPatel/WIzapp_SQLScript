CREATE PROCEDURE SP3S_BANKRECON--(LocId 3 digit change by Sanjay:04-11-2024)
@NMODE INT,
@CACCODE CHAR(10),
@DFROMDT DATETIME='',
@DTODT DATETIME='',
@BCHKONCLEARINGDT BIT=0,
@cSPID VARCHAR(50)=''
AS
BEGIN
	DECLARE @CFINYEAR VARCHAR(10)
	
	SET @CFINYEAR='01'+DBO.FN_GETFINYEAR(@DFROMDT)

	IF OBJECT_ID('#locListCBANKRECON','u') IS NOT NULL    
	  DROP TABLE #locListCBANKRECON    
    
	CREATE TABLE #locListCBANKRECON (dept_id VARCHAR(4))    
    
	SET @cSPID=ISNULL(@cSPID,'')
		
    
	 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @cSPID AND dept_id<>'')    
	  INSERT #locListCBANKRECON    
	  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @cSPID    
	 ELSE    
	  INSERT #locListCBANKRECON    
	  SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND loc_type=1 --OR ISNULL(Account_posting_at_ho,0)=1)  


		
	IF @NMODE=1
		GOTO LBLBANKOBSUMMARYBYLEDGER
	ELSE IF @NMODE=2
		GOTO LBLBANKOBSUMMARYBYBANK
	ELSE IF @NMODE=3		
		GOTO LBLPENDINGRECOCHEQUES
	ELSE IF @NMODE=4		
		GOTO LBLRECONCILEDCHEQUES
	ELSE IF @NMODE=5	
		GOTO LBLBANKRECOPRINT
	ELSE IF @NMODE=6	
		GOTO LBLBANKRECOPRINT_CLEARING
	ELSE
		GOTO END_PROC
				
LBLBANKOBSUMMARYBYLEDGER:
	
	DECLARE @OPENING_BALANCE TABLE(ac_code VARCHAR(50),OPENING NUMERIC(14,2))
	
	SELECT AC_NAME, 
	ISNULL(B.DEBIT_AMOUNT,0) AS DEBIT_AMOUNT,
	ISNULL(B.CREDIT_AMOUNT,0) AS CREDIT_AMOUNT,
	ISNULL(b.ob_vd_amt,0) AS OPENING_BALANCE, ISNULL(b.cb_vd_amt,0) AS CLOSING_BALANCE 
	FROM LM01106 A 
	LEFT OUTER JOIN 
	( 
		SELECT VA.AC_CODE,SUM(CASE WHEN voucher_dt<@dFromDt then DEBIT_AMOUNT-CREDIT_AMOUNT else 0 end) AS OB_VD_AMT,SUM(DEBIT_AMOUNT-CREDIT_AMOUNT) AS CB_VD_AMT, 
		SUM(CASE WHEN VB.VOUCHER_DT BETWEEN @DFROMDT AND @DTODT THEN   DEBIT_AMOUNT ELSE 0 END) AS DEBIT_AMOUNT, 
		SUM(CASE WHEN VB.VOUCHER_DT BETWEEN  @DFROMDT AND @DTODT THEN CREDIT_AMOUNT ELSE 0 END) AS CREDIT_AMOUNT 
		FROM VD01106 VA JOIN VM01106 VB ON VA.VM_ID=VB.VM_ID 
		join #locListCBANKRECON loc on loc.dept_id =va.cost_center_dept_id
		WHERE VB.CANCELLED=0 
		AND VB.VOUCHER_DT<=@DTODT 
	AND VA.AC_CODE=@CACCODE GROUP BY VA.AC_CODE 
	) B ON A.AC_CODE=B.AC_CODE  
	WHERE A.AC_CODE=@CACCODE ORDER BY AC_NAME 

	GOTO END_PROC


LBLBANKOBSUMMARYBYBANK: --BANK OPS/CBS


	DECLARE @NOPENING NUMERIC(14,2),@NCLOSING NUMERIC(14,2),@NCREDIT NUMERIC(14,2),@NDEBIT NUMERIC(14,2)

	SELECT @NOPENING = ISNULL(DBO.FN_ACT_BANK_OPENING( @CACCODE,'', @DFROMDT,'' , @cSPID),0)
	
	SELECT @NCLOSING = ISNULL(DBO.FN_ACT_BANK_OPENING(@CACCODE,'',@DTODT+1, @CFINYEAR , @cSPID),0)
		
	SELECT AC_NAME,@NOPENING  AS OPENING_BALANCE,
	 SUM(ISNULL(B.DEBIT_AMOUNT,0))  AS DEBIT_AMOUNT, 
	 SUM(ISNULL(B.CREDIT_AMOUNT,0)) AS  CREDIT_AMOUNT, 
	 (@NOPENING+SUM(ISNULL(B.DEBIT_AMOUNT,0))-SUM(ISNULL(B.CREDIT_AMOUNT,0))) AS CLOSING_BALANCE 
	 FROM LM01106 A (NOLOCK) 
	 LEFT OUTER JOIN 
	 ( 
	 SELECT VA.AC_CODE,SUM(DEBIT_AMOUNT) AS DEBIT_AMOUNT, 
	 SUM(CREDIT_AMOUNT) AS CREDIT_AMOUNT 
	 FROM VD01106 VA (NOLOCK) 
	 JOIN VM01106 VB (NOLOCK) ON VA.VM_ID=VB.VM_ID 
	 join #locListCBANKRECON loc on loc.dept_id =va.cost_center_dept_id
	 WHERE VB.CANCELLED=0 
	 AND  VA.RECON_DT BETWEEN @DFROMDT AND @DTODT
	 AND VA.AC_CODE=@CACCODE GROUP BY VA.AC_CODE 
	 UNION ALL
	 SELECT BANK_AC_CODE,SUM(CASE WHEN CHQ_AMT_TYPE='DR' THEN CHQ_AMT ELSE 0 END) AS DEBIT_AMOUNT,
	 SUM(CASE WHEN CHQ_AMT_TYPE='CR' THEN CHQ_AMT ELSE 0 END) AS CREDIT_AMOUNT  FROM 
	 BANK_OP_CHQ A (NOLOCK) 
	 WHERE BANK_AC_CODE=@CACCODE AND RECON_DT BETWEEN @DFROMDT AND @DTODT
	 GROUP BY BANK_AC_CODE
	 ) B ON A.AC_CODE=B.AC_CODE  
	 WHERE A.AC_CODE=@CACCODE
	 GROUP BY AC_NAME
	 ORDER BY AC_NAME 
	 GOTO END_PROC
		
LBLPENDINGRECOCHEQUES:
	
	DECLARE @TUNSECUREDLOANS TABLE (VM_ID VARCHAR(40))
	DECLARE @CUNSECUREDLOANHEADS VARCHAR(1000),@CCMD NVARCHAR(MAX)
	
	SELECT @CUNSECUREDLOANHEADS = DBO.FN_ACT_TRAVTREE( '0000000024' )
	SELECT @CUNSECUREDLOANHEADS = ISNULL(@CUNSECUREDLOANHEADS,'')+(CASE WHEN ISNULL(@CUNSECUREDLOANHEADS,'')<>'' THEN ',' ELSE '' END)
	+DBO.FN_ACT_TRAVTREE( '0000000031' )

		
	SET @CCMD=N'SELECT A.VM_ID FROM VD01106 A JOIN VM01106 B ON A.VM_ID=B.VM_ID
		 JOIN LM01106 C ON C.AC_CODE=A.AC_CODE
		 WHERE C.HEAD_CODE IN ('+@CUNSECUREDLOANHEADS+') AND
		 VOUCHER_DT<='''+CONVERT(VARCHAR,@DTODT,110)+'''   AND CANCELLED=0'
	
	INSERT @TUNSECUREDLOANS	 
	EXEC SP_EXECUTESQL @CCMD	 


	IF OBJECT_ID('tempdb..#tmpPendingReco','u') IS NOT NULL
		DROp TABLE #tmpPendingReco

	SELECT A.VD_ID, A.VD_ID AS VS_AC_VD_ID, A.NARRATION,A.VM_ID,
			 CONVERT(CHAR(10),(CASE WHEN A.RECON_DT=''  THEN NULL ELSE A.RECON_DT END),105) AS RECONDT, A.RECON_DT AS [ORG_RECON_DT],
			 A.X_TYPE, D.VOUCHER_TYPE,X.VOUCHER_DT,  X.VOUCHER_NO,
			  --DBO.FN_GETACNAME(A.VM_ID,A.AC_CODE,A.X_TYPE)  AS [AC_NAME] ,
			  CONVERT(VARCHAR(max),lm.ac_name) ac_name,A.AC_CODE, A.DEBIT_AMOUNT AS  [DEBIT_AMOUNT],
	 A.CREDIT_AMOUNT AS  [CREDIT_AMOUNT],  ISNULL(CHQ.CHQ_LEAF_NO  ,ISNULL(A.OPEN_CHEQUE_NO,'')) AS CHQ_LEAF_NO  
	into #tmpPendingReco 
	FROM VD01106 A (NOLOCK) 
	JOIN VM01106 X (NOLOCK) ON X.VM_ID=A.VM_ID
	JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.AC_CODE
	JOIN VCHTYPE  D (NOLOCK) ON D.VOUCHER_CODE=X.VOUCHER_CODE
	LEFT OUTER JOIN VD_CHQBOOK VD_CHQ (NOLOCK) ON A.VD_ID = VD_CHQ.VD_ID 
	LEFT OUTER JOIN CHQBOOK_D CHQ (NOLOCK) ON VD_CHQ.CHQBOOK_ROW_ID = CHQ.ROW_ID 
	WHERE A.AC_CODE=@CACCODE AND ISNULL(A.RECON_DT,'')=''

	AND X.VOUCHER_DT<=@DTODT  
	AND isnull(X.CANCELLED,0)=0 
	AND isnull(A.AUTOENTRY,0)=0
	UNION ALL
	SELECT A.ROW_ID AS VD_ID, '' AS VS_AC_VD_ID, 'CHQ NO : ' + CHQ_NO AS NARRATION, '' AS VM_ID, 
			   CONVERT(CHAR(10),  (CASE WHEN A.RECON_DT ='' THEN NULL ELSE A.RECON_DT END),105) AS RECONDT, A.RECON_DT AS [ORG_RECON_DT],
				A.CHQ_AMT_TYPE  AS X_TYPE, '' AS VOUCHER_TYPE, 
				A.CHQ_DT AS VOUCHER_DT, '' AS VOUCHER_NO,  B.AC_NAME ,B.AC_CODE , 
				CASE WHEN A.CHQ_AMT_TYPE ='DR' THEN CHQ_AMT ELSE 0 END AS DEBIT_AMOUNT, 
				CASE WHEN A.CHQ_AMT_TYPE ='DR' THEN 0 ELSE CHQ_AMT  END AS CREDIT_AMOUNT, '' AS CHQ_LEAF_NO 
	FROM BANK_OP_CHQ A 
	JOIN LM01106 B ON A.AC_CODE = B.AC_CODE  
	WHERE BANK_AC_CODE = @CACCODE AND  ISNULL(A.RECON_DT,'') =''
	ORDER BY VOUCHER_DT DESC ,VOUCHER_NO  

	--;WITH MAX_VS_AC_NAME
	--AS
	--(
	--	SELECT a.VM_ID,c.ac_name ,MAX(b.DEBIT_AMOUNT+b.CREDIT_AMOUNT) AS AMOUNT
	--	from #tmpPendingReco a
	--	join vd01106  b (nolock) on b.VM_ID=a.vm_id
	--	join lm01106 c (nolock) on c.AC_CODE=b.ac_code
	--	where b.vd_id<>a.vd_id AND a.X_TYPE<>b.X_TYPE
	--	AND isnull(b.autoentry,0)=0
	--	GROUP BY a.VM_ID,c.ac_name
	--)
	--UPDATE  a set ac_name=b.ac_name 
	--from #tmpPendingReco a
	--join MAX_VS_AC_NAME  b  on b.VM_ID=a.vm_id

	--EXEC SP3S_PROCESS_VSACNAMES
	--@cTempTable='#tmpPendingReco',
	--@cVsAcNameCol = 'ac_name'


	--*******FOR VS ACCOUNT *******

	 DECLARE @VM_ID VARCHAR(max), @VSACNAMES VARCHAR(MAX);	 

	 SELECT a.vm_id, AC_NAME=  lm.AC_NAME+' ['+CAST(CONVERT(NUMERIC(14,2),
	 sum(ISNULL(B.DEBIT_AMOUNT,0)+ISNULL(B.CREDIT_AMOUNT,0))) AS VARCHAR(50)) +B.X_TYPE+']' ,
	 sum(ISNULL(B.DEBIT_AMOUNT,0)+ISNULL(B.CREDIT_AMOUNT,0)) as Amount
	 into #tmpvm
	 FROM #tmpPendingReco A
	 JOIN VD01106 B (nolock) ON A.VM_ID=B.VM_ID 
	 JOIN LM01106 LM (NOLOCK) ON B.AC_CODE=LM.AC_CODE  
	 WHERE a.vd_id <>b.vd_id 
	 group by  b.vm_id,a.vm_id,lm.AC_NAME,B.X_TYPE
	 
	

	
     CREATE TABLE  #TMP   (VM_ID VARCHAR(100),UNQID VARCHAR(50), AC_NAME VARCHAR(500), VSACNAMES VARCHAR(MAX),Amount numeric(14,2),sr  int);

	 INSERT #TMP(VM_ID,UNQID, AC_NAME,Amount,sr)
	 SELECT VM_ID, DENSE_RANK() OVER (ORDER BY VM_ID),AC_NAME,AMOUNT,
	 ROW_NUMBER() OVER(PARTITION BY VM_ID ORDER BY AMOUNT DESC)  FROM #TMPVM

	 CREATE INDEX IX_AMT_TMPVM ON #TMP(SR)


	UPDATE #TMP SET @VSACNAMES = VSACNAMES = COALESCE(
		  CASE COALESCE(@VM_ID, N'') 
		  WHEN UNQID THEN  @VSACNAMES+CHAR(13)+CHAR(10) + N''+ AC_NAME --+CHAR(13)+CHAR(10)
		  ELSE AC_NAME  END , N'') , 
		@VM_ID = UNQID ;

		

		
	 SET @cCmd=N'UPDATE a SET Ac_name=b.VSACNAMES 
	 FROM #tmpPendingReco a
	 JOIN
	 (
		SELECT vm_id, UnqId, VSACNAMES = VSACNAMES,
		SR =ROW_NUMBER() OVER (PARTITION BY UNQID ORDER BY LEN(VSACNAMES) DESC)
		FROM #TMP
	
		) b ON  a.vm_id=b.vm_id and b.SR=1
	 '
	 print @cCmd
	 EXEC SP_EXECUTESQL @cCmd

	 --*******end of VS ACCOUNT *******

	select * from #tmpPendingReco
	GOTO END_PROC

LBLRECONCILEDCHEQUES:
	
	IF OBJECT_ID('tempdb..#tmpReconciledChq','u') IS NOT NULL
		DROp TABLE #tmpReconciledChq

	SELECT A.VD_ID, A.VD_ID AS VS_AC_VD_ID, A.NARRATION,A.VM_ID,
	CONVERT(CHAR(10),(CASE WHEN A.RECON_DT=''  THEN NULL ELSE A.RECON_DT END),105) AS RECONDT, A.RECON_DT AS [ORG_RECON_DT],
	A.X_TYPE, D.VOUCHER_TYPE,X.VOUCHER_DT,  X.VOUCHER_NO,
	--DBO.FN_GETACNAME(A.VM_ID,A.AC_CODE,A.X_TYPE) AS [AC_NAME]  ,
	CONVERT(VARCHAR(MAX),lm.ac_name) AC_NAME,A.AC_CODE, A.DEBIT_AMOUNT AS  [DEBIT_AMOUNT],
	A.CREDIT_AMOUNT AS  [CREDIT_AMOUNT],  CHQ.CHQ_LEAF_NO  
	into #tmpReconciledChq
	FROM VD01106 A (NOLOCK) 
	JOIN VM01106 X (NOLOCK) ON X.VM_ID=A.VM_ID
	JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.AC_CODE
	JOIN VCHTYPE  D (NOLOCK) ON D.VOUCHER_CODE=X.VOUCHER_CODE
	LEFT OUTER JOIN VD_CHQBOOK VD_CHQ (NOLOCK) ON A.VD_ID = VD_CHQ.VD_ID 
	LEFT OUTER JOIN CHQBOOK_D CHQ (NOLOCK) ON VD_CHQ.CHQBOOK_ROW_ID = CHQ.ROW_ID 
	WHERE A.AC_CODE=@CACCODE AND ISNULL(A.RECON_DT,'')<>''
	AND ((@BCHKONCLEARINGDT=0 AND X.VOUCHER_DT BETWEEN @DFROMDT AND @DTODT)
		 OR (@BCHKONCLEARINGDT=1 AND isnull(A.RECON_DT,'')<=@DTODT))   
	AND isnull(X.CANCELLED,0)=0 
	AND ISNULL(A.AUTOENTRY,0)=0
	UNION ALL
	SELECT A.ROW_ID AS VD_ID, '' AS VS_AC_VD_ID, 'CHQ NO : ' + CHQ_NO AS NARRATION, '' AS VM_ID, 
			   CONVERT(CHAR(10),  (CASE WHEN A.RECON_DT ='' THEN NULL ELSE A.RECON_DT END),105) AS RECONDT,A.RECON_DT AS [ORG_RECON_DT], 
				A.CHQ_AMT_TYPE  AS X_TYPE, '' AS VOUCHER_TYPE, 
				A.CHQ_DT AS VOUCHER_DT, '' AS VOUCHER_NO,  B.AC_NAME ,B.AC_CODE , 
				CASE WHEN A.CHQ_AMT_TYPE ='DR' THEN CHQ_AMT ELSE 0 END AS DEBIT_AMOUNT, 
				CASE WHEN A.CHQ_AMT_TYPE ='DR' THEN 0 ELSE CHQ_AMT  END AS CREDIT_AMOUNT, '' AS CHQ_LEAF_NO 
	FROM BANK_OP_CHQ A 
	JOIN LM01106 B ON A.AC_CODE = B.AC_CODE  
	WHERE BANK_AC_CODE = @CACCODE  AND  ISNULL(A.RECON_DT,'') <>''
	AND (@BCHKONCLEARINGDT=0 OR A.RECON_DT<=@DTODT)
	ORDER BY VOUCHER_DT DESC ,VOUCHER_NO  
 

	--;WITH MAX_VS_AC_NAME1
	--AS
	--(
	--	SELECT a.VM_ID,c.ac_name ,MAX(b.DEBIT_AMOUNT+b.CREDIT_AMOUNT) AS AMOUNT
	--	from #tmpReconciledChq a
	--	join vd01106  b (nolock) on b.VM_ID=a.vm_id
	--	join lm01106 c (nolock) on c.AC_CODE=b.ac_code
	--	where b.vd_id<>a.vd_id AND a.X_TYPE<>b.X_TYPE
	--	AND ISNULL(b.autoentry,0)=0
	--	GROUP BY a.VM_ID,c.ac_name
	--)
	--UPDATE  a set ac_name=b.ac_name 
	--from #tmpReconciledChq a
	--join MAX_VS_AC_NAME1  b  on b.VM_ID=a.vm_id

	EXEC SP3S_PROCESS_VSACNAMES
	@cTempTable='#tmpReconciledChq',
	@cVsAcNameCol = 'ac_name'

	select * from #tmpReconciledChq ORDER BY VOUCHER_DT DESC ,VOUCHER_NO  

	GOTO END_PROC
	
LBLBANKSTATEMENTPRINT: --BANK DETAILS 
  
	 SELECT AC_NAME, ISNULL(DBO.FN_ACT_BANK_OPENING( @CACCODE,'', @DFROMDT,'' , '01'),0)  AS OPENING_BALANCE,
	 ISNULL(B.DEBIT_AMOUNT,0) + ISNULL(C.DEBIT_AMOUNT,0)  AS DEBIT_AMOUNT, 
	 ISNULL(B.CREDIT_AMOUNT,0)  + ISNULL(C.CREDIT_AMOUNT,0) AS  CREDIT_AMOUNT, 
	 ISNULL(DBO.FN_ACT_BANK_CLOSING ( @CACCODE,'', @DTODT,'' , '01'),0) AS CLOSING_BALANCE 
	 FROM LM01106 A (NOLOCK) 
	 LEFT OUTER JOIN 
	 ( 
	 SELECT VA.AC_CODE,SUM(CASE WHEN VB.VOUCHER_DT<@DFROMDT  THEN (DEBIT_AMOUNT-CREDIT_AMOUNT) ELSE 0 END) AS OB_VD_AMT, 
	 SUM(CASE WHEN VB.VOUCHER_DT BETWEEN @DFROMDT AND @DTODT THEN   DEBIT_AMOUNT ELSE 0 END) AS DEBIT_AMOUNT, 
	 SUM(CASE WHEN VB.VOUCHER_DT BETWEEN  @DFROMDT AND @DTODT THEN CREDIT_AMOUNT ELSE 0 END) AS CREDIT_AMOUNT 
	 FROM VD01106 VA (NOLOCK) JOIN VM01106 VB (NOLOCK) ON VA.VM_ID=VB.VM_ID WHERE VB.CANCELLED=0
	 AND VB.VOUCHER_DT<=@DTODT AND VA.RECON_DT <>''
	 AND VA.AC_CODE=@CACCODE GROUP BY VA.AC_CODE 
	 ) B ON A.AC_CODE=B.AC_CODE  
	 LEFT OUTER JOIN 
	 ( SELECT  B.AC_CODE ,SUM(ISNULL(CASE WHEN CHQ_AMT_TYPE ='DR' THEN CHQ_AMT   ELSE 0  END,0)) AS DEBIT_AMOUNT  ,
	 SUM(ISNULL(CASE WHEN CHQ_AMT_TYPE ='CR' THEN CHQ_AMT   ELSE 0  END   ,0))AS CREDIT_AMOUNT 
	 FROM BANK_OP_CHQ (NOLOCK) 
	 JOIN LM01106 B (NOLOCK) ON BANK_OP_CHQ.BANK_AC_CODE = B.AC_CODE 
	 WHERE BANK_AC_CODE =  @CACCODE AND RECON_DT BETWEEN  @DFROMDT AND @DTODT
	 GROUP BY B.AC_CODE  
	 ) C ON A.AC_CODE=C.AC_CODE  
	 WHERE A.AC_CODE=@CACCODE ORDER BY AC_NAME 
 
	 GOTO END_PROC


LBLBANKOPENINGDETAILS: --BANK OPENING

	 SELECT A.*, B.AC_NAME FROM BANK_OP_BALANCE A (NOLOCK) 
	 JOIN LM01106 B (NOLOCK) ON A.BANK_AC_CODE = B.AC_CODE 
	 WHERE A.BANK_AC_CODE =@CACCODE AND A.FIN_YEAR =@CFINYEAR
	 
	 GOTO END_PROC
	 
LBLBANKOPENINGCHEQUES: --BANK OPENING CHQ

	 SELECT A.BANK_AC_CODE ,	A.AC_CODE,  B.AC_NAME,
	 CONVERT(CHAR(10),(CASE WHEN A.CHQ_DT='' THEN NULL ELSE A.CHQ_DT END),105) AS CHQ_DT1,
	 CHQ_DT, A.CHQ_NO, A.CHQ_AMT, A.CHQ_AMT_TYPE, A.RECON_DT, A.ROW_ID, A.LAST_UPDATE 
	 FROM BANK_OP_CHQ A (NOLOCK) 
	 JOIN LM01106 B (NOLOCK) ON A.AC_CODE = B.AC_CODE 
	 WHERE BANK_AC_CODE =@CACCODE
	 
	 GOTO END_PROC

LBLBANKRECOPRINT:

	SELECT A.VD_ID, A.VD_ID AS VS_AC_VD_ID, A.NARRATION,A.VM_ID,
			 CONVERT(CHAR(10),(CASE WHEN A.RECON_DT=''  THEN NULL ELSE A.RECON_DT END),105) AS RECONDT, 
			 (CASE WHEN A.X_TYPE='DR' THEN 'DR' ELSE 'CR' END) AS X_TYPE, D.VOUCHER_TYPE,X.VOUCHER_DT,  X.VOUCHER_NO,
			  LM.AC_NAME , A.AC_CODE, A.DEBIT_AMOUNT AS  [DEBIT_AMOUNT],
	 A.CREDIT_AMOUNT AS  [CREDIT_AMOUNT],  CHQ.CHQ_LEAF_NO  
	FROM VD01106 A (NOLOCK) 
	JOIN VM01106 X (NOLOCK) ON X.VM_ID=A.VM_ID
	JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.VS_AC_CODE
	JOIN VCHTYPE  D (NOLOCK) ON D.VOUCHER_CODE=X.VOUCHER_CODE
	LEFT OUTER JOIN VD_CHQBOOK VD_CHQ (NOLOCK) ON A.VD_ID = VD_CHQ.VD_ID 
	LEFT OUTER JOIN CHQBOOK_D CHQ (NOLOCK) ON VD_CHQ.CHQBOOK_ROW_ID = CHQ.ROW_ID 
	WHERE A.AC_CODE=@CACCODE AND (ISNULL(A.RECON_DT,'') ='' OR ISNULL(A.RECON_DT,'') >@DTODT)
	AND X.VOUCHER_DT <=  @DTODT 
	AND isnull(X.CANCELLED,0)=0  
	AND isnull(A.AUTOENTRY,0)=0

	UNION ALL
	 SELECT A.ROW_ID AS VD_ID, '' AS VS_AC_VD_ID, 'CHQ NO : ' + CHQ_NO AS NARRATION, '' AS VM_ID, 
			   CONVERT(CHAR(10),  (CASE WHEN A.RECON_DT ='' THEN NULL ELSE A.RECON_DT END),105) AS RECONDT, 
				(CASE WHEN A.CHQ_AMT_TYPE='DR' THEN 'DR' ELSE 'CR' END) AS X_TYPE, '' AS VOUCHER_TYPE, 
				A.CHQ_DT AS VOUCHER_DT, '' AS VOUCHER_NO,  B.AC_NAME ,B.AC_CODE , 
				CASE WHEN A.CHQ_AMT_TYPE ='DR' THEN CHQ_AMT ELSE 0 END AS DEBIT_AMOUNT, 
				CASE WHEN A.CHQ_AMT_TYPE ='DR' THEN 0 ELSE CHQ_AMT  END AS CREDIT_AMOUNT, '' AS CHQ_LEAF_NO 
	 FROM BANK_OP_CHQ A (NOLOCK) 
	 JOIN LM01106 B (NOLOCK) ON A.AC_CODE = B.AC_CODE  
	 WHERE BANK_AC_CODE = @CACCODE AND  (ISNULL(A.RECON_DT,'') ='' OR ISNULL(A.RECON_DT,'') >@DTODT)
	 ORDER BY VOUCHER_DT ,VOUCHER_NO  
	 
	 GOTO END_PROC
LBLBANKRECOPRINT_CLEARING:
	 if object_id ('tempdb..#tmpbankM','u') IS NOT NULL 
	 drop table #tmpbankM 
	 
	 SELECT e.VD_ID,  a.vd_id as vs_ac_vd_id, 0.00 as balance ,a.narration,a.vm_id,
			 convert(char(10),  (case when e.RECON_DT='' then Null else e.RECON_DT end),105) as recondt,
			 e.X_Type,  d.voucher_type,c.voucher_dt,c.voucher_no,ac_name, a.ac_code, e.debit_amount,  e.credit_amount
	 INTO #tmpbankM 
	 from vd01106 a (NOLOCK)
	 JOIN lm01106 b (NOLOCK) on a.ac_code=b.ac_code
	 JOIN  vm01106 c (NOLOCK) on a.vm_id=c.vm_id 
	 join vchtype d (NOLOCK) on d.voucher_code=c.voucher_code 
	 JOIN
	 (
			 select a.vd_id, a.vm_id,a.ac_code, x_type,credit_amount,debit_amount, a.narration, a.recon_dt
			 from vd01106 a (NOLOCK)
			 JOIN  vm01106 b (NOLOCK) on a.vm_id=b.vm_id
			 where a.ac_code=@CACCODE AND cancelled=0 AND ISNULL(b.op_entry,0)=0  
			  and a.cost_center_dept_id in (select dept_id from #locListCBANKRECON)  
			  and ISNULL(RECON_DT,'')<>'' AND isnull(a.AUTOENTRY,0)=0
	 ) e ON c.vm_id=e.vm_id 
	 JOIN 
	 (
			 select vm_id,max(debit_amount) as debit_amount,
			 max(credit_amount) as credit_amount
			 from vd01106 (NOLOCK) where vm_id in (
				 select a.vm_id from vd01106 a (NOLOCK) join vm01106 b (NOLOCK) on a.vm_id=b.vm_id
				 where a.ac_code=@CACCODE and cancelled=0 AND ISNULL(b.op_entry,0)=0  
				 and a.cost_center_dept_id in (select dept_id from #locListCBANKRECON)  
				 AND isnUll(RECON_DT,'')<>'' AND isnull(a.AUTOENTRY,0)=0)
			 GROUP BY vm_id) f 
	 ON c.vm_id=f.vm_id
	 AND ((CASE WHEN e.debit_amount>0  THEN 0 ELSE a.debit_amount END)=f.debit_amount OR
	 (CASE WHEN e.credit_amount>0  THEN 0 ELSE a.credit_amount END)=f.credit_amount)
	 where(a.ac_code <> e.ac_code)  
	 and a.cost_center_dept_id in (select dept_id from #locListCBANKRECON)  
	 and (E.recon_dt between  @DFROMDT and @dToDt)  and isnull(c.cancelled,0)=0 
	 AND isnull(a.AUTOENTRY,0)=0 
	 UNION ALL 
	 SELECT a.row_id AS vd_id, '' AS vs_ac_vd_id, 0.0 AS balance,'chq no : ' + chq_no AS narration, '' AS vm_id, 
	 CONVERT(CHAR(10),  (CASE WHEN a.recon_dt ='' THEN NULL ELSE a.RECON_DT END),105) AS recondt, 
	 a.chq_amt_type  AS x_type, '' AS voucher_type, 
	 a.chq_dt AS voucher_dt, '' AS voucher_no,  b.AC_NAME ,b.AC_CODE , 
	 CASE WHEN a.chq_amt_type ='Dr' THEN chq_Amt ELSE 0 END AS debit_amount, 
	 CASE WHEN a.chq_amt_type ='Dr' THEN 0 ELSE chq_Amt  END AS credit_amount 
	 FROM bank_op_chq a (NOLOCK) 
	 JOIN LM01106 b (NOLOCK) ON a.ac_code = b.AC_CODE 
	 WHERE Bank_ac_code = @CACCODE AND ISNULL(a.recon_dt,'') <>'' 
	 AND (isnull(a.recon_dt ,'') BETWEEN @DFROMDT AND @dToDt) 
	  order by recondt,e.x_type, e.debit_amount, e.credit_amount,c.voucher_dt 

	 select * from #tmpbankM a WHERE vs_ac_vd_id=(select top 1 vs_ac_vd_id FROM #tmpbankM WHERE 
	 vd_id=a.vd_id) 


	GOTO END_PROC
END_PROC:

END
--END OF PROCEDURE - SP3S_BANKRECON