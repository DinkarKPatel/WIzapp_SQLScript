CREATE PROCEDURE SP3S_INS_PMTMINDT 
@dMemoDt DATETIME,
@cXnType VARCHAR(50)
AS
BEGIN
	IF NOT EXISTS (SELECT TOP 1 * FROM pmtbuild_mindate_xndtchanges)
		INSERT pmtbuild_mindate_xndtchanges (memo_dt,xn_type)
		SELECT @dMemoDt,@cXnType
	ELSE
		UPDATE pmtbuild_mindate_xndtchanges SET memo_dt=@dMemoDt,xn_type=@cXnType WHERE memo_dt>@dMemoDt
END
