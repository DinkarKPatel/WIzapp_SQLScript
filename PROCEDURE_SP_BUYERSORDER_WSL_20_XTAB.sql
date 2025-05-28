
create PROCEDURE SP_BUYERSORDER_WSL_20_XTAB
@CMEMOID VARCHAR(40)='',
@CWHERE VARCHAR(500)=''
--WITH ENCRYPTION
 
AS    
BEGIN 
   
   
    DECLARE @DBNAME VARCHAR(100),@DTDQL NVARCHAR(MAX)
    SET @DBNAME=DB_NAME ()+'_IMAGE.dbo.'
    IF OBJECT_ID ('TEMPDB..#TMPIMG','U') IS NOT NULL
       DROP TABLE #TMPIMG
       
       SELECT A.ROW_ID ,A.ARTICLE_CODE,
       CAST(null AS VARBINARY(MAX)) AS PROD_IMAGE,
       CAST(null AS VARBINARY(MAX)) AS PROD_IMAGE1,
       CAST(null AS VARBINARY(MAX)) AS PROD_IMAGE2,
       CAST(null AS VARBINARY(MAX)) AS PROD_IMAGE3
       INTO #TMPIMG
       FROM BUYER_ORDER_DET A
       WHERE A.ORDER_ID =@CWHERE
      
      SET @DTDQL=N' UPDATE A SET  PROD_IMAGE=I.PROD_IMAGE ,
      PROD_IMAGE1=I.PROD_IMAGE1,
      PROD_IMAGE2=I.PROD_IMAGE2 ,
      PROD_IMAGE3=I.PROD_IMAGE3 
      FROM #TMPIMG A
      JOIN '+@DBNAME+' IMAGE_INFO I ON I.ARTICLE_CODE=A.ARTICLE_CODE '
      print @DTDQL
      EXEC SP_EXECUTESQL @DTDQL

IF OBJECT_ID ('TEMPDB..#TMPDETAILS','U') IS NOT NULL                        
         DROP TABLE #TMPDETAILS  

