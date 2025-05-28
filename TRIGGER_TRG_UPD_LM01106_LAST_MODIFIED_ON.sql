CREATE TRIGGER [DBO].[TRG_UPD_LM01106_LAST_MODIFIED_ON] ON [DBO].[LM01106]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.ac_code,'lm01106' FROM DELETED a
	JOIN INSERTED b ON b.ac_code=a.ac_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.ac_code=df.master_code AND df.master_tablename='lm01106'	
	where a.AC_NAME<>b.AC_NAME OR a.alias<>b.alias AND df.master_code IS NULL

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE LM01106 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.AC_CODE=LM01106.AC_CODE
	AND (lm01106.ac_name<>b.ac_name OR lm01106.head_code<>b.head_code OR lm01106.ALIAS<>b.alias)
END
