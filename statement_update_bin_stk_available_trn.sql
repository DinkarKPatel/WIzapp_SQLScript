update  bin set stk_available_trn=1 where bin_id <>'999' and stk_available_trn is null
update  bin set stk_available_trn=0 where bin_id ='999'