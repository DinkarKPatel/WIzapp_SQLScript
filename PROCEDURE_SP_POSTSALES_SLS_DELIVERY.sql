CREATE PROCEDURE SP_POSTSALES_SLS_DELIVERY        
(        
  @IMODE INT ,        
  @CWHERE VARCHAR(4000)='' ,    
  @CFINYEAR VARCHAR(10)=''          
)      
----WITH ENCRYPTION
  
AS        
        
BEGIN        
         
 IF @IMODE =1        
 GOTO LBLHBDMST        
         
 ELSE IF @IMODE =2        
 GOTO LBLHBDDET        
         
 ELSE IF @IMODE =3        
 GOTO LBLMST        
         
 ELSE IF @IMODE =4        
 GOTO LBLDET        
         
 ELSE IF @IMODE =5        
 GOTO LBLLOOKUP 
 
 ELSE IF @IMODE =6 
  GOTO LBLHBDDET_D  
        
 ELSE IF @IMODE =7 
  GOTO LBLBILLMST  
ELSE IF @IMODE =8 
  GOTO LBLBILLFIND          
 ELSE IF @IMODE =9
  GOTO LBLCONS          

 ELSE        
 GOTO LAST         

LBLCONS:
	SELECT a.*,c.article_no ,d.quantity_in_stock
	FROM SLS_DELIVERY_CONS a (NOLOCK)
	JOIN SKU b  (NOLOCK) ON b.product_code=a.product_code
	JOIN ARTICLE c  (NOLOCK) ON c.article_code=b.article_code
	LEFT OUTER JOIN PMT01106 d  (NOLOCK) ON d.product_code=b.product_code  AND a.bin_id=d.BIN_ID
	WHERE a.memo_id=@cwhere
	GOTO LAST
        
LBLHBDMST:        
        
 SELECT DISTINCT MEMO_NO,CM_ID,CM_NO,CUSTOMER_CODE,CUSTOMER_NAME,CANCELLED,CUSTOMER_ADDRESS,USER_CUSTOMER_CODE           
 FROM VW_POSTSALES_HBDPRINT (NOLOCK)          
 WHERE CANCELLED= 0 AND CM_NO = @CWHERE AND FIN_YEAR=@CFINYEAR           
 GOTO LAST        
         
