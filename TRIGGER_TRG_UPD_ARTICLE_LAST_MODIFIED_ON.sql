CREATE  TRIGGER[DBO].[TRG_UPD_ARTICLE_LAST_MODIFIED_ON] ON [DBO].[ARTICLE]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
begin

	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.article_code,'article' diff_type FROM DELETED a
	JOIN INSERTED b ON b.article_code=a.article_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.article_code=df.master_code AND df.master_tablename='article'	
	WHERE (a.Article_no<>b.article_no OR ISNULL(a.alias,'')<>ISNULL(b.alias,'') 
	OR ISNULL(a.stock_na,0)<>ISNULL(b.stock_na,0)  OR ISNULL(a.article_name,'')<>ISNULL(b.article_name,'')
	OR ISNULL(a.article_desc,'')<>ISNULL(b.article_desc,'')
	OR ISNULL(a.boxWeight,0)<>ISNULL(b.boxWeight,0)
	)
	AND df.master_code IS NULL

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
			RETURN
		
		UPDATE ARTICLE SET LAST_MODIFIED_ON=GETDATE()
		FROM DELETED B WHERE B.ARTICLE_CODE=ARTICLE.ARTICLE_CODE
		AND (ARTICLE.discon<>b.discon OR ARTICLE.wholesale_price<>b.wholesale_price OR ARTICLE.wsp_percentage<>b.wsp_percentage 
		OR ARTICLE.min_price<>b.min_price OR ARTICLE.stock_na<>b.stock_na OR ARTICLE.article_type<>b.article_type 
		OR ARTICLE.generate_barcodes_withArticle_Prefix<>b.generate_barcodes_withArticle_Prefix 
		OR ARTICLE.article_gen_mode<>b.article_gen_mode OR ARTICLE.FIX_MRP<>b.FIX_MRP OR 
		ARTICLE.SUPP_SPECIFIC<>b.SUPP_SPECIFIC OR ARTICLE.SUPP_AC_CODE<>b.SUPP_AC_CODE OR ARTICLE.SUPP_ITEM_CODE<>b.SUPP_ITEM_CODE 
		OR ARTICLE.gross_purchase_price<>b.gross_purchase_price OR ARTICLE.discount_percentage<>b.discount_percentage 
		OR ARTICLE.discount_amount<>b.discount_amount OR ARTICLE.gen_ean_codes<>b.gen_ean_codes 
		OR ARTICLE.size_center_point<>b.size_center_point OR ARTICLE.size_rate_diff<>b.size_rate_diff 
		OR ARTICLE.manual_disc<>b.manual_disc OR ARTICLE.manual_wsp<>b.manual_wsp OR ARTICLE.manual_rsp<>b.manual_rsp 
		OR ARTICLE.ORDERITEM<>b.ORDERITEM OR ARTICLE.bl_Article_name<>b.bl_Article_name  OR ARTICLE.ARTICLE_SET_TYPE<>b.ARTICLE_SET_TYPE 
		OR ARTICLE.Fixed_value_Addition<>b.Fixed_value_Addition OR ARTICLE.HSN_CODE<>b.HSN_CODE OR ARTICLE.coding_scheme<>b.coding_scheme 
		OR ARTICLE.uom_code<>b.uom_code OR ARTICLE.alias<>b.alias OR ARTICLE.mp_percentage<>b.mp_percentage 
		OR ARTICLE.purchase_price<>b.purchase_price OR ARTICLE.mrp<>b.mrp OR ARTICLE.para1_set<>b.para1_set 
		OR ARTICLE.para2_set<>b.para2_set OR ARTICLE.inactive<>b.inactive OR ARTICLE.article_no<>b.article_no 
		OR ARTICLE.article_name<>b.article_name OR ARTICLE.article_desc<>b.article_desc OR ARTICLE.sub_section_code<>b.sub_section_code 
		OR ARTICLE.PERISHABLE<>b.PERISHABLE
		OR ISNULL(ARTICLE.boxWeight,0)<>ISNULL(b.boxWeight,0)
		OR ISNULL(ARTICLE.ARTICLE_PACK_SIZE,0)<>ISNULL(b.ARTICLE_PACK_SIZE,0)
		)


end
