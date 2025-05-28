CREATE TRIGGER TRG_EMP_WPAYATT_AUTO_INSERT_EMP_ATTENDANCE    
ON EMP_WPAYATT    
FOR INSERT    
AS    
BEGIN    
    
DELETE FROM A    
FROM EMP_ATTENDANCE A    
JOIN inserted B ON B.emp_id=A.EMP_ID AND  DAY( A.[attendance_dt])=DAY(B.[IST_TIME]) AND MONTH( A.[attendance_dt])=MONTH(B.[IST_TIME])  AND YEAR( A.[attendance_dt])=YEAR(B.[IST_TIME])    
    
    
;WITH EMP_DETAILS    
AS    
(    
 SELECT A.emp_id,CAST( CONVERT(VARCHAR(50),a.ist_time,112) AS datetime) [DATE],CAST( CONVERT(VARCHAR(50),A.ist_time,114) AS datetime) AS [TIME]    
 FROM INSERTED A       
)    
,IN_TIME    
AS    
(    
 SELECT A.emp_id,CAST( CONVERT(VARCHAR(50),a.ist_time,112) AS datetime) [DATE],CAST( CONVERT(VARCHAR(50),A.ist_time,114) AS datetime) AS [TIME],(CASE A.TIME_STATUS WHEN 1 THEN 'I' ELSE 'O' END) AS [CHECK],1 AS MODE    
 ,1 AS ENTRY_ID,A.shift_id,A.location_id AS DEPT_ID,A.log_absent_status,A.REMARKS,A.empimage    
 FROM EMP_WPAYATT A       
 JOIN EMP_DETAILS C ON C.EMP_ID=A.emp_id AND DAY( A.[ist_time])=DAY(C.[DATE]) AND MONTH( A.[ist_time])=MONTH(C.[DATE])  AND YEAR( A.[ist_time])=YEAR(C.[DATE])    
 WHERE A.time_status=1    
)    
,OUT_TIME    
AS    
(    
 SELECT A.emp_id,CAST( CONVERT(VARCHAR(50),A.ist_time,112) AS datetime) [DATE],CAST( CONVERT(VARCHAR(50),A.ist_time,114) AS datetime) AS [TIME],(CASE A.TIME_STATUS WHEN 1 THEN 'I' ELSE 'O' END) AS [CHECK],1 AS MODE    
 ,2 AS ENTRY_ID,A.shift_id,A.location_id AS DEPT_ID,A.log_absent_status,A.REMARKS ,A.empimage    
 FROM EMP_WPAYATT A       
 JOIN EMP_DETAILS C ON C.EMP_ID=A.emp_id AND DAY( A.[ist_time])=DAY(C.[DATE]) AND MONTH( A.[ist_time])=MONTH(C.[DATE])  AND YEAR( A.[ist_time])=YEAR(C.[DATE])    
 WHERE A.time_status=2    
)    

INSERT EMP_ATTENDANCE( att_remarks, attendance_dt, dept_id, emp_id, empimage, empimage_out, entry_mode, halfday_cutoff, last_update, log_absent_status,     
modified, remarks_in , remarks_out, row_id, shift_id, shift_time_in, shift_time_out,  sync, time_in, time_out )      
SELECT    isnull(A.remarks,c.remarks) as att_remarks,isnull(A.[DATE],c.[date]) attendance_dt,isnull(A.dept_id,C.DEPT_ID), B.emp_id, 
A.empimage empimage, C.empimage AS empimage_out, 
ISNULL(A.ENTRY_ID,C.ENTRY_ID) as  entry_mode,     
halfday_cutoff, GETDATE() last_update, 
(CASE WHEN B.weekly_off1=DATENAME(WEEKDAY, A.[date]) THEN 1 WHEN A.[DATE]=CAST( CONVERT(VARCHAR(50),B.date_of_birth,112) AS datetime) 
THEN 4 ELSE A.log_absent_status END) AS log_absent_status,     
0 AS modified, ISNULL(A.REMARKS,'') AS remarks_in,isnull(C.REMARKS,'') AS remarks_out,NEWID() row_id, isnull(A.shift_id,C.shift_id), 
shift_time_in, shift_time_out,0 AS sync, 
isnull(A.[TIME],'') AS time_in,isnull(C.[TIME],'') AS time_out     
FROM EMP_MST B    (NOLOCK)  
JOIN EMP_SHIFTS B1 (NOLOCK) ON B1.SHIFT_ID = B.SHIFT_ID     
JOIN EMP_DETAILS B2 ON  B2.EMP_ID=B.emp_id     
LEFT JOIN OUT_TIME C ON C.EMP_ID=B.emp_id 
LEFT JOIN IN_TIME A  ON A.EMP_ID = B.EMP_ID      
    
END    
    
  