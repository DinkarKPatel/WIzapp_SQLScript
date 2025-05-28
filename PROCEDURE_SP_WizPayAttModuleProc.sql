CREATE PROC SP_WIZPAYATTMODULEPROC  
(        
 @CQUERYID INT,        
 @CVALUE1 VARCHAR(MAX) = '',        
 @CVALUE2 VARCHAR(MAX) = '',        
 @CVALUE3 VARCHAR(MAX) = '',
 @CVALUE4 VARCHAR(MAX) = ''
)      
--WITH ENCRYPTION  
 AS        
BEGIN        
DECLARE @CQUERY NVARCHAR(MAX)        
         
----------------------        
IF (@CQUERYID = 101)        
BEGIN        
SET @CQUERY = 'SELECT * FROM EMP_SHIFTS WHERE SHIFT_ID = ''' + @CVALUE1 + ''''
END        
-----------------------------
IF (@CQUERYID = 102)
BEGIN        
SET @CQUERY = 'SELECT DEPT_ID FROM EMP_MST WHERE EMP_ID = ''' + @CVALUE1 + ''''
END        
-----------------------------
IF (@CQUERYID = 103)
BEGIN        
SET @CQUERY = 'SELECT B.REF_ID AS [USER ID],
                                CONVERT(VARCHAR(10),A.IST_TIME,105) AS DATE,
                                CASE 
	                                WHEN CONVERT(VARCHAR(10),A.IST_TIME,108) = ''00:00:00'' THEN CONVERT(VARCHAR(10),A.IST_TIME,108) 
	                                ELSE CONVERT(VARCHAR(10),A.IST_TIME,108) 
                                END AS TIME, 
                                CASE 
	                                WHEN A.TIME_STATUS = 1 THEN ''IN''
	                                WHEN A.TIME_STATUS = 2 THEN ''OUT''
	                                END AS TIME_STATUS,
                                CASE 
	                                WHEN A.LOG_ABSENT_STATUS = 1 THEN ''WEEKLY OFF''
	                                WHEN A.LOG_ABSENT_STATUS = 2 THEN ''ABSENT''
	                                WHEN A.LOG_ABSENT_STATUS = 3 THEN ''LEAVE''
                                    WHEN A.LOG_ABSENT_STATUS = 4 THEN ''BIRTHDAY OFF''
                                    WHEN A.LOG_ABSENT_STATUS = 0 THEN '''' 
                                    END AS ABSENT_STATUS
                                FROM EMP_WPAYATT A
                                JOIN EMP_MST B ON A.EMP_ID=B.EMP_ID
                            WHERE MONTH(IST_TIME) = ''' + @CVALUE1 + ''' AND YEAR(IST_TIME) = ''' + @CVALUE2 + ''' 
                            ORDER BY B.REF_ID,A.IST_TIME'
END        
-----------------------------
IF (@CQUERYID = 104)
BEGIN        
SET @CQUERY = 'SELECT * FROM EMP_WPAYATT WHERE 1=2'
END        
-----------------------------
IF (@CQUERYID = 105)
BEGIN        
--SET @CQUERY = 'SELECT A.SHIFT_ID,A.SHIFT_NAME,A.SHIFT_TIME_IN, A.SHIFT_TIME_OUT, B.DEPT_ID FROM EMP_SHIFTS A           
--               LEFT OUTER JOIN EMP_SHIFT_LOC B ON A.SHIFT_ID = B.SHIFT_ID           
--               WHERE A.SHIFT_ID <> ''0000000'' AND B.DEPT_ID = ' + @CVALUE1 + '' 

SET @CQUERY = N'IF  EXISTS( SELECT TOP 1 * FROM EMP_SHIFT_LOC)

					SELECT A.SHIFT_ID,A.SHIFT_NAME,A.SHIFT_TIME_IN, A.SHIFT_TIME_OUT, 
					B.DEPT_ID
					FROM EMP_SHIFTS A               
					JOIN EMP_SHIFT_LOC B ON A.SHIFT_ID = B.SHIFT_ID               
					WHERE A.SHIFT_ID <> ''0000000'' AND B.DEPT_ID = '''+@CVALUE1+''' 
		        ELSE
					SELECT A.SHIFT_ID,A.SHIFT_NAME,A.SHIFT_TIME_IN, A.SHIFT_TIME_OUT, 
					ISNULL(B.DEPT_ID,'''+@CVALUE1+''') AS  DEPT_ID
					FROM EMP_SHIFTS A               
					LEFT OUTER JOIN EMP_SHIFT_LOC B ON A.SHIFT_ID = B.SHIFT_ID               
					WHERE A.SHIFT_ID <> ''0000000'' AND ISNULL(B.DEPT_ID,'''+@CVALUE1+''') = '''+@CVALUE1+''' '   

   
