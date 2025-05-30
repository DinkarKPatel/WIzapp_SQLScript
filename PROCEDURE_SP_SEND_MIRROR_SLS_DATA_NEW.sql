CREATE PROCEDURE SP_SEND_MIRROR_SLS_DATA_NEW--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
(
 @CREQXNID VARCHAR(50)
,@CCURLOCID VARCHAR(4)
,@BDONOTCHKPENDINGCUST BIT=0
,@BACKNOWLEDGE BIT=0
,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS
BEGIN
/*CMM01106,CMM01106_AUDIT,CMD01106,CMD01106_AUDIT,rps_mst,CMR01106,CUSTDYM,PREFIX,EMPLOYEE,EMPLOYEE,EMPLOYEE
PAYMODE_XN_DET,PAYMODE_MST,PAYMODE_GRP_MST,SKU,LM01106,HD01106,LMP01106,AREA,CITY,STATE,DTM*/				

	DECLARE @DTSQL NVARCHAR(MAX),@CSPID VARCHAR(10),@CTEMPTABLE VARCHAR(500),@CMEMOID VARCHAR(50),
	@CTEMPEMPLOYEETABLE VARCHAR(200),@DMEMOLASTUPDATE DATETIME,@CTABLENAME VARCHAR(100),@BRECFOUND BIT,
	@CWHERECLAUSE VARCHAR(MAX),@CFILTERCONDITION VARCHAR(MAX),@CFILTERCONDITION1 VARCHAR(MAX),@CFILTERCONDITION2 VARCHAR(MAX),
	@CCUTOFFDATE VARCHAR(20),@CSTEP VARCHAR(5),@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200),@CTEMPLMTABLE VARCHAR(200),
	@CTEMPLMPTABLE VARCHAR(200),@CTEMPAREATABLE VARCHAR(200),@CTEMPCITYTABLE VARCHAR(200),
	@CTEMPPMODEXNTABLE VARCHAR(200),@CTEMPPMODETABLE VARCHAR(200),@CTEMPCUSTTABLE VARCHAR(200),
	@CTEMPCOUPONTABLE VARCHAR(200),@BPENDINGMSTFOUND BIT,@CTEMPAUDITTABLE VARCHAR(500),@NROWCOUNT INT


BEGIN TRY
	
	IF @BDONOTCHKPENDINGCUST=1
		PRINT 'DO NOT CHECK CUST'
	ELSE
		PRINT 'CHECK CUST'	
		
	SET @CSTEP=10
	DECLARE @CTEMPDBNAME1 VARCHAR(40),@CTEMPDBNAME VARCHAR(40)


	set @CTEMPDBNAME1=''
	set @CTEMPDBNAME=''



	SET @CSTEP=15		
	SET @CMEMOID=@CREQXNID
	
	IF @BACKNOWLEDGE=1
		GOTO LBLTABLEINFO

	SET @CSTEP=20		
	
	DECLARE @CPRINTTEXT VARCHAR(100)
	
	SET @CPRINTTEXT='CHECK MST BEFORE SENDING SLS :'+(CASE WHEN @BDONOTCHKPENDINGCUST=1 THEN 'DO NOT CHECK CUST' ELSE 'CHECK CUST' END)
	
	PRINT @CPRINTTEXT
	
	SET @BPENDINGMSTFOUND=0
	
	IF @BDONOTCHKPENDINGCUST=0
		EXEC SP_SEND_MIRROR_XNSMST_DATA_NEW 'SLS',@CMEMOID,@CCURLOCID,@BDONOTCHKPENDINGCUST
		,@BPENDINGMSTFOUND OUTPUT
		,@CERRMSG OUTPUT
	
	PRINT (CASE WHEN @BPENDINGMSTFOUND=1 THEN 'PMST-Y' ELSE 'PMST-N' END)
	
	IF ISNULL(@BPENDINGMSTFOUND,0)=1
	BEGIN
		PRINT 'PENDING MASTER FOUND'
		GOTO END_PROC
	END

