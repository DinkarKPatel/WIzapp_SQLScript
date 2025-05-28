CREATE PROCEDURE SP3S_DELETEupload_pomerge_TABLES
@nSpId VARCHAR(50),
@nSpIdCopy VARCHAR(50)
AS
BEGIN
	IF OBJECT_ID('TEMPDB..#T','U') IS NOT NULL
	    DROP TABLE #T
	SELECT sp_ID
	into #T
	FROM Po_PoM01106_upload B (NOLOCK) WHERE sp_id=@nSpId OR sp_id=@nSpIdCopy
   

	IF EXISTS (SELECT TOP 1 'U' FROM #T)
	BEGIN

	 DELETE A FROM PO_ARTICLE_FIX_ATTR_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_ARTICLE_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr1_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr10_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr11_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr12_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr13_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr14_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr15_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr16_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr17_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr18_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr19_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr2_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr20_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr21_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr22_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr23_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr24_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr25_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr3_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr4_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr5_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr6_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr7_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr8_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_attr9_mst_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
 
	 DELETE A FROM PO_PARA1_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_PARA2_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_PARA3_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_PARA4_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_PARA5_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_PARA6_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_POD01106_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_POM01106_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_SECTIOND_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_SECTIONM_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_SKU_OH_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_SKU_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
	 DELETE A FROM PO_UOM_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id
     DELETE A FROM PO_XN_AUDIT_TRIAL_DET_UPLOAD A  WITH (ROWLOCK) join #t  B ON  A.sp_ID=B.sp_id


END	 


END