create PROCEDURE SP3S_SALEPERSON_CUSBAL
(
	 @DFROM_DT DATETIME=''         --FROM DATE TRANSACTIONS TO BE CONSIDERED
	,@DTO_DT DATETIME			--TILL DATE TRANSACTIONS TO BE CONSIDERED
	,@CEMP_CODE VARCHAR(7)=''	--FILTER SALE PERSON
	,@BORDER_XN BIT=0 /*@BORDER_XN: IF 1 CONSIDER ORDER ELSE DONOT CONSIDER ORDER */
	,@CDEPT_ID VARCHAR(5)= ''	--FILTER SALE PERSON
	,@iMode int=0
)
--WITH ENCRYPTION 
AS
BEGIN
SET NOCOUNT ON
DECLARE  @CSTEP VARCHAR(10),@CERR_MSG VARCHAR(500)
		,@CSALESPERSON VARCHAR(200),@CCUSTOMER_ID VARCHAR(50),@NCREDIT_AMOUNT NUMERIC(18,4),@NAGE_DAYS NUMERIC(10)	   
		,@NAGE1 NVARCHAR(5),@NAGE2 NVARCHAR(5),@NAGE3 NVARCHAR(5),@TILL_DTO_DT DATETIME,@Tran_dept_id varchar(5)
