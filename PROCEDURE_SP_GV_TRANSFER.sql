CREATE PROCEDURE SP_GV_TRANSFER      
@NQUERYID NUMERIC (2,0),      
@CMEMOID VARCHAR(40),      
@CWHERE VARCHAR(500),      
@CPRODUCTCODE VARCHAR(50),      
@CFINYEAR VARCHAR(5),      
@NNAVMODE NUMERIC(2,0)  
-- WITH ENCRYPTION
     
AS      
BEGIN      
DECLARE @CCMD NVARCHAR(MAX)      
      
IF       
@NQUERYID = 1      
GOTO LBLNAVIGATE      
      
ELSE IF       
@NQUERYID = 2      
GOTO LBLGETMASTERS      
      
ELSE IF       
@NQUERYID = 3      
GOTO LBLGETDETAILS      
      
ELSE IF       
@NQUERYID = 4      
GOTO LBLGETFLOOR      
      
ELSE IF      
@NQUERYID = 5      
GOTO LBLGETPRODUCTLIST      
  
ELSE IF      
@NQUERYID = 6      
GOTO LBLMSTLIST   
      


LBLNAVIGATE:      
 EXECUTE SP_NAVIGATE 'GV_STKXFER_MST',@NNAVMODE,@CMEMOID,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID',@CWHERE      
GOTO LAST      
      
LBLGETMASTERS:      

  SELECT *, T3.DEPT_ID +'-'+T3.DEPT_NAME AS TARGET_DEPT_NAME        
  FROM GV_STKXFER_MST T1        
  JOIN LOCATION T3 ON T3.DEPT_ID = T1.TARGET_DEPT_ID        
  WHERE T1.MEMO_ID = @CMEMOID         
       
GOTO LAST      
      
LBLGETDETAILS:      
        
  SELECT D.*,S.*
  FROM GV_STKXFER_DET D      
  JOIN GV_STKXFER_MST M ON D.MEMO_ID = M.MEMO_ID       
  JOIN SKU_GV_MST S ON D.GV_SRNO = S.GV_SRNO       
  LEFT OUTER JOIN PMT_GV_MST P ON D.GV_SRNO = P.GV_SRNO      
  WHERE M.MEMO_ID = @CMEMOID   
 GOTO LAST      
      

LBLGETFLOOR:      
  IF  @CMEMOID=@CWHERE
	SELECT * FROM LOCATION       
	WHERE MAJOR_DEPT_ID = DEPT_ID AND INACTIVE = 0 
	AND DEPT_ID <> @CWHERE      
	ORDER BY DEPT_NAME  
  ELSE
	  SELECT * FROM LOCATION       
	  WHERE DEPT_ID=@CMEMOID
GOTO LAST      


LBLGETPRODUCTLIST:      
	SELECT * FROM SKU_GV_MST A (NOLOCK)
	JOIN PMT_GV_MST P (NOLOCK) ON P.GV_SRNO=A.GV_SRNO
	WHERE P.QUANTITY_IN_STOCK>0
GOTO LAST      

      
LBLMSTLIST:      
 SET @CCMD = N'SELECT T1.*, T3.BIN_NAME AS TARGET_FLOOR_NAME, T4.BIN_NAME AS SOURCE_FLOOR_NAME      
  FROM FLOOR_ST_MST T1      
  JOIN BIN T3 ON T3.BIN_ID = T1.TARGET_BIN_ID      
  JOIN BIN T4 ON T4.BIN_ID = T1.BIN_ID   
  WHERE T1.TARGET_BIN_ID = '''+ @CMEMOID +'''      
  '+ @CWHERE +''  
 PRINT @CCMD      
 EXEC SP_EXECUTESQL @CCMD      
       
GOTO LAST     
      
LAST:      
END
