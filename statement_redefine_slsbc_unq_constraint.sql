DECLARE @cCmd NVARCHAR(MAX)
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='UNQ_scheme_Setup_slsbc')
BEGIN
	SET @cCmd=N'alter table scheme_Setup_slsbc drop constraint UNQ_scheme_Setup_slsbc'
	EXEC SP_EXECUTESQL @cCmd
END

SET @cCmd=N'alter table scheme_Setup_slsbc add constraint UNQ_scheme_Setup_slsbc unique (scheme_setup_det_row_id,product_code,source_type)'
EXEC SP_EXECUTESQL @cCmd