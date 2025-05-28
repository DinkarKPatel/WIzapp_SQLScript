CREATE PROCEDURE SP3S_GETWSL_DATA_PASTE
(        
 @NSPID INT,
 @NBOXNO INT=0 ,
 @Clocid varchar(5),
 @BAGAINSTPS bit=0,
 @NDEFAULT_RATE_TYPE Numeric(1,0)=1,-- 1 for wsp 2 for mrp 3 for pp
 @NPASTE BIT=0,
 @CUSERCODE varchar(10)=''

)                      
AS                        
BEGIN                        
	 
	
      DECLARE @CSTEP VARCHAR(5),@cBarCodeSeparator VARCHAR(5),@CERRORMSG varchar(500),
	          @XN_ITEM_TYPE INT,@nmemotype int,@BMULTIPLEMRP bit 
	  BEGIN TRY

	  select  @XN_ITEM_TYPE=A.XN_ITEM_TYPE,@NDEFAULT_RATE_TYPE=default_rate_type FROM WSL_INV_SETTINGS A (NOLOCK) where sp_id=@NSPID


	  if @BAGAINSTPS=1
	     Goto END_PROC

	  	  SET @CSTEP=10


		SELECT TOP 1 @cBarCodeSeparator = value from config (NOLOCK) WHERE config_option='barcode_separator'

		IF ISNULL(@cBarCodeSeparator,'')<>''
		BEGIN
			IF EXISTS (SELECT TOP 1 product_code FROM WSL_ITEM_DETAILS (NOLOCK) WHERE SP_ID=@NSPID 
				AND CHARINDEX(@cBarCodeSeparator,product_code)>0)
				UPDATE WSL_ITEM_DETAILS WITH (ROWLOCK) SET product_code=SUBSTRING(product_code,1,CHARINDEX(@cBarCodeSeparator,product_code)-1)
				WHERE SP_ID=@nSpId AND CHARINDEX(@cBarCodeSeparator,product_code)>0
		END

		SET @CSTEP=20

		IF EXISTS (SELECT TOP 1  'U' FROM WSL_ITEM_DETAILS A 
		  LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE= B.PRODUCT_CODE 
		  WHERE SP_ID=@NSPID AND  B.PRODUCT_CODE IS NULL)
		  BEGIN
	      		SET @CERRORMSG='BARCODE NOT FOUND'

				 UPDATE A SET ERRMSG='BARCODE NOT FOUND' FROM WSL_ITEM_DETAILS A 
				  LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE= B.PRODUCT_CODE 
				  WHERE SP_ID=@NSPID AND  B.PRODUCT_CODE IS NULL

				GOTO END_PROC

		  END


	    SET @CSTEP=30

		  UPDATE A SET ERRMSG=  CASE WHEN  @XN_ITEM_TYPE=1 AND b.sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=1 AND b.sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=1 AND b.sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=1 AND b.sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'  
                        
							  WHEN  @XN_ITEM_TYPE=2 AND b.sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=2 AND b.sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=2 AND b.sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=2 AND b.sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'  
                        
							  WHEN  @XN_ITEM_TYPE=3 AND b.sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=3 AND b.sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=3 AND b.sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=3 AND b.sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'  
                        
                        
							  WHEN  @XN_ITEM_TYPE=4 AND b.sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=4 AND b.sku_item_type=2 THEN 'CONSUMBLE  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'  
							  WHEN  @XN_ITEM_TYPE=4 AND b.sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN SERVICE   TRANSCTION ' 
							  WHEN  @XN_ITEM_TYPE=4 AND b.sku_item_type=5 THEN 'Repair    ITEM NOT ALLOWED IN SERVICE   TRANSCTION '    
							  
						     
			   END  
		 FROM wsl_item_details  A (NOLOCK)  
		 JOIN sku_names b (NOLOCK) ON A.PRODUCT_CODE=b.PRODUCT_CODE   
		 WHERE CASE WHEN ISNULL(b.sku_item_type,0) IN(0,1) THEN 1 ELSE b.sku_item_type END  <>@XN_ITEM_TYPE  
		 AND A.SP_ID=@NSPID  

		 if exists (select top 1 'u' from wsl_item_details a (nolock) where sp_id=@NSPID and errmsg <>'')
		 begin
		    SET @CERRORMSG='invali item type'
			GOTO END_PROC

		 end

		 SET @CSTEP=40

		  UPDATE A SET ERRMSG=CASE WHEN @nmemotype=1 THEN  'REGULAR INVOICE  CAN NOTE SCAN ESTIMATE BARCODE PLEASE CHECK ' 
					   ELSE 'ESTIMATE INVOCE  CAN NOTE SCAN REGULAR BARCODE PLEASE CHECK '  END 
		   FROM WSL_ITEM_DETAILS A (NOLOCK)
		  JOIN SKU (NOLOCK) ON A.PRODUCT_CODE =SKU.PRODUCT_CODE 
		  WHERE A.SP_ID=@NSPID AND CASE WHEN ISNULL(SKU.ER_FLAG,0) IN (0,1) THEN 1 ELSE 2 END<>@nmemotype



		  IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS WHERE SP_ID=@NSPID AND ISNULL(ERRMSG,'')<>'')
		  GOTO END_PROC

	
   IF @XN_ITEM_TYPE<>5 
	BEGIN

	
	   SELECT PRODUCT_CODE,PRODUCT_CODE As BATCH_BARCODE,
	             cast('' as varchar(7)) as BIN_ID,
	             CAST(0 AS NUMERIC(14,3)) AS MRP,
				 SRNO=CAST(0 AS NUMERIC(5,0)),
		         quantity_in_stock =cast(0 as numeric(14,3)),
				 cast('' as varchar(50)) as pick_List_id,
				 cast('' as varchar(50)) as order_id,
				 cast('' as varchar(50)) as bo_det_row_id,
				 cast('' as varchar(50)) as pick_list_row_id,
				 cast('' as varchar(7)) as Logged_BIN_ID,
				 cast('' as varchar(7)) as Major_BIN_ID
		 INTO #TMPMULTIPLEMRP
		 FROM PMT01106 (NOLOCK)
		 WHERE 1=2
		
	    
	   --APPLICATION PAAS BIN NAME SO UPDATE 
	     UPDATE A SET BIN_ID=B.BIN_ID  FROM WSL_ITEM_DETAILS A (NOLOCK)
		 JOIN BIN B (NOLOCK) ON A.BIN_NAME =B.BIN_NAME
		 WHERE A.BIN_NAME<>'' AND ISNULL(A.BIN_ID,'')='' AND A.SP_ID=@NSPID

		 Declare @NMODE numeric(1,0)
		 set @NMODE=0

		 	     
		 IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)=0 and  ISNULL(A.BIN_ID,'')='' AND A.SP_ID=@NSPID)
		 BEGIN
		     set @NMODE=1
			
		 END
		 ELSE IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)=0 and  ISNULL(A.BIN_ID,'')<>'' AND A.SP_ID=@NSPID)
		 BEGIN
		     
			set @NMODE=2


		 END
		 ELSE IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)<>0 and  ISNULL(A.BIN_ID,'')='' AND A.SP_ID=@NSPID)
		 BEGIN
		     
			set @NMODE=3

		 END
		 ELSE IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)<>0 and  ISNULL(A.BIN_ID,'')<>'' AND A.SP_ID=@NSPID)
		 BEGIN
		     
			 set @NMODE=4
			
		 END

	
		  EXEC SP3S_CHECK_DUPLICATE_BARCODE 
			    @CSP_ID=@NSPID,
				@CUSERCODE=@CUSERCODE,
				@CDEPT_ID=@Clocid,
				@NMODE=@NMODE,
				@BMULTIPLEMRP=@BMULTIPLEMRP  OUTPUT 

		
		   if isnull(@BMULTIPLEMRP,0)=1
		   begin
		      goto END_PROC
	       end

		   declare @BALLOWNEGSTOCK bit 
		   	SELECT @BALLOWNEGSTOCK=VALUE FROM user_role_det a (NOLOCK)
			JOIN users b (NOLOCK) ON a.role_id=b.role_id
			WHERE USER_CODE=@CUSERCODE 
			AND FORM_NAME='FRMWSLINVOICE' 
			AND FORM_OPTION='ALLOW_NEG_STOCK' 


		  IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE A.SP_ID=@NSPID  AND ISNULL(QUANTITY_IN_STOCK,0)=0 ) and ISNULL (@BALLOWNEGSTOCK,0)=0
			 BEGIN
			     SET @CERRORMSG='BARCODE NOT IN STOCK'
				 UPDATE A SET ERRMSG =' BARCODE NOT IN STOCK'
				 FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE A.SP_ID=@NSPID  AND ISNULL(QUANTITY_IN_STOCK,0)=0 
				 GOTO END_PROC

			END 

			
		   IF ISNULL(@BALLOWNEGSTOCK,0)=1
		   BEGIN
		       
			   UPDATE A SET MRP =B.MRP  FROM WSL_ITEM_DETAILS A (NOLOCK)
			   JOIN SKU_NAMES B (NOLOCK)  ON A.PRODUCT_CODE=B.PRODUCT_CODE 
			   WHERE A.SP_ID=@NSPID AND ISNULL(A.MRP,0)=0


		   END


	END

	--End of Duplicate barcode check 
    
		


	  END TRY
	  
	  BEGIN CATCH
			PRINT 'ENTER CATCH BLOCK'
			SET @CERRORMSG='ERROR IN PROCEDURE SP3S_GETWSL_DATA_PASTE : STEP #'+@CSTEP+' '+ERROR_MESSAGE()
			GOTO END_PROC 
	  END CATCH

