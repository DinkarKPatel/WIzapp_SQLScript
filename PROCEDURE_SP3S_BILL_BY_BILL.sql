create PROCEDURE SP3S_BILL_BY_BILL --(LocId 3 digit change  by Sanjay:04-11-2024)
(  
 @CAC_CODE VARCHAR(20)='',  
 @DT_TODATE DATETIME='',  
 @CLOCID VARCHAR(4)='',  
 @CXTYPE VARCHAR(5)='',  
 @CVMID VARCHAR(40)='',--'JM6761032B-97AC-41AE-91B2-054CDB795A12',  
 @NMODE NUMERIC(1,0)=1,---- @NMODE=1 --- CALLED FROM VOUCHER ENTRY NAVIGATION  
        ---- @NMODE=2 --- CALLED FROM VOUCHER ENTRY ADD/EDIT   
        ---- @NMODE=3 --- CALLED FROM REPORTING  
 @NDUEBILLMODE INT=1,---- @NDUEBILLMODE=1 --- DUE BILLS  
        ---- @NDUEBILLMODE=2 --- SETTLED BILLS  
        ---- @NDUEBILLMODE=3 --- ALL BILLS  
		---- @NDUEBILLMODE=4 --- Pending BILLS  
 @NOUTSTANDINGMODE INT=0,  
 @BSHOWMRRNO BIT=0,  
 @nUpdateMode NUMERIC(1,0)=0,  
 @cSPID  VARCHAR(50)='',  
 @bCalledFromSingleLedger BIT=0  
 ,@nSortOn NUMERIC(2,0)=1---- @nSortOn=1 --- SORT ON BILL DATE  
        ---- @nSortOn=2 --- SORT ON DUE DATE  
 ,@bConsiderUptoDate BIT=0
 ,@bSHowOnAccountEntries BIT=1,
 @cCompanyPanNo VARCHAR(20)=''
)  
AS  
BEGIN  
        
   IF @cSPID=''  
  SET @cSPID=CAST(@@SPID AS VARCHAR(5))  
  
   IF @NDUEBILLMODE=2 AND @nMode=3 AND @bConsiderUptoDate=0
	   SET @DT_TODATE='9999-01-01'  
         
  DECLARE @FIXEDHEADS VARCHAR(max),@CCREDITORHEADS VARCHAR(max),@CDEBTORHEADS VARCHAR(max),  
    @CCMD NVARCHAR(MAX)  ,@bLoc BIT,@cHoLocId VARCHAR(4),@cCurLocId varchar(4)
  
  
  select @cHoLocId= value from config (nolock) where config_option='ho_location_id'
  select @cCurLocId=value from config (nolock) where config_option='location_id'
  
  set @bLoc=0
  
  if @cCurLocId<>@cHoLocId
	set @bLoc=1
	
  DECLARE @dtAcCode TABLE (AC_CODE VARCHAR(50))  
    
  SELECT @FIXEDHEADS = DBO.FN_ACT_TRAVTREE( '0000000005' ),  
  @CDEBTORHEADS = DBO.FN_ACT_TRAVTREE( '0000000018' ),  
  @CCREDITORHEADS = DBO.FN_ACT_TRAVTREE( '0000000021' )   
    
  IF OBJECT_ID('TEMPDB..#TMPLOCLIST','U') IS NOT NULL  
   DROP TABLE #TMPLOCLIST  
     
  SELECT DEPT_ID INTO #TMPLOCLIST FROM LOCATION WHERE 1=2  
    
  IF OBJECT_ID('TEMPDB..#TMPBB','U') IS NOT NULL  
   DROP TABLE #TMPBB  
    
  IF @nMode IN (2)  
   INSERT #TMPLOCLIST  
   SELECT @cLocId AS DEPT_ID  
  ELSE  
  IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @cSPID AND dept_id<>'' ) AND @nMode<>5  
   INSERT #TMPLOCLIST  
   SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @cSPID AND dept_id<>''   
  ELSE  
   INSERT #TMPLOCLIST  
   SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1 OR @bLoc=1)  
  
  IF @NMODE IN (3,4,5,6,7,8) --- CALLED FROM REPORTING  
  BEGIN  
            
         DECLARE @DTSQL NVARCHAR(MAX)  
	   DECLARE @CCRDRHEADCODE VARCHAR(MAX)  
	   SET   @CCRDRHEADCODE=ISNULL(@CDEBTORHEADS,'')+','+isnull(@CCREDITORHEADS,'')  
  
	   IF OBJECT_ID ('TEMPDB..#TMPHEAD','U') IS NOT NULL  
		DROP TABLE #TMPHEAD  
		SELECT CAST('' AS VARCHAR(15)) AS HEAD_CODE  
		into #TMPHEAD  
		WHERE 1=2  
       
	   Print 'Select heads'
           
	   IF @CAC_CODE=''       
			SET @DTSQL=N'SELECT HEAD_CODE FROM HD01106 WHERE HEAD_CODE IN ('+@CCRDRHEADCODE+')'  
	   ELSE  
	   IF @nMode NOT IN (7,8)  
			SET @DTSQL=N'SELECT head_code from lm01106 where ac_code='''+@cAC_Code+''''  
	   ELSE  
	   IF @nMode = 7  
			SET @dTSql = 'SELECT head_code from HD01106 WHERE head_code in ('+dbo.FN_ACT_TRAVTREE(@cAC_Code)+')'  
	   ELSE
	   IF @nMode=8  
			SET @dTSql=N'SELECT DISTINCT b.head_code from LM_BROKER_DETAILS a (NOLOCK)
						JOIN lm01106 b (NOLOCK) ON b.ac_code=a.ac_code  where broker_ac_code='''+@cAC_Code+''''            
		
	   PRINT @DTSQL  
	   insert into #TMPHEAD  
	   exec sp_executesql @DTSQL  
                 
	   DECLARE @cStr VARCHAR(MAX)='tempdb..##BILL_BY_BILL_'+LTRIM(RTRIM(@cSPID))  
  
	   IF  @NMODE = 3 AND OBJECT_ID(@cstr,'u') IS NOT NULL  
	   BEGIN  
		SET @cCMD=N'SELECT AC_CODE FROM '+@cstr  
	   END  
	   ELSE   
	   IF @CAC_CODE<>'' AND @nMode NOT IN (7,8)       
	   BEGIN  
		SET @cCMD=N'SELECT ac_code from lm01106 where ac_code='''+@cAC_Code+''''  
	   END  
	   ELSE  
	   IF @nMode=8  
		SET @cCMD=N'SELECT ac_code from LM_BROKER_DETAILS where broker_ac_code='''+@cAC_Code+''''            
	   ELSE  
	   BEGIN  
		SET @cCMD=N'SELECT AC_CODE FROM lm01106 a (NOLOCK)  
			JOIN #TMPHEAD b ON b.head_code=a.head_code'  
	   END  
     
	   PRINT @cCmd  
	   INSERT INTO @dtAcCode(AC_CODE)  
	   EXEC SP_EXECUTESQL @cCMD  
       
	 --  if @@spid=149
		--select 'check dtaccode',@CCREDITORHEADS,@DT_TODATE,@nDueBillMode from @dtAcCode where ac_code='H100000143'

	   IF OBJECT_ID('TEMPDB..#TMPPENDINGBILLS','U') IS NOT NULL  
		DROP TABLE #TMPPENDINGBILLS  
  
  
	   PRINT 'Get Pending bills List'  
	   ;WITH ALL_BILLS  
	   AS  
	   (  
		SELECT C.AC_CODE,A.REF_NO,SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT ELSE -A.AMOUNT END) AS AMOUNT  
		   ,SUM(CASE WHEN A.X_TYPE='DR' THEN A.AMOUNT ELSE 0 END) AS DEBIT_AMOUNT  
		   ,SUM(CASE WHEN A.X_TYPE='CR' THEN A.AMOUNT ELSE 0 END) AS CREDIT_AMOUNT
		   ,SUM(CASE WHEN A.X_TYPE='DR' THEN A.amount_forex ELSE -A.amount_forex END) AS amount_forex  
		   ,SUM(CASE WHEN A.X_TYPE='DR' THEN A.amount_forex ELSE 0 END) AS debit_amount_forex  
		   ,SUM(CASE WHEN A.X_TYPE='CR' THEN A.amount_forex ELSE 0 END) AS credit_amount_forex  		   
		   FROM BILL_BY_BILL_REF A (NOLOCK)      
		   JOIN VD01106 C (NOLOCK) ON A.VD_ID=C.VD_ID     
		   JOIN VM01106 D (NOLOCK) ON C.VM_ID=D.VM_ID     
		   JOIN LMP01106 LM ON LM.AC_CODE=C.AC_CODE  
		   JOIN @dtAcCode ac ON ac.ac_code=LM.ac_code  
		   JOIN #TMPLOCLIST l ON l.dept_id=c.cost_center_dept_id  
		   WHERE((@bConsiderUptoDate =1 and @NMODE in(3,5)) or (D.VOUCHER_DT <= @DT_TODATE))
		   AND CANCELLED=0 AND BILL_BY_BILL=1   
		   GROUP BY C.AC_CODE,A.REF_NO  
	   )  
	   SELECT A.REF_NO,CONVERT(DATETIME,'') AS BILL_DT,CONVERT(DATETIME,'') AS DUE_DATE,convert(numeric(10,0),LMP.CREDIT_DAYS) AS CR_DAYS,  
	   A.AC_CODE,LM.AC_NAME,ABS(A.AMOUNT) AS PENDING_AMOUNT,ABS(A.amount_forex) AS PENDING_amount_forex,LM.HEAD_CODE,  
	   (CASE WHEN A.AMOUNT<0 THEN 'CR' ELSE 'DR' END) AS PENDING_AMOUNT_CR_DR,CONVERT(VARCHAR(50),'') AS MRR_NO,  
	   CONVERT(NUMERIC(7,3),0) AS DISCOUNT_PERCENTAGE,CONVERT(NUMERIC(7,3),0) AS LM_DISCOUNT_PERCENTAGE,  
	   CONVERT(VARCHAR(5),'') AS LM_CR_DAYS,CONVERT(DATETIME,'') AS REF_DATE,CONVERT(VARCHAR(5),'') AS cd_posted,  
	   A.CREDIT_AMOUNT,A.DEBIT_AMOUNT,A.credit_amount_forex,A.debit_amount_forex,A.REF_NO AS DISPLAY_REF_NO,CONVERT(VARCHAR(20),'') AS bill_type,
	   convert(varchar(4),'') as cost_center_Dept_id --- SPECIALLY GIVEN FOR COLUMN FIRST PENDING BILL DATE   
						  --- GIVEN IN SUMMARY REPORT (NOT POSSIBLE FOR APPLICATION TO DO THIS  
						  --- AS TOLD BY SIR ON 19-12-2017        
	   ,CAST(0 AS NUMERIC(14,2)) AS cd_percentage,cast(0 as NUMERIC(14,2)) AS cd_amount  
	   ,CONVERT(VARCHAR(40),'') settlement_vm_id ,CONVERT(NUMERIC(20,2),0) RunningTotal,convert(varchar(5),'') RunningTotal_crdr
	   ,convert(varchar(20),'') RunningTotal_str,CONVERT(NUMERIC(20,2),0) RunningTotal_forex,convert(varchar(5),'') RunningTotal_crdr_Forex
	   ,convert(varchar(20),'') RunningTotal_str_Forex,CONVERT(BIT,0) on_acccount,convert(datetime,'') pur_vendor_bill_dt
  
	   INTO #TMPPENDINGBILLS  
	   FROM ALL_BILLS A  
	   JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.AC_CODE   
	   JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE=A.AC_CODE   
	   JOIN #TMPHEAD HD ON HD.HEAD_CODE=LM.HEAD_CODE   
	   WHERE ((@NOUTSTANDINGMODE=0 OR (@NOUTSTANDINGMODE=1 AND   
	   CHARINDEX(LM.HEAD_CODE,@CCREDITORHEADS)>0)  
		  OR (@NOUTSTANDINGMODE=2 AND CHARINDEX(LM.HEAD_CODE,@CDEBTORHEADS)>0)) )  
		  AND  
		((ABS(A.AMOUNT)>1 AND @nDueBillMode IN (1,4)) OR (ABS(A.AMOUNT)<=1 AND @nDueBillMode=2) OR (@nDueBillMode=3))  
		
		--if @@spid=149
		--	select 'check pending',* from #TMPPENDINGBILLS
	   print 'update cr days now-1'  
     
	   UPDATE A SET CR_DAYS=B.CR_DAYS,A.cd_amount=b.cd_amount,A.cd_percentage=b.cd_percentage ,
	   a.cd_posted=CASE WHEN ISNULL(B.cd_posted,0)=0 THEN 'N' ELSE 'Y' END ,pur_vendor_bill_dt=b.pur_vendor_bill_dt
	   FROM #TMPPENDINGBILLS A  
	   JOIN BILL_BY_BILL_REF B ON A.REF_NO=B.REF_NO  
	   JOIN VD01106 C ON C.VD_ID=B.VD_ID AND C.AC_CODE=A.AC_CODE  
	   JOIN VM01106 D ON D.VM_ID=C.VM_ID  
	   WHERE CANCELLED=0 AND C.VD_ID=(SELECT TOP 1 VD_ID FROM VD01106 E JOIN VM01106 F ON F.VM_ID=E.VM_ID  
	   JOIN LM01106 LM ON LM.AC_CODE=E.AC_CODE  
	   WHERE E.VD_ID=C.VD_ID AND F.CANCELLED=0   
	   AND E.X_TYPE=(CASE WHEN CHARINDEX(LM.HEAD_CODE,@CCREDITORHEADS)>0 THEN 'CR' ELSE 'DR' END))         
       
	   print 'update cr days now-2'  
	   IF @bSHowOnAccountEntries=0
		   DELETE a   FROM #TMPPENDINGBILLS A  
		   JOIN BILL_BY_BILL_REF B ON A.REF_NO=B.REF_NO  
		   JOIN VD01106 C ON C.VD_ID=B.VD_ID AND C.AC_CODE=A.AC_CODE  
		   JOIN lm01106 d ON d.ac_code=c.ac_code
		   JOIN vm01106 e (NOLOCK) ON e.vm_id=c.vm_id
   		   JOIN  location loc (NOLOCK) ON loc.dept_ac_code=c.ac_code
		   WHERE loc.sor_loc=1 AND b.on_account=1 AND e.cancelled=0


	   UPDATE A SET DUE_DATE=''   
	   FROM #TMPPENDINGBILLS A  
	   JOIN LM01106 LM ON LM.AC_CODE=A.AC_CODE   
	   WHERE (CHARINDEX(LM.HEAD_CODE,@CCREDITORHEADS)>0 AND A.PENDING_AMOUNT_CR_DR='Dr')  
	   OR (CHARINDEX(LM.HEAD_CODE,@CDEBTORHEADS)>0  AND A.PENDING_AMOUNT_CR_DR='Cr')  
	   OR (@nDueBillMode IN (3))  
     
	   IF @nMode=3   
	   BEGIN  
			
			IF @NDUEBILLMODE IN (2,3)
				UPDATE A SET settlement_vm_id=(SELECT TOP 1 D.VM_ID FROM BILL_BY_BILL_REF B  
					  JOIN VD01106 C ON C.VD_ID=B.VD_ID   
					  JOIN VM01106 D ON D.VM_ID=C.VM_ID  
					  JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE  
					  WHERE B.REF_NO=A.REF_NO AND C.AC_CODE=A.AC_CODE  
					  AND CANCELLED=0 AND d.voucher_code IN ('0000000002','0000000003')  
					  ORDER BY VOUCHER_DT DESC  
					 ) FROM  #TMPPENDINGBILLS A  
				WHERE a.PENDING_AMOUNT=0  
			
			UPDATE A SET settlement_vm_id=(SELECT TOP 1 D.VM_ID FROM BILL_BY_BILL_REF B  
					JOIN VD01106 C ON C.VD_ID=B.VD_ID   
					JOIN VM01106 D ON D.VM_ID=C.VM_ID  
					JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE  
					WHERE B.REF_NO=A.REF_NO AND C.AC_CODE=A.AC_CODE  
					AND CANCELLED=0 
					ORDER BY VOUCHER_DT DESC  
					) FROM  #TMPPENDINGBILLS A  
			WHERE ISNULL(settlement_vm_id,'')=''			
      
	   END  
	   ELSE  
	   IF @NMODE=4  
	   BEGIN  
		   IF OBJECT_ID('TEMPDB..#TMPDUEBILLS','U') IS NOT NULL  
		   BEGIN  
         
			 INSERT INTO #TMPDUEBILLS(REF_NO,AC_CODE,DUE_BILLS,DUE_BILLS_FOREX,DUE_DATE)  
			 SELECT A.REF_NO,AC_CODE,PENDING_AMOUNT,PENDING_amount_forex,DUE_DATE  
			 FROM #TMPPENDINGBILLS A  
			 WHERE (@NDUEBILLMODE=1 AND DUE_DATE<=@DT_TODATE) OR @NDUEBILLMODE=2   
       
		   END  
		   ELSE  
		   BEGIN  
				SELECT A.REF_NO,AC_CODE,PENDING_AMOUNT,PENDING_amount_forex,DUE_DATE  
				 FROM #TMPPENDINGBILLS A  
				 WHERE (@NDUEBILLMODE=1 AND DUE_DATE<=@DT_TODATE) OR @NDUEBILLMODE=2   
        
		   END  
		   RETURN  
	   END
	   EXEC SP3S_GETBILLINFO_PENDINGBB '#TMPPENDINGBILLS',@CDEBTORHEADS,@BSHOWMRRNO,@DT_TODATE,@NDUEBILLMODE,@nMode,@bCalledFromSingleLedger,@nSortOn   
     
     
     
     
  END  
  ELSE  
  IF @NMODE=1 --- CALLED FROM VOUCHER ENTRY NAVIGATION  
  BEGIN  
	   SELECT B.AC_CODE,AC_NAME,A.REF_NO AS BILL_NO,CONVERT(DATETIME,'') AS BILL_DT,  
	   CAST(0 AS NUMERIC(14,0)) AS DEBIT_AMOUNT,  
	   CAST(0 AS NUMERIC(14,0)) AS CREDIT_AMOUNT,
	   CAST(0 AS NUMERIC(14,0)) AS debit_amount_forex,  
	   CAST(0 AS NUMERIC(14,0)) AS credit_amount_forex,	   
	   a.due_dt AS DUE_DATE,cd_base_amount,  
	   (CASE WHEN ISDATE(RIGHT(a.REF_NO,8))=1 AND SUBSTRING(REVERSE(a.REF_NO),9,1)='/'   
		  THEN LEFT(a.REF_NO,LEN(a.REF_NO)-9) ELSE a.REF_NO END) AS DISPLAY_REF_NO,A.VD_ID,A.REF_NO,  
		  A.AMOUNT,a.amount_forex,A.LAST_UPDATE,A.X_TYPE,A.CR_DAYS,A.REMARKS,ADJ_REMARKS,PAYMENT_ADJ_REF_NO,BB_ROW_ID,B.VM_ID,  
	   CONVERT(BIT,0) AS SELECTED,AMOUNT AS ADJ_AMT,amount AS NET_AMT,amount_forex AS ADJ_amt_FOREX,amount_forex AS NET_amt_FOREX,  
	   A.X_TYPE AS [TYPE],A.CD_PERCENTAGE,A.CD_AMOUNT,d.bill_type,a.cd_posted,b.cost_center_dept_id,
	   a.org_bill_no,a.org_bill_dt,a.org_bill_amount,a.org_bill_amount_forex,a.manual_cd,
	   (CASE WHEN A.X_TYPE='DR' THEN 'Cr' ELSE 'Dr' END) as pending_amount_cr_dr,
	   a.ignore_cd_base_amount,a.PUR_VENDOR_BILL_DT

	   INTO #TMPNAVBILLS FROM BILL_BY_BILL_REF A   
	   JOIN VD01106 B ON A.VD_ID=B.VD_ID  
	   JOIN LM01106 C ON C.AC_CODE=B.AC_CODE  
	   JOIN vm01106 d (NOLOCK) ON d.vm_id=b.vm_id  
	   WHERE B.VM_ID=@CVMID  
     
	   EXEC SP3S_GETBILLINFO_PENDINGBB '#TMPNAVBILLS',@CDEBTORHEADS,0,@DT_TODATE  
  END   
    
END