CREATE PROCEDURE SP3S_UPDATE_CMM_LASTDTCODE
@nSpId VARCHAR(50),
@dCmDt datetime,
@nUpdatemode int
AS
BEGIN
	DECLARE @cDtCode CHAR(7),@cProductCode VARCHAR(50),@cCmId varchar(50)


	IF @nUpdatemode=2
		SELECT @cCmId=cm_id FROM SLS_CMM01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
	ELSE 
		SET @cCmId=''

	SELECT product_code  into #tmpSlr FROM SLS_cmd01106_UPLOAD a (NOLOCK)
	WHERE a.sp_id=@nSpId AND QUANTITY<0

	WHILE EXISTS (SELECT TOP 1 * FROM #tmpSlr)
	BEGIN
		SELECT TOP 1 @cProductCode=product_code FROM #tmpSlr

		SET @cDtCode=''
		SELECT TOP 1 @cDtCode=dt_code FROM cmd01106 A(NOLOCK) 
		JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
		WHERE PRODUCT_CODE=@cProductCode AND cm_dt<=@dCmDt
		AND QUANTITY>0  AND a.cm_id<>@cCmId AND ISNULL(dt_code,'') NOT IN('','0000000') ORDER BY b.cm_dt desc

		IF ISNULL(@cDtCode,'')<>''
			UPDATE SLS_cmd01106_UPLOAD WITH (ROWLOCK) SET last_cmm_dt_code=@cDtCode WHERE sp_id=@nSpId
			AND PRODUCT_CODE=@cProductCode AND quantity<0

		DELETE FROM #tmpSlr WHERE product_code=@cProductCode
	END
END