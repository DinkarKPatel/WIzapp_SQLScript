
IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='hold_back_deliver_mst' AND COLUMN_NAME='EMP_CODE')
  alter table hold_back_deliver_mst drop column EMP_CODE


IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='hbd_hold_back_deliver_mst_upload' AND COLUMN_NAME='EMP_CODE')
  alter table hbd_hold_back_deliver_mst_upload drop column EMP_CODE

IF EXISTS (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='pshbd_hold_back_deliver_mst_upload' AND COLUMN_NAME='EMP_CODE')
  alter table pshbd_hold_back_deliver_mst_upload drop column EMP_CODE

    