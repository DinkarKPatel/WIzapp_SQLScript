CREATE PROCEDURE SP_INSERT_IMAGE_INFO
(
@CMASTERTABLE VARCHAR(30)
) 
AS
BEGIN
   
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
    ,@DTSQLINSERTPID01106 NVARCHAR(MAX),@CIMAGECONFIG BIT
    
    
      SET @DTSQL=N'IF EXISTS(SELECT * FROM '+@CMASTERTABLE +' WHERE ISNULL(IMAGE_NAME,'''')<>'''')
                    BEGIN
					   SET @CIMAGECONFIG=1
					END
					ELSE
					 BEGIN
					   SET @CIMAGECONFIG=0
					END'
		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL, N'@CIMAGECONFIG BIT OUTPUT',@CIMAGECONFIG OUTPUT
		
		IF  @CIMAGECONFIG=0 
		RETURN
       				

    
    SELECT @SECTION=SECTION,@SUB_SECTION=SUB_SECTION,@ARTICLE=ARTICLE  
    ,@PARA1=PARA1,@PARA2 = PARA2,@PARA3 = PARA3,@PARA4 = PARA4  
    ,@PARA5 = PARA5 , @PARA6 = PARA6, @PRODUCT = PRODUCT  
    FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)
    
    IF ( @SECTION=0 AND @SUB_SECTION=0 AND  @ARTICLE=0 AND  @PARA1=0 AND @PARA2 =0 AND @PARA3 = 0 AND @PARA4 = 0 AND  @PARA5 = 0 AND  @PARA6 = 0 AND @PRODUCT = 0 )
    RETURN
    
    SET @DTSQLCOLUMN   = N''  
    SET @DTSQLJOININFO = N''
    SET @DTSQLJOIN     = N''
     
    IF @PARA1 = 1
    BEGIN
     SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' P1.PARA1_CODE,'
     SET @DTSQLJOIN     = @DTSQLJOIN+' JOIN DBO.PARA1 P1 WITH(NOLOCK) ON P1.PARA1_NAME = D.PARA1_NAME'
    END
     ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END
     IF @PARA2 = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P2.PARA2_CODE,'
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA2 P2 WITH(NOLOCK) ON P2.PARA2_NAME = D.PARA2_NAME'
    END
    ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END
    IF @PARA3 = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P3.PARA3_CODE,'
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA3 P3 WITH(NOLOCK) ON P3.PARA3_NAME = D.PARA3_NAME'
    END
    ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END
    IF @PARA4 = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P4.PARA4_CODE,'
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA4 P4 WITH(NOLOCK) ON P4.PARA4_NAME = D.PARA4_NAME'
    END
    ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END
    IF @PARA5 = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P5.PARA5_CODE,'
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA5 P5 WITH(NOLOCK) ON P5.PARA5_NAME = D.PARA5_NAME'
    END
    ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END
    IF @PARA6 = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' P6.PARA6_CODE,'
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.PARA6 P6 WITH(NOLOCK) ON P6.PARA6_NAME = D.PARA6_NAME'
    END
    ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END
    IF @PRODUCT = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' D.PRODUCT_CODE,'
    END
    ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' '''','
       END  
    
    IF @ARTICLE = 1
    BEGIN
     SET @DTSQLCOLUMN=@DTSQLCOLUMN+' A.ARTICLE_CODE,'
     SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.ARTICLE A WITH(NOLOCK) ON A.ARTICLE_NO = D.ARTICLE_NO'
    END
    ELSE
     BEGIN
          SET @DTSQLCOLUMN=@DTSQLCOLUMN+' ''00000000'','
     END
     
     IF @SUB_SECTION = 1
    BEGIN
      
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' SU.SUB_SECTION_CODE,'
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.SECTIOND SU WITH(NOLOCK) ON SU.SUB_SECTION_NAME = D.SUB_SECTION_NAME'
      END
       ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END  
    
      
      IF @SECTION = 1
      BEGIN
         SET @DTSQLCOLUMN=@DTSQLCOLUMN+' S.SECTION_CODE,'
         SET @DTSQLJOIN = @DTSQLJOIN+' JOIN DBO.SECTIONM S WITH(NOLOCK) ON S.SECTION_NAME = D.SECTION_NAME'
      END
       ELSE
       BEGIN
        SET @DTSQLCOLUMN   = @DTSQLCOLUMN+' ''0000000'','
       END  

      SET @DTSQLCOLUMN=SUBSTRING(@DTSQLCOLUMN,1,LEN(@DTSQLCOLUMN)-1);

    SET @DTSQL=N'INSERT IMAGE_INFO(PARA1_CODE,PARA2_CODE, PARA3_CODE, 
						 PARA4_CODE, PARA5_CODE, PARA6_CODE,PRODUCT_CODE,ARTICLE_CODE,
						 SUB_SECTION_CODE,SECTION_CODE, IMAGE_NAME, IMAGE_SUBFOLDER )  
					      
                SELECT DISTINCT '+@DTSQLCOLUMN+',IMAGE_NAME,'''' AS IMAGE_SUBFOLDER  FROM  '+@CMASTERTABLE +' D(NOLOCK) 
                '+@DTSQLJOIN+''
                
    PRINT @DTSQL
    EXEC SP_EXECUTESQL @DTSQL
END
