create PROC SP_WIZPAYMODULEPROC  
(        
 @CQUERYID INT,        
 @CVALUE1 VARCHAR(MAX) = '',        
 @CVALUE2 VARCHAR(MAX) = '',        
 @CVALUE3 VARCHAR(MAX) = '' ,
 @CVALUE4 VARCHAR(MAX) = '' ,
 @CVALUE5 VARCHAR(MAX) = ''      
)      
--WITH ENCRYPTION  
 AS        
BEGIN        
 DECLARE @CQUERY NVARCHAR(MAX)        
 
 ----------------------        
 IF (@CQUERYID = 101)        
 BEGIN        
 -- ATTENDANCE (LOOK UP)        
  SET @CQUERY = 'SELECT DISTINCT YEAR(A.ATTENDANCE_DT) AS YEAR_NO, 0 AS FIN_MONTH_NO,           
  MONTH(A.ATTENDANCE_DT) AS MONTH_NO, DATENAME(MONTH, A.ATTENDANCE_DT) AS MONTH_NAME,  
  DATENAME(MONTH, A.ATTENDANCE_DT) + '' '' + CONVERT(VARCHAR,YEAR(A.ATTENDANCE_DT)) AS MONTH_VALUE  
  FROM EMP_ATTENDANCE A WHERE A.ATTENDANCE_DT BETWEEN '''+@CVALUE1+''' AND '''+@CVALUE2+''' ORDER BY YEAR(A.ATTENDANCE_DT),MONTH(A.ATTENDANCE_DT)'        
  
 END        
 --------------------        
 IF (@CQUERYID = 102)        
 BEGIN        
 -- ATTENDANCE (EMPLOYEE LIST)        
  SET @CQUERY = 'SELECT D.DEPT_NAME, C.DEPARTMENT_NAME,C.DEPARTMENT_ID, A.EMP_ID,       
 RTRIM(A.REF_ID + '' - '' + A.EMP_FNAME + '' '' + A.EMP_LNAME) AS EMP_NAME,             
    B.SHIFT_ID, B.SHIFT_NAME  
    FROM EMP_MST A             
    JOIN EMP_SHIFTS B   (NOLOCK) ON A.SHIFT_ID = B.SHIFT_ID            
    JOIN EMP_DEPARTMENT C  (NOLOCK) ON A.DEPARTMENT_ID = C.DEPARTMENT_ID            
    JOIN LOCATION D (NOLOCK) ON A.DEPT_ID = D.DEPT_ID      
    WHERE A.EMP_STATUS = 0 AND A.EMP_FNAME <> ''''       
    ORDER BY D.DEPT_ID + ''-'' + D.DEPT_NAME, C.DEPARTMENT_NAME, A.REF_ID'           
 END        
 --------------------        
 IF (@CQUERYID = 103)        
 BEGIN        
   -- ATTENDANCE (ATTENDANCE LIST)        
	DECLARE @CWHERE1 VARCHAR(500)
	SET @CWHERE1 = (CASE WHEN @CVALUE3='' THEN 'C.REF_ID' ELSE @CVALUE3 END)     
	SET @CQUERY = 'SELECT  A.ATTENDANCE_DT ,A.EMP_ID,A.time_in,A.time_out,A.row_id,A.entry_mode
		,A.shift_id,A.shift_time_in,A.shift_time_out,A.halfday_cutoff,'''' as empimage
		,A.dept_id,'''' as empimage_out,A.modified,A.log_absent_status,A.remarks_in
		,A.last_update,A.att_remarks,A.remarks_out,A.sync, B.SHIFT_NAME,        
	   '''' AS HOLIDAY_NAME,
	   DATENAME (WEEKDAY,A.ATTENDANCE_DT) AS WEEK_NAME , (C.EMP_FNAME + '' '' + C.EMP_LNAME) AS EMP_NAME  
	
	 --DBO.FN_GETEMP_ATDSTATUS(A.EMP_ID,ATTENDANCE_DT,A.LOG_ABSENT_STATUS,B.SHIFT_TIME_IN,
  --                       B.SHIFT_TIME_OUT,A.TIME_IN,A.TIME_OUT,B.EARLY_CUTOFF,
  --                       B.LATE_CUTOFF,B.HALFDAY_CUTOFF,
  --                       C.WEEKLY_OFF1) AS HOLIDAY_NAME,               
	FROM EMP_ATTENDANCE A            
	JOIN EMP_SHIFTS B    (NOLOCK) ON A.SHIFT_ID = B.SHIFT_ID            
	JOIN EMP_MST C     (NOLOCK) ON A.EMP_ID = C.EMP_ID  
	WHERE A.ATTENDANCE_DT BETWEEN ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + '''             
	AND C.EMP_STATUS = 0 AND C.REF_ID = '+ @CWHERE1 +' 
	AND ('''+@CVALUE4+'''='''' OR C.EMP_ID='''+@CVALUE4+''')
	ORDER BY A.EMP_ID, A.ATTENDANCE_DT, A.TIME_IN, A.TIME_OUT'       
	


	 --DBO.FN_GETEMP_ATDSTATUS(A.EMP_ID,ATTENDANCE_DT,A.LOG_ABSENT_STATUS,B.SHIFT_TIME_IN,
  --                       B.SHIFT_TIME_OUT,A.TIME_IN,A.TIME_OUT,B.EARLY_CUTOFF,
  --                       B.LATE_CUTOFF,B.HALFDAY_CUTOFF,
  --                       C.WEEKLY_OFF1) AS HOLIDAY_NAME,   
 END        
 --------------------        
 IF (@CQUERYID = 104)        
 BEGIN        
 -- ATTENDANCE (CALENDER LIST)        
  SET @CQUERY = 'SELECT * FROM EMP_CALENDER WHERE HOLIDAY_NAME <> '''' AND         
  HOLIDAY_DATE BETWEEN ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + ''''        
 END        
 --------------------        
 IF (@CQUERYID = 105)        
 BEGIN        
 -- ATTENDANCE (SHIFT LIST)        
  SET @CQUERY = 'SELECT A.SHIFT_ID, A.SHIFT_NAME, A.SHIFT_TIME_IN, A.SHIFT_TIME_OUT, A.HALFDAY_CUTOFF         
   FROM EMP_SHIFTS A WHERE A.SHIFT_NAME <> '''' ORDER BY A.SHIFT_NAME'        
 END        
 --------------------        
