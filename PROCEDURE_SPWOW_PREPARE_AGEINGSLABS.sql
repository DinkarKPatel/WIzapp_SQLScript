CREATE PROCEDURE SPWOW_PREPARE_AGEINGSLABS
@cAgeingSettingName VARCHAR(100)='ageing setting 1'
AS
BEGIN
	DECLARE @nMaxSrno INT,@nPrevDays INT,@nSrno INT,@nMinSrno INT

	select ageingdays,row_number() over (order by ageingdays) srno into #tmpAgeDays from wowdb_ageingdays (NOLOCK) 
	WHERE groupName=@cAgeingSettingName


	IF NOT EXISTS (SELECT TOP 1 * FROM #tmpAgeDays)
		INSERT INTO #tmpAgeDays (srno,ageingDays)
		select row_number() over (order by sr) sr,ageing_days from XTREME_AGEINGDAYS where mode=1

	select @nMaxSrno=max(srno) from #tmpAgeDays
	
	INSERT INTO #tmpAgeSlabs (fromDays,toDays,slabName,srno)
	SELECT 0,ageingDays ,'<='+LTRIM(RTRIM(str(ageingDays))),srno-1 from #tmpAgeDays WHERE SRNO=1
	union all
	SELECT ageingdays+1,999999999,'>'+LTRIM(RTRIM(str(ageingDays))),srno+1 from #tmpAgeDays WHERE SRNO=@nMaxSrno


	SELECT @nPrevDays=ageingdays from #tmpAgeDays where srno=1
	set @nSrno=2
	while @nSrno<=@nMaxSrno
	BEGIN

		INSERT INTO #tmpAgeSlabs (fromDays,toDays,slabName,srno)
		select @nPrevDays+1,ageingDays,ltrim(rtrim(str(@nPrevDays+1)))+'-'+ltrim(rtrim(str(ageingDays))),srno from #tmpAgeDays where srno=@nSrno

		select @nPrevDays=ageingDays from #tmpAgeDays where srno=@nSrno
		
		set @nSrno=@nSrno+1
	END
END