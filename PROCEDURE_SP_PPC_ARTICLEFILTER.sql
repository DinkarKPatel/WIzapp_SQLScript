CREATE PROCEDURE SP_PPC_ARTICLEFILTER               
(              
 @NMODE     INT, --(0)-FILL DROPDOWN 'SECTION_CODE, SECTION_NAME' (1) - VIEW FILTER DATA (2) - VIEW SECTION_CODE WISE              
 @SECTION_CODE   VARCHAR(9)='',                        
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
   SET @CCMD=N'SELECT SECTION_CODE, SECTION_NAME           
      FROM [SECTIONM]              
      WHERE ISNULL(INACTIVE, 0) = 0              
      ORDER BY SECTION_CODE DESC'              
   PRINT @CCMD              
   EXEC SP_EXECUTESQL @CCMD              
  END              
                
  SET @CSTEP = 10              
  IF (@NMODE=1)              
  BEGIN              
   SET @CCMD=N'SELECT DISTINCT SUB_SECTION_CODE, SUB_SECTION_NAME           
      FROM [SECTIONM]AS SM INNER JOIN [SECTIOND] AS SD  ON SM.SECTION_CODE=SD.SECTION_CODE
       WHERE (''' +RTRIM(LTRIM(@SECTION_CODE)) + '''='''' OR  SD.SECTION_CODE = ''' + @SECTION_CODE + ''') '          
           
   PRINT @CCMD              
   
   EXEC SP_EXECUTESQL @CCMD              
  END              
                
           
                
 END TRY                
 BEGIN CATCH                
  SET @ERRMSG_OUT='ERROR: [P]: SP_PPC_ARTICLEFILTER, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()              
  PRINT @ERRMSG_OUT              
                
  GOTO END_PROC                
 END CATCH                 
              
END_PROC:                
 IF  ISNULL(@ERRMSG_OUT,'')=''               
  SET @ERRMSG_OUT = ''              
END
