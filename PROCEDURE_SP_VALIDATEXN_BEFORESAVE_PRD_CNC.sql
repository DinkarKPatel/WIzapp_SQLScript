CREATE PROCEDURE SP_VALIDATEXN_BEFORESAVE_PRD_CNC  --(LocId 3 digit change by Sanjay:30-10-2024)
(  
 @NSPID   NUMERIC(5),  
 @CUSERCODE  NVARCHAR(10),  
 @NUPDATEMODE INT,  
 @CRETVAL  NVARCHAR(MAX) OUTPUT,  
 @BNEGSTOCKFOUND BIT OUTPUT  
)  
--WITH ENCRYPTION
AS  
BEGIN  
BEGIN TRY  
DECLARE @CCMD   NVARCHAR(MAX),  
  @NSTEP   INT,  
  @CDEPTID  VARCHAR(4) ,  
  @CTEMPICM  NVARCHAR(MAX),  
  @CTEMPICD  NVARCHAR(MAX),  
  @CTEMPDBNAME VARCHAR(50),  
  @CERRPRODUCTCODE VARCHAR(50)  
  
  
SET @NSTEP=0  
  
  SET @CTEMPDBNAME = (SELECT DBO.FN_GETTEMPDBNAME())
 
SET @NSTEP=1  
  
SET @CTEMPICM=@CTEMPDBNAME+'TEMP_PRD_ICM01106_'+LTRIM(RTRIM(STR(@NSPID)))  
SET @CTEMPICD=@CTEMPDBNAME+'TEMP_PRD_ICD01106_'+LTRIM(RTRIM(STR(@NSPID)))  
  
SET @NSTEP=2  
  
SELECT @CDEPTID= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
  
SET @CRETVAL=''  
  
--********************************************VALIDATION FOR ICM01106****************************************************  
SET @NSTEP=3  
--VALIDATING RECORD COUNT  
SET @CCMD=N'IF (SELECT COUNT(*) FROM '+@CTEMPICM+')=0  
    SET @CRETVAL1=''NO RECORD FOUND AT MASTER LEVEL..... CANNOT PROCEED'''  
  
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
 GOTO ATLAST  
  
			
SET @NSTEP=5  
--VALIDATING FINYEAR  
SET @CCMD=N'SELECT @CRETVAL1=(CASE WHEN ''01'' + LTRIM(RTRIM((DBO.FN_GETFINYEAR(CNC_MEMO_DT))))=FIN_YEAR THEN ''''   
   ELSE ''MEMO DATE IS NOT IN CURRENT FINANCIAL YEAR...CAN NOT PROCEED'' END)  
   FROM '+ @CTEMPICM   
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
GOTO ATLAST  
SET @NSTEP=6  
		
--VALIDATING CNC TYPE   
SET @CCMD=N'IF EXISTS (SELECT TOP 1 CNC_TYPE FROM '+ @CTEMPICM + N' WHERE CNC_TYPE NOT IN (1,2))  
    SET @CRETVAL1=''CANCELLATION/UNCANCELLATION MODE IS NOT CORRECT...CAN NOT PROCEED'''  
      
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
GOTO ATLAST  
  
SET @NSTEP=7  
--VALIDATING USER CODE  
IF @NUPDATEMODE=1  
BEGIN  
 SET @CCMD=N'UPDATE '+ @CTEMPICM + N' SET USER_CODE='''+@CUSERCODE+''' WHERE LTRIM(RTRIM(USER_CODE)) = '''''  
 EXEC SP_EXECUTESQL @CCMD  
  
END  
ELSE   
BEGIN  
 SET @CCMD=N'UPDATE '+ @CTEMPICM + N' SET USER_CODE='''+@CUSERCODE+''''-- WHERE LTRIM(RTRIM(ISNULL(EDT_USER_CODE,''''))) = '''''  
 EXEC SP_EXECUTESQL @CCMD  
END  
SET @NSTEP=8  
SET @CCMD=N'IF EXISTS (SELECT TOP 1 A.USER_CODE FROM '+ @CTEMPICM + N' A   
      LEFT OUTER JOIN USERS B ON B.USER_CODE=A.USER_CODE  
      WHERE B.USER_CODE IS NULL)  
    SET @CRETVAL1=''INVALID USER DETAILS FOUND....CAN NOT PROCEED'''  
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
 GOTO ATLAST  
			
