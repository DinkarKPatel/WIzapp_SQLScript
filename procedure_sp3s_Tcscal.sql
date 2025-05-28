
create Procedure sp3s_Tcscal
(
  @CXNTYPE VARCHAR(10)='WSL',
  @CLOCID varchar(5)='',
  @NTAXABLEVALUE NUMERIC(18,2)=0,
  @NPARTY_AMOUNT_FORTCS NUMERIC(18,2)=0,
  @CERRORMSG VARCHAR(max) OUTPUT  
)
as
begin
   DECLARE @CSTEP VARCHAR(10),@CSOURCEPANNO VARCHAR(10),@CPARTYPANNO VARCHAR(10),@dinv_dt datetime,
           @nTcs_Cutoff_Limit numeric(18,2),@NTcsRate_Without_PanNo NUMERIC(10,3),
		   @NTcsRate_With_PanNo NUMERIC(10,3),@NTCSCALC_AMOUNT numeric(18,2),@NOHTAXABLEVALUE numeric(10,2),
		   @bSCRAP_SALE bit
   set @CERRORMSG=''
   BEGIN TRY 
         
		 IF ISNULL(@CLOCID,'')=''
		 BEGIN
			set @CERRORMSG=' Source Location can Not be blank for Tcs calculation'
			goto end_proc
		END
				

		 SELECT @CSOURCEPANNO=substring(loc_gst_no,3,10)  FROM location WHERE DEPT_ID =@CLOCID

		 SELECT @CPARTYPANNO=CASE WHEN A.INV_MODE=1 THEN  SUBSTRING(B.Ac_gst_no,3,10) ELSE SUBSTRING(L.LOC_GST_NO,3,10) END ,
		       @dinv_dt=a.inv_dt ,
		       @bSCRAP_SALE=a.SCRAP_SALE
		FROM #TMSTTABLE A
		LEFT JOIN LMP01106 B (NOLOCK) ON A.AC_CODE=B.AC_CODE 
		LEFT JOIN LOCATION L (NOLOCK) ON A.PARTY_DEPT_ID =L.DEPT_ID 
		
	

         SELECT TOP 1 @nTcs_Cutoff_Limit= Tcs_Cutoff_Limit,
		              @NTcsRate_Without_PanNo= TcsRate_Without_PanNo,
					  @NTcsRate_With_PanNo=TcsRate_With_PanNo
		 FROM TCS_MST WHERE WEF<=@DINV_DT
		 ORDER BY WEF DESC


		 if isnull(@bSCRAP_SALE,0)=1
		    set @nTcs_Cutoff_Limit=1


		 IF ((ISNULL(@NPARTY_AMOUNT_FORTCS,0)+ISNULL(@NTAXABLEVALUE,0))>ISNULL(@nTcs_Cutoff_Limit,0) and ISNULL(@nTcs_Cutoff_Limit,0)<>0
		    AND ISNULL(@CSOURCEPANNO,0)<>ISNULL(@CPARTYPANNO,0) and isnull(@CSOURCEPANNO,'')<>'')
		 BEGIN
		   
		       --SET @NTCSCALC_AMOUNT=CASE WHEN ISNULL(@NPARTY_AMOUNT_FORTCS,0)>=ISNULL( @NTCS_CUTOFF_LIMIT,0) THEN @NTAXABLEVALUE
			      --                  ELSE (ISNULL(@NPARTY_AMOUNT_FORTCS,0)+ISNULL(@NTAXABLEVALUE,0))-ISNULL(@NTCS_CUTOFF_LIMIT,0) END
				SET @NTCSCALC_AMOUNT=@NTAXABLEVALUE

				UPDATE #TMSTTABLE SET TCS_baseAmount=@NTCSCALC_AMOUNT,
				TCS_PERCENtAgE=CASE WHEN ISNULL(@CPARTYPANNO,'')='' THEN @NTCSRATE_WITHOUT_PANNO ELSE @NTCSRATE_WITH_PANNO END
			    UPDATE #TMSTTABLE SET TCS_amount=ceiling(TCS_baseAmount*tcs_percentage/100)
		END
		else
		begin
		    UPDATE #TMSTTABLE SET TCS_baseAmount=0,TCS_PERCENtAgE=0,TCS_amount=0
		end
		
	

  END TRY  
  BEGIN CATCH
  print 'enter catch of sp3s_Tcscal'
  SELECT @CERRORMSG='ERROR MESSAGE IN PROCEDURE sp3s_Tcscal STEP#'+@CSTEP+' '+CAST(ERROR_MESSAGE() AS VARCHAR(1000))
  END CATCH  

  END_PROC:  

end
