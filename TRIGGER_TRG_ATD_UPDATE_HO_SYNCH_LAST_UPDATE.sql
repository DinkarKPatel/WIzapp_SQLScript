create trigger TRG_ATD_UPDATE_HO_SYNCH_LAST_UPDATE on EMP_WPAYATT
for insert
as
begin
     
	  update b set ho_synch_last_update=''  from inserted a
	  join EMP_WPAYATT b on a.row_id=b.row_id 

end
