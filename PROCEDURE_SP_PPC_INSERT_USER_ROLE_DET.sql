CREATE PROCEDURE SP_PPC_INSERT_USER_ROLE_DET
AS
BEGIN
	IF NOT EXISTS (SELECT TOP 1 'U' FROM USER_ROLE_DET WHERE ROLE_ID='0000000')
	BEGIN
		 INSERT USER_ROLE_DET	( ROLE_ID, FORM_NAME, FORM_OPTION, VALUE, ROW_ID, LAST_UPDATE, GROUP_NAME, S_NO, DISPLAY_FORM_NAME, DISPLAY_NAME )  
		 SELECT 	 '0000000' AS ROLE_ID, FORM_NAME, FORM_OPTION, VALUE, ROW_ID, LAST_UPDATE, GROUP_NAME, S_NO, DISPLAY_FORM_NAME, DISPLAY_NAME 
		 FROM PPC_MODULES 
	 END
END
