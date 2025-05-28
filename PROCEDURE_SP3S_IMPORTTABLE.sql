CREATE PROCEDURE SP3S_IMPORTTABLE
(
 @NAME VARCHAR(1000)
)
AS
BEGIN
      
      DECLARE @SQL NVARCHAR(MAX)
		     
	 DECLARE @DEFINITION TABLE(DEFINITIONID  INT
                                        ,FIELDVALUE VARCHAR(MAX),TABLENAME VARCHAR(100))
                                               
		SET @SQL=N'SELECT NAME, ''SELECT *  INTO '' + '''+@NAME+'..'' +NAME +'' FROM ''+NAME    FROM SYS.TABLES WHERE TYPE=''U''
				AND NAME NOT LIKE ''TMP%''
				AND NAME NOT LIKE ''TEMP%''
		'
		PRINT @SQL
		INSERT INTO @DEFINITION(TABLENAME,FIELDVALUE)
        EXEC SP_EXECUTESQL @SQL
        
         IF OBJECT_ID ('TEMPDB..#TMPTABLE','U') IS NOT NULL
           DROP TABLE #TMPTABLE
        
        SELECT * INTO #TMPTABLE FROM @DEFINITION
        
        DECLARE @CCMD VARCHAR(MAX),@TABLENAME VARCHAR(2000)
        
        WHILE EXISTS(SELECT TOP 1 'U' FROM #TMPTABLE)  
        BEGIN
           
           SET @TABLENAME=''
           SET @CCMD=''
           
             SELECT TOP 1 @TABLENAME=TABLENAME ,@CCMD=FIELDVALUE FROM #TMPTABLE
             ORDER BY DEFINITIONID
             
            SET @SQL=N'
            IF NOT EXISTS (SELECT TOP 1 ''U'' FROM  '+@NAME+'.SYS.OBJECTS WHERE NAME='''+@TABLENAME+''') 
            BEGIN
               '+@CCMD+'
            END '
            PRINT @SQL
            EXEC SP_EXECUTESQL @SQL
			
			           
            DELETE FROM #TMPTABLE WHERE TABLENAME=@TABLENAME
        
        END
        
        SET @SQL=N'DELETE FROM '+@NAME+'.DBO.MONITOR_SCRIPT'
        EXEC SP_EXECUTESQL @SQL

        SET @SQL=N'DELETE FROM '+@NAME+'.DBO.EXE_TIME'
        EXEC SP_EXECUTESQL @SQL
                
        EXEC COPYPROCEDURES @NAME
        
        EXEC SP3S_CRT_CONSTRAINT @NAME
        
        


END
