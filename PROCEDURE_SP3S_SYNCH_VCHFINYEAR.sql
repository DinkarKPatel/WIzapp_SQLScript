CREATE PROCEDURE SP3S_SYNCH_VCHFINYEAR
AS
BEGIN
	update vm01106 set fin_year='01'+dbo.fn_getfinyear(voucher_dt) 
	where fin_year<>'01'+dbo.fn_getfinyear(voucher_dt)
END