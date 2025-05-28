CREATE PROCEDURE SPWOW_PROCESS_XPERT_FILTEREXPR
@cXnType VARCHAR(100),
@cFilter VARCHAR(MAX) OUTPUT
AS
BEGIN
	SELECT TOP 1 @cFilter=ISNULL(filter_criteria,'') FROM #wow_xpert_rep_mst

	--select @cFilter
	
	IF RIGHT(@cXnType,2)='OH'
	BEGIN
		
		SET @cFilter=REPLACE(@cFilter,'ISNULL(Sku_Names.Sku_Er_Flag,0) IN (0 , 1 )','1=1')
		SET @cFilter=REPLACE(@cFilter,'ISNULL(SKU_NAMES.sku_item_type,1) IN (0,1)','1=1')
		SET @cFilter=REPLACE(@cFilter,'SKU_NAMES.SKU_ITEM_TYPE_DESC','XN_ITEM_TYPE_DESC_mst.xn_item_type_desc')
		
		
	END				 
	PRINT 'REPLACING FILTER FOR ' +@cXnType + ':'+ @cFilter

	IF CHARINDEX('account_posting_date',@cFilter)>0
	BEGIN
		IF @cXntype IN ('PUR','GRP_PUR')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','pim01106.bill_dt')
		ELSE

		IF @cXntype IN ('WSL','GRP_WSL')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','inm01106.inv_dt')
		ELSE
		IF @cXntype IN ('PRT','GRP_PRT')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','rmm01106.rm_dt')		
		ELSE
		IF @cXntype IN ('WSR','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','cnm01106.cn_dt')						
		ELSE
		IF @cXntype IN ('SLS','SLR','NSLS')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','cmm01106.cm_dt')		
		ELSE
		IF @cXntype IN ('JWI')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','jobwork_issue_mst.issue_dt')		
		ELSE
		IF @cXntype IN ('JWR')
			SET @cFilter=REPLACE(@cFilter,'account_posting_date','jobwork_receipt_mst.receipt_dt')		
	END
	--ELSE
	IF CHARINDEX('purchase_receipt_date',@cFilter)>0
	BEGIN
		IF @cXntype IN ('PUR','GRP_PUR')
			SET @cFilter=REPLACE(@cFilter,'purchase_receipt_date','pim01106.receipt_dt')
		ELSE
			SET @cFilter=REPLACE(@cFilter,'purchase_receipt_date','sku_names.purchase_receipt_Dt')
	END

	IF CHARINDEX('PIM01106.INV_DT',@cFilter)>0
	BEGIN
		IF @cXntype IN ('SLS','SLR','NSLS')		    
		  SET @cFilter=REPLACE(@cFilter,'PIM01106.INV_DT','sku_names.purchase_receipt_Dt')	
	   
	END


	IF CHARINDEX('PIM01106.RECEIPT_DT',@cFilter)>0
	BEGIN
		IF @cXntype NOT IN ('PUR','GRP_PUR')	
	 	 
		 SET @cFilter=REPLACE(@cFilter,'PIM01106.RECEIPT_DT','sku_names.purchase_receipt_Dt')
	  
	END


	--ELSE
	IF CHARINDEX('transaction_no',@cFilter)>0
	BEGIN
		IF @cXntype IN ('PUR','GRP_PUR')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','pim01106.mrr_no')
		ELSE
	    IF @cXntype IN ('WSL','GRP_WSL','DLV_INV')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','inm01106.inv_no')
		ELSE
		IF @cXntype IN ('PRT','GRP_PRT')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','rmm01106.rm_no')	
		ELSE
		IF @cXntype IN ('WPI','WPR','WPS')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','wps_mst.ps_no')		
		ELSE
		IF @cXntype IN ('WSR','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','cnm01106.cn_no')						
		ELSE
		IF @cXntype IN ('SLS','SLR','NSLS')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','cmm01106.cm_no')		
		ELSE
		IF @cXntype IN ('JWI')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','jobwork_issue_mst.issue_no')		
		ELSE
		IF @cXntype IN ('JWR')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','jobwork_receipt_mst.receipt_no')
		ELSE
		IF @cXntype IN ('CNC','UNC')
			SET @cFilter=REPLACE(@cFilter,'transaction_no','ICM01106.cnc_memo_no')	
	END
	--ELSE
	IF CHARINDEX('party_name',@cFilter)>0
	BEGIN
		IF @cXntype IN ('SLS','SLR','NSLS','APP','APR')
			SET @cFilter=REPLACE(@cFilter,'party_name','party_custdym.customer_fname+char(13)+party_custdym.customer_lname')		
		ELSE
		IF @cXntype IN ('GRP_WSL','GRP_PRT','GIT','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'party_name','TargetLocation.dept_name')		
		ELSE
		IF @cXntype IN ('GRP_PUR')
			SET @cFilter=REPLACE(@cFilter,'party_name','targetlocation.dept_name')	
		
		else
			SET @cFilter=REPLACE(@cFilter,'party_name','party_lm01106.ac_name')		
	END
	--ELSE
	IF CHARINDEX('party_alias',@cFilter)>0
	BEGIN
		IF @cXntype IN ('SLS','SLR','NSLS')
			SET @cFilter=REPLACE(@cFilter,'party_alias','party_custdym.title')		
		ELSE
		IF @cXntype IN ('GRP_WSL','GRP_PRT','GIT','GRP_PUR','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'party_name','TargetLocation.dept_alias')		
		ELSE
		IF @cXntype IN ('GRP_PUR','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'party_name','TargetLocation.dept_alias')		
		ELSE

			SET @cFilter=REPLACE(@cFilter,'party_alias','party_lm01106.alias')		
	END

	--ELSE
	IF CHARINDEX('party_state',@cFilter)>0
	BEGIN
		IF @cXntype IN ('GRP_WSL','GRP_PRT','GIT')
			SET @cFilter=REPLACE(@cFilter,'party_state','TargetLocation_state.state')		
		ELSE
		IF @cXntype IN ('GRP_PUR','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'party_state','TargetLocation_state.state')		
	END
	--ELSE

	IF CHARINDEX('PARTY_CITY.CITY',@cFilter)>0
	BEGIN
		IF @cXntype IN ('GRP_WSL','GRP_PRT','GIT')
			SET @cFilter=REPLACE(@cFilter,'PARTY_CITY.CITY','TargetLocation_city.CITY')		
		ELSE
		IF @cXntype IN ('GRP_PUR','GRP_WSR')
			SET @cFilter=REPLACE(@cFilter,'PARTY_CITY.CITY','TargetLocation_city.CITY')		
	END
	--ELSE

	IF CHARINDEX('EOSS_CATEGORY',@cFilter)>0
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'EOSS_CATEGORY','ISNULL(EOSS_CATEGORY,''Fresh'')')
	END

	

	
	IF CHARINDEX('ITEM_CODE_WO_BATCH',@cFilter)>0
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'ITEM_CODE_WO_BATCH','LEFT(sku_names.product_code,ISNULL(NULLIF(CHARINDEX (''@'',sku_names.product_code)-1,-1),LEN(sku_names.product_code )))')
	END


	IF @cXntype IN ('CON_SLS')
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'999','XXX')		
	END

	IF @cXntype IN ('SLS','SLR','NSLS')
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'party_lmp01106.mobile','PARTY_CUSTDYM.mobile')		
	END


	IF @cXntype IN ('POPEN')
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'SKU_NAMES.PARA5_NAME','PARA5.PARA5_NAME')		
	END

	IF @cXntype NOT IN ('POPEN')
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'POM01106.PO_DT BETWEEN','''2099-01-01''  NOT BETWEEN')		
	END


	IF CHARINDEX('TRANSACTION_REMARKS',@cFilter)>0
	BEGIN
		IF @cXntype IN ('CNC','UNC')
			SET @cFilter=REPLACE(@cFilter,'TRANSACTION_REMARKS','ICM01106.REMARKS')
		ELSE
		IF @cXntype IN ('PUR','GRP_PUR')
		SET @cFilter=REPLACE(@cFilter,'TRANSACTION_REMARKS','PIM01106.REMARKS')

		ELSE
		IF @cXntype IN ('SLS','SLR','NSLS')
		SET @cFilter=REPLACE(@cFilter,'TRANSACTION_REMARKS','CMM01106.REMARKS')

		ELSE
		IF @cXntype IN ('WSL','GRP_WSL')
		SET @cFilter=REPLACE(@cFilter,'TRANSACTION_REMARKS','INM01106.REMARKS')

		ELSE
		IF @cXntype IN ('WSR','GRP_WSR')
		SET @cFilter=REPLACE(@cFilter,'TRANSACTION_REMARKS','CNM01106.REMARKS')

		ELSE
		IF @cXntype IN ('IRR')
		SET @cFilter=REPLACE(@cFilter,'TRANSACTION_REMARKS','IRM01106.REMARKS')
		
	END



	IF CHARINDEX('TRANSACTION_PURCHASE_BILL_NO',@cFilter)>0
	BEGIN
		SET @cFilter=REPLACE(@cFilter,'TRANSACTION_PURCHASE_BILL_NO','(case when pim01106.inv_no ='''' then pim01106.bill_no else pim01106.inv_no end)')
		
	END


	--PRINT @cFilter

END