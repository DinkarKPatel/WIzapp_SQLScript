CREATE TRIGGER [DBO].[TRG_UPD_PARA6_LAST_MODIFIED_ON] ON [DBO].[PARA6]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.para6_code,'para6' FROM DELETED a
	JOIN INSERTED b ON b.para6_code=a.para6_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para6_code=df.master_code AND df.master_tablename='para6'	
	where (a.para6_name<>b.para6_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'')) and df.master_code is null

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA6 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA6_CODE=PARA6.PARA6_CODE
	AND (para6.para6_name<>b.para6_name OR para6.alias<>b.alias OR para6.inactive<>b.inactive 
		OR  para6.bl_para6_name<>b.bl_para6_name)
END
