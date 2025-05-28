IF NOT EXISTS (SELECT TOP 1 log_dt from opt_pmtbuild_log)
	INSERT opt_pmtbuild_log	(LOG_DT, build_endtime, build_starttime, 
	build_upto,  dbname,  fromdt,starttime,todt)
	SELECT 	top 1  log_dt,endtime,starttime, build_upto, DB_NAME() dbname,  fromdt,starttime,todt
	FROM LOGPMT_BUILD ORDER BY log_dt desc



