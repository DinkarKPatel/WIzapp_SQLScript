CREATE PROCEDURE SP3S_JOB_RATE
(
	@NQUERYID	INT,
	@CJOBCODE	VARCHAR(50)
)	
AS
BEGIN
	IF(@NQUERYID=10)
	BEGIN
		SELECT  CAST(0 AS INT) AS SR_ORDER,JOB_CODE,'----[SELECT A JOB]----' AS JOB_NAME 
		FROM JOBS (NOLOCK)  WHERE JOB_CODE='0000000'
		UNION
		SELECT CAST(1 AS INT) AS SR_ORDER,JOB_CODE,JOB_NAME FROM JOBS (NOLOCK)  
		WHERE JOB_NAME<>'' AND JOB_CODE<>'0000000'
		ORDER BY SR_ORDER,JOB_NAME
	END
	IF(@NQUERYID=20)
	BEGIN
		SELECT A.*,ART.ARTICLE_NO, ART.ARTICLE_NAME,         
		PARA1_NAME,PARA2_NAME,PARA3_NAME,UOM_NAME, SM.SECTION_NAME, SD.SUB_SECTION_NAME,             
		E.UOM_CODE,JOBS.JOB_NAME ,JW.AGENCY_NAME 
		FROM JOB_RATE_DET A
		JOIN ARTICLE ART ON A.ARTICLE_CODE = ART.ARTICLE_CODE          
		JOIN SECTIOND SD ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE        
		JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE        
		JOIN PARA1 P1 ON A.PARA1_CODE = P1.PARA1_CODE          
		JOIN PARA2 P2 ON A.PARA2_CODE = P2.PARA2_CODE          
		JOIN PARA3 P3 ON A.PARA3_CODE = P3.PARA3_CODE          
		JOIN UOM E ON ART.UOM_CODE = E.UOM_CODE       
		JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE=A.JOB_CODE 
		LEFT OUTER JOIN  PRD_AGENCY_MST JW (NOLOCK) ON JW.AGENCY_CODE=A.AGENCY_CODE 
		WHERE ISNULL(A.AGENCY_CODE,'')='' AND A.JOB_CODE=@CJOBCODE
	END
	ELSE IF(@NQUERYID=30)
	BEGIN
		SELECT A.*,ART.ARTICLE_NO, ART.ARTICLE_NAME,         
		PARA1_NAME,PARA2_NAME,PARA3_NAME,UOM_NAME, SM.SECTION_NAME, SD.SUB_SECTION_NAME,             
		E.UOM_CODE,JOBS.JOB_NAME ,JW.AGENCY_NAME
		FROM JOB_RATE_DET A
		JOIN ARTICLE ART ON A.ARTICLE_CODE = ART.ARTICLE_CODE          
		JOIN SECTIOND SD ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE        
		JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE        
		JOIN PARA1 P1 ON A.PARA1_CODE = P1.PARA1_CODE          
		JOIN PARA2 P2 ON A.PARA2_CODE = P2.PARA2_CODE          
		JOIN PARA3 P3 ON A.PARA3_CODE = P3.PARA3_CODE          
		JOIN UOM E ON ART.UOM_CODE = E.UOM_CODE       
		JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE=A.JOB_CODE 
		JOIN  PRD_AGENCY_MST JW (NOLOCK) ON JW.AGENCY_CODE=A.AGENCY_CODE
		WHERE  ISNULL(A.AGENCY_CODE,'')<>'' AND A.JOB_CODE=@CJOBCODE
	END
END
