CREATE TRIGGER [DBO].[TRG_UPD_PARA2_LAST_MODIFIED_ON] ON [DBO].[PARA2]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.para2_code,'para2' FROM DELETED a
	JOIN INSERTED b ON b.para2_code=a.para2_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para2_code=df.master_code AND df.master_tablename='para2'	
	where (a.para2_name<>b.para2_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'') 
			  OR ISNULL(a.para2_order,0)<>ISNULL(b.para2_order,0) OR ISNULL(a.para2_set,'')<>ISNULL(b.para2_set,''))
	and df.master_code is null

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA2 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA2_CODE=PARA2.PARA2_CODE
	AND (para2.para2_name<>b.para2_name OR para2.alias<>b.alias OR para2.inactive<>b.inactive OR para2.para2_order<>b.para2_order 
		OR para2.para2_set<>b.para2_set OR para2.bl_para2_name<>b.bl_para2_name)
END
