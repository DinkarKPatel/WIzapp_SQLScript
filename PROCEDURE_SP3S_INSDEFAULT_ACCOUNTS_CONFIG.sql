CREATE PROCEDURE SP3S_INSDEFAULT_ACCOUNTS_CONFIG
AS
BEGIN
	
	PRINT 'STEP-1'
	DECLARE @GST_ACCOUNTS_CONFIG_MST TABLE
	(
		[SNO] NUMERIC(4,2),
		[XN_TYPE] [VARCHAR](40),
		[DISPLAY_XN_TYPE] [VARCHAR](200),
		[ENABLEPOSTING] [BIT],
		[CUTOFFDATE] [DATETIME],
		[POST_BILL_BY_BILL_REFTYPE] [NUMERIC](1, 0),
		[POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE] [NUMERIC](1, 0) ,
		[CREATE_LEDGER_FOR_EACHCUSTOMER] [BIT] ,
		[POSTXFRBILLDATE] [BIT] ,
		[POSTING_XN_TYPE] [VARCHAR](20),
		[DISPLAY_POSTING_XN_TYPE] [VARCHAR](200)
	)

	PRINT 'STEP-2'
	INSERT @GST_ACCOUNTS_CONFIG_MST	( SNO,XN_TYPE,DISPLAY_XN_TYPE, ENABLEPOSTING, CUTOFFDATE, POST_BILL_BY_BILL_REFTYPE, 
	POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,CREATE_LEDGER_FOR_EACHCUSTOMER,POSTXFRBILLDATE,
	POSTING_XN_TYPE,DISPLAY_POSTING_XN_TYPE )  

	SELECT 1 AS SNO,'PUR' AS XN_TYPE,'PARTY PURCHASE' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30' ,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 1 AS SNO,'PUR_AST' AS XN_TYPE,'PARTY PURCHASE(ASSETS)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30' ,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 1 AS SNO,'PUR_SRV' AS XN_TYPE,'PARTY PURCHASE(SERVICES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30' ,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE	
	UNION ALL
	SELECT 1 AS SNO,'PUR_CON' AS XN_TYPE,'PARTY PURCHASE(CONSUMABLES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30' ,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE	
		
	UNION ALL
	SELECT 2 AS SNO,'PRT' AS XN_TYPE,'PARTY DEBIT NOTE' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 2 AS SNO,'PRT_AST' AS XN_TYPE,'PARTY DEBIT NOTE(ASSETS)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 2 AS SNO,'PRT_SRV' AS XN_TYPE,'PARTY DEBIT NOTE(SERVICES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 2 AS SNO,'PRT_CON' AS XN_TYPE,'PARTY DEBIT NOTE(CONSUMABLES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
					
	UNION ALL
	SELECT 3 AS SNO,'WSL' AS XN_TYPE,'PARTY WHOLESALE' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 3 AS SNO,'WSL_AST' AS XN_TYPE,'PARTY WHOLESALE(ASSETS)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 3 AS SNO,'WSL_SRV' AS XN_TYPE,'PARTY WHOLESALE(SERVICES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 3 AS SNO,'WSL_CON' AS XN_TYPE,'PARTY WHOLESALE(CONSUMABLES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	
	UNION ALL
	SELECT 4 AS SNO,'WSR' AS XN_TYPE,'PARTY WHOLESALE CREDIT NOTE' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 4 AS SNO,'WSR_AST' AS XN_TYPE,'PARTY WHOLESALE CREDIT NOTE(ASSETS)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 4 AS SNO,'WSR_SRV' AS XN_TYPE,'PARTY WHOLESALE CREDIT NOTE(SERVICES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 4 AS SNO,'WSR_CON' AS XN_TYPE,'PARTY WHOLESALE CREDIT NOTE(CONSUMABLES)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
					
	UNION ALL
	SELECT 5 AS SNO,'SLS' AS XN_TYPE,'RETAIL SALES' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,
	0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 6 AS SNO,'ARC' AS XN_TYPE,'O/S RECEIPT / PAYMENT' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE

	UNION ALL
	SELECT 7 AS SNO,'PTC' AS XN_TYPE,'PETTY CASH' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 11 AS SNO,'BTF' AS XN_TYPE,'BANK TRANSFER' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 8 AS SNO,'IWS' AS XN_TYPE,'INWARD SUPPLY /EXPENSE' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 10 AS SNO,'TLF' AS XN_TYPE,'TILL LIFT' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 
	UNION ALL
	SELECT 12 AS SNO,'JWR' AS XN_TYPE,'JOB WORK RECEIPT' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-06-30',0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'' AS POSTING_XN_TYPE,'' AS DISPLAY_POSTING_XN_TYPE 

	UNION ALL
	SELECT 9 AS SNO,'CHO_WSL_SAME_PANNO' AS XN_TYPE,'GROUP WHOLESALE (Same PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE	
	UNION ALL
	SELECT 9 AS SNO,'CHO_WSL_DIFF_PANNO' AS XN_TYPE,'GROUP WHOLESALE (Different PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 9 AS SNO,'CHI_PUR_SAME_PANNO' AS XN_TYPE,'GROUP PURCHASE (Same PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 9 AS SNO,'CHI_PUR_DIFF_PANNO' AS XN_TYPE,'GROUP PURCHASE (Different PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 9 AS SNO,'CHO_PRT_SAME_PANNO' AS XN_TYPE,'GROUP DEBIT NOTE (Same PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE	
	UNION ALL
	SELECT 9 AS SNO,'CHO_PRT_DIFF_PANNO' AS XN_TYPE,'GROUP DEBIT NOTE (Different PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 9 AS SNO,'CHI_WSR_SAME_PANNO' AS XN_TYPE,'GROUP CREDIT NOTE (Same PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE	
	UNION ALL
	SELECT 9 AS SNO,'CHI_WSR_DIFF_PANNO' AS XN_TYPE,'GROUP CREDIT NOTE (Different PAN No.)' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE	
	UNION ALL	
	SELECT 9 AS SNO,'CHI_XFR' AS XN_TYPE,'STOCK TRANSFER IN' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE
	UNION ALL
	SELECT 9 AS SNO,'CHO_XFR' AS XN_TYPE,'STOCK TRANSFER OUT' AS DISPLAY_XN_TYPE,0 AS ENABLEPOSTING,'2017-07-01' AS CUTOFFDATE,0 AS POST_BILL_BY_BILL_REFTYPE,
	0 AS  POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,0 AS CREATE_LEDGER_FOR_EACHCUSTOMER,0 AS POSTXFRBILLDATE,'XFR' AS POSTING_XN_TYPE,'GROUP TRANSFER' AS DISPLAY_POSTING_XN_TYPE

	select *  INTO #tmpXnItemTypes
	FROM 
	(SELECT ' (Services)' xn_item_type,'_SRV' suffix
	UNION
	SELECT ' (Assets)' xn_item_type,'_AST' suffix
	UNION
	SELECT ' (Consumables)' xn_item_type,'_CON' suffix
	) a

	INSERT INTO @GST_ACCOUNTS_CONFIG_MST (SNO,XN_TYPE,DISPLAY_XN_TYPE, ENABLEPOSTING, CUTOFFDATE, POST_BILL_BY_BILL_REFTYPE, 
	POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,CREATE_LEDGER_FOR_EACHCUSTOMER,POSTXFRBILLDATE,
	POSTING_XN_TYPE,DISPLAY_POSTING_XN_TYPE)
	SELECT SNO,XN_TYPE+suffix,DISPLAY_XN_TYPE+xn_item_type, ENABLEPOSTING, CUTOFFDATE, POST_BILL_BY_BILL_REFTYPE, 
	POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,CREATE_LEDGER_FOR_EACHCUSTOMER,POSTXFRBILLDATE,
	POSTING_XN_TYPE,DISPLAY_POSTING_XN_TYPE FROM @GST_ACCOUNTS_CONFIG_MST a, #tmpXnItemTypes b
	WHERE a.posting_xn_type='XFR'
	
	IF OBJECT_ID('tempdb..#tmpGstConfigmst','u') IS NOT NULL
		DROP TABLE #tmpGstConfigmst
		
	SELECT xn_type,enableposting INTO #tmpGstConfigmst FROM GST_ACCOUNTS_CONFIG_MST
	WHERE XN_TYPE IN ('CHI_CO_PUR','CHI_NONCO_PUR','CHO_CO_WSL', 'CHO_NONCO_WSL','CHI_CO_WSR','CHI_NONCO_WSR','CHO_CO_PRT')
	
	DELETE FROM gst_accounts_config_det_1 where xn_type IN ('CHI_CO_PUR','CHI_NONCO_PUR','CHO_CO_WSL', 
	'CHO_NONCO_WSL','CHI_CO_WSR','CHI_NONCO_WSR','CHO_CO_PRT')

	DELETE FROM gst_accounts_config_det_2 where xn_type IN ('CHI_CO_PUR','CHI_NONCO_PUR','CHO_CO_WSL', 
	'CHO_NONCO_WSL','CHI_CO_WSR','CHI_NONCO_WSR','CHO_CO_PRT')
		
	DELETE FROM GST_ACCOUNTS_CONFIG_MST WHERE XN_TYPE IN ('CHI_CO_PUR','CHI_NONCO_PUR','CHO_CO_WSL', 
	'CHO_NONCO_WSL','CHI_CO_WSR','CHI_NONCO_WSR','CHO_CO_PRT','CHI_PUR_CO_CO','CHI_PUR_CO_NONCO',
	'CHI_PUR_NONCO_CO','CHI_PUR_NONCO_NONCO','CHI_WSR_CO_CO','CHI_WSR_CO_NONCO','CHI_WSR_NONCO_CO',
	'CHI_WSR_NONCO_NONCO','CHO_PRT_CO_CO','CHO_PRT_CO_NONCO','CHO_PRT_NONCO_CO','CHO_PRT_NONCO_NONCO',
	'CHO_WSL_CO_CO','CHO_WSL_CO_NONCO','CHO_WSL_NONCO_CO','CHO_WSL_NONCO_NONCO') 
		
	PRINT 'STEP-4'
	INSERT GST_ACCOUNTS_CONFIG_MST	( SNO,XN_TYPE,DISPLAY_XN_TYPE, ENABLEPOSTING, CUTOFFDATE, POST_BILL_BY_BILL_REFTYPE, 
	POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,CREATE_LEDGER_FOR_EACHCUSTOMER,POSTXFRBILLDATE,
	POSTING_XN_TYPE,DISPLAY_POSTING_XN_TYPE ) 
	SELECT A.SNO,A.XN_TYPE,A.DISPLAY_XN_TYPE, A.ENABLEPOSTING,A.CUTOFFDATE,A.POST_BILL_BY_BILL_REFTYPE, 
	A.POST_BILL_BY_BILL_ADJ_EXCEPTION_TYPE,A.CREATE_LEDGER_FOR_EACHCUSTOMER,A.POSTXFRBILLDATE,
	A.POSTING_XN_TYPE,A.DISPLAY_POSTING_XN_TYPE FROM @GST_ACCOUNTS_CONFIG_MST A 
	LEFT OUTER JOIN GST_ACCOUNTS_CONFIG_MST B ON A.XN_TYPE=B.XN_TYPE WHERE B.XN_TYPE IS NULL

	UPDATE GST_ACCOUNTS_CONFIG_MST SET POSTING_XN_TYPE=XN_TYPE,DISPLAY_POSTING_XN_TYPE=DISPLAY_XN_TYPE 
	WHERE ISNULL(POSTING_XN_TYPE,'')=''

	UPDATE A SET SNO=B.SNO FROM GST_ACCOUNTS_CONFIG_MST A 
	JOIN @GST_ACCOUNTS_CONFIG_MST B ON A.XN_TYPE=B.XN_TYPE
	
	UPDATE a SET enableposting=b.enableposting FROM gst_accounts_config_mst a
	JOIN #tmpGstConfigmst b ON a.xn_type=b.xn_type
		
	PRINT 'STEP-7'
	
END
-------- END OF PROCEDURE SP3S_INSDEFAULT_ACCOUNTS_CONFIG
