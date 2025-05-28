CREATE PROCEDURE SP3S_ACT_TRIALLIST--(LocId 3 digit change by Sanjay:04-11-2024)
@cFinYear VARCHAR(5)='',    
@cParentHeadCode CHAR(10)='',    
@dFromDtPara DATETIME='',    
@dToDtPara DATETIME='',    
@nSpId VARCHAR(50)='',
@bCalledfromPrint BIT=0,    
@nMode NUMERIC(1,0)=1,  
@bCalledFromReminders BIT=0 ,
@nFormat INT=11,
@nEXPANDED INT=0,
@nDOnotSuppressvalue NUMERIC(1,0)=0
AS        
BEGIN        
BEGIN TRY        
    
 DECLARE @cStep VARCHAR(4),@cErrormsg varchar(max),@cCmd NVARCHAR(MAX),@CDONOTPICKOBHEADS VARCHAR(2000),@dFromDt DATETIME,@dToDt DATETIME,    
 @dFinYearFromDt DATETIME,@dOpnStkDt DATETIME,@CPICKPROFILTLOSSHEADS VARCHAR(2000),@bShowforAllLocs BIT,@cDtSuffix VARCHAR(20),    
 @nNetProfitLossAmt NUMERIC(20,2),@cPrevFinYear VARCHAR(5) ,@cFinYearPara varchar(5),@dMaxVOucherDt DATETIME,
 @cViewTrialForCancelledVouchers VARCHAR(20)   
     
 SET @cStep='5'
  SELECT TOP 1 @cViewTrialForCancelledVouchers=value FROM config WHERE config_option='LEDGER_OPENING_CUTOFF_DATE'    
     
  SET @cViewTrialForCancelledVouchers=ISNULL(@cViewTrialForCancelledVouchers,'')     
 
 SET @cStep='10'     
 IF @dFromDtPara=''    
 BEGIN    
  SELECT @dFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1),@dToDt=dbo.FN_GETFINYEARDATE(@cFinYear,2)      
    
  SET @dFinYearFromDt=@dFromDt    
 END    
 ELSE    
 BEGIN    
  SET @cFinYear='01'+dbo.FN_GETFINYEAR(@dFromDtPara)    
  SET @dFinYearFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)    
    
  SELECT @dFromDt=@dFromDtPara,@dToDt=@dToDtPara    
 END    
     
 SET @dOpnStkDt=DBO.FN_GETFINYEARDATE(@CFINYEAR,1)-1      
     
 SET @cStep='20'        
 IF OBJECT_ID('tempdb..#tmpHeads','u') is not null        
  drop table #tmpHeads        
    
 IF OBJECT_ID('tempdb..#tmpTrial','u') is not null        
  drop table #tmpTrial        
    
 IF OBJECT_ID('tempdb..#tmpOb','u') is not null        
  drop table #tmpOb        
    
 IF OBJECT_ID('tempdb..#tmpXn','u') is not null        
  drop table #tmpXn       
     
 SET @cStep='30'     
 SET @bShowforAllLocs=1    
     
 CREATE TABLE #LOCLISTC (dept_id VARchar(4))    
     
 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
 BEGIN    
  INSERT #LOCLISTC    
  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId    
      
  SET @bShowforAllLocs=0    
 END     
 ELSE    
  INSERT #LOCLISTC    
  SELECT DEPT_ID FROM LOCATION WHERE LOC_TYPE=1 AND DEPT_ID=MAJOR_DEPT_ID    
    
    
  SET @cStep='40'     
 SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
 SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
 SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    
     
 SET @cStep='60'     
     
 CREATE TABLE #tmpHeads (head_Code char(10),bs_child_head_code char(10),bs_head_code CHAR(10),
 bshead_name varchar(1000),srno numeric(1,0),debtor_creditor BIT,debtor_head BIT)      
    
    
 INSERT #tmpHeads (head_code,bs_child_head_code, bs_head_code,bshead_name,srno)    
 SELECT head_code,'','','',1 as srno FROM hd01106 
 WHERE (@cParentHeadCode='' or CHARINDEX(HEAD_CODE,DBO.FN_ACT_TRAVTREE(@cParentHeadCode))>0)   
 union    
 SELECT 'ZZZZZZZ' AS head_code,'','','ZZZZZZZ',2 as srno FROM hd01106    
 

 SET @cStep='70'     
 UPDATE #tmpHeads SET bs_child_head_code=dbo.FN_GET_BSHEADCODE(head_code)      
     
 UPDATE a SET bs_head_code=b.major_head_code,bshead_name=c.head_name FROM #tmpHeads a      
 JOIN hd01106 b ON a.bs_child_head_code=b.head_code    
 JOIN hd01106 c ON b.major_head_code=c.head_code    
 
	UPDATE #tmpHeads SET debtor_creditor=1
	WHERE (CHARINDEX(head_code,DBO.FN_ACT_TRAVTREE('0000000018'))>0
	OR CHARINDEX(head_code,DBO.FN_ACT_TRAVTREE('0000000021'))>0) 

	UPDATE #tmpHeads SET debtor_head=1
	WHERE CHARINDEX(head_code,DBO.FN_ACT_TRAVTREE('0000000018'))>0
	

	IF @nEXPANDED=0
		UPDATE #tmpHeads SET bs_child_head_code=(CASE WHEN CHARINDEX(head_code,DBO.FN_ACT_TRAVTREE('0000000018'))>0
		THEN '0000000018' ELSE '0000000021' END)
		WHERE debtor_creditor=1
	
  --   if @@spid=53
		--select 'check tmpheads',* from  #tmpHeads where head_code='0000000021'
     
 SET @cPrevFinYear='01'+dbo.FN_GETFINYEAR(@dFinYearFromDt-1)    
   
     
 SET @cStep='80'     
 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)        
 create table #tmpTrial (ac_code char(10),bshead_name varchar(200),head_name varchar(500),Ac_name varchar(500),    
 opening_debit numeric(20, 2), opening_credit numeric(20,2),xns_Debit numeric(20, 2), xns_Credit numeric(20,2),    
 closing_debit numeric(20, 2), closing_credit numeric(20,2),mode INT,BSHEAD_NAME_BAK VARCHAR(200),HEAD_NAME_BAK VARCHAR(200))         
    
 create table #tmpob (ac_code char(10),debit numeric(20, 2), credit numeric(20,2))         
 create table #tmpXn (ac_code char(10),debit numeric(20, 2), credit numeric(20,2))         
     
 SET @cStep='90'     
 insert #tmpob (ac_code,debit, credit)        
 select lm.major_ac_code,  sum(debit_amount)  as opening_debit,  sum(credit_amount) as opening_credit   
 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID        
 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE        
 join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
 JOIN #tmpHeads hd ON hd.head_code=lm.HEAD_CODE
 JOIN #LOCLISTC l ON l.dept_id=vd.cost_center_dept_id    
 where vm.VOUCHER_dT<@dFinYearFromDt   AND  charindex(lm.HEAD_CODE,@CDONOTPICKOBHEADS)=0    
 and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')        
