CREATE PROCEDURE SAVETRAN_SLS_RND_CN
(
	@iDateMode		INT,
	--@CLOCID VARCHAR(10),          
	@NMODE INT=0      ,    
	@CSPID VARCHAR(50) ,
	@CUSER_CODE CHAR(7)= '0000000',
	@CFINYEAR	varchar(10),
	@CMACHINENAME	varchar(100),
	@CWINDOWUSERNAME	varchar(100),
	@NLOGINSPID	varchar(40),
	@cGUSER_ALIAS VARCHAr(10),
	@CBINID			VARCHAR(10),
	@HBD_MEMO_ID	VARCHAR(22)=''
)
AS
BEGIN
	--changes by Dinkar in location id varchar(4)..
	--select * from SLS_IMPORT_DATA where sp_id='77173926434'

	--DECLARE @iDateMode		INT,
	--@CLOCID VARCHAR(10),          
	--@NMODE INT=0      ,    
	--@CSPID VARCHAR(50) ,
	--@CUSER_CODE CHAR(7)= '0000000',
	--@CFINYEAR	varchar(10),
	--@CMACHINENAME	varchar(100),
	--@CWINDOWUSERNAME	varchar(100),
	--@NLOGINSPID	varchar(40),
	--@cGUSER_ALIAS VARCHAR(10)='00'

	--SELECT @iDateMode=1,	@CLOCID ='F2',@NMODE =0 ,@CSPID ='77173926434',@CUSER_CODE='0000000',@cGUSER_ALIAS='00',@NLOGINSPID=@@SPID,	@CFINYEAR	='01122'
	DECLARE @CLOCID VARCHAR(10)  
	
	IF OBJECT_ID('TEMPDB..#SAVETRAN_SLS_BULK','U') IS NOT NULL
		DROP TABLE #SAVETRAN_SLS_BULK

	IF OBJECT_ID('TEMPDB..#SLS_IMPORT_DATA_DISTINCT','U') IS NOT NULL
		DROP TABLE #SLS_IMPORT_DATA_DISTINCT
		

	CREATE TABLE #SAVETRAN_SLS_BULK(PRODUCT_CODE VARCHAR(100), REF_NO  VARCHAR(100),DEPT_ID  VARCHAR(100), ERRMSG  VARCHAR(MAX),MEMO_ID VARCHAR(22))
	CREATE TABLE #SLS_IMPORT_DATA_DISTINCT(memo_no VARCHAR(100), memo_dt  VARCHAR(100),DEPT_ID VARCHAR(10))
    
	IF OBJECT_ID('TEMPDB..#TMPSLS_MEMO','U') IS NOT NULL
		DROP TABLE #TMPSLS_MEMO
		
		CREATE TABLE #TMPSLS_MEMO(memo_id VARCHAR(100))

	if(@iDateMode IN (1,6,5))
	BEGIN
		INSERT INTO #SLS_IMPORT_DATA_DISTINCT(memo_no,memo_dt,DEPT_ID)
		select memo_no,memo_dt,dept_id
		from SLS_IMPORT_DATA where sp_id=@CSPID AND dept_id<>''
		GROUP BY dept_id,memo_no,memo_dt
		ORDER BY dept_id,CONVERT(datetime,memo_dt,105) ,memo_no
	END
	--else if(@iDateMode=5)
	--BEGIN
	--	INSERT INTO #SLS_IMPORT_DATA_DISTINCT(memo_no,memo_dt)
	--	select memo_no,memo_dt
	--	from SLS_IMPORT_DATA where sp_id=@CSPID
	--	GROUP BY memo_no,memo_dt
	--	ORDER BY CONVERT(datetime,memo_dt,105) ,memo_no
	--END
	else
	BEGIN
		INSERT INTO #SLS_IMPORT_DATA_DISTINCT(memo_no,memo_dt,DEPT_ID)
		select memo_no,memo_dt,dept_id
		from SLS_IMPORT_DATA where sp_id=@CSPID AND dept_id<>''
		GROUP BY dept_id,memo_no,memo_dt
		ORDER BY dept_id,CONVERT(datetime,memo_dt) ,memo_no
	END

	SELECT TOP 1 @CLOCID=DEPT_ID FROM #SLS_IMPORT_DATA_DISTINCT
	--SELECT * FROM #SLS_IMPORT_DATA_DISTINCT

	DECLARE @cErrMsg VARCHAR(MAX),@cMemoPrefix VARCHAR(20), @cmemo_no VARCHAR(50),@cmemo_dt VARCHAR(50),@cdept_id varchar(10)

	SET @cMemoPrefix=@CLOCID+@cGUSER_ALIAS
	