SELECT  T1.ORDER_DT,T1.ORDER_NO,T2.AC_NAME,T1.TOTAL_AMOUNT, 
     T1.OTHER_CHARGES AS OTHER_CHARGES,T1.DISCOUNT_AMOUNT AS MST_DISCOUNT_AMOUNT,      
     T1.SUBTOTAL AS AMOUNT_WO_TAX,PARA1.PARA1_NAME,
	 --,PARA2.PARA2_NAME,PARA2.PARA2_ORDER,PARA3.PARA3_NAME, 
  --   PARA4.PARA4_NAME,PARA5.PARA5_NAME,PARA6.PARA6_NAME, 
     T1.PAYMENT_DETAILS,SECTIOND.SUB_SECTION_NAME,SECTIONM.SECTION_NAME,ARTICLE.ARTICLE_NO,  
     SUM(T3.QUANTITY) AS QTY  ,COM.COMPANY_CODE ,COM.LOGO_PATH,
	 COM.COMPANY_NAME  AS COMPANY_NAME ,
     L.ADDRESS1 AS COM_ADDRESS1,
     L.ADDRESS2 AS COM_ADDRESS2,
     LCT.CITY AS COM_CITY,
     L.PHONE PHONES_FAX
     ,T1.TRAIL_DT,T1.DELIVERY_DT  ,T2.ADDRESS0,T2.ADDRESS1,T2.ADDRESS2,T2.AREA_NAME,T2.CITY,T2.STATE,T2.PINCODE,
	 ARTICLE.DT_CREATED, EMP.EMP_NAME ,T1.REF_NO,ARTICLE.MRP,ARTICLE.WHOLESALE_PRICE,ARTICLE.PURCHASE_PRICE,
	 ARTICLE.ALIAS AS ARTICLE_ALIAS,ARTICLE.ARTICLE_NAME,T2.TIN_NO,T1.REMARKS AS MST_REMARKS,
	 SR_NO=ROW_NUMBER() OVER (ORDER BY T1.ORDER_DT,article.article_no,para1.para1_name) ,
	 SUM(T3.QUANTITY*T3.WS_PRICE) AS AMOUNT,
	 --,T3.GROSS_QUANTITY,
	 i.PROD_IMAGE ,
	 i.PROD_IMAGE1,
	 i.PROD_IMAGE2,
	 PROD_IMAGE3,
	 T1.CHECKED_BY,
	 T1.SENT_BY,
	 T1.booked_by ,
	 L.dept_name  AS WBO_FOR_DEPT_NAME,
	 T1.shipping_Address,
	 T1.shipping_address2,
	 T1.shipping_address3,
	 T1.shipping_area_code,
	 T1.shipping_area_name,
	 T1.shipping_city_name,
	 T1.shipping_pin,
	 T1.shipping_state_name,
     AN.Angadia_name AS TRANSPORTER_NAME,
     T1.pay_type,
     EMP1.emp_name AS SALE_PERSON,
     EMP.emp_name AS ALLOCATED_TO
	,CAST(0 AS INT)SIZE1,CAST(0 AS INT)SIZE2,CAST(0 AS INT)SIZE3,CAST(0 AS INT)SIZE4,CAST(0 AS INT)SIZE5,CAST(0 AS INT)SIZE6              
    ,CAST(0 AS INT)SIZE7,CAST(0 AS INT)SIZE8,CAST(0 AS INT)SIZE9,CAST(0 AS INT)SIZE10,CAST(0 AS INT)SIZE11,CAST(0 AS INT)SIZE12 
	,CAST(0 AS INT)SIZE13,CAST(0 AS INT)SIZE14,CAST(0 AS INT)SIZE15,CAST(0 AS INT)SIZE16,CAST(0 AS INT)SIZE17,CAST(0 AS INT)SIZE18
	,CAST(0 AS INT)SIZE19,CAST(0 AS INT)SIZE20,CAST(0 AS INT)SIZE21,CAST(0 AS INT)SIZE22,CAST(0 AS INT)SIZE23,CAST(0 AS INT)SIZE24
	,CAST(0 AS INT)SIZE25,CAST(0 AS INT)SIZE26,CAST(0 AS INT)SIZE27,CAST(0 AS INT)SIZE28,CAST(0 AS INT)SIZE29,CAST(0 AS INT)SIZE30
	,CAST(0 AS INT)SIZE31,CAST(0 AS INT)SIZE32,CAST(0 AS INT)SIZE33,CAST(0 AS INT)SIZE34,CAST(0 AS INT)SIZE35,CAST(0 AS INT)SIZE36
	 
	,T3.ws_price ,PARA1.para1_code ,
	L.loc_gst_no ,T2.Ac_gst_no AS PARTY_GST_NO
	 into #TMPDETAILS
     FROM BUYER_ORDER_MST T1      
     JOIN LMV01106 T2 ON T1.AC_CODE = T2.AC_CODE   
     JOIN BUYER_ORDER_DET T3 ON T3.ORDER_ID = T1.ORDER_ID      
     JOIN ARTICLE ON ARTICLE.ARTICLE_CODE = T3.ARTICLE_CODE      
     JOIN SECTIOND ON SECTIOND.SUB_SECTION_CODE= ARTICLE.SUB_SECTION_CODE      
     JOIN SECTIONM ON SECTIOND.SECTION_CODE = SECTIONM.SECTION_CODE      
     JOIN PARA1 ON PARA1.PARA1_CODE = T3.PARA1_CODE       
     LEFT OUTER JOIN COMPANY COM ON 1=1 AND COM.COMPANY_CODE='01'   
	 LEFT OUTER JOIN EMPLOYEE EMP ON T1.EMP_CODE = EMP.EMP_CODE   
	 LEFT OUTER JOIN EMPLOYEE EMP1 ON T1.SALE_EMP_CODE = EMP1.EMP_CODE 
	 JOIN location L ON CASE WHEN T1.WBO_FOR_DEPT_ID<>'' THEN T1.WBO_FOR_DEPT_ID ELSE T1.DEPT_ID END =L.dept_id
	 LEFT JOIN AREA LAR(NOLOCK) ON LAR.AREA_CODE=L.AREA_CODE
	 LEFT JOIN CITY LCT (NOLOCK) ON LCT.CITY_CODE=LAR.CITY_CODE
	 LEFT OUTER JOIN ANGM AN ON T1.angadia_code=AN.Angadia_code
	 left join #TMPIMG i on i.row_id =t3.row_id      
     WHERE T1.ORDER_ID=@CWHERE
	 group by T1.ORDER_DT,T1.ORDER_NO,T2.AC_NAME,T1.TOTAL_AMOUNT, 
     T1.OTHER_CHARGES ,T1.DISCOUNT_AMOUNT ,      
     T1.SUBTOTAL,PARA1.PARA1_NAME,
     T1.PAYMENT_DETAILS,SECTIOND.SUB_SECTION_NAME,SECTIONM.SECTION_NAME,ARTICLE.ARTICLE_NO,  
     COM.COMPANY_CODE ,COM.LOGO_PATH,
	 COM.COMPANY_NAME  ,
     L.ADDRESS1,
     L.ADDRESS2,
     LCT.CITY ,
     L.PHONE 
     ,T1.TRAIL_DT,T1.DELIVERY_DT  ,T2.ADDRESS0,T2.ADDRESS1,T2.ADDRESS2,T2.AREA_NAME,T2.CITY,T2.STATE,T2.PINCODE,
	 ARTICLE.DT_CREATED, EMP.EMP_NAME ,T1.REF_NO,ARTICLE.MRP,ARTICLE.WHOLESALE_PRICE,ARTICLE.PURCHASE_PRICE,
	 ARTICLE.ALIAS,ARTICLE.ARTICLE_NAME,T2.TIN_NO,T1.REMARKS ,
	 i.PROD_IMAGE ,
	 i.PROD_IMAGE1,
	 i.PROD_IMAGE2,
	 PROD_IMAGE3,
	 T1.CHECKED_BY,
	 T1.SENT_BY,
	 T1.booked_by ,
	 L.dept_name ,
	 T1.shipping_Address,
	 T1.shipping_address2,
	 T1.shipping_address3,
	 T1.shipping_area_code,
	 T1.shipping_area_name,
	 T1.shipping_city_name,
	 T1.shipping_pin,
	 T1.shipping_state_name,
     AN.Angadia_name ,
     T1.pay_type,
     EMP1.emp_name ,
     EMP.emp_name  ,T3.ws_price ,PARA1.para1_code ,L.loc_gst_no ,T2.Ac_gst_no 


	 DECLARE @DTSQL NVARCHAR(MAX)
	                        
	   IF OBJECT_ID('TEMPDB..#TMPSIZESET','U') IS NOT NULL                      
		DROP TABLE  #TMPSIZESET                      
                          
	 SELECT  P2.PARA2_SET ,ISNULL(PRINTCOLUMNNO,0) AS PRINTCOLUMNNO,                       
	 P2.PARA2_NAME,P2.PARA2_CODE,                      
	 CAST(SUM(QUANTITY) AS VARCHAR(100)) AS PARA2_QTY,                      
	 ROW_NUMBER()  OVER (ORDER BY   P2.PARA2_NAME) AS SNO                         
	 INTO #TMPSIZESET                      
	 FROM BUYER_ORDER_DET A                                          
	 JOIN PARA2 P2 ON P2.PARA2_CODE =a.PARA2_CODE                       
	 WHERE order_id =@CWHERE                      
	 GROUP BY P2.PARA2_SET ,ISNULL(PRINTCOLUMNNO,0),                      
	 P2.PARA2_NAME ,P2.PARA2_CODE  
	                
	 IF OBJECT_ID('TEMPDB..#TMPALLSIZE','U') IS NOT NULL                      
		DROP TABLE  #TMPALLSIZE                      
                       
	  SELECT  A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) AS PRINTCOLUMNNO, A.PARA2_NAME , a.para2_code  ,       
	  SNO =ROW_NUMBER () OVER (ORDER BY A.PARA2_SET,ISNULL(A.PRINTCOLUMNNO,0),A.PARA2_NAME)                
	  INTO #TMPALLSIZE                      
	  FROM PARA2 A                      
	  JOIN #TMPSIZESET B ON A.PARA2_SET =B.PARA2_SET      
	  AND A.para2_code =B.para2_code   --CHANGES                 
	  GROUP BY A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) , A.PARA2_NAME  , a.para2_code   
	  
	--  SELECT * FROM #TMPALLSIZE                   
                      
	   DECLARE @CUPDATECOLNAME VARCHAR(10),@NSRNO INT                      
                       
	   SET @NSRNO=1                      
	   WHILE @NSRNO <=36                      
	   BEGIN                      
		 SET @DTSQL=' ALTER TABLE #TMPDETAILS ADD HEADER'+RTRIM(LTRIM(STR(@NSRNO)))+' VARCHAR(100) '                      
		 PRINT @DTSQL                      
		 EXEC(@DTSQL)                       
                           
		 SET @DTSQL=' IF EXISTS(SELECT TOP 1 ''U'' FROM #TMPALLSIZE WHERE SNO='+RTRIM(LTRIM(STR(@NSRNO)))+')                      
		 BEGIN                      
	     UPDATE #TMPDETAILS SET HEADER'+RTRIM(LTRIM(STR(@NSRNO)))+                      
	   ' =(SELECT TOP 1  PARA2_NAME FROM #TMPALLSIZE WHERE SNO='+RTRIM(LTRIM(STR(@NSRNO)))+')                      
	   END '                      
		 PRINT @DTSQL                      
		 EXEC(@DTSQL)                       
		 SET @NSRNO=@NSRNO+1                      
	   END                       
	                 
	 DECLARE @CALLPARA2_NAME VARCHAR(MAX)                       
                      
	 SELECT  @CALLPARA2_NAME=ISNULL(@CALLPARA2_NAME+'','')+                      
	 CASE WHEN LEN(A.PARA2_NAME) =1 THEN ' '                      
		  WHEN LEN(A.PARA2_NAME) =2 THEN ' '                      
		   ELSE ' ' END+                 
	  LEFT((A.PARA2_NAME ),3)        
	 FROM                      
	 (                      
	  SELECT  A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) AS PRINTCOLUMNNO, A.PARA2_NAME                       
	  FROM PARA2 A                    
	  JOIN #TMPSIZESET B ON A.PARA2_SET =B.PARA2_SET 
	  AND A.para2_code =B.para2_code   --CHANGES                    
	  GROUP BY A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) , A.PARA2_NAME                       
                      
	 ) A                      
                          
 
