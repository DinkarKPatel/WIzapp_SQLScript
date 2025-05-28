CREATE PROCEDURE SP3S_Get_Purchase_Tcs_baseAmount
(
 @CsourceGstNo varchar(20)='',
 @CtargetGstNo varchar(20)='',
 @cfinyear varchar(5)='',
 @DINVDT datetime='',
 @bCalledFromVchEntry BIT=0,
 @cac_code varchar(10)='',
 @CMRR_ID VARCHAR(50)=''--IN CASE OF EDIT MODE pass inv_id 
)
AS
BEGIN
    

	DECLARE @CPARTYPANNOFILTER VARCHAR(1000),@DTSQL nvarchar(max),@Caccode_filter varchar(100)
	set @Caccode_filter=''

	
	IF @bCalledFromVchEntry=0
	begin

	    IF isnull(@CTARGETGSTNO,'')<>''
		   SET @CPARTYPANNOFILTER=' AND SUBSTRING (LM.AC_GST_NO,3,10) ='''+SUBSTRING (@CTARGETGSTNO,3,10)+''' '
		ELSE 
		   SET @CPARTYPANNOFILTER=' AND LM.AC_CODE ='''+@CAC_CODE+''' '


		SET @DTSQL=N'SELECT isnull(SUM(A.Total_amount  ),0) AS TCS_BASEAMOUNT
		FROM pim01106 A (NOLOCK) 
		JOIN LOCATION L (NOLOCK)  ON L.DEPT_ID =A.location_code
		LEFT JOIN LMP01106 LM (NOLOCK) ON A.AC_CODE =LM.AC_CODE 
		WHERE A.CANCELLED =0 
		AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
		AND A.FIN_YEAR ='''+@CFINYEAR+'''
		AND A.Receipt_dt<= '''+CONVERT(VARCHAR(10),@DINVDT,121)+'''
		AND SUBSTRING (L.LOC_GST_NO,3,10)='''+SUBSTRING (@CSOURCEGSTNO,3,10)+'''
		AND ISNULL(A.XN_ITEM_TYPE,0)=1
		and '''+isnull(SUBSTRING (@CSOURCEGSTNO,3,10),'')+'''<>''''
		and a.mrr_id<>'''+@CMRR_ID+''' '+@CPARTYPANNOFILTER
		


	end


	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL
END

