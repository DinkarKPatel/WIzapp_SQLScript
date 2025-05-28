if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (nolock) where table_name='wow_SchemeSetup_Title_Det'
			and column_name='barcodewise_flat_scheme')
	alter table wow_SchemeSetup_Title_Det drop column barcodewise_flat_scheme