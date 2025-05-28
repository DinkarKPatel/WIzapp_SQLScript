CREATE PROCEDURE SP3S_MANUALCOUNT_SETUP
@nQueryId NUMERIC(1,0),
@dLoginDt DATETIME='',
@cSetupid VARCHAR(20)='',
@cStkCntMemoId VARCHAR(40)='',
@cLoginDeptId VARCHAR(5)='',
@cSpId VARCHAR(40)=''
AS
BEGIN
		
	DECLARE @cHoLocId VARCHAR(5),@cCurLocid VARCHAR(5),@bHoLoc BIT,@cStkExpr varchar(2000),@cSourcetable VARCHAR(400),
			@cCollist varchar(2000),@cCmd NVARCHAR(MAX),@bErrorFound BIT,@bImportMode BIT,@cJoinstr VARCHAR(2000),
			@cAttrColName VARCHAR(200),@cFilter VARCHAR(4000),@cAttrName VARCHAR(200)
	
	DECLARE @tConfigAttr TABLE (attr_column_name varchar(200),attr_name varchar(200),table_name varchar(200))

	SET @bImportMode=0		
	--SELECT TOP 1 @cHoLocId=value FROM config WHERE config_option='ho_location_id'
	--SELECT TOP 1 @cCurLocId=value FROM config WHERE config_option='location_id'

	--SET @bHoLoc=0

	--IF @cHoLocId=@cCurLocId
	--	SET @bHoLoc=1

	IF @nQueryId=1
		GOTO lblGetPendingSetup
	ELSE
	IF @nQueryId=2
		GOTO lblGetStockData
	ELSE
	IF @nQueryId=3
		GOTO lblGetMemoDetail
	ELSE
	IF @nQueryId=4
		GOTO lblValidateImport
	ELSE
		GOTO END_PROC
		
lblGetPendingSetup:
	SELECT 	a.STK_COUNT_SETUP_ID,STK_COUNT_SETUP_NAME,FILTER_DISPLAY,isnull(c.memo_id,'') as STK_COUNT_memo_ID from STOCK_COUNT_SETUP_mst a
	JOIN STOCK_COUNT_SETUP_LINK_LOC b ON a.STK_COUNT_SETUP_ID=b.STK_COUNT_SETUP_ID 
	left outer join 
	(select a.STK_COUNT_SETUP_ID,a.memo_id,completed from MANUAL_STOCK_COUNT_XN_MST A
	 JOIN STOCK_COUNT_SETUP_LINK_LOC b ON a.STK_COUNT_SETUP_ID=b.STK_COUNT_SETUP_ID 
	 where memo_dt=@dLoginDt AND b.dept_id=@cLoginDeptId AND datepart(WEEKday,memo_dt)=b.WEEK_DAY ) c ON c.STK_COUNT_SETUP_ID=a.STK_COUNT_SETUP_ID
	 where b.dept_id=@cLoginDeptId AND WEEK_DAY=datepart(WEEKday,@dLoginDt) AND isnull(c.completed,0)=0 and a.inactive=0
	
	GOTO END_PROC

