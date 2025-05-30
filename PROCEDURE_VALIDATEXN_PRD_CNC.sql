CREATE PROCEDURE VALIDATEXN_PRD_CNC  
(  
  @CXNID VARCHAR(40),  
  @NUPDATEMODE INT,       
  @CERRORMSG VARCHAR(1000) OUTPUT  
  --*** PARAMETERS :  
  --*** @CXNID - TRANSACTION ID ( MEMO ID OF MASTER TABLE )  
)  
--WITH ENCRYPTION
AS  
BEGIN  
 DECLARE @CITEMNAME NVARCHAR(4000)
  
 DECLARE @CICMTABLE TABLE ( CNC_MEMO_ID VARCHAR(22), CNC_MEMO_NO VARCHAR(10), CNC_MEMO_DT DATETIME,   
          CNC_TYPE NUMERIC(1), FIN_YEAR VARCHAR(10), CANCELLED BIT)
   
 DECLARE @CICDTABLE TABLE ( CNC_MEMO_ID VARCHAR(22), PRODUCT_UID VARCHAR(50) , QUANTITY NUMERIC(10,3))  
   
 INSERT @CICMTABLE  
 SELECT CNC_MEMO_ID, CNC_MEMO_NO, CNC_MEMO_DT, CNC_TYPE, FIN_YEAR, CANCELLED
 FROM PRD_ICM01106 WHERE CNC_MEMO_ID = @CXNID  
  
 INSERT @CICDTABLE   
 SELECT A.CNC_MEMO_ID, A.PRODUCT_UID, A.QUANTITY 
 FROM PRD_ICD01106 A  
 LEFT OUTER JOIN PRD_SKU B ON A.PRODUCT_UID = ISNULL(B.PRODUCT_UID,'') AND B.WORK_ORDER_ID=''  
 WHERE  CNC_MEMO_ID = @CXNID  
  
 SET @CERRORMSG = ''  
   
   
  
 IF EXISTS (SELECT CNC_MEMO_ID FROM @CICMTABLE WHERE FIN_YEAR<>'01'+DBO.FN_GETFINYEAR(CNC_MEMO_DT))  
 BEGIN  
  SET @CERRORMSG='MISMATCH BETWEEN MEMO DATE & FIN YEAR .....PLEASE CHECK'  
  RETURN  
 END  
   
    
 IF EXISTS (SELECT CNC_MEMO_ID FROM @CICMTABLE WHERE FIN_YEAR<>SUBSTRING(CNC_MEMO_ID,3,5))  
 BEGIN  
  SET @CERRORMSG='MISMATCH BETWEEN MEMO ID & FIN YEAR .....PLEASE CHECK'  
  RETURN  
 END  
   
END_PROC:  
END  
--****************************************** END OF PROCEDURE VALIDATEXN_CNC
