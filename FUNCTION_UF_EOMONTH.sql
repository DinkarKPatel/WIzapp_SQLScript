CREATE FUNCTION UF_EOMONTH (@dDate datetime)
returns date
as
begin
	return convert(date,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@dDate)+1,0)))
end


