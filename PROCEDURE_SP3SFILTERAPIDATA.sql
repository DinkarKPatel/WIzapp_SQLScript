CREATE PROCEDURE SP3SFILTERAPIDATA        
(        
@FROMDT VARCHAR(40),        
@TODT VARCHAR(40),        
@CFILTER VARCHAR(MAX),             
@CCOLUMN VARCHAR(MAX)='',      --- SELECT COLUMNS        
@AGEING  INT =1, -- 1 FOR PUR & 2 FOR SALE        
@CAGE1 VARCHAR(10),        
@CAGE2 VARCHAR(10),        
@CAGE3 VARCHAR(10),
@NSLSSTK INT=1          -------- 1 FOR SALE & 2 FOR STOCK & 3 FOR ALL                      
)        
AS        
BEGIN        
        
	   DECLARE @CCMD NVARCHAR(MAX),@CCMD2 NVARCHAR(MAX),@DATABASENAME VARCHAR(50),        
	   @AGETBL VARCHAR(50),@CCMD1 NVARCHAR(MAX),@COL1 VARCHAR(50),@COL2  VARCHAR(50),        
	   @PICT_SOURCE VARCHAR(10),@CFILTERCONDITION VARCHAR(50),@CSLSSTKFILTER VARCHAR(5000) ,
	   @CHSLSSTKFILTER VARCHAR(1000),@CFILTERWHERE VARCHAR(500)       
	   DECLARE @AGEINGTABLE TABLE (PRODUCT_CODE VARCHAR(50),AGEING_ORDER VARCHAR(10),AGEING_1 VARCHAR(10))        
        
                   
            IF OBJECT_ID('AGEINGSKU','U') IS NOT NULL        
            DROP TABLE AGEINGSKU        
     
            SELECT @PICT_SOURCE=VALUE FROM CONFIG WHERE CONFIG_OPTION ='PICT_SOURCE'        
                    
            SET @CFILTER=(CASE WHEN @CFILTER='' THEN '1=1' ELSE @CFILTER END)        
        
            SET @DATABASENAME=DB_NAME()+'_RFOPT.DBO.RF_OPT'   
     
   --SET @PICT_SOURCE=3
   
        
     
	  IF @CFILTER=''  
	  SET @CFILTER='1=1 '   
	           
	  SET @AGETBL=''        
	  IF @AGEING=1        
	  SET @AGETBL='SKU'        
	  ELSE        
	  SET @AGETBL='SKU_XFP'        
	          
	  IF @PICT_SOURCE =1       
	  BEGIN      
	  SET @COL1='ARTICLE.DT_CREATED'        
		 SET @COL2='ARTICLE.ARTICLE_NO'      
	  END        
	             
	   IF @PICT_SOURCE =2      
	   BEGIN      
	   SET @COL1='PARA3.DT_CREATED'        
		 SET @COL2='PARA3.PARA3_NAME'       
	   END        
	            
	  IF @PICT_SOURCE =3       
	  BEGIN      
	  SET @COL1='SKU.DT_CREATED'        
		 SET @COL2='SKU.PRODUCT_CODE'       
	  END        
            
     
     IF @NSLSSTK=1
		 BEGIN
			 SET @CSLSSTKFILTER='CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN XN_QTY         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -(XN_QTY)         
				 ELSE 0.00 END)),0)AS NUMERIC(14,2)) AS  SQTY ,''NA'' AS CBS, ''NA'' AS NSQP '
			 
			  SET @CHSLSSTKFILTER='CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN XN_QTY         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -(XN_QTY)         
				 ELSE 0.00 END)),0)AS NUMERIC(14,2))  > 0'
				 
			 SET @CFILTERWHERE=' SKU.ER_FLAG IN (''0'' , ''1'' ) 
                                  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' AND    '+ @CFILTER +'  '	 	 
				 
				  
		 END    
         
     IF @NSLSSTK=2
		 BEGIN
			 SET @CSLSSTKFILTER=' CAST(ISNULL(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''API'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',        
				 ''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') AND XN_DT <= '''+ @TODT +'''         
				 AND ARTICLE.STOCK_NA=0 ) THEN 1 WHEN A.XN_TYPE IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',        
				 ''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') AND XN_DT <= '''+ @TODT +'''         
				 AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * (XN_QTY)),0) AS NUMERIC(14,2)) AS CBS ,
				 
				 CAST(CASE WHEN ( CAST(ISNULL(SUM((CASE WHEN XN_TYPE IN (''SCF'',''PRD'',''OPS'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'',        
				 ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'')AND XN_DT <= '''+ @TODT +'''  THEN 1         
				 WHEN XN_TYPE IN (''SCC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'')        
				 AND XN_DT <= '''+ @TODT +''' THEN -1 ELSE 0.00 END) * (XN_QTY)),0)AS NUMERIC(14,2))  + CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
				 ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2))) <> 0 THEN CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
				 ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2)) / ( CAST(ISNULL(SUM((CASE WHEN XN_TYPE IN (''SCF'',''PRD'',''OPS'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'',        
				 ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'')AND XN_DT <= '''+ @TODT +'''  THEN 1         
				 WHEN XN_TYPE IN (''SCC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'')        
				 AND XN_DT <= '''+ @TODT +''' THEN -1 ELSE 0.00 END) * (XN_QTY)),0)AS NUMERIC(14,2))  +  CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
				 ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2)))        
				 * 100 ELSE 0 END AS NUMERIC(14,2)) AS NSQP '
				 
		    SET @CHSLSSTKFILTER='CAST(ISNULL(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''API'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',        
				 ''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') AND XN_DT <= '''+ @TODT +'''         
				 AND ARTICLE.STOCK_NA=0 ) THEN 1 WHEN A.XN_TYPE IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',        
				 ''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') AND XN_DT <= '''+ @TODT +'''         
				 AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * (XN_QTY)),0) AS NUMERIC(14,2)) > 0 '
				 
			 SET @CFILTERWHERE=' SKU.ER_FLAG IN (''0'' , ''1'' ) AND    '+ @CFILTER +'
                                    '
		    		 
		 END    
         
      IF @NSLSSTK=3
      BEGIN
      SET @CSLSSTKFILTER='CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN XN_QTY         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -(XN_QTY)         
				 ELSE 0.00 END)),0)AS NUMERIC(14,2)) AS  SQTY ,
		        
				 CAST(ISNULL(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''API'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',        
				 ''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') AND XN_DT <= '''+ @TODT +'''         
				 AND ARTICLE.STOCK_NA=0 ) THEN 1 WHEN A.XN_TYPE IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',        
				 ''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') AND XN_DT <= '''+ @TODT +'''         
				 AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * (XN_QTY)),0) AS NUMERIC(14,2)) AS CBS,
		         
				 CAST(CASE WHEN ( CAST(ISNULL(SUM((CASE WHEN XN_TYPE IN (''SCF'',''PRD'',''OPS'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'',        
						 ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'')AND XN_DT <= '''+ @TODT +'''  THEN 1         
				 WHEN XN_TYPE IN (''SCC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'')        
				 AND XN_DT <= '''+ @TODT +''' THEN -1 ELSE 0.00 END) * (XN_QTY)),0)AS NUMERIC(14,2))  + CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
				 ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2))) <> 0 THEN CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
				 ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2)) / ( CAST(ISNULL(SUM((CASE WHEN XN_TYPE IN (''SCF'',''PRD'',''OPS'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'',        
				 ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'')AND XN_DT <= '''+ @TODT +'''  THEN 1         
				 WHEN XN_TYPE IN (''SCC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'')        
				 AND XN_DT <= '''+ @TODT +''' THEN -1 ELSE 0.00 END) * (XN_QTY)),0)AS NUMERIC(14,2))  +  CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
				 WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
				 ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2)))        
				 * 100 ELSE 0 END AS NUMERIC(14,2)) AS NSQP'
         
      SET @CHSLSSTKFILTER='CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN XN_QTY         
         WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -(XN_QTY)         
         ELSE 0.00 END)),0)AS NUMERIC(14,2)) > 0 
         AND 
         CAST(ISNULL(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''API'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',        
         ''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') AND XN_DT <= '''+ @TODT +'''         
         AND ARTICLE.STOCK_NA=0 ) THEN 1 WHEN A.XN_TYPE IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',        
         ''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') AND XN_DT <= '''+ @TODT +'''         
         AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * (XN_QTY)),0) AS NUMERIC(14,2))> 0'
         
         
         SET @CFILTERWHERE=' SKU.ER_FLAG IN (''0'' , ''1'' ) AND    '+ @CFILTER +' 
                                    '   
        
      END 

        
   SET @CCMD=N' SELECT '+@CCOLUMN+',('+ @COL1 +'  + ''/'' + '+ @COL2 +' + ''.'' + ''JPG'' )AS IMAGE,'+@CSLSSTKFILTER+''        
   -- PRINT @CCMD        
                   
    SET @CCMD2=N' FROM '+@DATABASENAME+' A (NOLOCK)          
         JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE         
         JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE = ARTICLE.ARTICLE_CODE         
         JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE        
         JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE = SECTIONM.SECTION_CODE         
         JOIN LM01106 (NOLOCK) ON LM01106.AC_CODE=SKU.AC_CODE        
         JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE=SKU.PARA1_CODE        
         JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE=SKU.PARA2_CODE        
         JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE=SKU.PARA3_CODE        
         JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE=SKU.PARA4_CODE        
         JOIN PARA5 (NOLOCK) ON PARA5.PARA5_CODE=SKU.PARA5_CODE        
         JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE=SKU.PARA6_CODE        
         --- JOIN '+@AGETBL+' T (NOLOCK) ON T.PRODUCT_CODE=SKU.PRODUCT_CODE        
         WHERE '+ @CFILTERWHERE+'    
         -- AND A.XN_TYPE IN(''SLS'',''SLR'')      
              
         GROUP BY '+ @COL1 +','+ @COL2 +','+@CCOLUMN+'        
         HAVING '+@CHSLSSTKFILTER+'
    
         --ORDER BY CAST(CASE WHEN ( CAST(ISNULL(SUM((CASE WHEN XN_TYPE IN (''SCF'',''PRD'',''OPS'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'',        
         --''BCG'',''MRP'',''DCI'',''PSB'',''JWR'')AND XN_DT <= '''+ @TODT +'''  THEN 1         
         --WHEN XN_TYPE IN (''SCC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'')        
         --AND XN_DT <= '''+ @TODT +''' THEN -1 ELSE 0.00 END) * (XN_QTY)),0)AS NUMERIC(14,2))  + CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
         --WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
         --ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2))) <> 0 THEN CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
         --WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
         --ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2)) / ( CAST(ISNULL(SUM((CASE WHEN XN_TYPE IN (''SCF'',''PRD'',''OPS'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'',        
         --''BCG'',''MRP'',''DCI'',''PSB'',''JWR'')AND XN_DT <= '''+ @TODT +'''  THEN 1         
         --WHEN XN_TYPE IN (''SCC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'')        
         --AND XN_DT <= '''+ @TODT +''' THEN -1 ELSE 0.00 END) * (XN_QTY)),0)AS NUMERIC(14,2))  +  CAST(ISNULL( SUM((CASE WHEN XN_TYPE IN (''SLS'')  AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN 1         
         --WHEN XN_TYPE IN(''SLR'') AND XN_DT BETWEEN '''+ @FROMDT +''' AND '''+ @TODT +''' THEN -1         
         --ELSE 0.00 END)*(XN_QTY)),0)AS NUMERIC(14,2)))        
         --* 100 ELSE 0 END AS NUMERIC(14,2)) DESC'
         
            
          
        
   -- PRINT @CCMD2        
    SET @CCMD=@CCMD+@CCMD2        
    --PRINT @CCMD        
    EXEC SP_EXECUTESQL @CCMD        
          
        
        
 --CASE WHEN ( SUM(NOBQP) + SUM(SQTY)) <> 0 THEN SUM(SQTY) / ( SUM(NOBQP) +  SUM(SQTY))        
 --       * 100 ELSE 0 END ) AS NSQP    
     
 END          
--********************************************** END OF PROCEDURE SP3SFILTERAPIDATA
