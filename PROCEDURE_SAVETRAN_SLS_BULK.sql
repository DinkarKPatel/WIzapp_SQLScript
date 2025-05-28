create PROCEDURE SAVETRAN_SLS_BULK
(
	@iDateMode			INT,
	@CLOCID				VARCHAR(10),          
	@NMODE				INT=0      ,    
	@CSPID				VARCHAR(50) ,
	@CUSER_CODE			CHAR(7)= '0000000',
	@CFINYEAR			varchar(10),
	@CMACHINENAME		varchar(100),
	@CWINDOWUSERNAME	varchar(100),
	@NLOGINSPID			varchar(40),
	@cGUSER_ALIAS		VARCHAr(10),
	@CBINID				VARCHAR(10)
)
AS
BEGIN
	--changes by Dinkar in location id varchar(4)..

	--SELECT @iDateMode=1,	@CLOCID ='F2',@NMODE =0 ,@CSPID ='77173926434',@CUSER_CODE='0000000',@cGUSER_ALIAS='00',@NLOGINSPID=@@SPID,	@CFINYEAR	='01122'
	DECLARE @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP VARCHAR(1) ,@cStep VARCHAR(10) 

	set @cStep='10'
	select @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP= value from config where config_option='RETAIN_EXCEL_NRV_SISLOC_SALEIMP'

	SET @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP=ISNULL(@cRETAIN_EXCEL_NRV_SISLOC_SALEIMP,'0')
	

	CREATE TABLE #SAVETRAN_SLS_BULK(PRODUCT_CODE VARCHAR(100), REF_NO  VARCHAR(100),DEPT_ID  VARCHAR(100), ERRMSG  VARCHAR(MAX),MEMO_ID VARCHAR(100))
	DECLARE  @tmp_uniqueBarcod TABLE (PRODUCT_CODE VARCHAR(100), BIN_ID  VARCHAR(100),DEPT_ID  VARCHAR(100), ERRMSG  VARCHAR(MAX),MEMO_ID VARCHAR(100))
	DECLARE  @tmp_NegativeStkBarcode TABLE (PRODUCT_CODE VARCHAR(100), REF_NO  VARCHAR(100),DEPT_ID  VARCHAR(100), ERRMSG  VARCHAR(MAX),MEMO_ID VARCHAR(100),memo_dt varchar(40))
	
	set @cStep='20'
	CREATE TABLE #SLS_IMPORT_DATA_DISTINCT(memo_no VARCHAR(100), memo_dt  VARCHAR(100))

	if(@iDateMode IN (1,6,5))
	BEGIN
		INSERT INTO #SLS_IMPORT_DATA_DISTINCT(memo_no,memo_dt)
		select memo_no,memo_dt
		from SLS_IMPORT_DATA where sp_id=@CSPID
		GROUP BY memo_no,memo_dt
		ORDER BY CONVERT(datetime,memo_dt,105) ,memo_no
	END
	else
	BEGIN
		INSERT INTO #SLS_IMPORT_DATA_DISTINCT(memo_no,memo_dt)
		select memo_no,memo_dt
		from SLS_IMPORT_DATA where sp_id=@CSPID
		GROUP BY memo_no,memo_dt
		ORDER BY CONVERT(datetime,memo_dt) ,memo_no
	END
	
	set @cStep='30'
	--SELECT * FROM #SLS_IMPORT_DATA_DISTINCT

	DECLARE @cErrMsg VARCHAR(MAX),@cMemoPrefix VARCHAR(20), @cmemo_no VARCHAR(50),@cmemo_dt VARCHAR(50)

	SET @cMemoPrefix=@CLOCID+@cGUSER_ALIAS

	 SELECT a.PRODUCT_CODE ,a.BIN_ID,CAST('' as varchar(4)) as Dept_id 
		 into #tmp_uniqueBarcod
     FROM SLS_CMD01106_UPLOAD A
	 where 1=2
	 	
