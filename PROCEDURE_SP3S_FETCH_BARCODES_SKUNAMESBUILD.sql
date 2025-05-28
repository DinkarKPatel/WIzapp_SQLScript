create PROCEDURE SP3S_FETCH_BARCODES_SKUNAMESBUILD
@cCutoffTime VARCHAR(20)
AS
BEGIN
	  
	  PRINT 'Step 1.5#'+convert(varchar,getdate(),113)
	  INSERT INTO SKU_DIFF (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,3 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=a.ac_code
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where sdf.master_tablename='lm01106' AND sdf.last_update<=@cCutoffTime AND df.PRODUCT_CODE IS NULL

		PRINT 'Step 2#'+convert(varchar,getdate(),113)
		INSERT sku_diff (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,4 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=a.article_code
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where sdf.master_tablename='article' AND sdf.last_update<=@cCutoffTime AND df.product_code is null
       
	   PRINT 'Step 2.3#'+convert(varchar,getdate(),113)
		INSERT sku_diff (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,4 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  JOIN art_det (NOLOCK) ON A.article_code =art_det .article_code AND A.para2_code =art_det .para2_code 
			  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=art_det.ROW_ID
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where sdf.master_tablename='ART_DET' AND sdf.last_update<=@cCutoffTime AND df.product_code is null
			  group by A.PRODUCT_CODE



		PRINT 'Step 2.5#'+convert(varchar,getdate(),113)	  
		INSERT sku_diff (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,5 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=A.ARTICLE_CODE
			  JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE
			  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=sectiond.section_code
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where sdf.master_tablename='sectionm' AND sdf.last_update<=@cCutoffTime AND df.product_code is null


		PRINT 'Step 3#'+convert(varchar,getdate(),113)	  
		INSERT sku_diff (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,6 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=A.ARTICLE_CODE
			  JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE
			  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=sectiond.sub_section_code
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where sdf.master_tablename='sectiond' AND sdf.last_update<=@cCutoffTime AND df.product_code is null

		DECLARE @nParaLoop INT,@cParaTable VARCHAR(150),@cCmd NVARCHAR(MAX),@cMasterColPara VARCHAR(100)
		--change for para7 24082022
		SET @nParaLoop=0
	    WHILE @nParaLoop<=32
		BEGIN
			SET @nParaLoop=@nParaLoop+1

			IF @nParaLoop BETWEEN 1 AND 7 
			BEGIN
				PRINT 'Step 4#'+convert(varchar,getdate(),113)

				SET @cParaTable='para'+LTRIM(RTRIM(STR(@nParaLoop)))
				SET @cMasterColPara=@cParaTable+'_code'

				SET @cCmd=N'INSERT sku_diff (product_code,diff_type,sp_id)
					  SELECT A.PRODUCT_CODE,'+str(@nParaLoop+7)+' as diff_type,'+LTRIM(RTRIM(STR(@@spid)))+' sp_id
					  FROM SKU A (NOLOCK)
					  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=a.'+@cMasterColPara+'
					  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id='''+LTRIM(RTRIM(STR(@@spid)))+'''
					  where sdf.master_tablename='''+@cParaTable+''' AND sdf.last_update<='''+@cCutoffTime+''' AND  df.product_code is null'
			END

			ELSE
			BEGIN
				SET @cParaTable='attr'+LTRIM(RTRIM(STR(@nParaLoop-7)))+'_mst'
				IF EXISTS (select TOP 1 * from config_attr where table_name=@cParaTable and table_caption<>'')
				BEGIN
					SET @cMasterColPara='attr'+LTRIM(RTRIM(STR(@nParaLoop-7)))+'_key_code'

					SET @cCmd=N'INSERT sku_diff (product_code,diff_type,sp_id)
						  SELECT A.PRODUCT_CODE,'+str(@nParaLoop+7)+' as diff_type,'+LTRIM(RTRIM(STR(@@spid)))+' sp_id
						  FROM SKU A (NOLOCK)
						  JOIN ARTICLE_FIX_ATTR AF (NOLOCK) ON AF.ARTICLE_CODE=A.ARTICLE_CODE
						  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=af.'+@cMasterColPara+'
						  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id='''+LTRIM(RTRIM(STR(@@spid)))+'''
						  where sdf.master_tablename='''+@cParaTable+''' and sdf.last_update<='''+@cCutoffTime+''' AND df.product_code is null'
				END
			END
			
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END
		
		PRINT 'Step 18#'+convert(varchar,getdate(),113)
		INSERT sku_diff (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,38 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  LEFT OUTER JOIN SKU_OH (NOLOCK) ON SKU_OH.product_code=a.product_code
			  JOIN SKU_NAMES SN (NOLOCK) ON sn.PRODUCT_CODE=a.PRODUCT_CODE
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where (((A.PURCHASE_PRICE+ISNULL(SKU_OH.TAX_AMOUNT,0)+ 
			    ISNULL(SKU_OH.OTHER_CHARGES,0) +  
				ISNULL(SKU_OH.ROUND_OFF,0) + ISNULL(SKU_OH.FREIGHT,0)+ 
				ISNULL(SKU_OH.EXCISE_DUTY_AMOUNT,0)+ISNULL(SKU_OH.VALUE_ADD,0))<>isnull(sn.lc,0)))
						 AND df.product_code is null
	
		PRINT 'Step 3#'+convert(varchar,getdate(),113)	  
		INSERT sku_diff (product_code,diff_type,sp_id)
		SELECT A.PRODUCT_CODE,39 as diff_type,@@spid sp_id
			  FROM SKU A (NOLOCK)
			  JOIN ARTICLE_fix_attr af (NOLOCK) ON Af.ARTICLE_CODE=A.ARTICLE_CODE
			  JOIN OPT_SKU_DIFF sdf (NOLOCK) ON  sdf.master_code=af.article_code
			  left outer JOIN SKU_DIFF df (NOLOCK) ON df.product_code=a.product_code AND df.sp_id=@@spid
			  where sdf.master_tablename='article_fix_attr' AND sdf.last_update<=@cCutoffTime AND df.product_code is null
		
	

END