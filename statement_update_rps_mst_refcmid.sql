update a set ref_cm_id=b.cm_id from rps_mst a JOIN  pack_slip_ref b ON a.cm_id=b.PACK_SLIP_ID
where isnull(a.ref_cm_id,'')=''

update a set ref_cm_id=b.cm_id from rps_mst a join cmd01106 b (NOLOCK) ON b.pack_slip_id=a.cm_id
JOIN cmm01106 c ON c.cm_id=b.cm_id
WHERE c.CANCELLED=0 AND isnull(a.ref_cm_id,'')=''
