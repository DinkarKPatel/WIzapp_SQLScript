CREATE PROCEDURE SP_NAVIGATE_GV
(
@CTABLENAME VARCHAR(100),
@SCHEMECODE CHAR(5)='',
@NNAVMODE INT
)
AS 
BEGIN

 DECLARE @CCMD NVARCHAR(MAX)
 
       IF @NNAVMODE=1 AND ISNULL(@SCHEMECODE,'')=''
       BEGIN
			    SET @CCMD=N'SELECT TOP 1 * FROM  '+@CTABLENAME+'
				            ORDER BY SCHEME_CODE ASC'
				 PRINT @CCMD
				 EXEC SP_EXECUTESQL @CCMD
       END

            
            
             
      IF @NNAVMODE=4 AND ISNULL(@SCHEMECODE,'')=''
      BEGIN
             SET @CCMD=N'SELECT TOP 1 * FROM  '+@CTABLENAME+'  
             ORDER BY SCHEME_CODE DESC'
             PRINT @CCMD
             EXEC SP_EXECUTESQL @CCMD
      END

             
             
      IF @NNAVMODE=2 AND ISNULL(@SCHEMECODE,'')<>''
      BEGIN
              SET @CCMD=N'SELECT TOP 1*  FROM  '+@CTABLENAME+'  WHERE SCHEME_CODE <'''+ @SCHEMECODE +'''
                          ORDER BY SCHEME_CODE ASC'
              PRINT @CCMD
              EXEC SP_EXECUTESQL @CCMD
      END

            
             
      IF @NNAVMODE=3 AND ISNULL(@SCHEMECODE,'')<>''
      BEGIN
 
             SET @CCMD=N'SELECT TOP 1 * FROM  '+@CTABLENAME+'  WHERE SCHEME_CODE > '''+ @SCHEMECODE +'''
                         ORDER BY SCHEME_CODE ASC'
             PRINT @CCMD
             EXEC SP_EXECUTESQL @CCMD
      END


END
