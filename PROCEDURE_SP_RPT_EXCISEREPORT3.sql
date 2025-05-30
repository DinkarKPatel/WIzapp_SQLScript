CREATE PROCEDURE SP_RPT_EXCISEREPORT3  --(LocId 3 digit change  by Sanjay:01-11-2024)
(    
@FROMDT DATETIME,          
@TODT  DATETIME,
@cLocId varchar(4)=''      
)     
AS    
BEGIN    
    
    
       DECLARE @CCMD NVARCHAR(MAX),@CFILTER NVARCHAR(MAX),@HO_LOC_ID VARCHAR(4)    
       ,@FROMDATE VARCHAR(MAX),@TODATE VARCHAR(MAX)    
           
       SET @CLOCID=''    
       SET @HO_LOC_ID=''    
       SET @FROMDATE=''    
       SET @TODATE=''    

	  IF @cLocId=''
		SELECT @CLOcID		= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 

       SELECT @HO_LOC_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'    
           
    
                            
  SET @FROMDATE=@FROMDT      
  SET @TODATE=@TODT      
       SET @CFILTER=''    
    --SELECT @CFILTER= DB_NAME()+'_RFOPT'+'.DBO.RF_OPT'    
    SET @CFILTER='VW_XNSREPS'    
        
        
   SET @CCMD=N'SELECT [SUB_SECTION_NAME],[ARTICLE_NO],MRP AS [CAL_MRP],    
  SUM(ISNULL(OBS , 0)) AS [CAL_OPENING_STOCK],    
  SUM(ISNULL(NPQ , 0)) AS [CAL_MFG_QTY],    
  ISNULL(SUM(OBS) + SUM(NPQ) ,0) AS [CAL_TOTAL_QTY],    
  ISNULL(SUM(NSQ) + SUM(NWQ) +SUM(CRQ),0) AS [CAL_SALE_QTY],    
  SUM(ISNULL(CBS , 0)) AS [CAL_CLOSING_STOCK],    
  --XN_NO,XN_DT,    
  (CASE WHEN SUM(ISNULL(NPQ , 0)) <> 0 THEN [INV_NO]     
        WHEN SUM(ISNULL(NSQ , 0)) <> 0 THEN [XN_NO]     
        WHEN SUM(ISNULL(NWQ , 0)) <> 0 THEN [XN_NO]     
        WHEN SUM(ISNULL(CRQ , 0)) <> 0 THEN [XN_NO] END)AS [BILL_NO_OR_MFG_NO],    
  (CASE WHEN SUM(ISNULL(NPQ , 0)) <> 0 THEN [INV_DT]     
        WHEN SUM(ISNULL(NSQ , 0)) <> 0 THEN [XN_DT]     
        WHEN SUM(ISNULL(NWQ , 0)) <> 0 THEN [XN_DT]     
        WHEN SUM(ISNULL(CRQ , 0)) <> 0 THEN [XN_DT] END)AS [BILL_DT_OR_MFG_DATE],    
  60 AS [CAL_MRP_PER],    
   ISNULL(SUM(NSG) + SUM(NWM) +SUM(CRM),0) AS  [CAL_SALE_VALUE_MRP],    
       
   (CASE WHEN SUM(ISNULL(NSQ , 0)) <> 0 THEN CAST(ROUND(ISNULL((SUM(NSG)*60)/100,0),0)AS NUMERIC(12,0))     
        WHEN SUM(ISNULL(NWQ , 0)) <> 0 THEN CAST(ROUND(ISNULL((SUM(NWM)*60)/100,0),0)AS NUMERIC(12,0))     
        WHEN SUM(ISNULL(CRQ , 0)) <> 0 THEN CAST(ROUND(ISNULL((SUM(CRM)*60)/100,0),0)AS NUMERIC(12,0)) ELSE 0 END)    
   AS [CAL_ASS_VALUE],    
       
  (CASE WHEN SUM(ISNULL(NSQ , 0)) <> 0 AND MRP > 999 AND SUB_SECTION_NAME <> ''UNSTITCH'' THEN ((ROUND(ISNULL((SUM(NSG)*60)/100,0),0))*2)/100       
        WHEN SUM(ISNULL(NWQ , 0)) <> 0 AND MRP > 999 AND SUB_SECTION_NAME <> ''UNSTITCH''  THEN ((ROUND(ISNULL((SUM(NWM)*60)/100,0),0))*2)/100      
        WHEN SUM(ISNULL(CRQ , 0)) <> 0 AND MRP > 999 AND SUB_SECTION_NAME <> ''UNSTITCH'' THEN ((ROUND(ISNULL((SUM(CRM)*60)/100,0),0))*2)/100 ELSE 0 END)   
        AS [CAL_EXCISE_SL]    
       
  FROM     
  (    
    SELECT SKU.[INV_DT],SKU.[INV_NO],XN_DT,XN_NO,SECTIOND.[SUB_SECTION_NAME],ARTICLE.[ARTICLE_NO],SKU.[MRP]    
      ,CAST(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''TTM'',''API'',''SCF'',''OPS'',''PRD'',  
       ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',  
       ''PSB'',''JWR'') AND XN_DT < '''+@FROMDATE+''' AND ARTICLE.STOCK_NA=0) THEN 1 WHEN A.XN_TYPE   
       IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'', ''CRM'',  
        ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') AND XN_DT < '''+@FROMDATE+'''  
         AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * ([XN_QTY])) AS NUMERIC(14,2)) AS OBS    
           
       ,CAST(SUM( CASE WHEN A.XN_TYPE=''PUR'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''    
       THEN XN_QTY  WHEN A.XN_TYPE=''PRT'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''     
       THEN - (ABS(XN_QTY)) ELSE 0 END) AS NUMERIC(14,3)) AS NPQ    
           
       ,CAST(SUM( CASE WHEN A.XN_TYPE=''SLS'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''     
       THEN XN_QTY  WHEN A.XN_TYPE=''SLR'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''     
       THEN - (ABS(XN_QTY)) ELSE 0 END) AS NUMERIC(14,3)) AS NSQ    
           
       ,CAST(SUM( CASE WHEN A.XN_TYPE=''SLS'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''     
       THEN (SKU.MRP * XN_QTY)  WHEN A.XN_TYPE=''SLR'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''  
        THEN -(ABS(SKU.MRP * XN_QTY)) ELSE 0 END) AS NUMERIC(14,3)) AS NSG    
          
       ,CAST(SUM( CASE WHEN A.XN_TYPE=''WSL'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''    
        THEN XN_QTY  WHEN A.XN_TYPE=''WSR'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''    
        THEN - (ABS(XN_QTY)) ELSE 0 END) AS NUMERIC(14,3)) AS NWQ    
           
        
           
       ,CAST(SUM( CASE WHEN A.XN_TYPE=''WSL'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' THEN ABS(SKU.MRP* A.XN_QTY)      
        WHEN A.XN_TYPE=''WSR'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+''' THEN -ABS(SKU.MRP* A.XN_QTY) ELSE 0 END) AS NUMERIC(14,3)) AS NWM    
           
       ,CAST(SUM( CASE WHEN A.XN_TYPE=''CHO'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''     
       THEN XN_QTY  ELSE 0 END) AS NUMERIC(14,3)) AS CRQ    
           
       ,CAST(SUM ( CASE WHEN A.XN_TYPE =''CHO'' AND XN_DT BETWEEN '''+@FROMDATE+''' AND '''+@TODATE+'''     
                       THEN (XN_QTY*SKU.MRP) ELSE 0 END) AS NUMERIC(14,3)) AS CRM    
           
           
      ,CAST(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''TTM'',''API'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') AND XN_DT <= '''+@TODATE+''' AND ARTICLE.STOCK_NA=0 ) THEN 1 WHEN A.XN_TYPE IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') AND XN_DT <= '''+@TODATE+''' AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * (XN_QTY))

  
 AS NUMERIC(14,2)) AS CBS    
                    
    FROM '+@CFILTER+' A  (NOLOCK)     
    JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE     
    JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE = ARTICLE.ARTICLE_CODE     
     JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE    
     JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE = SECTIONM.SECTION_CODE     
     JOIN LOC_VIEW  (NOLOCK) ON A.DEPT_ID = LOC_VIEW.DEPT_ID    
    WHERE (   ( LOC_VIEW.MAJOR_DEPT_ID IN ('''+@CLOCID+''' ))   )     
    AND ( LOC_VIEW.INACTIVE IN (0) AND LOC_VIEW.REPORT_BLOCKED IN (0))     
    AND  SKU.ER_FLAG IN (''0'' , ''1'' )   
   
     GROUP BY SKU.[INV_DT],SKU.[INV_NO],A.XN_DT,A.XN_NO,SECTIOND.[SUB_SECTION_NAME],  
     ARTICLE.[ARTICLE_NO],SKU.MRP    
    
    
   ) B     
    
    
    GROUP BY [INV_DT],[INV_NO],XN_DT,XN_NO,[SUB_SECTION_NAME],[ARTICLE_NO],[MRP]    
   HAVING NOT(SUM(ISNULL(OBS,0))= 0 AND SUM(ISNULL(NPQ,0))= 0     
   AND SUM(ISNULL(NSQ,0))= 0 AND SUM(ISNULL(NSG,0))= 0     
   AND SUM(ISNULL(NWQ,0))= 0 AND SUM(ISNULL(CRQ,0))= 0     
   AND SUM(ISNULL(CBS,0))= 0  AND SUM(ISNULL(CRM,0))= 0 AND SUM(ISNULL(NWM,0))= 0 )    
   ORDER BY [INV_DT],[INV_NO],XN_DT,XN_NO,[SUB_SECTION_NAME],[ARTICLE_NO],[MRP]'    
    
 PRINT @CCMD    
 EXEC SP_EXECUTESQL @CCMD             
       
          
END
