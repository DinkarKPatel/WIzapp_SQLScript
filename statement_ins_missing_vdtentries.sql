INSERT vdt01106 (TDS_CODE,VD_ID,TDS_AC_CODE,TDS_PER,TDS_AMT,SURCHARGE_PER,SURCHARGE_AMT,EDU_PER,EDU_AMT,ROW_ID,COMPANY_CODE,LAST_UPDATE,tds_bill_amount)
SELECT  A.TDS_CODE,c.VD_ID,a.ac_code AS TDS_AC_CODE,tds.TDS_PERCENTAGE AS TDS_PER,A.TDS_AMOUNT,
0 AS SURCHARGE_PER,0 AS SURCHARGE_AMT,0 AS EDU_PER,0 AS EDU_AMT,NEWID() AS ROW_ID,
'01' AS COMPANY_CODE,GETDATE() AS LAST_UPDATE,A.TOTAL_AMOUNT
FROM PIM01106 A
JOIN TDS_SECTION TDS ON TDS.TDS_CODE=A.TDS_CODE
JOIN postact_voucher_link B (NOLOCK) ON A.mrr_ID=B.MEMO_ID
JOIN vd01106 C (NOLOCK) ON C.vm_ID=B.vm_ID
join vm01106 e (nolock) on e.vm_id=c.vm_id
left join vdt01106 d (nolock) on d.vd_id=c.vd_id
WHERE  ISNULL(a.tds_amount,0)<>0 AND c.credit_amount=a.total_amount
and a.xn_item_type=4 and a.cancelled=0 and d.vd_id is  null AND e.cancelled=0
and b.xn_type='pur'


INSERT vdt01106 (TDS_CODE,VD_ID,TDS_AC_CODE,TDS_PER,TDS_AMT,SURCHARGE_PER,SURCHARGE_AMT,EDU_PER,EDU_AMT,ROW_ID,
COMPANY_CODE,LAST_UPDATE,tds_bill_amount)
SELECT A.TDS_CODE,c.VD_ID,PAYABLE_AC_CODE AS TDS_AC_CODE,tds.TDS_PERCENTAGE AS TDS_PER,A.tds,
0 AS SURCHARGE_PER,0 AS SURCHARGE_AMT,0 AS EDU_PER,0 AS EDU_AMT,NEWID() AS ROW_ID,
'01' AS COMPANY_CODE,GETDATE() AS LAST_UPDATE,0 as tds_bill_amount
FROM jobwork_receipt_mst A (NOLOCK)
JOIN TDS_SECTION TDS (NOLOCK) ON TDS.TDS_CODE=A.TDS_CODE
JOIN postact_voucher_link B (NOLOCK) ON A.receipt_ID=B.MEMO_ID
JOIN vd01106 C (NOLOCK) ON C.vm_ID=B.vm_ID AND C.AC_CODE=TDS.PAYABLE_AC_CODE
join vm01106 e (nolock) on e.vm_id=c.vm_id
left join vdt01106 d (nolock) on d.vd_id=c.vd_id
WHERE  ISNULL(a.tds,0)<>0 
and a.cancelled=0 and d.vd_id is  null AND e.cancelled=0
and b.xn_type='jwr'
