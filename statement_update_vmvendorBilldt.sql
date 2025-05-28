update a set posted_vendor_bill_dt=c.inv_dt from vm01106 a WITH (ROWLOCK)
JOIN POSTACT_VOUCHER_LINK b (NOLOCK) on b.VM_ID=a.vm_id
JOIN pim01106 c (NOLOCK) ON c.mrr_id=b.MEMO_ID
where b.XN_TYPE='PUR'