BEGIN TRY

	BEGIN TRAN
	DECLARE ABC CURSOR
	FOR 
	SELECT memo_no,memo_dt ,dept_id
	FROM #SLS_IMPORT_DATA_DISTINCT

	OPEN ABC
		FETCH NEXT FROM ABC INTO @cmemo_no,@cmemo_dt,@cdept_id

		WHILE @@FETCH_STATUS=0
		BEGIN
		if ISNULL(@cdept_id,'')=''
			SET @cdept_id=@CLOCID 

			SET @cMemoPrefix=@cdept_id+@cGUSER_ALIAS
			--SELECT @cmemo_no,@cmemo_dt
			DELETE FROM SLS_CMM01106_UPLOAD WHERE SP_ID=@CSPID
			DELETE FROM SLS_CMD01106_UPLOAD WHERE SP_ID=@CSPID
			DELETE FROM SLS_PAYMODE_XN_DET_UPLOAD WHERE SP_ID=@CSPID
			--IF @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP='1'
			--	EXEC SP3S_IMPORT_SLS_DATA_UPLOAD_NEW_PUMA @iDateMode=@iDateMode,	@CLOCID =@cdept_id,@NMODE =@NMODE ,@CSPID =@CSPID,@CUSER_CODE=@CUSER_CODE, @memo_no=@cmemo_no,@memo_dt=@cmemo_dt,@CBINID=@CBINID
			--ELSE
				EXEC SP3S_IMPORT_SLS_DATA_UPLOAD_RND_CN @iDateMode=@iDateMode,	@CLOCID =@cdept_id,@NMODE =@NMODE ,@CSPID =@CSPID,@CUSER_CODE=@CUSER_CODE, @memo_no=@cmemo_no,@memo_dt=@cmemo_dt,@CBINID=@CBINID

				;with CMD_DET
				AS
				(
					SELECT B.ROW_ID,CN_PRODUCT_CODE,emp_code,emp_code1,emp_code2 ,c.CM_DT,c.CM_NO
					FROM CMD01106 B(NOLOCK)
					JOIN CMM01106 C(NOLOCK) ON C.cm_id=B.cm_id
					JOIN hold_back_deliver_det a(NOLOCK) ON b.ROW_ID=a.ref_cmd_row_id
					WHERE ISNULL(CN_PRODUCT_CODE,'')<>'' AND a.memo_id=@HBD_MEMO_ID
				)
				UPDATE A SET A.emp_code=B.emp_code,A.emp_code1=B.emp_code1,A.emp_code2 =B.emp_code2 ,A.ref_sls_memo_dt=B.CM_DT,A.ref_sls_memo_no=B.CM_NO,
				A.pcs_quantity=A.QUANTITY,A.mtr_quantity=1
				FROM SLS_CMD01106_UPLOAD A 
				JOIN CMD_DET B ON B.CN_PRODUCT_CODE=A.PRODUCT_CODE
				WHERE A.SP_ID=@CSPID
			--SELECT * FROM SLS_CMM01106_UPLOAD WHERE SP_ID=@CSPID
			--SELECT * FROM SLS_CMD01106_UPLOAD WHERE SP_ID=@CSPID
			--SELECT * FROM SLS_PAYMODE_XN_DET_UPLOAD WHERE SP_ID=@CSPID

			SELECT @cErrMsg=ISNULL(ERRMSG,'') FROM #SAVETRAN_SLS_BULK
			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				GOTO END_PROC 
			END


			DECLARE @cCMID_UPLOAD VARCHAR(50),@iMode INT, @cCMDT_UPLOAD DATETIME
			SELECT @cCMID_UPLOAD = CM_ID,@cCMDT_UPLOAD=CM_DT FROM SLS_CMM01106_UPLOAD(NOLOCK) WHERE SP_ID=@CSPID

			SET @cCMID_UPLOAD=ISNULL(@cCMID_UPLOAD,'')
			SET @cCMDT_UPLOAD= ISNULL(@cCMDT_UPLOAD,'')

			SET @iMode= (CASE WHEN ISNULL(@cCMID_UPLOAD,'')='' OR ISNULL(@cCMID_UPLOAD,'')='LATER' THEN 1 ELSE 2 END)
			
			EXEC SaveTran_SLS_BEFORESAVE 
			@nUpdateMode		= @imode, 
			@nSpId				= @CSPID,
			@nLoginSpId		=  @nLoginSPID, 
			@bWizclipApiCalled	= 0,
			@bDonotValidateCoupon	= 1, 
			@cMemoNoPrefix		=@cMemoPrefix , 
			@bCalledFromBulkImport=1
			--SELECT 'SaveTran_SLS_BEFORESAVE'
			--SELECT * FROM SLS_CMM01106_UPLOAD WHERE SP_ID=@CSPID
			--SELECT * FROM SLS_CMD01106_UPLOAD WHERE SP_ID=@CSPID
			--SELECT * FROM SLS_PAYMODE_XN_DET_UPLOAD WHERE SP_ID=@CSPID
			print 'Come after SaveTran_SLS_beforeSAVE for sisloc:'+str(@imode)
			SELECT @cErrMsg=ISNULL(ERRMSG,'') FROM #SAVETRAN_SLS_BULK
			IF  ISNULL(@cErrMsg,'')=''
			BEGIN
				print 'Enter SaveTran_SLS_afterSAVE for sisloc'
				--nUpdateMode		= @iMode , 
				--				nLoginSpId		= @nLoginSpId,
				--				nSpId				= @CSPID, 
				--				cMemoNoPrefix		= @cMemoPrefix , 
				--				cFinYear			= @cFinYear,
				--				cMachineName		= @cMachineName, 
				--				cWindowUserName	= @cWindowUserName, 
				--				cWizAppUserCode	= @cUser_Code,
				--				cMemoID       	= @cCMID_UPLOAD,
				--				cMemodt       	= @cCMDT_UPLOAD,
				--				cLocId            =@cLocID,
				--				bcheckcreditlimit = 0,
				--				bDialogResult     =0

				----- Need to do this because User can Import last year data by logging in Current year
				SELECT @CFINYEAR='01'+dbo.fn_getfinyear(cm_dt) FROM sls_cmm01106_upload (NOLOCK) WHERE sp_id=@cSpId

				EXEC SaveTran_SLS_AFTERSAVE 
								@nUpdateMode		= @iMode , 
								@nLoginSpId		= @nLoginSpId,
								@nSpId				= @CSPID, 
								@cMemoNoPrefix		= @cMemoPrefix , 
								@cFinYear			= @cFinYear,
								@cMachineName		= @cMachineName, 
								@cWindowUserName	= @cWindowUserName, 
								@cWizAppUserCode	= @cUser_Code,
								@cMemoID       	= @cCMID_UPLOAD,
								@cMemodt       	= @cCMDT_UPLOAD,
								@bcheckcreditlimit = 0,
								@bDialogResult     =0,
								@bCalledFromBulkImport=1
				
				--SELECT 'SaveTran_SLS_AFTERSAVE'
				
				--SELECT * FROM #SAVETRAN_SLS_BULK
				

				SELECT @cErrMsg=ISNULL(ERRMSG,'') FROM #SAVETRAN_SLS_BULK
				
				
			END

			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				SET @cErrMsg ='Memo No : '+@cmemo_no+' Memo Date : '+ @cmemo_dt + ' Error : '+@cErrMsg
				GOTO END_PROC
			END
			ELSE
			BEGIN
				INSERT INTO HBD_RECEIPT(MEMO_ID,ADV_REC_ID,LAST_UPDATE,CM_ID)
				SELECT @HBD_MEMO_ID,NULL,GETDATE(),A.MEMO_ID 
				FROM #SAVETRAN_SLS_BULK A
				LEFT OUTER JOIN HBD_RECEIPT(NOLOCK) B ON B.MEMO_ID=@HBD_MEMO_ID AND B.CM_ID=A.MEMO_ID
				WHERE ISNULL(A.MEMO_ID,'')<>''
				AND B.MEMO_ID IS NULL

				update a set a.CN_REF_BILL_NO=c.memo_id,a.CN_REF_BILL_DT=GETDATE()
				from hold_back_deliver_det a
				join SLS_IMPORT_DATA b on b.product_code=a.cn_product_code and b.SP_ID=@CSPID
				join #SAVETRAN_SLS_BULK c on 1=1 

				UPDATE hold_back_deliver_mst SET HO_SYNCH_LAST_UPDATE='' WHERE memo_id=@HBD_MEMO_ID
				
				INSERT INTO #TMPSLS_MEMO(MEMO_ID)
				SELECT MEMO_ID FROM #SAVETRAN_SLS_BULK A
				WHERE ISNULL(A.MEMO_ID,'')<>''
			END


			FETCH NEXT FROM ABC INTO @cmemo_no,@cmemo_dt,@cdept_id

		END
