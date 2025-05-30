CREATE PROCEDURE SP3S_EOSS_GETSCHEMES_PARA_COMBINATION
@SCHEME_SETUP_DET_ROW_ID VARCHAR(250),
@CJOINSTRBUY VARCHAR(1000) OUTPUT,
@CJOINSTRGET VARCHAR(1000) OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	 DECLARE @cStep VARCHAR(5),@bCalledFromXpertReport BIT

BEGIN TRY
	 set @bCalledFromXpertReport=0

	 IF LEFT(@SCHEME_SETUP_DET_ROW_ID,5)='XPERT'
		SELECT @bCalledFromXpertReport=1,@SCHEME_SETUP_DET_ROW_ID=REPLACE(@SCHEME_SETUP_DET_ROW_ID,'XPERT','')
		

	 print 'Enter para combination for :'+	@SCHEME_SETUP_DET_ROW_ID
	 SET @cStep='10'
	 SET @cErrormsg=''
	 CREATE TABLE #TEMP_CONFIG
	 (
	  source_type numeric(1,0)
	 ,COLUMN_NAME VARCHAR(200)
	 )
	 
	 SET @cStep='20'
	 SELECT * INTO #TEMP_SCHALLCONFIG FROM SCHEME_SETUP_ALLMASTERS_CONFIG
	 WHERE SCHEME_SETUP_DET_ROW_ID = @SCHEME_SETUP_DET_ROW_ID

	 SET @cStep='30'	 
	 IF EXISTS (SELECT TOP 1 SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_COLUMN_NAME='ARTICLE' AND 
				SCHEME_SETUP_FLAG = 1)
		UPDATE #TEMP_SCHALLCONFIG SET SCHEME_SETUP_FLAG=0 WHERE SCHEME_SETUP_COLUMN_NAME='SUBSECTION'
	 
	 SET @cStep='50'	
	 IF EXISTS (SELECT TOP 1 SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_COLUMN_NAME='SUBSECTION' AND 
				SCHEME_SETUP_FLAG = 1) OR
				EXISTS (SELECT TOP 1 SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_COLUMN_NAME='ARTICLE' AND 
				SCHEME_SETUP_FLAG = 1)
		UPDATE #TEMP_SCHALLCONFIG SET SCHEME_SETUP_FLAG=0 WHERE SCHEME_SETUP_COLUMN_NAME='SECTION'
	 
	 SET @cStep='70'
	 INSERT INTO DBO.#TEMP_CONFIG(source_type,COLUMN_NAME) 
	 SELECT 1,SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_FLAG = 1

	 INSERT INTO DBO.#TEMP_CONFIG(source_type,COLUMN_NAME) 
	 SELECT 2,SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_FLAG = 1
	 	 
	SET @cStep='80' 
	DECLARE @nCnt NUMERIC(1,0),@DTSQLJOIN NVARCHAR(1000),@CCONFIG_COLUMN VARCHAR(200)


	SET @nCnt=1
	WHILE @nCnt<=2
	BEGIN
		SET @DTSQLJOIN=N' JOIN scheme_setup_allmasters sc (NOLOCK) ON 1=1 '
		WHILE EXISTS (SELECT TOP 1 * FROM #TEMP_CONFIG WHERE source_type=@nCnt)
		BEGIN
			SET @cStep='90'  
			SELECT TOP 1 @CCONFIG_COLUMN = COLUMN_NAME FROM #TEMP_CONFIG WHERE source_type=@nCnt

			IF @CCONFIG_COLUMN ='SECTION'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN sectionm (NOLOCK) ON sectionm.section_code=sc.section_code'+
											  ' AND itv.SECTION_name = Sectionm.SECTION_name'
			IF @CCONFIG_COLUMN ='SUBSECTION'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=sc.sub_section_code'+
								' JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code'+
								' AND itv.SECTION_name = SECTIONM.section_name and itv.sub_Section_name=sectiond.SUB_SECTION_name'
			IF @CCONFIG_COLUMN ='ARTICLE'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN article (NOLOCK) ON article.article_code=sc.article_code'+
										    ' AND itv.ARTICLE_no = article.article_no'
			IF @CCONFIG_COLUMN ='PARA1'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para1 (NOLOCK) ON para1.para1_code=sc.para1_code'+
										    ' AND itv.PARA1_name = para1.para1_name'
			IF @CCONFIG_COLUMN ='PARA2'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para2 (NOLOCK) ON para2.para2_code=sc.para2_code'+
											' AND itv.PARA2_name = para2.PARA2_name'

			IF @CCONFIG_COLUMN ='PARA3'
				SET @DTSQLJOIN =@DTSQLJOIN+' JOIN para3 (NOLOCK) ON para3.para3_code=sc.para3_code'+
										   ' AND itv.PARA3_name = para3.PARA3_name'
			IF @CCONFIG_COLUMN ='PARA4'
				SET @DTSQLJOIN =@DTSQLJOIN+' JOIN para4 (NOLOCK) ON para4.para4_code=sc.para4_code'+
										   ' AND itv.PARA4_name = para4.PARA4_name'
			IF @CCONFIG_COLUMN ='PARA5'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para5 (NOLOCK) ON para5.para5_code=sc.para5_code'+
										    ' AND itv.PARA5_name = para5.PARA5_name'

			IF @CCONFIG_COLUMN ='PARA6'
				SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para6 (NOLOCK) ON para6.para6_code=sc.para6_code'+
										    ' AND itv.PARA6_name = para6.PARA6_name'
		    
			SET @cStep='100'  
			DELETE FROM #TEMP_CONFIG WHERE source_type=@nCnt AND column_name=@CCONFIG_COLUMN
		END

		SET @cStep='110'
		IF @nCnt=1
			SET @CJOINSTRBuy=@DTSQLJOIN+' JOIN SCHEME_SETUP_DET SLSDET (NOLOCK) ON SLSDET.ROW_ID=sc.SCHEME_SETUP_DET_ROW_ID'
		ELSE
			SET @CJOINSTRGET=@DTSQLJOIN+' JOIN SCHEME_SETUP_DET SLSDET (NOLOCK) ON SLSDET.ROW_ID=sc.SCHEME_SETUP_DET_ROW_ID'

		SET @nCnt=@nCnt+1	
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_EOSS_GETSCHEMES_PARA_COMBINATION at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

END
