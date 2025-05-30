CREATE PROCEDURE SP3S_UPDATE_POSTING_CONFIG
@NMODE NUMERIC(1,0),
@NSPID INT
AS
BEGIN
	DECLARE @CERRORMSG VARCHAR(MAX),@CSTEP VARCHAR(5),@BBLANKACFOUND BIT
	
	SELECT @CERRORMSG='',@BBLANKACFOUND=0

BEGIN TRY	
	
	IF @NMODE=1
	BEGIN
		SET @CSTEP='10'
		
		UPDATE A SET  IGST_REVENUE_AC_CODE=(CASE WHEN B.IGST_REVENUE_AC_CODE NOT IN ('','0000000000') THEN B.IGST_REVENUE_AC_CODE ELSE A.IGST_REVENUE_AC_CODE END),
					  LGST_REVENUE_AC_CODE=(CASE WHEN B.LGST_REVENUE_AC_CODE NOT IN ('','0000000000') THEN B.LGST_REVENUE_AC_CODE ELSE A.LGST_REVENUE_AC_CODE END),
					  IGST_TAX_AC_CODE=(CASE WHEN B.IGST_TAX_AC_CODE NOT IN ('','0000000000') THEN B.IGST_TAX_AC_CODE ELSE A.IGST_TAX_AC_CODE END),
					  SGST_TAX_AC_CODE=(CASE WHEN B.SGST_TAX_AC_CODE NOT IN ('','0000000000') THEN B.SGST_TAX_AC_CODE ELSE A.SGST_TAX_AC_CODE END),
					  CGST_TAX_AC_CODE=(CASE WHEN B.CGST_TAX_AC_CODE NOT IN ('','0000000000') THEN B.CGST_TAX_AC_CODE ELSE A.CGST_TAX_AC_CODE END)
		FROM GST_ACCOUNTS_CONFIG_DET_REVENUE A
		JOIN GST_ACCOUNTS_CONFIG_DET_REVENUE_UPLOAD B ON A.XN_TYPE=B.XN_TYPE AND A.GST_PERCENTAGE=B.GST_PERCENTAGE
		AND A.SECTION_CODE=B.SECTION_CODE AND A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		WHERE B.SP_ID=@NSPID

		SET @CSTEP='20'
		INSERT GST_ACCOUNTS_CONFIG_DET_REVENUE	( XN_TYPE, GST_PERCENTAGE, SECTION_CODE, SUB_SECTION_CODE, 
		IGST_REVENUE_AC_CODE, LGST_REVENUE_AC_CODE, IGST_TAX_AC_CODE, CGST_TAX_AC_CODE, SGST_TAX_AC_CODE )  
		SELECT 	A.XN_TYPE, A.GST_PERCENTAGE, A.SECTION_CODE, A.SUB_SECTION_CODE,A.IGST_REVENUE_AC_CODE, 
		A.LGST_REVENUE_AC_CODE,A.IGST_TAX_AC_CODE,A.CGST_TAX_AC_CODE,A.SGST_TAX_AC_CODE
		FROM GST_ACCOUNTS_CONFIG_DET_REVENUE_UPLOAD A
		LEFT  OUTER JOIN GST_ACCOUNTS_CONFIG_DET_REVENUE B ON A.XN_TYPE=B.XN_TYPE AND A.GST_PERCENTAGE=B.GST_PERCENTAGE
		AND A.SECTION_CODE=B.SECTION_CODE AND A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		WHERE A.SP_ID=@NSPID AND B.GST_PERCENTAGE IS NULL 
		
		IF EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_REVENUE_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND (ISNULL(IGST_REVENUE_AC_CODE,'') IN ('','0000000000') OR
				   ISNULL(LGST_REVENUE_AC_CODE,'')  IN ('','0000000000') OR ISNULL(IGST_TAX_AC_CODE,'') IN ('','0000000000')
				   OR ISNULL(CGST_TAX_AC_CODE,'') IN ('','0000000000') OR ISNULL(SGST_TAX_AC_CODE,'') IN ('','0000000000'))	
				   AND XN_TYPE NOT IN ('CHI_XFR','CHO_XFR'))
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END		

		IF EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_REVENUE_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND ISNULL(LGST_REVENUE_AC_CODE,'')  IN ('','0000000000') 
				   AND XN_TYPE  IN ('CHI_XFR','CHO_XFR'))
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END							   
	END
	
	ELSE 
	IF @NMODE=2
	BEGIN
		SET @CSTEP='30'
		
		UPDATE A SET  IGST_REVENUE_AC_CODE=(CASE WHEN B.IGST_REVENUE_AC_CODE NOT IN ('','0000000000') THEN B.IGST_REVENUE_AC_CODE ELSE A.IGST_REVENUE_AC_CODE END),
					  LGST_REVENUE_AC_CODE=(CASE WHEN B.LGST_REVENUE_AC_CODE NOT IN ('','0000000000') THEN B.LGST_REVENUE_AC_CODE ELSE A.LGST_REVENUE_AC_CODE END),
					  IGST_TAX_AC_CODE=(CASE WHEN B.IGST_TAX_AC_CODE NOT IN ('','0000000000') THEN B.IGST_TAX_AC_CODE ELSE A.IGST_TAX_AC_CODE END),
					  SGST_TAX_AC_CODE=(CASE WHEN B.SGST_TAX_AC_CODE NOT IN ('','0000000000') THEN B.SGST_TAX_AC_CODE ELSE A.SGST_TAX_AC_CODE END),
					  CGST_TAX_AC_CODE=(CASE WHEN B.CGST_TAX_AC_CODE NOT IN ('','0000000000') THEN B.CGST_TAX_AC_CODE ELSE A.CGST_TAX_AC_CODE END)
		FROM GST_ACCOUNTS_CONFIG_DET_OVERHEADS A
		JOIN GST_ACCOUNTS_CONFIG_DET_OVERHEADS_UPLOAD B ON A.XN_TYPE=B.XN_TYPE AND A.GST_PERCENTAGE=B.GST_PERCENTAGE
		WHERE B.SP_ID=@NSPID

		SET @CSTEP='40'
		INSERT GST_ACCOUNTS_CONFIG_DET_OVERHEADS	( XN_TYPE, GST_PERCENTAGE, 
		IGST_REVENUE_AC_CODE, LGST_REVENUE_AC_CODE, IGST_TAX_AC_CODE, CGST_TAX_AC_CODE, SGST_TAX_AC_CODE )  
		SELECT 	A.XN_TYPE, A.GST_PERCENTAGE,A.IGST_REVENUE_AC_CODE, 
		A.LGST_REVENUE_AC_CODE,A.IGST_TAX_AC_CODE,A.CGST_TAX_AC_CODE,A.SGST_TAX_AC_CODE 
		FROM GST_ACCOUNTS_CONFIG_DET_OVERHEADS_UPLOAD A
		LEFT  OUTER JOIN GST_ACCOUNTS_CONFIG_DET_OVERHEADS B ON A.XN_TYPE=B.XN_TYPE AND A.GST_PERCENTAGE=B.GST_PERCENTAGE
		WHERE A.SP_ID=@NSPID AND  B.GST_PERCENTAGE IS NULL 	

		IF EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_OVERHEADS_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND (ISNULL(IGST_REVENUE_AC_CODE,'') IN ('','0000000000') OR
				   ISNULL(LGST_REVENUE_AC_CODE,'')  IN ('','0000000000') OR ISNULL(IGST_TAX_AC_CODE,'') IN ('','0000000000')
				   OR ISNULL(CGST_TAX_AC_CODE,'') IN ('','0000000000') OR ISNULL(SGST_TAX_AC_CODE,'') IN 
				   ('','0000000000')) AND LEFT(XN_TYPE,7) NOT IN ('CHI_XFR','CHO_XFR'))	
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END						

		IF EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_OVERHEADS_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND ISNULL(LGST_REVENUE_AC_CODE,'')  IN ('','0000000000') 
				   AND LEFT(XN_TYPE,7)  IN ('CHI_XFR','CHO_XFR'))
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END							   		
	END
	
	ELSE
	IF @NMODE=3
	BEGIN
		SET @CSTEP='50'
		UPDATE A SET VALUE=B.VALUE FROM GST_ACCOUNTS_CONFIG_DET_OTHERS A
		JOIN GST_ACCOUNTS_CONFIG_DET_OTHERS_UPLOAD B ON A.XN_TYPE=B.XN_TYPE AND A.COLUMNNAME=B.COLUMNNAME
		WHERE B.SP_ID=@NSPID
		
		SET @CSTEP='60'
		INSERT GST_ACCOUNTS_CONFIG_DET_OTHERS	( XN_TYPE,COLUMNNAME, COLUMNDESC, VALUE )  
		SELECT A.XN_TYPE,A.COLUMNNAME,A.COLUMNDESC,A.VALUE
		FROM GST_ACCOUNTS_CONFIG_DET_OTHERS_UPLOAD A
		LEFT OUTER JOIN GST_ACCOUNTS_CONFIG_DET_OTHERS B ON A.XN_TYPE=B.XN_TYPE AND A.COLUMNNAME=B.COLUMNNAME
		WHERE A.SP_ID=@NSPID AND B.COLUMNNAME IS NULL

		IF EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_OTHERS_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND ISNULL(VALUE,'') IN ('','0000000000'))
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END			
	END
	
	ELSE
	IF @NMODE=4
	BEGIN
		SET @CSTEP='70'
		UPDATE A SET VALUE=B.VALUE FROM GST_ACCOUNTS_CONFIG_DET_PAYMODES A
		JOIN GST_ACCOUNTS_CONFIG_DET_PAYMODES_UPLOAD B ON A.COLUMNNAME=B.COLUMNNAME
		WHERE B.SP_ID=@NSPID
		
		SET @CSTEP='80'
		INSERT GST_ACCOUNTS_CONFIG_DET_PAYMODES	( PAYMODE_CODE, COLUMNNAME, COLUMNDESC, VALUE )  
		SELECT A.PAYMODE_CODE,A.COLUMNNAME,A.COLUMNDESC,A.VALUE
		FROM GST_ACCOUNTS_CONFIG_DET_PAYMODES_UPLOAD A
		LEFT OUTER JOIN GST_ACCOUNTS_CONFIG_DET_PAYMODES B ON A.COLUMNNAME=B.COLUMNNAME
		WHERE A.SP_ID=@NSPID AND B.COLUMNNAME IS NULL
		
		IF EXISTS (SELECT TOP 1 PAYMODE_CODE FROM GST_ACCOUNTS_CONFIG_DET_PAYMODES_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND ISNULL(VALUE,'') IN ('','0000000000'))
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END			
	END
	
	ELSE
	IF @NMODE=5
	BEGIN
		SET @CSTEP='85'
		
		UPDATE A SET  GST_CESS_AC_CODE=(CASE WHEN B.GST_CESS_AC_CODE NOT IN ('','0000000000') THEN B.GST_CESS_AC_CODE ELSE A.GST_CESS_AC_CODE END)
		FROM GST_ACCOUNTS_CONFIG_DET_CESS A
		JOIN GST_ACCOUNTS_CONFIG_DET_CESS_UPLOAD B ON A.XN_TYPE=B.XN_TYPE AND A.gst_CESS_PERCENTAGE=B.gst_CESS_PERCENTAGE
		AND A.SECTION_CODE=B.SECTION_CODE AND A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		WHERE B.SP_ID=@NSPID

		SET @CSTEP='90'
		INSERT GST_ACCOUNTS_CONFIG_DET_CESS	( XN_TYPE, gst_cess_percentage, SECTION_CODE, SUB_SECTION_CODE,GST_CESS_AC_CODE )  
		SELECT 	A.XN_TYPE, A.gst_cess_percentage,A.SECTION_CODE, A.SUB_SECTION_CODE,A.GST_CESS_AC_CODE
		FROM GST_ACCOUNTS_CONFIG_DET_CESS_UPLOAD A
		LEFT  OUTER JOIN GST_ACCOUNTS_CONFIG_DET_CESS B ON A.XN_TYPE=B.XN_TYPE AND A.gst_cess_percentage=B.gst_cess_percentage
		AND A.SECTION_CODE=B.SECTION_CODE AND A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		WHERE A.SP_ID=@NSPID AND B.gst_cess_percentage IS NULL 
		
		IF EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_CESS_UPLOAD (NOLOCK)
				   WHERE SP_ID=@NSPID AND (ISNULL(GST_CESS_AC_CODE,'') IN ('','0000000000'))	
				   AND XN_TYPE NOT IN ('CHI_XFR','CHO_XFR'))
		BEGIN
			SET @BBLANKACFOUND=1
			GOTO END_PROC
		END		
	END
		
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @CERRORMSG='ERROR IN PROCEDURE SP3S_UPDATE_POSTING_CONFIG SPID:'+STR(@NSPID)+' AT STEP#'+@CSTEP+' :'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:			
	--IF @BBLANKACFOUND=1
	--	SET @CERRORMSG='BLANK ACCOUNT NAMES NOT ALLOWED....PLEASE CHECK'
		
	SELECT @CERRORMSG AS ERRMSG	 
END