LBLHBDDET:         

	 SELECT (CAST(1 AS BIT)) AS CHKDELIVER , C.PRODUCT_CODE ,        
	 G.CM_ID,A.MEMO_NO,A.MEMO_DT,G.CM_NO,G.CM_DT, A.CANCELLED,A.CUSTOMER_CODE,B.*,(CAST(1 AS NUMERIC(10,2))) AS QUANTITY,        
	 ART.ARTICLE_CODE, ART.ARTICLE_NO, ART.ARTICLE_NAME, P1.PARA1_CODE,          
	 PARA1_NAME, P2.PARA2_CODE,PARA2_NAME,P3.PARA3_CODE,PARA3_NAME,UOM_NAME,             
	 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,SKU.PURCHASE_PRICE,        
	 SKU.MRP,SKU.WS_PRICE,   SM.SECTION_NAME, SD.SUB_SECTION_NAME,          
	 P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,          
	 PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],          
	 ART.DT_CREATED AS [ART_DT_CREATED],P3.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],          
	 ART.STOCK_NA,F.JOB_NAME,        
	 (H.CUSTOMER_FNAME  + ' ' + H.CUSTOMER_LNAME) AS CUSTOMER_NAME,        
	 (H.ADDRESS1 + ',' + H.ADDRESS2 + ',' + I.AREA_NAME + ',' + I.PINCODE + ',' + J.CITY + ',' + K.STATE) AS CUSTOMER_ADDRESS ,    
	 G.FIN_YEAR      
	  --CHANGES    
	  ,EMP.EMP_CODE,EMP.EMP_NAME,ART.ALIAS AS ARTICLE_ALIAS,EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_NAME AS EMP_NAME2 ,A.memo_no AS HBD_MEMO_NO
	  ,A.memo_id AS HBD_MEMO_ID
	 FROM HOLD_BACK_DELIVER_MST A (NOLOCK)         
	 JOIN HOLD_BACK_DELIVER_DET B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID         
	 JOIN POST_SALES_JOBWORK_ISSUE_DET P (NOLOCK) ON P.REF_HBD_ROW_ID = B.ROW_ID       
	 JOIN POST_SALES_JOBWORK_ISSUE_MST ISSMST (NOLOCK) ON ISSMST.ISSUE_ID=P.ISSUE_ID       
	 JOIN POST_SALES_JOBWORK_RECEIPT_DET Q (NOLOCK) ON P.ROW_ID = Q.REF_ROW_ID        
	 JOIN POST_SALES_JOBWORK_RECEIPT_MST RMST ON RMST.RECEIPT_ID=Q.RECEIPT_ID      
	 JOIN CMD01106 C (NOLOCK) ON C.ROW_ID = B.REF_CMD_ROW_ID         
	 JOIN CMM01106 G (NOLOCK) ON C.CM_ID = G.CM_ID         
	 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=C.PRODUCT_CODE        
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
	 LEFT JOIN JOBS F (NOLOCK) ON F.JOB_CODE = P.JOB_CODE         
	 JOIN CUSTDYM H (NOLOCK) ON A.CUSTOMER_CODE = H.CUSTOMER_CODE        
	 JOIN AREA I (NOLOCK) ON I.AREA_CODE = H.AREA_CODE         
	 JOIN CITY J (NOLOCK) ON J.CITY_CODE = I.CITY_CODE         
	 JOIN STATE K (NOLOCK) ON K.STATE_CODE = J.STATE_CODE            
	 JOIN EMPLOYEE EMP ON EMP.EMP_CODE=C.EMP_CODE
	 LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON C.EMP_CODE1 = EMP1.EMP_CODE     
	LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON C.EMP_CODE2 = EMP2.EMP_CODE    
	          
	 WHERE P.JOB_CODE <> '0000000' AND A.CANCELLED = 0 AND B.DELIVERED=0  AND ISSMST.CANCELLED = 0 AND      
	 RMST.CANCELLED = 0  AND B.ROW_ID NOT IN       
	 (SELECT M.REF_HBD_ROW_ID FROM  SLS_DELIVERY_DET M (NOLOCK)         
	 JOIN SLS_DELIVERY_MST N (NOLOCK) ON M.MEMO_ID = N.MEMO_ID WHERE N.CANCELLED = 0)       
	 AND G.CM_NO = @CWHERE  AND   G.FIN_YEAR=@CFINYEAR           
	 
 GOTO LAST  
 
 
 
 LBLHBDDET_D:         
 SELECT (CAST(1 AS BIT)) AS CHKDELIVER , C.PRODUCT_CODE ,        
 G.CM_ID,A.MEMO_NO,A.MEMO_DT,G.CM_NO,G.CM_DT, A.CANCELLED,A.CUSTOMER_CODE,B.*,(CAST(1 AS NUMERIC(10,2))) AS QUANTITY,        
 ART.ARTICLE_CODE, ART.ARTICLE_NO, ART.ARTICLE_NAME, P1.PARA1_CODE,          
 PARA1_NAME, P2.PARA2_CODE,PARA2_NAME,P3.PARA3_CODE,PARA3_NAME,UOM_NAME,             
 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,SKU.PURCHASE_PRICE,        
 SKU.MRP,SKU.WS_PRICE,   SM.SECTION_NAME, SD.SUB_SECTION_NAME,          
 P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,          
 PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],          
 ART.DT_CREATED AS [ART_DT_CREATED],P3.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],          
 ART.STOCK_NA,F.JOB_NAME,        
 (H.CUSTOMER_FNAME  + ' ' + H.CUSTOMER_LNAME) AS CUSTOMER_NAME,        
 (H.ADDRESS1 + ',' + H.ADDRESS2 + ',' + I.AREA_NAME + ',' + I.PINCODE + ',' + J.CITY + ',' + K.STATE) AS CUSTOMER_ADDRESS ,    
 G.FIN_YEAR      

  ,EMP.EMP_CODE,EMP.EMP_NAME,ART.ALIAS AS ARTICLE_ALIAS    ,EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_NAME AS EMP_NAME2,A.memo_no AS HBD_MEMO_NO   
 FROM HOLD_BACK_DELIVER_MST A (NOLOCK)         
 JOIN HOLD_BACK_DELIVER_DET B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID         
   
 JOIN CMD01106 C (NOLOCK) ON C.ROW_ID = B.REF_CMD_ROW_ID         
 JOIN CMM01106 G (NOLOCK) ON C.CM_ID = G.CM_ID         
 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=C.PRODUCT_CODE        
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
 LEFT JOIN JOBS F (NOLOCK) ON F.JOB_CODE = B.JOB_CODE         
 JOIN CUSTDYM H (NOLOCK) ON A.CUSTOMER_CODE = H.CUSTOMER_CODE        
 JOIN AREA I (NOLOCK) ON I.AREA_CODE = H.AREA_CODE         
 JOIN CITY J (NOLOCK) ON J.CITY_CODE = I.CITY_CODE         
 JOIN STATE K (NOLOCK) ON K.STATE_CODE = J.STATE_CODE            
 JOIN EMPLOYEE EMP ON EMP.EMP_CODE=C.EMP_CODE  
 LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON C.EMP_CODE1 = EMP1.EMP_CODE     
LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON C.EMP_CODE2 = EMP2.EMP_CODE    
        
 WHERE  A.CANCELLED = 0   AND B.DELIVERED=0 AND B.ROW_ID NOT IN       
 (SELECT M.REF_HBD_ROW_ID FROM  SLS_DELIVERY_DET M (NOLOCK)         
 JOIN SLS_DELIVERY_MST N (NOLOCK) ON M.MEMO_ID = N.MEMO_ID WHERE N.CANCELLED = 0)       
 AND G.CM_NO = @CWHERE  AND   G.FIN_YEAR=@CFINYEAR           
 GOTO LAST  
      
         
LBLMST:        
 SELECT A.*,(C.CUSTOMER_FNAME  + ' ' + C.CUSTOMER_LNAME) AS CUSTOMER_NAME, C.USER_CUSTOMER_CODE,   
 (C.CUSTOMER_FNAME  + ' ' + C.CUSTOMER_LNAME + CHAR(10) + C.ADDRESS1 + ' ' + C.ADDRESS2 + ' ' + D.AREA_NAME + ' ' + D.PINCODE + ' ' + E.CITY + ' ' + F.STATE) AS     
 CUSTOMER_ADDRESS     ,ISNULL(EMP.EMP_NAME,'') AS EMP_NAME
 FROM SLS_DELIVERY_MST A (NOLOCK)       
 JOIN CUSTDYM C (NOLOCK) ON A.CUSTOMER_CODE = C.CUSTOMER_CODE    
 JOIN AREA D (NOLOCK) ON D.AREA_CODE = C.AREA_CODE     
 JOIN CITY E (NOLOCK) ON E.CITY_CODE = D.CITY_CODE     
 JOIN STATE F (NOLOCK) ON F.STATE_CODE = E.STATE_CODE   
 left JOIN EMPLOYEE EMP ON EMP.EMP_CODE=A.EMP_CODE
 WHERE A.MEMO_ID = @CWHERE          
    
    
 
 GOTO LAST        
         
