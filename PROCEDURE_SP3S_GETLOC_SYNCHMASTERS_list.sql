CREATE PROCEDURE SP3S_GETLOC_SYNCHMASTERS_list
@cLocId VARCHAR(4)
AS
BEGIN
	DECLARE @cSkuTable VARCHAR(200),@cCmd NVARCHAR(MAX),@nLoop INT,@cTable VARCHAR(50),@cColName VARCHAR(100),@cAttrJoin VARCHAR(MAX),
	@cJoinStr VARCHAR(500),@cJoiningCol VARCHAR(100),@cStep VARCHAR(5),@cErrormsg VARCHAR(MAX),@cMasterColExpr NVARCHAR(MAX),@cUnpivotExpr VARCHAR(1000)

BEGIN TRY

	SET @cErrormsg=''
	SET @cStep='10'
	CREATE TABLE #tmpMasterValues (mastervalue datetime,masterName VARCHAR(100))

	return --- Put return today as it is runnng damn slow at Cantabil and also Synch sku is now shifted to RestwizappService API (Sanjay : 19-09-2024)
	--- Return put by Dinkar is now removed as per discussion with Sir , Dinkar and Pankaj
	--- on this surity that Every cloud client shall have its locations also updated on the same day 
	--- so that automatic calls do not come (Date : 27-12-2023)

	DECLARE @tLocMstInfo TABLE (master_name VARCHAR(100),ho_last_modified_on DATETIME)

	
	SET @cStep='20'
	SET @cAttrJoin=''

	SET @cMasterColExpr='max(isnull(sectionm.last_modified_on,'''')) sectionm,max(isnull(sectiond.last_modified_on,'''')) sectiond,'+
	'max(isnull(article.last_modified_on,'''')) article,max(isnull(article_fix_attr.last_modified_on,'''')) article_fix_attr,max(isnull(lm01106.last_modified_on,'''')) lm01106,'+
	'max(isnull(sku.last_modified_on,'''')) sku'

	SET @cUnpivotExpr='SELECT MAX(max_date) AS max_date,TableName FROM OriginalData UNPIVOT (max_date FOR TableName IN ([sectionm],[sectiond],[article],[article_fix_attr],[lm01106],[sku]'
	SET @nLoop=1
	WHILE @nLoop<=32
	BEGIN
		SET @cStep='25'
		SET @cJoinStr=''


		
		IF @nLoop<=7
		BEGIN
			SET @cTable='para'+ltrim(rtrim(str(@nLoop)))
			SET @cMasterColExpr=@cMasterColExpr+N',MAX(isnull('+@cTable+'.LAST_MODIFIED_ON,'''')) para'+ltrim(rtrim(str(@nLoop)))
		END
		ELSE
		BEGIN
		
			

			SELECT @cTable='attr'+ltrim(rtrim(str(@nLoop-7)))+'_mst'

			IF NOT EXISTS (SELECT TOP 1 column_name FROM config_attr (NOLOCK) WHERE table_name=@cTable AND table_caption<>'')
				GOTO lblNext

			SET @cMasterColExpr=@cMasterColExpr+N',MAX(isnull('+@cTable+'.LAST_MODIFIED_ON,'''')) attr'+ltrim(rtrim(str(@nLoop-7)))+'_mst'
			
			SET @cAttrJoin=@cAttrJoin+ ' LEFT JOIN '+@cTable+' ON '+@cTable+'.attr'+ltrim(rtrim(str(@nLoop-7)))+'_Key_code=article_fix_attr.attr'+
			ltrim(rtrim(str(@nLoop-7)))+'_key_code'

			
		END
		SET @cUnpivotExpr=@cUnpivotExpr+',['+@cTable+']'

lblNext:
		SET @nLoop=@nLoop+1
	END

	SET @cUnpivotExpr=@cUnpivotExpr+'))'
	
	
	EXEC SP3S_GETFILTEREDMASTERS_POS
	@cLocId=@cLocId,
	@cMasterColExpr=@cMasterColExpr,
	@cModifiedColAlias='',
	@bReturnLastModifiedDateOnly=1,
	@cAttrJoin=@cAttrJoin,
	@cUnpivotExpr=@cUnpivotExpr
	

	--IF @@SPID=105
	--	select * from #tmpMasterValues

	INSERT @tLocMstInfo (master_name,ho_last_modified_on)
	SELECT masterName,max(isnull(masterValue,'')) ho_last_modified_on from #tmpMasterValues
	GROUP BY MASTERNAME
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GETLOC_SYNCHMASTERS_list at step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH


END_PROC:
	

	if @@spid=117
		select 'check @tLocMstInfo',* from @tLocMstInfo

	IF @cErrormsg=''
		SELECT a.master_name,isnull(b.loc_last_modified_on,'') loc_last_modified_on,'' errmsg FROM @tLocMstInfo a 
		JOIN synch_pos_masters_list b ON a.master_name=b.master_name
		WHERE b.dept_id=@cLocId 
		AND ISNULL(a.ho_last_modified_on,'')>CONVERT(DATETIME,isnull(b.loc_last_modified_on,''))

	ELSE
		SELECT @cErrormsg errmsg
END