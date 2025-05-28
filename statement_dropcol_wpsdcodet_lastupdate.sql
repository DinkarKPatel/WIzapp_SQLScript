if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (nolock) where table_name='wps_det' and column_name='last_update')
	alter table wps_Det drop column last_update

if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (nolock) where table_name='floor_st_det' and column_name='last_update')
	alter table floor_st_det drop column last_update