LBLDET:         

	;WITH HBD
	AS
	(
		 SELECT J.MEMO_NO, J.MEMO_ID,H.ROW_ID,H.REF_CMD_ROW_ID ,J.REMARKS AS BILL_REMARKS ,H.REMARKS AS ITEM_REMARKS ,H.job_code,I.JOB_RATE,JB.job_name
		 FROM HOLD_BACK_DELIVER_MST J
		 JOIN HOLD_BACK_DELIVER_DET H (NOLOCK) ON J.MEMO_ID = H.MEMO_ID
		 JOIN SLS_DELIVERY_DET B (NOLOCK) ON H.ROW_ID = B.REF_HBD_ROW_ID  
		 LEFT OUTER JOIN ITEM_STATUS I (NOLOCK) ON I.HBD_MEMO_ID=J.MEMO_ID AND I.HBD_ROW_ID=H.row_id
		 LEFT OUTER JOIN JOBS (NOLOCK) JB ON JB.job_code=H.job_code
		 WHERE J.CANCELLED =0 AND H.DELIVERED=0
		 AND B.memo_id=@CWHERE  
	)
	 SELECT  H.MEMO_NO AS HBD_MEMO_NO,CAST(1 AS BIT) AS CHKDELIVER,        
	 C.CM_NO,C.CM_ID,B.*,C.PRODUCT_CODE,(CAST(1 AS NUMERIC(10,2))) AS QUANTITY,        
	ART.ARTICLE_CODE, ART.ARTICLE_NO, ART.ARTICLE_NAME, P1.PARA1_CODE,          
	 PARA1_NAME, P2.PARA2_CODE,PARA2_NAME,P3.PARA3_CODE,PARA3_NAME,UOM_NAME,             
	 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,SKU.PURCHASE_PRICE,        
	 SKU.MRP,SKU.WS_PRICE,   SM.SECTION_NAME, SD.SUB_SECTION_NAME,          
	 P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,          
	 PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],          
	 ART.DT_CREATED AS [ART_DT_CREATED],P3.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],          
	 ART.STOCK_NA,
	 H.JOB_NAME ,H.JOB_CODE,
	 C.DISCOUNT_PERCENTAGE,C.DISCOUNT_AMOUNT,C.NET     
		--CHANGES    
	,EMP.EMP_CODE AS EMP_CODE,EMP.EMP_NAME AS EMP_NAME,ART.ALIAS AS ARTICLE_ALIAS ,EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_NAME AS EMP_NAME2,SKU.MRP
	,BILL_REMARKS,ITEM_REMARKS         ,H.memo_no AS HBD_MEMO_NO,
	(CUST.CUSTOMER_FNAME +' '+ CUST.CUSTOMER_LNAME) AS CUST_NAME,CUST.MOBILE ,H.JOB_RATE,H.memo_id AS HBD_MEMO_ID
	 FROM SLS_DELIVERY_MST A (NOLOCK)        
	 JOIN SLS_DELIVERY_DET B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
	 JOIN HBD H ON H.ROW_ID = B.REF_HBD_ROW_ID 
	 --JOIN 
	 --(
		-- SELECT J.MEMO_NO, J.MEMO_ID,ROW_ID,REF_CMD_ROW_ID ,J.REMARKS AS BILL_REMARKS ,H.REMARKS AS ITEM_REMARKS ,H.job_code,H.JOB_RATE,JB.job_name
		-- FROM HOLD_BACK_DELIVER_MST J
		-- JOIN HOLD_BACK_DELIVER_DET H (NOLOCK) ON J.MEMO_ID = H.MEMO_ID
		-- LEFT OUTER JOIN JOBS (NOLOCK) JB ON JB.job_code=H.job_code
		-- WHERE J.CANCELLED =0 AND DELIVERED=0
	 --) H ON H.ROW_ID = B.REF_HBD_ROW_ID   
	 LEFT JOIN
	 (
		SELECT CMM.CM_ID,CMM.CM_NO,PRODUCT_CODE,EMP_CODE,EMP_CODE1,EMP_CODE2,ROW_ID,
			   CMD.DISCOUNT_PERCENTAGE,CMD.DISCOUNT_AMOUNT,CMD.NET    
		FROM CMM01106 CMM (NOLOCK)
		JOIN CMD01106 CMD (NOLOCK) ON CMM.CM_ID =CMD.CM_ID 
		WHERE CMM.CANCELLED =0
	 )  C ON   C.ROW_ID = H.REF_CMD_ROW_ID              
	 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=B.PRODUCT_CODE        
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
	 left JOIN EMPLOYEE EMP ON EMP.EMP_CODE=C.EMP_CODE
	 LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON C.EMP_CODE1 = EMP1.EMP_CODE     
	 LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON C.EMP_CODE2 = EMP2.EMP_CODE    
	 left JOIN CUSTDYM Cust ON Cust.CUSTOMER_CODE=a.CUSTOMER_CODE
	 WHERE B.MEMO_ID=@CWHERE          
	
	
	--UNION
	-- SELECT  J.MEMO_NO AS HBD_MEMO_NO,CAST(1 AS BIT) AS CHKDELIVER,        
	-- '' AS CM_NO,'' AS CM_ID,B.*,SKU.PRODUCT_CODE,(CAST(1 AS NUMERIC(10,2))) AS QUANTITY,        
	-- ART.ARTICLE_CODE, ART.ARTICLE_NO, ART.ARTICLE_NAME,'0000000' AS PARA1_CODE,          
	-- '' AS PARA1_NAME,'0000000' AS PARA2_CODE,'' AS PARA2_NAME,'0000000' AS PARA3_CODE,'' AS PARA3_NAME,UOM_NAME,             
	-- CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,0 AS PURCHASE_PRICE,        
	-- 0 AS MRP,0 AS WS_PRICE,   SM.SECTION_NAME, SD.SUB_SECTION_NAME,          
	-- '0000000' AS PARA4_CODE,'' AS PARA5_CODE,'0000000' AS PARA6_CODE,          
	-- '' AS PARA4_NAME,'' AS PARA5_NAME,'' AS PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],          
	-- ART.DT_CREATED AS [ART_DT_CREATED],'' AS  [PARA3_DT_CREATED],'' AS [SKU_DT_CREATED],          
	-- ART.STOCK_NA,0 AS DISCOUNT_PERCENTAGE,0 AS DISCOUNT_AMOUNT,0 AS NET,     
	-- '' AS EMP_CODE,'' AS EMP_NAME,ART.ALIAS AS ARTICLE_ALIAS ,'' AS EMP_NAME1 ,'' AS EMP_NAME2,
	-- 0 AS MRP,'' AS BILL_REMARKS,'' AS ITEM_REMARKS ,J.memo_no AS HBD_MEMO_NO        
	-- FROM SLS_DELIVERY_MST A (NOLOCK)        
	-- JOIN SLS_DELIVERY_DET B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  

	-- JOIN HOLD_BACK_DELIVER_DET H (NOLOCK) ON H.ROW_ID=B.REF_HBD_ROW_ID
	-- JOIN HOLD_BACK_DELIVER_MST J (NOLOCK) ON J.MEMO_ID=H.MEMO_ID
 --	 JOIN SKU_REPAIR SKU (NOLOCK) ON SKU.PRODUCT_CODE=H.PRODUCT_CODE        
	-- JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE            
	-- JOIN SECTIOND SD (NOLOCK) ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE          
	-- JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE          
	-- JOIN UOM E (NOLOCK)ON ART.UOM_CODE = E.UOM_CODE      
	-- WHERE J.CANCELLED =0 AND H.DELIVERED=0
	-- AND B.MEMO_ID=@CWHERE AND J.MODE=2         		 
	 
 GOTO LAST        
         
