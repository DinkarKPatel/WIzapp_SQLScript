CREATE PROCEDURE SP3S_ONLINEORDERBOOKING  
(  
 @NQUERYID INT   ,   
 @CWHERE VARCHAR(100)  
)  
AS     
BEGIN    
  
 IF @NQUERYID=1    
 BEGIN    
  SELECT TOP 1 name FROM TEMPDB.SYS.TABLES(nolock) WHERE NAME LIKE '##'+DB_NAME()+'_TMP_LOGIN%'  
  ORDER BY NEWID()    
 END  
  
 ELSE IF @NQUERYID=2    
 BEGIN   
        
   ;with Cte_Deleverd as   
   (  
   SELECT A.REF_ORDER_ID   
   FROM CMD01106 A (NOLOCK)  
   JOIN CMM01106 B (NOLOCK) ON A.CM_ID =B.CM_ID   
   where b.CANCELLED =0 and  isnull(A.REF_ORDER_ID,'')<>''  
   GROUP BY A.REF_ORDER_ID  
   )  
  
  select top 1 ac_name,dept_id, order_no,order_dt,order_id,ref_no ,  
  (case when a.SaleReturnType = 2 THEN 'Return' else ' Sale' end) as  order_type  
  from  buyer_order_mst a (nolock)   
  join lm01106 b (nolock) on a.ac_code= b.ac_code  
  left join Cte_Deleverd c on a.order_id =c.REF_ORDER_ID   
  where mode=3 and isnull(viewonlineorder,0)=0  and cancelled=0  and c.REF_ORDER_ID is null  
  and WBO_FOR_DEPT_ID = @CWHERE  order by order_dt,order_no  
  
  
 END  
  
 ELSE IF @NQUERYID=3    
 BEGIN   
 select k.section_name, j.sub_section_name,c.article_no,d.para1_name ,e.para2_name ,f.para3_name,g.para4_name ,  
  h.para5_name ,i.para6_name,l.PARA7_NAME  , b.quantity as order_qty ,SKU.article_code,SKU.para1_code,SKU.para2_code,  
  SKU.para3_code,SKU.para4_code,SKU.para5_code,SKU.para6_code,l.PARA7_CODE ,b.row_id   
  from  buyer_order_mst a (nolock)   
  join buyer_order_det b (nolock) on a.order_id= b.order_id  
  join para7 l on b.para7_code= l.para7_code   
  JOIN SKU ON SKU.PARA7_code=l.PARA7_CODE
  join article c on SKU.article_code= c.article_code  
  left outer join para1 d on SKU.para1_code= d.para1_code   
  left outer join para2 e on SKU.para2_code= e.para2_code   
  left outer join para3 f on SKU.para3_code= f.para3_code   
  left outer join para4 g on SKU.para4_code= g.para4_code   
  left outer join para5 h on SKU.para5_code= h.para5_code   
  left outer join para6 i on SKU.para6_code= i.para6_code   
  join sectiond j on c.sub_section_code = j.sub_section_code   
  join sectionm k on j.section_code = k.section_code   
  --left outer join para7 l on b.para7_code= l.para7_code     
  where a.order_id= @CWHERE  
  --select k.section_name, j.sub_section_name,c.article_no,d.para1_name ,e.para2_name ,f.para3_name,g.para4_name ,  
  --h.para5_name ,i.para6_name,l.PARA7_NAME  , b.quantity as order_qty ,b.article_code,b.para1_code,b.para2_code,  
  --b.para3_code,b.para4_code,b.para5_code,b.para6_code,l.PARA7_CODE ,b.row_id   
  --from  buyer_order_mst a (nolock)   
  --join buyer_order_det b (nolock) on a.order_id= b.order_id  
  --join article c on b.article_code= c.article_code  
  --left outer join para1 d on b.para1_code= d.para1_code   
  --left outer join para2 e on b.para2_code= e.para2_code   
  --left outer join para3 f on b.para3_code= f.para3_code   
  --left outer join para4 g on b.para4_code= g.para4_code   
  --left outer join para5 h on b.para5_code= h.para5_code   
  --left outer join para6 i on b.para6_code= i.para6_code   
  --join sectiond j on c.sub_section_code = j.sub_section_code   
  --join sectionm k on j.section_code = k.section_code   
  --left outer join para7 l on b.para7_code= l.para7_code   
  --where a.order_id= @CWHERE  
 END  
  
  
    ELSE IF @NQUERYID=4    
 BEGIN   
 Update  buyer_order_mst Set viewonlineorder=1 , OnlineOrderStatus = 'ACCEPTED' Where order_id= @CWHERE  
 END  
  
  
 ELSE IF @NQUERYID=5    
 BEGIN   
      declare @CERRMSG varchar(100)  
   exec sp3s_OnlineOrder_Stock @CWHERE,@CERRMSG output   
  
     
  --select   cast(0 as bit) as CHK,a.product_code, quantity_in_stock,c.row_id   
  --From  pmt01106   a  
  --join sku b on a.product_code = b.product_code   
  --join buyer_order_det c on b.article_code = c.article_code  and b.para1_code = c.para1_code    
  --and b.para2_code = c.para2_code  and b.para3_code = c.para3_code   
  --where  c.order_id = @CWHERE and  a.quantity_in_stock>0  
 END  
  
