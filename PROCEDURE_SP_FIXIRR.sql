CREATE PROCEDURE SP_FIXIRR
(          
	@NQUERYID NUMERIC(3,0),                  
	@CMEMO VARCHAR(50)='',          
	@CFINYEAR VARCHAR(5) ,          
	@CWHERE VARCHAR(MAX)='',          
	@NNAVMODE NUMERIC(1,0),
	@CDEPTID VARCHAR(10)='',
	@CFROMDT VARCHAR(40)=''             
) 
--WITH ENCRYPTION 
AS         
BEGIN  

DECLARE @CCMD NVARCHAR(MAX)          
           
IF @NQUERYID=1               
   GOTO LBLNAVIGATE             
ELSE IF @NQUERYID=2              
   GOTO LBLMASTER                     
ELSE IF @NQUERYID=3              
   GOTO LBLDETAIL        
ELSE IF @NQUERYID=4             
   GOTO LBLLOCATION         
ELSE IF @NQUERYID=5            
   GOTO LBLSCAN        
ELSE IF @NQUERYID=6             
   GOTO LBLLOCATION1   
ELSE IF @NQUERYID=7             
   GOTO LBLALLLOCATION 
ELSE IF @NQUERYID=8             
   GOTO LBLCHKMRP        
ELSE IF @NQUERYID=9              
   GOTO LBLAPPROVED   
ELSE             
 GOTO LAST            
                       
LBLNAVIGATE:  -- CREATING LOOK UP TABLE           
                      
  EXEC SP_NAVIGATE 'FIXITEM_RATE_REVISION_MST',@NNAVMODE,@CMEMO,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID',@CWHERE                  
                         
  GOTO LAST                                  
                                         
                     
LBLMASTER:              
   SELECT A.*,B.USERNAME,C.USERNAME AS APPROVEDBY  FROM FIXITEM_RATE_REVISION_MST A (NOLOCK)             
   JOIN USERS B (NOLOCK) ON A.USER_CODE= B.USER_CODE   
   LEFT OUTER  JOIN USERS C (NOLOCK) ON A.APPROVED_BY_USERCODE= C.USER_CODE            
   WHERE A.MEMO_ID= @CMEMO            
                
   GOTO LAST              
                    
LBLDETAIL:                      
        SELECT F.*,SK.PURCHASE_PRICE,SK.ARTICLE_CODE, A.ARTICLE_NO,A.ARTICLE_NAME,SM.SECTION_NAME, SD.SUB_SECTION_NAME,
        SK.BARCODE_CODING_SCHEME AS CODING_SCHEME,
  P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,  
  P1.PARA1_CODE,P2.PARA2_CODE,P3.PARA3_CODE,P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE  ,SK.FIX_MRP,SK.PRODUCT_NAME,
  CAST(0 AS NUMERIC(18,2)) AS NEW_WSP,CAST(0 AS NUMERIC(18,2)) AS NEW_MRP,CAST(0 AS NUMERIC(18,2)) AS NEW_FIX_MRP,
  A.ALIAS AS ARTICLE_ALIAS,F.ROW_ID AS OLD_ROW_ID,CAST('' AS DATETIME) AS NEW_EXPIRY_DT
  FROM FIXITEM_RATE_REVISION_DET F (NOLOCK)  
  JOIN FIXITEM_RATE_REVISION_MST FMST ON FMST.MEMO_ID=F.MEMO_ID  
  JOIN SKU SK (NOLOCK) ON SK.PRODUCT_CODE=F.PRODUCT_CODE  
  JOIN ARTICLE A (NOLOCK) ON A.ARTICLE_CODE=SK.ARTICLE_CODE   
  JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE=A.SUB_SECTION_CODE  
  JOIN SECTIONM SM (NOLOCK) ON SM.SECTION_CODE=SD.SECTION_CODE  
  JOIN PARA1 P1 (NOLOCK) ON SK.PARA1_CODE=P1.PARA1_CODE  
  JOIN PARA2 P2 (NOLOCK) ON  SK.PARA2_CODE=P2.PARA2_CODE  
  JOIN PARA3 P3 (NOLOCK) ON SK.PARA3_CODE=P3.PARA3_CODE  
  JOIN PARA4 P4 (NOLOCK) ON SK.PARA4_CODE=P4.PARA4_CODE  
  JOIN PARA5 P5 (NOLOCK) ON SK.PARA5_CODE=P5.PARA5_CODE  
  JOIN PARA6 P6 (NOLOCK) ON SK.PARA6_CODE=P6.PARA6_CODE           
  WHERE F.MEMO_ID=@CMEMO             
  ORDER BY  F.SRNO             
  GOTO LAST          
         
LBLLOCATION:              
    SELECT F.REF_ROW_ID,F.LAST_UPDATE,F.TS,F.NEW_MRP,F.NEW_WSP, L.DEPT_ID,DEPT_NAME,C.CITY,S.STATE,  
    ISNULL(SK.MRP,'0.00') AS OLD_MRP,ISNULL(SK.WS_PRICE,'0.00') AS OLD_WSP ,CAST(0 AS NUMERIC(10)) AS SRNO,F.ROW_ID,
    CAST(0 AS BIT)AS CHK
    ,ISNULL(SK.FIX_MRP,'0.00') AS OLD_FIX_MRP,F.NEW_FIX_MRP,SK.EXPIRY_DT AS OLD_EXPIRY_DT,F.NEW_EXPIRY_DT    
    FROM LOCATION L (NOLOCK)     
    JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=L.AREA_CODE      
    JOIN CITY C (NOLOCK) ON C.CITY_CODE=AR.CITY_CODE      
    JOIN STATE S (NOLOCK) ON S.STATE_CODE=C.STATE_CODE      
    JOIN FIXITEM_RATE_REVISION_LOC_DET F (NOLOCK) ON F.DEPT_ID=L.DEPT_ID   
    JOIN FIXITEM_RATE_REVISION_DET FDET (NOLOCK) ON FDET.ROW_ID=F.REF_ROW_ID  
    JOIN FIXITEM_RATE_REVISION_MST FMST (NOLOCK) ON FMST.MEMO_ID=FDET.MEMO_ID  
    JOIN SKU SK (NOLOCK)  ON SK.PRODUCT_CODE=FDET.PRODUCT_CODE        
    WHERE FMST.MEMO_ID=@CMEMO   
      
  GOTO LAST       
        
