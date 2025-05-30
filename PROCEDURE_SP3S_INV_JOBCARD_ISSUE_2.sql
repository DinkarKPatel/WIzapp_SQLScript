CREATE PROCEDURE [DBO].[SP3S_INV_JOBCARD_ISSUE_2]          
(          
  @IMODE INT ,          
  @CWHERE VARCHAR(MAX)='',      
  @CAGENCYCODE VARCHAR(20)='',      
  @FINYEAR VARCHAR(10)=''  ,    
  @DEPTID VARCHAR(10)='' ,
  @NRETURNMODE INT=0
          
)      
----WITH ENCRYPTION
AS          
          
BEGIN        
 DECLARE @CCMD NVARCHAR(MAX)         
--LBLMST: 2         
	SELECT A.*,B.*,--C.JOB_NAME,
	'' AS ADDRESS_F,U.USERNAME AS USER_NAME,  
	U1.USERNAME AS EDT_USER_NAME ,BIN.BIN_NAME  
	,MST.ISSUE_NO AS JOBWORK_ISSUE_NO,MST.ISSUE_DT AS JOBWORK_ISSUE_DT  ,
	A.location_Code   as source_dept_id
	FROM BOM_ISSUE_MST A (NOLOCK)             
	JOIN PRD_AGENCY_MST B (NOLOCK) ON A.AGENCY_CODE = B.AGENCY_CODE             
	--JOIN JOBS C (NOLOCK) ON A.COMPANY_CODE = C.COMPANY_CODE            
	LEFT OUTER JOIN USERS U (NOLOCK) ON U.USER_CODE = A.USER_CODE     
	LEFT OUTER  JOIN USERS U1 (NOLOCK) ON U1.USER_CODE = A.EDT_USER_CODE   
	LEFT OUTER JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID
	LEFT OUTER JOIN JOBWORK_ISSUE_MST MST (NOLOCK) ON MST.ISSUE_ID= A.JOBWORK_ISSUE_ID      
	WHERE A.ISSUE_ID = @CWHERE             
       
END
