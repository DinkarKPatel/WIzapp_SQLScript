CREATE procedure SP3S_GET_SYNCH_MASTERS_POS
@cLocId VARCHAR(5),
@cMstname VARCHAR(200),
@cLastmodifiedOn VARCHAR(40)
AS
BEGIN
	
	--- Return put by Dinkar is now removed as per discussion with Sir , Dinkar and Pankaj
	--- on this surity that Every cloud client shall have it slocations also updated on the same day 
	--- so that automatic calls do not come (Date : 27-12-2023)
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(5),@cSkuTable VARCHAR(100),@nLoop NUMERIC(5,0),@cJoinStr VARCHAR(200),
	@cTable VARCHAR(100),@cColName VARCHAR(100),@cJoiningCol varchar(300),@cAttrStr VARCHAR(4000),
	@cSyncTable VARCHAR(200),@cCols VARCHAR(2000),@bFLowPurInfo BIT,@cHoLocId VARCHAR(4),@cGstno varchar(50),
	@cPanNo VARCHAR(50),@cModiFiedColAlias VARCHAR(100),@cJoinMasterValues VARCHAR(100),@cMasterColExpr VARCHAR(100)

	SET @cStep='10'

	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

	SELECT TOP 1 @cGstno=loc_gst_no,@cPanNo=pan_no FROM location (NOLOCK) WHERE dept_id=@cHoLocId

	SET @cSkuTable=db_name()+'_pmt.dbo.locsku_'+@cLocId

	SET @bFLowPurInfo=0

	IF EXISTS (SELECT dept_id FROM location (NOLOCK) WHERE dept_id=@cLocId AND upd_purinfo=1 AND 
		(loc_type=1 OR (SUBSTRING(@cGstno,3,LEN(@cGstNo))=substring(loc_gst_no,3,len(loc_gst_no)) AND isnull(loc_gst_no,'')<>'')
			OR (pan_no=@cPanNo AND isnull(pan_no,'')<>'') OR allow_purchase_at_ho=1))
		SET @bFLowPurInfo=1

	DECLARE @dLastUpdate DATETIME
	
	CREATE TABLE #tmpMasterValues (mastervalue varchar(200),masterName VARCHAR(100))

	IF @cMstname IN ('sku','SKU_OH')
	BEGIN
		SET @cStep='20'

		SET @cModiFiedColAlias=@cMstname
		EXEC SP3S_GETFILTEREDMASTERS_POS
		@cLocId=@cLocId,
		@cMasterColExpr='sku.product_code',
		@cModiFiedColAlias=@cModiFiedColAlias,
		@cLastModifiedon=@cLastModifiedon

		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'sku.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='sku' AND (isnull(a.restricted_column,0)<>1 OR @bFLowPurInfo=1)

		INSERT INTO #tmpMasterValues (mastervalue)
		SELECT DISTINCT sku.product_code FROM sku (NOLOCK)
		JOIN #tmpMasterValues b ON sku.product_code=LEFT(b.mastervalue, ISNULL(NULLIF(CHARINDEX ('@',b.mastervalue)-1,-1),LEN(b.mastervalue )))
		LEFT JOIN #tmpMasterValues c ON c.mastervalue=sku.product_code
		WHERE sku.barcode_coding_scheme=1 AND CHARINDEX ('@',b.mastervalue)>0 AND sku.LAST_MODIFIED_ON>@cLastModifiedon AND  c.mastervalue IS NULL

		SET @cCmd=N'SELECT ''MSTSYNC_SKU_UPLOAD'' table_name,'+@cCols+'
		FROM sku (NOLOCK) '+
		(CASE WHEN @cMstname='sku' THEN ' LEFT ' ELSE '' END)+ 
		' JOIN sku_oh c (NOLOCK) ON c.product_code=sku.product_code
		  JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END

	IF @cMstname IN ('SKU_OH')
	BEGIN
		SET @cStep='25'

		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'sku_oh.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='sku_oh' AND (isnull(a.restricted_column,0)<>1 OR @bFLowPurInfo=1)

		SET @cCmd=N'SELECT ''MSTSYNC_SKU_OH_UPLOAD'' table_name,'+@cCols+'
		FROM sku_oh (NOLOCK)
		JOIN #tmpMasterValues mst ON mst.mastervalue=sku_oh.product_code'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END	
	
	IF @cMstname IN ('SKU','lm01106','lmp01106') AND @bFLowPurInfo=1
	BEGIN
		SET @cStep='26.3'

		IF @cMstname<>'SKU'
		BEGIN
			SET @cModiFiedColAlias=@cMstname

			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='lm01106.ac_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon

		END

		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'lm01106.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='lm01106' 

		IF @cMstname='SKU'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_lm01106_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN lm01106 (NOLOCK) ON lm01106.ac_code=sku.ac_code '+
			(CASE WHEN @cMstname<>'lmp01106' THEN ' LEFT ' ELSE '' END)+
			' JOIN lmp01106 (NOLOCK) ON lmp01106.ac_code=lm01106.ac_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_lm01106_UPLOAD'' table_name,'+@cCols+'
			FROM lm01106 (NOLOCK)'+
			(CASE WHEN @cMstname<>'lmp01106' THEN ' LEFT ' ELSE '' END)+
			' JOIN lmp01106 (NOLOCK) ON lmp01106.ac_code=lm01106.ac_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=lm01106.ac_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END	

	IF @cMstname IN ('SKU','lmp01106') AND @bFLowPurInfo=1
	BEGIN
		SET @cStep='27.2'

		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'lmp01106.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='lmp01106'

		IF @cMstname='sku'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_lmp01106_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN lmp01106 (NOLOCK) ON lmp01106.ac_code=sku.ac_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_lmp01106_UPLOAD'' table_name,'+@cCols+'
			FROM lmp01106 (NOLOCK)
			JOIN #tmpMasterValues mst ON mst.mastervalue=lmp01106.ac_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END	

	IF @cMstname IN ('SKU','hsn_mst','article')
	BEGIN
		SET @cStep='29'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'d.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='hsn_mst'


		IF @cMstname<>'SKU'
		BEGIN
			SET @cMasterColExpr=(CASE WHEN @cMstname='hsn_mst' THEN 'hsn_mst.HSN_code' ELSE 'article.article_code' END)
			
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr=@cMasterColExpr,
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon
		END
		SET @cCmd=N''
		
		

		IF @cMstName IN ('sku')
			SET @cCmd=@cCmd+N'SELECT DISTINCT ''MSTSYNC_hsn_mst_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN hsn_mst d (NOLOCK) ON d.hsn_code=sku.hsn_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'

		IF @cMstName IN ('article')
			SET @cCmd=@cCmd+(CASE WHEN @cCmd<>'' THEN ' UNION ' ELSE '' END)+
				N'SELECT DISTINCT ''MSTSYNC_hsn_mst_UPLOAD'' table_name,'+@cCols+'
				FROM article a (NOLOCK)
				JOIN hsn_mst d (NOLOCK) ON d.hsn_code=a.hsn_code
				JOIN #tmpMasterValues mst ON mst.mastervalue=a.article_code'

		IF @cMstName IN ('hsn_mst')
			SET @cCmd=@cCmd+(CASE WHEN @cCmd<>'' THEN ' UNION ' ELSE '' END)+
				N'SELECT DISTINCT ''MSTSYNC_hsn_mst_UPLOAD'' table_name,'+@cCols+'
				FROM hsn_mst d (NOLOCK)
				JOIN #tmpMasterValues mst ON mst.mastervalue=d.hsn_code'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END


	IF @cMstname IN ('SKU','hsn_mst','article','hsn_det')
	BEGIN
		SET @cStep='31'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'c.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='hsn_det'

		SET @cCmd=N''

		IF @cMstname='hsn_det'
		BEGIN

			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='hsn_det.HSN_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon
		END

		IF @cMstName IN ('hsn_mst','hsn_det')
			SET @cCmd=@cCmd+N'SELECT DISTINCT ''MSTSYNC_hsn_det_UPLOAD'' table_name,'+@cCols+'
			FROM hsn_mst a (NOLOCK)
			JOIN hsn_det c (NOLOCK) ON c.hsn_code=a.hsn_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=a.hsn_code'

		IF @cMstName IN ('sku')
		BEGIN
			SET @cCmd=@cCmd+(CASE WHEN @cCmd<>'' THEN ' UNION ' ELSE '' END)+
				N'SELECT DISTINCT ''MSTSYNC_hsn_det_UPLOAD'' table_name,'+@cCols+'
				FROM sku (NOLOCK)
				JOIN hsn_det c (NOLOCK) ON c.hsn_code=sku.hsn_code
				JOIN #tmpMasterValues mst ON mst.mastervalue=SKU.product_code'

			SET @cCmd=@cCmd+(CASE WHEN @cCmd<>'' THEN ' UNION ' ELSE '' END)+
				N'SELECT DISTINCT ''MSTSYNC_hsn_det_UPLOAD'' table_name,'+@cCols+'
				FROM sku (NOLOCK)
				JOIN article b (nolock) ON b.article_code=sku.article_code 
				JOIN hsn_det c (NOLOCK) ON b.hsn_code=c.hsn_code
				JOIN #tmpMasterValues mst ON mst.mastervalue=SKU.product_code'
		END

		IF @cMstName IN ('article')
			SET @cCmd=@cCmd+(CASE WHEN @cCmd<>'' THEN ' UNION ' ELSE '' END)+
				N'SELECT DISTINCT ''MSTSYNC_hsn_det_UPLOAD'' table_name,'+@cCols+'
				FROM article a (NOLOCK)
				JOIN hsn_det c (NOLOCK) ON c.hsn_code=a.hsn_code
				JOIN #tmpMasterValues mst ON mst.mastervalue=a.article_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('UOM','article')
	BEGIN
		SET @cStep='32.5'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'uom.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='uom'

		IF @cMstname='UOM'
		BEGIN
			
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='UOM.uom_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon
		END

		IF @cMstname IN ('article')
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_uom_UPLOAD'' table_name,'+@cCols+'
			FROM article (NOLOCK)
			JOIN uom (NOLOCK) ON uom.uom_code=article.uom_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=article.article_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_uom_UPLOAD'' table_name,'+@cCols+'
			FROM uom (NOLOCK)
			JOIN #tmpMasterValues mst ON mst.mastervalue=uom.uom_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('art_para1','article')
	BEGIN
		

		IF @cMstname='art_para1'
		BEGIN
			SET @cStep='32.8'
	
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='art_para1.article_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon
		END

		SET @cStep='32.89'
		SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_art_para1_UPLOAD'' table_name,a.*
		FROM art_para1 a (NOLOCK)
		JOIN #tmpMasterValues mst ON mst.mastervalue=a.article_code'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('art_det','article')
	BEGIN
		SET @cStep='33.2'


		IF @cMstname='art_det'
		BEGIN
		
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='art_det.article_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon
		END


		SET @cStep='33.25'
		IF @cMstname IN ('art_det')
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_art_det_UPLOAD'' table_name,a.*
			FROM art_det a (NOLOCK)
			JOIN #tmpMasterValues mst ON mst.mastervalue=a.article_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_art_det_UPLOAD'' table_name,b.*
			FROM article (NOLOCK)
			JOIN art_det b (NOLOCK) ON b.article_code=article.article_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=article.article_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd


	END

	IF @cMstname IN ('SKU','article','article_fix_attr')
	BEGIN
		SET @cStep='35'
		IF @cMstname='article_fix_attr'
		BEGIN
		
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='article_fix_attr.article_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon

			
		END

		SET @cJoinMasterValues = (CASE WHEN  @cMstname='sku' THEN 'sku.product_code' when @cMstName='article' then 'c.article_code' else 'article_fix_attr.article_code' END)
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'c.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='article' AND (isnull(a.restricted_column,0)<>1 OR @bFLowPurInfo=1)

		IF @cMstname='sku'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_article_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN article c (NOLOCK) ON c.article_code=sku.article_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_article_UPLOAD'' table_name,'+@cCols+'
			FROM article c (NOLOCK)
			LEFT JOIN article_fix_attr (NOLOCK) ON c.article_code=article_fix_attr.article_code
			JOIN #tmpMasterValues mst ON mst.mastervalue='+@cJoinMasterValues
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('SKU','sectiond','article')
	BEGIN
		SET @cStep='40'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'d.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='sectiond'

		IF @cMstname='sectiond'
		BEGIN
		
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='sectiond.sub_section_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon

	
		END

		SET @cStep='45'

		IF @cMstName='SKU'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectiond_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN article c (NOLOCK) ON c.article_code=sku.article_code
			JOIN sectiond d (NOLOCK) ON d.sub_section_code=c.sub_section_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'
		ELSE
		IF @cMstName='article'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectiond_UPLOAD'' table_name,'+@cCols+'
			FROM article (NOLOCK)
			JOIN sectiond d (NOLOCK) ON d.sub_section_code=article.sub_section_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=article.article_code'
		ELSE
		IF @cMstName='sectiond'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectiond_UPLOAD'' table_name,'+@cCols+'
			FROM sectiond d (NOLOCK)
			JOIN #tmpMasterValues mst ON mst.mastervalue=d.sub_section_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('SKU','sectionm','sectiond','article')
	BEGIN
		SET @cStep='50'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'sectionm.'+column_name FROM  synch_sku_cols a (NOLOCK)
		WHERE table_name='sectionm'

		IF @cMstname='sectionm'
		BEGIN
		
			SET @cModiFiedColAlias=@cMstname
			EXEC SP3S_GETFILTEREDMASTERS_POS
			@cLocId=@cLocId,
			@cMasterColExpr='sectionm.section_code',
			@cModiFiedColAlias=@cModiFiedColAlias,
			@cLastModifiedon=@cLastModifiedon

		END

		IF @cMstName='SKU'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectionm_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN article c (NOLOCK) ON c.article_code=sku.article_code
			JOIN sectiond d (NOLOCK) ON d.sub_section_code=c.sub_section_code
			JOIN sectionm (NOLOCK) ON sectionm.section_code=d.section_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sectionm.section_code'
		ELSE
		IF @cMstName='article'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectionm_UPLOAD'' table_name,'+@cCols+'
			FROM article (NOLOCK)
			JOIN sectiond c (NOLOCK) ON c.sub_section_code=article.sub_section_code
			JOIN sectionm (NOLOCK) ON sectionm.section_code=c.section_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=article.article_code'
		ELSE
		IF @cMstName='sectiond'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectionm_UPLOAD'' table_name,'+@cCols+'
			FROM sectiond (NOLOCK)
			JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sectiond.sub_section_code'
		ELSE
		IF @cMstName='sectionm'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_Sectionm_UPLOAD'' table_name,'+@cCols+'
			FROM sectionm (NOLOCK)
			JOIN #tmpMasterValues mst ON mst.mastervalue=sectionm.section_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('sku','article','article_fix_attr')
	BEGIN
		SET @cStep='50'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'c.'+column_name FROM  INF_SCHEMA_COLUMNS a (NOLOCK)
		WHERE table_name='article_fix_attr'

		DECLARE @bOpenKey BIT,@cTableCalption VARCHAR(100)

		SET @nLoop=1
		WHILE @nLoop<=25
		BEGIN
			SET @bOpenKey=0
			SET @cAttrStr='attr'+ltrim(rtrim(str(@nLoop)))+'_key_code'

			SET @cTableCalption=''
			SELECT @cTableCalption=table_caption FROM  config_attr (NOLOCK) WHERE column_name=REPLACE(@cAttrStr,'_code','_name')
			
			IF ISNULL(@cTableCalption,'')=''
				SET @cCols=replace(@cCols,'c.'+@cAttrStr,'''0000000'' as '+@cAttrStr)

			SET @nLoop=@nLoop+1
		END

		IF @cMstname='sku'
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_article_fix_attr_UPLOAD'' table_name,'+@cCols+'
			FROM sku (NOLOCK)
			JOIN article_fix_attr c (NOLOCK) ON c.article_code=sku.article_code
			JOIN #tmpMasterValues mst ON mst.mastervalue=sku.product_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_article_fix_attr_UPLOAD'' table_name,'+@cCols+'
			FROM article_fix_attr c(NOLOCK)
			JOIN #tmpMasterValues mst ON mst.mastervalue=c.article_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @cMstname IN ('article','article_fix_attr')
	BEGIN
		SET @cStep='55'
		SET @cCols=NULL
		SELECT @cCols=coalesce(@cCols+',','')+'b.'+column_name FROM  INF_SCHEMA_COLUMNS a (NOLOCK)
		WHERE table_name='SD_ATTR_AVATAR'

		SET @cCmd=N'SELECT DISTINCT ''MSTSYNC_SD_ATTR_AVATAR_UPLOAD'' table_name,'+@cCols+'
		FROM article A (NOLOCK)
		JOIN SD_ATTR_AVATAR b (NOLOCK) ON A.sub_section_code=B.sub_section_code
		JOIN #tmpMasterValues mst ON mst.mastervalue=A.article_code'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END


	
	IF left(@cMstname,4) IN ('PARA','ATTR')
	BEGIN
		SET @cStep='57'
	

		SET @cMasterColExpr=@cMstName+'.'+(CASE WHEN left(@cMstname,4)='PARA' THEN @cMstName+'_code' ELSE REPLACE(@cMstName,'_MST','_key_code') END)
		SET @cModiFiedColAlias=@cMstname
		EXEC SP3S_GETFILTEREDMASTERS_POS
		@cLocId=@cLocId,
		@cMasterColExpr=@cMasterColExpr,
		@cModiFiedColAlias=@cModiFiedColAlias,
		@cLastModifiedon=@cLastModifiedon,
		@cMasterName=@cMstname
	END

	SET @nLoop=1

	WHILE @nLoop<=32
	BEGIN
		SET @cStep='60'
		SET @cJoinStr=''

		IF @nLoop<=7
			SET @cTable='para'+ltrim(rtrim(str(@nLoop)))
		ELSE
			SELECT @cTable='attr'+ltrim(rtrim(str(@nLoop-7)))+'_mst',
			@cJoinstr=' JOIN article_fix_attr af (NOLOCK) ON af.article_code=c.article_code'
		
		SET @cSyncTable='MSTSYNC_'+@cTable+'_upload'

		SET @cCols=NULL
		IF @nLoop>7
			SELECT @cCols=coalesce(@cCols+',','')+'d.'+REPLACE(column_name,'attr1',replace(@cTable,'_mst',''))
			FROM  synch_sku_cols a (NOLOCK)
			WHERE table_name='attr1_mst'
		ELSE
		begin
		    
			IF @CTABLE<>'PARA7'
				SELECT @CCOLS=COALESCE(@CCOLS+',','')+'D.'+REPLACE(COLUMN_NAME,'PARA1',REPLACE(@CTABLE,'_MST',''))
				FROM  SYNCH_SKU_COLS A (NOLOCK)	WHERE TABLE_NAME='PARA1'
				AND (@CTABLE IN ('PARA1','PARA2')  OR COLUMN_NAME NOT IN ('PARA1_ORDER','PARA1_SET'))
			ELSE
			 SELECT @CCOLS=COALESCE(@CCOLS+',','')+'D.'+REPLACE(COLUMN_NAME,'PARA1',REPLACE(@CTABLE,'_MST',''))
				FROM  SYNCH_SKU_COLS A (NOLOCK)	WHERE TABLE_NAME='PARA1'
				AND (COLUMN_NAME NOT IN ('PARA1_ORDER','PARA1_SET','ALIAS','BL_PARA1_NAME'))

		end
		
		print 'enter loop of masters:'+str(@nLoop)
		IF (@cTable<>@cMstname AND @cMstname NOT in ('article_fix_attr','article','sku')) OR
		(@cMstname IN ('article_fix_attr','article') AND @nLoop<=7)
			GOTO lblNext
		
		IF @nLoop>7 AND NOT EXISTS (SELECT TOP 1 table_name FROM config_attr(NOLOCK) WHERE table_caption<>'' AND table_name=@cTable)
			GOTO lblNext

		SET @cStep='70'
		SET @cColName=(CASE WHEN @nLoop>7 THEN REPLACE(@cTable,'_mst','') +'_key' ELSE @cTable END)+'_code'

		SET @cJoiningCol=(CASE WHEN @nLoop<=7 THEN 'c.'+@cColName ELSE 'af.'+@cColName END)

		IF left(@cMstname,4) in ('PARA','attr')
			SET @cCmd=N'SELECT DISTINCT '''+@cSyncTable+''' table_name,'+@cCols+'
			FROM '+@cTable+' d (NOLOCK) '+
			' JOIN #tmpMasterValues mst ON mst.mastervalue=d.'+@cColName
		ELSE
		IF @cMstname NOT IN ('article_fix_attr','article') and left(@cMstname,4)<>'ATTR'
			SET @cCmd=N'SELECT DISTINCT '''+@cSyncTable+''' table_name,'+@cCols+'
			FROM sku c (NOLOCK) '+@cJoinstr+
			' JOIN '+@cTable+' d ON d.'+@cColName+'='+@cJoiningCol+
			' JOIN #tmpMasterValues mst ON mst.mastervalue=c.product_code'
		ELSE
			SET @cCmd=N'SELECT DISTINCT '''+@cSyncTable+''' table_name,'+@cCols+'
			FROM article c (NOLOCK) '+@cJoinstr+
			' JOIN '+@cTable+' d ON d.'+@cColName+'='+@cJoiningCol+'
			JOIN #tmpMasterValues mst ON mst.mastervalue=c.article_code'
		

		PRINT isnull(@cCmd,'null cmd for table:'+@cTable)
		EXEC SP_EXECUTESQL @cCmd

		IF @cMstname NOT in ('article_fix_attr','article','sku')
			GOTO END_PROC

		lblNext:
		SET @nLoop=@nLoop+1
	END

END_PROC:
END