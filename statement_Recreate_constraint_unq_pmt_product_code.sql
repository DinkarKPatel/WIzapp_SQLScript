if exists (select top 1 * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where constraint_name='unq_pmt_product_code')
	alter table pmt01106 drop constraint unq_pmt_product_code

if exists (select top 1 * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where constraint_name='PK_pmt_product_code')
	alter table pmt01106 drop constraint PK_pmt_product_code

alter table  pmt01106 add constraint unq_pmt_product_code unique(BIN_ID, DEPT_ID, product_code, bo_order_id)

