DECLARE @CINDEXNAME VARCHAR(100),@DTSQL NVARCHAR(MAX)
SELECT @CINDEXNAME=I.NAME 
FROM sys.indexes AS i  
INNER JOIN sys.index_columns AS ic   
ON i.object_id = ic.object_id AND i.index_id = ic.index_id  
WHERE i.object_id = OBJECT_ID('PMT01106')  AND COL_NAME(ic.object_id,ic.column_id) ='rep_id'

IF ISNULL(@CINDEXNAME,'')<>''
BEGIN

	SET @DTSQL=N' DROP INDEX '+RTRIM(LTRIM(@CINDEXNAME))+' ON PMT01106;
	 ALTER TABLE PMT01106 ALTER COLUMN REP_ID CHAR(10);
	 CREATE INDEX  '+RTRIM(LTRIM(@CINDEXNAME))+' ON PMT01106(REP_ID);
	 '
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

END
