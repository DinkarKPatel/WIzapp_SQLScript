CREATE VIEW VW_PRD_JOBWORKRECEIPTPRINT  
  
AS  
 SELECT M.ISSUE_ID AS ISSUE_ID, A.CHALLAN_DT AS RECEIPR_CHALLAN_DT, A.REMARKS AS MST_REMARKS, B.REMARKS,B.TS,  
 B.PRODUCT_CODE,B.JOB_RATE,B.QUANTITY,A.RECEIPT_NO,A.RECEIPT_DT,A.JOB_CODE,A.NET_AMOUNT,  
 A.RECEIVED_BY,A.CANCELLED, F.JOB_NAME,  
 ART.ARTICLE_CODE, ART.ARTICLE_NO, ART.ARTICLE_NAME,UOM_NAME,       
 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,SKU.PURCHASE_PRICE,  
 SKU.MRP,SKU.WS_PRICE,   SM.SECTION_NAME, SD.SUB_SECTION_NAME,    
 P1.PARA1_CODE,P1.PARA1_NAME, P2.PARA2_CODE,P2.PARA2_NAME,P3.PARA3_CODE,P3.PARA3_NAME,P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,    
 PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],    
 ART.DT_CREATED AS [ART_DT_CREATED],P3.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],    
 ART.STOCK_NA,  
 ART.DT_CREATED ,Y.AGENCY_NAME ,'' AS ADDRESS ,B.REF_ROW_ID ,B.ROW_ID ,N.ISSUE_TYPE ,A.RECEIPT_ID,  
 M.REF_NO,N.ISSUE_NO,M.REMARKS AS ISSUE_REMARKS,COM.COMPANY_NAME,COM.ADDRESS9  
 FROM PRD_JOBWORK_RECEIPT_MST A (NOLOCK)                   
 JOIN PRD_JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID      
 JOIN PRD_JOBWORK_ISSUE_DET M (NOLOCK) ON M.ROW_ID = B.REF_ROW_ID   
 JOIN PRD_JOBWORK_ISSUE_MST N (NOLOCK) ON M.ISSUE_ID = N.ISSUE_ID   
 JOIN PRD_AGENCY_MST Y (NOLOCK) ON N.AGENCY_CODE = Y.AGENCY_CODE   
 JOIN PRD_SKU SKU (NOLOCK) ON SKU.PRODUCT_UID =B.PRODUCT_UID   
 JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE      
 JOIN SECTIOND SD (NOLOCK) ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE    
 JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE    
 JOIN PARA1 P1 (NOLOCK) ON SKU.PARA1_CODE = P1.PARA1_CODE      
 JOIN PARA2 P2 (NOLOCK) ON SKU.PARA2_CODE = P2.PARA2_CODE      
 JOIN PARA3 P3 (NOLOCK)ON SKU.PARA3_CODE = P3.PARA3_CODE      
 JOIN PARA4 P4 (NOLOCK)ON SKU.PARA4_CODE = P4.PARA4_CODE      
 JOIN PARA5 P5 (NOLOCK)ON SKU.PARA5_CODE = P5.PARA5_CODE      
 JOIN PARA6 P6 (NOLOCK)ON SKU.PARA6_CODE = P6.PARA6_CODE      
 JOIN UOM E (NOLOCK)ON ART.UOM_CODE = E.UOM_CODE   
 JOIN JOBS F (NOLOCK) ON F.JOB_CODE = M.JOB_CODE
 JOIN COMPANY COM(NOLOCK) ON COM.COMPANY_CODE ='01'
