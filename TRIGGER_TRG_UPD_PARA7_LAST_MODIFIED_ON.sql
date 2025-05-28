CREATE TRIGGER [DBO].[TRG_UPD_PARA7_LAST_MODIFIED_ON] ON [DBO].[PARA7]
FOR UPDATE
AS
BEGIN
     
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.para7_code,'para7' FROM DELETED a
	JOIN INSERTED b ON b.para7_code=a.para7_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para7_code=df.master_code AND df.master_tablename='para7'	
	where (a.para7_name<>b.para7_name ) and df.master_code is null


	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA7 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA7_CODE=PARA7.PARA7_CODE
	AND (PARA7.para7_name<>b.para7_name  OR PARA7.inactive<>b.inactive )
END