SET @NSTEP=10  
--VALIDATING FORM  
SET @CCMD=N'UPDATE ' + @CTEMPICM +' SET DEPT_ID = (CASE WHEN LTRIM(RTRIM(DEPT_ID))='''' THEN '''+ @CDEPTID+ ''' ELSE DEPT_ID END)'  
EXEC SP_EXECUTESQL @CCMD  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
 GOTO ATLAST  
		
SET @NSTEP=11  
SET @CCMD=N'IF EXISTS (SELECT TOP 1 A.DEPT_ID FROM '+ @CTEMPICM + N' A   
      LEFT OUTER JOIN LOCATION B ON B.DEPT_ID=A.DEPT_ID  
      WHERE B.DEPT_ID IS NULL)  
    SET @CRETVAL1=''INVALID LOCATION DETAILS FOUND....CAN NOT PROCEED'''  
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
 GOTO ATLAST  
  
--**************************************************VALIDATION FOR PRD_ICD01106*****************************************************  
SET @NSTEP=12  
--VALIDATING RECORD COUNT  
SET @CCMD=N'IF NOT EXISTS (SELECT TOP 1 PRODUCT_UID FROM '+@CTEMPICD+') OR   
    NOT EXISTS (SELECT TOP 1 PRODUCT_UID FROM '+ @CTEMPICD + ' WHERE LTRIM(RTRIM(PRODUCT_UID))<>'''')  
    SET @CRETVAL1=''BLANK DETAILS CAN NOT BE SAVED..... PLEASE CHECK'''  
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
GOTO ATLAST  
  
SET @NSTEP=14  
--VALIDATING QUANTITY  
SET @CCMD=N'IF EXISTS (SELECT TOP 1 QUANTITY FROM '+@CTEMPICD+' A JOIN '+@CTEMPICM+' B ON A.CNC_MEMO_ID=B.CNC_MEMO_ID  
        WHERE QUANTITY<=0)  
   SET @CRETVAL1=''QUANTITY SHOULD NOT BE LESS THAN OR EQUAL TO ZERO..... CANNOT PROCEED'''  
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
GOTO ATLAST  
SET @NSTEP=15  
--VALIDATING DISCRETE ITEMS  
SET @CCMD=N'IF EXISTS (SELECT TOP 1 A.PRODUCT_UID  FROM '+@CTEMPICD+ ' A  
      JOIN PRD_SKU B ON B.PRODUCT_UID=A.PRODUCT_UID  AND B.WORK_ORDER_ID=''''
      JOIN ARTICLE C ON C.ARTICLE_CODE=B.ARTICLE_CODE  
      WHERE C.DISCON=1 AND A.QUANTITY<>ROUND(A.QUANTITY,0))  
    SET @CRETVAL1=''DISCRETE ITEMS CAN NOT BE HANDLED IN DECIMALS... CANNOT PROCEED'''  
EXEC SP_EXECUTESQL @CCMD,N'@CRETVAL1 NVARCHAR(MAX) OUTPUT',@CRETVAL1=@CRETVAL OUTPUT  
PRINT @CCMD  
IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
GOTO ATLAST  
  
  
SET @NSTEP=20  
--VALIDATING PRODUCT CODE  
SET @CCMD=N'SELECT TOP 1 @CERRPRODUCTCODE=A.PRODUCT_UID FROM '+@CTEMPICD+' A  
   LEFT OUTER JOIN PRD_SKU B ON B.PRODUCT_UID=A.PRODUCT_UID WHERE B.PRODUCT_UID IS NULL AND B.WORK_ORDER_ID='''''  

EXEC SP_EXECUTESQL @CCMD,N'@CERRPRODUCTCODE VARCHAR(50) OUTPUT',@CERRPRODUCTCODE OUTPUT  
  
IF ISNULL(@CERRPRODUCTCODE,'')<>''  
 SET @CRETVAL='INVALID ITEM CODE '+@CERRPRODUCTCODE+' FOUND..... CANNOT PROCEED'  
  
SET @NSTEP=22  
--VALIDATING PRODUCT CODE  
SET @CCMD=N'SELECT TOP 1 @CERRPRODUCTCODE=A.PRODUCT_UID FROM '+@CTEMPICD+' A  
   JOIN '+@CTEMPICM+' B ON A.CNC_MEMO_ID=B.CNC_MEMO_ID '  
EXEC SP_EXECUTESQL @CCMD,N'@CERRPRODUCTCODE VARCHAR(50) OUTPUT',@CERRPRODUCTCODE OUTPUT  
  
IF ISNULL(@CERRPRODUCTCODE,'')<>''  
 SET @CRETVAL='ITEM CODE '+@CERRPRODUCTCODE+' IS HAVING ZERO ADJUSTMENT VALUE..... CANNOT PROCEED'  
  
