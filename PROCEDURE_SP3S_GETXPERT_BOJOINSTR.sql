CREATE PROCEDURE SP3S_GETXPERT_BOJOINSTR
@cXnType VARCHAR(100),
@cInputJoinStr VARCHAR(MAX),
@cJoinStr VARCHAR(MAX) output,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cPcCol VARCHAR(50),@bProcess BIT,@cSectionCol VARCHAR(100),@cSubSectionCol VARCHAR(100),@cStep VARCHAR(5),
			@cAttrCol VARCHAR(100)

	
BEGIN TRY
	
	SET @cStep='10'
	SELECT @cJoinStr=@cInputJoinStr,@bProcess=0,@cErrormsg=''
	
	SET @cStep='30'
	SELECT @cSectionCol=key_col FROM #rep_det WHERE key_col='section_name'
	SELECT @cSubSectionCol=key_col FROM #rep_det WHERE key_col='sub_section_name'
	SELECT TOP 1 @cAttrCol=key_col FROM #rep_det WHERE key_col like '%attr%'

	SET @cStep='40'
	IF ISNULL(@cSubSectionCol,'')<>''
		SET @cJoinStr=@cJoinStr+(CASE WHEN CHARINDEX('JOIN article',@cJoinStr)=0 THEN 
		' JOIN article (NOLOCK) ON article.article_code=a.article_code' ELSE '' END)+
		' JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=article.sub_section_code'

	SET @cStep='50'
	IF ISNULL(@cSectionCol,'')<>''
		SET @cJoinStr=@cJoinStr+(CASE WHEN CHARINDEX('JOIN article',@cJoinStr)=0 THEN 
		' JOIN article (NOLOCK) ON article.article_code=a.article_code' ELSE '' END)+
		(CASE WHEN CHARINDEX('JOIN sectiond',@cJoinStr)=0 THEN 
		' JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=article.sub_section_code' ELSE '' END)+
		' JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code'

	--IF ISNULL(@cAttrCol,'')<>''
	--	SET @cJoinStr=@cJoinStr+(CASE WHEN CHARINDEX('JOIN article',@cJoinStr)=0 THEN 
	--	' JOIN article (NOLOCK) ON article.article_code=a.article_code' ELSE '' END)+
	--	' JOIN article_fix_attr (NOLOCK) ON article.article_code=article_fix_attr.article_code'

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETXPERT_BOJOINSTR at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
END
