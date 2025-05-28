
if not exists (select top  1 'u' from para7 where PARA7_CODE ='0000000')
begin

	insert into para7(PARA7_CODE,PARA7_NAME,LAST_UPDATE,INACTIVE,LAST_MODIFIED_ON)
	select '0000000' PARA7_CODE,'' PARA7_NAME,getdate() LAST_UPDATE,0 INACTIVE,null LAST_MODIFIED_ON

end
