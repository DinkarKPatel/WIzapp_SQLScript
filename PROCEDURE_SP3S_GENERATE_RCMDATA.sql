create PROCEDURE SP3S_GENERATE_RCMDATA--(LocId 3 digit change by Sanjay:05-11-2024)
@nMode NUMERIC(1,0),
@dFromDt DATETIME,
@dToDt DATETIME,
@nSpId VARCHAR(5)=''
AS
BEGIN
	DECLARE @bFound BIT,@cMrrId VARCHAR(50),@CERRORMSG VARCHAR(MAX),@dItcDt DATETIME,@cRowIdBlankPc varchar(50),
	@cStep VARCHAR(5),@nLoop NUMERIC(1,0),@CMEMONOVAL VARCHAR(10),@cLocId VARCHAR(4),@cFinYear VARCHAR(10),
	@CCURSTATE_CODE VARCHAR(10),@CPARTYSTATE_CODE VARCHAR(10),@cPrefix VARCHAR(10)
	

BEGIN TRY	
	SET @cStep='10'
	
	IF @nMode=1
		GOTO lblPendingList
	ELSE
		GOTO lblGenRCM
		
lblPendingList:

		IF OBJECT_ID('tempdb..#tmpRcmPur','u') IS NOT NULL
			DROP TABLE #tmpRcmPur

		SELECT mrr_id,mrr_no,bill_Dt,fin_year,dept_id,ac_code INTO #tmpRcmPur FROM pim01106 (NOLOCK) 
		WHERE bill_Dt BETWEEN @dFromDt AND @dToDt
		AND ISNULL(rcm_applicable,0)=1 AND ISNULL(rcm_memo_no,'')='' and cancelled=0
		
		SELECT CONVERT(VARCHAR(5),'') AS sp_id,CONVERT(BIT,1) AS chk,mrr_id,mrr_no,bill_Dt,fin_year,dept_id,a.ac_code,ac_name FROM #tmpRcmPur a (NOLOCK) 
		JOIN LM01106 b ON a.ac_code=b.AC_CODE
		ORDER BY bill_dt
		
		SELECT a.mrr_id,a.product_code,a.purchase_price,a.invoice_quantity FROM pid01106 a (NOLOCK)
		JOIN #tmpRcmPur b ON a.mrr_id=b.mrr_id

