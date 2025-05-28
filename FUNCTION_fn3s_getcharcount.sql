CREATE FUNCTION fn3s_getcharcount(@tosearch varchar(30),@cString varchar(max))
RETURNS INT
AS
BEGIN
	DECLARE @nCnt INT
	SET @nCnt=(DATALENGTH(@cString)-DATALENGTH(REPLACE(@cString,@tosearch,'')))/DATALENGTH(@tosearch)

	RETURN @nCnt
END
