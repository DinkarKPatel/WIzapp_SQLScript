CREATE PROCEDURE SP3S_GET_DISCON
(
	@cProductCode	VARCHAR(100)
)
AS
BEGIN
	;WITH SKU_PC
	AS
	(
		SELECT article_code,barcode_coding_scheme FROM SKU (NOLOCK)
		WHERE PRODUCT_CODE=@cProductCode
		GROUP BY article_code,barcode_coding_scheme
	)
	select discon 
	from ARTICLE a (NOLOCK)
	JOIN SKU_PC b ON b.article_code=a.article_code
	WHERE ISNULL(b.barcode_coding_scheme,a.coding_scheme)<>1 
END