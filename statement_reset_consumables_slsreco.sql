update a set auto_posreco_cons_last_update='' from cmm01106 a join cmd_cons b on a.cm_id=b.cm_id

update posreco_xntypes set last_synch_dt='' where xn_type='sls'
