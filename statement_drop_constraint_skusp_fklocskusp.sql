
IF EXISTS (SELECT * FROM SYS.FOREIGN_KEYS WHERE name='FK_locskusp_pc')
	alter table LOCSKUSP drop constraint FK_locskusp_pc
