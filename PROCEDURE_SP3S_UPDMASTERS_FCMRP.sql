CREATE PROCEDURE SP3S_UPDMASTERS_FCMRP
(      
 @CTABLENAME VARCHAR(500),
 @CERRORMSG VARCHAR(MAX) OUTPUT    
)      
AS      
BEGIN      
       
    
     DECLARE @CCOLUMN_NAME VARCHAR(100),@CMSTTABLENAME VARCHAR(100),@CCOLUMN_CODE VARCHAR(100),
     @DTSQL NVARCHAR(MAX),@UPDATEVALUE NUMERIC(10,0),@UPDATEVALUE1 NUMERIC(10,0),@UPDATEVALUE2 NUMERIC(10,0),
     @BLOOP INT,@CLOCID VARCHAR(5),@cStep VARCHAR(4),@cFcTableName VARCHAR(200)
   
   SET @cFcTableName=REPLACE(@CTABLENAME,'IMPORT','IMPORT_FC')
   
   IF OBJECT_ID(@cFcTableName,'u') IS NOT NULL
   BEGIN
		SET @DTSQL=N'DROP TABLE '+@cFcTableName
		EXEC SP_EXECUTESQL @dTsQL
   END
   
   SET @cStep='10' 
    SELECT TOP 1 @CLOCID=value  FROM CONFIG WHERE config_option='LOCATION_ID'
        
    DECLARE @NSTEP NUMERIC(10,0)
   INSERT IMPORT_INFO VALUES (0,GETDATE())  
     
   SET @cStep='20'
   PRINT 'IMPORT MASTERS-START0'  
   BEGIN TRY    
   
	   IF OBJECT_ID('tempdb..#tmpfc','U') IS NOT NULL
			DROP TABLE #tmpFc
	   
	   SELECT product_code,convert(varchar(100),'') as fc_colname,mrp as fc_mrp INTO #tmpFc
	   FROM sku (NOLOCK) WHERE 1=2

	   IF OBJECT_ID('tempdb..#tmpfcCols','U') IS NOT NULL
			DROP TABLE #tmpfcCols
	   
	   SET @cStep='30'
	   SELECT convert(varchar(100),product_Code) as fc_colname,convert(numeric(2,0),0) as colorder INTO #tmpfcCols
	   FROM sku (NOLOCK) WHERE 1=2
	   
	   SET @cStep='40'      		 
	   --HANDLE NULL VALUE IN EXCEL IMPORT TABLE
		SET @DTSQL=''
		SELECT @DTSQL=N'INSERT #tmpfcCols
						SELECT  column_name,ROW_NUMBER() OVER (ORDER BY COLUMN_NAME) AS COLORDER
						FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME='''+@CTABLENAME+''' AND COLUMN_NAME LIKE ''FC%MRP'''
		SET @DTSQL=ISNULL(@DTSQL,'')
		IF @DTSQL<>'' EXEC(@DTSQL)
		--HANDLE NULL VALUE IN EXCEL IMPORT TABLE
	    
		SET @cStep='45' 
		 ; WITH  rCTE AS (
		SELECT CAST('['+fc_colname+']' AS NVARCHAR(MAX)) AS name, colOrder
		  FROM #tmpfcCols a
		  
		 WHERE colOrder=1
		UNION ALL
		SELECT r.name + ', ' + '['+a.fc_colname+']', a.colOrder
		  FROM rCTE r
			INNER JOIN #tmpfcCols a
			  ON r.colOrder + 1 = a.colOrder
		    
		)
		
		SELECT @dtSQL=N'SELECT product_code,'+name+' INTO '+@cFcTableName+' FROM '+@cTableName FROM rCTE
		EXEC SP_EXECUTESQL @dtSQL
		
		
		SET @cStep='50'
		--   article_fix_attr
		

		;WITH rCTE AS (
		SELECT CAST('['+fc_colname+']' AS NVARCHAR(MAX)) AS name, colOrder
		FROM #tmpfcCols a
		WHERE colOrder=1
		UNION ALL
		SELECT r.name + ', ' + '['+a.fc_colname+']', a.colOrder
		FROM rCTE r
		INNER JOIN #tmpfcCols a	ON r.colOrder + 1 = a.colOrder
		    
		)
		
		SELECT @dtSQL =N'SELECT *
		   FROM '+@cFcTableName+'
			  UNPIVOT (
					   fc_mrp FOR fc_name IN ('+name+')
					  ) p'
		FROM rCTE r
		WHERE colOrder = (SELECT MAX(colOrder) FROM rCTE)

		print @dtSQL
		SET @cStep='60'    		 
		INSERT #tmpFc (product_code,fc_mrp,fc_colname)
		EXEC sp_executeSQL @dtSQL
		
		SET @cStep='70' 
		UPDATE a SET fc_rate=c.fc_mrp FROM sku_fc_prices a 
		JOIN fc b ON a.fc_code=b.fc_code
		JOIN  #tmpFc c ON c.product_code=a.product_code AND c.fc_colname='fc_'+b.fc_code+'_mrp'
		
		SET @cStep='80' 
		INSERT sku_fc_prices	( product_code, fc_code, fc_rate )  
		SELECT a.product_code, b.fc_code, a.fc_mrp FROM #tmpFc a
		JOIN fc b ON 'fc_'+b.fc_code+'_mrp'=a.fc_colname
		LEFT OUTER JOIN sku_fc_prices c ON a.product_code=c.product_code  AND b.fc_code=c.fc_code
		WHERE c.product_code IS NULL
	
  END TRY    
     
 BEGIN CATCH    
  SET @CERRORMSG = 'ERROR IN UPDATING MASTERS (SP3S_UPDMASTERS_FCMRP) AT STEP- ' + @cStep + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()    
 END CATCH      
END