CREATE PROC SP_GENERATE_XML_FOR_INVOICE   
@CM_ID VARCHAR(100),@SQL_USER VARCHAR(100)='SA',@SQL_PASSWORD VARCHAR(100),@APP_FOLDER VARCHAR(200)
AS  
BEGIN  
--
SET NOCOUNT ON  

EXEC SP_CONFIGURE 'SHOW ADVANCED OPTIONS', 1;
RECONFIGURE;
EXEC SP_CONFIGURE 'XP_CMDSHELL', 1;
RECONFIGURE;

DECLARE @IN_PATH VARCHAR(1000),@OUT_PATH VARCHAR(1000),@ID INT  
DECLARE @MYFILE VARCHAR(MAX),@LINE_ITEMS VARCHAR(MAX),@ID_VALUE INT
SET @ID_VALUE=0
--SET @IN_PATH=@APP_FOLDER
IF EXISTS(SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLE_AUTO_EXPORT_FILE_PATH')
   SELECT TOP 1 @OUT_PATH=VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLE_AUTO_EXPORT_FILE_PATH'
ELSE    
   SET @OUT_PATH='D:'
IF RIGHT(RTRIM(@OUT_PATH),1)='\'
   SET @OUT_PATH=LEFT(LTRIM(RTRIM(@OUT_PATH)),LEN(LTRIM(RTRIM(@OUT_PATH)))-1)

TRUNCATE TABLE INVOICE_XML_TBL

/*
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='INVOICE_XML_TBL' AND COLUMN_NAME='ROW')
   ALTER TABLE INVOICE_XML_TBL ADD ROW INT

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='INVOICE_XML_TBL' AND COLUMN_NAME='ID')
*/
INSERT INTO INVOICE_XML_TBL WITH (ROWLOCK)  
(BILL_NO,BILL_AMOUNT,GROSS_AMT,TAX_AMOUNT,HEADER_DISCOUNT,STOCK_NO,PRODUCT_CODE,[DESCRIPTION],QUANTITY,RATE,DISCOUNT_AMOUNT,VALUE,AMOUNT,ID)
SELECT LTRIM(RTRIM(M.CM_NO)) BILL_NO,M.NET_AMOUNT BILL_AMOUNT,M.SUBTOTAL GROSS_AMT  
,(SELECT SUM(TAX_AMOUNT) FROM CMD01106 T (NOLOCK) WHERE T.CM_ID=M.CM_ID)TAX_AMOUNT  
,M.DISCOUNT_AMOUNT HEADER_DISCOUNT,D.PRODUCT_CODE STOCK_NO,S.ARTICLE_CODE PRODUCT_CODE  
,SD.SUB_SECTION_NAME [DESCRIPTION],D.QUANTITY,D.MRP RATE,D.DISCOUNT_AMOUNT  
,D.QUANTITY*D.MRP VALUE,D.NET AMOUNT  
,0
FROM CMM01106 M (NOLOCK)  
INNER JOIN CMD01106 D (NOLOCK) ON M.CM_ID=D.CM_ID  
INNER JOIN SKU S (NOLOCK) ON S.PRODUCT_CODE=D.PRODUCT_CODE  
LEFT OUTER JOIN ARTICLE A ON S.ARTICLE_CODE=A.ARTICLE_CODE  
LEFT OUTER JOIN SECTIOND SD ON A.SUB_SECTION_CODE=SD.SUB_SECTION_CODE
WHERE M.CM_ID=@CM_ID  

IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
   DROP TABLE #R
SELECT *,RANK() OVER(PARTITION BY BILL_NO ORDER BY STOCK_NO++PRODUCT_CODE)R INTO #R FROM INVOICE_XML_TBL(NOLOCK)

--SET IDENTITY_INSERT DBO.INVOICE_XML_TBL ON
UPDATE I SET I.ID=R.R
FROM INVOICE_XML_TBL I WITH (ROWLOCK)
INNER JOIN #R R ON R.BILL_NO=I.BILL_NO
AND I.STOCK_NO=R.STOCK_NO AND I.PRODUCT_CODE=R.PRODUCT_CODE
--SET IDENTITY_INSERT DBO.INVOICE_XML_TBL ON

DECLARE @SERVER VARCHAR(100),@DB VARCHAR(100)  
SELECT @SERVER=@@SERVERNAME,@DB=DB_NAME()  

--SET @MYFILE=@IN_PATH+'\GENERATE_XML.BAT '+@SERVER+' '+@SQL_USER+' '+@SQL_PASSWORD+' '+@DB+' '+@IN_PATH+'\XML_GENERATION_SCRIPT'+' '+@OUT_PATH+'\'+@CM_ID+'.XML'
--SET @MYFILE='BCP "SELECT TOP 1 BILL_NO,BILL_AMOUNT,GROSS_AMT,TAX_AMOUNT,HEADER_DISCOUNT,(SELECT STOCK_NO,PRODUCT_CODE,[DESCRIPTION],QUANTITY,RATE,DISCOUNT_AMOUNT,VALUE,AMOUNT FROM INVOICE_XML_TBL D (NOLOCK) FOR XML PATH (''LINE_ITEM''),ROOT(''BILL_LINEITEMS''),TYPE) FROM INVOICE_XML_TBL H (NOLOCK) FOR XML PATH (''CAPILLARY_INTEGRATION'')" QUERYOUT '+@OUT_PATH+'\'+@CM_ID+'.XML -C -S'+@SERVER+' -U'+@SQL_USER+' -P'+@SQL_PASSWORD+' -D'+@DB
SET @LINE_ITEMS=''
SELECT @ID=MIN(ID) FROM INVOICE_XML_TBL

WHILE @ID<=(SELECT MAX(ID) FROM INVOICE_XML_TBL)
 BEGIN
   --HEADER
   IF @ID=(SELECT MIN(ID) FROM INVOICE_XML_TBL)
      BEGIN
        SELECT @LINE_ITEMS='ECHO ^<?XML VERSION="1.0" ENCODING="UTF-8"?^>^<CAPILLARY_INTEGRATION^>^<BILL^>^<BILL_NO^>'+BILL_NO+'^<^/BILL_NO^>^<BILL_AMOUNT^>'+CAST(BILL_AMOUNT AS VARCHAR)+'^<^/BILL_AMOUNT^>^<GROSS_AMT^>'+CAST(GROSS_AMT AS VARCHAR)+'^<^/GROSS_AMT^>^<TAX_AMOUNT^>'+CAST(TAX_AMOUNT AS VARCHAR)+'^<^/TAX_AMOUNT^>^<HEADER_DISCOUNT^>'+CAST(HEADER_DISCOUNT AS VARCHAR)+'^<^/HEADER_DISCOUNT^>^<BILL_LINEITEMS^> > '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
        SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
        EXEC (@LINE_ITEMS)
      END
   
   --DETAILS
   SELECT @LINE_ITEMS='ECHO ^<LINE_ITEM^>^<STOCK_NO^>'+STOCK_NO+'^<^/STOCK_NO^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)
   
   SELECT @LINE_ITEMS='ECHO ^<PRODUCT_CODE^>'+PRODUCT_CODE+'^<^/PRODUCT_CODE^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   SELECT @LINE_ITEMS='ECHO ^<DESCRIPTION^>'+[DESCRIPTION]+'^<^/DESCRIPTION^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   SELECT @LINE_ITEMS='ECHO ^<QUANTITY^>'+CAST(QUANTITY AS VARCHAR)+'^<^/QUANTITY^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   SELECT @LINE_ITEMS='ECHO ^<RATE^>'+CAST(RATE AS VARCHAR)+'^<^/RATE^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   SELECT @LINE_ITEMS='ECHO ^<DISCOUNT_AMOUNT^>'+CAST(DISCOUNT_AMOUNT AS VARCHAR)+'^<^/DISCOUNT_AMOUNT^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   SELECT @LINE_ITEMS='ECHO ^<VALUE^>'+CAST(VALUE AS VARCHAR)+'^<^/VALUE^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   SELECT @LINE_ITEMS='ECHO ^<AMOUNT^>'+CAST(AMOUNT AS VARCHAR)+'^<^/AMOUNT^>^<^/LINE_ITEM^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML' FROM INVOICE_XML_TBL WHERE ID=@ID
   SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
   EXEC (@LINE_ITEMS)

   --FOOTER
   IF @ID=(SELECT MAX(ID) FROM INVOICE_XML_TBL)
      BEGIN
        SET @LINE_ITEMS='ECHO ^<^/BILL_LINEITEMS^>^<^/BILL^>^<^/CAPILLARY_INTEGRATION^> >> '+@OUT_PATH+'\'+@CM_ID+'.XML'
        SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''
        EXEC (@LINE_ITEMS)
      END
   
   SET @ID+=1
END

EXEC SP_CONFIGURE 'SHOW ADVANCED OPTIONS', 0;
RECONFIGURE;

SET NOCOUNT OFF  
END
