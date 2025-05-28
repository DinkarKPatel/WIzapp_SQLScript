CREATE PROCEDURE SP3S_VALIDATE_GVREDEMPTION_SINGLECHANNEL
(
	@NSPID VARCHAR(40),
	@NMODE INT,	
	@CLOCID VARCHAR(5)='',
	@bCalledfromSavetran BIT=0
)
--WITH ENCRYPTION
AS
BEGIN


	--INSERT MIRROR_gv_call (sp_id,calledfromsavetran,mode)
	--select @NSPID,@bCalledfromSaveTran,@nMode
		
	---- @NMODE ---- 1. CALLED FROM CASHMEMO PAYMENT WINDOW FOR VALIDATING THE GV & GET THE DENOMINATION ALSO
				---- 2. CALLED FROM CASHMEMO SAVE CLICK TO FINALLY VALIDATE & Acknowledg THE GV'S REDEEMED
				
	DECLARE @CADJBILLNO VARCHAR(20),@DADJBILLDT DATETIME,@CERRORMSG VARCHAR(MAX),@CCURLOCID VARCHAR(5),
			@CHOLOCID VARCHAR(5),@CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CTEMPTABLE VARCHAR(500),
			@CGVSRNOSEARCH VARCHAR(50),@CVALIDATEGVTHRUAPI VARCHAR(5),@CGVSCHEMECODE VARCHAR(10),
			@CGVSRNO VARCHAR(50),@nGvCnt NUMERIC(1,0)
	
	SET @CERRORMSG=''

