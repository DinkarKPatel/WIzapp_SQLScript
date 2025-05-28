if EXISTS (select tablename from XNS_UPLOAD_COLS where tablename='CMM01106')
BEGIN
	UPDATE XNS_UPLOAD_COLS SET columnname=columnname+',location_code' WHERE  tablename='CMM01106' and columnname not like '%LOCATION_CODE%'
END