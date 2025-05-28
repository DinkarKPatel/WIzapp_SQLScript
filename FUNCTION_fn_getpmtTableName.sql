CREATE function dbo.fn_getpmtTableName(@dLastXnDt datetime)
returns varchar(200)
as
begin
	declare @dFromDt DATETIME,@Cpmttablename varchar(200)
	
	set @Cpmttablename=''

	set @dFromDt=dateadd(dd,1,dateadd(mm,-1,@dLastXnDt))

	set @dLastXnDt=@dLastXnDt-1
	while @dLastXndt>=@dFromDt
	begin
		set @Cpmttablename=DB_NAME()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@DLASTXNDT,112)		
		if object_id(@Cpmttablename,'u') is not null
			break
		else
			set @Cpmttablename=''
		set @dLastXnDt=@dLastXnDt-1
	end

	return @Cpmttablename
end