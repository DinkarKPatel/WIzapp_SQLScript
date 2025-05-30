CREATE FUNCTION FN_GETSLSTITLE (@NMODE INT,@CCMDROWID VARCHAR(40))
RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @CRETSTR VARCHAR(200)
	
	SET @CRETSTR=''
	
	IF @NMODE=1
		SELECT TOP 1 @CRETSTR=SLS_TITLE FROM CMD_SCHEME_DET A WHERE CMD_ROW_ID=@CCMDROWID
	ELSE
		SELECT TOP 1 @CRETSTR=SLS_TITLE FROM SLS_CMD_SCHEME_DET_UPLOAD A WHERE CMD_ROW_ID=@CCMDROWID	
	
	RETURN ISNULL(@CRETSTR,'')	
END
