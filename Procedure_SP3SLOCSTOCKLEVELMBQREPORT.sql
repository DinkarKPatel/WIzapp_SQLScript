create PROCEDURE SP3SLOCSTOCKLEVELMBQREPORT  
(  
  @layOutcolumn varchar(max),  
  @calcolumn varchar(max),  
  @dFromDt Datetime,  
  @dToDt Datetime  
)  
  
AS  
BEGIN  
    
	 DECLARE @CCMD NVARCHAR(MAX),@SHOW_PARA1 BIT,@SHOW_PARA2 BIT,@SHOW_PARA3 BIT,@SHOW_PRODUCT BIT,@cjoin varchar(max),
	         @SHOW_PARA4 BIT,@SHOW_PARA5 BIT,@SHOW_PARA6 BIT

	 select @SHOW_PARA1=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PARA1_NAME'
	 select @SHOW_PARA2=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PARA2_NAME'
	 select @SHOW_PARA3=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PARA3_NAME'
	 select @SHOW_PARA4=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PARA4_NAME'
	 select @SHOW_PARA5=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PARA5_NAME'
	 select @SHOW_PARA6=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PARA6_NAME'
	 
	 select @SHOW_PRODUCT=OPEN_KEY  from CONFIG_BUYERORDER where COLUMN_NAME ='PRODUCT_CODE'
     
	

	 Select a.TITLE_NAME ,a.target_dept_id,location_code ,a.Applicable_From_Dt , a.Applicable_To_Dt , 
	        c.ARTICLE_CODE,art.article_no as stk_articleNo, para1_name ,para2_name ,para3_name,para4_name ,para5_name ,para6_name  ,product_code,
			STOCK_LEVEL_QTY ,cast(0 as numeric(14,3)) as NSQ, cast(0 as numeric(14,3)) as CBS ,c.ROW_ID  ,l.dept_name as Target_dept_name 
	 into #tmpStockLevel
	 from  LOC_STOCK_LEVEL_MST a   
	 join LOC_STOCK_LEVEL c on a.MEMO_ID = c.MEMO_ID   
	 join article art (nolock) on c.ARTICLE_CODE =art.article_code 
	 Join para1 P1 (nolock) on P1.para1_code =c.PARA1_CODE 
	 Join para2 P2 (nolock) on P2.para2_code =c.PARA2_CODE 
	 Join para3 P3 (nolock) on P3.para3_code =c.PARA3_CODE 
	 Join para4 P4 (nolock) on P4.para4_code =c.PARA4_CODE 
	 Join para5 P5 (nolock) on P5.para5_code =c.para5_code 
	 Join para6 P6 (nolock) on P6.para6_code =c.PARA6_CODE 
	 join location l (nolock) on a.target_dept_id =l.dept_id 
	 where  a.MEMO_DT  between @dFromDt and @dToDt  

	 if isnull(@SHOW_PRODUCT,0)=1
	 begin

		 Update A set CBS=b.quantity_in_stock 
		 from #tmpStockLevel A
		 join pmt01106 b (nolock) on A.product_code =b.product_code and A.target_dept_id =b.DEPT_ID 

		 ;with cte_sls as 
		 (
		 select a.target_dept_id, A.product_code ,SUM( b.Quantity) as SLSQTY
		 from #tmpStockLevel A
		 join cmd01106 b on A.product_code =b.PRODUCT_CODE 
		 join cmm01106 c on b.cm_id =c.cm_id and A.target_dept_id = c.location_Code 
		 where c.CANCELLED =0
		 group by a.target_dept_id, A.product_code
		 )

		 Update A set NSQ=b.SLSQTY
		 from #tmpStockLevel A
		 join cte_sls b on A.target_dept_id =b.target_dept_id and A.product_code =b.product_code 

	 end
	 else
	 begin
	       IF ISNULL(@SHOW_PARA1,0)=1
		      SET @CJOIN=' AND A.PARA1_NAME=B.PARA1_NAME '
		   
		   IF ISNULL(@SHOW_PARA2,0)=1
		      SET @CJOIN=isnull(@CJOIN,'')+' AND A.PARA2_NAME=B.PARA2_NAME '

			IF ISNULL(@SHOW_PARA3,0)=1
		      SET @CJOIN=isnull(@CJOIN,'')+' AND A.PARA3_NAME=B.PARA3_NAME '
		      
		     IF ISNULL(@SHOW_PARA4,0)=1
		      SET @CJOIN=isnull(@CJOIN,'')+' AND A.PARA4_NAME=B.PARA4_NAME '
		      
		     IF ISNULL(@SHOW_PARA5,0)=1
		      SET @CJOIN=isnull(@CJOIN,'')+' AND A.PARA5_NAME=B.PARA5_NAME '
            
              IF ISNULL(@SHOW_PARA6,0)=1
		      SET @CJOIN=isnull(@CJOIN,'')+' AND A.PARA6_NAME=B.PARA6_NAME '
	     
	      
		set @CCMD=N';with cte_stock as 
		  (
		    select A.ROW_ID ,SUM(c.quantity_in_stock ) as StockQTY 
			from #tmpStockLevel A
			join sku_names b on A.stk_articleNo=b.article_no 
			'+@CJOIN+'
			join pmt01106 c (nolock) on A.target_dept_id =c.DEPT_ID and b.product_Code =c.product_code 
			group by A.ROW_ID 
		  )
		  Update A set CBS=b.StockQTY 
		  from #tmpStockLevel A
		  join cte_stock b on A.ROW_ID =b.ROW_ID '
		  print @CCMD
		  exec sp_executesql @CCMD


		  set @CCMD=N';with cte_sls as 
		  (
		    select A.ROW_ID ,SUM(c.Quantity ) as SLS_qty 
			from #tmpStockLevel A
			join sku_names b (nolock) on A.stk_articleNo=b.article_no 
			'+@CJOIN+'
			 join cmd01106 c (nolock) on b.product_code =c.PRODUCT_CODE 
		     join cmm01106 d (nolock) on c.cm_id =d.cm_id and A.target_dept_id = d.location_Code 
		     where d.CANCELLED =0
			group by A.ROW_ID 
		  )
		  Update A set NSQ=b.SLS_qty 
		  from #tmpStockLevel A
		  join cte_sls b on A.ROW_ID =b.ROW_ID '
		  print @CCMD
		  exec sp_executesql @CCMD


	 end


 set @CCMD=N'
    SELECT '+ @layOutcolumn +',
	       '+ @calcolumn +'
	         
    FROM #tmpStockLevel A
	LEFT JOIN ART_NAMES (NOLOCK) ON ART_NAMES.ARTICLE_CODE =a.ARTICLE_CODE
	group by '+ @layOutcolumn +'
	'
  print @CCMD
  exec sp_executesql @CCMD


   if OBJECT_ID ('tempdb..#tmpStockLevel','U') is not null
	  drop table #tmpStockLevel
 
  
END  