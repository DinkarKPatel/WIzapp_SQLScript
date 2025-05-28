create PROCEDURE SP3S_DELETEupload_PURmerge_TABLES
@nSpId VARCHAR(50),
@nSpIdCopy VARCHAR(50)
AS
BEGIN
	
	IF OBJECT_ID('TEMPDB..#T','U') IS NOT NULL
	   DROP TABLE #T

	SELECT sp_ID  
	INTO #T
	FROM PUR_PIM01106_upload B (NOLOCK) WHERE sp_id=@nSpId OR sp_id=@nSpIdCopy
    
	IF EXISTS (SELECT TOP 1 'U' FROM #T)
	BEGIN
		DELETE A FROM PUR_PIM01106_UPLOAD A WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PID01106_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
	    DELETE A FROM PUR_DAILOGFILE_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_SECTIONM_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_SECTIOND_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_ARTICLE_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PARA1_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PARA2_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PARA3_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PARA4_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PARA5_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_PARA6_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
	    DELETE A FROM PUR_ATTRM_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
    	DELETE A FROM PUR_ATTR_KEY_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_ART_ATTR_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_SKU_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		DELETE A FROM PUR_SKU_OH_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
    	DELETE A FROM PUR_BOXM_upload A WITH (ROWLOCK)   join #t  B ON  A.sp_ID=B.sp_id
	    DELETE A FROM PUR_BOXD_upload A WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	    DELETE A FROM PUR_LOC_WISE_PURHISTORY_upload A WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	    DELETE A FROM PUR_ATTR1_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR10_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR11_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR12_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR13_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR14_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR15_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR16_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR17_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR18_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR19_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR2_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR20_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR21_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR22_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR23_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR24_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR25_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR3_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR4_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR5_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR6_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR7_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR8_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ATTR9_MST_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_ARTICLE_FIX_ATTR_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id
		 DELETE A FROM PUR_PMT01106_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id  
		 DELETE A FROM PUR_XN_AUDIT_TRIAL_DET_upload A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id  
		 DELETE A FROM PUR_POD_UPLOAD A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id  
		 DELETE A FROM PUR_HSN_det_UPLOAD A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id  
		 DELETE A FROM PUR_HSN_MST_UPLOAD A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id  
		 DELETE A FROM PUR_IMAGE_INFO_DOC_UPLOAD A  with (rowlock) join #t  B ON  A.sp_ID=B.sp_id 
		 
	END	 


END