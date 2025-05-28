if exists (select top 1 * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where constraint_name='FK_ARC01106_BIN_ID_BIN_BIN_ID')
	alter table arc01106 drop constraint FK_ARC01106_BIN_ID_BIN_BIN_ID
