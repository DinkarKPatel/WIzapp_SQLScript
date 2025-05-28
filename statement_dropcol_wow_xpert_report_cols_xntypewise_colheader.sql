IF EXISTS (SELECT TOP 1 column_name from  INFORMATION_SCHEMA.columns where column_name='col_header'
and table_name='wow_xpert_report_cols_xntypewise')
alter table wow_xpert_report_cols_xntypewise drop column col_header