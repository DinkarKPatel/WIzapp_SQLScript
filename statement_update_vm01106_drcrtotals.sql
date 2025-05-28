update vm01106 set drtotal=b.drtotal,crtotal=b.crtotal from 
(select vm_id,sum(debit_amount) drtotal,sum(credit_amount) crtotal from vd01106 (nolock) group by vm_id) b
where b.vm_id=vm01106.vm_id and (vm01106.DRTOTAL<>b.drtotal or vm01106.CRTOTAL<>b.crtotal)