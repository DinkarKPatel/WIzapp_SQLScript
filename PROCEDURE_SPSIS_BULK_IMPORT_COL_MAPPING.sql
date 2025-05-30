CREATE  PROCEDURE SPSIS_BULK_IMPORT_COL_MAPPING    
(    
 @cMAPPING_NAME VARCHAR(100)  ,
 @nMode		INT=0
)    
AS    
BEGIN
DECLARE @cXTYPE VARCHAR(50),@cMAPPING_NAME_CONFIG VARCHAR(500)
DECLARE @DT1  TABLE (MASTER_COL VARCHAR(100),MASTER_COL_EXPR VARCHAR(100),MAPPED_COL VARCHAR(100), MANDATORY VARCHAR(2))  
SET @cXTYPE ='SLSIMP'

 SELECT @cMAPPING_NAME_CONFIG= MAPPING_NAME
 FROM IMPORT_CONFIG_MST a(NOLOCK)    
 WHERE XN_TYPE='SLSIMP' AND MAPPING_NAME =@cMAPPING_NAME

 SET @cMAPPING_NAME_CONFIG =ISNULL(@cMAPPING_NAME_CONFIG,'')

IF @cMAPPING_NAME LIKE 'STOCK%' AND ISNULL(@cMAPPING_NAME_CONFIG,'')<>''
BEGIN
	SET @cXTYPE ='SLSIMP_STOCK'
	SET @cMAPPING_NAME_CONFIG ='STOCK_'+ISNULL(@cMAPPING_NAME_CONFIG,'')
END
IF @nMode=2
BEGIN
	SELECT DISTINCT DATA_START_FROM,EXCEL_DATE_FORMAT
	FROM IMPORT_CONFIG_MST a(NOLOCK)
	JOIN IMPORT_CONFIG_DET b(NOLOCK) ON b.MAPPING_CODE = a.MAPPING_CODE
	WHERE MAPPING_NAME = @cMAPPING_NAME_CONFIG
END
ELSE
BEGIN
 INSERT INTO @DT1    
 EXEC SP_EXCELDATA @XNTYPE=@cXTYPE
 SELECT DISTINCT MAPPING_NAME, a.MAPPING_CODE,EXCEL_date_format  ,DEFAULT_PARA_NAME,MAPPED_PARA_NAME AS MAPPED_COL,DT.MASTER_COL_EXPR    
 ,ISNULL(a.treat_as_csv,0) AS TREAT_AS_CSV,ISNULL(a.DATA_START_FROM,0) AS DATA_START_FROM, DT.*
 FROM IMPORT_CONFIG_MST a(NOLOCK)    
 JOIN IMPORT_CONFIG_DET b(NOLOCK) ON b.MAPPING_CODE = a.MAPPING_CODE    
 JOIN @DT1 DT ON DT.MASTER_COL=b.DEFAULT_PARA_NAME    
 WHERE MAPPING_NAME =@cMAPPING_NAME_CONFIG--CHARINDEX(MAPPING_NAME ,@cMAPPING_NAME)> 0
END
END    