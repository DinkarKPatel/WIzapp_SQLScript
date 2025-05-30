
IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='irr_irm01106_upload' AND COLUMN_NAME='IRR_MEMO_ID')
  alter table irr_irm01106_upload drop column IRR_MEMO_ID

IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='irr_ird01106_upload' AND COLUMN_NAME='IRR_MEMO_ID')
  alter table irr_ird01106_upload drop column IRR_MEMO_ID

IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='PFI_ORD_PLAN_BOM_DET_UPLOAD' AND COLUMN_NAME='PFI_MEMO_ID')
  alter table PFI_ORD_PLAN_BOM_DET_UPLOAD drop column PFI_MEMO_ID

IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='PFI_ORD_PLAN_BARCODE_DET_UPLOAD' AND COLUMN_NAME='PFI_MEMO_ID')
  alter table PFI_ORD_PLAN_BARCODE_DET_UPLOAD drop column PFI_MEMO_ID
