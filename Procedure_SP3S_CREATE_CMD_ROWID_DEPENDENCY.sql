 
 create PROCEDURE SP3S_CREATE_CMD_ROWID_DEPENDENCY
 AS
 BEGIN

  DECLARE @CLOCID VARCHAR(2),@CHODEPT_ID VARCHAR(2)
  
  SELECT @CLOCID=value  FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'
  SELECT @CHODEPT_ID=value  FROM CONFIG WHERE CONFIG_OPTION ='ho_LOCATION_ID'


if  @CLOCID<>@CHODEPT_ID
begin
	IF OBJECT_ID('UNQ_cmd01106_row_id','uq') IS  NULL
	   Alter table cmd01106 add constraint UNQ_cmd01106_row_id  unique(row_id)

	IF  OBJECT_ID('FK_cmd_manualbill_errors_cmd','f') IS  NULL
		 Alter table cmd_manualbill_errors add Constraint FK_cmd_manualbill_errors_cmd foreign key(cmd_row_id) references cmd01106(row_id)

	IF OBJECT_ID('fk_soradj_det_cmdrowid','f') IS  NULL
	   Alter table sor_basis_adjustment_det add Constraint fk_soradj_det_cmdrowid  foreign key (cmd_row_id) references cmd01106(row_id)

	IF OBJECT_ID('FK_slr_recon_det_cmd','f') IS  NULL
	   Alter table slr_recon_det add Constraint FK_slr_recon_det_cmd    foreign key (cmd_row_id) references cmd01106(row_id)

	IF OBJECT_ID('UNQ_cmd_cons_rowid','uq') IS  NULL
	   Alter table cmd_cons add Constraint UNQ_cmd_cons_rowid    Unique (row_id) 

	IF OBJECT_ID('unq_coupon_redemption_info','uq') IS  NULL
	   Alter table coupon_redemption_info add Constraint unq_coupon_redemption_info Unique(cm_id, ecoupon_id)

	IF OBJECT_ID('UNQ_cmm_credit_receipt','uq') IS  NULL
	   Alter table cmm_credit_receipt add Constraint UNQ_cmm_credit_receipt Unique(adv_rec_id, cm_id)


end

end