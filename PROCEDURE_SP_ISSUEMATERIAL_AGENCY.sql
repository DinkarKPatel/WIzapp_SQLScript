CREATE  PROCEDURE SP_ISSUEMATERIAL_AGENCY        
(                    
@NQUERYID NUMERIC (2,0),                        
@CMEMOID NVARCHAR(MAX),                        
@CWHERE NVARCHAR(MAX),                        
@CWHERE2 NVARCHAR(MAX),                        
@CFINYEAR NVARCHAR(MAX),                        
@NNAVMODE NUMERIC(2,0) ,            
@CAGENCY_CODE VARCHAR(100)='' ,            
@NQTY INT=0,            
@CPARA2_CODE VARCHAR(10)='',            
@NDEFAULT_BASIS INT=0,            
@CJOB_CODE VARCHAR(10)='',    
@CARTICLE_CODE VARCHAR(10)=''            
 )                                  
-- --WITH ENCRYPTION                   
                     
AS                     
BEGIN                            
                            
DECLARE @CCMD NVARCHAR(MAX),--CHANGE MAX                            
@CHEADCODESTR VARCHAR(MAX),--CHANGE MAX                            
@CDEBTORSTR VARCHAR(MAX),--CHANGE MAX                            
@CCREDITORSTR VARCHAR(MAX)--CHANGE MAX                             
DECLARE @WORKORDER_ID VARCHAR(100)                
                       
DECLARE @CQUERY1 NVARCHAR(MAX),@CQUERY11 NVARCHAR(MAX),@CQUERY2 NVARCHAR(MAX),            
@CQUERY21 NVARCHAR(MAX) ,@CQUERY211 NVARCHAR(MAX)--, @CMEMOID VARCHAR(50),@CWHERE1 VARCHAR(50)                          
 DECLARE @CREFWORKORDERMEMOID VARCHAR(MAX),@CSOURCEDEPTID VARCHAR(MAX)               
 
   DECLARE @ENABLEUPC VARCHAR(10)
   SELECT TOP 1 @ENABLEUPC=VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLED_UPC'
	        
     
     
IF  (@NQUERYID = 17  OR @NQUERYID = 18 OR @NQUERYID = 19 OR @NQUERYID = 21)    
BEGIN    
       
    IF OBJECT_ID('TEMPDB..#TMPRM','U') IS NOT NULL    
     DROP TABLE #TMPRM    
      
  SELECT AG.REF_AGENCY_CODE AS AGENCY_CODE,    
         AGM.AGENCY_NAME ,    
         AG.MEMO_ID,    
    CAST(0 AS BIT) AS CHCK,            
    B1.ARTICLE_NO,B1.ARTICLE_NAME ,            
          B1.ARTICLE_CODE,            
          C.ARTICLE_NO AS [COMPONENT_NO] ,            
          C.ARTICLE_CODE AS COMPONENT_CODE,             
          DET.PARA1_CODE AS COM_PARA1_CODE,            
          DET.PARA2_CODE AS COM_PARA2_CODE,            
          H.UOM_CODE,H.UOM_NAME ,       
          DET.QUANTITY AS FG_QTY,         
     AVG_QTY+ISNULL(ADD_AVG_QTY,0) AS AVG_QTY     
     ,ADD_AVG_QTY    
    ,ISSUE_QTY            
    ,CONVERT(NUMERIC(12,2),(AVG_QTY+ISNULL(ADD_AVG_QTY,0)) *ISSUE_QTY) AS REQUIRED_QTY   --CHANGES BY DET QUANTITYT             
    ,MST.MEMO_ID AS ORDER_ID      
    INTO #TMPRM         
    FROM PRD_WO_ART_BOM A (NOLOCK)                  
    JOIN  PRD_WO_DET B (NOLOCK) ON A.REF_ROW_ID = B.ROW_ID            
    JOIN PRD_WO_MST MST (NOLOCK) ON MST.MEMO_ID =B.MEMO_ID             
    JOIN ARTICLE B1 ON A.BOM_ARTICLE_CODE=B1.ARTICLE_CODE            
    JOIN UOM H ON H.UOM_CODE=B1.UOM_CODE               
   JOIN            
   (            
     SELECT C.PARA1_CODE,C.PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY             
     FROM PRD_WO_SUB_DET C                 
     GROUP BY REF_ROW_ID,C.PARA1_CODE,C.PARA2_CODE            
    ) DET ON B.ROW_ID=DET.REF_ROW_ID            
    JOIN ARTICLE C (NOLOCK) ON B.ARTICLE_CODE = C.ARTICLE_CODE      
    JOIN    
    (    
      SELECT A.MEMO_ID ,A.PARA1_CODE ,A.PARA2_CODE ,A.ISSUE_QTY ,B.REF_AGENCY_CODE,B.ORDER_ID    
    FROM PRD_AGENCY_ISSUE_ROW_MATERIAL_DET A    
    JOIN    
    (    
  SELECT A.REF_MATERIAL_ROW_ID, B.MEMO_ID, B.REF_AGENCY_CODE,    
  A.REF_PRD_WORKORDER_MEMOID AS ORDER_ID     
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET A    
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID=B.MEMO_ID    
  WHERE B.CANCELLED=0    
  AND B.REF_AGENCY_CODE =@CAGENCY_CODE    
  GROUP BY A.REF_MATERIAL_ROW_ID,B.MEMO_ID,B.REF_AGENCY_CODE,A.REF_PRD_WORKORDER_MEMOID    
    ) B ON A.MEMO_ID=B.MEMO_ID AND A.ROW_ID=REF_MATERIAL_ROW_ID    
    ) AG ON AG.ORDER_ID =B.MEMO_ID     
    AND DET.PARA1_CODE=AG.PARA1_CODE    
    AND DET.PARA2_CODE=AG.PARA2_CODE     
    JOIN PRD_AGENCY_MST AGM ON AGM.AGENCY_CODE =AG.REF_AGENCY_CODE     
    WHERE  AG.REF_AGENCY_CODE=@CAGENCY_CODE    
    ORDER BY MST.MEMO_ID                            
   -- WHERE B.MEMO_ID='HO0111700000HO00000529'      
       
       
  -- SELECT * FROM #TMPRM    
       
       
       
    IF OBJECT_ID('TEMPDB..#TMPPENDINGRM','U') IS NOT NULL    
     DROP TABLE #TMPPENDINGRM    
      
   SELECT A.* , ISS.QUANTITY,ISNULL(RET.QUANTITY,0) AS ISSUE_RM_QTY     
   INTO #TMPPENDINGRM    
   FROM #TMPRM A    
   LEFT OUTER JOIN    
   (    
        
    SELECT A.MEMO_ID, A.REF_AGENCY_CODE,A.ORDER_ID,    
            A.REF_COMPONENT_ARTICLE_CODE AS COMPONENT_CODE,A.ARTICLE_CODE,    
            A.COM_PARA1_CODE,    
            A.COM_PARA2_CODE ,    
            SUM(QUANTITY) AS QUANTITY    
    FROM    
    (    
     SELECT B.MEMO_ID, B.REF_AGENCY_CODE,A.REF_PRD_WORKORDER_MEMOID AS ORDER_ID,    
            REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE,COMPONENT_CODE,    
            COM_PARA1_CODE,    
            COM_PARA2_CODE ,    
            SUM(QUANTITY) AS QUANTITY    
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET A    
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID=B.MEMO_ID    
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=A.PRODUCT_UID    
  WHERE B.CANCELLED=0    
  AND REF_AGENCY_CODE=@CAGENCY_CODE    
  GROUP BY B.MEMO_ID, B.REF_AGENCY_CODE,A.REF_PRD_WORKORDER_MEMOID ,    
            REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE,COMPONENT_CODE,    
            COM_PARA1_CODE,    
            COM_PARA2_CODE    
            UNION ALL    
    SELECT A.REF_ISSUE_ID AS MEMO_ID, B.REF_AGENCY_CODE,A.REF_PRD_WORKORDER_MEMOID AS ORDER_ID,    
            REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE,COMPONENT_CODE,    
            COM_PARA1_CODE,    
            COM_PARA2_CODE ,    
            SUM(QUANTITY) AS QUANTITY    
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING A    
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING B ON A.MEMO_ID=B.MEMO_ID    
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=A.PRODUCT_UID    
  WHERE B.CANCELLED=0    
  AND REF_AGENCY_CODE=@CAGENCY_CODE    
  GROUP BY A.REF_ISSUE_ID, B.REF_AGENCY_CODE,A.REF_PRD_WORKORDER_MEMOID ,    
            REF_COMPONENT_ARTICLE_CODE,SKU.ARTICLE_CODE,COMPONENT_CODE,    
            COM_PARA1_CODE,    
            COM_PARA2_CODE     
    ) A    
    GROUP BY A.MEMO_ID, A.REF_AGENCY_CODE,A.ORDER_ID,    
            A.REF_COMPONENT_ARTICLE_CODE,A.ARTICLE_CODE,A.COMPONENT_CODE,    
            A.COM_PARA1_CODE,    
            A.COM_PARA2_CODE    
   ) ISS    
   ON ISS.MEMO_ID=A.MEMO_ID    
   AND ISS.ORDER_ID=A.ORDER_ID    
   AND ISS.COMPONENT_CODE=A.COMPONENT_CODE    
   AND ISS.ARTICLE_CODE=A.ARTICLE_CODE    
   AND ISS.COM_PARA1_CODE=A.COM_PARA1_CODE     
   AND ISS.COM_PARA2_CODE=A.COM_PARA2_CODE  
   LEFT JOIN
   (
      SELECT D.MEMO_ID  ,SKU.WORK_ORDER_ID AS ORDER_ID  ,SKU.COMPONENT_CODE ,SKU.COM_PARA1_CODE , 
           SKU.COM_PARA2_CODE,SKU.ARTICLE_CODE,
          SUM(A.QUANTITY  ) AS QUANTITY
	  FROM PRD_AGENCY_RM_RETURN_DET  A
	  JOIN PRD_AGENCY_RM_RETURN_MST  B ON A.MEMO_ID =B.MEMO_ID 
	  JOIN PRD_AGENCY_ISSUE_MATERIAL_DET C ON A.REF_ROW_ID =C.ROW_ID 
	  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST D ON D.MEMO_ID =C.MEMO_ID 
	  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID =C.PRODUCT_UID 
	  WHERE B.CANCELLED =0 AND D.CANCELLED =0
	  GROUP BY D.MEMO_ID  ,SKU.WORK_ORDER_ID   ,SKU.COMPONENT_CODE ,SKU.COM_PARA1_CODE , 
           SKU.COM_PARA2_CODE,SKU.ARTICLE_CODE
   ) RET ON RET.MEMO_ID=A.MEMO_ID    
   AND RET.ORDER_ID=A.ORDER_ID    
   AND RET.COMPONENT_CODE=A.COMPONENT_CODE    
   AND RET.ARTICLE_CODE=A.ARTICLE_CODE    
   AND RET.COM_PARA1_CODE=A.COM_PARA1_CODE     
   AND RET.COM_PARA2_CODE=A.COM_PARA2_CODE  
   WHERE ISNULL(REQUIRED_QTY,0)- (ISNULL(ISS.QUANTITY,0)-ISNULL(RET.QUANTITY,0))>0    
      
 
      
  
      
END      
    
                      
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
GOTO LBLGETDEPARTMENT                            
                            
ELSE IF                            
@NQUERYID = 5                            
GOTO LBLGETWORKORDERMASTER                            
                            
ELSE IF                            
@NQUERYID = 6                            
GOTO LBLGETWORKORDERDETAILS                            
                            
ELSE IF                            
@NQUERYID = 7                            
GOTO LBLGETORDERWISEITEMS                  
                            
ELSE IF                            
@NQUERYID = 8                            
GOTO LBLGETWODETAILS                            
                            
ELSE IF                             
@NQUERYID = 9                            
GOTO LBLGETLEDGERS                            
                            
ELSE IF                             
@NQUERYID = 10                            
GOTO LBLGETJOBS                            
            
ELSE IF                             
@NQUERYID = 11                            
GOTO LBLGETSTKDET            
            
ELSE IF                             
@NQUERYID = 12                            
GOTO LBLGETCOMPDET            
            
ELSE IF                             
@NQUERYID = 13                        
GOTO LBLGETSTKDET_VIEW            
ELSE IF             
@NQUERYID = 14                        
GOTO LBLDEFAULTBASIS_RATE            
            
ELSE IF             
@NQUERYID = 15                        
GOTO LBLISSUE_ROW_VIEW            
            
            
ELSE IF             
@NQUERYID = 16                        
GOTO LBLISSUE_RM_PENDING            
            
ELSE IF             
@NQUERYID = 17                       
GOTO LBLFG_PENDING            
            
ELSE IF             
@NQUERYID = 18                       
GOTO LBLCOM_PENDING            
            
            
ELSE IF             
@NQUERYID = 19                       
GOTO LBLRM_PENDING            
            
ELSE IF             
@NQUERYID = 20                       
GOTO LBL_ISSUE_REQ_VIEW            
            
            
ELSE IF             
@NQUERYID = 21                       
GOTO LBLGETORDERWISEITEMS_PENDING            
            
ELSE IF             
@NQUERYID = 22                       
GOTO LBLGETMASTERS_PENDING            
            
ELSE IF             
@NQUERYID = 23                       
GOTO LBLGETDETAILS_PENDING            
ELSE IF            
@NQUERYID = 24                            
GOTO LBLNAVIGATE_PENDING               
     
      
            
