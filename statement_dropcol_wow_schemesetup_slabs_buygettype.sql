if exists (select top 1 column_name from information_schema.columns (nolock) where column_name='buyType' and table_name='wow_schemesetup_slabs_det')
	alter table wow_schemesetup_slabs_det drop column buyType

if exists (select top 1 column_name from information_schema.columns (nolock) where column_name='getType' and table_name='wow_schemesetup_slabs_det')
	alter table wow_schemesetup_slabs_det drop column getType
