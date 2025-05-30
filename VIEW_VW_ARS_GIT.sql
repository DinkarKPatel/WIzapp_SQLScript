CREATE VIEW VW_ARS_GIT    
AS    
SELECT B.PARTY_DEPT_ID AS DEPT_ID,'TRI' AS XN_TYPE ,CONVERT(DATE,GETDATE())XN_DT,A.PRODUCT_CODE  
 ,ABS(SUM(A.QUANTITY)) AS XN_QTY,0 XN_SIGN,'STOCK' XN_MODE  
 FROM IND01106 A WITH(NOLOCK)    
 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID        
 JOIN LOCATION D WITH(NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID       
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1    
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1     
 WHERE B.CANCELLED = 0 AND ISNULL(D.SIS_LOC,0)=0 AND INV_MODE=2 AND LOC.value =HO.value AND ISNULL(B.xn_item_type,0) in (0,1)     
 GROUP BY B.PARTY_DEPT_ID,A.PRODUCT_CODE  
       
 UNION ALL        
 SELECT B.PARTY_DEPT_ID AS DEPT_ID,'TRI' AS XN_TYPE,CONVERT(DATE,GETDATE())XN_DT,A.PRODUCT_CODE  
 ,ABS(SUM(A.QUANTITY)) AS XN_QTY,0 XN_SIGN,'STOCK' XN_MODE  
 FROM RMD01106 A WITH(NOLOCK)        
 JOIN RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID        
 JOIN LOCATION D WITH(NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID        
 JOIN LOCATION E WITH(NOLOCK) ON E.DEPT_ID=  B.location_Code/*LEFT(B.RM_ID,2)      *//*Rohit 04-11-2024*/  
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1    
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1    
 WHERE B.CANCELLED = 0 AND B.DN_TYPE IN (0,1)  -- AND EXPORTED=1       
 AND ISNULL(E.SIS_LOC,0)=0 AND MODE=2 AND LOC.value =HO.value AND ISNULL(B.xn_item_type,0) in (0,1)     
 GROUP BY B.PARTY_DEPT_ID,A.PRODUCT_CODE  
          
 UNION ALL        
 SELECT B.DEPT_ID,'TRO' AS XN_TYPE,CONVERT(DATE,GETDATE())XN_DT,A.PRODUCT_CODE  
 ,-ABS(SUM(A.QUANTITY)) AS XN_QTY,0 XN_SIGN,'STOCK' XN_MODE  
 FROM PID01106 A WITH(NOLOCK)    
 JOIN PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID        
 JOIN LOCATION D WITH(NOLOCK) ON D.DEPT_ID=B.DEPT_ID      
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1    
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1    
 WHERE B.CANCELLED = 0 AND B.RECEIPT_DT<>'' AND ISNULL(D.SIS_LOC,0)=0 AND INV_MODE=2 AND LOC.VALUE=HO.VALUE AND ISNULL(B.xn_item_type,0) in (0,1)     
 GROUP BY B.DEPT_ID,A.PRODUCT_CODE  
   
   
 UNION ALL        
 SELECT B.BILLED_FROM_DEPT_ID AS DEPT_ID,'TRO' AS XN_TYPE,CONVERT(DATE,GETDATE())XN_DT,A.PRODUCT_CODE  
 ,-ABS(SUM(A.QUANTITY)) AS XN_QTY ,0 XN_SIGN,'STOCK' XN_MODE       
 FROM CND01106 A WITH(NOLOCK)        
 JOIN CNM01106 B WITH(NOLOCK) ON A.CN_ID = B.CN_ID        
 JOIN LOCATION D WITH(NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID       
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1    
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1     
 WHERE B.CANCELLED = 0 AND B.RECEIPT_DT<>'' AND B.MODE=2  AND ISNULL(D.SIS_LOC,0)=0 AND LOC.VALUE=HO.VALUE AND ISNULL(B.xn_item_type,0) in (0,1)     
 GROUP BY B.billed_from_dept_id,A.PRODUCT_CODE 