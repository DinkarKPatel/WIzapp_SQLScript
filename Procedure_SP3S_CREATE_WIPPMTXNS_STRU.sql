
CREATE PROCEDURE SP3S_CREATE_WIPPMTXNS_STRU  
@cDbName VARCHAR(400)='',  
@dXnDt DATETIME,  
@bInsPmt BIT=0,  
@bCrtIndex BIT=0,  
@bDonotChkDb BIT=0  
AS  
BEGIN  
 DECLARE @cPmtDbName VARCHAR(100),@cCmd NVARCHAR(MAX),@CFILEPATH VARCHAR(500),@cPmtTableNameXnDt VARCHAR(200),  
 @cPrevPmtTableNameXnDt VARCHAR(200),@cPmtTableXnDt VARCHAR(100),@cRecoveryModel SQL_VARIANT  
  
   
 IF @cDbName=''  
  SET @cDbName=db_name()  
 ELSE  
  SET @cDbName=REPLACE(@cDbName,'.dbo.','')  
  
 SET @cPmtDbName=@cDbName+'_PMT'  
  
  
  
 SELECT @CFILEPATH=PHYSICAL_NAME FROM SYS.MASTER_FILES WHERE DATABASE_ID=DB_ID(@cDbName) AND TYPE_DESC='ROWS'  
 SET @CFILEPATH=REVERSE(RIGHT(REVERSE(@CFILEPATH),(LEN(@CFILEPATH)-CHARINDEX('\',REVERSE(@CFILEPATH),1))+1))  
  
    
   SET @cPmtTableNameXnDt=@cDbName+'_pmt..WIPPMT_'+CONVERT(VARCHAR,@dXnDt,112)  
  
 IF OBJECT_ID(@cPmtTableNameXnDt,'U') IS NULL  
 BEGIN  
  SET @CCMD=N'SELECT product_code,bin_id,dept_id,quantity_in_stock as cbs_qty,CONVERT(NUMERIC(30,2),0) AS BOM_VALUE,  
                     CONVERT(NUMERIC(30,2),0) AS FG_VALUE  
                      
  INTO '+@cPmtTableNameXnDt+' FROM '+@cDbName+'.dbo.pmt01106 WHERE 1=2'    
  PRINT @cCmd  
  EXEC SP_EXECUTESQL @cCmd  
          
  SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_WIPPMT'+CONVERT(VARCHAR,@dXnDt,112)+  
  ' ON '+@cPmtTableNameXnDt+' ([dept_id])  
  INCLUDE ([product_code],[bin_id],[cbs_qty])'  
  print @cCmd  
   EXEC SP_EXECUTESQL @cCmd  
 END  
 ELSE  
 IF @bCrtIndex=1  
 BEGIN  
  DECLARE @cIndexName VARCHAR(200)  
  
  DECLARE @tIndList TABLE (ind_name VARCHAR(200))  
  
  SET @cCmd=N' use '+@cDbName+'_pmt ; SELECT  distinct I.[name] AS [index_name]  
     FROM sys.[tables] AS T    
       INNER JOIN sys.[indexes] I ON T.[object_id] = I.[object_id]    
       INNER JOIN sys.[index_columns] IC ON I.[object_id] = IC.[object_id]   
       INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id]   
     WHERE T.[is_ms_shipped] = 0 and I.[type_desc] <> ''HEAP'' and t.name='''+@cPmtTableXnDt+''''  
  
  PRINT @cCmd  
  
  INSERT @tIndList (ind_name)  
  EXEC SP_EXECUTESQL @cCmd  
  
  WHILE EXISTS (SELECT TOP 1 * FROM @tIndList)  
  BEGIN  
   SELECT TOP 1 @cIndexName=ind_name FROM @tIndList  
   SET @cCmd=N' use '+@cDbName+'_pmt ; DROP INDEX '+@cPmtTableXnDt+'.'+@cIndexName  
  
   PRINT @cCMD  
  
   EXEC SP_EXECUTESQL @cCmd  
  
   DELETE FROM @tIndList WHERE ind_name=@cIndexName  
  END  
  
  SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_WIPPMT'+CONVERT(VARCHAR,@dXnDt,112)+  
  ' ON '+@cPmtTableNameXnDt+' ([dept_id])  
  INCLUDE ([product_code],[bin_id],[cbs_qty])'  
  print @cCmd  
  EXEC SP_EXECUTESQL @cCmd  
 END  
  
 IF @bInsPmt=1  
 BEGIN  
  SET @cPrevPmtTableNameXnDt=@cDbName+'_pmt..WIPPMT_'+CONVERT(VARCHAR,@dXnDt-1,112)  
  
  SET @cCmd=N'TRUNCATE TABLE '+@cPmtTableNameXnDt  
  PRINT @cCmd  
  EXEC SP_EXECUTESQL @cCmd  
  
  SET @cCmd=N'INSERT '+@cPmtTableNameXnDt+'(product_code,bin_id,dept_id,cbs_qty)  
     SELECT product_code,bin_id,dept_id,cbs_qty FROM '+@cPrevPmtTableNameXnDt  
  PRINT @cCmd  
  EXEC SP_EXECUTESQL @cCmd  
 END  


 
END  