IF OBJECT_ID('TEMPDB..#TMPPARTICULAR','U') IS NOT NULL                      
    DROP TABLE  #TMPPARTICULAR                      
                         
   SELECT A.SR_NO, A.ARTICLE_NO  ,A.PARA1_CODE,                      
	   CAST('' AS VARCHAR(1000)) AS PARA2_NAME,                      
	   CAST('' AS VARCHAR(1000)) AS PARA2_CODE,                      
	   CAST('' AS NUMERIC(10,0)) AS PARA2_QTY,                      
	   CAST(0 AS INT ) AS SNO,                      
	   CAST(0 AS INT ) AS PRINTCOLUMNNO ,
	   CAST('' AS NUMERIC(14,2)) WS_PRICE
   INTO #TMPPARTICULAR                      
   FROM #TMPDETAILS A                      
   WHERE 1=2                      
                    
  SET @DTSQL=' SELECT  ARTICLE_NO,A.PARA1_CODE             
     ,A.PARA2_CODE               
     ,PARA2_NAME                      
     ,sum(QUANTITY) AS PARA2_QTY                      
     ,0 AS SNO                       
     ,cast(0 as int)   AS PRINTCOLUMNNO  ,
	 WS_PRICE
     FROM BUYER_ORDER_DET A
	 JOIN ARTICLE ON ARTICLE.ARTICLE_CODE = A.ARTICLE_CODE 
	 JOIN PARA1 ON PARA1.PARA1_CODE = A.PARA1_CODE 
	 JOIN PARA2 ON PARA2.PARA2_CODE = A.PARA2_CODE
	 WHERE order_id ='''+@CWHERE+''' 
	 group by ARTICLE_NO,A.PARA1_CODE             
     ,A.PARA2_CODE               
     ,PARA2_NAME,ISNULL(PRINTCOLUMNNO,0),WS_PRICE'         
	 
	 
	          
                           
   INSERT INTO #TMPPARTICULAR(ARTICLE_NO,PARA1_CODE,PARA2_CODE,PARA2_NAME,PARA2_QTY,SNO,PRINTCOLUMNNO, WS_PRICE)      
   EXEC(@DTSQL)  
   print @DTSQL +'test'  
   
 
   
   update a set PRINTCOLUMNNO =b.SNO from #TMPPARTICULAR  a
   join #TMPALLSIZE b on a.PARA2_CODE =b.para2_code             
                

					  --ROW_NUMBER () OVER (ORDER BY PARA2.PARA2_SET,ISNULL(PARA2.PRINTCOLUMNNO,0),PARA2.PARA2_NAME) 
                         
  DECLARE @CARTICLENO varchar(40),@CPARA1_CODE varchar(10),@nWS_PRICE numeric(10,2),
  @NPARA2_QTY numeric(10,3),@PRINTCOLUMNNO int,@CPARA2_CODE VARCHAR(10)

 
                      
  WHILE EXISTS (SELECT TOP 1 'U' FROM  #TMPPARTICULAR)                      
   BEGIN                      
                           
  SELECT TOP 1 @CARTICLENO=article_no ,@CPARA1_CODE=para1_code ,@nWS_PRICE=ws_price ,                            
  @PRINTCOLUMNNO=PRINTCOLUMNNO,@NPARA2_QTY=PARA2_QTY ,@CPARA2_CODE=PARA2_CODE      
  FROM #TMPPARTICULAR  
  order by PRINTCOLUMNNO 

 -- select count(*) from #TMPPARTICULAR
 --    if @PRINTCOLUMNNO>12
	-- begin
 --        SET @DTSQL=' ALTER TABLE #TMPDETAILS ADD SIZE'+RTRIM(LTRIM(STR(@PRINTCOLUMNNO)))+' VARCHAR(100) '                      
	--	 PRINT @DTSQL                      
	--	 EXEC(@DTSQL)    
	--end

	--IF NOT EXISTS (SELECT TOP 1 * FROM tempdb.INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='SIZE'+RTRIM(LTRIM(STR(@PRINTCOLUMNNO)))
	--						  AND TABLE_NAME LIKE '%#TMPDETAILS%')	and @PRINTCOLUMNNO>12	
	--begin
	--				  SET @DTSQL=' ALTER TABLE #TMPDETAILS ADD SIZE'+RTRIM(LTRIM(STR(@PRINTCOLUMNNO)))+' VARCHAR(100) '                      
	--	 PRINT @DTSQL                      
	--	 EXEC(@DTSQL)   
	--end
           
        IF @PRINTCOLUMNNO between 1 and 36                    
        BEGIN         
		             
                                  
			SET @DTSQL=' UPDATE #TMPDETAILS SET SIZE'+RTRIM(LTRIM(STR(@PRINTCOLUMNNO)))+'                      
			= '+RTRIM(LTRIM(STR(@NPARA2_QTY)))+'                      
			WHERE                       
			article_no='''+@CARTICLENO+'''             
			AND para1_code='''+@CPARA1_CODE+'''                                         
			AND ws_price='+RTRIM(LTRIM(STR(@nWS_PRICE,14,2)))+'                      
			'                      
			PRINT @DTSQL  +'Test Dinkar'                    
			EXEC(@DTSQL)   
		
                           
        END           
		
		
                              
    DELETE FROM #TMPPARTICULAR                      
    WHERE ARTICLE_NO=@CARTICLENO                      
    AND PARA1_CODE=@CPARA1_CODE                      
    AND WS_PRICE=@NWS_PRICE     
	AND PARA2_CODE =@CPARA2_CODE
 
   END                      
                        
   --DATASET 2                    
   SELECT   A.*,       
       @CALLPARA2_NAME AS ALLPARA2_NAME
	   --SR_NO,article_no ,para1_name  ,  
    --    SIZE1,SIZE2 ,SIZE3,SIZE4,SIZE5,SIZE6,SIZE7,SIZE8,SIZE9,SIZE10,SIZE11,SIZE12,                     
    --    HEADER1,HEADER2,HEADER3,HEADER4,HEADER5,HEADER6,HEADER7,HEADER8,HEADER9,HEADER10,                      
    --    HEADER11,HEADER12,HEADER13,HEADER14,HEADER15,HEADER16,HEADER17,HEADER18,HEADER19,HEADER20,                      
    --    HEADER21,HEADER22,HEADER23,HEADER24,HEADER25,HEADER26,HEADER27,HEADER28,HEADER29,HEADER30,                      
    --    HEADER31,HEADER32 ,A.*             
       
   FROM #TMPDETAILS A      
   ORDER BY a.SR_NO,a.article_no,a.para1_name                         
                        


END
