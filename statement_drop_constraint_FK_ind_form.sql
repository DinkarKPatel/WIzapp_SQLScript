if exists (select top 1 * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where constraint_name='FK_ind_form')
	alter table ind01106 drop constraint FK_ind_form
