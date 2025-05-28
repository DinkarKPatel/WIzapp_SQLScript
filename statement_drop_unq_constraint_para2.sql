IF EXISTS (SELECT TOP 1 table_name FROM  INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE (NOLOCK) WHERE CONSTRAINT_NAME='unq_para2_name')
	alter table para2 drop constraint unq_para2_name

