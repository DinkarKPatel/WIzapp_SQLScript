CREATE FUNCTION FN_ACT_TRAVTREESTR ( @CHEADCODE VARCHAR(20) )
RETURNS VARCHAR(MAX)
--WITH ENCRYPTION
AS 
BEGIN
	DECLARE @CRETVAL VARCHAR(MAX), 
			@CTEMPHEADCODE VARCHAR(10)
	
	SET @CRETVAL = ''

	DECLARE ABC CURSOR FOR 
	SELECT HEAD_CODE FROM HD01106 (NOLOCK) WHERE MAJOR_HEAD_CODE = @CHEADCODE AND HEAD_CODE <> @CHEADCODE

	OPEN ABC
	FETCH NEXT FROM ABC INTO @CTEMPHEADCODE
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @CRETVAL = @CRETVAL + ',''' + @CTEMPHEADCODE + ''''
		SET @CRETVAL = @CRETVAL + DBO.FN_ACT_TRAVTREESTR( @CTEMPHEADCODE )
	
		FETCH NEXT FROM ABC INTO @CTEMPHEADCODE
	END
	CLOSE ABC
	DEALLOCATE ABC

	RETURN @CRETVAL
END
