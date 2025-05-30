
create PROCEDURE SP_BILLEMPLOYEECATEGORYWISE    
(      
 @CDEPTID CHAR(5)='',    
 @CEMPCODE CHAR(7)='',    
 @DFROMDT DATETIME,    
 @DTODT DATETIME,    
 @BESTIMATEENABLED BIT = 0,--- 0 FOR DETAIL 1 FOR SUMMARY DATA    
 @CUSERCODE VARCHAR(15)='',    
 @CBINID VARCHAR(10)=''    
)     
AS    
BEGIN    
    
 IF (@DFROMDT='' AND @DTODT='')    
 BEGIN    
  SET @DFROMDT=GETDATE()    
  SET @DTODT=GETDATE()    
 END    
    
 IF OBJECT_ID('TEMPDB..#CATEGORYWISEBILL','U') IS NOT NULL    
  DROP TABLE #CATEGORYWISEBILL    
     
 CREATE TABLE #CATEGORYWISEBILL (dept_id VARCHAR(5),LOCNAME VARCHAR(100),CM_DT DATETIME,CM_NO VARCHAR(100)    
 ,BILLAMOUNT NUMERIC(18,2),BILLQTY NUMERIC(14,3),SALEPERSON VARCHAR(100),CATEGORY_NAME VARCHAR(100)    
 ,CATEGORYPERCENT INT,SALEPERSON1 VARCHAR(100),CATEGORY_NAME1 VARCHAR(100),    
 CATEGORYPERCENT1 INT,EMP_CODE VARCHAR(100),EMP_CODE1 VARCHAR(100))    
     
 INSERT INTO #CATEGORYWISEBILL    
 (dept_id,LOCNAME,CM_DT,CM_NO,BILLAMOUNT,BILLQTY,SALEPERSON,CATEGORY_NAME,CATEGORYPERCENT,    
 SALEPERSON1,CATEGORY_NAME1,CATEGORYPERCENT1,EMP_CODE,EMP_CODE1)    
    
   SELECT a.location_Code , DEPT_NAME AS LOCATINNAME,CM_DT,CM_NO,    
   SUM(B.rfnet ) AS BILLAMOUNT,SUM(B.QUANTITY) AS BILLQTY,H.EMP_NAME AS SALEPERSON,CAT.CATEGORY_NAME,     
 (CASE WHEN B.EMP_CODE='0000000' THEN 0    
       WHEN (B.EMP_CODE<>B.EMP_CODE1) AND (B.EMP_CODE<>'0000000' AND B.EMP_CODE1='0000000')    THEN 100      
       WHEN  (B.EMP_CODE<>B.EMP_CODE1 AND H.CATEGORY_CODE=H1.CATEGORY_CODE) OR (B.EMP_CODE=B.EMP_CODE1) THEN 50      
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT.CATEGORY_NAME='A'  THEN 60      
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT.CATEGORY_NAME='B'  THEN 40      
       END)AS CATEGORYPERCENT,    
 H1.EMP_NAME AS SALEPERSON1,CAT1.CATEGORY_NAME AS CATEGORY_NAME1,    
        
   (CASE     
       WHEN B.EMP_CODE1='0000000' THEN 0    
       WHEN  (B.EMP_CODE<>B.EMP_CODE1) AND (B.EMP_CODE='0000000' AND B.EMP_CODE1<>'0000000')   THEN 100      
       WHEN  (B.EMP_CODE<>B.EMP_CODE1 AND H.CATEGORY_CODE=H1.CATEGORY_CODE) OR (B.EMP_CODE=B.EMP_CODE1) THEN 50      
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT1.CATEGORY_NAME='A'  THEN 60       
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT1.CATEGORY_NAME='B'  THEN 40      
    END)AS CATEGORYPERCENT1,H.EMP_CODE,H1.EMP_CODE AS EMP_CODE1   
     
     
 ----CONVERT(NUMERIC(18,2),    
 ----SUM(CASE WHEN B.EMP_CODE  <>'' AND B.EMP_CODE1<>'' AND B.EMP_CODE<>B.EMP_CODE1     
 ----AND CAT.CATEGORY_NAME='A'     
 ----THEN ((B.RFNET)/100)*50    
 ----WHEN B.EMP_CODE  <>'' AND B.EMP_CODE1<>'' AND B.EMP_CODE<>B.EMP_CODE1     
 ----AND CAT.CATEGORY_NAME IN ('A' ,'B') AND H.CATEGORY_CODE='HO00001'      
 ----THEN ((B.RFNET)/100)*60    
 ----WHEN B.EMP_CODE  <>'' AND B.EMP_CODE1<>'' AND B.EMP_CODE<>B.EMP_CODE1     
 ----AND CAT.CATEGORY_NAME IN ('A' ,'B') AND H.CATEGORY_CODE='HO00002'      
 ----THEN ((B.RFNET)/100)*40    
 ----WHEN B.EMP_CODE  <>'' AND B.EMP_CODE1<>'' AND B.EMP_CODE<>B.EMP_CODE1  AND CAT.CATEGORY_NAME='B'     
 ----THEN ((B.RFNET)/100)*50    
 ----WHEN B.EMP_CODE  <>'' AND B.EMP_CODE1<>'' AND B.EMP_CODE=B.EMP_CODE1      
 ----THEN ((B.RFNET)/100)*100    
 ----WHEN B.EMP_CODE='' AND B.EMP_CODE1<>'' THEN ((B.RFNET)/100)*100     
 ----WHEN B.EMP_CODE<>'' AND B.EMP_CODE1<>'' THEN ((B.RFNET)/100)*100     
 ----END))AS SALECOMMISSION1    
     
 FROM CMM01106 A     
 JOIN CMD01106 B ON A.CM_ID=B.CM_ID    
 JOIN EMPLOYEE H (NOLOCK) ON B.EMP_CODE=H.EMP_CODE     
 JOIN EMPLOYEE H1 (NOLOCK) ON B.EMP_CODE1=H1.EMP_CODE     
 JOIN BIN B1 ON B1.BIN_ID=ISNULL(A.BIN_ID,'000')    
 LEFT JOIN EMPCATEGORY CAT ON CAT.CATEGORY_CODE=H.CATEGORY_CODE     
 LEFT JOIN EMPCATEGORY CAT1 ON CAT1.CATEGORY_CODE=H1.CATEGORY_CODE     
 JOIN LOCATION C (NOLOCK) ON a.location_Code =C.DEPT_ID     
     
   WHERE A.CM_DT BETWEEN @DFROMDT AND @DTODT  --AND A.CM_MODE = 1 --CHANGE     
 AND C.DEPT_ID = (CASE WHEN @CDEPTID = '' THEN C.DEPT_ID ELSE @CDEPTID END)      
  AND A.BIN_ID = (CASE WHEN @CBINID = '' THEN A.BIN_ID ELSE @CBINID END)      
  AND H.EMP_CODE = (CASE WHEN @CEMPCODE = '' THEN H.EMP_CODE ELSE @CEMPCODE END)      
  AND (A.MEMO_TYPE = 1) AND A.CANCELLED = 0--CHANGE    
  AND A.USER_CODE=(CASE WHEN @CUSERCODE='' THEN A.USER_CODE ELSE @CUSERCODE END)    
      
 GROUP BY a.location_Code , CM_NO,H.EMP_NAME,DEPT_NAME,CM_DT,CAT.CATEGORY_NAME,CAT1.CATEGORY_NAME,H1.EMP_NAME    
 ,CASE WHEN B.EMP_CODE='0000000' THEN 0    
       WHEN (B.EMP_CODE<>B.EMP_CODE1) AND (B.EMP_CODE<>'0000000' AND B.EMP_CODE1='0000000')    THEN 100      
       WHEN  (B.EMP_CODE<>B.EMP_CODE1 AND H.CATEGORY_CODE=H1.CATEGORY_CODE) OR (B.EMP_CODE=B.EMP_CODE1) THEN 50      
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT.CATEGORY_NAME='A'  THEN 60      
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT.CATEGORY_NAME='B'  THEN 40      
       END    
  ,CASE     
       WHEN B.EMP_CODE1='0000000' THEN 0    
       WHEN  (B.EMP_CODE<>B.EMP_CODE1) AND (B.EMP_CODE='0000000' AND B.EMP_CODE1<>'0000000')   THEN 100      
       WHEN  (B.EMP_CODE<>B.EMP_CODE1 AND H.CATEGORY_CODE=H1.CATEGORY_CODE) OR (B.EMP_CODE=B.EMP_CODE1) THEN 50      
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT1.CATEGORY_NAME='A'  THEN 60       
       WHEN  B.EMP_CODE<>B.EMP_CODE1 AND CAT1.CATEGORY_NAME='B'  THEN 40      
    END    
       ,H.EMP_CODE,H1.EMP_CODE         
   ORDER BY CM_NO    
    

	DROP TABLE TMPCATEGORYWISEBILL
    SELECT * INTO TMPCATEGORYWISEBILL FROM #CATEGORYWISEBILL


    IF @BESTIMATEENABLED=0    
  GOTO LBLDETAIL     
  ELSE    
  IF @BESTIMATEENABLED=1    
  GOTO LBLSUMMARY     
  ELSE       
     GOTO LAST     
          
   LBLDETAIL:    

    SELECT A.LOCNAME,A.CM_DT,A.CM_NO,A.BILLAMOUNT,BILLQTY,A.SALEPERSON,A.CATEGORY_NAME,A.CATEGORYPERCENT,    
           CONVERT(NUMERIC(18,2),(A.BILLAMOUNT*A.CATEGORYPERCENT/100))AS SALECOMMISION,    
           A.SALEPERSON1,A.CATEGORY_NAME1,A.CATEGORYPERCENT1,    
           CONVERT(NUMERIC(18,2),(A.BILLAMOUNT*A.CATEGORYPERCENT1/100))AS  SALECOMMISION1 ,
           ISNULL(EG.EMP_GRP_NAME,'') AS EMP_GRP_NAME,
           ISNULL(EG1.EMP_GRP_NAME,'') AS EMP_GRP_NAME1
    FROM #CATEGORYWISEBILL A 
    LEFT OUTER JOIN EMP_GRP_LINK EL ON EL.EMP_CODE =A.EMP_CODE 
    LEFT OUTER JOIN EMPLOYEE_GRP EG ON EG.EMP_GRP_CODE =EL.EMP_GRP_CODE AND EG.DEPT_ID =a.dept_id  
    LEFT OUTER JOIN EMP_GRP_LINK EL1 ON EL1.EMP_CODE =A.EMP_CODE1 
    LEFT OUTER JOIN EMPLOYEE_GRP EG1 ON EG1.EMP_GRP_CODE =EL1.EMP_GRP_CODE AND EG.DEPT_ID =a.dept_id 


    
 GOTO LAST    
     
 LBLSUMMARY:    
     
     
 
 SELECT  LOCNAME,E.EMP_NAME AS SALEPERSON,EMP.CATEGORY_NAME,
 ISNULL(EG.EMP_GRP_NAME,'') AS EMP_GRP_NAME,
 CONVERT(NUMERIC(18,2),SUM(SALECOMMISION))AS COMMISION 
 
 FROM    
 (    
  SELECT dept_id AS DEPT_ID, EMP_CODE,LOCNAME,SUM(BILLAMOUNT*CATEGORYPERCENT/100)AS SALECOMMISION    
  FROM #CATEGORYWISEBILL    
  GROUP BY dept_id,EMP_CODE,LOCNAME    
      
  UNION ALL    
      
  SELECT dept_id AS DEPT_ID,EMP_CODE1,LOCNAME,SUM(BILLAMOUNT*CATEGORYPERCENT1/100)AS SALECOMMISION1    
  FROM #CATEGORYWISEBILL    
  GROUP BY dept_id,EMP_CODE1,LOCNAME    
  )A     
  JOIN EMPLOYEE E ON A.EMP_CODE=E.EMP_CODE    
  JOIN EMPCATEGORY EMP ON EMP.CATEGORY_CODE=E.CATEGORY_CODE  
  LEFT OUTER JOIN EMP_GRP_LINK EL ON EL.EMP_CODE =E.EMP_CODE 
  LEFT OUTER JOIN EMPLOYEE_GRP EG ON EG.EMP_GRP_CODE =EL.EMP_GRP_CODE  and a.DEPT_ID =eg.dept_id
  GROUP BY ISNULL(EG.EMP_GRP_NAME,''),E.EMP_NAME,EMP.CATEGORY_NAME,LOCNAME    
       
      
 GOTO LAST    
LAST:    
END


