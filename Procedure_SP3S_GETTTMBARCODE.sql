
create Procedure SP3S_GETTTMBARCODE
(
 @NSPID varchar(50)='',
 @CDEPT_ID VARCHAR(5)
)
as
begin
     

	 DECLARE @NSTEP NUMERIC(5,0),@CERRORMSG VARCHAR(1000)
	 SET @CERRORMSG=''
    
 BEGIN TRY  
       

	   set @NSTEP=00

	  
	
		  IF NOT EXISTS (SELECT TOP 1'U' FROM JWR_MISSING_BARCODE_UPLOAD WHERE SP_ID=@NSPID)
		  BEGIN
		      	SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' BARCODE DETAILS NOT FOUND  '  
				GOTO END_PROC
		  END
		  GOTO END_PROC
		

			if object_id ('tempdb..#tmprecbarcode','U') is not null
			   drop table #tmprecbarcode

			;WITH RECBARCODE AS
			(
			SELECT  TMP.ARTICLE_CODE ,TMP.PARA1_CODE ,TMP.PARA2_CODE  , TMP.REC_QTY,
				  A.PRODUCT_CODE ,A.AGENCY_CODE ,A.JOB_CODE ,
				   SR=ROW_NUMBER () OVER (PARTITION BY TMP.ARTICLE_CODE ,TMP.PARA1_CODE ,TMP.PARA2_CODE ORDER BY A.PRODUCT_CODE),
				   CAST('' AS VARCHAR(50)) AS REF_ROW_ID,
				   CAST(0 AS NUMERIC(10,2)) AS Rate,
				   CAST('' AS VARCHAR(1000))  as ISSUE_REMARKS,
				   CAST('' AS VARCHAR(1000))  as ISSUE_NO,
				   CAST('' AS datetime)  as ISSUE_dt

			FROM JOBWORK_PMT A (NOLOCK)
			JOIN ORD_PLAN_BARCODE_DET DET (NOLOCK) ON DET.PRODUCT_CODE=A.PRODUCT_CODE
			JOIN ORD_PLAN_DET T1 (NOLOCK) ON  DET.REFROW_ID=T1.ROW_ID
			JOIN ORD_PLAN_MST T2 (NOLOCK) ON  T1.MEMO_ID=T2.MEMO_ID 
			JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.product_code 
			JOIN JWR_MISSING_BARCODE_UPLOAD TMP (NOLOCK) ON B.article_code =TMP.ARTICLE_CODE AND B.para1_code =TMP.PARA1_CODE 
			AND B.para2_code =TMP.PARA2_CODE   AND (isnull(TMP.JOBCARD_ID,'')=T2.MEMO_ID OR ISNULL(TMP.JOBCARD_ID,'')='')
			AND A.JOB_CODE =TMP.JOB_CODE 
			WHERE  ISNULL(QUANTITY_IN_STOCK,0) >0 AND T2.CANCELLED=0 
			and tmp.SP_ID=@NSPID
			)


			SELECT * into #tmprecbarcode FROM RECBARCODE WHERE SR <=REC_QTY
		    set @NSTEP=10
			declare @ctransferqty numeric(10,2),@ntottalqty numeric(10,0)

			select @ctransferqty=SUM(rec_qty) from JWR_MISSING_BARCODE_UPLOAD where SP_ID=@NSPID
			select @ntottalqty=COUNT(*) from #tmprecbarcode

			if  isnull(@ctransferqty,0)<>@ntottalqty
			begin  

			     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' mismatch In Totalqty :-'  +rtrim(LTRIM(STR(@ntottalqty)))+' and Transfer Qty:'+rtrim(LTRIM(STR(@ctransferqty)))
				 GOTO END_PROC
			end
 

		   SET @NSTEP = 15
			if object_id ('tempdb..#tmpmismatchqty','U') is not null
			   drop table #tmpmismatchqty

			SELECT A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE ,A.REC_QTY,COUNT(*) AS BARCODE_QTY  
			into #tmpmismatchqty
			FROM #TMPRECBARCODE A
			GROUP BY A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE ,A.REC_QTY 
			having A.REC_QTY<>COUNT(*)  

			 SET @NSTEP = 20
			if exists (select top 1 'u' from #tmpmismatchqty)
			begin
     
	             declare @cstr varchar(1000)

				 select top 1 @cstr=' Article:'+ article_no +',Para1_Name:'+para1_name +',Para2_Name:'+para2_name +',TTM Qty:' +str(REC_QTY) +',Barcode Qty:'+str(BARCODE_QTY)
				 from #tmpmismatchqty a
				 join article b on a.ARTICLE_CODE =b.article_code 
				 join para1 p1 on p1.para1_code =a.PARA1_CODE 
				 join para2 p2 on p2.para2_code =a.PARA2_CODE 

				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) +@cstr+ ' Issue Details Not found Please check  '  
				goto end_proc

			end

		
	

   
 END TRY  
   
 BEGIN CATCH  
  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
  GOTO END_PROC  
 END CATCH  
   
