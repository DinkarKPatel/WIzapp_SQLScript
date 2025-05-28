UPDATE rep_mst SET rep_code= 'X001',user_rep_type=user_rep_type+'(Sale Analysis)' where rep_code= 'c001'  

UPDATE rep_DET SET rep_code= 'X001' where rep_code= 'c001'  

UPDATE rep_det set key_col= 'NAQ' WHERE KEY_COL= 'NETCMAQ' and REP_CODE= 'C001'

DELETE   from rep_det where rep_code= 'C001' and Calculative_col =1 and col_header like '%App%'

update a set a.BASIC_COL = b.master_col,a.rep_code= 'X001'
from rep_det  a join xtreme_reports_exp_COLS b on a.key_col = b.calculative_col 
where a.rep_code= 'C001' and a.Calculative_col =1

UPDATE REP_DET SET COL_EXPR= 'PP' , col_mst = 'SKU_NAMES.PP',table_name = 'SKU_NAMES' ,
key_col= 'PP' where col_expr= 'PURCHASE_PRICE' and rep_code in ('C001','X001')

UPDATE REP_DET SET COL_EXPR= 'MRP' , col_mst = 'SKU_NAMES.MRp',table_name = 'SKU_NAMES' ,
key_col= 'MRP' where col_expr= 'MRP' and rep_code in ('C001','X001')

UPDATE REP_DET SET table_name = '' WHERE COL_EXPR in ('CM_NO','CM_DT') 
AND REP_CODE  IN ('X001','C001')


Update rep_sch set Rep_type = 'XNS' where rep_type= 'CRM'

Update rep_crm set rep_code = 'x001' where rep_code= 'C001'





