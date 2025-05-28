
create VIEW VW_XNSREPS_HBD
AS
  SELECT  CAST('PSHBD' AS VARCHAR(10)) AS XN_TYPE,
          A.MEMO_ID AS XN_ID,
          B.location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 05-11-2024*/ as dept_id,  
		  A.PRODUCT_CODE,     
		  A.QUANTITY AS XN_QTY,    
		  cast('999' as varchar(7))  AS [BIN_ID]        
  FROM HOLD_BACK_DELIVER_MST B (NOLOCK)      
  JOIN HOLD_BACK_DELIVER_det A (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
  WHERE   isnull(A.PRODUCT_CODE,'')<>''  
  AND ISNULL(A.DELIVERED,0)=0  
  
  UNION ALL    
  SELECT  CAST('PSJWI' AS VARCHAR(10)) AS XN_TYPE,
          A.issue_id AS XN_ID,
         B.location_code/*LEFT(B.issue_id,2)*//*Rohit 05-11-2024*/ as dept_id,  
		  A.PRODUCT_CODE,     
		  A.QUANTITY AS XN_QTY,    
		 '999'   AS [BIN_ID]        
  FROM POST_SALES_JOBWORK_ISSUE_MST B (NOLOCK)      
  JOIN POST_SALES_JOBWORK_ISSUE_det A (NOLOCK)ON A.issue_id = B.issue_id    
  WHERE B.CANCELLED = 0  AND B.BIN_ID='999'   
    
  UNION ALL   
  
  SELECT  CAST('PSJWR' AS VARCHAR(10)) AS XN_TYPE,
          A.receipt_id AS XN_ID,
         B.location_code/*LEFT(B.receipt_id,2)*//*Rohit 05-11-2024*/ as dept_id,  
		  A.PRODUCT_CODE,     
		  A.QUANTITY AS XN_QTY,    
		  '999'   AS [BIN_ID]        
  FROM POST_SALES_JOBWORK_RECEIPT_MST B (NOLOCK)      
     JOIN POST_SALES_JOBWORK_RECEIPT_det A (NOLOCK)ON A.receipt_id = B.receipt_id    
  WHERE   B.CANCELLED = 0  AND B.BIN_ID='999'  

  UNION ALL    

  SELECT   CAST('PSDLV' AS VARCHAR(10)) AS XN_TYPE,
          b.memo_id AS XN_ID,
          B.location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 05-11-2024*/ as dept_id,  
		  A.PRODUCT_CODE,     
		  A.QUANTITY AS XN_QTY,    
		  '999'   AS [BIN_ID]        
  FROM SLS_DELIVERY_MST B (NOLOCK)      
  JOIN SLS_DELIVERY_DET A (NOLOCK)ON A.MEMO_ID = B.MEMO_ID    
  WHERE   B.CANCELLED = 0    
  
 UNION ALL    

 SELECT  CAST('CHO' AS VARCHAR(10)) AS XN_TYPE,
          b.inv_id AS XN_ID,
		  B.location_code/*LEFT(b.inv_id,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
		  A.PRODUCT_CODE AS PRODUCT_CODE,     
		  A.QUANTITY AS XN_QTY,     
		  A.BIN_ID  AS [BIN_ID]
 FROM IND01106 A WITH(NOLOCK)    
 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
 WHERE B.CANCELLED = 0   AND ISNULL(B.PENDING_GIT,0)=0 
 and a.bin_id='999'
 
 Union all

 SELECT (CASE WHEN  (B.INV_MODE IN (0,1)) THEN 'PUR' ELSE 'CHI' END) AS XN_TYPE,     
		 B.MRR_ID AS XN_ID,     
		 B.DEPT_ID,
         a.product_code ,
         A.QUANTITY AS XN_QTY,    
         b.BIN_ID AS [BIN_ID]
 FROM PID01106 A WITH(NOLOCK)    
 JOIN PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1 
 LEFT OUTER JOIN pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
 WHERE B.CANCELLED = 0 AND c.mrr_id IS NULL
 AND A.PRODUCT_CODE<>'' AND B.RECEIPT_DT<>'' AND (b.inv_mode IN (0,1) OR loc.value<>ho.value)
 and b.BIN_ID='999'

 
 UNION ALL
 
 SELECT  'CHI' AS XN_TYPE,   
         B.MRR_ID AS XN_ID,
         B.DEPT_ID,    
		 A.PRODUCT_CODE AS PRODUCT_CODE,        
		 A.QUANTITY AS XN_QTY,     
		 b.BIN_ID AS [BIN_ID]
 FROM IND01106 A WITH(NOLOCK)    
 JOIN PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
 JOIN inm01106 d (nolock) on d.inv_id=a.inv_id
 WHERE B.CANCELLED = 0 AND b.inv_mode=2 AND d.cancelled=0
 AND B.RECEIPT_DT<>''  and b.BIN_ID ='999'