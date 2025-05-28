CREATE PROCEDURE SP3S_GETPARASATTR_CAPTIONS  
(
@cWhere Varchar(50)='',
@cRepType varchar(50)='' ,
@bExep bit=0
)
AS  
BEGIN  
	 SELECT distinct 99 as col_order, col_name,b.value+
	 (CASE WHEN right(a.col_name,5)='ALIAS' THEN ' Alias' WHEN right(a.col_name,3)='Set' THEN ' Set' ELSE '' END) 
	  as col_header,(case when c.key_col is null then cast(0 as bit)  else cast(1 as bit)  end ) as Required,
	  ISNULL(d.base_table_name,'') base_table,d.data_type
	  INTO #tmp
	  FROM transaction_analysis_MASTER_COLS a   
	 JOIN config b (NOLOCK) ON REPLACE(REPLACE(REPLACE(a.col_name,'_name','_caption'),'_alias','_caption'),'_set','_caption') =b.config_option  
	left outer join  rep_det  c on a.col_name = c.key_col  and c .rep_id= @cWhere and c.Calculative_col=0
	JOIN xpert_report_filtercols d ON d.filtercol_name=a.col_expr
	 where left(a.col_name,4)='para' AND b.value<>''   
	 and   isnull(rep_type,'DETAIL')= @cRepType
  
	 UNION ALL  
	 SELECT distinct 99 as col_order,col_name,b.table_caption as col_header,(case when c.key_col is null then cast(0 as bit)  else 
	 cast(1 as bit)  end ) as Required,ISNULL(d.base_table_name,'') base_table,d.data_type
	 FROM transaction_analysis_MASTER_COLS a 
	 JOIN config_attr b (NOLOCK) ON a.col_expr=b.column_name  
	 left outer join  rep_det  c on a.col_name = c.key_col  and c .rep_id= @cWhere and c.Calculative_col=0
	 JOIN xpert_report_filtercols d ON d.filtercol_name=a.col_expr
	 where left(a.col_name,4)='attr' AND b.table_caption<>''  
	 and   isnull(rep_type,'DETAIL')= @cRepType

	 UNION ALL  
	 SELECT distinct 99 as col_order,col_name,b.table_caption as col_header,
	 (case when c.key_col is null then cast(0 as bit)  else  cast(1 as bit)  end ) as Required,
	 'loc_names' base_table,d.data_type
	 FROM transaction_analysis_MASTER_COLS a 
	 JOIN config_locattr b (NOLOCK) ON a.col_expr='loc'+b.column_name  
	 left outer join  rep_det  c on a.col_name = c.key_col  and c .rep_id= @cWhere and c.Calculative_col=0
	 JOIN xpert_report_filtercols d ON d.filtercol_name=a.col_expr
	 where left(a.col_name,7)='locattr' AND b.table_caption<>''  
	 and   isnull(rep_type,'DETAIL')= @cRepType
 
	 UNION ALL  
	 SELECT distinct 99 as col_order,col_name,a.col_header,(case when c.key_col is null then cast(0 as bit)  else cast(1 as bit)  end ) as Required ,
	 ISNULL(d.base_table_name,'') base_table,d.data_type
	 FROM transaction_analysis_MASTER_COLS a 

	 left outer join  rep_det  c on a.col_name = c.key_col  and c .rep_id= @cWhere and c.Calculative_col=0
	 JOIN xpert_report_filtercols d ON d.filtercol_name=a.col_name
	 where left(a.col_name,4) not in('attr','para') AND left(a.col_name,7) not in('locattr') 
	 and   isnull(rep_type,'DETAIL')= @cRepType
  
	 INSERT INTO #tmp (col_order,col_name,col_header,Required,base_table,data_type)
	 SELECT distinct 99 as col_order,a.col_name,a.col_header,(case when c.key_col is null then cast(0 as bit)  else cast(1 as bit)  end ) as Required ,
	 ISNULL(d.base_table_name,'') base_table,d.data_type
	 FROM transaction_analysis_MASTER_COLS a 
	 left outer join  rep_det  c on a.col_name = c.key_col  and c .rep_id= @cWhere and c.Calculative_col=0
	 JOIN xpert_report_filtercols d ON d.filtercol_name=a.col_expr
	 LEFT JOIN #tmp e ON e.col_name=a.col_name
	 where left(a.col_name,4) not in('attr','para') AND left(a.col_name,7) not in('locattr') 
	 AND e.col_name IS NULL and   isnull(rep_type,'DETAIL')= @cRepType
  
	INSERT INTO #tmp (col_order,col_name,col_header,Required,base_table,data_type)
	SELECT 999 col_order,'xn_type' col_name,'Transaction Type' col_header,0 required,'xpert_xntypes' base_table,
	'String' data_type
	

	if @bExep =1 
		select a.* from USER_XTREAM_LAYOUT_SETUP  b
		Right outer join #tmp  a on a.col_name = b.KEY_Col 
		where b.KEY_Col  is null
	else
		SELECT * FROM #tmp ORDER BY col_header

END 