IF (@CQUERYID = 107)        
BEGIN        
-- ATTWIZARD (ATTENDANCE LIST)        
SET @CQUERY = 'SELECT * FROM EMP_ATTENDANCE  WHERE 1=2 ORDER BY EMP_ID, ATTENDANCE_DT'        
END        
--------------------        
 IF (@CQUERYID = 108)        
 BEGIN        
 -- ATTWIZARD (EMPLOYEE SHIFT INFORMATION)        
  SET @CQUERY = 'SELECT A.EMP_ID, B.SHIFT_ID, B.SHIFT_TIME_IN, B.SHIFT_TIME_OUT, B.HALFDAY_CUTOFF, A.DEPT_ID         
           FROM EMP_MST A        
           JOIN EMP_SHIFTS B (NOLOCK) ON A.SHIFT_ID = B.SHIFT_ID        
           WHERE A.EMP_STATUS <> 1'        
 END        
 --------------------        
 IF (@CQUERYID = 109)        
 BEGIN        
 -- EMPLOYEE LEAVE (LOOK UP)        
  SET @CQUERY = 'SELECT APPLICATION_ID ,APPLICATION_NO AS MST_MEMO_NO,EMP_ID AS MST_EMP_ID         
  FROM EMP_LEAVE_DETAILS         
  WHERE APPLICATION_DT BETWEEN ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + ''' ORDER BY APPLICATION_ID'        
 END        
 --------------------        
 IF (@CQUERYID = 110)        
 BEGIN        
 -- EMPLOYEE LEAVE (GRID LIST)        
  SET @CQUERY = 'SELECT A.LEAVE_CODE,A.LEAVE_NAME,ISNULL(A.NO_OF_LEAVES,0) AS TOTAL_LEAVES,        
   ISNULL(D.TAKEN_LEAVES,0)AS TAKEN_LEAVES, ISNULL(D.APPROVED_LEAVES,0) AS APPROVED_LEAVES,        
   0.00 AS BALANCE_LEAVES FROM EMP_LEAVE_MASTER A        
   LEFT OUTER JOIN         
   (        
    SELECT SUM(NO_OF_LEAVES)AS TAKEN_LEAVES,SUM(LEAVES_APPROVED)AS APPROVED_LEAVES,LEAVE_CODE        
    FROM EMP_LEAVE_DETAILS (NOLOCK)          
    WHERE EMP_ID = ''' + @CVALUE1 + ''' AND APPLICATION_DT BETWEEN ''' + @CVALUE2 + '''         
    AND ''' + @CVALUE3 + ''' GROUP BY LEAVE_CODE        
   ) AS D ON A.LEAVE_CODE = D.LEAVE_CODE WHERE A.LEAVE_CODE <> ''0000000'' ORDER BY A.LEAVE_NAME'        
 END        
 --------------------        
 IF (@CQUERYID = 111)        
 BEGIN        
 -- EMPLOYEE LEAVE (LEAVE LIST)        
  SET @CQUERY = 'SELECT A.*,B.ENCASHMENT,B.LEAVE_NAME,B.NO_OF_LEAVES AS TOTAL_LEAVES, C.REF_ID, C.EMP_TITLE,        
   C.EMP_FNAME,C.EMP_LNAME,C.EMAIL1,C.EMAIL2,C.MOBILE1,C.PHONES_H,C.IMG_NAME, C.WEEKLY_OFF1,C.WEEKLY_OFF2,         
   D.DEPARTMENT_NAME,E.DESIG_NAME,F.USERNAME AS CREATED_USER, G.USERNAME AS MODIFIED_USER         
   FROM EMP_LEAVE_DETAILS A         
   JOIN EMP_LEAVE_MASTER  B (NOLOCK) ON A.LEAVE_CODE=B.LEAVE_CODE         
   JOIN EMP_MST C    (NOLOCK) ON A.EMP_ID=C.EMP_ID         
   JOIN EMP_DEPARTMENT D  (NOLOCK) ON C.DEPARTMENT_ID=D.DEPARTMENT_ID         
   JOIN EMP_DESIG E   (NOLOCK) ON C.DESIG_ID=E.DESIG_ID         
   JOIN USERS F    (NOLOCK) ON F.USER_CODE=A.CREATED_BY        
   JOIN USERS G    (NOLOCK) ON G.USER_CODE=A.MODIFIED_BY         
   WHERE A.APPLICATION_ID = ''' + @CVALUE1 + ''' AND APPLICATION_DT BETWEEN ''' + @CVALUE2 + '''         
   AND ''' + @CVALUE3 + ''' ORDER BY  A.APPLICATION_ID'        
 END        
 --------------------        
 IF (@CQUERYID = 112)        
 BEGIN        
 -- EMPLOYEE LEAVE (LEAVE LIST)        
  SET @CQUERY = 'SELECT LEAVE_CODE,LEAVE_NAME,NO_OF_LEAVES FROM EMP_LEAVE_MASTER WHERE LEAVE_CODE <> ''0000000''  
     ORDER BY LEAVE_NAME'        
 END        
 --------------------        
 IF (@CQUERYID = 113)        
 BEGIN        
 -- EMPLOYEE LEAVE (EMPLOYEE LIST)        
  SET @CQUERY = 'SELECT A.EMP_ID,A.REF_ID,A.EMP_FNAME +'' ''+ A.EMP_LNAME AS EMP_NAME,A.PHONES_H,A.EMAIL1,        
   A.EMAIL2,A.MOBILE1,A.IMG_NAME,A.WEEKLY_OFF1,A.WEEKLY_OFF2,B.DEPARTMENT_NAME,C.DESIG_NAME        
   FROM EMP_MST A         
   JOIN EMP_DEPARTMENT B (NOLOCK) ON A.DEPARTMENT_ID=B.DEPARTMENT_ID        
   JOIN EMP_DESIG C  (NOLOCK) ON A.DESIG_ID=C.DESIG_ID         
   WHERE A.EMP_STATUS = 0 ORDER BY A.REF_ID'        
 END        
 --------------------        
 IF (@CQUERYID = 117)        
 BEGIN        
 -- PAYSLIPWIZARD (DEPARTMENT LIST)        
  SET @CQUERY = 'SELECT 1 AS ''CHECK'', DEPARTMENT_ID, DEPARTMENT_NAME         
  FROM EMP_DEPARTMENT         
  WHERE DEPARTMENT_NAME <> ''''         
  ORDER BY DEPARTMENT_NAME'        
 END        
 --------------------        
 IF (@CQUERYID = 119)        
 BEGIN        
 -- PAYSLIPWIZARD (MASTER RECORD)        
  SET @CQUERY = 'SELECT * FROM EMP_PAYSLIP_MST WHERE 1 = 2'        
 END        
 --------------------        
 IF (@CQUERYID = 120)        
 BEGIN        
 -- PAYSLIPWIZARD (DETAIL RECORD)  
  SET @CQUERY = 'SELECT * FROM EMP_PAYSLIP_DET WHERE 1 = 2'        
 END        
 --------------------        
 IF (@CQUERYID = 126)        
 BEGIN        
 -- EMPLOYEE MASTER (DEPARTMENT LIST)        
  SET @CQUERY = 'SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM EMP_DEPARTMENT     
  WHERE DEPARTMENT_NAME <> '''' ORDER BY DEPARTMENT_NAME '        
 END        
 --------------------        
 IF (@CQUERYID = 132)        
 BEGIN        
 -- LOAN ADVANCE (LOAN MASTER RECORD)        
  SET @CQUERY = 'SELECT T0.*, T1.EMP_FNAME,T1.EMP_LNAME , T1.ADDRESS1,T1.ADDRESS2,T1.PHONES_H, T2.AREA_NAME,            
   T3.CITY, T4.DEPARTMENT_NAME, T5.DESIG_NAME,T1.DEPARTMENT_ID,T1.DESIG_ID, T2.PINCODE,T6.STATE,T1.IMG_NAME,            
   T1.EMAIL1, T1.MOBILE1,T1.REF_ID, T1.PAN_NO,ID_PROOF_DOC_NO, T7.USERNAME,T8.USERNAME AS MODIFIEDUSER,            
   CASE             
   WHEN T1.ID_PROOF_DOC_TYPE=0 THEN ''''            
   WHEN T1.ID_PROOF_DOC_TYPE=1 THEN ''DRIVING LICENCE''            
   WHEN T1.ID_PROOF_DOC_TYPE=2 THEN ''PASSPORT'' WHEN T1.ID_PROOF_DOC_TYPE=3 THEN ''VOTER ID CARD''            
   ELSE ''OTHERS''           
   END AS ID_PROOF_DOC_TYPE            
   FROM EMP_LOAN_MST T0               
   JOIN EMP_MST T1 (NOLOCK) ON T0.EMP_ID = T1.EMP_ID               
   JOIN AREA T2  (NOLOCK) ON T2.AREA_CODE = T1.AREA_CODE               
   JOIN CITY T3  (NOLOCK) ON T2.CITY_CODE = T3.CITY_CODE               
   JOIN EMP_DEPARTMENT T4 (NOLOCK) ON T4.DEPARTMENT_ID = T1.DEPARTMENT_ID              
   JOIN EMP_DESIG T5 (NOLOCK) ON T5.DESIG_ID = T1.DESIG_ID              
   JOIN STATE T6  (NOLOCK) ON T6.STATE_CODE = T3.STATE_CODE               
   JOIN USERS T7  (NOLOCK) ON T7.USER_CODE = T0.CREATED_BY              
   JOIN USERS T8  (NOLOCK) ON T8.USER_CODE=T0.MODIFIED_BY          
   WHERE LOAN_ID = ''' + @CVALUE1 + ''''        
 END        
 --------------------        
 IF (@CQUERYID = 133)        
 BEGIN        
 -- LOAN ADVANCE (EMP LOAN LIST)        
  SET @CQUERY ='SELECT T0.EMP_FNAME, T0.EMP_LNAME, T0.EMP_ID, T0.EMP_FNAME + '' '' + T0.EMP_LNAME AS EMP_NAME,  
  T0.DESIG_ID, T0.DEPARTMENT_ID, T1.DESIG_NAME,T2.DEPARTMENT_NAME,T0.ADDRESS1,T0.ADDRESS2,T4.AREA_NAME,T3.CITY,            
  T4.PINCODE,T5.STATE,T0.REF_ID, T0.PHONES_H,T0.EMAIL1,T0.MOBILE1,T0.IMG_NAME,T0.PAN_NO,            
   CASE             
   WHEN T0.ID_PROOF_DOC_TYPE=0 THEN ''''            
   WHEN T0.ID_PROOF_DOC_TYPE=1 THEN ''DRIVING LICENCE''            
   WHEN T0.ID_PROOF_DOC_TYPE=2 THEN ''PASSPORT'' WHEN T0.ID_PROOF_DOC_TYPE=3 THEN ''VOTER ID CARD''            
   ELSE ''OTHERS''               
   END AS ID_PROOF_DOC_TYPE,T0.ID_PROOF_DOC_NO              
   FROM EMP_MST T0               
   JOIN EMP_DESIG T1  (NOLOCK) ON T1.DESIG_ID = T0.DESIG_ID              
   JOIN EMP_DEPARTMENT T2 (NOLOCK) ON T2.DEPARTMENT_ID = T0.DEPARTMENT_ID              
   JOIN AREA T4   (NOLOCK) ON T4.AREA_CODE = T0.AREA_CODE               
   JOIN CITY T3   (NOLOCK) ON T4.CITY_CODE = T3.CITY_CODE              
   JOIN STATE T5   (NOLOCK) ON T5.STATE_CODE = T3.STATE_CODE               
   WHERE T0.EMP_STATUS = 0'             
 END        
 --------------------        
 IF (@CQUERYID = 134)        
 BEGIN        
 -- LOAN ADVANCE (EMP ADDRESS LIST)        
  SET @CQUERY = 'SELECT MAILING_ADDRESS1,MAILING_ADDRESS2,T2.AREA_NAME,T3.CITY,T4.STATE,T2.PINCODE          
   FROM   EMP_MST T1           
   JOIN AREA T2 (NOLOCK) ON T1.MAILING_AREA_CODE = T2.AREA_CODE          
   JOIN CITY T3 (NOLOCK) ON T3.CITY_CODE = T2.CITY_CODE          
   JOIN STATE T4 (NOLOCK) ON T3.STATE_CODE = T4.STATE_CODE           
   WHERE T1.EMP_ID = ''' + @CVALUE1 + ''' '        
 END        
 --------------------        
 IF (@CQUERYID = 135)        
 BEGIN        
 -- LOAN ADVANCE (LOAN DETAIL RECORD LIST)        
  SET @CQUERY = 'SELECT LOAN_ID AS [LOAN ID],CONVERT(CHAR(10),LOAN_DATE,105) AS [LOAN DATE],LOAN_AMOUNT AS [LOAN AMOUNT],          
   TENURE,EMI_AMOUNT AS [EMI AMOUNT]           
   FROM EMP_LOAN_MST WHERE LOAN_ID =''' + @CVALUE1 +  ''''        
 END        
 --------------------        
 IF (@CQUERYID = 136)        
 BEGIN        
 -- LOAN ADVANCE (LOAN DETAIL RECORD LIST)        
  SET @CQUERY = ' SELECT LOAN_ID,CONVERT(CHAR (10),LOAN_DATE,105) AS LOAN_DATE,TENURE ,LOAN_AMOUNT, INTEREST_RATE,          
   CASE         
   WHEN LOAN_TYPE= 1 THEN ''LOAN''         
   ELSE ''ADVANCE''         
   END AS LOAN_TYPE,         
   EMI_AMOUNT,        
   CASE         
   WHEN SETTLEMENT_TYPE = 1 THEN ''ONE TIME''         
   ELSE ''EMI''         
   END AS SETTLEMENT_TYPE,        
   APPROVED_AMOUNT FROM EMP_LOAN_MST           
   WHERE EMP_ID = ''' + @CVALUE1 + ''''        
 END        
 --------------------        
 IF (@CQUERYID = 137)        
 BEGIN        
 -- LOAN ADVANCE (LOOKUP)        
  SET @CQUERY = N'SELECT TOP 1 LOAN_ID FROM EMP_LOAN_MST  WHERE LOAN_ID <> ''0000000''           
  '+(CASE WHEN  @CVALUE1 IN(0,2,3) THEN 'AND  LOAN_ID '+(CASE WHEN  @CVALUE1 =2 THEN '<' WHEN @CVALUE1 =3           
  THEN '>' ELSE '=' END)+''''+ @CVALUE2 +'''' ELSE '' END)+' ORDER BY LOAN_ID '+(CASE WHEN  @CVALUE1 IN (1,3)           
  THEN ' ASC ' ELSE ' DESC ' END)          
  END        
 --------------------        
IF (@CQUERYID = 140)      
 BEGIN          
 -- PAY SLIP GENERATION (LOOKUP)      
  SET @CQUERY = N'SELECT DISTINCT A.PAYSLIP_MONTH AS MONTH_NO,      
  CASE A.PAYSLIP_MONTH       
  WHEN 1 THEN ''JANURARY''      
  WHEN 2 THEN ''FEBRUARY''      
  WHEN 3 THEN ''MARCH''      
  WHEN 4 THEN ''APRIL''      
  WHEN 5 THEN ''MAY''      
  WHEN 6 THEN ''JUNE''      
  WHEN 7 THEN ''JULY''      
  WHEN 8 THEN ''AUGUST''      
  WHEN 9 THEN ''SEPTEMBER''      
  WHEN 10 THEN ''OCTOBER''      
  WHEN 11 THEN ''NOVEMBER''      
  WHEN 12 THEN ''DECEMBER''      
  END AS MONTH_NAME,A.PAYSLIP_YEAR       
  FROM EMP_PAYSLIP_MST A  
  JOIN EMP_MST (NOLOCK) B ON A.EMP_ID = B.EMP_ID
  WHERE B.EMP_STATUS = 0 
  --AND A.PAYSLIP_DATE BETWEEN '''+@CVALUE1+''' AND '''+@CVALUE2+''' 
  AND CONVERT(A.PAYSLIP_YEAR AS VARCHAR)+''-''+RIGHT(''0''+CAST(A.PAYSLIP_MONTH AS VARCHAR),2)+''-01'' BETWEEN '''+@CVALUE1+''' AND '''+@CVALUE2+''' 
  ORDER BY A.PAYSLIP_YEAR,A.PAYSLIP_MONTH'        
  END          
 --------------------                
 IF (@CQUERYID = 144)      
 BEGIN          
 -- PAY SLIP GENERATION (PAYSLIP MASTER RECORD)      
  SET @CQUERY = N'SELECT * FROM EMP_PAYSLIP_MST WHERE 1=2'      
  END          
 --------------------                
 IF (@CQUERYID = 145)      
 BEGIN          
 -- PAY SLIP GENERATION (PAYSLIP DETAIL RECORD)      
  SET @CQUERY = N'SELECT * FROM EMP_PAYSLIP_DET WHERE 1=2'      
  END          
 --------------------                
 IF (@CQUERYID = 152)      
 BEGIN          
 -- PAY SLIP WIZARD (MONTH LIST)      
  SET @CQUERY = N'SELECT DISTINCT PAYSLIP_MONTH, PAYSLIP_YEAR,        
 CASE         
 WHEN PAYSLIP_MONTH = 1 THEN ''JANUARY''      
 WHEN PAYSLIP_MONTH = 2 THEN ''FEBRUARY''        
 WHEN PAYSLIP_MONTH = 3 THEN ''MARCH''        
 WHEN PAYSLIP_MONTH = 4 THEN ''APRIL''        
 WHEN PAYSLIP_MONTH = 5 THEN ''MAY''        
 WHEN PAYSLIP_MONTH = 6 THEN ''JUNE''        
 WHEN PAYSLIP_MONTH = 7 THEN ''JULY''        
 WHEN PAYSLIP_MONTH = 8 THEN ''AUGUST''        
 WHEN PAYSLIP_MONTH = 9 THEN ''SEPTEMBER''      
 WHEN PAYSLIP_MONTH = 10 THEN ''OCTOBER''        
 WHEN PAYSLIP_MONTH = 11 THEN ''NOVEMBER''        
 WHEN PAYSLIP_MONTH = 12 THEN ''DECEMBER''       
 END AS PAYSLIP_MONTHNAME      
 FROM EMP_PAYSLIP_MST        
 WHERE (PAYSLIP_MONTH >= 4 AND PAYSLIP_MONTH <= 12 AND PAYSLIP_YEAR = ''' + @CVALUE1 + ''' ) OR        
 (PAYSLIP_MONTH >= 1 AND PAYSLIP_MONTH <= 3 AND PAYSLIP_YEAR = ''' + @CVALUE2 + ''' )        
 ORDER BY PAYSLIP_YEAR DESC, PAYSLIP_MONTH DESC'      
  END          
 --------------------                
IF (@CQUERYID = 153)      
 BEGIN          
 -- PAY SLIP WIZARD (MONTH LIST)      
  SET @CQUERY = N'SELECT * FROM EMP_CALENDER A       
 WHERE A.HOLIDAY_NAME <> ''''       
 AND MONTH(A.HOLIDAY_DATE) = ''' + @CVALUE1 + '''      
 AND YEAR(A.HOLIDAY_DATE) = ''' + @CVALUE2 + '''       
 ORDER BY A.HOLIDAY_DATE'      
  END          
 --------------------                
