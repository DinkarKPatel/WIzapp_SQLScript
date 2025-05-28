
IF EXISTS (SELECT TOP 1 * FROM CONFIG_CUST_ATTR)
	return

DECLARE @cCurLocId VARCHAR(5)/*Rohit 01-11-2024*/,@cHoLocId VARCHAR(5)/*Rohit 01-11-2024*/
SELECT TOP 1 @cCurLocId=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'
SELECT TOP 1 @cHoLocId=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'

IF @cCurLocId<>@cHoLocId
	RETURN


---- This script shall run only at Ho becasue of difference in distribution of attributes in respective tables
----- between Ho & Pos found at Donear (17-01-2019) 	 	
IF OBJECT_ID('tempdb..#tmpAttrm','u') IS NOT NULL
	DROP TABLE #tmpattrm
	
SELECT 'cust_attr'+ltrim(rtrim(str((row_number() over (order by attribute_code)))))+'_mst' as  table_name,
attribute_name as  TABLE_CAPTION,attribute_code,0 as open_key ,
'cust_attr'+ltrim(rtrim(str((row_number() over (order by attribute_code)))))+'_name' as  columnname
into #tmpattrm 
from attrm WHERE ATTRIBUTE_TYPE = 3 AND ATTRIBUTE_CODE<>'0000000'
AND ATTRIBUTE_NAME<>''
 
 
IF NOT EXISTS (SELECT TOP 1 * FROM CONFIG_CUST_ATTR )
	INSERT CONFIG_CUST_ATTR	( TABLE_NAME, TABLE_CAPTION ,open_key,column_name)  
	SELECT TABLE_NAME, TABLE_CAPTION,open_key,columnname
	FROM #tmpAttrm



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


DECLARE ABC CURSOR FOR
SELECT ATTRIBUTE_CODE,table_name,replace(TABLE_NAME ,'_mst','_key_code') FROM #tmpattrm



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
				   N' LEFT OUTER JOIN cust_ATTR ' + @CALIASC + ' ON A.customer_code = ' 
				   + @CALIASC + '.customer_code AND ' + @CALIASC + '.ATTRIBUTE_CODE = ''' + @CATTRIBUTECODE + ''''


	SET @CCMD2=N'IF NOT EXISTS (SELECT TOP 1 '+@CATTRKEYCOLNAME+' from '+@cAttrTableName+' WHERE '+@CATTRKEYCOLNAME+'=''0000000'')
					INSERT INTO '+@cAttrTableName+'('+@CATTRKEYCOLNAME+','+REPLACE(@CATTRKEYCOLNAME,'_code','_name')+')
					SELECT ''0000000'','''''
	PRINT @cCmd2
	EXEC SP_EXECUTESQL @cCmd2


	SET @CCMD2=N'INSERT INTO '+@cAttrTableName+'('+@CATTRKEYCOLNAME+','+REPLACE(@CATTRKEYCOLNAME,'_code','_name')+','+REPLACE(@CATTRKEYCOLNAME,'_key_code','_alias')+')
				 SELECT DISTINCT c.key_code,c.key_name,c.key_alias
				 FROM cust_ATTR a
				 JOIN attr_key c ON a.key_code=c.key_code
				 LEFT OUTER JOIN '+@cAttrTableName+' b  ON c.key_code=b.'+@CATTRKEYCOLNAME+'
				 WHERE c.attribute_code='''+@CATTRIBUTECODE+''' AND b.'+@CATTRKEYCOLNAME+' IS NULL and c.key_code<>'''''
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
		SELECT @cAttrTableName='cust_attr'+LTRIM(rtrim(str(@NCTR)))+'_mst',@CATTRKEYCOLNAME='cust_attr'+LTRIM(rtrim(str(@NCTR)))+'_key_code'
		
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


IF LEFT(@CATTRCOLNAME,1)=','
	SET @CATTRCOLNAME=SUBSTRING(@CATTRCOLNAME,2,LEN(@CATTRCOLNAME))
	
SET @CATTREXPR=' SELECT  A.customer_code, ' + @CATTRCOLNAME + ' FROM custdym A '+ @CATTRJOINSTR

SET @CCMDCRTATTRVALUE = N' INSERT customer_fix_attr	( customer_code, cust_attr1_key_code, cust_attr2_key_code, cust_attr3_key_code, cust_attr4_key_code, 
cust_attr5_key_code, cust_attr6_key_code, cust_attr7_key_code, cust_attr8_key_code, cust_attr9_key_code, cust_attr10_key_code ,
cust_attr11_key_code,cust_attr12_key_code,cust_attr13_key_code,cust_attr14_key_code,cust_attr15_key_code,cust_attr16_key_code,
cust_attr17_key_code,cust_attr18_key_code,cust_attr19_key_code,cust_attr20_key_code,cust_attr21_key_code,cust_attr22_key_code,
cust_attr23_key_code,cust_attr24_key_code,cust_attr25_key_code
)'+@CATTREXPR



PRINT @CCMDCRTATTRVALUE
EXEC SP_EXECUTESQL @CCMDCRTATTRVALUE




insert into CONFIG_CUST_ATTR(table_name,table_caption,open_key,column_name)
select table_name,table_caption,openkey open_key,column_name from
(
select 'cust_attr1_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr1_name' as column_name union all
select 'cust_attr2_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr2_name' as column_name union all
select 'cust_attr3_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr3_name' as column_name union all
select 'cust_attr4_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr4_name' as column_name union all
select 'cust_attr5_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr5_name' as column_name union all
select 'cust_attr6_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr6_name' as column_name union all
select 'cust_attr7_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr7_name' as column_name union all
select 'cust_attr8_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr6_name' as column_name union all
select 'cust_attr9_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr9_name' as column_name union all
select 'cust_attr10_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr10_name' as column_name union all
select 'cust_attr11_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr11_name' as column_name union all
select 'cust_attr12_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr12_name' as column_name union all
select 'cust_attr13_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr13_name' as column_name union all
select 'cust_attr14_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr14_name' as column_name union all
select 'cust_attr15_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr15_name' as column_name union all
select 'cust_attr16_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr16_name' as column_name union all
select 'cust_attr17_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr17_name' as column_name union all
select 'cust_attr18_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr18_name' as column_name union all
select 'cust_attr19_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr19_name' as column_name union all
select 'cust_attr20_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr20_name' as column_name union all
select 'cust_attr21_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr21_name' as column_name union all
select 'cust_attr22_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr22_name' as column_name union all
select 'cust_attr23_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr23_name' as column_name union all
select 'cust_attr24_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr24_name' as column_name union all
select 'cust_attr25_mst' as table_name ,'' as table_caption,0 as openkey,'cust_attr25_name' as column_name 
) a
where table_name not in(select table_name from config_cust_attr)

