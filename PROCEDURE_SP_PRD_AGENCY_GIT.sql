CREATE PROCEDURE SP_PRD_AGENCY_GIT
@NQUERYID NUMERIC(4,0),                                
@CDEPARTMENTID VARCHAR(10),                                
@CMEMOID VARCHAR(MAX),                                
@CAGENCYCODE VARCHAR(500),                          
@CWHERE VARCHAR(MAX)='',                      
@CPARA1_CODE VARCHAR(MAX)='',                      
@CPARA2_CODE VARCHAR(MAX)='',                      
@CORDER_ID VARCHAR(MAX)='',                      
@NQTY INT =0,                  
@CCOMPONENT_NO VARCHAR(MAX)='',            
@NSP_ID INT=0                     
------WITH ENCRYPTION                                
                                
AS         
BEGIN                                  
  DECLARE @CCMD NVARCHAR(MAX) ,@DTSQL NVARCHAR(MAX)                          
     DECLARE @DTSQL1 NVARCHAR(MAX)                      
     DECLARE @CQRY1 VARCHAR(MAX) ,@CENABLED_UPC VARCHAR(10)                    
                  
     SELECT TOP 1 @CENABLED_UPC=VALUE  FROM CONFIG WHERE CONFIG_OPTION='ENABLED_UPC'              
  
                          
IF @NQUERYID = 1                                  
GOTO LBLGETMASTER                                  
                                  
ELSE IF @NQUERYID = 2                                  
GOTO LBLGETDETAILS                                  
                                  
ELSE IF @NQUERYID = 3                                  
GOTO LBLGETMASTERCURSOR                                  
                                  
ELSE IF @NQUERYID = 4                                  
GOTO LBLGETDETAILCURSOR                                  
                                  
ELSE IF @NQUERYID = 5                                  
GOTO LBLGETAGENCY                                
                                
ELSE IF @NQUERYID = 6                                 
GOTO LBLAPPLU                                
                                
 ELSE IF @NQUERYID = 7                                  
GOTO LBLGETMASTER1                       
                      
ELSE IF @NQUERYID = 8                                  
GOTO LBLORDER                                  
                      
ELSE IF @NQUERYID = 9                                  
GOTO LBLGETFG                       
                      
                      
                      
                      
LBLGETFG:                              
 IF(ISNULL(@CMEMOID,'')<>'') -------FOR NAVIGATION                                  
 BEGIN                        
  IF OBJECT_ID('TEMPDB..#TMPRECUPC','U') IS NOT NULL      
    DROP TABLE #TMPRECUPC   
       
 --SELECT A.MEMO_ID AS RECEIPT_ID, B.WO_ID AS WO_ID ,B.PARA1_CODE AS  PARA1_CODE, B.PARA2_CODE AS  PARA2_CODE,
 --        LM.AC_CODE ,LM.AC_NAME,BO.ITEM_MERCHANT_CODE ,      
 --        EMP.EMP_NAME AS ITEM_MERCHANT_NAME,      
 --        SUM(A.QUANTITY ) AS FN_REC        
 --INTO #TMPRECUPC      
 --FROM PRD_AGENCY_MATERIAL_RECEIPT_UPC A (NOLOCK)  
 --JOIN PRD_UPCPMT B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE 
 --LEFT JOIN(SELECT * FROM PRD_WO_ORDERS ) WO ON WO.MEMO_ID =B.WO_ID 
 -- LEFT JOIN 
 --(
 -- SELECT A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE  
 -- FROM BUYER_ORDER_DET A (NOLOCK)
 -- JOIN BUYER_ORDER_MST B (NOLOCK) ON A.ORDER_ID =B.ORDER_ID 
 -- WHERE B.CANCELLED =0
 -- GROUP BY A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE
 --) BO ON BO.ORDER_ID =ISNULL(B.ORDER_ID ,WO.ORDER_ID )
 --LEFT OUTER JOIN EMPLOYEE EMP ON EMP.EMP_CODE =BO.ITEM_MERCHANT_CODE 
 --LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =BO.AC_CODE 
 --WHERE A.MEMO_ID =@CMEMOID  AND ISNULL(B.PRODUCT_CODE,'')<>'' 
 --GROUP BY A.MEMO_ID , B.WO_ID  ,B.PARA1_CODE , B.PARA2_CODE ,
 --        LM.AC_CODE ,LM.AC_NAME,BO.ITEM_MERCHANT_CODE ,      
 --        EMP.EMP_NAME     
      
            
           
 -- IF OBJECT_ID('TEMPDB..#TMPRECUPC','U') IS NOT NULL      
 --   DROP TABLE #TMPRECUPC      
 --SELECT A.MEMO_ID AS RECEIPT_ID, B.*       
 --INTO #TMPRECUPC      
 --FROM PRD_AGENCY_MATERIAL_RECEIPT_UPC A      
 --JOIN FN_WO_ALLOCATION('','') B ON A.PRODUCT_CODE =B.PRODUCT_CODE       
 --WHERE A.MEMO_ID =@CMEMOID  AND ISNULL(B.PRODUCT_CODE,'')<>''      
      
                       
 SELECT CAST(0 AS BIT) AS CHCK, CAST('' AS VARCHAR(100)) AS MEMO_ID,  
   -- CASE  WHEN ISNULL(@CENABLED_UPC,'')='1' THEN FN_REC  ELSE  A.REC_QTY END AS  REC_QTY ,
    A.REC_QTY AS REC_QTY      
  , A.*,0 AS PROCESS_QTY,RIGHT(A.REF_WO_ID,10) AS WO_NO,                      
 PENDING_QTY=0,DEFAULT_BASIS_NAME,      
 '' AS AC_CODE,      
 '' AS ITEM_MERCHANT_CODE,      
 '' AS AC_NAME,      
 '' AS MERCHANT_NAME,  
 A.REF_WO_ID AS REF_WO_ID                      
 FROM                      
 (                      
  SELECT C.REF_WO_ID,A.ARTICLE_CODE,                      
  A.PARA1_CODE,PARA1_NAME COM_COLOR,                      
  A.PARA2_CODE,PARA2_NAME COM_SIZE,                      
  J.JOB_NAME ,                      
  REC_QTY                       
 ,DEFAULT_BASIS                      
 ,RATE                      
 ,AMOUNT                      
 ,A.NET_AMOUNT                      
 ,A.MEMO_ID                      
 ,AR.ARTICLE_NO 
 ,'' AS ISSUE_REMARKS                     
  FROM PRD_AGENCY_ROW_MATERIAL_RECEIPT_DET A                      
  JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST B ON A.MEMO_ID =B.MEMO_ID                   
  JOIN      
  (                   
   SELECT JOB_CODE, C.MEMO_ID,DET.REF_PRD_WORKORDER_MEMOID AS REF_WO_ID,C.REF_MATERIAL_ROW_ID             
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET C                      
   JOIN             
   (            
   SELECT JOB_CODE, ROW_ID,REF_PRD_WORKORDER_MEMOID FROM PRD_AGENCY_ISSUE_MATERIAL_DET   
   GROUP BY JOB_CODE, ROW_ID,REF_PRD_WORKORDER_MEMOID            
   UNION             
   SELECT JOB_CODE,ROW_ID,REF_PRD_WORKORDER_MEMOID FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING             
    )            
   DET ON C.REF_ROW_ID=DET.ROW_ID                      
  -- WHERE C.MEMO_ID=@CMEMOID                      
   GROUP BY JOB_CODE,C.MEMO_ID,C.REF_MATERIAL_ROW_ID,REF_PRD_WORKORDER_MEMOID                      
  ) C ON A.MEMO_ID=C.MEMO_ID                          
 AND A.ROW_ID=C.REF_MATERIAL_ROW_ID                      
 JOIN ARTICLE AR ON AR.ARTICLE_CODE=A.ARTICLE_CODE                      
 JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE                      
 JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE                      
 LEFT JOIN JOBS J ON J.JOB_CODE =C.JOB_CODE                       
 --WHERE CANCELLED=0                       
 --WHERE B.MEMO_ID=@CMEMOID                      
 --AND DEFAULT_BASIS<>1                      
 --GROUP BY C.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE                      
 ) A                      
 LEFT OUTER JOIN DEFAULT_BASIS_MASTER DM ON DM.DEFAULT_BASIS_VALUE=DEFAULT_BASIS        
 --LEFT JOIN       
 --(      
 -- SELECT FN.WO_ID ,FN.PARA1_CODE,FN.PARA2_CODE,FN.RECEIPT_ID,      
 --        FN.AC_CODE ,      
 --        FN.AC_NAME,      
 --        FN.ITEM_MERCHANT_CODE ,      
 --        FN.ITEM_MERCHANT_NAME,      
 --        FN.FN_REC      
 -- FROM #TMPRECUPC FN      
 -- GROUP BY FN.WO_ID ,FN.PARA1_CODE,FN.PARA2_CODE,FN.RECEIPT_ID,      
 --        FN.AC_NAME,FN.AC_CODE ,FN.ITEM_MERCHANT_CODE ,      
 --        FN.ITEM_MERCHANT_NAME,FN.FN_REC      
 --)   FN ON FN.WO_ID  =A.REF_WO_ID AND FN.PARA1_CODE=A.PARA1_CODE  AND FN.PARA2_CODE=A.PARA2_CODE AND FN.RECEIPT_ID=A.MEMO_ID                          
 WHERE A.MEMO_ID=@CMEMOID              
            
SELECT @CMEMOID                     
                
