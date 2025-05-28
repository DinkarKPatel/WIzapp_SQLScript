UPDATE location set  DEFAULT_CASH_MEMO_PRINT_NAME=b.value FROM  config_loc b 
WHERE b.dept_id=location.dept_id AND b.config_option='DEFAULT_CASH_MEMO_PRINT_NAME'

UPDATE location set  DO_NOT_ENFORCE_LAST_RUN_DT=b.value FROM  config_loc b 
WHERE b.dept_id=location.dept_id AND b.config_option='DO_NOT_ENFORCE_LAST_RUN_DT'

UPDATE location set  LEAD_DAYS_FOR_ALTERATION=b.value FROM  config_loc b 
WHERE b.dept_id=location.dept_id AND b.config_option='LEAD_DAYS_FOR_ALTERATION'

IF OBJECT_ID('config_loc_bkp_20220215','u') IS NULL
	SELECT * INTO config_loc_bkp_20220215 FROM  config_loc

DELETE FROM  config_loc WHERE config_option IN ('DEFAULT_CASH_MEMO_PRINT_NAME','DO_NOT_ENFORCE_LAST_RUN_DT',
'LEAD_DAYS_FOR_ALTERATION')
