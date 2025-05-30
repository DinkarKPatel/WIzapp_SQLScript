CREATE VIEW  VW_POSTSALES_WL_HBDLIST   

AS  
  
 SELECT DISTINCT A.MEMO_NO AS MEMO_NO , CONVERT(NVARCHAR,A.MEMO_DT,105) AS MEMO_DATE,A.MEMO_ID AS MEMO_ID ,  
 (CASE WHEN A.CANCELLED = 1 THEN 'CANCELLED' ELSE '' END) AS CANCELLED,  
 (C.CUSTOMER_FNAME  + ' ' + C.CUSTOMER_LNAME) AS CUSTOMER_NAME,  
 (C.ADDRESS1 + ',' + C.ADDRESS2 + ',' + D.AREA_NAME + ',' + D.PINCODE + ',' + E.CITY + ',' + F.STATE) AS   
 ADDRESS ,ISNULL(A1.COUNT_HITEM,0) AS TOTAL_HOLD_QTY,X.CM_NO,X.CM_DT,
 ISNULL(L.DEPT_NAME,'') AS SHOWROOM_NAME,
 (CASE WHEN A.DELIVERY_POINT = 1 THEN 'AT SHOWROOM' ELSE 'OTHERS' END) AS DELIVERY_POINT ,
 ISNULL(DELIVERY_ADDRESS,'') AS  DELIVERY_ADDRESS
 FROM HOLD_BACK_DELIVER_MST A (NOLOCK)   
 JOIN CUSTDYM C (NOLOCK) ON A.CUSTOMER_CODE = C.CUSTOMER_CODE  
 JOIN AREA D (NOLOCK) ON D.AREA_CODE = C.AREA_CODE   
 JOIN CITY E (NOLOCK) ON E.CITY_CODE = D.CITY_CODE   
 JOIN STATE F (NOLOCK) ON F.STATE_CODE = E.STATE_CODE  
 JOIN
 (
	SELECT DISTINCT B.CM_ID,B.CM_NO,B.CM_DT,C.MEMO_ID FROM CMD01106 A
	JOIN CMM01106 B ON B.CM_ID	=A.CM_ID
	JOIN HOLD_BACK_DELIVER_DET C ON C.REF_CMD_ROW_ID=A.ROW_ID
 )X ON X.MEMO_ID=A.MEMO_ID
  LEFT OUTER JOIN LOCATION L (NOLOCK) ON L.DEPT_ID=A.DELIVERY_DEPT_ID
 LEFT OUTER JOIN  
 (SELECT COUNT(DELIVERED) AS COUNT_HITEM,DELIVERED,MEMO_ID   
 FROM  HOLD_BACK_DELIVER_DET   
 WHERE DELIVERED = 0 GROUP BY DELIVERED ,MEMO_ID ) A1 ON A.MEMO_ID = A1.MEMO_ID
