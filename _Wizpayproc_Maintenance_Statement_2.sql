
---------------

IF NOT EXISTS ( SELECT DESIG_ID FROM EMP_DESIG WHERE DESIG_ID = '0000000' )
	INSERT INTO EMP_DESIG (DESIG_ID, DESIG_NAME, REMARKS, LAST_UPDATE)
	VALUES ('0000000', '','',GETDATE())
