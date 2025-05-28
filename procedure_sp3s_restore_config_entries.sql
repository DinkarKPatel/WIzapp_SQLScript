create procedure sp3s_restore_config_entries
as
begin
	UPDATE config SET value='2017-07-01' WHERE config_option='GST_CUT_OFF_DATE'
end