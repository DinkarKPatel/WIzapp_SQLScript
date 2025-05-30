CREATE PROCEDURE SP3S_VCHPOSTING_WIZ
(
	@NQID			INT,
	@DTTODAYDATE	DATETIME,
	@bShowAll		BIT=0
)
AS
BEGIN
	DECLARE @CHEADCODE VARCHAR(MAX) ,@CHEADCODE1 VARCHAR(MAX) 
	IF @NQID=1
	BEGIN
		SELECT DISTINCT XN_TYPE, DISPLAY_XN_TYPE AS [XN_DESC],
		(CASE WHEN xn_type in ('arc','SLS') THEN CAST(@DTTODAYDATE-1 AS DATETIME) ELSE CAST(@DTTODAYDATE AS DATETIME) END) AS [AS_ON],'' AS DEPT_ID,'' AS DEPT_NAME,
		'' AS AC_CODE,'' AS AC_NAME,CAST(1 AS BIT) AS CHK,SNO
		FROM GST_ACCOUNTS_CONFIG_MST
		WHERE ISNULL(ENABLEPOSTING,0)=1
		ORDER BY SNO

		SELECT * FROM GST_ACCOUNTS_CONFIG_MST WHERE xn_type in ('arc','SLS')
	END
	ELSE IF @NQID=2
	BEGIN
		SELECT DEPT_ID,DEPT_ID+' - '+DEPT_NAME AS DEPT_NAME
		FROM LOCATION a (NOLOCK)
		JOIN loc_accounting_company b  (NOLOCK) ON a.PAN_NO=b.pan_no
		UNION 
		SELECT DEPT_ID,DEPT_ID+' - '+DEPT_NAME AS DEPT_NAME
		FROM LOCATION a (NOLOCK)
		JOIN loc_accounting_company b  (NOLOCK) ON SUBSTRING(a.loc_gst_no,3,10)=b.pan_no
		UNION ALL
		SELECT '' AS DEPT_ID,'--ALL--' AS DEPT_NAME 
		ORDER BY DEPT_NAME
	END
	ELSE IF @NQID=3
	BEGIN
		IF ISNULL(@bShowAll,0)=1
		BEGIN
			SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000021') 
			SET @CHEADCODE1=DBO.FN_ACT_TRAVTREE('0000000018') 
			SELECT '' AS AC_CODE, '--ALL--' AS AC_NAME
			UNION
			SELECT AC_CODE, AC_NAME FROM LMV01106 (NOLOCK) 
			WHERE  ISNULL(INACTIVE,0)=0 AND (CHARINDEX(HEAD_CODE,@CHEADCODE)>0 OR ALLOW_CREDITOR_DEBTOR = 1) 
			AND LTRIM(RTRIM(ISNULL(AC_NAME,'')))<>''  
			UNION 
			SELECT AC_CODE, AC_NAME FROM LMV01106 (NOLOCK) 
			WHERE  ISNULL(INACTIVE,0)=0 AND (CHARINDEX(HEAD_CODE,@CHEADCODE1)>0 OR ALLOW_CREDITOR_DEBTOR = 1) 
			AND LTRIM(RTRIM(ISNULL(AC_NAME,'')))<>'' 
			ORDER BY AC_NAME
		END
		ELSE 
			SELECT '' AS AC_CODE, '--ALL--' AS AC_NAME
		END
	ELSE IF @NQID=4
	BEGIN
		IF ISNULL(@bShowAll,0)=1
		BEGIN
			SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000018') 
			SELECT '' AS AC_CODE, '--ALL--' AS AC_NAME
			UNION
			SELECT AC_CODE, AC_NAME FROM LMV01106 (NOLOCK) 
			WHERE  ISNULL(INACTIVE,0)=0 AND (CHARINDEX(HEAD_CODE,@CHEADCODE)>0 OR ALLOW_CREDITOR_DEBTOR = 1) 
			AND LTRIM(RTRIM(ISNULL(AC_NAME,'')))<>'' AND 1=2 
			ORDER BY AC_NAME
		END
		ELSE 
			SELECT '' AS AC_CODE, '--ALL--' AS AC_NAME
		END
	
END