END        
-----------------------------
IF (@CQUERYID = 106)
BEGIN        
SET @CQUERY = 'SELECT 1 AS CAME, A.TIME_STATUS,A.EMP_ID,A.IST_TIME,A.LOG_ABSENT_STATUS,
                                B.REF_ID + '' - '' + B.EMP_FNAME + '' '' + B.EMP_LNAME AS EMPNAME,
                                C.SHIFT_NAME, 
                                CASE 
                                    WHEN A.TIME_STATUS = 1 THEN ''IN'' 
                                    WHEN A.TIME_STATUS = 2 THEN ''OUT'' 
                                ELSE 
                                    CASE 
                                        WHEN A.LOG_ABSENT_STATUS=1 THEN ''WEEKLY OFF'' 
                                        WHEN A.LOG_ABSENT_STATUS=2 THEN ''ABSENT'' 
                                        WHEN A.LOG_ABSENT_STATUS=3 THEN ''LEAVE'' 
                                        WHEN A.LOG_ABSENT_STATUS=4 THEN ''BIRTHDAY OFF''
                                    END 
                                END AS ATTSTATUS,
                                CASE 
                                    WHEN DATEPART(HOUR,A.IST_TIME)=0 THEN '''' 
                                    ELSE CONVERT(VARCHAR(5),A.IST_TIME,114) 
                                END AS ATTTIME FROM EMP_WPAYATT A
                                JOIN EMP_MST B ON A.EMP_ID=B.EMP_ID
                                JOIN EMP_SHIFTS C ON A.SHIFT_ID=C.SHIFT_ID
                                WHERE CONVERT(VARCHAR(10),A.IST_TIME,105)=''' + @CVALUE1 + '''
                                ORDER BY A.LOG_ABSENT_STATUS,A.IST_TIME DESC'
END        
-----------------------------
IF (@CQUERYID = 107)
BEGIN        
SET @CQUERY = 'SELECT A.EMP_ID, A.REF_ID, A.EMP_FNAME + ''  '' + A.EMP_LNAME AS EMP_NAME,
                                B.DEPARTMENT_NAME, C.DESIG_NAME, D.SHIFT_ID, D.SHIFT_NAME,
                                D.SHIFT_TIME_IN, D.SHIFT_TIME_OUT, D.HALFDAY_CUTOFF FROM EMP_MST A 
                                INNER JOIN EMP_DEPARTMENT B ON A.DEPARTMENT_ID=B.DEPARTMENT_ID
                                INNER JOIN EMP_DESIG C ON A.DESIG_ID=C.DESIG_ID 
                                JOIN EMP_SHIFTS D ON A.SHIFT_ID=D.SHIFT_ID
                                WHERE A.EMP_STATUS=0 ' + @CVALUE1 + ' ORDER BY A.REF_ID'
END        
-----------------------------
IF (@CQUERYID = 108)
BEGIN        
SET @CQUERY = 'SELECT A.EMP_ID, A.REF_ID, A.REF_ID + '' - '' + A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMPNAME
                                FROM EMP_MST A 
                                WHERE EMP_STATUS = 0 AND DEPT_ID = ''' + @CVALUE1 + ''' 
                                AND EMP_ID NOT IN 
                                (
	                                SELECT DISTINCT EMP_ID FROM EMP_WPAYATT 
	                                WHERE DAY(IST_TIME) = ''' + @CVALUE2 + ''' 
                                    AND MONTH(IST_TIME) = ''' + @CVALUE3 + ''' 
                                    AND YEAR(IST_TIME) = ''' + @CVALUE4 + '''
                                )'
END        
-----------------------------
IF (@CQUERYID = 109)
BEGIN        
SET @CQUERY = 'SELECT TOP 1 A.*,B.SHIFT_NAME FROM EMP_WPAYATT A
                            JOIN EMP_SHIFTS B ON A.SHIFT_ID=B.SHIFT_ID  
                            WHERE EMP_ID = ''' + @CVALUE1 + ''' AND DAY(IST_TIME) = ''' + @CVALUE2 + '''
                            AND MONTH(IST_TIME) = ''' + @CVALUE3 + '''
                            AND YEAR(IST_TIME) = ''' + @CVALUE4 + '''
                            ORDER BY IST_TIME DESC'
END        
-----------------------------
IF (@CQUERYID = 110)
BEGIN        
SET @CQUERY = 'SELECT COUNT(*) ABLOG FROM EMP_WPAYATT WHERE LOG_ABSENT_STATUS <> 0 AND 
                            EMP_ID = ''' + @CVALUE1 + '''
                            AND DAY(IST_TIME)=''' + @CVALUE2 + '''
                            AND MONTH(IST_TIME)=''' + @CVALUE3 + '''
                            AND YEAR(IST_TIME)=''' + @CVALUE4 + ''''
END        
-----------------------------
IF (@CQUERYID = 111)
BEGIN        
SET @CQUERY = 'SELECT TOP 1 * FROM EMP_WPAYATT WHERE 
                            EMP_ID = ''' + @CVALUE1 + '''
                            AND DAY(IST_TIME)=''' + @CVALUE2 + '''
                            AND MONTH(IST_TIME)=''' + @CVALUE3 + '''
                            AND YEAR(IST_TIME)=''' + @CVALUE4 + '''
                            ORDER BY IST_TIME DESC'
END        
-----------------------------
IF (@CQUERYID = 112)
BEGIN        
SET @CQUERY = 'SELECT COUNT(*) FROM EMP_WPAYATT 
               WHERE EMP_ID = ''' + @CVALUE1 + ''' 
               AND TIME_STATUS = 1 AND DAY(IST_TIME) = ''' + @CVALUE2 + '''
               AND MONTH(IST_TIME) = ''' + @CVALUE3 + '''
               AND YEAR(IST_TIME) = ''' + @CVALUE4 + ''''
END        
-----------------------------
--IF (@CQUERYID = 101)
--BEGIN        
--SET @CQUERY = ''
--END        
-----------------------------


-----------------------------        
 IF @CQUERY <> ''        
  BEGIN        
  PRINT @CQUERY        
  EXEC SP_EXECUTESQL @CQUERY        
  END        
 ELSE  
 BEGIN  
 PRINT 'QUERY FAILED'  
 END  
END
