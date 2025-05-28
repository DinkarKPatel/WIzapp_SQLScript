update a set cd_posted=1 from bill_by_bill_ref a 
join vd01106 b on a.vd_id=b.vd_id
join BILL_BY_BILL_REF c on c.REF_NO=a.ref_no
join vd01106 d on d.vd_id=c.vd_id
where b.vm_id=d.vm_id and c.cd_posted=1 and a.cd_posted=0
