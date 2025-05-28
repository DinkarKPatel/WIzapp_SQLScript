CREATE PROCEDURE SP3S_DROPCOLS_DOCMIRRORTABLES
AS
BEGIN
	IF OBJECT_ID('tempdb..#dropmirrorcols','u') IS NOT NULL
		DROP TABLE #dropmirrorcols
		
	select a.name as colname,B.NAME as tablename,'alter table '+b.name+' drop column '+a.name as cmd INTO #dropmirrorcols
	from syscolumns a join sysobjects b on a.id=b.id 
	left outer join 
	(select a.name AS colname,b.name as tablename,C.name AS MIRROR_TABLENAME from 
	 syscolumns a join sysobjects b on a.id=b.id
	 JOIN SYSOBJECTS C ON c.name='DOCWSL_'+B.NAME+'_MIRROR'
	 ) C ON C.MIRROR_TABLENAME=B.name AND C.colname=A.NAME
	 WHERE LEFT(B.NAME,7)='DOCWSL_' AND RIGHT(B.NAME,6)='MIRROR' 
	 AND C.colname IS NULL AND A.name NOT IN ('VERSION_NO','DOCWSL_MEMO_ID','VERSION_LAST_UPDATE')
	 
	UNION ALL
	select a.name as colname,B.NAME as tablename,'alter table '+b.name+' drop column '+a.name as cmd 
	from syscolumns a join sysobjects b on a.id=b.id 
	left outer join 
	(select a.name AS colname,b.name as tablename,C.name AS MIRROR_TABLENAME from 
	 syscolumns a join sysobjects b on a.id=b.id
	 JOIN SYSOBJECTS C ON c.name='DOCPRT_'+B.NAME+'_MIRROR'
	 ) C ON C.MIRROR_TABLENAME=B.name AND C.colname=A.NAME
	 WHERE LEFT(B.NAME,7)='DOCPRT_' AND RIGHT(B.NAME,6)='MIRROR' 
	 AND C.colname IS NULL AND A.name NOT IN ('VERSION_NO','DOCPRT_MEMO_ID','VERSION_LAST_UPDATE')

	PRINT 'Get REcords for Mirr table colums to be dropped'

	DECLARE @bLoop BIT,@cCmd NVARCHAR(MAX),@cTableName VARCHAR(100),@cColName VARCHAR(300)
	SET @bLoop=0
	WHILE @bLoop=0
	BEGIN
		SET @cCmd=''
		SELECT TOP 1 @cCmd=cmd,@cTableName=tablename,@cColName=colname  FROM #dropmirrorcols
		
		IF ISNULL(@cCmd,'')=''
			BREAK
		
		PRINT 'Dropping column :'+@cColName+' from Table:'+@cTablename
		EXEC SP_EXECUTESQL @cCmd
		
		DELETE FROM #dropmirrorcols WHERE cmd=@cCmd	
	END 
END
