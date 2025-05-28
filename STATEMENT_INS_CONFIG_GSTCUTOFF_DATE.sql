IF NOT EXISTS (SELECT TOP 1 * FROM CONFIG (NOLOCK) WHERE config_option='GST_CUT_OFF_DATE')
	INSERT config	( config_option, last_update, REMARKS, row_id, value )  
	SELECT 'GST_CUT_OFF_DATE' AS config_option,getdate() as last_update, 
	'' as REMARKS,'' as row_id,'2017-07-01' as value
ELSE
	UPDATE config SET value='2017-07-01'  WHERE config_option='GST_CUT_OFF_DATE'