LBLTABLEINFO:

	
	SET @CSTEP=40

	DECLARE @TXNSSENDINFO TABLE (TARGET_TABLENAME VARCHAR(100),RECCOUNT NUMERIC(5,0))  	
	
	IF @BACKNOWLEDGE=1
		GOTO END_PROC


			
	SET @CSTEP=60
	---- SEND THE CASH MEMO MASTER TABLE
	SELECT 'SLS_CMM01106_upload' AS TARGET_TABLENAME,CMM01106.* FROM CMM01106 WHERE CM_ID=@CMEMOID
	
	SET @CSTEP=65	
	---- SEND THE CASH MEMO DETAIL TABLE
	SELECT 'SLS_CMD01106_upload' AS TARGET_TABLENAME,CMD01106.*  FROM CMD01106 WHERE CM_ID=@CMEMOID
	
	SET @CSTEP=70
	---- SEND THE PACK SLIP REFERENCE TABLE RELATED TO GIVEN CASH MEMO
	SELECT 'SLS_RPS_MST_upload' AS TARGET_TABLENAME,RPS_MST.* FROM RPS_MST WHERE REF_CM_ID=@CMEMOID

  SET @CSTEP=75

	SELECT 'SLS_DTM_UPLOAD' AS TARGET_TABLENAME,dtm.*,@CMEMOID AS SLS_MEMO_ID FROM DTM (NOLOCK)
    JOIN CMM01106 B ON  DTM.DT_CODE=B.DT_CODE
    WHERE B.CM_ID=@CMEMOID AND LEFT(dtm.dt_code,2)='WC'


	SET @CSTEP=80
	 --SEND THE DOCUMENT REFERENCE TABLE RELATED TO GIVEN CASH MEMO
	SELECT 'SLS_DAILOGFILE_upload' AS TARGET_TABLENAME,DAILOGFILE.* FROM DAILOGFILE	 WHERE MEMONO=@CMEMOID AND DAILOGFILE.UPLOADED=0
	
	SET @CSTEP=85
	SELECT 'SLS_PAYMODE_XN_DET_upload' AS TARGET_TABLENAME,PAYMODE_XN_DET.* FROM PAYMODE_XN_DET WHERE MEMO_ID=@CMEMOID AND XN_TYPE='SLS'
			
	SET @CSTEP=90
	SELECT  'SLS_CMD_MANUALBILL_ERRORS_upload' AS TARGET_TABLENAME,A.* FROM CMD_MANUALBILL_ERRORS A JOIN CMD01106 B ON A.CMD_ROW_ID = B.ROW_ID
	WHERE B.CM_ID = @CMEMOID

	SET @CSTEP=100
	SELECT  'SLS_COUPON_REDEMPTION_INFO_upload' AS TARGET_TABLENAME,A.* FROM COUPON_REDEMPTION_INFO A WHERE CM_ID = @CMEMOID

	
	SET @CSTEP=110
	SELECT 'SLS_IMAGE_XN_DET_upload' AS TARGET_TABLENAME,IMAGE_XN_DET.* FROM IMAGE_XN_DET WHERE MEMO_ID=@CMEMOID AND XN_TYPE='SLS'

	
	SET @CSTEP=120
	SELECT 'SLS_GV_MST_REDEMPTION_upload' AS TARGET_TABLENAME,GV_MST_REDEMPTION.* FROM GV_MST_REDEMPTION WHERE REDEMPTION_CM_ID=@CMEMOID

	SET @CSTEP=130
	SELECT 'SLS_CMD_CONS_upload' AS TARGET_TABLENAME,CMD_CONS.* FROM CMD_CONS WHERE CM_ID=@CMEMOID
	
	SET @CSTEP=131
	SELECT 'SLS_PMT01106_upload' AS TARGET_TABLENAME,A.DEPT_ID,A.product_code,A.BIN_ID,A.quantity_in_stock,@CMEMOID AS SLS_MEMO_ID FROM PMT01106 A 
	JOIN CMD01106 (NOLOCK) B ON B.PRODUCT_CODE=A.product_code 
 	WHERE B.CM_ID=@CMEMOID
	UNION
	SELECT 'SLS_PMT01106_upload' AS TARGET_TABLENAME,A.DEPT_ID,A.product_code,A.BIN_ID,A.quantity_in_stock,@CMEMOID AS SLS_MEMO_ID FROM PMT01106 A 
	JOIN CMD_CONS B (NOLOCK) ON B.PRODUCT_CODE=A.product_code 
 	WHERE B.CM_ID=@CMEMOID

	SET @CSTEP=160	
	---- Removed this code after discussion in Zoom meeting with Sir & confirmation by Anil	
	---- that this code was written 2 years back (14-10-2020)
	---- SEND THE CUSTOMER DATA
	--SELECT 'SLS_CUSTDYM_UPLOAD' AS TARGET_TABLENAME,CUSTDYM.*,@CMEMOID AS SLS_MEMO_ID FROM CUSTDYM (NOLOCK)
 --   JOIN CMM01106 B ON  CUSTDYM.CUSTOMER_CODE=B.CUSTOMER_CODE
 --   WHERE B.CM_ID=@CMEMOID AND CUSTDYM.CUSTOMER_CODE<>'000000000000'


	SET @CSTEP=170

	SELECT 'SLS_XN_AUDIT_TRIAL_DET_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS SLS_MEMO_ID FROM XN_AUDIT_TRIAL_DET A WHERE XN_TYPE ='SLS' AND XN_ID=@CMEMOID

    SELECT 'SLS_POSGRRECOS_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS SLS_MEMO_ID FROM POSGRRECOS A WHERE  a.CM_ID=@CMEMOID

	GOTO END_PROC

END TRY

BEGIN CATCH
	SET @CERRMSG='P: SP_SEND_mirror_SLS_DATA_NEW, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH
		
END_PROC:

END
--- 'END OF CREATING PROCEDURE - SP_SEND_MIRROR_SLS_DATA_NEW'
