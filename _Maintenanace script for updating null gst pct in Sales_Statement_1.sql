UPDATE A SET GST_PERCENTAGE=0,CGST_AMOUNT=0,SGST_AMOUNT=0,IGST_AMOUNT=0 FROM CMD01106 A
JOIN CMM01106 B ON A.CM_ID=B.CM_ID WHERE CM_DT>='2017-07-01' AND GST_PERCENTAGE IS NULL
