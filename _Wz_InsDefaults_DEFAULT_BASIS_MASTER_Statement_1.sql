IF NOT EXISTS (SELECT TOP 1 'U' FROM  DEFAULT_BASIS_MASTER)
BEGIN
  INSERT DEFAULT_BASIS_MASTER	(  DEFAULT_BASIS_NAME, DEFAULT_BASIS_VALUE ) 
  SELECT 	   DEFAULT_BASIS_NAME='RATE/MTR', DEFAULT_BASIS_VALUE=1 UNION ALL 
  SELECT 	   DEFAULT_BASIS_NAME='RATE/PCS', DEFAULT_BASIS_VALUE=2 UNION ALL
  SELECT 	 DEFAULT_BASIS_NAME='RATE/DAYS', DEFAULT_BASIS_VALUE=3 UNION ALL
  SELECT 	   DEFAULT_BASIS_NAME='RATE/HOURS', DEFAULT_BASIS_VALUE=4
END