LBLGETMASTERS_PENDING:               
                         
 SELECT DISTINCT T1.*, T2.USERNAME,T3.DEPARTMENT_NAME,            
 --ISNULL(T6.MEMO_ID,'') AS WORK_ORDER_MEMO_ID,                            
 --ISNULL(T6.MEMO_ID,'') AS REF_PRD_WORKORDER_MEMOID,            
 --ISNULL(J.JOB_NAME,'') AS JOB_NAME,                                    --(CASE WHEN T7.MEMO_DT <> '' THEN CONVERT(CHAR(10),ISNULL(T7.MEMO_DT,''),105) ELSE ''  END) AS WORKORDERDT                            
 ISNULL(AGE.AGENCY_NAME,'') AS AGENCY_NAME                            
 ,ISNULL(ARTSET.ARTICLE_NO,'') AS ARTICLE_SET ,FRM.FORM_NAME            
 FROM PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING  T1              
 JOIN PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING  D ON T1.MEMO_ID=D.MEMO_ID                           
 JOIN USERS T2 ON T1.USER_CODE = T2.USER_CODE                            
 LEFT OUTER JOIN PRD_AGENCY_MST AGE ON T1.REF_AGENCY_CODE = AGE.AGENCY_CODE                             
 LEFT OUTER JOIN PRD_DEPARTMENT_MST T3 ON T3.DEPARTMENT_ID = T1.DEPARTMENT_ID                   
 LEFT OUTER JOIN PRD_WO_DET T6 ON D.REF_PRD_WORKORDER_MEMOID= T6.MEMO_ID            
 LEFT OUTER JOIN PRD_WO_MST T7 ON T6.MEMO_ID= T7.MEMO_ID                                        
 LEFT OUTER JOIN JOBS J ON J.JOB_CODE=D.JOB_CODE                            
 LEFT OUTER JOIN ARTICLE ARTSET ON T7.ARTICLE_SET_CODE = ARTSET.ARTICLE_CODE                             
 JOIN FORM FRM ON T1.TAX_FORM_ID=FRM.FORM_ID                          
 WHERE T1.MEMO_ID = @CMEMOID                            
GOTO LAST                            
                            
