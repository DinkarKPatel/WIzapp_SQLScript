CREATE PROCEDURE SP_PRD_BUYER_ORDER_ALLOCATION  
(  
 @NQUERYID INT=0,  
 @CARTICLE_CODE VARCHAR(50)='',  
 @CPARA1_CODE VARCHAR(10)='',  
 @CPARA2_CODE VARCHAR(10)='',  
 @CORDER_ID VARCHAR(100)='',  
 @CMEMO_ID VARCHAR(50)='',  
 @NNAVMODE INT=0,  
 @CWHERE VARCHAR(MAX)='',  
 @CFINYEAR VARCHAR(5)=''  
)  
AS  
BEGIN  
  
 DECLARE @DTSQL NVARCHAR(MAX)  
----FILTER IN HOUSE BUYER ORDER NOT IN TRANSFER TO TRADING  
--**************  
 IF @NQUERYID IN(4,6)  
 BEGIN       
  IF OBJECT_ID('TEMPDB..#TMPWO','U') IS NOT NULL    
     DROP TABLE #TMPWO    
         
     SELECT M.ORDER_NO,M.ORDER_DT, M.AC_CODE, A.ORDER_ID,A.MEMO_ID ,B.ARTICLE_CODE,Q.PARA1_CODE,Q.PARA2_CODE,         
     SUM(B.QUANTITY) AS QUANTITY,  
      SUM(Q.QUANTITY) AS PRD_QUANTITY      
   INTO #TMPWO     
   FROM  (SELECT DISTINCT * FROM PRD_WO_ORDERS) A         
   JOIN PRD_WO_MST C ON C.MEMO_ID=A.MEMO_ID         
   JOIN PRD_WO_DET P ON C.MEMO_ID=P.MEMO_ID         
   JOIN PRD_WO_SUB_DET Q ON P.ROW_ID =Q.REF_ROW_ID         
   JOIN BUYER_ORDER_DET B ON A.ORDER_ID=B.ORDER_ID         
   AND B.PARA1_CODE = Q.PARA1_CODE         
   AND B.PARA2_CODE = Q.PARA2_CODE         
   AND B.ARTICLE_CODE = C.ARTICLE_SET_CODE         
   JOIN BUYER_ORDER_MST M ON M.ORDER_ID=B.ORDER_ID         
   WHERE C.CANCELLED=0  AND M.CANCELLED=0    
   AND 1=2    
   GROUP BY M.ORDER_NO,M.ORDER_DT,M.AC_CODE,A.ORDER_ID,A.MEMO_ID,B.ARTICLE_CODE,Q.PARA1_CODE,Q.PARA2_CODE    
         
         
  SET @DTSQL=N' SELECT M.ORDER_NO,M.ORDER_DT,M.AC_CODE,B.ORDER_ID,ISNULL(A.MEMO_ID,'''') AS MEMO_ID ,B.ARTICLE_CODE,B.PARA1_CODE,B.PARA2_CODE,         
     SUM(B.QUANTITY) AS QUANTITY, SUM(ISNULL(A.QUANTITY,0)) AS PRD_QUANTITY       
   FROM BUYER_ORDER_DET B     
   JOIN BUYER_ORDER_MST M ON M.ORDER_ID=B.ORDER_ID     
   JOIN    
   (    
    SELECT ORD.ORDER_ID,MST.ARTICLE_SET_CODE ,MST.MEMO_ID,DET.PARA1_CODE,DET.PARA2_CODE,DET.QUANTITY    
   FROM PRD_WO_DET B (NOLOCK)  
   JOIN PRD_WO_MST MST (NOLOCK) ON B.MEMO_ID=MST.MEMO_ID  
   JOIN (SELECT DISTINCT * FROM PRD_WO_ORDERS) ORD ON ORD.MEMO_ID=MST.MEMO_ID        
   JOIN  
   (  
    SELECT PARA1_CODE,PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY   
    FROM PRD_WO_SUB_DET C  
    GROUP BY REF_ROW_ID,PARA1_CODE,PARA2_CODE  
   ) DET ON B.ROW_ID=DET.REF_ROW_ID  
   JOIN  
   (  
     SELECT WO_ID,PARA1_CODE,PARA2_CODE FROM   
     PRD_UPCPMT  A
     LEFT JOIN
     (
      SELECT PRODUCT_CODE  
      FROM PRD_TRANSFER_MAIN_DET A
      JOIN PRD_TRANSFER_MAIN_MST B ON A.MEMO_ID=B.MEMO_ID
      WHERE B.CANCELLED=0
     
     ) B ON A.PRODUCT_CODE=B.PRODUCT_CODE
     WHERE ISNULL(ORDER_ID,'''')=''''  AND B.PRODUCT_CODE IS NULL
     GROUP BY WO_ID,PARA1_CODE,PARA2_CODE  
    ) UPC ON UPC.WO_ID=MST.MEMO_ID  
    AND UPC.PARA1_CODE=DET.PARA1_CODE  
    AND UPC.PARA2_CODE=DET.PARA2_CODE     
   WHERE MST.CANCELLED=0 AND MARK_AS_COMPLETED=1    
   GROUP BY ORD.ORDER_ID,MST.ARTICLE_SET_CODE ,MST.MEMO_ID,DET.PARA1_CODE,DET.PARA2_CODE,DET.QUANTITY   
     
   ) A ON A.ORDER_ID=B.ORDER_ID         
   AND B.PARA1_CODE = A.PARA1_CODE         
   AND B.PARA2_CODE = A.PARA2_CODE         
   AND B.ARTICLE_CODE = A.ARTICLE_SET_CODE     
   WHERE  M.CANCELLED=0 
    AND M.ORDER_STATUS<>2
   AND B.ARTICLE_CODE='''+@CARTICLE_CODE+'''  
   AND B.PARA1_CODE='''+@CPARA1_CODE+'''  
   AND B.PARA2_CODE='''+@CPARA2_CODE+'''  
   GROUP BY M.ORDER_NO,M.ORDER_DT,M.AC_CODE,B.ORDER_ID,A.MEMO_ID,B.ARTICLE_CODE,B.PARA1_CODE,B.PARA2_CODE'    
   PRINT @DTSQL    
  INSERT INTO #TMPWO    
  EXEC SP_EXECUTESQL @DTSQL    
  
   
      
  IF OBJECT_ID('TEMPDB..#TMPTRANSFER','U') IS NOT NULL    
     DROP TABLE #TMPTRANSFER    
      
  SELECT A.*,ISNULL(ISSUE_QTY,0) AS TRF_QTY    
  INTO #TMPTRANSFER    
  FROM     
             
   ( SELECT A.ORDER_ID,A.MEMO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,         
     SUM(A.QUANTITY) AS QUANTITY, SUM(A.PRD_QUANTITY) AS PRD_QUANTITY       
    FROM  #TMPWO A    
    GROUP BY A.ORDER_ID,A.MEMO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE    
   ) A    
   JOIN    
   (    
    SELECT MST.ARTICLE_SET_CODE AS ARTICLE_CODE,PMT.PARA1_CODE,PMT.PARA2_CODE,    
     PMT.WO_ID AS REF_WO_ID,    
     COUNT(*) AS ISSUE_QTY    
    FROM PRD_TRANSFER_TO_TRADING_UPC A  
       JOIN PRD_TRANSFER_MAIN_MST B ON A.MEMO_ID =B.MEMO_ID   
       JOIN PRD_UPCPMT PMT ON PMT.PRODUCT_CODE=A.PRODUCT_CODE  
       JOIN PRD_WO_MST MST ON MST.MEMO_ID =PMT.WO_ID   
       WHERE B.CANCELLED =0  AND MST.CANCELLED =0   AND ISNULL(PMT.ORDER_ID ,'')=''  
    GROUP BY MST.ARTICLE_SET_CODE,PMT.PARA1_CODE,PMT.PARA2_CODE,PMT.WO_ID  
   ) B ON A.MEMO_ID=B.REF_WO_ID    
   AND A.ARTICLE_CODE=B.ARTICLE_CODE    
   AND A.PARA1_CODE=B.PARA1_CODE    
   AND A.PARA2_CODE=B.PARA2_CODE    
       
      
  IF OBJECT_ID('TEMPDB..#TMPALLOCATEORD','U') IS NOT NULL    
     DROP TABLE #TMPALLOCATEORD    
      
      
    SELECT A.*,ISNULL(TRF_QTY,0) AS TRF_QTY ,  
     PRD_QUANTITY-(ISNULL(CNT,0)+ISNULL(TRF_QTY,0)) AS PENDING_QTY  
    INTO #TMPALLOCATEORD  
    FROM #TMPWO A  
    LEFT OUTER JOIN    
   (    
    SELECT A.ORDER_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,    
     SUM(TRF_QTY) AS TRF_QTY    
    FROM #TMPTRANSFER A    
    GROUP BY A.ORDER_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE    
   ) C ON A.ORDER_ID=C.ORDER_ID    
   AND A.ARTICLE_CODE=C.ARTICLE_CODE    
   AND A.PARA1_CODE=C.PARA1_CODE    
   AND A.PARA2_CODE=C.PARA2_CODE    
    LEFT OUTER JOIN  
   (  
    SELECT WO_ID ,PARA1_CODE,PARA2_CODE,COUNT(*) AS CNT  
    FROM PRD_UPCPMT A  
    WHERE ISNULL(A.ORDER_ID ,'')<>''  
    GROUP BY WO_ID,PARA1_CODE,PARA2_CODE  
   ) AL ON AL.WO_ID =A.MEMO_ID   
   AND AL.PARA1_CODE=A.PARA1_CODE  
   AND AL.PARA2_CODE=A.PARA2_CODE     
   WHERE PRD_QUANTITY-(ISNULL(TRF_QTY,0)+ISNULL(CNT,0))>0  
   ORDER BY ORDER_ID    
     
  -- SELECT * FROM #TMPALLOCATEORD  
  
  
 END      
   
--*************  
  
IF @NQUERYID=1  
   GOTO LBLART  
ELSE IF @NQUERYID=2  
   GOTO LBLCOLOR  
ELSE IF @NQUERYID=3  
   GOTO LBLSIZE  
ELSE IF @NQUERYID=4  
   GOTO LBLINHOUSEORDE  
ELSE IF @NQUERYID=5  
   GOTO LBLSPECIFICBUYER  
ELSE IF @NQUERYID=6  
   GOTO LBLFGBARCODE  
ELSE IF @NQUERYID=7  
   GOTO LBLMSTVIEW  
ELSE IF @NQUERYID=8  
   GOTO LBLDETVIEW  
ELSE IF @NQUERYID=9  
   GOTO LBLMST  
ELSE IF @NQUERYID=10  
   GOTO NAVIGATE  
ELSE   
   GOTO END_PROC  
     
   LBLART:  
        
      SELECT B.ARTICLE_CODE,C.ARTICLE_NO,C.ARTICLE_NAME   
      FROM BUYER_ORDER_MST A  
      JOIN BUYER_ORDER_DET B ON A.ORDER_ID=B.ORDER_ID  
      JOIN ARTICLE C ON C.ARTICLE_CODE=B.ARTICLE_CODE  
      WHERE A.CANCELLED =0 AND A.ORDER_STATUS<>2  
      GROUP BY B.ARTICLE_CODE,C.ARTICLE_NO,C.ARTICLE_NAME   
     
   GOTO END_PROC  
     
   LBLCOLOR:  
       
      SELECT B.PARA1_CODE,C.PARA1_NAME  
      FROM BUYER_ORDER_MST A  
      JOIN BUYER_ORDER_DET B ON A.ORDER_ID=B.ORDER_ID  
      JOIN PARA1 C ON C.PARA1_CODE=B.PARA1_CODE  
      WHERE A.CANCELLED =0   
      AND B.ARTICLE_CODE=@CARTICLE_CODE  
      GROUP BY B.PARA1_CODE,C.PARA1_NAME  
         
     
   GOTO END_PROC  
     
     
    LBLSIZE:  
       
      SELECT D.PARA2_NAME,D.PARA2_CODE   
      FROM BUYER_ORDER_MST A  
      JOIN BUYER_ORDER_DET B ON A.ORDER_ID=B.ORDER_ID  
      JOIN PARA2 D ON D.PARA2_CODE=B.PARA2_CODE  
      WHERE A.CANCELLED =0   
      AND B.ARTICLE_CODE=@CARTICLE_CODE  
      AND B.PARA1_CODE=@CPARA1_CODE  
      GROUP BY D.PARA2_NAME,D.PARA2_CODE  
         
     
   GOTO END_PROC  
      
    LBLINHOUSEORDE:  
      
  
 SELECT CAST(0 AS BIT) AS CHK, B.ARTICLE_CODE,C.ARTICLE_NO,C.ARTICLE_NAME,  
 B.PARA1_CODE,P1.PARA1_NAME,P2.PARA2_NAME,P2.PARA2_CODE,B.ORDER_ID AS INHOUSE_ORDER_ID,    
 B.ORDER_ID,B.ORDER_NO,B.ORDER_DT,B.QUANTITY  AS ORD_QTY,  
 SUM(B.PENDING_QTY) AS PENDING_QTY,  
 CAST(CAST('LATER' AS VARCHAR(5))+CAST(NEWID()  AS VARCHAR(40)) AS VARCHAR(40)) AS ROW_ID,  
 CAST('LATER' AS VARCHAR(100)) AS MEMO_ID,  
 CAST(0 AS NUMERIC(10,0)) AS QUANTITY  
 FROM #TMPALLOCATEORD B  
 JOIN ARTICLE C ON C.ARTICLE_CODE=B.ARTICLE_CODE  
 JOIN PARA1 P1 ON B.PARA1_CODE=P1.PARA1_CODE  
    JOIN PARA2 P2 ON B.PARA2_CODE=P2.PARA2_CODE  
 WHERE  B.ARTICLE_CODE=@CARTICLE_CODE  
 AND B.PARA1_CODE=@CPARA1_CODE  
 AND B.PARA2_CODE=@CPARA2_CODE  
 GROUP BY B.ARTICLE_CODE,C.ARTICLE_NO,C.ARTICLE_NAME,  
 B.PARA1_CODE,P1.PARA1_NAME,P2.PARA2_NAME,P2.PARA2_CODE,    
 B.ORDER_ID,B.ORDER_NO,B.ORDER_DT,B.QUANTITY  
 ORDER BY B.ORDER_NO,B.ORDER_DT  
   
 GOTO END_PROC  
   
 LBLSPECIFICBUYER:  
      
      
       
    --DECLARE @DTSQL NVARCHAR(MAX)  
    IF OBJECT_ID('TEMPDB..#TMPSPECIFICBO','U') IS NOT NULL    
     DROP TABLE #TMPSPECIFICBO    
         
     SELECT M.ORDER_NO,M.ORDER_DT, M.AC_CODE, A.ORDER_ID,B.ARTICLE_CODE,Q.PARA1_CODE,Q.PARA2_CODE,         
     SUM(B.QUANTITY) AS QUANTITY  
      
   INTO #TMPSPECIFICBO     
   FROM  (SELECT DISTINCT * FROM PRD_WO_ORDERS) A         
   JOIN PRD_WO_MST C ON C.MEMO_ID=A.MEMO_ID         
   JOIN PRD_WO_DET P ON C.MEMO_ID=P.MEMO_ID         
   JOIN PRD_WO_SUB_DET Q ON P.ROW_ID =Q.REF_ROW_ID         
   JOIN BUYER_ORDER_DET B ON A.ORDER_ID=B.ORDER_ID         
   AND B.PARA1_CODE = Q.PARA1_CODE         
   AND B.PARA2_CODE = Q.PARA2_CODE         
   AND B.ARTICLE_CODE = C.ARTICLE_SET_CODE         
   JOIN BUYER_ORDER_MST M ON M.ORDER_ID=B.ORDER_ID         
   WHERE C.CANCELLED=0  AND M.CANCELLED=0    
   AND 1=2    
   GROUP BY M.ORDER_NO,M.ORDER_DT, M.AC_CODE, A.ORDER_ID,B.ARTICLE_CODE,Q.PARA1_CODE,Q.PARA2_CODE    
         
         
  SET @DTSQL=N' SELECT M.ORDER_NO,M.ORDER_DT,M.AC_CODE,B.ORDER_ID,B.ARTICLE_CODE,B.PARA1_CODE,B.PARA2_CODE,         
     SUM(B.QUANTITY)-ISNULL(CNT,0) AS QUANTITY      
   FROM BUYER_ORDER_DET B     
   JOIN BUYER_ORDER_MST M ON M.ORDER_ID=B.ORDER_ID     
   LEFT JOIN    
   (    
    SELECT A.ORDER_ID,A.ARTICLE_SET_CODE ,A.PARA1_CODE,A.PARA2_CODE,  
    SUM(A.QUANTITY ) AS PRD_QTY   
    FROM    
    (SELECT ORD.ORDER_ID,MST.ARTICLE_SET_CODE ,MST.MEMO_ID,DET.PARA1_CODE,DET.PARA2_CODE,DET.QUANTITY    
    FROM PRD_WO_DET B (NOLOCK)  
   JOIN PRD_WO_MST MST (NOLOCK) ON B.MEMO_ID=MST.MEMO_ID  
   JOIN (SELECT DISTINCT * FROM PRD_WO_ORDERS) ORD ON ORD.MEMO_ID=MST.MEMO_ID        
   JOIN  
   (  
    SELECT PARA1_CODE,PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY   
    FROM PRD_WO_SUB_DET C  
    GROUP BY REF_ROW_ID,PARA1_CODE,PARA2_CODE  
   ) DET ON B.ROW_ID=DET.REF_ROW_ID  
   WHERE MST.CANCELLED=0 AND MARK_AS_COMPLETED=1    
   GROUP BY ORD.ORDER_ID,MST.ARTICLE_SET_CODE ,MST.MEMO_ID,DET.PARA1_CODE,DET.PARA2_CODE,DET.QUANTITY   
   ) A         
      GROUP BY A.ORDER_ID,A.ARTICLE_SET_CODE ,A.PARA1_CODE,A.PARA2_CODE  
    
   ) A ON A.ORDER_ID=B.ORDER_ID         
   AND B.PARA1_CODE = A.PARA1_CODE         
   AND B.PARA2_CODE = A.PARA2_CODE         
   AND B.ARTICLE_CODE = A.ARTICLE_SET_CODE    
   LEFT OUTER JOIN  
   (  
    SELECT  ISNULL(A.ORDER_ID,'''') AS ORDER_ID,B.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,COUNT(*) AS CNT  
    FROM PRD_UPCPMT A
    JOIN PRD_WO_MST MST ON A.WO_ID =MST.MEMO_ID 
    JOIN BUYER_ORDER_DET B ON A.ORDER_ID=B.ORDER_ID AND A.PARA1_CODE=B.PARA1_CODE AND A.PARA2_CODE =B.PARA2_CODE
    AND MST.ARTICLE_SET_CODE =B.ARTICLE_CODE 
    JOIN BUYER_ORDER_MST BM ON BM.ORDER_ID =B.ORDER_ID 
    WHERE BM.CANCELLED =0 AND MST.CANCELLED =0
    GROUP BY A.ORDER_ID,B.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE  
   ) AL ON AL.ORDER_ID=B.ORDER_ID  
   AND AL.ARTICLE_CODE=B.ARTICLE_CODE
   AND AL.PARA1_CODE=B.PARA1_CODE  
   AND AL.PARA2_CODE=B.PARA2_CODE      
   WHERE  M.CANCELLED=0  AND M.ORDER_STATUS=2   
   AND B.ARTICLE_CODE='''+@CARTICLE_CODE+'''  
   AND B.PARA1_CODE='''+@CPARA1_CODE+'''  
   AND B.PARA2_CODE='''+@CPARA2_CODE+'''  
   GROUP BY CNT,M.ORDER_NO,M.ORDER_DT,M.AC_CODE,B.ORDER_ID,B.ARTICLE_CODE,B.PARA1_CODE,B.PARA2_CODE,ISNULL(PRD_QTY,0)  
   HAVING SUM(B.QUANTITY)-ISNULL(PRD_QTY,0)>0   
   AND SUM(B.QUANTITY)-ISNULL(CNT,0)>0'    
   PRINT @DTSQL    
  INSERT INTO #TMPSPECIFICBO    
  EXEC SP_EXECUTESQL @DTSQL    
  
          
        SELECT A.ARTICLE_CODE,B.ARTICLE_NO, CAST(0 AS BIT) AS CHK, A.AC_CODE AS AC_CODE,  
        LM.AC_NAME AS AC_NAME,  
        A.ORDER_ID,A.ORDER_NO,A.ORDER_DT,P1.PARA1_NAME,A.PARA1_CODE,P2.PARA2_NAME,A.PARA2_CODE ,A.QUANTITY,  
        A.ORDER_ID AS BUYER_ORDER_ID,  
        CAST(CAST('LATER' AS VARCHAR(5))+CAST(NEWID()  AS VARCHAR(40)) AS VARCHAR(40)) AS ROW_ID,  
  CAST('LATER' AS VARCHAR(40)) AS REF_ROW_ID,  
  ALLOCATE_QTY=CAST(0 AS NUMERIC(10,0)),  
     PENDING_QTY=CAST(0 AS NUMERIC(10,0))  
        FROM #TMPSPECIFICBO A  
        JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE  
        JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE  
        JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE  
        JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE  
     
   
 GOTO END_PROC  
   
 LBLFGBARCODE:  
        
   
      SELECT CAST(0 AS BIT) AS CHK,   
      A.ORDER_ID,A.MEMO_ID ,A.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,P1.PARA1_NAME,A.PARA1_CODE,P2.PARA2_NAME,A.PARA2_CODE,  
      B.PRODUCT_CODE,B.JOB_CODE,  
     CASE WHEN ISNULL(B.JOB_CODE,'')='' THEN 'IN WORK_ORDER' ELSE JOBS.JOB_NAME END AS STATUS,  
      CAST('' AS VARCHAR(50)) AS BO_ORDER_ID,  
      CAST('LATER' AS VARCHAR(40)) AS ROW_ID,  
      CAST('LATER' AS VARCHAR(40)) AS REF_ROW_ID,  
      CAST(0 AS NUMERIC(10,2)) AS QUANTITY,  
      CAST('' AS VARCHAR(100)) AS BUYER_NAME,  
       ROW_NUMBER() OVER (ORDER BY A.ORDER_ID) AS NEW_ROW_ID,
       JOBS.JOB_NAME  
      FROM #TMPALLOCATEORD A  
      JOIN PRD_UPCPMT B ON A.MEMO_ID=B.WO_ID AND A.PARA1_CODE=B.PARA1_CODE AND A.PARA2_CODE=B.PARA2_CODE  
      JOIN ARTICLE ART ON ART.ARTICLE_CODE=A.ARTICLE_CODE  
      JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE  
      JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE  
      LEFT JOIN JOBS ON JOBS.JOB_CODE=B.JOB_CODE  
      LEFT OUTER JOIN  
      (  
         
   SELECT PRODUCT_CODE  FROM PRD_TRANSFER_TO_TRADING_UPC A  
   JOIN PRD_TRANSFER_MAIN_MST B ON A.MEMO_ID =B.MEMO_ID   
   WHERE B.CANCELLED =0  
      ) TR ON TR.PRODUCT_CODE =B.PRODUCT_CODE   
      WHERE A.ORDER_ID=@CORDER_ID AND ISNULL(B.ORDER_ID,'')=''   
      AND TR.PRODUCT_CODE IS NULL  
      AND ISNULL(B.ORDER_ID,'') =''  
      --AND B.QUANTITY_IN_STOCK>0   
     -- AND  ISNULL(B.JOB_CODE,'')<>''  
               
 GOTO END_PROC  
   
 LBLMSTVIEW:  
       
       
     SELECT A.FIN_YEAR,A.MEMO_ID,A.MEMO_NO,A.MEMO_DT,  
            A.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,  
            A.PARA1_CODE,P1.PARA1_NAME,  
            A.PARA2_CODE,P2.PARA2_NAME  ,A.CANCELLED
        FROM PRD_BUYER_ORDER_ALLOCATE_MST A  
        JOIN ARTICLE ART ON ART.ARTICLE_CODE=A.ARTICLE_CODE  
     JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE  
     JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE  
     WHERE A.MEMO_ID=@CMEMO_ID  
     ORDER BY MEMO_DT,MEMO_NO  
   
 GOTO END_PROC  
   
 LBLDETVIEW:  
       
       
     SELECT A.MEMO_ID,A.MEMO_NO,A.MEMO_DT,  
            A.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,  
            A.PARA1_CODE,P1.PARA1_NAME,  
            A.PARA2_CODE,P2.PARA2_NAME,  
            MST.ORDER_NO AS ORDER_NO,MST.ORDER_DT AS ORDER_DT,--INHOUSE  
            BR.PRODUCT_CODE AS UPC,  
            SD.AC_CODE,LM.AC_NAME,  
            MST1.ORDER_NO AS SP_ORDER_NO,MST1.ORDER_DT AS SP_ORDER_DT,DET.ROW_ID,  
            CASE WHEN ISNULL(JOBS.JOB_CODE,'')='' THEN 'IN WORK_ORDER' ELSE JOBS.JOB_NAME END AS STATUS1  
        FROM PRD_BUYER_ORDER_ALLOCATE_MST A  
        JOIN PRD_BUYER_ORDER_ALLOCATE_DET DET ON A.MEMO_ID=DET.MEMO_ID  
        JOIN PRD_BUYER_ORDER_ALLOCATE_SUB_DET SD ON DET.ROW_ID=SD.REF_ROW_ID  
        JOIN PRD_BUYER_ORDER_ALLOCATE_BARCODE BR ON BR.REF_ROW_ID=SD.ROW_ID  
        JOIN ARTICLE ART ON ART.ARTICLE_CODE=A.ARTICLE_CODE  
     JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE  
     JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE  
     JOIN BUYER_ORDER_MST MST ON MST.ORDER_ID=DET.INHOUSE_ORDER_ID  
     JOIN BUYER_ORDER_MST MST1 ON MST1.ORDER_ID=SD.BUYER_ORDER_ID  
     JOIN LM01106 LM ON LM.AC_CODE=SD.AC_CODE  
     JOIN PRD_UPCPMT PMT ON PMT.PRODUCT_CODE=BR.PRODUCT_CODE  
     LEFT JOIN JOBS ON JOBS.JOB_CODE=PMT.JOB_CODE  
     WHERE A.MEMO_ID=@CMEMO_ID  
     ORDER BY MEMO_DT,MEMO_NO  
   
 GOTO END_PROC  
   
 LBLMST:--FOR BIND  
     
   SELECT A.FIN_YEAR, A.MEMO_ID,A.MEMO_NO,A.MEMO_DT,  
             A.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,  
             A.PARA1_CODE,P1.PARA1_NAME,  
             A.PARA2_CODE,P2.PARA2_NAME,  
             A.LAST_UPDATE  ,A.CANCELLED 
      FROM PRD_BUYER_ORDER_ALLOCATE_MST A  
      JOIN ARTICLE ART ON ART.ARTICLE_CODE=A.ARTICLE_CODE  
   JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE  
   JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE  
   WHERE A.MEMO_ID=@CMEMO_ID  
   
 GOTO END_PROC  
   
   NAVIGATE:  
     
    EXEC SP_NAVIGATE  'PRD_BUYER_ORDER_ALLOCATE_MST',@NNAVMODE,@CWHERE,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID',''    
    GOTO END_PROC  
     
      
END_PROC:   
END
