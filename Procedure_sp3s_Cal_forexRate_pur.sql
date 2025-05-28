create Procedure sp3s_Cal_forexRate_pur
(
 @csp_id varchar(50)='',
 @CERRORMSG VARCHAR(1000) OUTPUT  
)
as
begin
    

	  BEGIN TRY 
	     
		UPDATE a SET 
			       Forex_igst_amount =(FOREX_XN_VALUE_WITHOUT_GST*gst_percentage /100)
		FROM PUR_PID01106_UPLOAD a WITH (NOLOCK)
		WHERE A.SP_ID=@CSP_ID


		update a set Forex_subtotal=b.FC_Net,
		Forex_total_amount=round(FC_Net-Forex_Discount_amount +isnull(Forex_OTHER_CHARGES_TAXABLE_VALUE,0)+isnull(Forex_FREIGHT_TAXABLE_VALUE,2),2)
		FROM PUR_PIm01106_UPLOAD a WITH (NOLOCK)
		join
		(
		  select sp_id, SUM(FC_NET) As FC_Net
		  from PUR_pid01106_UPLOAD a WITH (NOLOCK)
		  WHERE A.SP_ID=@CSP_ID
		  group by sp_id
		) b on a.sp_id=b.sp_id 
		WHERE A.SP_ID=@CSP_ID


	  End Try
	  Begin catch
	  print 'enter catch of sp3s_Cal_forexRate_pur'
      SELECT @CERRORMSG='ERROR MESSAGE IN PROCEDURE sp3s_Cal_forexRate_pur'+CAST(ERROR_MESSAGE() AS VARCHAR(1000))
	  end catch

	  end_proc:

end