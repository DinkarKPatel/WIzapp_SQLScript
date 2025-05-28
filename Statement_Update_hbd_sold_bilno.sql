
Update a set SOLD_BILL_NO=c.CM_NO ,SOLD_BILL_DT=c.cm_dt ,SOLD_PRODUCT_CODE=b.PRODUCT_CODE ,SOLD_NET_AMOUNT=b.net
from HOLD_BACK_DELIVER_DET A (nolock)
join cmd01106 b (nolock) on a.ref_cmd_row_id =b.ROW_ID 
join cmm01106 c (nolock) on b.cm_id =c.cm_id 
where ref_cmd_row_id <>'' and c.CANCELLED =0
and ISNULL(SOLD_BILL_NO,'')=''