END_PROC: 


       

	   SELECT      '' AS PRODUCT_CODE, A.ARTICLE_CODE, ART.ARTICLE_NO, ART.ARTICLE_NAME, A.PARA1_CODE,A.jobcard_id ,      
					P1.PARA1_NAME, A.PARA2_CODE, P2.PARA2_NAME, '0000000' PARA3_CODE, '' AS PARA3_NAME, UOM.UOM_NAME,         
					@CDEPT_ID AS DEPT_ID, ART.CODING_SCHEME AS CODING_SCHEME,  ART.INACTIVE,
					0 AS QUANTITY_IN_STOCK,      
					ART.PURCHASE_PRICE,
					ART.MRP AS [MRP],    
					ART.WHOLESALE_PRICE  AS WS_PRICE,       
					'' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
					'0000000' PARA4_CODE,'' PARA5_CODE,'0000000' PARA6_CODE,      
					'' PARA4_NAME,'' PARA5_NAME,'' PARA6_NAME,UOM.UOM_CODE,ISNULL(UOM.UOM_TYPE,0) AS [UOM_TYPE],      
					ART.DT_CREATED AS [ART_DT_CREATED],'' AS [PARA3_DT_CREATED],'' AS [SKU_DT_CREATED],      
					CASE WHEN ISNULL(ART.ARTICLE_PRD_MODE,0) =2 THEN 1 ELSE ART.STOCK_NA END AS STOCK_NA,
					'' AS EAN, '0000000' FORM_ID,'' AS FORM_NAME,0 AS TAX_PERCENTAGE , '' AS PRODUCT_NAME,  
					ART.MRP AS RATE,1 AS ER_FLAG,ISNULL(ART.FIX_MRP,0) AS [FIX_MRP] ,'' AS AC_NAME  
					,'' AS INV_DT,'' AS RECEIPT_DT ,'0000000000' AS AC_CODE,ART.ALIAS AS [ARTICLE_ALIAS],
					'000' AS   [BIN_ID],'' AS [BIN_NAME],'' AS [WIP_UID],
					0 AS LANDED_COST,''  AS ONLINE_BAR_CODE,
					'' AS VENDOR_EAN_NO,ART.HSN_CODE,SM.ITEM_TYPE,A.REC_QTY AS QUANTITY ,@CERRORMSG AS ERRMSG ,
					A.jobcard_id 
	   FROM JWR_MISSING_BARCODE_UPLOAD A (NOLOCK)
	   JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =A.ARTICLE_CODE 
	   JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 
	   JOIN SECTIONM SM (NOLOCK) ON SM.SECTION_CODE =SD.SECTION_CODE 
	   JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_CODE=A.PARA1_CODE 
	   JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_CODE=A.PARA2_CODE 
	   JOIN UOM (NOLOCK) ON UOM.UOM_CODE =ART .UOM_CODE 
	   WHERE A.SP_ID =@NSPID 


		--SELECT A.PRODUCT_CODE, A.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, A.PARA1_CODE,      
		--			C.PARA1_NAME, A.PARA2_CODE, D.PARA2_NAME, A.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,         
		--			ISNULL(PMT.DEPT_ID, '') AS DEPT_ID, A.BARCODE_CODING_SCHEME AS CODING_SCHEME,  B.INACTIVE,
		--			CASE WHEN (B.STOCK_NA =1 OR ISNULL(B.ARTICLE_PRD_MODE,0) =2) THEN 99 ELSE 
		--				ISNULL(PMT.QUANTITY_IN_STOCK,0) END 
		--			 AS QUANTITY_IN_STOCK,      
		--			A.PURCHASE_PRICE,
		--			A.MRP AS [MRP],    
		--			A.WS_PRICE  AS WS_PRICE,       
		--			'' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,      
		--			A.PARA4_CODE,A.PARA5_CODE,A.PARA6_CODE,      
		--			PARA4_NAME,PARA5_NAME,PARA6_NAME,B.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],      
		--			B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],A.DT_CREATED AS [SKU_DT_CREATED],      
		--			CASE WHEN ISNULL(B.ARTICLE_PRD_MODE,0) =2 THEN 1 ELSE B.STOCK_NA END AS STOCK_NA,
		--			'' AS EAN,  
		--			A.FORM_ID,'' AS FORM_NAME,0 AS TAX_PERCENTAGE , A.PRODUCT_NAME,  
		--			A.MRP AS RATE,A.ER_FLAG,ISNULL(A.FIX_MRP,0) AS [FIX_MRP] ,'' AS AC_NAME  
		--			,A.INV_DT,A.RECEIPT_DT ,'0000000000' as AC_CODE,B.ALIAS AS [ARTICLE_ALIAS],
		--			ISNULL(PMT.BIN_ID, @CDEPT_ID) AS [BIN_ID],ISNULL(BIN.BIN_NAME, '') AS [BIN_NAME],'' AS [WIP_UID],
		--			0 AS LANDED_COST,A.ONLINE_PRODUCT_CODE AS ONLINE_BAR_CODE,
		--			A.VENDOR_EAN_NO,A.HSN_CODE,SM.ITEM_TYPE,1 as quantity ,@CERRORMSG as errmsg
 
	 -- FROM SKU A   (NOLOCK)     
	 -- JOIN JOBWORK_PMT PMT  (NOLOCK) ON A.PRODUCT_CODE=PMT.PRODUCT_CODE  
	 -- LEFT OUTER JOIN BIN (NOLOCK) ON BIN.BIN_ID=ISNULL(PMT.BIN_ID, '')
	 -- JOIN ARTICLE B  (NOLOCK) ON A.ARTICLE_CODE = B.ARTICLE_CODE        
	 -- JOIN SECTIOND SD  (NOLOCK) ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE      
	 -- JOIN SECTIONM SM  (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE      
	 -- JOIN PARA1 C  (NOLOCK) ON A.PARA1_CODE = C.PARA1_CODE        
	 -- JOIN PARA2 D  (NOLOCK) ON A.PARA2_CODE = D.PARA2_CODE        
	 -- JOIN PARA3 F  (NOLOCK) ON A.PARA3_CODE = F.PARA3_CODE        
	 -- JOIN PARA4 G  (NOLOCK) ON A.PARA4_CODE = G.PARA4_CODE        
	 -- JOIN PARA5 H  (NOLOCK) ON A.PARA5_CODE = H.PARA5_CODE        
	 -- JOIN PARA6 I  (NOLOCK) ON A.PARA6_CODE = I.PARA6_CODE           
	 -- JOIN UOM E  (NOLOCK) ON B.UOM_CODE = E.UOM_CODE  
	 -- join #tmprecbarcode BC (nolock) on bc.product_code =a.product_code 





end



