CREATE PROCEDURE SP_ARS_FILTER
(
@DFROMDATE DATETIME,
@DTODATE DATETIME,
--@ARS_ID VARCHAR(50)='',
@PLAN_NAME VARCHAR(50)='',
@SESSION_ID VARCHAR(50)=''
) 
--WITH ENCRYPTION
AS
BEGIN
DECLARE @CMD VARCHAR(MAX)
SET @CMD='SELECT PLAN_NAME,ARS_ID MEMO_NO,S.SEASON_NAME 
FROM ARS_MST A (NOLOCK) 
JOIN SEASON_MST S (NOLOCK) ON A.SEASON_ID=S.SEASON_ID
WHERE CONVERT(DATE,A.LAST_UPDATE) BETWEEN '''+REPLACE(CONVERT(VARCHAR,@DFROMDATE,102),'.','-')+''' AND '''+REPLACE(CONVERT(VARCHAR,@DTODATE,102),'.','-')+''''
--+CASE WHEN ISNULL(@ARS_ID,'') ='' THEN '' ELSE ' AND ARS_ID='''+@ARS_ID+'''' END
+CASE WHEN ISNULL(@PLAN_NAME,'') ='' THEN '' ELSE ' AND PLAN_NAME='''+@PLAN_NAME+'''' END
+CASE WHEN ISNULL(@SESSION_ID,'') ='' THEN '' ELSE ' AND A.SEASON_ID='''+@SESSION_ID+'''' END
PRINT @CMD
EXEC(@CMD)
END
--END OF PROCEDURE - SP_ARS_FILTER
