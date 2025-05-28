CREATE TRIGGER [DBO].[TRG_UPD_PARA5_LAST_MODIFIED_ON] ON [DBO].[PARA5]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.para5_code,'para5' FROM DELETED a
	JOIN INSERTED b ON b.para5_code=a.para5_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para5_code=df.master_code AND df.master_tablename='para5'	
	where (a.para5_name<>b.para5_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'')) and df.master_code is null

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA5 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA5_CODE=PARA5.PARA5_CODE
	AND (para5.para5_name<>b.para5_name OR para5.alias<>b.alias OR para5.inactive<>b.inactive 
		OR  para5.bl_para5_name<>b.bl_para5_name)
END
