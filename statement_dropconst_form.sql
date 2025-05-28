IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_form_exciseduty_ac')
alter table form drop constraint FK_form_exciseduty_ac

IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_form_exciseeducess_ac') 
alter table form drop constraint FK_form_exciseeducess_ac

IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_form_exciseheducess_ac') 
alter table form drop constraint FK_form_exciseheducess_ac
 
IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_form_pur_return_ac_code')
alter table form drop constraint FK_form_pur_return_ac_code

IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_form_sale_return_ac_code') 
alter table form drop constraint FK_form_sale_return_ac_code

IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_purchase_ac_code') 
alter table form drop constraint FK_purchase_ac_code

IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_sales_ac_code') 
alter table form drop constraint FK_sales_ac_code

IF EXISTS(select CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='FK_tax_ac_code') 
alter table form drop constraint FK_tax_ac_code