AND  ((CANCELLED=0 AND ISNULL(debtor_head,0)=0)
    OR (VOUCHER_DT>@cViewTrialForCancelledVouchers AND ISNULL(debtor_head,0)=1 AND cancelled=0)
    OR (@cViewTrialForCancelledVouchers<>'' AND ISNULL(consider_for_ledger_view,0)=1     
     AND VOUCHER_DT<=@cViewTrialForCancelledVouchers AND ISNULL(debtor_head,0)=1))  

 GROUP BY lm.major_ac_code
 HAVING sum(DEBIT_AMOUNT - CREDIT_AMOUNT)<>0    
     
 SET @cStep='100'    
 IF NOT (DATEPART(MM,@dFromDt)=4 AND DATEPART(DD,@dFromDt)=1)    
 BEGIN    
  SET @cStep='110'     
  insert #tmpob (ac_code,debit, credit)        
  select lm.major_ac_code,  sum(debit_amount)  as opening_debit,  sum(credit_amount) as opening_credit    
  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID        
  join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE        
  join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
  JOIN #LOCLISTC l ON l.dept_id=vd.cost_center_dept_id    
  JOIN #tmpHeads hd ON hd.head_code=lm.HEAD_CODE
  where vm.VOUCHER_dT BETWEEN @dFinyearFromDt AND @dFromDt-1  
  and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')        
