create PROCEDURE SP3S_UPDATE_IMGINFO_BARCODES
@bCalledforBulkUpdate BIT=0,
@bCalledFromImageInfoTrigger BIT=0
AS
BEGIN

	DECLARE @bSKU BIT,@bARTICLE BIT,@bPARA1 BIT,@bPARA2 BIT,@bPARA3 BIT,@bPARA4 BIT,@bPARA5 BIT,@bPARA6 BIT
	DECLARE @cExpr NVARCHAR(MAX),@cIMGID NVARCHAR(100),@ccmd nVARCHAR(MAX),@cDBNAME NVARCHAR(100),
	        @cExprName nvarchar(max),@cJoinName nvarchar(max)

	SET @cDBNAME=DB_NAME()
	--SELECT @cDBNAME 
	SET @cExpr=''
	set @cExprName=''

	SELECT @bSKU =PRODUCT,@bARTICLE =ARTICLE,@bPARA1 =para1,@bPARA2 =para2,@bPARA3 =para3,@bPARA4 =para4,@bPARA5 =para5,@bPARA6 =para6
	FROM IMAGE_INFO_CONFIG

	IF @bSku=1 AND @bCalledforBulkUpdate=0 AND @bCalledFromImageInfoTrigger=0
		RETURN
	
	
    IF EXISTS (SELECT TOP 1 * from config (NOLOCK) where config_option='build_bulk_skunames_imageinfo_2' AND value='1')
		and @bCalledforBulkUpdate=1
		RETURN


	SET @cExpr=' 1=1 '
	set @cExprName='  1=1'

	IF ISNULL(@bSKU,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND  LEFT(SKU.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',SKU.PRODUCT_CODE)-1,-1),LEN(SKU.PRODUCT_CODE )))  =IMG.product_code'
	END

	IF ISNULL(@bARTICLE,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.ARTICLE_CODE =IMG.ARTICLE_CODE'
		SELECT @cExprName =ISNULL(@cExprName,'')+ ' AND sn.ARTICLE_NO =Article.ARTICLE_NO'
	END
	IF ISNULL(@bPARA1,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.PARA1_CODE  =IMG.PARA1_CODE'
		SELECT @cExprName=ISNULL(@cExprName,'')+ ' AND sn.PARA1_NAME =para1.PARA1_NAME'
	END
	IF ISNULL(@bPARA2,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.PARA2_CODE =IMG.PARA2_CODE'
		SELECT @cExprName=ISNULL(@cExprName,'')+ ' AND sn.PARA2_NAME =para2.PARA2_NAME'
	END
	IF ISNULL(@bPARA3,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.PARA3_CODE  =IMG.PARA3_CODE'
		SELECT @cExprName=ISNULL(@cExprName,'')+ ' AND sn.PARA3_NAME =para3.PARA3_NAME'
	END
	IF ISNULL(@bPARA4,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.PARA4_CODE = IMG.PARA4_CODE'
		SELECT @cExprName=ISNULL(@cExprName,'')+ ' AND sn.PARA4_NAME =para4.PARA4_NAME'
	END
	IF ISNULL(@bPARA5,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.PARA5_CODE  =IMG.PARA5_CODE'
		SELECT @cExprName=ISNULL(@cExprName,'')+ ' AND sn.PARA5_NAME =para5.PARA5_NAME'
	END
	IF ISNULL(@bPARA6,0)=1
	BEGIN
		SELECT @cExpr=ISNULL(@cExpr,'')+ ' AND SKU.PARA6_CODE =IMG.PARA6_CODE'
		SELECT @cExprName=ISNULL(@cExprName,'')+ ' AND sn.PARA6_NAME =para6.PARA6_NAME'
	END
	
	IF @bCalledFromImageInfoTrigger=1
	begin
		SET @cCMD=N' UPDATE SN SET barcode_img_id=img.img_id FROM SKU_NAMES sn  WITH (ROWLOCK) 
					 JOIN sku (NOLOCK) ON sku.product_code=sn.product_code 
				     JOIN '+@cDBNAME+'_image.dbo.image_info img on '+@cExpr+
					 ' JOIN #tmpExistingSkuImg b ON b.img_id=img.img_id 
					   where isnull(sn.barcode_img_id,'''')<>img.img_id '
		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD
		--change for mbkb when code is different and name is same image will auto assign
		if isnull(@bSKU,0)<>1
		begin
		
		SET @CCMD=N' UPDATE SN SET BARCODE_IMG_ID=IMG.IMG_ID FROM '+@CDBNAME+'_IMAGE.DBO.IMAGE_INFO IMG '+
		           CASE WHEN @BARTICLE=1 THEN ' JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=IMG.ARTICLE_CODE ' ELSE '' END+
		           CASE WHEN @BPARA1 =1 THEN ' JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE=IMG.PARA1_CODE ' ELSE '' END+
		           CASE WHEN @BPARA2 =1 THEN ' JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE=IMG.PARA2_CODE ' ELSE '' END+
		           CASE WHEN @BPARA3 =1 THEN ' JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE=IMG.PARA3_CODE ' ELSE '' END+
		           CASE WHEN @BPARA4 =1 THEN ' JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE=IMG.PARA4_CODE ' ELSE '' END+
		           CASE WHEN @BPARA5 =1 THEN ' JOIN PARA5 (NOLOCK) ON PARA5.PARA5_CODE=IMG.PARA5_CODE ' ELSE '' END+
		           CASE WHEN @BPARA6 =1 THEN ' JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE=IMG.PARA6_CODE ' ELSE '' END+
		           ' JOIN #tmpExistingSkuImg b ON b.img_id=img.img_id 
		             JOIN SKU_NAMES sn (NOLOCK) ON '+@cExprName +'  WHERE ISNULL(SN.BARCODE_IMG_ID,'''')='''' '
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	   
	   end
		
	end
	ELSE
	IF @bCalledforBulkUpdate=0
	begin
		SET @cCMD=N' UPDATE Sku SET img_id=img.img_id FROM #tmpNewSkuImg sku JOIN '+@cDBNAME+'_image.dbo.image_info img on '+@cExpr
		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD
		
	IF EXISTS (SELECT TOP 1 'U' FROM #TMPNEWSKUIMG WHERE ISNULL(IMG_ID,'')='')
	begin
	      
	    if isnull(@bSKU,0)<>1
		begin
		
		SET @CCMD=N';with CTE_SKU as 
		             (
		             SELECT a.product_code ,ARTICLE.ARTICLE_NO ,PARA1.para1_name,para2.para2_name,
		                    para3.para3_name,para4.para4_name,para5.para5_name,para6.para6_name ,a.IMG_ID
		             FROM #TMPNEWSKUIMG A
		             JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=a.ARTICLE_CODE 
		             JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE=a.PARA1_CODE
		             JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE=a.PARA2_CODE 
		             JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE=A.PARA3_CODE
		             JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE=a.PARA4_CODE
		             JOIN PARA5 (NOLOCK) ON PARA5.PARA5_CODE=a.PARA5_CODE
		             JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE=a.PARA6_CODE
		             WHERE ISNULL(IMG_ID,'''')=''''
		             )
		             
		           UPDATE sn SET img_id=IMG.IMG_ID FROM '+@CDBNAME+'_IMAGE.DBO.IMAGE_INFO IMG '+
		           CASE WHEN @BARTICLE=1 THEN ' JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=IMG.ARTICLE_CODE ' ELSE '' END+
		           CASE WHEN @BPARA1 =1 THEN ' JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE=IMG.PARA1_CODE ' ELSE '' END+
		           CASE WHEN @BPARA2 =1 THEN ' JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE=IMG.PARA2_CODE ' ELSE '' END+
		           CASE WHEN @BPARA3 =1 THEN ' JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE=IMG.PARA3_CODE ' ELSE '' END+
		           CASE WHEN @BPARA4 =1 THEN ' JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE=IMG.PARA4_CODE ' ELSE '' END+
		           CASE WHEN @BPARA5 =1 THEN ' JOIN PARA5 (NOLOCK) ON PARA5.PARA5_CODE=IMG.PARA5_CODE ' ELSE '' END+
		           CASE WHEN @BPARA6 =1 THEN ' JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE=IMG.PARA6_CODE ' ELSE '' END+
		           ' JOIN CTE_SKU sn (NOLOCK) ON '+@cExprName +'  
		             WHERE ISNULL(SN.IMG_ID,'''')='''' '
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	   
	   end
	end

	end
	ELSE
	begin
		SET @cCMD=N' UPDATE SN SET barcode_img_id=img.img_id FROM SKU_NAMES sn  WITH (ROWLOCK) JOIN sku (NOLOCK) ON sku.product_code=sn.product_code '+
				     ' JOIN '+@cDBNAME+'_image.dbo.image_info img on '+@cExpr	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD
	end

	IF @bCalledforBulkUpdate=1
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 * from config where config_option='build_bulk_skunames_imageinfo_2')
		BEGIN
			  INSERT config	( config_option,  Description,  last_update,  row_id,value)  
			  SELECT 'build_bulk_skunames_imageinfo_2'  config_option,'Build new column Image id in sku_names in BUlk' Description, 
					  getdate() last_update,newid() row_id,'1' value
		END	
		ELSE
			 UPDATE config SET value='1' where config_option='build_bulk_skunames_imageinfo_2'
	END
END