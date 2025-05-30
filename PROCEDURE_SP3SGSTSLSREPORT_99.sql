CREATE PROCEDURE SP3SGSTSLSREPORT_99(@CXNID VARCHAR(40))
AS
BEGIN
SET NOCOUNT ON
DECLARE @GST_COLLECTION VARCHAR(MAX)='',@SETTLEMENT VARCHAR(MAX)='SETTLEMENT: ',@TNC VARCHAR(MAX)='',@QUOTE VARCHAR(MAX)=''
;WITH CTE AS    
(    
 SELECT 'CC' AS PAYMODE_NAME,SUM(AMOUNT) AMT     
 FROM PAYMODE_XN_DET A (NOLOCK)     
 JOIN PAYMODE_MST B (NOLOCK) ON A.PAYMODE_CODE=B.PAYMODE_CODE      
 WHERE A.XN_TYPE ='SLS' AND A.MEMO_ID=@CXNID  
 AND B.PAYMODE_GRP_CODE='0000002'  
 UNION  
 SELECT PAYMODE_NAME=CASE B.PAYMODE_NAME WHEN 'INR' THEN 'CASH' ELSE B.PAYMODE_NAME END    
 ,SUM(AMOUNT) AMT     
 FROM PAYMODE_XN_DET A (NOLOCK)     
 JOIN PAYMODE_MST B (NOLOCK) ON A.PAYMODE_CODE=B.PAYMODE_CODE      
 WHERE A.XN_TYPE ='SLS' AND A.MEMO_ID=@CXNID  
 AND B.PAYMODE_GRP_CODE!='0000002'  
 GROUP BY B.PAYMODE_NAME    
)    
SELECT @SETTLEMENT=COALESCE(@SETTLEMENT,'')+PAYMODE_NAME+': '+DBO.CURR_GROUPING(AMT,',')+REPLICATE(CHAR(32),3) FROM CTE WHERE ISNULL(AMT,0)<>0  
SELECT @QUOTE=ISNULL(QUOTATION1,'')+CHAR(13)+ISNULL(QUOTATION2,'')FROM GST_QUOTATION_MST WHERE XN_TYPE='SLS' 
SELECT @TNC+=TNC_1+CHAR(13)+TNC_2+CHAR(13)+TNC_3+CHAR(13)+TNC_4+CHAR(13)+TNC_5+CHAR(13)+TNC_6 FROM GST_TNC WHERE XN_TYPE='SLS'

SELECT CMM.CM_NO
,CMM.CM_DT
,REPLACE(DBO.GST_SLS_PARTY_NAME(CMM.CUSTOMER_CODE,'SLS','CUS'),';CUS','') AS PARTY_NAME
,CMM.SUBTOTAL
,CMM.ATD_CHARGES AS OTHER_CHARGES
,CMM.ROUND_OFF
,CMM.NET_AMOUNT
,@GST_COLLECTION AS GST_COLLECTION
,@SETTLEMENT AS SETTLEMENT
,@TNC AS TNC
,@QUOTE AS QUOTATION
FROM CMM01106 CMM (NOLOCK)     
WHERE CMM.CM_ID=@CXNID      



DECLARE @CCOLNAME VARCHAR(MAX)='',@DTSQL VARCHAR(MAX)='',@SNO BIT=0
SET @SNO=0    
IF EXISTS(SELECT * FROM GST_XN_DETAIL (NOLOCK) WHERE DISPLAYNAME='BARCODE' AND XN_TYPE='SLS' AND ISVISIBLE=1)    
   SET @SNO=1 

SELECT @CCOLNAME=ISNULL(@CCOLNAME+'+','  ')+SOURCENAME+'.'+QUOTENAME(COLUMNNAME) +'+'+''''+COLUMNSEPARATOR+''''+' ' FROM GST_XN_DETAIL (NOLOCK) WHERE XN_TYPE ='SLS' AND ISVISIBLE=1 ORDER BY DISPLAYORDER      

SELECT TOP 1 @CCOLNAME=LEFT(@CCOLNAME,LEN(@CCOLNAME)-3-LEN(COLUMNSEPARATOR)) FROM GST_XN_DETAIL (NOLOCK) WHERE XN_TYPE='SLS'    

SET @DTSQL=N'SELECT ROW_NUMBER() OVER (ORDER BY '+CASE @SNO WHEN 0 THEN @CCOLNAME ELSE 'CMD.SR_NO' END+' ) AS SR_NO,'      

