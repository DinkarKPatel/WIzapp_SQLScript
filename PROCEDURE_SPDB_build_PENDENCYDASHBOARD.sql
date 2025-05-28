CREATE PROCEDURE SPDB_build_PENDENCYDASHBOARD
@cErrormsg VARCHAR(MAX) OUTPUT
--WITH ENCRYPTIONAS	
AS
BEGIN
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @DMINXNDT DATETIME,@DMAXXNDT DATETIME,@NCBSSTKVAL NUMERIC(10,2),@cHOLocId VARCHAR(4),
			@CCMD NVARCHAR(MAX),@CFINYEAR VARCHAR(10),@CRFDBNAME VARCHAR(500),@cLastPmtTable varchar(200),
			@tSauAdjCbs varchar(200),@cPmtDbName varchar(200),
			@tWip VARCHAR(200),@tPendingApp VARCHAR(200),@tPendingJw VARCHAR(200),@tPendingGit VARCHAR(200),
			@tPendingWPS VARCHAR(200),@tPendingRPS VARCHAR(200),@tPendingDnPS VARCHAR(200),@tPendingCnPS VARCHAR(200),
			@tPendingPO VARCHAR(200),@tPendingWBO VARCHAR(200),@tPendingRBO VARCHAR(200),
			@tPendingASN VARCHAR(200),@tPendingGRN VARCHAR(200)
			