END                      
ELSE                      
BEGIN                      
                      
                      
SET @DTSQL=N'SELECT CAST(0 AS BIT) AS CHCK, CAST('''' AS VARCHAR(100)) AS MEMO_ID,                      
  CAST(''LATER''+ CAST(RIGHT(DT1.REF_PRD_WORKORDER_MEMOID,10)+T1.MEMO_NO+R.PARA1_CODE+P2.PARA2_CODE AS VARCHAR(100)) AS VARCHAR(40)) AS ROW_ID,                      
  DT1.REF_PRD_WORKORDER_MEMOID AS WO_ID,                       
  RIGHT(DT1.REF_PRD_WORKORDER_MEMOID,10) AS WO_NO,                      
  R.ARTICLE_CODE,AR.ARTICLE_NAME ,AR.ARTICLE_NO,                      
  R.PARA1_CODE,P1.PARA1_NAME AS COM_COLOR,                      
  P2.PARA2_CODE,P2.PARA2_NAME AS COM_SIZE,                      
  T1.MEMO_NO AS ISSUE_MEMO_NO,                       
  T1.MEMO_ID AS ISSUE_MEMO_ID,                 
  T1.MEMO_DT AS ISSUE_MEMO_DT,                      
  R.ISSUE_QTY AS ISSUE_QTY,                      
  R.ISSUE_QTY-ISNULL(T5.REC_QTY,0)  AS PENDING_QTY ,                      
  R.ISSUE_QTY-ISNULL(T5.REC_QTY,0) AS REC_QTY,                      
  ISNULL(DEFAULT_BASIS_VALUE,''2'') AS DEFAULT_BASIS_VALUE,                      
  ISNULL(DEFAULT_BASIS_VALUE,''2'') AS  DEFAULT_BASIS,                      
  ISNULL(DEFAULT_BASIS_NAME,''RATE/PCS'') AS DEFAULT_BASIS_NAME,                      
  JOBS.JOB_CODE,                      
  JOBS.JOB_NAME,                      
  ISNULL(NEW_RATE,CR.C_RATE) AS RATE,                
  AMOUNT,R.NET_AMOUNT ,
  T1.REMARKS AS ISSUE_REMARKS                      
  FROM PRD_AGENCY_ISSUE_MATERIAL_MST T1                       
  JOIN                      
  (                      
   SELECT JOB_CODE,REF_MATERIAL_ROW_ID,REF_PRD_WORKORDER_MEMOID,MEMO_ID                       
   FROM PRD_AGENCY_ISSUE_MATERIAL_DET                      
   GROUP BY JOB_CODE,REF_PRD_WORKORDER_MEMOID,MEMO_ID,REF_MATERIAL_ROW_ID                      
  ) DT1  ON T1.MEMO_ID=DT1.MEMO_ID                               
  JOIN PRD_AGENCY_ISSUE_ROW_MATERIAL_DET R ON T1.MEMO_ID=R.MEMO_ID AND R.ROW_ID=DT1.REF_MATERIAL_ROW_ID                      
  JOIN JOBS ON JOBS.JOB_CODE=DT1.JOB_CODE                      
  LEFT OUTER JOIN PRD_WO_MST T4 ON DT1.REF_PRD_WORKORDER_MEMOID = T4.MEMO_ID                                      
  LEFT OUTER JOIN                
  (           --DET.REC_QTY,                
                  
                  
  SELECT A.PARA1_CODE,A.PARA2_CODE, B.MEMO_ID,B.REF_PRD_WORKORDER_MEMOID,SUM(A.REC_QTY) AS REC_QTY ,SUM(B.QT1) AS QT1                
  FROM PRD_AGENCY_ROW_MATERIAL_RECEIPT_DET A                
  JOIN                
  (                
  SELECT DT1.MEMO_ID AS REC_MEMO_ID, DT1.REF_MATERIAL_ROW_ID ,DT2.REF_PRD_WORKORDER_MEMOID, DT2.MEMO_ID, SUM(DT1.QUANTITY) AS  QT1                                
  FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT1                                
  JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT1 ON MT1.MEMO_ID=DT1.MEMO_ID                
 -- JOIN PRD_AGENCY_ROW_MATERIAL_RECEIPT_DET DET ON DET.MEMO_ID=DT1.MEMO_ID AND DET.ROW_ID=DT1.REF_MATERIAL_ROW_ID                             
  JOIN             
  (            
  SELECT DT2.REF_PRD_WORKORDER_MEMOID, DT2.MEMO_ID,ROW_ID            
  FROM            
  (            
  SELECT DT2.REF_PRD_WORKORDER_MEMOID, DT2.MEMO_ID,ROW_ID FROM PRD_AGENCY_ISSUE_MATERIAL_DET DT2             
  UNION          
   SELECT DT2.REF_PRD_WORKORDER_MEMOID, DT2.REF_ISSUE_ID,ROW_ID FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING DT2             
   ) DT2             
   GROUP BY DT2.REF_PRD_WORKORDER_MEMOID, DT2.MEMO_ID,ROW_ID            
  )DT2 ON DT1.REF_ROW_ID =DT2.ROW_ID                                
  WHERE MT1.CANCELLED=0                                
  GROUP BY  DT1.MEMO_ID,DT1.REF_MATERIAL_ROW_ID, DT2.REF_PRD_WORKORDER_MEMOID,DT2.MEMO_ID                   
  ) B ON A.MEMO_ID=B.REC_MEMO_ID AND A.ROW_ID =B.REF_MATERIAL_ROW_ID                 
  GROUP BY A.PARA1_CODE,A.PARA2_CODE, B.MEMO_ID,B.REF_PRD_WORKORDER_MEMOID                              
  )  T5 ON DT1.MEMO_ID= T5.MEMO_ID AND DT1.REF_PRD_WORKORDER_MEMOID=T5.REF_PRD_WORKORDER_MEMOID                 
  AND T5.PARA1_CODE=R.PARA1_CODE                              
  AND T5.PARA2_CODE=R.PARA2_CODE                 
  JOIN PRD_AGENCY_MST T6 ON T6.AGENCY_CODE=T1.REF_AGENCY_CODE             
  JOIN                              
  (SELECT A.REF_PRD_WORKORDER_MEMOID, A.MEMO_ID,SUM(QUANTITY) AS QUANTITY              
  FROM(                
  SELECT A11.REF_PRD_WORKORDER_MEMOID, A12.MEMO_ID,SUM(QUANTITY) AS QUANTITY                         
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET A11                                
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST A12 ON A11.MEMO_ID=A12.MEMO_ID                                
  GROUP BY A12.MEMO_ID,REF_PRD_WORKORDER_MEMOID                   
  UNION ALL                
  SELECT A11.REF_PRD_WORKORDER_MEMOID, A11 .REF_ISSUE_ID,SUM(QUANTITY) AS QUANTITY FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING  A11                                
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING  A12 ON A11.MEMO_ID=A12.MEMO_ID                   
  GROUP BY A11.REF_PRD_WORKORDER_MEMOID, A11 .REF_ISSUE_ID                        
  ) A                
  GROUP BY A.REF_PRD_WORKORDER_MEMOID, A.MEMO_ID                      
  ) T51 ON T51.MEMO_ID=T1.MEMO_ID  AND DT1.REF_PRD_WORKORDER_MEMOID=T51.REF_PRD_WORKORDER_MEMOID'         
                  
 SET @DTSQL1=N' JOIN ARTICLE AR ON AR.ARTICLE_CODE = R.ARTICLE_CODE                       
  JOIN PARA1 P1 ON P1.PARA1_CODE=R.PARA1_CODE                          
  JOIN PARA2 P2 ON P2.PARA2_CODE=R.PARA2_CODE                       
  LEFT OUTER JOIN            
  ( SELECT A.JOB_CODE,A.ARTICLE_TYPE ,CALCULATION,--1 FOR FG 2 FOR RM                  
  AGENCY_CODE,ARTICLE_CODE,CASE WHEN RATE=0 THEN STD_RATE ELSE  RATE END AS NEW_RATE                  
  FROM PRD_JOB_RATE_MST A                  
  LEFT JOIN PRD_JOB_RATE_DET B ON A.JOB_CODE=B.JOB_CODE                  
  WHERE B.AGENCY_CODE='''+@CAGENCYCODE+'''  AND ARTICLE_TYPE=1    
  ) RT ON DT1.JOB_CODE=RT.JOB_CODE  AND RT.ARTICLE_CODE= R.ARTICLE_CODE   
   --  
  LEFT OUTER JOIN  
  (  
      
  SELECT   A.REF_AGENCY_CODE ,A.JOB_CODE , A.MEMO_ID ,A. ORDER_ID,  
           A.COM_PARA1_CODE   ,A.COM_PARA2_CODE,  
           SUM(A.RATE  ) AS C_RATE  
   FROM  
   (  
      
    SELECT A.REF_AGENCY_CODE ,A.JOB_CODE , A.MEMO_ID ,A.REF_COMPONENT_ARTICLE_CODE ,A. ORDER_ID,  
           A.COM_PARA1_CODE   ,A.COM_PARA2_CODE,JR.RATE    
    FROM  
    (  
    SELECT B.REF_AGENCY_CODE ,A.JOB_CODE , B.MEMO_ID ,A.REF_COMPONENT_ARTICLE_CODE ,A.REF_PRD_WORKORDER_MEMOID AS ORDER_ID,  
           C.COM_PARA1_CODE   ,C.COM_PARA2_CODE         
    FROM PRD_AGENCY_ISSUE_MATERIAL_DET A  
    JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID =B.MEMO_ID   
    JOIN  PRD_SKU C ON A.PRODUCT_UID =C.PRODUCT_UID   
    WHERE B.CANCELLED =0  
    AND B.REF_AGENCY_CODE='''+@CAGENCYCODE+'''  
    AND A.REF_PRD_WORKORDER_MEMOID '+@CORDER_ID+'   
    GROUP BY B.REF_AGENCY_CODE ,A.JOB_CODE ,B.MEMO_ID ,A.REF_COMPONENT_ARTICLE_CODE ,A.REF_PRD_WORKORDER_MEMOID ,  
           C.COM_PARA1_CODE   ,C.COM_PARA2_CODE   
    UNION   
    SELECT B.REF_AGENCY_CODE,A.JOB_CODE , A.REF_ISSUE_ID  ,A.REF_COMPONENT_ARTICLE_CODE ,A.REF_PRD_WORKORDER_MEMOID AS ORDER_ID,  
           C.COM_PARA1_CODE   ,C.COM_PARA2_CODE         
    FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING  A  
    JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING  B ON A.MEMO_ID =B.MEMO_ID   
    JOIN  PRD_SKU C ON A.PRODUCT_UID =C.PRODUCT_UID   
    WHERE B.CANCELLED =0  
   AND B.REF_AGENCY_CODE='''+@CAGENCYCODE+'''  
    AND A.REF_PRD_WORKORDER_MEMOID '+@CORDER_ID+'   
    GROUP BY B.REF_AGENCY_CODE ,A.JOB_CODE ,A.REF_ISSUE_ID  ,A.REF_COMPONENT_ARTICLE_CODE ,A.REF_PRD_WORKORDER_MEMOID ,  
           C.COM_PARA1_CODE   ,C.COM_PARA2_CODE  
     ) A  
     JOIN  
     (  
       
      SELECT A.JOB_CODE ,B.AGENCY_CODE ,B.ARTICLE_CODE ,B.RATE   
      FROM PRD_JOB_RATE_MST A  
      JOIN PRD_JOB_RATE_DET  B ON A.JOB_CODE=B.JOB_CODE  
      WHERE B.AGENCY_CODE='''+@CAGENCYCODE+'''   
     ) JR ON A.JOB_CODE =JR.JOB_CODE   
     AND A.REF_AGENCY_CODE =JR.AGENCY_CODE   
     AND A.REF_COMPONENT_ARTICLE_CODE =JR.ARTICLE_CODE   
       
    GROUP BY A.REF_AGENCY_CODE ,A.JOB_CODE , A.MEMO_ID ,A.REF_COMPONENT_ARTICLE_CODE ,A. ORDER_ID,  
           A.COM_PARA1_CODE   ,A.COM_PARA2_CODE,JR.RATE   
    )A     
    GROUP BY  A.REF_AGENCY_CODE ,A.JOB_CODE , A.MEMO_ID ,A. ORDER_ID,  
           A.COM_PARA1_CODE   ,A.COM_PARA2_CODE      
      
  ) CR ON CR.MEMO_ID =T1.MEMO_ID  
  AND CR.REF_AGENCY_CODE =T1.REF_AGENCY_CODE   
  AND CR.ORDER_ID =DT1.REF_PRD_WORKORDER_MEMOID  
  AND CR.COM_PARA1_CODE =P1.PARA1_CODE   
  AND CR.COM_PARA2_CODE =P2.PARA2_CODE   
  --  
                    
  LEFT OUTER JOIN DEFAULT_BASIS_MASTER DF ON DF.DEFAULT_BASIS_VALUE=RT.CALCULATION                     
  WHERE T1.REF_AGENCY_CODE='''+@CAGENCYCODE+''' AND T1.CANCELLED =0                               
  --AND ISNULL(T5.QT1,0)<ISNULL(T51.QUANTITY,0)                    
 AND R.ISSUE_QTY-ISNULL(T5.REC_QTY,0)>0                
  AND T1.DEPARTMENT_ID='''+@CDEPARTMENTID+'''                      
  AND DT1.REF_PRD_WORKORDER_MEMOID '+@CORDER_ID+'   
  ORDER BY DT1.REF_PRD_WORKORDER_MEMOID ,P1.PARA1_NAME , P2.PARA2_NAME'                      
                      
--PRINT @DTSQL                      
--EXEC SP_EXECUTESQL  @DTSQL                      
                      
--PRINT @DTSQL                      
PRINT @DTSQL                 
PRINT @DTSQL1                     
                      
EXECUTE(  @DTSQL      +@DTSQL1)                
--EXEC SP_EXECUTESQL  @DTSQL1                      
                        
END                           
                       
GOTO LAST                      
                         
LBLORDER:                         
                       
  SELECT CAST(0 AS BIT) AS CHCK,                   
  DT1.REF_PRD_WORKORDER_MEMOID AS MEMO_ID  ,RIGHT(DT1.REF_PRD_WORKORDER_MEMOID,10) AS MEMO_NO,T1.MEMO_DT ,  
  T4.MEMO_DT AS ORDER_DT  
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET DT1                             
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST T1 ON T1.MEMO_ID=DT1.MEMO_ID                                      
  JOIN PRD_DEPARTMENT_MST T3 ON T1.DEPARTMENT_ID = T3.DEPARTMENT_ID                                      
  JOIN JOBS ON JOBS.JOB_CODE = DT1.JOB_CODE                 
  LEFT OUTER JOIN PRD_WO_MST T4 ON DT1.REF_PRD_WORKORDER_MEMOID = T4.MEMO_ID                                      
  LEFT OUTER JOIN                                       
  (                              
  SELECT DT2.MEMO_ID, SUM(DT1.QUANTITY) AS  QT1                                
  FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT1                                
  JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT1 ON MT1.MEMO_ID=DT1.MEMO_ID             
  JOIN             
  (            
   SELECT A.MEMO_ID, A.ROW_ID FROM PRD_AGENCY_ISSUE_MATERIAL_DET A            
   JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID=B.MEMO_ID            
   WHERE B.CANCELLED=0           
   AND B.REF_AGENCY_CODE=@CAGENCYCODE     
   UNION ALL            
   SELECT A.REF_ISSUE_ID, A.ROW_ID FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING A            
   JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING B ON A.MEMO_ID=B.MEMO_ID            
   WHERE B.CANCELLED=0            
   AND B.REF_AGENCY_CODE=@CAGENCYCODE  
  ) DT2 ON DT1.REF_ROW_ID =DT2.ROW_ID                                
  WHERE MT1.CANCELLED=0  AND MT1.AGENCY_CODE =@CAGENCYCODE                               
  GROUP BY DT2.MEMO_ID                                 
 )  T5 ON DT1.MEMO_ID= T5.MEMO_ID                                
  JOIN PRD_AGENCY_MST T6 ON T6.AGENCY_CODE=T1.REF_AGENCY_CODE                                     
  JOIN                              
  (                              
  SELECT A.MEMO_ID ,SUM( QUANTITY) AS QUANTITY                
  FROM                
  (                         
  SELECT A12.MEMO_ID,SUM(QUANTITY) AS QUANTITY FROM PRD_AGENCY_ISSUE_MATERIAL_DET A11                                
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST A12 ON A11.MEMO_ID=A12.MEMO_ID            
  WHERE A12.CANCELLED=0       
   AND A12.REF_AGENCY_CODE=@CAGENCYCODE        
  GROUP BY A12.MEMO_ID                  
  UNION ALL                
  SELECT A11 .REF_ISSUE_ID,SUM(QUANTITY) AS QUANTITY FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING  A11                                
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING  A12 ON A11.MEMO_ID=A12.MEMO_ID                   
  WHERE A12.CANCELLED=0           
  AND A12.REF_AGENCY_CODE=@CAGENCYCODE             
  GROUP BY  A11.REF_ISSUE_ID                  
  ) A                 
  GROUP BY A.MEMO_ID                                
  ) T51 ON T51.MEMO_ID=T1.MEMO_ID                              
                                  
  WHERE T1.REF_AGENCY_CODE=@CAGENCYCODE AND T1.CANCELLED =0 
  AND ISNULL(T4.MARK_AS_COMPLETED,0)<>2
  AND ISNULL(T5.QT1,0)<ISNULL(T51.QUANTITY,0)                       
  AND T1.DEPARTMENT_ID=@CDEPARTMENTID                       
  GROUP BY  DT1.REF_PRD_WORKORDER_MEMOID ,T1.MEMO_DT  ,T4.MEMO_DT                    
                         
                       
GOTO LAST                             
                              
                    
                              
                              
LBLGETMASTER1:                                  
 SELECT  T1.[AC_CODE],T1.[MEMO_ID],T1.[MEMO_NO],T1.[MEMO_DT],T1.[LAST_UPDATE],T1.[TS],T1.[COMPANY_CODE],T1.[FIN_YEAR]                              
 ,T1.[USER_CODE],T1.[REF_NO],T1.[SENT_TO_HO],T1.[CANCELLED],T1.[MODE],T1.[DEPARTMENT_ID]                              
 ,T1.[AGENCY_CODE],T1.[SUBTOTAL],T1.[DISCOUNT_PER],T1.[DISCOUNT_AMOUNT],T1.[NET_AMOUNT],T1.[TDS]                              
 ,T1.[AGENCY_CHALLAN_NO],T1.[AGENCY_CHALLAN_DT],T1.[AGENCY_BILL_NO],T1.[AGENCY_BILL_DT]                              
 ,T1.[REMARKS],T1.[RECEIVEDBY]                              
 ,T1.[FREIGHT],T1.[OTHERCHARGES],T1.[ROUNDOFF],ISNULL(T2.AGENCY_NAME,'') AS AGENCY_NAME,ISNULL(T3.USERNAME,'') AS USERNAME                              
 FROM PRD_AGENCY_MATERIAL_RECEIPT_MST T1                                
 LEFT OUTER JOIN PRD_AGENCY_MST T2 ON T1.AGENCY_CODE=T2.AGENCY_CODE                              
 LEFT OUTER JOIN USERS T3 ON T3.USER_CODE=T1.USER_CODE                         
 WHERE T1.MEMO_ID=@CMEMOID --AND T1.CANCELLED=0                              
                          
 GOTO LAST                                  
                              
                              
                                 
LBLGETMASTER:                          
                          
      DECLARE @DTSQL2 NVARCHAR(MAX),@DTSQL3 NVARCHAR(MAX),@DTSQL4 VARCHAR(MAX)                  
                            
   SET @DTSQL=N'                   
   SELECT CHCK,ARTICLE_NO,ARTICLE_CODE,REF_WO_ID,REF_WO_NO,MEMO_ID,                  
   ISSUE_MEMO_NO,ISSUE_DT,                  
   SUM(AVG_QTY) AS AVG_QTY,                 
   SUM(REQUIRED_QTY) AS REQUIRED_QTY,                  
  REC_QTY,                      
  PARA1_CODE,                      
  PARA2_CODE,                      
  REF_MATERIAL_ROW_ID FROM                  
   (                  
   SELECT CHCK,ARTICLE_NO,ARTICLE_CODE,REF_WO_ID,REF_WO_NO,MEMO_ID,                  
   ISSUE_MEMO_NO,ISSUE_DT,                  
   BM_ARTICLE_CODE,                  
   (AVG_QTY) AS AVG_QTY,                  
   SUM(REQUIRED_QTY) AS REQUIRED_QTY,                  
  REC_QTY,                      
  PARA1_CODE,                      
  PARA2_CODE,                      
  REF_MATERIAL_ROW_ID FROM                  
   (                  
   SELECT DISTINCT  CAST(0 AS BIT) AS CHCK, AR.ARTICLE_NO,AR.ARTICLE_CODE,                  
    SKU.ARTICLE_CODE AS BM_ARTICLE_CODE,                      
      DT1.REF_PRD_WORKORDER_MEMOID AS REF_WO_ID,                      
      RIGHT(DT1.REF_PRD_WORKORDER_MEMOID,10) AS REF_WO_NO,                      
      T1.MEMO_ID,                      
      T1.MEMO_NO AS ISSUE_MEMO_NO,T1.MEMO_DT AS ISSUE_DT,                      
      (DT1.AVG_QTY   )  AS AVG_QTY,          
      (CONVERT(NUMERIC(12,2),AVG_QTY * '''+STR(@NQTY)+''')) AS REQUIRED_QTY,                      
       0 AS REC_QTY,                      
     COM_PARA1_CODE AS PARA1_CODE,                      
       COM_PARA2_CODE AS PARA2_CODE, 
       CAST(''LATER''+ CAST(RIGHT(DT1.REF_PRD_WORKORDER_MEMOID,10)+T1.MEMO_NO+COM_PARA1_CODE+COM_PARA2_CODE AS VARCHAR(100)) AS VARCHAR(40))  AS REF_MATERIAL_ROW_ID                   
      -- CAST(''''           AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID                      
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET (NOLOCK) DT1                                  
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST (NOLOCK) T1 ON T1.MEMO_ID=DT1.MEMO_ID                                      
  JOIN ARTICLE (NOLOCK) AR ON AR.ARTICLE_CODE=DT1.REF_COMPONENT_ARTICLE_CODE                      
  JOIN PRD_SKU SKU (NOLOCK) ON SKU.PRODUCT_UID=DT1.PRODUCT_UID                        
  JOIN REC_RAW_MATERIAL_UPLOAD TMP ON           
  TMP.WO_ID=DT1.REF_PRD_WORKORDER_MEMOID           
  AND TMP.ISSUE_MEMO_ID=DT1.MEMO_ID                 
  AND TMP.PARA1_CODE=SKU.COM_PARA1_CODE          
  AND TMP.PARA2_CODE=SKU.COM_PARA2_CODE          
  LEFT OUTER JOIN PRD_WO_MST T4 ON DT1.REF_PRD_WORKORDER_MEMOID = T4.MEMO_ID                                      
  LEFT OUTER JOIN                                       
  (                              
  SELECT DT2.MEMO_ID, SUM(DT1.QUANTITY) AS  QT1                                
  FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT1                                
  JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT1 ON MT1.MEMO_ID=DT1.MEMO_ID                                
  JOIN PRD_AGENCY_ISSUE_MATERIAL_DET DT2 ON DT1.REF_ROW_ID =DT2.ROW_ID                                
  WHERE MT1.CANCELLED=0                                
  GROUP BY DT2.MEMO_ID                                 
  )  T5 ON DT1.MEMO_ID= T5.MEMO_ID                             
  JOIN PRD_AGENCY_MST T6 ON T6.AGENCY_CODE=T1.REF_AGENCY_CODE                                     
  JOIN                              
  (                             
  SELECT A12.MEMO_ID,SUM(QUANTITY) AS QUANTITY FROM PRD_AGENCY_ISSUE_MATERIAL_DET A11                              
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST A12 ON A11.MEMO_ID=A12.MEMO_ID                              
  GROUP BY A12.MEMO_ID                              
  ) T51 ON T51.MEMO_ID=T1.MEMO_ID'                              
                                 
 SET @DTSQL1=N' WHERE T1.REF_AGENCY_CODE='''+@CAGENCYCODE+''' AND T1.CANCELLED =0            
  AND TMP.SP_ID='''+RTRIM(LTRIM(STR(@NSP_ID)))+'''                         
  AND ISNULL(T5.QT1,0)<ISNULL(T51.QUANTITY,0)                
  AND T1.DEPARTMENT_ID='''+@CDEPARTMENTID+'''                      
  AND T1.MEMO_ID '+@CMEMOID+'                      
  AND SKU.COM_PARA1_CODE  '+@CPARA1_CODE+'                      
  AND SKU.COM_PARA2_CODE  '+@CPARA2_CODE+'                    
  AND DT1.REF_PRD_WORKORDER_MEMOID  '+@CORDER_ID+'                    
  '                             
 SET @DTSQL2=N' UNION ALL  SELECT DISTINCT CAST(0 AS BIT) AS CHCK, AR.ARTICLE_NO,AR.ARTICLE_CODE,                   
      SKU.ARTICLE_CODE AS BM_ARTICLE_CODE,                     
      DT1.REF_PRD_WORKORDER_MEMOID AS REF_WO_ID,                      
      RIGHT(DT1.REF_PRD_WORKORDER_MEMOID,10) AS REF_WO_NO,                      
   MST.MEMO_ID AS MEMO_ID,                      
      MST.MEMO_NO  AS ISSUE_MEMO_NO,MST.MEMO_DT AS ISSUE_DT,                      
      (DT1.AVG_QTY   )  AS AVG_QTY,                      
      (CONVERT(NUMERIC(12,2),AVG_QTY * '''+STR(@NQTY)+''')) AS REQUIRED_QTY,                      
       0 AS REC_QTY,                      
       COM_PARA1_CODE AS PARA1_CODE,                      
       COM_PARA2_CODE AS PARA2_CODE,                      
       CAST(''''           AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID                      
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING (NOLOCK) DT1                                  
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING (NOLOCK) T1 ON T1.MEMO_ID=DT1.MEMO_ID            
  JOIN ARTICLE (NOLOCK) AR ON AR.ARTICLE_CODE=DT1.REF_COMPONENT_ARTICLE_CODE                      
  JOIN PRD_SKU SKU (NOLOCK) ON SKU.PRODUCT_UID=DT1.PRODUCT_UID                        
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST MST ON MST.MEMO_ID=DT1.REF_ISSUE_ID           
  JOIN REC_RAW_MATERIAL_UPLOAD TMP ON           
  TMP.WO_ID=DT1.REF_PRD_WORKORDER_MEMOID           
  AND TMP.ISSUE_MEMO_ID=DT1.REF_ISSUE_ID                 
  AND TMP.PARA1_CODE=SKU.COM_PARA1_CODE          
  AND TMP.PARA2_CODE=SKU.COM_PARA2_CODE                     
  LEFT OUTER JOIN PRD_WO_MST T4 ON DT1.REF_PRD_WORKORDER_MEMOID = T4.MEMO_ID                             
  LEFT OUTER JOIN                                       
  (                              
  SELECT DT2.MEMO_ID AS MEMO_ID, SUM(DT1.QUANTITY) AS  QT1                                
  FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT1                                
  JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT1 ON MT1.MEMO_ID=DT1.MEMO_ID                                
  JOIN PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING DT2 ON DT1.REF_ROW_ID =DT2.ROW_ID                                
  WHERE MT1.CANCELLED=0                                
  GROUP BY DT2.MEMO_ID                                 
  )  T5 ON DT1.MEMO_ID= T5.MEMO_ID                                
  JOIN PRD_AGENCY_MST T6 ON T6.AGENCY_CODE=T1.REF_AGENCY_CODE                                     
  JOIN                              
  (                              
  SELECT A12.MEMO_ID,SUM(QUANTITY) AS QUANTITY FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING A11                              
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING A12 ON A11.MEMO_ID=A12.MEMO_ID                              
  GROUP BY A12.MEMO_ID                              
  ) T51 ON T51.MEMO_ID=T1.MEMO_ID '                             
                                 
  SET @DTSQL3=N'WHERE T1.REF_AGENCY_CODE='''+@CAGENCYCODE+''' AND T1.CANCELLED =0           
  AND TMP.SP_ID='''+RTRIM(LTRIM(STR(@NSP_ID)))+'''                           
  AND ISNULL(T5.QT1,0)<ISNULL(T51.QUANTITY,0)                      
  AND T1.DEPARTMENT_ID='''+@CDEPARTMENTID+'''                      
  AND DT1.REF_ISSUE_ID '+@CMEMOID+'                      
  AND SKU.COM_PARA1_CODE  '+@CPARA1_CODE+'                      
  AND SKU.COM_PARA2_CODE  '+@CPARA2_CODE+'                    
   AND DT1.REF_PRD_WORKORDER_MEMOID  '+@CORDER_ID+'                      
   ) A '      
                    
  SET @DTSQL4=N'GROUP BY  CHCK,ARTICLE_NO,ARTICLE_CODE,REF_WO_ID,REF_WO_NO,MEMO_ID,                  
   ISSUE_MEMO_NO,ISSUE_DT,                  
   BM_ARTICLE_CODE,                  
  REC_QTY,AVG_QTY,                      
  PARA1_CODE,                      
  PARA2_CODE,                      
  REF_MATERIAL_ROW_ID                  
  ) A                  
  GROUP BY CHCK,ARTICLE_NO,ARTICLE_CODE,REF_WO_ID,REF_WO_NO,MEMO_ID,                  
   ISSUE_MEMO_NO,ISSUE_DT,                  
  REC_QTY,                      
  PARA1_CODE,                      
  PARA2_CODE,                      
  REF_MATERIAL_ROW_ID'                       
  PRINT  @DTSQL                          
 PRINT  @DTSQL1                      
 SET  @DTSQL=@DTSQL+@DTSQL1 +@DTSQL2+@DTSQL3+@DTSQL4                     
                      
 EXEC SP_EXECUTESQL @DTSQL                      
    -- AND REF_PRD_WORKORDER_MEMOID='HO0111700000HO00000532'                       
GOTO LAST                      
                      
                                       
                              
                                   
                                      
                                      
LBLGETDETAILS:                                
DECLARE @CQRY VARCHAR(MAX)                                
SET @CQRY=N'SELECT T1.[LAST_UPDATE],T1.[ADDITIONAL_QUANTITY]                                  
  ,T1.[ARTICLE_CODE],SKU.[PARA1_CODE],SKU.[PARA2_CODE],T1.[AVG_QTY],T1.[MEMO_ID],                      
  T1.ROW_ID AS [REF_ROW_ID],T1.[TYPE]                                  
  ,T1.[REF_COMPONENT_ARTICLE_CODE],ISNULL(T1.[GROSS_WEIGHT],0) AS GROSS_WEIGHT,T1.[NO_OF_PCS],T5.CANCELLED'                                
                        
IF(ISNULL(@CMEMOID,'')<>'') -------FOR NAVIGATION                                  
 BEGIN                       
 SET @CQRY1=@CQRY                                 
 SET @CQRY=@CQRY+',T5.MEMO_NO AS ISSUE_MEMO_NO,P1.PARA1_NAME COM_COLOR,P2.PARA2_NAME AS COM_SIZE,                      
  CAST(1 AS  BIT) AS CHK, T4.MEMO_ID AS [RECEIPT_ID],(ISNULL(T4.[QUANTITY],0)) AS QUANTITY,                       
  ISNULL(T4.[RATE],0) AS RATE                                  
  ,ISNULL(T4.[AMOUNT],0) AS AMOUNT,ISNULL(T4.[DISCOUNT_PER],0) AS DISCOUNT_PERCENTAGE                                  
  ,ISNULL(T4.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,ISNULL(T4.[NET_AMOUNT],0) AS NET_AMOUNT,T4.CHALLAN_NO,                                   
  T2.ARTICLE_NO,T2.ARTICLE_NAME,T2.ARTICLE_DESC,UOM.UOM_NAME,                                        
  PARA1.PARA1_NAME,PARA2.PARA2_NAME,T3.ARTICLE_NO AS COMP_ARTICLE_NO ,T1.STOCK_TYPE   --,ISNULL(T4.REF_ROW_ID,'') AS REF_ROW_ID     
 ,ISNULL(T4.XN_PRODUCT_UID,'''') AS XN_PRODUCT_UID                       
  ,SKU.PRODUCT_CODE                        
  ,T4.MANUAL_AMOUNT,T4.MANUAL_RATE                       
  ,T4.PCS                      
  ,T4.AVERAGE                      
  ,T4.DEFAULT_BASIS                      
  ,T2.DISCON                      
  ,0 AS RATE_PCS                      
  ,0 AS RATE_DAYS                      
  ,0 AS RATE_HOURS                      
  ,0 AS RATE_MTR                      
  ,DEFAULT_BASIS_NAME                       
  ,RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10) AS WORKORDERNO                      
  ,J.JOB_CODE                      
  ,J.JOB_NAME                 
  ,T4.REF_MATERIAL_ROW_ID                 
  ,T4.ROW_ID             
  ,PARA4.PARA4_NAME                   
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET T1                                       
  JOIN ARTICLE T2 ON T1.ARTICLE_CODE = T2.ARTICLE_CODE                                      
  JOIN UOM ON T2.UOM_CODE = UOM.UOM_CODE                                  
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=T1.PRODUCT_UID                                   
  JOIN PARA1 ON SKU.PARA1_CODE = PARA1.PARA1_CODE                                       
  JOIN PARA2 ON SKU.PARA2_CODE = PARA2.PARA2_CODE              
  JOIN PARA4 ON SKU.PARA4_CODE = PARA4.PARA4_CODE                                       
  JOIN ARTICLE T3 ON T1.REF_COMPONENT_ARTICLE_CODE = T3.ARTICLE_CODE                                     
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST T5 ON T5.MEMO_ID=T1.MEMO_ID                       
  LEFT JOIN PARA1 P1 ON SKU.COM_PARA1_CODE=P1.PARA1_CODE                      
  LEFT JOIN PARA2 P2 ON SKU.COM_PARA2_CODE=P2.PARA2_CODE                      
  JOIN JOBS J ON J.JOB_CODE=T1.JOB_CODE                       
  LEFT OUTER JOIN                                 
  (                                 
   SELECT DT.PCS,DT.AVERAGE,DT.DEFAULT_BASIS ,DT.XN_PRODUCT_UID,DT.MEMO_ID,                       
   DT.REF_ROW_ID,SUM(ISNULL(DT.QUANTITY,0)) AS QUANTITY                                 
   ,ISNULL(DT.[RATE],0) AS RATE                                  
   ,ISNULL(DT.[AMOUNT],0) AS AMOUNT,ISNULL(DT.[DISCOUNT_PER],0) AS DISCOUNT_PER                                
   ,ISNULL(DT.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,ISNULL(DT.[NET_AMOUNT],0) AS NET_AMOUNT, DT.CHALLAN_NO                       
   ,DT.MANUAL_AMOUNT                      
   ,DT.MANUAL_RATE                
   ,DT.REF_MATERIAL_ROW_ID                 
   ,DT.ROW_ID                              
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT                                
   LEFT OUTER JOIN PRD_AGENCY_ISSUE_MATERIAL_DET T11 ON DT.REF_ROW_ID=T11.ROW_ID                 
   GROUP BY DT.PCS,DT.AVERAGE,DT.DEFAULT_BASIS, DT.XN_PRODUCT_UID,DT.REF_ROW_ID,DT.MEMO_ID ,DT.RATE, DT.AMOUNT , DT.DISCOUNT_PER,DT.DISCOUNT_AMOUNT,DT.NET_AMOUNT, DT.CHALLAN_NO                      
    ,DT.MANUAL_AMOUNT,DT.MANUAL_RATE ,DT.REF_MATERIAL_ROW_ID,DT.ROW_ID                       
  ) T4 ON T4.REF_ROW_ID=T1.ROW_ID                        
  LEFT JOIN DEFAULT_BASIS_MASTER DM (NOLOCK) ON DM.DEFAULT_BASIS_VALUE =T4.DEFAULT_BASIS                              
  WHERE T4.MEMO_ID='''+@CMEMOID+''' UNION ALL '                       
                        
   SET @CQRY1=@CQRY1+',T5.MEMO_NO AS ISSUE_MEMO_NO,P1.PARA1_NAME COM_COLOR,P2.PARA2_NAME AS COM_SIZE,                      
  CAST(1 AS  BIT) AS CHK, T4.MEMO_ID AS [RECEIPT_ID],(ISNULL(T4.[QUANTITY],0)) AS QUANTITY,                       
  ISNULL(T4.[RATE],0) AS RATE                                  
  ,ISNULL(T4.[AMOUNT],0) AS AMOUNT,ISNULL(T4.[DISCOUNT_PER],0) AS DISCOUNT_PERCENTAGE                                  
  ,ISNULL(T4.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,ISNULL(T4.[NET_AMOUNT],0) AS NET_AMOUNT,T4.CHALLAN_NO,                                   
  T2.ARTICLE_NO,T2.ARTICLE_NAME,T2.ARTICLE_DESC,UOM.UOM_NAME,                                        
  PARA1.PARA1_NAME,PARA2.PARA2_NAME,T3.ARTICLE_NO AS COMP_ARTICLE_NO ,T1.STOCK_TYPE   --,ISNULL(T4.REF_ROW_ID,'') AS REF_ROW_ID                                  
 ,ISNULL(T4.XN_PRODUCT_UID,'''') AS XN_PRODUCT_UID                       
  ,SKU.PRODUCT_CODE                        
  ,T4.MANUAL_AMOUNT,T4.MANUAL_RATE                       
  ,T4.PCS                      
  ,T4.AVERAGE                      
  ,T4.DEFAULT_BASIS                      
  ,T2.DISCON                      
  ,0 AS RATE_PCS                      
  ,0 AS RATE_DAYS                      
  ,0 AS RATE_HOURS                      
  ,0 AS RATE_MTR                      
  ,DEFAULT_BASIS_NAME                       
  ,RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10) AS WORKORDERNO                      
  ,J.JOB_CODE                      
  ,J.JOB_NAME                     
  ,T4.REF_MATERIAL_ROW_ID                  
  ,T4.ROW_ID              
  ,PARA4.PARA4_NAME              
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING T1                                       
  JOIN ARTICLE T2 ON T1.ARTICLE_CODE = T2.ARTICLE_CODE                          
  JOIN UOM ON T2.UOM_CODE = UOM.UOM_CODE                                      
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=T1.PRODUCT_UID                                   
  JOIN PARA1 ON SKU.PARA1_CODE = PARA1.PARA1_CODE                                       
  JOIN PARA2 ON SKU.PARA2_CODE = PARA2.PARA2_CODE                                       
  JOIN ARTICLE T3 ON T1.REF_COMPONENT_ARTICLE_CODE = T3.ARTICLE_CODE                                     
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING T5 ON T5.MEMO_ID=T1.MEMO_ID                   
  LEFT JOIN PARA1 P1 ON SKU.COM_PARA1_CODE=P1.PARA1_CODE                      
  LEFT JOIN PARA2 P2 ON SKU.COM_PARA2_CODE=P2.PARA2_CODE              
  JOIN PARA4 ON SKU.PARA4_CODE = PARA4.PARA4_CODE                     
  JOIN JOBS J ON J.JOB_CODE=T1.JOB_CODE                       
  LEFT OUTER JOIN                                 
  (                                 
   SELECT DT.PCS,DT.AVERAGE,DT.DEFAULT_BASIS ,DT.XN_PRODUCT_UID,DT.MEMO_ID,                       
   DT.REF_ROW_ID,SUM(ISNULL(DT.QUANTITY,0)) AS QUANTITY                                 
   ,ISNULL(DT.[RATE],0) AS RATE                                  
   ,ISNULL(DT.[AMOUNT],0) AS AMOUNT,ISNULL(DT.[DISCOUNT_PER],0) AS DISCOUNT_PER                                
   ,ISNULL(DT.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,ISNULL(DT.[NET_AMOUNT],0) AS NET_AMOUNT, DT.CHALLAN_NO                       
   ,DT.MANUAL_AMOUNT                      
   ,DT.MANUAL_RATE                
   ,DT.REF_MATERIAL_ROW_ID                 
   ,DT.ROW_ID                               
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT                                
   LEFT OUTER JOIN PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING T11 ON DT.REF_ROW_ID=T11.ROW_ID                                   
   GROUP BY DT.PCS,DT.AVERAGE,DT.DEFAULT_BASIS,DT.XN_PRODUCT_UID,DT.REF_ROW_ID,DT.MEMO_ID ,DT.RATE, DT.AMOUNT , DT.DISCOUNT_PER,DT.DISCOUNT_AMOUNT,DT.NET_AMOUNT, DT.CHALLAN_NO             
    ,DT.MANUAL_AMOUNT,DT.MANUAL_RATE ,DT.REF_MATERIAL_ROW_ID,DT.ROW_ID                       
  ) T4 ON T4.REF_ROW_ID=T1.ROW_ID                        
  LEFT JOIN DEFAULT_BASIS_MASTER DM (NOLOCK) ON DM.DEFAULT_BASIS_VALUE =T4.DEFAULT_BASIS                              
  WHERE T4.MEMO_ID='''+@CMEMOID+''''              
--PRINT @CQRY
--PRINT @CQRY1            
EXECUTE (@CQRY+@CQRY1)                      
  GOTO LAST                               
END                                  
ELSE                                   
 BEGIN      ------FOR DATA EXTRACTION                         
              
-- SET @CQRY1=@CQRY        
DECLARE @CQRY2 NVARCHAR(MAX)                  
                                
 SET @CQRY=@CQRY+',SKU.[COM_PARA1_CODE],SKU.[COM_PARA2_CODE],                  
 CAST(0 AS NUMERIC(10,2)) AS QUANTITY   --(ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0))                       
   ,CONVERT(NUMERIC(12,2),(AVG_QTY * (ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0))))   AS REC_QTY                   
  , ISNULL(T4.[AMOUNT],0) AS AMOUNT, --T1.AMOUNT                      
  ISNULL(T1.[DISCOUNT_PERCENTAGE],0) AS DISCOUNT_PERCENTAGE                                  
  ,ISNULL(T1.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,                      
  ISNULL(T4.[NET_AMOUNT],0) AS NET_AMOUNT,                        
  T4.CHALLAN_NO,                        
  T5.MEMO_NO AS ISSUE_MEMO_NO,                              
  T2.ARTICLE_NO,T2.ARTICLE_NAME,T2.ARTICLE_DESC,UOM.UOM_NAME,                                        
  PARA1.PARA1_NAME,PARA2.PARA2_NAME,T3.ARTICLE_NO AS COMP_ARTICLE_NO ,T1.STOCK_TYPE   --,ISNULL(T4.REF_ROW_ID,'') AS REF_ROW_ID                                  
  ,ISNULL(T1.PRODUCT_UID,'''') AS XN_PRODUCT_UID                        
  ,SKU.PRODUCT_CODE,                      
  T2.DISCON,                      
  CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.DEFAULT_BASIS                               
  ELSE 1 END   AS DEFAULT_BASIS ,                   
                       
    ISNULL(NEW_RATE,CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.RATE                             
  ELSE 0 END) AS RATE ,                  
  T1.PCS,T1.AVERAGE,(T1.QUANTITY -ISNULL(T4.QUANTITY,0)) AS QUANTITY_IN_STOCK,                      
                 
                  
   CASE WHEN ISNULL(AJ.JOB_RATE_PCS,0)<>0 THEN AJ.JOB_RATE_PCS                      
        ELSE 0 END AS RATE_PCS,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_DAYS,0)<>0 THEN AJ.JOB_RATE_DAYS                      
       ELSE 0 END AS RATE_DAYS,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_HOURS,0)<>0 THEN AJ.JOB_RATE_HOURS                      
        ELSE 0 END AS RATE_HOURS,                      
   CASE WHEN ISNULL(AJ.RATE_MTR,0)<>0 THEN AJ.RATE_MTR                      
        ELSE 0 END AS RATE_MTR                
                       
  , DEFAULT_BASIS_NAME                      
  ,RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10) AS WORKORDERNO                      
  ,T1.REF_PRD_WORKORDER_MEMOID AS WO_ID  , 
  CAST(''LATER''+ CAST(RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10)+T5.MEMO_NO+SKU.COM_PARA1_CODE+SKU.COM_PARA2_CODE AS VARCHAR(100)) AS VARCHAR(40)) AS REF_MATERIAL_ROW_ID,
  --,CAST('''' AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID,                      
  T1.JOB_CODE,                      
  JOBS.JOB_NAME  ,                
  ROW_ID=CAST(''LATER''+CAST(NEWID() AS VARCHAR(100)) AS VARCHAR(40)),            
  T2.CODING_SCHEME,            
  PARA4.PARA4_NAME               
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET T1                   
  JOIN PRD_WO_MST MST ON MST.MEMO_ID= T1.REF_PRD_WORKORDER_MEMOID                                    
  JOIN ARTICLE T2 ON T1.ARTICLE_CODE = T2.ARTICLE_CODE                                      
  JOIN UOM ON T2.UOM_CODE = UOM.UOM_CODE                                     
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=T1.PRODUCT_UID            
  JOIN PRD_PMT PMT ON PMT.PRODUCT_UID=SKU.PRODUCT_UID              
  --AND PMT.QUANTITY_IN_STOCK= (CASE WHEN UOM.UOM_NAME=''PCS'' AND T2.CODING_SCHEME=3  THEN 1 ELSE PMT.QUANTITY_IN_STOCK END )            
  AND PMT.DEPARTMENT_ID='''+@CDEPARTMENTID+'''                                   
  JOIN PARA1 ON SKU.PARA1_CODE = PARA1.PARA1_CODE                                       
  JOIN PARA2 ON SKU.PARA2_CODE = PARA2.PARA2_CODE             
  JOIN PARA4 ON SKU.PARA4_CODE = PARA4.PARA4_CODE                                       
  JOIN ARTICLE T3 ON T1.REF_COMPONENT_ARTICLE_CODE = T3.ARTICLE_CODE                                     
 JOIN PRD_AGENCY_ISSUE_MATERIAL_MST T5 ON T5.MEMO_ID=T1.MEMO_ID                      
  LEFT OUTER JOIN                  
  (                  
  SELECT A.JOB_CODE,A.ARTICLE_TYPE ,--1 FOR FG 2 FOR RM                  
  AGENCY_CODE,ARTICLE_CODE,CASE WHEN RATE=0 THEN STD_RATE ELSE  RATE END AS NEW_RATE                  
  FROM PRD_JOB_RATE_MST A                  
  JOIN PRD_JOB_RATE_DET B ON A.JOB_CODE=B.JOB_CODE                  
  WHERE B.AGENCY_CODE='''+@CAGENCYCODE +''' AND ARTICLE_TYPE=2                  
   ) RT ON T1.JOB_CODE=RT.JOB_CODE                  
   AND RT.ARTICLE_CODE= T2.ARTICLE_CODE                       
  LEFT OUTER JOIN                                 
  (                                 
   SELECT DT.PCS,DT.AVERAGE, DT.REF_ROW_ID,SUM(ISNULL(DT.QUANTITY,0)) AS QUANTITY ,MT.CANCELLED  --DT.XN_PRODUCT_UID,                               
   ,SUM(ISNULL(DT.[RATE],0)) AS RATE                               
   ,0 AS AMOUNT, --SUM(ISNULL(DT.[AMOUNT],0))            
   0 AS DISCOUNT_PER            --SUM(ISNULL(DT.[DISCOUNT_PER],0))                    
   ,0 AS DISCOUNT_AMOUNT,--SUM(ISNULL(DT.[DISCOUNT_AMOUNT],0))            
   0 AS NET_AMOUNT , --SUM(ISNULL(DT.[NET_AMOUNT],0))            
   DT.CHALLAN_NO                                  
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT                                
   JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT ON   MT.MEMO_ID=DT.MEMO_ID                                
   LEFT OUTER JOIN PRD_AGENCY_ISSUE_MATERIAL_DET T11 ON DT.REF_ROW_ID=T11.ROW_ID     
                                   
   WHERE MT.CANCELLED=0                            
   AND T11.MEMO_ID  '+@CORDER_ID+'                      
   GROUP BY DT.PCS,DT.AVERAGE,DT.REF_ROW_ID,MT.CANCELLED, DT.CHALLAN_NO  --,DT.RATE, DT.AMOUNT , DT.DISCOUNT_PER,DT.DISCOUNT_AMOUNT,DT.NET_AMOUNT                                
  ) T4 ON T4.REF_ROW_ID=T1.ROW_ID                            
  LEFT JOIN                      
 (                      
  SELECT DISTINCT DEFAULT_BASIS, A.JOB_CODE,                      
 CASE WHEN ISNULL(DEFAULT_BASIS,0)=1  THEN JOB_RATE                      
       WHEN ISNULL(DEFAULT_BASIS,0)=2  THEN JOB_RATE_PCS                      
       WHEN ISNULL(DEFAULT_BASIS,0)=3  THEN JOB_RATE_DAYS                      
       WHEN ISNULL(DEFAULT_BASIS,0)=4  THEN JOB_RATE_HOURS                      
     ELSE 0 END AS RATE,                      
 JOB_RATE_PCS,                      
    JOB_RATE_DAYS,                      
    JOB_RATE_HOURS,                      
    JOB_RATE AS RATE_MTR                      
 FROM AGENCY_JOBS A (NOLOCK)                      
 WHERE A.AGENCY_CODE='''+@CAGENCYCODE+'''                      
 ) AJ ON T1.JOB_CODE=AJ.JOB_CODE                      
 JOIN JOBS ON JOBS.JOB_CODE=T1.JOB_CODE                      
 LEFT JOIN DEFAULT_BASIS_MASTER DM (NOLOCK) ON DM.DEFAULT_BASIS_VALUE = CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.DEFAULT_BASIS                       
     --WHEN ISNULL(WO.RATE,0)<>0 THEN WO.DEFAULT_BASIS                      
     --WHEN ISNULL(ART_JOBS.DEFAULT_BASIS,0)<>0 THEN ART_JOBS.DEFAULT_BASIS                         
  ELSE 1 END      
  WHERE                        
  T1.MEMO_ID '+@CORDER_ID+' AND                       
  T5.REF_AGENCY_CODE='''+@CAGENCYCODE+'''                       
  AND SKU.COM_PARA1_CODE '+@CPARA1_CODE+'                      
  AND SKU.COM_PARA2_CODE '+@CPARA2_CODE+'                    
  AND T3.ARTICLE_NO '+@CCOMPONENT_NO +'                             
  AND (ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0)) >0                                
   UNION ALL  '                       
                       
  SET @CQRY1='SELECT T1.[LAST_UPDATE],T1.[ADDITIONAL_QUANTITY]                                  
  ,T1.[ARTICLE_CODE],SKU.[PARA1_CODE],SKU.[PARA2_CODE],T1.[AVG_QTY],MST.[MEMO_ID],                      
  T1.ROW_ID AS [REF_ROW_ID],T1.[TYPE]                                  
  ,T1.[REF_COMPONENT_ARTICLE_CODE],ISNULL(T1.[GROSS_WEIGHT],0) AS GROSS_WEIGHT,T1.[NO_OF_PCS],T5.CANCELLED ,            
  SKU.[COM_PARA1_CODE],SKU.[COM_PARA2_CODE],                   
  (AVG_QTY * (ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0))) AS QUANTITY   --(ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0))                  
                  
  ,CONVERT(NUMERIC(12,2),AVG_QTY * '''+STR(@NQTY)+''')  AS REC_QTY     
  , ISNULL(T4.[AMOUNT],0) AS AMOUNT, --T1.AMOUNT                      
  ISNULL(T1.[DISCOUNT_PERCENTAGE],0) AS DISCOUNT_PERCENTAGE                                  
  ,ISNULL(T1.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,                      
  ISNULL(T4.[NET_AMOUNT],0) AS NET_AMOUNT,                        
  T4.CHALLAN_NO,                        
  MST.MEMO_NO AS ISSUE_MEMO_NO,                              
  T2.ARTICLE_NO,T2.ARTICLE_NAME,T2.ARTICLE_DESC,UOM.UOM_NAME,                                        
  PARA1.PARA1_NAME,PARA2.PARA2_NAME,T3.ARTICLE_NO AS COMP_ARTICLE_NO ,T1.STOCK_TYPE   --,ISNULL(T4.REF_ROW_ID,'') AS REF_ROW_ID                                  
  ,ISNULL(T1.PRODUCT_UID,'''') AS XN_PRODUCT_UID                        
  ,SKU.PRODUCT_CODE,                      
  T2.DISCON,                      
  CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.DEFAULT_BASIS                                
  ELSE 1 END   AS DEFAULT_BASIS ,                 
                       
  ISNULL(NEW_RATE,CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.RATE                                 
  ELSE 0 END) AS RATE ,                
                  
  T1.PCS,T1.AVERAGE,(T1.QUANTITY -ISNULL(T4.QUANTITY,0)) AS QUANTITY_IN_STOCK,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_PCS,0)<>0 THEN AJ.JOB_RATE_PCS                      
       ELSE 0 END AS RATE_PCS,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_DAYS,0)<>0 THEN AJ.JOB_RATE_DAYS                      
       ELSE 0 END AS RATE_DAYS,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_HOURS,0)<>0 THEN AJ.JOB_RATE_HOURS                      
       ELSE 0 END AS RATE_HOURS,                      
   CASE WHEN ISNULL(AJ.RATE_MTR,0)<>0 THEN AJ.RATE_MTR                      
        ELSE 0 END AS RATE_MTR, DEFAULT_BASIS_NAME                     
  ,RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10) AS WORKORDERNO                      
  ,T1.REF_PRD_WORKORDER_MEMOID AS WO_ID     
  ,CAST(''LATER''+ CAST(RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10)+T5.MEMO_NO+SKU.COM_PARA1_CODE+SKU.PARA2_CODE AS VARCHAR(100)) AS VARCHAR(40)) AS REF_MATERIAL_ROW_ID,                 
  --,CAST('''' AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID,                      
  T1.JOB_CODE,                      
  JOBS.JOB_NAME ,                
  ROW_ID=CAST(''LATER''+CAST(NEWID() AS VARCHAR(100)) AS VARCHAR(40)),            
  T2.CODING_SCHEME ,            
  PARA4.PARA4_NAME                      
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING T1                                       
  JOIN ARTICLE T2 ON T1.ARTICLE_CODE = T2.ARTICLE_CODE                            
  JOIN UOM ON T2.UOM_CODE = UOM.UOM_CODE                                      
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=T1.PRODUCT_UID            
  JOIN PRD_PMT PMT ON PMT.PRODUCT_UID=SKU.PRODUCT_UID              
  --AND PMT.QUANTITY_IN_STOCK= (CASE WHEN UOM.UOM_NAME=''PCS'' AND T2.CODING_SCHEME=3  THEN 1 ELSE PMT.QUANTITY_IN_STOCK END )            
  AND PMT.DEPARTMENT_ID='''+@CDEPARTMENTID+'''                                   
  JOIN PARA1 ON SKU.PARA1_CODE = PARA1.PARA1_CODE                                       
  JOIN PARA2 ON SKU.PARA2_CODE = PARA2.PARA2_CODE            
  JOIN PARA4 ON SKU.PARA4_CODE = PARA4.PARA4_CODE                                        
  JOIN ARTICLE T3 ON T1.REF_COMPONENT_ARTICLE_CODE = T3.ARTICLE_CODE                                     
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING T5 ON T5.MEMO_ID=T1.MEMO_ID                          
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST MST ON MST.MEMO_ID=T1.REF_ISSUE_ID                 
  LEFT OUTER JOIN                  
  (                  
  SELECT A.JOB_CODE,A.ARTICLE_TYPE ,--1 FOR FG 2 FOR RM                  
  AGENCY_CODE,ARTICLE_CODE,CASE WHEN RATE=0 THEN STD_RATE ELSE  RATE END AS NEW_RATE                  
  FROM PRD_JOB_RATE_MST A                  
  JOIN PRD_JOB_RATE_DET B ON A.JOB_CODE=B.JOB_CODE                  
  WHERE B.AGENCY_CODE='''+@CAGENCYCODE +''' AND ARTICLE_TYPE=2                  
   ) RT ON T1.JOB_CODE=RT.JOB_CODE                  
   AND RT.ARTICLE_CODE= SKU.ARTICLE_CODE  '      
              
 SET @CQRY2=' LEFT OUTER JOIN                                 
  (                                 
   SELECT DT.PCS,DT.AVERAGE, DT.REF_ROW_ID,SUM(ISNULL(DT.QUANTITY,0)) AS QUANTITY ,MT.CANCELLED --DT.XN_PRODUCT_UID,                                
   ,SUM(ISNULL(DT.[RATE],0)) AS RATE                                  
   ,0 AS AMOUNT,0 AS DISCOUNT_PER                                
   ,0 AS DISCOUNT_AMOUNT,0 AS NET_AMOUNT , DT.CHALLAN_NO                                  
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT                                
   JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT ON   MT.MEMO_ID=DT.MEMO_ID                                
   LEFT OUTER JOIN PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING T11 ON DT.REF_ROW_ID=T11.ROW_ID                  
   WHERE MT.CANCELLED=0                                
   AND T11.REF_ISSUE_ID  '+@CORDER_ID+'                      
   GROUP BY DT.PCS,DT.AVERAGE,DT.REF_ROW_ID,MT.CANCELLED, DT.CHALLAN_NO  --,DT.RATE, DT.AMOUNT , DT.DISCOUNT_PER,DT.DISCOUNT_AMOUNT,DT.NET_AMOUNT                                
  ) T4 ON T4.REF_ROW_ID=T1.ROW_ID                            
  LEFT JOIN                      
 (                      
  SELECT DISTINCT DEFAULT_BASIS, A.JOB_CODE,                      
 CASE WHEN ISNULL(DEFAULT_BASIS,0)=1  THEN JOB_RATE                      
       WHEN ISNULL(DEFAULT_BASIS,0)=2  THEN JOB_RATE_PCS                      
       WHEN ISNULL(DEFAULT_BASIS,0)=3  THEN JOB_RATE_DAYS                      
       WHEN ISNULL(DEFAULT_BASIS,0)=4  THEN JOB_RATE_HOURS                      
     ELSE 0 END AS RATE,                      
 JOB_RATE_PCS,                      
    JOB_RATE_DAYS,                      
    JOB_RATE_HOURS,                      
    JOB_RATE AS RATE_MTR                      
 FROM AGENCY_JOBS A (NOLOCK)                      
 WHERE A.AGENCY_CODE='''+@CAGENCYCODE+'''                      
 ) AJ ON T1.JOB_CODE=AJ.JOB_CODE                      
 JOIN JOBS ON JOBS.JOB_CODE=AJ.JOB_CODE          
 LEFT JOIN DEFAULT_BASIS_MASTER DM (NOLOCK) ON DM.DEFAULT_BASIS_VALUE = CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.DEFAULT_BASIS                        
  ELSE 1 END                        
  WHERE T5.CANCELLED=0 AND                       
  MST.MEMO_ID '+@CORDER_ID+' AND                       
  T5.REF_AGENCY_CODE='''+@CAGENCYCODE+'''                       
  AND SKU.COM_PARA1_CODE '+@CPARA1_CODE+'                      
  AND SKU.COM_PARA2_CODE '+@CPARA2_CODE+'                  
  AND T3.ARTICLE_NO '+@CCOMPONENT_NO +'                               
  AND (ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0)) >0                                
  ORDER BY COMP_ARTICLE_NO'                 
              
              
 PRINT @CQRY 
PRINT @CQRY1       
PRINT @CQRY2           
            
            
      
IF OBJECT_ID('TEMPDB..#TMPREC','U') IS NOT NULL            
   DROP TABLE #TMPREC            
            
SELECT T1.[LAST_UPDATE],T1.[ADDITIONAL_QUANTITY]                                  
  ,T1.[ARTICLE_CODE],SKU.[PARA1_CODE],SKU.[PARA2_CODE],T1.[AVG_QTY],T1.[MEMO_ID],                      
  T1.ROW_ID AS [REF_ROW_ID],T1.[TYPE]                                  
  ,T1.[REF_COMPONENT_ARTICLE_CODE],ISNULL(T1.[GROSS_WEIGHT],0) AS GROSS_WEIGHT,T1.[NO_OF_PCS],T5.CANCELLED                                
  ,SKU.[COM_PARA1_CODE],SKU.[COM_PARA2_CODE],                  
 (AVG_QTY * (ISNULL(T1.QUANTITY,0)-ISNULL(T4.[QUANTITY],0))) AS QTY ---              
   ,CONVERT(NUMERIC(12,2),AVG_QTY * '         0')   AS REC_QTY                   
  , ISNULL(T4.[AMOUNT],0) AS AMOUNT, --T1.AMOUNT                      
  ISNULL(T1.[DISCOUNT_PERCENTAGE],0) AS DISCOUNT_PERCENTAGE                                  
  ,ISNULL(T1.[DISCOUNT_AMOUNT],0) AS DISCOUNT_AMOUNT,                      
  ISNULL(T4.[NET_AMOUNT],0) AS NET_AMOUNT,                        
  T4.CHALLAN_NO,                        
  T5.MEMO_NO AS ISSUE_MEMO_NO,                              
  T2.ARTICLE_NO,T2.ARTICLE_NAME,T2.ARTICLE_DESC,UOM.UOM_NAME,                                        
  PARA1.PARA1_NAME,PARA2.PARA2_NAME,T3.ARTICLE_NO AS COMP_ARTICLE_NO ,T1.STOCK_TYPE               
  ,ISNULL(T1.PRODUCT_UID,'') AS XN_PRODUCT_UID                        
  ,SKU.PRODUCT_CODE,                      
  T2.DISCON,           
  CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.DEFAULT_BASIS                               
  ELSE 1 END   AS DEFAULT_BASIS ,                   
                       
    ISNULL(NEW_RATE,CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.RATE                             
  ELSE 0 END) AS RATE ,                
  T1.PCS,T1.AVERAGE,(T1.QUANTITY -ISNULL(T4.QUANTITY,0)) AS QUANTITY_IN_STOCK,                      
                 
                  
   CASE WHEN ISNULL(AJ.JOB_RATE_PCS,0)<>0 THEN AJ.JOB_RATE_PCS                      
        ELSE 0 END AS RATE_PCS,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_DAYS,0)<>0 THEN AJ.JOB_RATE_DAYS                      
       ELSE 0 END AS RATE_DAYS,                      
  CASE WHEN ISNULL(AJ.JOB_RATE_HOURS,0)<>0 THEN AJ.JOB_RATE_HOURS                      
        ELSE 0 END AS RATE_HOURS,                      
   CASE WHEN ISNULL(AJ.RATE_MTR,0)<>0 THEN AJ.RATE_MTR                      
        ELSE 0 END AS RATE_MTR                
                       
  , DEFAULT_BASIS_NAME                      
  ,RIGHT(T1.REF_PRD_WORKORDER_MEMOID,10) AS WORKORDERNO                      
  ,T1.REF_PRD_WORKORDER_MEMOID AS WO_ID                      
  ,CAST('' AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID,                      
  T1.JOB_CODE,                      
  JOBS.JOB_NAME  ,                
 ROW_ID=CAST('LATER'+CAST(NEWID() AS VARCHAR(100)) AS VARCHAR(40)),            
  T2.CODING_SCHEME,            
  PARA4.PARA4_NAME             
  INTO #TMPREC                
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET T1                   
  JOIN PRD_WO_MST MST ON MST.MEMO_ID= T1.REF_PRD_WORKORDER_MEMOID                                    
  JOIN ARTICLE T2 ON T1.ARTICLE_CODE = T2.ARTICLE_CODE                                      
  JOIN UOM ON T2.UOM_CODE = UOM.UOM_CODE                                      
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=T1.PRODUCT_UID                                  
  JOIN PARA1 ON SKU.PARA1_CODE = PARA1.PARA1_CODE                                       
  JOIN PARA2 ON SKU.PARA2_CODE = PARA2.PARA2_CODE             
  JOIN PARA4 ON SKU.PARA4_CODE = PARA4.PARA4_CODE                                        
  JOIN ARTICLE T3 ON T1.REF_COMPONENT_ARTICLE_CODE = T3.ARTICLE_CODE                                     
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST T5 ON T5.MEMO_ID=T1.MEMO_ID                      
  LEFT OUTER JOIN                  
  (                  
  SELECT A.JOB_CODE,A.ARTICLE_TYPE ,--1 FOR FG 2 FOR RM                  
  AGENCY_CODE,ARTICLE_CODE,CASE WHEN RATE=0 THEN STD_RATE ELSE  RATE END AS NEW_RATE                  
  FROM PRD_JOB_RATE_MST A                  
  JOIN PRD_JOB_RATE_DET B ON A.JOB_CODE=B.JOB_CODE                  
  WHERE B.AGENCY_CODE='' AND ARTICLE_TYPE=2                  
   ) RT ON T1.JOB_CODE=RT.JOB_CODE                  
   AND RT.ARTICLE_CODE= T2.ARTICLE_CODE                       
  LEFT OUTER JOIN                                 
  (                                 
   SELECT DT.PCS,DT.AVERAGE, DT.XN_PRODUCT_UID,DT.REF_ROW_ID,SUM(ISNULL(DT.QUANTITY,0)) AS QUANTITY ,MT.CANCELLED                                 
   ,SUM(ISNULL(DT.[RATE],0)) AS RATE                                  
   ,SUM(ISNULL(DT.[AMOUNT],0)) AS AMOUNT,SUM(ISNULL(DT.[DISCOUNT_PER],0)) AS DISCOUNT_PER                                
   ,SUM(ISNULL(DT.[DISCOUNT_AMOUNT],0)) AS DISCOUNT_AMOUNT,SUM(ISNULL(DT.[NET_AMOUNT],0)) AS NET_AMOUNT , DT.CHALLAN_NO                                  
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET DT                                
   JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST MT ON   MT.MEMO_ID=DT.MEMO_ID                                
   LEFT OUTER JOIN PRD_AGENCY_ISSUE_MATERIAL_DET T11 ON DT.REF_ROW_ID=T11.ROW_ID                                   
   WHERE 1=2                  
   GROUP BY DT.PCS,DT.AVERAGE,DT.XN_PRODUCT_UID,DT.REF_ROW_ID,MT.CANCELLED, DT.CHALLAN_NO  --,DT.RATE, DT.AMOUNT , DT.DISCOUNT_PER,DT.DISCOUNT_AMOUNT,DT.NET_AMOUNT                                
  ) T4 ON T4.REF_ROW_ID=T1.ROW_ID                            
  LEFT JOIN                      
 (                      
  SELECT DISTINCT DEFAULT_BASIS, A.JOB_CODE,                      
 CASE WHEN ISNULL(DEFAULT_BASIS,0)=1  THEN JOB_RATE                      
       WHEN ISNULL(DEFAULT_BASIS,0)=2  THEN JOB_RATE_PCS                      
       WHEN ISNULL(DEFAULT_BASIS,0)=3  THEN JOB_RATE_DAYS                      
       WHEN ISNULL(DEFAULT_BASIS,0)=4  THEN JOB_RATE_HOURS                      
     ELSE 0 END AS RATE,                      
 JOB_RATE_PCS,                      
    JOB_RATE_DAYS,                      
    JOB_RATE_HOURS,                      
    JOB_RATE AS RATE_MTR                      
 FROM AGENCY_JOBS A (NOLOCK)                      
 WHERE A.AGENCY_CODE=''                      
 ) AJ ON T1.JOB_CODE=AJ.JOB_CODE                      
 JOIN JOBS ON JOBS.JOB_CODE=AJ.JOB_CODE                      
 LEFT JOIN DEFAULT_BASIS_MASTER DM (NOLOCK) ON DM.DEFAULT_BASIS_VALUE = CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.DEFAULT_BASIS                              
  ELSE 1 END                        
  WHERE  1=2            
            
INSERT INTO #TMPREC                             
EXECUTE (@CQRY+@CQRY1+@CQRY2)            
            
    --CHA        
        -- DROP TABLE TMPREC    
        --SELECT * INTO TMPREC  FROM #TMPREC    
           
          
         
         
            
 IF OBJECT_ID('TEMPDB..#TMPRECSUM','') IS NOT NULL            
    DROP TABLE #TMPRECSUM            
      DROP TABLE TMPREC       
    SELECT * INTO TMPREC FROM #TMPREC        
            
 SELECT (A.AVG_QTY*B.REC_QTY) AS REQUIRED_QTY,A.*,            
    SR=ROW_NUMBER() OVER (PARTITION BY  A.MEMO_ID,A.WO_ID,A.COM_PARA1_CODE,A.COM_PARA2_CODE,A.REF_COMPONENT_ARTICLE_CODE,A.ARTICLE_CODE ORDER BY             
     A.MEMO_ID,A.WO_ID,A.COM_PARA1_CODE,A.COM_PARA2_CODE,A.REF_COMPONENT_ARTICLE_CODE,A.ARTICLE_CODE,A.QUANTITY_IN_STOCK DESC )            
 INTO #TMPRECSUM            
 FROM #TMPREC A            
 JOIN REC_RAW_MATERIAL_UPLOAD B ON A.MEMO_ID=B.ISSUE_MEMO_ID            
 AND A.WO_ID=B.WO_ID            
 AND A.COM_PARA1_CODE=B.PARA1_CODE            
 AND A.COM_PARA2_CODE=B.PARA2_CODE          
 LEFT OUTER JOIN      
(      
 SELECT A.PRODUCT_UID ,SUM(QUANTITY) AS QUANTITY       
 FROM PRD_AGENCY_RM_RETURN_DET A      
 JOIN PRD_AGENCY_RM_RETURN_MST B ON A.MEMO_ID =B.MEMO_ID       
 WHERE B.CANCELLED =0      
 GROUP BY A.PRODUCT_UID      
) C ON A.XN_PRODUCT_UID=C.PRODUCT_UID       
WHERE (A.AVG_QTY*B.REC_QTY)- ISNULL(C.QUANTITY,0) >0       
AND B.SP_ID =@NSP_ID        
         
            
            
          
         
            
 IF OBJECT_ID('TEMPDB..#TMPRECSUM_DUP','') IS NOT NULL            
    DROP TABLE #TMPRECSUM_DUP            
            
 SELECT SUM(B.QUANTITY_IN_STOCK) AS CUMM_SUM,A.REQUIRED_QTY,            
     CASE WHEN A.CODING_SCHEME =3  THEN A.QUANTITY_IN_STOCK             
     ELSE            
     CASE WHEN A.QUANTITY_IN_STOCK >=A.REQUIRED_QTY AND SUM(B.QUANTITY_IN_STOCK)-(A.QUANTITY_IN_STOCK+A.REQUIRED_QTY)<0   THEN A.REQUIRED_QTY             
    WHEN A.QUANTITY_IN_STOCK <A.REQUIRED_QTY AND SUM(B.QUANTITY_IN_STOCK)<=A.REQUIRED_QTY THEN A.QUANTITY_IN_STOCK            
    WHEN A.QUANTITY_IN_STOCK <A.REQUIRED_QTY AND SUM(B.QUANTITY_IN_STOCK)>A.REQUIRED_QTY AND A.QUANTITY_IN_STOCK-(SUM(B.QUANTITY_IN_STOCK)-A.REQUIRED_QTY)>0 THEN A.QUANTITY_IN_STOCK-(SUM(B.QUANTITY_IN_STOCK)-A.REQUIRED_QTY)        
     ELSE 0 END END  AS QUANTITY ,            
   A.LAST_UPDATE,A.ADDITIONAL_QUANTITY,A.ARTICLE_CODE,            
   A.PARA1_CODE,A.PARA2_CODE,A.AVG_QTY,A.MEMO_ID,A.REF_ROW_ID,            
   A.TYPE,A.REF_COMPONENT_ARTICLE_CODE,            
   A.GROSS_WEIGHT,A.NO_OF_PCS,A.CANCELLED,A.COM_PARA1_CODE,A.COM_PARA2_CODE,            
   A.QTY,A.REC_QTY,A.AMOUNT,A.DISCOUNT_PERCENTAGE,A.DISCOUNT_AMOUNT,A.NET_AMOUNT,            
   A.CHALLAN_NO,A.ISSUE_MEMO_NO,A.ARTICLE_NO,A.ARTICLE_NAME,            
   A.ARTICLE_DESC,A.UOM_NAME,A.PARA1_NAME,A.PARA2_NAME,A.COMP_ARTICLE_NO,            
   A.STOCK_TYPE,A.XN_PRODUCT_UID,A.PRODUCT_CODE,            
   A.DISCON,A.DEFAULT_BASIS,A.RATE,A.PCS,A.RATE AS  BILL_RATE,            
   A.AVERAGE,A.QUANTITY_IN_STOCK,A.RATE_PCS,A.RATE_DAYS,            
   A.RATE_HOURS,A.RATE_MTR,A.DEFAULT_BASIS_NAME,A.WORKORDERNO,            
   A.WO_ID,A.REF_MATERIAL_ROW_ID,A.JOB_CODE,A.JOB_NAME,A.ROW_ID,A.SR,            
   CASE WHEN A.CODING_SCHEME =3 THEN 0 ELSE 1 END AS CHK_QTY,            
   A.PARA4_NAME            
 INTO #TMPRECSUM_DUP              
 FROM #TMPRECSUM A            
 JOIN #TMPRECSUM B ON A.WO_ID=B.WO_ID             
 AND A.MEMO_ID=B.MEMO_ID            
 AND A.REF_COMPONENT_ARTICLE_CODE=B.REF_COMPONENT_ARTICLE_CODE             
 AND A.COM_PARA1_CODE=B.COM_PARA1_CODE              
 AND A.COM_PARA2_CODE=B.COM_PARA2_CODE              
 AND A.ARTICLE_CODE =B.ARTICLE_CODE             
 AND B.SR<=A.SR            
 GROUP BY A.REQUIRED_QTY,A.LAST_UPDATE,A.ADDITIONAL_QUANTITY,A.ARTICLE_CODE,            
 A.PARA1_CODE,A.PARA2_CODE,A.AVG_QTY,A.MEMO_ID,A.REF_ROW_ID,            
 A.TYPE,A.REF_COMPONENT_ARTICLE_CODE,            
 A.GROSS_WEIGHT,A.NO_OF_PCS,A.CANCELLED,A.COM_PARA1_CODE,A.COM_PARA2_CODE,            
 A.QTY,A.REC_QTY,A.AMOUNT,A.DISCOUNT_PERCENTAGE,A.DISCOUNT_AMOUNT,A.NET_AMOUNT,            
 A.CHALLAN_NO,A.ISSUE_MEMO_NO,A.ARTICLE_NO,A.ARTICLE_NAME,            
 A.ARTICLE_DESC,A.UOM_NAME,A.PARA1_NAME,A.PARA2_NAME,A.COMP_ARTICLE_NO,            
 A.STOCK_TYPE,A.XN_PRODUCT_UID,A.PRODUCT_CODE,            
 A.DISCON,A.DEFAULT_BASIS,A.RATE,A.PCS,            
 A.AVERAGE,A.QUANTITY_IN_STOCK,A.RATE_PCS,A.RATE_DAYS,            
 A.RATE_HOURS,A.RATE_MTR,A.DEFAULT_BASIS_NAME,A.WORKORDERNO,            
 A.WO_ID,A.REF_MATERIAL_ROW_ID,A.JOB_CODE,A.JOB_NAME,A.ROW_ID,A.SR,A.CODING_SCHEME,A.PARA4_NAME             
      
      
            
 DELETE FROM #TMPRECSUM_DUP WHERE QUANTITY=0            
       
       
       
--  LEFT OUTER JOIN      
--(      
-- SELECT A.PRODUCT_UID ,SUM(QUANTITY) AS QUANTITY       
-- FROM PRD_AGENCY_RM_RETURN_DET A      
-- JOIN PRD_AGENCY_RM_RETURN_MST B ON A.MEMO_ID =B.MEMO_ID       
-- WHERE B.CANCELLED =0      
-- GROUP BY A.PRODUCT_UID      
--) B ON A.XN_PRODUCT_UID=B.PRODUCT_UID       
--WHERE A.QUANTITY- ISNULL(B.QUANTITY,0) >0       
       
         
 SELECT REQUIRED_QTY=REQUIRED_QTY,QUANTITY =A.QUANTITY, *,CAST(CASE WHEN CHK_QTY>0 THEN 1 ELSE 0 END AS  BIT) AS CHK       
 FROM #TMPRECSUM_DUP A          
 ORDER BY A.MEMO_ID,A.WO_ID, A.REF_COMPONENT_ARTICLE_CODE,A.ARTICLE_CODE,            
 A.COM_PARA1_CODE,A.COM_PARA2_CODE,A.SR           
       
 --SELECT * INTO TMPRECSUM_DUP FROM #TMPRECSUM_DUP         
       
 --DROP TABLE TMPRECSUM_DUP      
            
GOTO LAST                              
                                   
END                                  
                     
                                  
LBLGETDETAILCURSOR:                                  
 SELECT T1.*                                  
 FROM PRD_AGENCY_MATERIAL_RECEIPT_DET T1                                  
 WHERE T1.MEMO_ID = @CMEMOID                                 
GOTO LAST                                  
                                  
LBLGETMASTERCURSOR:                                  
 SELECT T1.*                                  
 FROM PRD_AGENCY_MATERIAL_RECEIPT_MST T1                    
 WHERE T1.MEMO_ID = @CMEMOID                                 
GOTO LAST                 
                                  
LBLGETAGENCY:                                
 SELECT T1.*,T2.AGENCY_CODE,T2.AGENCY_NAME                           
 FROM LMV01106 T1                                  
 JOIN PRD_AGENCY_MST T2 ON T1.AC_CODE = T2.AC_CODE AND T2.AGENCY_CODE<>'00000'                                 
GOTO LAST                                 
                                  
LBLAPPLU:                                
SET @CCMD=N'SELECT MEMO_ID,MEMO_NO FROM PRD_AGENCY_MATERIAL_RECEIPT_MST '+(CASE WHEN ISNULL(@CWHERE,'')='' THEN ''                          
 ELSE ' WHERE '+@CWHERE END)                         
 SET @CCMD=@CCMD+' ORDER BY PRD_AGENCY_MATERIAL_RECEIPT_MST.MEMO_DT'                             
                          
PRINT @CCMD                          
EXEC SP_EXECUTESQL @CCMD                           
GOTO LAST                                 
                                  
LAST:                                  
END           
--END OF PROCEDURE SP_PRD_AGENCY_GIT
