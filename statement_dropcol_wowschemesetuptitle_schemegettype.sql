if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (nolock) where table_name='wow_schemesetup_title_det' and column_name='schemegettype')
	alter table wow_schemesetup_title_det drop column schemegettype
