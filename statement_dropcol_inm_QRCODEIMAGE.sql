if exists (select column_name from information_schema.columns where column_name='QRCODEIMAGE'
		   and table_name='inm01106')
   	alter table inm01106 drop column QRCODEIMAGE

if exists (select column_name from information_schema.columns where column_name='QRCODEIMAGE'
		   and table_name='wsl_inm01106_upload')
   	alter table wsl_inm01106_upload drop column QRCODEIMAGE

if exists (select column_name from information_schema.columns where column_name='QRCODEIMAGE'
		   and table_name='docwsl_inm01106_mirror')
   	alter table docwsl_inm01106_mirror drop column QRCODEIMAGE