END_PROC:
		PRINT 'LAST STEP:'+@CSTEP

		

			IF @BMULTIPLEMRP=1
			  BEGIN
	       
		 
				   SELECT A.PRODUCT_CODE ,A.BATCH_BARCODE as batch_product_code ,A.SRNO,bin.bin_name ,A.MRP ,'multiple mrp/bin found of this barcode Please Use specific batch barcode in file ' errmsg
				   FROM #TMPMULTIPLEMRP A
				   join bin (nolock) on a.BIN_ID=bin.BIN_ID
				   WHERE PRODUCT_CODE IN(SELECT PRODUCT_CODE FROM #TMPMULTIPLEMRP WHERE SRNO>1 )
				   return
			  END
			  IF EXISTS (SELECT TOP 1 'U'  from WSL_ITEM_DETAILS a (nolock) WHERE A.SP_ID=@NSPID AND ISNULL(errmsg,'')<>'')
			  BEGIN
			       
				   SELECT A.PRODUCT_CODE  ,A.MRP,A.BIN_NAME ,A.BIN_ID ,A.errmsg  from WSL_ITEM_DETAILS a (nolock) WHERE A.SP_ID=@NSPID AND ISNULL(errmsg,'')<>''
				    return
			  END

	
		  IF ISNULL(@BAGAINSTPS,0)=1
		  BEGIN
		   

				SELECT A.PRODUCT_CODE  ,MST.PS_ID,MST.PS_NO,MST.PS_DT ,A.QUANTITY AS INVOICE_QUANTITY,A.QUANTITY,
				       CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN SN.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN SN.PP  ELSE SN.WS_PRICE END AS RATE, 
					   CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN SN.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN SN.PP  ELSE SN.WS_PRICE END AS net_RATE,
					   AMOUNT=(CASE WHEN @NDEFAULT_RATE_TYPE=2 THEN SN.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN SN.PP  ELSE SN.WS_PRICE END)*A.QUANTITY,
					   AMOUNT_MRP=sn.mrp*A.QUANTITY,
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
					   sn.para7_name,sn.Fix_mrp,sn.VENDOR_EAN_NO,@NBOXNO As box_no,@CERRORMSG As Errmsg,
					   (CASE WHEN ISNULL(SN.SN_UOM_TYPE,0) IN(0,1) THEN 1 ELSE SN.SN_UOM_TYPE END) as Uom_type,@Clocid As DEPT_ID,sn.batch_no ,sn.mrp,cast('' as varchar(100)) as batch_Product_code,
					   SN.UOM AS UOM_NAME ,SN.UOM AS UOM_CODE, --All totaling depend Upon uom code
					   a.XNITEMWEIGHT,a.emp_code,a.emp_code1,a.emp_code2,
					   EMP.EMP_NAME,EMP1.EMP_NAME AS EMP1_NAME,EMP2.EMP_NAME AS EMP2_NAME,sn.ws_price ,SN.SN_ARTICLE_PACK_SIZE as ARTICLE_PACK_SIZE
				FROM WPS_DET  A (NOLOCK)
				JOIN WPS_MST MST (NOLOCK) ON A.PS_ID=MST.PS_ID 
				JOIN WSL_PSID B ON A.PS_ID=B.PS_ID 
				JOIN SKU_NAMES SN (NOLOCK) ON SN.PRODUCT_CODE =A.PRODUCT_CODE 
				LEFT OUTER JOIN EMPLOYEE EMP (NOLOCK) ON a.EMP_CODE= EMP.EMP_CODE    
				LEFT OUTER JOIN EMPLOYEE EMP1 (NOLOCK) ON a.EMP_CODE1= EMP1.EMP_CODE    
				LEFT OUTER JOIN EMPLOYEE EMP2 (NOLOCK) ON a.EMP_CODE2= EMP2.EMP_CODE    
				WHERE B.SP_ID=@NSPID

				delete from WSL_PSID where SP_ID=@NSPID
				RETURN

		    END
			else
			begin

			  	SELECT SN.PRODUCT_CODE ,quantity  AS INVOICE_QUANTITY,quantity QUANTITY,
				       CASE WHEN @NPASTE=1 and rate<>0 THEN a.rate WHEN @NDEFAULT_RATE_TYPE=2 THEN a.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN SN.PP  ELSE SN.WS_PRICE END  AS RATE,
					   CASE WHEN @NPASTE=1 and NET_RATE<>0 THEN a.NET_RATE WHEN @NDEFAULT_RATE_TYPE=2 THEN a.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN SN.PP  ELSE SN.WS_PRICE END AS NET_RATE,
					   AMOUNT=(CASE WHEN @NPASTE=1 and rate<>0 THEN a.rate WHEN @NDEFAULT_RATE_TYPE=2 THEN a.MRP WHEN @NDEFAULT_RATE_TYPE=3 THEN SN.PP  ELSE SN.WS_PRICE END)*quantity,
					   AMOUNT_MRP=a.MRP*quantity,
				       a.BIN_ID ,a.QUANTITY_IN_STOCK,
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
					   (CASE WHEN ISNULL(SN.SN_UOM_TYPE,0) IN(0,1) THEN 1 ELSE SN.SN_UOM_TYPE END) as Uom_type,@Clocid As DEPT_ID,a.row_id,
					   sn.batch_no ,a.mrp,cast('' as varchar(100)) as batch_Product_code,
					   SN.UOM AS UOM_NAME ,SN.UOM AS UOM_CODE, --All totaling depend Upon uom code
					   a.manual_rate,a.manual_net_rate,a.manual_discount,a.DISCOUNT_PERCENTAGE ,a.DISCOUNT_AMOUNT ,
					   sn.boxWeight as XNITEMWEIGHT,a.BO_DET_ROW_ID,sn.ws_price ,SN.SN_ARTICLE_PACK_SIZE as ARTICLE_PACK_SIZE
				FROM wsl_item_details a
				join SKU_NAMES  SN (NOLOCK) on a.PRODUCT_CODE=sn.product_Code
				WHERE a.sp_id=@NSPID

           end
	 
	  
	  		
END
------------- END OF PROCEDURE SP3S_GETWSL_DATA