BEGIN TRY
	
	SET @CSTEP=10
		
	IF ISNULL(@CLOCID,'')=''
	BEGIN
		SET @CERRORMSG =' LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	END

	--- Have to do this silly step because application has bind the denomination column in Redemption window
	 --- and cannot give it to the api in different column as per Anil/Rohit	
	IF @nMode=1  
		UPDATE validate_sls_gvredemption_upload with (rowlock) set gv_adj_amount=denomination
		where sp_id=@nSpId

	SET @CSTEP=20
	UPDATE A WITH (ROWLOCK) SET ERRMSG='INVALID GV NO. ENTERED....CANNOT REDEEM' 
	FROM validate_sls_gvredemption_upload A
	LEFT OUTER JOIN SKU_GV_MST B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	WHERE sp_id=@nSpId AND B.GV_SRNO IS NULL AND LEFT(a.gv_srno,2)<>'WC'
		
	SET @CSTEP=25
	UPDATE A WITH (ROWLOCK) SET ERRMSG='Gv is marked as Cancelled....CANNOT REDEEM' 
	FROM validate_sls_gvredemption_upload A
	JOIN GV_GEN_DET B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	JOIN gv_gen_mst c (NOLOCK) ON c.memo_id=b.memo_id
	left JOIN 
	(select a.gv_srno from validate_sls_gvredemption_upload a (nolock)
	 join GV_GEN_DET d (NOLOCK) ON A.GV_SRNO=d.GV_SRNO
	 JOIN gv_gen_mst e (NOLOCK) ON e.memo_id=d.memo_id 
	 where  e.cancelled=0 and sp_id=@nSpId ) d on d.GV_SRNO=a.GV_SRNO
	 WHERE sp_id=@nSpId AND c.cancelled=1 AND d.gv_srno IS NULL
	 
	SET @CSTEP=30
	UPDATE A SET GV_TYPE=(CASE WHEN B.GV_TYPE IS NULL THEN 1 ELSE b.gv_type END)
	FROM validate_sls_gvredemption_upload A WITH (ROWLOCK)
	LEFT OUTER JOIN SKU_GV_MST B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	WHERE sp_id=@nSpId

	SET @CSTEP=35
	UPDATE A SET ERRMSG='GV HAS BEEN ADJUSTED IN THE BILL NO.:'+C.CM_NO+' DATED:'+CONVERT(VARCHAR,C.CM_DT,105)
	FROM validate_sls_gvredemption_upload A WITH (ROWLOCK) 
	JOIN PAYMODE_XN_DET B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	JOIN CMM01106 C (NOLOCK) ON B.MEMO_ID=C.CM_ID
	JOIN sku_gv_mst d (NOLOCK) ON d.gv_srno=a.gv_srno
	WHERE sp_id=@nSpId AND B.XN_TYPE='SLS' AND C.CANCELLED=0 AND C.CM_ID<>ISNULL(a.cm_id,'') AND left(a.gv_srno,2)<>'WC'
	AND ISNULL(d.allow_partial_redemption,0)<>1 AND isnull(errmsg,'')=''
	
	SET @cStep=37
	UPDATE A SET ERRMSG='GV  HAS BEEN ADJUSTED IN THE BILL NO.:'+B.CM_NO+' DATED:'+CONVERT(VARCHAR,B.redeemed_on,105)
	+'....CANNOT REDEEM'
	FROM validate_sls_gvredemption_upload A WITH (ROWLOCK) 
	JOIN GV_MST_REDEMPTION B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	JOIN sku_gv_mst c (NOLOCK) ON c.gv_srno=a.GV_SRNO
	WHERE SP_ID=@nSpId AND ISNULL(B.REDEMPTION_CM_ID,'')<>ISNULL(a.cm_id,'') AND ISNULL(B.REDEMPTION_CM_ID,'')<>''
	AND ISNULL(c.allow_partial_redemption,0)<>1 AND isnull(errmsg,'')=''		
	

	SET @cStep=38
	UPDATE A SET ERRMSG='GV adjusted amount cannot be more than '+
	(CASE WHEN ISNULL(c.gv_type,1) IN (0,1)  THEN LTRIM(RTRIM(STR(ISNULL(d.gv_issue_amount,0)-ISNULL(b.gv_adj_amount,0))))
	      ELSE  LTRIM(RTRIM(STR(c.denomination))) END)+'....CANNOT REDEEM'
	FROM validate_sls_gvredemption_upload A WITH (ROWLOCK) 
	LEFT JOIN 
	(SELECT a.GV_SRNO,SUM(gv_amount) gv_adj_amount FROM   GV_MST_REDEMPTION a (NOLOCK)
	 JOIN validate_sls_gvredemption_upload  B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	 JOIN sku_gv_mst c (NOLOCK) ON c.gv_srno=b.gv_srno
	 WHERE sp_id=@nSpId AND ISNULL(c.allow_partial_redemption,0)=1
	 AND ISNULL(a.REDEMPTION_CM_ID,'')<>isnull(b.cm_id,'')
	 GROUP BY a.gv_srno) b ON a.GV_SRNO=b.gv_srno
	 JOIN sku_gv_mst c (NOLOCK) ON c.gv_srno=a.gv_srno
	 LEFT JOIN 
	 (SELECT a.gv_srno,SUM(a.denomination) gv_issue_amount FROM arc_gvsale_details a (NOLOCK)
	  JOIN arc01106 b (NOLOCK) ON b.adv_rec_id=a.adv_rec_id
	  JOIN validate_sls_gvredemption_upload c (NOLOCK) ON c.GV_SRNO=a.gv_srno
	  WHERE sp_id=@nSpid AND cancelled=0
	  GROUP BY a.gv_srno) d ON d.gv_srno=a.GV_SRNO
 	 
	WHERE SP_ID=@nSpId AND isnull(errmsg,'')=''	AND ISNULL(c.allow_partial_redemption,0)=1 AND 
	((ISNULL(c.gv_type,1) IN (0,1) AND isnull(a.gv_adj_amount,0)>(ISNULL(d.gv_issue_amount,0)-ISNULL(b.gv_adj_amount,0))) OR 
	 (ISNULL(c.gv_type,1)=2 AND a.gv_adj_amount>c.denomination))
	
	
	SET @CSTEP=40
	IF EXISTS (SELECT TOP 1  GV_SRNO FROM validate_sls_gvredemption_upload (NOLOCK)
				WHERE sp_id=@nSpId AND  GV_TYPE=1)
	BEGIN
		SET @CSTEP=42
		UPDATE A  SET GV_SOLD=1,sold_TO_customer_code=c.customer_code,redemption_usage_type=c.gv_usage_type  FROM validate_sls_gvredemption_upload A WITH (ROWLOCK)
		JOIN ARC_GVSALE_DETAILS B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
		JOIN ARC01106 C (NOLOCK) ON B.ADV_REC_ID=C.ADV_REC_ID
		JOIN sku_gv_mst d (NOLOCK) ON d.gv_srno=a.gv_srno
		WHERE sp_id=@nSpId AND C.CANCELLED=0 AND D.gv_type=1
		
		--SET @CSTEP=44
		--UPDATE A  SET GV_SOLD=1 FROM validate_sls_gvredemption_upload A WITH (ROWLOCK)
		--JOIN gvsale_pos_validate B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
		--WHERE sp_id=@nSpId AND gv_type=1 AND isnull(gv_sold,0)=0
	END
		
	SET @CSTEP=50	
	UPDATE validate_sls_gvredemption_upload WITH (ROWLOCK)
	SET ERRMSG='GV IS NOT SOLD TO ANY CUSTOMER ....CANNOT REDEEM'
	WHERE sp_id=@nSpId AND gv_type=1 AND isnull(gv_sold,0)=0 AND LEFT(gv_srno,2)<>'WC'
	AND isnull(errmsg,'')=''
	

	IF @nMode=1
	BEGIN	
		SET @CSTEP=55
		UPDATE a WITH (ROWLOCK) SET ERRMSG='WRONG COMBINATION OF GV NO. & SCRATCH NO. ENTERED....CANNOT REDEEM'
		FROM validate_sls_gvredemption_upload a
		JOIN GV_gen_det B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
		JOIN gv_gen_mst d (NOLOCK) ON d.memo_id=b.memo_id
		JOIN  sku_gv_mst c (NOLOCK) ON c.gv_srno=a.GV_SRNO
		WHERE sp_id=@nSpId AND ISNULL(A.GV_SCRATCH_NO,'')<>B.GV_SCRATCH_NO	 AND LEFT(a.gv_srno,2)<>'WC'
		AND isnull(errmsg,'')='' AND  (b.gv_scratch_no<>'' OR c.gv_type=1) AND d.cancelled=0

		SET @CSTEP=60
		
		UPDATE validate_sls_gvredemption_upload WITH (ROWLOCK) SET ERRMSG='Invalid Customer details given for Redemption of GV:'+ISNULL(sold_to_customer_code,'')
		WHERE sp_id=@nSpId AND gv_sold=1 AND ((redemption_usage_type IN (0,1) AND ISNULL(sold_to_customer_code,'')<>ISNULL(redemption_customer_code,''))
		OR ISNULL(redemption_customer_code,'000000000000') IN ('','000000000000'))

		--sold_TO_customer_code
	END				

	SET @CSTEP=65
	UPDATE a WITH (ROWLOCK) SET ERRMSG='GV IS EXPIRED ON DATE :'+CONVERT(VARCHAR,B.DT_EXPIRY,105)+'....CANNOT REDEEM'
	FROM validate_sls_gvredemption_upload a 
	JOIN SKU_GV_MST B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
	WHERE sp_id=@nSpId AND B.DT_EXPIRY<CONVERT(DATE,GETDATE())	 AND LEFT(a.gv_srno,2)<>'WC' 
	AND isnull(errmsg,'')='' AND ISNULL(b.dt_expiry,'')<>''


	
	IF @nMode=1
	BEGIN
		SET @CSTEP=70
		UPDATE a WITH (ROWLOCK) SET gv_adj_amount=(CASE WHEN c.gv_type=1 THEN
		ISNULL(d.gv_issue_amount,0)-ISNULL(b.gv_adj_amount,0) ELSE c.denomination END)
		FROM validate_sls_gvredemption_upload A
		LEFT JOIN 
		(SELECT a.GV_SRNO,SUM(gv_amount) gv_adj_amount FROM   GV_MST_REDEMPTION a (NOLOCK)
		 JOIN validate_sls_gvredemption_upload  B (NOLOCK) ON A.GV_SRNO=B.GV_SRNO
		 JOIN sku_gv_mst c (NOLOCK) ON c.gv_srno=b.gv_srno
		 WHERE sp_id=@nSpId AND ISNULL(c.allow_partial_redemption,0)=1
		 AND ISNULL(a.REDEMPTION_CM_ID,'')<>isnull(b.cm_id,'')
		 GROUP BY a.gv_srno) b ON a.GV_SRNO=b.gv_srno
		 JOIN sku_gv_mst c (NOLOCK) ON c.gv_srno=a.gv_srno
		 LEFT JOIN 
		 (SELECT a.gv_srno,SUM(a.denomination) gv_issue_amount FROM arc_gvsale_details a (NOLOCK)
		  JOIN arc01106 b (NOLOCK) ON b.adv_rec_id=a.adv_rec_id
		  JOIN validate_sls_gvredemption_upload c (NOLOCK) ON c.GV_SRNO=a.gv_srno
		  WHERE sp_id=@nSpid AND cancelled=0
		  GROUP BY a.gv_srno) d ON d.gv_srno=a.GV_SRNO
		WHERE sp_id=@nSpId AND LEFT(a.gv_srno,2)<>'WC' 
		AND (ISNULL(a.gv_adj_amount,0)=0 OR ISNULL(c.allow_partial_redemption,0)=0)

		DECLARE @nTotGvAdjAmt NUMERIC(5,0),@nBillamt numeric(10,2)

		SET @CSTEP=75
		SELECT @nTotGvAdjAmt=sum(isnull(gv_adj_amount,0)) FROM validate_sls_gvredemption_upload (NOLOCK)
		WHERE sp_id=@nSpId

		SELECT @nBillamt=isnull(bill_amount,0) from  validate_sls_gvredemption_upload (NOLOCK)
		WHERE sp_id=@nSpId

		--select @nTotGvAdjAmt,@nBillamt
		IF @nTotGvAdjAmt>@nBillamt
		BEGIN
			SET @CSTEP=80
			SELECT top 1 @CGVSRNO=gv_srno FROM validate_sls_gvredemption_upload (NOLOCK)
			WHERE sp_id=@nSpid AND ISNULL(gv_adj_amount,0)>(@nTotGvAdjAmt-@nBillamt)
			AND LEFT(gv_srno,2)<>'WC'

			SET @CSTEP=83
			UPDATE a WITH (ROWLOCK) SET gv_adj_amount=gv_adj_amount-(@nTotGvAdjAmt-@nBillamt)
			FROM validate_sls_gvredemption_upload A
			WHERE sp_id=@nSpId AND gv_srno=@CGVSRNO

		END

		SET @CSTEP=86
		UPDATE validate_sls_gvredemption_upload WITH (ROWLOCK) SET denomination=gv_adj_amount
		WHERE sp_id=@nSpId

	END
		
