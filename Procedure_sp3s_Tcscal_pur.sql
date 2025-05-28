
CREATE Procedure sp3s_Tcscal_pur
(
  @CXNTYPE VARCHAR(10)='Pur',
  @CLOCID varchar(5)='',
  @NTAXABLEVALUE NUMERIC(18,2)=0,
  @NPARTY_AMOUNT_FORTCS NUMERIC(18,2)=0,
  @CERRORMSG VARCHAR(max) OUTPUT  ,
  @ninvmode int=1
)
as
begin
   DECLARE @CSTEP VARCHAR(10),@CSOURCEPANNO VARCHAR(10),@CPARTYPANNO VARCHAR(10),@dinv_dt datetime,
           @nTcs_Cutoff_Limit numeric(18,2),@NTcsRate_Without_PanNo NUMERIC(10,3),
		   @NTcsRate_With_PanNo NUMERIC(10,3),
		   @NTCSCALC_AMOUNT numeric(18,2),
		   @NOHTAXABLEVALUE numeric(10,2)
   set @CERRORMSG=''
   BEGIN TRY 
         
		 IF ISNULL(@CLOCID,'')=''
		 BEGIN
			set @CERRORMSG=' Source Location can Not be blank for Tcs calculation'
			goto end_proc
		END
			
			

		 SELECT @CSOURCEPANNO=substring(loc_gst_no,3,10)  FROM location WHERE DEPT_ID =@CLOCID


		     
			SELECT @CPARTYPANNO=  SUBSTRING(B.Ac_gst_no,3,10) ,
				   @dinv_dt=a.receipt_dt 
			FROM #TMSTTABLE A
			LEFT JOIN LMP01106 B (NOLOCK) ON A.AC_CODE=B.AC_CODE 
	       
		

         SELECT TOP 1 @nTcs_Cutoff_Limit= Tcs_Cutoff_Limit,
		              @NTcsRate_Without_PanNo= TcsRate_Without_PanNo,
					  @NTcsRate_With_PanNo=TcsRate_With_PanNo
		 FROM TCS_MST WHERE WEF<=@DINV_DT AND ISNULL(TCS_TYPE,0)=CASE WHEN @CXNTYPE='WSL' THEN 0 ELSE 1 END
		 ORDER BY WEF DESC
		
		  
		
		

		 IF ((ISNULL(@NPARTY_AMOUNT_FORTCS,0)+ISNULL(@NTAXABLEVALUE,0))>ISNULL(@nTcs_Cutoff_Limit,0) and ISNULL(@nTcs_Cutoff_Limit,0)<>0
		    AND ISNULL(@CSOURCEPANNO,0)<>ISNULL(@CPARTYPANNO,0) and isnull(@CSOURCEPANNO,'')<>'' AND ISNULL(@CPARTYPANNO,'')<>'')
		 BEGIN
		   
			   	SET @NTCSCALC_AMOUNT=@NTAXABLEVALUE

	
				  UPDATE #TMSTTABLE SET GOODS_TDS_BASEAMOUNT=@NTCSCALC_AMOUNT,
				  GOODS_TDS_PERCENTAGE=CASE WHEN ISNULL(@CPARTYPANNO,'')='' THEN @NTCSRATE_WITHOUT_PANNO ELSE @NTCSRATE_WITH_PANNO END

			      UPDATE #TMSTTABLE SET GOODS_TDS_AMOUNT=(GOODS_TDS_BASEAMOUNT*GOODS_TDS_PERCENTAGE/100)

			

				
		END
		else
		begin

		    UPDATE #TMSTTABLE SET GOODS_TDS_BASEAMOUNT=0,GOODS_TDS_PERCENTAGE=0,GOODS_TDS_AMOUNT=0
		   
		end
		
	

  END TRY  
  BEGIN CATCH
  print 'enter catch of sp3s_Tcscal_pur'
  SELECT @CERRORMSG='ERROR MESSAGE IN PROCEDURE sp3s_Tcscal_pur STEP#'+@CSTEP+' '+CAST(ERROR_MESSAGE() AS VARCHAR(1000))
  END CATCH  

  END_PROC:  

end
