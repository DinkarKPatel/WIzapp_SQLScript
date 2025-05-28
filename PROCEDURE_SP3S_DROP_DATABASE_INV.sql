CREATE PROCEDURE SP3S_DROP_DATABASE_INV
AS
BEGIN
       
            IF OBJECT_ID('TEMPDB..#TMP','U') IS NOT NULL
            DROP TABLE #TMP
            
            IF OBJECT_ID('TEMPDB..#TMP1','U') IS NOT NULL
            DROP TABLE #TMP1
            
            SELECT NAME INTO #TMP FROM SYS.DATABASES WHERE NAME LIKE '%INV_MST%' OR NAME LIKE '%ART_MST%' OR NAME LIKE '%CUST_MST%'
            SELECT NAME INTO #TMP1 FROM SYS.TABLES WHERE NAME LIKE '%_UPLOAD' OR LEFT(NAME,7)='DOCIRT_'
            
            
            IF  EXISTS(SELECT TOP 1 'U' FROM #TMP1 WHERE RIGHT(NAME ,7)<>'_UPLOAD')
            RETURN
            
            DECLARE @NCNT INT,@DBNAME VARCHAR(MAX),@BLOOP BIT,@CCMD NVARCHAR(MAX)
            SET @NCNT=1
            SET @BLOOP=0
            SET @DBNAME=''
            
            WHILE @BLOOP=0
            BEGIN
                 SET @DBNAME=''
                  SET @NCNT=@NCNT+1
                   SELECT @DBNAME=NAME FROM #TMP
                   IF ISNULL(@DBNAME,'')=''
                   BREAK

                   SET @CCMD=N'ALTER DATABASE ['+@DBNAME+'] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
                   DROP DATABASE '+@DBNAME+''
                   PRINT @CCMD
                   EXEC SP_EXECUTESQL @CCMD
                   
                   SET @CCMD='DELETE FROM #TMP WHERE NAME ='''+@DBNAME+''''
                     PRINT @CCMD
                   EXEC SP_EXECUTESQL @CCMD

            END
            
            DECLARE @NCNT1 INT,@TABLENAME VARCHAR(MAX),@BLOOP1 BIT,@CCMD1 NVARCHAR(MAX)
            SET @NCNT1=1
            SET @BLOOP1=0
            SET @TABLENAME=''
            
            WHILE @BLOOP1=0
            BEGIN
                 SET @TABLENAME=''
                  SET @NCNT1=@NCNT1+1
                   SELECT @TABLENAME=NAME FROM #TMP1
                   IF ISNULL(@TABLENAME,'')=''
                   BREAK
                    
                   SET @CCMD='TRUNCATE TABLE '+@TABLENAME+''
                   PRINT @CCMD
                   EXEC SP_EXECUTESQL @CCMD
                   
                   SET @CCMD='DELETE FROM #TMP1 WHERE NAME ='''+@TABLENAME+''''
                     PRINT @CCMD
                   EXEC SP_EXECUTESQL @CCMD
            END
		DECLARE @CMD VARCHAR(MAX)	
		SELECT TOP 100 @CMD=COALESCE(@CMD,'')+'DROP TABLE ['+NAME+'];'+CHAR(13) FROM SYS.TABLES WHERE NAME LIKE '%01106_OLD%' OR NAME LIKE '%01106_NEW%'
		EXEC(@CMD)
END
