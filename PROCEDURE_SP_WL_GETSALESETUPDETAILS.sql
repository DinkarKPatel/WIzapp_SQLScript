

-- RETURNS THE SALES SETUP DETAILS OF GIVEN BARCODE AT GIVEN DATE
CREATE PROCEDURE SP_WL_GETSALESETUPDETAILS
(
	@CPRODUCTCODE   VARCHAR(50),
	@CXNDT			DATETIME
)
--WITH ENCRYPTION
AS 
BEGIN
	DECLARE @CFILTER				NVARCHAR(4000),
			--@CCURFILTER			NVARCHAR(4000),
			@CROWFILTER				NVARCHAR(4000),
			@CCMD					NVARCHAR(4000),
			@DISC_METHOD			NUMERIC(2),
			@DISCOUNT_PERCENTAGE	NUMERIC(10,2), 
			@DISCOUNT_PERCENTAGE2	NUMERIC(10,2),
			@DISCOUNT_PERCENTAGE3	NUMERIC(10,2),
			@EFFECTIVE_DISCOUNT		NUMERIC(10,2),
			@DISCOUNT_AMOUNT		NUMERIC(10,2),
			@NET_PRICE				NUMERIC(10,2),
			@FILTER_MODE			NUMERIC(2),
			@D_FILTER				NVARCHAR(4000),
			@ROW_ID					NVARCHAR(100)

	SET @CFILTER = N''

	SET @CROWFILTER = N' WHERE SKU.PRODUCT_CODE = ''' + @CPRODUCTCODE + ''''

	DECLARE @OUTPUTC TABLE ( DISC_METHOD			NUMERIC(2),
							 DISCOUNT_PERCENTAGE	NUMERIC(10,2), 
							 DISCOUNT_PERCENTAGE2	NUMERIC(10,2),
							 DISCOUNT_PERCENTAGE3	NUMERIC(10,2),
							 EFFECTIVE_DISCOUNT		NUMERIC(10,2),
							 DISCOUNT_AMOUNT		NUMERIC(10,2),
							 NET_PRICE				NUMERIC(10,2),
							 ROW_ID					NVARCHAR(100)
						  )
							 
	DECLARE FILTER_CUR CURSOR FOR
	SELECT  A.DISC_METHOD,A.DISCOUNT_PERCENTAGE,A.DISCOUNT_PERCENTAGE2,A.DISCOUNT_PERCENTAGE3,
			A.DISCOUNT_AMOUNT,A.NET_PRICE,A.FILTER_MODE,A.D_FILTER,A.ROW_ID
	FROM SLSDET A 
	JOIN SLSMST B ON A.SLS_MEMO_NO= B.SLS_MEMO_NO
	WHERE @CXNDT BETWEEN B.SLS_FROM_DT AND B.SLS_TO_DT
	AND A.D_FILTER <> ''
	ORDER BY SLS_ORDER

	OPEN FILTER_CUR

	FETCH NEXT FROM FILTER_CUR INTO @DISC_METHOD, @DISCOUNT_PERCENTAGE, @DISCOUNT_PERCENTAGE2, @DISCOUNT_PERCENTAGE3, 
									@DISCOUNT_AMOUNT, @NET_PRICE, @FILTER_MODE, @D_FILTER, @ROW_ID						
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		
		SET @CFILTER = N' AND  ( ' + @D_FILTER + ' ) '
		PRINT @CFILTER
		SET @CCMD = N'IF NOT OBJECT_ID(''__TEMP'') IS NULL
							DROP TABLE __TEMP
				SELECT SKU.PRODUCT_CODE INTO __TEMP-- , SKU.MRP,SECTIONM.SECTION_NAME, SECTIOND.SUB_SECTION_NAME, LMV01106.AC_NAME
				
				FROM SKU (NOLOCK)
				JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE = ARTICLE.ARTICLE_CODE
				JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE
				JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE = SECTIONM.SECTION_CODE
				JOIN PARA1 (NOLOCK) ON SKU.PARA1_CODE = PARA1.PARA1_CODE
				JOIN PARA2 (NOLOCK) ON SKU.PARA2_CODE = PARA2.PARA2_CODE
				JOIN PARA3 (NOLOCK) ON SKU.PARA3_CODE = PARA3.PARA3_CODE
				JOIN PARA4 (NOLOCK) ON SKU.PARA4_CODE = PARA4.PARA4_CODE
				JOIN PARA5 (NOLOCK) ON SKU.PARA5_CODE = PARA5.PARA5_CODE
				JOIN PARA6 (NOLOCK) ON SKU.PARA6_CODE = PARA6.PARA6_CODE
				JOIN LMV01106 (NOLOCK) ON SKU.AC_CODE = LMV01106.AC_CODE'  +
				@CROWFILTER + (CASE WHEN ISNULL(@D_FILTER,'') <>'' THEN @CFILTER ELSE '' END)
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD

		IF (@@ROWCOUNT>0)
		BEGIN
		SET @EFFECTIVE_DISCOUNT	=ISNULL(@DISCOUNT_PERCENTAGE,0)
		IF(ISNULL(@DISCOUNT_PERCENTAGE2,0)>0)
		SET @EFFECTIVE_DISCOUNT	=@EFFECTIVE_DISCOUNT+((100-@EFFECTIVE_DISCOUNT) * @DISCOUNT_PERCENTAGE2/100)
		IF(ISNULL(@DISCOUNT_PERCENTAGE3,0)>0)
		SET @EFFECTIVE_DISCOUNT	=@EFFECTIVE_DISCOUNT+((100-@EFFECTIVE_DISCOUNT) * @DISCOUNT_PERCENTAGE3/100)

		
			INSERT INTO @OUTPUTC ( DISC_METHOD, DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE2, 
								   DISCOUNT_PERCENTAGE3,EFFECTIVE_DISCOUNT, DISCOUNT_AMOUNT, NET_PRICE, ROW_ID )
						VALUES   ( ISNULL(@DISC_METHOD,0), ISNULL(@DISCOUNT_PERCENTAGE,0), ISNULL(@DISCOUNT_PERCENTAGE2,0), 
								   ISNULL(@DISCOUNT_PERCENTAGE3,0),ISNULL(@EFFECTIVE_DISCOUNT,0), ISNULL(@DISCOUNT_AMOUNT,0), 
								   ISNULL(@NET_PRICE,0), ISNULL(@ROW_ID,'') )
			GOTO END_PROC
		END

		FETCH NEXT FROM FILTER_CUR INTO @DISC_METHOD, @DISCOUNT_PERCENTAGE, @DISCOUNT_PERCENTAGE2, @DISCOUNT_PERCENTAGE3, 
									@DISCOUNT_AMOUNT, @NET_PRICE, @FILTER_MODE, @D_FILTER, @ROW_ID	
	END
	
END_PROC:
	CLOSE FILTER_CUR
	DEALLOCATE FILTER_CUR


	SELECT * FROM @OUTPUTC
END
--*************************************** END OF PROCEDURE SP_WL_GETSALESETUPDETAILS
