if exists (select top 1 column_name from INFORMATION_SCHEMA.columns where table_name='wow_auth_mappings' and column_name='wow_auth_option')
	alter table wow_auth_mappings drop column wow_auth_option

if exists (select top 1 column_name from INFORMATION_SCHEMA.columns where table_name='wow_auth_mappings' and column_name='wa_form_option')
	alter table wow_auth_mappings drop column wa_form_option

truncate table wow_auth_mappings
