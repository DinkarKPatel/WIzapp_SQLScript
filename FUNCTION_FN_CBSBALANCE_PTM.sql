CREATE FUNCTION FN_CBSBALANCE_PTM  
(  
 @CWHERE1 DATETIME,  
 @CDEPT_ID VARCHAR(8)  
)  
RETURNS DECIMAL  
--WITH ENCRYPTION  
BEGIN  
 DECLARE @PCO_AMOUNT NUMERIC(14,2) ,  
 @XN_AMOUNT NUMERIC(14,2), 
 @XN_REC_AMOUNT NUMERIC(14,2),  
 @PCI_AMOUNT NUMERIC(14,2),  
 @OPENINGBAL NUMERIC(14,2)  
    /*Rohit 30-10-2024
 --SELECT @PCO_AMOUNT=ISNULL(SUM(PCO_MST.AMOUNT) ,0)  
 --FROM PCO_MST     
 --WHERE MEMO_DT <= @CWHERE1   
 --AND LEFT(MEMO_NO,2)=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN LEFT(MEMO_NO,2) ELSE @CDEPT_ID END)  
 --GROUP BY LEFT(MEMO_ID,2)  
  
 SELECT @XN_AMOUNT=ISNULL(SUM(A.XN_AMOUNT),0)  
 FROM PED01106 A  
 JOIN PEM01106 B ON B.PEM_MEMO_ID=A.PEM_MEMO_ID  
 WHERE B.PEM_MEMO_DT <= @CWHERE1  AND XN_TYPE= 'DR'  AND B.CANCELLED=0 
  AND LEFT(A.PEM_MEMO_ID,2)=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN LEFT(A.PEM_MEMO_ID,2) ELSE @CDEPT_ID END)   
 
 
 SELECT @XN_REC_AMOUNT=ISNULL(SUM(A.XN_AMOUNT),0)  
 FROM PED01106 A  
 JOIN PEM01106 B ON B.PEM_MEMO_ID=A.PEM_MEMO_ID  
 WHERE B.PEM_MEMO_DT <= @CWHERE1  AND XN_TYPE= 'CR'  AND B.CANCELLED=0
 AND LEFT(A.PEM_MEMO_ID,2)=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN LEFT(A.PEM_MEMO_ID,2) ELSE @CDEPT_ID END)  
   
 SELECT @PCI_AMOUNT=ISNULL(SUM(PCI_MST.AMOUNT) ,0)  
 FROM PCI_MST     
 WHERE MEMO_DT <= @CWHERE1  AND RECEIPT_DT<>''    
 AND SUBSTRING(MEMO_NO,3,2)=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN SUBSTRING(MEMO_NO,3,2) ELSE @CDEPT_ID END)  
 GROUP BY SUBSTRING(MEMO_NO,3,2)  
  */
  
 SELECT @XN_AMOUNT=ISNULL(SUM(A.XN_AMOUNT),0)  
 FROM PED01106 A  
 JOIN PEM01106 B ON B.PEM_MEMO_ID=A.PEM_MEMO_ID  
 WHERE B.PEM_MEMO_DT <= @CWHERE1  AND XN_TYPE= 'DR'  AND B.CANCELLED=0 
  AND B.location_code=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN B.location_code ELSE @CDEPT_ID END)   
 
 
 SELECT @XN_REC_AMOUNT=ISNULL(SUM(A.XN_AMOUNT),0)  
 FROM PED01106 A  
 JOIN PEM01106 B ON B.PEM_MEMO_ID=A.PEM_MEMO_ID  
 WHERE B.PEM_MEMO_DT <= @CWHERE1  AND XN_TYPE= 'CR'  AND B.CANCELLED=0
 AND B.location_code=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN B.location_code ELSE @CDEPT_ID END)  
   
 SELECT @PCI_AMOUNT=ISNULL(SUM(PCI_MST.AMOUNT) ,0)  
 FROM PCI_MST     
 WHERE MEMO_DT <= @CWHERE1  AND RECEIPT_DT<>''    
 AND location_code=(CASE WHEN ISNULL(@CDEPT_ID ,'')='' THEN location_code ELSE @CDEPT_ID END)  
 GROUP BY location_code
 SET @OPENINGBAL=(ISNULL(@PCI_AMOUNT,0) + ISNULL(@XN_REC_AMOUNT,0)) - (ISNULL(@PCO_AMOUNT,0)+ISNULL(@XN_AMOUNT,0))  
   
  
 RETURN ISNULL(@OPENINGBAL,0)  
    
END
