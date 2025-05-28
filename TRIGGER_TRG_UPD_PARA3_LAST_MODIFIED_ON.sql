CREATE TRIGGER [DBO].[TRG_UPD_PARA3_LAST_MODIFIED_ON] ON [DBO].[PARA3]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT b.para3_code,'para3' FROM DELETED a
	JOIN INSERTED b ON b.para3_code=a.para3_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para3_code=df.master_code AND df.master_tablename='para3'	
	where (a.para3_name<>b.para3_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'')) and df.master_code is null

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA3 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA3_CODE=PARA3.PARA3_CODE
	AND (para3.para3_name<>b.para3_name OR para3.alias<>b.alias OR para3.inactive<>b.inactive 
		OR  para3.bl_para3_name<>b.bl_para3_name)
END
