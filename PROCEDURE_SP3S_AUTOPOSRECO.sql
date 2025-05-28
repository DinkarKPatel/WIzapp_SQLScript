create PROCEDURE SP3S_AUTOPOSRECO
(
@NMODE INT=1,
@cLocIdPara VARCHAR(5)='',
@cXnTypePara VARCHAR(10)='',
@cErrmsgPara VARCHAR(MAX)='',
@cCutOffDatePara VARCHAR(20)=''
---  @nMode
---   1-Check for any Reco data to be synched at HO
---   2-Do the Reco between ho & POS
---   3-Acknowledge the REco differences at POS from HO
)
AS
BEGIN

BEGIN TRY

   GOTO END_PROC
   --as Discuss with sanjiv Sir donot synch without complete testing (14122023)
   --due to calling of this Procedure mirrorservice hang out on Cantabil
	   
	DECLARE @CCMD NVARCHAR(MAX),@CHOID CHAR(2),@CERRORMSG VARCHAR(MAX),@cSTEP VARCHAR(4),@bDataFound BIT,
	@BUPLOADYEARWISEDATA BIT,@dLastSynchDate DATETIME,@cHoLocId CHAR(2),@cXnType VARCHAR(10)

lblNext:
	IF @nMode=3
		BEGIN TRAN
		
	IF @nMode=1
	BEGIN
		SET @cSTEP='10'
		SET @cXnType=''
		
		IF @cLocIdPara=''
			SELECT @cLocIdPara=VALUE FROM config (NOLOCK) WHERE config_option='location_id'

		SELECT TOP 1 @cXnType=xn_type FROM posreco_xntypes (NOLOCK) 
		WHERE CONVERT(DATE,isnull(last_synch_dt,''))<>CONVERT(DATE,GETDATE()) AND isnull(ERRMSG,'')=''
		AND enabled=1 ORDER BY SRNO
				
		IF ISNULL(@cXnType,'')=''
		BEGIN
			GOTO END_PROC
		END
	END
	ELSE
	IF @nMode IN (2,3)
		SET @cXnType=@cXnTypePara
	
	IF NOT (@nMode=3 AND @cErrmsgPara<>'')		
	BEGIN
		DECLARE @cCutOffDate VARCHAR(12)

		IF @cCutOffDatePara=''
			SELECT @cCutOffDate = value FROM config (NOLOCK) WHERE config_option='NEW_DATA_ARCHIVING_DATE'
		ELSE
			SET @cCutOffDate=@cCutOffDatePara
		
		SET @cCutOffDate=ISNULL(@cCutOffDate,'')
			
		SET @cSTEP='20'
		SET @cCmd=N'EXEC SP3S_AUTOPOSRECO_'+@cXntype+'
		@nMode ='+str(@nMode)+',
		@cLocIdPara='''+@cLocIdPara+''',
		@cCutOffDate = '''+@cCutOffDate+''',
		@cErrormsg=@cErrormsg OUTPUT,
		@bDataFound=@bDataFound OUTPUT'
	
		print @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@cErrormsg VARCHAR(MAX) OUTPUT,@bDataFound BIT OUTPUT',
		@cErrormsg OUTPUT,@bDataFound OUTPUT
	END
	IF @nMode=1 AND @bDatafound=0 AND ISNULL(@CERRORMSG,'')=''
	BEGIN
		print 'Data found 0 for Xn type :'+@cXnType
		UPDATE posreco_xntypes WITH (ROWLOCK) SET last_synch_dt=getdate() WHERE xn_type=@cXntype
		GOTO lblNext
	END
END TRY

BEGIN CATCH
	SET @CERRORMSG = 'Error in Procedure SP3S_AUTOPOSRECO at STEP#' + @cSTEP + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	GOTO END_PROC
END CATCH
	
END_PROC:
	
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' 
			COMMIT TRANSACTION
		ELSE
			ROLLBACK
	END
	
	IF @cXnTypePara<>'' AND @cErrmsgPara<>''
		UPDATE posreco_xntypes WITH (ROWLOCK) SET errmsg=@cErrmsgPara WHERE xn_type=@cXntypePara
	ELSE
	IF ISNULL(@CERRORMSG,'')<>'' AND @nMode IN (1,3)
	BEGIN
		UPDATE posreco_xntypes WITH (ROWLOCK) SET errmsg=@CERRORMSG WHERE xn_type=@cXntype
	END
	
	IF @nMode=1 AND ISNULL(@CERRORMSG,'')='' AND @bDataFound=1
	BEGIN
		UPDATE #auto_posreco_data_upload set entry_type=isnull(entry_type,0),amount=isnull(amount,0),
		paymode_code=isnull(paymode_code,''),mode=isnull(mode,0)

		SELECT '#auto_posreco_data_upload' as tablename,* FROM #auto_posreco_data_upload
	END
		
	SELECT ISNULL(@CERRORMSG,'') AS ERRMSG		
END						

