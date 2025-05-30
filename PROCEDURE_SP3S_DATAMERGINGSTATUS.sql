CREATE PROCEDURE SP3S_DATAMERGINGSTATUS--(LocId 3 digit change by Sanjay:06-11-2024)
@CLOC VARCHAR(4)=''
AS
BEGIN

	 DECLARE @CCMD NVARCHAR(MAX)      
	 
	 DECLARE @CMTEMP TABLE ( LOCATION_ID VARCHAR(4),LOCATION VARCHAR(500),PHONE VARCHAR(50),LASTBILLNO CHAR(15),
							 LASTBILLDATE DATETIME,LASTHANDSHAKEDATE DATETIME,OVERDUEDAYS INT)
	       
	 SET @CCMD=N'SELECT C.DEPT_ID AS DEPT_ID,C.DEPT_NAME AS LOCATION,C.PHONE AS PHONE ,''''AS LASTBILLNO,
					MAX(CM_DT) AS LASTBILLDATE,MAX(A.LAST_UPDATE)  AS LASTHANDSHAKEDATE,
					DATEDIFF(DAY,MAX(CM_DT),GETDATE()) AS OVERDUEDAYS
					FROM CMM01106 A (NOLOCK) JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=A.LOCATION_CODE
					WHERE substring(CM_NO,len(location_code)+3,1) <> ''N'' AND C.INACTIVE=0'
					+CASE @CLOC WHEN '' THEN '' ELSE ' AND C.DEPT_ID='''+@CLOC+'''' END
					+'GROUP BY C.DEPT_ID,C.DEPT_NAME,C.PHONE'
				    
	 PRINT @CCMD  
	 INSERT @CMTEMP ( LOCATION_ID,LOCATION,PHONE,LASTBILLNO,LASTBILLDATE,LASTHANDSHAKEDATE,OVERDUEDAYS )     
	 EXEC SP_EXECUTESQL @CCMD
	 
	 ;WITH CTE_MAXCMM AS
	 (
	 select T1.LASTBILLDATE,T1.LOCATION_ID,MAX(T2.CM_NO) AS MAXBILLNO from @CMTEMP t1
	 JOIN cmm01106 T2 (NOLOCK) ON t2.location_Code=T1.LOCATION_ID AND T2.CM_DT=T1.LASTBILLDATE
	 GROUP BY T1.LASTBILLDATE,T1.LOCATION_ID
	 )

	 UPDATE T1 SET T1.LASTBILLNO=MAXBILLNO FROM @CMTEMP T1
	 JOIN CTE_MAXCMM T2 (NOLOCK) ON t2.LOCATION_ID=T1.LOCATION_ID AND T2.LASTBILLDATE=T1.LASTBILLDATE


	 SELECT * FROM @CMTEMP
	 order by OVERDUEDAYS desc


END
