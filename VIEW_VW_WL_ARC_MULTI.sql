CREATE VIEW VW_WL_ARC_MULTI  
AS  
SELECT A.ADV_REC_ID
,A.FIN_YEAR
,A.ARC_TYPE
,A.ARCT
,(CASE WHEN A.ARC_TYPE=1 THEN 'RECEIPT' ELSE 'PAYMENT' END) AS [MST_ARC_TYPE]
,(CASE WHEN A.ARCT=1 THEN 'OUTSTANDING'   
   WHEN A.ARCT=2 THEN 'ADVANCE VOUCHERS'  
   ELSE 'OTHER CHARGES' END) AS [MST_ARCT]
,A.ADV_REC_NO AS MST_ADV_REC_NO
,A.ADV_REC_DT AS MST_XN_DT
,A.HSN_CODE AS MST_HSN_CODE
,A.CARD_ISSUE_TYPE
,A.CARD_ISSUE_DT
,ISNULL(BM.CARD_NAME,'') AS DISCOUNTED_CARD_TYPE
,A.CARD_NO
,A.GIFT_CARD_NO
,CUST.CUSTOMER_TITLE AS MST_CUSTOMER_TITLE
,CUST.CUSTOMER_FNAME AS MST_CUSTOMER_FNAME
,CUST.CUSTOMER_LNAME AS MST_CUSTOMER_LNAME 
,A.REMARKS AS MST_REMARKS
,CUST.USER_CUSTOMER_CODE AS MST_USER_CUSTOMER_CODE
,A.AMOUNT AS MST_AMOUNT,A.DISCOUNT_AMOUNT AS MST_DISCOUNT_AMOUNT,A.NET_AMOUNT AS MST_NET_AMOUNT,C.USERNAME AS MST_USERNAME,  
CUST.ADDRESS1 +' '+CUST .ADDRESS2 AS MST_ADDRESS0,
X.ADDRESS AS MST_ADDRESS1 , A.CANCELLED AS MST_CANCELLED,ISNULL(EMP.EMP_NAME,'') AS MST_EMP_NAME
,DBO.FN_GETBILLSADJ(A.ADV_REC_ID) AS ADJ_BIILS,
--,B.CASH_AMOUNT,B.CC_AMOUNT,B.CN_AMOUNT,B.ADVANCE_AMOUNT_ADJUSTED,B.CREDIT_AMOUNT,B.OTHER_DOC_AMOUNT,B.BANK_CHARGES,
LM.AC_NAME AS MST_AC_NAME,
LM.AC_NAME ,LM.STATE AS AC_STATE,LM.AREA_NAME AS AC_AREA,LM.CITY AS AC_CITY,LM.PINCODE AS AC_PIN,
LM.ADDRESS0 + ' ' + LM.ADDRESS1 + ' ' + LM.ADDRESS2 + ' ' + LM.AREA_NAME + ' ' + LM.CITY + ' ' +  
LM.STATE + ' ' + LM.MOBILE + ' ' AS AC_ADDRESS
,A.PARTY_TYPE,A2.ORDER_NO,A.REF_NO AS [MST_REF_NO],A.DISCOUNT_PERCENTAGE AS [MST_DISCOUNT_PERCENTAGE]
-- PARTY_TYPE 1-CUSTOMER 2-LEDGER
,CMP.PAN_NO
,CMP.EMAIL_ID
,CMP.PWD
,CMP.STATE
,CMP.COUNTRY
,CMP.MOBILE
,CMP.CONTACT_NAME
,CMP.TDS_AC_NO
,CMP.COMPANY_CODE
,CMP.COMPANY_NAME
,CMP.ALIAS
,CMP.ADDRESS1
,CMP.ADDRESS2
,CMP.CITY
,CMP.TIN_NO
,CMP.TAN_NO
,CMP.PHONES_FAX
,CMP.CST_NO
,CMP.CST_DT
,CMP.SST_NO
,CMP.SST_DT
,CMP.GRP_CODE
,CMP.ADDRESS9
,CMP.AREA_CODE
,CMP.PRINT_ADDRESS
,CMP.WORKABLE
,CMP.PIN
,CMP.LOGO_PATH
,CMP.WEB_ADDRESS
,CMP.SSPL_FIRST_HDSR
,CMP.POLICY_NO
,CMP.GRP_NAME
,CMP.CIN
,CMP.TIN_NO AS COMP_TIN_NO
FROM ARC01106 A  
--LEFT OUTER JOIN VW_BILL_PAYMODE B ON B.MEMO_ID=A.ADV_REC_ID AND B.XN_TYPE='ARC'  
LEFT OUTER  JOIN USERS C ON C.USER_CODE=A.USER_CODE  
LEFT OUTER JOIN CUSTDYM CUST ON CUST.CUSTOMER_CODE=A.CUSTOMER_CODE 
LEFT OUTER JOIN LMV01106 LM ON LM.AC_CODE = A.AC_CODE
LEFT OUTER JOIN 
(
	SELECT AREA_CODE ,AD1 .AREA_NAME +' '+AD2 .CITY +CHAR(10)+AD3 .STATE+'' +AD1 .PINCODE AS ADDRESS  FROM AREA AD1 
	LEFT OUTER JOIN CITY AD2 ON AD2.CITY_CODE=AD1.CITY_CODE
	LEFT OUTER JOIN STATE AD3 ON AD3.STATE_CODE	=AD2.STATE_CODE
	LEFT OUTER JOIN REGIONM AD4 ON AD4.REGION_CODE=AD3.REGION_CODE
)X ON X.AREA_CODE=CUST.AREA_CODE
LEFT OUTER JOIN EMPLOYEE EMP ON EMP.EMP_CODE = A.EMP_CODE
LEFT OUTER JOIN WSL_ORDER_ADV_RECEIPT  A1 ON A.ADV_REC_ID=A1.ADV_REC_ID
LEFT OUTER JOIN WSL_ORDER_MST A2 ON A1.ORDER_ID = A2.ORDER_ID 
LEFT OUTER JOIN BWD_MST BM ON BM.MEMO_ID=A.CARD_CODE
JOIN COMPANY CMP ON CMP.COMPANY_CODE='01'
