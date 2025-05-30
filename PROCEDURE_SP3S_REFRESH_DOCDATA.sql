create PROCEDURE SP3S_REFRESH_DOCDATA
@CXNTYPE VARCHAR(20),
@CMEMOID VARCHAR(50),
@CERRMSG VARCHAR(MAX) OUTPUT
AS
BEGIN
BEGIN TRY
	
	DECLARE @CSTEP VARCHAR(3)
	
	SET @CERRMSG=''
	
	IF @CXNTYPE='DOCWSL'
	BEGIN
		SET @CSTEP='10'
		
		DELETE A FROM DOCWSL_IND01106_MIRROR A WITH (ROWLOCK) WHERE A.INV_ID =@CMEMOID
		DELETE A FROM DOCWSL_INM01106_MIRROR A			 WITH (ROWLOCK) WHERE A.INV_ID  =@CMEMOID
		DELETE A FROM DOCWSL_FORM_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_REGIONM_MIRROR A			  WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_STATE_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_CITY_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_AREA_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_HD01106_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_LM01106_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_LMP01106_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SECTIONM_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SECTIOND_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA1_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA2_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA3_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA4_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA5_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA6_MIRROR A				 WITH (ROWLOCK) WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARA7_MIRROR A				 WITH (ROWLOCK) WHERE A.DOCWSL_MEMO_ID =@CMEMOID

		DELETE A FROM DOCWSL_ARTICLE_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_ATTRM_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_ART_ATTR_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_ATTR_KEY_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SKU_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SKU_OH_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SCHEME_SETUP_MST_MIRROR A	 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SCHEME_SETUP_DET_MIRROR A	 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_SCHEME_SETUP_SLSBC_MIRROR A WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARCEL_MST_MIRROR A		 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_PARCEL_DET_MIRROR A		 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_ANGM_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_HSN_MST_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID
		DELETE A FROM DOCWSL_HSN_DET_MIRROR A			 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID				
		--20 JAN 2018
		DELETE A FROM DOCWSL_BOXM_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID				
		DELETE A FROM DOCWSL_BOXD_MIRROR A				 WITH (ROWLOCK)  WHERE A.DOCWSL_MEMO_ID =@CMEMOID	

		DELETE FROM DOCWSL_art_det_mirror WITH (ROWLOCK) where DOCWSL_MEMO_ID=@CMEMOID
        DELETE FROM DOCWSL_art_para1_mirror WITH (ROWLOCK) where DOCWSL_MEMO_ID=@CMEMOID

	END
	
	ELSE
	IF @CXNTYPE='DOCPRT'
	BEGIN
		SET @CSTEP='20'
		DELETE A FROM DOCPRT_FORM_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_STATE_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_CITY_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_AREA_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_HD01106_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_LM01106_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
	    
		DELETE A FROM DOCPRT_LMP01106_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_SECTIONM_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_LOCSST_MST_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_SECTIOND_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_LOCSST_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_LOCSSTADD_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_PARA1_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_PARA2_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_PARA3_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_PARA4_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_PARA5_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_PARA6_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_ARTICLE_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_ATTRM_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_ART_ATTR_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_ATTR_KEY_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_SKU_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_SKU_OH_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		DELETE A FROM DOCPRT_PARCEL_MST_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		DELETE A FROM DOCPRT_PARCEL_DET_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		DELETE A FROM DOCPRT_ANGM_MIRROR A WHERE A.DOCPRT_MEMO_ID =@CMEMOID
		
		DELETE A FROM DOCPRT_RMD01106_MIRROR A WHERE A.RM_ID =@CMEMOID
		DELETE A FROM DOCPRT_RMM01106_MIRROR A WHERE A.RM_ID  =@CMEMOID
		
		--20 JAN 2018
		DELETE A FROM DOCPRT_BOXM_MIRROR A WITH (ROWLOCK) WHERE A.DOCPRT_MEMO_ID=@CMEMOID
		DELETE A FROM DOCPRT_BOXD_MIRROR A WITH (ROWLOCK) WHERE A.DOCPRT_MEMO_ID=@CMEMOID

	END		
	
	ELSE
	IF @CXNTYPE='DOCPUR'
	BEGIN
	
    truncate table DOCPUR_PIM01106_UPLOAD 
	truncate table DOCPUR_PID01106_UPLOAD 
	truncate table DOCPUR_LM01106_UPLOAD 
	truncate table DOCPUR_LMP01106_UPLOAD
	truncate table DOCPUR_SECTIONM_UPLOAD
	truncate table DOCPUR_SECTIOND_UPLOAD
	truncate table DOCPUR_ARTICLE_UPLOAD
	truncate table DOCPUR_PARA1_UPLOAD
	truncate table DOCPUR_PARA2_UPLOAD
	truncate table DOCPUR_PARA3_UPLOAD
	truncate table DOCPUR_PARA4_UPLOAD
	truncate table DOCPUR_PARA5_UPLOAD
	truncate table DOCPUR_PARA6_UPLOAD
	truncate table DOCPUR_sku_UPLOAD
	truncate table DOCPUR_sku_oh_UPLOAD
	truncate table DOCPUR_config_UPLOAD
	truncate table DOCPUR_UOM_UPLOAD 

	truncate table DOCPUR_hsn_det_UPLOAD
	truncate table DOCPUR_hsn_mst_UPLOAD 
	truncate table DOCPUR_PURCHASEORDERPROCESSINGNEW_UPLOAD
	truncate table DOCPUR_IMAGE_INFO_DOC_UPLOAD
	
	
    truncate table DOCPUR_ARTICLE_FIX_ATTR_Upload
	truncate table DOCPUR_SD_ATTR_AVATAR_Upload
	truncate table DOCPUR_ATTR1_MST_Upload
	truncate table DOCPUR_ATTR2_MST_Upload
	truncate table DOCPUR_ATTR3_MST_Upload
	truncate table DOCPUR_ATTR4_MST_Upload
	truncate table DOCPUR_ATTR5_MST_Upload
	truncate table DOCPUR_ATTR6_MST_Upload
	truncate table DOCPUR_ATTR7_MST_Upload
	truncate table DOCPUR_ATTR8_MST_Upload
	truncate table DOCPUR_ATTR9_MST_Upload
	truncate table DOCPUR_ATTR10_MST_Upload
	truncate table DOCPUR_ATTR11_MST_Upload
	truncate table DOCPUR_ATTR12_MST_Upload
	truncate table DOCPUR_ATTR13_MST_Upload
	truncate table DOCPUR_ATTR14_MST_Upload
	truncate table DOCPUR_ATTR15_MST_Upload
	truncate table DOCPUR_ATTR16_MST_Upload
	truncate table DOCPUR_ATTR17_MST_Upload
	truncate table DOCPUR_ATTR18_MST_Upload
	truncate table DOCPUR_ATTR19_MST_Upload
	truncate table DOCPUR_ATTR20_MST_Upload
	truncate table DOCPUR_ATTR21_MST_Upload
	truncate table DOCPUR_ATTR22_MST_Upload
	truncate table DOCPUR_ATTR23_MST_Upload
	truncate table DOCPUR_ATTR24_MST_Upload
	truncate table DOCPUR_ATTR25_MST_Upload


	END
	ELSE
	IF @CXNTYPE='DOCGV'
	BEGIN
		TRUNCATE TABLE DOCGV_GV_STKXFER_MST_UPLOAD
		TRUNCATE TABLE DOCGV_GV_STKXFER_DET_UPLOAD
		TRUNCATE TABLE DOCGV_GV_MST_INFO_UPLOAD
		TRUNCATE TABLE DOCGV_SKU_GV_MST_UPLOAD
	END

	ELSE
	IF @cXntype='DOCIRT'
	BEGIN
		TRUNCATE TABLE DOCIRT_IRD01106_MIRROR
		truncate table DOCIRT_IRM01106_MIRROR
		truncate table DOCIRT_SECTIONM_MIRROR
		truncate table DOCIRT_SECTIOND_MIRROR
		truncate table DOCIRT_PARA1_MIRROR
		truncate table DOCIRT_PARA2_MIRROR
		truncate table DOCIRT_PARA3_MIRROR
		truncate table DOCIRT_PARA4_MIRROR
		truncate table DOCIRT_PARA5_MIRROR
		truncate table DOCIRT_PARA6_MIRROR
		truncate table DOCIRT_ARTICLE_MIRROR
		truncate table DOCIRT_UOM_MIRROR
		truncate table DOCIRT_ART_DET_MIRROR
		truncate table DOCIRT_ART_PARA1_MIRROR
		truncate table DOCIRT_ARTicle_fix_attr_MIRROR
		truncate table DOCIRT_SKU_MIRROR
	END
	 ELSE 
	 IF @cXntype='DOCWBO'  
	 BEGIN
            
            
	  DELETE A FROM DOCWBO_BUYER_ORDER_DET_MIRROR A WITH (ROWLOCK) WHERE A.ORDER_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_BUYER_ORDER_MST_MIRROR A    WITH (ROWLOCK) WHERE A.ORDER_ID  =@CMEMOID  
	  DELETE A FROM DOCWBO_HD01106_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_LM01106_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_LMP01106_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_SECTIONM_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_SECTIOND_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA1_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA2_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA3_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA4_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA5_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA6_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_PARA7_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
    
    
	  DELETE A FROM DOCWBO_ARTICLE_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_UOM_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_ATTRM_MIRROR A     WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_ART_ATTR_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_ATTR_KEY_MIRROR A    WITH (ROWLOCK)  WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
    
	   DELETE A FROM DOCWBO_ARTICLE_FIX_ATTR_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
    
	  DELETE A FROM DOCWBO_attr1_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr10_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr11_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr12_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr13_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr14_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr15_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr16_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr17_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr18_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr19_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr2_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr20_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr21_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr22_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr23_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr24_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr25_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr3_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr4_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr5_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr6_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr7_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr8_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_attr9_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_Paymode_mst_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
	  DELETE A FROM DOCWBO_SalesOrderProcessing_MIRROR A  WITH (ROWLOCK) WHERE A.DOCWBO_MEMO_ID =@CMEMOID  
  
  
	 END
 
 
END TRY

BEGIN CATCH
	SET @CERRMSG='P:SP3S_REFRESH_DOCDATA, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()        
END CATCH

END_PROC:

IF @@TRANCOUNT>0       
BEGIN 
	IF ISNULL(@CERRMSG,'')='' 
		COMMIT TRANSACTION
	ELSE
		ROLLBACK

END    
	
END
