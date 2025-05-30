CREATE VIEW VW_PO_HSN_SUMMARY
AS
SELECT PO_ID,HSN_CODE,GST_PERCENTAGE,SUM(INVOICE_QUANTITY)QTY,SUM(XN_VALUE_WITHOUT_GST)HSN_TAXABLE_VALUE
,SUM(IGST_AMOUNT)IGST_AMOUNT
,SUM(CGST_AMOUNT)CGST_AMOUNT
,SUM(SGST_AMOUNT)SGST_AMOUNT
FROM POD01106 (NOLOCK) 
GROUP BY PO_ID,HSN_CODE,GST_PERCENTAGE
