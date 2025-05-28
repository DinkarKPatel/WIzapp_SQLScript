CREATE PROCEDURE SP3S_CREATE_SKUNAMES  --- Do not overwrite in May2022 Release Folder	
@nMode INT=0 --- 1 IF Called from Restart of Monitor
AS
BEGIN



START_PROCESS:	  
	  DECLARE @cDiffTable VARCHAR(100),@cCmd NVARCHAR(MAX),@cCurTime VARCHAR(50),@FROM DATETIME,@TO DATETIME,@MSG VARCHAR(200),
			  @nRowsCnt INT

	  SET @from=getdate()
	  

	  SET @cCurTime=CONVERT(VARCHAR,GETDATE(),113)

	 ;WITH CTE AS (SELECT master_CODE,R=ROW_NUMBER()OVER(PARTITION BY master_tablename,master_CODE ORDER BY master_CODE) FROM OPT_SKU_DIFF (NOLOCK)
				  )
			DELETE CTE WHERE R>1

			  
	  EXEC SP3S_CREATE_MISSING_SKUNAMES
	  @bRunOptimizedProcess=1
	  
	  IF @nMode=1
		GOTO END_PROC

	  IF NOT EXISTS (SELECT TOP 1 master_code FROM opt_sku_diff (NOLOCK))
	  BEGIN
			RAISERROR('Exiting! No Records found to insert/update',0,1) WITH NOWAIT
			GOTO END_PROC
	  END
     
	  IF EXISTS (SELECT TOP 1 master_code FROM opt_sku_diff (NOLOCK) WHERE master_tablename<>'sku')
		  EXEC SP3S_FETCH_BARCODES_SKUNAMESBUILD
		  @cCutoffTime=@cCurTime

  	  CREATE TABLE #tRows (rows_updated INT)

	  EXEC SP3S_UPD_SKUNAMES_INFO 
	  @bRunOptimizedProcess=1,
	  @cCutoffTime=@cCurTime

	  DELETE FROM opt_sku_diff WITH (ROWLOCK) WHERE last_update<=@cCurTime
	  DELETE FROM sku_diff WITH (ROWLOCK) WHERE sp_id=@@spid
	  
	  SELECT @nRowsCnt=rows_updated FROM #tRows  

	  SET @TO=GETDATE()
	  SET @MSG='Updated '+ltrim(rtrim(str(@nRowsCnt)))+' rows by Optimized Process Diff Data in '+CAST(DATEDIFF(SS,@FROM,@TO) AS VARCHAR)+' seconds'     
	  RAISERROR(@MSG,0,1) WITH NOWAIT
END_PROC:

	SET NOCOUNT OFF		 
END