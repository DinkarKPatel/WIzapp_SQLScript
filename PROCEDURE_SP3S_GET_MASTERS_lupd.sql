CREATE PROCEDURE SP3S_GET_MASTERS_lupd
AS
BEGIN
	DECLARE @dLastUpdate DATETIME,@cLocId VARCHAR(4)

	SELECT TOP 1 @cLocId=value FROM config (NOLOCK) WHERE config_option='location_id'

	SELECT @cLocId dept_id,* INTO #tmpmst FROM 
	(
	SELECT 'SKU' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  sku(NOLOCK)
	UNION ALL
	SELECT 'ARTICLE' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ARTICLE(NOLOCK)
	UNION ALL
	SELECT 'ARTICLE_FIX_ATTR' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ARTICLE_FIX_ATTR(NOLOCK)
	UNION ALL	
	SELECT 'SECTIONM' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  SECTIONM(NOLOCK)
	UNION ALL
	SELECT 'SECTIOND' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  SECTIOND(NOLOCK)
	UNION ALL
	SELECT 'PARA1' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA1(NOLOCK)
	UNION ALL
	SELECT 'PARA2' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA2(NOLOCK)
	UNION ALL
	SELECT 'PARA3' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA3(NOLOCK)
	UNION ALL
	SELECT 'PARA4' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA4(NOLOCK)
	UNION ALL
	SELECT 'PARA5' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA5(NOLOCK)
	UNION ALL
	SELECT 'PARA6' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA6(NOLOCK)
	UNION ALL
	SELECT 'PARA7' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  PARA7 (NOLOCK)
	UNION ALL
	SELECT 'ATTR1_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR1_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR2_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR2_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR3_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR3_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR4_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR4_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR5_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR5_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR6_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR6_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR7_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR7_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR8_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR8_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR9_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR9_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR10_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR10_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR11_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR11_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR12_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR12_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR13_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR13_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR14_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR14_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR15_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR15_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR16_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR16_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR17_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR17_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR18_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR18_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR19_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR19_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR20_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR20_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR21_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR21_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR22_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR22_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR23_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR23_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR24_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR24_MST(NOLOCK)
	UNION ALL	
	SELECT 'ATTR25_MST' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  ATTR25_MST(NOLOCK)
	UNION ALL	
	SELECT 'LM01106' AS master_name,MAX(last_modified_on) loc_last_modified_on FROM  lm01106(NOLOCK)
	) a


	select master_name,convert(varchar,loc_last_modified_on,113) loc_last_modified_on from  #tmpmst
END