BEGIN TRY
	IF OBJECT_ID('TEMPDB..#BALANCEDETAILS','U') IS NOT NULL
		DROP TABLE #BALANCEDETAILS
		
		SET @TILL_DTO_DT=(SELECT GETDATE ())
		set @Tran_dept_id=''
	
	print 'step#1'+convert(varchar,getdate(),113)
	SET @CSTEP=1

	
		DECLARE @CHO_DEPT_ID VARCHAR(5),@Cloc_id varchar(5)
		SELECT TOP 1 @CHO_DEPT_ID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'
		SELECT TOP 1 @Cloc_id=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'

		IF ISNULL(@CHO_DEPT_ID,'')<>ISNULL(@Cloc_id,'')  
		SET @CDEPT_ID=''

		IF ISNULL(@CHO_DEPT_ID,'')=ISNULL(@Cloc_id,'')  and @iMode=1
		begin
		  
		   set @Tran_dept_id=@CDEPT_ID
		   set @CDEPT_ID=''
		end

	
	---GETTING RETAIL ORDER DETAIL
	IF OBJECT_ID('TEMPDB..#ORDER_DET','U') IS NOT NULL
		DROP TABLE #ORDER_DET
	
	IF OBJECT_ID('TEMPDB..#PENDING_ORDER','U') IS NOT NULL
		DROP TABLE #PENDING_ORDER
	
	print 'step#2'+convert(varchar,getdate(),113)
	--GETTING AMOUNT AGAINST EACH ORDER
	SELECT A.ORDER_ID   AS XN_ID
	      ,SUM(B.RFNET) AS TOTAL_AMOUNT  
	      ,CAST(0 AS NUMERIC(12,2)) AS RECEIPT_TILL_DT
	      ,'ORD'		AS  XN_TYPE
	      ,CONVERT(VARCHAR(22),'') AS ADV_REC_ID
	INTO #ORDER_DET      
	FROM WSL_ORDER_MST A  (NOLOCK)
	JOIN WSL_ORDER_DET B (NOLOCK) ON A.ORDER_ID=B.ORDER_ID
	JOIN CUSTDYM CUST (NOLOCK) ON CUST.CUSTOMER_CODE=A.CUSTOMER_CODE
	WHERE A.CANCELLED = 0 AND ISNULL(B.CANCELLED,0)=0
	AND A.CUSTOMER_CODE <> '000000000000' 
	AND A.ORDER_DT BETWEEN @DFROM_DT AND @DTO_DT
	AND A.EMP_CODE=(CASE WHEN @CEMP_CODE='' THEN A.EMP_CODE ELSE @CEMP_CODE END)
	AND (@CDEPT_ID='' OR cust.LOCATION_ID=@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR A.location_Code =@TRAN_DEPT_ID)

	GROUP BY A.ORDER_ID
	UNION ALL
	--GETTING ADVANCES RECEIVED AGAINST ORDERS
	SELECT A.ORDER_ID AS XN_ID
	      ,CASE WHEN A.ORDER_DT <=@DTO_DT THEN  -ISNULL(ARC.NET_AMOUNT,0) ELSE 0 END AS TOTAL_AMOUNT  
	      ,CASE WHEN A.ORDER_DT >@DTO_DT THEN  -ISNULL(ARC.NET_AMOUNT,0) ELSE 0 END AS RECEIPT_TILL_DT
	      ,'ADV' AS  XN_TYPE
	      ,ARC.ADV_REC_ID 
	FROM WSL_ORDER_MST A  (NOLOCK)
	JOIN WSL_ORDER_ADV_RECEIPT AR (NOLOCK) ON AR.ORDER_ID=A.ORDER_ID
	JOIN ARC01106 ARC (NOLOCK) ON AR.ADV_REC_ID=ARC.ADV_REC_ID
	JOIN CUSTDYM CUST (NOLOCK) ON CUST.CUSTOMER_CODE=A.CUSTOMER_CODE
	WHERE A.CANCELLED = 0 
	AND A.CUSTOMER_CODE <> '000000000000' 
	AND A.ORDER_DT <= (CASE WHEN @DFROM_DT='' THEN @TILL_DTO_DT ELSE '9999-12-31' END) --@DTO_DT
	/*IF FROM DATE IS CONSIDERED, DONOT CONSIDER SETTLEMENT DATE ELSE CONSIDER SETTLEMENT DATE*/
	AND ISNULL(ARC.CANCELLED,0)=0 
	AND (@CDEPT_ID='' OR cust.LOCATION_ID=@CDEPT_ID)--
	AND (@TRAN_DEPT_ID='' OR A.location_Code =@TRAN_DEPT_ID)
	
	print 'step#3'+convert(varchar,getdate(),113)
	--GETTING AMOUNT AGAINST BARCODES DELIEVERED IN CASH MEMO
	INSERT #ORDER_DET(XN_ID,TOTAL_AMOUNT,XN_TYPE,ADV_REC_ID)
	SELECT  WOM.ORDER_ID AS XN_ID
		  ,-SUM((WOD.RFNET/WOD.QUANTITY)*B.QUANTITY) AS TOTAL_AMOUNT  
	      ,'DVL' AS  XN_TYPE
	      ,A.CM_ID AS ADV_REC_ID 
	FROM CMM01106 A  (NOLOCK)
	JOIN CMD01106 B (NOLOCK) ON A.CM_ID=B.CM_ID
	JOIN WSL_ORDER_DET WOD (NOLOCK) ON B.PRODUCT_CODE=(CASE WHEN WOD.ORDER_TYPE=0 THEN WOD.PRODUCT_CODE ELSE WOD.REF_PRODUCT_CODE END)
	JOIN WSL_ORDER_MST WOM (NOLOCK) ON WOD.ORDER_ID=WOM.ORDER_ID AND A.CUSTOMER_CODE=WOM.CUSTOMER_CODE
	JOIN CUSTDYM CUST (NOLOCK) ON CUST.CUSTOMER_CODE=A.CUSTOMER_CODE
	WHERE A.CANCELLED = 0 AND WOM.CANCELLED=0 AND ISNULL(WOD.CANCELLED,0)=0 AND A.CUSTOMER_CODE <> '000000000000' 
	AND B.QUANTITY>0
	AND A.CM_DT<=(CASE WHEN @DFROM_DT='' THEN @DTO_DT ELSE '9999-12-31' END) 
	AND (@CDEPT_ID='' OR cust.LOCATION_ID=@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR WOM.location_Code =@TRAN_DEPT_ID)
	/*IF FROM DATE IS CONSIDERED, DONOT CONSIDER SETTLEMENT DATE ELSE CONSIDER SETTLEMENT DATE*/
	GROUP BY WOM.ORDER_ID,A.CM_ID
	
	--GETTING LIST OF ORDERS WHOSE ADVANCES HAVE BEEN SETTLED
	INSERT #ORDER_DET(XN_ID,TOTAL_AMOUNT,XN_TYPE,ADV_REC_ID)
	SELECT A.XN_ID
	      ,SUM(B.AMOUNT) AS TOTAL_AMOUNT  
	      ,'DVL' AS  XN_TYPE
	      ,'' AS ADV_REC_ID 
	FROM #ORDER_DET A  (NOLOCK)
	JOIN PAYMODE_XN_DET B (NOLOCK) ON A.ADV_REC_ID=B.MEMO_ID AND B.XN_TYPE='SLS'
	JOIN #ORDER_DET C (NOLOCK) ON B.ADJ_MEMO_ID=C.ADV_REC_ID AND C.XN_TYPE='ADV'
	WHERE A.XN_TYPE = 'DVL' 
	GROUP BY A.XN_ID
	
	print 'step#4'+convert(varchar,getdate(),113)
	SELECT XN_ID,SUM(TOTAL_AMOUNT) AS BALANCE_AMOUNT
	INTO #PENDING_ORDER
	FROM #ORDER_DET
	WHERE @BORDER_XN=1
	GROUP BY XN_ID
	HAVING SUM(TOTAL_AMOUNT)>0
	
	print 'step#5'+convert(varchar,getdate(),113)
	--GETTING SINGLE EMPLOYEE FOR A MEMO
	IF OBJECT_ID('TEMPDB..#SLS_EMPS','U') IS NOT NULL
		DROP TABLE #SLS_EMPS
	
	SELECT DISTINCT CMM.CM_ID
		  ,(CASE WHEN ISNULL(EMP_CODE,'0000000')<>'0000000' THEN EMP_CODE
				 WHEN ISNULL(EMP_CODE1,'0000000')<>'0000000' THEN  EMP_CODE1
				 ELSE ISNULL(EMP_CODE2,'0000000') END) AS EMP_CODE
	INTO #SLS_EMPS				 
	FROM CMM01106 CMM(NOLOCK)
	JOIN CUSTDYM B (NOLOCK) ON cmm.CUSTOMER_CODE = B.CUSTOMER_CODE
	LEFT JOIN CMd01106 CMD(NOLOCK) ON CMD.CM_ID=CMM.CM_ID
	WHERE CMM.CM_DT BETWEEN @DFROM_DT AND @DTO_DT
	AND (ISNULL(@CEMP_CODE,'')='' OR CMD.EMP_CODE=@CEMP_CODE OR CMD.EMP_CODE1=@CEMP_CODE 
		 OR CMD.EMP_CODE2=@CEMP_CODE)
	AND (@CDEPT_ID='' OR b.location_id =@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR CMM.location_Code=@TRAN_DEPT_ID)
	;WITH DUPEMP 
	AS
	(
		SELECT CM_ID,EMP_CODE,ROW_NUMBER() OVER(PARTITION BY CM_ID ORDER BY EMP_CODE DESC) AS DUP_CNT 
		FROM #SLS_EMPS
	)
	DELETE DUPEMP WHERE DUP_CNT>1
	
	print 'step#6'+convert(varchar,getdate(),113)
	SET @CSTEP=10
	---GETTING SALE PERSON WISE BILLS WHICH HAS CREDIT ISSUE
	SELECT	 E.EMP_NAME AS SALESPERSON 
			,A.CUSTOMER_CODE
			,B.USER_CUSTOMER_CODE AS CUSTOMER_ID
			,ISNULL(B.CUSTOMER_TITLE,'')+' '+ISNULL(B.CUSTOMER_FNAME,'')+' '+ISNULL(B.CUSTOMER_LNAME,'')
			 AS CUSTOMER_NAME
			,'SLS' AS XN_TYPE --CREDIT ISSUE
			,A.CM_NO AS XN_NO
			,A.CM_ID AS XN_ID
			,A.CM_DT AS XN_DT
			,PAY.CREDIT_AMOUNT AS CREDIT_AMOUNT
			,CAST(0 AS NUMERIC(12,2) ) AS RECEIPT_AMOUNT_TILL_DT
			,A.location_Code  AS DEPT_ID   
			,A.MEMO_TYPE,A.NET_AMOUNT AS BILL_AMOUNT
	INTO #BALANCEDETAILS		
	FROM CMM01106 A (NOLOCK)
	INNER JOIN #SLS_EMPS T ON A.CM_ID =T.CM_ID 
	INNER JOIN EMPLOYEE E(NOLOCK) ON E.EMP_CODE=T.EMP_CODE
	LEFT JOIN CUSTDYM B (NOLOCK) ON A.CUSTOMER_CODE = B.CUSTOMER_CODE
	JOIN VW_BILL_PAYMODE PAY (NOLOCK) ON PAY.MEMO_ID = A.CM_ID AND PAY.XN_TYPE = 'SLS'
	WHERE A.CM_MODE = 1 
	AND A.CANCELLED = 0 
	AND A.CUSTOMER_CODE <> '000000000000'   
	AND (PAY.CREDIT_AMOUNT > 0) ---GETTING ONLY BILL WITH CREDIT ISSUE
	AND A.CM_DT BETWEEN @DFROM_DT AND @DTO_DT
	AND (@CDEPT_ID='' OR b.location_id  =@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR A.location_Code =@TRAN_DEPT_ID)
	--AND DBO.FN_GETSALEPERSON(A.CM_ID,0)=(CASE WHEN ISNULL(@CSALE_PERSON,'')='' THEN  ELSE  )

	print 'step#6.1'+convert(varchar,getdate(),113)
	INSERT #BALANCEDETAILS (SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME,XN_TYPE 
			,XN_NO,XN_ID,XN_DT,CREDIT_AMOUNT,RECEIPT_AMOUNT_TILL_DT,DEPT_ID,MEMO_TYPE,BILL_AMOUNT)
	
	--GETTING SALE PERSONWISE CREDIT REFUND AMOUNT FOR CREDIT ISSUED BILLS
	SELECT	 E.EMP_NAME AS SALESPERSON 
			,A.CUSTOMER_CODE
			,B.USER_CUSTOMER_CODE AS CUSTOMER_ID
			,ISNULL(B.CUSTOMER_TITLE,'')+' '+ISNULL(B.CUSTOMER_FNAME,'')+' '+ISNULL(B.CUSTOMER_LNAME,'')
			 AS CUSTOMER_NAME
			,'SLS' AS XN_TYPE --CREDIT REFUND
			,A.CM_NO AS XN_NO
			,A.CM_ID AS XN_ID
			,A.CM_DT AS XN_DT
			,-ABS(PM.AMOUNT) AS CREDIT_REFUND_AMOUNT
			,CAST(0 AS NUMERIC(12,2) ) AS RECEIPT_AMOUNT_TILL_DT
			,A.location_Code  AS DEPT_ID   
			,A.MEMO_TYPE
			, 0 AS BILL_AMOUNT --A.NET_AMOUNT NET AMOUNT CONSIDER IN CREDIT ISSUE
	FROM CMM01106 A  (NOLOCK)
	INNER JOIN #SLS_EMPS T ON A.CM_ID=T.CM_ID 
	INNER JOIN EMPLOYEE E(NOLOCK) ON E.EMP_CODE=T.EMP_CODE
	JOIN PAYMODE_XN_DET PM (NOLOCK) ON A.CM_ID=PM.ADJ_MEMO_ID 
	JOIN CMM01106 REFCM (NOLOCK) ON REFCM.CM_ID=PM.MEMO_ID
	LEFT JOIN CUSTDYM B (NOLOCK) ON A.CUSTOMER_CODE = B.CUSTOMER_CODE
	WHERE A.CM_MODE = 1 
	AND A.CANCELLED = 0 AND REFCM.CANCELLED=0
	AND A.CUSTOMER_CODE <> '000000000000' 
	AND A.CM_DT BETWEEN @DFROM_DT AND @DTO_DT AND PM.PAYMODE_CODE='CMR0001' AND PM.XN_TYPE='SLS'
	AND (@CDEPT_ID='' OR b.location_id =@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR A.location_Code=@TRAN_DEPT_ID)
	
	print 'step#6.2'+convert(varchar,getdate(),113)
	INSERT #BALANCEDETAILS (SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME,XN_TYPE 
			,XN_NO,XN_ID,XN_DT,CREDIT_AMOUNT,RECEIPT_AMOUNT_TILL_DT,DEPT_ID,MEMO_TYPE,BILL_AMOUNT)
	--GETTING SALE PERSON WISE LIST OF BILLS AGAINST WHICH RECEIPTS HAVE BEEN MADE
	SELECT	 E.EMP_NAME AS SALESPERSON 
			,A.CUSTOMER_CODE
			,B.USER_CUSTOMER_CODE AS CUSTOMER_ID
			,ISNULL(B.CUSTOMER_TITLE,'')+' '+ISNULL(B.CUSTOMER_FNAME,'')+' '+ISNULL(B.CUSTOMER_LNAME,'')
			 AS CUSTOMER_NAME
			,'SLS' AS XN_TYPE --OUTSTANDING RECEIPTS
			,A.CM_NO AS XN_NO
			,A.CM_ID AS XN_ID
			,A.CM_DT AS XN_DT
			,-CCR.RECEIPT_AMOUNT
			,CCR.RECEIPT_AMOUNT_TILL_DT AS RECEIPT_AMOUNT_TILL_DT
			,A.location_Code  AS DEPT_ID   
			,A.MEMO_TYPE
			,0 AS BILL_AMOUNT--CASE WHEN  ISNULL(CCR.RECEIPT_AMOUNT,0)<>0 THEN  A.NET_AMOUNT ELSE 0 END
	FROM CMM01106 A  (NOLOCK)
	INNER JOIN #SLS_EMPS T ON A.CM_ID =T.CM_ID 
	INNER JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE=T.EMP_CODE
	JOIN 
	(
	 SELECT SUM(CASE WHEN B.ADV_REC_DT <=@DTO_DT THEN  ISNULL(RECEIPT_AMOUNT,0)+ISNULL(B.DISCOUNT_AMOUNT,0) ELSE 0 END) AS RECEIPT_AMOUNT,
	        SUM(CASE WHEN B.ADV_REC_DT >@DTO_DT AND B.ADV_REC_DT<=@TILL_DTO_DT THEN  ISNULL(RECEIPT_AMOUNT,0)+ISNULL(B.DISCOUNT_AMOUNT,0) ELSE 0 END) AS RECEIPT_AMOUNT_TILL_DT,
	        CCR.CM_ID FROM 
	 CMM_CREDIT_RECEIPT CCR (NOLOCK) --ON A.CM_ID=CCR.CM_ID 
	 JOIN ARC01106 B ON CCR.ADV_REC_ID=B.ADV_REC_ID
	 WHERE B.CANCELLED=0 
	-- AND (@CDEPT_ID='' OR LEFT(CCR.ADV_REC_ID,2)=@CDEPT_ID)
 	 GROUP BY CCR.CM_ID
	)CCR ON A.CM_ID=CCR.CM_ID 
	--JOIN CMM_CREDIT_RECEIPT CCR (NOLOCK) ON A.CM_ID=CCR.CM_ID 
	LEFT JOIN CUSTDYM B (NOLOCK) ON A.CUSTOMER_CODE = B.CUSTOMER_CODE
	WHERE A.CM_MODE = 1 
	AND A.CANCELLED = 0 
	AND A.CUSTOMER_CODE <> '000000000000' 
	AND ISNULL(CCR.RECEIPT_AMOUNT,0)+ISNULL(CCR.RECEIPT_AMOUNT_TILL_DT,0)>0
	AND A.CM_DT BETWEEN @DFROM_DT AND @DTO_DT 
	AND (@CDEPT_ID='' OR b.LOCATION_ID =@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR A.location_Code=@TRAN_DEPT_ID)
	
	print 'step#6.3'+convert(varchar,getdate(),113)
	INSERT #BALANCEDETAILS (SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME,XN_TYPE 
			,XN_NO,XN_ID,XN_DT,CREDIT_AMOUNT,RECEIPT_AMOUNT_TILL_DT,DEPT_ID,MEMO_TYPE,BILL_AMOUNT)
	---GETTING SALE PERSON WISE WHOLESALE ORDER AGAINST WHICH CASH MEMO HAS NOT BEEN GENERATED AND WITH DUE ORDER AMOUNT
	SELECT	 EMP.EMP_NAME AS SALESPERSON 
			,A.CUSTOMER_CODE AS CUSTOMER_CODE
			,B.USER_CUSTOMER_CODE AS CUSTOMER_ID
			,ISNULL(B.CUSTOMER_TITLE,'')+' '+ISNULL(B.CUSTOMER_FNAME,'')+' '+ISNULL(B.CUSTOMER_LNAME,'')
			 AS CUSTOMER_NAME
			,'WOD' AS XN_TYPE --WHOLESALE ORDER
			,A.ORDER_NO AS XN_NO
			,A.ORDER_ID AS XN_ID
			,A.ORDER_DT AS XN_DT
			,PO.BALANCE_AMOUNT AS AMOUNT
			,CAST(0 AS NUMERIC(12,2) ) AS RECEIPT_AMOUNT_TILL_DT
			,A.location_Code  AS DEPT_ID   
			,1 AS MEMO_TYPE
			,A.TOTAL_AMOUNT AS BILL_AMOUNT
	FROM WSL_ORDER_MST A  (NOLOCK)
	JOIN #PENDING_ORDER PO (NOLOCK) ON A.ORDER_ID=PO.XN_ID
	JOIN EMPLOYEE EMP (NOLOCK) ON A.EMP_CODE=EMP.EMP_CODE
	LEFT JOIN WSL_ORDER_ADV_RECEIPT AR (NOLOCK) ON AR.ORDER_ID=A.ORDER_ID
	LEFT JOIN ARC01106 ARC (NOLOCK) ON AR.ADV_REC_ID=ARC.ADV_REC_ID
	LEFT JOIN CUSTDYM B (NOLOCK) ON A.CUSTOMER_CODE = B.CUSTOMER_CODE
	LEFT JOIN LM01106 LM (NOLOCK) ON A.AC_CODE=LM.AC_CODE
	WHERE A.CANCELLED = 0 AND ISNULL(ARC.CANCELLED,0)=0 
	AND A.CUSTOMER_CODE <> '000000000000' 
	AND (@CDEPT_ID='' OR b.location_id =@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR A.location_Code =@TRAN_DEPT_ID)
	
	print 'step#7'+convert(varchar,getdate(),113)

	INSERT #BALANCEDETAILS (SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME,XN_TYPE 
			,XN_NO,XN_ID,XN_DT,CREDIT_AMOUNT,RECEIPT_AMOUNT_TILL_DT,DEPT_ID,MEMO_TYPE,BILL_AMOUNT)
	---GETTING SALE PERSON WISE WHOLESALE ORDER AGAINST WHICH CASH MEMO HAS NOT BEEN GENERATED AND WITH DUE ORDER AMOUNT
	SELECT	 '' AS SALESPERSON 
			,A.CUSTOMER_CODE AS CUSTOMER_CODE
			,B.USER_CUSTOMER_CODE AS CUSTOMER_ID
			,ISNULL(B.CUSTOMER_TITLE,'')+' '+ISNULL(B.CUSTOMER_FNAME,'')+' '+ISNULL(B.CUSTOMER_LNAME,'')
			 AS CUSTOMER_NAME
			,'HBD' AS XN_TYPE --WHOLESALE ORDER
			,A.MEMO_NO AS XN_NO
			,A.MEMO_ID AS XN_ID
			,A.memo_dt AS XN_DT
			,A.TOTAL_AMOUNT-ISNULL(ARC.NET_AMOUNT,0) AS AMOUNT
			,CAST(0 AS NUMERIC(12,2) ) AS RECEIPT_AMOUNT_TILL_DT
			,A.location_Code  AS DEPT_ID   
			,1 AS MEMO_TYPE
			,A.TOTAL_AMOUNT AS BILL_AMOUNT
	FROM hold_back_deliver_mst A  (NOLOCK)
	LEFT JOIN
	(
	  SELECT AR.MEMO_ID,SUM(ARC.NET_AMOUNT) AS NET_AMOUNT
	   FROM HBD_RECEIPT AR (NOLOCK) 
	   JOIN ARC01106 ARC (NOLOCK) ON AR.ADV_REC_ID=ARC.ADV_REC_ID AND ISNULL(ARC.CANCELLED,0)=0
	   WHERE  --(@CDEPT_ID='' OR LEFT(AR.MEMO_ID,2)=@CDEPT_ID) AND
	    ISNULL(ARC.CANCELLED,0)=0 
	  GROUP BY AR.MEMO_ID
	) ARC ON A.memo_id=ARC.MEMO_ID
	LEFT JOIN CUSTDYM B (NOLOCK) ON A.CUSTOMER_CODE = B.CUSTOMER_CODE
	WHERE A.CANCELLED = 0 
	AND A.CUSTOMER_CODE <> '000000000000' 
	AND A.Entry_mode=2
	AND (@CDEPT_ID='' OR b.LOCATION_ID=@CDEPT_ID)
	AND (@TRAN_DEPT_ID='' OR A.location_Code =@TRAN_DEPT_ID)
	AND A.TOTAL_AMOUNT-ISNULL(ARC.NET_AMOUNT,0)>0
	print 'step#8'+convert(varchar,getdate(),113)

	SET @CSTEP=20
	---DELETING BILLS WITH NO SALE PERSON NAME SPECIFIED
	--DELETE #BALANCEDETAILS WHERE ISNULL(SALESPERSON,'')=''
	/*INSTEAD OF DELETING THE CUSTOMERS WITH NO SALEPERSON NAME
	, JUST UPDATE THE SALEPERSON WITH MISC*/
	UPDATE #BALANCEDETAILS SET SALESPERSON='MISC' WHERE ISNULL(SALESPERSON,'')=''


	SET @CSTEP=30
	IF OBJECT_ID('TEMPDB..#BALANCESUMMARY','U') IS NOT NULL
		DROP TABLE #BALANCESUMMARY
		
	SELECT SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME
		  ,SUM(ISNULL(CREDIT_AMOUNT,0)) AS CREDIT_AMOUNT
		  ,SUM(ISNULL(BILL_AMOUNT,0)) AS BILL_AMOUNT
		  ,SUM(ISNULL(RECEIPT_AMOUNT_TILL_DT,0)) AS RECEIPT_AMT
		  ,CONVERT(NUMERIC(18,4),0) AS [A0_30]
		  ,CONVERT(NUMERIC(18,4),0) AS [A31_60] 
		  ,CONVERT(NUMERIC(18,4),0) AS [A61_90] 
		  ,CONVERT(NUMERIC(18,4),0) AS [ABOVE90] 
		  ,CONVERT(NUMERIC(18,4),0) AS CUSTOMER_BALANCE
	INTO #BALANCESUMMARY
	FROM #BALANCEDETAILS
	GROUP BY SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME
	HAVING SUM(ISNULL(CREDIT_AMOUNT,0))>0
	
	print 'step#8'+convert(varchar,getdate(),113)
	IF OBJECT_ID('TEMPDB..#EMP_CUST_BAL','U') IS NOT NULL
		DROP TABLE #EMP_CUST_BAL
		
	--THIS TABLE WILL BE USED BY SP3S_CUSTOMERBALANCE PROCEDUER TO DUMP CUSTOMER BALANCES	
	CREATE TABLE #EMP_CUST_BAL(CUSTOMER_CODE CHAR(15),BALANCE NUMERIC(18,2))
	
	EXEC SP3S_CUSTOMERBALANCE  @DFROM_DT=''
							  ,@DTO_DT=@DTO_DT
							  ,@BORDER_XN=@BORDER_XN
							  ,@CCUS_CODE=''
							  ,@NMODE=1
							  ,@NRETURNCBS=3,
							  @iMode=@iMode

	SET @CSTEP=40
	print 'step#9'+convert(varchar,getdate(),113)
	--CALCULATING BILL NO WISE DUE AMOUNT AGING
	IF OBJECT_ID('TEMPDB..#BALANCEAGE','U') IS NOT NULL
		DROP TABLE #BALANCEAGE
	
	SET @CSTEP=50
	SELECT SALESPERSON,CUSTOMER_ID,XN_DT,SUM(ISNULL(CREDIT_AMOUNT,0)) AS CREDIT_AMOUNT
	,SUM(ISNULL(BILL_AMOUNT,0)) AS BILL_AMOUNT,DATEDIFF(DD,XN_DT,@DTO_DT) AS AGE_DAYS
	INTO #BALANCEAGE
	FROM #BALANCEDETAILS
	GROUP BY SALESPERSON,CUSTOMER_ID,CUSTOMER_NAME,XN_DT
	HAVING SUM(ISNULL(CREDIT_AMOUNT,0))>0	
	
	
	
	
	SET @CSTEP=55
	---FILTERING BILLS WITH DETAILS HAVING PENDING AMOUNT
	IF OBJECT_ID('TEMPDB..#BALANCEDETAILS1','U') IS NOT NULL
		DROP TABLE #BALANCEDETAILS1
	
	print 'step#9'+convert(varchar,getdate(),113)	
	SELECT SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,CUSTOMER_NAME,XN_NO,XN_DT,XN_TYPE,SUM(ISNULL(CREDIT_AMOUNT,0)) AS CREDIT_AMOUNT
		  ,SUM(ISNULL(BILL_AMOUNT,0)) AS BILL_AMOUNT
		  ,SUM(ISNULL(RECEIPT_AMOUNT_TILL_DT,0)) AS RECEIPT_AMT
	INTO #BALANCEDETAILS1
	FROM #BALANCEDETAILS
	GROUP BY SALESPERSON,CUSTOMER_CODE,CUSTOMER_ID,XN_NO,XN_DT,XN_TYPE,CUSTOMER_NAME
	HAVING SUM(ISNULL(CREDIT_AMOUNT,0))>0	
	
	--GETTTING LIST OF DISTINCT CUSTOMERS APPEARING IN SALE PERSON WISE CUSTOMER BALANCE
	IF OBJECT_ID('TEMPDB..#CUSTOMERLIST','U') IS NOT NULL
		DROP TABLE #CUSTOMERLIST
	
	SELECT DISTINCT CUSTOMER_CODE 
	INTO #CUSTOMERLIST
	FROM #BALANCEDETAILS1
	
	print 'step#10'+convert(varchar,getdate(),113)
	IF OBJECT_ID('TEMPDB..#EMP_CUST_BAL1','U') IS NOT NULL
		DROP TABLE #EMP_CUST_BAL1
	
	SELECT A.* 
	INTO #EMP_CUST_BAL1 
	FROM #EMP_CUST_BAL A
	JOIN #CUSTOMERLIST B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE
		
	SET @CSTEP=60
	IF CURSOR_STATUS('GLOBAL','CUR_AGE') IN (0,1)
	BEGIN
		CLOSE CUR_AGE
		DEALLOCATE CUR_AGE
	END
	
	print 'step#11'+convert(varchar,getdate(),113)
	SET @CSTEP=70		
	DECLARE CUR_AGE CURSOR FOR SELECT SALESPERSON,CUSTOMER_ID,CREDIT_AMOUNT,AGE_DAYS FROM #BALANCEAGE
	OPEN CUR_AGE 
	FETCH NEXT FROM CUR_AGE INTO @CSALESPERSON,@CCUSTOMER_ID,@NCREDIT_AMOUNT,@NAGE_DAYS 
	WHILE @@FETCH_STATUS=0
	BEGIN
			IF @NAGE_DAYS<=30 
				UPDATE #BALANCESUMMARY SET [A0_30]=[A0_30]+@NCREDIT_AMOUNT
				WHERE SALESPERSON=@CSALESPERSON AND CUSTOMER_ID=@CCUSTOMER_ID
			ELSE IF @NAGE_DAYS>30 AND @NAGE_DAYS<=60
				UPDATE #BALANCESUMMARY SET [A31_60]=[A31_60]+@NCREDIT_AMOUNT
				WHERE SALESPERSON=@CSALESPERSON AND CUSTOMER_ID=@CCUSTOMER_ID
			ELSE IF @NAGE_DAYS>60 AND @NAGE_DAYS<=90
				UPDATE #BALANCESUMMARY SET [A61_90]=[A61_90]+@NCREDIT_AMOUNT
				WHERE SALESPERSON=@CSALESPERSON AND CUSTOMER_ID=@CCUSTOMER_ID
			ELSE
				UPDATE #BALANCESUMMARY SET [ABOVE90]=[ABOVE90]+@NCREDIT_AMOUNT
				WHERE SALESPERSON=@CSALESPERSON AND CUSTOMER_ID=@CCUSTOMER_ID											
	FETCH NEXT FROM CUR_AGE INTO @CSALESPERSON,@CCUSTOMER_ID,@NCREDIT_AMOUNT,@NAGE_DAYS 	
	END
	CLOSE CUR_AGE 
	DEALLOCATE CUR_AGE 
	
	
