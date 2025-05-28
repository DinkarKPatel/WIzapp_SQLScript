CREATE PROCEDURE SP3S_BUILD_WEEKNO_DATES 
@bCalledfromDayChange BIT=0
AS
BEGIN
	DECLARE @nYearStored NUMERIC(4,0),@dFromDt DATETIME,@dToDt DATETIME,@cDate VARCHAR(10),
	@cFinYear VARCHAR(10),@dRetDate1 DATETIME,@dRetDate2 DATETIME,@nWeekNo NUMERIC(3,0),@nLastWeekNo NUMERIC(3,0)

	IF @bCalledfromDayChange=1
	BEGIN
		SELECT TOP 1 @dToDt=to_dt,@dFromDt=from_dt FROM weekno_dates ORDER BY to_dt desc
		IF @dToDt IS NOT NULL
		BEGIN
			IF YEAR(@dToDt)>YEAR(getdate())
				RETURN
		END

	END

	DELETE FROM weekno_dates

	SET @cDate='2017-01-01'

	select @cFinyear='01'+dbo.FN_GETFINYEAR(CONVERT(DATE,@cDate))

	SET @dFromDt=CONVERT(DATE,@cDate)

	
	SET @cDate=LTRIM(RTRIM(STR(DATEPART(YY,GETDATE()))))+'-12-31'
	select @cFinyear='01'+dbo.FN_GETFINYEAR(@cDate)

	SET @dToDt=dbo.FN_GETFINYEARdate(@cFinyear,2)

	DELETE FROM weekno_dates WHERE xn_year BETWEEN YEAR(@dFromDt) AND YEAR(@dToDt)

	
	SELECT @nWeekNo=0,@nlastWeekNo=0

	SET @nWeekNo=0
	WHILE @dFromdt<=@dToDt
	BEGIN
		
		SET @nWeekNo=@nWeekNo+1

		SET @dRetDate2=@dFromdt+6
		
		INSERT INTO weekno_dates (xn_year,from_dt,to_dt,weekdates_str,week_no)
		SELECT year(@dFromDt) xn_year,@dFromDt from_dt,@dRetDate2 to_dt,
		(CONVERT(VARCHAR,@dFromdt,103)+'-'+CONVERT(VARCHAR,@dRetDate2,103)) as weekdates_str,@nWeekNo week_no
		
		IF (DATEPART(dd,@dRetDate2)=31 AND datepart(mm,@dRetDate2)=12) OR
			(datepart(mm,@dFromDt)=12 AND datepart(mm,@dRetDate2)=1)
			SET @nWeekNo=0

		SET @dFromdt=@dRetDate2+1

	END

END
