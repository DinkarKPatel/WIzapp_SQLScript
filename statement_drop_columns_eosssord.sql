if exists (select top 1 table_name from information_schema.table_constraints where table_name='eosssord'
			and constraint_name='FK_EOSSSORD_DTM')
	alter table EOSSSORd drop constraint FK_EOSSSORD_DTM

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='dt_name'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column dt_name

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='dt_code'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column dt_code

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='claimed_base_discount'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column claimed_base_discount

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='claimed_base_less_gm'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column claimed_base_less_gm

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='pur_gst_pct'
		   AND TABLE_NAME='eosssord')
	alter table eosssord drop column pur_gst_pct

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='gst_percentage'
		   AND TABLE_NAME='eosssord')
	alter table eosssord drop column gst_percentage

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='discount_sharing_base'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column discount_sharing_base

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='pur_bill_no'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column pur_bill_no

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='pur_bill_dt'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column pur_bill_dt

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='gm_type'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column gm_type

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='EOSS_FRESH'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column EOSS_FRESH

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='TOTAL_DISCOUNT_AMOUNT'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column TOTAL_DISCOUNT_AMOUNT

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='NET_DIFF'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column NET_DIFF

if exists (select column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE COLUMN_NAME='TERMS'
		   AND TABLE_NAME='eosssord')
	alter table EOSSSORd drop column TERMS