IF (@CQUERYID = 154)      
 BEGIN          
 -- PAY SLIP WIZARD (MONTH LIST)      
  SET @CQUERY = N'SELECT DISTINCT YEAR(ATTENDANCE_DT) AS ''YEAR'', DATENAME(MONTH, ATTENDANCE_DT) AS ''MONTH'',       
 MONTH(ATTENDANCE_DT) FROM EMP_ATTENDANCE       
 WHERE (MONTH(ATTENDANCE_DT)>=4 AND YEAR(ATTENDANCE_DT) = ''' + @CVALUE1 + ''')       
 OR (MONTH(ATTENDANCE_DT) <= 3 AND YEAR(ATTENDANCE_DT) = ''' + @CVALUE2 + ''')       
 ORDER BY YEAR(ATTENDANCE_DT), MONTH(ATTENDANCE_DT)'      
  END          
 --------------------                
IF (@CQUERYID = 156)      
 BEGIN          
 -- ATTENDANCE WIZARD (PAY SLIP INFO)      
  SET @CQUERY = N'SELECT C.EMP_ID, C.PAYSLIP_ID FROM EMP_PAYSLIP_MST C       
 WHERE C.PAYSLIP_MONTH = ''' + @CVALUE1 + '''       
 AND C.PAYSLIP_YEAR = ''' + @CVALUE2 + '''    
 AND C.CANCELLED = 0 OR C.CANCELLED = 2 '      
  END          
 --------------------                
IF (@CQUERYID = 157)      
 BEGIN          
 -- EMP MASTER (AREA DETAIL)      
  SET @CQUERY = N'SELECT A.AREA_NAME,A.AREA_CODE , A.PINCODE, B.CITY,      
 B.CITY_CODE, C.STATE,C.STATE_CODE FROM AREA A        
 JOIN  CITY B ON A.CITY_CODE=B.CITY_CODE      
 JOIN STATE C ON B.STATE_CODE=C.STATE_CODE       
 WHERE A.AREA_CODE = ''' + @CVALUE1 + ''''      
  END          
 --------------------                
IF (@CQUERYID = 159)      
 BEGIN          
 -- EMP MASTER (REPORT)      
  SET @CQUERY = N'SELECT * FROM VW_LOANADVANCE       
WHERE EMP_ID = ''' + @CVALUE1 + '''       
 AND MST_LOAN_DATE BETWEEN ''' + @CVALUE2 + '''       
 AND ''' + @CVALUE3 + ''''      
  END          
 --------------------      
IF (@CQUERYID = 162)      
 BEGIN          
 -- EMP MASTER (REPORT)      
  SET @CQUERY = N'SELECT * FROM VW_EMP WHERE EMP_ID = ''' + @CVALUE1 + ''''      
  END          
  --------------------      
IF (@CQUERYID = 165)      
 BEGIN          
 -- LEAVE       
  SET @CQUERY = N'SELECT * FROM EMP_PAYSLIP_MST       
 WHERE CANCELLED = 0 AND EMP_ID = ''' + @CVALUE1 + '''       
 AND PAYSLIP_MONTH = ''' + @CVALUE2 + '''       
 AND PAYSLIP_YEAR = ''' + @CVALUE3 + ''''      
  END          
 --------------------      
IF (@CQUERYID = 168)      
 BEGIN          
 -- LEAVE       
  SET @CQUERY = N'SELECT * FROM VW_LOANADVANCE WHERE LOAN_ID = ''' + @CVALUE1 + ''''      
  END          
--------------------      
IF (@CQUERYID = 173)      
 BEGIN          
 -- CALENDER MASTER       
  SET @CQUERY = N'SELECT *,'''' AS ROW_ID, 
                  CONVERT(VARCHAR(12), HOLIDAY_DATE,105 ) AS DISP_HOLIDAY_DATE       
  FROM EMP_CALENDER       
  WHERE CASE       
  WHEN (MONTH(HOLIDAY_DATE) BETWEEN 1 AND 3) THEN       
  CONVERT( VARCHAR(10), (YEAR (HOLIDAY_DATE)-1))+''-''+       
  CONVERT ( VARCHAR(10), YEAR (HOLIDAY_DATE))      
  ELSE CONVERT( VARCHAR(10), YEAR (HOLIDAY_DATE))+''-''+       
  CONVERT ( VARCHAR(10), (YEAR (HOLIDAY_DATE)+1))      
  END = ''' + @CVALUE1 + '''       
  ORDER BY HOLIDAY_DATE '      
  END          
 --------------------      
IF (@CQUERYID = 178)    
 BEGIN          
 -- ATTENDANCE WIZARD    
  SET @CQUERY = N'SELECT * FROM _EMPATT ORDER BY [USER ID], DATE, TIME'    
        
  END          
 --------------------      
IF (@CQUERYID = 179)    
 BEGIN          
 -- LEAVE    
  SET @CQUERY = N'SELECT * FROM EMP_PAYSLIP_MST WHERE CANCELLED=0 AND     
                EMP_ID = ''' + @CVALUE1 + ''' AND PAYSLIP_MONTH = ''' + @CVALUE2 + '''    
                AND PAYSLIP_YEAR = ''' + @CVALUE3 + ''''    
  END          
 --------------------      
IF (@CQUERYID = 180)    
 BEGIN          
 -- LEAVE    
  SET @CQUERY = N'SELECT * FROM VW_QBF_LEAVEAPPLICATION  WHERE APPLICATION_ID = ''' + @CVALUE1 + ''''    
  END          
 --------------------      
IF (@CQUERYID = 181)    
 BEGIN          
 -- LEAVE    
  SET @CQUERY = N'SELECT DISTINCT(MST_MEMO_NO),APPLICATION_ID,MST_EMP_ID FROM VW_QBF_LEAVEAPPLICATION ' + @CVALUE1 + ''    
  END          
 --------------------      
IF (@CQUERYID = 182)    
 BEGIN          
 -- LEAVE    
   SET @CQUERY = N'SELECT PSM.*,         
    (        
     SELECT ISNULL(SUM(LM.APPROVED_AMOUNT),0.00) FROM EMP_LOAN_MST LM         
     WHERE LM.EMP_ID=PSM.EMP_ID AND MONTH(LM.LOAN_DATE)=''' + @CVALUE1 + ''' AND         
     LM.LOAN_STATUS=1 AND LM.SETTLED=0         
    ) AS LOAN_AMOUNT,        
    (        
     SELECT SUM(PSD.AMOUNT) FROM EMP_PAYSLIP_DET PSD        
     WHERE PSD.PAYSLIP_ID = PSM.PAYSLIP_ID AND PAY_TYPE IN(3,4) AND LOAN_ID<>''0000000''        
    ) AS LOAN_PAID,
    EM.REF_ID, 
    EM.PAN_NO, 
    EM.EMP_TITLE + '' '' + EM.EMP_FNAME + '' '' + EM.EMP_LNAME AS EMPNAME,        
    EM.WEEKLY_OFF1, 
    EM.WEEKLY_OFF2, 
    ''CREATED BY - ''+ CU.USERNAME AS CREATEDBY,        
    ''MODIFIED BY - ''+ MU.USERNAME AS MODIFIEDBY,        
    (        
     CASE         
     WHEN PSM.CANCELLED=1 THEN ''CANCELLED BY - '' + CANU.USERNAME          
     ELSE ''''         
     END        
    ) AS CANCELLEDBY,
    EM.DEPARTMENT_ID,
    DEPT.DEPARTMENT_NAME,
    EM.DESIG_ID,
    DESIG.DESIG_NAME,
    EM.DEPT_ID,
    LOC.DEPT_NAME,
    EM.PF_AMOUNT AS PFAMOUNT_EMPMASTER,
    EM.BANK_ACC_NO
    FROM EMP_PAYSLIP_MST PSM        
    INNER JOIN EMP_MST EM ON EM.EMP_ID=PSM.EMP_ID         
    INNER JOIN USERS CU ON PSM.USER_CODE=CU.USER_CODE        
    INNER JOIN USERS MU ON PSM.EDIT_USER_CODE=MU.USER_CODE        
    INNER JOIN USERS CANU ON PSM.CANCELLED_USER_CODE=CANU.USER_CODE      
    INNER JOIN EMP_DEPARTMENT DEPT ON EM.DEPARTMENT_ID=DEPT.DEPARTMENT_ID    
    INNER JOIN EMP_DESIG DESIG ON EM.DESIG_ID =DESIG.DESIG_ID    
    INNER JOIN LOCATION LOC ON LOC.DEPT_ID=EM.DEPT_ID       
    WHERE PSM.PAYSLIP_MONTH=''' + @CVALUE1 + ''' AND PSM.PAYSLIP_YEAR=''' + @CVALUE2 + '''  
    AND EM.EMP_ID='''+@CVALUE3+'''        
    ORDER BY PSM.PAYSLIP_YEAR,PSM.PAYSLIP_MONTH,PSM.EMP_ID,PSM.MODIFIED_ON'    
  END          
 --------------------      
