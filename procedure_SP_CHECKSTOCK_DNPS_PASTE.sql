create PROCEDURE SP_CHECKSTOCK_DNPS_PASTE
 @CACCODE varchar(10)='',
 @CSPID VARCHAR(50), 
 @BDONOTCHECKSTOCK BIT=0,    
 @CUSERCODE VARCHAR(10),
 @BESTIMATEMODE NUMERIC(1,0)=0,
 @XN_ITEM_TYPE NUMERIC(2,0)=1,
 @cDeptID VARCHAR(10)= '',
 @NPSMODE INT=1
 
-- WITH ENCRYPTION
AS    
BEGIN   
	 DECLARE @NSTKQTY NUMERIC(10,3),@CLOC_ID  VARCHAR(5),@CDONOTCHECKSTOCK VARCHAR(5),
	 @BSTOCKNA BIT,@NCNT NUMERIC(3,0),@DEXPIRYDT DATETIME, @NITEMTYPE NUMERIC(2,0),@CSKUPC VARCHAR(50),@nCodingScheme NUMERIC(1,0),
	 @cBarCodeSeparator VARCHAR(10),@cCHECK_SUPPLIER_DN varchar(10)
	    
		
	
     IF ISNULL(@cDeptID,'')='' 
	    SELECT TOP 1 @CLOC_ID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID
	 ELSE
	    SELECT @CLOC_ID= @cDeptID
	 
    UPDATE PRT_ITEM_DETAILS SET ROW_ID=CAST('LATER'+CAST(NEWID() AS VARCHAR(40)) AS VARCHAR(40))
    WHERE SP_ID=RTRIM(LTRIM(@CSPID))	and isnull(row_id,'')=''

	IF ISNULL(@XN_ITEM_TYPE,0)=0
	SET @XN_ITEM_TYPE=1

	SELECT @cCHECK_SUPPLIER_DN=value  FROM CONFIG WHERE CONFIG_OPTION ='CHECK_SUPPLIER_DN'

	

   UPDATE ITEM SET ERRMSG=CASE WHEN  @XN_ITEM_TYPE=1 AND D.ITEM_TYPE=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN INVENTORY TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=1 AND D.ITEM_TYPE=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=1 AND D.ITEM_TYPE=4 THEN 'SERVICE    ITEM NOT ALLOWED IN INVENTORY TRANSCTION'
	                     
	                     WHEN  @XN_ITEM_TYPE=2 AND D.ITEM_TYPE=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=2 AND D.ITEM_TYPE=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=2 AND D.ITEM_TYPE=4 THEN 'SERVICE    ITEM NOT ALLOWED IN CONSUMBLE TRANSCTION'
	                     
	                     WHEN  @XN_ITEM_TYPE=3 AND D.ITEM_TYPE=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=3 AND D.ITEM_TYPE=2 THEN 'CONSUMABLE ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=3 AND D.ITEM_TYPE=4 THEN 'SERVICE    ITEM NOT ALLOWED IN ASSESTS   TRANSCTION'
	                     
	                     
	                     WHEN  @XN_ITEM_TYPE=4 AND D.ITEM_TYPE=1 THEN 'INVENTORY  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=4 AND D.ITEM_TYPE=2 THEN 'CONSUMBLE  ITEM NOT ALLOWED IN SERVICE   TRANSCTION'
	                     WHEN  @XN_ITEM_TYPE=4 AND D.ITEM_TYPE=3 THEN 'ASSESTS    ITEM NOT ALLOWED IN SERVICE   TRANSCTION '
						 ELSE '' END
	  FROM PRT_ITEM_DETAILS item
	 JOIN SKU A(NOLOCK) ON A.product_code=ITEM.product_code
	 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE
	 JOIN SECTIOND C(NOLOCK) ON C.SUB_SECTION_CODE=B.SUB_SECTION_CODE
	 JOIN SECTIONM D(NOLOCK) ON D.SECTION_CODE=C.SECTION_CODE
	 WHERE SP_ID=RTRIM(LTRIM(@CSPID))
	 AND CASE WHEN ISNULL(D.ITEM_TYPE,0) IN (0,1) THEN 1 ELSE D.ITEM_TYPE END <>ISNULL(@XN_ITEM_TYPE,1)

	   IF EXISTS (SELECT TOP 1 'U' FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND ISNULL(ERRMSG,'')<>'')
	   GOTO END_PROC

	 

	 UPDATE A SET ERRMSG ='BARCODE NOT FOUND' FROM PRT_ITEM_DETAILS A
	 LEFT JOIN SKU (NOLOCK) ON A.PRODUCT_CODE =SKU.PRODUCT_CODE 
	 WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND SKU.PRODUCT_CODE IS NULL


	 IF EXISTS (SELECT TOP 1 'U' FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND ISNULL(ERRMSG,'')<>'')
	  GOTO END_PROC


	 IF ISNULL(@CCHECK_SUPPLIER_DN,'')=1 AND @NPSMODE=1
	BEGIN
	     
		 UPDATE A SET ERRMSG =CASE WHEN B.AC_CODE <>@CACCODE AND B.BARCODE_CODING_SCHEME <>1 THEN 
		 'NO PURCHASE DETAILS FOUND FOR THE BARCODE AGAINST THE SELECTED SUPPLIER.TRY AGAINST OTHER SUPPLIERS.'  ELSE '' END 
		 FROM PRT_ITEM_DETAILS A (NOLOCK)
		 LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE 
		 WHERE A.SP_ID =RTRIM(LTRIM(@CSPID))

		  IF EXISTS (SELECT TOP 1 'U' FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND ISNULL(ERRMSG,'')<>'')
	     GOTO END_PROC

	END


   UPDATE A SET ERRMSG=CASE WHEN @BESTIMATEMODE=1 THEN  'REGULAR INVOICE  CAN NOTE SCAN ESTMATE BARCODE PLEASE CHECK ' 
			 ELSE 'ESTMATE INVOCE  CAN NOTE SCAN REGULAR BARCODE PLEASE CHECK '  END 
   FROM PRT_ITEM_DETAILS A (NOLOCK)
   JOIN SKU (NOLOCK) ON A.PRODUCT_CODE =SKU.PRODUCT_CODE 
   WHERE A.SP_ID=RTRIM(LTRIM(@CSPID)) AND CASE WHEN SKU.ER_FLAG IN (0,1) THEN 1 ELSE 2 END<>@BESTIMATEMODE
   
    IF EXISTS (SELECT TOP 1 'U' FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND ISNULL(ERRMSG,'')<>'')
	   GOTO END_PROC
   
  
 
	 
	 IF @BDONOTCHECKSTOCK=0
	 BEGIN
			SELECT TOP 1 @CDONOTCHECKSTOCK =VALUE FROM USER_ROLE_DET A(NOLOCK)
			JOIN USERS B(NOLOCK) ON A.ROLE_ID=B.ROLE_ID
			WHERE USER_CODE=@CUSERCODE --AND USER_CODE<>'0000000'
			AND FORM_NAME='FRMSALE' 
			AND FORM_OPTION='ALLOW_NEG_STOCK'		
			
			IF ISNULL(@CDONOTCHECKSTOCK,'')='1'
				SET @BDONOTCHECKSTOCK = 1
	 END  
	 
	

	IF @BDONOTCHECKSTOCK=0
	BEGIN


			 IF OBJECT_ID('TEMPDB..#TMPNEGSTOCK','U') IS NOT NULL  
			  DROP TABLE #TMPNEGSTOCK  
  
      
			SELECT @CDEPTID AS DEPT_ID, A.PRODUCT_CODE ,A.BIN_ID,A.QUANTITY,  
			CAST(0 AS NUMERIC(10,3)) AS QUANTITY_IN_STOCK  
			INTO #TMPNEGSTOCK  
			FROM  
			(  
			SELECT A.PRODUCT_CODE ,A.BIN_ID  
			,SUM(A.QUANTITY) AS QUANTITY  
			FROM PRT_ITEM_DETAILS A (NOLOCK)  
			WHERE A.SP_ID=@CSPID   
			GROUP BY A.PRODUCT_CODE,A.BIN_ID  
			) A    
		    
			
			UPDATE A SET QUANTITY_IN_STOCK =PMT.QUANTITY_IN_STOCK  FROM #TMPNEGSTOCK A
			JOIN PMT01106 PMT (NOLOCK) ON A.PRODUCT_CODE =PMT.PRODUCT_CODE AND A.DEPT_ID =PMT.DEPT_ID AND A.BIN_ID =PMT.BIN_ID 
			WHERE CHARINDEX('@',A.PRODUCT_CODE)<>0

			
			UPDATE A SET QUANTITY_IN_STOCK =PMT.QUANTITY_IN_STOCK  FROM #TMPNEGSTOCK A
			JOIN 
			(  select LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE ))) as product_code  ,
			        dept_id ,bin_id,sum(quantity_in_stock) as  quantity_in_stock
			   from PMT01106 a (NOLOCK) 
			   WHERE DEPT_ID=@CDEPTID
			   group by LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE ))) ,
			   dept_id ,bin_id
			   
			)pmt ON A.PRODUCT_CODE =PMT.PRODUCT_CODE AND A.DEPT_ID =PMT.DEPT_ID AND A.BIN_ID =PMT.BIN_ID 
			WHERE CHARINDEX('@',A.PRODUCT_CODE)=0
  
  
		  IF ISNULL(@CDONOTCHECKSTOCK,0)=0  
		  BEGIN      
				IF EXISTS (SELECT TOP 1 'U' FROM #TMPNEGSTOCK A WHERE  A.QUANTITY>ISNULL(A.QUANTITY_IN_STOCK,0) )  
				BEGIN  
         
				  UPDATE A SET ERRMSG='QUANTITY GOING NEGATIVE' FROM  PRT_ITEM_DETAILS A  
				  JOIN #TMPNEGSTOCK B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID   
				  JOIN SKU S (NOLOCK) ON S.PRODUCT_CODE =A.PRODUCT_CODE  
				  JOIN ARTICLE ART ON ART.ARTICLE_CODE =S.ARTICLE_CODE  
				  WHERE A.SP_ID=@CSPID AND ISNULL(ART.STOCK_NA ,0)=0  
				   and b.QUANTITY>ISNULL(b.QUANTITY_IN_STOCK,0)  

				END   
         
		 		 IF EXISTS (SELECT TOP 1 'U' FROM PRT_ITEM_DETAILS WHERE ISNULL(ERRMSG,'')<>'' AND SP_ID=@CSPID)  
					GOTO END_PROC  
  
		  END  
   

   END
	

					SELECT TMP.PRODUCT_CODE  AS PRODUCT_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, 
					sn.PARA1_NAME, sn.PARA2_NAME, sn.PARA3_NAME, E.UOM_NAME,         
					A.PURCHASE_PRICE,sn.SECTION_NAME, sn.SUB_SECTION_NAME,      
					SN.PARA4_NAME,SN.PARA5_NAME,SN.PARA6_NAME,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
					B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],A.DT_CREATED AS [SKU_DT_CREATED],      
					B.STOCK_NA,TMP.PRODUCT_CODE  AS EAN,  
					F1.FORM_NAME,F1.TAX_PERCENTAGE , A.PRODUCT_NAME,(CASE WHEN ISNULL(a.ER_FLAG,0)=0 THEN 1 ELSE A.ER_FLAG END) AS ER_FLAG,
					sn.AC_NAME,A.INV_DT,A.RECEIPT_DT ,B.ALIAS AS [ARTICLE_ALIAS],'' AS [WIP_UID],
					(A.PURCHASE_PRICE+ISNULL(SKU_OH.TAX_AMOUNT,0)+ ISNULL(SKU_OH.OTHER_CHARGES,0) +   
					ISNULL(SKU_OH.ROUND_OFF,0) + ISNULL(SKU_OH.FREIGHT,0)- ISNULL(SKU_OH.DISCOUNT_AMOUNT,0) +
					ISNULL(SKU_OH.EXCISE_DUTY_AMOUNT,0)) AS LANDED_COST,A.ONLINE_PRODUCT_CODE AS ONLINE_BAR_CODE,
					A.VENDOR_EAN_NO,(CASE WHEN ISNULL(A.HSN_CODE,'')='' THEN B.HSN_CODE ELSE A.HSN_CODE END) AS HSN_CODE,
					Sn.sku_item_type  ITEM_TYPE,B.UOM_CODE,F1.FORM_ID,A.MRP,A.WS_PRICE,a.AC_CODE ,
					B.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE,A.PARA3_CODE,A.PARA4_CODE,A.PARA5_CODE,A.PARA6_CODE,B.PARA1_SET,B.PARA2_SET ,ISNULL(A.FIX_MRP,0) AS [FIX_MRP],
					SN.PARA1_NAME ,SN.PARA2_NAME,SN.para2_order ,A.INV_NO AS BILL_NO,A.challan_no 
					,B.sub_section_code,@CDEPTID AS DEPT_ID,TMP.ROW_ID ,GETDATE() AS LAST_UPDATE,TMP.PS_ID ,
					0 AS selling_days,0 AS CANCELLED,B.discon ,b.article_desc ,A.ws_price AS WSP,A.barcode_coding_scheme AS CODING_SCHEME,
					'' AS BRAND_NAME,TMP.QUANTITY ,B.dt_created AS  ART_DT_CREATED ,F.dt_created AS PARA3_DT_CREATED,
					'' AS CITY  ,TMP.BIN_ID ,BIN.BIN_NAME ,CAST('' AS VARCHAR(50)) AS SP_ID,
					 TMP.PRODUCT_CODE AS ORG_PRODUCUt_CODE,CAST('' AS VARCHAR(20)) AS BIX_ID
					,ISNULL(SN.ATTR1_KEY_NAME,'') as ATTR1_KEY_NAME   ,ISNULL(SN.ATTR2_KEY_NAME,'')  as ATTR2_KEY_NAME
				    ,ISNULL(SN.ATTR3_KEY_NAME,'') as ATTR3_KEY_NAME  ,ISNULL(SN.ATTR4_KEY_NAME,'') as ATTR4_KEY_NAME
					,ISNULL(SN.ATTR5_KEY_NAME,'') as ATTR5_KEY_NAME,ISNULL(SN.ATTR6_KEY_NAME,'') as ATTR6_KEY_NAME
					,ISNULL(SN.ATTR7_KEY_NAME,'')  ATTR7_KEY_NAME ,ISNULL(SN.ATTR8_KEY_NAME,'')  ATTR8_KEY_NAME
					,ISNULL(SN.ATTR9_KEY_NAME,'')  ATTR9_KEY_NAME ,ISNULL(SN.ATTR10_KEY_NAME,'') ATTR10_KEY_NAME
					,ISNULL(SN.ATTR11_KEY_NAME,'') ATTR11_KEY_NAME,ISNULL(SN.ATTR12_KEY_NAME,'') ATTR12_KEY_NAME
					,ISNULL(SN.ATTR13_KEY_NAME,'') ATTR13_KEY_NAME ,ISNULL(SN.ATTR14_KEY_NAME,'') ATTR14_KEY_NAME
					,ISNULL(SN.ATTR15_KEY_NAME,'') ATTR15_KEY_NAME     
					,ISNULL(SN.ATTR16_KEY_NAME,'') ATTR16_KEY_NAME,ISNULL(SN.ATTR17_KEY_NAME,'') ATTR17_KEY_NAME
					,ISNULL(SN.ATTR18_KEY_NAME,'') ATTR18_KEY_NAME,ISNULL(SN.ATTR19_KEY_NAME,'') ATTR19_KEY_NAME
					,ISNULL(SN.ATTR20_KEY_NAME,'')  ATTR20_KEY_NAME  ,ISNULL(SN.ATTR21_KEY_NAME,'') ATTR21_KEY_NAME
					,ISNULL(SN.ATTR22_KEY_NAME,'') as ATTR22_KEY_NAME,ISNULL(SN.ATTR23_KEY_NAME,'') as ATTR23_KEY_NAME
					,ISNULL(SN.ATTR24_KEY_NAME,'') ATTR24_KEY_NAME,ISNULL(SN.ATTR25_KEY_NAME,'')  ATTR25_KEY_NAME 
					,tmp.ERRMSG 
					FROM SKU A   (NOLOCK)     
					JOIN PRT_ITEM_DETAILS TMP (NOLOCK) ON A.product_code =TMP.PRODUCT_CODE 
					LEFT OUTER JOIN SKU_OH  (NOLOCK) ON SKU_OH.PRODUCT_CODE=A.PRODUCT_CODE    		
					JOIN SKU_NAMES SN (NOLOCK) ON SN.product_Code=A.product_Code 						
					JOIN ARTICLE B  (NOLOCK) ON A.ARTICLE_CODE = B.ARTICLE_CODE          
					JOIN PARA3 F  (NOLOCK) ON A.PARA3_CODE = F.PARA3_CODE              
					LEFT OUTER JOIN UOM E  (NOLOCK) ON B.UOM_CODE = E.UOM_CODE   
					LEFT OUTER JOIN FORM F1  (NOLOCK) ON A.FORM_ID=F1.FORM_ID  
					JOIN BIN (NOLOCK) ON BIN.BIN_ID =TMP.BIN_ID      
					where tmp.SP_ID=RTRIM(LTRIM(@CSPID)) 


 END_PROC:

   IF EXISTS (SELECT TOP 1 'U' FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND ISNULL(ERRMSG,'')<>'')
	BEGIN
	    SELECT *  FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID)) AND ISNULL(ERRMSG,'')<>''

	END
	delete   FROM PRT_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(@CSPID))
 END 

	
 