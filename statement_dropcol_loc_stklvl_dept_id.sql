if exists (select column_name from INFORMATION_SCHEMA.columns where column_name='dept_id'
			and table_name='loc_stock_level')
	alter table loc_stock_level drop column dept_id 
if exists (select column_name from INFORMATION_SCHEMA.columns where column_name='dept_id'
			and table_name='stklvl_loc_stock_level_upload')
	alter table stklvl_loc_stock_level_upload drop column dept_id 
