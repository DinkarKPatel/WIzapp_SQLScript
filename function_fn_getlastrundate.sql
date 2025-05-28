CREATE FUNCTION fn_getlastrundate()
returns datetime
AS
BEGIN
	DECLARE @cDeptId VARCHAR(4),@dlastRundate datetime
	SELECT @cDeptId=dept_id FROM NEW_APP_LOGIN_INFO (nolock) where spid=@@spid

	SELECT @dlastRundate=VALUE FROM config where config_option='last_run_date_wenc_'+@cDeptId

	if @dlastRundate IS NULL
		SELECT @dlastRundate=VALUE FROM config where config_option='last_run_date_wenc'
	
	RETURN @dlastRundate
END