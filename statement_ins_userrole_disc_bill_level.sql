if not exists (select top 1 * from   user_role_det where form_option='disc_bill_level' and form_name='frmsale')
	INSERT user_role_det	( DISPLAY_FORM_NAME, DISPLAY_NAME, FORM_NAME, FORM_OPTION, GROUP_NAME, LAST_UPDATE, 
	ROLE_ID, ROW_ID, S_NO, VALUE )  
	SELECT 	  DISPLAY_FORM_NAME, DISPLAY_NAME, FORM_NAME,'disc_bill_level' FORM_OPTION, GROUP_NAME, LAST_UPDATE, ROLE_ID, ROW_ID, 
	S_NO, VALUE from user_role_det where form_option='disc' and form_name='frmsale'