LBLUPDATEREDEEMINFO:
	IF @bCalledfromSavetran=0
		BEGIN TRAN
	
	IF @nMode=2 
	BEGIN

		IF NOT EXISTS (SELECT TOP 1 gv_srno FROM validate_sls_gvredemption_upload (NOLOCK)
					   WHERE sp_id=@nSpId AND isnull(errmsg,'')<>'')
		BEGIN
			SET @CSTEP=90
			
			IF @bCalledfromSavetran=0
				INSERT GV_MST_REDEMPTION ( GV_SRNO, REDEEMED_AT_DEPT_ID, REDEEMED_ON, REDEMPTION_CM_ID,gv_amount,gv_scratch_no ) 
				SELECT A.GV_SRNO, @CLOCID AS REDEEMED_AT_DEPT_ID,GETDATE() AS REDEEMED_ON,
				a.cm_id AS REDEMPTION_CM_ID,a.denomination,a.gv_scratch_no FROM validate_sls_gvredemption_upload A
				WHERE a.sp_id=@nSpId AND left(a.gv_srno,2)<>'WC'
			ELSE
				INSERT SLS_gv_mst_redemption_UPLOAD (SP_ID, GV_SRNO, REDEEMED_AT_DEPT_ID, REDEEMED_ON, REDEMPTION_CM_ID,gv_amount,gv_scratch_no ) 
				SELECT A.SP_ID, A.GV_SRNO, @CLOCID AS REDEEMED_AT_DEPT_ID,GETDATE() AS REDEEMED_ON,
				a.cm_id AS REDEMPTION_CM_ID,a.denomination,a.gv_scratch_no FROM validate_sls_gvredemption_upload A
				WHERE a.sp_id=@nSpId AND left(a.gv_srno,2)<>'WC'

		END
	END