IF (@CQUERYID = 183)    
 BEGIN          
 -- LEAVE    
 IF 1=(SELECT TOP 1 VALUE FROM CONFIG WHERE  CONFIG_OPTION='ENABLE_NEW_PAYSLIP')
 BEGIN
	SET @CQUERY = N'SELECT A.ROW_ID,A.PAYSLIP_ID,A.PAY_ID,A.LOAN_ID,A.PAY_TYPE
	,(CASE WHEN A.PAY_ID=''PAY0005'' THEN (SELECT EMPLOYER_PF_AMOUNT FROM EMP_PAYSLIP_MST WHERE PAYSLIP_ID='''+@CVALUE1+ ''') 
		   WHEN A.PAY_ID=''PAY0006'' THEN (SELECT EMPLOYER_ESI_AMOUNT FROM EMP_PAYSLIP_MST WHERE PAYSLIP_ID='''+@CVALUE1+ ''')				
	  ELSE A.AMOUNT END) AS AMOUNT
	,A.ORG_AMOUNT,    
		CASE     
	  WHEN A.PAY_TYPE=2 THEN B.PAY_NAME     
	  WHEN A.PAY_TYPE=1 THEN B.PAY_NAME     
	  WHEN A.PAY_TYPE=3 THEN ''LOAN''+'' (ID-''+C.LOAN_ID+'')''     
	  WHEN A.PAY_TYPE=4 THEN ''SAL ADVANCE''+'' (ID-''+C.LOAN_ID+'')''    
		END AS PAY_NAME,    
		ISNULL(C.APPROVED_AMOUNT,0.00) AS LOAN_AMOUNT,  
		ISNULL(B.PAY_ORDER,0) AS PAY_ORDER    
		FROM EMP_PAYSLIP_DET A    
		LEFT OUTER JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID    
		LEFT OUTER JOIN EMP_LOAN_MST C ON A.LOAN_ID=C.LOAN_ID    
		WHERE A.PAYSLIP_ID=''' + @CVALUE1 + '''     
		ORDER BY A.PAYSLIP_ID,A.PAY_TYPE,B.PAY_ORDER'
 END
 ELSE
 BEGIN
	  SET @CQUERY = N'SELECT A.*,    
		CASE     
	  WHEN A.PAY_TYPE=2 THEN B.PAY_NAME     
	  WHEN A.PAY_TYPE=1 THEN B.PAY_NAME     
	  WHEN A.PAY_TYPE=3 THEN ''LOAN''+'' (ID-''+C.LOAN_ID+'')''     
	  WHEN A.PAY_TYPE=4 THEN ''SAL ADVANCE''+'' (ID-''+C.LOAN_ID+'')''    
		END AS PAY_NAME,    
		ISNULL(C.APPROVED_AMOUNT,0.00) AS LOAN_AMOUNT,  
		ISNULL(B.PAY_ORDER,0) AS PAY_ORDER    
		FROM EMP_PAYSLIP_DET A    
		LEFT OUTER JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID    
		LEFT OUTER JOIN EMP_LOAN_MST C ON A.LOAN_ID=C.LOAN_ID    
		WHERE A.PAYSLIP_ID=''' + @CVALUE1 + '''     
		ORDER BY A.PAYSLIP_ID,A.PAY_TYPE,B.PAY_ORDER'    
  END  
  END          
 --------------------      
IF (@CQUERYID = 186)    
 BEGIN          
 -- PRE PAYMENT ANALYSIS    
  SET @CQUERY = N'SELECT EA.EMP_ID, EA.ATTENDANCE_DT, EA.SHIFT_TIME_IN, EA.SHIFT_TIME_OUT,     
    EA.SHIFT_TIME_OUT-EA.SHIFT_TIME_IN AS SHIFT_DURATION, EA.HALFDAY_CUTOFF,     
    EA.TIME_OUT-EA.TIME_IN AS EMP_DURATION, EA.TIME_IN, EA.TIME_OUT    
                FROM EMP_ATTENDANCE EA     
                WHERE MONTH(EA.ATTENDANCE_DT) = ''' + @CVALUE1 + ''' AND EA.EMP_ID = ''' + @CVALUE2 + '''      
                ORDER BY EMP_ID,ATTENDANCE_DT'    
  END          
 --------------------      
IF (@CQUERYID = 188)    
 BEGIN          
 -- PRE PAYSLIP    
  SET @CQUERY = N'SELECT A.*,    
    CASE     
    WHEN A.PAY_TYPE=2 THEN B.PAY_NAME     
    WHEN A.PAY_TYPE=1 THEN B.PAY_NAME     
                WHEN A.PAY_TYPE=3 THEN ''LOAN''+'' (ID-''+C.LOAN_ID+'')''     
                WHEN A.PAY_TYPE=4 THEN ''ADVANCE''+'' (ID-''+C.LOAN_ID+'')''    
                END AS PAY_NAME,    
                ISNULL(C.APPROVED_AMOUNT,0.00) AS LOAN_AMOUNT    
                FROM EMP_PAYSLIP_DET A    
                LEFT OUTER JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID    
                LEFT OUTER JOIN EMP_LOAN_MST C ON A.LOAN_ID=C.LOAN_ID    
                WHERE A.PAYSLIP_ID = ''' + @CVALUE1 + ''' ORDER BY A.PAYSLIP_ID,A.PAY_TYPE'    
  END          
 --------------------      
IF (@CQUERYID = 189)    
 BEGIN          
 -- PRE PAYSLIP    
  SET @CQUERY = N'SELECT A.PAYSLIP_ID, A.BASIC_SALARY, B.REF_ID,     
    B.EMP_TITLE + '' '' + B.EMP_FNAME + '' '' + B.EMP_LNAME AS EMPNAME    
                FROM EMP_PAYSLIP_MST A    
                JOIN EMP_MST B ON A.EMP_ID = B.EMP_ID    
                WHERE A.EMP_ID = ''' + @CVALUE1 + ''''    
  END          
 --------------------      
IF (@CQUERYID = 190)    
 BEGIN          
 -- THEME    
  SET @CQUERY = N'SELECT THEME_CODE, THEME_NAME FROM THEMES ORDER BY THEME_NAME'    
  END          
 --------------------      
IF (@CQUERYID = 191)    
 BEGIN          
 -- THEME    
  SET @CQUERY = N'SELECT * FROM THEMES  WHERE THEME_CODE = ''' + @CVALUE1 + ''''    
  END          
 --------------------      
IF (@CQUERYID = 192)    
 BEGIN          
 -- THEME    
  SET @CQUERY = N'SELECT * FROM THEME_MODULES  WHERE THEME_CODE = ''' + @CVALUE1 + '''     
    ORDER BY GROUP_NAME, FORM_NAME'    
  END          
 --------------------      
IF (@CQUERYID = 198)    
 BEGIN          
 -- ATTENDANCE WIZARD    
  SET @CQUERY = N'SELECT * FROM _EMPATT ORDER BY [USER ID], DATE, [TIME IN], [TIME OUT]'    
  END          
 --------------------            
IF (@CQUERYID = 199)    
 BEGIN          
 -- ATTENDANCE WIZARD  -  LOCATION LIST  
  SET @CQUERY = N'SELECT 1 AS ''CHECK'', A.DEPT_ID, A.DEPT_NAME FROM LOCATION A  
     WHERE A.DEPT_NAME <> '''' ORDER BY A.DEPT_NAME'  
  END          
 --------------------                  
IF (@CQUERYID = 200)    
 BEGIN          
 -- ATTENDANCE WIZARD  -  ALL LEFT EMPLOYEE LIST  
  SET @CQUERY = N'SELECT 0 AS ''CHECK'', A.EMP_ID, A.REF_ID, A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMP_NAME,           
    B.DEPARTMENT_NAME, A.SHIFT_ID, C.SHIFT_NAME, A.DEPT_ID, A.WEEKLY_OFF1,   
    A.WEEKLY_OFF2, A.LEAVING_DATE FROM EMP_MST A           
    JOIN EMP_DEPARTMENT B (NOLOCK) ON A.DEPARTMENT_ID = B.DEPARTMENT_ID          
    JOIN EMP_SHIFTS C (NOLOCK) ON A.SHIFT_ID = C.SHIFT_ID  
    JOIN LOCATION D (NOLOCK) ON A.DEPT_ID = D.DEPT_ID   
    WHERE A.EMP_STATUS = 2  
    ORDER BY B.DEPARTMENT_NAME, A.EMP_FNAME'  
  END          
 --------------------                  
