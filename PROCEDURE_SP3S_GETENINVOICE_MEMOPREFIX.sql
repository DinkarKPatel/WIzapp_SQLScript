create PROCEDURE SP3S_GETENINVOICE_MEMOPREFIX 
@cXnType VARCHAR(20),
@cPartyGstNo VARCHAR(50),
@cSourceLocId VARCHAR(50),
@cFinyear VARCHAR(10),
@cInputMemoPrefix VARCHAR(25),
@nSpId VARCHAR(40)='',
@cErrormsg VARCHAR(MAX) OUTPUT,
@cOutputMemoPrefix VARCHAR(25) OUTPUT
AS
BEGIN
	DECLARE @bEnableEInvoice BIT,@NPARTYTYPE NUMERIC(1,0),@cPartyCode VARCHAR(15),@bDonotPrefixFinyear BIT,
			@cStep VARCHAR(4),@cUserAlias VARCHAR(5),@cKeysTable VARCHAR(20),@cCmd NVARCHAR(MAX),
			@clastkeyval VARCHAR(20)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''
	
	SET @bDonotPrefixFinyear=0
	SET @cOutputMemoPrefix=@cInputMemoPrefix
	
	SET @cStep='20'
	IF @cXnType NOT IN ('WSL_GRP','WSL','GRP_WSR','WSR_GRP','PRT_GRP','PRT','WSR','SLS','FDN','FCN') OR @cFinYear<'01122'
		RETURN
	
	SELECT @bEnableEInvoice= ISNULL(enable_einvoice,0)	FROM location (NOLOCK) WHERE dept_id=@cSourceLocId
	--- Changes done as per WizTickit#0523-00026
	IF @cXnType='SLS' 
	BEGIN
		IF (@bEnableEInvoice=1 AND ISNULL(@cPartyGstNo,'')='') OR @bEnableEInvoice=0
			SELECT @bEnableEInvoice=ISNULL(ENFORCE_YEAR_CODE_RETAIL_SALE,0) 
			FROM location (NOLOCK) WHERE dept_id=@cSourceLocId
	END

	IF ISNULL(@bEnableEInvoice,0)=0
		RETURN

	IF @cXntype='SLS'
	BEGIN
	
		SET @cStep='32'
		SET @CKEYSTABLE='KEYS_CMM_'+LTRIM(RTRIM(@CUSERALIAS))

	END		

	
	SET @cStep='60'
	IF  @bDonotPrefixFinyear=0 
	BEGIN
		SET @cOutputMemoPrefix=@cInputMemoPrefix+RIGHT(@cFinyear,2)

		IF @cXntype='SLS'
		BEGIN
			SET @cCmd=N'SELECT @clastkeyval=lastkeyval FROM  '+@cKeysTable+' WHERE prefix='''+@cOutputMemoPrefix+''''
			EXEC SP_EXECUTESQL @cCmd,N'@clastkeyval VARCHAR(10) OUTPUT',@clastkeyval OUTPUT
			IF RIGHT(@clastkeyval,5)='99999'
				SET @cErrormsg='Maximum bills generated in this series ...Either change User alias or Create Bill in other User'
		END
	END
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETENINVOICE_MEMOPREFIX at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END