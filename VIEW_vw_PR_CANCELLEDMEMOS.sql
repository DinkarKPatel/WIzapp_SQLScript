CREATE VIEW VW_PR_CANCELLEDMEMOS
AS
 SELECT  'PRD'+B.MEMO_ID  AS XN_ID
 FROM PRD_STK_TRANSFER_DTM_MST B
 WHERE B.CANCELLED=1     
 -- DCO    
   
 UNION ALL    
   
 SELECT 'FLR'+B.MEMO_ID  AS XN_ID
 FROM FLOOR_ST_MST B (NOLOCK)
 WHERE  B.CANCELLED = 1    
         
 -- PURCHASE INVOICE    
 UNION ALL    
 SELECT 'PIM'+B.MRR_ID AS XN_ID       
 FROM PIM01106 B (NOLOCK)
 WHERE  B.CANCELLED = 1
      
 -- PURCHASE RETURN    
 UNION ALL    
 SELECT 'RMM'+B.RM_ID AS XN_ID
 FROM RMM01106 B (NOLOCK)
 WHERE B.CANCELLED = 1
    
 ---RETAIL SALE     
 UNION ALL    
 SELECT 'CMM'+B.CM_ID AS XN_ID
 FROM CMM01106 B (NOLOCK)
 WHERE B.CANCELLED = 1     
   
 -- APPROVAL ISSUE    
 UNION ALL    
 SELECT 'APM'+B.MEMO_ID AS XN_ID
 FROM APM01106 B (NOLOCK)
 WHERE B.CANCELLED = 1    
   
 -- APPROVAL RETURN    
 UNION ALL    
 SELECT 'APR'+C.MEMO_ID AS XN_ID
 FROM APPROVAL_RETURN_MST C (NOLOCK)
 WHERE  C.CANCELLED = 1    
     
 -- CANCELLATION AND STOCK ADJUSTMENT    
 UNION ALL    
 SELECT 'ICM'+B.CNC_MEMO_ID AS XN_ID
 FROM ICM01106 B (NOLOCK) 
 WHERE B.CANCELLED = 1    
     
 --WHOLESALE INVOICE    
 UNION ALL    
 SELECT 'INM'+B.INV_ID AS XN_ID
 FROM INM01106 B (NOLOCK)
 WHERE B.CANCELLED = 1
 
    
 --WHOLESALE PACKSLIP    
 UNION ALL    
 SELECT 'WPI'+B.PS_ID AS XN_ID
 FROM WPS_MST B (NOLOCK)
 WHERE B.CANCELLED = 1    
     
 --WHOLESALE CREDIT NOTE    
 UNION ALL    
 SELECT 'CNM'+B.CN_ID AS XN_ID
 FROM CNM01106 B (NOLOCK)
 WHERE B.CANCELLED = 1
    
 -- GENERATION OF NEW BAR CODES IN RATE REVISION    
 UNION ALL     
 SELECT 'SCM'+B.MEMO_ID AS XN_ID
 FROM SCM01106 B (NOLOCK)
 WHERE B.CANCELLED=1
      
 -- JOB WORK ISSUE    
  UNION ALL     
 SELECT 'JWI'+B.ISSUE_ID AS XN_ID
 FROM JOBWORK_ISSUE_MST B (NOLOCK)
 WHERE  B.CANCELLED=1
     
 -- JOB WORK RECEIPT    
 UNION ALL     
 SELECT 'JWR'+B.RECEIPT_ID AS XN_ID
 FROM JOBWORK_RECEIPT_MST B (NOLOCK)
 WHERE  B.CANCELLED=1
     
 UNION ALL    
     
 SELECT DISTINCT 'BOC'+D.ORDER_ID AS XN_ID   
 FROM WSL_ORDER_BOM E(NOLOCK)     
 LEFT OUTER JOIN WSL_ORDER_DET C (NOLOCK) ON E.REF_ROW_ID=C.ROW_ID    
 LEFT OUTER JOIN WSL_ORDER_MST D (NOLOCK) ON C.ORDER_ID=D.ORDER_ID    
 JOIN POD01106 P ON C.ROW_ID = P.WOD_ROW_ID     
 JOIN POM01106 PM ON P.PO_ID = PM.PO_ID      
 WHERE  PM.CANCELLED = 1    
    
 UNION ALL   
 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
 SELECT 'SNC'+B.MEMO_ID AS XN_ID
 FROM SNC_MST B (NOLOCK)
 WHERE  B.CANCELLED=1
  
 UNION ALL  
   
 SELECT 'TTM'+B.MEMO_ID AS XN_ID
 FROM PRD_TRANSFER_MAIN_MST B 
 WHERE B.CANCELLED=1

 --DEBITNOTE PACKSLIP    
 UNION ALL    
 SELECT 'DNPI'+B.PS_ID AS XN_ID
 FROM DNPS_MST B (NOLOCK) 
 WHERE B.CANCELLED = 1
