CREATE PROCEDURE SP3S_GETIRR_LASTUPDATE
AS
BEGIN
	declare @dLupd DATETIME,@cHoLocId VARCHAR(4)

	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

	SELECT @dLupd=MAX(b.last_update) FROM IRM01106 b
	WHERE TYPE<>2 AND ISNULL(barcodes_generated,0)=0 AND left(b.irm_memo_id,2)=@cHoLocId

	IF ISNULL(@dLupd,'')<>''
		SELECT CONVERT(VARCHAR,@dLupd,113) AS LastIRRSynchUpdate
	ELSE
		SELECT TOP 1 CONVERT(VARCHAR,XN_DT,113)  AS LASTIRRSYNCHUPDATE	FROM VW_XNSREPS (NOLOCK) WHERE XN_DT<>'' ORDER BY XN_DT		--discuss with sanjiv sir (min date of vwxnsreps)
END
