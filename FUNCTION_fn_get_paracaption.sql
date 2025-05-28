CREATE FUNCTION fn_get_paracaption(@cParaName VARCHAR(200))
returns varchar(200)
as
begin
	DECLARE @cCaption VARCHAR(200)

	IF @cParaName LIKE '%para%caption'
		SELECT TOP 1 @cCaption=value FROM config (NOLOCK) WHERE config_option=REPLACE(@cParaName,'_name','_caption')
	else
		SET @cCaption=@cParaName

	RETURN @cCaption
end