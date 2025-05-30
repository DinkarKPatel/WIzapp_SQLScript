

DECLARE  @dtLocal TABLE(XN_TYPE	varchar(10),COLUMN_NAME	nvarchar(MAX),DISPLAY_COLUMN_NAME	nvarchar(200),SELECTED	bit	,MODULE_NAME	varchar(100),GROUP_NAME VARCHAR(50))

INSERT INTO @DTLOCAL VALUES('POADJ','POADJ.MEMO_DT','MEMO_DT',0,'PO_ADJUSTMENT','POADJ_MASTERS')
INSERT INTO @DTLOCAL VALUES('POADJ','POADJ.REMARKS','REMARKS',0,'PO_ADJUSTMENT','POADJ_MASTERS')
INSERT INTO @DTLOCAL VALUES('POADJ','POADJ.memo_no','memo_no',0,'PO_ADJUSTMENT','POADJ_MASTERS')

INSERT INTO @dtLocal VALUES('POADJ','u.username','username',0,'PO_ADJUSTMENT','POADJ_MASTERS')
INSERT INTO @dtLocal VALUES('POADJ','u1.username','Edit_username',0,'PO_ADJUSTMENT','POADJ_MASTERS')

INSERT INTO @dtLocal VALUES('POADJ','lmv.AC_NAME','AC_NAME',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.PRINT_NAME','PRINT_NAME',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.ADDRESS0','ADDRESS0',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.ADDRESS1','ADDRESS1',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.ADDRESS2','ADDRESS2',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.AREA_NAME','AREA_NAME',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.CITY','CITY',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.STATE','STATE',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.PINCODE','PINCODE',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.CST_NO','CST_NO',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.CST_DT','CST_DT',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.TIN_NO','TIN_NO',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.TIN_DT','TIN_DT',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.MOBILE','MOBILE',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.E_MAIL','E_MAIL',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.PAN_NO','PAN_NO',0,'PO_ADJUSTMENT','PARTY')
INSERT INTO @dtLocal VALUES('POADJ','lmv.AC_GST_NO','AC_GST_NO',0,'PO_ADJUSTMENT','PARTY')


INSERT INTO @dtLocal VALUES('POADJ','POADJDET.ADJ_QUANTITY','QUANTITY',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','POADJDET.PURCHASE_PRICE','PURCHASE_PRICE',0,'PO_ADJUSTMENT','POADJ_DETAILS')

INSERT INTO @DTLOCAL VALUES('POADJ','pom.PO_NO','PO_NO',0,'PO_ADJUSTMENT','POADJ_MASTERS')
INSERT INTO @DTLOCAL VALUES('POADJ','pom.REF_NO','REF_NO',0,'PO_ADJUSTMENT','POADJ_MASTERS')
INSERT INTO @DTLOCAL VALUES('POADJ','pom.PO_DT','PO_DT',0,'PO_ADJUSTMENT','POADJ_MASTERS')

INSERT INTO @dtLocal VALUES('POADJ','POD.product_code','product_code',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','POADJDET.PURCHASE_PRICE','PURCHASE_PRICE',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','P1.PARA1_NAME','PARA1_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','P2.PARA2_NAME','PARA2_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','P3.PARA3_NAME','PARA3_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','P4.PARA4_NAME','PARA4_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','P5.PARA5_NAME','PARA5_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','P6.PARA6_NAME','PARA6_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','ART.ARTICLE_NO','ARTICLE_NO',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','ART.ARTICLE_NAME','ARTICLE_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','SD.SUB_SECTION_NAME','SUB_SECTION_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','SM.SECTION_NAME','SECTION_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','UOM.UOM_NAME','UOM_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @dtLocal VALUES('POADJ','UOM.UOM_TYPE','UOM_TYPE',0,'PO_ADJUSTMENT','POADJ_DETAILS')
INSERT INTO @DTLOCAL VALUES('POADJ','SKU.PRODUCT_NAME','PRODUCT_NAME',0,'PO_ADJUSTMENT','POADJ_DETAILS')  



UPDATE B SET SELECTED=A.SELECTED FROM   DYNAMIC_PRINT_COLS A
JOIN @DTLOCAL B ON A.DISPLAY_COLUMN_NAME=B.DISPLAY_COLUMN_NAME and a.MODULE_NAME =b.MODULE_NAME 
WHERE  A.SELECTED<>B.SELECTED
AND A.SELECTED=1

DELETE a
FROM DYNAMIC_PRINT_COLS a
LEFT OUTER JOIN @dtLocal b ON b.COLUMN_NAME=a.COLUMN_NAME AND A.DISPLAY_COLUMN_NAME =B.DISPLAY_COLUMN_NAME 
WHERE b.COLUMN_NAME IS NULL AND a.MODULE_NAME= 'PO_ADJUSTMENT'

INSERT INTO DYNAMIC_PRINT_COLS(XN_TYPE,COLUMN_NAME,DISPLAY_COLUMN_NAME,SELECTED,MODULE_NAME,GROUP_NAME)
SELECT a.XN_TYPE,a.COLUMN_NAME,a.DISPLAY_COLUMN_NAME,a.SELECTED,a.MODULE_NAME,A.GROUP_NAME 
FROM @dtLocal a
LEFT OUTER JOIN DYNAMIC_PRINT_COLS b (NOLOCK) ON b.COLUMN_NAME=a.COLUMN_NAME AND b.XN_TYPE ='POADJ'
WHERE b.COLUMN_NAME IS NULL

--REMOVE DUPLICATE RECORDS
;WITH CTE AS
(
SELECT * ,SR=ROW_NUMBER () OVER (PARTITION BY XN_TYPE,COLUMN_NAME ,DISPLAY_COLUMN_NAME
ORDER BY  XN_TYPE,COLUMN_NAME ,DISPLAY_COLUMN_NAME,SELECTED)
FROM  DYNAMIC_PRINT_COLS	
WHERE LTRIM(RTRIM(XN_TYPE))='POADJ'
)

DELETE  FROM CTE WHERE SR>1
