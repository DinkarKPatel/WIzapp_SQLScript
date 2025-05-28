CREATE PROCEDURE SP3S_QC            
(            
  @CQUERYID   NUMERIC(2),              
  @CWHERE   VARCHAR(MAX)='',              
  @CFINYEAR   VARCHAR(5)='',              
  @CDEPTID   VARCHAR(5)='',              
  @NNAVMODE   NUMERIC(2)=1,              
  @CWIZAPPUSERCODE VARCHAR(10)='',              
  @CREFMEMOID  VARCHAR(40)='',              
  @CREFMEMODT  DATETIME='',              
  @BINCLUDEESTIMATE BIT=1,              
  @CFROMDT   DATETIME='',              
  @CTODT    DATETIME='',            
  @BCARDDISCOUNT  BIT=0,            
  @CCUSTCODE   VARCHAR(15)='',            
  @AC_CODE           CHAR(15)='',             
  @MODE              INT =0,            
  @PRODUCT_CODE  VARCHAR(50)='' ,            
  @PO_ID    VARCHAR(22)='',            
  @ASN_ID            VARCHAR(22)=''            
)            
AS            
BEGIN            
                       
        IF @CQUERYID=1 --PEDING PO ID AND NO             
        GOTO LBL1             
        IF @CQUERYID=2   --- MASTER            
        GOTO LBL2            
        IF @CQUERYID=3   ---- DETAIL            
        GOTO LBL3            
        IF @CQUERYID=4            
        GOTO LBL4            
        IF @CQUERYID=5            
        GOTO LBL5            
        IF @CQUERYID=6            
        GOTO LBL6            
        IF @CQUERYID=7            
        GOTO LBL7     
  ELSE    
        IF @CQUERYID=8 --PEDING PO ID AND NO             
        GOTO LBLSUPPLOV             
              
        ELSE            
        GOTO LAST              
              
                     
      LBL1:  
      
      DECLARE @IMAXLEVEL INT,@cHEAD_CODE VARCHAR(MAX) 
      
      SELECT @IMAXLEVEL=MAX(LEVEL_NO) 
			FROM XN_APPROVAL_CHECKLIST_LEVELS 
			WHERE XN_TYPE='PO' AND INACTIVE=0 
		SET @IMAXLEVEL=ISNULL(@IMAXLEVEL,0)	          
    
            SELECT  AC_NAME,F.PO_ID,F.PO_NO,ARTICLE_NO,F.ARTICLE_CODE,F.PARA1_CODE,PARA1_NAME,POD_QUANTITY AS PO_QUANTITY            
          ,ISNULL(Z.QC_QUANTITY,0) AS QC_QUANTITY,            
          ( F.POD_QUANTITY-ISNULL(Z.QC_QUANTITY,0)) PENDING_QUANTITY FROM            
              (                
     SELECT  AC_NAME,POD01106.PO_ID,POD01106.ARTICLE_CODE,POD01106.PARA1_CODE,PO_NO,            
     SUM(QUANTITY) AS POD_QUANTITY             
     FROM POD01106 (NOLOCK)            
     JOIN POM01106(NOLOCK) ON POM01106.PO_ID=POD01106.PO_ID     
     JOIN LM01106 (NOLOCK) ON LM01106.AC_CODE=POM01106.AC_CODE           
     WHERE POM01106.AC_CODE=@AC_CODE  AND CANCELLED=0           
     AND PO_RECEIVING_MODE=2
     AND (@IMAXLEVEL=0 OR POM01106.APPROVEDLEVELNO=99)             
     GROUP BY POD01106.PO_ID,POD01106.ARTICLE_CODE,POD01106.PARA1_CODE,PO_NO ,AC_NAME           
                  
     )F            
     LEFT JOIN            
     (            
     SELECT PO_ID,ARTICLE_CODE,PARA1_CODE,ISNULL(SUM(QC_QUANTITY),0) QC_QUANTITY             
     FROM QC_XN_MST A(NOLOCK) JOIN  QC_XN_DET_1 B(NOLOCK) ON A.MEMO_ID=B.MEMO_ID            
     WHERE AC_CODE=@AC_CODE AND CANCELLED=0           
     GROUP BY PO_ID,ARTICLE_CODE,PARA1_CODE          
     )Z ON Z.PO_ID=F.PO_ID AND Z.ARTICLE_CODE=F.ARTICLE_CODE AND Z.PARA1_CODE=F.PARA1_CODE             
     JOIN ARTICLE(NOLOCK) ON F.ARTICLE_CODE=ARTICLE.ARTICLE_CODE            
     JOIN PARA1(NOLOCK) ON F.PARA1_CODE=PARA1.PARA1_CODE            
     WHERE ( F.POD_QUANTITY-ISNULL(Z.QC_QUANTITY,0)) > 0             
                 
                      
         GOTO LAST                 
             
        SET @cHEAD_CODE = DBO.FN_ACT_TRAVTREE('0000000021') ----ADD VARIABLE BY GAURI ON 17/4/2019
                    
       LBL2:            
       ;WITH CTE AS             
       (SELECT Q.MEMO_ID,P.PO_NO,R1=ROW_NUMBER()OVER(PARTITION BY Q.MEMO_ID ORDER BY P.PO_NO) FROM QC_XN_DET_1 Q(NOLOCK) JOIN POM01106 P (NOLOCK) ON P.PO_ID=Q.PO_ID)
       
       SELECT A.MEMO_ID
       ,MEMO_NO
       ,CONVERT(VARCHAR,MEMO_DT,105) AS MEMO_DT
       ,AC_NAME
       ,SUPPLIER_LOCATION
       ,INSPECTED_BY
       ,USERNAME
       ,A.LAST_UPDATE
       ,A.FIN_YEAR
       ,(CASE WHEN A.CANCELLED=0 THEN 'UNCANCELLED' ELSE 'CANCELLED' END) AS  CANCELLED            
       ,CTE.PO_NO
       FROM QC_XN_MST A (NOLOCK)             
       JOIN LM01106 B (NOLOCK) ON  A.AC_CODE=B.AC_CODE            
       JOIN USERS C(NOLOCK) ON C.USER_CODE=A.USER_CODE            
       JOIN CTE ON CTE.MEMO_ID=A.MEMO_ID AND CTE.R1=1
       --WHERE (A.AC_CODE=@AC_CODE)           
                     
                     
                     
       GOTO LAST             
                   
          
       LBL3:            
                      
                     
         SELECT MEMO_ID,ARTICLE_NO,PARA1_NAME,PO_ID,PENDING_PO_QUANTITY,QC_QUANTITY,            
          QC_RESULT,ROW_ID,NO_OF_CARTONS             
           FROM QC_XN_DET_1 A(NOLOCK)            
           JOIN ARTICLE B(NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE            
           JOIN PARA1 C(NOLOCK) ON C.PARA1_CODE=A.PARA1_CODE            
           WHERE MEMO_ID=@CWHERE            
                      
     
       GOTO LAST             
                   
        LBL4:            
                      
                     
         EXECUTE SP_NAVIGATE 'QC_XN_MST',@NNAVMODE,@CREFMEMOID,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID',@CWHERE,@BINCLUDEESTIMATE              
            
                      
                      
       GOTO LAST             
                   
                
       LBL5:            
                   
       SELECT * FROM QC_ATTRM            
                   
       GOTO LAST            
                   
       LBL6:            
                   
       SELECT A.QC_ATTRIBUTES_CODE,QC_ATTRIBUTES_NAME,QC_KEY_CODE,QC_KEY_NAME FROM QC_ATTR_KEY A JOIN QC_ATTRM B           
       ON A.QC_ATTRIBUTES_CODE=B.QC_ATTRIBUTES_CODE            
        
                
      GOTO LAST          
                
      LBL7:     
          
      SELECT LM.AC_CODE,AC_NAME,(CASE WHEN A.CANCELLED=1 THEN 'CANCELLED' ELSE 'UNCANCELLED' END) AS CANCELLED,A.INSPECTED_BY,    
      A.MEMO_NO,A.MEMO_DT,A.SUPPLIER_LOCATION,USERNAME,MEMO_PREFIX    
      FROM QC_XN_MST A(NOLOCK)    
      JOIN LM01106 LM(NOLOCK) ON LM.AC_CODE=A.AC_CODE    
      JOIN USERS(NOLOCK) ON USERS.USER_CODE=A.USER_CODE    
       WHERE A.MEMO_ID=@CWHERE     
          
          
          
      SELECT ARTICLE_NO,B.NO_OF_CARTONS,PARA1_NAME,B.PENDING_PO_QUANTITY,B.PO_ID,B.QC_QUANTITY,B.QC_RESULT,PO_NO    
      FROM QC_XN_DET_1 B(NOLOCK)     
      JOIN ARTICLE AR(NOLOCK) ON AR.ARTICLE_CODE=B.ARTICLE_CODE    
      JOIN PARA1(NOLOCK) ON PARA1.PARA1_CODE=B.PARA1_CODE    
      JOIN POM01106(NOLOCK) ON POM01106.PO_ID=B.PO_ID    
      WHERE MEMO_ID=@CWHERE     
          
         
          
      SELECT QC_KEY_NAME,QC_ATTRIBUTES_NAME FROM QC_XN_DET_2 A    
      JOIN QC_ATTR_KEY B(NOLOCK) ON A.QC_KEY_CODE=B.QC_KEY_CODE    
      JOIN QC_ATTRM C(NOLOCK) ON C.QC_ATTRIBUTES_CODE=B.QC_ATTRIBUTES_CODE    
      WHERE MEMO_ID=@CWHERE AND ISNULL(QC_ATTRIBUTES_NAME,'')<>''    
          
      GOTO LAST    
    
LBLSUPPLOV:    
       
        
   SELECT AC_CODE,AC_NAME FROM LM01106     
   WHERE  CHARINDEX(HEAD_CODE ,@cHEAD_CODE)>0    ----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019
   AND  INACTIVE=0
LAST:              
END
