
INSERT config_locattr	( column_name, table_caption, table_name ) 
select a.column_name,a.table_caption,a.table_name from 
(
SELECT 	'attr1_key_name'   as column_name, '' as table_caption,
'Locattr1_mst'  as table_name 
UNION
SELECT 	'attr2_key_name'   as column_name, '' as table_caption,
'Locattr2_mst'  as table_name 
UNION
SELECT 	'attr3_key_name'   as column_name, '' as table_caption,
'Locattr3_mst'  as table_name 
UNION
SELECT 	'attr4_key_name'   as column_name, '' as table_caption,
'Locattr4_mst'  as table_name 
UNION
SELECT 	'attr5_key_name'   as column_name, '' as table_caption,
'Locattr5_mst'  as table_name 
UNION
SELECT 	'attr6_key_name'   as column_name, '' as table_caption,
'Locattr6_mst'  as table_name 
UNION
SELECT 	'attr7_key_name'   as column_name, '' as table_caption,
'Locattr7_mst'  as table_name 
UNION
SELECT 	'attr8_key_name'   as column_name, '' as table_caption,
'Locattr8_mst'  as table_name 
UNION
SELECT 	'attr9_key_name'   as column_name, '' as table_caption,
'Locattr9_mst'  as table_name 
UNION
SELECT 	'attr10_key_name'   as column_name, '' as table_caption,
'Locattr10_mst'  as table_name 
union
SELECT 	'attr11_key_name'   as column_name, '' as table_caption,
'Locattr11_mst'  as table_name 
UNION
SELECT 	'attr12_key_name'   as column_name, '' as table_caption,
'Locattr12_mst'  as table_name 
UNION
SELECT 	'attr13_key_name'   as column_name, '' as table_caption,
'Locattr13_mst'  as table_name 
UNION
SELECT 	'attr14_key_name'   as column_name, '' as table_caption,
'Locattr14_mst'  as table_name 
UNION
SELECT 	'attr15_key_name'   as column_name, '' as table_caption,
'Locattr15_mst'  as table_name 
UNION
SELECT 	'locattr16_key_name'   as column_name, '' as table_caption,
'Locattr16_mst'  as table_name 
UNION
SELECT 	'attr17_key_name'   as column_name, '' as table_caption,
'Locattr17_mst'  as table_name 
UNION
SELECT 	'attr18_key_name'   as column_name, '' as table_caption,
'Locattr18_mst'  as table_name 
UNION
SELECT 	'attr19_key_name'   as column_name, '' as table_caption,
'Locattr19_mst'  as table_name 
UNION
SELECT 	'attr20_key_name'   as column_name, '' as table_caption,
'Locattr20_mst'  as table_name 
union all
SELECT 	'locattr21_key_name'   as column_name, '' as table_caption,
'Locattr21_mst'  as table_name 
union all
SELECT 	'attr22_key_name'   as column_name, '' as table_caption,
'Locattr22_mst'  as table_name 
union all
SELECT 	'attr23_key_name'   as column_name, '' as table_caption,
'Locattr23_mst'  as table_name 
union all
SELECT 	'attr24_key_name'   as column_name, '' as table_caption,
'Locattr24_mst'  as table_name 
union all
SELECT 	'attr25_key_name'   as column_name, '' as table_caption,
'Locattr25_mst'  as table_name 
) a
left join config_locattr b on a.column_name =b.column_name 
where b.column_name is null
