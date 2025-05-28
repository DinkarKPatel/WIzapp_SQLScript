IF NOT EXISTS (SELECT TOP 1 * FROM pos_db_Seasons)
	insert into POS_DB_SEASONS (season_name,from_Dt,to_dt)
	SELECT 'Spring','1900-02-01','1900-04-30'
	union 
	SELECT 'Summer','1900-05-01','1900-07-31'
	union
	SELECT 'Autumn','1900-08-01','1900-10-31'
	union
	SELECT 'Winter','1900-11-01','1900-01-31'