create PROCEDURE SPOLAP_SEND_MIRROR_TTM_DATA
(
	 @CUPLOADEDXNID VARCHAR(50)
	,@BACKNOWLEDGE BIT=0
	,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CMEMOID VARCHAR(50),@CSTEP VARCHAR(5)
BEGIN TRY 
 SET @CSTEP=00
 
 DECLARE @CTEMPDBNAME1 VARCHAR(40),@CTEMPDBNAME VARCHAR(40)
 
 
 
 SET @CSTEP=10 			
 
  SET @CMEMOID=@CUPLOADEDXNID
	---- IF NO MEMO FOUND , JUST END THE PROCESS
	IF ISNULL(@CMEMOID,'')=''
		GOTO END_PROC

LBLTABLEINFO:
	SET @CSTEP=50

	IF @BACKNOWLEDGE=1
		GOTO END_PROC
		
	SET @CSTEP=55
	SELECT DISTINCT 'TTM_TRANSFER_TO_TRADING_MST_MIRROR' AS TARGET_TABLENAME,A.* ,@CMEMOID AS XN_ID FROM TRANSFER_TO_TRADING_MST(NOLOCK) A WHERE A.MEMO_ID=@CMEMOID
	
	SET @CSTEP=60
	SELECT DISTINCT 'TTM_TRANSFER_TO_TRADING_DET_MIRROR' AS TARGET_TABLENAME,A.* FROM TRANSFER_TO_TRADING_DET(NOLOCK) A WHERE A.MEMO_ID=@CMEMOID
	
	
	SET @CSTEP=68
	SELECT DISTINCT 'OLAP_PMT01106_MIRROR' AS TARGET_TABLENAME,A.DEPT_ID,A.product_code,A.BIN_ID,A.quantity_in_stock,
	@CMEMOID AS TTM_MEMO_ID FROM PMT01106 A (NOLOCK)  
	JOIN TRANSFER_TO_TRADING_DET B (NOLOCK) ON B.PRODUCT_CODE=A.product_code
	WHERE B.MEMO_ID=@CMEMOID
	
	
	
    
LBLCHECKDATA:

END TRY
BEGIN CATCH
	SET @CERRMSG='P: SPOLAP_SEND_MIRROR_TTM_DATA_NEW, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH 
	
END_PROC:

END	
---END OF PROCEDURE - SP_SEND_MIRROR_TTM_DATA_NEW

