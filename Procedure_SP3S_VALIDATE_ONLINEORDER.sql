create Procedure SP3S_VALIDATE_ONLINEORDER
(
  @NUPDATEMODE INT,
  @CSP_ID VARCHAR(50),
  @corder_id varchar(30)='',
  @CERRORMSG VARCHAR(200) OUTPUT
)
As
BEGIN
     declare @corderid varchar(50)  ,@OnlineOrderStatus VARCHAR(20)

	
	if @NUPDATEMODE=1
	begin

	    if exists (select top 1'u' from WSLORD_BUYER_ORDER_MST_UPLOAD a (nolock)  where a.SP_ID =@CSP_ID and isnull(a.SaleReturnType,0)=0  )
		  begin
		       set @CERRORMSG=' Invalid Sale Return Type  '
			    Return
		  end


		 SELECT @corderid=b.order_id
		 FROM WSLORD_BUYER_ORDER_MST_UPLOAD a WITH (NOLOCK)
		 JOIN BUYER_ORDER_MST B ON A.Ref_no=B.Ref_no and   A.SaleReturnType=B.SaleReturnType
		 where a.SP_ID =@CSP_ID and b.CANCELLED =0

		 if ISNULL (@corderid,'')<>'' 
		 begin
			    set @CERRORMSG=' Order already Generated '
			    Return

		 end 
    
	end

	if @NUPDATEMODE in(2,3)
	begin

	   SELECT @OnlineOrderStatus=OnlineOrderStatus FROM BUYER_ORDER_MST (NOLOCK) WHERE order_id  =@CORDER_ID
	   
	   if @OnlineOrderStatus<>''
	   begin
		     declare @ctext varchar(20)
			 set @ctext=''
			 set @ctext=case when @NUPDATEMODE=3 then 'cancelled' else 'overwrite' end
		     set @CERRORMSG='Order processed,you can not '+@ctext
			 Return
	   end

	END


   IF @NUPDATEMODE IN(1,2)
	BEGIN
	     

		 IF EXISTS (SELECT TOP 1'U' FROM  WSLORD_BUYER_ORDER_MST_UPLOAD A (NOLOCK) 
		 LEFT OUTER JOIN gst_state_mst B ON A.SHIPPING_GST_STATE_CODE=B.gst_state_code
		 WHERE A.SP_ID =@CSP_ID AND B.gst_state_name IS NULL)
		 BEGIN
		      
			   SET @CERRORMSG='INVALID GSTSTATE PLEASE CHECK IN GSTSTATE MASTER'
		       RETURN
		 END
		 
		  IF EXISTS (SELECT TOP 1'U' FROM  WSLORD_BUYER_ORDER_det_UPLOAD A (NOLOCK) 
		   JOIN sku B (nolock) ON A.product_code =B.product_code
		 WHERE A.SP_ID =@CSP_ID AND ISNULL(b.product_code,'')<>'' and ABS(a.ws_price )>b.mrp  )
		 BEGIN
		      
			   SET @CERRORMSG='Item rate can not be greater than Retail Price'
		       RETURN 
		 END

	END



	


END