lblGetStockData:
	
	SELECT @cFilter = [filter] from STOCK_COUNT_SETUP_mst WHERE STK_COUNT_SETUP_ID=@cSetupid 

	IF ISNULL(@cFilter,'')=''
	    SET @cFilter= '1=1'


	IF @bImportMode=1
	BEGIN
		SET @cJoinstr=' 1=1 '
	
		SELECT @cJoinstr=@cJoinstr+(CASE WHEN charindex('SECTION_NAME',@cColList)>0 THEN  ' AND b.section_name=c.section_name ' ELSE '' END)+
			(CASE WHEN charindex('SUB_SECTION_NAME',@cColList)>0 THEN  ' AND b.sub_section_name=c.sub_section_name ' ELSE '' END)+
			(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ' AND b.article_no=c.article_no ' ELSE '' END)+
			(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' AND b.para1_name=c.para1_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ' AND b.para2_name=c.para2_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
			(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)
		
		
		INSERT @tConfigAttr (attr_column_name)
		SELECT column_name from CONFIG_ATTR where table_caption<>''

		WHILE EXISTS (select * from @tConfigAttr)
		BEGIN
			SELECT top 1 @cAttrColName=ATTR_COLUMN_NAME from @tConfigAttr
			
			IF charindex(@cAttrColName,@cColList)>0
				SELECT @cJoinstr=@cJoinstr+' AND b.'+@cAttrColName+'=c.'+@cAttrColName

			DELETE FROM @tConfigAttr where attr_column_name=@cAttrColName
		END

		--select @cCollist as collist,@cSetupid 
		SET @cCmd = N' SELECT b.*,c.row_id,c.memo_id,c.sp_id,c.physical_stock FROM
					(SELECT '+@cCollist+',SUM(quantity_in_stock) as computer_stock
					from pmt01106 a (NOLOCK)
					JOIN sku_names b ON a.product_code=b.product_code
					WHERE '+@cFilter+' AND a.dept_id='''+@cLoginDeptId+'''
					GROUP BY '+@cColList+'
					) b JOIN stkcnt_MANUAL_STOCK_COUNT_XN_det_upload c ON '+@cJoinStr+' 
					WHERE c.sp_id='''+@cSpid+'''
					ORDER BY '+@cColList
		
	END
	ELSE
	BEGIN
		SELECT @cCollist = coalesce(@cColList+',','')+col_value from STOCK_COUNT_SETUP_col_list  
		WHERE STK_COUNT_SETUP_ID=@cSetupid 

		
		SET @cCmd = N'SELECT '+@cCollist+',SUM(quantity_in_stock) as computer_stock,convert(numeric(20,2),0) physical_stock,convert(varchar(40),newid()) as row_id,
						convert(varchar(40),''LATER'') as memo_id,convert(varchar(40),'''') as sp_id
						from pmt01106 a (NOLOCK)
						JOIN sku_names b ON a.product_code=b.product_code
						WHERE '+@cFilter+' AND a.dept_id='''+@cLoginDeptId+'''
						GROUP BY '+@cColList+'
						ORDER BY '+@cColList
	END

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	GOTO END_PROC

lblGetMemoDetail:
	SELECT @cSetupid=STK_COUNT_SETUP_ID FROM MANUAL_STOCK_COUNT_XN_MST (NOLOCK) WHERE memo_id=@cStkCntMemoId

	SELECT @cCollist = coalesce(@cColList+',','')+col_value from STOCK_COUNT_SETUP_col_list  
	WHERE STK_COUNT_SETUP_ID=@cSetupid 

	SET @cCmd = N'SELECT '+@cCollist+',computer_stock,physical_stock,row_id,memo_id,convert(varchar(40),'''') as sp_id
					from MANUAL_STOCK_COUNT_XN_DET b (NOLOCK)
					WHERE b.memo_id='''+@cStkCntMemoId+'''
					ORDER BY '+@cCollist

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC

lblValidateImport:
	
	SELECT @cCollist = coalesce(@cColList+',','')+'b.'+col_value from STOCK_COUNT_SETUP_col_list  
	WHERE STK_COUNT_SETUP_ID=@cSetupid 

	SET @bErrorFound=0

	SET @cCmd = N' IF EXISTS (SELECT '+@cCollist+',''Duplicate values not allowed'' as errmsg
							from stkcnt_MANUAL_STOCK_COUNT_XN_det_upload b (NOLOCK)
							WHERE b.sp_id='''+@cSpId+'''
							GROUP BY '+@cColList+' HAVING count(*)>1)
						SELECT '+@cCollist+',''Duplicate values not allowed'' as errmsg
						from stkcnt_MANUAL_STOCK_COUNT_XN_det_upload b (NOLOCK)
						WHERE b.sp_id='''+@cSpId+'''
						GROUP BY '+@cColList+' HAVING count(*)>1'

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF @@ROWCOUNT>0
		SET @bErrorFound=1

	DECLARE @TERROR TABLE (mst_TYPE varchar(20),mst_VALUE varchar(200),errmsg varchar(500))
	
	--RETURN THE LIST OF MASTERS THAT ARE NEW TO THE SYSTEM.
	IF charindex('SECTION_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW SECTION NAMES
		SELECT DISTINCT 'SECTION',A.SECTION_NAME,'SECTION DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN SECTIONM B ON A.SECTION_NAME=B.SECTION_NAME
		WHERE B.SECTION_NAME IS	 NULL AND a.sp_id=@cSpId

	IF charindex('SUB_SECTION_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW SUB SECTIONS
		SELECT DISTINCT 'SUBSECTION',A.SUB_SECTION_NAME+'('+A.SECTION_NAME+')','SUBSECTION DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN (select section_name,sub_section_name from SECTIOND b
				  JOIN SECTIONM C ON c.section_code=b.section_code) b on a.section_name=a.section_name and b.sub_section_name=a.sub_section_name
		WHERE b.SECTION_NAME IS NULL AND a.sp_id=@cSpId

	IF charindex('article_no',@cColList)>0		
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW ARTICLES
		SELECT DISTINCT 'ARTICLE',A.ARTICLE_NO+'('+A.SUB_SECTION_NAME+')','ARTICLE DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN article b on b.article_no=a.article_no
		WHERE B.ARTICLE_NO IS NULL AND a.sp_id=@cSpId

	DECLARE @CPARA1NAME VARCHAR(50),@CPARA2NAME VARCHAR(50),@CPARA3NAME VARCHAR(50),@CPARA4NAME VARCHAR(50),@CPARA5NAME VARCHAR(50),@CPARA6NAME VARCHAR(50)


	SELECT TOP 1 @CPARA1NAME=VALUE FROM CONFIG WHERE  CONFIG_OPTION='PARA1_caption'
	IF charindex('para1_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW PARA1 NAMES
		SELECT DISTINCT @CPARA1NAME,A.PARA1_NAME,@CPARA1NAME+' DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN PARA1 B ON A.PARA1_NAME=B.PARA1_NAME
		WHERE B.PARA1_NAME IS NULL AND a.sp_id=@cSpId

	SELECT TOP 1 @CPARA2NAME=VALUE FROM CONFIG WHERE  CONFIG_OPTION='PARA2_caption'
	IF charindex('para2_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW PARA2 NAMES
		SELECT DISTINCT @CPARA2NAME,A.PARA2_NAME,@CPARA2NAME+' DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN PARA2 B ON A.PARA2_NAME=B.PARA2_NAME
		WHERE B.PARA2_NAME IS NULL AND a.sp_id=@cSpId

	SELECT TOP 1 @CPARA3NAME=VALUE FROM CONFIG WHERE  CONFIG_OPTION='PARA3_caption'
	
	IF charindex('para3_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW PARA3 NAMES
		SELECT DISTINCT @CPARA3NAME,A.PARA3_NAME,@CPARA3NAME+' DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN PARA3 B ON A.PARA3_NAME=B.PARA3_NAME
		WHERE B.PARA3_NAME IS NULL AND a.sp_id=@cSpId			

	SELECT TOP 1 @CPARA4NAME=VALUE FROM CONFIG WHERE  CONFIG_OPTION='PARA4_caption'

	IF charindex('para4_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW PARA4 NAMES
		SELECT DISTINCT @CPARA4NAME,A.PARA4_NAME,@CPARA4NAME+' DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN PARA4 B ON A.PARA4_NAME=B.PARA4_NAME
		WHERE B.PARA4_NAME IS NULL AND a.sp_id=@cSpId			

	SELECT TOP 1 @CPARA5NAME=VALUE FROM CONFIG WHERE  CONFIG_OPTION='PARA5_caption'
	
	IF charindex('para5_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW PARA5 NAMES
		SELECT DISTINCT @CPARA5NAME,A.PARA5_NAME,@CPARA5NAME+' DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN PARA5 B ON A.PARA5_NAME=B.PARA5_NAME
		WHERE B.PARA5_NAME IS NULL AND a.sp_id=@cSpId			

	SELECT TOP 1 @CPARA6NAME=VALUE FROM CONFIG WHERE  CONFIG_OPTION='PARA6_caption'		

	IF charindex('para6_NAME',@cColList)>0
		INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
		--LIST OF NEW PARA6 NAMES
		SELECT DISTINCT @CPARA6NAME,A.PARA6_NAME,@CPARA6NAME+' DOESNOT EXISTS.'
		FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
		LEFT JOIN PARA6 B ON A.PARA6_NAME=B.PARA6_NAME
		WHERE B.PARA6_NAME IS NULL AND a.sp_id=@cSpId
	

	DECLARE @cAttrTableName varchAr(200)
	INSERT @tConfigAttr (attr_column_name,attr_name,table_name)
	SELECT column_name,table_caption,table_name from config_attr
	 where table_caption<>''

	WHILE EXISTS (select * from @tConfigAttr)
	BEGIN
		SELECT top 1 @cAttrColName=ATTR_COLUMN_NAME,@cAttrName=attr_name,@cAttrTableName=table_name from @tConfigAttr
			
		IF charindex(@cAttrColName,@cColList)>0
		BEGIN
			SET @cCmd=N'SELECT DISTINCT '''+ @cAttrName+''',A.'+@cAttrColName+','''+@cAttrName+'DOESNOT EXISTS.''
			FROM stkcnt_MANUAL_STOCK_COUNT_XN_det_upload A
			LEFT JOIN '+@cAttrTablename+' B ON A.'+@cAttrColName+'=B.'+@cAttrColName+'
			WHERE B.'+@cAttrColName+' IS NULL AND a.sp_id='''+@cSpId+''''

			PRINT @cCmd

			INSERT @TERROR(mst_TYPE,mst_VALUE,errmsg)
			EXEC SP_EXECUTESQL @cCmd
		END

		DELETE FROM @tConfigAttr where attr_column_name=@cAttrColName
	END


	IF EXISTS (SELECT TOP 1 * FROM @tError)
	BEGIN
		SET @bErrorFound=1
		SELECT * FROM @TERROR
	END

	IF @bErrorFound=0	BEGIN
		SET @bImportMode=1
		GOTO lblGetStockData
	END	
END_PROC:
	
END