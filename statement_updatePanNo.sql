
UPDATE A SET PAN_NO =SUBSTRING( LOC_GST_NO,3,10) FROM LOCATION A (NOLOCK) WHERE  ISNULL(LOC_GST_NO,'')<>''
AND ISNULL(PAN_NO,'') =''

UPDATE A SET PAN_NO= C.PAN_NO FROM 
VM01106 A (NOLOCK)
JOIN VD01106 B (NOLOCK) ON A.VM_ID =B.VM_ID 
JOIN LOCATION C (NOLOCK) ON  B.cost_center_dept_id =C.dept_id 
WHERE ISNULL(A.PAN_NO,'')='' AND ISNULL(C.PAN_NO,'')<>''
AND A.cancelled =0