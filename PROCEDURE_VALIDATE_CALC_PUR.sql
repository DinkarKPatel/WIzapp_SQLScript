CREATE PROCEDURE VALIDATE_CALC_PUR
@CXNID VARCHAR(50) = ''
--WITH ENCRYPTION

AS
BEGIN
	
	DECLARE @CPIMTABLE TABLE 
		(			
			MRR_ID					VARCHAR(22), 
			MRR_NO					VARCHAR(10), 
			CANCELLED				BIT, 
			SUBTOTAL				NUMERIC(14,2), 
			SUBTOTAL_ERROR			VARCHAR(500),
		    DISCOUNT_PERCENTAGE		NUMERIC(10,2), 
			DISCOUNT_AMOUNT			NUMERIC(10,2),
			DISCOUNT_AMOUNT_ERROR	VARCHAR(500),
			TAX_AMOUNT				NUMERIC(10,2), 
			TAX_AMOUNT_ERROR		VARCHAR(500),
			FREIGHT					NUMERIC(10,2), 
			OTHER_CHARGES			NUMERIC(10,2),
		    EXCISE_DUTY_ERROR		NUMERIC(10,2),
			ROUND_OFF				NUMERIC(10,2), 
			ROUND_OFF_ERROR			VARCHAR(500),
			TOTAL_AMOUNT			NUMERIC(14,2),
			TOTAL_AMOUNT_ERROR		VARCHAR(500),
		    BILL_LEVEL_TAX_METHOD	NUMERIC(5) 
		)
	
	DECLARE @CPIDTABLE TABLE 
		( 
			MRR_ID					VARCHAR(22), 
			PRODUCT_CODE			VARCHAR(50), 
			GROSS_PURCHASE_PRICE	NUMERIC(10,2),
			DISCOUNT_PERCENTAGE		NUMERIC(10,2),		
			DISCOUNT_AMOUNT			NUMERIC(10,2),
			PURCHASE_PRICE			NUMERIC(10,2),
			PURCHASE_PRICE_ERROR	VARCHAR(500),
			INVOICE_QUANTITY		NUMERIC(10,3),
			TAX_PERCENTAGE			NUMERIC(10,2),
			TAX_AMOUNT				NUMERIC(10,2),
			TAX_AMOUNT_ERROR		VARCHAR(500)
		)
	 
	DECLARE @ERRORLIST TABLE
		(
			ERROR_COLUMN			VARCHAR(100),
			ERROR_COLUMN_VALUE		NUMERIC(12,3),
			ERROR_MSG				VARCHAR(500),
			MRR_ID					VARCHAR(50)
		)
	
	INSERT @CPIMTABLE
	SELECT	A.MRR_ID, A.MRR_NO, A.CANCELLED, 
			A.SUBTOTAL, 
			CASE WHEN A.SUBTOTAL = ISNULL(B.SUBTOTAL,0) THEN 
				'OK' 
			ELSE 
				'MISMATCH BETWEEN ITEM WISE TOTAL ('+ LTRIM(RTRIM(STR(ISNULL(B.SUBTOTAL,0),10,2))) +') AND BILL LEVEL SUBTOTAL ('+ LTRIM(RTRIM(STR(ISNULL(A.SUBTOTAL,0),10,2))) +').'
			END AS SUBTOTAL_ERROR,
			
			A.DISCOUNT_PERCENTAGE, A.DISCOUNT_AMOUNT,
			CASE WHEN A.DISCOUNT_AMOUNT = ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2) THEN 'OK' 
			ELSE 
				'MISMATCH BETWEEN EXPECTED DISCOUNT AMOUNT ('+ LTRIM(RTRIM(STR(ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2),10,2))) +') AND UPDATED DISCOUNT AMOUNT ('+ LTRIM(RTRIM(STR(A.DISCOUNT_AMOUNT,10,2))) +').' 
			END AS DISCOUNT_AMOUNT_ERROR,
			
			A.TAX_AMOUNT,
			CASE WHEN A.TAX_AMOUNT = ISNULL(B.TAX_AMOUNT,0) THEN 
				'OK'  
			ELSE
				'MISMATCH BETWEEN ITEM WISE TAX AMOUNT ('+ LTRIM(RTRIM(STR(ISNULL(B.TAX_AMOUNT,0),10,2))) +') AND BILL LEVEL TOTAL TAX AMOUNT ('+ LTRIM(RTRIM(STR(ISNULL(A.TAX_AMOUNT,0),10,2))) +').'
			END AS TAX_AMOUNT_ERROR,
			
			A.FREIGHT, A.OTHER_CHARGES, A.EXCISE_DUTY_AMOUNT,
			
			A.ROUND_OFF, 
			CASE WHEN ROUND_OFF = 
					ROUND(ISNULL(B.SUBTOTAL,0)  
							- ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2)
							+ CASE WHEN A.BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(B.TAX_AMOUNT,0) END
							+ A.FREIGHT + A.OTHER_CHARGES + A.EXCISE_DUTY_AMOUNT,0) 
						-
						(
							ISNULL(B.SUBTOTAL,0)  
							- ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2)
							+ CASE WHEN A.BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(B.TAX_AMOUNT,0) END
							+ A.FREIGHT + A.OTHER_CHARGES + A.EXCISE_DUTY_AMOUNT
						) 
			THEN 'OK' 
			ELSE 
				'MISMATCH BETWEEN EXPECTED ROUND OFF AMOUNT ('+ 
				LTRIM(RTRIM(STR(
									ROUND(ISNULL(B.SUBTOTAL,0)  
									- ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2)
									+ CASE WHEN A.BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(B.TAX_AMOUNT,0) END
									+ A.FREIGHT + A.OTHER_CHARGES + A.EXCISE_DUTY_AMOUNT,0) 
									-
									(
										ISNULL(B.SUBTOTAL,0)  
										- ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2)
										+ CASE WHEN A.BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(B.TAX_AMOUNT,0) END
										+ A.FREIGHT + A.OTHER_CHARGES + A.EXCISE_DUTY_AMOUNT
									) 
									,10,2))) 
				+') AND UPDATED ROUND OFF AMOUNT ('+ LTRIM(RTRIM(STR(A.ROUND_OFF,10,2))) +').'  
			END AS ROUND_OFF_ERROR,
			
			A.TOTAL_AMOUNT, 
			CASE WHEN A.TOTAL_AMOUNT = 
									(
										ROUND(ISNULL(B.SUBTOTAL,0)  
										- ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2)
										+ CASE WHEN A.BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(B.TAX_AMOUNT,0) END
										+ A.FREIGHT + A.OTHER_CHARGES + A.EXCISE_DUTY_AMOUNT,0) 
									)  
			THEN 'OK' 
			ELSE 
				'MISMATCH BETWEEN EXPECTED TOTAL AMOUNT ('+ 
				LTRIM(RTRIM(STR(
									ROUND(ISNULL(B.SUBTOTAL,0)  
									- ROUND(ISNULL(B.SUBTOTAL,0) * A.DISCOUNT_PERCENTAGE / 100,2)
									+ CASE WHEN A.BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(B.TAX_AMOUNT,0) END
									+ A.FREIGHT + A.OTHER_CHARGES + A.EXCISE_DUTY_AMOUNT,0) 
								,10,2))) 
				+') AND UPDATEDTOTAL AMOUNT ('+ LTRIM(RTRIM(STR(A.TOTAL_AMOUNT,10,2))) +').' 
			END AS TOTAL_AMOUNT_ERROR,
			
			A.BILL_LEVEL_TAX_METHOD
			FROM PIM01106 A 
			JOIN 
			(
				SELECT  MRR_ID,SUM(INVOICE_QUANTITY * PURCHASE_PRICE) AS SUBTOTAL,SUM(TAX_AMOUNT) AS TAX_AMOUNT
				FROM PID01106 
				WHERE MRR_ID = CASE WHEN  @CXNID = '' THEN MRR_ID ELSE @CXNID END
				GROUP BY MRR_ID
			)	B ON A.MRR_ID = B.MRR_ID 
			WHERE A.MRR_ID = CASE WHEN  @CXNID = '' THEN A.MRR_ID ELSE @CXNID END
	
	
	
	INSERT @CPIDTABLE 
	SELECT	A.MRR_ID, 
			A.PRODUCT_CODE,
			A.GROSS_PURCHASE_PRICE,
			A.DISCOUNT_PERCENTAGE,
			A.DISCOUNT_AMOUNT, 
			
			A.PURCHASE_PRICE, 
			CASE WHEN  A.PURCHASE_PRICE = A.GROSS_PURCHASE_PRICE - A.DISCOUNT_AMOUNT THEN 'OK' 
			ELSE
				'MISMATCH BETWEEN EXPECTED PURCHASE PRICE ('+ LTRIM(RTRIM(STR(A.GROSS_PURCHASE_PRICE - A.DISCOUNT_AMOUNT,10,2))) +') AND UPDATEDTOTAL PURCHASE PRICE ('+ LTRIM(RTRIM(STR(ISNULL(A.PURCHASE_PRICE,0),10,2))) +').'
			END AS PURCHASE_PRICE_ERROR,
			A.INVOICE_QUANTITY,
			
			A.TAX_PERCENTAGE, 
			A.TAX_AMOUNT,
			
			CASE WHEN BILL_LEVEL_TAX_METHOD = 2 THEN 
				(CASE WHEN A.TAX_AMOUNT = ROUND(((A.INVOICE_QUANTITY * A.PURCHASE_PRICE) -  ( (A.INVOICE_QUANTITY * A.PURCHASE_PRICE) * ISNULL(B.DISCOUNT_PERCENTAGE,0)/100)) *( A.TAX_PERCENTAGE / (100 + A.TAX_PERCENTAGE) ),2) THEN 'OK'
				ELSE 
					'MISMATCH BETWEEN EXPECTED TAX AMOUNT ('+ LTRIM(RTRIM(STR(ROUND(((A.INVOICE_QUANTITY * A.PURCHASE_PRICE) -  ( (A.INVOICE_QUANTITY * A.PURCHASE_PRICE) * ISNULL(B.DISCOUNT_PERCENTAGE,0)/100)) * (A.TAX_PERCENTAGE / (100 + A.TAX_PERCENTAGE)  ),2),10,2)))
					+') AND UPDATEDTOTAL TAX AMOUNT ('+ LTRIM(RTRIM(STR(ISNULL(A.TAX_AMOUNT,0),10,2))) +').'
				END) 
			ELSE
				(CASE WHEN A.TAX_AMOUNT = ROUND(((A.INVOICE_QUANTITY * A.PURCHASE_PRICE) -  ( (A.INVOICE_QUANTITY * A.PURCHASE_PRICE) * ISNULL(B.DISCOUNT_PERCENTAGE,0)/100)) * A.TAX_PERCENTAGE / 100,2) THEN 'OK'
				ELSE 
					'MISMATCH BETWEEN EXPECTED TAX AMOUNT ('+ LTRIM(RTRIM(STR(ROUND(((A.INVOICE_QUANTITY * A.PURCHASE_PRICE) -  ( (A.INVOICE_QUANTITY * A.PURCHASE_PRICE) * ISNULL(B.DISCOUNT_PERCENTAGE,0)/100)) * A.TAX_PERCENTAGE / 100,2),10,2))) +') AND UPDATEDTOTAL TAX
					AMOUNT ('+ LTRIM(RTRIM(STR(ISNULL(A.TAX_AMOUNT,0),10,2))) +').'
				END) 
			END
			AS TAX_AMOUNT_ERROR
	FROM PID01106 A 
			JOIN 
			(
				SELECT  MRR_ID,DISCOUNT_PERCENTAGE,BILL_LEVEL_TAX_METHOD
				FROM PIM01106 
				WHERE MRR_ID = CASE WHEN  @CXNID = '' THEN MRR_ID ELSE @CXNID END
			)	B ON A.MRR_ID = B.MRR_ID 
	WHERE A.MRR_ID = CASE WHEN  @CXNID = '' THEN A.MRR_ID ELSE @CXNID END
	
	--SELECT * FROM @CPIMTABLE
	--SELECT * FROM @CPIDTABLE
	
	DECLARE @SUBTOTAL				NUMERIC(12,2),
			@SUBTOTAL_ERROR			NVARCHAR(500),
			@DISCOUNT_AMOUNT		NUMERIC(12,2),
			@DISCOUNT_AMOUNT_ERROR	NVARCHAR(500),
			@TAX_AMOUNT				NUMERIC(12,2),
			@TAX_AMOUNT_ERROR		NVARCHAR(500),
			@ROUND_OFF				NUMERIC(12,2),
			@ROUND_OFF_ERROR		NVARCHAR(500),
			@TOTAL_AMOUNT			NUMERIC(12,2),
			@TOTAL_AMOUNT_ERROR		NVARCHAR(500),
			@MRRID					NVARCHAR(50),
			@PURCHASE_PRICE			NUMERIC(12,2),
			@PURCHASE_PRICE_ERROR	NVARCHAR(500),
			@PRODUCT_CODE			NVARCHAR(50),
			@INVOICE_QUANTITY		NUMERIC(10,3),
			@ERROR_COLUMN			NVARCHAR(500),
			@ERROR_COLUMN_VALUE		NVARCHAR(500),
			@ERROR_MSG				NVARCHAR(500),
			@MRR_ID					NVARCHAR(50)
	
	
	DECLARE ERRORS CURSOR FOR
	SELECT	SUBTOTAL,SUBTOTAL_ERROR,DISCOUNT_AMOUNT,DISCOUNT_AMOUNT_ERROR
			,TAX_AMOUNT,TAX_AMOUNT_ERROR ,ROUND_OFF,ROUND_OFF_ERROR,TOTAL_AMOUNT,TOTAL_AMOUNT_ERROR,MRR_ID
	FROM @CPIMTABLE
	WHERE	SUBTOTAL_ERROR <> 'OK' OR DISCOUNT_AMOUNT_ERROR <> 'OK' OR TAX_AMOUNT_ERROR <> 'OK'
			OR ROUND_OFF_ERROR <> 'OK' OR TOTAL_AMOUNT_ERROR <> 'OK'
	OPEN ERRORS
	FETCH NEXT FROM ERRORS INTO @SUBTOTAL,@SUBTOTAL_ERROR,@DISCOUNT_AMOUNT,@DISCOUNT_AMOUNT_ERROR
			,@TAX_AMOUNT,@TAX_AMOUNT_ERROR ,@ROUND_OFF,@ROUND_OFF_ERROR,@TOTAL_AMOUNT,@TOTAL_AMOUNT_ERROR,@MRRID
	WHILE @@FETCH_STATUS = 0
	BEGIN
			
			IF(@SUBTOTAL_ERROR <> 'OK')
			BEGIN
				SET @ERROR_COLUMN ='BL : SUBTOTAL'	
				SET @ERROR_COLUMN_VALUE = @SUBTOTAL		
				SET @ERROR_MSG =@SUBTOTAL_ERROR
				INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRRID )
			END
			IF(@DISCOUNT_AMOUNT_ERROR <> 'OK')
			BEGIN
				SET @ERROR_COLUMN ='BL : DISCOUNT_AMOUNT'	
				SET @ERROR_COLUMN_VALUE = @DISCOUNT_AMOUNT		
				SET @ERROR_MSG =@DISCOUNT_AMOUNT_ERROR
				INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRRID )
			END
			IF(@TAX_AMOUNT_ERROR <> 'OK')
			BEGIN
				SET @ERROR_COLUMN ='BL : TAX_AMOUNT'	
				SET @ERROR_COLUMN_VALUE = @TAX_AMOUNT		
				SET @ERROR_MSG =@TAX_AMOUNT_ERROR
				INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRRID )
			END
			IF(@ROUND_OFF_ERROR <> 'OK')
			BEGIN
				SET @ERROR_COLUMN ='BL : ROUND_OFF'	
				SET @ERROR_COLUMN_VALUE = @ROUND_OFF		
				SET @ERROR_MSG =@ROUND_OFF_ERROR
				INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRRID )
			END
			IF(@TOTAL_AMOUNT_ERROR <> 'OK')
			BEGIN
				SET @ERROR_COLUMN ='BL : TOTAL_AMOUNT'	
				SET @ERROR_COLUMN_VALUE = @TOTAL_AMOUNT		
				SET @ERROR_MSG =@TOTAL_AMOUNT_ERROR
				INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRRID )
			END
			
					DECLARE ERRORSD CURSOR FOR
					SELECT	PRODUCT_CODE,INVOICE_QUANTITY,PURCHASE_PRICE,PURCHASE_PRICE_ERROR,TAX_AMOUNT,TAX_AMOUNT_ERROR,MRR_ID
					FROM @CPIDTABLE
					WHERE MRR_ID = @MRRID AND PURCHASE_PRICE_ERROR <> 'OK' OR TAX_AMOUNT_ERROR <> 'OK' 
					OPEN ERRORSD
					FETCH NEXT FROM ERRORSD INTO @PRODUCT_CODE,@INVOICE_QUANTITY,@PURCHASE_PRICE,@PURCHASE_PRICE_ERROR,@TAX_AMOUNT,@TAX_AMOUNT_ERROR ,@MRR_ID
					WHILE @@FETCH_STATUS = 0
					BEGIN
						IF(@PURCHASE_PRICE_ERROR <> 'OK' OR @TAX_AMOUNT_ERROR <> 'OK')
						BEGIN
							INSERT INTO @ERRORLIST VALUES ('PRODUCT_CODE '+ @PRODUCT_CODE, @INVOICE_QUANTITY, '',@MRR_ID )
						END
						IF(@PURCHASE_PRICE_ERROR <> 'OK')
						BEGIN
							SET @ERROR_COLUMN ='IL : PURCHASE_PRICE'	
							SET @ERROR_COLUMN_VALUE = @PURCHASE_PRICE		
							SET @ERROR_MSG =@PURCHASE_PRICE_ERROR
							INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRR_ID )
						END
						
						IF(@TAX_AMOUNT_ERROR <> 'OK')
						BEGIN
							SET @ERROR_COLUMN ='IL : TAX_AMOUNT'	
							SET @ERROR_COLUMN_VALUE = @TAX_AMOUNT		
							SET @ERROR_MSG =@TAX_AMOUNT_ERROR
							INSERT INTO @ERRORLIST VALUES (@ERROR_COLUMN, @ERROR_COLUMN_VALUE, @ERROR_MSG,@MRR_ID )
						END
						
					FETCH NEXT FROM ERRORSD INTO @PRODUCT_CODE,@INVOICE_QUANTITY,@PURCHASE_PRICE,@PURCHASE_PRICE_ERROR,@TAX_AMOUNT,@TAX_AMOUNT_ERROR ,@MRR_ID
					END
					CLOSE ERRORSD
					DEALLOCATE ERRORSD
			
			
	FETCH NEXT FROM ERRORS INTO @SUBTOTAL,@SUBTOTAL_ERROR,@DISCOUNT_AMOUNT,@DISCOUNT_AMOUNT_ERROR
	,@TAX_AMOUNT,@TAX_AMOUNT_ERROR ,@ROUND_OFF,@ROUND_OFF_ERROR,@TOTAL_AMOUNT,@TOTAL_AMOUNT_ERROR,@MRRID
	END
	CLOSE ERRORS
	DEALLOCATE ERRORS
	
	SELECT * FROM @ERRORLIST
END
