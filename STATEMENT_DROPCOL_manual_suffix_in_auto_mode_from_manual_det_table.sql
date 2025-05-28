IF EXISTS (SELECT TOP 1 column_name from  INFORMATION_SCHEMA.columns where COLUMN_NAME='manual_suffix_in_auto_mode'
AND table_name='series_Setup_manual_det_upload')
	alter table series_Setup_manual_det_upload drop column manual_suffix_in_auto_mode