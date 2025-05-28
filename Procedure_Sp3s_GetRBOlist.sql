create Procedure Sp3s_GetRBOlist
(
  @nmode int =0 --0 for all and 1 for Pending list
)
as
Begin
     
	 --Procedure Return data Pending Orderid or all for 00material Consuption

	 IF @NMODE=0
	 BEGIN
	      
		  SELECT cast(0 as bit) as chk, A.ORDER_NO ,A.ORDER_DT ,A.ORDER_ID ,a.Ref_no,
		         cust.user_customer_code,isnull(cust.customer_fname,'') +' '+isnull(cust.customer_lname,'') as CustomerName,
				 a.Delivery_DT ,a.Trail_dt
		  FROM WSL_ORDER_MST A
		  join custdym cust   (nolock) on a.customer_code=cust.customer_code
		  WHERE A.CANCELLED =0 
		  ORDER BY A.ORDER_DT  ,A.ORDER_NO 

	 END
	 ELSE IF  @NMODE=1
	 BEGIN
	       ;with cte as
		   (
		    SELECT A.ORDER_ID,B.PRODUCT_CODE,A.CUSTOMER_CODE,B.order_type ,
			       REF_PRODUCT_CODE,a.order_no ,a.order_dt ,a.Ref_no,a.Delivery_DT ,a.Trail_dt   
			FROM WSL_ORDER_MST A (NOLOCK)
			JOIN WSL_ORDER_DET B (NOLOCK) ON A.order_id =B.order_id 
			LEFT JOIN 
			(
			  SELECT A.PRODUCT_CODE ,B.CUSTOMER_CODE  
			  FROM cmd01106 A (NOLOCK)
			  JOIN cmm01106 B (NOLOCK) ON A.CM_ID =B.CM_ID
			  WHERE B.CANCELLED =0  
			) C ON C.PRODUCT_CODE=(CASE WHEN A.ORDER_TYPE=1 THEN b.REF_PRODUCT_CODE ELSE b.PRODUCT_CODE END)
		     AND c.CUSTOMER_CODE=a.CUSTOMER_CODE and c.PRODUCT_CODE is null
			WHERE A.CANCELLED =0 AND ISNULL(B.CANCELLED ,0)=0
			)

		  SELECT cast(0 as bit) as chk, A.ORDER_NO ,A.ORDER_DT ,A.ORDER_ID   ,a.Ref_no ,
		          cust.user_customer_code,isnull(cust.customer_fname,'') +' '+isnull(cust.customer_lname,'') as CustomerName,
				  a.Delivery_DT ,a.Trail_dt
		  FROM cte A
		  join custdym cust   (nolock) on a.customer_code=cust.customer_code
		  group by A.ORDER_NO ,A.ORDER_DT ,A.ORDER_ID ,a.Ref_no ,
		   cust.user_customer_code,isnull(cust.customer_fname,'') +' '+isnull(cust.customer_lname,''),
				  a.Delivery_DT ,a.Trail_dt
		  ORDER BY A.ORDER_DT  ,A.ORDER_NO 

		  
	 END

end