IF @NUPDATEMODE=2  
BEGIN  
 SET @NSTEP=25  
   
 IF OBJECT_ID('TEMPDB..#TMPSTOCKCHECK','U') IS NOT NULL   
  DROP TABLE #TMPSTOCKCHECK  
   
 SELECT PRODUCT_UID,QUANTITY_IN_STOCK INTO #TMPSTOCKCHECK FROM PRD_PMT WHERE 1=2  
   
 SET @CCMD=N'SELECT A.PRODUCT_UID,(A.QUANTITY_IN_STOCK+(CASE WHEN CNC_TYPE=1 THEN B.QUANTITY ELSE -B.QUANTITY END))  
    AS QUANTITY_IN_STOCK FROM PRD_PMT A  
    JOIN PRD_ICD01106 B ON A.PRODUCT_UID=B.PRODUCT_UID  
    JOIN '+@CTEMPICM+' C ON C.CNC_MEMO_ID=B.CNC_MEMO_ID  
    JOIN PRD_SKU D ON D.PRODUCT_UID=A.PRODUCT_UID AND D.WORK_ORDER_ID=''  
    JOIN ARTICLE E ON E.ARTICLE_CODE=D.ARTICLE_CODE  
    WHERE B.PRODUCT_UID NOT IN   
    (SELECT PRODUCT_UID FROM '+@CTEMPICD+') AND A.DEPARTMENT_ID = C.DEPARTMENT_ID
    AND (A.QUANTITY_IN_STOCK+(CASE WHEN CNC_TYPE=1 THEN B.QUANTITY ELSE -B.QUANTITY END))<0  
    AND E.STOCK_NA=0  
    UNION ALL  
    SELECT A.PRODUCT_UID,(A.QUANTITY_IN_STOCK+  
    (CASE WHEN CNC_TYPE=1 THEN B.QUANTITY ELSE -B.QUANTITY END)+  
    (CASE WHEN CNC_TYPE=1 THEN -C.QUANTITY ELSE C.QUANTITY END)) AS QUANTITY_IN_STOCK  
    FROM PRD_PMT A JOIN PRD_ICD01106 B ON A.PRODUCT_UID=B.PRODUCT_UID  
    JOIN '+@CTEMPICD+' C ON C.CNC_MEMO_ID=B.CNC_MEMO_ID AND C.PRODUCT_UID=B.PRODUCT_UID  
    JOIN PRD_ICM01106 D ON B.CNC_MEMO_ID=D.CNC_MEMO_ID  
    JOIN PRD_SKU E ON E.PRODUCT_UID=A.PRODUCT_UID AND E.WORK_ORDER_ID='' 
    JOIN ARTICLE F ON F.ARTICLE_CODE=E.ARTICLE_CODE      
    WHERE A.DEPARTMENT_ID = B.DEPARTMENT_ID
    AND (A.QUANTITY_IN_STOCK+      (CASE WHEN CNC_TYPE=1 THEN B.QUANTITY ELSE -B.QUANTITY END)+  
    (CASE WHEN CNC_TYPE=1 THEN -C.QUANTITY ELSE C.QUANTITY END))<0 AND F.STOCK_NA=0'  
 PRINT @CCMD  
 INSERT #TMPSTOCKCHECK   
 EXEC SP_EXECUTESQL @CCMD  
   
 IF EXISTS (SELECT TOP 1 PRODUCT_UID FROM #TMPSTOCKCHECK)      
 BEGIN  
  SET @CRETVAL='STOCK GOING NEGATIVE FOR FOLLOWING BARCODES....CAN NOT PROCEED'         
  SELECT *,@CRETVAL AS  ERRMSG FROM #TMPSTOCKCHECK  
  SET @BNEGSTOCKFOUND=1  
 END   
   
 GOTO ATLAST  
END  
  
  
SET @NSTEP=16  
SET @CRETVAL=''  
  
ATLAST:  

IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>''  
 SET @CRETVAL=ISNULL(@CRETVAL,'') +'(SP_VALIDATEXN_BEFORESAVE_PRD_CNC AT STEP :'+LTRIM(RTRIM(STR(@NSTEP)))+')'  
END TRY  

BEGIN CATCH  
 SET @CRETVAL=N'ERROR FOUND IN '+ISNULL(ERROR_PROCEDURE(),'SP_VALIDATEXN_BEFORESAVE_PRD_CNC ')+  
   'STEP :'+LTRIM(RTRIM(STR(@NSTEP)))  +' MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')  
END CATCH  
END  
--************************************ END OF PROCEDURE SP_VALIDATEXN_BEFORESAVE_PRD_CNC
