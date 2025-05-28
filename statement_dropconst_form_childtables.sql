SELECT C.NAME AS target_table
     ,B.NAME AS fk_name
INTO #tmpFormConst           
FROM SYSREFERENCES A 
JOIN SYSOBJECTS B ON A.CONSTID = B.ID 
JOIN SYSOBJECTS C ON A.FKEYID = C.ID 
JOIN SYSOBJECTS D ON A.RKEYID = D.ID 
JOIN SYSCOLUMNS E ON A.FKEY1 = E.COLID AND A.FKEYID = E.ID 
JOIN SYSCOLUMNS F ON A.RKEY1 = F.COLID AND A.RKEYID = F.ID		   
WHERE D.NAME='form'  AND F.NAME='form_id'

declare @cCmd NVARCHAR(MAX),@cTable VARCHAR(200),@cConstName VARCHAR(400)
while exists (select top 1 * from #tmpFormConst)
BEGIN
	select top 1 @cTable=target_table,@cConstName=FK_NAME FROM #tmpFormConst

	SET @cCmd=N'alter table '+@cTable+' drop constraint '+@cConstName
	EXEC SP_EXECUTESQL @cCmd

	delete from #tmpFormConst where fk_name=@cConstName
END