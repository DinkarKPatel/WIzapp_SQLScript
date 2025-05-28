IF EXISTS (SELECT TOP 1 COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='hsn_code' AND TABLE_NAME='mstsku_sectiond_upload')
	alter table mstsku_sectiond_upload drop column hsn_code
