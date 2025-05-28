if exists (select top 1 * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where constraint_name='FK_act_filter_loc_location')
	alter table act_filter_loc drop constraint FK_act_filter_loc_location