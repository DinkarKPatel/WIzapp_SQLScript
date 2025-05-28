create FUNCTION DbO.FN_CHECKHOLOC()
RETURNS BIT
AS
BEGIN
	DECLARE @cHoLocId CHAR(2),@cCurLocId CHAR(2),@bHoLoc BIT
	SELECT TOP 1 @cCurLocId=value FROM config (NOLOCK) WHERE config_option='location_id'
	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

	IF @cCurLocId=@cHoLocId
		SET @bHoLoc=1
	ELSE
		SET @bHoLoc=0

	RETURN @bHoLoc
END
