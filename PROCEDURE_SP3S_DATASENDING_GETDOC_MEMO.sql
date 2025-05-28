create PROC SP3S_DATASENDING_GETDOC_MEMO--(LocId 3 digit change by Sanjay:05-11-2024)
@cTargetLocId VARCHAR(4),
@cLastIRRSynchUpdate VARCHAR(30)='',
@nDocAPIMode INT=0,
@cXnType VARCHAR(20) OUTPUT,
@cREqXnId VARCHAR(50) OUTPUT,
@dAckLastUpdate DATETIME OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS 
BEGIN

	DECLARE @cHoLocId VARCHAR(4),@cSearchMemoId VARCHAR(50),@BAPPROVEDIRR BIT,@cStep VARCHAR(4),
			@cCmd NVARCHAR(MAX)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''
	
	---- Removed code for deleting entry from doc_merging errors because Anil confirmed that
	---- Application is deleting entry from the table after every 1 hour (Date:11-02-2021)
		
	DECLARE @tRetDoc TABLE (xn_type VARCHAR(20),memo_id VARCHAR(50),last_update DATETIME)

	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
	
	IF @nDocAPIMode=1
		GOTO lblChallansDocs

	SET @BAPPROVEDIRR=0
	IF EXISTS(SELECT TOP 1 'U' FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='SEND_IRR_TO_POS_AFTER_APPROVAL' AND value='1')
		SET @BAPPROVEDIRR=1

	SET @cStep='20'
	IF ISNULL(@cLastIRRSynchUpdate,'')<>''
		SELECT TOP 1 @cSearchMemoId = A.IRM_MEMO_ID,@dAckLastUpdate=a.last_update FROM IRM01106 A
		LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCIRT'
		WHERE a.location_Code=@cHoLocId AND TYPE<>2 AND ISNULL(barcodes_generated,0)=0 AND (@BAPPROVEDIRR=0 OR ISNULL(a.APPROVED,0)=@BAPPROVEDIRR)
		AND a.last_update>@cLastIRRSynchUpdate AND c.xn_type IS NULL 
		and DATEDIFF (MINUTE,a.last_update ,GETDATE())>1
		ORDER BY a.last_update --AS DISCUSS WITH SANJIV SIR

	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCIRT',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	IF @nDocAPIMode=2
		GOTO lblOtherDocs

lblChallansDocs:
	SET @cStep='30'

	SET @cCmd=N'SELECT '+(CASE WHEN @nDocAPIMode=0 THEN ' TOP 1 ' ELSE '' END)+'''DOCWSL'',a.inv_id,a.last_update
	FROM inm01106 a (NOLOCK)
	JOIN PARCEL_MST PM WITH (NOLOCK) ON PM.PARCEL_MEMO_ID=a.docwsl_PARCEL_MEMO_ID
	JOIN LOCATION L ON L.DEPT_ID=a.location_code
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.memo_id=a.inv_id AND c.xn_type=''DOCWSL''
	WHERE A.PARTY_DEPT_ID='''+@cTargetLocId+''' AND A.INV_MODE=2 
	AND A.APPROVED=(CASE WHEN L.STN_APPROVAL = 1 THEN 2 ELSE A.APPROVED END) 
	AND PM.XN_TYPE=''WSL'' AND A.INV_DT>=''2018-04-01'' 
	AND convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'''')
	AND pm.cancelled=0 AND c.DEPT_ID IS NULL'
	
	PRINT isnull(@cCmd	,'null cmd for wsl challans')
	SET @cStep='40'
	INSERT @tRetDoc (xn_type,memo_id,last_update)
	EXEC SP_EXECUTESQL @cCmd
	
	--select * into tmpinm from @tRetDoc

	IF @nDocAPIMode=0
	BEGIN
		SET @cStep='45'
		SELECT @cSearchMemoId=memo_id,@dAckLastUpdate=last_update FROM @tRetDoc
		IF ISNULL(@cSearchMemoId,'')<>''
			GOTO END_PROC
	END

	SET @cStep='50'
	SET @cCmd=N'SELECT '+(CASE WHEN @nDocAPIMode=0 THEN ' TOP 1 ' ELSE '' END)+'''DOCPRT'',a.rm_id,a.last_update 
	FROM rmm01106 a (NOLOCK)
	JOIN PARCEL_MST PM WITH (NOLOCK) ON PM.PARCEL_MEMO_ID=a.docprt_PARCEL_MEMO_ID
	JOIN LOCATION L ON L.DEPT_ID=a.location_code
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.memo_id=a.rm_id AND c.xn_type=''DOCPRT''
	WHERE A.PARTY_DEPT_ID='''+@cTargetLocId+''' AND A.MODE=2 
	AND A.APPROVED=(CASE WHEN L.STN_APPROVAL = 1 THEN 2 ELSE A.APPROVED END) 
	AND PM.XN_TYPE=''PRT'' AND A.RM_DT>=''2018-04-01'' AND convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'''')
	AND c.DEPT_ID IS NULL'

	PRINT isnull(@cCmd	,'null cmd for prt challans')

	SET @cStep='52'
	INSERT @tRetDoc (xn_type,memo_id,last_update)
	EXEC SP_EXECUTESQL @cCmd

	IF @nDocAPIMode=0
	BEGIN
		SET @cStep='55'
		SELECT @cSearchMemoId=memo_id,@dAckLastUpdate=last_update FROM @tRetDoc
		IF ISNULL(@cSearchMemoId,'')<>''
			GOTO END_PROC
	END


	IF @nDocAPIMode=1
	BEGIN
		IF EXISTS (SELECT TOP 1 * FROM @tRetDoc)
		BEGIN
			SELECT * FROM @tRetDoc
			GOTO END_PROC
		END
	END
