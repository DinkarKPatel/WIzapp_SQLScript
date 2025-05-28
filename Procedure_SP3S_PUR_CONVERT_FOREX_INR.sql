create Procedure SP3S_PUR_CONVERT_FOREX_INR
(
 @csp_id varchar(50)='',
 @CERRORMSG VARCHAR(1000) OUTPUT  
)
as
begin
    

	  BEGIN TRY 
	    
		
		 declare @ENABLE_MULTI_CURRENCY varchar(10)
	     SELECT TOP 1 @ENABLE_MULTI_CURRENCY=value  FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION ='ENABLE_MULTI_CURRENCY' 

		 if isnull(@ENABLE_MULTI_CURRENCY,'')<>'1'
		 GOTO END_PROC  
        
		IF EXISTS (SELECT TOP 1 'U'  FROM PUR_pim01106_UPLOAD a with (nolock) 
		JOIN LMP01106 LMP WITH (NOLOCK) ON LMP.AC_CODE =A.ac_code 
		where sp_id=@csp_id AND ISNULL(LMP.fc_code,'') IN('','0000000'))
		GOTO END_PROC

	
	
	
	     
		 if exists (select top 1'u' from PUR_pim01106_UPLOAD a with (nolock) where sp_id=@csp_id and  isnull(XN_FC_CODE,'')='')
		 begin
		      SET @CERRORMSG='Invalid Currency Code'
			  goto end_proc
		 end
		 if exists (select top 1'u' from PUR_pim01106_UPLOAD a with (nolock) where sp_id=@csp_id and  isnull(FC_RATE,0)=0)
		 begin
		      SET @CERRORMSG='Invalid Currency Rate'
			  goto end_proc
		 end
		 --if exists (select top 1'u' from PUR_PID01106_UPLOAD a with (nolock) where sp_id=@csp_id and   isnull(Forex_Accessiblevalue,0)+isnull(Forex_CustomdutyAmt,0)=0)
		 --begin
		 --     SET @CERRORMSG='Invalid Forex_Accessiblevalue & CustomdutyAmt'
			--  goto  end_proc
		 --end


		 UPDATE A SET gross_purchase_price = ISNULL(Forex_gross_purchase_price ,0)*B.FC_RATE ,
		              discount_amount = ISNULL(a.Forex_discount_amount  ,0)*B.FC_RATE   ,
					  purchase_price =(ISNULL(Forex_gross_purchase_price ,0)*B.FC_RATE)-
					                  (ISNULL(a.Forex_discount_amount  ,0)/a.quantity )*B.FC_RATE 
		 FROM PUR_PID01106_UPLOAD A WITH (NOLOCK)
		 JOIN PUR_PIM01106_UPLOAD B WITH (NOLOCK) ON A.SP_ID =B.SP_ID 
		 WHERE A.SP_ID=@CSP_ID


		 -- as Per ved ji tax calculat only (FOREX_ACCESSIBLEVALUE+ISNULL(FOREX_CUSTOMDUTYAMT,0)) in taxable value (24102024)

		 UPDATE A SET FOREX_XN_VALUE_WITHOUT_GST= (ISNULL(FOREX_ACCESSIBLEVALUE,0)+ISNULL(Forex_CustomdutyAmt,0)) 
		 FROM PUR_PID01106_UPLOAD A WITH (NOLOCK)
		 JOIN PUR_PIM01106_UPLOAD B WITH (NOLOCK) ON A.SP_ID =B.SP_ID 
		 WHERE A.SP_ID=@CSP_ID

		 UPDATE a SET 
			       Forex_igst_amount =(FOREX_XN_VALUE_WITHOUT_GST*FOREX_GST_PERCENTAGE /100)
		FROM PUR_PID01106_UPLOAD a WITH (NOLOCK)
		WHERE A.SP_ID=@CSP_ID


		UPDATE a SET 
		           OTHER_CHARGES_TAXABLE_VALUE=(Forex_OTHER_CHARGES_TAXABLE_VALUE *FC_RATE ),
				   FREIght_TAXABLE_VALUE=(Forex_FREIght_TAXABLE_VALUE *FC_RATE ),
				   discount_amount =(Forex_Discount_amount *FC_RATE )
		FROM PUR_PIm01106_UPLOAD a 
		WHERE A.SP_ID=@CSP_ID

		
		update a set Forex_subtotal=round(b.Forex_subtotal,2),
		Forex_total_amount=round(b.Forex_subtotal-Forex_Discount_amount +isnull(Forex_OTHER_CHARGES_TAXABLE_VALUE,0)+isnull(Forex_FREIGHT_TAXABLE_VALUE,2),2)
		FROM PUR_PIm01106_UPLOAD a WITH (NOLOCK)
		join
		(
		  select sp_id, SUM(Forex_purchase_price*invoice_quantity) As Forex_subtotal
		  from PUR_pid01106_UPLOAD a WITH (NOLOCK)
		  WHERE A.SP_ID=@CSP_ID
		  group by sp_id
		) b on a.sp_id=b.sp_id 
		WHERE A.SP_ID=@CSP_ID

		update a set 
		Forex_PIMDISCOUNTAMOUNT=ROUND((CASE WHEN B.Forex_subtotal=0 THEN 0 ELSE (B.Forex_DISCOUNT_AMOUNT/B.Forex_SUBTOTAL)*(A.Forex_PURCHASE_PRICE*A.INVOICE_QUANTITY) END),2)
		FROM PUR_pid01106_UPLOAD a WITH (NOLOCK)
		join PUR_pim01106_UPLOAD b  WITH (NOLOCK) on a.sp_id =b.sp_id 
		WHERE A.SP_ID=@CSP_ID

		UPDATE A SET FC_NET =(a.Forex_purchase_price*a.invoice_quantity )-isnull(a.Forex_PIMDISCOUNTAMOUNT,0)
		FROM PUR_PID01106_UPLOAD A WHERE A.SP_ID=@CSP_ID


	  End Try
	  Begin catch
	  print 'enter catch of SP3S_CONVERT_FOREX_INR'
      SELECT @CERRORMSG='ERROR MESSAGE IN PROCEDURE SP3S_CONVERT_FOREX_INR'+CAST(ERROR_MESSAGE() AS VARCHAR(1000))
	  end catch

	  end_proc:

	 

end

