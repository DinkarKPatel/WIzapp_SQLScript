INSERT wow_xpert_rep_det	( col_header, col_order, col_width, column_id, decimal_place, dimension, grp_total, Measurement_col, rep_id, row_id, xn_type )  
SELECT 	 'Stock Na' col_header,0 col_order,5 col_width,'C0042' column_id,2 decimal_place,0 dimension, 0 grp_total,0 Measurement_col, a.rep_id,newid() row_id, a.xn_type 
FROM wow_xpert_rep_det a LEFT JOIN wow_xpert_rep_det b on a.rep_id=b.rep_id AND b.column_id='C0042'
JOIN  wow_xpert_rep_mst c on c.rep_id=a.rep_id 
where c.xpert_rep_code='r1' and b.rep_id is null
group by a.rep_id, a.xn_type 

