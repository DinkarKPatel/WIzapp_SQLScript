
IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='sku_names' AND COLUMN_NAME='hsn_code')
  alter table sku_names drop column hsn_code

IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='sku_names' AND COLUMN_NAME='barcode_coding_scheme')
  alter table sku_names drop column barcode_coding_scheme


IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='sku_names' AND COLUMN_NAME='article_desc')
  alter table sku_names drop column article_desc


  