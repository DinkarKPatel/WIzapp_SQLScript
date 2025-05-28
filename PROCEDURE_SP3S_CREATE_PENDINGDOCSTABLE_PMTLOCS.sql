CREATE PROCEDURE SP3S_CREATE_PENDINGDOCSTABLE_PMTLOCS--(LocId 3 digit change by Sanjay:04-11-2024)
@cPmtDbName VARCHAR(400),
@cDtSuffix varchar(20)
AS
BEGIN
	DECLARE @tSauAdjCbs varchar(200),@tWip VARCHAR(200),@tPendingJw VARCHAR(200),@tPendingApp VARCHAR(200),@tGit VARCHAR(200),
	@tPendingWPS VARCHAR(200),@tPendingRPS VARCHAR(200),@tPendingDNPS VARCHAR(200),@tPendingCNPS VARCHAR(200),@CCMD NVARCHAR(MAX)
	
	SELECT 	@tWip=@cPmtDbName+'WIPSTOCK_'+@cDtSuffix,
	@tPendingApp=@cPmtDbName+'PENDING_APPROVALS_'+@cDtSuffix,
	@tPendingJw=@cPmtDbName+'PENDING_JOBWORK_TRADING_'+@cDtSuffix

	EXEC SP3S_CREATE_LOCWISEGITXNS_STRU @cDtSuffix

	

	IF OBJECT_ID(@tPendingApp,'U') IS NULL
	BEGIN
		SET @CCMD=N'CREATE TABLE '+@tPendingApp+'(memo_id VARCHAR(50),xn_no varchar(50),xn_dt DATETIME,xn_party_code varchar(50),
					PRODUCT_CODE VARCHAR(50),DEPT_ID  VARCHAR(4),bin_id VARCHAR(7),quantity NUMERIC(10,2))'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF OBJECT_ID(@tPendingJw,'U') IS NULL
	BEGIN
		SET @CCMD=N'CREATE TABLE '+@tPendingJw+'(memo_id VARCHAR(50),xn_no varchar(50),xn_dt DATETIME,xn_party_code varchar(50),
					PRODUCT_CODE VARCHAR(50),DEPT_ID  VARCHAR(4),bin_id VARCHAR(7),quantity NUMERIC(10,2))'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF OBJECT_ID(@tWIP,'U') IS NULL
	BEGIN
		SET @CCMD=N'CREATE TABLE '+@tWIP+'(memo_id VARCHAR(50),xn_no varchar(50),xn_dt DATETIME,xn_party_code varchar(50),
					PRODUCT_CODE VARCHAR(50),DEPT_ID  VARCHAR(4),bin_id VARCHAR(7),quantity NUMERIC(10,2),value NUMERIC(10,2))'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'TRUNCATE TABLE '+@tPendingApp
	EXEC SP_EXECUTESQL @cCmd
	SET @cCmd=N'TRUNCATE TABLE '+@tWip
	EXEC SP_EXECUTESQL @cCmd
	SET @cCmd=N'TRUNCATE TABLE '+@tPendingJw
	EXEC SP_EXECUTESQL @cCmd
	
END
