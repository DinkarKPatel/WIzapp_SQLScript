
declare @cconstraintname varchar(100),@dtsql nvarchar(max)
select @cconstraintname=CONSTRAINT_NAME   from INFORMATION_SCHEMA.KEY_COLUMN_USAGE   where  table_name='DESIGNM' and COLUMN_NAME ='design_code'

if isnull(@cconstraintname,'')<>''
begin
	set @dtsql=N'ALTER TABLE DESIGNM DROP CONSTRAINT '+@cconstraintname+''
	exec sp_executesql @dtsql
end

ALTER TABLE DESIGNM alter column design_code varchar(10) not null
ALTER TABLE DESIGNM add CONSTRAINT pk_designm_designcode primary key (design_code)



