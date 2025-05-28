create PROC SP_WIZPAYMODULEPROC_103
(        
 @CVALUE1 VARCHAR(MAX) = '',        
 @CVALUE2 VARCHAR(MAX) = '',        
 @CVALUE3 VARCHAR(MAX) = '' ,
 @CVALUE4 VARCHAR(MAX) = '' ,
 @CVALUE5 VARCHAR(MAX) = ''      
)      
--WITH ENCRYPTION  
 AS        
BEGIN        

   -- ATTENDANCE (ATTENDANCE LIST)        
	DECLARE @CWHERE1 VARCHAR(500),@CQUERY NVARCHAR(MAX)
	SET @CWHERE1 = (CASE WHEN @CVALUE3='' THEN 'C.REF_ID' ELSE @CVALUE3 END)     
	SET @CQUERY = N'SELECT  A.ATTENDANCE_DT ,A.EMP_ID,A.time_in,A.time_out,A.row_id,A.entry_mode
		,A.shift_id,A.shift_time_in,A.shift_time_out,A.halfday_cutoff,'''' as empimage
		,A.dept_id,'''' as empimage_out,A.modified,A.log_absent_status,A.remarks_in
		,A.last_update,A.att_remarks,A.remarks_out,A.sync, B.SHIFT_NAME,        
	   '''' AS HOLIDAY_NAME,
	   DATENAME (WEEKDAY,A.ATTENDANCE_DT) AS WEEK_NAME , (C.EMP_FNAME + '' '' + C.EMP_LNAME) AS EMP_NAME  
	
	FROM EMP_ATTENDANCE A            
	JOIN EMP_SHIFTS B    (NOLOCK) ON A.SHIFT_ID = B.SHIFT_ID            
	JOIN EMP_MST C     (NOLOCK) ON A.EMP_ID = C.EMP_ID  
	WHERE A.ATTENDANCE_DT BETWEEN ''' + @CVALUE1 + ''' AND ''' + @CVALUE2 + '''             
	AND C.EMP_STATUS = 0 AND C.REF_ID = '+ @CWHERE1 +' 
	AND ('''+@CVALUE4+'''='''' OR C.EMP_ID='''+@CVALUE4+''')
	ORDER BY A.EMP_ID, A.ATTENDANCE_DT, A.TIME_IN, A.TIME_OUT'       

	EXEC SP_EXECUTESQL @cQuery
 END        
