


IF OBJECT_ID ('TEMPDB..#TMPTRG','U') IS NOT NULL
   DROP TABLE #TMPTRG

SELECT SO.NAME
INTO #TMPTRG
FROM SYSOBJECTS SO, SYSCOMMENTS SC
WHERE TYPE = 'TR'
AND SO.ID = SC.ID
AND TEXT LIKE '%UPLOAD_MIRRORXN%'



DECLARE  @CTRGNAME VARCHAR(100),@DTSQL NVARCHAR(MAX)

WHILE EXISTS (SELECT TOP 1'U' FROM #TMPTRG)
BEGIN
    

	SELECT TOP 1 @CTRGNAME=NAME FROM #TMPTRG

	SET @DTSQL=N' DROP TRIGGER '+@CTRGNAME
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	DELETE FROM #TMPTRG WHERE NAME =@CTRGNAME
   

END