IF (@CQUERYID = 201)    
 BEGIN          
  SET @CQUERY = N'SELECT A.DEPT_ID, A.DEPT_NAME FROM LOCATION A WHERE A.DEPT_NAME <> '''' ORDER BY DEPT_ID'  
  END          
 --------------------                  
IF (@CQUERYID = 202)    
 BEGIN          
  SET @CQUERY = N'SELECT EMP_ID FROM EMP_MST WHERE EMP_ID NOT IN   
    (  
     SELECT DISTINCT A.EMP_ID FROM EMP_ATTENDANCE A   
     WHERE MONTH(A.ATTENDANCE_DT) = ''' + @CVALUE1 + '''  
     AND YEAR(A.ATTENDANCE_DT) = ''' + @CVALUE2 + '''  
    ) '  
  END          
 --------------------                  
IF (@CQUERYID = 203)    
 BEGIN          
  SET @CQUERY = N'SELECT 0 AS CHECKS, A.DEPT_ID, A.DEPT_NAME AS DEPT_NAME FROM LOCATION A   
     WHERE A.INACTIVE=0  ORDER BY A.DEPT_ID'  
  END          
 --------------------                  
IF (@CQUERYID = 204)    
 BEGIN          
  SET @CQUERY = N'SELECT 0 AS CHECKS, A.DEPARTMENT_ID, A.DEPARTMENT_NAME FROM EMP_DEPARTMENT A   
     WHERE A.DEPARTMENT_ID <> ''0000000'' ORDER BY A.DEPARTMENT_NAME'  
  END          
 --------------------                  
IF (@CQUERYID = 205)    
 BEGIN          
  SET @CQUERY = N'SELECT B.REF_ID, B.EMP_FNAME, A.* FROM EMP_WPAYATT A   
                            JOIN EMP_MST B ON A.EMP_ID = B.EMP_ID  
                            WHERE A.EMP_ID IN (' + @CVALUE1 + ') AND MONTH(IST_TIME)=''' + @CVALUE2 + '''  
                            AND YEAR(IST_TIME)=''' + @CVALUE3 + '''
                            ORDER BY EMP_ID, IST_TIME'  
  END          
 --------------------                  
IF (@CQUERYID = 206)    
BEGIN          
SET @CQUERY = N'SELECT A.DEPT_ID, A.DEPT_NAME,   
                                  ISNULL(D.SHIFT_NAME,'''') AS OLD_SHIFT_NAME,   
                                  ISNULL(D.SHIFT_ID,'''') AS OLD_SHIFT_ID,  
                                  '''' AS NEW_SHIFT_NAME,   
                                  '''' AS NEW_SHIFT_ID  
                                FROM LOCATION A   
                                LEFT OUTER JOIN  
                                (  
                                 SELECT TOP 1 B.SHIFT_ID, C.SHIFT_NAME, B.DEPT_ID FROM EMP_MST B  
                                 JOIN EMP_SHIFTS C (NOLOCK) ON B.SHIFT_ID = C.SHIFT_ID  
                                 WHERE B.EMP_STATUS = 0 ORDER BY B.REF_ID   
                                ) D ON A.DEPT_ID = D.DEPT_ID  
                                WHERE A.DEPT_NAME <> ''''   
                                ORDER BY A.DEPT_NAME'  
END          
-- --------------------                  
IF (@CQUERYID = 207)  
BEGIN          
SET @CQUERY = N'SELECT A.SHIFT_ID, A.SHIFT_NAME, A.SHIFT_TIME_IN, A.SHIFT_TIME_OUT, A.HALFDAY_CUTOFF  
                                FROM EMP_SHIFTS A WHERE A.SHIFT_NAME <> '''' ORDER BY A.SHIFT_NAME'  
END          
-- --------------------                  
IF (@CQUERYID = 208)  
BEGIN          
SET @CQUERY = N'SELECT A.*,B.PAY_TYPE,B.PAY_ORDER, B.FIXED FROM EMP_SALARY_PROFILE A  
                                INNER JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID  WHERE A.EMP_ID=''' + @CVALUE1 + ''''  
END          
---- --------------------                  
IF (@CQUERYID = 209)  
BEGIN          
SET @CQUERY = N'SELECT * FROM VW_ATTSUMMARY  
                WHERE ATT_MONTH=''' + @CVALUE1 + ''' AND ATT_YEAR=''' + @CVALUE2 +   
                ''' AND EMP_ID=''' + @CVALUE3 + ''''  
END          
-- --------------------                  
IF (@CQUERYID = 210)  
BEGIN          
SET @CQUERY = N'SELECT EMP_ID,PF_ENABLED,ESI_ENABLED,BASIC_SALARY, PF_AMOUNT, PF_NO, ESI_NO 
				FROM EMP_MST WHERE EMP_ID=''' + @CVALUE1 + ''''  
END          
-- --------------------                  
IF (@CQUERYID = 211)  
BEGIN          
SET @CQUERY = N'SELECT 1 AS [CHECK], A.EMP_ID, A.REF_ID, EMP_FNAME + '' '' + EMP_LNAME AS EMP_NAME,  
                B.DEPARTMENT_NAME, B.DEPARTMENT_ID, A.DATE_OF_JOINING,A.BASIC_SALARY, A.DEPT_ID FROM EMP_MST A   
                JOIN EMP_DEPARTMENT B (NOLOCK) ON A.DEPARTMENT_ID = B.DEPARTMENT_ID   
                WHERE A.EMP_FNAME <> '''' AND EMP_STATUS = 0    
                ORDER BY B.DEPARTMENT_NAME, A.EMP_FNAME, REF_ID'  
END          
---- --------------------                  
IF (@CQUERYID = 212)  
BEGIN          
SET @CQUERY = N'SELECT EM.EMP_ID,EM.REF_ID,EM.EMP_TITLE + '' '' + EM.EMP_FNAME + '' '' + EM.EMP_LNAME AS EMP_NAME,   
    EM.BASIC_SALARY, EM.SALARY_PROFILE_ID, ESP.ALIAS, ESP.EXPRESSION,ESP.PAY_ID,EP.PAY_NAME,EP.PAY_TYPE,  
    0 AS AMOUNT,EM.PF_ENABLED,EM.ESI_ENABLED FROM EMP_MST EM       
                INNER JOIN EMP_SALARY_PROFILE ESP ON ESP.EMP_ID=EM.EMP_ID  
                INNER JOIN EMP_PAY EP ON ESP.PAY_ID =EP.PAY_ID  
                WHERE EM.EMP_STATUS=0 AND EM.EMP_ID = ''' + @CVALUE1 + '''   
                ORDER BY EP.PAY_TYPE DESC,ESP.EXPRESSION'  
END          
---- --------------------                  
IF (@CQUERYID = 213)  
BEGIN          
SET @CQUERY = N'SELECT LM.* FROM EMP_LOAN_MST LM       
                WHERE LM.LOAN_STATUS=1 AND LM.APPROVED_AMOUNT>0 AND LM.SETTLED=0 AND       
                LM.EMP_ID = ''' + @CVALUE1 + '''  AND MONTH(LM.LOAN_DATE)=''' + @CVALUE2 + '''   
                AND YEAR(LM.LOAN_DATE)=''' + @CVALUE3 + '''   
                ORDER BY LM.LOAN_TYPE,LM.SETTLEMENT_TYPE'  
END          
---- --------------------            
IF (@CQUERYID = 215)  
BEGIN          
SET @CQUERY = N'SELECT PAY_ID, PAY_NAME,PAY_TYPE, ISNULL(PAY_ORDER, 0) AS PAY_ORDER, FIXED FROM EMP_PAY   
    WHERE PAY_NAME <> '''' ORDER BY PAY_TYPE DESC, PAY_ORDER,PAY_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 216)  
BEGIN          
SET @CQUERY = N'SELECT DISTINCT CASE WHEN(MONTH(HOLIDAY_DATE) BETWEEN 1 AND 3) THEN  
                 CONVERT( VARCHAR(10), (YEAR (HOLIDAY_DATE)-1))+''-''+   
                 CONVERT ( VARCHAR(10), YEAR (HOLIDAY_DATE)) ELSE   
                 CONVERT( VARCHAR(10), YEAR (HOLIDAY_DATE))+''-''+   
                 CONVERT ( VARCHAR(10), (YEAR (HOLIDAY_DATE)+1))  
                 END  AS [YEAR] FROM EMP_CALENDER WHERE HOLIDAY_NAME <> '''''  
END          
---- --------------------                  
IF (@CQUERYID = 217)  
BEGIN          
SET @CQUERY = N'SELECT A.EMP_ID,A.REF_ID,A.EMP_TITLE + '' '' + A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMPNAME,  
    B.DESIG_NAME FROM EMP_MST A   
    JOIN EMP_DESIG B ON A.DESIG_ID = B.DESIG_ID   
    WHERE A.DEPARTMENT_ID = ''' + @CVALUE1 + ''' ORDER BY A.REF_ID,B.DESIG_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 218)  
BEGIN          
SET @CQUERY = N'SELECT DEPARTMENT_ID, DEPARTMENT_NAME FROM EMP_DEPARTMENT   
    WHERE DEPARTMENT_NAME <> '''' AND DEPARTMENT_ID <>''0000000'' ORDER BY DEPARTMENT_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 219)  
BEGIN          
SET @CQUERY = N'SELECT A.EMP_ID, A.REF_ID, A.EMP_TITLE + '' '' + A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMPNAME,  
    B.DEPARTMENT_NAME FROM EMP_MST A   
                JOIN EMP_DEPARTMENT B ON A.DEPARTMENT_ID=B.DEPARTMENT_ID   
                WHERE A.DESIG_ID = ''' + @CVALUE1 + ''' ORDER BY A.REF_ID,B.DEPARTMENT_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 220)  
BEGIN          
SET @CQUERY = N'SELECT EMP_ID,MST_REF_ID AS REF_ID FROM VW_EMPMASTER ' + @CVALUE1 + ''  
END          
---- --------------------                  
IF (@CQUERYID = 221)  
BEGIN          
SET @CQUERY = N'SELECT EMP_ID ,REF_ID,REF_ID AS MST_MEMO_NO FROM EMP_MST   
    WHERE EMP_ID <> ''0000000'' ORDER BY REF_ID'  
END          
---- --------------------                  
IF (@CQUERYID = 222)  
BEGIN          
SET @CQUERY = N'SELECT T0.*, T3.AREA_NAME, T3.PINCODE,T4.CITY_CODE,T4.CITY,T5.STATE_CODE,       
                 T5.STATE, T6.DEPARTMENT_NAME,T7.DESIG_NAME,T8.SHIFT_NAME,T8.SHIFT_TIME_IN,T8.SHIFT_TIME_OUT,       
                 CONVERT(CHAR(20),ISNULL((T8.SHIFT_TIME_OUT - T8.SHIFT_TIME_IN),0),114) AS SHIFT_DURATION,        
                 T10.AREA_NAME AS MAILING_AREA_NAME,T11.CITY_CODE AS MAILING_CITY_CODE,          
                 T11.CITY AS MAILING_CITY,T12.STATE_CODE AS MAILING_STATE_CODE, T12.STATE AS MAILING_STATE,        
                 T10.PINCODE AS MAILING_PINCODE,T13.USERNAME, B.DEPT_ID + '' - '' + B.DEPT_NAME AS DEPT_NAME  
                 FROM EMP_MST T0       
                 LEFT  JOIN AREA T3 ON T3.AREA_CODE = T0.AREA_CODE       
                 LEFT JOIN CITY T4 ON T4.CITY_CODE = T3.CITY_CODE       
                 LEFT JOIN STATE T5 ON T5.STATE_CODE = T4.STATE_CODE       
                 LEFT JOIN EMP_DEPARTMENT T6 ON T6.DEPARTMENT_ID = T0.DEPARTMENT_ID       
                 LEFT JOIN EMP_DESIG T7 ON T7.DESIG_ID = T0.DESIG_ID       
                 LEFT JOIN EMP_SHIFTS T8 ON T0.SHIFT_ID = T8.SHIFT_ID      
                 LEFT JOIN AREA T10 ON T0.MAILING_AREA_CODE = T10.AREA_CODE       
                 LEFT JOIN CITY T11 ON T11.CITY_CODE = T10.CITY_CODE       
                 LEFT JOIN STATE T12 ON T11.STATE_CODE  = T12.STATE_CODE       
                 LEFT JOIN USERS T13 ON T13.USER_CODE = T0.USER_CODE    
                 LEFT JOIN LOCATION B ON T0.DEPT_ID=B.DEPT_ID       
                 WHERE T0.EMP_ID = ''' + @CVALUE1 + ''''  
END          
---- --------------------                  
IF (@CQUERYID = 223)  
BEGIN          
SET @CQUERY = N'SELECT A.AREA_CODE, A.AREA_NAME, A.PINCODE, B.CITY, C.STATE FROM AREA A       
                                 JOIN CITY B ON A.CITY_CODE = B.CITY_CODE      
                                 JOIN STATE C ON B.STATE_CODE = C.STATE_CODE       
                                 WHERE A.AREA_NAME <> '''' ORDER BY A.AREA_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 224)  
