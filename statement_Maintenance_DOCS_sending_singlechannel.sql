IF NOT EXISTS (SELECT TOP 1 * FROM config (NOLOCK) WHERE config_option='maintainance_docs_singlechannel' and value='1')
begin
	update a set doc_synch_last_update=a.last_update from inm01106 a
	join pim01106 b on a.inv_id=b.inv_id
	left outer join upload_mirrordoc c on c.xn_id=a.inv_id and c.xn_type='DOCWSL'
	where a.inv_mode=2 AND c.xn_id is NULL

	update a set doc_synch_last_update=a.last_update from rmm01106 a
	join cnm01106 b on a.rm_id=b.rm_id 
	left outer join upload_mirrordoc c on c.xn_id=a.rm_id and c.xn_type='DOCPRT'
	where a.mode=2 AND  c.xn_id is NULL

	UPDATE a set doc_synch_last_update=a.last_update from pom01106 a 
	LEFT OUTER JOIN  upload_mirrordoc b ON  a.po_id=b.xn_id AND b.xn_id='DOCPO'
	WHERE b.xn_id IS NULL

	UPDATE a set doc_synch_last_update=a.last_update from pco_mst a 
	LEFT OUTER JOIN  upload_mirrordoc b ON  a.memo_id=b.xn_id AND b.xn_id='DOCPCO'
	WHERE b.xn_id IS NULL

	UPDATE a set doc_synch_last_update=a.last_update from gv_stkxfer_mst a 
	LEFT OUTER JOIN  upload_mirrordoc b ON  a.memo_id=b.xn_id AND b.xn_id='DOCGV'
	WHERE b.xn_id IS NULL

	UPDATE a set doc_synch_last_update=a.last_update from pim01106 a 
	LEFT OUTER JOIN  upload_mirrordoc b ON  a.mrr_id=b.xn_id AND b.xn_id='DOCPUR'
	WHERE b.xn_id IS NULL

	UPDATE a set doc_synch_last_update=a.last_update from asn_mst a 
	LEFT OUTER JOIN  upload_mirrordoc b ON  a.memo_id=b.xn_id AND b.xn_id='DOCASN'
	WHERE b.xn_id IS NULL

	UPDATE a set doc_synch_last_update=a.last_update from buyer_order_mst a 
	LEFT OUTER JOIN  upload_mirrordoc b ON  a.order_id=b.xn_id AND b.xn_id='DOCWBO'
	WHERE b.xn_id IS NULL

	IF NOT EXISTS (SELECT TOP 1 * FROM config (NOLOCK) WHERE config_option='maintainance_docs_singlechannel')
		 INSERT config	( config_option, CTRL_NAME, Description, GROUP_NAME, last_update, OPT_SR_NO, REMARKS, 
		 row_id, SET_AT_HO, value, VALUE_TYPE )  
		 SELECT  'maintainance_docs_singlechannel' config_option,'' CTRL_NAME,'' Description,null GROUP_NAME, 
		 getdate() last_update,0  OPT_SR_NO,'' REMARKS,newid() row_id,0	 SET_AT_HO,'1' value,
		 '' VALUE_TYPE 
	else
		update config set value='1' where config_option='maintainance_docs_singlechannel'

END