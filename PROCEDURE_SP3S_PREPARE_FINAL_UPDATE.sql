CREATE PROCEDURE SP3S_PREPARE_FINAL_UPDATE
AS
BEGIN
	DECLARE @DTSQL NVARCHAR(MAX), @CSTEP INT, @CERRMSG NVARCHAR(MAX)
	
	BEGIN TRY

		--PARA1
		SET @CSTEP=10
		UPDATE A1 SET A1.PARA1_NAME = A2.PARA1_NAME FROM PARA1 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_PARA1_UPLOAD A2 (NOLOCK) ON A1.PARA1_CODE = A2.PARA1_CODE
		
		SET @CSTEP=20
		INSERT PARA1 WITH (ROWLOCK)( PARA1_CODE, PARA1_NAME, LAST_UPDATE, ALIAS, INACTIVE, PARA1_ORDER, 
		                  PARA1_SET, REMARKS, BL_PARA1_NAME, LAST_MODIFIED_ON ) 
		SELECT A.PARA1_CODE,A.PARA1_NAME,A.LAST_UPDATE,A.ALIAS,A.INACTIVE,A.PARA1_ORDER,A.PARA1_SET, 
		A.REMARKS,A.BL_PARA1_NAME,A.LAST_MODIFIED_ON
		FROM  MST_COMP_PARA1_UPLOAD A(NOLOCK) 
		LEFT JOIN PARA1 B(NOLOCK) ON 
		A.PARA1_CODE = B.PARA1_CODE WHERE B.PARA1_CODE IS NULL

		--PARA2
		SET @CSTEP=30
		UPDATE A1
		SET A1.PARA2_NAME = A2.PARA2_NAME
		FROM PARA2 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_PARA2_UPLOAD A2(NOLOCK) ON A1.PARA2_CODE = A2.PARA2_CODE
		
		SET @CSTEP=40
		INSERT PARA2 WITH (ROWLOCK) ( LAST_UPDATE,ALIAS,INACTIVE,PARA2_ORDER,PARA2_SET,PARA2_CODE,PARA2_NAME,REMARKS,BL_PARA2_NAME,LAST_MODIFIED_ON )  
        SELECT A.LAST_UPDATE,A.ALIAS,A.INACTIVE,A.PARA2_ORDER,A.PARA2_SET,A.PARA2_CODE,A.PARA2_NAME,A.REMARKS,A.BL_PARA2_NAME,A.LAST_MODIFIED_ON 
        FROM MST_COMP_PARA2_UPLOAD A(NOLOCK) 
		LEFT JOIN PARA2 B(NOLOCK) ON 
		A.PARA2_CODE = B.PARA2_CODE WHERE B.PARA2_CODE IS NULL

		--PARA3
		SET @CSTEP=50
		UPDATE A1
		SET A1.PARA3_NAME = A2.PARA3_NAME
		FROM PARA3 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_PARA3_UPLOAD A2(NOLOCK) ON A1.PARA3_CODE = A2.PARA3_CODE
		
		SET @CSTEP=60
		INSERT PARA3 WITH (ROWLOCK) (PARA3_CODE,PARA3_NAME,LAST_UPDATE,ALIAS,INACTIVE,DT_CREATED,REMARKS,BL_PARA3_NAME,LAST_MODIFIED_ON )  
        SELECT A.PARA3_CODE,A.PARA3_NAME,A.LAST_UPDATE,A.ALIAS,A.INACTIVE,A.DT_CREATED,A.REMARKS,A.BL_PARA3_NAME,A.LAST_MODIFIED_ON 
        FROM MST_COMP_PARA3_UPLOAD A(NOLOCK) 
		LEFT JOIN PARA3 B(NOLOCK) ON 
		A.PARA3_CODE = B.PARA3_CODE WHERE B.PARA3_CODE IS NULL


		--PARA4
		SET @CSTEP=70
		UPDATE A1
		SET A1.PARA4_NAME = A2.PARA4_NAME
		FROM PARA4 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_PARA4_UPLOAD A2 (NOLOCK) ON A1.PARA4_CODE = A2.PARA4_CODE
		
		SET @CSTEP=80
		INSERT PARA4 WITH (ROWLOCK) (PARA4_CODE,PARA4_NAME,LAST_UPDATE,ALIAS,INACTIVE,REMARKS,BL_PARA4_NAME,LAST_MODIFIED_ON )  
        SELECT A.PARA4_CODE,A.PARA4_NAME,A.LAST_UPDATE,A.ALIAS,A.INACTIVE,A.REMARKS,A.BL_PARA4_NAME,A.LAST_MODIFIED_ON 
        FROM MST_COMP_PARA4_UPLOAD A(NOLOCK) 
		LEFT JOIN PARA4 B(NOLOCK) ON 
		A.PARA4_CODE = B.PARA4_CODE WHERE B.PARA4_CODE IS NULL


		--PARA5
		SET @CSTEP=90
		UPDATE A1
		SET A1.PARA5_NAME = A2.PARA5_NAME
		FROM PARA5 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_PARA5_UPLOAD A2 (NOLOCK) ON A1.PARA5_CODE = A2.PARA5_CODE
		
		SET @CSTEP=100
		 INSERT PARA5 WITH (ROWLOCK) (ALIAS,INACTIVE,PARA5_CODE,PARA5_NAME,LAST_UPDATE,REMARKS,BL_PARA5_NAME,LAST_MODIFIED_ON )  
         SELECT A.ALIAS,A.INACTIVE,A.PARA5_CODE,A.PARA5_NAME,A.LAST_UPDATE,A.REMARKS,A.BL_PARA5_NAME,A.LAST_MODIFIED_ON 
          FROM MST_COMP_PARA5_UPLOAD A(NOLOCK) 
		 LEFT JOIN PARA5 B(NOLOCK) ON 
		 A.PARA5_CODE = B.PARA5_CODE WHERE B.PARA5_CODE IS NULL


		--PARA6
		SET @CSTEP=110
		UPDATE A1
		SET A1.PARA6_NAME = A2.PARA6_NAME
		FROM PARA6 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_PARA6_UPLOAD A2 (NOLOCK) ON A1.PARA6_CODE = A2.PARA6_CODE
		
		SET @CSTEP=120
		INSERT PARA6 WITH (ROWLOCK) ( PARA6_CODE,PARA6_NAME,LAST_UPDATE,ALIAS,INACTIVE,REMARKS,BL_PARA6_NAME,LAST_MODIFIED_ON )
		SELECT A.PARA6_CODE,A.PARA6_NAME,A.LAST_UPDATE,A.ALIAS,A.INACTIVE,A.REMARKS,A.BL_PARA6_NAME,A.LAST_MODIFIED_ON 
		FROM MST_COMP_PARA6_UPLOAD A(NOLOCK) 
		 LEFT JOIN PARA6 B(NOLOCK) ON 
		 A.PARA6_CODE = B.PARA6_CODE WHERE B.PARA6_CODE IS NULL


		--SECTIONM
		SET @CSTEP=130
		UPDATE A1
		SET A1.SECTION_NAME = A2.SECTION_NAME
		FROM SECTIONM A1 WITH (ROWLOCK) 
		JOIN MST_COMP_SECTIONM_UPLOAD A2 (NOLOCK) ON A1.SECTION_CODE = A2.SECTION_CODE
		
		 SET @CSTEP=140
		 INSERT SECTIONM WITH (ROWLOCK) 	( SECTION_CODE, SECTION_NAME, LAST_UPDATE, ALIAS, INACTIVE, REMARKS, 
		 BL_SECTION_NAME, TRIAL_DT, LAST_MODIFIED_ON )  
		 SELECT  A.SECTION_CODE, A.SECTION_NAME, A.LAST_UPDATE, A.ALIAS, A.INACTIVE, A.REMARKS, '' AS BL_SECTION_NAME, 
		 '' AS TRIAL_DT, '' AS LAST_MODIFIED_ON FROM MST_COMP_SECTIONM_UPLOAD A(NOLOCK) 
		 LEFT JOIN SECTIONM B(NOLOCK) ON 
		 A.SECTION_CODE = B.SECTION_CODE WHERE B.SECTION_CODE IS NULL
		 

		
		--SECTIOND
		SET @CSTEP=150
		UPDATE A1
		SET A1.SECTION_CODE = A2.SECTION_CODE, A1.SUB_SECTION_NAME = A2.SUB_SECTION_NAME
		
		FROM SECTIOND A1 WITH (ROWLOCK) 
		JOIN MST_COMP_SECTIOND_UPLOAD A2(NOLOCK) ON A1.SUB_SECTION_CODE = A2.SUB_SECTION_CODE
		
		SET @CSTEP=160
		 INSERT SECTIOND WITH (ROWLOCK) 	( SUB_SECTION_NAME, LAST_UPDATE, ALIAS, INACTIVE, MFG_CATEGORY, SECTION_CODE, 
		 SUB_SECTION_CODE, REMARKS, BL_SUB_SECTION_NAME, EXCISABLE, LAST_MODIFIED_ON )  
		 SELECT A.SUB_SECTION_NAME,A.LAST_UPDATE,A.ALIAS,A.INACTIVE,A.MFG_CATEGORY,A.SECTION_CODE,
		 A.SUB_SECTION_CODE,A. REMARKS,'' AS BL_SUB_SECTION_NAME,0 AS  EXCISABLE,'' AS LAST_MODIFIED_ON 
		 FROM MST_COMP_SECTIOND_UPLOAD A(NOLOCK) LEFT JOIN SECTIOND B (NOLOCK) ON A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		 WHERE B.SUB_SECTION_CODE IS NULL

		
		
		
		--ARTICLE
		SET @CSTEP=170
		UPDATE A1
		SET	A1.UOM_CODE = A2.UOM_CODE, A1.CODING_SCHEME = A2.CODING_SCHEME,
			A1.SUB_SECTION_CODE = A2.SUB_SECTION_CODE, A1.ARTICLE_NAME = A2.ARTICLE_NAME, 
			A1.ARTICLE_NO = A2.ARTICLE_NO
		FROM ARTICLE A1 WITH (ROWLOCK) 
		JOIN MST_COMP_ARTICLE_UPLOAD A2(NOLOCK) ON A1.ARTICLE_CODE = A2.ARTICLE_CODE
		
		SET @CSTEP=180
		 INSERT ARTICLE WITH (ROWLOCK) 	( PARA2_CODE, PARA3_CODE, PARA4_CODE, PARA5_CODE, PARA6_CODE, DISCON, WHOLESALE_PRICE, WSP_PERCENTAGE, MIN_PRICE, STOCK_NA, ARTICLE_TYPE, CREATED_ON, ARTICLE_GROUP_CODE, COMPANY_CODE, 
		 GENERATE_BARCODES_WITHARTICLE_PREFIX, ARTICLE_GEN_MODE, ARTICLE_PRD_MODE, ARTICLE_SET_CODE, OH_PERCENTAGE, OH_AMOUNT, FIX_MRP, ENABLE_FIXWT_ENTRY, FIX_WEIGHT, EXP_AMOUNT, SUPP_SPECIFIC, SUPP_AC_CODE, 
		 SUPP_ITEM_CODE, REMARKS, FIX_PRICE_ARTICLE, GROSS_PURCHASE_PRICE, DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, GEN_EAN_CODES, SIZE_CENTER_POINT, SIZE_RATE_DIFF, MANUAL_DISC, MANUAL_WSP, MANUAL_RSP, AREA_WISE_RATE_APPLICABLE,
		  ORDERITEM, BL_ARTICLE_NAME, DO_AMOUNT, DO_PERCENTAGE, EXP_PERCENTAGE, LAST_MODIFIED_ON, ARTICLE_SET_TYPE, STYLE_NO, COLOR_NAME, COLOR_CODE, SIZE, DEBIT_MATERIAL, CODING_SCHEME, LAST_UPDATE, UOM_CODE, ALIAS, MP_PERCENTAGE, 
		  PURCHASE_PRICE, MRP, PARA1_SET, PARA2_SET, INACTIVE, SKU_CODE, DT_CREATED, USER_CODE, EDT_USER_CODE, ARTICLE_CODE, ARTICLE_NO, ARTICLE_NAME, ARTICLE_DESC, SUB_SECTION_CODE, PARA1_CODE ) 
         SELECT A.PARA2_CODE, A.PARA3_CODE, A.PARA4_CODE, A.PARA5_CODE, A.PARA6_CODE, A.DISCON, A.WHOLESALE_PRICE, A.WSP_PERCENTAGE, A.MIN_PRICE, A.STOCK_NA, A.ARTICLE_TYPE, A.CREATED_ON, A.ARTICLE_GROUP_CODE, A.COMPANY_CODE, 
         A.GENERATE_BARCODES_WITHARTICLE_PREFIX, A.ARTICLE_GEN_MODE, A.ARTICLE_PRD_MODE, A.ARTICLE_SET_CODE, A.OH_PERCENTAGE, A.OH_AMOUNT, A.FIX_MRP, A.ENABLE_FIXWT_ENTRY, A.FIX_WEIGHT, A.EXP_AMOUNT, A.SUPP_SPECIFIC, A.SUPP_AC_CODE,
          A.SUPP_ITEM_CODE, A.REMARKS, A.FIX_PRICE_ARTICLE, A.GROSS_PURCHASE_PRICE, A.DISCOUNT_PERCENTAGE, A.DISCOUNT_AMOUNT, A.GEN_EAN_CODES, A.SIZE_CENTER_POINT, A.SIZE_RATE_DIFF, A.MANUAL_DISC, A.MANUAL_WSP, A.MANUAL_RSP, 
          A.AREA_WISE_RATE_APPLICABLE, A.ORDERITEM, A.BL_ARTICLE_NAME, A.DO_AMOUNT, A.DO_PERCENTAGE, A.EXP_PERCENTAGE, A.LAST_MODIFIED_ON, A.ARTICLE_SET_TYPE, A.STYLE_NO, A.COLOR_NAME, A.COLOR_CODE, A.SIZE, A.DEBIT_MATERIAL, 
          A.CODING_SCHEME, A.LAST_UPDATE, A.UOM_CODE, A.ALIAS, A.MP_PERCENTAGE, A.PURCHASE_PRICE, A.MRP, A.PARA1_SET, A.PARA2_SET, A.INACTIVE, A.SKU_CODE, A.DT_CREATED, A.USER_CODE, A.EDT_USER_CODE, A.ARTICLE_CODE, A.ARTICLE_NO,
           A.ARTICLE_NAME, A.ARTICLE_DESC, A.SUB_SECTION_CODE, A.PARA1_CODE 
          FROM MST_COMP_ARTICLE_UPLOAD A(NOLOCK) 
          LEFT JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE
		 WHERE B.ARTICLE_CODE IS NULL

		
		--LM01106
		SET @CSTEP=190
		UPDATE A1
		SET A1.AC_NAME = A2.AC_NAME, A1.HEAD_CODE = A2.HEAD_CODE
		FROM LM01106 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_LM01106_UPLOAD A2(NOLOCK) ON A1.AC_CODE = A2.AC_CODE
		
		--HD01106
		SET @CSTEP=200
		UPDATE A1
		SET A1.HEAD_NAME = A2.HEAD_NAME, A1.MAJOR_HEAD_CODE = A2.MAJOR_HEAD_CODE
		FROM HD01106 A1 WITH (ROWLOCK) 
		JOIN MST_COMP_HD01106_UPLOAD A2 (NOLOCK) ON A1.HEAD_CODE = A2.HEAD_CODE
		
		--FORM
		SET @CSTEP=210
		UPDATE A1
		SET A1.FORM_NAME = A2.FORM_NAME
		FROM FORM A1 WITH (ROWLOCK) 
		JOIN MST_COMP_FORM_UPLOAD A2 (NOLOCK) ON A1.FORM_ID = A2.FORM_ID
		
		--SKU
		SET @CSTEP=220
		UPDATE A1
		SET	A1.FORM_ID = A2.FORM_ID, A1.PARA1_CODE = A2.PARA1_CODE,
			A1.PARA2_CODE = A2.PARA2_CODE, A1.PARA3_CODE = A2.PARA3_CODE,
			A1.PARA4_CODE = A2.PARA4_CODE, A1.PARA5_CODE = A2.PARA5_CODE,
			A1.PARA6_CODE = A2.PARA6_CODE, A1.ARTICLE_CODE = A2.ARTICLE_CODE,
			A1.AC_CODE = A2.AC_CODE, A1.VENDOR_EAN_NO = A2.VENDOR_EAN_NO,
			A1.ONLINE_PRODUCT_CODE = A2.ONLINE_PRODUCT_CODE, A1.DT_CREATED = A2.DT_CREATED
		FROM SKU A1 WITH (ROWLOCK) 
		JOIN MST_COMP_SKU_UPLOAD A2 (NOLOCK) ON A1.PRODUCT_CODE = A2.PRODUCT_CODE
		
		
		---ATTRM---
		SET @CSTEP=230
		UPDATE A1 SET 
		       A1.ATTRIBUTE_NAME = A2.ATTRIBUTE_NAME
		       ,A1.ATTRIBUTE_GROUP=A2.ATTRIBUTE_GROUP
		FROM ATTRM A1 WITH (ROWLOCK) 
		JOIN MST_COMP_ATTRM_UPLOAD A2 (NOLOCK) ON A1.ATTRIBUTE_CODE = A2.ATTRIBUTE_CODE
		
		SET @CSTEP=240
		 INSERT ATTRM WITH (ROWLOCK) 	( ATTRIBUTE_NAME, ATTRIBUTE_GROUP, LAST_UPDATE, COMPANY_CODE, ATTRIBUTE_TYPE, INACTIVE, REMARKS, ATTRIBUTE_ORDER, ATTRIBUTE_CODE, ATTRIBUTE_MODE, MANDATORY, LAST_MODIFIED_ON )  
		 SELECT A.ATTRIBUTE_NAME, A.ATTRIBUTE_GROUP, A.LAST_UPDATE, A.COMPANY_CODE, A.ATTRIBUTE_TYPE, A.INACTIVE, A.REMARKS, A.ATTRIBUTE_ORDER, A.ATTRIBUTE_CODE, A.ATTRIBUTE_MODE,A.MANDATORY, '' AS LAST_MODIFIED_ON 
		 FROM MST_COMP_ATTRM_UPLOAD A(NOLOCK) LEFT JOIN ATTRM B (NOLOCK) ON A.ATTRIBUTE_CODE=B.ATTRIBUTE_CODE
		 WHERE B.ATTRIBUTE_CODE IS NULL

		
		
		---ATTR_KEY----
		SET @CSTEP=250
		UPDATE A1 SET 
		       A1.ATTRIBUTE_CODE = A2.ATTRIBUTE_CODE,
		       A1.KEY_NAME=A2.KEY_NAME
		FROM ATTR_KEY A1 WITH (ROWLOCK) 
		JOIN MST_COMP_ATTR_KEY_UPLOAD A2(NOLOCK) ON A1.KEY_CODE = A2.KEY_CODE
		
	     SET @CSTEP=260
		 INSERT ATTR_KEY WITH (ROWLOCK) 	( ATTRIBUTE_CODE, KEY_CODE, KEY_NAME, LAST_UPDATE, COMPANY_CODE, KEY_ALIAS, INACTIVE, LAST_MODIFIED_ON )  
		 SELECT A.ATTRIBUTE_CODE, A.KEY_CODE, A.KEY_NAME, A.LAST_UPDATE, A.COMPANY_CODE, A.KEY_ALIAS, A.INACTIVE, '' AS LAST_MODIFIED_ON 
		 FROM MST_COMP_ATTR_KEY_UPLOAD A(NOLOCK) LEFT JOIN ATTR_KEY B (NOLOCK) ON A.KEY_CODE=B.KEY_CODE
		 WHERE B.KEY_CODE IS NULL

		
		-- ART_ATTR---
        SET @CSTEP=270
	    DELETE A FROM  ART_ATTR A  WITH (ROWLOCK) JOIN MST_COMP_ART_ATTR_UPLOAD B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE AND A.ATTRIBUTE_CODE=B.ATTRIBUTE_CODE
	    
	    SET @CSTEP=280
		 INSERT ART_ATTR WITH (ROWLOCK)  ( ARTICLE_CODE, ATTRIBUTE_CODE, KEY_CODE, ROW_ID, LAST_UPDATE, COMPANY_CODE, OPEN_KEY_NAME )
         SELECT A.ARTICLE_CODE, A.ATTRIBUTE_CODE, A.KEY_CODE, A.ROW_ID, A.LAST_UPDATE,'01' AS  COMPANY_CODE,
          A.OPEN_KEY_NAME 
         FROM MST_COMP_ART_ATTR_UPLOAD A(NOLOCK)
         JOIN ARTICLE B (NOLOCK)ON A.ARTICLE_CODE=B.ARTICLE_CODE
         
         
        SET @CSTEP=300
		PRINT 'DATA UPDATED SUCCESSFULLY'
		
		--DELETE MIRROR_IMGNOTSYNCH_LOG
		DELETE A FROM MIRROR_IMGNOTSYNCH_LOG A  WITH (ROWLOCK) JOIN MST_COMP_SKU_UPLOAD B (NOLOCK) ON A.PRODUCT_CODE = B.PRODUCT_CODE
		
		PRINT 'RESET ''MIRROR_IMGNOTSYNCH_LOG'' SUCCESSFULLY.'
			
	END TRY  
	BEGIN CATCH  
		SET @CERRMSG='P: SP3S_PREPARE_FINAL_UPDATE, STEP: '+CAST(@CSTEP AS VARCHAR(5))+', MESSAGE: ' + ERROR_MESSAGE()
		GOTO END_PROC  
	END CATCH   

END_PROC:  
	IF  ISNULL(@CERRMSG,'')<>'' 
		SELECT ISNULL(@CERRMSG,'') AS ERRMSG
	ELSE 
		SELECT '' AS ERRMSG
END

---END OF PROCEDURE - SP3S_PREPARE_FINAL_UPDATE
