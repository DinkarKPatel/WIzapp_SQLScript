CREATE PROCEDURE SP3S_CREATE_ARTNAMES
@nMode INT=0 --- 0 - Day Change from  Postmonitor , 1. Restart of Console , 2. Called from Insert Trigger of Article
			 	
AS
BEGIN
	  DECLARE @nArtCnt NUMERIC(5,0),@nArtNamesCnt NUMERIC(5,0),@cTableName VARCHAR(200),@cCmd NVARCHAR(MAX),
			  @cColCode VARCHAR(100),@cColName VARCHAR(100)
	  
	  SELECT @nArtNamesCnt=0,@nArtCnt=0
	  IF @nMode<=1
	  BEGIN
		  SELECT @nArtCnt=COUNT(article_code) FROM article (NOLOCK)
		  SELECT @nArtNamesCnt=COUNT(article_code) FROM art_names (NOLOCK)
	  END

	  IF ISNULL(@nArtNamesCnt,0)<ISNULL(@nArtCnt,0) OR @nMode=2
	  BEGIN
			IF @nMode IN (0,1)
			BEGIN
			    IF EXISTS (SELECT TOP 1 article_code FROM  art_diff (NOLOCK) WHERE sp_id=@@spid)	
  					DELETE FROM art_diff WITH (ROWLOCK) WHERE sp_id=@@spid			

				INSERT art_diff (article_code,diff_type,sp_id)
				SELECT a.article_code,1 as diff_type,@@spid sp_id from article a (NOLOCK)
				LEFT OUTER JOIN art_names b (NOLOCK) ON a.article_code=b.article_code
				WHERE b.article_code IS NULL	
			END

			print 'Insert missing articles'
			INSERT art_names (article_code,article_no,article_name,section_name,SUB_SECTION_NAME
			, ATTR1_KEY_NAME, ATTR2_KEY_NAME, ATTR3_KEY_NAME, ATTR4_KEY_NAME, ATTR5_KEY_NAME
			, ATTR6_KEY_NAME, ATTR7_KEY_NAME, ATTR8_KEY_NAME, ATTR9_KEY_NAME, ATTR10_KEY_NAME
			, ATTR11_KEY_NAME, ATTR12_KEY_NAME, ATTR13_KEY_NAME, ATTR14_KEY_NAME, ATTR15_KEY_NAME
			, ATTR16_KEY_NAME, ATTR17_KEY_NAME, ATTR18_KEY_NAME, ATTR19_KEY_NAME, ATTR20_KEY_NAME
			, ATTR21_KEY_NAME, ATTR22_KEY_NAME, ATTR23_KEY_NAME, ATTR24_KEY_NAME, ATTR25_KEY_NAME)
			SELECT a.article_code,a.article_no,a.article_name,c.section_name,b.SUB_SECTION_NAME 
			,A1.ATTR1_KEY_NAME,A2.ATTR2_KEY_NAME,A3.ATTR3_KEY_NAME,A4.ATTR4_KEY_NAME,A5.ATTR5_KEY_NAME      
			,A6.ATTR6_KEY_NAME,A7.ATTR7_KEY_NAME,A8.ATTR8_KEY_NAME,A9.ATTR9_KEY_NAME,A10.ATTR10_KEY_NAME      
			,A11.ATTR11_KEY_NAME,A12.ATTR12_KEY_NAME,A13.ATTR13_KEY_NAME,A14.ATTR14_KEY_NAME,A15.ATTR15_KEY_NAME      
			,A16.ATTR16_KEY_NAME,A17.ATTR17_KEY_NAME,A18.ATTR18_KEY_NAME,A19.ATTR19_KEY_NAME,A20.ATTR20_KEY_NAME      
			,A21.ATTR21_KEY_NAME,A22.ATTR22_KEY_NAME,A23.ATTR23_KEY_NAME,A24.ATTR24_KEY_NAME,A25.ATTR25_KEY_NAME      	  
			from article a (NOLOCK)
			JOIN sectiond b (NOLOCK) ON a.sub_section_code=b.sub_section_code
			JOIN sectionm c (NOLOCK) ON c.section_code=b.section_code
			JOIN art_diff d (NOLOCK) ON d.article_code=a.article_code
			LEFT JOIN ARTICLE_FIX_ATTR  AF (NOLOCK) ON AF.ARTICLE_CODE=A.ARTICLE_CODE
			LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=af.attr1_KEY_CODE      
			LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=af.attr2_KEY_CODE      
			LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=af.attr3_KEY_CODE      
			LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=af.attr4_KEY_CODE      
			LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=af.attr5_KEY_CODE      
			LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=af.attr6_KEY_CODE      
			LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=af.attr7_KEY_CODE      
			LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=af.attr8_KEY_CODE      
			LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=af.attr9_KEY_CODE      
			LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=af.attr10_KEY_CODE      
			LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=af.attr11_KEY_CODE      
			LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=af.attr12_KEY_CODE      
			LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=af.attr13_KEY_CODE      
			LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=af.attr14_KEY_CODE      
			LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=af.attr15_KEY_CODE      
			LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=af.attr16_KEY_CODE      
			LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=af.attr17_KEY_CODE      
			LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=af.attr18_KEY_CODE      
			LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=af.attr19_KEY_CODE      
			LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=af.attr20_KEY_CODE      
			LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=af.attr21_KEY_CODE      
			LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=af.attr22_KEY_CODE      
			LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=af.attr23_KEY_CODE      
			LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=af.attr24_KEY_CODE      
			LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=Af.ATTR25_KEY_CODE
			LEFT OUTER JOIN art_names an (NOLOCK) ON a.article_code=an.article_code
			WHERE d.sp_id=@@SPID AND an.article_code IS NULL	

			DELETE FROM art_diff WITH (ROWLOCK) WHERE sp_id=@@spid
	  END

	  ---- No need to Check for mismatch of Column value and Update Art_names If called from Restart of Monitor
	  IF @nMode<>0
	 	  RETURN	  	

	  PRINT 'Step 0.4#'+convert(varchar,getdate(),113)
	  IF EXISTS (SELECT TOP 1 article_code FROM  art_diff (NOLOCK) WHERE sp_id=@@spid)	
  		DELETE FROM art_diff WITH (ROWLOCK) WHERE sp_id=@@spid
		
		PRINT 'Step 2#'+convert(varchar,getdate(),113)
		INSERT art_diff (article_code,diff_type,sp_id)
		SELECT A.article_code,4 as diff_type,@@spid sp_id
			  FROM article A (NOLOCK)
			  JOIN art_names aN (NOLOCK) ON an.article_code=a.article_code
			  left outer JOIN art_diff df (NOLOCK) ON df.article_code=a.article_code AND df.sp_id=@@spid
			  where (an.Article_no<>a.article_no  OR ISNULL(an.article_name,'')<>a.article_name)
			  and df.article_code is null

		PRINT 'Step 2.5#'+convert(varchar,getdate(),113)	  
		INSERT art_diff (article_code,diff_type,sp_id)
		SELECT A.article_code,5 as diff_type,@@spid sp_id
			  FROM article A (NOLOCK)
			  JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=a.SUB_SECTION_CODE
			  JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE=SECTIOND.SECTION_CODE
			  JOIN art_names aN (NOLOCK) ON an.article_code=a.article_code
			  left outer JOIN art_diff df (NOLOCK) ON df.article_code=a.article_code AND df.sp_id=@@spid
			  where (an.section_name<>SECTIONM.section_name)   and df.article_code is null


		PRINT 'Step 3#'+convert(varchar,getdate(),113)	  
		INSERT art_diff (article_code,diff_type,sp_id)
		SELECT A.article_code,6 as diff_type,@@spid sp_id
			  FROM ARTICLE A (NOLOCK)
			  JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=A.SUB_SECTION_CODE
			  JOIN art_names an (NOLOCK) ON an.article_code=a.article_code
			  left outer JOIN art_diff df (NOLOCK) ON df.article_code=a.article_code AND df.sp_id=@@spid
			  where (an.sub_section_name<>SECTIOND.sub_section_name)   and df.article_code is null


		PRINT 'Step 10#'+convert(varchar,getdate(),113)

		
		SELECT table_name,column_name colname INTO #tmpAttrTables FROM  config_attr (NOLOCK) WHERE table_caption <> ''

		WHILE EXISTS (SELECT TOP 1 table_name FROM  #tmpAttrTables)
		BEGIN
			SELECT TOP 1 @cTableName=table_name,@cColName=colname,
			@cColCode=REPLACE(colname,'name','code')  FROM #tmpAttrTables

			SET @cCmd=N'IF EXISTS (select TOP 1 * from config_attr where table_name='''+@cTableName+''' and table_caption<>'''')
			INSERT art_diff (article_code,diff_type,sp_id)
			SELECT A.article_code,13 as diff_type,'+str(@@spid)+' sp_id
				  FROM article A (NOLOCK)
				  JOIN ARTICLE_FIX_ATTR AF (NOLOCK) ON AF.ARTICLE_CODE=A.ARTICLE_CODE
				  JOIN '+@cTableName+' A1 (NOLOCK) ON A1.'+@cColCode+'=AF.'+@cColCode+'
				  JOIN art_names an (NOLOCK) ON an.article_code=a.article_code
				  left outer JOIN art_diff df (NOLOCK) ON df.article_code=a.article_code AND df.sp_id='+str(@@spid)+
				  ' where ISNULL(an.'+@cColName+','''')<>a1.'+@cColName+' and df.article_code is null'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd

			DELETE FROM #tmpAttrTables WHERE table_name=@cTableName
		END

		PRINT 'Step 15#'+convert(varchar,getdate(),113)

		SELECT A.article_CODE,a.ARTICLE_NO,a.ARTICLE_NAME
		,c.SECTION_NAME,b.SUB_SECTION_NAME,A1.ATTR1_KEY_NAME,A2.ATTR2_KEY_NAME,A3.ATTR3_KEY_NAME,A4.ATTR4_KEY_NAME,A5.ATTR5_KEY_NAME      
		,A6.ATTR6_KEY_NAME,A7.ATTR7_KEY_NAME,A8.ATTR8_KEY_NAME,A9.ATTR9_KEY_NAME,A10.ATTR10_KEY_NAME      
		,A11.ATTR11_KEY_NAME,A12.ATTR12_KEY_NAME,A13.ATTR13_KEY_NAME,A14.ATTR14_KEY_NAME,A15.ATTR15_KEY_NAME      
		,A16.ATTR16_KEY_NAME,A17.ATTR17_KEY_NAME,A18.ATTR18_KEY_NAME,A19.ATTR19_KEY_NAME,A20.ATTR20_KEY_NAME      
		,A21.ATTR21_KEY_NAME,A22.ATTR22_KEY_NAME,A23.ATTR23_KEY_NAME,A24.ATTR24_KEY_NAME,A25.ATTR25_KEY_NAME      	  
		INTO #art_NAMES
		FROM article A (NOLOCK) 
		JOIN sectiond b (NOLOCK) ON a.sub_section_code=b.sub_section_code
		JOIN sectionm c (NOLOCK) ON c.section_code=b.section_code
		JOIN ART_DIFF adf (NOLOCK) ON adf.article_code=a.article_code
		LEFT JOIN ARTICLE_FIX_ATTR  AF (NOLOCK) ON AF.ARTICLE_CODE=A.ARTICLE_CODE
		LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=af.attr1_KEY_CODE      
		LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=af.attr2_KEY_CODE      
		LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=af.attr3_KEY_CODE      
		LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=af.attr4_KEY_CODE      
		LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=af.attr5_KEY_CODE      
		LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=af.attr6_KEY_CODE      
		LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=af.attr7_KEY_CODE      
		LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=af.attr8_KEY_CODE      
		LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=af.attr9_KEY_CODE      
		LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=af.attr10_KEY_CODE      
		LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=af.attr11_KEY_CODE      
		LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=af.attr12_KEY_CODE      
		LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=af.attr13_KEY_CODE      
		LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=af.attr14_KEY_CODE      
		LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=af.attr15_KEY_CODE      
		LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=af.attr16_KEY_CODE      
		LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=af.attr17_KEY_CODE      
		LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=af.attr18_KEY_CODE      
		LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=af.attr19_KEY_CODE      
		LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=af.attr20_KEY_CODE      
		LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=af.attr21_KEY_CODE      
		LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=af.attr22_KEY_CODE      
		LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=af.attr23_KEY_CODE      
		LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=af.attr24_KEY_CODE      
		LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=Af.ATTR25_KEY_CODE
		WHERE adf.sp_id=@@spid

		PRINT 'Step 20#'+convert(varchar,getdate(),113)

		UPDATE a SET ARTICLE_NO=S.ARTICLE_NO,ARTICLE_NAME=S.ARTICLE_NAME,SECTION_NAME=S.SECTION_NAME
		,SUB_SECTION_NAME=S.SUB_SECTION_NAME
		,ATTR1_KEY_NAME=S.ATTR1_KEY_NAME, ATTR2_KEY_NAME=S.ATTR2_KEY_NAME, ATTR3_KEY_NAME=S.ATTR3_KEY_NAME, ATTR4_KEY_NAME=S.ATTR4_KEY_NAME, ATTR5_KEY_NAME=S.ATTR5_KEY_NAME
		,ATTR6_KEY_NAME=S.ATTR6_KEY_NAME, ATTR7_KEY_NAME=S.ATTR7_KEY_NAME, ATTR8_KEY_NAME=S.ATTR8_KEY_NAME, ATTR9_KEY_NAME=S.ATTR9_KEY_NAME, ATTR10_KEY_NAME=S.ATTR10_KEY_NAME
		,ATTR11_KEY_NAME=S.ATTR11_KEY_NAME, ATTR12_KEY_NAME=S.ATTR12_KEY_NAME, ATTR13_KEY_NAME=S.ATTR13_KEY_NAME, ATTR14_KEY_NAME=S.ATTR14_KEY_NAME, ATTR15_KEY_NAME=S.ATTR15_KEY_NAME
		,ATTR16_KEY_NAME=S.ATTR16_KEY_NAME,ATTR17_KEY_NAME=S.ATTR17_KEY_NAME, ATTR18_KEY_NAME=S.ATTR18_KEY_NAME, ATTR19_KEY_NAME=S.ATTR19_KEY_NAME, ATTR20_KEY_NAME=S.ATTR20_KEY_NAME
		,ATTR21_KEY_NAME=S.ATTR21_KEY_NAME, ATTR22_KEY_NAME=S.ATTR22_KEY_NAME
		,ATTR23_KEY_NAME=S.ATTR23_KEY_NAME, ATTR24_KEY_NAME=S.ATTR24_KEY_NAME 
		,ATTR25_KEY_NAME=S.ATTR25_KEY_NAME
		FROM art_names a JOIN #art_names s ON a.article_code=s.article_code		
END