CREATE PROCEDURE [DBO].[SPPR_PARA2]           
(          
 @NMODE    INT, --(1) - VIEW FILTER DATA (2) - VIEW PARA2_CODE WISE          
 @PARA2_CODE   VARCHAR(9)='',          
 @PARA2_NAME   VARCHAR(300)='',          
 @PARA2_SET   VARCHAR(40)='',          
 @INACTIVE   VARCHAR(1)='',          
 @ERRMSG_OUT   VARCHAR(MAX) OUT          
)          
AS          
BEGIN          
 DECLARE @CSTEP INT, @CCMD NVARCHAR(MAX)          
           
 BEGIN TRY          
  SET @ERRMSG_OUT = ''          
            
  SET @CSTEP = 10          
  IF (@NMODE=1)          
  BEGIN          
   SET @CCMD=N'SELECT PARA2_CODE, PARA2_NAME, ALIAS, PARA2_SET, REMARKS,PARA2_ORDER,           
      CASE WHEN ISNULL(INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END AS INACTIVE FROM [PARA2]          
      WHERE PARA2_NAME LIKE ''%' + @PARA2_NAME + '%''          
      AND PARA2_SET LIKE ''%' + @PARA2_SET + '%'' '          
   IF @INACTIVE = 'Y'          
   BEGIN          
    SET @CCMD+=N' AND ISNULL(INACTIVE, 0)= 1 '          
   END          
   IF @INACTIVE = 'N'          
   BEGIN          
    SET @CCMD+=N' AND ISNULL(INACTIVE, 0)= 0 '          
   END          
   SET @CCMD+=N' ORDER BY PARA2_CODE DESC'            
            
   PRINT @CCMD          
   EXEC SP_EXECUTESQL @CCMD          
  END          
            
  SET @CSTEP = 20          
  IF (@NMODE=2)          
  BEGIN          
   SET @CCMD=N'SELECT PARA2_CODE, PARA2_NAME, ALIAS, PARA2_SET, REMARKS,PARA2_ORDER,           
      CASE WHEN ISNULL(INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END AS INACTIVE FROM [PARA2]          
      WHERE PARA2_CODE = ''' + @PARA2_CODE + ''' '          
          
   PRINT @CCMD          
   EXEC SP_EXECUTESQL @CCMD          
  END          
            
 END TRY            
 BEGIN CATCH            
  SET @ERRMSG_OUT='ERROR: [P]: SPPR_PARA2, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()          
  PRINT @ERRMSG_OUT          
            
  GOTO END_PROC            
 END CATCH             
          
END_PROC:            
 IF  ISNULL(@ERRMSG_OUT,'')=''           
  SET @ERRMSG_OUT = ''          
END
