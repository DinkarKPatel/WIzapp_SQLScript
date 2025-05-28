CREATE FUNCTION DBO.GET_WEEK_START_END(@myDate DATE, @TYPE VARCHAR(1))
RETURNS DATE
AS
BEGIN
	DECLARE @ReturnDt DATE;
	SET @ReturnDt = @myDate;
	
	DECLARE @MondayDateFirstValue INT = 1
	SET @MondayDateFirstValue = 7 - @MondayDateFirstValue - 1

	IF @TYPE = 'S'
	   SET @ReturnDt = DATEADD(DAY, 0 - (@@DATEFIRST + @MondayDateFirstValue + DATEPART(dw, @myDate)) % 7, @myDate)
	ELSE IF @TYPE = 'E'
	   SET @ReturnDt = DATEADD(DAY, 6 - (@@DATEFIRST + @MondayDateFirstValue + DATEPART(dw, @myDate)) % 7, @myDate)
	
	RETURN @ReturnDt
END