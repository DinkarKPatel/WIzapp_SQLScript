CREATE Procedure SP3S_CONVERT_FOREX_INR
(
 @csp_id varchar(50)='',
 @CERRORMSG VARCHAR(1000) OUTPUT  
)
as
begin
    

	  BEGIN TRY 
	     
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

		 UPDATE A SET FOREX_XN_VALUE_WITHOUT_GST= (ISNULL(FOREX_ACCESSIBLEVALUE,0)+ISNULL(FOREX_CUSTOMDUTYAMT,0)) 
		 FROM PUR_PID01106_UPLOAD A WITH (NOLOCK)
		 JOIN PUR_PIM01106_UPLOAD B WITH (NOLOCK) ON A.SP_ID =B.SP_ID 
		 WHERE A.SP_ID=@CSP_ID


		UPDATE a SET 
		           OTHER_CHARGES_TAXABLE_VALUE=(Forex_OTHER_CHARGES_TAXABLE_VALUE *FC_RATE ),
				   FREIght_TAXABLE_VALUE=(Forex_FREIght_TAXABLE_VALUE *FC_RATE ),
				   discount_amount =(Forex_Discount_amount *FC_RATE )
		FROM PUR_PIm01106_UPLOAD a 
		WHERE A.SP_ID=@CSP_ID


	  End Try
	  Begin catch
	  print 'enter catch of SP3S_CONVERT_FOREX_INR'
      SELECT @CERRORMSG='ERROR MESSAGE IN PROCEDURE SP3S_CONVERT_FOREX_INR'+CAST(ERROR_MESSAGE() AS VARCHAR(1000))
	  end catch

	  end_proc:

end