END TRY

BEGIN CATCH
	SET @CERRORMSG = 'PROCEDURE SP3S_VALIDATE_GVREDEMPTION_SINGLECHANNEL STEP- ' + @CSTEP + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	PRINT 'ERROR IN CATCH BLOCK:'+@CERRORMSG
	GOTO END_PROC
END CATCH

END_PROC:
	
	IF @bCalledfromSavetran=0
	BEGIN
		IF @@TRANCOUNT>0
		BEGIN
			IF ISNULL(@CERRORMSG,'')=''
				COMMIT
			ELSE
				ROLLBACK	
		END
	END
	
	UPDATE validate_sls_gvredemption_upload WITH (ROWLOCK) SET ERRMSG=ISNULL(@CERRORMSG,'') 
	WHERE sp_id=@nSpId AND ISNULL(ERRMSG,'')=''
	

LAST:	
	IF @bCalledfromSavetran=0
	BEGIN
		SELECT a.*,'' scheme_id
		FROM validate_sls_gvredemption_upload	a (NOLOCK)
		LEFT OUTER JOIN sku_gv_mst b (NOLOCK) ON a.gv_srno=b.gv_srno
		WHERE sp_id=@nSpId
	END


	DELETE A FROM validate_sls_gvredemption_upload	a WITH (ROWLOCK)
	WHERE SP_ID=@nSpid
END
--********************************* END OF PROCEDURE SP3S_VALIDATE_GVREDEMPTION_SINGLECHANNEL
