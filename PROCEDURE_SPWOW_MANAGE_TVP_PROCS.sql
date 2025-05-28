CREATE PROCEDURE SPWOW_MANAGE_TVP_PROCS
@nMode INT=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cTvpName VARCHAR(100),@cTvpDefinition VARCHAR(MAX),@cStep VARCHAR(5),
			@cErrormsg VARCHAR(MAX),@cTvpProcName  VARCHAR(200)

BEGIN TRY
	SET @cStep='10'

	GOTO END_PROC -- Discarded this process for Now as tvp handling is not being done propery at Console level (Sanjay:11-01-2024)

	IF @nMode=2
		GOTO lblCreateTvp 

	SELECT NAME as tvpName into #tmpTableTypes from  sys.types where is_table_type=1

	SET @cStep='12'
	SELECT DISTINCT SO.name AS procName INTO #tmpTvpProcs FROM sys.objects AS SO (NOLOCK)
	INNER JOIN sys.parameters AS P  (NOLOCK) ON SO.OBJECT_ID = P.OBJECT_ID
	JOIN #tmpTableTypes t  (NOLOCK) on t.tvpName=TYPE_NAME(P.user_type_id)
	

	SET @cStep='14'
	DELETE b from #tmpTvpProcs a join monitor_script b ON 'PROCEDURE_'+a.procName+'.txt'=b.ROW_ID
	

	DELETE b from #tmpTableTypes a join monitor_script b ON 'type_'+a.tvpName+'.txt'=b.ROW_ID

	WHILE EXISTS (SELECT TOP 1 procname from #tmpTvpProcs)
	BEGIN
		SET @cStep='17'
		SELECT TOP 1 @cTvpProcName=procname from #tmpTvpProcs

		SET @cCmd=N'DROP PROCEDURE '+@cTvpProcName
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		DELETE FROM #tmpTvpProcs WHERE procName=@cTvpProcName
	END


	SET @cStep='20'
	WHILE EXISTS (SELECT TOP 1 * FROM  #tmpTableTypes)
	BEGIN
		SELECT TOP 1 @cTvpName=tvpname FROM #tmpTableTypes

		SET @cStep='25'
		SET @cCmd=N'DROP TYPE '+@cTvpName

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		DELETE FROM  #tmpTableTypes WHERE tvpName=@cTvpName
	END
	
	GOTO END_PROC

	
lblCreateTvp:
	SET @cStep='40'
	DECLARE @tTvpInfo TABLE (tvpName VARCHAR(100),baseTableName VARCHAR(200),consider_deleted_column BIT,wow_map_tablename VARCHAR(100))

	INSERT INTO @tTvpInfo (tvpName,baseTableName,consider_deleted_column)
	SELECT 'tvpWowRepDet','wow_xpert_rep_det',1
	UNION ALL
	SELECT 'tvpWowRepMst','wow_xpert_rep_mst',0
	UNION ALL
	SELECT 'tvpWowSdRepDet','wow_sdrep_xn_det',1
	UNION ALL
	SELECT 'tvpWowSdRepMst','wow_sdrep_xn_mst',0
	UNION ALL
	SELECT 'tvpWowRepMstLinkedFilter','WOW_Xpert_Rep_Mst_Linked_Filter',1
	UNION ALL
	SELECT 'tvpWowLocation','location',0
	UNION ALL
	SELECT 'tvpWowArea','area',0
	UNION ALL
	SELECT 'tvpWowCity','city',0
	UNION ALL
	SELECT 'tvpWowRegionm','Regionm',0
	UNION ALL
	SELECT 'tvpWowstate','state',0
	UNION ALL
	SELECT 'tvpWowLocUsers','locusers',1
	UNION ALL
	SELECT 'tvpWowLocBin','bin_loc',1
	UNION ALL
	SELECT 'tvpWowBin','bin',0
	UNION ALL
	SELECT 'tv_EditCols','',0
	UNION ALL
	SELECT 'tvpConfigLoc','config_loc',0
	UNION ALL
	SELECT 'tvpWowxnBoxDetails','xnBoxDetails',0
	UNION ALL
	SELECT 'tvpWowCmm','cmm01106',0
	UNION ALL
	SELECT 'tvpWowCmd','cmd01106',1

	
	INSERT INTO @tTvpInfo (tvpName,baseTableName,consider_deleted_column,wow_map_tablename)
	SELECT 'tvpWowGateEntryMst','parcel_mst',0,'Gateentrymst'
	UNION ALL
	SELECT 'tvpWowGateEntryDet','parcel_det',1,'Gateentrydet'
	UNION ALL
	SELECT 'tvpWowGrnPsMst','grn_ps_mst',0,'grn_ps_mst'
	UNION ALL
	SELECT 'tvpWowGrnPsDet','grn_ps_det',1,'grn_ps_det'
	UNION ALL
	SELECT 'tvpWowRackXfrMst','floor_st_mst',0,'floor_st_mst'
	UNION ALL
	SELECT 'tvpWowRackXfrDet','floor_st_det',1,'floor_st_det'
	UNION ALL
	SELECT 'tvpWowWpsMst','wps_mst',0,'wps_mst'
	UNION ALL
	SELECT 'tvpWowWpsDet','wps_det',1,'wps_det'
	UNION ALL
	SELECT 'tvpWowARC','arc01106',1,'arc01106'

	SET @cStep='50'

	---- Insert Tvp definition for all columns of table
	SELECT  DISTINCT 'CREATE TYPE ['+tvp.tvpName + '] AS TABLE  ( '+S.COLUMN_NAME+(CASE WHEN tvp.consider_deleted_column=1 THEN 
	',deleted BIT' ELSE '' END)+')' as tvp_definition,tvp.tvpName
	INTO #tvpDefinition FROM INFORMATION_SCHEMA.TABLES T    
	JOIN @tTvpInfo tvp ON tvp.baseTableName=t.TABLE_NAME
	CROSS APPLY    
		(    
		SELECT STUFF((    
	SELECT +',['+COLUMN_NAME + '] '+    
	CASE WHEN DATA_TYPE IN ('DECIMAL','NUMERIC') THEN DATA_TYPE +' ('+ CAST(NUMERIC_PRECISION AS VARCHAR)+','+CAST(NUMERIC_SCALE AS VARCHAR)+')'    
	WHEN DATA_TYPE IN ('VARCHAR','CHAR') THEN DATA_TYPE +' ('+ CASE CHARACTER_MAXIMUM_LENGTH WHEN '-1' THEN 'MAX' ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) END +')'
	WHEN DATA_TYPE IN ('NVARCHAR','NCHAR','VARBINARY') THEN DATA_TYPE +' ('+ CASE CHARACTER_maximum_LENGTH WHEN '-1' THEN 'MAX' ELSE CAST(CHARACTER_maximum_LENGTH AS VARCHAR) END +')'
	ELSE DATA_TYPE    
	END    
	    
	FROM INFORMATION_SCHEMA.COLUMNS C (NOLOCK)   
	LEFT JOIN dbo.INF_SCHEMA_IDENTITY_COLUMNS C2 (NOLOCK) ON C2.COLUMNNAME=C.COLUMN_NAME AND c2.tablename=c.TABLE_NAME
	JOIN @tTvpInfo d ON d.baseTableName=t.TABLE_NAME
	WHERE T.TABLE_NAME = C.TABLE_NAME AND c.column_name NOT IN ('TS')  FOR XML PATH('')    
	),1,1,'') AS [COLUMN_NAME]
	
	
	) AS S    
	WHERE LEFT(t.TABLE_NAME,10)<>'INF_SCHEMA' AND T.TABLE_TYPE ='BASE TABLE'
	AND ISNULL(tvp.wow_map_tablename,'')=''


	---- Insert Tvp definition for selected columns of table based upon wow_map_columns
	SET @cStep='55'
	INSERT INTO #tvpDefinition (tvpName,tvp_definition)
	SELECT  DISTINCT  tvp.tvpName, 'CREATE TYPE ['+tvp.tvpName + '] AS TABLE  ( '+S.COLUMN_NAME+(CASE WHEN tvp.consider_deleted_column=1 THEN 
	',deleted BIT' ELSE '' END)+')' as tvp_definition
	FROM INFORMATION_SCHEMA.TABLES T    
	JOIN @tTvpInfo tvp ON tvp.baseTableName=t.TABLE_NAME
	CROSS APPLY    
		(    
		SELECT STUFF((    
	SELECT +',['+COLUMN_NAME + '] '+    
	CASE WHEN DATA_TYPE IN ('DECIMAL','NUMERIC') THEN DATA_TYPE +' ('+ CAST(NUMERIC_PRECISION AS VARCHAR)+','+CAST(NUMERIC_SCALE AS VARCHAR)+')'    
	WHEN DATA_TYPE IN ('VARCHAR','CHAR') THEN DATA_TYPE +' ('+ CASE CHARACTER_MAXIMUM_LENGTH WHEN '-1' THEN 'MAX' ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) END +')'
	WHEN DATA_TYPE IN ('NVARCHAR','NCHAR','VARBINARY') THEN DATA_TYPE +' ('+ CASE CHARACTER_maximum_LENGTH WHEN '-1' THEN 'MAX' ELSE CAST(CHARACTER_maximum_LENGTH AS VARCHAR) END +')'
	ELSE DATA_TYPE    
	END    
	    
	FROM INFORMATION_SCHEMA.COLUMNS C (NOLOCK)   
	LEFT JOIN dbo.INF_SCHEMA_IDENTITY_COLUMNS C2 (NOLOCK) ON C2.COLUMNNAME=C.COLUMN_NAME AND c2.tablename=c.TABLE_NAME
	JOIN @tTvpInfo d ON d.baseTableName=t.TABLE_NAME
	JOIN wow_map_Columns m (NOLOCK) ON m.tablename=d.wow_map_tablename AND m.OrgColumnName=c.COLUMN_NAME
	WHERE T.TABLE_NAME = C.TABLE_NAME AND c.column_name NOT IN ('TS')  FOR XML PATH('')    
	),1,1,'') AS [COLUMN_NAME]
	
	
	) AS S    
	WHERE LEFT(t.TABLE_NAME,10)<>'INF_SCHEMA' AND T.TABLE_TYPE ='BASE TABLE'
	AND ISNULL(tvp.wow_map_tablename,'')<>''


	DELETE a FROM #tvpDefinition a JOIN sys.types b (NOLOCK) ON a.tvpName=b.name
	where b.is_user_defined=1

	WHILE EXISTS (SELECT TOP 1 * FROM  #tvpDefinition)
	BEGIN
		SET @cStep='60'
		SELECT TOP 1 @cCmd=tvp_definition,@cTvpName=tvpName FROM #tvpDefinition
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		DELETE FROM  #tvpDefinition WHERE tvpName=@cTvpName
	END

	SET @cStep='70'
	SET @cCmd=N'CREATE TYPE  tv_EditCols AS TABLE (tableName VARCHAR(100),columnName VARCHAR(200))'
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY

BEGIN CATCH
	
	SET @cErrormsg='Error in Procedure SPWOW_MANAGE_TVP_PROCS at Step#'+@cStep+' '+ERROR_MESSAGE()
	
	RAISERROR (@cErrormsg,16,1)

	GOTO END_PROC
END CATCH
	
END_PROC:

	SELECT ISNULL(@cErrormsg,'') errmsg
END
