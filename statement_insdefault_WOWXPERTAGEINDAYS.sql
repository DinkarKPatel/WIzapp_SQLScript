if not exists (select top 1 ageing_mode from WOW_XPERT_AGEINDAYS)
BEGIN
	insert into WOW_XPERT_AGEINDAYS (ageing_mode,srno,ageing_days)
	select mode,sr,ageing_days from XTREME_AGEINGDAYS
END