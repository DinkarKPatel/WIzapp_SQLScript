IF EXISTS (SELECT * FROM SYS.FOREIGN_KEYS WHERE name='fk_picklist_para2_code')
	alter table ind01106 drop constraint fk_picklist_para2_code

IF EXISTS (SELECT * FROM SYS.FOREIGN_KEYS WHERE name='fk_picklist_para1_code')
	alter table ind01106 drop constraint fk_picklist_para1_code

IF EXISTS (SELECT * FROM SYS.FOREIGN_KEYS WHERE name='fk_picklist_article_code')
	alter table ind01106 drop constraint fk_picklist_article_code

IF EXISTS (SELECT * FROM SYS.FOREIGN_KEYS WHERE name='FK_WSL_BUYER_ORDER')
	alter table ind01106 drop constraint FK_WSL_BUYER_ORDER