END TRY
BEGIN CATCH
	SET @CERR_MSG='PROCEDURE - SP3S_SALEPERSON_CUSBAL AT STEP - '+@CSTEP+', ERROR MESASGE - '+ERROR_MESSAGE()
END CATCH



IF ISNULL(@CERR_MSG,'')=''
BEGIN
	SELECT A.SALESPERSON,A.CUSTOMER_ID,A.CUSTOMER_NAME,A.CREDIT_AMOUNT,A.BILL_AMOUNT,A.RECEIPT_AMT,
		   A.[A0_30],A.[A31_60],A.[A61_90],A.[ABOVE90]
		  ,CONVERT(VARCHAR(20),ABS(ISNULL(BALANCE,0)))+' '
		   +(CASE WHEN ISNULL(BALANCE,0)>0 THEN 'DR' WHEN ISNULL(BALANCE,0)<0 THEN 'CR' ELSE '' END) AS CUSTOMER_BALANCE   
	FROM #BALANCESUMMARY A
	LEFT JOIN #EMP_CUST_BAL B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE
	ORDER BY SALESPERSON,CUSTOMER_NAME
	
	SELECT SALESPERSON,CUSTOMER_ID,CUSTOMER_NAME,XN_NO,XN_DT,CREDIT_AMOUNT,BILL_AMOUNT 
		  ,(CASE WHEN ISNULL(B.BALANCE,0)>0 THEN B.BALANCE ELSE 0 END) AS DEBIT_BALANCE
		  ,(CASE WHEN ISNULL(B.BALANCE,0)<0 THEN ABS(B.BALANCE) ELSE 0 END) AS CREDIT_BALANCE	
		  ,A.RECEIPT_AMT
	FROM #BALANCEDETAILS1 A
	LEFT JOIN #EMP_CUST_BAL B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE
	 --WHERE CREDIT_AMOUNT=BILL_AMOUNT 
	ORDER BY A.SALESPERSON,A.CUSTOMER_NAME,A.XN_DT
	
	SELECT SUM(CASE WHEN ISNULL(B.BALANCE,0)>0 THEN B.BALANCE ELSE 0 END) AS DEBIT_TOTAL
		  ,SUM(CASE WHEN ISNULL(B.BALANCE,0)<0 THEN ABS(B.BALANCE) ELSE 0 END) AS CREDIT_TOTAL	
	FROM #EMP_CUST_BAL1 B
END
ELSE 
	SELECT @CERR_MSG AS ERRORMESSAGE
END
---END OF PROCEDURE - SP3S_SALEPERSON_CUSBAL