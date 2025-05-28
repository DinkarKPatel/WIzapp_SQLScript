IF OBJECT_ID('temp_pim01106','u') IS NOT NULL
BEGIN
	---- We need to do this because this table not having mrr_dt column due to which Procedure accessing this table
	---- not being able to create
	DECLARE @cCmd NVARCHAR(MAX)
	SET @cCmd=N'DROP TABLE temp_pim01106'
	EXEC SP_EXECUTESQL @cCmd
END
