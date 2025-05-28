CREATE PROCEDURE SPWOW_UPDATE_IMAGEINFO_XPERTREP
@cRepTempTable VARCHAR(500),
@cErrormsg VARCHAR(MAX) output
AS    
BEGIN    
    --DECLARE LOCAL VARIABLE    
    DECLARE @SECTION BIT,@SUB_SECTION BIT,@ARTICLE BIT,@PARA1 BIT    
    ,@PARA2 BIT,@PARA3 BIT,@PARA4 BIT,@PARA5 BIT,@PARA6 BIT    
    ,@PRODUCT BIT,@CSTR NVARCHAR(MAX),@DTJoin NVARCHAR(MAX)    
    ,@SECTION_CODE  VARCHAR(100),@cImgInfoTable VARCHAR(400),@cStep Varchar(5)
    ,@SUB_SECTION_CODE  VARCHAR(100),@cMstJoin VARCHAR(1000),@cJoinStr VARCHAR(300),@cJoinCol VARCHAR(100)
	,@cJoinImgCol VARCHAR(200),@cCmd NVARCHAR(MAX)

BEGIN TRY
    ---SET VALE INTO LOCAL VARIABLE    
	SET @cStep='10'
    SELECT @SECTION=SECTION,@SUB_SECTION=SUB_SECTION,@ARTICLE=ARTICLE    
    ,@PARA1=PARA1,@PARA2 = PARA2,@PARA3 = PARA3,@PARA4 = PARA4    
    ,@PARA5 = PARA5 , @PARA6 = PARA6, @PRODUCT = PRODUCT    
    FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)     
	
	SET @cStep='20'
    SET @cImgInfoTable=DB_NAME()+'_IMAGE..image_info '     
    SELECT @cMstJoin='', @DTJoin= ' JOIN '+@cImgInfoTable+' img (NOLOCK) ON '
	
	SET @cStep='25'
	IF ISNULL(@PRODUCT,0)=1 AND EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr LIKE '%product_code%' or col_expr like '%Item_Code%')
	BEGIN
	    SET @DTJoin = @DTJoin+' a.[Item Code]=img.product_Code'
	END
	ELSE
	BEGIN
		SET @cStep='30'
		SET @DTJoin=@DTJoin+'  1=1 '

		IF ISNULL(@ARTICLE,0) = 1     
		BEGIN    

		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.article_no')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.article_no'
			
               
		   SElect @cMstJoin=@cMstJoin+@cJoinStr+' JOIN article (nolock) on article.article_no='+@cJoinCol,
				   @DTJoin = @DTJoin+' AND article.article_code=img.article_code '
		END    

		SET @cStep='40'
		IF ISNULL(@Sub_SECTION,0) = 1     
		BEGIN    
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.sub_section_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.sub_Section_name'

		   SElect @cMstJoin=@cMstJoin+' JOIN sectiond (nolock) on sectiond.sub_section_name='+@cJoinCol,
				   @DTJoin = @DTJoin+' AND sectiond.sub_section_code=img.sub_section_code '
		END    

		SET @cStep='50'
		IF ISNULL(@SECTION,0) = 1     
		BEGIN    
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.section_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.section_name'

		   SElect @cMstJoin=@cMstJoin+' JOIN sectionm (nolock) on sectionm.section_name='+@cJoinCol,
				   @DTJoin = @DTJoin+' AND sectionm.section_code=img.section_code '
		END    
        
		SET @cStep='60'
		IF ISNULL(@PARA1,0) = 1    
		BEGIN    
		   SET @cJoinCol=NULL	
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.para1_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.para1_name'

			SElect @cMstJoin=@cMstJoin+' JOIN para1 (nolock) on para1.para1_name='+@cJoinCol,
		    @DTJoin = @DTJoin+' AND para1.para1_code=img.para1_code '
		END    
        
		SET @cStep='70'
		IF ISNULL(@PARA2,0) = 1    
		BEGIN    
		   SET @cJoinCol=NULL	
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.para2_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.para2_name'

			SElect @cMstJoin=@cMstJoin+' JOIN para2 (nolock) on para2.para2_name='+@cJoinCol,
		    @DTJoin = @DTJoin+' AND para2.para2_code=img.para2_code '

		END    
        SET @cStep='80'
		IF ISNULL(@PARA3,0) = 1    
		BEGIN    
		   SET @cJoinCol=NULL	
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.para3_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.para3_name'

			SElect @cMstJoin=@cMstJoin+' JOIN para3 (nolock) on para3.para3_name='+@cJoinCol,
		    @DTJoin = @DTJoin+' AND para3.para3_code=img.para3_code '
		END    
        
		SET @cStep='90'
		IF ISNULL(@PARA4,0) = 1    
		BEGIN    
		   SET @cJoinCol=NULL	
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.para4_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.para4_name'

   			SElect @cMstJoin=@cMstJoin+' JOIN para4 (nolock) on para4.para4_name='+@cJoinCol,
		    @DTJoin = @DTJoin+' AND para4.para4_code=img.para4_code '
		END    
        
		SET @cStep='100'
		IF ISNULL(@PARA5,0) = 1    
		BEGIN    
		   SET @cJoinCol=NULL	
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.para5_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.para5_name'

  			SElect @cMstJoin=@cMstJoin+' JOIN para5 (nolock) on para5.para5_name='+@cJoinCol,
		    @DTJoin = @DTJoin+' AND para5.para5_code=img.para5_code '

		END    
       
	   SET @cStep='105'
		IF ISNULL(@PARA6,0) = 1    
		BEGIN    
		   SET @cJoinCol=NULL	
		   IF EXISTS (SELECT TOP 1 col_expr FROM #wow_xpert_rep_det WHERE col_expr='sku_names.para6_name')
				SELECT @cJoinStr='',@cJoinCol='a.['+col_header+']' FROM  #wow_xpert_rep_det WHERE col_expr='sku_names.para6_name'


			SElect @cMstJoin=@cMstJoin+' JOIN para6 (nolock) on para6.para6_name='+@cJoinCol,
		    @DTJoin = @DTJoin+' AND para6.para6_code=img.para6_code '
		END    
    END
	
	SET @cStep='110'
	PRINT 'Update image id column for Report'
	SET @cCmd=N'UPDATE a SET img_id=img.img_id FROM '+@cRepTempTable+' a '+@cMstJoin+@DTJoin
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY


BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_UPDATE_IMAGEINFO_XPERTREP at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC 
END CATCH

END_PROC:
	
END