BEGIN TRY		
	DECLARE @cCurLocId VARCHAR(2),@cTableName VARCHAR(300),@cStep VARCHAR(10)
		
	SET @cStep='10'
	
	SET @cErrormsg=''

	DECLARE @BPICKFREIGHT BIT,@BPICKOC BIT,@BPICKRO BIT,@CPICKFREIGHT VARCHAR(2),@CPICKOC VARCHAR(2),@CPICKRO VARCHAR(2),
	@NSTOCKADJVALUE NUMERIC(10,2)
	
	SELECT TOP 1 @cCurLocId=LTRIM(RTRIM(VALUE)) FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'
	SELECT TOP 1 @cHOLocId=LTRIM(RTRIM(VALUE)) FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'
	
	SELECT @CPICKFREIGHT=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='FIXREPS_PICK_FREIGHT' 
	SELECT @CPICKOC=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='FIXREPS_PICK_OTHER_CHARGES'
	SELECT @CPICKRO=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='FIXREPS_PICK_ROUND_OFF'
	
	SET @cStep='20'

	SELECT @BPICKFREIGHT=(CASE WHEN ISNULL(@CPICKFREIGHT,'')='1' THEN 1 ELSE 0 END),
				@BPICKOC=(CASE WHEN ISNULL(@CPICKOC,'')='1' THEN 1 ELSE 0 END),
			@BPICKRO=(CASE WHEN ISNULL(@CPICKRO,'')='1' THEN 1 ELSE 0 END)

	SET @cStep='30'
	SET @cPmtDbName=DB_NAME()+'_PMT.DBO.'

	IF OBJECT_ID('tempdb..#locList','u') IS NOT NULL
		DROP TABLE #locList

	CREATE TABLE #LocList (dept_id CHAR(2))

	INSERT INTO #LocList 
	SELECT dept_id FROM location ---WHERE (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1) 
	
	SET @cStep='40'
	CREATE TABLE #tmpGitProcess (memo_id VARCHAR(50),quantity NUMERIC(10,2),memo_dt DATETIME,tat_days NUMERIC(5,0))
	
	--THIS TABLE WOULD GET THE WIP STOCK 
	
	declare @cPmtTablename varchar(100),@dxndt datetime
	
	set @dxndt=CONVERT(DATE,GETDATE())

		SET @cStep='50'
		
		TRUNCATE TABLE PENDING_APPROVALS_SMRY
		TRUNCATE TABLE PENDING_JOBWORK_TRADING_SMRY
		TRUNCATE TABLE PENDING_RPS_SMRY
		TRUNCATE TABLE PENDING_WPS_SMRY
		TRUNCATE TABLE PENDING_DNPS_SMRY
		TRUNCATE TABLE PENDING_GIT_SMRY
		TRUNCATE TABLE PENDING_PO_SMRY
		TRUNCATE TABLE PENDING_RBO_SMRY
		TRUNCATE TABLE PENDING_WBO_SMRY
		TRUNCATE TABLE PENDING_ASN_SMRY
		TRUNCATE TABLE PENDING_GRN_SMRY
	
		SET @cStep='70'
		EXEC SP3S_GET_PENDING_GITLOCS @dXnDt,1
		
		SET @cStep='80'
		--GETTING LIST OF PENDING APPROVALS
		INSERT PENDING_APPROVALS_SMRY (memo_ID,quantity,memo_dt,tat_days)
		SELECT B.MEMO_ID,SUM(A.QUANTITY - ISNULL(X.APR_QTY,0)),memo_dt,ISNULL(tat_days,7) as tat_days
		FROM APD01106 A (NOLOCK)  
		JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		JOIN sku_names sn (NOLOCK) ON A.PRODUCT_CODE = Sn.PRODUCT_CODE  
		JOIN #LocList ll ON ll.dept_id=LEFT(b.memo_id,2)
		LEFT OUTER JOIN  
			(  
				SELECT APD_ROW_ID, SUM(QUANTITY) AS APR_QTY  
				FROM APPROVAL_RETURN_DET A (NOLOCK)  
				JOIN APPROVAL_RETURN_MST B (NOLOCK) ON A.MEMO_ID=B.MEMO_ID
				WHERE  CANCELLED=0
				GROUP BY APD_ROW_ID  
			)X ON A.ROW_ID = X.APD_ROW_ID  
		WHERE  sn.STOCK_NA=0 AND B.CANCELLED = 0  
		AND ISNULL(Sn.sku_item_type,0) IN(0,1)
		GROUP BY B.MEMO_ID,memo_dt,ISNULL(tat_days,7)
		HAVING SUM(A.QUANTITY - ISNULL(X.APR_QTY,0))>0 

		SET @cStep='85'
		INSERT PENDING_WPS_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT B.ps_ID,SUM(A.QUANTITY) ,ps_dt,ISNULL(tat_days,7) as tat_days 
		FROM WPS_DET A (NOLOCK)   
		JOIN WPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID  
		JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
		JOIN #LocList ll ON ll.dept_id=LEFT(b.ps_id,2)
		LEFT OUTER JOIN inm01106 c (NOLOCK) ON c.inv_id=b.wsl_inv_id
		WHERE  isnull(b.wsl_inv_id,'')='' AND sn.STOCK_NA=0 AND B.CANCELLED = 0  
		AND ISNULL(Sn.sku_item_type,0) IN(0,1)
		GROUP BY B.PS_ID,ps_dt,ISNULL(tat_days,7)

		SET @cStep='90'
		INSERT PENDING_RPS_SMRY (memo_ID,quantity,memo_dt,tat_days)
		SELECT B.cm_ID,SUM(A.QUANTITY),b.cm_dt ,ISNULL(tat_days,7) as tat_days 
		FROM RPS_DET A (NOLOCK)   
		JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID  
		JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
		JOIN #LocList ll ON ll.dept_id=LEFT(b.cm_id,2)
		LEFT OUTER JOIN cmm01106 c (NOLOCK) ON c.cm_id=b.ref_cm_id
		WHERE  isnull(b.REF_CM_id,'')='' AND sn.STOCK_NA=0 AND B.CANCELLED = 0  
		AND ISNULL(Sn.sku_item_type,0) IN(0,1)
		GROUP BY B.cm_ID,b.cm_dt,ISNULL(tat_days,7)

		SET @cStep='100'
		INSERT PENDING_DNPS_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT B.ps_ID,SUM(A.QUANTITY - ISNULL(c.prt_QTY,0)),ps_dt ,ISNULL(tat_days,7) as tat_days 
		FROM DNPS_DET A (NOLOCK)  
		JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID  
		JOIN #LocList ll ON ll.dept_id=LEFT(b.ps_id,2)
		LEFT OUTER JOIN 
		(SELECT ps_id,product_code,SUM(quantity) as prt_qty FROM rmd01106 a (NOLOCK)
			JOIN rmm01106 b (NOLOCK) ON a.rm_id=b.rm_id
			WHERE entry_mode=2 AND cancelled=0
			GROUP BY ps_id,product_code
			) c ON c.ps_id=a.ps_ID and C.PRODUCT_CODE=a.product_code
		JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
		WHERE sn.STOCK_NA=0 AND B.CANCELLED = 0  
		AND ISNULL(Sn.sku_item_type,0) IN(0,1)
		GROUP BY b.PS_ID,ps_dt,ISNULL(tat_days,7)
		HAVING SUM(A.QUANTITY - ISNULL(c.prt_QTY,0))>0

		
		SET @cStep='120'
		--GETTING LIST OF PENDING JOBWORK FOR TRADING 
		INSERT PENDING_JOBWORK_TRADING_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT A.ISSUE_ID,SUM(B.QUANTITY-ISNULL(JWR.QUANTITY,0)),issue_dt,ISNULL(tat_days,7) as tat_days   
		FROM JOBWORK_ISSUE_MST A (NOLOCK)
		JOIN JOBWORK_ISSUE_DET B (NOLOCK) ON A.ISSUE_ID=B.ISSUE_ID 
		LEFT JOIN 
		(
			SELECT REF_ROW_ID,SUM(B.QUANTITY) AS QUANTITY
			FROM JOBWORK_RECEIPT_MST A (NOLOCK)
			JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID=B.RECEIPT_ID
			WHERE A.CANCELLED=0  AND A.WIP=0 
			AND A.MODE=1
			GROUP BY REF_ROW_ID
		)JWR ON B.ROW_ID=JWR.REF_ROW_ID
		JOIN SKU_names sn (NOLOCK) ON sn.PRODUCT_CODE=b.PRODUCT_CODE
		JOIN #LocList ll ON ll.dept_id=LEFT(b.issue_id,2)
		WHERE A.CANCELLED=0 AND A.WIP=0 AND A.ISSUE_TYPE=1 AND isnull(sn.STOCK_NA,0)=0
		AND ISNULL(Sn.sku_ITEM_TYPE,0) IN(0,1)
		GROUP BY A.ISSUE_ID,issue_dt,ISNULL(tat_days,7)

		SET @cStep='125'
		INSERT PENDING_GIT_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT memo_id,quantity,memo_dt,tat_days FROM #tmpGitProcess

		SET @cStep='130'
		INSERT PENDING_PO_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT A.PO_ID,SUM(B.QUANTITY-ISNULL(b.pi_qty,0)),po_dt,ISNULL(tat_days,7) as tat_days   
		FROM Pom01106 A (NOLOCK)
		JOIN POD01106 B (NOLOCK) ON A.PO_ID=B.PO_ID
		WHERE cancelled=0 
		GROUP BY a.po_id,po_dt,ISNULL(tat_days,7)
		HAVING SUM(B.QUANTITY-ISNULL(b.pi_qty,0))<>0

		SET @cStep='135'
		INSERT PENDING_WBO_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT A.ORDER_ID,SUM(det.QUANTITY-ISNULL(det.inv_qty,0)),order_dt,ISNULL(tat_days,7) as tat_days   
		FROM BUYER_ORDER_MST A (NOLOCK)
		JOIN BUYER_ORDER_DET DET (NOLOCK) ON A.ORDER_ID=DET.ORDER_ID 
		WHERE cancelled=0 
		GROUP BY a.order_id,order_dt,ISNULL(tat_days,7)
		HAVING SUM(det.QUANTITY-ISNULL(det.inv_qty,0))<>0

		SET @cStep='140'
		INSERT PENDING_RBO_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT a.order_id,SUM(a.QUANTITY-ISNULL(b.sls_qty,0)),order_dt,tat_days
		FROM 
		(SELECT A.ORDER_ID,(CASE WHEN isnull(b.ref_product_code,'')<>'' then b.ref_product_code ELSE 
		 b.product_code END) as product_code,SUM(B.QUANTITY) as quantity,order_dt,ISNULL(tat_days,7) as tat_days
		FROM WSL_ORDER_MST A (NOLOCK)
		JOIN WSL_ORDER_DET b (NOLOCK) ON A.ORDER_ID=b.ORDER_ID 
		WHERE b.cancelled=0  and a.cancelled=0
		GROUP BY a.order_id,(CASE WHEN isnull(b.ref_product_code,'')<>'' then b.ref_product_code ELSE 
		 b.product_code END),order_dt,ISNULL(tat_days,7)  
		) A
		LEFT OUTER JOIN 
		(SELECT ref_order_id as order_id,product_code,sum(quantity) as sls_qty from cmd01106 a (NOLOCK)
		 JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
		 WHERE ISNULL(ref_order_id,'')<>'' AND cancelled=0
		 GROUP BY ref_order_id,product_code
		)  b ON a.order_id=b.order_id and a.product_code=b.product_code
		group by a.order_id,order_dt,tat_days
		HAVING  SUM(a.QUANTITY-ISNULL(b.sls_qty,0))<>0

		SET @cStep='145'
		INSERT PENDING_GRN_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT B.memo_ID,SUM(A.QUANTITY),memo_dt,ISNULL(b.tat_days,7) as tat_days  
		FROM GRN_PS_DET A (NOLOCK)   
		JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
		JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
		JOIN #LocList ll ON ll.dept_id=LEFT(b.memo_id,2)
		LEFT OUTER JOIN pim01106 c (NOLOCK) ON c.mrr_id=b.REF_CONVERTED_MRR_ID
		WHERE  isnull(b.REF_CONVERTED_MRR_ID,'')='' AND sn.STOCK_NA=0 AND B.CANCELLED = 0  
		AND ISNULL(Sn.sku_item_type,0) IN(0,1)
		GROUP BY B.memo_ID,memo_dt,ISNULL(b.tat_days,7)

		SET @cStep='150'
		INSERT PENDING_ASN_SMRY (memo_id,quantity,memo_dt,tat_days)
		SELECT B.memo_ID,SUM(A.QUANTITY-isnull(b.grn_qty,0)),memo_dt,ISNULL(tat_days,7) as tat_days  
		FROM ASN_DET a (NOLOCK)
		JOIN ASN_MST b(NOLOCK) ON b.MEMO_ID=a.MEMO_ID
		LEFT OUTER JOIN
		(
		SELECT ASN_ROW_ID,ISNULL(SUM(A.QUANTITY),0) grn_qty FROM GRN_PS_DET A(NOLOCK)
		JOIN GRN_PS_MST B(NOLOCK) ON A.MEMO_ID=B.MEMO_ID
		JOIN ASN_DET C(NOLOCK) ON C.ROW_ID=A.ASN_ROW_ID
		WHERE  B.CANCELLED=0
		GROUP BY ASN_ROW_ID
		)Z ON Z.ASN_ROW_ID=a.ROW_ID 
		WHERE cancelled=0 
		GROUP BY b.memo_id,memo_dt,ISNULL(tat_days,7)
		HAVING SUM(A.QUANTITY-isnull(b.grn_qty,0))>0

	GOTO END_PROC

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPDB_build_PENDENCYDASHBOARD at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
--END OF PROCEDURE - SPDB_build_PENDENCYDASHBOARD