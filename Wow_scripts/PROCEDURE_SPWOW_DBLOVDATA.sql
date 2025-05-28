CREATE PROCEDURE SPWOW_DBLOVDATA
@cLovType VARCHAR(100),
@cSeasonCode CHAR(7)=''
AS
BEGIN
	IF @cLovType='POS'
	BEGIN
		SELECT dept_id locId,dept_id+'-'+dept_name locName,dept_alias locAlias from location (NOLOCK)
	END
	ELSE
	IF @cLovType='USR'
	BEGIN
		SELECT a.dept_id locId,b.user_code userId,username userName from locusers a (nolock)
		JOIN users b (NOLOCK) ON a.user_code=b.user_code
		ORDER BY 1
	END
	ELSE
	IF @cLovType='DLVWH'
	BEGIN
		SELECT distinct a.dept_id locId,a.dept_id+'-'+dept_name locName,dept_alias locAlias from buyer_order_mst a (NOLOCK)
		JOIN location b (NOLOCK) ON a.wbo_for_dept_id=b.dept_id
		WHERE inactive=0 AND a.season_code=@cSeasonCode
	END

END
