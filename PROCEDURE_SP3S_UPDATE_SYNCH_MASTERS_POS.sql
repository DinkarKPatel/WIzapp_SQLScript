CREATE PROCEDURE SP3S_UPDATE_SYNCH_MASTERS_POS
@nMode NUMERIC(1,0)=1,
@cMstName VARCHAR(200)=''
AS
BEGIN
	DECLARE @nLoop NUMERIC(3,0),@cStep VARCHAR(5),@cTable VARCHAR(100),@cSyncTable VARCHAR(200),@cColName VARCHAR(200),@bFLowPurInfo BIT,
			@cErrormsg VARCHAR(500),@cCmd NVARCHAR(MAX),@LupdateOnly BIT,@bUpdPurInfo BIT,@cCurLocId VARCHAR(4)

BEGIN TRY
	SET @cStep='5'
	IF @nMode=1
		GOTO END_PROC



	SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'


	SET @cErrormsg=''
	

	SELECT TOP 1 @bUpdPurInfo=ISNULL(upd_purinfo,0) FROM  location (NOLOCK) WHERE dept_id=@cCurLocId

	BEGIN TRAN
	IF @cMstname IN ('SKU','sectionm','sectiond','article')
	BEGIN
		SET @cStep='10'
		SET @cSyncTable='MSTSYNC_sectionm_upload'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU', @CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='sectionm',@CKEYFIELD1='section_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		SET @cStep='11'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'sectionm','MSTSYNC_sectionm_upload','section_code'
	END

	IF @cMstname IN ('SKU','sectiond','article')
	BEGIN
		SET @cStep='20'
		SET @cSyncTable='MSTSYNC_sectiond_upload'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU', @CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='sectiond',@CKEYFIELD1='sub_section_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		SET @cStep='21'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'sectiond','MSTSYNC_sectiond_upload','sub_section_code'
	END
	
	IF @cMstname IN ('SKU','article','article_fix_attr')
	BEGIN
		SET @cStep='30'
		SET @cSyncTable='MSTSYNC_article_upload'
		
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU', @CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='article',@CKEYFIELD1='article_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		SET @cStep='31'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'article','MSTSYNC_article_upload','article_code'
	END


	SET @nLoop=1
	WHILE @nLoop<=32
	BEGIN
		SET @cStep='40'

		IF @nLoop<=7
			SET @cTable='para'+ltrim(rtrim(str(@nLoop)))
		ELSE
			SELECT @cTable='attr'+ltrim(rtrim(str(@nLoop-7)))+'_mst'
		
		SET @cSyncTable='MSTSYNC_'+@cTable+'_upload'
		
		print 'enter loop of masters:'+str(@nLoop)
		IF ((@cTable<>@cMstname AND @cMstname NOT in ('article_fix_attr','sku')) OR (@cMstname='article_fix_attr' AND @nLoop<=7))
		    AND NOT(@cMstName='article' AND @cTable='para2')
			GOTO lblNext

		SET @cColName=(CASE WHEN @nLoop>7 THEN REPLACE(@cTable,'_mst','') +'_key' ELSE @cTable END)+'_code'

		SET @LupdateOnly=(CASE WHEN @cMstName='sku' THEN 0 WHEN @cMstName='article_fix_attr' AND @nLoop>7 THEN 0 
							   WHEN @cMstName='article' AND @cTable='para2' THEN 0	ELSE 1 END)

		SET @CSTEP='50'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU',@CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE=@CTABLE,@CKEYFIELD1=@cColName,@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=@LUPDATEONLY,@BALWAYSUPDATE=1
		
		SET @cStep='51'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON @CTABLE,@cSyncTable,@cColName

