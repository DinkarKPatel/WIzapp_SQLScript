CREATE FUNCTION FN_GETCMM_PARADET
(@DXNDT DATETIME,@CXNNO VARCHAR(20),@NMODE NUMERIC(1,0))
RETURNS VARCHAR(1000)
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @TPARATABLE TABLE (PARA_NAME VARCHAR(100))
	
	DECLARE @CSTR VARCHAR(1000),@CPARANAME VARCHAR(200)
	SET @CSTR=''
	
	IF @NMODE=1
		INSERT @TPARATABLE 
		SELECT DISTINCT SECTION_NAME FROM CMD01106 A JOIN CMM01106 B ON A.CM_ID=B.CM_ID
					 JOIN SKU C ON C.PRODUCT_CODE=A.PRODUCT_CODE
					 JOIN ARTICLE D ON D.ARTICLE_CODE=C.ARTICLE_CODE
					 JOIN SECTIOND E ON E.SUB_SECTION_CODE=D.SUB_SECTION_CODE
					 JOIN SECTIONM F ON F.SECTION_CODE=E.SECTION_CODE
		WHERE (@DXNDT<>'' AND CM_DT=@DXNDT) AND (@CXNNO='' OR B.CM_NO=@CXNNO)			 
	ELSE
		INSERT @TPARATABLE 
		SELECT DISTINCT SUB_SECTION_NAME FROM CMD01106 A JOIN CMM01106 B ON A.CM_ID=B.CM_ID
					 JOIN SKU C ON C.PRODUCT_CODE=A.PRODUCT_CODE
					 JOIN ARTICLE D ON D.ARTICLE_CODE=C.ARTICLE_CODE
					 JOIN SECTIOND E ON E.SUB_SECTION_CODE=D.SUB_SECTION_CODE
		WHERE (@DXNDT<>'' AND CM_DT=@DXNDT) AND (@CXNNO='' OR B.CM_NO=@CXNNO)			 
		
	DECLARE PARACURSOR CURSOR  FOR SELECT PARA_NAME FROM @TPARATABLE
	OPEN PARACURSOR
	FETCH NEXT FROM PARACURSOR INTO @CPARANAME
	WHILE @@FETCH_STATUS=0
	BEGIN
	    SET @CSTR=@CSTR+(CASE WHEN @CSTR<>'' THEN ',' ELSE '' END)+@CPARANAME
		FETCH NEXT FROM PARACURSOR INTO @CPARANAME
	END			
	CLOSE PARACURSOR
	DEALLOCATE PARACURSOR
	
	RETURN @CSTR
END
