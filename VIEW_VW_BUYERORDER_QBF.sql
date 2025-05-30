CREATE VIEW VW_BUYERORDER_QBF

AS 
SELECT A.ORDER_NO AS MST_ORDER_NO,
A.ORDER_ID,
A.ORDER_DT AS MST_ORDER_DT,
A.AC_CODE AS MST_AC_CODE,
A.TOTAL_AMOUNT AS MST_TOTAL_AMOUNT,
A.REMARKS AS MST_REMARKS,
A.SUBTOTAL AS MST_SUBTOTAL,
A.FREIGHT AS MST_FREIGHT,
A.TAX_PERCENTAGE AS MST_TAX_PERCENTAGE,
CONVERT(NUMERIC(14,2),A.TOTAL_AMOUNT * T1.FC_RATE) AS AMOUNT_IN_INR,
A.DISCOUNT_PERCENTAGE AS MST_DISCOUNT_PERCENTAGE,
A.DISCOUNT_AMOUNT AS MST_DISCOUNT_AMOUNT,
A.OTHER_CHARGES AS MST_OTHER_CHARGES,
A.FC_CODE AS MST_FC_CODE,
A.REF_NO AS MST_REF_NO,
A.TRAIL_DT AS MST_TRAIL_DT,
A.PAYMENT_DETAILS AS MST_PAYMENT_DETAILS,
A.SHIPPING_ADDRESS AS MST_SHIPPING_ADDRESS,
A.ORDER_ID AS MST_ORDER_ID,
A.DELIVERY_DT AS MST_DELIVERY_DT,
A.ROUND_OFF AS ROUND_OFF,
A.TAX_AMOUNT AS MST_TAX_AMOUNT,
A.CHECKED_BY AS MST_CHECKED_BY,
A.MANUAL_DISCOUNT AS MST_MANUAL_DISCOUNT,
A.FIN_YEAR AS MST_FIN_YEAR,
B.AC_NAME AS MST_AC_NAME,
D.USERNAME AS MST_EDT_USERNAME,
E.USERNAME AS MST_USERNAME,
A.REF_ORDER_ID,A.MEMO_TYPE,A.APPROVED,A.SALE_EMP_CODE,A.ORDER_TIME,
T1.FC_RATE ,A.MODE,A.CONVERTED_BY_USER_CODE,
ART.ARTICLE_NO,P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,
P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,
DET.WS_PRICE,DET.QUANTITY,DET.REMARKS,DET.RFNET,DET.GROSS_WSP,DET.DISCOUNT_PERCENTAGE,DET.DISCOUNT_AMOUNT,DET.MANUAL_DISCOUNT,
ART.MRP,(DET.QUANTITY * DET.WS_PRICE) AS AMOUNT,
CONVERT(NUMERIC(14,2),A.TOTAL_AMOUNT * T1.FC_RATE) AS MST_AMOUNT_IN_INR,
(ISNULL(P7.EMP_FNAME,'') +' '+ ISNULL(P7.EMP_LNAME,'')) AS MST_EMP_NAME 
,CUST.CUSTOMER_FNAME +' '+ CUST.CUSTOMER_LNAME AS MST_CUSTOMER_NAME ,
CUST.USER_CUSTOMER_CODE AS MST_USER_CUSTOMER_CODE,CUST.CUSTOMER_FNAME,CUST.CARD_NO,
CUST.MOBILE, (CASE WHEN DET.ORDER_TYPE = 1 THEN 'READY STK' ELSE 'PO' END) AS ORDER_TYPE_VALUE,
DET.PRODUCT_CODE,A.location_Code
FROM WSL_ORDER_MST A
JOIN LMV01106 B (NOLOCK)  ON A.AC_CODE = B.AC_CODE       
JOIN USERS D  (NOLOCK)  ON A.USER_CODE = D.USER_CODE       
JOIN USERS E (NOLOCK)  ON A.EDT_USER_CODE = E.USER_CODE       
JOIN LOCATION C (NOLOCK)  ON A.DEPT_ID = C.DEPT_ID       
LEFT OUTER JOIN FC T1 (NOLOCK)   ON A.FC_CODE = T1.FC_CODE    
JOIN WSL_ORDER_DET DET (NOLOCK) ON DET.ORDER_ID=A.ORDER_ID
JOIN ARTICLE ART(NOLOCK)  ON DET.ARTICLE_CODE = ART.ARTICLE_CODE      
JOIN PARA1 P1 (NOLOCK)  ON DET.PARA1_CODE = P1.PARA1_CODE      
JOIN PARA2 P2 (NOLOCK)  ON DET.PARA2_CODE = P2.PARA2_CODE       
JOIN PARA3 P3(NOLOCK)  ON DET.PARA3_CODE = P3.PARA3_CODE       
JOIN PARA4 P4 (NOLOCK)  ON DET.PARA4_CODE = P4.PARA4_CODE       
JOIN PARA5 P5 (NOLOCK)  ON DET.PARA5_CODE = P5.PARA5_CODE       
JOIN PARA6 P6 (NOLOCK) ON DET.PARA6_CODE = P6.PARA6_CODE   
JOIN custdym CUST (NOLOCK) ON A.CUSTOMER_CODE = CUST.CUSTOMER_CODE
LEFT OUTER JOIN EMP_MST P7 (NOLOCK) ON  P7.EMP_ID = A.EMP_CODE
