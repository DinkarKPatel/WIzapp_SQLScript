if exists (select top 1 constraint_name from information_schema.TABLE_CONSTRAINTS where left(constraint_name,3)='unq_lm01106_ac_name')
	alter table lm01106 drop constraint unq_lm01106_ac_name