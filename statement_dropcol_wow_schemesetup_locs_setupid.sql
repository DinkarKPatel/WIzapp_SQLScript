if exists (select top 1 column_name from  INFORMATION_SCHEMA.columns where column_name='setupid'
and table_name='wow_schemesetup_locs')
	alter table wow_schemesetup_locs drop column setupid