AND  ((CANCELLED=0 AND ISNULL(debtor_head,0)=0)
    OR (VOUCHER_DT>@cViewTrialForCancelledVouchers AND ISNULL(debtor_head,0)=1 AND cancelled=0)
    OR (@cViewTrialForCancelledVouchers<>'' AND ISNULL(consider_for_ledger_view,0)=1     
     AND VOUCHER_DT<=@cViewTrialForCancelledVouchers AND ISNULL(debtor_head,0)=1))  
  GROUP BY lm.major_ac_code    
  HAVING sum(DEBIT_AMOUNT - CREDIT_AMOUNT)<>0    
      
 END    
       
 --IF @bCalledFromReminders=0     
 --  insert #tmpob (ac_code, credit,debit)        
 --  SELECT '0000000002',(CASE WHEN NetProfitLossAmt<0 THEN ABS(NetProfitLossAmt) ELSE 0 END),    
 --  (CASE WHEN NetProfitLossAmt>0 THEN ABS(NetProfitLossAmt) ELSE 0 END)     
 --  FROM Trial_profitloss_locwise a  (NOLOCK)
 --  JOIN #LOCLISTC b ON a.dept_id=b.dept_id  
 --  WHERE a.fin_year=@cPrevFinYear  


 insert #tmpTrial (ac_code,bshead_name,head_name,Ac_name,opening_debit,opening_credit,xns_Debit,xns_Credit,closing_debit,closing_credit,mode)     
 SELECT '0000000002' as ac_code,'PROFIT  &  LOSS A/C' as bshead_name,'PROFIT  &  LOSS A/C' as head_name,
 'PROFIT  &  LOSS A/C' as ac_name,    
 SUM(OPENING_DEBIT) OPENING_DEBIT,SUM(OPENING_CREDIT) opening_credit,
 0 xns_Debit,0 xns_Credit,
 SUM(CLOSING_DEBIT) CLOSING_DEBIT,SUM(CLOSING_CREDIT) CLOSING_CREDIT,1 mode
 from  
 (
 SELECT  SUM(CASE WHEN NetProfitLossAmt<0 THEN 0 ELSE NetProfitLossAmt END) as opening_debit,
 SUM(CASE WHEN NetProfitLossAmt<0 THEN ABS(NetProfitLossAmt) ELSE 0 END)  as opening_credit,
 convert(numeric(20,2),0) closing_debit,convert(numeric(20,2),0) closing_credit
 FROM Trial_profitloss_locwise A (NOLOCK)      
 JOIN #LOCLISTC LOCLIST ON A.DEPT_ID = LOCLIST.DEPT_ID      
 WHERE A.fin_year = @cPrevFinYear         

 UNION ALL
 SELECT 0 as opening_debit,0 as opening_credit,
 SUM(CASE WHEN NetProfitLossAmt<0 THEN 0 ELSE NetProfitLossAmt END) as closing_debit,
 SUM(CASE WHEN NetProfitLossAmt<0 THEN ABS(NetProfitLossAmt) ELSE 0 END)  as closing_credit
 FROM Trial_profitloss_locwise A (NOLOCK)       
 JOIN #LOCLISTC LOCLIST ON A.DEPT_ID = LOCLIST.DEPT_ID      
 WHERE A.fin_year = @cPrevFinYear
 ) a
     
 SET @cStep='130'     
 insert #tmpXn (ac_code,Debit, Credit)        
 select lm.major_ac_code,sum(debit_amount) as Debit,  sum(credit_amount) as credit    
 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID        
 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE        
 join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE        
 JOIN #LOCLISTC l ON l.dept_id=vd.cost_center_dept_id    
 JOIN #tmpHeads hd ON hd.head_code=lm.HEAD_CODE
 where vm.voucher_dt between @dFromDt AND @dToDt 
 and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')        
 AND  ((CANCELLED=0 AND ISNULL(debtor_head,0)=0)
    OR (VOUCHER_DT>@cViewTrialForCancelledVouchers AND ISNULL(debtor_head,0)=1 AND cancelled=0)
    OR (@cViewTrialForCancelledVouchers<>'' AND ISNULL(consider_for_ledger_view,0)=1     
     AND VOUCHER_DT<=@cViewTrialForCancelledVouchers AND ISNULL(debtor_head,0)=1))  
 GROUP BY lm.major_ac_code     
     
 SET @cStep='150'       
 insert #tmpTrial (ac_code,bshead_name,head_name,Ac_name,opening_debit,opening_credit,xns_Debit,xns_Credit,closing_debit,closing_credit,mode)        
 SELECT (CASE WHEN @nExpanded=0 AND ISNULL(thd.debtor_creditor,0)=1 THEN '0000000000'
 ELSE lm.ac_code END) ac_code,bshd.HEAD_NAME as bshead_name,
 (CASE WHEN @nExpanded=0 AND ISNULL(thd.debtor_creditor,0)=1 THEN bschd.HEAD_NAME ELSE  hd.head_name END),
 (CASE WHEN @nExpanded=0 AND ISNULL(thd.debtor_creditor,0)=1 THEN ''
 ELSE lm.ac_name END) Ac_name,SUM(opening_debit) as opening_debit,    
 SUM(opening_credit) as opening_credit,SUM(xns_debit) as xns_debit,SUM(xns_credit) as xns_credit,    
 SUM(opening_debit+xns_debit) as closing_debit,SUM(opening_credit+xns_credit) as closing_credit,1 as mode    
 FROM    
 (SELECT ac_code,debit as opening_debit,Credit as opening_credit,0 as xns_debit,0 as xns_credit    
  FROM #tmpob    
  UNION ALL    
  SELECT ac_code,0 as opening_debit,0 as opening_credit,debit as xns_debit,credit as xns_credit    
  FROM #tmpXn    
  ) a    
  LEFT JOIN LM01106 lm (NOLOCK) ON lm.AC_CODE=a.AC_CODE    
  JOIN #tmpHeads thd ON thd.head_Code=lm.HEAD_CODE    
  JOIN hd01106 bshd on bshd.head_code=thd.bs_head_code      
  JOIN hd01106 hd on hd.head_code=LM.HEAD_CODE    
  left JOIN hd01106 bschd on bschd.head_code=thd.bs_child_head_code
  GROUP BY (CASE WHEN @nExpanded=0 AND ISNULL(thd.debtor_creditor,0)=1 THEN '0000000000'
				 ELSE lm.ac_code END),bshd.HEAD_NAME,(CASE WHEN @nExpanded=0 AND ISNULL(thd.debtor_creditor,0)=1 THEN bschd.HEAD_NAME ELSE  hd.head_name END),
			(CASE WHEN @nExpanded=0 AND ISNULL(thd.debtor_creditor,0)=1 THEN ''
			 ELSE lm.ac_name END)
     
  SET @cStep='160'     
  
 	DECLARE @bEntryFound BIT,@nCbP NUMERIC(20,2),@dXndt DATETIME


	SET @bEntryFound=0
	EXEC SP3S_GETMANUAL_ACCOUNTS_CBS
	@dXnDt=@dOpnStkDt,
	@nCbp=@nCbp OUTPUT,
	@bEntryFound=@bEntryFound OUTPUT
	
	
	IF @bEntryFound=0 
	BEGIN
		SET @cStep='165'    
		SELECT @nCbp=SUM(OpnStkinHand) FROM Trial_profitloss_locwise a (NOLOCK)
		JOIN #LOCLISTC b ON a.dept_id=b.dept_id WHERE a.fin_year=@cFinYear
	END		

	SELECT @cDtSuffix='('+CONVERT(VARCHAR,@dFromDtPara,105)+')'	
	
	SET @cStep='168'    
 IF @cParentHeadCode='' 
	 insert #tmpTrial (ac_code,bshead_name,head_name,Ac_name,opening_debit,opening_credit,xns_Debit,xns_Credit,closing_debit,closing_credit,mode)     
	 SELECT '0000000000' as ac_code,'CURRENT ASSETS' as bshead_name,'STOCK IN HAND' as head_name,'STOCK IN HAND'+@cDtSuffix as ac_name,    
	 ISNULL(@nCbp,0) as opening_debit,0 AS credit,0 AS xns_Debit,0 AS xns_Credit,ISNULL(@nCbp,0) as closing_debit,0 as closing_credit,1 as mode    
 
 SET @cStep='172'        
 UPDATE #tmpTrial SET opening_debit=opening_debit-opening_credit,    
 opening_credit=0 WHERE (opening_debit-opening_credit)>=0    
    
 UPDATE #tmpTrial SET opening_credit=ABS(opening_debit-opening_credit),    
 opening_debit=0 WHERE (opening_debit-opening_credit)<0    
    
 UPDATE #tmpTrial SET closing_debit=closing_debit-closing_credit,    
 closing_credit=0 WHERE (closing_debit-closing_credit)>=0    
    
 UPDATE #tmpTrial SET closing_credit=ABS(closing_debit-closing_credit),    
 closing_debit=0 WHERE (closing_debit-closing_credit)<0    
 
 SET @cStep='175'        
 IF @nMode=1    
  DELETE FROM #tmpTrial WHERE opening_credit+opening_debit=0 AND xns_Credit+xns_Debit=0    
 ELSE    
 IF @nMode=2    
  DELETE FROM #tmpTrial WHERE (opening_credit+opening_debit)=0    
 ELSE    
 IF @nMode=3    
  DELETE FROM #tmpTrial WHERE (closing_credit+closing_debit)=0    
  
 IF @bCalledFromReminders=1    
 BEGIN  
	 INSERT #TMPCLOSING  (HEAD_NAME,AC_code,LEDGER_BAL)  
	 SELECT head_name,ac_code,(closing_debit-closing_credit) FROM #tmpTrial  
  
	 RETURN  
 END 
   
 SET @cStep='180'      
 insert #tmpTrial (bshead_name,head_name,Ac_name,opening_debit,opening_credit,xns_debit,xns_Credit,    
 closing_debit,closing_credit,mode)        
 select bshead_name,head_name,'Total : ' as Ac_name,     
 SUM(opening_debit) AS opening_debit,SUM(opening_credit) AS opening_credit,    
 SUM(xns_debit) AS xns_debit,SUM(xns_credit) AS xns_credit,    
 SUM(closing_debit) AS closing_debit,SUM(closing_credit) AS closing_credit,2 as mode     
 FROM   #tmpTrial     
 GROUP BY bshead_name,head_name      
     
 SET @cStep='190'     
 insert #tmpTrial (bshead_name,head_name,Ac_name,opening_debit,opening_credit,xns_debit,xns_Credit,    
 closing_debit,closing_credit,mode)      
 select bshead_name,'ZZZZZZZZZZ' as head_name,'Total : ' as Ac_name,     
 SUM(opening_debit) AS opening_debit,SUM(opening_credit) AS opening_credit,    
 SUM(xns_debit) AS xns_debit,SUM(xns_credit) AS xns_credit,    
 SUM(closing_debit) AS closing_debit,SUM(closing_credit) AS closing_credit ,3 as mode     
 FROM   #tmpTrial     
 WHERE mode=2    
 GROUP BY bshead_name      
    
 if (SELECT COUNT(*) FROM #tmpTrial)>0    
 BEGIN    
	  SET @cStep='200'     
	  insert #tmpTrial (bshead_name,head_name,Ac_name,opening_debit,opening_credit,xns_debit,xns_Credit,    
	  closing_debit,closing_credit,mode)      
	  select 'ZZZZZZZ' as bshead_name,'ZZZZZZZ' as head_name,'Grand Total : ' as Ac_name,     
	  SUM(opening_debit) AS opening_debit,SUM(opening_credit) AS opening_credit,    
	  SUM(xns_debit) AS xns_debit,SUM(xns_credit) AS xns_credit,    
	  SUM(closing_debit) AS closing_debit,SUM(closing_credit) AS closing_credit ,4 as mode     
	  FROM   #tmpTrial     
	  WHERE mode=2     
 END    
     
 SET @cStep='210'     
 IF OBJECT_ID('tempdb..#tmpTrial_output','u') is not null        
  drop table #tmpTrial_output    
    
 select ac_code,ROW_NUMBER() OVER(PARTITION BY bshead_name ,head_name ORDER BY bshead_name ,head_name,ac_name,mode) AS SRNO,    
 bshead_name AS bs_head_name,head_name,Ac_name,opening_debit,opening_credit,xns_debit,xns_Credit,    
 closing_debit,closing_credit ,mode    
 ,bshead_name AS DISPLAY_bs_head_name,head_name AS DISPLAY_head_name,Ac_name AS DISPLAY_Ac_name    
 INTO #tmpTrial_output    
 from #tmpTrial       
     
 SET @cStep='220'     
 --SELECT * FROM #tmpTrial_output
 
 IF @nDOnotSuppressvalue=0
 BEGIN
	 UPDATE #tmpTrial_output SET DISPLAY_bs_head_name='',DISPLAY_head_name=''    
	 WHERE srno >1    
    
	 UPDATE #tmpTrial_output SET DISPLAY_bs_head_name=(CASE WHEN mode<>3 THEN '' ELSE DISPLAY_bs_head_name END),DISPLAY_head_name=''    
	 WHERE mode >1    
    
	 UPDATE #tmpTrial_output SET opening_debit= NULL WHERE opening_debit=0    
    
	 UPDATE #tmpTrial_output SET opening_credit= NULL WHERE opening_credit=0    
    
	 UPDATE #tmpTrial_output SET xns_debit= NULL WHERE xns_debit=0    
    
	 UPDATE #tmpTrial_output SET xns_credit= NULL WHERE xns_credit=0    
    
	 UPDATE #tmpTrial_output SET closing_debit= NULL WHERE closing_debit=0    
    
	 UPDATE #tmpTrial_output SET closing_credit= NULL WHERE closing_credit=0    
 END
 
 --drop table Trialoutput_1920      
 SET @cStep='230'  
 if @nFormat=12
 BEGIN
	UPDATE #tmpTrial_output SET DISPLAY_Ac_name= 'Total ('+bs_head_name+') : '  WHERE 'ZZZZZZZZZZ' = head_name   

	SELECT DISTINCT '' AC_CODE,A.BSHEAD_NAME BS_HEAD_NAME,HEAD_NAME,HEAD_NAME AC_NAME,NULL OPENING_DEBIT,NULL OPENING_CREDIT,NULL XNS_DEBIT,NULL XNS_CREDIT,    
	NULL CLOSING_DEBIT,NULL CLOSING_CREDIT,0 MODE,A.BSHEAD_NAME DISPLAY_BS_HEAD_NAME,HEAD_NAME DISPLAY_HEAD_NAME,HEAD_NAME DISPLAY_AC_NAME,    
	CAST(4 AS INT) AS  FORMAT_REQ ,B.SRNO 
	--INTO TRIALOUTPUT_1920      
	FROM #TMPTRIAL A
	JOIN 
	(
	SELECT DISTINCT BSHEAD_NAME,SRNO FROM #TMPHEADS
	) B ON B.BSHEAD_NAME=A.BSHEAD_NAME
	WHERE HEAD_NAME NOT IN('ZZZZZZZ','ZZZZZZZZZZ') AND AC_NAME NOT LIKE 'TOTAL%'
	UNION ALL
	SELECT AC_CODE,BS_HEAD_NAME,HEAD_NAME,AC_NAME,OPENING_DEBIT,OPENING_CREDIT,XNS_DEBIT,XNS_CREDIT,    
	CLOSING_DEBIT,CLOSING_CREDIT,MODE,DISPLAY_BS_HEAD_NAME,DISPLAY_HEAD_NAME,DISPLAY_AC_NAME,    
	CAST((CASE WHEN MODE=1 AND ISNULL(DISPLAY_HEAD_NAME,'')='' THEN 0 ELSE MODE END) AS INT) AS  FORMAT_REQ    ,B.SRNO 
	--INTO TRIALOUTPUT_1920    
	FROM #TMPTRIAL_OUTPUT  A    
	JOIN 
	(
	SELECT DISTINCT BSHEAD_NAME,SRNO FROM #TMPHEADS
	) B ON B.BSHEAD_NAME=A.BS_HEAD_NAME    
	ORDER BY SRNO,BS_HEAD_NAME,HEAD_NAME,MODE ,AC_NAME  ,AC_CODE    
 END
 ELSE
 BEGIN
	SELECT AC_CODE,BS_HEAD_NAME,HEAD_NAME,AC_NAME,OPENING_DEBIT,OPENING_CREDIT,XNS_DEBIT,XNS_CREDIT,    
	CLOSING_DEBIT,CLOSING_CREDIT,MODE,DISPLAY_BS_HEAD_NAME,DISPLAY_HEAD_NAME,DISPLAY_AC_NAME,    
	CAST((CASE WHEN MODE=1 AND ISNULL(DISPLAY_HEAD_NAME,'')='' THEN 0 ELSE MODE END) AS INT) AS  FORMAT_REQ    ,B.SRNO 
	--INTO TRIALOUTPUT_1920    
	FROM #TMPTRIAL_OUTPUT  A    
	JOIN 
	(
		SELECT DISTINCT BSHEAD_NAME,SRNO FROM #TMPHEADS
	) B ON B.BSHEAD_NAME=A.BS_HEAD_NAME    
	ORDER BY SRNO,BS_HEAD_NAME,HEAD_NAME,MODE ,AC_NAME  ,AC_CODE  
 END

 SET @cStep='200'
	IF (EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='TRIALLIST_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0))
	  	DROP TABLE TRIALLIST_CURSOR

	IF  OBJECT_ID('TRIALLIST_CURSOR','U') IS NULL	
	BEGIN
		SELECT AC_CODE,BS_HEAD_NAME,HEAD_NAME,AC_NAME,OPENING_DEBIT,OPENING_CREDIT,XNS_DEBIT,XNS_CREDIT,    
		CLOSING_DEBIT,CLOSING_CREDIT,MODE,DISPLAY_BS_HEAD_NAME,DISPLAY_HEAD_NAME,DISPLAY_AC_NAME,    
		CAST((CASE WHEN MODE=1 AND ISNULL(DISPLAY_HEAD_NAME,'')='' THEN 0 ELSE MODE END) AS INT) AS  FORMAT_REQ    ,CAST(0 AS INT) AS SRNO 
		INTO TRIALLIST_CURSOR     
		FROM #TMPTRIAL_OUTPUT  A    
		WHERE 1=2
	END



END TRY         
    
 BEGIN CATCH        
  SET @cErrormsg='Error in Procedure SP3S_act_triallist at Step#'+@cStep+':'+ERROR_MESSAGE()        
  goto end_proc        
 END CATCH      
    
end_proc:        
 IF ISNULL(@cErrormsg,'')<>''        
  select ISNULL(@cErrormsg,'') as DISPLAY_bs_head_name        
END        
---End Trial Balance-----------------------------------  
