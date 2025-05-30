CREATE  PROC [DBO].[AGENCYVIEW]            
               
@JOBCODE VARCHAR(7),      
@AGENCYCODE VARCHAR(7)=''      
                   
AS                                   
BEGIN     
  
SELECT CAST(1 AS BIT ) AS CHK,AGENCY_NAME,JOB_CODE,B.JOB_RATE,A.AGENCY_CODE  
FROM PRD_AGENCY_MST A JOIN AGENCY_JOBS B ON A.AGENCY_CODE= B.AGENCY_CODE  
WHERE JOB_CODE= @JOBCODE  
UNION ALL  
SELECT CAST(0 AS BIT ) AS CHK,AGENCY_NAME,@JOBCODE AS JOB_CODE,0 AS HOB_RATE,AGENCY_CODE  
FROM PRD_AGENCY_MST  
WHERE AGENCY_CODE NOT IN (SELECT AGENCY_CODE FROM AGENCY_JOBS  WHERE JOB_CODE= @JOBCODE)  
AND AGENCY_CODE <> @AGENCYCODE  
  
END
