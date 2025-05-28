
Update a set  columnname =a.columnname +','+'Manual_Party_State_code'
from XNS_UPLOAD_COLS A
where tablename ='cmm01106'
and CHARINDEX ('Manual_Party_State_code',columnname)=0