lblGenRCM:			

	SET @CERRORMSG=''
	
	SET @cStep='20'
	SET @nLoop=1
	WHILE @nLoop=1
	BEGIN
		SET @cMrrId=''
		
		SET @cStep='30'
		SELECT TOP 1 @cMrrId=A.mrr_id,
		@cLocId=CASE WHEN ISNULL(PIM.Pur_For_Dept_id,'')<>'' THEN Pur_For_Dept_id ELSE PIM.DEPT_ID END ,
		@cFinYear=pim.fin_year,
		@CPARTYSTATE_CODE=ISNULL(B.AC_GST_STATE_CODE,''''),@dItcDt=pim.bill_dt FROM rcm_pending_memo a
		JOIN pim01106 PIM (NOLOCK) ON PIM.mrr_id=A.MRR_ID 
		JOIN LMP01106 b ON pim.ac_code=b.AC_CODE
		WHERE a.sp_id=@nSpId ORDER BY pim.bill_Dt
		
		IF ISNULL(@cMrrId,'')=''
			BREAK
		

		select top 1 @cRowIdBlankPc=row_id from pid01106 (nolock) where mrr_id=@cMrrId and product_code=''

		if isnull(@cRowIdBlankPc,'')<>''
		begin
			set @CERRORMSG='Bar code not generated for this Mrr Id #'+@cMrrId
			goto end_proc
		end	

		PRINT 'Calculating GSt for Mrr Id :'+@cMrrId
	    SELECT TOP 1 @CCURSTATE_CODE=ISNULL(GST_STATE_CODE,'') FROM LOCATION A WHERE A.DEPT_ID =@cLocId
	       
		DELETE FROM GST_TAXINFO_CALC WHERE sp_id=@nSpId
		
		SET @cStep='40'
		INSERT GST_TAXINFO_CALC	(PRODUCT_CODE, SP_ID, NET_VALUE,ROW_ID,TAX_METHOD,QUANTITY,HSN_CODE,MRP,memo_dt,gst_percentage) 
		  SELECT 	  A.PRODUCT_CODE,@NSPID,((A.PURCHASE_PRICE*A.INVOICE_QUANTITY)-ISNULL(PIMDISCOUNTAMOUNT,0)),
		 A.ROW_ID,B.BILL_LEVEL_TAX_METHOD,A.QUANTITY,
		 CASE WHEN ISNULL(A.HSN_CODE,'') IN('','0000000000') THEN  HM.HSN_CODE ELSE A.HSN_CODE END AS HSN_CODE,
		 A.MRP,@dItcDt,ISNULL(a.rcm_gst_percentage,0)
		 FROM pid01106 A (NOLOCK)
		 JOIN pim01106 B (NOLOCK) ON A.MRR_ID =B.MRR_ID
		 JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =A.ARTICLE_CODE 
		 LEFT JOIN HSN_MST HM (NOLOCK) ON HM.HSN_CODE=ART.HSN_CODE 
		 WHERE a.mrr_id=@cMrrId AND ISNULL(A.PRODUCT_CODE,'')<>'' 
		
		SET @cStep='50'
		 
		IF OBJECT_ID('TEMPDB..#TMPHSN','U') IS NOT NULL
			   DROP TABLE #TMPHSN

		;WITH CTE AS
		(
		SELECT B.HSN_CODE,(CASE WHEN a.gst_percentage=0 THEN ISNULL(C.TAX_PERCENTAGE,0) ELSE a.gst_percentage END)  AS TAX_PERCENTAGE,ISNULL(C.RATE_CUTOFF,0) AS RATE_CUTOFF,
		       ISNULL(C.RATE_CUTOFF_TAX_PERCENTAGE,0) AS RATE_CUTOFF_TAX_PERCENTAGE,
		      ISNULL(C.WEF,'') AS WEF,ISNULL(B.TAXABLE_ITEM,'') AS TAXABLE_ITEM,ISNULL(B.HSN_TYPE ,'') AS HSN_TYPE  ,
			  SR=ROW_NUMBER() OVER (PARTITION BY A.ROW_ID ORDER BY C.WEF DESC),
			  ISNULL(C.GST_CAL_BASIS,0) AS GST_CAL_BASIS
		FROM GST_TAXINFO_CALC A (NOLOCK)
		JOIN HSN_MST B (NOLOCK) ON A.HSN_CODE =B.HSN_CODE 
		LEFT JOIN HSN_DET C (NOLOCK) ON B.HSN_CODE =C.HSN_CODE AND C.WEF  <=MEMO_DT 
		WHERE A.SP_ID =LTRIM(RTRIM((@NSPID)))  
		)
		SELECT * INTO #TMPHSN FROM CTE WHERE SR=1
		
		
	   SET @cStep='60'

	   UPDATE TMP SET MRP= CASE WHEN ISNULL(HM.GST_CAL_BASIS,1)=1 THEN NET_VALUE ELSE (MRP*QUANTITY) END
	   FROM GST_TAXINFO_CALC TMP
	   JOIN #TMPHSN  HM (NOLOCK) ON HM.HSN_CODE=TMP.HSN_CODE 
	   WHERE TMP.SP_ID=LTRIM(RTRIM((@NSPID)))	   

	   SET @cStep='62'
	   UPDATE TMP SET  NET_VALUE_WOTAX= ROUND(MRP-(MRP*(CASE WHEN TAX_METHOD=2 THEN (HM.RATE_CUTOFF_TAX_PERCENTAGE/  
												   (100 + HM.RATE_CUTOFF_TAX_PERCENTAGE)) ELSE 0 END)),2)
	   FROM GST_TAXINFO_CALC TMP (NOLOCK)
	   JOIN #TMPHSN HM (NOLOCK) ON HM.HSN_CODE=TMP.HSN_CODE 
	   WHERE TMP.SP_ID=LTRIM(RTRIM((@NSPID)))
	   
	   SET @cStep='65'			   			
	   UPDATE TMP SET GST_PERCENTAGE=ISNULL(CASE WHEN HM.RATE_CUTOFF<ABS(TMP.NET_VALUE_WOTAX)/ABS(TMP.QUANTITY) 
	   THEN HM.TAX_PERCENTAGE ELSE RATE_CUTOFF_TAX_PERCENTAGE END ,0),
	   IGST_AMOUNT=0,
	   SGST_AMOUNT=0
	   FROM GST_TAXINFO_CALC TMP (NOLOCK)
	   JOIN #TMPHSN HM (NOLOCK) ON HM.HSN_CODE=TMP.HSN_CODE 
	   WHERE TMP.SP_ID=LTRIM(RTRIM((@NSPID)))

		SET @cStep='70'
		UPDATE TMP SET XN_VALUE_WITHOUT_GST =ROUND(NET_VALUE-(NET_VALUE*(CASE WHEN TAX_METHOD=2 THEN ((ISNULL(TMP.GST_PERCENTAGE,0))/  
		(100 + ISNULL(TMP.GST_PERCENTAGE,0))) ELSE 0 END)),2)
		FROM GST_TAXINFO_CALC TMP
		WHERE TMP.SP_ID=LTRIM(RTRIM((@NSPID)))

		
		SET @cStep='90'
        UPDATE TMP SET IGST_AMOUNT =ROUND(CASE WHEN @CCURSTATE_CODE<>@CPARTYSTATE_CODE THEN 
        NET_VALUE*(CASE WHEN TAX_METHOD=2 THEN (TMP.GST_PERCENTAGE/  
        (100 + TMP.GST_PERCENTAGE)) ELSE (TMP.GST_PERCENTAGE/100) END)
		ELSE 0 END,2) ,
		
		CGST_AMOUNT=ROUND((CASE WHEN @CCURSTATE_CODE<>@CPARTYSTATE_CODE THEN 0
		ELSE NET_VALUE*(CASE WHEN TAX_METHOD=2 THEN (TMP.GST_PERCENTAGE/  
		(100 + TMP.GST_PERCENTAGE)) ELSE (TMP.GST_PERCENTAGE/100) END) 
		 END)/2,2),
		 
		SGST_AMOUNT=ROUND((CASE WHEN @CCURSTATE_CODE<>@CPARTYSTATE_CODE THEN 0
		ELSE NET_VALUE*(CASE WHEN TAX_METHOD=2 THEN (TMP.GST_PERCENTAGE/  
		(100 + TMP.GST_PERCENTAGE)) ELSE (TMP.GST_PERCENTAGE/100) END) 
		END)/2,2)
		FROM GST_TAXINFO_CALC TMP (NOLOCK)
		WHERE TMP.SP_ID=LTRIM(RTRIM((@NSPID)))

	 --   IF @cMrrId='LU01120000LUPHO-000024'
	 --   begin
		--	select * from GST_TAXINFO_CALC where SP_ID=LTRIM(RTRIM((@NSPID)))
		--	select * from #TMPHSN
		--end
		
		SET @cStep='100'
		BEGIN TRAN
		
		SET @cPrefix=@cLocId+'RCM'
		
		SET @nLoop=0  
		WHILE @nLoop=0  
		BEGIN  
			
			 SET @cStep='110'
			 EXEC GETNEXTKEY 'pim01106','rcm_memo_no',10,@cPrefix, 1,@CFINYEAR,0, @CMEMONOVAL OUTPUT     
		       
			 PRINT @CMEMONOVAL  
		       
			 SET @cStep='120'
			 IF EXISTS (SELECT RCM_MEMO_NO FROM pim01106 (NOLOCK) WHERE rcm_memo_no=@CMEMONOVAL
					    AND FIN_YEAR = @CFINYEAR)
				 SET @nLoop=0  
 			 ELSE  
				 SET @nLoop=1  
			 
		END  
		
		SET @cStep='130'
		IF (@CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%' )
		BEGIN  
		   SET @CERRORMSG = 'STEP- ' + @cSTEP + ' ERROR CREATING NEXT MEMO NO....'   
		   GOTO END_PROC      
		END  
		
		SET @cStep='140'
		UPDATE pim01106 SET rcm_memo_no=@CMEMONOVAL WHERE mrr_id=@cMrrId

		if exists (select top 1 'u' from GST_TAXINFO_CALC where sp_id=LTRIM(RTRIM((@NSPID)))
		and isnull(cgst_amount,0)+isnull(sgst_amount,0)+isnull(igst_amount,0)=0)
		begin
		   SET @CERRORMSG = 'STEP- ' + @cSTEP + ' Gst calculation zero can not Process....' +@cMrrId  
		   GOTO END_PROC 
	
		end
		
		UPDATE pid01106 SET rcm_gst_percentage=b.gst_percentage,rcm_taxable_value=b.xn_value_without_gst,
		rcm_igst_amount=b.igst_amount,rcm_cgst_amount=b.cgst_amount,rcm_sgst_amount=b.sgst_amount			
		FROM GST_TAXINFO_CALC b WHERE b.row_id=PID01106.row_id
		and  b.SP_ID=LTRIM(RTRIM((@NSPID)))
		

		--select 'chck rcm gst', * from gst_taxinfo_calc where sp_id=@nSpId

		COMMIT
		DELETE FROM rcm_pending_memo WHERE mrr_id=@cMrrId AND sp_id=@nSpId
	END

END TRY

BEGIN CATCH
	SET @CERRORMSG='Error in Procedure SP3S_GENERATE_RCMDATA AT Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC 
END CATCH

END_PROC:
	
	IF @@TRANCOUNT>0 AND ISNULL(@cErrormsg,'')<>''
		ROLLBACK
	
	IF ISNULL(@cErrormsg,'')<>'' OR @nMode=2
		SELECT ISNULL(@cErrormsg,'') AS errmsg	
END