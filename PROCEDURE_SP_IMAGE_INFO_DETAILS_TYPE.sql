CREATE PROCEDURE DBO.SP_IMAGE_INFO_DETAILS_TYPE
(      
  @TYPE_VAL VARCHAR(MAX)
)      
AS      
 BEGIN      
    SET NOCOUNT ON
   --DECLARE LOCAL VARIABLE        
    DECLARE @SECTION BIT,@SUB_SECTION BIT,@ARTICLE BIT,@PARA1 BIT        
    ,@PARA2 BIT,@PARA3 BIT,@PARA4 BIT,@PARA5 BIT,@PARA6 BIT        
    ,@PRODUCT BIT,@CSTR NVARCHAR(MAX)       
    ,@SECTION_CODE  VARCHAR(100),@SUB_SECTION_CODE  VARCHAR(100),@ARTICLE_CODE  VARCHAR(100)        
    ,@PARA1_CODE  VARCHAR(100),@PARA2_CODE  VARCHAR(100),@PARA3_CODE  VARCHAR(100),@PARA4_CODE  VARCHAR(100)        
    ,@PARA5_CODE  VARCHAR(100),@PARA6_CODE  VARCHAR(100),@DTSQOLFROM NVARCHAR(MAX)       
    ,@DTSQLCOLUMN NVARCHAR(MAX),@DTSQLJOIN VARCHAR(MAX),@DTSQLJOININFO NVARCHAR(MAX)      
    ,@DTSQL NVARCHAR(MAX),@DTSQLWHERE NVARCHAR(MAX),@DTSQLFROM NVARCHAR(MAX),@DTSQLFILTER NVARCHAR(MAX)      
    ,@DTSQLINSERT NVARCHAR(MAX),@DTSQLALTERTABLE NVARCHAR(MAX),@DTSQLPRODUCTTABLE NVARCHAR(MAX)      
    ,@DTSQLALTERPID01106 NVARCHAR(MAX),@DTSQLSELECTPID01106 NVARCHAR(MAX),@DSQLWHERECONDITION NVARCHAR(MAX)      
    ,@DTSQLINSERTPID01106 NVARCHAR(MAX),@DTSQLINSERTPID01106_NEW NVARCHAR(MAX)      
    ,@DTSQLJOININFO_NEW NVARCHAR(MAX)      
          
    ---SET VALE INTO LOCAL VARIABLE        
    SELECT @SECTION=0 ,@SUB_SECTION=0 ,@ARTICLE=0 ,@PRODUCT=0 ,@PARA1=0 ,@PARA2=0 ,@PARA3=0 ,@PARA4=0 ,@PARA5=0 ,@PARA6=0
    
    SELECT @SECTION = SECTION
    ,@SUB_SECTION = SUB_SECTION
    ,@ARTICLE = ARTICLE        
    ,@PARA1 = PARA1
    ,@PARA2 = PARA2
    ,@PARA3 = PARA3
    ,@PARA4 = PARA4        
    ,@PARA5 = PARA5 
    ,@PARA6 = PARA6
    ,@PRODUCT = PRODUCT
    FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)      
    
    DECLARE @TYP_FIELD VARCHAR(100)
    IF OBJECT_ID('TEMPDB..#TYP','U') IS NOT NULL
       DROP TABLE #TYP
    CREATE TABLE #TYP (TYP VARCHAR(100))   
    SET @TYPE_VAL=REPLACE(REPLACE(REPLACE(@TYPE_VAL,'IN',''),'(',''),')','')
    SET @TYPE_VAL=LTRIM(RTRIM(@TYPE_VAL))
    --SELECT @SECTION SECTION ,@SUB_SECTION SUB_SECTION ,@ARTICLE ARTICLE ,@PRODUCT PRODUCT ,@PARA1 PARA1 ,@PARA2 PARA2 ,@PARA3 PARA3 ,@PARA4 PARA4 ,@PARA5 PARA5 ,@PARA6 PARA6,@TYPE_VAL TYPE_VAL
    
    IF RIGHT(@TYPE_VAL,1)!=','   
       SET @TYPE_VAL+=','
    WHILE LEN(@TYPE_VAL)>0
      BEGIN
         SET @TYP_FIELD=LEFT(@TYPE_VAL,CHARINDEX(',',@TYPE_VAL)-1)
         INSERT #TYP SELECT REPLACE(LTRIM(RTRIM(@TYP_FIELD)),'''','')
         SET @TYPE_VAL=SUBSTRING(@TYPE_VAL,CHARINDEX(',',@TYPE_VAL)+1,8000)
      END  
    --SELECT TYP FROM #TYP
    
    ---CREATE TABLE FOR INSERT DATA FROM IMAGE_INFO TABLE      
    IF OBJECT_ID('TEMPDB..#IMAGE_DETAIL') IS NOT NULL      
    DROP TABLE #IMAGE_DETAIL      
      
    CREATE TABLE #IMAGE_DETAIL      
    (      
     SRNO INT      
    ,IMAGE_NAME VARCHAR(200)      
    ,IMAGE_SUBFOLDER VARCHAR(200)      
    )      
          
    IF OBJECT_ID('TEMPDB..#TEMP_PID01106') IS NOT NULL      
    DROP TABLE #TEMP_PID01106      
    IF OBJECT_ID('TEMPDB..#TEMP_PID01106') IS NOT NULL      
    DROP TABLE #TEMP_PID01106      
    CREATE TABLE #TEMP_PID01106      
    (      
     SRNO INT      
    ,SECTION_CODE VARCHAR(200)      
    ,SECTION_NAME VARCHAR(200)      
    ,SUB_SECTION_CODE VARCHAR(200)      
    ,SUB_SECTION_NAME VARCHAR(200)      
    ,ARTICLE_CODE VARCHAR(200)      
    ,ARTICLE_NO VARCHAR(200)      
    ,PARA1_CODE VARCHAR(200)      
    ,PARA1_NAME VARCHAR(500)      
    ,PARA2_CODE VARCHAR(200)      
    ,PARA2_NAME VARCHAR(500)      
    ,PARA3_CODE VARCHAR(200)      
    ,PARA3_NAME VARCHAR(500)      
    ,PARA4_CODE VARCHAR(200)      
    ,PARA4_NAME VARCHAR(500)      
    ,PARA5_CODE VARCHAR(200)      
    ,PARA5_NAME VARCHAR(500)      
    ,PARA6_CODE VARCHAR(200)      
    ,PARA6_NAME VARCHAR(500)      
    ,PRODUCT_CODE VARCHAR(200)      
    )      
    DECLARE @SQLCMD VARCHAR(MAX)  
    SET @SQLCMD='
    INSERT INTO #TEMP_PID01106 (SRNO,PARA1_NAME,PARA1_CODE, PARA2_NAME,PARA2_CODE      
    , PARA3_NAME,PARA3_CODE, PARA4_NAME,PARA4_CODE, PARA5_NAME,PARA5_CODE      
    , PARA6_NAME,PARA6_CODE, PRODUCT_CODE, ARTICLE_NO,ARTICLE_CODE      
    , SUB_SECTION_NAME,SUB_SECTION_CODE, SECTION_NAME,SECTION_CODE )      
    SELECT DISTINCT  D.SRNO,P1.PARA1_NAME,P1.PARA1_CODE, P2.PARA2_NAME,P2.PARA2_CODE      
    , P3.PARA3_NAME,P3.PARA3_CODE, P4.PARA4_NAME,P4.PARA4_CODE, P5.PARA5_NAME,P5.PARA5_CODE      
    , P6.PARA6_NAME,P6.PARA6_CODE, D.PRODUCT_CODE, A.ARTICLE_NO,A.ARTICLE_CODE      
    , SU.SUB_SECTION_NAME,SU.SUB_SECTION_CODE, S.SECTION_NAME,S.SECTION_CODE       
    FROM DBO.PID01106 D WITH(NOLOCK)        
    JOIN DBO.PARA1 P1 WITH(NOLOCK) ON P1.PARA1_CODE = D.PARA1_CODE       
    JOIN DBO.PARA2 P2 WITH(NOLOCK) ON P2.PARA2_CODE = D.PARA2_CODE       
    JOIN DBO.PARA3 P3 WITH(NOLOCK) ON P3.PARA3_CODE = D.PARA3_CODE       
    JOIN DBO.PARA4 P4 WITH(NOLOCK) ON P4.PARA4_CODE = D.PARA4_CODE       
    JOIN DBO.PARA5 P5 WITH(NOLOCK) ON P5.PARA5_CODE = D.PARA5_CODE       
    JOIN DBO.PARA6 P6 WITH(NOLOCK) ON P6.PARA6_CODE = D.PARA6_CODE       
    JOIN DBO.ARTICLE A WITH(NOLOCK) ON A.ARTICLE_CODE = D.ARTICLE_CODE       
    JOIN DBO.SECTIOND SU WITH(NOLOCK) ON SU.SUB_SECTION_CODE = A.SUB_SECTION_CODE       
    JOIN DBO.SECTIONM S WITH(NOLOCK) ON SU.SECTION_CODE = S.SECTION_CODE       
    WHERE D.'+CASE WHEN @PRODUCT=1 THEN 'PRODUCT_CODE'
         WHEN @SECTION=1 THEN 'SECTION' 
         WHEN @SUB_SECTION=1 THEN 'SUB_SECTION'
         WHEN @ARTICLE=1 THEN 'ARTICLE'
         WHEN @PARA1=1 THEN 'PARA1'
         WHEN @PARA2=1 THEN 'PARA2'
         WHEN @PARA3=1 THEN 'PARA3'
         WHEN @PARA4=1 THEN 'PARA4'
         WHEN @PARA5=1 THEN 'PARA5'
         WHEN @PARA6=1 THEN 'PARA6'
    END+' IN (SELECT TYP FROM #TYP)'
    EXEC(@SQLCMD)
              
    --SET VALUE INTO DECLARE VARIABLE      
    SET @DTSQLINSERT   = N'INSERT INTO #IMAGE_DETAIL(IMAGE_NAME,IMAGE_SUBFOLDER,  '      
    SET @DTSQLFROM     = N' FROM DBO.PID01106 D WITH(NOLOCK) '      
    --SET @DTSQLCOLUMN   = N' SELECT DISTINCT IMAGE_NAME,IMAGE_SUBFOLDER, '        
    SET @DTSQLCOLUMN   = N''        
    SET @DTSQLJOININFO = N''      
    --SET @DTSQLWHERE    = N' WHERE D.MRR_ID = '''+@MRR_ID+''''      
    SET @DTSQLWHERE    = N' WHERE D.'+CASE	WHEN @PRODUCT=1 THEN 'PRODUCT_CODE'
											WHEN @SECTION=1 THEN 'SECTION' 
											WHEN @SUB_SECTION=1 THEN 'SUB_SECTION'
											WHEN @ARTICLE=1 THEN 'ARTICLE'
											WHEN @PARA1=1 THEN 'PARA1'
											WHEN @PARA2=1 THEN 'PARA2'
											WHEN @PARA3=1 THEN 'PARA3'
											WHEN @PARA4=1 THEN 'PARA4'
											WHEN @PARA5=1 THEN 'PARA5'
											WHEN @PARA6=1 THEN 'PARA6'
									  END+' IN (SELECT TYP FROM #TYP) '      
    SET @DTSQLJOIN     = N''      
    SET @DTSQLFILTER   = N''      
    SET @DTSQLALTERTABLE= N' '      
    SET @DTSQLALTERPID01106=N''      
    SET @DTSQLSELECTPID01106 =N''      
    SET @DSQLWHERECONDITION =N''      
    SET @DTSQLINSERTPID01106 =N''      
    SET @DTSQLINSERTPID01106_NEW =N''      
    SET @DTSQLJOININFO_NEW =N''      
          
     --IF PARA1_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PARA1 = 1      
    BEGIN      
     SET @DTSQLINSERT   = @DTSQLINSERT+'PARA1_NAME,PARA1_CODE,'      
     SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' P1.PARA1_NAME,P1.PARA1_CODE,'      
     SET @DTSQLJOIN     = @DTSQLJOIN+' JOIN DBO.PARA1 P1 WITH(NOLOCK) ON P1.PARA1_CODE = D.PARA1_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PARA1_CODE = I.PARA1_CODE'       
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PARA1_CODE = I.PARA1_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PARA1_CODE <> ''0000000'' '        
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'PARA1_NAME VARCHAR(500), PARA1_CODE VARCHAR(50),'      
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'PARA1_CODE VARCHAR(50),'             
    SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.PARA1_NAME,D.PARA1_CODE,'       
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +'PARA1_NAME,PARA1_CODE ,'      
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PARA1_CODE,'      
     SET @DSQLWHERECONDITION  = ' AND I.PARA1_CODE IS NULL'      
    END      
          
    --IF PARA2_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PARA2 = 1      
    BEGIN      
     SET @DTSQLINSERT   = @DTSQLINSERT+'PARA2_NAME,PARA2_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P2.PARA2_NAME,P2.PARA2_CODE,'      
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA2 P2 WITH(NOLOCK) ON P2.PARA2_CODE = D.PARA2_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PARA2_CODE = I.PARA2_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PARA2_CODE = I.PARA2_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PARA2_CODE <> ''0000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'PARA2_NAME VARCHAR(500), PARA2_CODE VARCHAR(50),'       
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'PARA2_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.PARA2_NAME,D.PARA2_CODE,'      
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' PARA2_NAME,PARA2_CODE ,'      
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PARA2_CODE,'      
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.PARA2_CODE IS NULL'                
    END      
    --IF PARA3_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PARA3 = 1      
    BEGIN      
     SET @DTSQLINSERT   = @DTSQLINSERT+'PARA3_NAME,PARA3_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P3.PARA3_NAME,P3.PARA3_CODE,'      
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA3 P3 WITH(NOLOCK) ON P3.PARA3_CODE = D.PARA3_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PARA3_CODE = I.PARA3_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PARA3_CODE = I.PARA3_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PARA3_CODE <> ''0000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'PARA3_NAME VARCHAR(500), PARA3_CODE VARCHAR(50),'        
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+' PARA3_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.PARA3_NAME,D.PARA3_CODE,'         
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' PARA3_NAME,PARA3_CODE ,'       
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.PARA3_CODE IS NULL'       
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PARA3_CODE,'                
    END      
    --IF PARA4_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PARA4 = 1      
    BEGIN      
     SET @DTSQLINSERT   = @DTSQLINSERT+'PARA4_NAME,PARA4_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P4.PARA4_NAME,P4.PARA4_CODE,'      
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA4 P4 WITH(NOLOCK) ON P4.PARA4_CODE = D.PARA4_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PARA4_CODE = I.PARA4_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PARA4_CODE = I.PARA4_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PARA4_CODE <> ''0000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'PARA4_NAME VARCHAR(500),PARA4_CODE VARCHAR(50),'         
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'PARA4_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.PARA4_NAME,D.PARA4_CODE,'       
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' PARA4_NAME,PARA4_CODE ,'       
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.PARA4_CODE IS NULL'         
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PARA4_CODE,'                           
    END      
          
    --IF PARA5_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PARA5 = 1      
    BEGIN      
     SET @DTSQLINSERT   = @DTSQLINSERT+'PARA5_NAME,PARA5_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P5.PARA5_NAME,P5.PARA5_CODE,'      
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA5 P5 WITH(NOLOCK) ON P5.PARA5_CODE = D.PARA5_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PARA5_CODE = I.PARA5_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PARA5_CODE = I.PARA5_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PARA5_CODE <> ''0000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'PARA5_NAME VARCHAR(500),PARA5_CODE VARCHAR(50),'        
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'PARA5_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.PARA5_NAME,D.PARA5_CODE,'      
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' PARA5_NAME,PARA5_CODE ,'       
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.PARA5_CODE IS NULL'         
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PARA5_CODE,'                                           
    END      
    --IF PARA6_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PARA6 = 1      
    BEGIN      
     SET @DTSQLINSERT   = @DTSQLINSERT+'PARA6_NAME,PARA6_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P6.PARA6_NAME,P6.PARA6_CODE,'      
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA6 P6 WITH(NOLOCK) ON P6.PARA6_CODE = D.PARA6_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PARA6_CODE = I.PARA6_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PARA6_CODE = I.PARA6_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PARA6_CODE <> ''0000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'PARA6_NAME VARCHAR(500), PARA6_CODE VARCHAR(50),'       
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'PARA6_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+'D.PARA6_NAME,D.PARA6_CODE,'        
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +'PARA6_NAME, PARA6_CODE ,'         
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.PARA6_CODE IS NULL'      
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PARA6_CODE,'       
    END      
    --IF PRODUCT_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
    IF @PRODUCT = 1      
    BEGIN      
    SET @DTSQLINSERT   = @DTSQLINSERT+'PRODUCT_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' D.PRODUCT_CODE,'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.PRODUCT_CODE = I.PRODUCT_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.PRODUCT_CODE = I.PRODUCT_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.PRODUCT_CODE <> ''0000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+' PRODUCT_CODE VARCHAR(100),'      
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'PRODUCT_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.PRODUCT_CODE,'        
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' PRODUCT_CODE ,'         
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.PRODUCT_CODE IS NULL'       
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.PRODUCT_CODE,'         
    END      
    --IF ARTICLE_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
   IF @ARTICLE = 1      
    BEGIN      
    SET @DTSQLINSERT   = @DTSQLINSERT+'ARTICLE_NO,ARTICLE_CODE,'      
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' A.ARTICLE_NO,A.ARTICLE_CODE,'      
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.ARTICLE A WITH(NOLOCK) ON A.ARTICLE_CODE = D.ARTICLE_CODE'      
     SET @DTSQLJOININFO = @DTSQLJOININFO +' AND D.ARTICLE_CODE = I.ARTICLE_CODE'      
     SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.ARTICLE_CODE = I.ARTICLE_CODE'       
     SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.ARTICLE_CODE <> ''00000000'' '      
     SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'ARTICLE_NO VARCHAR(100),ARTICLE_CODE VARCHAR(50),'      
     SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'ARTICLE_CODE VARCHAR(50),'             
     SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.ARTICLE_NO,D.ARTICLE_CODE,'        
     SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' ARTICLE_NO,ARTICLE_CODE ,'         
     SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.ARTICLE_CODE IS NULL'        
     SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'D.ARTICLE_CODE,'         
    END      
          
   --IF SUB_SECTION_CODE COLUMN IS TRUE IN IMAGE CONFIG TABLE      
   IF @SUB_SECTION = 1      
    BEGIN      
      IF @ARTICLE = 1 --IF ARTICLE CODE COLUMN IS TRUE THEN ALREADY JOIN WITH ARTICLE, SO WE ONLY JOIN SECTIOND TABLE      
      BEGIN      
         SET @DTSQLINSERT   = @DTSQLINSERT+'SUB_SECTION_NAME,SUB_SECTION_CODE,'      
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' SU.SUB_SECTION_NAME,SU.SUB_SECTION_CODE,'      
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.SECTIOND SU WITH(NOLOCK) ON SU.SUB_SECTION_CODE = A.SUB_SECTION_CODE'      
         SET @DTSQLJOININFO = @DTSQLJOININFO +' AND SU.SUB_SECTION_CODE = I.SUB_SECTION_CODE'      
         SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.SUB_SECTION_CODE = I.SUB_SECTION_CODE'       
         SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.SUB_SECTION_CODE <> ''0000000'' '      
         SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'SUB_SECTION_NAME VARCHAR(100), SUB_SECTION_CODE VARCHAR(50),'      
         SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'SUB_SECTION_CODE VARCHAR(50),'             
         SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.SUB_SECTION_NAME,D.SUB_SECTION_CODE,'      
         SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' SUB_SECTION_NAME,SUB_SECTION_CODE ,'         
         SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.SUB_SECTION_CODE IS NULL'      
         SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'SU.SUB_SECTION_CODE,'               
      END      
      ELSE      
      BEGIN --IF ARTICLE CODE IS NOT TRU IN IMAGE CONFIG TABLE THEN WE SET ALL JOIN FROM ARTICLE AND SECTION      
         SET @DTSQLINSERT   = @DTSQLINSERT+'SUB_SECTION_NAME,SUB_SECTION_CODE,'      
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' SU.SUB_SECTION_NAME,SU.SUB_SECTION_CODE,'      
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.ARTICLE A WITH(NOLOCK) ON A.ARTICLE_CODE = D.ARTICLE_CODE      
                             JOIN DBO.SECTIOND SU WITH(NOLOCK) ON SU.SUB_SECTION_CODE = A.SUB_SECTION_CODE'      
         SET @DTSQLJOININFO = @DTSQLJOININFO +' AND SU.SUB_SECTION_CODE = I.SUB_SECTION_CODE'      
         SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.SUB_SECTION_CODE = I.SUB_SECTION_CODE'       
         SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.SUB_SECTION_CODE <> ''0000000'' '      
         SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'SUB_SECTION_NAME VARCHAR(100), SUB_SECTION_CODE VARCHAR(50),'      
         SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'SUB_SECTION_CODE VARCHAR(50),'             
         SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+'D.SUB_SECTION_NAME,D.SUB_SECTION_CODE,'      
         SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' SUB_SECTION_NAME,SUB_SECTION_CODE ,'       
         SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.SUB_SECTION_CODE IS NULL'       
         SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'SU.SUB_SECTION_CODE,'                  
      END      
    END      
    --IF SECTION CODE IS TRUE INTO IMAGE CONFIG TABLE      
    IF @SECTION = 1      
    BEGIN      
      IF @SUB_SECTION = 1 --IF SUB SECTION CODE IS ALREADY TRUE THEN WE ONLY JOIN THROUGH SECTIONM      
      BEGIN      
         SET @DTSQLINSERT   = @DTSQLINSERT+'SECTION_NAME,SECTION_CODE,'      
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' S.SECTION_NAME,S.SECTION_CODE,'      
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.SECTIONM S WITH(NOLOCK) ON SU.SECTION_CODE = S.SECTION_CODE'      
         SET @DTSQLJOININFO = @DTSQLJOININFO +' AND S.SECTION_CODE = I.SECTION_CODE'      
         SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.SECTION_CODE = I.SECTION_CODE'       
         SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.SECTION_CODE <> ''0000000'' '      
         SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'SECTION_NAME VARCHAR(100),SECTION_CODE VARCHAR(50),'      
         SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'SECTION_CODE VARCHAR(50),'             
         SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+'D.SECTION_NAME,D.SECTION_CODE,'      
         SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' SECTION_NAME,SECTION_CODE ,'       
         SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.SECTION_CODE IS NULL'      
         SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'S.SECTION_CODE,'                   
      END      
      ELSE IF @ARTICLE = 1 --IF TRUE ARTICLE BUT NOT TRUE SUB SECTION CODE THEN WE NEED TO JOIN FIRST SECTIOND TEHN SECTIONM      
      BEGIN      
         SET @DTSQLINSERT   = @DTSQLINSERT+'SECTION_NAME,SECTION_CODE,'      
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' S.SECTION_NAME,S.SECTION_CODE,'      
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.SECTIOND SU WITH(NOLOCK) ON SU.SUB_SECTION_CODE = A.SUB_SECTION_CODE      
                             JOIN DBO.SECTIONM S WITH(NOLOCK) ON S.SECTION_CODE = SU.SECTION_CODE'      
         SET @DTSQLJOININFO = @DTSQLJOININFO +' AND S.SECTION_CODE = I.SECTION_CODE'      
         SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.SECTION_CODE = I.SECTION_CODE'       
         SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.SECTION_CODE <> ''0000000'' '      
         SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'SECTION_NAME VARCHAR(100),SECTION_CODE VARCHAR(50),'      
         SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'SECTION_CODE VARCHAR(50),'             
         SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+' D.SECTION_NAME,D.SECTION_CODE,'      
         SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' SECTION_NAME,SECTION_CODE ,'       
         SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.SECTION_CODE IS NULL'       
         SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'S.SECTION_CODE,'                      
      END      
      ELSE      
      BEGIN      
         SET @DTSQLINSERT   = @DTSQLINSERT+'SECTION_NAME,SECTION_CODE,'      
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' S.SECTION_NAME,S.SECTION_CODE,'      
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.ARTICLE A WITH(NOLOCK) ON A.ARTICLE_CODE = D.ARTICLE_CODE      
                             JOIN DBO.SECTIOND SU WITH(NOLOCK) ON SU.SUB_SECTION_CODE = A.SUB_SECTION_CODE      
                             JOIN DBO.SECTIONM S WITH(NOLOCK) ON S.SECTION_CODE = SU.SECTION_CODE'      
         SET @DTSQLJOININFO = @DTSQLJOININFO +' AND S.SECTION_CODE = I.SECTION_CODE'      
         SET @DTSQLJOININFO_NEW = @DTSQLJOININFO_NEW +' AND D.SECTION_CODE = I.SECTION_CODE'       
         SET @DTSQLFILTER   = @DTSQLFILTER + ' AND I.SECTION_CODE <> ''0000000'' '      
         SET @DTSQLALTERTABLE = @DTSQLALTERTABLE+'SECTION_NAME VARCHAR(100), SECTION_CODE VARCHAR(50),'      
         SET @DTSQLALTERPID01106=@DTSQLALTERPID01106+'SECTION_CODE VARCHAR(50),'             
         SET @DTSQLSELECTPID01106 = @DTSQLSELECTPID01106+'D.SECTION_NAME, D.SECTION_CODE,'      
         SET @DTSQLINSERTPID01106  = @DTSQLINSERTPID01106 +' SECTION_NAME,SECTION_CODE ,'       
         SET @DSQLWHERECONDITION  = @DSQLWHERECONDITION + ' AND I.SECTION_CODE IS NULL'       
         SET @DTSQLINSERTPID01106_NEW = @DTSQLINSERTPID01106_NEW+'S.SECTION_CODE,'         
      END      
    END      
          
    SET @DTSQLINSERT = SUBSTRING(@DTSQLINSERT,1,LEN(@DTSQLINSERT)-1)+' )';      
    SET @DTSQLCOLUMN=SUBSTRING(@DTSQLCOLUMN,1,LEN(@DTSQLCOLUMN)-1);      
    SET @DTSQLALTERPID01106=SUBSTRING(@DTSQLALTERPID01106,1,LEN(@DTSQLALTERPID01106)-1);      
    SET @DTSQLSELECTPID01106=SUBSTRING(@DTSQLSELECTPID01106,1,LEN(@DTSQLSELECTPID01106)-1);      
    SET @DTSQLALTERTABLE =SUBSTRING(@DTSQLALTERTABLE,1,LEN(@DTSQLALTERTABLE)-1)      
    SET @DTSQLINSERTPID01106 = SUBSTRING(@DTSQLINSERTPID01106,1,LEN(@DTSQLINSERTPID01106)-1);      
    SET @DTSQLINSERTPID01106_NEW =SUBSTRING(@DTSQLINSERTPID01106_NEW,1,LEN(@DTSQLINSERTPID01106_NEW)-1);      
          
   -- SET @DTSQLPRODUCTTABLE= 'ALTER TABLE #TEMP_PID01106 ADD '+@DTSQLALTERPID01106      
    SET @DTSQLALTERTABLE = 'ALTER TABLE #IMAGE_DETAIL ADD '+@DTSQLALTERTABLE      
        
      
    --EXEC SP_EXECUTESQL @DTSQLPRODUCTTABLE      
    EXEC SP_EXECUTESQL @DTSQLALTERTABLE      
        PRINT @DTSQLALTERTABLE
         
    SET @DTSQL = @DTSQLINSERT+'SELECT DISTINCT IMAGE_NAME,IMAGE_SUBFOLDER,'+@DTSQLCOLUMN +@DTSQLFROM+ @DTSQLJOIN+' LEFT JOIN DBO.IMAGE_INFO I WITH(NOLOCK) ON 1=1'+@DTSQLJOININFO + @DTSQLWHERE +@DTSQLFILTER      
    PRINT @DTSQL      
    EXEC SP_EXECUTESQL @DTSQL      
          
    --SET @DTSQL ='INSERT INTO #TEMP_PID01106(SRNO,'+@DTSQLINSERTPID01106+')       
    --SELECT D.SRNO,'+@DTSQLINSERTPID01106_NEW+' FROM DBO.PID01106 D      
    --JOIN DBO.ARTICLE A WITH(NOLOCK) ON D.ARTICLE_CODE = A.ARTICLE_CODE      
    --JOIN DBO.SECTIOND SU WITH(NOLOCK) ON A.SUB_SECTION_CODE=SU.SUB_SECTION_CODE      
    --JOIN DBO.SECTIONM S WITH(NOLOCK)  ON SU.SECTION_CODE = S.SECTION_CODE      
    --WHERE MRR_ID='''+@MRR_ID+''''      
    -- PRINT 'A'      
    ----SET @DTSQL ='INSERT INTO #TEMP_PID01106('+@DTSQLINSERTPID01106+') SELECT '+@DTSQLINSERTPID01106_NEW+' FROM DBO.PID01106 WHERE MRR_ID='''+@MRR_ID+''''      
    --EXEC SP_EXECUTESQL @DTSQL      
          
    SET @DTSQL='INSERT INTO #IMAGE_DETAIL(SRNO,'+@DTSQLINSERTPID01106+')      
                SELECT D.SRNO,'+@DTSQLSELECTPID01106+' FROM #TEMP_PID01106 D      
                LEFT JOIN #IMAGE_DETAIL I ON 1=1 '+@DTSQLJOININFO_NEW+' WHERE 1=1 '+@DSQLWHERECONDITION+''      
    PRINT @DTSQL      
    EXEC SP_EXECUTESQL @DTSQL      
          
     SET @DTSQL =N'UPDATE I SET I.SRNO = D.SRNO      
                  FROM #IMAGE_DETAIL I      
                  JOIN #TEMP_PID01106 D ON 1=1 '+@DTSQLJOININFO_NEW+'      
                  WHERE I.SRNO IS NULL'      
    PRINT @DTSQL      
    EXEC SP_EXECUTESQL @DTSQL      
          
    DECLARE @COLUMNLIST NVARCHAR(MAX)      
    SET @COLUMNLIST = (SELECT      
                      STUFF((SELECT ','+NAME FROM TEMPDB.SYS.COLUMNS       
    WHERE OBJECT_ID = OBJECT_ID('TEMPDB..#IMAGE_DETAIL')  AND NAME <> 'SRNO'      
                      FOR XML PATH('')),1,1,'') )      
    PRINT  @COLUMNLIST                         
    --SET @DTSQL =N'SELECT '+@COLUMNLIST+' FROM #IMAGE_DETAIL ORDER BY SRNO'      
    SET @DTSQL =N'SELECT '+@COLUMNLIST+',MIN(SRNO) AS [SRNO] FROM #IMAGE_DETAIL  GROUP BY '+@COLUMNLIST+' ORDER BY [SRNO]'      
    PRINT @DTSQL    
    EXEC SP_EXECUTESQL @DTSQL      
          
    --SELECT * FROM #IMAGE_DETAIL      
    SET NOCOUNT OFF
  END
