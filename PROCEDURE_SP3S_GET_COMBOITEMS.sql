CREATE PROCEDURE SP3S_GET_COMBOITEMS
(
	@cXnType	VARCHAR(100)='',
	@cComboType	VARCHAR(100)='',
	@nMode		INT=0
)
AS
BEGIN
	DECLARE @DTALL TABLE (DisplayMember varchar(200), ValueMember varchar(200),XNTYPE	varchar(100),COMBOTYPE varchar(100))
	/* WHOLESALE AND WHOLESALE PACKSLIP */
	IF (@cComboType	='ITEM_TYPE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Inventory' AS DisplayMember,'1' AS ValueMember, @cXnType, 'ITEM_TYPE' WHERE @cXnType	IN ('WSL','WSR','PO','PUR','APP','APR','PRCL')  
		UNION
		SELECT 'Consumable' AS DisplayMember,'2' AS ValueMember, @cXnType, 'ITEM_TYPE'  WHERE @cXnType	IN ('WSL','WSR','PO','PUR','APP','APR','PRCL')  
		UNION
		SELECT 'Assets' AS DisplayMember,'3' AS ValueMember, @cXnType, 'ITEM_TYPE'  WHERE @cXnType	IN ('WSL','WSR','PO','PUR','APP','APR','PRCL')  
		UNION 
		SELECT 'Services' AS DisplayMember,'4' AS ValueMember, @cXnType, 'ITEM_TYPE'  WHERE @cXnType	IN ('WSL','WSR','PO','PUR','PRCL')  
		UNION 
		SELECT 'Repair/Defective' AS DisplayMember,'5' AS ValueMember, @cXnType, 'ITEM_TYPE' WHERE @cXnType	IN ('WSL','PUR')
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'ITEM_TYPE' WHERE @nMode=1

	END
	--ELSE IF (@cXnType	IN ('PO','PUR','APP','APR') AND 	@cComboType	='ITEM_TYPE')
	--BEGIN
	--	INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
	--	SELECT 'Inventory' AS DisplayMember,'1' AS ValueMember, @cXnType, 'ITEM_TYPE' 
	--	UNION
	--	SELECT 'Consumable' AS DisplayMember,'2' AS ValueMember, @cXnType, 'ITEM_TYPE' 
	--	UNION
	--	SELECT 'Assets' AS DisplayMember,'3' AS ValueMember, @cXnType, 'ITEM_TYPE' 
	--	UNION 
	--	SELECT 'Services' AS DisplayMember,'4' AS ValueMember, @cXnType, 'ITEM_TYPE' 
	--	UNION 
	--	SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'ITEM_TYPE'  WHERE @nMODE=1
	--END
	IF (@cComboType	='SUPPLY_TYPE_CODE')
	BEGIN
	/*	B2B/B2C/ SEZWP/S EZWOP/E XP WP/EXP WOP/DE XP	*/
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'B2B' AS DisplayMember,'B2B' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE' WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION
		SELECT 'B2C' AS DisplayMember,'B2C' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE'  WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION
		SELECT 'SEZWP' AS DisplayMember,'SEZWP' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE'  WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION 
		SELECT 'SEZWOP' AS DisplayMember,'SEZWOP' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE'  WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION 
		SELECT 'EXPWP' AS DisplayMember,'EXPWP' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE' WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION 
		SELECT 'EXPWOP' AS DisplayMember,'EXPWOP' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE' WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION 
		SELECT 'DEXP' AS DisplayMember,'DEXP' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE' WHERE @cXnType	IN ('WSL','WSR','SLS','PRT')  
		UNION 
		SELECT 'All' AS DisplayMember,'' AS ValueMember, @cXnType, 'SUPPLY_TYPE_CODE' WHERE @nMode=1

	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='PAYMENT_TYPE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Credit' AS DisplayMember,'4' AS ValueMember, @cXnType, 'PAYMENT_TYPE'  WHERE @cXnType	IN ('WSL')
		UNION
		SELECT 'Cash' AS DisplayMember,'1' AS ValueMember, @cXnType, 'PAYMENT_TYPE'   WHERE @cXnType	IN ('WSL')
		UNION
		SELECT 'Credit Card' AS DisplayMember,'2' AS ValueMember, @cXnType, 'PAYMENT_TYPE'  WHERE @cXnType	IN ('WSL')
		UNION 
		SELECT 'Composit' AS DisplayMember,'5' AS ValueMember, @cXnType, 'PAYMENT_TYPE'  WHERE @cXnType	IN ('WSL')
		UNION
		SELECT 'Credit' AS DisplayMember,'4' AS ValueMember, @cXnType, 'PAYMENT_TYPE'  WHERE @cXnType	IN ('WSR')--1=4
		UNION
		SELECT 'Cash' AS DisplayMember,'1' AS ValueMember, @cXnType, 'PAYMENT_TYPE' WHERE @cXnType	IN ('WSR')--2=1
		UNION
		SELECT 'Credit Card' AS DisplayMember,'2' AS ValueMember, @cXnType, 'PAYMENT_TYPE'  WHERE @cXnType	IN ('WSR')--3=2
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'PAYMENT_TYPE' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR','PUR') AND 	@cComboType	='INV_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Party Invoice' AS DisplayMember,'1' AS ValueMember, @cXnType, 'INV_MODE'   WHERE @cXnType	IN ('WSL')
		UNION
		SELECT 'Branch Invoice' AS DisplayMember,'2' AS ValueMember, @cXnType, 'INV_MODE'  WHERE @cXnType	IN ('WSL')
		UNION 
		SELECT 'Party Credit Note' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'INV_MODE' WHERE @cXnType	IN ('WSR')
		UNION
		SELECT 'Group Credit Note' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'INV_MODE' WHERE @cXnType	IN ('WSR')
		UNION 
		SELECT 'Party Purchase' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'INV_MODE' WHERE @cXnType	IN ('PUR')
		UNION
		SELECT 'Group Purchase' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'INV_MODE' WHERE @cXnType	IN ('PUR')
		UNION
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'INV_MODE' WHERE @nMode=1

	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='ENTRY_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Box Entry' AS DisplayMember,'1' AS ValueMember, @cXnType, 'ENTRY_MODE'  WHERE @cXnType	IN ('WSL')
		UNION 
		SELECT 'Direct' AS DisplayMember,'1' AS ValueMember, @cXnType, 'ENTRY_MODE'  WHERE @cXnType	IN ('WSR')
		UNION 
		SELECT 'Packslip' AS DisplayMember,'2' AS ValueMember, @cXnType, 'ENTRY_MODE' 
		UNION 
		SELECT 'Wholesale Buyer Order' AS DisplayMember,'3' AS ValueMember, @cXnType, 'ENTRY_MODE'   WHERE @cXnType	IN ('WSL')
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'ENTRY_MODE' WHERE @nMode=1
		--UNION 
		--SELECT 'Picklist' AS DisplayMember,'4' AS ValueMember, @cXnType, 'ENTRY_MODE' 
	END
	ELSE IF (@cXnType	IN ('PRT') AND 	@cComboType	='ENTRY_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Box Entry' AS DisplayMember,'3' AS ValueMember, @cXnType, 'ENTRY_MODE'
		UNION 	
		SELECT 'Packslip' AS DisplayMember,'2' AS ValueMember, @cXnType, 'ENTRY_MODE' 
		UNION 
		SELECT 'Performa' AS DisplayMember,'4' AS ValueMember, @cXnType, 'ENTRY_MODE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'ENTRY_MODE' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSR') AND 	@cComboType	='INV_METHOD')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Regular' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'INV_METHOD' 
		UNION 
		SELECT 'Financial' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'INV_METHOD' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PRT') AND 	@cComboType	='INV_METHOD')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Regular' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'INV_METHOD' 
		UNION 
		SELECT 'Financial' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'INV_METHOD' WHERE @nMode IN (1,11)
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'INV_METHOD' WHERE @nMode=11

	END
	ELSE IF (@cXnType	='WSL_PS' AND 	@cComboType	='ENTRY_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Direct' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Against Sales Order' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Against Picklist' AS DisplayMember,'4' AS ValueMember, @cXnType, 'ENTRY_MODE' 
	END
	ELSE IF (@cXnType	IN ('WSL','WSR','PUR','PRT') AND 	@cComboType	='MEMO_TYPE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Regular' AS DisplayMember,'1' AS ValueMember, @cXnType, 'MEMO_TYPE' 
		UNION 
		SELECT 'Estimate' AS DisplayMember,'2' AS ValueMember, @cXnType, 'MEMO_TYPE'
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'MEMO_TYPE'  WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='INV_TYPE')
	BEGIN 
		SELECT 'Regular' AS DisplayMember,'1' AS ValueMember, @cXnType, 'INV_TYPE' 
		UNION 
		SELECT 'Lot' AS DisplayMember,'2' AS ValueMember, @cXnType, 'INV_TYPE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'INV_TYPE'  WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR','PRT') AND 	@cComboType	='TAX_METHOD')
	BEGIN 
		SELECT 'Exclusive' AS DisplayMember,'1' AS ValueMember, @cXnType, 'TAX_METHOD' 
		UNION 
		SELECT 'Inclusive' AS DisplayMember,'2' AS ValueMember, @cXnType, 'TAX_METHOD' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'TAX_METHOD' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='INV_METHOD')
	BEGIN 
		SELECT 'Outstation' AS DisplayMember,'1' AS ValueMember, @cXnType, 'INV_METHOD' 
		UNION 
		SELECT 'Local' AS DisplayMember,'2' AS ValueMember, @cXnType, 'INV_METHOD' 
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='INVOICE_TYPE')
	BEGIN 
		SELECT 'Retail Invoice' AS DisplayMember,'1' AS ValueMember, @cXnType, 'INVOICE_TYPE' 
		UNION 
		SELECT 'Tax Invoice' AS DisplayMember,'2' AS ValueMember, @cXnType, 'INVOICE_TYPE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'INVOICE_TYPE' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='TAX_TYPE')
	BEGIN 
		SELECT 'Bill Level' AS DisplayMember,'1' AS ValueMember, @cXnType, 'TAX_TYPE' 
		UNION 
		SELECT 'Item Level' AS DisplayMember,'2' AS ValueMember, @cXnType, 'TAX_TYPE' 
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='XFER_TYPE')
	BEGIN 
		SELECT 'Invoice' AS DisplayMember,'1' AS ValueMember, @cXnType, 'XFER_TYPE' 
		UNION 
		SELECT 'Stock Transfer' AS DisplayMember,'2' AS ValueMember, @cXnType, 'XFER_TYPE' 
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='DISCOUNT_ON')
	BEGIN 
		SELECT 'MRP' AS DisplayMember,'1' AS ValueMember, @cXnType, 'DISCOUNT_ON' 
		UNION 
		SELECT 'RATE' AS DisplayMember,'2' AS ValueMember, @cXnType, 'DISCOUNT_ON' 
		UNION 
		SELECT 'All' AS DisplayMember,'2' AS ValueMember, @cXnType, 'DISCOUNT_ON' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='TAX_METHOD_OH')
	BEGIN 
		SELECT 'Exclusive' AS DisplayMember,'1' AS ValueMember, @cXnType, 'TAX_METHOD_OH' 
		UNION 
		SELECT 'Inclusive' AS DisplayMember,'2' AS ValueMember, @cXnType, 'TAX_METHOD_OH' 
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='Bill_LEVEL_DISC_METHOD')
	BEGIN 
		SELECT 'RATE' AS DisplayMember,'1' AS ValueMember, @cXnType, 'Bill_LEVEL_DISC_METHOD' 
		UNION 
		SELECT 'MRP' AS DisplayMember,'2' AS ValueMember, @cXnType, 'Bill_LEVEL_DISC_METHOD' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, 'Bill_LEVEL_DISC_METHOD' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR') AND 	@cComboType	='SET_NAV_FILTER_WSL')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Both' AS DisplayMember,'0' AS ValueMember, @cXnType, 'SET_NAV_FILTER_WSL' 
		UNION 
		SELECT 'Party Invoice' AS DisplayMember,'1' AS ValueMember, @cXnType, 'SET_NAV_FILTER_WSL' 
		UNION 
		SELECT 'Group Invoice' AS DisplayMember,'2' AS ValueMember, @cXnType, 'SET_NAV_FILTER_WSL' 
	END
	/* LOCATION MASTER */
	ELSE IF (@cXnType	='LOC' AND 	@cComboType	='AUTO_CALCULATION_OF_ALTERATION_CHARGES')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Donot Open' AS DisplayMember,'0' AS ValueMember ,@cXnType, 'AUTO_CALCULATION_OF_ALTERATION_CHARGES' 
		UNION 
		SELECT 'Open Before Saving' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'AUTO_CALCULATION_OF_ALTERATION_CHARGES' 
		UNION 
		SELECT 'Open After Saving' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'AUTO_CALCULATION_OF_ALTERATION_CHARGES' 
	END
	/* PRT : PURCHASE RETURN */
	ELSE IF (@cXnType	='PRT' AND 	@cComboType	='INV_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Party Debit Note' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'INV_MODE' 
		UNION
		SELECT 'Group Debit Note' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'INV_MODE' 
		UNION
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'INV_MODE' WHERE  @nMode=1
	END
	/* PO */
	
	ELSE IF (@cXnType	IN ('PO') AND 	@cComboType	='ENTRY_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Direct' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Buyer Order(Retail)' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Buyer Order(WSL-FG)' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Buy Plan' AS DisplayMember,'4' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Buyer Order(WSL-RM)' AS DisplayMember,'5' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Quotation' AS DisplayMember,'6' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'ENTRY_MODE' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PO','PUR') AND 	@cComboType	='RECEIVE_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Direct' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'RECEIVE_MODE' 
		UNION 
		SELECT 'Advance Shipment Note (ASN)' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'RECEIVE_MODE' 
		UNION 
		SELECT 'GRN Pack Slip' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'RECEIVE_MODE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'RECEIVE_MODE' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PO','PUR') AND 	@cComboType	='CALCULATE_PP')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'RSP From PP' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'CALCULATE_PP' 
		UNION 
		SELECT 'PP From RSP' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'CALCULATE_PP' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'CALCULATE_PP' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PO','PUR') AND 	@cComboType	='PO_TYPE')
	BEGIN 
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT (CASE WHEN @nMode=1 THEN 'All' ELSE '--NA--' END) AS DisplayMember,'' AS ValueMember ,@cXnType , 'PO_TYPE'
		UNION
		SELECT PO_TYPE AS DisplayMember,PO_TYPE_ID AS ValueMember ,@cXnType , 'PO_TYPE'
		from PO_TYPE_MST 
		WHERE INACTIVE=0
	END
	ELSE IF (@cXnType	IN ('PO','PUR','PRT') AND 	@cComboType	='TAX_METHOD')
	BEGIN 
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Exclusive' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'TAX_METHOD' 
		UNION 
		SELECT 'Inclusive' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'TAX_METHOD' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'TAX_METHOD' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('WSL','WSR','PO','PUR','APP','APR','PRCL') AND 	@cComboType	='STATUS')
	BEGIN 
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Cancelled' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'STATUS'  WHERE @nMode=1
		UNION 
		SELECT 'UnCancelled' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'STATUS'  WHERE @nMode=1
		UNION 
		SELECT 'All' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'STATUS' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PO','PUR') AND 	@cComboType	='DATE_WISE')
	BEGIN 
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'PO Date' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'DATE_WISE'  WHERE @nMode=1
		UNION 
		SELECT 'Expiry Date' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'DATE_WISE'  WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PUR','PRT') AND 	@cComboType	='ENTRY_TYPE')
	BEGIN 
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Bill' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'ENTRY_TYPE' 
		UNION 
		SELECT 'Challan' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'ENTRY_TYPE' 
		UNION 
		SELECT 'All' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'ENTRY_TYPE'  WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PUR') AND 	@cComboType	='AGAINST_PO')
	BEGIN 
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Box' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'AGAINST_PO' 
		UNION 
		SELECT 'Selection' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'AGAINST_PO' 
		UNION 
		SELECT 'Excel' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'AGAINST_PO' 
	END
	ELSE IF (@cXnType	IN ('PUR') AND 	@cComboType	='ENTRY_MODE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Direct' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Against PO - Box' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Against PO - By Selection' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Against PO - Excel' AS DisplayMember,'4' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION 
		SELECT 'Convert Challan To Bill' AS DisplayMember,'5' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION
		SELECT 'Against GRN' AS DisplayMember,'6' AS ValueMember ,@cXnType , 'ENTRY_MODE'-- WHERE @nMode=1
		UNION 
		SELECT 'Convert Parcel To Bill' AS DisplayMember,'7' AS ValueMember ,@cXnType , 'ENTRY_MODE' 
		UNION
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'ENTRY_MODE' WHERE @nMode=1
	END
	ELSE IF (@cXnType	IN ('PUR') AND 	@cComboType	='DT_FLAG')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'GST Date' AS DisplayMember,'4' AS ValueMember ,@cXnType , 'DT_FLAG' 
		UNION 
		SELECT 'MRR Date' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'DT_FLAG' 
		UNION 
		SELECT 'Receipt Date' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'DT_FLAG' 
		UNION 
		SELECT 'Invoice Date' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'DT_FLAG' 
	end
	ELSE IF (@cXnType	IN ('PUR') AND 	@cComboType	='CHALLAN_STATUS')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Pending' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'CHALLAN_STATUS' 
		UNION 
		SELECT 'Converted to Bill' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'CHALLAN_STATUS' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'CHALLAN_STATUS' 
	end
	ELSE IF (@cXnType	IN ('PUR','WSL','PRT','WSR') AND 	@cComboType	='ACCOUNT_STATUS')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Pending' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'ACCOUNT_STATUS' 
		UNION 
		SELECT 'Updated' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'ACCOUNT_STATUS' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'ACCOUNT_STATUS' 
	end
	ELSE IF (@cXnType	IN ('APP','APR') AND 	@cComboType	='MEMO_TYPE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Retail' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'MEMO_TYPE' 
		UNION 
		SELECT 'Wholesale' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'MEMO_TYPE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'MEMO_TYPE'  WHERE @nMode=1
		
	END
	ELSE IF (@cXnType	IN ('APP','APR') AND 	@cComboType	='PARTY_TYPE')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Party' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'PARTY_TYPE' 
		UNION 
		SELECT 'Ledger' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'PARTY_TYPE' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'PARTY_TYPE'  WHERE @nMode=1
		
	END
	ELSE IF (@cXnType	IN ('APP','APR') AND 	@cComboType	='MEMO_STATUS')
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Approval Settled' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'MEMO_STATUS' 
		UNION 
		SELECT 'Partially Settled' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'MEMO_STATUS' 
		UNION 
		SELECT 'Pending Approval' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'MEMO_STATUS' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'MEMO_STATUS'  WHERE @nMode=1
		
	END
	ELSE IF (@cXnType	IN ('WSL') AND 	@cComboType	='DOMESTIC_FOR_EXPORT')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Domestic' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'DOMESTIC_FOR_EXPORT' 
		UNION 
		SELECT 'DirectExport With Payment' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'DOMESTIC_FOR_EXPORT' 
		UNION 
		SELECT 'DirectExport Without Payment' AS DisplayMember,'3' AS ValueMember ,@cXnType , 'DOMESTIC_FOR_EXPORT' 
	end
	ELSE IF (@cXnType	IN ('PRCL') AND 	@cComboType	='PAID_BY')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Paid By Supplier/Customer' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'PAID_BY' 
		UNION 
		SELECT 'Paid By Company' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'PAID_BY' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'PAID_BY'   WHERE @nMode=1
	end
	ELSE IF (@cXnType	IN ('PRCL') AND 	@cComboType	='Parcel_Type')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Linked' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'Parcel_Type' 
		UNION 
		SELECT 'Open' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'Parcel_Type' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'Parcel_Type'   WHERE @nMode=1
	end
	ELSE IF (@cXnType	IN ('PRCL') AND 	@cComboType	='INWORD_XN_TYPE')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Purchase Invoice' AS DisplayMember,'PUR' AS ValueMember ,@cXnType , 'INWORD_XN_TYPE' 
		UNION 
		SELECT 'Wholesale Credit Note' AS DisplayMember,'WSR' AS ValueMember ,@cXnType , 'INWORD_XN_TYPE' 
		UNION 
		SELECT 'GRN' AS DisplayMember,'GRN' AS ValueMember ,@cXnType , 'INWORD_XN_TYPE' 
		UNION 
		SELECT 'Job Work Receipt' AS DisplayMember,'JWR' AS ValueMember ,@cXnType , 'INWORD_XN_TYPE' 
		UNION 
		SELECT 'All' AS DisplayMember,'' AS ValueMember ,@cXnType , 'INWORD_XN_TYPE'   WHERE @nMode=1

	end
	ELSE IF (@cXnType	IN ('PRCL') AND 	@cComboType	='OUTWORD_XN_TYPE')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Purchase Return' AS DisplayMember,'PRT' AS ValueMember ,@cXnType , 'OUTWORD_XN_TYPE' 
		UNION 
		SELECT 'Wholesale Invoice' AS DisplayMember,'WSL' AS ValueMember ,@cXnType , 'OUTWORD_XN_TYPE' 
		UNION 
		SELECT 'Material Issue' AS DisplayMember,'MIS' AS ValueMember ,@cXnType , 'OUTWORD_XN_TYPE' 
		UNION 
		SELECT 'Job Work Issue' AS DisplayMember,'JWI' AS ValueMember ,@cXnType , 'OUTWORD_XN_TYPE' 
		UNION 
		SELECT 'Retail Sale' AS DisplayMember,'SLS' AS ValueMember ,@cXnType , 'OUTWORD_XN_TYPE' 		
		UNION 
		SELECT 'All' AS DisplayMember,'' AS ValueMember ,@cXnType , 'OUTWORD_XN_TYPE'   WHERE @nMode=1

	end
	ELSE IF (@cXnType	IN ('PRCL') AND 	@cComboType	='ADJ_STATUS')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Opened' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'ADJ_STATUS' 
		UNION 
		SELECT 'Unopened' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'ADJ_STATUS' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'ADJ_STATUS'   WHERE @nMode=1

	end
	ELSE IF (@cXnType	IN ('PRCL') AND 	@cComboType	='TRANSPORTER_BILL_STATUS')
	BEGIN
	    INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Pending' AS DisplayMember,'1' AS ValueMember ,@cXnType , 'TRANSPORTER_BILL_STATUS' 
		UNION 
		SELECT 'Closed' AS DisplayMember,'2' AS ValueMember ,@cXnType , 'TRANSPORTER_BILL_STATUS' 
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember ,@cXnType , 'TRANSPORTER_BILL_STATUS'   WHERE @nMode=1

	END
	ELSE IF (@cXnType	IN ('SLS') )
	BEGIN
		INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT 'Credit Refund' AS DisplayMember,'1' AS ValueMember, @cXnType,@cComboType  WHERE 	@cComboType	='PAYMENT_TYPE'
		UNION
		SELECT 'Cash Refund' AS DisplayMember,'2' AS ValueMember, @cXnType, @cComboType   WHERE 	@cComboType	='PAYMENT_TYPE'
		UNION
		SELECT 'Credit' AS DisplayMember,'3' AS ValueMember, @cXnType, @cComboType WHERE 	@cComboType	='PAYMENT_TYPE'
		UNION
		SELECT 'Credit Note' AS DisplayMember,'4' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='PAYMENT_TYPE'

		UNION
		SELECT 'Without Order' AS DisplayMember,'1' AS ValueMember, @cXnType, @cComboType WHERE 	@cComboType	='ORDER_STATUS'
		UNION
		SELECT 'Against Order' AS DisplayMember,'2' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='ORDER_STATUS'

		UNION
		SELECT 'Cancelled' AS DisplayMember,'1' AS ValueMember, @cXnType, @cComboType WHERE 	@cComboType	='CANCELLED'
		UNION
		SELECT 'Uncancelld' AS DisplayMember,'0' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='CANCELLED'
		UNION
		SELECT 'All' AS DisplayMember,'2' AS ValueMember, @cXnType, @cComboType WHERE 	@cComboType	='CANCELLED'
		
		
		
		UNION
		SELECT 'Pending' AS DisplayMember,'1' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='BILL_STATUS'
		UNION
		SELECT 'Adjusted' AS DisplayMember,'2' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='BILL_STATUS'

		UNION
		SELECT 'Without Hold' AS DisplayMember,'1' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='HOLD_STATUS'
		UNION
		SELECT 'With Hold' AS DisplayMember,'2' AS ValueMember, @cXnType, @cComboType  WHERE 	@cComboType	='HOLD_STATUS'
		
		UNION 
		SELECT 'All' AS DisplayMember,'0' AS ValueMember, @cXnType, @cComboType WHERE @nMode=1 AND @cComboType	NOT IN ('CANCELLED','SLS_PAYMODE_FILTER')
		UNION
		SELECT ' All'/*Rohit 20-12-2022 : For Toppest in result */ AS DisplayMember,'' AS ValueMember, @cXnType, @cComboType WHERE @nMode=1 AND @cComboType	='SLS_PAYMODE_FILTER'
		UNION
		select B.paymode_name   AS DisplayMember,'PYMT_'+REPLACE(REPLACE(B.PAYMODE_NAME,'.',''),' ','') AS ValueMember,@cXnType , @cComboType
		from PAYMODE_MST B
		JOIN PAYMODE_XN_DET A (NOLOCK) ON A.PAYMODE_CODE=B.PAYMODE_CODE
		WHERE A.xn_type=@cXnType AND @cComboType	='SLS_PAYMODE_FILTER'
		GROUP BY B.paymode_name

	END
	ELSE IF (@cComboType	='CURRENCY')
	BEGIN 
		--INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
		SELECT  'All'  AS DisplayMember,'' AS ValueMember ,@cXnType , 'CURRENCY',CAST(0 AS NUMERIC(10,2)) AS FC_RATE
		WHERE @nMode=1
		UNION
		SELECT fc_name AS DisplayMember,fc_code AS ValueMember ,@cXnType , 'CURRENCY',fc_rate
		from FC 
		RETURN
	END
	--IF  (@cComboType	='SLS_PAYMODE_FILTER')
	--BEGIN
	--	INSERT INTO @DTALL(DisplayMember ,ValueMember ,XNTYPE	,COMBOTYPE)
	--	SELECT  'All'  AS DisplayMember,'0' AS ValueMember ,@cXnType , 'PAYMENT_TYPE'
	--	UNION 
	--	select DISTINCT B.paymode_name   AS DisplayMember,'PYMT_'+REPLACE(REPLACE(B.PAYMODE_NAME,'.',''),' ','') AS ValueMember,@cXnType , 'PAYMENT_TYPE'
	--	from PAYMODE_XN_DET A
	--	JOIN PAYMODE_MST B ON A.PAYMODE_CODE=B.PAYMODE_CODE
	--	WHERE A.xn_type='SLS'
	--END
	--
	/* END OF PO */
	select * from @DTALL

END