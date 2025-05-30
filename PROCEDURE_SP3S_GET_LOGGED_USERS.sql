CREATE PROCEDURE SP3S_GET_LOGGED_USERS
AS
BEGIN
	DECLARE @tDelSessions TABLE (spid INT)

	IF OBJECT_ID('tempdb..#SSPLLogin','U') IS NOT NULL
		DROP TABLE #SSPLLogin

	
	SELECT CAST('' AS VARCHAR(MAX)) AS WINDOW_USER_NAME,CAST('' AS VARCHAR(MAX)) AS COMPUTER_NAME,CAST('' AS VARCHAR(MAX)) AS LOGIN_NAME
	,CAST('' AS DATETIME) AS LOGIN_TIME,CAST('' AS VARCHAR(MAX)) AS SP_ID,CAST('' AS VARCHAR(MAX)) AS LOCATION_ID,CAST('' AS VARCHAR(MAX)) AS BIN_ID
	INTO #SSPLLogin
	WHERE 1=2
	
	EXECUTE SP3S_GET_LOGGED_USERS_THROUGH_TEMPDB @bShowResult=0

	INSERT @tDelSessions
	SELECT A.spid 
	FROM NEW_APP_LOGIN_INFO a WITH (ROWLOCK)
	LEFT OUTER JOIN
	(
		--SELECT CONVERT(INT,case when   charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))) =0 then  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))
	 --           else  left(LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))), charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))))-1) end ) AS SPID 
		--FROM tempdb.INFORMATION_SCHEMA.TABLES (NOLOCK) WHERE TABLE_NAME LIKE '##'+CAST(DB_NAME() AS VARCHAR(100))+'[_]TMP[_]LOGIN[_]%'
		SELECT * FROM #SSPLLogin
	)b ON b.SP_ID=a.SPID
	WHERE b.SP_ID IS NULL

	IF EXISTS (SELECT TOP 1 * FROM @tDelSessions)
		DELETE  a FROM NEW_APP_LOGIN_INFO a WITH (ROWLOCK) JOIN @tDelSessions b ON a.spid=b.spid

	--SELECT STATIC_IP AS IP,COMPUTER_NAME AS [WINDOW],WINDOW_USER_NAME AS [USER], 
	--LOGIN_NAME AS [LOGIN],a.SPID AS [SP ID], LAST_UPDATE AS [LOGIN TIME],
	--CAST(0 AS BIT) AS CHK,PROCESS_ID 
	SELECT STATIC_IP AS IP,A.COMPUTER_NAME AS [WINDOW],A.WINDOW_USER_NAME AS [USER], 
	A.LOGIN_NAME AS [LOGIN],a.SP_ID AS [SP ID], A.LOGIN_TIME AS [LOGIN TIME],
	CAST(0 AS BIT) AS CHK,PROCESS_ID 
	FROM #SSPLLogin a (NOLOCK)
	LEFT OUTER JOIN
	(
		--SELECT CONVERT(INT,case when   charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))) =0 then  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))
	 --           else  left(LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))), charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))))-1) end ) AS SPID 
		--FROM tempdb.INFORMATION_SCHEMA.TABLES (NOLOCK) 
		--WHERE TABLE_NAME LIKE '##'+CAST(DB_NAME() AS VARCHAR(100))+'[_]TMP[_]LOGIN[_]%'
		SELECT * FROM NEW_APP_LOGIN_INFO
	)b ON b.SPID=a.SP_ID
	/*
	DECLARE @tDelSessions TABLE (spid INT)

	INSERT @tDelSessions
	SELECT A.spid 
	FROM NEW_APP_LOGIN_INFO a WITH (ROWLOCK)
	LEFT OUTER JOIN
	(
		SELECT CONVERT(INT,case when   charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))) =0 then  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))
	            else  left(LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))), charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))))-1) end ) AS SPID 
		FROM tempdb.INFORMATION_SCHEMA.TABLES (NOLOCK) WHERE TABLE_NAME LIKE '##'+CAST(DB_NAME() AS VARCHAR(100))+'[_]TMP[_]LOGIN[_]%'
	)b ON b.SPID=a.SPID
	WHERE b.SPID IS NULL

	IF EXISTS (SELECT TOP 1 * FROM @tDelSessions)
		DELETE  a FROM NEW_APP_LOGIN_INFO a WITH (ROWLOCK) JOIN @tDelSessions b ON a.spid=b.spid

	SELECT STATIC_IP AS IP,COMPUTER_NAME AS [WINDOW],WINDOW_USER_NAME AS [USER], 
	LOGIN_NAME AS [LOGIN],a.SPID AS [SP ID], LAST_UPDATE AS [LOGIN TIME],
	CAST(0 AS BIT) AS CHK,PROCESS_ID 
	FROM NEW_APP_LOGIN_INFO a (NOLOCK)
	JOIN
	(
		SELECT CONVERT(INT,case when   charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))) =0 then  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_','')))
	            else  left(LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))), charindex('_',  LTRIM(RTRIM(REPLACE(TABLE_NAME,'##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_',''))))-1) end ) AS SPID 
		FROM tempdb.INFORMATION_SCHEMA.TABLES (NOLOCK) 
		WHERE TABLE_NAME LIKE '##'+CAST(DB_NAME() AS VARCHAR(100))+'[_]TMP[_]LOGIN[_]%'
	)b ON b.SPID=a.SPID
	*/

END

