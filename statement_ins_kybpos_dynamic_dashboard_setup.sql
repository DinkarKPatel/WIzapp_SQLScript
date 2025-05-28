IF NOT EXISTS (SELECT TOP 1 * FROM pos_dynamic_dashboard_setup (NOLOCK) WHERE setup_id='KYB0001')
	INSERT pos_dynamic_dashboard_setup	( additional_filter_criteria, DASHBOARD_MODE, display_mode, filter_criteria, filter_description, 
	LAST_UPDATE, para_name, RAW_FILTER_EXPR, RAW_PARA, setup_id, setup_name )  
	SELECT 	  '' additional_filter_criteria,0 DASHBOARD_MODE,1 display_mode, ' 1=1 ' filter_criteria, '' filter_description,getdate() LAST_UPDATE,'dept_id' para_name, 
	'' RAW_FILTER_EXPR, '' RAW_PARA,'KYB0001' AS setup_id, 'KYB' AS setup_name