CREATE TRIGGER [DBO].[TRG_UPD_PARA1_LAST_MODIFIED_ON] ON [DBO].[PARA1]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN

	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.para1_code,'para1'  FROM DELETED a
	JOIN INSERTED b ON b.para1_code=a.para1_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para1_code=df.master_code AND df.master_tablename='para1'	
	where (a.para1_name<>b.para1_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'')
	OR ISNULL(a.para1_set,'')<>ISNULL(b.para1_Set,''))  and df.master_code is null


	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA1 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA1_CODE=PARA1.PARA1_CODE
	AND (para1.para1_name<>b.para1_name OR para1.alias<>b.alias OR para1.inactive<>b.inactive OR para1.para1_order<>b.para1_order OR para1.para1_set<>b.para1_set OR para1.bl_para1_name<>b.bl_para1_name)
END
