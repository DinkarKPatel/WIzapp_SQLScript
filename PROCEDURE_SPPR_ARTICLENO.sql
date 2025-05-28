CREATE PROCEDURE [DBO].[SPPR_ARTICLENO]             
(            
 @NMODE     INT, --(0)-FILL DROPDOWN 'ARTILCE_NO, SECTION' (1) - VIEW FILTER DATA (2) - VIEW ARTILCE_NO WISE            
 @ARTILCE_NO  VARCHAR(100)='',            
 @INACTIVE    VARCHAR(50)='',            
 @ERRMSG_OUT    VARCHAR(MAX)='' OUT ,
 @CSECTION_CODE VARCHAR(10)='',
 @CSUB_SECTION_CODE VARCHAR(10)='',
 @NARTICLE_TYPE INT=0,
 @NSUB_ARTICLE_TYPE INT=0
)            
AS            
BEGIN            
 DECLARE @CSTEP INT, @CCMD NVARCHAR(MAX)  ,@CFILTER VARCHAR(MAX)          
             
 BEGIN TRY            
  SET @ERRMSG_OUT = ''     
  SET @CFILTER=''
  IF @NARTICLE_TYPE=1
  SET @CFILTER=' AND A.ARTICLE_TYPE =  ''1'''
  ELSE IF @NARTICLE_TYPE=2
  SET @CFILTER=' AND A.ARTICLE_TYPE <>  ''1'''      
              
  SET @CSTEP = 5            
  IF (@NMODE=0)            
  BEGIN            
   SET @CCMD=N'SELECT ARTICLE_NO,ARTICLE_CODE,SECTION_NAME,SUB_SECTION_NAME,A.INACTIVE  
              FROM ARTICLE AS A          
              JOIN SECTIOND AS SD ON A.SUB_SECTION_CODE=SD.SUB_SECTION_CODE          
              JOIN SECTIONM AS SM ON SD.SECTION_CODE=SM.SECTION_CODE             
              WHERE ISNULL(A.INACTIVE, 0) = 0            
              ORDER BY ARTICLE_NO '            
   PRINT @CCMD            
   EXEC SP_EXECUTESQL @CCMD            
  END            
              
  SET @CSTEP = 10            
  IF (@NMODE=1)            
  BEGIN            
   SET @CCMD=N'SELECT A.ARTICLE_NO,A.ARTICLE_CODE,SECTION_NAME,SUB_SECTION_NAME,CASE WHEN A.ARTICLE_TYPE=1 THEN ''FINISH GOOD''  
       WHEN A.ARTICLE_TYPE=2 THEN ''RAW MATERIAL''  
       WHEN A.ARTICLE_TYPE=3 THEN ''FABRIC''  
       WHEN A.ARTICLE_TYPE=4 THEN ''TRIM'' ELSE ''PACKING'' END AS ARTICLE_TYPE,         
              CASE WHEN ISNULL(A.INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END INACTIVE   ,
              ISNULL(BOM,0) AS BOM,
              ISNULL(JOBS,0) AS JOBS,
              ISNULL(BOM.COMPLETED,0) AS COMPLETED
              FROM [ARTICLE]  AS A            
              JOIN SECTIOND AS SD ON A.SUB_SECTION_CODE=SD.SUB_SECTION_CODE          
              JOIN SECTIONM AS SM ON SD.SECTION_CODE=SM.SECTION_CODE    
              LEFT OUTER JOIN
              (
               SELECT ARTICLE_CODE,COUNT(*) AS BOM ,ISNULL(COMPLETED,0) AS COMPLETED
			   FROM PPC_ART_BOM
			   GROUP BY ARTICLE_CODE,ISNULL(COMPLETED,0)
              ) BOM ON BOM.ARTICLE_CODE=A.ARTICLE_CODE  
               LEFT OUTER JOIN
              (
               SELECT ARTICLE_CODE,COUNT(*) AS JOBS 
			    FROM ART_JOBS
			   GROUP BY ARTICLE_CODE
              ) JOBS ON JOBS.ARTICLE_CODE=A.ARTICLE_CODE       
              WHERE (''' + @ARTILCE_NO + '''=''''OR ARTICLE_NO =  ''' + @ARTILCE_NO + ''')   
              AND  (''' + @CSECTION_CODE + '''=''''OR SM.SECTION_CODE =  ''' + @CSECTION_CODE + ''') 
              AND  (''' + @CSUB_SECTION_CODE + '''=''''OR SD.SUB_SECTION_CODE =  ''' + @CSUB_SECTION_CODE + ''')  
              AND ('''+RTRIM(LTRIM(STR(@NSUB_ARTICLE_TYPE)))+'''=''0'' OR A.ARTICLE_TYPE='''+RTRIM(LTRIM(STR(@NSUB_ARTICLE_TYPE)))+''')
              '+@CFILTER +'
              AND A.INACTIVE LIKE ''%' + @INACTIVE + '%''          
                        
              ORDER BY ARTICLE_CODE DESC'            
              
   PRINT @CCMD            
   EXEC SP_EXECUTESQL @CCMD            
  END            
              
  SET @CSTEP = 20            
  IF (@NMODE=2)            
  BEGIN            
   SET @CCMD=N'SELECT ARTICLE_NO,SECTION_NAME,SUB_SECTION_NAME,CASE WHEN A.ARTICLE_TYPE=1 THEN ''FINISH GOOD''  
       WHEN A.ARTICLE_TYPE=2 THEN ''RAW MATERIAL''  
       WHEN A.ARTICLE_TYPE=3 THEN ''FABRIC''  
       WHEN A.ARTICLE_TYPE=4 THEN ''TRIM'' ELSE ''PACKING'' END AS ARTICLE_TYPE,           
              CASE WHEN ISNULL(A.INACTIVE, 0) = 0 THEN ''NO'' ELSE ''YES'' END INACTIVE   
              FROM [ARTICLE]  AS A            
              JOIN SECTIOND AS SD ON A.SUB_SECTION_CODE=SD.SUB_SECTION_CODE          
              JOIN SECTIONM AS SM ON SD.SECTION_CODE=SM.SECTION_CODE             
              WHERE ARTICLE_NO = ''' + @ARTILCE_NO + ''' '            
              
   PRINT @CCMD            
   EXEC SP_EXECUTESQL @CCMD            
  END            
              
 END TRY              
 BEGIN CATCH              
  SET @ERRMSG_OUT='ERROR: [P]: SPPR_SECTIONM, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()            
  PRINT @ERRMSG_OUT            
              
  GOTO END_PROC              
 END CATCH               
            
END_PROC:              
 IF  ISNULL(@ERRMSG_OUT,'')=''             
  SET @ERRMSG_OUT = ''            
END