BEGIN          
SET @CQUERY = N'SELECT DESIG_ID, DESIG_NAME FROM EMP_DESIG WHERE DESIG_ID <> ''0000000'''  
END          
---- --------------------                  
IF (@CQUERYID = 225)  
BEGIN          
SET @CQUERY = N'SELECT SHIFT_NAME,SHIFT_ID,SHIFT_TIME_IN,SHIFT_TIME_OUT,ISNULL(DEFAULT_SHIFT,0) AS [DEFAULT_SHIFT] FROM EMP_SHIFTS WHERE SHIFT_ID <> ''0000000'''  
END          
---- --------------------                  
IF (@CQUERYID = 227)  
BEGIN          
SET @CQUERY = N'SELECT B.PAY_NAME, B.PAY_TYPE,B.PAY_ORDER, A.* , B.FIXED  
                FROM EMP_SALARY_PROFILE A  
                JOIN EMP_PAY B ON A.PAY_ID = B.PAY_ID  
                WHERE A.EMP_ID = ''' + @CVALUE1 + ''' ORDER BY A.EMP_ID, B.PAY_TYPE DESC,B.PAY_ORDER,B.PAY_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 228)  
BEGIN          
SET @CQUERY = N'SELECT A.PAY_ID, A.PAY_NAME, A.PAY_TYPE, FIXED FROM EMP_PAY A WHERE PAY_ID <> ''0000000''   
    ORDER BY A.PAY_TYPE DESC, A.PAY_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 229)  
BEGIN          
SET @CQUERY = N'SELECT A.DEPT_ID, A.DEPT_ID + '' - '' + A.DEPT_NAME AS DEPT_NAME FROM LOCATION A WHERE INACTIVE = 0'  
END          
---- --------------------                  
IF (@CQUERYID = 230)  
BEGIN          
SET @CQUERY = N'SELECT LEAVE_CODE,LEAVE_NAME FROM EMP_LEAVE_MASTER WHERE LEAVE_NAME <> '''' ORDER BY LEAVE_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 232)  
BEGIN          
SET @CQUERY = N'SELECT SHIFT_ID , SHIFT_NAME FROM EMP_SHIFTS WHERE SHIFT_NAME <> '''''  
END          
---- --------------------                  
IF (@CQUERYID = 233)  
BEGIN          
SET @CQUERY = N'SELECT A.EMP_ID,A.REF_ID,A.EMP_TITLE + '' '' + A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMPNAME,  
                        D.SHIFT_NAME FROM EMP_MST A   
                        JOIN EMP_SHIFTS D ON A.SHIFT_ID = D.SHIFT_ID  
                        WHERE D.SHIFT_ID = ''' + @CVALUE1 + ''' ORDER BY A.REF_ID'  
END          
---- --------------------                  
IF (@CQUERYID = 234)  
BEGIN          
SET @CQUERY = N'SELECT MEMO_NO FROM EMP_LEAVE_CREDIT ORDER BY YEAR, MONTH, EMP_ID'  
END          
---- --------------------                  
IF (@CQUERYID = 235)  
BEGIN          
SET @CQUERY = N'SELECT A.*, B.EMP_FNAME + '' ''  + B.EMP_LNAME AS EMP_NAME, B.REF_ID   
                FROM EMP_LEAVE_CREDIT A  
                JOIN EMP_MST B (NOLOCK) ON A.EMP_ID = B.EMP_ID   
                WHERE MEMO_NO = ''' + @CVALUE1 + ''''  
END          
---- --------------------                  
IF (@CQUERYID = 236)  
BEGIN          
SET @CQUERY = N'SELECT A.EMP_ID, A.REF_ID, A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMP_NAME,           
               B.DEPARTMENT_NAME, C.DESIG_NAME FROM EMP_MST A           
               JOIN EMP_DEPARTMENT B (NOLOCK) ON A.DEPARTMENT_ID = B.DEPARTMENT_ID   
               JOIN EMP_DESIG C (NOLOCK) ON A.DESIG_ID = C.DESIG_ID   
               WHERE A.EMP_STATUS = 0 ORDER BY B.DEPARTMENT_NAME, A.EMP_FNAME'  
END          
---- --------------------                  
IF (@CQUERYID = 237)  
BEGIN          
SET @CQUERY = N'SELECT * FROM EMP_LEAVE_MASTER WHERE LEAVE_CODE <> ''0000000'' ORDER BY LEAVE_NAME'  
END          
---- --------------------                  
IF (@CQUERYID = 239)  
BEGIN          
SET @CQUERY = N'SELECT A.*,B.PAY_TYPE,B.PAY_ORDER, B.FIXED FROM EMP_SALARY_PROFILE A  
                INNER JOIN EMP_PAY B ON A.PAY_ID=B.PAY_ID    
                WHERE A.EMP_ID=''' + @CVALUE1 + ''''  
END          
---- --------------------                  
IF (@CQUERYID = 240)  
BEGIN          
SET @CQUERY = N'SELECT DISTINCT EM.EMP_ID, EM.REF_ID,   
				EM.REF_ID + '' - '' + EM.EMP_FNAME + '' '' + EM.EMP_LNAME AS EMPNAME,  
				ED.DEPARTMENT_ID, ED.DEPARTMENT_NAME, EM.DEPT_ID, LOC.DEPT_NAME  
                FROM EMP_PAYSLIP_MST PSM   
                INNER JOIN EMP_MST EM ON PSM.EMP_ID=EM.EMP_ID  
                INNER JOIN EMP_DEPARTMENT ED ON EM.DEPARTMENT_ID=ED.DEPARTMENT_ID   
                INNER JOIN LOCATION LOC ON EM.DEPT_ID=LOC.DEPT_ID  
                WHERE EM.EMP_ID <> ''0000000''   
                AND PSM.PAYSLIP_MONTH = ''' + @CVALUE1 + '''   
                AND PSM.PAYSLIP_YEAR = ''' + @CVALUE2 + '''  
               -- AND EM.EMP_STATUS = 0  
                ORDER BY LOC.DEPT_NAME,ED.DEPARTMENT_NAME,EM.REF_ID'  
END          
---- --------------------                  
IF (@CQUERYID = 241)  
BEGIN          
SET @CQUERY = N'SELECT EM.EMP_ID, EM.BASIC_SALARY, ESP.ALIAS,       
                ESP.EXPRESSION,ESP.PAY_ID,EP.PAY_NAME,EP.PAY_TYPE,0 AS AMOUNT,EM.PF_ENABLED,EM.ESI_ENABLED      
                FROM EMP_MST EM       
                INNER JOIN EMP_SALARY_PROFILE ESP ON EM.EMP_ID = ESP.EMP_ID
                INNER JOIN EMP_PAY EP ON ESP.PAY_ID =EP.PAY_ID  
                WHERE EM.EMP_STATUS=0 AND EM.EMP_ID = ''' + @CVALUE1 + '''
                ORDER BY EP.PAY_TYPE DESC,ESP.EXPRESSION'  
END          
---- --------------------                  
IF (@CQUERYID = 242)  
BEGIN          
SET @CQUERY = N'SELECT EMP_ID, DATE_OF_BIRTH FROM EMP_MST ORDER BY EMP_ID'
END          
---- --------------------                  
IF (@CQUERYID = 243)  
BEGIN          
SET @CQUERY = N'SELECT 1 AS [CHECK], A.DEPT_ID, A.DEPT_ALIAS, A.DEPT_NAME FROM LOCATION A
WHERE A.INACTIVE = 0 ORDER BY A.DEPT_ID'
END          
---- --------------------                  
IF (@CQUERYID = 245)  
BEGIN        
SET @CQUERY = N'
SELECT B.*,  C.DEPT_NAME, C.DEPT_ALIAS 
	FROM EMP_ATTENDANCE A
		JOIN(
			SELECT  B.EMP_ID,A.DEPT_ID,  B.ATTENDANCE_DT, MAX (TIME_OUT ) AS TIME_OUT 
			FROM EMP_ATTENDANCE A
			JOIN(
					SELECT MAX (ATTENDANCE_DT) AS ATTENDANCE_DT, EMP_ID
					FROM EMP_ATTENDANCE
					GROUP BY EMP_ID
				)B ON A.EMP_ID = B.EMP_ID  AND A.ATTENDANCE_DT = B.ATTENDANCE_DT
			WHERE MONTH(B.ATTENDANCE_DT) = ''' + @CVALUE1 + ''' AND YEAR(B.ATTENDANCE_DT) = ''' + @CVALUE2 + '''				
				GROUP BY B.EMP_ID, B.ATTENDANCE_DT,A.DEPT_ID
			) B ON A.EMP_ID = B.EMP_ID  AND A.ATTENDANCE_DT = B.ATTENDANCE_DT  AND A.TIME_OUT = B.TIME_OUT 
		AND B.DEPT_ID=A.DEPT_ID	
		
	JOIN LOCATION C ON B.DEPT_ID = C.DEPT_ID
	GROUP BY B.EMP_ID, B.ATTENDANCE_DT , A.DEPT_ID, C.DEPT_NAME, C.DEPT_ALIAS, B.TIME_OUT ,B.DEPT_ID 
	ORDER BY B.EMP_ID, B.ATTENDANCE_DT DESC '
END          
---- --------------------                  
IF(@CQUERYID = 246)
BEGIN
SET @CQUERY = N'SELECT A.EMP_ID, A.REF_ID, A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMP_NAME, 
                                A.DEPARTMENT_ID, A.DESIG_ID, A.DEPT_ID, A.SHIFT_ID, B.DEPARTMENT_NAME, 
                                C.SHIFT_NAME, C.SHIFT_TIME_IN, C.SHIFT_TIME_OUT, C.HALFDAY_CUTOFF, A.IMG_NAME FROM EMP_MST A
                                JOIN EMP_DEPARTMENT B (NOLOCK) ON A.DEPARTMENT_ID = B.DEPARTMENT_ID
                                JOIN EMP_SHIFTS C (NOLOCK) ON A.SHIFT_ID = C.SHIFT_ID
                                WHERE A.EMP_STATUS = 0 ' + @CVALUE1 + ' ORDER BY A.EMP_FNAME, A.EMP_LNAME'
