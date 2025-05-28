CREATE PROCEDURE SP3S_CREATE_LOCWISEGITXNS_STRU
@dXnDt DATETIME,
@bInsGit BIT=0
AS
BEGIN
	DECLARE @cPmtDbName VARCHAR(100),@cCmd NVARCHAR(MAX),@CFILEPATH VARCHAR(500),@cPmtTableNameXnDt VARCHAR(200),
	@cPrevGitTableNameXnDt VARCHAR(200),@cPmtTableXnDt VARCHAR(100),@cGitTableNameXnDt VARCHAR(200)

	SET @cGitTableNameXnDt=DB_NAME()+'_pmt..gitlocs_'+CONVERT(VARCHAR,@dXnDt,112)
	IF OBJECT_ID(@cGitTableNameXnDt,'U') IS NULL
	BEGIN
		SET @CCMD=N'SELECT CONVERT(VARCHAR(45),'''') AS memo_id,product_code,dept_id,bin_id,quantity_in_stock as git_qty,
		CONVERT(NUMERIC(15,2),0) AS git_pp,convert(varchar(40),'''') xn_no,last_update as xn_dt,
		CONVERT(VARCHAR(20),'''') xn_party_code INTO '+@cGitTableNameXnDt+' FROM pmt01106 WHERE 1=2'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
			   		
		SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_GIT'+CONVERT(VARCHAR,@dXnDt,112)+
		' ON '+@cGitTableNameXnDt+' ([dept_id])
		INCLUDE ([product_code],[git_qty],[git_pp])'
		print @cCmd
		 EXEC SP_EXECUTESQL @cCmd
	END

	IF @bInsGit=1
	BEGIN
		SET @cPrevGitTableNameXnDt=DB_NAME()+'_pmt..gitlocs_'+CONVERT(VARCHAR,@dXnDt-1,112)

		SET @cCmd=N'TRUNCATE TABLE '+@cGitTableNameXnDt
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cCmd=N'INSERT '+@cGitTableNameXnDt+'(memo_id,product_code,bin_id,dept_id,cbs_qty,cbp,xn_party_code,xn_no,xn_dt)
					SELECT memo_id,product_code,bin_id,dept_id,cbs_qty,cbp,xn_party_code,xn_no,xn_dt
					FROM '+@cPrevGitTableNameXnDt
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END
END