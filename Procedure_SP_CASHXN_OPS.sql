create PROCEDURE SP_CASHXN_OPS  
(  
	 @BESTIMATEENABLED BIT = 1,  
	 @BSKIPSLSENTRIES BIT=0,  
	 @BCALLEDFROMPTCASH BIT=0,
	 @CUSERCODE  VARCHAR(15)='',
	 @CBINID	VARCHAR(10)=''
)  
AS  
BEGIN  
  --(dinkar) Replace  left(memoid,2) to Location_code 
 DECLARE  @NLOCOPENING NUMERIC(14,2),  
   @CCURRENTLOC VARCHAR(4),  
   @CHOLOC VARCHAR(4),  
   @CCONSIDERALLCASHXN VARCHAR(1),  
   @cHEAD_CODE VARCHAR(MAX)  
     
 SELECT TOP 1 @CCURRENTLOC =DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID   
 SELECT TOP 1 @CHOLOC = [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'HO_LOCATION_ID'  
  

  IF OBJECT_ID('TEMPDB..#LOC_EFF_DATES','U') IS NOT NULL
		DROP TABLE #LOC_EFF_DATES
	
	CREATE TABLE #LOC_EFF_DATES( MAJORDEPTID VARCHAR(4),DEPT_ID VARCHAR(4),EFF_DATE DATETIME,DEFFECTIVEDATE dateTime,FROMDT dateTime, TODT dateTime) 		
	
	INSERT #LOC_EFF_DATES(MAJORDEPTID,DEPT_ID,EFF_DATE,DEFFECTIVEDATE,FROMDT,TODT)	
	SELECT DEPT_ID as MAJORDEPTID, DEPT_ID,MAX(OPENING_CASH_DATE) ,
	       '' as DEFFECTIVEDATE,'' as FROMDT, convert(varchar(10),getdate(),121) as TODT
	FROM LOC_REQ 
	GROUP BY DEPT_ID

	INSERT #LOC_EFF_DATES(MAJORDEPTID, DEPT_ID,EFF_DATE,DEFFECTIVEDATE,FROMDT,TODT)
	SELECT a.dept_id MAJORDEPTID, a.dept_id,'' as EFF_DATE ,
	       '' as DEFFECTIVEDATE,'' as FROMDT, convert(varchar(10),getdate(),121) as TODT
	FROM  location a (NOLOCK) 
	LEFT JOIN #LOC_EFF_DATES b ON a.dept_id=b.dept_id
	WHERE b.DEPT_ID IS NULL

	UPDATE B SET  DEFFECTIVEDATE = DATEADD(DAY ,-1, OPENING_CASH_DATE  )
	FROM LOC_REQ  A
	JOIN #LOC_EFF_DATES B ON A.DEPT_ID =B.DEPT_ID

	UPDATE #LOC_EFF_DATES SET TODT=DEFFECTIVEDATE  WHERE TODT<DEFFECTIVEDATE
	UPDATE #LOC_EFF_DATES SET FROMDT=DEFFECTIVEDATE  WHERE FROMDT<DEFFECTIVEDATE



 SELECT TOP 1 @CCONSIDERALLCASHXN=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='CONSIDER_ALL_CASH_RECEIPTS'
   
 SET @CCONSIDERALLCASHXN=ISNULL(@CCONSIDERALLCASHXN,'')  
   
 IF @BCALLEDFROMPTCASH=0  
  SET @CCONSIDERALLCASHXN='1'  


  
 DECLARE @CRESULT TABLE (Dept_id char(4), XN_DT DATETIME, XN_NO VARCHAR(40), XN_ID VARCHAR(40),  
        XN_TYPE VARCHAR(10), DEBIT_AMOUNT NUMERIC(14,2), CREDIT_AMOUNT NUMERIC(14,2),  
        AC_NAME VARCHAR(1000), NARRATION VARCHAR(MAX),  
        OP_BAL NUMERIC(14,2), CL_BAL NUMERIC(14,2) )  
  
 
 ----IF @CCURRENTLOC = @CHOLOC    -- IF HEAD OFFICE  
 INSERT @CRESULT (Dept_id, XN_DT, XN_NO, XN_ID, XN_TYPE, DEBIT_AMOUNT, CREDIT_AMOUNT, AC_NAME, NARRATION )  
 SELECT a.dept_id, DEFFECTIVEDATE AS XN_DT,  
   SPACE(40) AS XN_NO, SPACE(40) AS XN_ID, 'OPS' AS XN_TYPE,  
   (CASE WHEN OPENING_CASH_BALANCE>0 THEN OPENING_CASH_BALANCE ELSE 0 END ) AS DEBIT_AMOUNT,  
   (CASE WHEN OPENING_CASH_BALANCE<0 THEN ABS(OPENING_CASH_BALANCE) ELSE 0 END ) AS CREDIT_AMOUNT,  
   SPACE(254) AS AC_NAME,  
   SPACE(254) AS NARRATION  
 FROM LOC_REQ A
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON A.DEPT_ID=TMPLOC.DEPT_ID
 WHERE  DEFFECTIVEDATE BETWEEN FROMDT AND TODT  
   
 
 
 SET  @cHEAD_CODE = DBO.FN_ACT_TRAVTREE('0000000014') ----ADD VARIABLE BY GAURI ON 17/4/2019
 
 INSERT @CRESULT (dept_id, XN_DT, XN_NO, XN_ID, XN_TYPE, DEBIT_AMOUNT, CREDIT_AMOUNT, AC_NAME, NARRATION )  
 SELECT tmploc.dept_id, CM_DT AS XN_DT, SPACE(40) AS XN_NO, SPACE(40) AS XN_ID,  
   ( CASE WHEN SUM(D.CASH_AMOUNT)<0 THEN 'SLR' ELSE 'SLS' END ) AS XN_TYPE,  
   ( CASE WHEN SUM(D.CASH_AMOUNT)>0 THEN SUM(D.CASH_AMOUNT) ELSE 0 END) AS DEBIT_AMOUNT,  
   ( CASE WHEN SUM(D.CASH_AMOUNT)>0 THEN 0 ELSE ABS(SUM(D.CASH_AMOUNT)) END) AS CREDIT_AMOUNT,  
   'CASH SALE' AS AC_NAME,  
   SPACE(254) AS NARRATION  
 FROM CMM01106 A  
 JOIN CUSTDYM C ON A.CUSTOMER_CODE = C.CUSTOMER_CODE  
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON A.location_Code =TMPLOC.DEPT_ID
 LEFT OUTER JOIN VW_BILL_PAYMODE D ON A.CM_ID = D.MEMO_ID AND D.XN_TYPE = 'SLS'  
 WHERE --A.CM_MODE = 1 AND   --CHANGE  
 A.CANCELLED = 0  
 AND   A.CM_DT >DEFFECTIVEDATE AND (A.MEMO_TYPE = 1 OR @BESTIMATEENABLED = 1)--CHANGE  
 AND   A.CM_DT BETWEEN FROMDT AND TODT  
 --AND   A.CM_DT BETWEEN '2011-11-26' AND '2011-11-26'  
 AND   ((A.location_Code = MAJORDEPTID OR MAJORDEPTID='') AND (ISNULL(A.BIN_ID,'') = @CBINID OR @CBINID=''))  
 AND   ISNULL(D.CASH_AMOUNT,0) <> 0  
 AND (@BSKIPSLSENTRIES=0 OR FROMDT='') AND @CCONSIDERALLCASHXN='1' 
 AND A.USER_CODE=(CASE WHEN @CUSERCODE='' THEN A.USER_CODE ELSE @CUSERCODE END) 
 GROUP BY tmploc.dept_id,A.CM_DT  
  
 UNION ALL   
 SELECT TMPLOC.dept_id, ADV_REC_DT AS XN_DT, ADV_REC_NO AS XN_NO, ADV_REC_ID AS XN_ID,  
   ( CASE WHEN ARC_TYPE=1 THEN 'REC' ELSE 'PAY' END ) AS XN_TYPE,  
   ( CASE WHEN ARC_TYPE=1 THEN D.CASH_AMOUNT ELSE 0 END) AS DEBIT_AMOUNT,  
   ( CASE WHEN ARC_TYPE=1 THEN 0 ELSE D.CASH_AMOUNT END) AS CREDIT_AMOUNT,  
   C.CUSTOMER_TITLE + ' ' + C.CUSTOMER_FNAME + ' ' + C.CUSTOMER_LNAME AS AC_NAME,  
   A.REMARKS AS NARRATION  
 FROM ARC01106 A  
 JOIN CUSTDYM C ON A.CUSTOMER_CODE = C.CUSTOMER_CODE  
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON A.location_Code =TMPLOC.DEPT_ID
 LEFT OUTER JOIN VW_BILL_PAYMODE D ON A.ADV_REC_ID = D.MEMO_ID AND D.XN_TYPE = 'ARC'  
 WHERE A.CANCELLED = 0  
 AND   D.CASH_AMOUNT <> 0  
 AND   ((A.location_Code  = MAJORDEPTID OR MAJORDEPTID='') AND (ISNULL(A.BIN_ID,'') = @CBINID OR @CBINID=''))  
 AND   A.ADV_REC_DT >DEFFECTIVEDATE -- ISNULL((SELECT [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'OPENING_CASH_DATE'),'')  
 AND   A.ADV_REC_DT BETWEEN FROMDT AND TODT AND @CCONSIDERALLCASHXN='1'  
  AND A.USER_CODE=(CASE WHEN @CUSERCODE='' THEN A.USER_CODE ELSE @CUSERCODE END)
 UNION ALL  
 SELECT TMPLOC.dept_id, B.PEM_MEMO_DT AS XN_DT, B.PEM_MEMO_NO AS XN_NO, B.PEM_MEMO_ID AS XN_ID,  
   ( CASE WHEN A.XN_TYPE='CR' THEN 'PCR' ELSE 'PCP' END ) AS XN_TYPE,  
   ( CASE WHEN A.XN_TYPE='CR' THEN A.XN_AMOUNT ELSE 0 END) AS DEBIT_AMOUNT,  
   ( CASE WHEN A.XN_TYPE='DR' THEN A.XN_AMOUNT ELSE 0 END) AS CREDIT_AMOUNT,  
   C.AC_NAME,  
   A.NARRATION  
 FROM PED01106 A  
 JOIN PEM01106 B ON A.PEM_MEMO_ID = B.PEM_MEMO_ID  
 JOIN LM01106 C ON A.AC_CODE = C.AC_CODE  
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON B.location_Code  =TMPLOC.DEPT_ID
 WHERE B.CANCELLED = 0  
 AND (B.location_Code  = MAJORDEPTID OR MAJORDEPTID='')  
 AND B.PEM_MEMO_DT > DEFFECTIVEDATE -- ISNULL((SELECT [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'OPENING_CASH_DATE'),'')  
 AND B.PEM_MEMO_DT BETWEEN FROMDT AND TODT  
 AND B.USER_CODE=(CASE WHEN @CUSERCODE='' THEN B.USER_CODE ELSE @CUSERCODE END)
 UNION ALL  
 SELECT TMPLOC.dept_id, INV_DT AS XN_DT, SPACE(40) AS XN_NO, SPACE(40) AS XN_ID,  
   'WSL' AS XN_TYPE,  
   SUM(B.AMOUNT) AS DEBIT_AMOUNT,  
   0 AS CREDIT_AMOUNT,  
   'WHOLESALE ON CASH' AS AC_NAME,  
   SPACE(254) AS NARRATION  
 FROM INM01106 A  
 JOIN PAYMODE_XN_DET B ON A.INV_ID=B.MEMO_ID  AND B.XN_TYPE='WSL'
 JOIN PAYMODE_MST C ON C.PAYMODE_CODE=B.PAYMODE_CODE  
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON A.location_Code =TMPLOC.DEPT_ID
 WHERE (A.location_Code  = MAJORDEPTID OR MAJORDEPTID='') AND CANCELLED = 0  
 AND C.PAYMODE_GRP_CODE='0000001'  
 AND (@BSKIPSLSENTRIES=0 OR FROMDT='') AND @CCONSIDERALLCASHXN='1'   
 AND INV_DT > DEFFECTIVEDATE -- ISNULL((SELECT [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'OPENING_CASH_DATE'),'')  
 AND INV_DT BETWEEN FROMDT AND TODT  
 AND A.USER_CODE=(CASE WHEN @CUSERCODE='' THEN A.USER_CODE ELSE @CUSERCODE END)
 GROUP BY tmploc.dept_id,INV_DT  
	
 UNION ALL   
 SELECT TMPLOC.dept_id, CN_DT AS XN_DT, SPACE(40) AS XN_NO, SPACE(40) AS XN_ID,  
   'WSR' AS XN_TYPE,  
   0 AS DEBIT_AMOUNT,  
   SUM(TOTAL_AMOUNT) AS CREDIT_AMOUNT,  
   'WHOLESALE RETURN ON CASH' AS AC_NAME,  
   SPACE(254) AS NARRATION  
 FROM CNM01106 A  
 JOIN LM01106 B ON A.AC_CODE = B.AC_CODE  
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON A.location_Code =TMPLOC.DEPT_ID
 WHERE (A.location_Code  = MAJORDEPTID OR MAJORDEPTID='') AND CHARINDEX(B.HEAD_CODE,@cHEAD_CODE)> 0 ----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019 
 AND CANCELLED = 0  
 AND CN_DT >DEFFECTIVEDATE -- ISNULL((SELECT [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'OPENING_CASH_DATE'),'')  
 AND CN_DT BETWEEN FROMDT AND TODT  
 AND (@BSKIPSLSENTRIES=0 OR FROMDT='') AND @CCONSIDERALLCASHXN='1'
 AND A.USER_CODE=(CASE WHEN @CUSERCODE='' THEN A.USER_CODE ELSE @CUSERCODE END)  
 GROUP BY TMPLOC.dept_id,CN_DT  
   
 UNION ALL  
 SELECT TMPLOC.DEPT_ID, RECEIPT_DT AS XN_DT,MEMO_NO AS XN_NO,MEMO_ID,  
   'PCI' AS XN_TYPE,  
   AMOUNT AS DEBIT_AMOUNT,  
   0 AS CREDIT_AMOUNT,  
   'PETTY CASH INWARDS' AS AC_NAME,  
   REMARKS AS NARRATION  
 FROM PCI_MST       
 JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON location_code =TMPLOC.DEPT_ID
 WHERE RECEIPT_DT <= TODT AND RECEIPT_DT > DEFFECTIVEDATE  
-- AND SUBSTRING(MEMO_NO,3,2)=(CASE WHEN ISNULL(DEPTID ,'')='' THEN SUBSTRING(MEMO_NO,3,2) ELSE DEPTID END)  
 AND USER_CODE=(CASE WHEN @CUSERCODE='' THEN USER_CODE ELSE @CUSERCODE END)  
 AND CANCELLED=0
 UNION ALL  
 
 SELECT TMPLOC.DEPT_ID,MEMO_DT AS XN_DT,MEMO_NO AS XN_NO,MEMO_ID,  
   'PCO' AS XN_TYPE,  
   0 AS DEBIT_AMOUNT,  
   AMOUNT AS CREDIT_AMOUNT,  
   'PETTY CASH OUTWARDS' AS AC_NAME,  
   REMARKS AS NARRATION  
 FROM PCO_MST A    
  JOIN #LOC_EFF_DATES TMPLOC (NOLOCK) ON A.location_Code =TMPLOC.DEPT_ID
 WHERE   CANCELLED=0 AND MEMO_DT  <= TODT AND MEMO_DT > DEFFECTIVEDATE  
 --AND LEFT(MEMO_NO,2)=(CASE WHEN ISNULL(@CDEPTID ,'')='' THEN LEFT(MEMO_NO,2) ELSE @CDEPTID END)  
 AND USER_CODE=(CASE WHEN @CUSERCODE='' THEN USER_CODE ELSE @CUSERCODE END)  
  
LAST_REC:  

  
  TRUNCATE TABLE PETTYCASHCLOSING
  Declare @DminDt dateTime ,@DmaxDt DateTime
  select @DminDt=min(xn_dt),@DmaxDt=max(xn_dt) 
  from @CRESULT
  where xn_dt<>''
 

  while @DminDt<=@DmaxDt
  begin
      insert into PettyCashclosing(Dept_id,ClosingDate,ClosingBalance)
	  select A.dept_id , @DminDt as ClosingDate,0 AS ClosingBalance
	  from location  A (nolock)

	  set @DminDt=@DminDt+1

  end


  DELETE A FROM PETTYCASHCLOSING A
  JOIN(

  SELECT DEPT_ID ,MIN(XN_DT) AS XN_DT FROM @CRESULT
  GROUP BY DEPT_ID
  ) B ON A.DEPT_ID=B.DEPT_ID
  WHERE A.CLOSINGDATE<B.XN_DT


  Update a set ClosingBalance=b.Closing
  from PETTYCASHCLOSING a
  join
  (

  SELECT A.dept_id,a.ClosingDate ,
         SUM(DEBIT_AMOUNT - CREDIT_AMOUNT) AS Closing
  FROM PETTYCASHCLOSING A
  JOIN @CRESULT B ON A.DEPT_ID=B.DEPT_ID and b.xn_dt<=ClosingDate
  group by A.dept_id,a.ClosingDate 
  ) b on A.DEPT_ID=B.DEPT_ID and a.ClosingDate=b.ClosingDate


    
END  
--******************************************* END OF PROCEDURE SP_CASHXN



--

