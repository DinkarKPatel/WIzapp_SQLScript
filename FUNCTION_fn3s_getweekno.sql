CREATE FUNCTION fn3s_getweekno(@dXnDt DATETIME)
RETURNS INT
AS
BEGIN
	DECLARE @nRetWeekNo INT

	SELECT TOP 1@nRetWeekNo= week_no FROM WEEKNO_DATES (NOLOCK) WHERE xn_year=year(@dXnDt) AND 
	@dXndt BETWEEN from_dt AND to_dt
	
	IF @nRetWeekNo IS NULL
		SET @nRetWeekNo=DATEPART(WEEK,@dXnDt)	
	
	RETURN @nRetWeekno
END
