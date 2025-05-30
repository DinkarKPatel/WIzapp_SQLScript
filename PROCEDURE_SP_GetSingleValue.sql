CREATE PROC SP_GETSINGLEVALUE  
(        
 @CQUERYID INT,        
 @CVALUE1 VARCHAR(MAX) = '',        
 @CVALUE2 VARCHAR(MAX) = '',        
 @CVALUE3 VARCHAR(MAX) = ''        
)      
--WITH ENCRYPTION  
 AS        
BEGIN        
 DECLARE @CQUERY NVARCHAR(MAX)        
         
 ----------------------        
 IF (@CQUERYID = 101)  
BEGIN          
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_PAY WHERE PAY_NAME = ''' + @CVALUE1 + ''' AND PAY_ID <> ''' + @CVALUE2 + ''''  
END          
------------------------              
IF(@CQUERYID = 102)
BEGIN
SET @CQUERY = N'SELECT APPROVED_AMOUNT FROM EMP_LOAN_MST WHERE LOAN_ID=''' + @CVALUE1 + ''''
END
-------------------------
IF(@CQUERYID = 103)
BEGIN
SET @CQUERY = N'SELECT SUM(A.AMOUNT) FROM EMP_PAYSLIP_DET A 
				JOIN EMP_PAYSLIP_MST B (NOLOCK) ON A.PAYSLIP_ID = B.PAYSLIP_ID 
				WHERE A.LOAN_ID = ''' + @CVALUE1 + ''' AND B.CANCELLED = 0'
END
--------------------------
IF(@CQUERYID = 104)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_ATTENDANCE 
				WHERE EMP_ID  = ''' + @CVALUE1 + ''' AND MONTH(ATTENDANCE_DT) = ''' + @CVALUE2 + '''
				AND YEAR(ATTENDANCE_DT)  = ''' + @CVALUE3 + ''' AND ENTRY_MODE = 2'
END
-------------------------
IF(@CQUERYID = 105)
BEGIN
SET @CQUERY = N'SELECT COUNT (*) FROM EMP_CALENDER A WHERE YEAR(A.HOLIDAY_DATE) = ''' + @CVALUE1 + ''' 
				AND MONTH(A.HOLIDAY_DATE) = ''' + @CVALUE2 + ''' 
				AND DATEPART(WEEKDAY,A.HOLIDAY_DATE) <> 1 AND LEAVE_COUNT = 1'
END
---------------------------
IF(@CQUERYID = 106)
BEGIN
SET @CQUERY = N'SELECT EMP_ID FROM EMP_MST WHERE REF_ID = ''' + @CVALUE1 + ''''
END
---------------------------
IF(@CQUERYID = 107)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_MST WHERE DEPT_ID = ''' + @CVALUE1 + ''' AND EMP_STATUS = 0'
END
---------------------------
IF(@CQUERYID = 108)
BEGIN
SET @CQUERY = N'SELECT SUM(AMOUNT) AS PAID_AMOUNT FROM EMP_PAYSLIP_DET A
                                    JOIN EMP_PAYSLIP_MST B (NOLOCK) ON A.PAYSLIP_ID = B.PAYSLIP_ID
                                    WHERE A.LOAN_ID = ''' + @CVALUE1 + ''' AND B.CANCELLED = 0'
END
---------------------------
IF(@CQUERYID = 109)
BEGIN
SET @CQUERY = N'SELECT LOAN_AMOUNT FROM EMP_LOAN_MST WHERE LOAN_ID = ''' + @CVALUE1 + ''''
END
---------------------------
IF(@CQUERYID = 110)
BEGIN
SET @CQUERY = N'SELECT COUNT (*) FROM EMP_CALENDER A WHERE YEAR(A.HOLIDAY_DATE) = ''' + @CVALUE1 + '''
                AND MONTH(A.HOLIDAY_DATE) = ''' + @CVALUE2 + ''' 
                AND DATEPART(WEEKDAY,A.HOLIDAY_DATE) <> 1 AND LEAVE_COUNT = 1'
END
---------------------------
IF(@CQUERYID = 111)
BEGIN
SET @CQUERY = N'SELECT FINALIZED FROM EMP_PAYSLIP_MST WHERE PAYSLIP_ID = ''' + @CVALUE1 + ''''
END
---------------------------
IF(@CQUERYID = 112)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_PAYSLIP_MST 
				WHERE CANCELLED = 0 AND EMP_ID = ''' + @CVALUE1 + '''
				AND PAYSLIP_MONTH = ''' + @CVALUE2 + ''' AND PAYSLIP_YEAR = ''' + @CVALUE3 + ''''
END
---------------------------
IF(@CQUERYID = 113)
BEGIN
SET @CQUERY = N'SELECT ISNULL(SUM(AMOUNT),0) AS PAID_AMOUNT FROM EMP_PAYSLIP_DET A
                                    JOIN EMP_PAYSLIP_MST B (NOLOCK) ON A.PAYSLIP_ID = B.PAYSLIP_ID
                                    WHERE A.LOAN_ID <> ''0000000'' AND B.CANCELLED = 0'
END
---------------------------
IF(@CQUERYID = 114)
BEGIN
SET @CQUERY = N'SELECT COUNT(EMP_ID)AS EMPCOUNT FROM EMP_PAYSLIP_MST 
				WHERE EMP_ID = ''' + @CVALUE1 + ''' AND CANCELLED<>1'
END
---------------------------
IF(@CQUERYID = 115)
BEGIN
SET @CQUERY = N'SELECT TOP 1 C.DEPT_NAME FROM EMP_ATTENDANCE B 
				JOIN LOCATION C ON B.DEPT_ID = C.DEPT_ID
                WHERE EMP_ID = ''' + @CVALUE1 + '''  AND 
                MONTH(B.ATTENDANCE_DT) = ''' + @CVALUE2 + '''  
                AND YEAR(B.ATTENDANCE_DT) = ''' + @CVALUE3 + ''' 
                ORDER BY ATTENDANCE_DT DESC, TIME_OUT DESC'
END
---------------------------
IF(@CQUERYID = 116)
BEGIN
SET @CQUERY = N'SELECT BASIC_SALARY FROM EMP_MST WHERE EMP_ID = ''' + @CVALUE1 + ''''
END
---------------------------
IF(@CQUERYID = 117)
BEGIN
SET @CQUERY = N'SELECT ISNULL(SUM(AMOUNT),0) AS PAID_AMOUNT FROM EMP_PAYSLIP_DET A
                JOIN EMP_PAYSLIP_MST B (NOLOCK) ON A.PAYSLIP_ID = B.PAYSLIP_ID
                WHERE A.LOAN_ID = ''' + @CVALUE1 + ''' AND B.CANCELLED = 0 AND 
                A.PAYSLIP_ID <> ''' + @CVALUE2 + ''''
END
---------------------------
IF(@CQUERYID = 118)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_PAYSLIP_MST 
                WHERE ((PAYSLIP_MONTH > ''' + @CVALUE1 + ''' AND PAYSLIP_YEAR = ''' + @CVALUE2 + ''' ) 
                OR (PAYSLIP_YEAR > ''' + @CVALUE2 + ''' )) AND EMP_ID = ''' + @CVALUE3 + ''' AND CANCELLED = 0'
END
---------------------------
IF(@CQUERYID = 119)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_PAY WHERE PAY_ORDER = ''' + @CVALUE1 + ''' 
				AND PAY_ID <> ''' + @CVALUE2 + ''''
END
---------------------------
IF(@CQUERYID = 120)
BEGIN
SET @CQUERY = N'SELECT MAX(PAY_ORDER) AS PAY_ORDER FROM EMP_PAY'
END
---------------------------
IF(@CQUERYID = 121)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_DEPARTMENT WHERE DEPARTMENT_NAME = ''' + @CVALUE1 + ''' 
				AND DEPARTMENT_ID <> ''' + @CVALUE2 + ''''
END
---------------------------
IF(@CQUERYID = 122)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_DESIG WHERE DESIG_NAME = ''' + @CVALUE1 + '''
				AND DESIG_ID <> ''' + @CVALUE2 + ''''
END
---------------------------
IF(@CQUERYID = 123)
BEGIN
SET @CQUERY = N'SELECT EMP_ID FROM EMP_MST WHERE REF_ID = ''' + @CVALUE1 + ''''
END
---------------------------
IF(@CQUERYID = 124)
BEGIN
SET @CQUERY = N'SELECT MAX(REF_ID) AS MAX_REF_ID FROM EMP_MST'
END
---------------------------
IF(@CQUERYID = 125)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_LEAVE_MASTER WHERE LEAVE_NAME = ''' + @CVALUE1 + ''' 
				AND LEAVE_CODE <> ''' + @CVALUE2 + ''''
END
---------------------------
IF(@CQUERYID = 126)
BEGIN
SET @CQUERY = N'SELECT A.PAYSLIP_ID FROM EMP_PAYSLIP_MST A WHERE A.EMP_ID = ''' + @CVALUE1 + ''' 
				AND A.PAYSLIP_MONTH = ''' + @CVALUE2 + ''' AND A.PAYSLIP_YEAR = ''' + @CVALUE3 + ''' 
				AND A.CANCELLED <> 1'
END
---------------------------
IF(@CQUERYID = 127)
BEGIN
SET @CQUERY = N'SELECT A.CANCELLED FROM EMP_PAYSLIP_MST A WHERE A.EMP_ID = ''' + @CVALUE1 + ''' 
				AND A.PAYSLIP_MONTH = ''' + @CVALUE2 + ''' AND A.PAYSLIP_YEAR = ''' + @CVALUE3 + ''' 
				AND A.CANCELLED = 2'
END
---------------------------
IF(@CQUERYID = 128)
BEGIN
SET @CQUERY = N'SELECT A.PAYSLIP_ID FROM EMP_PAYSLIP_MST A WHERE A.EMP_ID = ''' + @CVALUE1 + ''' 
				AND A.PAYSLIP_MONTH = ''' + @CVALUE2 + ''' AND A.PAYSLIP_YEAR = ''' + @CVALUE3 + ''' 
				AND A.CANCELLED  = 0'
END
--------------------------- 
IF(@CQUERYID = 129)
BEGIN
SET @CQUERY = N'SELECT A.PAYSLIP_ID FROM EMP_PAYSLIP_MST A WHERE A.EMP_ID = ''' + @CVALUE1 + ''' 
				AND A.PAYSLIP_MONTH = ''' + @CVALUE2 + ''' AND A.PAYSLIP_YEAR = ''' + @CVALUE3 + ''' 
				AND A.CANCELLED  = 0'
END
---------------------------
--IF(@CQUERYID = 104)
--BEGIN
--SET @CQUERY = N''
--END
--------------------------- 
 
DECLARE @DSTARTTIME DATETIME,@DENDTIME DATETIME

SET @DSTARTTIME=GETDATE()
 IF @CQUERY <> ''        
  BEGIN        
  PRINT @CQUERY        
  EXEC SP_EXECUTESQL @CQUERY        
  END        
 ELSE  
 BEGIN  
 PRINT 'QUERY FAILED'  
 END  

  INSERT WIZPAY_LOG	( SP_NAME, START_TIME, END_TIME )  
  SELECT 	 'SP_GETSINGLEVALUE:'+STR(@CQUERYID) AS SP_NAME,@DSTARTTIME AS START_TIME,GETDATE() AS  END_TIME 

END