LBLLOOKUP:        
	SELECT * FROM SLS_DELIVERY_MST (NOLOCK) ORDER BY LAST_UPDATE DESC     
	GOTO LAST    
LBLBILLMST:
	DECLARE @DTSQL NVARCHAR(MAX)
    SET @CWHERE= REPLACE(REPLACE(@CWHERE,',',''','''),' ','')

   SET @DTSQL=N'SELECT CMM.CM_NO AS BILL_NO,CMM.CM_DT AS BILL_DT
       ,ISNULL(SUBTOTAL,0) +ISNULL(SUBTOTAL_R,0) AS AMOUNT
       ,ISNULL(CR_AMOUNT,0) AS CREDIT_AMOUNT 
       ,(ISNULL(SUBTOTAL,0) +ISNULL(SUBTOTAL_R,0))-ISNULL(CR_AMOUNT,0) AS RECEIVABLE_AMOUNT
       ,C.MOBILE,
       CUSTOMER=CUSTOMER_TITLE+ '' ''+CUSTOMER_FNAME+'' ''+CUSTOMER_LNAME
       FROM CMM01106 CMM (NOLOCK)
       LEFT JOIN 
       (SELECT XN.MEMO_ID,SUM(AMOUNT) AS CR_AMOUNT 
         FROM  PAYMODE_XN_DET XN (NOLOCK)
         JOIN PAYMODE_MST M (NOLOCK) ON M.PAYMODE_CODE=XN.PAYMODE_CODE
         JOIN PAYMODE_GRP_MST GM (NOLOCK) ON GM.PAYMODE_GRP_CODE=M.PAYMODE_GRP_CODE
         WHERE GM.PAYMODE_GRP_CODE =''0000004''
         GROUP BY XN.MEMO_ID
       ) XN ON XN.MEMO_ID=CMM.CM_ID
       JOIN CUSTDYM C ON C.CUSTOMER_CODE=CMM.CUSTOMER_CODE
       WHERE CMM.CANCELLED=0 AND  CMM.CM_ID IN('''+@CWHERE+''')'

    PRINT @DTSQL
    EXEC SP_EXECUTESQL @DTSQL            
    GOTO LAST 
    
LBLBILLFIND:
    
	SELECT M.CM_ID,A.MEMO_NO,A.MEMO_DT,M.CM_NO,M.CM_DT, A.CANCELLED,A.CUSTOMER_CODE,
	(H.CUSTOMER_FNAME  + ' ' + H.CUSTOMER_LNAME) AS CUSTOMER_NAME,    
	(H.ADDRESS1 + ',' + H.ADDRESS2 + ',' + I.AREA_NAME + ',' + I.PINCODE + ',' 
	+ J.CITY + ',' + K.STATE) AS CUSTOMER_ADDRESS  
	FROM HOLD_BACK_DELIVER_MST A (NOLOCK)   
	JOIN HOLD_BACK_DELIVER_DET B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	JOIN CMD01106 C (NOLOCK) ON C.ROW_ID = B.REF_CMD_ROW_ID      
	JOIN CMM01106 M (NOLOCK) ON C.CM_ID = M.CM_ID             
	JOIN CUSTDYM H (NOLOCK) ON A.CUSTOMER_CODE = H.CUSTOMER_CODE  
	JOIN AREA I (NOLOCK) ON I.AREA_CODE = H.AREA_CODE   
	JOIN CITY J (NOLOCK) ON J.CITY_CODE = I.CITY_CODE   
	JOIN STATE K (NOLOCK) ON K.STATE_CODE = J.STATE_CODE   

    GOTO LAST 
    
    
         
LAST:        
            
END
