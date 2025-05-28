 create PROCEDURE SP3S_DROP_CMD_ROWID_DEPENDENCY
 AS
 BEGIN

  DECLARE @CLOCID VARCHAR(2),@CHODEPT_ID VARCHAR(2)
  
  SELECT @CLOCID=value  FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'
  SELECT @CHODEPT_ID=value  FROM CONFIG WHERE CONFIG_OPTION ='ho_LOCATION_ID'

  if @CLOCID=@CHODEPT_ID
  begin

  
	IF  OBJECT_ID('FK_cmd_manualbill_errors_cmd','f') IS not NULL
		 Alter table cmd_manualbill_errors drop Constraint FK_cmd_manualbill_errors_cmd 

	IF OBJECT_ID('fk_soradj_det_cmdrowid','f') IS not  NULL
	   Alter table sor_basis_adjustment_det drop Constraint fk_soradj_det_cmdrowid  

	IF OBJECT_ID('FK_slr_recon_det_cmd','f') IS not NULL
	   Alter table slr_recon_det drop Constraint FK_slr_recon_det_cmd   

    
	IF OBJECT_ID('fk_soradj_det_cmdrowid','f') IS not NULL
	   Alter table sor_basis_adjustment_det drop Constraint fk_soradj_det_cmdrowid   


	IF OBJECT_ID('UNQ_cmd_cons_rowid','uq') IS not  NULL
	   Alter table cmd_cons drop Constraint UNQ_cmd_cons_rowid  

	IF OBJECT_ID('unq_coupon_redemption_info','uq') IS not  NULL
	   Alter table coupon_redemption_info drop Constraint unq_coupon_redemption_info 

	
	IF OBJECT_ID('UNQ_cmd01106_row_id','uq') IS not NULL
	   Alter table cmd01106 drop constraint UNQ_cmd01106_row_id  
	
	IF OBJECT_ID('UNQ_Rowid','UQ')  IS not NULL
		ALTER TABLE paymode_xn_det drop constraint UNQ_Rowid

	IF OBJECT_ID('UNQ_cmm_credit_receipt','UQ')  IS not NULL
		ALTER TABLE cmm_credit_receipt drop constraint UNQ_cmm_credit_receipt
 END

end