CREATE PROCEDURE SPACT_GET_BSHEADS 
AS
BEGIN
	declare @cCmd NVARCHAR(MAX)

	CREATE TABLE #tmpHeads (head_code char(10),major_head_code char(10))

	SET @cCmd=N'
	SELECT head_code,''0000000018'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000018')+')  
	UNION
	SELECT head_code,''0000000021'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000021')+')  
	UNION
	SELECT head_code,''0000000001'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000001')+')  
	UNION
	SELECT head_code,''0000000002'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000002')+')  
	UNION   
	SELECT head_code,''0000000007'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000007')+')  
	UNION   
	SELECT head_code,''0000000004'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000004')+')  
	UNION   
	SELECT head_code,''0000000003'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000003')+')
	UNION   
	SELECT head_code,''00DEF00034'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('00DEF00034')+')
	UNION   
	SELECT head_code,''0000000005'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000005')+')  	
	UNION   
	SELECT head_code,''0000000008'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000008')+') 
	UNION   
	SELECT head_code,''0000000011'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000011')+')  	
	UNION   
	SELECT head_code,''0000000006'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000006')+')  	
	UNION   
	SELECT head_code,''0000000006'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('00DEF00032')+')  	
	UNION   
	SELECT head_code,''00DEF00033'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('00DEF00033')+')  	
	'

	insert into #tmpHeads(head_code,major_head_code)
	exec sp_executesql @cCmd

	select a.*,b.head_name major_head_Name from #tmpHeads a JOIN hd01106 b (NOLOCK) ON a.major_head_code=b.HEAD_CODE
	order by a.head_code
END