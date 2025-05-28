
create TRIGGER TRG_ShopifyVariant_UPDSKUNAMES
ON ShopifyVariant
FOR INSERT,Update
AS
BEGIN
		DECLARE @cExpr NVARCHAR(MAX),@cIMGID NVARCHAR(100),@ccmd nVARCHAR(MAX),@cDBNAME NVARCHAR(100)


		SELECT variantSku,shopifyInventoryItemId 
		INTO #tmpShopifyVariant
		FROM inserted
	    
		EXEC  SP3S_UPDATE_ShopifyVariant_BARCODES
		

END