lblNext:
		SET @nLoop=@nLoop+1
	END


	IF @cMstname IN ('SKU','lm01106','lmp01106') AND @bUpdPurInfo=1
	BEGIN
		SET @cStep='52'
		SET @cSyncTable='MSTSYNC_lm01106_upload'
		
		
		
		update a SET HEAD_CODE=isnull(b.head_code,'0000000021'),major_ac_code=isnull(c.ac_Code,a.ac_code) 
		FROM MSTSYNC_lm01106_upload A
		LEFT join HD01106 b on a.HEAD_CODE=b.head_code
		LEFT join lm01106 c on c.ac_CODE=a.major_ac_code
		
		SET @cStep='52.5'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU',@CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='lm01106',@CKEYFIELD1='ac_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		SET @cStep='52.7'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'lm01106','MSTSYNC_lm01106_upload','ac_code'		


		SET @cStep='52.9'
	    update a SET area_CODE=isnull(b.area_code,'0000000')
		FROM MSTSYNC_lmp01106_upload A
		LEFT join area b on a.area_CODE=b.area_code
	
		SET @cStep='53.2'
		SET @cSyncTable='MSTSYNC_lmp01106_upload'

		SET @cStep='53.5'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU',@CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='lmp01106',@CKEYFIELD1='ac_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		SET @cStep='53.7'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'lmp01106','MSTSYNC_lmp01106_upload','ac_code'		
	END

	IF @cMstname='sku'
	BEGIN
		SET @cStep='60'
		SET @cSyncTable='MSTSYNC_sku_upload'

		IF @bUpdPurInfo=0
			UPDATE MSTSYNC_sku_upload SET ac_code='0000000000'

		SET @cStep='65'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU',@CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='sku',@CKEYFIELD1='product_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=1,@BALWAYSUPDATE=1
		
		SET @cStep='66'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'sku','MSTSYNC_sku_upload','product_code'
	END

	IF @cMstname IN ('sku','article_fix_attr')
	BEGIN
		SET @cStep='70'
		SET @cSyncTable='MSTSYNC_article_fix_attr_upload'
		-- @cXntype='SYNCHSKU' (Do not mention this clause to get all columns overwritten for this table)
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='article_fix_attr',@CKEYFIELD1='article_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		SET @cStep='71'
		EXEC SP3S_UPDATE_LAST_MODIFIED_ON 'article_fix_attr','MSTSYNC_article_fix_attr_upload','article_code'
	END

	IF @cMstname IN ('article','article_fix_attr')
	BEGIN
		SET @cStep='80'
		SET @cSyncTable='MSTSYNC_sd_attr_avatar_upload'
		EXEC UPDATEMASTERXN_MIRROR @cXntype='SYNCHSKU',@CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='sd_attr_avatar',@CKEYFIELD1='sub_section_code',@CKEYFIELD2='',@CKEYFIELD3=''  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	END

	IF @cMstname IN ('article')
	BEGIN
		SET @cStep='85'
		SET @cSyncTable='MSTSYNC_art_Det_upload'
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@cSyncTable,@CDESTDB=''
				,@CDESTTABLE='art_Det',@CKEYFIELD1='article_code',@CKEYFIELD2='para2_code',@CKEYFIELD3='para1_Code'  
				,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATE_SYNCH_MASTERS_POS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@cErrormsg,'')=''
			COMMIT
		ELSE
			ROLLBACK
			
	END

	 truncate table mstsync_hsn_mst_upload
	 truncate table mstsync_hsn_det_upload
	 truncate table mstsync_uom_upload
	 truncate table mstsync_art_para1_upload
	 truncate table MSTSYNC_art_det_UPLOAD
	 truncate table MSTSYNC_lm01106_UPLOAD
	 truncate table MSTSYNC_lmp01106_UPLOAD
	 truncate table MSTSYNC_SKU_OH_UPLOAD
	 truncate table MSTSYNC_SKU_UPLOAD
	 truncate table MSTSYNC_article_UPLOAD
	 truncate table MSTSYNC_Sectiond_UPLOAD
	 truncate table MSTSYNC_Sectionm_UPLOAD
	 TRUNCATE TABLE MSTSYNC_article_fix_attr_upload
	 TRUNCATE TABLE MSTSYNC_sd_attr_avatar_upload

	SET @nLoop=1
	WHILE @nLoop<=32
	BEGIN
		IF @nLoop<=7
			SET @cTable='para'+ltrim(rtrim(str(@nLoop)))
		ELSE
			SELECT @cTable='attr'+ltrim(rtrim(str(@nLoop-7)))+'_mst'
		
		SET @cSyncTable='MSTSYNC_'+@cTable+'_upload'
		SET @cCmd=N'TRUNCATE TABLE '+@cSyncTable
		EXEC SP_EXECUTESQL @cCmd

		SET @nLoop=@nLoop+1
	END

LAST:
	SELECT ISNULL(@cErrormsg,'') errmsg

	IF @nMode<>1
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 * from  MST_SYNCHSKU_LOG (NOLOCK) WHERE mst_name=@cMstName)
			INSERT INTO MST_SYNCHSKU_LOG (MST_NAME,last_update,errmsg)
			SELECT @cMstName,getdate(),ISNULL(@cErrormsg,'')
		ELSE
			UPDATE MST_SYNCHSKU_LOG SET last_update=getdate(),errmsg=ISNULL(@cErrormsg,'')
			WHERE mst_name=@cMstName
	END
END