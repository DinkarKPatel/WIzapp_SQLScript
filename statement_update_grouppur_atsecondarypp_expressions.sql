UPDATE b set column_id='C1270' from wow_xpert_report_cols_xntypewise a join wow_xpert_rep_det b on a.column_id=b.column_id and a.xn_type=b.xn_type
where  a.column_id in ('c1100') and (b.xn_type in ('grp_prt') or (b.xn_type='stock' and b.col_header like 'Group%'))

UPDATE b set column_id='C1271' from wow_xpert_report_cols_xntypewise a join wow_xpert_rep_det b on a.column_id=b.column_id and a.xn_type=b.xn_type
where  a.column_id in ('c1098') and (b.xn_type in ('grp_pur') or (b.xn_type='stock' and b.col_header like 'Group%'))