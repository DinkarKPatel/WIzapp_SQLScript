IF EXISTS (SELECT TOP 1 config_option FROM config(nolock) WHERE config_option='POSTINGCONFIG_CUSTCONTROLACCOUNT_REPLACED' and VALUE='1')
	RETURN

IF NOT EXISTS (SELECT TOP 1 config_option FROM config(nolock) WHERE config_option='CUSTOMER_CONTROL_AC_CODE')
	INSERT config	( config_option, CTRL_NAME, Description, GROUP_NAME, last_update, OPT_SR_NO, REMARKS, row_id, SET_AT_HO, value, VALUE_TYPE )  
	SELECT 'CUSTOMER_CONTROL_AC_CODE' config_option,NULL CTRL_NAME,'Customer control account for Account Posting' Description,'ACCOUNTS' GROUP_NAME,
	getdate() last_update,null OPT_SR_NO,'It is used for Posting of Retail Sales and Outstanding Receipt/Advances and their adjustments' REMARKS,
	newid() row_id,0 SET_AT_HO, value,'STRING' VALUE_TYPE 
	FROM GST_ACCOUNTS_CONFIG_DET_PAYMODES (NOLOCK) WHERE COLUMNNAME='CUSTOMER_CONTROL_AC_CODE_SALE'
ELSE
	update a set value=b.value from config a JOIN GST_ACCOUNTS_CONFIG_DET_PAYMODES b (NOLOCK) ON  b.COLUMNNAME='CUSTOMER_CONTROL_AC_CODE_SALE'
	WHERE a.config_option='CUSTOMER_CONTROL_AC_CODE' 

IF NOT EXISTS (SELECT TOP 1 config_option FROM config(nolock) WHERE config_option='CUSTOMER_CONTROL_AC_CODE')
	INSERT config	( config_option, CTRL_NAME, Description, GROUP_NAME, last_update, OPT_SR_NO, REMARKS, row_id, SET_AT_HO, value, VALUE_TYPE )  
	SELECT 'CREATE_LEDGER_FOR_EACHCUSTOMER' config_option,NULL CTRL_NAME,'Create Ledger for each Customer in Accounts Posting' Description,'ACCOUNTS' GROUP_NAME,
	getdate() last_update,null OPT_SR_NO,'It is used for creating Ledger of customer if not found on every Sale/ARC accounts posting' REMARKS,
	newid() row_id,0 SET_AT_HO, ISNULL(CREATE_LEDGER_FOR_EACHCUSTOMER,0) value,'Boolean' VALUE_TYPE 
	 FROM GST_ACCOUNTS_CONFIG_MST WHERE XN_TYPE='SLS'
ELSE
	update a set value=(CASE WHEN b.CREATE_LEDGER_FOR_EACHCUSTOMER=1 THEN '1' ELSE '0' END) from config a JOIN GST_ACCOUNTS_CONFIG_MST b (NOLOCK) ON  b.XN_TYPE='SLS'
	WHERE a.config_option='CREATE_LEDGER_FOR_EACHCUSTOMER'

IF NOT EXISTS (SELECT TOP 1 config_option FROM config(nolock) WHERE config_option='POSTINGCONFIG_CUSTCONTROLACCOUNT_REPLACED')
	INSERT config	( config_option, CTRL_NAME, Description, GROUP_NAME, last_update, OPT_SR_NO, REMARKS, row_id, SET_AT_HO, value, VALUE_TYPE )  
	SELECT 'POSTINGCONFIG_CUSTCONTROLACCOUNT_REPLACED' config_option,NULL CTRL_NAME,null Description,null GROUP_NAME,
	getdate() last_update,null OPT_SR_NO,null REMARKS,newid() row_id,0 SET_AT_HO, '1' value,null VALUE_TYPE 
ELSE
	UPDATE config SET value='1' WHERE config_option='POSTINGCONFIG_CUSTCONTROLACCOUNT_REPLACED'