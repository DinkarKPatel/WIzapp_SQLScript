CREATE VIEW  VW_POSTSALES_SLS_DELIVERYLIST 

AS

	SELECT  A.MEMO_NO AS MEMO_NO , CONVERT(NVARCHAR,A.MEMO_DT,105) AS MEMO_DATE,A.DELIVERED_TO AS DELIVERED_TO,A.MEMO_ID AS MEMO_ID ,(CASE WHEN A.CANCELLED = 1 THEN 'CANCELLED' ELSE '' END) AS CANCELLED,
	(C.CUSTOMER_FNAME  + ' ' + C.CUSTOMER_LNAME) AS CUSTOMER_NAME,
	(C.ADDRESS1 + ',' + C.ADDRESS2 + ',' + D.AREA_NAME + ',' + D.PINCODE + ',' + E.CITY + ',' + F.STATE) AS 
	ADDRESS 
	,COM.COMPANY_CODE AS COMP_COMPANYCODE
,COM.PAN_NO AS COMP_PANNO
,COM.EMAIL_ID AS COMP_EMAILID
,COM.PWD AS COMP_PWD
,COM.STATE AS COMP_STATE 
,COM.COUNTRY AS COMP_CONTRY
,COM.MOBILE AS COMP_MOBILE
,COM.CONTACT_NAME AS COMP_CONTACTNAME
,COM.TDS_AC_NO AS COMP_TDSACNO
,COM.COMPANY_NAME AS COMP_COMPANYNAME
,COM.ALIAS AS COMP_ALIAS
,COM.ADDRESS1 AS COMP_ADDRESS1
,COM.ADDRESS2 AS COMP_ADDRESS2 
,COM.CITY AS COMP_CITY
,COM.TAN_NO AS COMP_TANNO
,COM.PHONES_FAX AS COMP_PHONES_FAX
,COM.CST_DT AS COMP_CST_DT
,COM.SST_NO AS COMP_SSTNO
,COM.SST_DT AS COMP_SSTDT
,COM.GRP_CODE AS COMP_GRPCODE
,COM.ADDRESS9 AS COMP_ADDRESS9
,COM.AREA_CODE AS COMP_AREACODE
,COM.PRINT_ADDRESS AS COMP_PRINTADDRESS
,COM.WORKABLE AS COMP_WORKABLE
,COM.PIN AS COMP_PIN
,COM.LOGO_PATH AS COMP_LOGOPATH
,COM.WEB_ADDRESS AS COMP_WEBADDRESS
,COM.SSPL_FIRST_HDSR AS COMP_SSPLFIRSTHDSR
,COM.POLICY_NO AS COMP_POLICYNO
,COM.GRP_NAME AS COMP_GRPNAME 
,COM.CIN AS COMP_CIN
	FROM SLS_DELIVERY_MST A (NOLOCK)  
	JOIN CUSTDYM C (NOLOCK) ON A.CUSTOMER_CODE = C.CUSTOMER_CODE
	JOIN AREA D (NOLOCK) ON D.AREA_CODE = C.AREA_CODE 
	JOIN CITY E (NOLOCK) ON E.CITY_CODE = D.CITY_CODE 
	JOIN STATE F (NOLOCK) ON F.STATE_CODE = E.STATE_CODE
    JOIN COMPANY COM ON COM.COMPANY_CODE ='01'
