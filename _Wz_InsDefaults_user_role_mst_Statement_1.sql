--*** DEFAULT USER ROLE [ADMIN] ENTRY IN USER ROLE MASTER TABLE
IF NOT EXISTS ( SELECT ROLE_ID FROM USER_ROLE_MST WHERE ROLE_ID = '0000000' )
BEGIN
	INSERT USER_ROLE_MST ( ROLE_ID,ROLE_NAME )
	VALUES ('0000000', 'ADMIN')
END
