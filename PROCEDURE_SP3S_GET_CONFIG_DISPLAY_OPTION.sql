CREATE PROCEDURE SP3S_GET_CONFIG_DISPLAY_OPTION
(
	@nMode	INT=0,
	@cConfigSection	VARCHAR(100)='',
	@cConfigOption	VARCHAR(100)=''
)
AS
BEGIN
	DECLARE @DTALL TABLE (DisplayMember varchar(200), ValueMember varchar(200),Config_Option varchar(200))

	INSERT INTO @DTALL(DisplayMember ,ValueMember 	,Config_Option)
	SELECT 'Party and Bill Wise' AS DisplayMember,'1' AS ValueMember  , 'DN_TYPE' 
	WHERE @nMode=1 OR  ( @cConfigOption	='DN_TYPE') 
	UNION
	SELECT 'Party Wise' AS DisplayMember,'2' AS ValueMember  ,'DN_TYPE'
	WHERE @nMode=1 OR (  @cConfigOption	='DN_TYPE')
	UNION
	SELECT 'Bill' AS DisplayMember,'1' AS ValueMember , 'DEFAULT_PUR_ENTRY_MODE' 
	WHERE @nMode=1 OR  ( @cConfigOption	='DEFAULT_PUR_ENTRY_MODE') 
	UNION
	SELECT 'Challan' AS DisplayMember,'2' AS ValueMember  ,'DEFAULT_PUR_ENTRY_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_PUR_ENTRY_MODE')
	UNION
	SELECT 'Serial' AS DisplayMember,'1' AS ValueMember, 'PRODUCT_CODE_GENERATION_RANDOM'
	WHERE @nMode=1 OR ( @cConfigOption	='PRODUCT_CODE_GENERATION_RANDOM')
	UNION
	SELECT 'Random' AS DisplayMember,'2' AS ValueMember  , 'PRODUCT_CODE_GENERATION_RANDOM'
	WHERE @nMode=1 OR (  @cConfigOption	='PRODUCT_CODE_GENERATION_RANDOM')
	UNION	
	SELECT 'Calculate MRP from WS Price' AS DisplayMember,'1' AS ValueMember ,'MRP_WSP_MODE' 
	WHERE @nMode=1 OR (  @cConfigOption	='MRP_WSP_MODE')
	UNION
	SELECT 'Calculate WS Price from MRP' AS DisplayMember,'2' AS ValueMember , 'MRP_WSP_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='MRP_WSP_MODE')
	UNION	
	SELECT 'Rate Revision' AS DisplayMember,'1' AS ValueMember ,  'DEFINE_FOCUS_ON_RATE_REVISION'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFINE_FOCUS_ON_RATE_REVISION')
	UNION
	SELECT 'Tag Printing' AS DisplayMember,'2' AS ValueMember , 'DEFINE_FOCUS_ON_RATE_REVISION'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFINE_FOCUS_ON_RATE_REVISION')
	UNION 
	SELECT 'PO' AS DisplayMember,'1' AS ValueMember , 'RATE_PICKING_METHOD_AGAINST_PO'
	WHERE @nMode=1 OR (  @cConfigOption	='RATE_PICKING_METHOD_AGAINST_PO')
	UNION
	SELECT 'Party Rate Master' AS DisplayMember,'2' AS ValueMember , 'RATE_PICKING_METHOD_AGAINST_PO'
	WHERE @nMode=1 OR (  @cConfigOption	='RATE_PICKING_METHOD_AGAINST_PO')
	UNION
	SELECT 'Rounded' AS DisplayMember,'1' AS ValueMember ,  'MRP_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='MRP_ROUNDING_MODE')
	UNION
	SELECT 'Ends At' AS DisplayMember,'2' AS ValueMember , 'MRP_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='MRP_ROUNDING_MODE')
	UNION 
	SELECT 'Rounded' AS DisplayMember,'1' AS ValueMember , 'WSP_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='WSP_ROUNDING_MODE')
	UNION
	SELECT 'Ends At' AS DisplayMember,'2' AS ValueMember ,  'WSP_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='WSP_ROUNDING_MODE')
	UNION 
	SELECT 'Higher' AS DisplayMember,'1' AS ValueMember , 'MRP_ROUNDING_LEVEL'
	WHERE @nMode=1 OR ( @cConfigOption	= 'MRP_ROUNDING_LEVEL')
	UNION
	SELECT 'Nearest' AS DisplayMember,'0' AS ValueMember ,   'MRP_ROUNDING_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	= 'MRP_ROUNDING_LEVEL')
	UNION	
	SELECT 'Higher' AS DisplayMember,'1' AS ValueMember ,  'WSP_ROUNDING_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='WSP_ROUNDING_LEVEL')
	UNION
	SELECT 'Nearest' AS DisplayMember,'0' AS ValueMember ,   'WSP_ROUNDING_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='WSP_ROUNDING_LEVEL')
	UNION	
	SELECT 'Any Node' AS DisplayMember,'1' AS ValueMember ,  'CAMPAIGN_RUN_ON_ANY_NODE_SPECIFIC_NODE'
	WHERE @nMode=1 OR ( @cConfigOption	='CAMPAIGN_RUN_ON_ANY_NODE_SPECIFIC_NODE')
	UNION
	SELECT 'Specific Node' AS DisplayMember,'2' AS ValueMember ,   'CAMPAIGN_RUN_ON_ANY_NODE_SPECIFIC_NODE'
	WHERE @nMode=1 OR (  @cConfigOption	='CAMPAIGN_RUN_ON_ANY_NODE_SPECIFIC_NODE')
	UNION	
	SELECT 'Any Node' AS DisplayMember,'1' AS ValueMember ,  'MONITOR_RUN_ON_ANY_NODE_SPECIFIC_NODE'
	WHERE @nMode=1 OR (  @cConfigOption	='MONITOR_RUN_ON_ANY_NODE_SPECIFIC_NODE')
	UNION
	SELECT 'Specific Node' AS DisplayMember,'2' AS ValueMember ,  'MONITOR_RUN_ON_ANY_NODE_SPECIFIC_NODE'
	WHERE @nMode=1 OR (  @cConfigOption	='MONITOR_RUN_ON_ANY_NODE_SPECIFIC_NODE')
	UNION	
	SELECT 'Fixed' AS DisplayMember,'1' AS ValueMember ,   'CODING_SCHEME'
	WHERE @nMode=1 OR ( @cConfigOption	='CODING_SCHEME')
	UNION
	SELECT 'Lot' AS DisplayMember,'2' AS ValueMember ,   'CODING_SCHEME'
	WHERE @nMode=1 OR (   @cConfigOption	='CODING_SCHEME')
	UNION	
	SELECT 'Unique' AS DisplayMember,'3' AS ValueMember ,   'CODING_SCHEME'
	WHERE @nMode=1 OR (   @cConfigOption	='CODING_SCHEME')
	UNION
	SELECT 'USB Port' AS DisplayMember,'1' AS ValueMember ,   'DEFAULT_PRINTER'
	WHERE @nMode=1 OR (   @cConfigOption	='DEFAULT_PRINTER')
	UNION	
	SELECT 'LPT Port' AS DisplayMember,'2' AS ValueMember ,   'DEFAULT_PRINTER'
	WHERE @nMode=1 OR (   @cConfigOption	='DEFAULT_PRINTER')
	UNION	
	SELECT 'Section' AS DisplayMember,'1' AS ValueMember ,   'ARTICLE_NAME_PREFIX'
	WHERE @nMode=1 OR (   @cConfigOption	='ARTICLE_NAME_PREFIX')
	UNION
	SELECT 'SubSection' AS DisplayMember,'2' AS ValueMember ,   'ARTICLE_NAME_PREFIX'
	WHERE @nMode=1 OR (   @cConfigOption	='ARTICLE_NAME_PREFIX')
	UNION	
	SELECT 'Both' AS DisplayMember,'3' AS ValueMember ,   'ARTICLE_NAME_PREFIX'
	WHERE @nMode=1 OR (   @cConfigOption	='ARTICLE_NAME_PREFIX')
	UNION
	SELECT 'Bill By Bill' AS DisplayMember,'1' AS ValueMember ,   'DEFAULT_BALANCE_METHOD_CUSTOMER'
	WHERE @nMode=1 OR (   @cConfigOption	='DEFAULT_BALANCE_METHOD_CUSTOMER')
	UNION	
	SELECT 'On Account' AS DisplayMember,'2' AS ValueMember ,   'DEFAULT_BALANCE_METHOD_CUSTOMER'
	WHERE @nMode=1 OR (   @cConfigOption	='DEFAULT_BALANCE_METHOD_CUSTOMER')
	UNION
	SELECT 'Manual' AS DisplayMember,'1' AS ValueMember ,   'DEFINE_FOCUS_ON_ARTICLEMASTER'
	WHERE @nMode=1 OR (   @cConfigOption	='DEFINE_FOCUS_ON_ARTICLEMASTER')
	UNION	
	SELECT 'Auto' AS DisplayMember,'2' AS ValueMember ,   'DEFINE_FOCUS_ON_ARTICLEMASTER'
	WHERE @nMode=1 OR (   @cConfigOption	='DEFINE_FOCUS_ON_ARTICLEMASTER')
	UNION	
	SELECT 'Article' AS DisplayMember,'1' AS ValueMember ,   'PICT_SOURCE'
	WHERE @nMode=1 OR (   @cConfigOption	='PICT_SOURCE')
	UNION
	SELECT 'Style' AS DisplayMember,'2' AS ValueMember ,   'PICT_SOURCE'
	WHERE @nMode=1 OR (   @cConfigOption	='PICT_SOURCE')
	UNION	
	SELECT 'Product' AS DisplayMember,'3' AS ValueMember ,   'PICT_SOURCE'
	WHERE @nMode=1 OR (   @cConfigOption	='PICT_SOURCE')
	UNION
	SELECT 'MRP' AS DisplayMember,'1' AS ValueMember ,   'VALUE_AT'
	WHERE @nMode=1 OR (  @cConfigOption	='VALUE_AT')
	UNION
	SELECT 'PP' AS DisplayMember,'2' AS ValueMember ,   'VALUE_AT'
	WHERE @nMode=1 OR (  @cConfigOption	='VALUE_AT')
	UNION
	SELECT 'PARA1' AS DisplayMember,'PARA1' AS ValueMember ,   'STK_PARA_NAME'
	WHERE @nMode=1 OR (  @cConfigOption	='STK_PARA_NAME')
	UNION
	SELECT 'PARA2' AS DisplayMember,'PARA2' AS ValueMember ,   'STK_PARA_NAME'
	WHERE @nMode=1 OR (  @cConfigOption	='STK_PARA_NAME')
	UNION
	SELECT 'PARA3' AS DisplayMember,'PARA3' AS ValueMember ,   'STK_PARA_NAME'
	WHERE @nMode=1 OR (  @cConfigOption	='STK_PARA_NAME')
	UNION
	SELECT 'PARA4' AS DisplayMember,'PARA4' AS ValueMember ,   'STK_PARA_NAME'
	WHERE @nMode=1 OR (  @cConfigOption	='STK_PARA_NAME')
	UNION
	SELECT 'PARA5' AS DisplayMember,'PARA5' AS ValueMember ,   'STK_PARA_NAME'
	WHERE @nMode=1 OR (  @cConfigOption	='STK_PARA_NAME')
	UNION
	SELECT 'PARA6' AS DisplayMember,'PARA6' AS ValueMember ,   'STK_PARA_NAME'
	WHERE @nMode=1 OR (  @cConfigOption	='STK_PARA_NAME')
	UNION
	SELECT 'As per Purchase and then Party Rate' AS DisplayMember,'1' AS ValueMember ,  'GROUP_DEBIT_NOTE_RATE_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='GROUP_DEBIT_NOTE_RATE_MODE')
	UNION
	SELECT 'As Per Party Rate' AS DisplayMember,'2' AS ValueMember ,   'GROUP_DEBIT_NOTE_RATE_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='GROUP_DEBIT_NOTE_RATE_MODE')
	UNION
	SELECT 'Last Sale Details' AS DisplayMember,'1' AS ValueMember , 'RATE_PICKING_MODE'
	WHERE @nMode=1 OR (   @cConfigOption	='RATE_PICKING_MODE')
	
	UNION
	SELECT 'Party Rate' AS DisplayMember,'2' AS ValueMember ,   'RATE_PICKING_MODE'
	WHERE @nMode=1 OR (   @cConfigOption	='RATE_PICKING_MODE')
	UNION
	SELECT 'Customer ID' AS DisplayMember,'1' AS ValueMember ,   'FOCUS'
	WHERE @nMode=1 OR (  @cConfigOption	='FOCUS')
	UNION
	SELECT 'Sales Person' AS DisplayMember,'2' AS ValueMember ,   'FOCUS'
	WHERE @nMode=1 OR (  @cConfigOption	='FOCUS')
	UNION
	SELECT 'Item Entry' AS DisplayMember,'3' AS ValueMember ,   'FOCUS'
	WHERE @nMode=1 OR (  @cConfigOption	='FOCUS')
	UNION
	SELECT 'Nearest ONE' AS DisplayMember,'1' AS ValueMember ,   'SLS_ROUND_BILL_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='SLS_ROUND_BILL_LEVEL')
	UNION
	SELECT 'Nearest FIVE' AS DisplayMember,'2' AS ValueMember ,   'SLS_ROUND_BILL_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='SLS_ROUND_BILL_LEVEL')
	UNION
	SELECT 'Higher FIVE' AS DisplayMember,'3' AS ValueMember ,   'SLS_ROUND_BILL_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='SLS_ROUND_BILL_LEVEL')
	UNION
	SELECT 'N/A' AS DisplayMember,'4' AS ValueMember ,   'SLS_ROUND_BILL_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='SLS_ROUND_BILL_LEVEL')
	UNION
	SELECT 'Pick Ledger Discount on Bill level' AS DisplayMember,'1' AS ValueMember ,  'PICK_LEDGER_DISC'
	WHERE @nMode=1 OR (  @cConfigOption	='PICK_LEDGER_DISC')
	UNION
	SELECT 'Pick Ledger Discount on Item level' AS DisplayMember,'2' AS ValueMember ,  'PICK_LEDGER_DISC'
	WHERE @nMode=1 OR (  @cConfigOption	='PICK_LEDGER_DISC')
	UNION
	SELECT BIN_NAME AS DisplayMember,MAJOR_BIN_ID AS ValueMember,'DEFAULT_ZONE'
	FROM BIN (NOLOCK) WHERE MAJOR_BIN_ID= BIN_ID
	AND (@nMode=1 OR (  @cConfigOption	='DEFAULT_ZONE'))
	UNION
	SELECT 'Cash' AS DisplayMember,'1' AS ValueMember ,  'PAYMENT_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='PAYMENT_MODE')
	UNION
	SELECT 'Credit Issued' AS DisplayMember,'4' AS ValueMember ,  'PAYMENT_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='PAYMENT_MODE')
	UNION
	SELECT 'Composit' AS DisplayMember,'5' AS ValueMember ,  'PAYMENT_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='PAYMENT_MODE')
	UNION
	SELECT 'Credit Card' AS DisplayMember,'2' AS ValueMember ,  'PAYMENT_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='PAYMENT_MODE')
	UNION
	SELECT 'By Default Barcode Wise' AS DisplayMember,'1' AS ValueMember ,  'DEFAULT_BW_OPTION'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_BW_OPTION')
	UNION
	SELECT 'By Default Non Barcode Wise' AS DisplayMember,'2' AS ValueMember ,  'DEFAULT_BW_OPTION'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_BW_OPTION')
	UNION
	SELECT 'MRP' AS DisplayMember,'1' AS ValueMember ,  'CUSTOMDUTY_BASEPRICE'
	WHERE @nMode=1 OR (  @cConfigOption	='CUSTOMDUTY_BASEPRICE')
	UNION
	SELECT 'WSP' AS DisplayMember,'2' AS ValueMember ,  'CUSTOMDUTY_BASEPRICE'
	WHERE @nMode=1 OR (  @cConfigOption	='CUSTOMDUTY_BASEPRICE')
	UNION
	SELECT 'Local' AS DisplayMember,'1' AS ValueMember ,  'DEFAULT_INV_METHOD'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_INV_METHOD')
	UNION
	SELECT 'Outstation' AS DisplayMember,'2' AS ValueMember ,  'DEFAULT_INV_METHOD'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_INV_METHOD')
	UNION
	SELECT 'PineLabs' AS DisplayMember,'1' AS ValueMember ,   'EDC_MACHINE'
	WHERE @nMode=1 OR (  @cConfigOption	='EDC_MACHINE')
	UNION
	SELECT 'Innovative' AS DisplayMember,'2' AS ValueMember ,   'EDC_MACHINE'
	WHERE @nMode=1 OR (  @cConfigOption	='EDC_MACHINE')
	UNION
	SELECT 'Zero Quantity' AS DisplayMember,'1' AS ValueMember ,   'SCAN_QTY_FOR_DISCONTYPE'
	WHERE @nMode=1 OR (  @cConfigOption	='SCAN_QTY_FOR_DISCONTYPE')
	UNION
	SELECT 'Stock Quantity' AS DisplayMember,'2' AS ValueMember ,   'SCAN_QTY_FOR_DISCONTYPE'
	WHERE @nMode=1 OR (  @cConfigOption	='SCAN_QTY_FOR_DISCONTYPE')
	UNION
	SELECT 'Bill' AS DisplayMember,'1' AS ValueMember ,   'TAX_FORM_DEFINE_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='TAX_FORM_DEFINE_LEVEL')
	UNION
	SELECT 'Item' AS DisplayMember,'2' AS ValueMember ,   'TAX_FORM_DEFINE_LEVEL'
	WHERE @nMode=1 OR (  @cConfigOption	='TAX_FORM_DEFINE_LEVEL')
	UNION
	SELECT 'Party' AS DisplayMember,'1' AS ValueMember ,   'DEFAULT_INVOICE_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_INVOICE_MODE')
	UNION
	SELECT 'Group' AS DisplayMember,'2' AS ValueMember ,   'DEFAULT_INVOICE_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_INVOICE_MODE')
	UNION
	SELECT MST.PAYMODE_NAME AS DisplayMember,MST.PAYMODE_CODE AS ValueMember,'DEFAULT_CREDIT_CARD'
    FROM PAYMODE_MST MST (NOLOCK) 
    JOIN PAYMODE_GRP_MST GRP (NOLOCK) ON MST.PAYMODE_GRP_CODE = GRP.PAYMODE_GRP_CODE
	WHERE GRP.PAYMODE_GRP_CODE='0000002' AND INACTIVE=0 AND MST.PAYMODE_CODE NOT LIKE 'EDC%'
	AND (@nMode=1 OR (  @cConfigOption	='DEFAULT_CREDIT_CARD'))
	UNION
	SELECT JOB_NAME AS DisplayMember,JOB_CODE AS ValueMember  ,'DEFAULT_JOB_CODE' 
	FROM JOBS (NOLOCK) WHERE JOB_NAME <> '' AND INACTIVE = 0
	AND (@nMode=1 OR (  @cConfigOption	='DEFAULT_JOB_CODE'))
	UNION
	SELECT dt_name+'('+Cast(discount_percentage  AS VARCHAR(10)) +')' AS DisplayMember ,dt_code AS ValueMember,'DEFAULT_DISCOUNT_TYPE' 
	FROM dtm (NOLOCK) WHERE dt_name <> '' and isnull(inactive,0)=0 and  wizclip_discount <> 1
	AND (@nMode=1 OR (  @cConfigOption	='DEFAULT_DISCOUNT_TYPE'))
	UNION
	SELECT UOM_NAME AS DisplayMember,uom_code AS ValueMember,'DEFAULT_UOM_CODE'
	FROM UOM (NOLOCK) 
	WHERE (@nMode=1 OR (   @cConfigOption	='DEFAULT_UOM_CODE'))
	UNION
	SELECT UOM_NAME AS DisplayMember,uom_name AS ValueMember,'DEFAULT_UOM_NAME'
	FROM UOM (NOLOCK) 
	WHERE (@nMode=1 OR (   @cConfigOption	='DEFAULT_UOM_NAME'))
	UNION
	SELECT 'Invoicing' AS DisplayMember,'1' AS ValueMember ,   'CALCULATE_TCS_AGAINST_INVOICING'
	WHERE @nMode=1 OR (  @cConfigOption	='CALCULATE_TCS_AGAINST_INVOICING')
	UNION
	SELECT 'Receipts' AS DisplayMember,'2' AS ValueMember ,   'CALCULATE_TCS_AGAINST_INVOICING'
	WHERE @nMode=1 OR (  @cConfigOption	='CALCULATE_TCS_AGAINST_INVOICING')
	
	UNION
	SELECT 'Voucher Level' AS DisplayMember,'1' AS ValueMember ,   'Narrationlevel'
	WHERE @nMode=1 OR (  @cConfigOption	='Narrationlevel')
	UNION
	SELECT 'Item Level' AS DisplayMember,'2' AS ValueMember ,   'Narrationlevel'
	WHERE @nMode=1 OR (  @cConfigOption	='Narrationlevel')
	
	
	UNION
	SELECT 'Date Wise' AS DisplayMember,'1' AS ValueMember ,   'VOUCHER_NO_SYSTEM'
	WHERE @nMode=1 OR (  @cConfigOption	='VOUCHER_NO_SYSTEM')
	UNION
	SELECT 'Type Wise' AS DisplayMember,'2' AS ValueMember ,   'VOUCHER_NO_SYSTEM'
	WHERE @nMode=1 OR (  @cConfigOption	='VOUCHER_NO_SYSTEM')
	UNION
	SELECT 'Running' AS DisplayMember,'3' AS ValueMember ,   'VOUCHER_NO_SYSTEM'
	WHERE @nMode=1 OR (  @cConfigOption	='VOUCHER_NO_SYSTEM')
	UNION
	SELECT 'Bill By Bill' AS DisplayMember,'1' AS ValueMember ,   'DEFAULT_BALANCE_METHOD'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_BALANCE_METHOD')
	UNION
	SELECT 'On Account' AS DisplayMember,'2' AS ValueMember ,   'DEFAULT_BALANCE_METHOD'
	WHERE @nMode=1 OR (  @cConfigOption	='DEFAULT_BALANCE_METHOD')
	UNION
	SELECT HEAD_NAME AS DisplayMember,HEAD_CODE AS ValueMember,   'BROKER_HEAD_CODE'  
	FROM HD01106 (NOLOCK)
	WHERE HEAD_CODE <>'0000000' AND (@nMode=1 OR (  @cConfigOption	='BROKER_HEAD_CODE'))
	UNION
	SELECT HEAD_NAME AS DisplayMember,HEAD_CODE AS ValueMember,   'TRANSPORTER_HEAD_CODE'  
	FROM HD01106 (NOLOCK)
	WHERE HEAD_CODE <>'0000000' AND (@nMode=1 OR (  @cConfigOption	='TRANSPORTER_HEAD_CODE'))
	UNION
	SELECT ac_name AS DisplayMember,ac_code AS ValueMember,   'VCH_BANK_CHARGES'  
	FROM LM01106 (NOLOCK)
	WHERE  ac_name<>''  AND ISNULL(inactive,0)=0  AND (@nMode=1 OR (  @cConfigOption	='VCH_BANK_CHARGES'))
	UNION
	SELECT ac_name AS DisplayMember,ac_code AS ValueMember,   'SALARY ACCOUNT'  
	FROM LM01106 (NOLOCK)
	WHERE  ac_name<>''  AND ISNULL(inactive,0)=0  AND (@nMode=1 OR (  @cConfigOption	='SALARY ACCOUNT'))
	UNION
	SELECT ac_name AS DisplayMember,ac_code AS ValueMember,   'ROUND_OFF AC_CODE'  
	FROM LM01106 (NOLOCK)
	WHERE  ac_name<>''  AND ISNULL(inactive,0)=0  AND (@nMode=1 OR (  @cConfigOption	='ROUND_OFF AC_CODE'))
	UNION
	SELECT ac_name AS DisplayMember,ac_code AS ValueMember,   'VCH_DISC_ALLOW'  
	FROM LM01106 (NOLOCK)
	WHERE  ac_name<>''  AND ISNULL(inactive,0)=0  AND (@nMode=1 OR (  @cConfigOption	='VCH_DISC_ALLOW'))
	UNION
	SELECT ac_name AS DisplayMember,ac_code AS ValueMember,   'VCH_DISC_AVAIL'  
	FROM LM01106 (NOLOCK)
	WHERE  ac_name<>''  AND ISNULL(inactive,0)=0  AND (@nMode=1 OR (  @cConfigOption	='VCH_DISC_AVAIL'))
	UNION
	SELECT 'Manual/Inventory' AS DisplayMember,'1' AS ValueMember ,   'STOCK_PICK_METHOD'
	WHERE @nMode=1 OR (  @cConfigOption	='STOCK_PICK_METHOD')
	UNION
	SELECT 'Auto/Ledger' AS DisplayMember,'2' AS ValueMember ,   'STOCK_PICK_METHOD'
	WHERE @nMode=1 OR (  @cConfigOption	='STOCK_PICK_METHOD')
	UNION
	SELECT VALUE AS DisplayMember,'PARA1' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA1_CAPTION' AND ISNULL(VALUE,'')<>'' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT 'PARA1' AS DisplayMember,'PARA1' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA1_CAPTION' AND ISNULL(VALUE,'')='' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT VALUE AS DisplayMember,'PARA2' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA2_CAPTION' AND ISNULL(VALUE,'')<>'' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT 'PARA2' AS DisplayMember,'PARA2' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA2_CAPTION' AND ISNULL(VALUE,'')='' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT VALUE AS DisplayMember,'PARA3' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA3_CAPTION' AND ISNULL(VALUE,'')<>'' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT 'PARA3' AS DisplayMember,'PARA3' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA3_CAPTION' AND ISNULL(VALUE,'')='' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))

	UNION
	SELECT VALUE AS DisplayMember,'PARA4' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA4_CAPTION' AND ISNULL(VALUE,'')<>'' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT 'PARA4' AS DisplayMember,'PARA4' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA4_CAPTION' AND ISNULL(VALUE,'')='' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))



	UNION
	SELECT VALUE AS DisplayMember,'PARA5' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA5_CAPTION' AND ISNULL(VALUE,'')<>'' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT 'PARA5' AS DisplayMember,'PARA5' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA5_CAPTION' AND ISNULL(VALUE,'')='' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))

	UNION
	SELECT VALUE AS DisplayMember,'PARA6' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA6_CAPTION' AND ISNULL(VALUE,'')<>'' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))
	UNION
	SELECT 'PARA6' AS DisplayMember,'PARA6' AS ValueMember ,   'PARA_NAME_FOR_DISCOUNT_VIEW' 
	FROM CONFIG 
	where config_option = 'PARA6_CAPTION' AND ISNULL(VALUE,'')='' 
	AND ( @nMode=1 OR (  @cConfigOption	='PARA_NAME_FOR_DISCOUNT_VIEW'))

	UNION
	SELECT 'Nearest ONE' AS DisplayMember,'1' AS ValueMember ,   'TDS_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='TDS_ROUNDING_MODE')
	UNION
	SELECT 'Higher ONE' AS DisplayMember,'2' AS ValueMember ,   'TDS_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='TDS_ROUNDING_MODE')
	UNION
	SELECT 'Do Not Round' AS DisplayMember,'3' AS ValueMember ,   'TDS_ROUNDING_MODE'
	WHERE @nMode=1 OR (  @cConfigOption	='TDS_ROUNDING_MODE')
	UNION
	SELECT  ac_name AS DisplayMember,ac_code AS ValueMember,   'CUSTOMER_CONTROL_AC_CODE' as Config_Option
	FROM LM01106 (NOLOCK) 
	WHERE HEAD_CODE='0000000018'
	AND ( @nMode=1 OR  @cConfigOption='CUSTOMER_CONTROL_AC_CODE' )
	
	if(   @cConfigOption	='VCH_DISC_ALLOW' OR @cConfigOption	='VCH_DISC_AVAIL' OR  @cConfigOption='CUSTOMER_CONTROL_AC_CODE')
		SELECT * FROM @DTALL ORDER BY Config_Option,DisplayMember
	else
		SELECT * FROM @DTALL ORDER BY Config_Option,ValueMember
END