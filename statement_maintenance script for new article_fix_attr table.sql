IF EXISTS (SELECT TOP 1 * FROM article_fix_attr)
	GOTO END_PROC

DECLARE @cCurLocId varchar(5)/*Rohit 01-11-2024*/,@cHoLocId VARCHAR(5)/*Rohit 01-11-2024*/
SELECT TOP 1 @cCurLocId=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'
SELECT TOP 1 @cHoLocId=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'

IF @cCurLocId<>@cHoLocId
	RETURN


---- This script shall run only at Ho becasue of difference in distribution of attributes in respective tables
----- between Ho & Pos found at Donear (17-01-2019) 	 	
IF OBJECT_ID('tempdb..#tmpAttrm','u') IS NOT NULL
	DROP TABLE #tmpattrm
	
SELECT 'attr'+ltrim(rtrim(str((row_number() over (order by attribute_code)))))+'_mst' as  table_name,
attribute_name as  TABLE_CAPTION,attribute_code,0 as open_key into #tmpattrm from attrm where attribute_code not in ('0000000','') and attribute_name<>''
and isnull(ATTRIBUTE_TYPE,0) in (0,1)


IF NOT EXISTS (SELECT TOP 1 * FROM config_ATTR )
	INSERT config_Attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY )  
	SELECT TABLE_NAME, TABLE_CAPTION,open_key
	FROM #tmpAttrm


UPDATE config_attr set column_name=REPLACE(TABLE_NAME,'_mst','_key_name')

DECLARE @CATTRIBUTECODE VARCHAR(7), @CATTRIBUTENAME VARCHAR(50), 
		@NCTR NUMERIC(10), @CALIASC VARCHAR(10), @CALIASD VARCHAR(10),
		@CATTRCOLNAME VARCHAR(MAX), 
		@CATTRJOINSTR VARCHAR(MAX), 
		@CATTRJOINSTRGRP VARCHAR(MAX), 
		@CCMD NVARCHAR(MAX), 
		@CCMD1 NVARCHAR(MAX), 
		@CCMD2 NVARCHAR(MAX), 
		@CCREATEALTER VARCHAR(10),
		@CCMDCRTATTRGRPVIEW NVARCHAR(MAX), 
		@CCMDCRTATTRVALUE NVARCHAR(MAX),
		@CDATABASE VARCHAR(50), 
		@CVALUE VARCHAR(50), 
		@CCMDCRTRFVIEW NVARCHAR(MAX),
		@CCMDALIAS NVARCHAR(MAX), 
		@CATTRCOLNAMEALIAS VARCHAR(MAX), 
		@CCMDCRTATTRALIASVALUE NVARCHAR(MAX),
		@CATTREXPR VARCHAR(MAX),@nAttrMode INT,
		@cAttrTableName VARCHAR(200),@CATTRKEYCOLNAME VARCHAR(200),@CATTRMSTCOLNAME VARCHAR(200)


DELETE from Art_attr WHERE key_code=''

delete a from art_attr a join attr_key b on a.key_code=b.key_code
where a.attribute_code<>b.attribute_code

update a set key_name=a.KEY_NAME+'_'+a.key_code from Attr_key a
where a.key_code<>(select top 1 b.key_code from attr_key b where b.attribute_code=a.attribute_code and b.key_name=a.key_name)

DECLARE ABC CURSOR FOR
SELECT ATTRIBUTE_CODE,table_name,replace(table_name,'mst','key_code') FROM #tmpattrm

SET @NCTR = 1
SET @CCMD = N''
SET @CCMD1= N''
SET @CCMD2= N''
SET @CCMDALIAS = N''


OPEN ABC
FETCH NEXT FROM ABC INTO @CATTRIBUTECODE,@cAttrTableName, @CATTRKEYCOLNAME
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @CALIASC	= 'C' + CONVERT(VARCHAR(10), @NCTR)
	SET @CALIASD	= 'D' + CONVERT(VARCHAR(10), @NCTR)
	
	SET @CCMD = @CCMD + 
				(CASE WHEN @CCMD<>'' THEN ', '+CHAR(13) ELSE '' END) +
					N'(CASE WHEN  '+ @CALIASC + '.ATTRIBUTE_CODE = ''' + @CATTRIBUTECODE + ''' 
				  THEN ISNULL('+@CALIASC+'.KEY_code,'''') ELSE ''0000000'' END) AS [' + @CATTRKEYCOLNAME+']'

	SET @CCMD1 = @CCMD1 + 
				(CASE WHEN @CCMD1<>'' THEN ' '+CHAR(13) ELSE '' END) +
				   N' LEFT OUTER JOIN ART_ATTR ' + @CALIASC + ' ON A.ARTICLE_CODE = ' 
				   + @CALIASC + '.ARTICLE_CODE AND ' + @CALIASC + '.ATTRIBUTE_CODE = ''' + @CATTRIBUTECODE + ''''


	SET @CCMD2=N'IF NOT EXISTS (SELECT TOP 1 '+@CATTRKEYCOLNAME+' from '+@cAttrTableName+' WHERE '+@CATTRKEYCOLNAME+'=''0000000'')
					INSERT INTO '+@cAttrTableName+'('+@CATTRKEYCOLNAME+','+REPLACE(@CATTRKEYCOLNAME,'_code','_name')+')
					SELECT ''0000000'','''''
	PRINT @cCmd2
	EXEC SP_EXECUTESQL @cCmd2


	SET @CCMD2=N'INSERT INTO '+@cAttrTableName+'('+@CATTRKEYCOLNAME+','+REPLACE(@CATTRKEYCOLNAME,'_code','_name')+','+REPLACE(@CATTRKEYCOLNAME,'_key_code','_alias')+')
				 SELECT DISTINCT c.key_code,c.key_name,c.key_alias
				 FROM art_attr a
				 JOIN attr_key c ON a.key_code=c.key_code
				 LEFT OUTER JOIN '+@cAttrTableName+' b  ON c.key_code=b.'+@CATTRKEYCOLNAME+'
				 WHERE c.attribute_code='''+@CATTRIBUTECODE+''' AND b.'+@CATTRKEYCOLNAME+' IS NULL'
	PRINT @cCmd2
	EXEC SP_EXECUTESQL @cCmd2
		
	SET @NCTR = @NCTR + 1

	FETCH NEXT FROM ABC INTO @CATTRIBUTECODE,@cAttrTableName, @CATTRKEYCOLNAME
