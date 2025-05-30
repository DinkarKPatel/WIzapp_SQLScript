UPDATE A SET APD_PRODUCT_CODE=B.PRODUCT_CODE,
             MRP=B.MRP ,
             DISCOUNT_PERCENTAGE=B.DISCOUNT_PERCENTAGE,
             DISCOUNT_AMOUNT=( ((B.MRP*A.QUANTITY)*B.DISCOUNT_PERCENTAGE)/100)
FROM  APPROVAL_RETURN_DET A (NOLOCK)
JOIN APD01106 B (NOLOCK) ON A.APD_ROW_ID =B.ROW_ID 
WHERE ISNULL(A.APD_PRODUCT_CODE,'')=''

UPDATE  A SET RFNET=(A.MRP*A.QUANTITY)-A.DISCOUNT_AMOUNT
FROM APPROVAL_RETURN_DET A (NOLOCK)
WHERE ISNULL(RFNET,0)=0

