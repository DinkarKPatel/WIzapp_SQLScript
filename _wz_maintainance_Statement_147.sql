
update a set a.ref_cm_id=b.cm_id from rps_mst a
join cmd01106 b on a.cm_id=b.pack_slip_id
where isnull(a.ref_cm_id,'')=''