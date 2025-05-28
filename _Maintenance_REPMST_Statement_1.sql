
if  Exists (Select top 1 * from Eoss_rep_mst)
return 

INSERT Eoss_rep_mst	( appenFilterWithAdd, last_update, rep_id, rep_operator ) 
SELECT appenFilterWithAdd, last_update, rep_id, rep_operator	 FROM rep_mst 
 
INSERT Eoss_rep_filter	( cattr, cContaining, cINLIST, cnot, colDatatype,
filter_lbl, rep_id, row_id )  
SELECT 	  cattr, cContaining, cINLIST, cnot, colDatatype, filter_lbl, rep_id, row_id 
FROM rep_filter


INSERT Eoss_rep_filter_det	( attr_value, cattr, filter_lbl, rep_id, row_id ) 
SELECT 	  attr_value, cattr, filter_lbl, rep_id, row_id 
FROM rep_filter_det

