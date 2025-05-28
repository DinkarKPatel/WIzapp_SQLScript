CREATE PROCEDURE SP_ATTRIBUTE_DETAILS  
AS  
BEGIN  
   
       DECLARE @CCMD NVARCHAR(MAX),@CCMD1 NVARCHAR(MAX),@CPARA1 VARCHAR(50),@CPARA2 VARCHAR(50),@CPARA3 VARCHAR(50),@CPARA4 VARCHAR(50),@CPARA5 VARCHAR(50),@CPARA6 VARCHAR(50)  
       TRUNCATE TABLE ATTRIBUTE_DETAILS  
         
       SELECT @CPARA1=VALUE  FROM CONFIG WHERE CONFIG_OPTION='PARA1_CAPTION'
       SELECT @CPARA2=VALUE  FROM CONFIG WHERE CONFIG_OPTION='PARA2_CAPTION'
       SELECT @CPARA3=VALUE  FROM CONFIG WHERE CONFIG_OPTION='PARA3_CAPTION'
       SELECT @CPARA4=VALUE  FROM CONFIG WHERE CONFIG_OPTION='PARA4_CAPTION'
       SELECT @CPARA5=VALUE  FROM CONFIG WHERE CONFIG_OPTION='PARA5_CAPTION'
       SELECT @CPARA6=VALUE  FROM CONFIG WHERE CONFIG_OPTION='PARA6_CAPTION'
              
         
       SET @CCMD=N'INSERT INTO ATTRIBUTE_DETAILS(TABLENAME,COLNAME)  
                 SELECT ''ARTICLE'' AS TABLENAME,''ARTICLE_NO'' AS COLNAME  
                 UNION ALL  
                 ----SELECT ''SKU'' AS TABLENAME,''PURCHASE_DATE'' AS COLNAME  
                 ----UNION ALL  
                 ----SELECT ''SKU'' AS TABLENAME,''RECEIPT_DATE'' AS COLNAME  
                 ----UNION ALL  
                 SELECT ''SKU'' AS TABLENAME,''WS_PRICE'' AS COLNAME  
                 UNION ALL  
                 SELECT ''SKU'' AS TABLENAME,''PURCHASE_PRICE'' AS COLNAME  
                 UNION ALL  
                   SELECT DISTINCT TABLENAME,'''' AS COLNAME FROM XNSINFO WHERE    
                   TABLENAME NOT IN (''SD_ATTR'',''EAN_SYNC'',''ART_ATTR'',''ART_PARA1'',''ART_DET'',  
                   ''ARTICLE_MEASUREMENTS'',''UOM'',''MEASUREMENT_MST'',''ATTRM'',''ATTR_KEY'')  
                   AND  XN_TYPE=''MSTINV'' OR TABLENAME=''LM01106'''  
       PRINT @CCMD  
       EXEC SP_EXECUTESQL @CCMD  
         
       SET @CCMD=N'UPDATE ATTRIBUTE_DETAILS SET   
                    COLNAME=(CASE WHEN TABLENAME=''PARA1'' THEN ''PARA1_NAME''  
                                  WHEN TABLENAME=''PARA2''THEN ''PARA2_NAME''  
                                  WHEN TABLENAME=''PARA3''THEN ''PARA3_NAME''  
                                  WHEN TABLENAME=''PARA4''THEN ''PARA4_NAME''  
                                  WHEN TABLENAME=''PARA5''THEN ''PARA5_NAME''  
                                  WHEN TABLENAME=''PARA6''THEN ''PARA6_NAME''  
                                  WHEN TABLENAME=''ARTICLE'' AND COLNAME=''ARTICLE_NO''THEN ''ARTICLE_NO''  
                                  WHEN TABLENAME=''ARTICLE'' AND COLNAME=''''THEN ''ARTICLE_NAME''  
                                  WHEN TABLENAME=''SECTIONM''THEN ''SECTION_NAME''  
                                  WHEN TABLENAME=''SECTIOND''THEN ''SUB_SECTION_NAME''  
                                  WHEN TABLENAME=''LM01106''THEN ''AC_NAME''  
                                  WHEN TABLENAME=''SKU'' AND COLNAME<>''WS_PRICE'' AND COLNAME<>''PURCHASE_PRICE''   
                                  AND COLNAME<>''PURCHASE_DATE''AND COLNAME<>''RECEIPT_DATE'' THEN ''MRP''  
                                  WHEN TABLENAME=''SKU'' AND COLNAME=''WS_PRICE'' THEN ''WS_PRICE''  
                                  WHEN TABLENAME=''SKU'' AND COLNAME=''PURCHASE_PRICE'' THEN ''PURCHASE_PRICE''  
                                   ----WHEN TABLENAME=''SKU'' AND COLNAME=''PURCHASE_DATE'' THEN ''PURCHASE_DATE''  
                                   ---- WHEN TABLENAME=''SKU'' AND COLNAME=''RECEIPT_DATE'' THEN ''RECEIPT_DATE''  
                                  ELSE '''' END ),  
                  USERDISPLAY=(CASE WHEN TABLENAME=''PARA1'' THEN '''+@CPARA1+'''  
                                  WHEN TABLENAME=''PARA2''THEN '''+@CPARA2+'''  
                                  WHEN TABLENAME=''PARA3''THEN '''+@CPARA3+'''  
                                  WHEN TABLENAME=''PARA4''THEN '''+@CPARA4+'''  
                                  WHEN TABLENAME=''PARA5''THEN '''+@CPARA5+'''  
                                  WHEN TABLENAME=''PARA6''THEN '''+@CPARA6+'''  
                                  WHEN TABLENAME=''ARTICLE'' AND COLNAME=''ARTICLE_NO'' THEN ''ARTICLE NO''  
                                  WHEN TABLENAME=''SECTIONM''THEN ''SECTION NAME''  
                                  WHEN TABLENAME=''SECTIOND''THEN ''SUB SECTION NAME''  
                                  WHEN TABLENAME=''ARTICLE'' AND COLNAME<>''ARTICLE_NO'' THEN ''ARTICLE_NAME''  
                                  WHEN TABLENAME=''LM01106''THEN ''SUPPLIER NAME''  
                                   WHEN TABLENAME=''SKU'' AND COLNAME<>''WS_PRICE'' AND COLNAME<>''PURCHASE_PRICE''   
                                   AND COLNAME<>''PURCHASE_DATE''AND COLNAME<>''RECEIPT_DATE''THEN ''MRP''  
                               WHEN TABLENAME=''SKU'' AND COLNAME=''WS_PRICE'' THEN ''WHOLESALE PRICE''  
                                  WHEN TABLENAME=''SKU'' AND COLNAME=''PURCHASE_PRICE'' THEN ''PURCHASE PRICE''  
                                  ----WHEN TABLENAME=''SKU'' AND COLNAME=''PURCHASE_DATE'' THEN ''PURCHASE DATE''  
                                  ---- WHEN TABLENAME=''SKU'' AND COLNAME=''RECEIPT_DATE'' THEN ''RECEIPT DATE''   
                                    
                                  ELSE '''' END )'  
            PRINT @CCMD  
       EXEC SP_EXECUTESQL @CCMD                          
     SET @CCMD1=N'UPDATE ATTRIBUTE_DETAILS SET  DATA_TYPE=(CASE WHEN TABLENAME=''PARA1'' THEN ''VARCHAR''  
                                  WHEN TABLENAME=''PARA2''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''PARA3''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''PARA4''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''PARA5''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''PARA6''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''ARTICLE'' AND COLNAME=''ARTICLE_NO'' THEN ''VARCHAR''  
                                  WHEN TABLENAME=''SECTIONM''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''SECTIOND''THEN ''VARCHAR''  
                                  WHEN TABLENAME=''ARTICLE'' AND COLNAME<>''ARTICLE_NO'' THEN ''VARCHAR''  
                                  WHEN TABLENAME=''LM01106''THEN ''VARCHAR''  
                                   WHEN TABLENAME=''SKU'' AND COLNAME<>''WS_PRICE'' AND COLNAME<>''NUMERIC''   
                                   AND COLNAME<>''PURCHASE_DATE''AND COLNAME<>''RECEIPT_DATE''THEN ''NUMERIC''  
                                   WHEN TABLENAME=''SKU'' AND COLNAME=''WS_PRICE'' THEN ''NUMERIC''  
                                  WHEN TABLENAME=''SKU'' AND COLNAME=''PURCHASE_PRICE'' THEN ''NUMERIC''  
                                  ----WHEN TABLENAME=''SKU'' AND COLNAME=''PURCHASE_DATE'' THEN ''DATETIME''  
                                  ---- WHEN TABLENAME=''SKU'' AND COLNAME=''RECEIPT_DATE'' THEN ''DATETIME''   
                                  ELSE '''' END )'                   
                                    
       PRINT @CCMD1  
       EXEC SP_EXECUTESQL @CCMD1                             
       SELECT TABLENAME,COLNAME,USERDISPLAY,DATA_TYPE FROM ATTRIBUTE_DETAILS ORDER BY USERDISPLAY 
             
  
END
