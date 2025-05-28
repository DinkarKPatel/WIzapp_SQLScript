 INSERT xnsinfo	( child_para_NAME, insertstr, insertstrvalue, keyfield, linked_master, mastercolname, mastertable, memodtcol, PARENT_para_NAME, PARENT_TABLENAME, tablename, temp_table_name, updatestr, whereclause, xn_desc, xn_download, xn_type, xns_merging_order, xns_sending_order, xns_table )  
 SELECT  child_para_NAME, a.insertstr, a.insertstrvalue, a.keyfield, 0 linked_master, mastercolname, mastertable, memodtcol, 
 PARENT_para_NAME, PARENT_TABLENAME, a.tablename, temp_table_name, a.updatestr, whereclause, xn_desc, xn_download, xn_type, 
 xns_merging_order, xns_sending_order, xns_table FROM mirrorxnsinfo a
  left outer join xnsinfo b on a.tablename=b.tablename
where b.tablename is null