END
CLOSE ABC
DEALLOCATE ABC


IF @NCTR<=25
BEGIN
	WHILE @NCTR<=25
	BEGIN
		SELECT @cAttrTableName='attr'+LTRIM(rtrim(str(@NCTR)))+'_mst',@CATTRKEYCOLNAME='attr'+LTRIM(rtrim(str(@NCTR)))+'_key_code'
		
		SET @CCMD2=N'IF NOT EXISTS (SELECT TOP 1 '+@CATTRKEYCOLNAME+' from '+@cAttrTableName+' WHERE '+@CATTRKEYCOLNAME+'=''0000000'')
						INSERT INTO '+@cAttrTableName+'('+@CATTRKEYCOLNAME+','+REPLACE(@CATTRKEYCOLNAME,'_code','_name')+')
						SELECT ''0000000'','''''
		PRINT @cCmd2
		EXEC SP_EXECUTESQL @cCmd2
		
		SET @cCmd=@CcMD+',''0000000'' AS '+ @CATTRKEYCOLNAME
		SET @NCTR = @NCTR + 1
	END
END

SET @CATTRCOLNAME		= @CCMD
SET @CATTRJOINSTR		= @CCMD1


IF OBJECT_ID('art_attr_backup_for_article_fix_attr_dup') IS NULL
	SELECT a.* INTO art_attr_backup_for_article_fix_attr_dup
	from art_attr a
	join attr_key b on a.key_code=b.key_code
	where a.attribute_code<>b.attribute_code

IF LEFT(@CATTRCOLNAME,1)=','
	SET @CATTRCOLNAME=SUBSTRING(@CATTRCOLNAME,2,LEN(@CATTRCOLNAME))
	
SET @CATTREXPR=' SELECT  A.ARTICLE_CODE, ' + @CATTRCOLNAME + ' FROM ARTICLE A '+ @CATTRJOINSTR

SET @CCMDCRTATTRVALUE = N' INSERT article_fix_attr	( article_code, attr1_key_code, attr2_key_code, attr3_key_code, attr4_key_code, 
attr5_key_code, attr6_key_code, attr7_key_code, attr8_key_code, attr9_key_code, attr10_key_code, attr11_key_code, 
attr12_key_code, attr13_key_code, attr14_key_code, attr15_key_code, attr16_key_code, attr17_key_code, 
attr18_key_code, attr19_key_code, attr20_key_code, attr21_key_code, attr22_key_code, attr23_key_code, 
attr24_key_code, attr25_key_code )'+@CATTREXPR


--' INSERT article_fix_attr	( article_code, attr1_key_code, attr2_key_code, attr3_key_code, attr4_key_code, 
--attr5_key_code, attr6_key_code, attr7_key_code, attr8_key_code, attr9_key_code, attr10_key_code, attr11_key_code, 
--attr12_key_code, attr13_key_code, attr14_key_code, attr15_key_code, attr16_key_code, attr17_key_code, 
--attr18_key_code, attr19_key_code, attr20_key_code, attr21_key_code, attr22_key_code, attr23_key_code, 
--attr24_key_code, attr25_key_code )'+ 


PRINT @CCMDCRTATTRVALUE
EXEC SP_EXECUTESQL @CCMDCRTATTRVALUE

END_PROC:

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr1_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr1_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr1_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr2_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr2_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr2_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr3_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr3_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr3_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr4_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr4_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr4_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr5_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr5_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr5_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr6_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr6_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr6_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr7_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr7_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr7_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr8_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr8_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr8_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr9_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr9_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr9_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr10_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr10_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr10_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr11_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr11_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr11_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr12_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr12_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr12_key_name' as column_name											

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr13_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr13_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr13_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr14_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr14_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr14_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr15_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr15_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr15_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr16_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr16_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr16_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr17_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr17_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr17_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr18_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr18_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr18_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr19_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr19_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr19_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr20_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr20_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr20_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr21_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr21_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr21_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr22_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr22_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr22_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr23_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr23_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr23_key_name' as column_name

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr24_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr24_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr24_key_name' as column_name											 

IF NOT EXISTS (SELECT TOP 1 * FROM config_attr WHERE table_name='attr25_mst')
	INSERT config_attr	( TABLE_NAME, TABLE_CAPTION, OPEN_KEY, column_name )  
	SELECT 'attr25_mst' as TABLE_NAME,'' as TABLE_CAPTION,0 as  OPEN_KEY,'attr25_key_name' as column_name											 

