if exists (select top 1 column_name from  INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE COLUMN_NAME='igst_amount'
		   and TABLE_NAME='snc_barcode_det')
	alter table snc_barcode_det drop column igst_amount

if exists (select top 1 column_name from  INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE COLUMN_NAME='cgst_amount'
		   and TABLE_NAME='snc_barcode_det')
alter table snc_barcode_det drop column cgst_amount

if exists (select top 1 column_name from  INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE COLUMN_NAME='sgst_amount'
		   and TABLE_NAME='snc_barcode_det')
	alter table snc_barcode_det drop column sgst_amount

if exists (select top 1 column_name from  INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE COLUMN_NAME='XN_VALUE_WITHOUT_GST'
		   and TABLE_NAME='snc_barcode_det')
	alter table snc_barcode_det drop column XN_VALUE_WITHOUT_GST
