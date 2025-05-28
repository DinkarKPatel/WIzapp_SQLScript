--- Make all existing client to have default Sale return discount picking method as Max discount as per
--- Gupta Creation Tickit##0523-00163 (Date : 16-05-2023)
IF EXISTS (SELECT TOP 1 config_option from config (NOLOCK) WHERE config_option='update_location_DISCOUNT_PICKMODE_SLR_max' AND value='1')
	RETURN

UPDATE location SET DISCOUNT_PICKMODE_SLR=2

IF NOT EXISTS (SELECT TOP 1 config_option from config (NOLOCK) WHERE config_option='update_location_DISCOUNT_PICKMODE_SLR_max')
	 INSERT config	( config_option, value, row_id, last_update, REMARKS, CTRL_NAME, VALUE_TYPE, OPT_SR_NO, Description, GROUP_NAME, 
	 SET_AT_HO )  
	 SELECT 'update_location_DISCOUNT_PICKMODE_SLR_max' config_option,'1' value,newid() row_id, 
	 getdate() last_update,' Update new option of applying Sale return discount as Max for existing Locations' REMARKS, 
	 null CTRL_NAME,null VALUE_TYPE,null OPT_SR_NO,'' Description,null GROUP_NAME,0 SET_AT_HO
ELSE
	UPDATE config set value='1' WHERE config_option='update_location_DISCOUNT_PICKMODE_SLR_max'

	