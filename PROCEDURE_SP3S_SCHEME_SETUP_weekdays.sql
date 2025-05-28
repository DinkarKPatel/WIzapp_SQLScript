CREATE PROCEDURE SP3S_SCHEME_SETUP_weekdays
@cSchRowId varchar(50)=''
AS
BEGIN
	DECLARE @tWeeks TABLE (weekday_name VARCHAR(20),week_order numeric(1,0))

	INSERT INTO @tWeeks (weekday_name,week_order)
	SELECT 'Sunday',1
	UNION
	SELECT 'Monday',2
	UNION
	SELECT 'Tuesday',3
	UNION
	SELECT 'Wednesday',4
	UNION
	SELECT 'Thursday',5
	UNION
	SELECT 'Friday',6
	UNION
	SELECT 'Saturday',7

	SELECT @cSchRowId as scheme_setup_det_row_id, a.weekday_name,isnull(b.selected,0) selected
	FROM @tWeeks a
	LEFT OUTER JOIN scheme_setup_weekdays_details b ON a.weekday_name=b.weekday_name AND b.scheme_setup_det_row_id=@cSchRowId
	ORDER BY a.week_order
END