
Update a set  columnname =a.columnname +','+'TOTAL_MRP_VALUE'
from XNS_UPLOAD_COLS A
where tablename ='cmm01106'
and CHARINDEX ('TOTAL_MRP_VALUE',columnname)=0

Update a set  columnname =a.columnname +','+'TOTAL_DISCOUNT'
from XNS_UPLOAD_COLS A
where tablename ='cmm01106'
and CHARINDEX ('TOTAL_DISCOUNT',columnname)=0

Update a set  columnname =a.columnname +','+'TOTAL_GST_AMOUNT'
from XNS_UPLOAD_COLS A
where tablename ='cmm01106'
and CHARINDEX ('TOTAL_GST_AMOUNT',columnname)=0

