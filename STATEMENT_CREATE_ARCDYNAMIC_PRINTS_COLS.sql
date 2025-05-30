
DECLARE  @dtLocal TABLE(XN_TYPE	varchar(10),COLUMN_NAME	nvarchar(MAX),DISPLAY_COLUMN_NAME	nvarchar(200),SELECTED	bit	,MODULE_NAME	varchar(100),GROUP_NAME VARCHAR(50))
INSERT INTO @dtLocal VALUES('ARC','l.Dept_Print_Name','COMPANY_NAME',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.ADDRESS1','ADDRESS1',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.ADDRESS2','ADDRESS2',0,'CUSTOMER_RECEIPT','ARC_MST')

INSERT INTO @dtLocal VALUES('ARC','l.Dept_Print_Name','LOCATION_Print_Name',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.PINCODE','LOCATION_PINCODE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.AREA_NAME','LOCATION_AREA',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.CITY','CITY',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.PHONE','PHONES_FAX',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.TIN_NO','TIN_NO',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.TAN_NO','TAN_NO',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','CMP.CIN','CIN',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.LOC_GST_NO','LOC_GST_NO',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','l.GST_STATE_CODE','LOC_GST_STATE_CODE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','ls.GST_STATE_NAME','LOC_GST_STATE_NAME',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CMP.LOGO_PATH','LOGO_PATH',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ISNULL(L.REGISTERED_ADD,'''')','REGISTERED_ADDRESS',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ISNULL(ls.UT,0)','UT',0,'CUSTOMER_RECEIPT','ARC_MST')



INSERT INTO @DTLOCAL VALUES('ARC','CU.CUSTOMER_FNAME +'' ''+CU.CUSTOMER_LNAME+ISNULL('' ( ''+USER_CUSTOMER_CODE+'' )'','''') ','PARTY_NAME',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','RTRIM(LTRIM(CU.ADDRESS1+'' ''+CU.ADDRESS2+'' ''+'' ''+CA.AREA_NAME+CC.CITY+'' ''+CU .PIN ))','PARTY_ADDRESS',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','RTRIM(LTRIM(CU.ADDRESS1))','PARTY_ADDRESS1',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','RTRIM(LTRIM(CU.ADDRESS2))','PARTY_ADDRESS2',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','RTRIM(LTRIM(CU.ADDRESS0))+'' ''+RTRIM(LTRIM(CU.ADDRESS9))','PARTY_ADDRESS3',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC',' RTRIM(LTRIM(CA.AREA_NAME+'' ''+CC.CITY+'' ''+CA.AREA_CODE))','PARTY_CITY',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CU.CUS_GST_NO','PARTY_GST_NO',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CS.GST_STATE_NAME','PARTY_STATE_NAME',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CASE WHEN ARC.CANCELLED =1 THEN ''CANCELLED'' ELSE '''' END','CANCELLED',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CASE ARC.ARCT WHEN 1 THEN ''OUTSTANDING'' WHEN 2 THEN ''ADVANCE'' END+'' VOUCHER''  ','INVOICE_TYPE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','TMPBILL.CUST_BAL','CUST_BAL',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CS.GST_STATE_CODE','PARTY_STATE_CODE',0,'CUSTOMER_RECEIPT','ARC_MST')



INSERT INTO @DTLOCAL VALUES('ARC','GV.GV_SRNO','GV_SRNO',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GV.QUANTITY','QUANTITY',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GV.ROW_ID','ROW_ID',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GV.DENOMINATION','DENOMINATION',0,'CUSTOMER_RECEIPT','ARC_MST')

INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.DT_CREATED','DT_CREATED',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.DENOMINATION','GVSKU_DENOMINATION',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.DISCOUNT_AMOUNT','GVSKU_DISCOUNT_AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.validity_days','validity_days',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.dt_expiry','dt_expiry',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.gv_type','gv_type',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.scheme_id','scheme_id',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.validate_with_eoss','validate_with_eoss',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','GVSKU.allow_partial_redemption','allow_partial_redemption',0,'CUSTOMER_RECEIPT','ARC_MST')


INSERT INTO @DTLOCAL VALUES('ARC','ARC.ADV_REC_ID','ADV_REC_ID',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.ADV_REC_NO','ADV_REC_NO',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CONVERT(VARCHAR,ARC.ADV_REC_DT,105)','ADV_REC_DT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ISNULL(ARC.REMARKS,'''')','REMARKS',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','CASE WHEN ARC.arc_type =2 THEN ''PAYMENT'' ELSE ''RECEIPT'' END','ARC_TYPE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.AMOUNT','AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.DISCOUNT_PERCENTAGE','DISCOUNT_PERCENTAGE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.DISCOUNT_AMOUNT','DISCOUNT_AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.NET_AMOUNT','NET_AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.HSN_CODE','HSN_CODE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.TAXABLE_VALUE','TAXABLE_VALUES',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.GST_PERCENTAGE','GST_PERCENTAGE',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.CGST_AMOUNT','CGST_AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.SGST_AMOUNT','SGST_AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','ARC.IGST_AMOUNT','IGST_AMOUNT',0,'CUSTOMER_RECEIPT','ARC_MST')




INSERT INTO @DTLOCAL VALUES('ARC','TMPBILL.SALE_PERSON','SALE_PERSON',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @DTLOCAL VALUES('ARC','TMPBILL.AGAINST_BILL_NO','AGAINST_BILL_NO',0,'CUSTOMER_RECEIPT','ARC_MST')



INSERT INTO @dtLocal VALUES('ARC','GST_TNC.TNC_1','TNC_1',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','GST_TNC.TNC_2','TNC_2',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','GST_TNC.TNC_3','TNC_3',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','GST_TNC.TNC_4','TNC_4',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','GST_TNC.TNC_5','TNC_5',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','GST_TNC.TNC_6','TNC_6',0,'CUSTOMER_RECEIPT','ARC_MST')

INSERT INTO @dtLocal VALUES('ARC','EMP.EMP_NAME','EMP_NAME',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','U.username','USERNAME',0,'CUSTOMER_RECEIPT','ARC_MST')
INSERT INTO @dtLocal VALUES('ARC','EU.username','EDT_USERNAME',0,'CUSTOMER_RECEIPT','ARC_MST')


UPDATE B SET SELECTED=A.SELECTED FROM   DYNAMIC_PRINT_COLS A
JOIN @DTLOCAL B ON A.DISPLAY_COLUMN_NAME=B.DISPLAY_COLUMN_NAME and a.MODULE_NAME =b.MODULE_NAME 
WHERE  A.SELECTED<>B.SELECTED
AND A.SELECTED=1



DELETE a
FROM DYNAMIC_PRINT_COLS a
LEFT OUTER JOIN @dtLocal b ON b.COLUMN_NAME=a.COLUMN_NAME AND A.DISPLAY_COLUMN_NAME =B.DISPLAY_COLUMN_NAME 
WHERE b.COLUMN_NAME IS NULL AND a.MODULE_NAME= 'CUSTOMER_RECEIPT'

INSERT INTO DYNAMIC_PRINT_COLS(XN_TYPE,COLUMN_NAME,DISPLAY_COLUMN_NAME,SELECTED,MODULE_NAME,GROUP_NAME)
SELECT a.XN_TYPE,a.COLUMN_NAME,a.DISPLAY_COLUMN_NAME,a.SELECTED,a.MODULE_NAME,A.GROUP_NAME 
FROM @dtLocal a
LEFT OUTER JOIN DYNAMIC_PRINT_COLS b (NOLOCK) ON b.COLUMN_NAME=a.COLUMN_NAME  AND b.XN_TYPE ='ARC'
WHERE b.COLUMN_NAME IS NULL  

--REMOVE DUPLICATE RECORDS
;WITH CTE AS
(
SELECT * ,SR=ROW_NUMBER () OVER (PARTITION BY XN_TYPE,COLUMN_NAME ,DISPLAY_COLUMN_NAME
ORDER BY  XN_TYPE,COLUMN_NAME ,DISPLAY_COLUMN_NAME,SELECTED)
FROM  DYNAMIC_PRINT_COLS	
 WHERE LTRIM(RTRIM(XN_TYPE))='ARC'
)

DELETE  FROM CTE WHERE SR>1