END TRY
BEGIN CATCH 
	SET @cErrMsg ='Memo No : '+@cmemo_no+' Memo Date : '+ @cmemo_dt  + ' Error : '+ ERROR_MESSAGE()
END CATCH

END_PROC:
	CLOSE ABC
	DEALLOCATE ABC
	
	UPDATE A SET HO_SYNCH_LAST_UPDATE ='' FROM CMM01106 A (NOLOCK)
	JOIN #TMPSLS_MEMO B ON A.CM_ID =B.MEMO_ID 
	
	IF @@TRANCOUNT>0
	BEGIN
			IF  ISNULL(@cErrMsg,'')=''
			COMMIT TRANSACTION
		ELSE 
			ROLLBACK TRANSACTION
	END
	if (SELECT COUNT(*) FROM #SAVETRAN_SLS_BULK)=0
	BEGIN
		INSERT INTO #SAVETRAN_SLS_BULK (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG  )
		SELECT  '' PRODUCT_CODE, '' REF_NO,'' DEPT_ID,ISNULL(@CERRMSG,'') AS ERRMSG  
	END
	ELSE
		UPDATE #SAVETRAN_SLS_BULK SET ERRMSG=@cErrMsg

	SELECT * FROM #SAVETRAN_SLS_BULK
	--SELECT ISNULL(@cErrMsg,'') AS ERRMSG 
END	


