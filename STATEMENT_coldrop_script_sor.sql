declare @defConstName VARCHAR(200)

IF OBJECT_ID('tempdb..#tmpColInfo','u') IS NOT NULL
	DROP TABLE #tmpColInfo

select OBJECT_NAME(a.object_id) as constname,b.name as colname,OBJECT_NAME(parent_object_id) as table_name 
into #tmpColInfo from sys.default_constraints  a
join sys.columns b on a.parent_column_id=b.column_id and a.parent_object_id=b.object_id where OBJECT_NAME(parent_object_id) in ('eosssorm','eosssord')

DECLARE @CCMD NVARCHAR(MAX)
IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='Mode' AND TABLE_NAME='EOSSSORM')
BEGIN
	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='Mode' and table_name='eosssorm'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORM DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END
	
	SET @cCmd=N'alter table EOSSSORM DROP COLUMN Mode'
	EXEC SP_EXECUTESQL @cCmd	
END

IF NOT EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='output_gst' AND TABLE_NAME='EOSSSORD')
AND EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='EOSSSORM')
BEGIN
	SET @cCmd=N'alter table EOSSSORd add output_gst numeric(10,2)'
	EXEC SP_EXECUTESQL @cCmd
	
END
IF NOT EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='input_gst' AND TABLE_NAME='EOSSSORD')
AND EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='EOSSSORM')
BEGIN
	SET @cCmd=N'alter table EOSSSORd add input_gst numeric(10,2)'
	EXEC SP_EXECUTESQL @cCmd

END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='eoss_fresh' AND TABLE_NAME='EOSSSORM')
AND EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='EOSSSORM')
BEGIN
	SET @cCmd=N'alter table EOSSSORd add eoss_fresh numeric(1,0)'
	EXEC SP_EXECUTESQL @cCmd

END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='eoss_scheme_name' AND TABLE_NAME='EOSSSORM')
AND EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='EOSSSORM')
BEGIN
	SET @cCmd=N'alter table EOSSSORd add eoss_scheme_name varchar(400)'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='mrp_value' AND TABLE_NAME='EOSSSORM')
AND EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='EOSSSORM')
BEGIN
	SET @cCmd=N'alter table EOSSSORd add mrp_value numeric(10,2)'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='mrp' AND TABLE_NAME='EOSSSORD')
BEGIN
	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='mrp' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END


	SET @cCmd=N'alter table EOSSSORd drop column mrp'
	EXEC SP_EXECUTESQL @cCmd

END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='purchase_price' AND TABLE_NAME='EOSSSORM')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='purchase_price' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'alter table EOSSSORd drop column purchase_price'
	EXEC SP_EXECUTESQL @cCmd
	
END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='gm_type' AND TABLE_NAME='EOSSSORM')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='gm_type' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END
	
	SET @cCmd=N'alter table EOSSSORd drop column gm_type'
	EXEC SP_EXECUTESQL @cCmd
	
END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='NET_DIFF' AND TABLE_NAME='EOSSSORD')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='NET_DIFF' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END
	
	SET @cCmd=N'alter table EOSSSORd drop column NET_DIFF'
	EXEC SP_EXECUTESQL @cCmd
	
END


IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='TERMS' AND TABLE_NAME='EOSSSORD')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='TERMS' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END
	
	SET @cCmd=N'alter table EOSSSORd drop column TERMS'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='INACTIVE' AND TABLE_NAME='EOSSSORd')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='INACTIVE' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'alter table EOSSSORd drop column INACTIVE'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='cmm_discount_percentage' AND TABLE_NAME='EOSSSORd')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='cmm_discount_percentage' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'alter table EOSSSORd drop column cmm_discount_percentage'
	EXEC SP_EXECUTESQL @cCmd
END



IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='cmm_discount_amount' AND TABLE_NAME='EOSSSORd')
BEGIN

	set @defConstName=''
	SELECT @defConstName=constname from #tmpColInfo where colname='cmm_discount_amount' and table_name='EOSSSORD'
	
	IF ISNULL(@defConstName,'')<>''
	BEGIN
		SET @cCmd=N'alter table EOSSSORD DROP constraint '+@defConstName
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'alter table EOSSSORd drop column cmm_discount_amount'
	EXEC SP_EXECUTESQL @cCmd
END










