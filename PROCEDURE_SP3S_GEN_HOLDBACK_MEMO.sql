CREATE PROCEDURE SP3S_GEN_HOLDBACK_MEMO
@nUpdatemode NUMERIC(2,0),
@nSpid VARCHAR(40),
@cMemoid VARCHAR(40),
@cLocationId VARCHAR(4),
@cFinYear VARCHAR(5),
@cmemoprefix varchar(10)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN

	DECLARE @bAutoCalAtdCharges BIT,@cHoldBackMemoId VARCHAR(40),@cHoldBackMemoNo VARCHAR(10),@cHoldItem VARCHAR(50),
	@cStep VARCHAR(10),@cTempDbName VARCHAR(400),@cCmd NVARCHAR(MAX)

BEGIN TRY

	SELECT @cTempDbName='',@cErrormsg=''

	--SELECT TOP 1 @bAutoCalAtdCharges=ISNULL(AUTO_CALCULATION_OF_ALTERATION_CHARGES,0) FROM location (NOLOCK) WHERE dept_id=@cLocationId
	--IF @bAutoCalAtdCharges=1 

		SELECT TOP 1 @CHOLDITEM=PRODUCT_CODE FROM PSHBD_HOLD_BACK_DELIVER_DET_UPLOAD (NOLOCK) 
		WHERE SP_ID=@NSPID 
		
		
	IF isnull(@cHoldItem,'')<>''
	BEGIN
		SET @cStep = 466
		EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@NSPID,1
				
		DECLARE @CTEMPHBMTABLENAME VARCHAR(500),@CTEMPHBDTABLENAME varchar(500),@CTEMPHBMTABLE VARCHAR(500),
				@CTEMPHBDTABLE VARCHAR(500)
		

		IF @NUPDATEMODE=2
		BEGIN
			SET @CSTEP = 468

			SELECT @CHOLDBACKMEMOID=b.MEMO_ID ,@CHOLDBACKMEMONO=b.MEMO_NO 
			FROM ITEM_STATUS A (NOLOCK)
			JOIN  HOLD_BACK_DELIVER_MST B (NOLOCK) ON A.HBD_MEMO_ID=B.MEMO_ID
			WHERE A.CM_ID=@CMEMOID and b.cancelled=0

			
			IF LEFT(ISNULL(@CHOLDBACKMEMOID,''),5) IN('','LATER')
			BEGIN
			     SET @nUpdatemode=1
				 GOTO LBLSAVEMEMO
			END

			UPDATE A SET MEMO_ID=@CHOLDBACKMEMOID,MEMO_NO=@CHOLDBACKMEMONO,BIN_ID='999' ,fin_year=@cFinYear
			FROM PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD A
			WHERE SP_ID=@NSPID and LEFT(MEMO_ID,5) IN('','LATER')

			
			UPDATE A SET MEMO_ID=@CHOLDBACKMEMOID,row_id=st.HBD_ROW_ID,PRODUCT_CODE=ST.PRODUCT_CODE
			FROM PSHBD_HOLD_BACK_DELIVER_DET_UPLOAD A
			LEFT JOIN ITEM_STATUS ST (nolock) ON ST.REF_CMD_ROW_ID=A.REF_CMD_ROW_ID and st.HBD_MEMO_ID=@CHOLDBACKMEMOID
			WHERE SP_ID=@NSPID and LEFT(MEMO_ID,5) IN('','LATER')

		END
			
		SET @cStep = 470
		SELECT @cHoldBackMemoId=ISNULL(@cHoldBackMemoId,'LATER'),@cHoldBackMemoNo=ISNULL(@cHoldBackMemoNo,'LATER')

		

		LBLSAVEMEMO:

		IF isnull(@CMEMOPREFIX,'')=''
		   SET @CMEMOPREFIX=@CLOCATIONID
		DECLARE @OUTPUT TABLE (errmsg VARCHAR(MAX),memo_id VARCHAR(40))

		INSERT @OUTPUT (ERRMSG,memo_id)
		EXEC SAVETRAN_HBD
		@NUPDATEMODE=@nUpdatemode ,
		@NSPID=@NSPID,
		@CMEMOID=@CHOLDBACKMEMOID,
		@CPREFIX=@CMEMOPREFIX,
		@CFINYEAR=@CFINYEAR,
		@bCalledFromSlsSavetran=1

		SELECT TOP 1 @CERRORMSG=errmsg,@CHOLDBACKMEMOID=memo_id  FROM @OUTPUT
		
		IF  NOT EXISTS (SELECT TOP 1 'U' FROM HOLD_BACK_DELIVER_MST WHERE MEMO_ID =@CHOLDBACKMEMOID) and ISNULL(@CERRORMSG,'')=''
		BEGIN
		    SET @CERRORMSG='ERROR IN GENERATING MEMO PLEASE CHECK'
		END


		GOTO END_PROC
	END
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GEN_HOLDBACK_MEMO at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:	

END