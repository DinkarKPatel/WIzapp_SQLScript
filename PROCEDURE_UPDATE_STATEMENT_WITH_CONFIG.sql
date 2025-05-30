CREATE PROCEDURE UPDATE_STATEMENT_WITH_CONFIG
AS
BEGIN
	IF NOT EXISTS(SELECT TOP 1 'U' FROM CONFIG WHERE   CONFIG_OPTION='UPDATE_HSN_CODE_SKU')
	BEGIN
	
		DECLARE @cCmd NVARCHAR(MAX)
	
		SET @cCmd=N'UPDATE A SET HSN_CODE=C.HSN_CODE  FROM SKU A
		JOIN ARTICLE B ON A.ARTICLE_CODE =B.ARTICLE_CODE 
		JOIN SECTIOND C ON B.SUB_SECTION_CODE =C.SUB_SECTION_CODE 
		WHERE ISNULL(A.HSN_CODE,'''')  IN('''',''0000000000'')'
	
		EXEC SP_EXECUTESQL @cCmd
	
		INSERT CONFIG	( CONFIG_OPTION, VALUE, ROW_ID, LAST_UPDATE,  REMARKS )  
		SELECT 	   CONFIG_OPTION='UPDATE_HSN_CODE_SKU', 
		VALUE=1, ROW_ID=NEWID(), LAST_UPDATE=GETDATE(), REMARKS =''



	END 
END