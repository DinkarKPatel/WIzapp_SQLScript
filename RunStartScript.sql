DECLARE @cCmd NVARCHAR(1000)
IF OBJECT_ID('SP_CREATEPAYMODEVIEW','P') IS NOT NULL
BEGIN
	SET @cCmd=N'EXEC SP_CREATEPAYMODEVIEW'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT NAME FROM SYS.triggers WHERE NAME='IO_TRIG_LMV01106')
BEGIN
	DROP TRIGGER IO_TRIG_LMV01106
END

IF EXISTS(SELECT * FROM SYSOBJECTS(NOLOCK) WHERE NAME ='CHK_POSTACT_VOUCHER_LINK_MEMOID_XNTYPE')
	ALTER TABLE POSTACT_VOUCHER_LINK DROP CONSTRAINT CHK_POSTACT_VOUCHER_LINK_MEMOID_XNTYPE

IF EXISTS(SELECT * FROM SYSOBJECTS(NOLOCK) WHERE NAME ='chk_postact_voucher_link_dup')
	ALTER TABLE POSTACT_VOUCHER_LINK DROP CONSTRAINT chk_postact_voucher_link_dup

IF OBJECT_ID('chk_UNQ_ART_BOM_JOB','C') IS NOT NULL	
	ALTER TABLE art_bom DROP CONSTRAINT chk_UNQ_ART_BOM_JOB

IF OBJECT_ID('CHK_DUPBBREF','C') IS NOT NULL	
	ALTER TABLE BILL_BY_BILL_REF DROP CONSTRAINT CHK_DUPBBREF

IF OBJECT_ID('CheckDUp_art_para1','C') IS NOT NULL	
	ALTER TABLE art_para1 DROP CONSTRAINT CheckDUp_art_para1

IF OBJECT_ID('CheckDUp_lm_Ac_name','C') IS NOT NULL	
	ALTER TABLE lm01106 DROP CONSTRAINT CheckDUp_lm_Ac_name



IF EXISTS(SELECT * FROM SYSOBJECTS(NOLOCK) WHERE NAME ='CHK_LMP01106_DUP_CUSTCODE')
	ALTER TABLE LMP01106 DROP CONSTRAINT CHK_LMP01106_DUP_CUSTCODE

IF EXISTS(SELECT TOP 1 table_name FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS (NOLOCK) WHERE CONSTRAINT_NAME ='unq_series_setup_manual_det_rowid')
	ALTER TABLE series_setup_manual_det drop constraint unq_series_setup_manual_det_rowid

IF EXISTS(SELECT TOP 1 table_name FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS (NOLOCK) WHERE CONSTRAINT_NAME ='unq_transaction_analysis_master_COLS')
	ALTER TABLE transaction_analysis_master_COLS drop constraint unq_transaction_analysis_master_COLS

IF EXISTS(SELECT TOP 1 table_name FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS (NOLOCK) WHERE CONSTRAINT_NAME ='unq_transaction_analysis_calculative_COLS')
	ALTER TABLE transaction_analysis_calculative_COLS drop constraint unq_transaction_analysis_calculative_COLS
--drop new 
IF OBJECT_ID('chk_parcel_dup','C') IS NOT NULL	
	ALTER TABLE parcel_det DROP CONSTRAINT chk_parcel_dup

IF OBJECT_ID('CK_Unq_parcel','C') IS NOT NULL	
	ALTER TABLE parcel_mst DROP CONSTRAINT CK_Unq_parcel

	 
IF OBJECT_ID('FN_CheckNamesLoc') IS NOT NULL
BEGIN
	IF OBJECT_ID('chk_article_no','C') IS NOT NULL	
		ALTER TABLE article DROP CONSTRAINT chk_article_no

	IF OBJECT_ID('chk_subsection_name','C') IS NOT NULL	
		ALTER TABLE SECTIOND DROP CONSTRAINT chk_subsection_name


	IF OBJECT_ID('chk_section_name','C') IS NOT NULL	
		ALTER TABLE SECTIONM DROP CONSTRAINT chk_section_name
	
END


IF OBJECT_ID('unq_gv_gen_det','C') IS NOT NULL	
	ALTER TABLE gv_gen_det DROP CONSTRAINT unq_gv_gen_det

IF OBJECT_ID('CHK_UNIQUE_PRODUCT_CODE','C') IS NOT NULL	
	ALTER TABLE WSL_ORDER_DET DROP CONSTRAINT CHK_UNIQUE_PRODUCT_CODE

