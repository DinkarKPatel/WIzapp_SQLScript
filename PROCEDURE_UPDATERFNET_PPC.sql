CREATE PROCEDURE UPDATERFNET_PPC
		@CXNTYPE VARCHAR(10),
		@CXNID VARCHAR(40) = '',
		@NSPID INT = 0

		--*** PARAMETERS :
		--*** @CXNTYPE	- TRANSACTION TYPE (MODULE SPECIFIC)
		--*** @CXNID	- TRANSACTION ID ( MEMO ID OF MASTER TABLE )
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CCMD NVARCHAR(4000), 
			@CMEMOID VARCHAR(40), 
			@NSUBTOTAL NUMERIC(14,2),
			@NSUMRFNET NUMERIC(14,2),
			@NSUMRFNETWT NUMERIC(14,2),
			@NTAX NUMERIC(14,2),
			@NINCLTAX NUMERIC(10,2),
			@CROWID VARCHAR(40)

	
	--*** UPDATION OF RFNET FOR PUR
	IF @CXNTYPE IN ('PUR')		-- PURCHASE INVOICE
	BEGIN
		IF @CXNID <> ''
			DECLARE ABC CURSOR FOR SELECT MRR_ID, (TOTAL_AMOUNT) FROM PPC_PIM01106 WHERE MRR_ID = @CXNID 
		ELSE 
		BEGIN
			IF @NSPID <> 0
				DECLARE ABC CURSOR FOR SELECT MRR_ID, (TOTAL_AMOUNT) FROM PPC_PIM01106
				WHERE MRR_ID IN ( SELECT XN_ID FROM XNNOS WHERE XN_TYPE = 'PUR' AND SP_ID = @NSPID )
			ELSE
				DECLARE ABC CURSOR FOR SELECT DISTINCT A.MRR_ID, (B.TOTAL_AMOUNT) FROM PPC_PID01106 A
				JOIN PPC_PIM01106 B ON A.MRR_ID=B.MRR_ID WHERE A.PURCHASE_PRICE<>0 AND ( A.RFNET IS NULL OR A.RFNET = 0 OR A.RFNET_WOTAX IS NULL OR A.RFNET_WOTAX=0) 
		END

		OPEN ABC
		FETCH NEXT FROM ABC INTO @CMEMOID, @NSUBTOTAL
		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'UPDATING RFNET FOR MRR ID : '+@CMEMOID
			
			SELECT TOP 1 @CROWID = ROW_ID FROM PRD_PID01106 WHERE MRR_ID = @CMEMOID

			UPDATE PPC_PID01106 SET RFNET =
			DBO.FN_GETRFNETVALUE( A.PURCHASE_PRICE, A.QUANTITY, B.SUBTOTAL,
			( D.TAX_AMOUNT +B.FREIGHT + B.OTHER_CHARGES + B.ROUND_OFF - B.DISCOUNT_AMOUNT))
			FROM PPC_PID01106 A
			JOIN PPC_PIM01106 B ON A.MRR_ID = B.MRR_ID
			--JOIN 
			--JOIN PPC_SKU C ON C.PRODUCT_UID=A.PRODUCT_UID
			JOIN (SELECT SUM(TAX_AMOUNT) AS TAX_AMOUNT FROM PPC_PID01106 WHERE MRR_ID = @CMEMOID) D ON 1=1			
			WHERE B.MRR_ID = @CMEMOID

			SELECT @NSUMRFNET = SUM(RFNET), @NSUMRFNETWT = SUM(RFNET_WOTAX)
			FROM PPC_PID01106 A WHERE A.MRR_ID = @CMEMOID
			
			
			IF @NSUMRFNET <> @NSUBTOTAL
				UPDATE PRD_PID01106 SET RFNET = RFNET + ( @NSUBTOTAL - @NSUMRFNET ) 
				WHERE MRR_ID = @CMEMOID AND ROW_ID = @CROWID

			

			FETCH NEXT FROM ABC INTO @CMEMOID, @NSUBTOTAL
		END
		CLOSE ABC
		DEALLOCATE ABC
	END				-- END OF PUR
		
	
END
