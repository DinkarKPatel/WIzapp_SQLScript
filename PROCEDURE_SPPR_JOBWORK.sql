CREATE PROCEDURE [DBO].[SPPR_JOBWORK]                   
(                  
 @NMODE     INT, --(0)-FILL DROPDOWN 'SECTION_CODE, SECTION_NAME' (1) - VIEW FILTER DATA (2) - VIEW SECTION_CODE WISE                  
 @JOB_CODE   VARCHAR(9)='',                  
 @JOB_NAME   VARCHAR(300)='',                  
 @INACTIVE    VARCHAR(5)='',                  
 @ERRMSG_OUT    VARCHAR(MAX) OUT                  
)                  
AS                  
BEGIN                  
 DECLARE @CSTEP INT, @CCMD NVARCHAR(MAX)                  
                   
 BEGIN TRY                  
  SET @ERRMSG_OUT = ''                  
                    
  SET @CSTEP = 5                  
  IF (@NMODE=0)                  
  BEGIN                  
   SET @CCMD=N'SELECT JOB_CODE, JOB_NAME                
      FROM [JOBS]                  
      WHERE ISNULL(INACTIVE, 0) = 0                  
      ORDER BY JOB_CODE DESC'                  
   PRINT @CCMD                  
   EXEC SP_EXECUTESQL @CCMD                  
  END                  
                    
  SET @CSTEP = 10                  
  IF (@NMODE=1)                  
  BEGIN                  
   SET @CCMD=N'SELECT JOB_CODE, JOB_NAME,INACTIVE  FROM (                  
       SELECT JOB_CODE, JOB_NAME,                   
       CASE WHEN ISNULL(INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END AS INACTIVE FROM [JOBS]) AS SQ_SECTION                  
      WHERE JOB_CODE LIKE ''%' + @JOB_CODE + '%''                   
      AND INACTIVE LIKE ''%' + @INACTIVE + '%''                  
      ORDER BY JOB_CODE DESC '                  
                    
   PRINT @CCMD                  
   EXEC SP_EXECUTESQL @CCMD                  
  END                  
                    
  SET @CSTEP = 20                  
  IF (@NMODE=2)                  
  BEGIN                  
   SET @CCMD=N'SELECT JOB_CODE, JOB_NAME,JOBRATE,PER_DAYS,                   
      CASE WHEN ISNULL(INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END AS INACTIVE FROM [JOBS]                  
      WHERE JOB_CODE = ''' + @JOB_CODE + ''' '                  
                    
   PRINT @CCMD                  
   EXEC SP_EXECUTESQL @CCMD                  
  END                  
                    
 END TRY                    
 BEGIN CATCH                    
  SET @ERRMSG_OUT='ERROR: [P]: SPPR_JOBWORK, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()                  
  PRINT @ERRMSG_OUT                  
                    
  GOTO END_PROC                    
 END CATCH                     
                  
END_PROC:                    
 IF  ISNULL(@ERRMSG_OUT,'')=''                   
  SET @ERRMSG_OUT = ''                  
END
