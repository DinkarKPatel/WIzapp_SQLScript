create PROCEDURE SP3S_UPDATE_ShopifyVariant_BARCODES
AS
BEGIN

	
	declare @cskuvariant varchar(max),@cCMD nvarchar(max)

	
	SELECT COL_VALUE OptionColName ,SRNO =0,SKU_ORDER optionOrder
	into #tmpVariantOption
	FROM INV_SKU_COL_LIST (nolock) WHERE FOR_SKU=1 

	insert into #tmpVariantOption(OptionColName,SRNO,optionOrder)
	select a.OptionColName,srNo=1,a.optionOrder 
	from ShopifyVaiantOption A (nolock)
	left join #tmpVariantOption b on a.OptionColName =b.OptionColName 
	where b.OptionColName is null

	
	 SELECT   @cskuvariant=ISNULL(@cskuvariant + '+''-''+','')  +  OPTIONCOLNAME   
	 FROM #TMPVARIANTOPTION A  (NOLOCK)   


	 SET @cCMD=N' Update a set variantSku =b.variantSku
	 FROM SKU_NAMES A (NOLOCK) 
	 join #tmpShopifyVariant b on b.variantSku='+@cskuvariant+' 
	 where b.variantSku<> isnull(a.variantSku,'''')  '

	 print @cCMD
	 exec sp_executesql @cCMD


	
END