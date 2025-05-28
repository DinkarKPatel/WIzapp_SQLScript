CREATE Procedure SP3SWOW_GETPRODUCT
(
@cLocID varchar(2),
@cRackID varchar(50),
@cProductCode Varchar(50),
@XN_ITEM_TYPE  Numeric(5,0)=1,
@cWhere Varchar(200)='' 
)
As
Begin

     DECLARE 	 @BSTOCKNA BIT, @NITEMTYPE NUMERIC(2,0),	 @nBarCodeCodingScheme NUMERIC(1,0),
	 @CPRDCODE Varchar(100),@nStockQty Numeric(14,3)

	 SELECT @CPRDCODE= Product_Code  FROM SKU  (NOLOCK) where product_code= @cProductCode


	 IF @CPRDCODE IS NULL 
	 BEGIN     
		 SELECT 'Selected Product Code '+@cProductCode+' Not Found ' AS errorMessage  
		 RETURN
	 END


      SELECT @NITEMTYPE=ITEM_TYPE,@nBarCodeCodingScheme=ISNULL(barcode_coding_scheme,0), @BSTOCKNA= isnull(B.Stock_Na,0)
	  FROM SKU A(NOLOCK)
	 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE
	 JOIN SECTIOND C(NOLOCK) ON C.SUB_SECTION_CODE=B.SUB_SECTION_CODE
	 JOIN SECTIONM D(NOLOCK) ON D.SECTION_CODE=C.SECTION_CODE
	 WHERE PRODUCT_CODE=@CPRODUCTCODE
	 
	 IF ISNULL(@NITEMTYPE,0)>0 
	 BEGIN
	      IF  @XN_ITEM_TYPE<>@NITEMTYPE
	      BEGIN
	         SELECT errorMessage=CASE WHEN  @XN_ITEM_TYPE=1 AND @NITEMTYPE=2 THEN 'Consumable Item Not Allowed In Inventory Transaction'
	                     WHEN  @XN_ITEM_TYPE=1 AND @NITEMTYPE=3 THEN 'Assests Item Not Allowed In Inventory Transaction'
	                     WHEN  @XN_ITEM_TYPE=1 AND @NITEMTYPE=4 THEN 'Service Item Not Allowed In Inventory Transaction'
	                     
	                     WHEN  @XN_ITEM_TYPE=2 AND @NITEMTYPE=1 THEN 'Inventory  Item Not Allowed In  Consumable Transaction'
	                     WHEN  @XN_ITEM_TYPE=2 AND @NITEMTYPE=3 THEN 'Assests  Item Not Allowed In  Consumable Transaction'
	                     WHEN  @XN_ITEM_TYPE=2 AND @NITEMTYPE=4 THEN 'Service  Item Not Allowed In  Consumable Transaction'
	                     
	                     WHEN  @XN_ITEM_TYPE=3 AND @NITEMTYPE=1 THEN 'Inventory  Item Not Allowed In  Assests Transaction'
	                     WHEN  @XN_ITEM_TYPE=3 AND @NITEMTYPE=2 THEN 'Consumable  Item Not Allowed In  Assests Transaction'
	                     WHEN  @XN_ITEM_TYPE=3 AND @NITEMTYPE=4 THEN 'Service  Item Not Allowed In  Assests Transaction'
	                     
	                     
	                     WHEN  @XN_ITEM_TYPE=4 AND @NITEMTYPE=1 THEN 'Inventory  Item Not Allowed In   Service Transaction'
	                     WHEN  @XN_ITEM_TYPE=4 AND @NITEMTYPE=2 THEN 'Consumable  Item Not Allowed In   Service Transaction'
	                     WHEN  @XN_ITEM_TYPE=4 AND @NITEMTYPE=3 THEN 'Assests  Item Not Allowed In   Service Transaction '
	          END      
		      RETURN
	      END
	 END
	 

	IF @BSTOCKNA=0
	BEGIN
	      SELECT @nStockQty= sum(Quantity_in_Stock) From pmt01106 (Nolock) 
	      Where ( product_code=@cProductCode  OR  CHARINDEX(@cProductCode+'@',PRODUCT_CODE)>0)    and Dept_id= @cLocID and bin_id= @cRackID		
		IF @nStockQty<=0 
		BEGIN
		   SELECT 'Selected Product Code '+@cProductCode+' Is Not In Stock ' AS errorMessage  
		   RETURN
		END			
	END
	 

       CREATE TABLE #TEMPIMAGEBASE64(PRODUCT_CODE VARCHAR(100),IMG_ID VARCHAR(50),PROD_IMAGE VARBINARY(MAX),PROD_IMAGE_BASE64 NVARCHAR(MAX))

		DECLARE @cCMD NVARCHAR(MAX)
		SET @cCMD=N'SELECT B.PRODUCT_CODE,IMG_ID,PROD_IMAGE,CAST(N'''' AS XML).value(
          ''xs:base64Binary(xs:hexBinary(sql:column("PROD_IMAGE")))''
        , ''NVARCHAR(MAX)''
    )    AS PROD_IMAGE_BASE64
	   FROM '+DB_NAME()+'_IMAGE..IMAGE_INFO a (NOLOCK)
	   JOIN sku_names B (NOLOCK) ON B.barcode_img_id=a.IMG_ID
	   WHERE  B.product_Code<>'''' AND B.product_Code=''' + @cProductCode + ''''
	   PRINT @cCMD
	   INSERT INTO #TEMPIMAGEBASE64(PRODUCT_CODE ,IMG_ID ,PROD_IMAGE ,PROD_IMAGE_BASE64 )
	   EXECUTE SP_EXECUTESQL @cCMD
	   	 

		Select a.DEPT_ID as locId ,a.BIN_ID as rackId , @cProductCode as productCode,sum(quantity_in_stock) as quantityInStock ,b.article_no as articleNo , 
		b.section_name  as sectionName,b.sub_section_name as subSectionName ,Art.sub_section_code as subSectionCode, b.para1_name as para1Name , b.para2_name as para2Name,
		b.para3_name as para3Name , b.para4_name as para4Name,b.para5_name as para5Name ,b.para6_name as para6Name ,
		b.ATTR1_KEY_NAME as attr1keyName, b.ATTR2_KEY_NAME as attr2keyName, b.ATTR3_KEY_NAME as attr3keyName,
		b.ATTR4_KEY_NAME as attr4keyName, b.ATTR5_KEY_NAME as attr5keyName, b.ATTR6_KEY_NAME as attr6keyName,
		b.ATTR7_KEY_NAME as attr7keyName, b.ATTR8_KEY_NAME as attr8keyName, b.ATTR9_KEY_NAME as attr9keyName,
		b.ATTR10_KEY_NAME as attr10keyName, b.ATTR11_KEY_NAME as attr11keyName, b.ATTR12_KEY_NAME as attr12keyName,
		b.ATTR13_KEY_NAME as attr13keyName, b.ATTR14_KEY_NAME as attr14keyName, b.ATTR15_KEY_NAME as attr15keyName,
		b.ATTR16_KEY_NAME as attr16keyName, b.ATTR17_KEY_NAME as attr17keyName, b.ATTR18_KEY_NAME as attr18keyName,
		b.ATTR19_KEY_NAME as attr19keyName, b.ATTR20_KEY_NAME as attr20keyName, b.ATTR21_KEY_NAME as attr21keyName,
		b.ATTR22_KEY_NAME as attr22keyName, b.ATTR23_KEY_NAME as attr23keyName, b.ATTR24_KEY_NAME as attr24keyName,
		b.ATTR25_KEY_NAME as attr25keyName,b.mrp, B.boxWeight as xnitemWeight,B.stock_na as stockNa,B.sku_item_type as skuItemType,
		b.sku_item_type_desc as skuitemtypeDesc,B.sn_barcode_coding_scheme as codingScheme,B.SN_Uom_type as uomType,
		b.barcode_img_id as barcodeImgId,C.PROD_IMAGE_BASE64 AS [image]
		From sku_names B  (nolock)
		Left outer join article Art (nolock)  on Art.article_no = B.article_no 
	  Join PMT01106 A (nolock) on a.product_code = B.product_Code AND dept_id= @cLocID  and bin_id=@cRackID  and a.quantity_in_stock >0
		LEFT OUTER JOIN #TEMPIMAGEBASE64 C ON C.PRODUCT_CODE=B.product_Code
		where ( b.product_code=@cProductCode  OR  CHARINDEX(@cProductCode+'@',b.PRODUCT_CODE)>0)
		group by 	a.DEPT_ID ,a.BIN_ID ,b.article_no,b.section_name ,b.sub_section_name,Art.sub_section_code, b.para1_name  , b.para2_name ,
		b.para3_name  , b.para4_name,b.para5_name ,b.para6_name,	b.ATTR1_KEY_NAME , b.ATTR2_KEY_NAME ,
		b.ATTR3_KEY_NAME ,	b.ATTR4_KEY_NAME , b.ATTR5_KEY_NAME , b.ATTR6_KEY_NAME ,	b.ATTR7_KEY_NAME ,
		b.ATTR8_KEY_NAME , b.ATTR9_KEY_NAME,	b.ATTR10_KEY_NAME , b.ATTR11_KEY_NAME , b.ATTR12_KEY_NAME,
		b.ATTR13_KEY_NAME, b.ATTR14_KEY_NAME , b.ATTR15_KEY_NAME, b.ATTR16_KEY_NAME , b.ATTR17_KEY_NAME ,
		b.ATTR18_KEY_NAME,b.ATTR19_KEY_NAME , b.ATTR20_KEY_NAME , b.ATTR21_KEY_NAME ,
		b.ATTR22_KEY_NAME , b.ATTR23_KEY_NAME,  b.ATTR24_KEY_NAME,	b.ATTR25_KEY_NAME ,b.mrp, B.boxWeight,
		B.stock_na ,B.sku_item_type,	b.sku_item_type_desc ,B.sn_barcode_coding_scheme,B.SN_Uom_type,
		b.barcode_img_id,C.PROD_IMAGE_BASE64

End