BEGIN TRY
     
	WHILE EXISTS (SELECT TOP 1 * FROM #SLS_IMPORT_DATA_DISTINCT)
	BEGIN
			set @cStep='40'
			SELECT TOP 1 @cmemo_no=memo_no,@cmemo_dt=memo_dt FROM #SLS_IMPORT_DATA_DISTINCT ORDER BY memo_dt,memo_no
			
			SET @cErrMsg=''
			DELETE FROM #SAVETRAN_SLS_BULK

			BEGIN TRAN
	
			set @cStep='50'
			--SELECT @cmemo_no,@cmemo_dt
			DELETE FROM SLS_CMM01106_UPLOAD WHERE SP_ID=@CSPID
			DELETE FROM SLS_CMD01106_UPLOAD WHERE SP_ID=@CSPID
			DELETE FROM SLS_PAYMODE_XN_DET_UPLOAD WHERE SP_ID=@CSPID

			set @cStep='60'
			IF @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP='1'
				EXEC SP3S_IMPORT_SLS_DATA_UPLOAD_NEW_PUMA @iDateMode=@iDateMode,	@CLOCID =@CLOCID,@NMODE =@NMODE ,@CSPID =@CSPID,@CUSER_CODE=@CUSER_CODE, @memo_no=@cmemo_no,@memo_dt=@cmemo_dt,@CBINID=@CBINID
			ELSE
				EXEC SP3S_IMPORT_SLS_DATA_UPLOAD_NEW @iDateMode=@iDateMode,	@CLOCID =@CLOCID,@NMODE =@NMODE ,@CSPID =@CSPID,@CUSER_CODE=@CUSER_CODE, @memo_no=@cmemo_no,@memo_dt=@cmemo_dt,@CBINID=@CBINID


			SELECT @cErrMsg=ISNULL(ERRMSG,'') FROM #SAVETRAN_SLS_BULK
			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				GOTO END_PROC_INNER
			END
			
			set @cStep='70'
			DECLARE @cCMID_UPLOAD VARCHAR(50),@iMode INT, @cCMDT_UPLOAD DATETIME
			SELECT @cCMID_UPLOAD = CM_ID,@cCMDT_UPLOAD=CM_DT FROM SLS_CMM01106_UPLOAD(NOLOCK) WHERE SP_ID=@CSPID

			SET @cCMID_UPLOAD=ISNULL(@cCMID_UPLOAD,'')
			SET @cCMDT_UPLOAD= ISNULL(@cCMDT_UPLOAD,'')

			set @cStep='80'
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
			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				GOTO END_PROC_INNER
			END

		    print 'Enter SaveTran_SLS_afterSAVE for sisloc'

			set @cStep='90'
		 --stock validation of Unique Barcode More than One Quantity
		   insert into @tmp_uniqueBarcod(PRODUCT_CODE,BIN_ID,Dept_id)
		   SELECT a.PRODUCT_CODE ,a.BIN_ID,@CLOCID as Dept_id 
		   FROM SLS_CMD01106_UPLOAD A
		   join sku_names sn (nolock) on sn.product_Code =a.product_Code
		   WHERE SP_ID=@CSPID  and isnull(sn.sn_barcode_coding_scheme ,0)=3
		   and a.QUANTITY <0
		   group by a.PRODUCT_CODE ,a.BIN_ID 

		   set @cStep='100'
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
						@cLocId            =@cLocID,
						@bcheckcreditlimit = 0,
						@bDialogResult     =0,
						@bCalledFromBulkImport=1
				

			SELECT @cErrMsg=ISNULL(ERRMSG,'') FROM #SAVETRAN_SLS_BULK

			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				SET @cErrMsg ='Memo No : '+@cmemo_no+' Memo Date : '+ @cmemo_dt + ' Error : '+@cErrMsg
				GOTO END_PROC_INNER
			END

		   set @cStep='110'
		   IF EXISTS (SELECT TOP 1'U'  FROM @TMP_UNIQUEBARCOD A
					   JOIN PMT01106 B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID =B.BIN_ID 
					   AND ISNULL(B.BO_ORDER_ID,'')='' AND B.QUANTITY_IN_STOCK  >1)
		   begin
				SET @cErrMsg ='UNIQUE BARCODE IS ALREADY IN STOCK....PLEASE CHECK'
				INSERT INTO @tmp_NegativeStkBarcode(product_code,errmsg,dept_id,ref_no,memo_dt)
				SELECT A.PRODUCT_CODE,@cErrMsg,@cLocId, @cMemo_no,@cMemo_dt
				FROM @TMP_UNIQUEBARCOD A
			   JOIN PMT01106 B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID =B.BIN_ID 
			   AND ISNULL(B.BO_ORDER_ID,'')='' AND B.QUANTITY_IN_STOCK  >1 AND ISNULL(A.PRODUCT_CODE,'')<>''
			   GOTO END_PROC_INNER
		   end

		   DELETE FROM @tmp_uniqueBarcod

END_PROC_INNER:
			
			set @cStep='120'
			IF  ISNULL(@cErrMsg,'')<>''
			BEGIN
				if not exists (select top 1 product_code from @tmp_NegativeStkBarcode where ref_no=@cMemo_no and memo_dt=@cMemo_dt and dept_id=@CLOCID)
					INSERT INTO @tmp_NegativeStkBarcode (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG ,memo_dt )
					SELECT  '' PRODUCT_CODE, @cMemo_no REF_NO,@CLOCID DEPT_ID,ISNULL(@CERRMSG,'') AS ERRMSG  ,@cmemo_dt
			END

			if @@trancount>0
			begin
				IF  ISNULL(@cErrMsg,'')=''
					commit
				else
					rollback
			end
			
			set @cStep='130'
		    set @cErrMsg=''
			DELETE FROM #SLS_IMPORT_DATA_DISTINCT where memo_no=@cmemo_no and memo_dt=@cmemo_dt

		END
END TRY
BEGIN CATCH 
	SET @cErrMsg ='Error in Procedure Savetran_sls_bulk at Step# '+@cStep+' Memo No : '+@cmemo_no+' Memo Date : '+ @cmemo_dt  + ' Error : '+ ERROR_MESSAGE()
END CATCH

END_PROC:

	if @@trancount>0
	begin
		rollback
	end

	if isnull(@cErrMsg,'')<>''
	begin
		if not exists (select top 1 product_code from @tmp_NegativeStkBarcode where ref_no=isnull(@cMemo_no,'') 
		     and memo_dt=isnull(@cMemo_dt,'') and dept_id=@CLOCID)
			INSERT INTO @tmp_NegativeStkBarcode (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG ,MEMO_ID )
			SELECT  '' PRODUCT_CODE, '' REF_NO,'' DEPT_ID,ISNULL(@CERRMSG,'') AS ERRMSG  ,'' AS MEMO_ID
	end
	else
	begin
		if not exists (select top 1 product_code from @tmp_NegativeStkBarcode)
			INSERT INTO @tmp_NegativeStkBarcode (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG ,MEMO_ID )
			SELECT  '' PRODUCT_CODE, '' REF_NO,'' DEPT_ID,'' AS ERRMSG  ,'' AS MEMO_ID
	end

	SELECT * FROM @tmp_NegativeStkBarcode
	

	DELETE from SLS_IMPORT_DATA where sp_id=@CSPID

END	
