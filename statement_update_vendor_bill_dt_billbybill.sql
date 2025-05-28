update a set PUR_VENDOR_BILL_DT=d.inv_dt from bill_by_bill_ref a 
join vd01106 b on a.vd_id=b.vd_id
join POSTACT_VOUCHER_LINK c on c.vm_id=b.vm_id
join pim01106 d on d.mrr_id=c.memo_id
where c.XN_TYPE='PUR'


update d set PUR_VENDOR_BILL_DT=a.PUR_VENDOR_BILL_DT from bill_by_bill_ref a
join vd01106 b on a.vd_id=b.vd_id
join vm01106 c on c.vm_id=b.vm_id
join POSTACT_VOUCHER_LINK v on v.vm_id=c.vm_id
join bill_by_bill_ref d on d.ref_no=a.ref_no
join vd01106 e on e.vd_id=d.vd_id and e.ac_code=b.ac_code
join vm01106 f on f.vm_id=e.vm_id
where v.XN_TYPE='PUR' and f.voucher_code='0000000002'

