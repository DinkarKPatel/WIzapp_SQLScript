IF EXISTS(select column_name from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='buyer_order_det' and COLUMN_NAME='season_id')
BEGIN
	ALTER TABLE buyer_order_det DROP COLUMN season_id
END

IF EXISTS(select column_name from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='wslord_buyer_order_det_upload' and COLUMN_NAME='season_id')
BEGIN
	ALTER TABLE wslord_buyer_order_det_upload DROP COLUMN season_id
END

