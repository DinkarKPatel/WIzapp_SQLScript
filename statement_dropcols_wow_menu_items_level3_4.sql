if exists(select top 1 column_name from INFORMATION_SCHEMA.columns (nolock) where TABLE_NAME='wow_menu_items' and COLUMN_NAME='level3_name')
	alter table wow_menu_items drop column level3_name

if exists(select top 1 column_name from INFORMATION_SCHEMA.columns (nolock) where TABLE_NAME='wow_menu_items' and COLUMN_NAME='level4_name')
	alter table wow_menu_items drop column level4_name