END  
  
/*
Rohit : 26-05-2025 kvs : 16:04:04
METTLE APPARELS - FYND ORDER -  BARCODE 8909252089073 ONLINE ORDER KE CASE MAIN BLANK DETAILS AA RAHI HAIN IN CASH MEMO ORDER LINK  
LOCATION ID -6Y  
ULTRA 68 852 034 - 47477  
MOB-8580400292 

CREATE PROCEDURE SP3S_ONLINEORDERBOOKING
(
	@NQUERYID INT   , 
	@CWHERE VARCHAR(100)
)
AS   
BEGIN  

	IF @NQUERYID=1  
	BEGIN 	
		SELECT TOP 1 name FROM TEMPDB.SYS.TABLES(nolock) WHERE NAME LIKE '##'+DB_NAME()+'_TMP_LOGIN%'
		ORDER BY NEWID()  
	END

	ELSE IF @NQUERYID=2  
	BEGIN 
	     
		 ;with Cte_Deleverd as 
		 (
		 SELECT A.REF_ORDER_ID 
		 FROM CMD01106 A (NOLOCK)
		 JOIN CMM01106 B (NOLOCK) ON A.CM_ID =B.CM_ID 
		 where b.CANCELLED =0 and  isnull(A.REF_ORDER_ID,'')<>''
		 GROUP BY A.REF_ORDER_ID
		 )

		select top 1 ac_name,dept_id, order_no,order_dt,order_id,ref_no ,
		(case when a.SaleReturnType = 2 THEN 'Return' else ' Sale' end) as  order_type
		from  buyer_order_mst a (nolock) 
		join lm01106 b (nolock) on a.ac_code= b.ac_code
		left join Cte_Deleverd c on a.order_id =c.REF_ORDER_ID 
		where mode=3 and isnull(viewonlineorder,0)=0  and cancelled=0  and c.REF_ORDER_ID is null
		and WBO_FOR_DEPT_ID = @CWHERE  order by order_dt,order_no


	END

	ELSE IF @NQUERYID=3  
	BEGIN 
		select k.section_name, j.sub_section_name,c.article_no,d.para1_name ,e.para2_name ,f.para3_name,g.para4_name ,
		h.para5_name ,i.para6_name,l.PARA7_NAME  , b.quantity as order_qty ,b.article_code,b.para1_code,b.para2_code,
		b.para3_code,b.para4_code,b.para5_code,b.para6_code,l.PARA7_CODE ,b.row_id 
		from  buyer_order_mst a (nolock) 
		join buyer_order_det b (nolock) on a.order_id= b.order_id
		join article c on b.article_code= c.article_code
		left outer join para1 d on b.para1_code= d.para1_code 
		left outer join para2 e on b.para2_code= e.para2_code 
		left outer join para3 f on b.para3_code= f.para3_code 
		left outer join para4 g on b.para4_code= g.para4_code 
		left outer join para5 h on b.para5_code= h.para5_code 
		left outer join para6 i on b.para6_code= i.para6_code 
		join sectiond j on c.sub_section_code = j.sub_section_code 
		join sectionm k on j.section_code = k.section_code 
		left outer join para7 l on b.para7_code= l.para7_code 
		where a.order_id= @CWHERE
	END


    ELSE IF @NQUERYID=4  
	BEGIN 
	Update  buyer_order_mst Set viewonlineorder=1 , OnlineOrderStatus = 'ACCEPTED' Where order_id= @CWHERE
	END


 ELSE IF @NQUERYID=5  
	BEGIN 
	     declare @CERRMSG varchar(100)
		 exec sp3s_OnlineOrder_Stock @CWHERE,@CERRMSG output 

		 
		--select   cast(0 as bit) as CHK,a.product_code, quantity_in_stock,c.row_id 
		--From  pmt01106   a
		--join sku b on a.product_code = b.product_code 
		--join buyer_order_det c on b.article_code = c.article_code  and b.para1_code = c.para1_code  
		--and b.para2_code = c.para2_code  and b.para3_code = c.para3_code 
		--where  c.order_id = @CWHERE and  a.quantity_in_stock>0
	END

END





*/