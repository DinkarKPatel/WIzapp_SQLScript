CREATE PROCEDURE SP3S_GETXPERT_AGEINGCOLS	
@cRepId VARCHAR(50),
@cAgeColNames VARCHAR(300) OUTPUT
AS
BEGIN
	SET @cAgeColNames=','
	IF EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr='ageing_1') AND 
		NOT EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr='purchase_ageing_days')
		SET @cAgeColNames=@cAgeColNames+'CONVERT(VARCHAR(20),'''') ageing_1,CONVERT(NUMERIC(10,0),0) AS [purchase ageing]'

	IF EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr='ageing_3') AND 
		NOT EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr='shelf_ageing_days')
		SET @cAgeColNames=@cAgeColNames+(CASE WHEN @cAgeColNames<>',' THEN ',' ELSE '' END)+
						  'CONVERT(VARCHAR(20),'''') ageing_3,CONVERT(NUMERIC(10,0),0) AS [shelf ageing]'

	IF EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr='ageing_2') AND 
		NOT EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr='selling_days')
		SET @cAgeColNames=@cAgeColNames+(CASE WHEN @cAgeColNames<>',' THEN ',' ELSE '' END)+
						  'CONVERT(VARCHAR(20),'''') ageing_2,CONVERT(NUMERIC(10,0),0) AS [Sale ageing]'

	INSERT #rep_det	(row_id,col_order, rep_id,Calculative_col, col_expr, col_header, Dimension, key_col, Mesurement_col ) 
	SELECT newid() row_id,a.col_order, a.rep_id,a.Calculative_col,a.col_expr,a.col_header,a.Dimension,a.key_col, a.Mesurement_col
	FROM 
	(
	SELECT @cRepId rep_id,1 Calculative_col,'purchase_ageing_days' col_expr,'Purchase Ageing' col_header,
	0 Dimension,'purchase_ageing_days' key_col,0 Mesurement_col,1 col_order
	FROM #rep_det WHERE col_expr='ageing_1'
	UNION ALL
	SELECT @cRepId rep_id,1 Calculative_col,'shelf_ageing_days' col_expr,'Shelf Ageing' col_header,
	0 Dimension,'shelf_ageing_days' key_col,0 Mesurement_col,3 col_order
	FROM #rep_det WHERE col_expr='ageing_3'
	UNION ALL
	SELECT @cRepId rep_id,1 Calculative_col,'selling_days' col_expr,'Sale Ageing' col_header,
	0 Dimension,'selling_days' key_col,0 Mesurement_col,3 col_order
	FROM #rep_det WHERE col_expr='ageing_2'

	) a
	LEFT JOIN #rep_det b ON a.rep_id=b.rep_id AND a.key_col=b.key_col
	WHERE b.rep_id IS NULL

	UPDATE a SET dimension=1 FROM #rep_det a
	JOIN #rep_det b ON a.rep_id=b.rep_id
	WHERE (a.col_expr='ageing_1' AND b.col_expr='purchase_ageing_days') OR 
	(a.col_expr='ageing_3' AND b.col_expr='shelf_ageing_days')  OR 
	(a.col_expr='ageing_2' AND b.col_expr='selling_days')


	UPDATE a SET mesurement_col=1 FROM #rep_det a
	JOIN #rep_det b ON a.rep_id=b.rep_id
	WHERE (a.key_col IN ('OBS','CBS') AND b.col_expr='purchase_ageing_days') OR 
	(a.key_col IN ('OBS','CBS') AND b.col_expr='shelf_ageing_days')  OR 
	(a.key_col IN ('NSQ','SPQ','SRQ') AND b.col_expr='selling_days')

	UPDATE #rep_mst set CrossTab_Type=1
END
