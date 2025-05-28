create TRIGGER [DBO].[TRG_UPD_UOM_LAST_MODIFIED_ON] ON [DBO].UOM
FOR UPDATE
AS
BEGIN

	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.uom_code,'UOM' FROM DELETED a
	JOIN INSERTED b ON b.uom_code=a.uom_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.uom_code=df.master_code AND df.master_tablename='UOM'	
	where (isnull(a.uom_type,0) <> isnull(B.uom_type,0) OR a.inactive <> B.inactive OR
	a.uom_name <> B.uom_name OR a.bl_uom_name <> B.bl_uom_name) and df.master_code is null


	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
			
	UPDATE UOM SET LAST_MODIFIED_ON=CAST(GETDATE() AS DATE) 
	FROM DELETED B WHERE B.uom_code=UOM.uom_code
	AND (uom.uom_type <> B.uom_type OR uom.inactive <> B.inactive OR
	uom.uom_name <> B.uom_name OR uom.bl_uom_name <> B.bl_uom_name)
END