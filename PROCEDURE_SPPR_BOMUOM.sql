CREATE PROCEDURE SPPR_BOMUOM               
(              
 @NMODE     INT, --(0)-FILL DROPDOWN 'SECTION_CODE, SECTION_NAME' (1) - VIEW FILTER DATA (2) - VIEW SECTION_CODE WISE              
 @UOM_CODE   VARCHAR(9)='',              
 @UOM_NAME   VARCHAR(300)='',              
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
   SET @CCMD=N'SELECT CONVERSION_UOM_CODE, CONVERSION_UOM_NAME,INACTIVE            
      FROM [PPC_BOM_UOM]              
      WHERE ISNULL(INACTIVE, 0) = 0              
      ORDER BY CONVERSION_UOM_CODE DESC'              
   PRINT @CCMD              
   EXEC SP_EXECUTESQL @CCMD              
  END              
                
  SET @CSTEP = 10              
  IF (@NMODE=1)              
  BEGIN              
   SET @CCMD=N'SELECT CONVERSION_UOM_CODE, CONVERSION_UOM_NAME,                  
       CASE WHEN ISNULL(INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END AS INACTIVE FROM [PPC_BOM_UOM]               
      WHERE('''+ @UOM_CODE + '''='''' OR CONVERSION_UOM_CODE LIKE ''%' + @UOM_CODE + '%'')               
      AND ( ''' + @INACTIVE + ''' ='''' OR INACTIVE LIKE ''%' + @INACTIVE + '%'' )             
      ORDER BY CONVERSION_UOM_CODE DESC '              
                
   PRINT @CCMD              
   EXEC SP_EXECUTESQL @CCMD              
  END              
                
  SET @CSTEP = 20              
  IF (@NMODE=2)              
  BEGIN              
   SET @CCMD=N'SELECT CONVERSION_UOM_CODE, CONVERSION_UOM_NAME,                   
      CASE WHEN ISNULL(INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END AS INACTIVE FROM [PPC_BOM_UOM]              
      WHERE CONVERSION_UOM_CODE = ''' + @UOM_CODE + ''' '              
                
   PRINT @CCMD              
   EXEC SP_EXECUTESQL @CCMD              
  END              
                
 END TRY                
 BEGIN CATCH                
  SET @ERRMSG_OUT='ERROR: [P]: SPPR_BOMUOM, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()              
  PRINT @ERRMSG_OUT              
                
  GOTO END_PROC                
 END CATCH                 
              
END_PROC:                
 IF  ISNULL(@ERRMSG_OUT,'')=''               
  SET @ERRMSG_OUT = ''              
END
