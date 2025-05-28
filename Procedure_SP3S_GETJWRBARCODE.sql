
create Procedure SP3S_GETJWRBARCODE
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
			JOIN JWR_MISSING_BARCODE_UPLOAD TMP (NOLOCK) ON B.article_code =TMP.ARTICLE_CODE 
			AND B.para1_code =TMP.PARA1_CODE AND B.para2_code =TMP.PARA2_CODE  
			AND (isnull(TMP.JOBCARD_ID,'')=T2.MEMO_ID OR ISNULL(TMP.JOBCARD_ID,'')='')
			AND A.AGENCY_CODE=TMP.AGENCY_CODE AND A.JOB_CODE =TMP.JOB_CODE 
			WHERE ISNULL(A.TTM,0)=0 AND ISNULL(QUANTITY_IN_STOCK,0) =0 AND T2.CANCELLED=0 
			and tmp.SP_ID=@NSPID
			)

			 
			SELECT * into #tmprecbarcode FROM RECBARCODE WHERE SR <=REC_QTY

			
			 set @NSTEP=10
			update a set REF_ROW_ID =b.row_id ,Rate =b.job_rate ,issue_no =c.issue_no,
			issue_dt=c.issue_dt  ,
			             ISSUE_REMARKS=b.remarks
			from  #tmprecbarcode a
			join jobwork_issue_det b on a.PRODUCT_CODE =b.product_code and a.JOB_CODE =b.job_code 
			join jobwork_issue_mst c on b.issue_id =c.issue_id and a.agency_code =c.agency_code 
			where c.cancelled =0

		

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

				 select top 1 @cstr=' Article:'+ article_no +',Para1_Name:'+para1_name +',Para2_Name:'+para2_name +',Rec Qty:' +str(REC_QTY) +',Barcode Qty:'+str(BARCODE_QTY)
				 from #tmpmismatchqty a
				 join article b on a.ARTICLE_CODE =b.article_code 
				 join para1 p1 on p1.para1_code =a.PARA1_CODE 
				 join para2 p2 on p2.para2_code =a.PARA2_CODE 

				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) +@cstr+ ' Issue Details Not found Please check  '  
				goto end_proc

			end

			 SET @NSTEP = 30

			if exists (select top 1 'u' from #tmprecbarcode where REF_ROW_ID ='')
			begin

				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' Issue Details Not found Please check  '  
				goto end_proc
			end

			 SET @NSTEP = 40
			
		
		

   
 END TRY  
   
 BEGIN CATCH  
  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
  GOTO END_PROC  
 END CATCH  
   
END_PROC: 

	--SELECT 	     '000'  BIN_ID,0 CESS_AMOUNT,0 CGST_AMOUNT,0 GST_PERCENTAGE,'0000000000' HSN_CODE,0 IGST_AMOUNT, a.JOB_CODE, 
	--				a.RATE job_rate ,0 JWRDISCOUNTAMOUNT,GETDATE() LAST_UPDATE,0 NO_HRS,'' OLD_ROW_ID, 0 PREV_JOB_RATE,0 PRINT_LABEL, 
	--				A.PRODUCT_CODE,1 QUANTITY,'LATER' RECEIPT_ID, 
	--				REF_ROW_ID,'' REMARKS,'LATER' ROW_ID,
	--				0 SGST_AMOUNT,@NSPID  SP_ID,'' WIP_UID, 
	--				0 XN_VALUE_WITH_GST, 0 XN_VALUE_WITHOUT_GST ,
	--				(CAST(0 AS BIT)) AS CHKDELIVER ,
	--				1 as RECEIVE_QUNATITY, 0 as BALANCE_QUANTITY,        
	--				1 as PENDING_QUANTITY, 1 AS ISSUE_QUANTITY,a. REF_ROW_ID,'' as BIN_NAME,      
	--				a.Rate AS AMOUNT,    a.rate ,      
	--				jobs.JOB_NAME, A.ISSUE_NO , A.ISSUE_DT,  1 as NET_REC,                        
	--				sn.ARTICLE_NO, sn.ARTICLE_NAME, PARA1_NAME,PARA2_NAME,PARA3_NAME,'PCS' AS UOM_NAME,                 
	--				CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,sn.pp as PURCHASE_PRICE,            
	--				 sn.SECTION_NAME, sn.SUB_SECTION_NAME,                    
	--				PARA4_NAME,PARA5_NAME,PARA6_NAME,             
	--				ISNULL(sn.STOCK_NA,0) AS STOCK_NA,am.AGENCY_NAME,a.AGENCY_CODE,jobs.JOB_NAME AS PREV_JOB_NAME,    
	--				'0000000' AS PREV_JOB_CODE   ,ISSUE_REMARKS AS [ISSUE_REMARKS],    
	--				'' AS BILL_NO                              
	--				,'' as BUYER_ORDER_ID,'' BUYER_ORDER_NO,'' BUYER_ORDER_DT,'' BUYER_ORDER_REF_NO    
	--				,'' JOB_CARD_ID,'' JOB_CARD_NO,'' AS JOB_CARD_ID    
	--				,'' AS MERCHANT_NAME,ISNULL(NULL,'') AS BUYER_NAME    
	--				,  '' design_no  ,SKU.barcode_coding_scheme CODING_SCHEME,@NSPID AS SP_ID 
	--				,@CERRORMSG AS ERRMSG
				
	--		FROM #TMPRECBARCODE  A
	--		JOIN SKU_NAMES SN ON SN.PRODUCT_CODE=A.PRODUCT_CODE
	--		JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =A.PRODUCT_CODE
	--		join article art (nolock) on art.article_code =sku.article_code 
	--		JOIN UOM  (NOLOCK) ON UOM.UOM_CODE =ART.UOM_CODE 
	--		JOIN JOBS ON JOBS.JOB_CODE =A.JOB_CODE
	--		join prd_agency_mst am on am.agency_code=a.agency_code 

			SELECT  a.AGENCY_CODE,a.ROW_ID,a.ARTICLE_CODE,a.PARA1_CODE,a.PARA2_CODE,a.RATE,a.REC_QTY,a.jobcard_id,
			      '000'  BIN_ID,0 CESS_AMOUNT,0 CGST_AMOUNT,0 GST_PERCENTAGE,'0000000000' HSN_CODE,0 IGST_AMOUNT, a.JOB_CODE, 
					a.RATE job_rate ,0 JWRDISCOUNTAMOUNT,GETDATE() LAST_UPDATE,0 NO_HRS,'' OLD_ROW_ID, 0 PREV_JOB_RATE,0 PRINT_LABEL, 
					'' as PRODUCT_CODE,REC_QTY QUANTITY,'LATER' RECEIPT_ID, 
					'' REF_ROW_ID,'' REMARKS,'LATER' ROW_ID,
					0 SGST_AMOUNT,'' WIP_UID, 
					0 XN_VALUE_WITH_GST, 0 XN_VALUE_WITHOUT_GST ,
					(CAST(0 AS BIT)) AS CHKDELIVER ,
					REC_QTY as RECEIVE_QUNATITY, 0 as BALANCE_QUANTITY,        
					REC_QTY as PENDING_QUANTITY, REC_QTY AS ISSUE_QUANTITY,'' as BIN_NAME,      
					(a.Rate*REC_QTY) AS AMOUNT,    a.rate ,      
					jobs.JOB_NAME, '' ISSUE_NO , '' ISSUE_DT,  REC_QTY as NET_REC,                        
					art.ARTICLE_NO, art.ARTICLE_NAME, PARA1_NAME,PARA2_NAME,'' as PARA3_NAME,'PCS' AS UOM_NAME,                 
					CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,art.purchase_price as PURCHASE_PRICE,            
					 sm.SECTION_NAME, sd.SUB_SECTION_NAME,                    
					'' as PARA4_NAME,'' as PARA5_NAME,'' as PARA6_NAME,             
					ISNULL(art.STOCK_NA,0) AS STOCK_NA,am.AGENCY_NAME,a.AGENCY_CODE,jobs.JOB_NAME AS PREV_JOB_NAME,    
					'0000000' AS PREV_JOB_CODE   ,'' AS [ISSUE_REMARKS],    
					'' AS BILL_NO                              
					,'' as BUYER_ORDER_ID,'' BUYER_ORDER_NO,'' BUYER_ORDER_DT,'' BUYER_ORDER_REF_NO    
					,'' JOB_CARD_ID,'' JOB_CARD_NO,'' AS JOB_CARD_ID    
					,'' AS MERCHANT_NAME,ISNULL(NULL,'') AS BUYER_NAME    
					,  '' design_no  ,3 CODING_SCHEME,@NSPID AS SP_ID 
					,@CERRORMSG AS ERRMSG ,cast('' as timestamp) as Ts
					

			FROM JWR_MISSING_BARCODE_UPLOAD A (NOLOCK)
			JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE =A.JOB_CODE
			JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =A.ARTICLE_CODE 
			JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 
			JOIN SECTIONM SM (NOLOCK) ON SM.SECTION_CODE =SD.SECTION_CODE 
			JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_CODE=A.PARA1_CODE 
			JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_CODE=A.PARA2_CODE 
			join prd_agency_mst am on am.agency_code=a.agency_code 
			where a.sp_id=@NSPID


			


end