lblOtherDocs:
	DECLARE @IMAXLEVEL INT
			
	--GETTING THE MAX LEVEL OF APPROVAL FOR PURCHASE TRANSACTION
	SELECT @IMAXLEVEL=MAX(LEVEL_NO) 
	FROM XN_APPROVAL_CHECKLIST_LEVELS 
	WHERE XN_TYPE='PO' AND INACTIVE=0
			
	SET @IMAXLEVEL=ISNULL(@IMAXLEVEL,0)

	SET @cStep='70'
	SELECT TOP 1 @cSearchMemoId =a.po_id,@dAckLastUpdate=a.last_update
	FROM  POM01106 A WITH (NOLOCK)
	JOIN LOCATION L WITH (NOLOCK) ON  L.DEPT_ID=a.location_code
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCPO'
	WHERE A.DEPT_ID=@cTargetLocId
	and a.location_code=@cHoLocId
	AND (@IMAXLEVEL=0 OR A.APPROVEDLEVELNO=99)
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'')
	AND c.xn_type IS NULL
	
	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='80'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCPO',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	SET @cStep='90'
	SELECT TOP 1 @cSearchMemoId =a.memo_id,@dAckLastUpdate=a.last_update
	FROM GV_STKXFER_MST a (NOLOCK)
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCGV'
	WHERE target_dept_id=@cTargetLocId  
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'')
	AND c.xn_type IS NULL

	IF ISNULL(@cSearchMemoId,'')<>'' 
	BEGIN
		SET @cStep='100'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCGV',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	SET @cStep='110'
	SELECT TOP 1 @cSearchMemoId =a.memo_id,@dAckLastUpdate=a.last_update FROM
	pco_mst a (NOLOCK)
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCPCO'
	WHERE a.target_location_Code=@cTargetLocId 
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'')
	AND c.xn_type IS NULL

	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='120'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCPCO',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	SET @cStep='130'

	set @cSearchMemoId=''
	SELECT TOP 1 @cSearchMemoId =mrr_id,@dAckLastUpdate=a.last_update
	FROM pim01106 a (NOLOCK)
	JOIN location b (NOLOCK) ON a.dept_id=b.dept_id
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCPUR'
	where a.DEPT_ID=@cTargetLocId AND ISNULL(ALLOW_PURCHASE_AT_HO,0)=1
	AND inv_mode=1 AND ISNULL(send_to_loc,0)=1	
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'')
	AND c.xn_type IS NULL

	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='140'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCPUR',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	SET @cStep='150'
	SELECT TOP 1 @cSearchMemoId =A.dept_id,@dAckLastUpdate=a.last_update
	FROM LOCSKUSP a WITH(NOLOCK)
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCMRP'
	WHERE SENT_TO_LOCATION = 0
	AND A.DEPT_ID=@CTARGETLOCID
	AND c.xn_type IS NULL


	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='160'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCMRP',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	SET @cStep='170'
	SELECT TOP 1 @cSearchMemoId = a.memo_id,@dAckLastUpdate=a.last_update
	FROM ASN_MST a (NOLOCK)  
	JOIN POM01106 b (NOLOCK) ON b.PO_ID=a.PO_ID 
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCASN'
	WHERE b.dept_id=@cTargetLocId 
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'')
	AND c.xn_type IS NULL

	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='180'

		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCASN',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	SET @cStep='190'
	SELECT TOP 1 @cSearchMemoId = a.order_id,@dAckLastUpdate=a.last_update
	FROM BUYER_ORDER_MST a (NOLOCK)
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCWBO'
	WHERE a.wbo_for_dept_id=@cTargetLocId AND a.APPROVEDLEVELNO=99 
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'') 
	AND c.xn_type IS NULL

	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='200'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCWBO',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			


	SET @cStep='210'
	SELECT TOP 1 @cSearchMemoId = a.Memo_Id,@dAckLastUpdate=a.last_update
	FROM DEBITNOTE_PROFORMA_mst a (NOLOCK)
	LEFT OUTER JOIN doc_merging_errors c (NOLOCK) ON c.dept_id=@cTargetLocId AND c.xn_type='DOCDNPF'
	WHERE a.Target_DeptId=@cTargetLocId AND a.APPROVEDLEVELNO=99 
	AND  convert(varchar,a.LAST_UPDATE,120)<>ISNULL(convert(varchar,a.doc_synch_last_update,120),'') 
	AND c.xn_type IS NULL

	IF ISNULL(@cSearchMemoId,'')<>''
	BEGIN
		SET @cStep='220'
		INSERT @tRetDoc (xn_type,memo_id)
		SELECT 'DOCDNPF',@cSearchMemoId as memo_id
		GOTO END_PROC
	END			

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_DATASENDING_GETDOC_MEMO at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
	print 'last step of SP3S_DATASENDING_GETDOC_MEMO :'+@cStep
	SELECT @cXntype='',@cREqXnId=''

	IF @cErrormsg='' AND EXISTS (SELECT * FROM @tREtDoc) AND @nDocAPIMode<>1
	BEGIN
		SELECT @cXntype=xn_type,@cREqXnId=memo_id from @tREtDoc
	
	END

END
