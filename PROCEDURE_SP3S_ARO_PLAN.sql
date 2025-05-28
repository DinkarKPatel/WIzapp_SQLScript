CREATE PROCEDURE SP3S_ARO_PLAN
@nQueryId NUMERIC(2,0),
@cWhere VARCHAR(500)=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cCollist VARCHAR(1000)

	IF @nQueryId=1
		goto lblMst
	else
	IF @nQueryId=2
		goto lblDet
	else
	IF @nQueryId=3
		goto lblLocLink
	else
	IF @nQueryId=4
	BEGIN
		IF @cWhere<>''
			goto lblCols
		else
			goto lblColList
	END
	else
		goto lbllast

lblMst:
	select * from aro_plan_mst where plan_id=@cWhere
	goto lblLast
lblDet:
	select @cCollist = coalesce(@cColList+',','')+'a.'+column_name from CONFIG_BUYERORDER (NOLOCK)
	WHERE ISNULL(open_key,0)=1 and column_name<>'PRODUCT_CODE'

	DECLARE @cAddJoin VARCHAR(MAX),@cAddCols VARCHAR(MAX)

	SELECT @cAddJoin = ' JOIN article art (NOLOCK) ON art.article_no=a.article_no
						 JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
						 JOIN  sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
						 JOIN article_fix_attr af (NOLOCK) ON af.article_code=art.article_code '

	SELECT @cAddJoin=@cAddJoin+
	' JOIN  '+table_name+' ON '+table_name+'.'+replace(column_name,'_name','_code')+'=af.'+replace(column_name,'_name','_code')
	FROM config_attr WHERE table_caption<>''	
	
	SELECT @cAddCols=',sm.section_name,sd.sub_section_name'
	SELECT @cAddCols=@cAddCols+','+table_name+'.'+column_name+' as ['+table_caption+']'
	FROM config_attr WHERE table_caption<>''	
	
	SET @cCmd=N'select plan_id,dept_id,row_id,'+@cColList+@cAddCols+',sale_qty,growth_factor,safety_level,mbq,target_plan_sale,
				target_daily_sale,min_stock_days,reorder_stock_days,max_stock_days,suggested_plan_stock,
				min_plan_stock,target_plan_stock,max_plan_stock from aro_plan_det a '+@cAddJoin+'
				where plan_id='''+@cWhere+'''
				ORDER BY dept_id,'+@cColList
	EXEC SP_EXECUTESQL @cCmd
	goto lblLast
lblCols:
	select * from CONFIG_BUYERORDER (NOLOCK) WHERE ISNULL(open_key,0)=1
	 and column_name<>'PRODUCT_CODE'
	goto lblLast

lblLocLink:
	IF @cWhere<>''
		select a.*,dept_name,area_name,city,state,convert(numeric(5,0),0) as min_stock_days,
		convert(numeric(5,0),0) as max_stock_days,convert(numeric(5,0),0) as reorder_stock_days,
		b.GROWTH_FACTOR,b.SAFETY_FACTOR
		from aro_plan_link_loc a join loc_view b on a.dept_id=b.dept_id
		where plan_id=@cWhere
	ELSE
		SELECT convert(bit,0) as chk, dept_id,dept_name,area_name,city,state,convert(char(10),'LATER') as plan_id,
		convert(numeric(5,0),0) as min_stock_days,
		convert(numeric(5,0),0) as max_stock_days,convert(numeric(5,0),0) as reorder_stock_days,
		GROWTH_FACTOR,SAFETY_FACTOR
		from loc_view where inactive=0

	goto lblLast

lblColList:
	DECLARE @CPARA1 VARCHAR(50),@CPARA2 VARCHAR(50),@CPARA3 VARCHAR(50),@CPARA4 VARCHAR(50)  ,
	@CPARA5 VARCHAR(50),@CPARA6 VARCHAR(50)

	SELECT @CPARA1=ISNULL(VALUE,'PARA1')   
	FROM  CONFIG  
	WHERE CONFIG_OPTION='PARA1_caption' 
		  
	SELECT @CPARA2=ISNULL(VALUE,'PARA2')   
	FROM CONFIG  
	WHERE  CONFIG_OPTION='PARA2_caption' 
		  
	SELECT @CPARA3=ISNULL(VALUE,'PARA3')   
	FROM CONFIG  
	WHERE  CONFIG_OPTION='PARA3_caption'
		  
	SELECT @CPARA4=ISNULL(VALUE,'PARA4')   
	FROM CONFIG  
	WHERE  CONFIG_OPTION='PARA4_caption'
		  
	SELECT @CPARA5=ISNULL(VALUE,'PARA5')   
	FROM CONFIG  
	WHERE  CONFIG_OPTION='PARA5_caption'
		  
	SELECT @CPARA6=ISNULL(VALUE,'PARA6')   
	FROM CONFIG  
	WHERE  CONFIG_OPTION='PARA6_caption'


	SELECT 'SECTION NAME' AS COL_HEADER,'SECTION_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT 'SUB SECTION NAME' AS COL_HEADER,'SUB_SECTION_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT 'ARTICLE NO' AS COL_HEADER,'ARTICLE_NO' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT (CASE WHEN ISNULL(@CPARA1,'')='' THEN 'PARA1' ELSE @CPARA1 END) AS COL_HEADER,'PARA1_NAME' AS col_value,convert(bit,0) as chk   
	UNION ALL    
	SELECT (CASE WHEN ISNULL(@CPARA2,'')='' THEN 'PARA2' ELSE @CPARA2 END) AS COL_HEADER,'PARA2_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT (CASE WHEN ISNULL(@CPARA3,'')='' THEN 'PARA3' ELSE @CPARA3 END) AS COL_HEADER,'PARA3_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT (CASE WHEN ISNULL(@CPARA4,'')='' THEN 'PARA4' ELSE @CPARA4 END) AS COL_HEADER,'PARA4_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT (CASE WHEN ISNULL(@CPARA5,'')='' THEN 'PARA5' ELSE @CPARA5 END) AS COL_HEADER,'PARA5_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL    
	SELECT (CASE WHEN ISNULL(@CPARA6,'')='' THEN 'PARA6' ELSE @CPARA6 END) AS COL_HEADER,'PARA6_NAME' AS col_value,convert(bit,0) as chk    
	UNION ALL
	SELECT 'ARTICLE NAME' AS COL_HEADER,'ARTICLE_NAME' AS col_value,convert(bit,0) as chk 
	UNION ALL    
	SELECT TABLE_CAPTION  AS COL_HEADER,column_name AS col_value,convert(bit,0) as chk FROM  CONFIG_ATTR  where TABLE_CAPTION <> '' 		  

lblLast:
	
END