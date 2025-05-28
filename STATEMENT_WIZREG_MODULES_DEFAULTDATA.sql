--FRMPENDINGREGISTRATION
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ACCESS' AND form_name='FRMPENDINGREGISTRATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMPENDINGREGISTRATION'form_name, 'ACCESS'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'PENDING REGISTRATION'display_form_name, 'ACCESS'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ADD' AND form_name='FRMPENDINGREGISTRATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMPENDINGREGISTRATION'form_name, 'ADD'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'PENDING REGISTRATION'display_form_name, 'ADD'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='VIEW' AND form_name='FRMPENDINGREGISTRATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id)
  SELECT '0000000'user_code, 'FRMPENDINGREGISTRATION'form_name, 'VIEW'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'PENDING REGISTRATION'display_form_name, 'VIEW'display_name, null dept_id; 
  
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='DELETE' AND form_name='FRMPENDINGREGISTRATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMPENDINGREGISTRATION'form_name, 'DELETE'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'PENDING REGISTRATION'display_form_name, 'DELETE'display_name, null dept_id;

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='EDIT' AND form_name='FRMPENDINGREGISTRATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMPENDINGREGISTRATION'form_name, 'EDIT'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'PENDING REGISTRATION'display_form_name, 'EDIT'display_name, null dept_id;
  
  
--FRMCLIENTMASTER
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ACCESS' AND FORM_NAME='FRMCLIENTMASTER')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMCLIENTMASTER'form_name, 'ACCESS'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'CLIENT MASTER'display_form_name, 'ACCESS'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ADD' AND FORM_NAME='FRMCLIENTMASTER')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMCLIENTMASTER'form_name, 'ADD'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'CLIENT MASTER'display_form_name, 'ADD'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='VIEW' AND FORM_NAME='FRMCLIENTMASTER')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id)
  SELECT '0000000'user_code, 'FRMCLIENTMASTER'form_name, 'VIEW'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'CLIENT MASTER'display_form_name, 'VIEW'display_name, null dept_id; 
  
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='DELETE' AND FORM_NAME='FRMCLIENTMASTER')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMCLIENTMASTER'form_name, 'DELETE'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'CLIENT MASTER'display_form_name, 'DELETE'display_name, null dept_id;

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='EDIT' AND FORM_NAME='FRMCLIENTMASTER')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMCLIENTMASTER'form_name, 'EDIT'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'CLIENT MASTER'display_form_name, 'EDIT'display_name, null dept_id;
  
--FRMLISTOFACTIVATION
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ACCESS' AND FORM_NAME='FRMLISTOFACTIVATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFACTIVATION'form_name, 'ACCESS'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF ACTIVE REGISTRATION'display_form_name, 'ACCESS'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ADD' AND FORM_NAME='FRMLISTOFACTIVATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFACTIVATION'form_name, 'ADD'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF ACTIVE REGISTRATION'display_form_name, 'ADD'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='VIEW' AND FORM_NAME='FRMLISTOFACTIVATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id)
  SELECT '0000000'user_code, 'FRMLISTOFACTIVATION'form_name, 'VIEW'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF ACTIVE REGISTRATION'display_form_name, 'VIEW'display_name, null dept_id; 
  
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='DELETE' AND FORM_NAME='FRMLISTOFACTIVATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFACTIVATION'form_name, 'DELETE'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF ACTIVE REGISTRATION'display_form_name, 'DELETE'display_name, null dept_id;

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='EDIT' AND FORM_NAME='FRMLISTOFACTIVATION')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFACTIVATION'form_name, 'EDIT'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF ACTIVE REGISTRATION'display_form_name, 'EDIT'display_name, null dept_id;
  

--FRMLISTOFMODULES
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ACCESS' AND FORM_NAME='FRMLISTOFMODULES')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFMODULES'form_name, 'ACCESS'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF MODULES'display_form_name, 'ACCESS'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='ADD' AND FORM_NAME='FRMLISTOFMODULES')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFMODULES'form_name, 'ADD'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF MODULES'display_form_name, 'ADD'display_name, null dept_id; 

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='VIEW' AND FORM_NAME='FRMLISTOFMODULES')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id)
  SELECT '0000000'user_code, 'FRMLISTOFMODULES'form_name, 'VIEW'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF MODULES'display_form_name, 'VIEW'display_name, null dept_id; 
  
IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='DELETE' AND FORM_NAME='FRMLISTOFMODULES')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFMODULES'form_name, 'DELETE'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF MODULES'display_form_name, 'DELETE'display_name, null dept_id;

IF NOT EXISTS(SELECT TOP 1 FORM_NAME FROM WIZREG_MODULES WHERE GROUP_NAME='WIZREG' AND form_option='EDIT' AND FORM_NAME='FRMLISTOFMODULES')
  INSERT WIZREG_MODULES	(user_code, form_name, form_option, value, row_id, last_update, group_name, S_NO, display_form_name, display_name, dept_id )  
  SELECT '0000000'user_code, 'FRMLISTOFMODULES'form_name, 'EDIT'form_option, 1 value, newid()row_id, getdate()last_update, 'WIZREG'group_name, 0 S_NO, 'LIST OF MODULES'display_form_name, 'EDIT'display_name, null dept_id;  
