IF EXISTS(SELECT TOP 1 'U' FROM gst_accounts_config_mst WHERE SNO IS NULL)
UPDATE gst_accounts_config_mst SET SNO=0 WHERE SNO IS NULL
