CREATE PROCEDURE SP_CHECKSTOCK_BATCH_PASTE    
 @CPRODUCTCODE VARCHAR(50), 	--SP_ID PASSED IN PRODUCT CODE    
 @BDONOTCHECKSTOCK BIT=0,    
 @CBINID  VARCHAR(7)='', 
 @CWHERE VARCHAR(40)='',  
 @NQTY NUMERIC(14,0)=1,  
 @CUSERCODE VARCHAR(10),
 @XN_ITEM_TYPE NUMERIC(2,0)=1,
 @CDEPT_ID VARCHAR(2),
 @NentryMode numeric(2,0)=0

AS    
BEGIN    
	 DECLARE @NSTKQTY NUMERIC(10,3),@CPRDCODE VARCHAR(100),@CLOC_ID  VARCHAR(5),@CDONOTCHECKSTOCK VARCHAR(5),
	 @BSTOCKNA BIT,@NCNT NUMERIC(3,0),@DEXPIRYDT DATETIME,@CSKUPC VARCHAR(50),
	 @DTSQL NVARCHAR(MAX),@BMULTIPLEMRP BIT 
	 
	
	SET @BMULTIPLEMRP=0

	IF ISNULL(@XN_ITEM_TYPE,0)=0
	SET @XN_ITEM_TYPE=1

	 SELECT TOP 1 @CLOC_ID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 

	 UPDATE A SET ERRMSG='1-SELECTED BARCODE NOT FOUND....PLEASE CHECK' 
	 FROM WSL_ITEM_DETAILS A (NOLOCK)
	 LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.product_code 
	 WHERE B.PRODUCT_CODE IS NULL
	 AND A.sp_id =RTRIM(LTRIM(@CPRODUCTCODE))
	 
	 IF @@ROWCOUNT >0
	    GOTO END_PROC
	 
	 UPDATE A SET ERRMSG='2-INVOICE QTY CAN NOT BE ZERO....PLEASE CHECK' 
	 FROM WSL_ITEM_DETAILS A (NOLOCK)
	 WHERE A.SP_ID =RTRIM(LTRIM(@CPRODUCTCODE))
	 AND ISNULL(A.INVOICE_QUANTITY ,0)=0
	 
	 IF @@ROWCOUNT >0
	    GOTO END_PROC
	 
	UPDATE WSL_ITEM_DETAILS SET ER_FLAG =1 WHERE ISNULL(ER_FLAG,0)=0 AND SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
	    
    UPDATE A SET ERRMSG=CASE WHEN A.ER_FLAG=1 THEN  'REGULAR INVOICE  CAN NOTE SCAN ESTMATE BARCODE PLEASE CHECK ' 
			 ELSE 'ESTMATE INVOCE  CAN NOTE SCAN REGULAR BARCODE PLEASE CHECK '  END 
   FROM WSL_ITEM_DETAILS A (NOLOCK)
   JOIN SKU (NOLOCK) ON A.PRODUCT_CODE =SKU.PRODUCT_CODE 
   WHERE A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND CASE WHEN SKU.ER_FLAG IN (0,1) THEN 1 ELSE 2 END<>A.ER_FLAG

   IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND ISNULL(ERRMSG,'')<>'')
	  GOTO END_PROC

	 UPDATE ITEM SET ERRMSG=CASE WHEN  @XN_ITEM_TYPE=1 AND D.sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN INVENTORY TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=1 AND D.sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=1 AND D.sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'
	                     
	                     WHEN  @XN_ITEM_TYPE=2 AND D.sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=2 AND D.sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=2 AND D.sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'
	                     
	                     WHEN  @XN_ITEM_TYPE=3 AND D.sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=3 AND D.sku_item_type=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=3 AND D.sku_item_type=4 THEN 'SERVICE    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'
	                     
	                     
	                     WHEN  @XN_ITEM_TYPE=4 AND D.sku_item_type=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=4 AND D.sku_item_type=2 THEN 'CONSUMBLE  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=4 AND D.sku_item_type=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN SERVICE   TRANSCTION '
						 ELSE '' END
	 FROM WSL_ITEM_DETAILS ITEM
	 JOIN SKU_names d(NOLOCK) ON d.product_code=ITEM.product_code
	 WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
	 AND CASE WHEN ISNULL(D.sku_item_type,0) IN (0,1) THEN 1 ELSE D.sku_item_type END <>ISNULL(@XN_ITEM_TYPE,1)

	   IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND ISNULL(ERRMSG,'')<>'')
	      GOTO END_PROC
     
	 
	
		 --** new Process has been Implementd as discuss with sir User Import file (barcode,(barcode+mrp),(barcode+bin_id),barcode,bin_id,mrp))

	IF @XN_ITEM_TYPE<>5 
	BEGIN

	
	   SELECT PRODUCT_CODE,PRODUCT_CODE As BATCH_BARCODE,
	             cast('' as varchar(7)) as BIN_ID,
				 CAST(0 AS NUMERIC(14,3)) AS MRP,SRNO=CAST(0 AS NUMERIC(5,0)),
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
		 WHERE A.BIN_NAME<>'' AND ISNULL(A.BIN_ID,'')='' AND A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))

		 Declare @NMODE numeric(1,0)
		 set @NMODE=0

		 	     
		 IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)=0 and  ISNULL(A.BIN_ID,'')='' AND A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)))
		 BEGIN
		     set @NMODE=1
			
		 END
		 ELSE IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)=0 and  ISNULL(A.BIN_ID,'')<>'' AND A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)))
		 BEGIN
		     
			set @NMODE=2


		 END
		 ELSE IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)<>0 and  ISNULL(A.BIN_ID,'')='' AND A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)))
		 BEGIN
		     
			set @NMODE=3

		 END
		 ELSE IF   EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE ISNULL(A.MRP,0)<>0 and  ISNULL(A.BIN_ID,'')<>'' AND A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)))
		 BEGIN
		     
			 set @NMODE=4
			
		 END
		
		  --- This procedure is giving error while calling it from here because of some changes being done in below procedure
		  --- w.r.t. being called from Wholesale paste but not tested it from Pack slip paste .So I am commenting it from now 
		  --- Dinkar will do it when he comes back (Sanjay : 17-01-2024)
		  EXEC SP3S_CHECK_DUPLICATE_BARCODE 
			    @CSP_ID=@CPRODUCTCODE,
				@CUSERCODE=@CUSERCODE,
				@CDEPT_ID=@CDEPT_ID,
				@NMODE=@NMODE,
				@BMULTIPLEMRP=@BMULTIPLEMRP  OUTPUT 



		   if isnull(@BMULTIPLEMRP,0)=1
		    goto END_PROC


			 declare @BALLOWNEGSTOCK bit 
		   	SELECT @BALLOWNEGSTOCK=VALUE FROM user_role_det a (NOLOCK)
			JOIN users b (NOLOCK) ON a.role_id=b.role_id
			WHERE USER_CODE=@CUSERCODE 
			AND FORM_NAME='FRMWSLINVOICE' 
			AND FORM_OPTION='ALLOW_NEG_STOCK' 
            
            IF ISNULL(@BALLOWNEGSTOCK,0)=1
			UPDATE A SET QUANTITY_IN_STOCK=999 FROM  WSL_ITEM_DETAILS A (NOLOCK) WHERE A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) 

		  IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))  AND ISNULL(QUANTITY_IN_STOCK,0)=0 )
			 BEGIN
			     
				 UPDATE A SET ERRMSG =' BARCODE NOT IN STOCK'
				 FROM WSL_ITEM_DETAILS A (NOLOCK) WHERE A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))  AND ISNULL(QUANTITY_IN_STOCK,0)=0 
				 GOTO END_PROC

			END 


	END

	--End of Duplicate barcode check 

	 
	
     DECLARE @CCMD NVARCHAR(MAX),@BPERISHABLE BIT

	
  	
	UPDATE TMP SET ERRMSG='3.BARCODE IS PART OF STOCK RECONCILIATION....PLEASE CHECK' FROM STMH01106 A(NOLOCK) 
	JOIN PMT01106 B(NOLOCK) ON A.REP_ID=B.REP_ID
	JOIN wsl_item_details TMP (NOLOCK) ON TMP.PRODUCT_CODE =B.product_code AND B.BIN_ID =TMP.BIN_ID  
	WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND B.DEPT_ID =@CDEPT_ID 
	 
	 IF @@ROWCOUNT >0
	    GOTO END_PROC
		
	 UPDATE TMP SET STOCK_NA=B.STOCK_NA FROM SKU A (NOLOCK)
	 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE
	 JOIN wsl_item_details TMP (NOLOCK) ON A.product_code =TMP.PRODUCT_CODE 		 
	 WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
	 
	 IF @NQTY=0
		SET @NQTY=1
	
	
	UPDATE A SET errmsg ='4.THIS BATCH OF ITEM EXPIRED ON :'+CONVERT(VARCHAR,B.EXPIRY_DT ,105)+'....PLEASE CHECK' 
	FROM wsl_item_details A (NOLOCK)
	JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.product_code 
	JOIN ARTICLE ART (NOLOCK) ON ART.article_code =B.article_code 
	WHERE ISNULL(ART.PERISHABLE,0)=1
	AND B.EXPIRY_DT <@CWHERE
	AND SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
	
	IF @@ROWCOUNT >0
	    GOTO END_PROC

		
	IF EXISTS (SELECT TOP 1 'U'  FROM wsl_item_details WHERE sp_id=RTRIM(LTRIM(@CPRODUCTCODE)) AND errmsg <>'')
	BEGIN
		GOTO END_PROC
	
	END


	
	
         IF EXISTS (SELECT TOP 1 'U' FROM WSL_ORDER_ID  WHERE  SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND ORDER_ID<>'')
         BEGIN
              
           
              DECLARE @CJOIN VARCHAR(MAX),@CBDJOIN VARCHAR(MAX)
			  SET @CJOIN=''
			  set @CBDJOIN=''

			  IF OBJECT_ID('TEMPDB..#TMPCONFIG','U') IS NOT NULL
			     DROP TABLE #TMPCONFIG

			  SELECT COLUMN_NAME , 
			  CASE WHEN LEFT(COLUMN_NAME,4)='ATTR' THEN  REPLACE(COLUMN_NAME,'KEY_NAME','MST')
			       WHEN LEFT(COLUMN_NAME,4)='PARA' THEN  REPLACE(COLUMN_NAME,'_NAME','')
				   WHEN COLUMN_NAME='ARTICLE_NO' THEN  'ARTICLE'
				   WHEN COLUMN_NAME='SECTION_NAME' THEN  'SECTIONM'
				   WHEN COLUMN_NAME='SUB_SECTION_NAME' THEN  'SECTIOND'
			  ELSE COLUMN_NAME END  AS TABLENAME,
			  CASE WHEN COLUMN_NAME='ARTICLE_NO' THEN  'ARTICLE_CODE'
			       ELSE REPLACE(COLUMN_NAME,'_NAME','_CODE' ) END AS COLUMN_CODE ,
			  CAST('' AS VARCHAR(1000)) AS JOINS,
			  CAST('' AS VARCHAR(1000)) AS BDJOINS
			  INTO #TMPCONFIG
			  FROM CONFIG_BUYERORDER
			  WHERE COLUMN_NAME NOT IN('PRODUCT_CODE','MRP_FROM_TO')
			  AND ISNULL(OPEN_KEY,0)=1

			

			UPDATE A SET JOINS= '  JOIN '+TABLENAME+' (NOLOCK) ON '+TABLENAME+'.'+COLUMN_CODE + 
			CASE WHEN LEFT(TABLENAME,4)='ATTR' THEN '=ARTICLE_FIX_ATTR.'
			ELSE  '=SKU.' END
			+COLUMN_CODE +' '  FROM #TMPCONFIG A
			WHERE LEFT(TABLENAME,4) IN('PARA','ATTR')


			SELECT @CJOIN =ISNULL(@CJOIN+' ','')+JOINS  FROM #TMPCONFIG WHERE JOINS<>''
			UPDATE #TMPCONFIG SET BDJOINS ='SKU'+'.'+COLUMN_CODE + '=isnull(BD.'+COLUMN_CODE+','+'SKU'+'.'+COLUMN_CODE+')'
			SELECT @CBDJOIN =ISNULL(@CBDJOIN+' and  ','')+BDJOINS  FROM #TMPCONFIG 
			
		
			
			IF EXISTS (SELECT TOP 1'U' FROM CONFIG_BUYERORDER WHERE COLUMN_NAME ='MRP_FROM_TO' AND ISNULL(OPEN_KEY,0)=1)
			   SET @CBDJOIN=@CBDJOIN+' and SKU.MRP BETWEEN  BD.From_mrp AND BD.to_mrp '

			   --select @CJOIN,@CBDJOIN
			   --return

             IF  EXISTS (SELECT TOP 1 'U' from WSL_ORDER_ID a (nolock)
			  JOIN BUYER_ORDER_BARCODE_DET B (nolock) ON A.ORDER_ID =B.ORDER_ID 
			  join buyer_order_mst c (nolock) on b.ORDER_ID=c.order_id 
			  where c.cancelled=0 and a.sp_id =RTRIM(LTRIM(STR(@CPRODUCTCODE))) )
			  begin
			  
				  UPDATE A SET BO_DET_ROW_ID=B.REF_ROW_ID,ORDER_ID=B.ORDER_ID  
				   FROM  WSL_ITEM_DETAILS A (nolock)
				   join  BUYER_ORDER_BARCODE_DET b (nolock) on a.PRODUCT_CODE =b.PRODUCT_CODE
				   join buyer_order_mst c (nolock) on b.ORDER_ID=c.order_id 
				   JOIN WSL_ORDER_ID WSL (NOLOCK) ON WSL.ORDER_ID=B.ORDER_ID AND A.SP_ID=WSL.SP_ID
				   where c.cancelled=0  and a.sp_id =RTRIM(LTRIM(STR(@CPRODUCTCODE)))
             
             end
			 else   IF  EXISTS (SELECT TOP 1 'U' from WSL_ORDER_ID a (nolock)
			  JOIN BUYER_ORDER_DET B (nolock) ON A.ORDER_ID =B.ORDER_ID 
			  join buyer_order_mst c (nolock) on b.ORDER_ID=c.order_id 
			  where c.cancelled=0 and a.sp_id =RTRIM(LTRIM(STR(@CPRODUCTCODE))) and isnull(b.product_code,'') <>'' )
			  AND  EXISTS( SELECT TOP 1 'U'    FROM CONFIG_BUYERORDER WHERE COLUMN_NAME='PRODUCT_CODE' AND OPEN_KEY=1)
			  begin
			    
				
				    SET @DTSQL=' UPDATE A SET BO_DET_ROW_ID=BD.ROW_ID ,ORDER_ID=BD.ORDER_ID  
					 FROM  wsl_item_details A
					 JOIN SKU (NOLOCK) ON A.PRODUCT_CODE=SKU.PRODUCT_CODE 
					 JOIN BUYER_ORDER_DET BD (NOLOCK) ON  BD.PRODUCT_CODE=LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))
					  JOIN WSL_ORDER_ID WSL (NOLOCK) ON WSL.ORDER_ID=BD.ORDER_ID AND A.SP_ID=WSL.SP_ID
					 WHERE ISNULL(BD.PRODUCT_CODE,'''')<>'''' AND a.SP_ID='''+RTRIM(LTRIM(STR(@CPRODUCTCODE)))+''' '
					 PRINT @DTSQL
					 EXEC SP_EXECUTESQL @DTSQL
             
			  
			  end 
             else
			 begin
		
	
			    IF OBJECT_ID ('TEMPDB..##TMPBODET','U') IS NOT NULL
				   DROP  TABLE ##TMPBODET

			   DECLARE @CCOLUMNCODE VARCHAR(MAX)
			   SELECT @CCOLUMNCODE =ISNULL(@CCOLUMNCODE+', ','')+COLUMN_CODE+'=NULLIF('+COLUMN_CODE+',''0000000''' +')'  FROM #TMPCONFIG 


		         SET @DTSQL=' SELECT a.product_code,a.inv_qty, a.row_id, A.order_id,a.quantity,'+@CCOLUMNCODE+'
				INTO ##TMPBODET 
				FROM BUYER_ORDER_DET A (NOLOCK)
			    JOIN WSL_ORDER_ID WSL (NOLOCK) ON  A.ORDER_ID =WSL.ORDER_ID 
				WHERE WSL.SP_ID='+RTRIM(LTRIM(STR(@CPRODUCTCODE)))
				exec sp_executesql @DTSQL

	

				UPDATE WSL_ITEM_DETAILS SET ROW_ID=NEWID() where sp_id=RTRIM(LTRIM(STR(@CPRODUCTCODE)))
			  
			    IF OBJECT_ID ('TEMPDB..#TMPWSLITEM','U') IS NOT NULL
				   DROP  TABLE #TMPWSLITEM

				   SELECT * INTO #TMPWSLITEM FROM WSL_ITEM_DETAILS where sp_id=RTRIM(LTRIM(STR(@CPRODUCTCODE)))


				   if object_id ('tempdb..#tmpsku','u') is not null
				      drop table #tmpsku


				   SELECT A.PRODUCT_CODE ,SKU.ARTICLE_CODE  ,SKU.PARA1_CODE ,SKU.PARA2_CODE ,SKU.PARA3_CODE,sku.para4_code ,sku.para5_code,sku.para6_code ,
						  attr1_key_code,attr2_key_code,attr3_key_code,attr4_key_code,attr5_key_code,
						  attr6_key_code,attr7_key_code,attr8_key_code,attr9_key_code,attr10_key_code,
                          attr11_key_code,attr12_key_code,attr13_key_code,attr14_key_code,attr15_key_code,
                          attr16_key_code,attr17_key_code,attr18_key_code,attr19_key_code,attr20_key_code,
                          attr21_key_code ,attr22_key_code,attr23_key_code,attr24_key_code,attr25_key_code,
						  SECTIOND.sub_section_code,SECTIONM.section_code,sku.mrp 
		            into #tmpsku
				   FROM WSL_ITEM_DETAILS A
				   JOIN SKU  ON A.PRODUCT_CODE=sku.PRODUCT_CODE
				   JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE
				   JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE 
				   JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE=SECTIOND.SECTION_CODE 
				   LEFT JOIN ARTICLE_FIX_ATTR (NOLOCK) ON  ARTICLE_FIX_ATTR.ARTICLE_CODE=ARTICLE.ARTICLE_CODE
				   WHERE A.SP_ID=RTRIM(LTRIM(STR(@CPRODUCTCODE)))
				   group by  A.PRODUCT_CODE ,SKU.ARTICLE_CODE  ,SKU.PARA1_CODE ,SKU.PARA2_CODE ,SKU.PARA3_CODE,sku.para4_code ,sku.para5_code,sku.para6_code ,
						  attr1_key_code,attr2_key_code,attr3_key_code,attr4_key_code,attr5_key_code,
						  attr6_key_code,attr7_key_code,attr8_key_code,attr9_key_code,attr10_key_code,
                          attr11_key_code,attr12_key_code,attr13_key_code,attr14_key_code,attr15_key_code,
                          attr16_key_code,attr17_key_code,attr18_key_code,attr19_key_code,attr20_key_code,
                          attr21_key_code ,attr22_key_code,attr23_key_code,attr24_key_code,attr25_key_code,
						  SECTIOND.sub_section_code,SECTIONM.section_code,sku.mrp 



						
				-- AND (BD.quantity-ISNULL(INV_QTY,0))-ISNULL(invoice_quantity,0)>=0 
					--SELECT Article_code,PARA1_CODE,para2_code,* FROM #TMPWSLITEM  A ORDER BY A.article_code,A.PARA1_CODE,A.para2_code

					-- SELECT article_code,PARA1_CODE,para2_code,* FROM #tmpsku A  ORDER BY A.article_code,A.PARA1_CODE,A.para2_code

				DECLARE @CROWID VARCHAR(50)
				WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPWSLITEM)
				BEGIN
				     SELECT TOP 1 @CROWID=ROW_ID FROM #TMPWSLITEM


			     SET @DTSQL=' UPDATE A SET BO_DET_ROW_ID=BD.ROW_ID,ORDER_ID=BD.ORDER_ID  
				 FROM  WSL_ITEM_DETAILS A
				 JOIN #tmpsku sku on a.product_code=sku.product_code 
				 '+@CJOIN +'
				 JOIN ##TMPBODET BD (NOLOCK) ON 1=1
				 '+@CBDJOIN+'
				 WHERE  A.SP_ID='''+RTRIM(LTRIM(STR(@CPRODUCTCODE)))+''' 
				 AND (BD.quantity-ISNULL(INV_QTY,0))-ISNULL(invoice_quantity,0)>=0 
				 and a.row_id='''+@CROWID+'''
				 '
				 PRINT @DTSQL
				 EXEC SP_EXECUTESQL @DTSQL

			--select sku.article_code,sku.para1_code,sku.para2_code, a.product_code, BD.quantity,	ISNULL(bd.INV_QTY,0),
			--ISNULL(invoice_quantity,0), BO_DET_ROW_ID=BD.ROW_ID,ORDER_ID=BD.ORDER_ID  
			--	 FROM  WSL_ITEM_DETAILS A
			--	 JOIN #tmpsku sku on a.product_code=sku.product_code 
			--	    JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE=SKU.PARA1_CODE    JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE=SKU.PARA2_CODE 
			--	 JOIN ##TMPBODET BD (NOLOCK) ON 1=1
			--	  and  SKU.ARTICLE_CODE=isnull(BD.ARTICLE_CODE,SKU.ARTICLE_CODE) and  SKU.PARA1_CODE=isnull(BD.PARA1_CODE,SKU.PARA1_CODE) and  SKU.PARA2_CODE=isnull(BD.PARA2_CODE,SKU.PARA2_CODE)
			--	 WHERE  A.SP_ID='82' 
			--	-- AND (BD.quantity-ISNULL(INV_QTY,0))-ISNULL(invoice_quantity,0)>=0 
			--	 and a.row_id=@CROWID
				 
					
			
				
				    UPDATE A SET INV_QTY=A.INV_QTY+ISNULL(B.INVOICE_QUANTITY,0) FROM ##TMPBODET A
					JOIN WSL_ITEM_DETAILS B ON A.ROW_ID=B.BO_DET_ROW_ID
					WHERE B.ROW_ID=@CROWID
                    
					--PRINT  @CROWID
				    DELETE FROM #TMPWSLITEM WHERE ROW_ID=@CROWID

				 
				 IF EXISTS (SELECT TOP 1 'U' FROM wsl_item_details WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND (ISNULL(BO_DET_ROW_ID,'')='' OR ISNULL(order_id,'')='') and ROW_ID=@CROWID)
				 begin
				      
					 SET @DTSQL=' UPDATE A SET errmsg='' Peinding Order qty''+cast( (isnull(BD.quantity,0)-ISNULL(INV_QTY,0)) as varchar(100))+
					                       ''and invoice qty'' +cast(a.invoice_quantity as varchar(100))
					 FROM  WSL_ITEM_DETAILS A
					 JOIN #tmpsku sku on a.product_code=sku.product_code 
					 '+@CJOIN +'
					 left JOIN ##TMPBODET BD (NOLOCK) ON 1=1
					 '+@CBDJOIN+'
					 WHERE ISNULL(BD.PRODUCT_CODE,'''')='''' AND A.SP_ID='''+RTRIM(LTRIM(STR(@CPRODUCTCODE)))+''' 
					 and a.row_id='''+@CROWID+'''
					 '
					 PRINT @DTSQL
					 EXEC SP_EXECUTESQL @DTSQL

				 end

					


				END


		
             SET @DTSQL=' UPDATE A SET BO_DET_ROW_ID=BD.ROW_ID ,ORDER_ID=BD.ORDER_ID  
             FROM  wsl_item_details A
             JOIN SKU (NOLOCK) ON A.PRODUCT_CODE=SKU.PRODUCT_CODE 
             JOIN BUYER_ORDER_DET BD (NOLOCK) ON  BD.PRODUCT_CODE=LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))
             JOIN WSL_ORDER_ID WSL (NOLOCK) ON WSL.ORDER_ID=BD.ORDER_ID AND A.SP_ID=WSL.SP_ID
             WHERE ISNULL(BD.PRODUCT_CODE,'''')<>'''' AND a.SP_ID='''+RTRIM(LTRIM(STR(@CPRODUCTCODE)))+''' 
			 AND (BD.quantity-ISNULL(INV_QTY,0))-ISNULL(invoice_quantity,0)>0  '
             PRINT @DTSQL
             EXEC SP_EXECUTESQL @DTSQL
             

			 end
             
			
             IF EXISTS (SELECT TOP 1 'U' FROM wsl_item_details WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE)) AND (ISNULL(BO_DET_ROW_ID,'')='' OR ISNULL(order_id,'')=''))
             BEGIN
                   
                    UPDATE A SET errmsg =isnull(errmsg,'')+' Pending Order Qty not available for this barcode' 
					FROM wsl_item_details A (NOLOCK)
					WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
					AND (ISNULL(BO_DET_ROW_ID,'')='' OR ISNULL(order_id,'')='')

					GOTO END_PROC
             END
             
      		
				UPDATE  A SET errmsg ='INVOICE QTY GREATER THAN  ORDER QTY PLEASE CHECK '
				FROM WSL_ITEM_DETAILS A
				JOIN
				(	
				SELECT A.BO_DET_ROW_ID FROM
				(	
		        SELECT A.ORDER_ID , BO_DET_ROW_ID,SUM(invoice_quantity) AS invoice_quantity 
				 FROM WSL_ITEM_DETAILS A
				WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
				GROUP BY  A.ORDER_ID , BO_DET_ROW_ID
				) A
				JOIN BUYER_ORDER_DET BD (NOLOCK) ON BD.row_id =A.BO_DET_ROW_ID
				WHERE invoice_quantity>(BD.quantity-ISNULL(BD.INV_QTY,0))
               ) B ON A.BO_DET_ROW_ID =B.BO_DET_ROW_ID 
			   WHERE SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))


			   IF @@ROWCOUNT >0
			    GOTO END_PROC

  
              
      END 
         

		 lblDetails:
	
	
		  
	
				SELECT TMP.PRODUCT_CODE AS PRODUCT_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, 
				C.PARA1_NAME, D.PARA2_NAME, F.PARA3_NAME, E.UOM_NAME,         
				A.PURCHASE_PRICE,SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
				G.PARA4_NAME,H.PARA5_NAME,I.PARA6_NAME,
				(CASE WHEN ISNULL(E.UOM_TYPE,0) IN(0,1) THEN 1 ELSE ISNULL(E.UOM_TYPE,0) END) AS [UOM_TYPE],      
				B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],A.DT_CREATED AS [SKU_DT_CREATED],      
				B.STOCK_NA,(CASE  WHEN @CPRDCODE=@CPRODUCTCODE THEN '' ELSE @CPRODUCTCODE END) AS EAN,  
				cast('' as varchar(20)) FORM_NAME,cast(0 as int) TAX_PERCENTAGE , A.PRODUCT_NAME,(CASE WHEN ISNULL(A.ER_FLAG,0)=0 THEN 1 ELSE A.ER_FLAG END) AS ER_FLAG,
				LM.AC_NAME,A.INV_DT,A.RECEIPT_DT ,B.ALIAS AS [ARTICLE_ALIAS],'' AS [WIP_UID],
				(A.PURCHASE_PRICE+ISNULL(SKU_OH.TAX_AMOUNT,0)+ ISNULL(SKU_OH.OTHER_CHARGES,0) +   
				ISNULL(SKU_OH.ROUND_OFF,0) + ISNULL(SKU_OH.FREIGHT,0)- ISNULL(SKU_OH.DISCOUNT_AMOUNT,0) +
				ISNULL(SKU_OH.EXCISE_DUTY_AMOUNT,0)) AS LANDED_COST,A.ONLINE_PRODUCT_CODE AS ONLINE_BAR_CODE,
				A.VENDOR_EAN_NO,(CASE WHEN ISNULL(A.HSN_CODE,'')='' THEN B.HSN_CODE ELSE A.HSN_CODE END) AS HSN_CODE,
				SM.ITEM_TYPE,B.UOM_CODE,'0000000' as FORM_ID,
				(case when tmp.mrp =0 then  A.MRP else tmp.mrp end ) as Mrp,
				A.WS_PRICE,LM.AC_CODE ,
				B.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE,A.PARA4_CODE,A.PARA5_CODE,A.PARA6_CODE,B.PARA1_SET,B.PARA2_SET ,ISNULL(A.FIX_MRP,0) AS [FIX_MRP],
				TMP.INVOICE_QUANTITY AS QUANTITY,TMP.BIN_ID
				,tmp.ORDER_ID 
				,B.ARTICLE_CODE AS PACKSLIP_ARTICLE_CODE
				,A.PARA1_CODE AS PACKSLIP_PARA1_CODE
				,A.PARA2_CODE AS PACKSLIP_PARA2_CODE
				,TMP.BO_DET_ROW_ID
				,(CASE WHEN a.ws_price<>0 THEN a.ws_price ELSE a.mrp END) as RATE,
				isnull(ad.boxWeight,b.boxWeight) as XNITEMWEIGHT,A.barcode_coding_scheme,A.barcode_coding_scheme as coding_scheme,tmp.pick_list_row_id,
				tmp.QUANTITY_IN_STOCK,b.sub_section_code
				FROM SKU A   (NOLOCK)     
				JOIN wsl_item_details TMP (NOLOCK) ON A.product_code =TMP.PRODUCT_CODE 
				LEFT OUTER JOIN SKU_OH  (NOLOCK) ON SKU_OH.PRODUCT_CODE=A.PRODUCT_CODE    								
				JOIN ARTICLE B  (NOLOCK) ON A.ARTICLE_CODE = B.ARTICLE_CODE        
				JOIN SECTIOND SD  (NOLOCK) ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
				JOIN SECTIONM SM  (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE      
				JOIN PARA1 C  (NOLOCK) ON A.PARA1_CODE = C.PARA1_CODE        
				JOIN PARA2 D  (NOLOCK) ON A.PARA2_CODE = D.PARA2_CODE        
				JOIN PARA3 F  (NOLOCK) ON A.PARA3_CODE = F.PARA3_CODE        
				JOIN PARA4 G  (NOLOCK) ON A.PARA4_CODE = G.PARA4_CODE        
				JOIN PARA5 H  (NOLOCK) ON A.PARA5_CODE = H.PARA5_CODE        
				JOIN PARA6 I  (NOLOCK) ON A.PARA6_CODE = I.PARA6_CODE     
				JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE = A.AC_CODE         
				LEFT OUTER JOIN UOM E  (NOLOCK) ON B.UOM_CODE = E.UOM_CODE 
				LEFT JOIN art_det Ad (nolock) on ad.article_code =a.article_code and ad.para2_code =a.para2_code and isnull(ad.boxWeight,0)<>0
			    where  SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
				
					
		
	  END_PROC:


	
	  IF @BMULTIPLEMRP=1
	  BEGIN
	       
		 
		   SELECT A.PRODUCT_CODE ,A.BATCH_BARCODE as batch_product_code ,A.SRNO,bin.bin_name ,A.MRP ,'multiple mrp/bin found of this barcode Please Use specific batch barcode in file ' errmsg
		   FROM #TMPMULTIPLEMRP A
		   join bin (nolock) on a.BIN_ID=bin.BIN_ID
		   WHERE PRODUCT_CODE IN(SELECT PRODUCT_CODE FROM #TMPMULTIPLEMRP WHERE SRNO>1 )

	  END
	  ELSE
	  BEGIN

			IF EXISTS (SELECT TOP 1 'U'  FROM wsl_item_details WHERE sp_id=RTRIM(LTRIM(@CPRODUCTCODE)) AND errmsg <>'')
			BEGIN
	

	    
				SELECT A.PRODUCT_CODE ,ART.article_no ,errmsg 
				FROM wsl_item_details A (NOLOCK)
				left JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.product_code 
				left JOIN ARTICLE ART (NOLOCK) ON ART.article_code =B.article_code 
				WHERE A.ERRMSG<>'' AND A.SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))
		
	
			END

 	END
 	DELETE FROM WSL_ORDER_ID WHERE  SP_ID=RTRIM(LTRIM(@CPRODUCTCODE))	 
	  
END  
--END OF PROCEDURE - SP_CHECKSTOCK_BATCHnew1
