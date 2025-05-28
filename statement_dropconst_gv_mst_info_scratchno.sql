if exists (select constraint_name from  information_schema.TABLE_CONSTRAINTS where constraint_name='unq_gv_mst_info_scratchno')
	alter table gv_mst_info drop constraint unq_gv_mst_info_scratchno