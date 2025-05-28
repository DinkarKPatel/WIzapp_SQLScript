CREATE PROCEDURE SP3s_validate_weekdates(@dFromDt DATETIME,@dToDt DATETIME)
as
begin
	declare @dRetDate1 datetime,@dREtDate2 DATETIME,@cErrormsg varchar(500)

	SET @cErrormsg=''
	select @dRetDate1= @dFromdt - DATEPART(weekday, @dFromdt)+1,
		   @dRetDate2=@dToDt - DATEPART(weekday, @dToDt) + 7

	IF @dRetDate1<>@dFromDt OR @dREtDate2<>@dToDt
		SET @cErrormsg='From Date should be : '+CONVERT(VARCHAR,@dRetdate1,105)+' and To Date should be :'+CONVERT(VARCHAR,@dRetdate2,105)+
					   ' for getting Week wise Reports..'
	
	SELECT @cErrormsg errmsg
end