IF OBJECT_ID('CK_Dup_Report','C') IS NOT NULL	
	ALTER TABLE rep_mst DROP CONSTRAINT CK_Dup_Report

IF OBJECT_ID('ck_unique_parcel ','C') IS NOT NULL	
	ALTER TABLE Parcel_mst DROP CONSTRAINT ck_unique_parcel 


IF OBJECT_ID('PID_PIM_TEMP','U') IS NOT NULL  
       DROP TABLE PID_PIM_TEMP  



IF EXISTS (SELECT TOP 1 * FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE COLUMN_NAME='config_section'
			and TABLE_NAME='config') 	
BEGIN	
	DECLARE @cTableBkp VARCHAR(30)

	SET @cTableBkp='CONFIG_BKP_'+convert(varchar,getdate(),112)
	EXEC SP_EXECUTESQL @cCmd	
	
	SET @cCmd=N'SELECT * INTO '+@cTableBkp+' from config'
	EXEC SP_EXECUTESQL @cCmd	
	
	SET @cCmd=N'update config set config_option=''barcode_prefix'' where 
				config_option=''prefix'''
	EXEC SP_EXECUTESQL @cCmd	

	SET @cCmd=N'update config set config_option=''SLS_SYNC_AFTER'' where 
				config_section=''SLS_SYNC_AFTER'''
	EXEC SP_EXECUTESQL @cCmd	

	SET @cCmd=N'with cteLoc as
				(SELECT isnull(dept_id,'''') as dept_id,config_option,value,row_number() over 
				(partition by isnull(dept_id,''''),config_option order by dept_id,config_option) as rno
				 FROM config (NOLOCK)
				 where config_option in (''last_run_date'',''DO_NOT_ENFORCE_LAST_RUN_DT'',''last_run_date_wenc'')
				)
				INSERT config_loc (dept_id,config_option,value)
				select dept_id,config_option,value from cteLoc where rno=1
				'
	EXEC SP_EXECUTESQL @cCmd	

		
	SET @cCmd=N'update config set config_option=config_section+''_''+config_option where 
				config_option in (''PICK_FREIGHT'',''PICK_OTHER_CHARGES'',
				''PICK_ROUND_OFF'')'
	EXEC SP_EXECUTESQL @cCmd	

	SET @cCmd=N'update config set config_option=config_section+''_''+config_option
				where config_option IN (''SALES_PERSON_AT_ITEM_LEVEL'',''RETAIN_W8_SERIES'',
				''ITEM_LEVEL_ROUND_OFF'',''ROUND_OFF_GST'',''CALCULATE_GST_IN_CHALLAN'',
				''round_item_net'',''debug_mode'',''ROUND_BILL_LEVEL'')
				OR config_section in (''CONSIDER_FOR_AUTO_BATCH'',''MSTUSRROLE'',''MANUAL_MST_PREFIX'')'
	EXEC SP_EXECUTESQL @cCmd	
		   
	SET @cCmd=N'update config set config_option=config_option+''_caption''
	where  config_option in (''para1'',''para2'',''para3'',''para4'',
	''para5'',''para6'')'
		   
	EXEC SP_EXECUTESQL @cCmd	
		   
	SET @cCmd=N'DELETE A FROM config a JOIN STRUCOMP_to_be_deleted_config_COMP b
	ON a.config_section=b.config_section and a.config_option=b.config_option'

	EXEC SP_EXECUTESQL @cCmd	

	SET @cCmd=N'ALTER TABLE config DROP COLUMN config_section'
	EXEC SP_EXECUTESQL @cCmd	
END

;with cteDupConfig
as
(select *,row_number() over ( partition by config_option order by config_option ) as rno
 from config)

DELETE FROM cteDupConfig WHERE rno>1

if exists (select column_name from INFORMATION_SCHEMA.columns where column_name='dept_id' and table_name='config')
alter table config drop column dept_id

UPDATE BIN SET stk_available_trn=1 WHERE major_bin_id='999' AND ISNULL(stk_available_trn,0)<>1

---Need to do this because of Unique Constraint failure error coming on many clients 
---Which gets corrected only after latest version of Proc : exec sp3s_build_xpertreporting_expressions
---and It rund only on successful running of Console (Date:20-12-2021)
IF OBJECT_ID('transaction_analysis_MASTER_COLS','U') is not null
BEGIN
	DELETE from transaction_analysis_MASTER_COLS

	DELETE from transaction_analysis_calculative_COLS
END

EXEC SPWOW_MANAGE_TVP_PROCS 
@nMode=2

