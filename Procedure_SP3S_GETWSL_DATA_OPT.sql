create PROCEDURE SP3S_GETWSL_DATA_OPT  
(          
 @CPRODUCT_CODE VARCHAR(50),  
 @NXN_ITEM_TYPE NUMERIC(2,0)=1,  
 @NMEMOTYPE NUMERIC(1,0)=0,  
 @CDEPT_ID varchar(5),  
 @NQuantity Numeric(10,3),  
 @cUSER_CODE varchar(7),  
 @NboxNo numeric(5,0),  
 @NDEFAULT_RATE_TYPE numeric(1,0)=1,  
 @CTARGETLOCID varchar(5)='',  
 @ninvmode int=0  ,
 @cloggedBinId varchar(8)='000'
)                        
AS                          
BEGIN                          
    
   
      DECLARE @CSTEP VARCHAR(5),@cBarCodeSeparator VARCHAR(5),@CERRORMSG varchar(500),  
           @sku_item_type INT,@sku_er_flag INT,@CCMD nvarchar(max),@ncodingScheme int,  
     @nrate numeric(14,2),@cbin_id varchar(7),@qtystock numeric(10,3),@nmrp numeric(18,2),  
     @bstock_na bit,@cBIN_NAME VARCHAR(100)  
  
   
   BEGIN TRY  
  
     SELECT  b.product_code,B.BIN_ID AS BIN_ID ,B.QUANTITY_IN_STOCK,cast('' as varchar(100)) as batch_Product_code,  
             SHOW_BATCH_COLUMNS=cast(0 as bit),Rate =cast(0 as Numeric(14,2)),mrp =cast(0 as Numeric(14,2)),CAST('' AS VARCHAR(100)) AS BIN_NAME  
              INTO #TMPstock  
     FROM  PMT01106 B   
     where 1=2  
  
      SET @CSTEP=10  
  
  
  SELECT TOP 1 @cBarCodeSeparator = value from config (NOLOCK) WHERE config_option='barcode_separator'  
  
  IF ISNULL(@cBarCodeSeparator,'')<>''  
  BEGIN  
   IF CHARINDEX(@cBarCodeSeparator,@CPRODUCT_CODE)>0  
         SET @CPRODUCT_CODE=SUBSTRING(@CPRODUCT_CODE,1,CHARINDEX(@cBarCodeSeparator,@CPRODUCT_CODE)-1)  
      
  END  
  
 
  
  SET @CSTEP=20  
  
  IF NOT EXISTS (SELECT TOP 1  'U' FROM SKU A (nolock) WHERE product_code=@CPRODUCT_CODE)  
  BEGIN  
  
    select 'BarCode not In SKU' as ERRMSG  
    GOTO END_PROC  
  END  
  
   if @cloggedBinId='888'
  begin
       select 'Transaction not allowed in Git Bin' as ERRMSG  
        GOTO END_PROC  
  end
    
     SET @CSTEP=30  
  
   SELECT @SKU_ITEM_TYPE=SKU_ITEM_TYPE,@sku_er_flag=sku_er_flag,@ncodingScheme=a.sn_barcode_coding_scheme  ,  
          @NRATE=CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN a.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN a.PP  ELSE a.WS_PRICE END,  
    @nmrp=mrp,@bstock_na=stock_na  
   FROM SKU_NAMES A (NOLOCK) WHERE  PRODUCT_CODE =@CPRODUCT_CODE   
  
   if isnull(@sku_er_flag,0)=0  
      set @sku_er_flag=1  
  
   if ISNULL(@sku_item_type,0)<>@NXN_ITEM_TYPE  
   begin  
        
      SET @CERRORMSG=  CASE WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN INVENTORY TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'    
                          
         WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'    
                          
         WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'    
                          
                          
         WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=2 THEN 'CONSUMBLE  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'    
         WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN SERVICE   TRANSCTION '   
         WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN SERVICE   TRANSCTION '      
         ELSE '' END  
  
      
   GOTO END_PROC  
                
   end  
  
  
     
       
   IF @NINVMODE=2  
   BEGIN  
  
   IF EXISTS (SELECT TOP 1 'U' FROM LOCATION (NOLOCK) WHERE ISNULL(CATEGORYCODE,'')<>'' AND DEPT_ID=@CTARGETLOCID)  
   BEGIN  
  
     EXEC VALIDATEXN_POSCATEGORY   
     @CXN_TYPE='WSL',  
     @CXNID='',  
     @NUPDATEMODE=1,  
     @CPARTY_DEPT_ID=@CTARGETLOCID,  
     @CERRORMSG=@CERRORMSG OUTPUT,  
     @BCALLEDFROMSCANNING=1,  
     @cproduct_code=@CPRODUCT_CODE,  
     @CDEPT_ID=@CDEPT_ID  
  
  
     IF ISNULL(@CERRORMSG,'')<>''  
        GOTO END_PROC  
     
   END  
  
    END  
  
    
  
   SET @CSTEP=40  
  
   IF ISNULL(@sku_er_flag,0)<>@NMEMOTYPE  
   BEGIN  
          SET @CERRORMSG=CASE WHEN @NMEMOTYPE=1 THEN  'REGULAR INVOICE  CAN NOTE SCAN ESTIMATE BARCODE PLEASE CHECK '   
    ELSE 'ESTIMATE INVOCE  CAN NOTE SCAN REGULAR BARCODE PLEASE CHECK '  END   
        
    GOTO END_PROC  
    
  END  
   
     if isnull(@bstock_na,0)=0  
     begin  
          declare @BALLOWNEGSTOCK bit  
  
         SELECT @BALLOWNEGSTOCK=VALUE FROM user_role_det a (NOLOCK)  
		JOIN users b (NOLOCK) ON a.role_id=b.role_id  
		WHERE USER_CODE=@cUSER_CODE   
		AND FORM_NAME='FRMWSLINVOICE'   
		AND FORM_OPTION='ALLOW_NEG_STOCK'   
  
      SET @bstock_na =isnull(@BALLOWNEGSTOCK,0)   
  
     End  
  
     if isnull(@ncodingScheme,0)<>1  
     begin  
        
      INSERT INTO #TMPSTOCK(PRODUCT_CODE,BIN_ID,BIN_NAME,QUANTITY_IN_STOCK,rate )  
      SELECT  b.product_code,B.BIN_ID AS BIN_ID,BIN.BIN_NAME ,B.QUANTITY_IN_STOCK,@nrate  
      FROM  PMT01106 B (nolock)  
      JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID  
      JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@cUSER_CODE  
      WHERE b.Product_code=@CPRODUCT_CODE   
      AND( B.QUANTITY_IN_STOCK >0  or @bstock_na=1)  
      AND B.DEPT_ID= @CDEPT_ID  
      AND (@cUSER_CODE='0000000' OR C.USER_CODE=@cUSER_CODE)  
      and b.bin_id <>'999'   
      and isnull(b.bo_order_id ,'')=''  
         
  
     end  
     Else  
     begin  
  
           
      INSERT INTO #TMPSTOCK(PRODUCT_CODE,BIN_ID,BIN_NAME,QUANTITY_IN_STOCK,batch_Product_code)  
      SELECT @CPRODUCT_CODE product_code,B.BIN_ID AS BIN_ID,BIN.BIN_NAME ,B.QUANTITY_IN_STOCK,b.product_code  
      FROM  PMT01106 B   
      JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID  
      JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@cUSER_CODE  
      WHERE   (b.PRODUCT_CODE=@CPRODUCT_CODE OR  CHARINDEX(@CPRODUCT_CODE+'@',b.PRODUCT_CODE)>0)  
      AND( B.QUANTITY_IN_STOCK >0  or @bstock_na=1)  
      AND B.DEPT_ID= @CDEPT_ID  
      AND (@cUSER_CODE='0000000' OR C.USER_CODE=@cUSER_CODE)  
      and b.bin_id <>'999'   
      and isnull(b.bo_order_id ,'')=''  
  
      UPDATE A SET RATE =(CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN B.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN B.PP  ELSE B.WS_PRICE END),  
                  mrp=b.mrp   
      FROM #TMPSTOCK A (NOLOCK)  
      JOIN SKU_NAMES B ON A.batch_Product_code =B.PRODUCT_CODE   
  
     
  
      SELECT @NRATE=RATE,@cbin_id =bin_id ,@nmrp=mrp,@cBIN_NAME =BIN_NAME FROM #TMPSTOCK  
      SET @NRATE=ISNULL(@NRATE,0)  
  
         
      IF EXISTS (SELECT TOP 1 'U' FROM #TMPSTOCK A   
      WHERE mrp not in(SELECT TOP 1  mrp  FROM #TMPSTOCK A WHERE mrp=@nmrp ))  
      begin  
         UPDATE #TMPSTOCK SET SHOW_BATCH_COLUMNS =1  
         CREATE NONCLUSTERED INDEX IX_TMP_PC ON  #TMPSTOCK(PRODUCT_CODE)  
      
    end  
      ELSE   
      BEGIN  
            
		   SELECT @QTYSTOCK=SUM(QUANTITY_IN_STOCK) FROM #TMPSTOCK  
		   truncate table #TMPSTOCK  
	        
           INSERT INTO #TMPSTOCK(PRODUCT_CODE,BIN_ID,QUANTITY_IN_STOCK,batch_Product_code,Rate,mrp,BIN_NAME )  
            SELECT @CPRODUCT_CODE product_code,isnull(@cbin_id,'000')  AS BIN_ID ,isnull(@QTYSTOCK,0) QUANTITY_IN_STOCK,  
            @CPRODUCT_CODE product_code,isnull(@nrate ,0),@nmrp as Mrp,@cBIN_NAME as BIN_NAME  
  
       
      END  
  
       
     end  
  
     if isnull(@bstock_na,0)=1  and ISNULL(@BALLOWNEGSTOCK,0)=0
         Update #TMPSTOCK set quantity_in_stock =0
     --   Update #TMPSTOCK set quantity_in_stock =999  
  
   
     IF NOT EXISTS (SELECT TOP 1 'U' FROM #TMPSTOCK )  and @NQuantity>0 and isnull(@bstock_na,0)=0   
      SET @CERRORMSG='Stock not Available'  
  
  
   END TRY  
     
   BEGIN CATCH  
   PRINT 'ENTER CATCH BLOCK'  
   SET @CERRORMSG='ERROR IN PROCEDURE SP3S_GETWSL_DATA : STEP #'+@CSTEP+' '+ERROR_MESSAGE()  
   GOTO END_PROC   
   END CATCH  
  
END_PROC:  
  PRINT 'LAST STEP:'+@CSTEP  
  
    if exists (select top 1'u' from #TMPstock where SHOW_BATCH_COLUMNS =1)  
     begin  
  ;WITH PMT
  AS
  (
	  SELECT (CASE WHEN CHARINDEX('@',product_Code)>0 AND CHARINDEX('@',@Cproduct_Code)=0 THEN SUBSTRING(product_code,1,CHARINDEX('@',product_Code)-1) ELSE product_Code END) AS BATCH_PRODUCT_CODE
	  ,@NQUANTITY  AS INVOICE_QUANTITY,@NQUANTITY QUANTITY,  
				isnull(rate,0)  AS RATE,isnull(rate,0)  AS NET_RATE, AMOUNT=isnull(rate,0)*@NQUANTITY,    
			   BIN_ID, BIN_NAME,SUM(QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK,mrp,AMOUNT_MRP=MRP*@NQUANTITY
	   FROM #TMPstock 
	   GROUP BY (CASE WHEN CHARINDEX('@',product_Code)>0 AND CHARINDEX('@',@CPRODUCT_CODE)=0 THEN SUBSTRING(product_code,1,CHARINDEX('@',product_Code)-1) ELSE product_Code END),RATE,BIN_ID,BIN_NAME,MRP
	)
      --SELECT sn. PRODUCT_CODE ,@NQUANTITY  AS INVOICE_QUANTITY,@NQUANTITY QUANTITY,  
      --      isnull(b.rate,0)  AS RATE,isnull(b.rate,0)  AS NET_RATE, AMOUNT=isnull(b.rate,0)*@NQUANTITY,  
      --  AMOUNT_MRP=SN.MRP*@NQUANTITY,  
      --     B.BIN_ID, B.BIN_NAME,B.QUANTITY_IN_STOCK,  
	   SELECT sn. PRODUCT_CODE ,b.INVOICE_QUANTITY,b.QUANTITY,  
            b.RATE,b.NET_RATE, b.AMOUNT,  b.AMOUNT_MRP,  
           B.BIN_ID, B.BIN_NAME,B.QUANTITY_IN_STOCK,
        sn.article_no,sn.section_name,sn.sub_section_name,  
        sn.para1_name,sn.para2_name,sn.para3_name,sn.para4_name,sn.para5_name,sn.para6_name,  
        sn.ATTR1_KEY_NAME,sn.ATTR2_KEY_NAME,sn.ATTR3_KEY_NAME,sn.ATTR4_KEY_NAME,sn.ATTR5_KEY_NAME,  
        sn.ATTR6_KEY_NAME,sn.ATTR7_KEY_NAME,sn.ATTR8_KEY_NAME,sn.ATTR9_KEY_NAME,sn.ATTR10_KEY_NAME,  
        sn.ATTR11_KEY_NAME,sn.ATTR12_KEY_NAME,sn.ATTR13_KEY_NAME,sn.ATTR14_KEY_NAME,sn.ATTR15_KEY_NAME,  
        sn.ATTR16_KEY_NAME,sn.ATTR17_KEY_NAME,sn.ATTR18_KEY_NAME,sn.ATTR19_KEY_NAME,sn.ATTR20_KEY_NAME,  
        sn.ATTR21_KEY_NAME,sn.ATTR22_KEY_NAME,sn.ATTR23_KEY_NAME,sn.ATTR24_KEY_NAME,sn.ATTR25_KEY_NAME,  
        sn.article_name,sn.stock_na,sn.sku_item_type,sn.para2_order,sn.uom as Uom,sn.para1_set,sn.para2_set,  
        sn.sn_hsn_code as hsn_code,sn.sn_barcode_coding_scheme coding_scheme,sn.sn_article_desc,  
        sn.sku_er_flag,sn.alt_uom_conversion_factor,sn.alternate_uom_name,  
        sn.para7_name,sn.Fix_mrp,sn.VENDOR_EAN_NO,@NboxNo As box_no,@CERRORMSG As Errmsg,  
        isnull(sn.SN_Uom_type,0) as Uom_type,@CDEPT_ID As DEPT_ID,  
        sn.batch_no--(CASE WHEN CHARINDEX('@',sn.product_Code)>0 THEN SUBSTRING(sn.product_code,CHARINDEX('@',sn.product_Code)+1,LEN(sn.product_code)) ELSE sn.product_Code END)  AS batch_no 
		,b.mrp,isnull(batch_Product_code,'') as batch_Product_code,  
        SN.UOM AS UOM_NAME ,SN.UOM AS UOM_CODE, --All totaling depend Upon uom code  
        sn.boxWeight as XNITEMWEIGHT,SN.ws_price  
  
      FROM PMT b  
      join  SKU_NAMES  SN (NOLOCK) on sn.product_Code =b.batch_Product_code   
    WHERE SN.product_Code = @CPRODUCT_CODE  
  
  
  
     end  
     else  
     begin  
                        
		;WITH PMT
		  AS
		  (
		  SELECT (CASE WHEN CHARINDEX('@',product_Code)>0 AND CHARINDEX('@',@CPRODUCT_CODE)=0 THEN SUBSTRING(product_code,1,CHARINDEX('@',product_Code)-1) ELSE product_Code END) AS BATCH_PRODUCT_CODE
		  ,@NQUANTITY  AS INVOICE_QUANTITY,@NQUANTITY QUANTITY,  
					isnull(rate,0)  AS RATE,isnull(rate,0)  AS NET_RATE, AMOUNT=isnull(rate,0)*@NQUANTITY,    
				   BIN_ID, BIN_NAME,SUM(QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK,MRP,AMOUNT_MRP=MRP*@NQUANTITY 
		   FROM #TMPstock 
		   GROUP BY (CASE WHEN CHARINDEX('@',product_Code)>0 AND CHARINDEX('@',@CPRODUCT_CODE)=0 THEN SUBSTRING(product_code,1,CHARINDEX('@',product_Code)-1) ELSE product_Code END),RATE,BIN_ID,BIN_NAME,mrp
			)
        --SELECT sn. PRODUCT_CODE ,@NQUANTITY  AS INVOICE_QUANTITY,@NQUANTITY QUANTITY,  
        --    isnull(b.rate,0)  AS RATE,isnull(b.rate,0)  AS NET_RATE, AMOUNT=isnull(b.rate,0)*@NQUANTITY,  
        --AMOUNT_MRP=isnull(b.mrp, sn.mrp) *@NQUANTITY,  
        --   B.BIN_ID,B.BIN_NAME ,  
		SELECT sn. PRODUCT_CODE ,b.INVOICE_QUANTITY,b.QUANTITY,  
            b.RATE,b.NET_RATE, b.AMOUNT,  b.AMOUNT_MRP,  
           B.BIN_ID, B.BIN_NAME,
        case when @bstock_na=1 then 9999 else  B.QUANTITY_IN_STOCK end QUANTITY_IN_STOCK,  
        sn.article_no,sn.section_name,sn.sub_section_name,  
        sn.para1_name,sn.para2_name,sn.para3_name,sn.para4_name,sn.para5_name,sn.para6_name,  
        sn.ATTR1_KEY_NAME,sn.ATTR2_KEY_NAME,sn.ATTR3_KEY_NAME,sn.ATTR4_KEY_NAME,sn.ATTR5_KEY_NAME,  
        sn.ATTR6_KEY_NAME,sn.ATTR7_KEY_NAME,sn.ATTR8_KEY_NAME,sn.ATTR9_KEY_NAME,sn.ATTR10_KEY_NAME,  
        sn.ATTR11_KEY_NAME,sn.ATTR12_KEY_NAME,sn.ATTR13_KEY_NAME,sn.ATTR14_KEY_NAME,sn.ATTR15_KEY_NAME,  
        sn.ATTR16_KEY_NAME,sn.ATTR17_KEY_NAME,sn.ATTR18_KEY_NAME,sn.ATTR19_KEY_NAME,sn.ATTR20_KEY_NAME,  
        sn.ATTR21_KEY_NAME,sn.ATTR22_KEY_NAME,sn.ATTR23_KEY_NAME,sn.ATTR24_KEY_NAME,sn.ATTR25_KEY_NAME,  
        sn.article_name,sn.stock_na,sn.sku_item_type,sn.para2_order,sn.uom as Uom,sn.para1_set,sn.para2_set,  
        sn.sn_hsn_code as hsn_code,sn.sn_barcode_coding_scheme coding_scheme,sn.sn_article_desc,  
        sn.sku_er_flag,sn.alt_uom_conversion_factor,sn.alternate_uom_name,  
        sn.para7_name,sn.Fix_mrp,sn.VENDOR_EAN_NO,@NboxNo As box_no,@CERRORMSG As Errmsg,  
        isnull(sn.SN_Uom_type,0) as Uom_type,@CDEPT_ID As DEPT_ID,  
        sn.batch_no--(CASE WHEN CHARINDEX('@',sn.product_Code)>0 THEN SUBSTRING(sn.product_code,CHARINDEX('@',sn.product_Code)+1,LEN(sn.product_code)) ELSE sn.product_Code END)  AS batch_no 
		,isnull(b.mrp, sn.mrp) as mrp,isnull(batch_Product_code,'') as batch_Product_code,  
        SN.UOM AS UOM_NAME ,SN.UOM AS UOM_CODE, --All totaling depend Upon uom code  
        sn.boxWeight as XNITEMWEIGHT,SN.ws_price  
  
    FROM SKU_NAMES  SN (NOLOCK)  
    LEFT OUTER join  PMT b on sn.product_Code =b.BATCH_PRODUCT_CODE   
    WHERE SN.product_Code=@CPRODUCT_CODE  
  
  
     end  
  
  
  
    
     
       
END  
------------- END OF PROCEDURE SP3S_GETWSL_DATA  
/*
CREATE PROCEDURE SP3S_GETWSL_DATA_OPT
(        
 @CPRODUCT_CODE VARCHAR(50),
 @NXN_ITEM_TYPE NUMERIC(2,0)=1,
 @NMEMOTYPE NUMERIC(1,0)=0,
 @CDEPT_ID varchar(2),
 @NQuantity Numeric(10,3),
 @cUSER_CODE varchar(7),
 @NboxNo numeric(5,0),
 @NDEFAULT_RATE_TYPE numeric(1,0)=1,
 @CTARGETLOCID varchar(2)='',
 @ninvmode int=0
)                      
AS                        
BEGIN                        
	 
	
      DECLARE @CSTEP VARCHAR(5),@cBarCodeSeparator VARCHAR(5),@CERRORMSG varchar(500),
	          @sku_item_type INT,@sku_er_flag INT,@CCMD nvarchar(max),@ncodingScheme int,
			  @nrate numeric(14,2),@cbin_id varchar(7),@qtystock numeric(10,3),@nmrp numeric(18,2),
			  @bstock_na bit,@cBIN_NAME VARCHAR(100)

	
	  BEGIN TRY

	    SELECT  b.product_code,B.BIN_ID AS BIN_ID ,B.QUANTITY_IN_STOCK,cast('' as varchar(100)) as batch_Product_code,
		           SHOW_BATCH_COLUMNS=cast(0 as bit),Rate =cast(0 as Numeric(14,2)),mrp =cast(0 as Numeric(14,2)),CAST('' AS VARCHAR(100)) AS BIN_NAME
              INTO #TMPstock
		   FROM  PMT01106 B 
		   where 1=2

	  	  SET @CSTEP=10


		SELECT TOP 1 @cBarCodeSeparator = value from config (NOLOCK) WHERE config_option='barcode_separator'

		IF ISNULL(@cBarCodeSeparator,'')<>''
		BEGIN
			IF CHARINDEX(@cBarCodeSeparator,@CPRODUCT_CODE)>0
		       SET @CPRODUCT_CODE=SUBSTRING(@CPRODUCT_CODE,1,CHARINDEX(@cBarCodeSeparator,@CPRODUCT_CODE)-1)
				
		END

		SET @CSTEP=20

		IF NOT EXISTS (SELECT TOP 1  'U' FROM SKU A (nolock) WHERE product_code=@CPRODUCT_CODE)
		BEGIN

	      	select 'BarCode not In SKU' as ERRMSG
			GOTO END_PROC
		END
		
	    SET @CSTEP=30

		 SELECT @SKU_ITEM_TYPE=SKU_ITEM_TYPE,@sku_er_flag=sku_er_flag,@ncodingScheme=a.sn_barcode_coding_scheme  ,
		        @NRATE=CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN a.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN a.PP  ELSE a.WS_PRICE END,
				@nmrp=mrp,@bstock_na=stock_na
		 FROM SKU_NAMES A (NOLOCK) WHERE  PRODUCT_CODE =@CPRODUCT_CODE 

		 if isnull(@sku_er_flag,0)=0
		    set @sku_er_flag=1

		 if ISNULL(@sku_item_type,0)<>@NXN_ITEM_TYPE
		 begin
		    
		    SET @CERRORMSG=  CASE WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=1 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
                        
							  WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=2 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
                        
							  WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=3 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
                        
                        
							  WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=2 THEN 'CONSUMBLE  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'  
							  WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN SERVICE   TRANSCTION ' 
							  WHEN  @NXN_ITEM_TYPE=4 AND @sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN SERVICE   TRANSCTION '    
							  ELSE '' END

				
			GOTO END_PROC
			           
		 end


		 
     
	  IF @NINVMODE=2
	  BEGIN

			IF EXISTS (SELECT TOP 1 'U' FROM LOCATION (NOLOCK) WHERE ISNULL(CATEGORYCODE,'')<>'' AND DEPT_ID=@CTARGETLOCID)
			BEGIN

					EXEC VALIDATEXN_POSCATEGORY 
					@CXN_TYPE='WSL',
					@CXNID='',
					@NUPDATEMODE=1,
					@CPARTY_DEPT_ID=@CTARGETLOCID,
					@CERRORMSG=@CERRORMSG OUTPUT,
					@BCALLEDFROMSCANNING=1,
					@cproduct_code=@CPRODUCT_CODE,
					@CDEPT_ID=@CDEPT_ID


					IF ISNULL(@CERRORMSG,'')<>''
					   GOTO END_PROC
			
			END

	   END

		

		 SET @CSTEP=40

		 IF ISNULL(@sku_er_flag,0)<>@NMEMOTYPE
		 BEGIN
		        SET @CERRORMSG=CASE WHEN @NMEMOTYPE=1 THEN  'REGULAR INVOICE  CAN NOTE SCAN ESTIMATE BARCODE PLEASE CHECK ' 
				ELSE 'ESTIMATE INVOCE  CAN NOTE SCAN REGULAR BARCODE PLEASE CHECK '  END 
			   
				GOTO END_PROC
		
		END
 
           if isnull(@bstock_na,0)=0
		   begin
		        declare @BALLOWNEGSTOCK bit

		      	SELECT @BALLOWNEGSTOCK=VALUE FROM user_role_det a (NOLOCK)
				JOIN users b (NOLOCK) ON a.role_id=b.role_id
				WHERE USER_CODE=@cUSER_CODE 
				AND FORM_NAME='FRMWSLINVOICE' 
				AND FORM_OPTION='ALLOW_NEG_STOCK' 

				SET @bstock_na =isnull(@BALLOWNEGSTOCK,0) 

		   End

		   if isnull(@ncodingScheme,0)<>1
		   begin
		    
		       INSERT INTO #TMPSTOCK(PRODUCT_CODE,BIN_ID,BIN_NAME,QUANTITY_IN_STOCK,rate )
			   SELECT  b.product_code,B.BIN_ID AS BIN_ID,BIN.BIN_NAME ,B.QUANTITY_IN_STOCK,@nrate
			   FROM  PMT01106 B 
			   JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
			   JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@cUSER_CODE
			   WHERE b.Product_code=@CPRODUCT_CODE 
			   AND( B.QUANTITY_IN_STOCK >0  or @bstock_na=1)
			   AND B.DEPT_ID= @CDEPT_ID
			   AND (@cUSER_CODE='0000000' OR C.USER_CODE=@cUSER_CODE)
			   and b.bin_id <>'999' 
			   and isnull(b.bo_order_id ,'')=''
			    

		   end
		   Else
		   begin

		       
			   INSERT INTO #TMPSTOCK(PRODUCT_CODE,BIN_ID,BIN_NAME,QUANTITY_IN_STOCK,batch_Product_code)
			   SELECT @CPRODUCT_CODE product_code,B.BIN_ID AS BIN_ID,BIN.BIN_NAME ,B.QUANTITY_IN_STOCK,b.product_code
			   FROM  PMT01106 B 
			   JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
			   JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@cUSER_CODE
			   WHERE   (b.PRODUCT_CODE=@CPRODUCT_CODE OR  CHARINDEX(@CPRODUCT_CODE+'@',b.PRODUCT_CODE)>0)
			   AND( B.QUANTITY_IN_STOCK >0  or @bstock_na=1)
			   AND B.DEPT_ID= @CDEPT_ID
			   AND (@cUSER_CODE='0000000' OR C.USER_CODE=@cUSER_CODE)
			   and b.bin_id <>'999' 
			   and isnull(b.bo_order_id ,'')=''

			


			   UPDATE A SET RATE =(CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN B.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN B.PP  ELSE B.WS_PRICE END),
			               mrp=b.mrp 
			   FROM #TMPSTOCK A (NOLOCK)
			   JOIN SKU_NAMES B ON A.batch_Product_code =B.PRODUCT_CODE 

			

			   SELECT @NRATE=RATE,@cbin_id =bin_id ,@nmrp=mrp,@cBIN_NAME =BIN_NAME FROM #TMPSTOCK
			   SET @NRATE=ISNULL(@NRATE,0)

			    
			   IF EXISTS (SELECT TOP 1 'U' FROM #TMPSTOCK A 
			   WHERE mrp not in(SELECT TOP 1  mrp  FROM #TMPSTOCK A WHERE mrp=@nmrp ))
			   begin
			      UPDATE #TMPSTOCK SET SHOW_BATCH_COLUMNS =1
				  CREATE NONCLUSTERED INDEX IX_TMP_PC ON  #TMPSTOCK(PRODUCT_CODE)
				
				end
			   ELSE 
			   BEGIN
			       
				   SELECT @QTYSTOCK=SUM(QUANTITY_IN_STOCK) FROM #TMPSTOCK
				   truncate table #TMPSTOCK
				  
				    INSERT INTO #TMPSTOCK(PRODUCT_CODE,BIN_ID,QUANTITY_IN_STOCK,batch_Product_code,Rate,mrp,BIN_NAME )
			        SELECT @CPRODUCT_CODE product_code,isnull(@cbin_id,'000')  AS BIN_ID ,isnull(@QTYSTOCK,0) QUANTITY_IN_STOCK,
					       @CPRODUCT_CODE product_code,isnull(@nrate ,0),@nmrp as Mrp,@cBIN_NAME as BIN_NAME

					
			   END

			
			 
			  
		   end

		

		   
		   if isnull(@bstock_na,0)=1
		      Update #TMPSTOCK set quantity_in_stock =999

	
		   IF NOT EXISTS (SELECT TOP 1 'U' FROM #TMPSTOCK )  and @NQuantity>0 and isnull(@bstock_na,0)=0 
		    SET @CERRORMSG='Stock not Available'


	  END TRY
	  
	  BEGIN CATCH
			PRINT 'ENTER CATCH BLOCK'
			SET @CERRORMSG='ERROR IN PROCEDURE SP3S_GETWSL_DATA : STEP #'+@CSTEP+' '+ERROR_MESSAGE()
			GOTO END_PROC 
	  END CATCH

END_PROC:
		PRINT 'LAST STEP:'+@CSTEP
	
		         if exists (select top 1'u' from #TMPstock where SHOW_BATCH_COLUMNS =1)
				 begin

				 	SELECT sn. PRODUCT_CODE ,@NQUANTITY  AS INVOICE_QUANTITY,@NQUANTITY QUANTITY,
				        isnull(b.rate,0)  AS RATE,isnull(b.rate,0)  AS NET_RATE, AMOUNT=isnull(b.rate,0)*@NQUANTITY,
					   AMOUNT_MRP=SN.MRP*@NQUANTITY,
				       B.BIN_ID, B.BIN_NAME,B.QUANTITY_IN_STOCK,
					   sn.article_no,sn.section_name,sn.sub_section_name,
					   sn.para1_name,sn.para2_name,sn.para3_name,sn.para4_name,sn.para5_name,sn.para6_name,
					   sn.ATTR1_KEY_NAME,sn.ATTR2_KEY_NAME,sn.ATTR3_KEY_NAME,sn.ATTR4_KEY_NAME,sn.ATTR5_KEY_NAME,
					   sn.ATTR6_KEY_NAME,sn.ATTR7_KEY_NAME,sn.ATTR8_KEY_NAME,sn.ATTR9_KEY_NAME,sn.ATTR10_KEY_NAME,
					   sn.ATTR11_KEY_NAME,sn.ATTR12_KEY_NAME,sn.ATTR13_KEY_NAME,sn.ATTR14_KEY_NAME,sn.ATTR15_KEY_NAME,
					   sn.ATTR16_KEY_NAME,sn.ATTR17_KEY_NAME,sn.ATTR18_KEY_NAME,sn.ATTR19_KEY_NAME,sn.ATTR20_KEY_NAME,
					   sn.ATTR21_KEY_NAME,sn.ATTR22_KEY_NAME,sn.ATTR23_KEY_NAME,sn.ATTR24_KEY_NAME,sn.ATTR25_KEY_NAME,
					   sn.article_name,sn.stock_na,sn.sku_item_type,sn.para2_order,sn.uom as Uom,sn.para1_set,sn.para2_set,
					   sn.sn_hsn_code as hsn_code,sn.sn_barcode_coding_scheme coding_scheme,sn.sn_article_desc,
					   sn.sku_er_flag,sn.alt_uom_conversion_factor,sn.alternate_uom_name,
					   sn.para7_name,sn.Fix_mrp,sn.VENDOR_EAN_NO,@NboxNo As box_no,@CERRORMSG As Errmsg,

					   isnull(sn.SN_Uom_type,0) as Uom_type,@CDEPT_ID As DEPT_ID,
					   sn.batch_no ,sn.mrp,isnull(batch_Product_code,'') as batch_Product_code,
					   SN.UOM AS UOM_NAME ,SN.UOM AS UOM_CODE, --All totaling depend Upon uom code
					   sn.boxWeight as XNITEMWEIGHT,SN.ws_price

				  FROM #TMPstock b
				  join  SKU_NAMES  SN (NOLOCK) on sn.product_Code =b.batch_Product_code 
			      WHERE b.product_Code = @CPRODUCT_CODE



				 end
				 else
				 begin
                      
					  	SELECT sn. PRODUCT_CODE ,@NQUANTITY  AS INVOICE_QUANTITY,@NQUANTITY QUANTITY,
				        isnull(b.rate,0)  AS RATE,isnull(b.rate,0)  AS NET_RATE, AMOUNT=isnull(b.rate,0)*@NQUANTITY,
					   AMOUNT_MRP=isnull(b.mrp, sn.mrp) *@NQUANTITY,
				       B.BIN_ID,B.BIN_NAME ,
					   case when @bstock_na=1 then 9999 else  B.QUANTITY_IN_STOCK end QUANTITY_IN_STOCK,
					   sn.article_no,sn.section_name,sn.sub_section_name,
					   sn.para1_name,sn.para2_name,sn.para3_name,sn.para4_name,sn.para5_name,sn.para6_name,
					   sn.ATTR1_KEY_NAME,sn.ATTR2_KEY_NAME,sn.ATTR3_KEY_NAME,sn.ATTR4_KEY_NAME,sn.ATTR5_KEY_NAME,
					   sn.ATTR6_KEY_NAME,sn.ATTR7_KEY_NAME,sn.ATTR8_KEY_NAME,sn.ATTR9_KEY_NAME,sn.ATTR10_KEY_NAME,
					   sn.ATTR11_KEY_NAME,sn.ATTR12_KEY_NAME,sn.ATTR13_KEY_NAME,sn.ATTR14_KEY_NAME,sn.ATTR15_KEY_NAME,
					   sn.ATTR16_KEY_NAME,sn.ATTR17_KEY_NAME,sn.ATTR18_KEY_NAME,sn.ATTR19_KEY_NAME,sn.ATTR20_KEY_NAME,
					   sn.ATTR21_KEY_NAME,sn.ATTR22_KEY_NAME,sn.ATTR23_KEY_NAME,sn.ATTR24_KEY_NAME,sn.ATTR25_KEY_NAME,
					   sn.article_name,sn.stock_na,sn.sku_item_type,sn.para2_order,sn.uom as Uom,sn.para1_set,sn.para2_set,
					   sn.sn_hsn_code as hsn_code,sn.sn_barcode_coding_scheme coding_scheme,sn.sn_article_desc,
					   sn.sku_er_flag,sn.alt_uom_conversion_factor,sn.alternate_uom_name,
					   sn.para7_name,sn.Fix_mrp,sn.VENDOR_EAN_NO,@NboxNo As box_no,@CERRORMSG As Errmsg,
					   isnull(sn.SN_Uom_type,0) as Uom_type,@CDEPT_ID As DEPT_ID,
					   sn.batch_no ,isnull(b.mrp, sn.mrp) as mrp,isnull(batch_Product_code,'') as batch_Product_code,
					   SN.UOM AS UOM_NAME ,SN.UOM AS UOM_CODE, --All totaling depend Upon uom code
					   sn.boxWeight as XNITEMWEIGHT,SN.ws_price

				FROM SKU_NAMES  SN (NOLOCK)
				left join  #TMPstock b on sn.product_Code =b.product_code 
				WHERE SN.product_Code=@CPRODUCT_CODE


				 end



	 
	  
	  		
END
------------- END OF PROCEDURE SP3S_GETWSL_DATA
*/