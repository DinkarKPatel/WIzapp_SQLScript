CREATE PROCEDURE [DBO].[SPPPC_FILL_PARA3]  
(  
 @NQUERYID   INT,    
 @VPARAMETER  VARCHAR(500)  
)  
AS      
BEGIN   
  
 DECLARE @CSTEP INT, @CCMD NVARCHAR(MAX), @ERRMSG_OUT VARCHAR(MAX)  
 BEGIN TRY  
  SET NOCOUNT ON;  
    
  SET @ERRMSG_OUT = ''  
    
  IF @NQUERYID = 1  
   -- GET PARA3 LIST  
   GOTO LBLGETPARA3LIST  
     
  ELSE IF @NQUERYID = 2  
   -- GET PARA3 USING LIKE  
   GOTO LBLGETPARA3LIKE  
    
  ELSE IF @NQUERYID = 7  
   -- GET INFO BY PARA3 NAME  
   GOTO LBLGETINFOBYPARA3NAME  
  
  ELSE  
   GOTO LAST  
  
-- GET PARA3 LIST  
LBLGETPARA3LIST:  
  SET @CSTEP = 101  
  SELECT A.PARA3_CODE, A.PARA3_NAME  
  FROM [PARA3] A (NOLOCK)   
  WHERE A.INACTIVE = 0  AND ISNULL(A.PARA3_NAME,'')<>''  
  ORDER BY A.PARA3_NAME  
    
  GOTO LAST  
  
  
-- GET PARA3 LIKE  
LBLGETPARA3LIKE:  
  SET @CSTEP = 102  
  SELECT TOP 10 A.PARA3_CODE, A.PARA3_NAME  
  FROM [PARA3] A (NOLOCK)   
  WHERE A.INACTIVE = 0  AND ISNULL(A.PARA3_NAME,'')<>''  
  AND A.PARA3_NAME LIKE '%'+ @VPARAMETER +'%'  
  ORDER BY A.PARA3_NAME  
    
  GOTO LAST  
  
  
-- GET INFO BY PARA3 NAME  
LBLGETINFOBYPARA3NAME:  
  SET @CSTEP = 107  
  
  IF NOT EXISTS (SELECT TOP 1 'U' FROM PARA3 WHERE PARA3_NAME =@VPARAMETER)
  BEGIN
	  EXEC SAVETRAN_PARA3 @PARA3_CODE='',@PARA3_NAME=@VPARAMETER,@ALIAS='',@INACTIVE=0,@REMARKS='',
	  @ERRMSG_OUT=@ERRMSG_OUT OUTPUT,@BDELETE=0
	  
  END
  ELSE
  BEGIN
      SELECT '' AS ERRMSG
  END
  
  SELECT A.PARA3_CODE, A.PARA3_NAME  
  FROM [PARA3] A (NOLOCK)   
  WHERE A.PARA3_NAME = @VPARAMETER  
    
  GOTO LAST  
    
LAST:     
 GOTO END_PROC  
  
  SET NOCOUNT OFF;  
 END TRY    
 BEGIN CATCH    
  SET @ERRMSG_OUT='ERROR: [P]: SPPPC_PARA3, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()  
  GOTO END_PROC    
 END CATCH     
  
END_PROC:    
 IF  ISNULL(@ERRMSG_OUT,'')<>''   
  SELECT @ERRMSG_OUT AS ERRORMSG  
END
