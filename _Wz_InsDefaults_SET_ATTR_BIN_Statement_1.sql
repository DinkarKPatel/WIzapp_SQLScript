IF NOT EXISTS(SELECT BIN_ID FROM BIN WHERE BIN_ID='000')
BEGIN
	INSERT INTO BIN(BIN_ID,BIN_NAME,BIN_ALIAS,INACTIVE,LAST_UPDATE,MAJOR_BIN_ID)
	VALUES('000','DEFAULT BIN','DB',0,GETDATE(),'000')
END
