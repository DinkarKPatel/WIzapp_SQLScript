CREATE PROCEDURE SP3S_GETWSLORD_DYNAMICEXPR
@nMode NUMERIC(1,0)=1,
@cRetExpr VARCHAR(MAX) output
AS
BEGIN
	DECLARE @cConfigCols VARCHAR(1000)

	SELECT @cConfigCols = coalesce(@cConfigCols+',','')+'a.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK) 
	WHERE isnull(open_key,0)=1

	IF @nMode=1
	BEGIN
		SET @cRetExpr='article_no'
		SELECT @cRetExpr=@cRetExpr+
			(CASE WHEN charindex('PRODUCT_CODE',@cConfigCols)>0 THEN  ',a.product_code' ELSE '' END)+
			(CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ',section_name' ELSE '' END)+
			(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ',sub_section_name ' ELSE '' END)+
			(CASE WHEN charindex('ARTICLE_NAME',@cConfigCols)>0 THEN  ',article_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',para1_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',para2_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',para3_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',para4_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',para5_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',para6_name ' ELSE '' END)
	END
	ELSE
		SELECT @cRetExpr=' c.sp_id=b.sp_id '+
			(CASE WHEN charindex('SECTION_code',@cConfigCols)>0 THEN  ' AND b.section_code=c.section_code ' ELSE '' END)+
			(CASE WHEN charindex('SUB_SECTION_code',@cConfigCols)>0 THEN  ' AND b.sub_section_code=c.sub_section_code ' ELSE '' END)+
			(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 THEN  ' AND b.article_code=c.article_code ' ELSE '' END)+
			(CASE WHEN charindex('ARTICLE_code',@cConfigCols)>0 THEN  ' AND b.article_code=c.article_code ' ELSE '' END)+
			(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ' AND b.para1_code=c.para1_code ' ELSE '' END)+
			(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ' AND b.para2_code=c.para2_code ' ELSE '' END)+
			(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ' AND b.para3_code=c.para3_code ' ELSE '' END)+
			(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ' AND b.para4_code=c.para4_code ' ELSE '' END)+
			(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ' AND b.para5_code=c.para5_code ' ELSE '' END)+
			(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ' AND b.para6_code=c.para6_code ' ELSE '' END)

END