LBLLOCATION1:        
  SELECT CAST(0 AS NUMERIC(10)) AS SRNO,DEPT_NAME,    
  C.CITY,S.STATE,--'' AS CURR_MRP,'' AS CURR_WSP,    
  F.*     
  FROM LOCATION L      
   JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=L.AREA_CODE      
   JOIN CITY C (NOLOCK) ON C.CITY_CODE=AR.CITY_CODE      
   JOIN STATE S (NOLOCK) ON S.STATE_CODE=C.STATE_CODE    
  LEFT OUTER JOIN FIXITEM_RATE_REVISION_LOC_DET F (NOLOCK) ON F.DEPT_ID=L.DEPT_ID     
  WHERE 1=2     
  ORDER BY L.DEPT_ID    
  GOTO LAST             
         
  LBLSCAN:          
  SELECT S.*,A.ARTICLE_NO,A.ARTICLE_NAME,SM.SECTION_NAME, SD.SUB_SECTION_NAME,S.BARCODE_CODING_SCHEME AS CODING_SCHEME,  
  P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,A.ALIAS AS ARTICLE_ALIAS 
  FROM SKU S (NOLOCK) 
  JOIN ARTICLE A (NOLOCK) ON A.ARTICLE_CODE=S.ARTICLE_CODE   
  JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE=A.SUB_SECTION_CODE  
  JOIN SECTIONM SM (NOLOCK) ON SM.SECTION_CODE=SD.SECTION_CODE  
  JOIN PARA1 P1 (NOLOCK) ON S.PARA1_CODE=P1.PARA1_CODE  
  JOIN PARA2 P2 (NOLOCK) ON S.PARA2_CODE=P2.PARA2_CODE  
  JOIN PARA3 P3 (NOLOCK) ON S.PARA3_CODE=P3.PARA3_CODE  
  JOIN PARA4 P4 (NOLOCK) ON S.PARA4_CODE=P4.PARA4_CODE  
  JOIN PARA5 P5 (NOLOCK) ON S.PARA5_CODE=P5.PARA5_CODE  
  JOIN PARA6 P6 (NOLOCK) ON S.PARA6_CODE=P6.PARA6_CODE  
  WHERE  S.BARCODE_CODING_SCHEME=1 AND S.PRODUCT_CODE= @CWHERE     
  GOTO LAST    
          
  LBLALLLOCATION:   
  SELECT  L.DEPT_ID,DEPT_NAME,C.CITY,S.STATE      
  FROM LOCATION L (NOLOCK)     
  LEFT OUTER JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=L.AREA_CODE      
  LEFT OUTER JOIN CITY C (NOLOCK) ON C.CITY_CODE=AR.CITY_CODE      
  LEFT OUTER JOIN STATE S (NOLOCK) ON S.STATE_CODE=C.STATE_CODE 
  WHERE L.DEPT_ID=L.MAJOR_DEPT_ID AND L.INACTIVE=0
  ORDER BY L.DEPT_ID

  GOTO LAST
   
   
LBLCHKMRP:
 
   
  
  
    SELECT TOP 1 LOC.DEPT_ID, LOC.DEPT_NAME, S.PRODUCT_CODE,S.MRP,S.WS_PRICE ,  
           ISNULL(L.MRP,S.MRP) AS NEW_MRP,ISNULL(L.WS_PRICE,S.WS_PRICE) AS NEW_WSP ,
           ISNULL(L.MRP,S.FIX_MRP) AS NEW_FIX_MRP 
	FROM SKU S (NOLOCK) 
	LEFT OUTER JOIN       
	(      
		SELECT TOP 1 PRODUCT_CODE,MRP,WS_PRICE ,FROM_DT,DEPT_ID         
		FROM LOCSKUSP  (NOLOCK)       
		WHERE PRODUCT_CODE=@CWHERE AND DEPT_ID=@CDEPTID   AND ( FROM_DT <= @CFROMDT OR @CFROMDT=''  )       
		ORDER BY FROM_DT DESC          
	)L ON L.PRODUCT_CODE=S.PRODUCT_CODE   
	LEFT OUTER JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID=L.DEPT_ID  
	WHERE S.PRODUCT_CODE=@CWHERE AND LOC.DEPT_ID=@CDEPTID
	ORDER BY L.FROM_DT DESC  
   

   GOTO LAST       

LBLAPPROVED:

   SELECT  TOP 1 DEL.*,MST.MEMO_NO FROM  FIXITEM_RATE_REVISION_DET DEL
   JOIN FIXITEM_RATE_REVISION_MST MST ON MST.MEMO_ID=DEL.MEMO_ID
   WHERE DEL.PRODUCT_CODE=@CWHERE   AND MST.APPROVED=0  AND MST.TYPE=1

   GOTO LAST               
   
LAST:          
          
END