SET @DTSQL+=@CCOLNAME+' AS PARTICULARS ,      
CMD.HSN_CODE [HSN_CODE],      
CAST(SUM(CMD.QUANTITY) AS DECIMAL(10,2))QUANTITY,      
UOM.UOM_NAME UOM_NAME,      
CMD.MRP RATE,      
CAST(ROUND((ISNULL(CMD.CMM_DISCOUNT_AMOUNT,0)+ISNULL(CMD.DISCOUNT_AMOUNT,0))/(CMD.MRP*CMD.QUANTITY)*100,2) AS NUMERIC(10,2))[DISC %],      
CAST(SUM(ISNULL(CMD.XN_VALUE_WITHOUT_GST,0))AS DECIMAL(18,2))[TAXABLE_VALUE],      
CAST(DBO.CURR_GROUPING(ROUND(ISNULL(CMD.GST_PERCENTAGE,0),2),'''') AS VARCHAR)+''%''[GST],      
DBO.CURR_GROUPING(SUM(CASE CMD.TAX_METHOD WHEN 1 THEN ISNULL(CMD.NET,0)-ISNULL(CMD.CMM_DISCOUNT_AMOUNT,0)   
 ELSE ISNULL(CMD.XN_VALUE_WITHOUT_GST,0)  
      +ISNULL(CMD.IGST_AMOUNT,0)+ISNULL(CMD.CGST_AMOUNT,0)+ISNULL(CMD.SGST_AMOUNT,0)   
  END),'''')  
AS [ITEM_NET_AMT]  
FROM CMD01106 CMD (NOLOCK)       
JOIN CMM01106 CMM (NOLOCK) ON CMM.CM_ID=CMD.CM_ID       
JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =CMD.PRODUCT_CODE         
JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE =SKU.ARTICLE_CODE         
JOIN UOM (NOLOCK) ON UOM.UOM_CODE =ARTICLE.UOM_CODE         
JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE=SECTIOND.SUB_SECTION_CODE        
JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE=SECTIONM.SECTION_CODE        
LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID=LEFT(CMM.CM_ID,2)      
LEFT JOIN GST_STATE_MST LS (NOLOCK) ON LS.GST_STATE_CODE=LEFT(TL.LOC_GST_NO,2)      
LEFT JOIN EMPLOYEE ON EMPLOYEE.EMP_CODE=CMD.EMP_CODE       
LEFT JOIN EMPLOYEE EMPLOYEE1 ON EMPLOYEE1.EMP_CODE=CMD.EMP_CODE1       
LEFT JOIN EMPLOYEE EMPLOYEE2 ON EMPLOYEE2.EMP_CODE=CMD.EMP_CODE2          
LEFT OUTER JOIN PARA1 ON PARA1.PARA1_CODE=SKU.PARA1_CODE      
LEFT OUTER JOIN PARA2 ON PARA2.PARA2_CODE=SKU.PARA2_CODE      
LEFT OUTER JOIN PARA3 ON PARA3.PARA3_CODE=SKU.PARA3_CODE      
LEFT OUTER JOIN PARA4 ON PARA4.PARA4_CODE=SKU.PARA4_CODE      
LEFT OUTER JOIN PARA5 ON PARA5.PARA5_CODE=SKU.PARA5_CODE      
LEFT OUTER JOIN PARA6 ON PARA6.PARA6_CODE=SKU.PARA6_CODE      
WHERE CMD.CM_ID='''+@CXNID+'''      
GROUP BY '+CASE @SNO WHEN 0 THEN '' ELSE 'CMD.SR_NO,' END+@CCOLNAME+',UOM.UOM_NAME,CMD.HSN_CODE,CMD.MRP
,CAST(ROUND((ISNULL(CMD.CMM_DISCOUNT_AMOUNT,0)+ISNULL(CMD.DISCOUNT_AMOUNT,0))/(CMD.MRP*CMD.QUANTITY)*100,2) AS NUMERIC(10,2))
,CAST(DBO.CURR_GROUPING(ROUND(ISNULL(CMD.GST_PERCENTAGE,0),2),'''') AS VARCHAR)+''%''
,EMPLOYEE.EMP_NAME,EMPLOYEE1.EMP_NAME,EMPLOYEE2.EMP_NAME,SKU.PRODUCT_CODE
,(CASE WHEN CMD.TAX_METHOD=1 THEN SECTIONM.SECTION_NAME+'' - ''+SECTIOND.SUB_SECTION_NAME ELSE ''*'' + SECTIONM.SECTION_NAME+'' - ''+SECTIOND.SUB_SECTION_NAME END)       
,ISNULL(CMD.REF_SLS_MEMO_DT,''1900-01-01'')  
,ISNULL(CMD.REF_SLS_MEMO_NO,'''')         
ORDER BY 1'      

PRINT @DTSQL      
EXEC(@DTSQL)

SET NOCOUNT OFF
END--PROC SP3SGSTSLSREPORT_99
