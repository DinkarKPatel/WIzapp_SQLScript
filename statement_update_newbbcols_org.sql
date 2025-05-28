update a SET org_bill_no=pim.bill_no,org_bill_dt=pim.bill_dt,org_bill_amount=pim.total_amount from 
bill_by_bill_ref  a
join vd01106 b on  a.vd_id=b.vd_id
join POSTACT_VOUCHER_LINK c on c.vm_id=b.vm_id
join pim01106 pim on pim.mrr_id=c.MEMO_ID
where xn_type='pur'

update a SET org_bill_no=rmm.rm_no,org_bill_dt=rmm.rm_dt,org_bill_amount=rmm.total_amount from 
bill_by_bill_ref  a
join vd01106 b on  a.vd_id=b.vd_id
join POSTACT_VOUCHER_LINK c on c.vm_id=b.vm_id
join rmm01106 rmm on rmm.rm_id=c.MEMO_ID
where xn_type='prt'

update a SET org_bill_no=pim.bill_no,org_bill_dt=pim.bill_dt,org_bill_amount=pim.total_amount from 
bill_by_bill_ref  a
JOIN vd01106 vd ON a.vd_id=vd.vd_id
JOIN  bill_by_bill_ref d on d.ref_no=a.ref_no
join vd01106 b on  d.vd_id=b.vd_id AND b.ac_code=vd.ac_code
join POSTACT_VOUCHER_LINK c on c.vm_id=b.vm_id
JOIN vm01106 vm_pur (NOLOCK) ON vm_pur.vm_id=c.vm_id
join pim01106 pim on pim.mrr_id=c.MEMO_ID
JOIN vm01106 vm ON vm.vm_id=vd.vm_id
where c.xn_type='pur' and vm.voucher_code='0000000002'
AND vm.cancelled=0 AND vm_pur.cancelled=0

update a SET org_bill_no=rmm.rm_no,org_bill_dt=rmm.rm_dt,org_bill_amount=rmm.total_amount from 
bill_by_bill_ref  a
JOIN vd01106 vd ON a.vd_id=vd.vd_id
JOIN  bill_by_bill_ref d on d.ref_no=a.ref_no
join vd01106 b on  d.vd_id=b.vd_id AND b.ac_code=vd.ac_code
join POSTACT_VOUCHER_LINK c on c.vm_id=b.vm_id
JOIN vm01106 vm_prt (NOLOCK) ON vm_prt.vm_id=c.vm_id
join rmm01106 rmm on rmm.rm_id=c.MEMO_ID
JOIN vm01106 vm ON vm.vm_id=vd.vm_id
where c.xn_type='prt' and vm.voucher_code='0000000002'
AND vm.cancelled=0 AND vm_prt.cancelled=0 AND ISNULL(a.org_bill_no,'')=''

