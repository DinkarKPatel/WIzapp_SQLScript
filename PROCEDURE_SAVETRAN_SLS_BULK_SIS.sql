create PROCEDURE SAVETRAN_SLS_BULK_SIS
(
	@iDateMode		INT,
	@CLOCID VARCHAR(10),          
	@NMODE INT=0      ,    
	@CSPID VARCHAR(50) ,
	@CUSER_CODE CHAR(7)= '0000000',
	@CFINYEAR	varchar(10),
	@CMACHINENAME	varchar(100),
	@CWINDOWUSERNAME	varchar(100),
	@NLOGINSPID	varchar(40),
	@cGUSER_ALIAS VARCHAr(10),
	@CBINID			VARCHAR(10)
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
	DECLARE @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP VARCHAR(1)  

	select @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP= value from config where config_option='RETAIN_EXCEL_NRV_SISLOC_SALEIMP'

SET @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP=ISNULL(@cRETAIN_EXCEL_NRV_SISLOC_SALEIMP,'0')
	
	IF OBJECT_ID('TEMPDB..#SAVETRAN_SLS_BULK','U') IS NOT NULL
		DROP TABLE #SAVETRAN_SLS_BULK

	IF OBJECT_ID('TEMPDB..#SLS_IMPORT_DATA_DISTINCT','U') IS NOT NULL
		DROP TABLE #SLS_IMPORT_DATA_DISTINCT
		

	CREATE TABLE #SAVETRAN_SLS_BULK(PRODUCT_CODE VARCHAR(100), REF_NO  VARCHAR(100),DEPT_ID  VARCHAR(100), ERRMSG  VARCHAR(MAX))
	CREATE TABLE #SLS_IMPORT_DATA_DISTINCT(memo_no VARCHAR(100), memo_dt  VARCHAR(100),DEPT_ID VARCHAR(10))

	update a SET DEPT_ID=ISNULL(c.dept_id,'')
	FROM SLS_IMPORT_DATA a 
	LEFT OUTER JOIN Locattr5_mst b ON b.attr5_key_name=a.store_code
	LEFT OUTER JOIN loc_fix_attr c ON c.attr5_key_code=b.attr5_key_code
	WHERE SP_ID=@CSPID
	--select dept_id from loc_fix_attr  a JOIN Locattr5_mst b ON b.attr5_key_code=a.attr5_key_code where b.attr5_key_name='ss130'
	--select memo_no,memo_dt
	--INTO #SLS_IMPORT_DATA_DISTINCT
	--from SLS_IMPORT_DATA where sp_id=@CSPID
	--GROUP BY memo_no,memo_dt
	
	--ORDER BY CONVERT(datetime,memo_dt,105) ,memo_no

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
			IF @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP='1'
				EXEC SP3S_IMPORT_SLS_DATA_UPLOAD_NEW_PUMA @iDateMode=@iDateMode,	@CLOCID =@cdept_id,@NMODE =@NMODE ,@CSPID =@CSPID,@CUSER_CODE=@CUSER_CODE, @memo_no=@cmemo_no,@memo_dt=@cmemo_dt,@CBINID=@CBINID
			ELSE
				EXEC SP3S_IMPORT_SLS_DATA_UPLOAD_NEW @iDateMode=@iDateMode,	@CLOCID =@cdept_id,@NMODE =@NMODE ,@CSPID =@CSPID,@CUSER_CODE=@CUSER_CODE, @memo_no=@cmemo_no,@memo_dt=@cmemo_dt,@CBINID=@CBINID


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
				

				SELECT @cErrMsg=ISNULL(ERRMSG,'') FROM #SAVETRAN_SLS_BULK
			END

			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				SET @cErrMsg ='Memo No : '+@cmemo_no+' Memo Date : '+ @cmemo_dt + ' Error : '+@cErrMsg
				GOTO END_PROC
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


