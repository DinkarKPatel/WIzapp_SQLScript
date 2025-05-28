update a set last_update=(case when f.crtotal<>d.crtotal then getdate() else c.last_update end)
 from postact_voucher_link a 
join pim01106 b on a.memo_id=b.mrr_id
join inm01106 c on c.inv_id=b.inv_id
join postact_voucher_link e on e.memo_id=c.inv_id
join  vm01106 d on d.vm_id=a.vm_id
join  vm01106 f on f.vm_id=e.vm_id
where a.xn_type='purchi' and e.xn_type='wslcho'
and d.cancelled=0 and f.cancelled=0

update a set last_update=(case when f.crtotal<>d.crtotal then getdate() else c.last_update end)
from postact_voucher_link a 
join cnm01106 b on a.memo_id=b.cn_id
join rmm01106 c on c.rm_id=b.rm_id
join postact_voucher_link e on e.memo_id=c.rm_id
join  vm01106 d on d.vm_id=a.vm_id
join  vm01106 f on f.vm_id=e.vm_id
where a.xn_type='wsrchi' and e.xn_type='prtcho'
and d.cancelled=0 and f.cancelled=0