END        
----------------------------
IF(@CQUERYID = 247)
BEGIN
SET @CQUERY = N'SELECT B.REF_ID, B.IMG_NAME, B.EMP_FNAME + '' '' + B.EMP_LNAME AS EMP_NAME, 
--                       (CASE WHEN A.LOG_ABSENT_STATUS=1 OR B.WEEKLY_OFF1= DATENAME(DW,A.ATTENDANCE_DT)  THEN ''W''
--WHEN A.LOG_ABSENT_STATUS=4 THEN ''B'' WHEN A.LOG_ABSENT_STATUS=3 THEN ''LV'' ELSE '''' END) +   

--(CASE WHEN ((A.TIME_IN='''' AND A.TIME_OUT='''' AND A.LOG_ABSENT_STATUS NOT IN (1,4,2)AND B.WEEKLY_OFF1= DATENAME(DW,A.ATTENDANCE_DT)))   THEN ''LV'' ELSE    
--(CASE WHEN ((A.TIME_IN = '''') OR (A.TIME_OUT = '''')) THEN (CASE WHEN A.LOG_ABSENT_STATUS=2 THEN ''A''  WHEN A.LOG_ABSENT_STATUS=0 THEN ''LV'' WHEN A.LOG_ABSENT_STATUS=0 AND B.WEEKLY_OFF1= DATENAME(DW,A.ATTENDANCE_DT) THEN ''LV'' ELSE '''' END)    
--WHEN A.LOG_ABSENT_STATUS<>1 AND ((A.TIME_IN > A.HALFDAY_CUTOFF) OR (A.TIME_OUT < A.HALFDAY_CUTOFF)) THEN (CASE WHEN A.LOG_ABSENT_STATUS<>1 THEN ''LV'' ELSE '''' END)    
--WHEN ((A.TIME_IN > D.LATE_CUTOFF) AND (A.TIME_IN <= A.HALFDAY_CUTOFF)) AND    
--((A.TIME_OUT < D.EARLY_CUTOFF) AND (A.TIME_OUT >= A.HALFDAY_CUTOFF)) THEN ''LV''    
--WHEN (A.TIME_IN <= A.SHIFT_TIME_IN) AND (A.TIME_OUT >= A.SHIFT_TIME_OUT) THEN ''P''    
--ELSE     
---- INCOMING STATUS    
--(CASE WHEN  (A.TIME_IN <= A.SHIFT_TIME_IN) THEN ''O''    
--WHEN  (A.TIME_IN > A.SHIFT_TIME_IN) AND (A.TIME_IN <= D.LATE_CUTOFF) THEN ''L''    
--WHEN  (A.TIME_IN > D.LATE_CUTOFF) AND (A.TIME_IN <= A.HALFDAY_CUTOFF) THEN ''H''    
--WHEN  (A.TIME_IN > A.HALFDAY_CUTOFF) THEN ''LV''    
--END) +    

---- OUTGOING STATUS    
--(CASE WHEN  (A.TIME_OUT >= A.SHIFT_TIME_OUT) THEN ''O''    
--WHEN  (A.TIME_OUT < A.SHIFT_TIME_OUT) AND (A.TIME_OUT >= D.EARLY_CUTOFF) THEN ''E''    
--WHEN  (A.TIME_OUT < D.EARLY_CUTOFF) AND (A.TIME_OUT >= A.HALFDAY_CUTOFF) THEN ''H''    
--WHEN  (A.TIME_OUT < A.HALFDAY_CUTOFF) THEN ''LV''    
--END)     
--END)     
--END)AS ABSENT_STATUS, 

 DBO.FN_GETEMP_ATDSTATUS(A.EMP_ID,ATTENDANCE_DT,A.LOG_ABSENT_STATUS,D.SHIFT_TIME_IN,
                         D.SHIFT_TIME_OUT,A.TIME_IN,A.TIME_OUT,D.EARLY_CUTOFF,
                         D.LATE_CUTOFF,D.HALFDAY_CUTOFF,
                         B.WEEKLY_OFF1) AS ABSENT_STATUS,
	


D.SHIFT_NAME, C.DEPARTMENT_ID, C.DEPARTMENT_NAME, A.* 
                        FROM EMP_ATTENDANCE A 
                        JOIN EMP_MST B (NOLOCK) ON A.EMP_ID = B.EMP_ID
                        JOIN EMP_DEPARTMENT C (NOLOCK) ON B.DEPARTMENT_ID = C.DEPARTMENT_ID
                        JOIN EMP_SHIFTS D (NOLOCK) ON A.SHIFT_ID = D.SHIFT_ID
                        WHERE A.ATTENDANCE_DT = ''' + @CVALUE1 + ''' ' + @CVALUE2 + '
                        ORDER BY B.EMP_FNAME, B.EMP_LNAME, A.TIME_IN, A.TIME_OUT'
END
-----------------------------        
IF(@CQUERYID = 248)
BEGIN
SET @CQUERY = N'SELECT LOAN_ID FROM EMP_PAYSLIP_DET A 
				WHERE A.PAYSLIP_ID = ''' + @CVALUE1 + ''' AND LOAN_ID <> ''0000000'''
END
-----------------------------        
IF(@CQUERYID = 249)
BEGIN
SET @CQUERY = N'SELECT 1 AS [CHECK], A.EMP_ID, A.REF_ID, A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMP_NAME,         
                               B.DEPARTMENT_NAME, A.SHIFT_ID, C.SHIFT_NAME, A.DEPT_ID, A.WEEKLY_OFF1, 
                               A.WEEKLY_OFF2 FROM EMP_MST A         
                               JOIN EMP_DEPARTMENT B (NOLOCK) ON A.DEPARTMENT_ID = B.DEPARTMENT_ID        
                               JOIN EMP_SHIFTS C (NOLOCK) ON A.SHIFT_ID = C.SHIFT_ID
                               JOIN LOCATION D (NOLOCK) ON A.DEPT_ID = D.DEPT_ID ' + @CVALUE1 + '
                               ORDER BY B.DEPARTMENT_NAME, A.EMP_FNAME'
END
-----------------------------        
IF(@CQUERYID = 250)
BEGIN
SET @CQUERY = N'SELECT COUNT(*) FROM EMP_ATTENDANCE 
				WHERE EMP_ID IN (' + @CVALUE1 + ') AND MONTH(ATTENDANCE_DT) = ''' + @CVALUE2 + ''' 
				AND YEAR(ATTENDANCE_DT) = ''' + @CVALUE3 + ''''
END
-----------------------------        
IF(@CQUERYID = 251)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMP ' + @CVALUE1 + ''
END
-----------------------------        
IF(@CQUERYID = 252)
BEGIN
SET @CQUERY = N'SELECT EMP_FNAME + '' '' + EMP_LNAME AS EMPLOYEE_NAME,REF_ID AS EMPLOYEE_ID,EMP_ID 
                                FROM EMP_MST WHERE EMP_ID <> ''0000000'''
END
-----------------------------        
IF(@CQUERYID = 253)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_ATTREGISTER ' + @CVALUE1 + '
                ORDER BY MONTH_NO,DEPT_ID,DEPARTMENT_NAME,REF_ID,ATTENDANCE_DT'
END
-----------------------------        
IF(@CQUERYID = 254)
BEGIN
SET @CQUERY = N'SELECT DISTINCT CO_ALIAS FROM EMP_MST WHERE CO_ALIAS <> '''' ORDER BY CO_ALIAS'
END
-----------------------------        
IF(@CQUERYID = 255)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.EMP_ID,A.REF_ID,A.REF_ID + '' '' + A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMPNAME,
                        A.DEPT_ID,C.DEPT_NAME,B.DEPARTMENT_ID,B.DEPARTMENT_NAME,VW.ATTMONTH,VW.MONTH_NO
                        FROM VW_ATTREGISTER VW 
                        INNER JOIN EMP_MST A ON VW.EMP_ID = A.EMP_ID
                        JOIN EMP_DEPARTMENT B ON A.DEPARTMENT_ID =B.DEPARTMENT_ID
                        JOIN LOCATION C ON A.DEPT_ID=C.DEPT_ID
                        WHERE A.EMP_ID <> '''' ' + @CVALUE1 + ' AND MONTH(VW.ATTENDANCE_DT)=
                        ''' + @CVALUE2 + ''' ' + @CVALUE3 + ' 
                        ORDER BY C.DEPT_NAME,B.DEPARTMENT_NAME,A.REF_ID,VW.MONTH_NO'
END
-----------------------------        
IF(@CQUERYID = 256)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.EMP_ID,A.REF_ID,A.REF_ID + '' '' + A.EMP_FNAME + '' '' + A.EMP_LNAME AS EMPNAME,
                        A.DEPT_ID,C.DEPT_NAME,B.DEPARTMENT_ID,B.DEPARTMENT_NAME,VW.ATTMONTH,VW.MONTH_NO
                        FROM VW_ATTREGISTER VW 
                        INNER JOIN EMP_MST A ON VW.EMP_ID =A.EMP_ID
                        JOIN EMP_DEPARTMENT B ON A.DEPARTMENT_ID =B.DEPARTMENT_ID
                        JOIN LOCATION C ON A.DEPT_ID=C.DEPT_ID
                        WHERE A.EMP_ID <> '''' ' + @CVALUE1 + ' 
                        ORDER BY C.DEPT_NAME,B.DEPARTMENT_NAME,A.REF_ID,VW.MONTH_NO'
END
-----------------------------        
IF(@CQUERYID = 257)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_PFESI WHERE EMP_ID <> '''' ' + @CVALUE1 + ' 
                            AND PAYSLIP_MONTH = ''' + @CVALUE2 + ''' AND PAYSLIP_YEAR = ''' + @CVALUE3 + ''''
END
-----------------------------        
IF(@CQUERYID = 258)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_PFESI WHERE EMP_ID <> '''' ' + @CVALUE1 + '' 
END
-----------------------------        
IF(@CQUERYID = 259)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.EMP_ID, A.REF_ID, A.REF_ID + '' '' + A.EMP_FNAME + '' '' + A.EMP_LNAME 
              AS EMPNAME, A.DEPT_ID, C.DEPT_NAME, B.DEPARTMENT_ID, B.DEPARTMENT_NAME,VW.ATTMONTH,
              VW.MONTH_NO,VW.AC_MONTH_NO,VW.YEAR
              FROM VW_ATTREGISTER VW 
              INNER JOIN EMP_MST A ON VW.EMP_ID =A.EMP_ID
              JOIN EMP_DEPARTMENT B ON A.DEPARTMENT_ID =B.DEPARTMENT_ID
              JOIN LOCATION C ON A.DEPT_ID=C.DEPT_ID ' + @CVALUE1 + ' 
              ORDER BY VW.MONTH_NO, C.DEPT_NAME,B.DEPARTMENT_NAME,A.REF_ID'
END
-----------------------------        
IF(@CQUERYID = 260)
BEGIN
SET @CQUERY = N'SELECT * FROM EMP_LEAVE_CREDIT    
                WHERE MONTH = ''' + @CVALUE1 + ''' AND YEAR = ''' + @CVALUE2 + ''' AND EMP_ID=''' + @CVALUE3 + ''''
END
-----------------------------        
IF(@CQUERYID = 261)
BEGIN
--SET @CQUERY = N'SELECT * FROM VW_ATTSUMMARY WHERE EMP_ID=''' + @CVALUE1 + ''' 
--				AND ATT_MONTH = ''' + @CVALUE2 + ''' AND ATT_YEAR=''' + @CVALUE3 + ''' ORDER BY EMP_ID'
				

				
SET @CQUERY = N'SELECT YEAR(ATTENDANCE_DT) AS ATT_YEAR, MONTH(ATTENDANCE_DT) AS ATT_MONTH, EMP_ID,   
SUM(CASE WHEN REPLACE(ATTSTATUS,''W'','''')=''P'' THEN 1 ELSE 0 END) AS P,  
SUM(CASE WHEN ATTSTATUS LIKE ''%H%'' THEN 1 ELSE 0 END) AS H,  
SUM(CASE WHEN ATTSTATUS LIKE ''%E%'' THEN 1 ELSE 0 END) AS E,  
SUM(CASE WHEN ATTSTATUS LIKE ''%L%'' AND ATTSTATUS NOT LIKE ''%LV%'' THEN 1 ELSE 0 END) AS L,  
SUM(CASE WHEN REPLACE(ATTSTATUS,''W'','''')='''' AND (ATTSTATUS = ''W'') THEN 1 ELSE 0 END) AS W,  
SUM(CASE WHEN REPLACE(ATTSTATUS,''W'','''')=''A'' THEN 1 ELSE 0 END) AS A,  
SUM(CASE WHEN ATTSTATUS LIKE ''%LV%'' THEN 1 ELSE 0 END) AS LV, 
SUM(CASE WHEN ATTSTATUS LIKE ''%B%'' THEN 1 ELSE 0 END) AS B, 
DEPT_ID, 
DEPARTMENT_ID, CO_ALIAS
FROM VW_ATTREGISTER  
WHERE EMP_ID= '''+@CVALUE1+''' AND  ATTENDANCE_DT BETWEEN '''+@CVALUE2+''' AND '''+@CVALUE3+'''
AND MONTH(ATTENDANCE_DT) = ''' + @CVALUE4 + ''' AND YEAR(ATTENDANCE_DT) =''' + @CVALUE5 + '''
GROUP BY YEAR(ATTENDANCE_DT), MONTH(ATTENDANCE_DT), EMP_ID, DEPT_ID, DEPARTMENT_ID, CO_ALIAS  
ORDER BY EMP_ID '
				
				
				
				
				
END
-----------------------------        
IF(@CQUERYID = 262)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMPATTVIEWER WHERE ATTENDANCE_DT BETWEEN ''' + @CVALUE1 + ''' 
				AND ''' + @CVALUE2 + ''' AND ((TIME_IN <> ''1900-01-01 00:00:00.000'' 
				AND TIME_OUT <> ''1900-01-01 00:00:00.000'' ) OR (TIME_IN <> ''1900-01-01 00:00:00.000'' 
				AND TIME_OUT =''1900-01-01 00:00:00.000'') OR (TIME_IN = ''1900-01-01 00:00:00.000'' 
				AND TIME_OUT <> ''1900-01-01 00:00:00.000''))  ' + @CVALUE3 + ' ORDER BY ATTENDANCE_DT'
END
-----------------------------        
IF(@CQUERYID = 263)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_LOANANDADV WHERE LOAN_DATE BETWEEN  ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + ''' 
				' + @CVALUE3 + ''
END
-----------------------------        
IF(@CQUERYID = 264)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_LOCCASHFLOW_REP WHERE PAYSLIP_MONTH = ''' + @CVALUE1 + ''' 
                        AND PAYSLIP_YEAR = ''' + @CVALUE2 + ''' ' + @CVALUE3 + ' ORDER BY DEPT_ID'
END
-----------------------------        
IF(@CQUERYID = 265)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMP_INCOMPLETE_ENTRIES WHERE ATTENDANCE_DT BETWEEN ''' + @CVALUE1 + ''' 
				AND ''' + @CVALUE2 + ''' ' + @CVALUE3 + ' ORDER BY DEPT_ID, EMP_ID, ATTENDANCE_DT'
END
-----------------------------        
IF(@CQUERYID = 266)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_CASHREPORT WHERE  PAYSLIP_MONTH = ''' + @CVALUE1 + ''' 
                        AND PAYSLIP_YEAR=''' + @CVALUE2 + ''' ' + @CVALUE3 + '
                        ORDER BY PAYSLIP_YEAR, PAYSLIP_MONTH, DEPT_ID, REF_ID'
END
-----------------------------        
IF(@CQUERYID = 267)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.EMP_ID,A.REF_ID,A.EMPNAME,A.BASIC_SALARY,
                            A.DEPT_ID,A.DEPT_NAME,A.DEPARTMENT_ID,A.DEPARTMENT_NAME,A.DEPT_ID,A.DEPT_NAME,
                            A.PF_ENABLED,A.ESI_ENABLED, A.PF_AMOUNT
                            FROM VW_EMPDETAILS_REP A WHERE A.EMP_ID <> '''' ' + @CVALUE1 + ' ORDER BY A.REF_ID'
END
-----------------------------        
IF(@CQUERYID = 268)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMPDETAILS_REP WHERE EMP_ID = ''' + @CVALUE1 + ''' '
END
-----------------------------        
IF(@CQUERYID = 269)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_SALARY ORDER BY EMP_ID'
END
-----------------------------        
IF(@CQUERYID = 270)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.CO_ALIAS, A.EMP_ID,A.REF_ID,
                        B.REF_ID + '' '' + B.EMP_FNAME + '' '' + B.EMP_LNAME AS EMPNAME,
                        A.BASIC_SALARY, A.DEPT_ID,A.DEPT_NAME,A.DEPARTMENT_ID,A.DEPARTMENT_NAME,A.ARREAR_AMT,
                        A.MODE_OF_PAYMENT, 0 AS ACTUAL_SAL, A.WORK_DAYS FROM VW_SALSHEET A 
                        JOIN EMP_MST B ON A.EMP_ID = B.EMP_ID 
                        WHERE A.PAYSLIP_ID <> '''' AND PAYSLIP_MONTH = ''' + @CVALUE1 + ''' AND PAYSLIP_YEAR = ''' + @CVALUE2 + '''
                        ' + @CVALUE3 + ' ORDER BY A.CO_ALIAS, A.REF_ID'
END
-----------------------------        
IF(@CQUERYID = 271)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.EMP_ID, A.REF_ID, 
                        B.REF_ID + '' '' + B.EMP_FNAME + '' '' + B.EMP_LNAME AS EMPNAME, A.BASIC_SALARY,
                        A.DEPT_ID,A.DEPT_NAME,A.DEPARTMENT_ID,A.DEPARTMENT_NAME,A.MODE_OF_PAYMENT 
                        FROM VW_EMPDETAILS_REP A 
                        JOIN EMP_MST B ON A.EMP_ID=B.EMP_ID WHERE A.EMP_ID <> '''' ' + @CVALUE1 + ' 
                        ORDER BY A.REF_ID'
END
-----------------------------        
IF(@CQUERYID = 272)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMPDETAILS_REP WHERE EMP_ID <> '''' ' + @CVALUE1 + ' ORDER BY CO_ALIAS, DEPT_NAME, REF_ID, PAY_ORDER'
END
-----------------------------        
IF(@CQUERYID = 273)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMPMOVEMENT WHERE EMP_ID <> '''' AND ( ATTENDANCE_DT 
				BETWEEN ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + ''' ) ' + @CVALUE3 + '
                ORDER BY EMP_ID, ATTENDANCE_DT,TIME_IN,TIME_OUT'
END
-----------------------------        
IF(@CQUERYID = 274)
BEGIN
SET @CQUERY = N'SELECT DESIG_ID,DESIG_NAME FROM EMP_DESIG WHERE DESIG_ID<>''0000000'''
END
-----------------------------        
IF(@CQUERYID = 275)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMPATTVIEWER 
                        WHERE ATTENDANCE_DT BETWEEN ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + ''' 
                        ORDER BY ATTENDANCE_DT,EMP_FNAME,EMP_LNAME, TIME_IN,TIME_OUT'
END
-----------------------------        
IF(@CQUERYID = 276)
BEGIN
SET @CQUERY = N'SELECT * FROM VW_EMPATTVIEWER WHERE MONTH(ATTENDANCE_DT) = ''' + @CVALUE1 + ''' 
				AND EMP_ID = ''' + @CVALUE2 + ''' ORDER BY ATTENDANCE_DT,EMP_FNAME,EMP_LNAME, TIME_IN,TIME_OUT'
END
-----------------------------        
IF(@CQUERYID = 277)
BEGIN
SET @CQUERY = N'SELECT DISTINCT(MST_LOAN_ID) AS LOAN_ID FROM VW_LOANADVANCE ' + @CVALUE1 + ''
END
-----------------------------        
IF(@CQUERYID = 278)
BEGIN
SET @CQUERY = N'SELECT DISTINCT A.CO_ALIAS FROM EMP_MST A ORDER BY A.CO_ALIAS'
END
-----------------------------        
IF(@CQUERYID = 280)
BEGIN          
SET @CQUERY = N'SELECT EMP_ID ,REF_ID,REF_ID AS MST_MEMO_NO FROM HR_EMP_MST   
    WHERE EMP_ID <> ''0000000'' ORDER BY REF_ID'
    
END
-----------------------------        
IF (@CQUERYID = 281)  
BEGIN          
	SET @CQUERY = N'SELECT T0.*,T1.JOB_DESCRIPTION,T2.*  
					FROM HR_EMP_MST T0 
					LEFT OUTER JOIN HR_EMP_MST_PROFILE_DETAILS T1 ON T1.EMP_ID=T0.EMP_ID
					LEFT OUTER JOIN HR_EMP_MST_CONTACT_DETAILS T2 ON T2.EMP_ID =T0.EMP_ID 
					WHERE T0.EMP_ID = ''' + @CVALUE1 + '''' 
END          
-----------------------------
IF(@CQUERYID =282)
BEGIN
SET @CQUERY =N'SELECT T0.*, T3.AREA_NAME, T3.PINCODE,T4.CITY_CODE,T4.CITY ,T5.STATE_CODE,       
                 T5.STATE, T6.AREA_NAME AS MAILING_AREA_NAME,T7.CITY_CODE AS MAILING_CITY_CODE,          
                 T7.CITY AS MAILING_CITY,T9.STATE_CODE AS MAILING_STATE_CODE, T9.STATE AS MAILING_STATE,        
                 T6.PINCODE AS MAILING_PINCODE 
                 FROM HR_EMP_MST_CONTACT_DETAILS T0   
                LEFT OUTER JOIN AREA T3 ON T3.AREA_CODE = T0.AREA_CODE       
                LEFT OUTER JOIN CITY T4 ON T4.CITY_CODE = T3.CITY_CODE 
                LEFT OUTER JOIN AREA T6 ON T0.MAILING_AREA_CODE = T6.AREA_CODE       
                LEFT OUTER JOIN CITY T7 ON T7.CITY_CODE = T6.CITY_CODE  
                LEFT OUTER JOIN STATE T9 ON T7.STATE_CODE=T9.STATE_CODE     
                LEFT OUTER JOIN STATE T5 ON T5.STATE_CODE = T4.STATE_CODE WHERE T0.EMP_ID = ''' + @CVALUE1 + ''''
     
END 
------------------------------
IF(@CQUERYID =283)
BEGIN
SET @CQUERY=N'SELECT T0.*,T1.DEPT_NAME,T1.DEPT_ID,T2.DEPARTMENT_NAME,T2.DEPARTMENT_ID,T3.DESIG_ID,T3.DESIG_NAME,
               T4.SHIFT_NAME,T4.SHIFT_ID FROM HR_EMP_MST_PROFILE_DETAILS T0
               LEFT JOIN EMP_DEPARTMENT T2 ON T2.DEPARTMENT_ID = T0.DEPARTMENT_ID
               LEFT JOIN LOCATION T1 ON T1.DEPT_ID =T0.DEPT_ID
               LEFT JOIN EMP_DESIG T3 ON T3.DESIG_ID = T0.DESIG_ID
               LEFT JOIN EMP_SHIFTS T4 ON T4.SHIFT_ID =T0.SHIFT_ID 
               WHERE T0.EMP_ID ='''+@CVALUE1+''''        
                         

END
------------------------------
IF(@CQUERYID =284)
BEGIN
SET @CQUERY =N'SELECT *,
				(CASE MODE_OF_PAYMENT WHEN  0 THEN ''CHEQUE'' WHEN 1 THEN ''SELF CHEQUE'' WHEN 2 THEN ''CASH'' WHEN 3 THEN ''BANK'' END) AS PAY_MODE 
				FROM HR_EMP_MST_SALARY_DETAILS WHERE EMP_ID='''+@CVALUE1+''''
END
-----------------------------  

IF(@CQUERYID =285)
BEGIN
SET @CQUERY =N'SELECT * FROM HR_EMP_DOCS_MST WHERE EMP_ID='''+@CVALUE1+''''
END

-----------------------------    
  
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
  SELECT 	 'SP_WIZPAYMODULEPROC:'+STR(@CQUERYID) AS SP_NAME,@DSTARTTIME AS START_TIME,GETDATE() AS  END_TIME 

 
END