LBLGETDETAILS_PENDING:                            
                             
 IF @CMEMOID <> ''                            
 BEGIN                            
  SELECT TOP 1 @CREFWORKORDERMEMOID=REF_PRD_WORKORDER_MEMOID FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING WHERE MEMO_ID = @CMEMOID                        
  SELECT TOP 1 @CSOURCEDEPTID = DEPARTMENT_ID  FROM PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING WHERE MEMO_ID = @CMEMOID                        
 END                            
 ELSE                            
  SELECT @CREFWORKORDERMEMOID='' ,@CSOURCEDEPTID =''                        
                             
 SET @CCMD = N'SELECT  CAST(1 AS BIT) AS CHCK,C.UOM_NAME,D.PRODUCT_UID,D.[QUANTITY]  ,D.[ROW_ID]  ,D.[LAST_UPDATE]  ,D.[TS]  ,D.[ADDITIONAL_QUANTITY]  ,D.[ARTICLE_CODE] ,D.[AVG_QTY]                          
  ,D.[MEMO_ID]  ,D.[REF_ROW_ID]  ,D.[TYPE]  ,D.[REF_COMPONENT_ARTICLE_CODE]  ,D.[GROSS_WEIGHT] ,D.[NO_OF_PCS]  ,D.RATE  ,D.[AMOUNT]  ,D.[DISCOUNT_PERCENTAGE]  ,D.[DISCOUNT_AMOUNT]                          
  ,D.[NET_AMOUNT], B.ARTICLE_NO, B.ARTICLE_NAME,SKU.PARA1_CODE,SKU.PARA2_CODE, PARA1.PARA1_NAME, D.ROW_ID , ARTCOM.ARTICLE_NO AS COMP_NAME,                        
  CASE WHEN ISNULL(P.QUANTITY_IN_STOCK,0)>0 THEN P.QUANTITY_IN_STOCK WHEN ISNULL(P.WIP,0)>0 THEN P.WIP ELSE ISNULL(P.QUANTITY_IN_STOCK,0) END AS QUANTITY_IN_STOCK                         
  ,PARA2.PARA2_NAME,ISNULL(O.ISSUED_QTY,0) AS ISSUED_QTY, ISNULL(O.TOTAL_QTY,0) AS TOTAL_QTY,                        
  (ISNULL(O.TOTAL_QTY,0) - ISNULL(O.ISSUED_QTY ,0)) AS BALANCE_QTY,                            
  ISNULL(B.ENABLE_FIXWT_ENTRY,0) AS ENABLE_FIXWT_ENTRY,ISNULL(B.FIX_WEIGHT,0) AS FIX_WEIGHT                             
  ,D.STOCK_TYPE,SKU.PRODUCT_CODE,B.DISCON ,PCS=D.PCS ,            
  AVERAGE=D.AVERAGE ,D.DEFAULT_BASIS AS DEFAULT_BASIS ,D.JOB_CODE AS JOB_CODE,            
  JOBS.JOB_NAME AS JOB_NAME ,D.REF_PRD_WORKORDER_MEMOID AS REF_WO_ID ,            
  RIGHT(D.REF_PRD_WORKORDER_MEMOID,10) AS REF_WO_NO ,            
  D.REF_PRD_WORKORDER_MEMOID AS REF_PRD_WORKORDER_MEMOID,            
  P1.PARA1_NAME AS COM_COLOR,            
  P2.PARA2_NAME AS COM_SIZE,            
  '''' AS REF_MATERIAL_ROW_ID,            
  CAST('''' AS VARCHAR(100)) AS REF_ISSUE_ID,            
  D.ITEM_REMARKS    
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING D             
  JOIN JOBS ON D.JOB_CODE=JOBS.JOB_CODE                       
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=D.PRODUCT_UID                        
  JOIN ARTICLE B ON SKU.ARTICLE_CODE  = B.ARTICLE_CODE                             
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING IM ON IM.MEMO_ID=D.MEMO_ID                          
  JOIN UOM C ON B.UOM_CODE = C.UOM_CODE       
  JOIN PARA1 ON PARA1.PARA1_CODE = SKU.PARA1_CODE                            
  JOIN PARA2 ON PARA2.PARA2_CODE = SKU.PARA2_CODE                             
  JOIN PRD_PMT P ON P.PRODUCT_UID = D.PRODUCT_UID AND P.DEPARTMENT_ID = IM.DEPARTMENT_ID                        
  JOIN ARTICLE ARTCOM ON D.REF_COMPONENT_ARTICLE_CODE = ARTCOM.ARTICLE_CODE                   
  LEFT JOIN PARA1 P1 ON SKU.COM_PARA1_CODE=P1.PARA1_CODE            
  LEFT JOIN PARA2 P2 ON SKU.COM_PARA2_CODE=P2.PARA2_CODE             
  LEFT OUTER JOIN                         
  (                        
   SELECT P1.PARA1_NAME,P2.PARA2_NAME, A.ARTICLE_CODE,K.PARA1_CODE,K.PARA2_CODE,K.QUANTITY AS TOTAL_QTY, S.ISSUED_QTY ,S.PRODUCT_UID                        
   FROM PRD_WO_DET A                         
   JOIN PRD_WO_SUB_DET K ON A.ROW_ID = K.REF_ROW_ID                
   JOIN PARA1 P1 ON P1.PARA1_CODE = K.PARA1_CODE                            
   JOIN PARA2 P2 ON P2.PARA2_CODE = K.PARA2_CODE                              
   LEFT OUTER JOIN                             
   (                        
    SELECT D.PRODUCT_UID,D.ARTICLE_CODE,SK.PARA1_CODE,SK.PARA2_CODE,SUM(D.QUANTITY) AS ISSUED_QTY,                            
    D.REF_COMPONENT_ARTICLE_CODE AS RCA                     
    FROM PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING D                         
    JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING M ON M.MEMO_ID = D.MEMO_ID                             
    JOIN PRD_SKU SK ON SK.PRODUCT_UID=D.PRODUCT_UID                        
    WHERE D.REF_PRD_WORKORDER_MEMOID = '''+ @CREFWORKORDERMEMOID +''' AND M.DEPARTMENT_ID = '''+ @CSOURCEDEPTID +'''                             
    AND M.CANCELLED = 0                            
     GROUP BY  D.ARTICLE_CODE,D.REF_COMPONENT_ARTICLE_CODE,D.PRODUCT_UID,SK.PARA1_CODE,SK.PARA2_CODE                        
   ) S ON S.ARTICLE_CODE= A.ARTICLE_CODE AND S.PARA1_CODE = K.PARA1_CODE AND  S.PARA2_CODE = K.PARA2_CODE                             
   AND S.RCA = A.ARTICLE_CODE WHERE A.MEMO_ID ='''+ @CREFWORKORDERMEMOID +'''                          ) O ON O.PRODUCT_UID = SKU.PRODUCT_UID --AND O.ARTICLE_CODE = D.REF_COMPONENT_ARTICLE_CODE                            
  WHERE D.MEMO_ID ='''+@CMEMOID+''' --AND P.DEPARTMENT_ID='''+@CWHERE+''' --AND D.TYPE = 1 '                          
 PRINT @CCMD                            
 EXECUTE SP_EXECUTESQL @CCMD                            
                            
                            
 SET @CCMD = N'SELECT CAST('''' AS VARCHAR(50)) AS  COM_PARA1_NAME,CAST('''' AS VARCHAR(50)) AS COM_PARA2_NAME,            
 CAST('''' AS VARCHAR(50)) AS UOM_NAME,CAST('''' AS VARCHAR(50)) AS PRODUCT_UID,CAST(0 AS NUMERIC(10,3)) AS QUANTITY,                            
 CAST('''' AS VARCHAR(50)) AS ARTICLE_NO,CAST('''' AS VARCHAR(50)) AS ROW_ID,                            
 CAST(0 AS NUMERIC(10,3)) AS QUANTITY_IN_STOCK,                            
 --CHANGE                            
 CAST(0 AS BIT) AS TYPE,CAST('''' AS VARCHAR(50)) AS PARA1_CODE,CAST('''' AS VARCHAR(50)) AS PARA2_CODE,                            
 CAST('''' AS VARCHAR(50)) AS PARA1_NAME,CAST('''' AS VARCHAR(50)) AS PARA2_NAME             
 ,CAST('''' AS VARCHAR(50)) AS PRODUCT_CODE,            
 '''' AS JOB_CODE,            
  '''' AS JOB_NAME ,            
 '''' AS REF_WO_ID ,            
  '''' AS REF_WO_NO,            
  '''' AS REF_PRD_WORKORDER_MEMOID,            
  '''' AS REF_MATERIAL_ROW_ID,    
  ''''  AS ITEM_REMARKS            
 FROM PRD_AGENCY_ISSUE_MATERIAL_MST WHERE 1=2'                            
                             
 PRINT @CCMD                            
 EXECUTE SP_EXECUTESQL @CCMD                            
                            
 GOTO LAST                            
                                  
                            
                          
            
LBLGETORDERWISEITEMS_PENDING:    ----PENDING BARCODE WISE DETAILS              
        
SET @CQUERY1 = N' SELECT  CAST(0 AS BIT) AS CHCK,A.ARTICLE_CODE AS [COMPONENT_CODE],            
C.PARA1_CODE AS COMPARA1_CODE,C.PARA2_CODE AS COMPARA2_CODE,            
 B.ARTICLE_NO AS [COMP_NAME], P11.PARA1_NAME AS COM_COLOR,P21.PARA2_NAME AS COM_SIZE ,B1.ARTICLE_NO,B1.ARTICLE_NAME  ,P1.PARA1_NAME ,P2.PARA2_NAME                             
,SUM(ISNULL(D.AVG_QTY,0)+ISNULL(D.ADD_AVG_QTY,0)) AS AVG_QTY ,E.PRODUCT_UID,E.ARTICLE_CODE AS ARTICLE_CODE,E.PARA1_CODE ,E.PARA2_CODE,A.ROW_ID AS REF_ROW_ID ,                            
NEWID() AS ROW_ID ,CAST(0 AS NUMERIC(10,2)) AS QUANTITY ,(F.QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK ,(F.QUANTITY_IN_STOCK) AS ORG_QUANTITY_IN_STOCK                
,SUM('''+STR(@NQTY)+'''* ISNULL(D.AVG_QTY,0)) AS TOTAL_QTY ,SUM(ISNULL(S.ISSUED_QTY,0)) AS ISSUED_QTY             
,SUM((ISNULL(C.QUANTITY,0)* ISNULL(D.AVG_QTY,0)) - ISNULL(S.ISSUED_QTY ,0)) AS BALANCE_QTY             
, ISNULL(B.ENABLE_FIXWT_ENTRY,0) AS ENABLE_FIXWT_ENTRY,ISNULL(B.FIX_WEIGHT,0) AS FIX_WEIGHT                        
,CAST(0 AS NUMERIC(10,3)) AS GROSS_WEIGHT,CAST(0 AS NUMERIC(10,3)) AS NO_OF_PCS            
,E.MRP ,E.WS_PRICE,E.TAX_AMOUNT AS ITEM_TAX_AMOUNT,             
E.FORM_ID AS ITEM_FORM_ID,G.FORM_NAME,G.TAX_PERCENTAGE AS ITEM_TAX_PERCENTAGE            
, B.UOM_CODE,H.UOM_NAME ,            
CASE WHEN ISNULL(AJ.DEFAULT_BASIS,0)<>0 THEN AJ.DEFAULT_BASIS             
     WHEN ISNULL(J.DEFAULT_BASIS,0)<>0 THEN J.DEFAULT_BASIS                   
ELSE 1 END   AS DEFAULT_BASIS ,            
0 AS RATE             
,ISNULL(S.DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE,ISNULL(S.DISCOUNT_AMOUNT,0) AS DISCOUNT_AMOUNT             
,SUM(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END)) AS AMOUNT             
,SUM(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END))-ISNULL(S.DISCOUNT_AMOUNT,0) AS NET_AMOUNT             
,SM.SECTION_NAME,SD.SUB_SECTION_NAME ,CAST(1 AS NUMERIC(1,0)) AS STOCK_TYPE ,ISNULL(C.QUANTITY,0) AS COM_QTY            
,E.PRODUCT_CODE ,B1.DISCON,CAST(0 AS NUMERIC(10,2)) AS PCS ,CAST(0 AS NUMERIC(10,2)) AS AVG_QTY1 ,            
J1.JOB_CODE,            
J1.JOB_NAME ,            
A.MEMO_ID AS REF_WO_ID ,            
RIGHT(A.MEMO_ID,10) AS REF_WO_NO,            
A.MEMO_ID AS REF_PRD_WORKORDER_MEMOID,            
SUM(PRD.QUANTITY) AS ORD_QUANTITY,            
A.MEMO_ID,            
CAST('''' AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID,            
CAST('''' AS VARCHAR(100)) AS REF_ISSUE_ID            
FROM PRD_WO_DET A             
JOIN    
(     
SELECT ORDER_ID FROM #TMPPENDINGRM      
GROUP BY ORDER_ID    
)TMP    
ON A.MEMO_ID=TMP.ORDER_ID            
JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE             
JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID             
JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID              
JOIN ARTICLE B1 ON D.BOM_ARTICLE_CODE=B1.ARTICLE_CODE             
JOIN PRD_SKU E ON            
E.ARTICLE_CODE=D.BOM_ARTICLE_CODE            
AND A.MEMO_ID=E.WORK_ORDER_ID            
AND A.ARTICLE_CODE=E.COMPONENT_CODE              
AND C.PARA1_CODE=E.COM_PARA1_CODE             
AND C.PARA2_CODE=E.COM_PARA2_CODE            
JOIN            
(            
 SELECT A.ARTICLE_CODE,A.MEMO_ID ,SUM(QUANTITY) AS QUANTITY            
 FROM PRD_WO_DET A            
 JOIN PRD_WO_SUB_DET B ON A.ROW_ID=B.REF_ROW_ID            
  GROUP BY A.ARTICLE_CODE, A.MEMO_ID            
) PRD ON PRD.MEMO_ID=A.MEMO_ID AND PRD.ARTICLE_CODE=A.ARTICLE_CODE            
'            
            
SET @CQUERY2 = N'  JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B1.SUB_SECTION_CODE             
 JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE             
 JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID'             
IF ISNULL(@NNAVMODE,0)=0            
SET @CQUERY2 = @CQUERY2+ N' AND QUANTITY_IN_STOCK >0 '              --AND QUANTITY_IN_STOCK >0             
SET @CQUERY2 = @CQUERY2+ N'  JOIN PARA1 P1 ON P1.PARA1_CODE=E.PARA1_CODE            
 JOIN PARA2 P2 ON P2.PARA2_CODE=E.PARA2_CODE             
 JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE             
 JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE             
LEFT JOIN            
(            
 SELECT TOP 1  DEFAULT_BASIS, A.JOB_CODE,            
JOB_RATE AS RATE            
FROM AGENCY_JOBS A (NOLOCK)            
WHERE A.AGENCY_CODE='''+@CAGENCY_CODE +'''            
--AND ('''+@CWHERE2+''' ='''' OR A.JOB_CODE='''+@CWHERE2+''' )            
) AJ ON 1=1            
LEFT OUTER JOIN             
(            
 SELECT TOP 1 A.MEMO_ID, J.REF_ROW_ID,J.DEFAULT_BASIS,J.JOB_RATE,             
 J.JOB_RATE_PCS,            
 J.JOB_RATE_DAYS,            
 J.JOB_RATE_HOURS,            
 JOB_CODE              
 FROM PRD_WO_DET A             
 JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID             
 JOIN PRD_WO_ART_JOBS J ON C.REF_ROW_ID=J.REF_ROW_ID            
 WHERE J.JOB_RATE<>0             
 AND C.PARA1_CODE='''+@CWHERE2+'''            
 AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
            
) J ON  A.MEMO_ID=J.MEMO_ID AND C.REF_ROW_ID=J.REF_ROW_ID            
 LEFT JOIN JOBS J1 ON J1.JOB_CODE=CASE WHEN '''+@CJOB_CODE+'''<>'''' THEN '''+@CJOB_CODE+''' ELSE ISNULL(AJ.JOB_CODE,J.JOB_CODE ) END            
 JOIN FORM G ON G.FORM_ID=E.FORM_ID             
LEFT JOIN (             
SELECT D.AVG_QTY,D.REF_COMPONENT_ARTICLE_CODE,SUM(D.QUANTITY) AS ISSUED_QTY ,D.PRODUCT_UID             
,D.RATE,D.AMOUNT,D.DISCOUNT_PERCENTAGE,D.DISCOUNT_AMOUNT,D.NET_AMOUNT             
FROM PRD_AGENCY_ISSUE_MATERIAL_DET D JOIN PRD_AGENCY_ISSUE_MATERIAL_MST M ON M.MEMO_ID = D.MEMO_ID              
WHERE ('''+@CMEMOID+'''='''' OR D.REF_PRD_WORKORDER_MEMOID = '''+@CMEMOID+''')             
AND M.DEPARTMENT_ID = '''+ SUBSTRING(@CWHERE,5,15) +''' AND M.CANCELLED = 0              
 GROUP BY D.RATE,D.AMOUNT,D.DISCOUNT_PERCENTAGE,D.PRODUCT_UID,D.DISCOUNT_AMOUNT,D.NET_AMOUNT , D.AVG_QTY,D.REF_COMPONENT_ARTICLE_CODE              
) S ON E.PRODUCT_UID=S.PRODUCT_UID'             
SET @CQUERY11=N' JOIN UOM H ON H.UOM_CODE=B1.UOM_CODE'            
SET @CQUERY11 = @CQUERY11+ N'             
WHERE ('''+@CMEMOID+'''= '''' OR A.MEMO_ID= '''+@CMEMOID+''')            
AND DEPARTMENT_ID='''+@CWHERE+'''              
--AND C.PARA1_CODE '''+@CWHERE2+'''            
--AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
            
--AND('''+@CWHERE2+'''='''' OR J1.JOB_CODE='''+@CWHERE2+''' )            
'            
SET @CQUERY21=N' GROUP BY A.ARTICLE_CODE,B.ARTICLE_NO,P11.PARA1_NAME,P21.PARA2_NAME,B1.ARTICLE_NO,B1.ARTICLE_NAME,P1.PARA1_NAME,P2.PARA2_NAME                             
, E.PRODUCT_UID,E.ARTICLE_CODE,E.PARA1_CODE,E.PARA2_CODE,            
A.ROW_ID,ISNULL(B.ENABLE_FIXWT_ENTRY,0),ISNULL(B.FIX_WEIGHT,0),E.MRP,E.WS_PRICE,E.TAX_AMOUNT ,            
E.FORM_ID ,G.FORM_NAME,G.TAX_PERCENTAGE , B.UOM_CODE,H.UOM_NAME               
,CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END             
, ISNULL(S.DISCOUNT_PERCENTAGE,0) ,ISNULL(S.DISCOUNT_AMOUNT,0)            
--,(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END))             
--,(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END))-ISNULL(S.DISCOUNT_AMOUNT,0)             
,SM.SECTION_NAME,SD.SUB_SECTION_NAME ,ISNULL(C.QUANTITY,0),F.QUANTITY_IN_STOCK ,C.PARA1_CODE,C.PARA2_CODE            
,E.PRODUCT_CODE,B1.DISCON ,            
CASE WHEN ISNULL(AJ.DEFAULT_BASIS,0)<>0 THEN AJ.DEFAULT_BASIS             
     WHEN ISNULL(J.DEFAULT_BASIS,0)<>0 THEN J.DEFAULT_BASIS             
ELSE 1 END  ,            
CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.RATE             
     WHEN ISNULL(J.DEFAULT_BASIS,0)=1  THEN J.JOB_RATE            
     WHEN ISNULL(J.DEFAULT_BASIS,0)=2  THEN J.JOB_RATE_PCS            
     WHEN ISNULL(J.DEFAULT_BASIS,0)=3  THEN J.JOB_RATE_DAYS            
     WHEN ISNULL(J.DEFAULT_BASIS,0)=4  THEN J.JOB_RATE_HOURS            
   --  WHEN ISNULL(ART_JOBS.RATE,0)<>0 THEN ART_JOBS.RATE             
ELSE 0 END,J1.JOB_CODE,J1.JOB_NAME ,A.MEMO_ID  ,            
RIGHT(A.MEMO_ID,10)   '              
            
            
            
PRINT @CQUERY1            
PRINT @CQUERY2            
PRINT @CQUERY11            
PRINT @CQUERY21            
EXEC (@CQUERY1+@CQUERY2+@CQUERY11+@CQUERY21)              
            
                             
 GOTO LAST             
             
             
LBL_ISSUE_REQ_VIEW: ---VIEW FOR BINDING COMPONENT GRID            
            
              
  SET @CCMD= N'SELECT CHCK,            
          CAST('''' AS VARCHAR(100)) AS MEMO_ID,            
          CAST(''LATER''+CAST(NEWID() AS VARCHAR(100)) AS VARCHAR(40)) AS ROW_ID,            
          ARTICLE_NO,ARTICLE_NAME ,            
          ARTICLE_CODE,            
          [COMPONENT_NO] ,             
          COMPONENT_CODE,             
          COM_PARA1_CODE,            
          COM_PARA2_CODE,            
          UOM_CODE,UOM_NAME,            
             SUM(A.AVG_QTY) AS AVG_QTY,            
             SUM(A.REQUIRED_QTY) AS REQ_QTY,            
             CAST(0 AS NUMERIC(12,0)) AS ISSUE_QTY            
            FROM            
           (            
    SELECT CAST(0 AS BIT) AS CHCK,            
    B1.ARTICLE_NO,B1.ARTICLE_NAME ,            
          B1.ARTICLE_CODE,            
          C.ARTICLE_NO AS [COMPONENT_NO] ,            
          C.ARTICLE_CODE AS COMPONENT_CODE,             
          DET.PARA1_CODE AS COM_PARA1_CODE,            
          DET.PARA2_CODE AS COM_PARA2_CODE,            
          H.UOM_CODE,H.UOM_NAME ,            
    AVG_QTY            
    ,CONVERT(NUMERIC(12,2),AVG_QTY * '+STR(@NQTY)+') AS REQUIRED_QTY   --CHANGES BY DET QUANTITYT             
                
    FROM PRD_WO_ART_BOM A (NOLOCK)                  
    JOIN  PRD_WO_DET B (NOLOCK) ON A.REF_ROW_ID = B.ROW_ID            
    JOIN PRD_WO_MST MST (NOLOCK) ON MST.MEMO_ID =B.MEMO_ID             
    JOIN ARTICLE B1 ON A.BOM_ARTICLE_CODE=B1.ARTICLE_CODE            
    JOIN UOM H ON H.UOM_CODE=B1.UOM_CODE               
    JOIN            
    (            
     SELECT C.PARA1_CODE,C.PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY             
     FROM PRD_WO_SUB_DET C            
     WHERE C.PARA1_CODE='''+@CWHERE2+'''            
     AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
     GROUP BY REF_ROW_ID,C.PARA1_CODE,C.PARA2_CODE            
    ) DET ON B.ROW_ID=DET.REF_ROW_ID            
    JOIN ARTICLE C (NOLOCK) ON B.ARTICLE_CODE = C.ARTICLE_CODE               
    JOIN            
    (            
     SELECT B.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,A.ISSUE_QTY             
     FROM PRD_STK_TRANSFER_MATERIAL_DET A            
     JOIN             
     (            
      SELECT REF_ROW_ID,REF_WO_ID             
      FROM PRD_STK_TRANSFER_MST A            
      JOIN PRD_STK_TRANSFER_DET B ON A.MEMO_ID=B.MEMO_ID             
      WHERE A.CANCELLED =0 AND REF_WO_ID='''+@CMEMOID+'''             
      AND TARGET_DEPARTMENT_ID='''+@CWHERE+'''            
      GROUP BY REF_ROW_ID,REF_WO_ID            
     ) B ON A.ROW_ID  =B.REF_ROW_ID              
     WHERE  REF_WO_ID='''+@CMEMOID+'''             
    ) STK ON B.MEMO_ID=STK.REF_WO_ID            
    AND MST.ARTICLE_SET_CODE=STK.ARTICLE_CODE            
    AND DET.PARA1_CODE=STK.PARA1_CODE            
    AND DET.PARA2_CODE=STK.PARA2_CODE            
    JOIN            
    (            
       SELECT DISTINCT A.ARTICLE_CODE, A.COMPONENT_CODE,A.COM_PARA1_CODE,A.COM_PARA2_CODE            
       FROM PRD_SKU A            
       JOIN PRD_PMT B ON A.PRODUCT_UID=B.PRODUCT_UID            
       WHERE B.QUANTITY_IN_STOCK>0            
       AND A.WORK_ORDER_ID='''+@CMEMOID+'''            
       AND B.DEPARTMENT_ID='''+@CWHERE+'''            
                
    )  PMT ON A.BOM_ARTICLE_CODE=PMT.ARTICLE_CODE            
    AND PMT.COMPONENT_CODE=B.ARTICLE_CODE      
    AND DET.PARA1_CODE=PMT.COM_PARA1_CODE            
    AND DET.PARA2_CODE=PMT.COM_PARA2_CODE            
                      
    WHERE B.MEMO_ID='''+@CMEMOID+'''                
                         
   ) A                      
   GROUP BY CHCK,ARTICLE_NO,ARTICLE_NAME ,            
          ARTICLE_CODE,            
          [COMPONENT_NO] ,             
          UOM_CODE,UOM_NAME, COMPONENT_CODE,             
          COM_PARA1_CODE,            
          COM_PARA2_CODE,            
          UOM_CODE,UOM_NAME'            
              
 PRINT @CCMD            
 EXEC SP_EXECUTESQL @CCMD             
            
            
GOTO LAST             
            
            
LBLCOM_PENDING: ----COMPONENT PENDING DETAILS            
        
 SELECT CAST(0 AS BIT) AS CHCK,A.AGENCY_CODE AS  REF_AGENCY_CODE,    
 A.ORDER_ID AS REF_WO_ID, A.MEMO_ID ,            
 A.COM_PARA1_CODE AS PARA1_CODE,            
 A.COM_PARA2_CODE AS PARA2_CODE,            
  SUM(AVG_QTY) AS AVG_QTY ,            
  SUM(REQUIRED_QTY) AS REQ_QTY ,            
  CONVERT(NUMERIC(10,2),SUM(REQUIRED_QTY)/SUM(AVG_QTY+ISNULL(ADD_AVG_QTY,0))) AS ISSUE_QTY ,             
  A.COMPONENT_NO AS ARTICLE_NO, A.COMPONENT_CODE,            
 SUM(ISNULL(FG_QTY,0)-ISNULL(ISSUE_QTY,0)) AS PENDING_QTY            
 FROM #TMPPENDINGRM A            
 GROUP BY A.AGENCY_CODE ,    
 A.ORDER_ID , A.MEMO_ID ,            
 A.COM_PARA1_CODE ,            
 A.COM_PARA2_CODE ,                  
 A.COMPONENT_NO, A.COMPONENT_CODE            
     
     
-- SELECT * INTO TMPRRM FROM #TMPPENDINGRM    
     
       
             
GOTO LAST             
            
LBLRM_PENDING: ---ROW_MATERIAL PENDING DETAILS            
      
       
       
   SELECT CAST(0 AS BIT) AS CHCK,             
   A.AGENCY_CODE AS REF_AGENCY_CODE,    
   A.ORDER_ID AS REF_WO_ID, A.MEMO_ID ,AVG_QTY ,A.UOM_CODE , A.REQUIRED_QTY AS  REQ_QTY ,ISSUE_RM_QTY AS ISSUE_QTY ,             
   A.COMPONENT_NO AS COMP_NO, A.COMPONENT_CODE,            
   A.COM_PARA1_CODE AS PARA1_CODE,            
   A.COM_PARA2_CODE AS PARA2_CODE,            
   A.ARTICLE_CODE,            
   AR.ARTICLE_NO AS ARTICLE_NO,            
   (ISNULL(A.REQUIRED_QTY,0) -ISNULL(ISSUE_RM_QTY,0)) AS PENDING_QTY           
   FROM #TMPPENDINGRM A    
   JOIN ARTICLE AR ON A.ARTICLE_CODE=AR.ARTICLE_CODE         
             
            
GOTO LAST             
            
----------------PENDING ISSUE------            
            
LBLFG_PENDING: ----FINISH GOOD PENDING DETAILS       
    
    
    
    SELECT     
    A.AGENCY_CODE AS REF_AGENCY_CODE,    
    MST.ARTICLE_SET_CODE AS ARTICLE_CODE,             
    AR.ARTICLE_NO AS FG_ARTICLE_NO,            
    A.COM_PARA1_CODE AS PARA1_CODE,            
    P1.PARA1_NAME ,          
    P2.PARA2_NAME ,            
    A.COM_PARA2_CODE AS PARA2_CODE,            
    RIGHT(A.MEMO_ID,10) AS ISSUE_MEMO_NO,            
    A.MEMO_ID,            
    A.ORDER_ID  AS WORK_ORDER_ID,            
    MST.MEMO_NO AS WORK_ORDER_NO,            
    FG_QTY,            
    CAST(0 AS BIT) AS CHCK,            
    ISSUE_QTY AS ISSUE_QTY,          
    FG_QTY-ISNULL(ISSUE_QTY,0) AS PENDING_QTY     
    FROM #TMPPENDINGRM  A     
    JOIN PRD_WO_MST MST (NOLOCK) ON MST.MEMO_ID =A.ORDER_ID      
    JOIN ARTICLE AR (NOLOCK) ON AR.ARTICLE_CODE=MST.ARTICLE_SET_CODE    
    JOIN PARA1 P1 ON P1.PARA1_CODE =A.COM_PARA1_CODE             
    JOIN PARA2 P2 ON P2.PARA2_CODE =A.COM_PARA2_CODE     
    GROUP BY  A.AGENCY_CODE ,    
    MST.ARTICLE_SET_CODE ,             
    AR.ARTICLE_NO ,            
    A.COM_PARA1_CODE ,            
    P1.PARA1_NAME ,          
    P2.PARA2_NAME ,            
    A.COM_PARA2_CODE ,            
    RIGHT(A.MEMO_ID,10) ,            
    A.MEMO_ID,            
    A.ORDER_ID  ,            
    MST.MEMO_NO ,            
    FG_QTY,                
    ISSUE_QTY     
     
     
            
               
GOTO LAST             
           
            
LBLISSUE_RM_PENDING:            
             
             
  SET @CCMD= N'SELECT CHCK,            
          CAST('''' AS VARCHAR(100)) AS MEMO_ID,            
          CAST(''LATER''+CAST(NEWID() AS VARCHAR(100)) AS VARCHAR(40)) AS ROW_ID,            
          ARTICLE_NO,ARTICLE_NAME ,            
          ARTICLE_CODE,            
          [COMPONENT_NO] ,             
          [COMPONENT_NO] AS COMP_NO ,             
          COMPONENT_CODE ,             
          COM_PARA1_CODE ,            
          COM_PARA2_CODE ,            
          UOM_CODE,UOM_NAME,            
             CONVERT(NUMERIC(12,2),A.AVG_QTY) AS AVG_QTY,            
             CONVERT(NUMERIC(12,2),A.REQUIRED_QTY) AS REQ_QTY,            
             CAST(0 AS NUMERIC(12,0)) AS ISSUE_QTY,            
             A.MEMO_ID AS ORDER_ID           
            FROM            
           (            
    SELECT CAST(0 AS BIT) AS CHCK,            
    B1.ARTICLE_NO,B1.ARTICLE_NAME ,            
          B1.ARTICLE_CODE,            
          C.ARTICLE_NO AS [COMPONENT_NO] ,            
          C.ARTICLE_CODE AS COMPONENT_CODE,             
          DET.PARA1_CODE AS COM_PARA1_CODE,            
          DET.PARA2_CODE AS COM_PARA2_CODE,            
          H.UOM_CODE,H.UOM_NAME ,            
    AVG_QTY            
    ,CONVERT(NUMERIC(12,2),AVG_QTY * '+STR(@NQTY)+') AS REQUIRED_QTY   --CHANGES BY DET QUANTITYT             
    ,MST.MEMO_ID            
    FROM PRD_WO_ART_BOM A (NOLOCK)                  
    JOIN  PRD_WO_DET B (NOLOCK) ON A.REF_ROW_ID = B.ROW_ID            
    JOIN PRD_WO_MST MST (NOLOCK) ON MST.MEMO_ID =B.MEMO_ID             
    JOIN ARTICLE B1 ON A.BOM_ARTICLE_CODE=B1.ARTICLE_CODE            
    JOIN UOM H ON H.UOM_CODE=B1.UOM_CODE               
    LEFT JOIN            
(            
     SELECT C.PARA1_CODE,C.PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY             
     FROM PRD_WO_SUB_DET C            
     WHERE C.PARA1_CODE='''+@CWHERE2+'''            
     AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
     GROUP BY REF_ROW_ID,C.PARA1_CODE,C.PARA2_CODE            
    ) DET ON B.ROW_ID=DET.REF_ROW_ID            
    JOIN ARTICLE C (NOLOCK) ON B.ARTICLE_CODE = C.ARTICLE_CODE               
    LEFT JOIN            
    (            
     SELECT B.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,A.ISSUE_QTY             
     FROM PRD_STK_TRANSFER_MATERIAL_DET A            
     JOIN             
     (            
      SELECT REF_ROW_ID,REF_WO_ID             
      FROM PRD_STK_TRANSFER_MST A            
      JOIN PRD_STK_TRANSFER_DET B ON A.MEMO_ID=B.MEMO_ID             
      WHERE A.CANCELLED =0 AND REF_WO_ID='''+@CMEMOID+'''             
     -- AND TARGET_DEPARTMENT_ID='''+@CWHERE+'''            
      GROUP BY REF_ROW_ID,REF_WO_ID            
     ) B ON A.ROW_ID  =B.REF_ROW_ID              
     WHERE  REF_WO_ID='''+@CMEMOID+'''             
    ) STK ON B.MEMO_ID=STK.REF_WO_ID            
    AND MST.ARTICLE_SET_CODE=STK.ARTICLE_CODE            
    AND DET.PARA1_CODE=STK.PARA1_CODE            
    AND DET.PARA2_CODE=STK.PARA2_CODE            
    LEFT JOIN            
    (            
       SELECT DISTINCT A.ARTICLE_CODE, A.COMPONENT_CODE,A.COM_PARA1_CODE,A.COM_PARA2_CODE            
       FROM PRD_SKU A            
       JOIN PRD_PMT B ON A.PRODUCT_UID=B.PRODUCT_UID            
       --WHERE           
      -- B.QUANTITY_IN_STOCK>0 AND           
      --  A.WORK_ORDER_ID='''+@CMEMOID+'''            
      -- AND B.DEPARTMENT_ID='''+@CWHERE+'''            
                
    )  PMT ON A.BOM_ARTICLE_CODE=PMT.ARTICLE_CODE            
    AND PMT.COMPONENT_CODE=B.ARTICLE_CODE            
    AND DET.PARA1_CODE=PMT.COM_PARA1_CODE            
    AND DET.PARA2_CODE=PMT.COM_PARA2_CODE            
 
    WHERE B.MEMO_ID='''+@CMEMOID+'''                
                         
   ) A                      
    GROUP BY MEMO_ID,CHCK,ARTICLE_NO,ARTICLE_NAME ,            
          ARTICLE_CODE,            
          [COMPONENT_NO] ,             
     UOM_CODE,UOM_NAME, COMPONENT_CODE,             
          COM_PARA1_CODE,            
          COM_PARA2_CODE,            
          UOM_CODE,UOM_NAME,AVG_QTY,(A.REQUIRED_QTY)'            
              
 PRINT @CCMD            
 EXEC SP_EXECUTESQL @CCMD             
                     
GOTO LAST             
            
LBLISSUE_ROW_VIEW:     
       
 --IF OBJECT_ID('TEMPDB..#TMPPRODUCT','U') IS NOT NULL
 --  DROP TABLE #TMPPRODUCT 
   
 -- SELECT  A.MEMO_ID AS ISSUE_ID,SUM(A.QUANTITY) AS ISSUE_QTY,
 -- BO.ITEM_MERCHANT_CODE ,  
 -- EMP.EMP_NAME  AS MERCHANT_NAME, 
 -- LM.AC_CODE AS  AC_CODE,         
 -- LM.AC_NAME  AS  AC_NAME ,
 -- B.PARA1_CODE ,
 -- B.PARA2_CODE    ,
 -- B.WO_ID 
 -- INTO #TMPPRODUCT 
 -- FROM   PRD_AGENCY_ISSUE_MATERIAL_UPC (NOLOCK) A
 -- JOIN PRD_UPCPMT B ON A.PRODUCT_CODE =B.PRODUCT_CODE 
 -- LEFT JOIN(SELECT * FROM PRD_WO_ORDERS ) WO ON WO.MEMO_ID =B.WO_ID    
 -- LEFT OUTER JOIN 
 --(
  
 -- SELECT A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE 
 -- FROM BUYER_ORDER_DET A (NOLOCK)
 -- JOIN BUYER_ORDER_MST B (NOLOCK) ON A.ORDER_ID =B.ORDER_ID 
 -- WHERE B.CANCELLED =0
 -- GROUP BY A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE
 --) BO ON BO.ORDER_ID =ISNULL(B.ORDER_ID ,WO.ORDER_ID )
 --LEFT OUTER JOIN EMPLOYEE EMP ON EMP.EMP_CODE =BO.ITEM_MERCHANT_CODE 
 --LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =BO.AC_CODE 
 --WHERE A.MEMO_ID =@CMEMOID 
 --GROUP BY  A.MEMO_ID ,BO.ITEM_MERCHANT_CODE , EMP.EMP_NAME ,
 --LM.AC_CODE , LM.AC_NAME ,B.PARA1_CODE ,B.PARA2_CODE ,B.WO_ID 
                
SELECT 
      --CASE WHEN ISNULL(@ENABLEUPC,'')='1' THEN ISNULL(TMP.ISSUE_QTY,0)
      -- ELSE A.ISSUE_QTY  END AS ISSUE_QTY,
 A.*,A.ISSUE_QTY  AS PROCESS_QTY,            
RIGHT(REF_WO_ID,10) AS WO_NO,            
PENDING_QTY=0,
'' AS ITEM_MERCHANT_CODE ,  
'' AS MERCHANT_NAME, 
'' AS AC_CODE,         
'' AS AC_NAME     
FROM            
(            
 SELECT C.REF_WO_ID,A.ARTICLE_CODE,            
 A.PARA1_CODE,PARA1_NAME COM_COLOR,            
 A.PARA2_CODE,PARA2_NAME COM_SIZE,            
 J.JOB_NAME ,            
 ISSUE_QTY            
,DEFAULT_BASIS            
,RATE            
,AMOUNT            
,A.NET_AMOUNT            
FROM PRD_AGENCY_ISSUE_ROW_MATERIAL_DET A       
JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID =B.MEMO_ID            
LEFT JOIN             
 (            
  SELECT JOB_CODE, C.MEMO_ID,C.REF_PRD_WORKORDER_MEMOID AS REF_WO_ID,REF_MATERIAL_ROW_ID            
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET C            
  WHERE C.MEMO_ID=@CMEMOID            
  GROUP BY JOB_CODE,C.MEMO_ID,C.REF_MATERIAL_ROW_ID,C.REF_PRD_WORKORDER_MEMOID            
 ) C ON A.MEMO_ID=C.MEMO_ID             
AND A.ROW_ID=C.REF_MATERIAL_ROW_ID            
JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE            
JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE            
LEFT JOIN JOBS J ON J.JOB_CODE =C.JOB_CODE             
WHERE B.MEMO_ID=@CMEMOID                       
) A      
--LEFT JOIN #TMPPRODUCT TMP ON TMP.WO_ID =A.REF_WO_ID AND TMP.PARA1_CODE =A.PARA1_CODE AND TMP.PARA2_CODE =A.PARA2_CODE 

--LEFT JOIN(SELECT * FROM PRD_WO_ORDERS ) WO ON WO.MEMO_ID =A.REF_WO_ID   
--LEFT OUTER JOIN 
-- (
  
--  SELECT A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE 
--  FROM BUYER_ORDER_DET A (NOLOCK)
--  JOIN BUYER_ORDER_MST B (NOLOCK) ON A.ORDER_ID =B.ORDER_ID 
--  WHERE B.CANCELLED =0
--  GROUP BY A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE
-- ) BO ON BO.ORDER_ID =ISNULL(A.ORDER_ID ,WO.ORDER_ID )
-- LEFT OUTER JOIN EMPLOYEE EMP ON EMP.EMP_CODE =BO.ITEM_MERCHANT_CODE 
-- LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =BO.AC_CODE 

              
--LEFT JOIN 
--(
 
--  LEFT JOIN(SELECT * FROM PRD_WO_ORDERS ) WO ON WO.MEMO_ID =A.WO_ID  
-- LEFT OUTER JOIN 
-- (
--  SELECT A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE  
--  FROM BUYER_ORDER_DET A (NOLOCK)
--  JOIN BUYER_ORDER_MST B (NOLOCK) ON A.ORDER_ID =B.ORDER_ID 
--  WHERE B.CANCELLED =0
--  GROUP BY A.ORDER_ID ,A.ITEM_MERCHANT_CODE ,B.AC_CODE
-- ) BO ON BO.ORDER_ID =ISNULL(A.ORDER_ID ,WO.ORDER_ID )
-- LEFT OUTER JOIN EMPLOYEE EMP ON EMP.EMP_CODE =BO.ITEM_MERCHANT_CODE 
-- LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =BO.AC_CODE 
 
--  --SELECT FN.AC_CODE ,FN.ITEM_MERCHANT_CODE , FN.PARA2_CODE,FN.PARA1_CODE, FN.WO_ID,FN.ITEM_MERCHANT_NAME ,  
--  -- FN.AC_NAME AS AC_NAME ,
--  -- COUNT(*) AS FN_ISSUE  
--  ---- FROM FN_WO_ALLOCATION ('','') FN
--  -- JOIN #TMPPRODUCT A ON FN.PRODUCT_CODE=A.PRODUCT_CODE 
--  ----WHERE A.MEMO_ID =@CMEMOID
--  --GROUP BY FN.AC_CODE ,FN.ITEM_MERCHANT_CODE ,FN.PARA2_CODE,FN.PARA1_CODE, FN.WO_ID,FN.ITEM_MERCHANT_NAME ,  
--  -- FN.AC_NAME 
--) FN ON FN.WO_ID  =A.REF_WO_ID AND FN.PARA1_CODE=A.PARA1_CODE  AND FN.PARA2_CODE=A.PARA2_CODE    
            
GOTO LAST             
            
LBLDEFAULTBASIS_RATE:            
DECLARE @RATE  NUMERIC(10,2)            
    
    
--SELECT * FROM SYS.TABLES WHERE NAME LIKE '%RATE%'    
    
  SELECT TOP 1 @RATE=CASE WHEN RATE=0 THEN STD_RATE ELSE  RATE END                
  FROM PRD_JOB_RATE_MST A                
  LEFT JOIN PRD_JOB_RATE_DET B ON A.JOB_CODE=B.JOB_CODE                
  WHERE B.AGENCY_CODE=@CAGENCY_CODE      
  AND ARTICLE_TYPE=1  AND A.JOB_CODE=@CJOB_CODE    
  AND B.ARTICLE_CODE=@CARTICLE_CODE          
--SELECT TOP 1 @RATE=            
--  CASE WHEN @NDEFAULT_BASIS=1  THEN JOB_RATE            
--      WHEN  @NDEFAULT_BASIS=2  THEN JOB_RATE_PCS            
--       WHEN @NDEFAULT_BASIS=3  THEN JOB_RATE_DAYS            
--       WHEN @NDEFAULT_BASIS=4  THEN JOB_RATE_HOURS            
--     ELSE 0 END              
-- FROM AGENCY_JOBS A (NOLOCK)            
-- WHERE A.AGENCY_CODE=@CAGENCY_CODE AND  DEFAULT_BASIS=@NDEFAULT_BASIS            
             
-- IF ISNULL(@RATE,0)=0            
-- BEGIN            
--    SELECT TOP 1 @RATE=            
--      CASE WHEN @NDEFAULT_BASIS=1  THEN JOB_RATE           
--      WHEN  @NDEFAULT_BASIS=2  THEN JOB_RATE_PCS            
--      WHEN @NDEFAULT_BASIS=3  THEN JOB_RATE_DAYS            
--      WHEN @NDEFAULT_BASIS=4  THEN JOB_RATE_HOURS            
--     ELSE 0 END               
--     FROM PRD_WO_ART_JOBS A           
--    JOIN PRD_WO_DET B ON A.REF_ROW_ID=B.ROW_ID            
--    WHERE B.MEMO_ID=@CMEMOID AND DEFAULT_BASIS=@NDEFAULT_BASIS            
             
-- END            
             
             
 SELECT ISNULL(@RATE,0) AS RATE             
             
             
             
GOTO LAST             
            
            
LBLGETSTKDET_VIEW:            
                 
 SET @WORKORDER_ID=@CMEMOID            
            
                 
    SELECT  CAST(0 AS BIT) AS CHCK, CAST('' AS VARCHAR(100)) AS MEMO_ID,            
    MST.MEMO_NO AS WO_NO,            
 CAST('LATER'+ CAST(NEWID() AS VARCHAR(100)) AS VARCHAR(40)) AS ROW_ID,            
 AR.ARTICLE_CODE ,            
 AR.ARTICLE_NO,AR.ARTICLE_NAME,A.MEMO_ID AS WO_ID,            
 PARA1.PARA1_NAME COM_COLOR,PARA2.PARA2_NAME COM_SIZE,            
 CONVERT(NUMERIC(10,2),SUM(K.QUANTITY)/COUNT(A.ARTICLE_CODE)) AS WO_QTY,            
 (ISNULL(STK.ISSUE_QTY,0)) AS STOCK_QTY,            
 (ISNULL(STK.PROCESS_QTY,0)) AS PROCESS_QTY,            
 CONVERT(NUMERIC(10,2),STK.ISSUE_QTY)-(ISNULL(STK.PROCESS_QTY,0)) AS PENDING_QTY,            
 CAST(0 AS NUMERIC(10,2)) AS ISSUE_QTY,            
 K.PARA1_CODE,K.PARA2_CODE,            
 1  AS DEFAULT_BASIS ,            
 0 AS RATE,            
 JOB_NAME  AS JOB_NAME,            
 J1.JOB_CODE  AS JOB_CODE,            
 'RATE/MTR' AS DEFAULT_BASIS_NAME,1 AS DEFAULT_BASIS_VALUE             
 ,CAST(0 AS NUMERIC(12,2)) AS AMOUNT            
 ,CAST(0 AS NUMERIC(12,2)) AS NET_AMOUNT             
 FROM PRD_WO_DET (NOLOCK) A              
 JOIN PRD_WO_MST MST ON MST.MEMO_ID=A.MEMO_ID            
 JOIN PRD_WO_SUB_DET K ON A.ROW_ID = K.REF_ROW_ID               
 JOIN ARTICLE B ON A.ARTICLE_CODE = B.ARTICLE_CODE                     
 JOIN UOM D ON B.UOM_CODE = D.UOM_CODE                     
 JOIN PARA1 ON PARA1.PARA1_CODE = K.PARA1_CODE                     
 JOIN PARA2 ON PARA2.PARA2_CODE = K.PARA2_CODE             
 JOIN ARTICLE AR ON AR.ARTICLE_CODE=MST.ARTICLE_SET_CODE            
 JOIN            
 (            
  SELECT DET.MEMO_ID             
  FROM PRD_WO_ART_BOM A     
  JOIN PRD_WO_DET DET ON A.REF_ROW_ID=DET.ROW_ID            
  JOIN PRD_SKU B ON A.BOM_ARTICLE_CODE=B.ARTICLE_CODE            
  JOIN PRD_PMT C ON B.PRODUCT_UID=C.PRODUCT_UID             
  WHERE QUANTITY_IN_STOCK>0      
  AND DET.MEMO_ID=@CMEMOID             
 AND B.WORK_ORDER_ID=@WORKORDER_ID            
  AND C.DEPARTMENT_ID=@CWHERE            
  GROUP BY DET.MEMO_ID             
 )PMT ON PMT.MEMO_ID=A.MEMO_ID            
  JOIN            
 (            
   SELECT C.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,            
   SUM(A.ISSUE_QTY) AS ISSUE_QTY,            
   SUM(ISSUE.ISSUE_QTY) AS PROCESS_QTY             
   FROM PRD_STK_TRANSFER_MATERIAL_DET A            
   JOIN PRD_STK_TRANSFER_MST B ON A.MEMO_ID =B.MEMO_ID            
   JOIN             
   (            
     SELECT C.MEMO_ID,C.REF_ROW_ID,REF_WO_ID            
     FROM PRD_STK_TRANSFER_DET C            
     WHERE C.REF_WO_ID=@CMEMOID            
     GROUP BY C.MEMO_ID,C.REF_ROW_ID,REF_WO_ID            
   ) C ON A.MEMO_ID=C.MEMO_ID             
   AND A.ROW_ID=C.REF_ROW_ID            
   LEFT OUTER JOIN            
   (            
                 
   SELECT A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,A.ISSUE_QTY,B.ORDER_ID            
   FROM PRD_AGENCY_ISSUE_ROW_MATERIAL_DET A            
   JOIN             
  (            
   SELECT A.MEMO_ID, A.REF_PRD_WORKORDER_MEMOID AS ORDER_ID,            
   REF_MATERIAL_ROW_ID             
   FROM PRD_AGENCY_ISSUE_MATERIAL_DET A            
   JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID=B.MEMO_ID            
   WHERE B.CANCELLED=0            
   GROUP BY A.REF_PRD_WORKORDER_MEMOID,REF_MATERIAL_ROW_ID,A.MEMO_ID            
  ) B ON A.MEMO_ID=B.MEMO_ID AND A.ROW_ID=B.REF_MATERIAL_ROW_ID            
              
    WHERE ORDER_ID=@CMEMOID             
   ) ISSUE ON C.REF_WO_ID=ISSUE.ORDER_ID AND             
   A.ARTICLE_CODE=ISSUE.ARTICLE_CODE AND  A.PARA1_CODE= ISSUE.PARA1_CODE            
   AND A.PARA2_CODE=ISSUE.PARA2_CODE             
   WHERE CANCELLED=0 AND REF_WO_ID=@CMEMOID            
   AND B.TARGET_DEPARTMENT_ID=@CWHERE            
              GROUP BY C.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE            
 ) STK ON STK.REF_WO_ID=MST.MEMO_ID             
 AND PARA1.PARA1_CODE=STK.PARA1_CODE             
 AND PARA2.PARA2_CODE=STK.PARA2_CODE            
 LEFT JOIN            
 (            
  SELECT TOP 1 DEFAULT_BASIS, A.JOB_CODE,            
  CASE WHEN ISNULL(DEFAULT_BASIS,0)=1  THEN JOB_RATE            
       WHEN ISNULL(DEFAULT_BASIS,0)=2  THEN JOB_RATE_PCS            
       WHEN ISNULL(DEFAULT_BASIS,0)=3  THEN JOB_RATE_DAYS            
       WHEN ISNULL(DEFAULT_BASIS,0)=4  THEN JOB_RATE_HOURS            
     ELSE 0 END AS RATE            
 FROM AGENCY_JOBS A (NOLOCK)            
 JOIN PRD_AGENCY_MST B (NOLOCK) ON  A.AGENCY_CODE =B.AGENCY_CODE            
 WHERE A.AGENCY_CODE=@CAGENCY_CODE            
 ) AJ ON  1=1            
 LEFT JOIN JOBS J1 ON J1.JOB_CODE=AJ.JOB_CODE            
 WHERE A.MEMO_ID=@CMEMOID             
 AND MST.CANCELLED=0            
 GROUP BY AR.ARTICLE_NO,AR.ARTICLE_CODE ,AR.ARTICLE_NAME,A.MEMO_ID ,            
 PARA1.PARA1_NAME ,PARA2.PARA2_NAME,K.PARA1_CODE,K.PARA2_CODE,STK.ISSUE_QTY,            
 JOB_NAME ,STK.PROCESS_QTY,J1.JOB_CODE  ,  MST.MEMO_NO             
             
            
GOTO LAST             
            
           
            
LBLGETCOMPDET:            
                                     
SET @CCMD= N'SELECT CHCK,ARTICLE_NO,REF_WO_ID,REF_WO_NO,            
             SUM(A.AVG_QTY) AS AVG_QTY,            
             SUM(A.REQUIRED_QTY) AS REQUIRED_QTY,            
             0 AS ISSUE_QTY,     
             '''' AS ITEM_REMARKS         
            FROM            
           (            
    SELECT CAST(0 AS BIT) AS CHCK, C.ARTICLE_NO,B.ARTICLE_CODE,            
    B.MEMO_ID AS REF_WO_ID,            
    RIGHT(B.MEMO_ID,10) AS REF_WO_NO            
    ,AVG_QTY            
    ,CONVERT(NUMERIC(12,2),AVG_QTY * '+STR(@NQTY)+') AS REQUIRED_QTY   --CHANGES BY DET QUANTITYT     
    ,STK.ISSUE_QTY                
    FROM PRD_WO_ART_BOM A (NOLOCK)                  
    JOIN PRD_WO_DET B (NOLOCK) ON A.REF_ROW_ID = B.ROW_ID            
    JOIN PRD_WO_MST MST (NOLOCK) ON MST.MEMO_ID =B.MEMO_ID              
    JOIN            
    (            
     SELECT C.PARA1_CODE,C.PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY             
     FROM PRD_WO_SUB_DET C            
     WHERE C.PARA1_CODE='''+@CWHERE2+'''            
     AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
     GROUP BY REF_ROW_ID,C.PARA1_CODE,C.PARA2_CODE            
    ) DET ON B.ROW_ID=DET.REF_ROW_ID            
    JOIN ARTICLE C (NOLOCK) ON B.ARTICLE_CODE = C.ARTICLE_CODE               
    JOIN            
    (            
     SELECT B.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,A.ISSUE_QTY             
     FROM PRD_STK_TRANSFER_MATERIAL_DET A            
     JOIN             
     (            
      SELECT REF_ROW_ID,REF_WO_ID             
      FROM PRD_STK_TRANSFER_MST A            
      JOIN PRD_STK_TRANSFER_DET B ON A.MEMO_ID=B.MEMO_ID             
      WHERE A.CANCELLED =0 AND REF_WO_ID='''+@CMEMOID+'''             
      AND TARGET_DEPARTMENT_ID='''+@CWHERE+'''            
      GROUP BY REF_ROW_ID,REF_WO_ID            
     ) B ON A.ROW_ID  =B.REF_ROW_ID              
     WHERE  REF_WO_ID='''+@CMEMOID+'''             
    ) STK ON B.MEMO_ID=STK.REF_WO_ID            
    AND MST.ARTICLE_SET_CODE=STK.ARTICLE_CODE            
    AND DET.PARA1_CODE=STK.PARA1_CODE            
    AND DET.PARA2_CODE=STK.PARA2_CODE            
    JOIN            
    (            
       SELECT DISTINCT A.ARTICLE_CODE, A.COMPONENT_CODE,A.COM_PARA1_CODE,A.COM_PARA2_CODE            
       FROM PRD_SKU A            
       JOIN PRD_PMT B ON A.PRODUCT_UID=B.PRODUCT_UID            
       WHERE B.QUANTITY_IN_STOCK>0            
       AND A.WORK_ORDER_ID='''+@CMEMOID+'''            
       AND B.DEPARTMENT_ID='''+@CWHERE+'''            
                
    )  PMT ON A.BOM_ARTICLE_CODE=PMT.ARTICLE_CODE AND            
    PMT.COMPONENT_CODE=B.ARTICLE_CODE            
    AND DET.PARA1_CODE=PMT.COM_PARA1_CODE            
    AND DET.PARA2_CODE=PMT.COM_PARA2_CODE            
                      
    WHERE B.MEMO_ID='''+@CMEMOID+'''                
                         
   ) A                      
   GROUP BY CHCK,ARTICLE_NO,REF_WO_ID,REF_WO_NO'            
              
 PRINT @CCMD            
 EXEC SP_EXECUTESQL @CCMD             
             
GOTO LAST             
            
LBLGETSTKDET:            
 
   IF ISNULL(@ENABLEUPC,'')='1'
	  SET @CAGENCY_CODE=''
	  
SET @WORKORDER_ID=@CMEMOID            
             
SELECT CAST(0 AS BIT) AS CHCK, CAST('' AS VARCHAR(100)) AS MEMO_ID,            
 CAST('LATER'+ CAST(A.WO_ID+A.PARA1_CODE+A.PARA2_CODE AS VARCHAR(100)) AS VARCHAR(40)) AS ROW_ID,            
A.ARTICLE_CODE,A.ARTICLE_NO,A.ARTICLE_NAME,            
 A.WO_ID,RIGHT(A.WO_ID,10) AS WO_NO,            
 A.PARA1_CODE,A.PARA2_CODE, A. COM_COLOR,            
 A.COM_SIZE, A.WO_QTY,  A.QUANTITY_IN_STOCK,            
A.WO_QTY-(SUM(ISNULL(ISSUE_QTY,0))-(ISNULL(REC_QTY,0)))  AS STOCK_QTY, --SUM(ISNULL(ISSUE_QTY,0))           
SUM(ISSUE_QTY)-(ISNULL(REC_QTY,0))  AS PROCESS_QTY,   --SUM(ISSUE_QTY)          
A.WO_QTY-(SUM(ISNULL(ISSUE_QTY,0))-(ISNULL(REC_QTY,0))) AS ISSUE_QTY,            
A.WO_QTY-(SUM(ISNULL(ISSUE_QTY,0))-(ISNULL(REC_QTY,0))) AS PENDING_QTY,              
1  AS DEFAULT_BASIS ,            
 0 AS RATE,JOB_NAME  AS JOB_NAME,            
 J1.JOB_CODE  AS JOB_CODE,            
 'RATE/MTR' AS DEFAULT_BASIS_NAME,1 AS DEFAULT_BASIS_VALUE            
 ,CAST(0 AS NUMERIC(12,2)) AS AMOUNT            
 ,CAST(0 AS NUMERIC(12,2)) AS NET_AMOUNT             
FROM             
(            
SELECT MST.ARTICLE_SET_CODE AS ARTICLE_CODE,B1.ARTICLE_NO,B1.ARTICLE_NAME,            
       A.MEMO_ID AS WO_ID,            
       C.PARA1_CODE,C.PARA2_CODE,      
       P11.PARA1_NAME AS COM_COLOR,            
       P21.PARA2_NAME AS COM_SIZE,            
       CONVERT(NUMERIC(10,2),(C.QUANTITY))-ISNULL(CNC_QTY,0) AS WO_QTY,            
       SUM(F.QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK    
 
 FROM PRD_WO_MST MST (NOLOCK)
 JOIN PRD_WO_DET (NOLOCK) A ON MST.MEMO_ID =A.MEMO_ID 
 JOIN
	(
	 SELECT PARA1_CODE,PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY 
	 FROM PRD_WO_SUB_DET C
	 GROUP BY REF_ROW_ID,PARA1_CODE,PARA2_CODE
 ) C ON A.ROW_ID=C.REF_ROW_ID       
--FROM PRD_WO_DET A             
--JOIN PRD_WO_MST MST ON MST.MEMO_ID=A.MEMO_ID            
JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE             
--JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID             
JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID              
JOIN ARTICLE B1 ON MST.ARTICLE_SET_CODE=B1.ARTICLE_CODE             
JOIN PRD_SKU E ON            
E.ARTICLE_CODE=D.BOM_ARTICLE_CODE            
AND A.MEMO_ID=E.WORK_ORDER_ID            
AND A.ARTICLE_CODE=E.COMPONENT_CODE              
AND C.PARA1_CODE=E.COM_PARA1_CODE             
AND C.PARA2_CODE=E.COM_PARA2_CODE            
JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID   
AND QUANTITY_IN_STOCK >0              
JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE             
JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE     
LEFT OUTER JOIN    
(    
  SELECT ARTICLE_CODE,PARA1_CODE,PARA2_CODE,B.REF_WO_ID ,    
  SUM(QUANTITY) AS CNC_QTY     
  FROM PRD_WO_CNC_MST A    
  JOIN PRD_WO_CNC_DET B ON A.MEMO_ID =B.MEMO_ID    
  WHERE A.CANCELLED=0    
  GROUP BY ARTICLE_CODE,PARA1_CODE,PARA2_CODE,B.REF_WO_ID     
) CNC ON CNC.REF_WO_ID=A.MEMO_ID    
  AND CNC.PARA1_CODE=P11.PARA1_CODE    
  AND CNC.PARA2_CODE=P21.PARA2_CODE          
WHERE A.MEMO_ID=@CMEMOID            
AND DEPARTMENT_ID=@CWHERE             
GROUP BY MST.ARTICLE_SET_CODE,C.PARA1_CODE,C.PARA2_CODE,            
P11.PARA1_NAME,P21.PARA2_NAME ,B1.ARTICLE_NO,B1.ARTICLE_NAME,A.MEMO_ID,CNC_QTY,C.QUANTITY            
) A            
JOIN             
(            
  SELECT C.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,            
   SUM(A.ISSUE_QTY) AS STK_QTY            
  -- SUM(ISNULL(ISSUE.ISSUE_QTY,0)) AS PROCESS_QTY             
   FROM PRD_STK_TRANSFER_MATERIAL_DET A            
   JOIN PRD_STK_TRANSFER_MST B ON A.MEMO_ID =B.MEMO_ID            
   JOIN             
   (            
     SELECT C.MEMO_ID,C.REF_ROW_ID,REF_WO_ID            
     FROM PRD_STK_TRANSFER_DET C            
     WHERE C.REF_WO_ID=@CMEMOID            
     GROUP BY C.MEMO_ID,C.REF_ROW_ID,REF_WO_ID            
   ) C ON A.MEMO_ID=C.MEMO_ID             
  AND A.ROW_ID=C.REF_ROW_ID            
  WHERE B.CANCELLED=0            
  AND B.TARGET_DEPARTMENT_ID=@CWHERE            
  GROUP BY C.REF_WO_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE             
) STK  ON  STK.REF_WO_ID=A.WO_ID AND            
A.PARA1_CODE=STK.PARA1_CODE             
AND A.PARA2_CODE=STK.PARA2_CODE            
AND STK.ARTICLE_CODE=A.ARTICLE_CODE            
LEFT JOIN             
(            
  SELECT ORDER_ID,C.REF_MATERIAL_ROW_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,        
   SUM(A.ISSUE_QTY) AS ISSUE_QTY            
  -- SUM(ISNULL(ISSUE.ISSUE_QTY,0)) AS PROCESS_QTY             
   FROM PRD_AGENCY_ISSUE_ROW_MATERIAL_DET A            
   JOIN PRD_AGENCY_ISSUE_MATERIAL_MST B ON A.MEMO_ID =B.MEMO_ID            
   JOIN             
   (            
     SELECT C.REF_PRD_WORKORDER_MEMOID AS ORDER_ID,C.MEMO_ID,C.REF_MATERIAL_ROW_ID            
     FROM PRD_AGENCY_ISSUE_MATERIAL_DET C            
     WHERE C.REF_PRD_WORKORDER_MEMOID=@CMEMOID             
     GROUP BY C.REF_PRD_WORKORDER_MEMOID,C.MEMO_ID,C.REF_MATERIAL_ROW_ID            
   ) C ON A.MEMO_ID=C.MEMO_ID             
  AND A.ROW_ID=C.REF_MATERIAL_ROW_ID            
  WHERE B.CANCELLED=0            
  AND B.DEPARTMENT_ID=@CWHERE             
  AND(@CAGENCY_CODE='' OR B.REF_AGENCY_CODE=@CAGENCY_CODE)
  GROUP BY ORDER_ID,C.REF_MATERIAL_ROW_ID,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE             
) P              
ON  P.ORDER_ID=A.WO_ID AND            
A.PARA1_CODE=P.PARA1_CODE             
AND A.PARA2_CODE=P.PARA2_CODE        
AND P.ARTICLE_CODE=A.ARTICLE_CODE    
--  
 LEFT OUTER JOIN  
 (  
    
  SELECT C.ORDER_ID, A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE  ,  
   SUM(A.REC_QTY) AS REC_QTY  
  FROM PRD_AGENCY_ROW_MATERIAL_RECEIPT_DET A  
  JOIN PRD_AGENCY_MATERIAL_RECEIPT_MST B ON A.MEMO_ID=B.MEMO_ID  
  JOIN  
  (  
   SELECT ID.REF_PRD_WORKORDER_MEMOID AS ORDER_ID, A.REF_MATERIAL_ROW_ID  
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET A  
   JOIN PRD_AGENCY_ISSUE_MATERIAL_DET ID ON A.REF_ROW_ID =ID.ROW_ID   
   JOIN PRD_AGENCY_ISSUE_MATERIAL_MST IM ON IM.MEMO_ID  =ID.MEMO_ID   
   WHERE IM.CANCELLED =0   
   AND ID.REF_PRD_WORKORDER_MEMOID=@CMEMOID  
   AND(@CAGENCY_CODE='' OR IM.REF_AGENCY_CODE=@CAGENCY_CODE)   
   GROUP BY ID.REF_PRD_WORKORDER_MEMOID , A.REF_MATERIAL_ROW_ID  
   UNION  
   SELECT ID.REF_PRD_WORKORDER_MEMOID AS ORDER_ID, A.REF_MATERIAL_ROW_ID  
   FROM PRD_AGENCY_MATERIAL_RECEIPT_DET A  
   JOIN PRD_AGENCY_ISSUE_MATERIAL_DET_PENDING ID ON A.REF_ROW_ID =ID.ROW_ID   
   JOIN PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING IM ON IM.MEMO_ID  =ID.MEMO_ID   
   WHERE IM.CANCELLED =0   
   AND ID.REF_PRD_WORKORDER_MEMOID=@CMEMOID     
    AND(@CAGENCY_CODE='' OR IM.REF_AGENCY_CODE=@CAGENCY_CODE)  
   GROUP BY ID.REF_PRD_WORKORDER_MEMOID , A.REF_MATERIAL_ROW_ID  
  ) C ON A.ROW_ID =C.REF_MATERIAL_ROW_ID  
  WHERE B.CANCELLED=0  
  AND B.DEPARTMENT_ID=@CWHERE
   AND(@CAGENCY_CODE='' OR B.AGENCY_CODE=@CAGENCY_CODE)     
  GROUP BY C.ORDER_ID, A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE  
  
  
 ) REC  
 ON REC.ORDER_ID=A.WO_ID AND            
 A.PARA1_CODE=REC.PARA1_CODE             
 AND A.PARA2_CODE=REC.PARA2_CODE            
 AND REC.ARTICLE_CODE=A.ARTICLE_CODE   
--          
LEFT JOIN            
 (            
  SELECT TOP 1 DEFAULT_BASIS, A.JOB_CODE,            
  CASE WHEN ISNULL(DEFAULT_BASIS,0)=1  THEN JOB_RATE            
       WHEN ISNULL(DEFAULT_BASIS,0)=2  THEN JOB_RATE_PCS            
       WHEN ISNULL(DEFAULT_BASIS,0)=3  THEN JOB_RATE_DAYS            
       WHEN ISNULL(DEFAULT_BASIS,0)=4  THEN JOB_RATE_HOURS            
     ELSE 0 END AS RATE            
 FROM AGENCY_JOBS A (NOLOCK)            
 JOIN PRD_AGENCY_MST B (NOLOCK) ON  A.AGENCY_CODE =B.AGENCY_CODE            
 WHERE A.AGENCY_CODE=@CAGENCY_CODE            
) AJ ON  1=1            
LEFT JOIN JOBS J1 ON J1.JOB_CODE=AJ.JOB_CODE            
GROUP BY            
A.ARTICLE_CODE,A.ARTICLE_NO,A.ARTICLE_NAME,            
       A.WO_ID,            
       A.PARA1_CODE,A.PARA2_CODE,            
       A. COM_COLOR,            
        A.COM_SIZE,            
        A.WO_QTY,            
        A.QUANTITY_IN_STOCK,            
STK_QTY ,JOB_NAME  ,            
 J1.JOB_CODE  ,(ISNULL(REC_QTY,0))      
HAVING STK_QTY -(SUM(ISNULL(ISSUE_QTY,0))-(ISNULL(REC_QTY,0))) >0            
            
      
            
GOTO LAST             
                                  
            
LBLNAVIGATE:    
    EXECUTE SP_NAVIGATE 'PRD_AGENCY_ISSUE_MATERIAL_MST',@NNAVMODE,@CMEMOID,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID',@CWHERE          
                        
 --SET @CCMD=N'SELECT MEMO_ID,MEMO_NO FROM PRD_AGENCY_ISSUE_MATERIAL_MST '+(CASE WHEN ISNULL(@CWHERE,'')='' THEN ''                    
 --   ELSE ' WHERE '+@CWHERE END)                    
 --PRINT @CCMD                    
 --EXEC SP_EXECUTESQL @CCMD                              
GOTO LAST               
            
                   
LBLNAVIGATE_PENDING:        
 EXECUTE SP_NAVIGATE 'PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING',@NNAVMODE,@CMEMOID,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID',@CWHERE          
                                   
 --SET @CCMD=N'SELECT MEMO_ID,MEMO_NO FROM PRD_AGENCY_ISSUE_MATERIAL_MST_PENDING '+(CASE WHEN ISNULL(@CWHERE,'')='' THEN ''                    
 --   ELSE ' WHERE '+@CWHERE END)                    
 --PRINT @CCMD                    
 --EXEC SP_EXECUTESQL @CCMD                              
GOTO LAST                           
                            
LBLGETMASTERS:               
                         
 SELECT DISTINCT T1.*, T2.USERNAME,T3.DEPARTMENT_NAME,            
 --ISNULL(T6.MEMO_ID,'') AS WORK_ORDER_MEMO_ID,                            
 --ISNULL(T6.MEMO_ID,'') AS REF_PRD_WORKORDER_MEMOID,            
 --ISNULL(J.JOB_NAME,'') AS JOB_NAME,                                         
 --(CASE WHEN T7.MEMO_DT <> '' THEN CONVERT(CHAR(10),ISNULL(T7.MEMO_DT,''),105) ELSE ''  END) AS WORKORDERDT                            
 ISNULL(AGE.AGENCY_NAME,'') AS AGENCY_NAME                            
 ,ISNULL(ARTSET.ARTICLE_NO,'') AS ARTICLE_SET ,FRM.FORM_NAME          
 FROM PRD_AGENCY_ISSUE_MATERIAL_MST T1              
 JOIN PRD_AGENCY_ISSUE_MATERIAL_DET D ON T1.MEMO_ID=D.MEMO_ID                           
 JOIN USERS T2 ON T1.USER_CODE = T2.USER_CODE                            
 LEFT OUTER JOIN PRD_AGENCY_MST AGE ON T1.REF_AGENCY_CODE = AGE.AGENCY_CODE                
 LEFT OUTER JOIN PRD_DEPARTMENT_MST T3 ON T3.DEPARTMENT_ID = T1.DEPARTMENT_ID                   
 LEFT OUTER JOIN PRD_WO_DET T6 ON D.REF_PRD_WORKORDER_MEMOID= T6.MEMO_ID            
 LEFT OUTER JOIN PRD_WO_MST T7 ON T6.MEMO_ID= T7.MEMO_ID                                        
 LEFT OUTER JOIN JOBS J ON J.JOB_CODE=D.JOB_CODE                            
 LEFT OUTER JOIN ARTICLE ARTSET ON T7.ARTICLE_SET_CODE = ARTSET.ARTICLE_CODE                             
 JOIN FORM FRM ON T1.TAX_FORM_ID=FRM.FORM_ID                          
 WHERE T1.MEMO_ID = @CMEMOID                            
GOTO LAST                            
                            
LBLGETDETAILS:                            
                             
-- DECLARE @CREFWORKORDERMEMOID VARCHAR(MAX),@CSOURCEDEPTID VARCHAR(MAX) --CHANGE MAX                            
 IF @CMEMOID <> ''                            
 BEGIN                            
  SELECT TOP 1 @CREFWORKORDERMEMOID=REF_PRD_WORKORDER_MEMOID FROM PRD_AGENCY_ISSUE_MATERIAL_DET WHERE MEMO_ID = @CMEMOID                        
  SELECT TOP 1 @CSOURCEDEPTID = DEPARTMENT_ID  FROM PRD_AGENCY_ISSUE_MATERIAL_MST WHERE MEMO_ID = @CMEMOID                        
 END                            
 ELSE                            
  SELECT @CREFWORKORDERMEMOID='' ,@CSOURCEDEPTID =''              
              
              
                        
                             
 SET @CCMD = N'SELECT  CAST(1 AS BIT) AS CHCK,C.UOM_NAME,D.PRODUCT_UID,D.[QUANTITY]  ,D.[ROW_ID]  ,D.[LAST_UPDATE]  ,D.[TS]  ,D.[ADDITIONAL_QUANTITY]  ,D.[ARTICLE_CODE] ,D.[AVG_QTY]                          
  ,D.[MEMO_ID]  ,D.[REF_ROW_ID]  ,D.[TYPE]  ,D.[REF_COMPONENT_ARTICLE_CODE]  ,D.[GROSS_WEIGHT] ,D.[NO_OF_PCS]  ,D.RATE  ,D.[AMOUNT]  ,D.[DISCOUNT_PERCENTAGE]  ,D.[DISCOUNT_AMOUNT]                          
  ,D.[NET_AMOUNT], B.ARTICLE_NO, B.ARTICLE_NAME,SKU.PARA1_CODE,SKU.PARA2_CODE, PARA1.PARA1_NAME, D.ROW_ID , ARTCOM.ARTICLE_NO AS COMP_NAME,                        
  CASE WHEN ISNULL(P.QUANTITY_IN_STOCK,0)>0 THEN P.QUANTITY_IN_STOCK WHEN ISNULL(P.WIP,0)>0 THEN P.WIP ELSE ISNULL(P.QUANTITY_IN_STOCK,0) END AS QUANTITY_IN_STOCK                         
  ,PARA2.PARA2_NAME,ISNULL(O.ISSUED_QTY,0) AS ISSUED_QTY, ISNULL(O.TOTAL_QTY,0) AS TOTAL_QTY,                        
  (ISNULL(O.TOTAL_QTY,0) - ISNULL(O.ISSUED_QTY ,0)) AS BALANCE_QTY,                            
  ISNULL(B.ENABLE_FIXWT_ENTRY,0) AS ENABLE_FIXWT_ENTRY,ISNULL(B.FIX_WEIGHT,0) AS FIX_WEIGHT                             
  ,D.STOCK_TYPE,SKU.PRODUCT_CODE,B.DISCON ,PCS=D.PCS ,            
  AVERAGE=D.AVERAGE ,D.DEFAULT_BASIS AS DEFAULT_BASIS ,D.JOB_CODE AS JOB_CODE,            
  JOBS.JOB_NAME AS JOB_NAME ,REF_PRD_WORKORDER_MEMOID AS REF_WO_ID ,            
  RIGHT(REF_PRD_WORKORDER_MEMOID,10) AS REF_WO_NO ,            
  REF_PRD_WORKORDER_MEMOID AS REF_PRD_WORKORDER_MEMOID,            
  P1.PARA1_NAME AS COM_COLOR,            
  P2.PARA2_NAME AS COM_SIZE,            
  D.REF_MATERIAL_ROW_ID,            
  CAST('''' AS VARCHAR(100)) AS REF_ISSUE_ID,    
  D.ITEM_REMARKS   ,
  CAST(COM_PARA1_CODE AS VARCHAR(10)) AS COMPARA1_CODE,
  CAST(COM_PARA2_CODE AS VARCHAR(10)) AS COMPARA2_CODE         
            
  FROM PRD_AGENCY_ISSUE_MATERIAL_DET D             
  JOIN JOBS ON D.JOB_CODE=JOBS.JOB_CODE                       
  JOIN PRD_SKU SKU ON SKU.PRODUCT_UID=D.PRODUCT_UID                        
  JOIN ARTICLE B ON SKU.ARTICLE_CODE  = B.ARTICLE_CODE                             
  JOIN PRD_AGENCY_ISSUE_MATERIAL_MST IM ON IM.MEMO_ID=D.MEMO_ID                          
  JOIN UOM C ON B.UOM_CODE = C.UOM_CODE                         
  JOIN PARA1 ON PARA1.PARA1_CODE = SKU.PARA1_CODE                            
  JOIN PARA2 ON PARA2.PARA2_CODE = SKU.PARA2_CODE                             
  JOIN PRD_PMT P ON P.PRODUCT_UID = D.PRODUCT_UID AND P.DEPARTMENT_ID = IM.DEPARTMENT_ID                        
  JOIN ARTICLE ARTCOM ON D.REF_COMPONENT_ARTICLE_CODE = ARTCOM.ARTICLE_CODE                   
  LEFT JOIN PARA1 P1 ON SKU.COM_PARA1_CODE=P1.PARA1_CODE            
  LEFT JOIN PARA2 P2 ON SKU.COM_PARA2_CODE=P2.PARA2_CODE               LEFT OUTER JOIN                         
  (                        
   SELECT P1.PARA1_NAME,P2.PARA2_NAME, A.ARTICLE_CODE,K.PARA1_CODE,K.PARA2_CODE,K.QUANTITY AS TOTAL_QTY, S.ISSUED_QTY ,S.PRODUCT_UID                        
   FROM PRD_WO_DET A                         
   JOIN PRD_WO_SUB_DET K ON A.ROW_ID = K.REF_ROW_ID                
   JOIN PARA1 P1 ON P1.PARA1_CODE = K.PARA1_CODE                     
   JOIN PARA2 P2 ON P2.PARA2_CODE = K.PARA2_CODE                              
   LEFT OUTER JOIN                             
   (                        
    SELECT D.PRODUCT_UID,D.ARTICLE_CODE,SK.PARA1_CODE,SK.PARA2_CODE,SUM(D.QUANTITY) AS ISSUED_QTY,                            
    D.REF_COMPONENT_ARTICLE_CODE AS RCA                             
    FROM PRD_AGENCY_ISSUE_MATERIAL_DET D                         
    JOIN PRD_AGENCY_ISSUE_MATERIAL_MST M ON M.MEMO_ID = D.MEMO_ID                             
    JOIN PRD_SKU SK ON SK.PRODUCT_UID=D.PRODUCT_UID                        
    WHERE D.REF_PRD_WORKORDER_MEMOID = '''+ @CREFWORKORDERMEMOID +''' AND M.DEPARTMENT_ID = '''+ @CSOURCEDEPTID +'''                             
    AND M.CANCELLED = 0                            
     GROUP BY  D.ARTICLE_CODE,D.REF_COMPONENT_ARTICLE_CODE,D.PRODUCT_UID,SK.PARA1_CODE,SK.PARA2_CODE                        
   ) S ON S.ARTICLE_CODE= A.ARTICLE_CODE AND S.PARA1_CODE = K.PARA1_CODE AND  S.PARA2_CODE = K.PARA2_CODE                             
   AND S.RCA = A.ARTICLE_CODE WHERE A.MEMO_ID ='''+ @CREFWORKORDERMEMOID +'''                        
  ) O ON O.PRODUCT_UID = SKU.PRODUCT_UID --AND O.ARTICLE_CODE = D.REF_COMPONENT_ARTICLE_CODE                            
  WHERE D.MEMO_ID ='''+@CMEMOID+''' --AND P.DEPARTMENT_ID='''+@CWHERE+''' --AND D.TYPE = 1 '                          
 PRINT @CCMD                            
 EXECUTE SP_EXECUTESQL @CCMD                            
                            
                            
 SET @CCMD = N'SELECT CAST('''' AS VARCHAR(50)) AS  COM_PARA1_NAME,CAST('''' AS VARCHAR(50)) AS COM_PARA2_NAME,            
 CAST('''' AS VARCHAR(50)) AS UOM_NAME,CAST('''' AS VARCHAR(50)) AS PRODUCT_UID,CAST(0 AS NUMERIC(10,3)) AS QUANTITY,                            
 CAST('''' AS VARCHAR(50)) AS ARTICLE_NO,CAST('''' AS VARCHAR(50)) AS ROW_ID,                            
 CAST(0 AS NUMERIC(10,3)) AS QUANTITY_IN_STOCK,                            
 --CHANGE                            
 CAST(0 AS BIT) AS TYPE,CAST('''' AS VARCHAR(50)) AS PARA1_CODE,CAST('''' AS VARCHAR(50)) AS PARA2_CODE,                            
 CAST('''' AS VARCHAR(50)) AS PARA1_NAME,CAST('''' AS VARCHAR(50)) AS PARA2_NAME             
 ,CAST('''' AS VARCHAR(50)) AS PRODUCT_CODE,            
 '''' AS JOB_CODE,            
  '''' AS JOB_NAME ,            
 '''' AS REF_WO_ID ,            
  '''' AS REF_WO_NO,            
  '''' AS REF_PRD_WORKORDER_MEMOID,            
  '''' AS REF_MATERIAL_ROW_ID  ,    
  '''' AS ITEM_REMARKS  ,
  CAST('''' AS VARCHAR(10)) AS COMPARA1_CODE,
  CAST('''' AS VARCHAR(10)) AS COMPARA2_CODE                            
 FROM PRD_AGENCY_ISSUE_MATERIAL_MST WHERE 1=2'                            
                             
 PRINT @CCMD                            
 EXECUTE SP_EXECUTESQL @CCMD                            
                            
 GOTO LAST                            
                            
                            
                  
LBLGETDEPARTMENT:  --SELECT * FROM PRD_AGENCY_MST                          
 SELECT * FROM PRD_AGENCY_MST WHERE AGENCY_CODE <> '00000' AND INACTIVE = 0                            
 --CHANGE                            
 ORDER BY AGENCY_NAME --                            
GOTO LAST                            
                  
LBLGETWORKORDERMASTER:                            
 SELECT DISTINCT T1.*,CONVERT(CHAR(10),ISNULL(T1.MEMO_DT,''),105) AS MEMO_DATE,ART.ARTICLE_NO                             
    FROM PRD_WO_MST T1                            
    JOIN PRD_WO_DET T2 ON T2.MEMO_ID = T1.MEMO_ID                            
    JOIN ARTICLE ART ON T1.ARTICLE_SET_CODE = ART.ARTICLE_CODE                             
    WHERE T1.CANCELLED = 0 AND T1.MARK_AS_COMPLETED =1             
    AND (@CMEMOID='' OR T1.MEMO_ID=@CMEMOID)            
    --AND ART.ARTICLE_CODE=@CWHERE2            
              
              
            
      
GOTO LAST                            
                            
LBLGETWORKORDERDETAILS:                            
                            
  SELECT A.ROW_ID,B.ARTICLE_CODE,B.ARTICLE_NO                              
  FROM PRD_WO_DET A JOIN ARTICLE B ON A.ARTICLE_CODE = B.ARTICLE_CODE                              
  WHERE MEMO_ID = @CMEMOID                             
                              
  GOTO LAST                            
                            
LBLGETORDERWISEITEMS:                           
                     
  --SELECT * FROM SYS.TABLES WHERE NAME LIKE '%WO_SUB%'            
            
            
            
SET @CQUERY1 = N' SELECT  CAST(0 AS BIT) AS CHCK,A.ARTICLE_CODE AS [COMPONENT_CODE],            
C.PARA1_CODE AS COMPARA1_CODE,C.PARA2_CODE AS COMPARA2_CODE,            
 B.ARTICLE_NO AS [COMP_NAME], P11.PARA1_NAME AS COM_COLOR,P21.PARA2_NAME AS COM_SIZE ,B1.ARTICLE_NO,B1.ARTICLE_NAME  ,P1.PARA1_NAME ,P2.PARA2_NAME             
,SUM(ISNULL(D.AVG_QTY,0)) AS AVG_QTY ,E.PRODUCT_UID,E.ARTICLE_CODE AS ARTICLE_CODE,E.PARA1_CODE ,E.PARA2_CODE,A.ROW_ID AS REF_ROW_ID ,                            
NEWID() AS ROW_ID ,CAST(0 AS NUMERIC(10,2)) AS QUANTITY ,(F.QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK ,(F.QUANTITY_IN_STOCK) AS ORG_QUANTITY_IN_STOCK                
,SUM('''+STR(@NQTY)+'''* ISNULL(D.AVG_QTY,0)) AS TOTAL_QTY ,SUM(ISNULL(S.ISSUED_QTY,0)) AS ISSUED_QTY             
,SUM((ISNULL(C.QUANTITY,0)* ISNULL(D.AVG_QTY,0)) - ISNULL(S.ISSUED_QTY ,0)) AS BALANCE_QTY             
, ISNULL(B.ENABLE_FIXWT_ENTRY,0) AS ENABLE_FIXWT_ENTRY,ISNULL(B.FIX_WEIGHT,0) AS FIX_WEIGHT                        
,CAST(0 AS NUMERIC(10,3)) AS GROSS_WEIGHT,CAST(0 AS NUMERIC(10,3)) AS NO_OF_PCS            
,E.MRP ,E.WS_PRICE,E.TAX_AMOUNT AS ITEM_TAX_AMOUNT,             
E.FORM_ID AS ITEM_FORM_ID,G.FORM_NAME,G.TAX_PERCENTAGE AS ITEM_TAX_PERCENTAGE            
, B.UOM_CODE,H.UOM_NAME ,            
CASE WHEN ISNULL(AJ.DEFAULT_BASIS,0)<>0 THEN AJ.DEFAULT_BASIS             
     WHEN ISNULL(J.DEFAULT_BASIS,0)<>0 THEN J.DEFAULT_BASIS             
ELSE 1 END   AS DEFAULT_BASIS ,            
0 AS RATE             
,ISNULL(S.DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE,ISNULL(S.DISCOUNT_AMOUNT,0) AS DISCOUNT_AMOUNT             
,SUM(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END)) AS AMOUNT             
,SUM(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END))-ISNULL(S.DISCOUNT_AMOUNT,0) AS NET_AMOUNT             
,SM.SECTION_NAME,SD.SUB_SECTION_NAME ,CAST(1 AS NUMERIC(1,0)) AS STOCK_TYPE ,ISNULL(C.QUANTITY,0) AS COM_QTY            
,E.PRODUCT_CODE ,B1.DISCON,CAST(0 AS NUMERIC(10,2)) AS PCS ,CAST(0 AS NUMERIC(10,2)) AS AVG_QTY1 ,            
J1.JOB_CODE,            
J1.JOB_NAME ,            
A.MEMO_ID AS REF_WO_ID ,            
RIGHT(A.MEMO_ID,10) AS REF_WO_NO,            
A.MEMO_ID AS REF_PRD_WORKORDER_MEMOID,            
SUM(PRD.QUANTITY) AS ORD_QUANTITY,            
A.MEMO_ID,            
CAST('''' AS VARCHAR(100)) AS REF_MATERIAL_ROW_ID ,    
CAST('''' AS VARCHAR(1000)) AS ITEM_REMARKS           
FROM PRD_WO_DET A             
JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE             
JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID             
JOIN PRD_WO_ART_BOM D ON C.REF_ROW_ID=D.REF_ROW_ID              
JOIN ARTICLE B1 ON D.BOM_ARTICLE_CODE=B1.ARTICLE_CODE             
JOIN PRD_SKU E ON            
E.ARTICLE_CODE=D.BOM_ARTICLE_CODE            
AND A.MEMO_ID=E.WORK_ORDER_ID            
AND A.ARTICLE_CODE=E.COMPONENT_CODE              
AND C.PARA1_CODE=E.COM_PARA1_CODE             
AND C.PARA2_CODE=E.COM_PARA2_CODE            
JOIN            
(            
 SELECT A.ARTICLE_CODE,A.MEMO_ID ,SUM(QUANTITY) AS QUANTITY            
 FROM PRD_WO_DET A            
 JOIN PRD_WO_SUB_DET B ON A.ROW_ID=B.REF_ROW_ID            
  GROUP BY A.ARTICLE_CODE, A.MEMO_ID            
) PRD ON PRD.MEMO_ID=A.MEMO_ID AND PRD.ARTICLE_CODE=A.ARTICLE_CODE            
'            
            
SET @CQUERY2 = N'  JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B1.SUB_SECTION_CODE             
 JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE             
 JOIN PRD_PMT F ON E.PRODUCT_UID=F.PRODUCT_UID'             
IF ISNULL(@NNAVMODE,0)=0            
SET @CQUERY2 = @CQUERY2+ N' AND QUANTITY_IN_STOCK >0 '              --AND QUANTITY_IN_STOCK >0             
SET @CQUERY2 = @CQUERY2+ N'  JOIN PARA1 P1 ON P1.PARA1_CODE=E.PARA1_CODE            
 JOIN PARA2 P2 ON P2.PARA2_CODE=E.PARA2_CODE             
 JOIN PARA1 P11 ON P11.PARA1_CODE=C.PARA1_CODE             
 JOIN PARA2 P21 ON P21.PARA2_CODE=C.PARA2_CODE             
LEFT JOIN            
(            
 SELECT TOP 1  DEFAULT_BASIS, A.JOB_CODE,            
JOB_RATE AS RATE            
FROM AGENCY_JOBS A (NOLOCK)            
WHERE A.AGENCY_CODE='''+@CAGENCY_CODE +'''            
--AND ('''+@CWHERE2+''' ='''' OR A.JOB_CODE='''+@CWHERE2+''' )            
) AJ ON 1=1            
LEFT OUTER JOIN             
(            
 SELECT TOP 1 A.MEMO_ID, J.REF_ROW_ID,J.DEFAULT_BASIS,J.JOB_RATE,             
 J.JOB_RATE_PCS,            
 J.JOB_RATE_DAYS, 
 J.JOB_RATE_HOURS,            
 JOB_CODE              
 FROM PRD_WO_DET A             
 JOIN PRD_WO_SUB_DET C ON A.ROW_ID=C.REF_ROW_ID             
 JOIN PRD_WO_ART_JOBS J ON C.REF_ROW_ID=J.REF_ROW_ID            
 WHERE J.JOB_RATE<>0 AND A.MEMO_ID='''+@CMEMOID+'''            
 AND C.PARA1_CODE='''+@CWHERE2+'''            
 AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
            
) J ON  A.MEMO_ID=J.MEMO_ID AND C.REF_ROW_ID=J.REF_ROW_ID            
 LEFT JOIN JOBS J1 ON J1.JOB_CODE=CASE WHEN '''+@CJOB_CODE+'''<>'''' THEN '''+@CJOB_CODE+''' ELSE ISNULL(AJ.JOB_CODE,J.JOB_CODE ) END            
 JOIN FORM G ON G.FORM_ID=E.FORM_ID             
LEFT JOIN (             
SELECT D.AVG_QTY,D.REF_COMPONENT_ARTICLE_CODE,SUM(D.QUANTITY) AS ISSUED_QTY ,D.PRODUCT_UID             
,D.RATE,D.AMOUNT,D.DISCOUNT_PERCENTAGE,D.DISCOUNT_AMOUNT,D.NET_AMOUNT             
FROM PRD_AGENCY_ISSUE_MATERIAL_DET D JOIN PRD_AGENCY_ISSUE_MATERIAL_MST M ON M.MEMO_ID = D.MEMO_ID              
WHERE ('''+@CMEMOID+'''='''' OR D.REF_PRD_WORKORDER_MEMOID = '''+@CMEMOID+''')             
AND M.DEPARTMENT_ID = '''+ SUBSTRING(@CWHERE,5,15) +''' AND M.CANCELLED = 0              
 GROUP BY D.RATE,D.AMOUNT,D.DISCOUNT_PERCENTAGE,D.PRODUCT_UID,D.DISCOUNT_AMOUNT,D.NET_AMOUNT , D.AVG_QTY,D.REF_COMPONENT_ARTICLE_CODE              
) S ON E.PRODUCT_UID=S.PRODUCT_UID'             
SET @CQUERY11=N' JOIN UOM H ON H.UOM_CODE=B1.UOM_CODE'            
SET @CQUERY11 = @CQUERY11+ N'             
WHERE ('''+@CMEMOID+'''= '''' OR A.MEMO_ID= '''+@CMEMOID+''')            
AND DEPARTMENT_ID='''+@CWHERE+'''              
AND C.PARA1_CODE='''+@CWHERE2+'''            
AND C.PARA2_CODE='''+@CPARA2_CODE+'''            
            
--AND('''+@CWHERE2+'''='''' OR J1.JOB_CODE='''+@CWHERE2+''' )            
'            
SET @CQUERY21=N' GROUP BY A.ARTICLE_CODE,B.ARTICLE_NO,P11.PARA1_NAME,P21.PARA2_NAME,B1.ARTICLE_NO,B1.ARTICLE_NAME,P1.PARA1_NAME,P2.PARA2_NAME                             
, E.PRODUCT_UID,E.ARTICLE_CODE,E.PARA1_CODE,E.PARA2_CODE,            
A.ROW_ID,ISNULL(B.ENABLE_FIXWT_ENTRY,0),ISNULL(B.FIX_WEIGHT,0),E.MRP,E.WS_PRICE,E.TAX_AMOUNT ,            
E.FORM_ID ,G.FORM_NAME,G.TAX_PERCENTAGE , B.UOM_CODE,H.UOM_NAME               
,CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END             
, ISNULL(S.DISCOUNT_PERCENTAGE,0) ,ISNULL(S.DISCOUNT_AMOUNT,0)            
--,(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END))             
--,(ISNULL(C.QUANTITY,0) * ISNULL(D.AVG_QTY,0)*(CASE WHEN ISNULL(E.PURCHASE_PRICE,0)=0 THEN 0 ELSE E.PURCHASE_PRICE END))-ISNULL(S.DISCOUNT_AMOUNT,0)             
,SM.SECTION_NAME,SD.SUB_SECTION_NAME ,ISNULL(C.QUANTITY,0),F.QUANTITY_IN_STOCK ,C.PARA1_CODE,C.PARA2_CODE            
,E.PRODUCT_CODE,B1.DISCON ,            
CASE WHEN ISNULL(AJ.DEFAULT_BASIS,0)<>0 THEN AJ.DEFAULT_BASIS             
     WHEN ISNULL(J.DEFAULT_BASIS,0)<>0 THEN J.DEFAULT_BASIS             
ELSE 1 END  ,            
CASE WHEN ISNULL(AJ.RATE,0)<>0 THEN AJ.RATE             
     WHEN ISNULL(J.DEFAULT_BASIS,0)=1  THEN J.JOB_RATE            
     WHEN ISNULL(J.DEFAULT_BASIS,0)=2  THEN J.JOB_RATE_PCS            
     WHEN ISNULL(J.DEFAULT_BASIS,0)=3  THEN J.JOB_RATE_DAYS            
     WHEN ISNULL(J.DEFAULT_BASIS,0)=4  THEN J.JOB_RATE_HOURS            
   --  WHEN ISNULL(ART_JOBS.RATE,0)<>0 THEN ART_JOBS.RATE             
ELSE 0 END,J1.JOB_CODE,J1.JOB_NAME ,A.MEMO_ID  ,            
RIGHT(A.MEMO_ID,10)   '              
            
     
            
PRINT @CQUERY1            
PRINT @CQUERY2            
PRINT @CQUERY11            
PRINT @CQUERY21            
EXEC (@CQUERY1+@CQUERY2+@CQUERY11+@CQUERY21)              
            
                   
                             
 GOTO LAST                            
                            
LBLGETWODETAILS:                            
GOTO LAST                            
                        
LBLGETLEDGERS:                            
SELECT DISTINCT T1.* FROM PRD_AGENCY_MST T1              
JOIN AGENCY_JOBS T2 ON T2.AGENCY_CODE = T1.AGENCY_CODE   
JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=T1.AC_CODE                                         
 WHERE( @CWHERE= '' OR T2.JOB_CODE = @CWHERE )   
 AND LM.INACTIVE=0         
 ORDER BY T1.AGENCY_NAME                             
 GOTO LAST                            
                            
LBLGETJOBS:                            
 
 SELECT DISTINCT JOBS.* FROM PRD_WO_DET D                             
 JOIN PRD_WO_ART_JOBS J ON D.ROW_ID = J.REF_ROW_ID                             
 JOIN JOBS ON J.JOB_CODE = JOBS.JOB_CODE  
 JOIN AGENCY_JOBS AG ON AG.JOB_CODE=JOBS.JOB_CODE                           
 WHERE (@CMEMOID ='' OR D.MEMO_ID =@CMEMOID )  
 AND AG.AGENCY_CODE=@CAGENCY_CODE          
 ORDER BY JOBS.JOB_NAME                            
 --                            
        
        
                         
GOTO LAST                            
LAST:                            
END
