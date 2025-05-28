
create Procedure SP_JOB_WORK_ISSUE_GETDATA
(
 @csp_id varchar(50),
 @DEPTID varchar(4)='',
 @NMODE INT=1, --1 FOR SCANNING & 2 FOR ARTICLE SELECTION
 @CJOB_CODE VARCHAR(10)=''

)
as
begin
  --(dinkar) Replace  left(memoid,2) to Location_code   
	DECLARE @CERRMSG VARCHAR(1000)
	BEGIN TRY

	      IF @NMODE=2
	       GOTO LBLSUMMARY


	
	  DECLARE @LEVEL_NO INT
	  SELECT TOP 1 @LEVEL_NO=LEVEL_NO  FROM XN_APPROVAL_CHECKLIST_LEVEL_USERS A  
	  WHERE A.XN_TYPE ='jC'	AND DEPT_ID =@DEPTID


	  if @nmode=2
	  begin

		  
			if object_id ('tempdb..#tmprecbarcode','U') is not null
			   drop table #tmprecbarcode
           
		   ;with RECBARCODE as 
		   (
			SELECT TMP.AGENCY_CODE,@DEPTID DEPT_ID,PMT.PRODUCT_CODE,1 AS QUANTITY,'000' AS BIN_ID,TMP.JOB_CODE,'' AS DUE_DT,@CSP_ID ASSP_ID,
			         SR=ROW_NUMBER () OVER (PARTITION BY TMP.ARTICLE_CODE ,TMP.PARA1_CODE ,TMP.PARA2_CODE ORDER BY A.PRODUCT_CODE),
					 tmp.ARTICLE_CODE ,tmp.PARA1_CODE ,tmp.PARA2_CODE ,tmp.REC_QTY
			FROM JOBWORK_PMT PMT (NOLOCK)
			JOIN ORD_PLAN_BARCODE_DET A (NOLOCK) ON PMT.PRODUCT_CODE=A.PRODUCT_CODE
			JOIN ORD_PLAN_DET T1 (NOLOCK) ON  A.REFROW_ID=T1.ROW_ID
			JOIN ORD_PLAN_MST T2 (NOLOCK) ON  T1.MEMO_ID=T2.MEMO_ID 
			LEFT JOIN ORD_PLAN_JOB T3 (NOLOCK) ON   T2.MEMO_ID=T3.MEMO_ID AND T3.ARTICLE_CODE=T1.ARTICLE_CODE and isnull(T3.JOB_ORDER,0)>0
			LEFT JOIN
			(
			  SELECT PJ.MEMO_ID,PJ.ARTICLE_CODE  ,PJ.JOB_CODE ,PJ.JOB_ORDER  
			  FROM ORD_PLAN_JOB  PJ (NOLOCK)
			) PJ ON  T3.MEMO_ID=PJ.MEMO_ID AND T3.ARTICLE_CODE=PJ.ARTICLE_CODE AND isnull(T3.JOB_ORDER,0)-1 =PJ.JOB_ORDER  
			JOIN JWR_MISSING_BARCODE_UPLOAD TMP (NOLOCK) ON T1.ARTICLE_CODE =TMP.ARTICLE_CODE AND T1.PARA1_CODE =TMP.PARA1_CODE AND T1.PARA2_CODE =TMP.PARA2_CODE AND (isnull(TMP.JOBCARD_ID,'')=T2.MEMO_ID OR ISNULL(TMP.JOBCARD_ID,'')='')
			WHERE PMT.QUANTITY_IN_STOCK>0 AND T2.CANCELLED=0 AND ISNULL(T2.SHORT_CLOSE,0)=0
			AND( ISNULL(T2.ENFORCE_JOB_ORDER,0) =0 OR  ((ISNULL(PMT.JOB_CODE,'')='' AND ISNULL(T3.JOB_ORDER,0) =1)OR ( PMT.JOB_CODE =PJ.JOB_CODE )))
			AND (ISNULL(T2.ENFORCE_JOB_ORDER,0) =0 OR T3.JOB_CODE=TMP.JOB_CODE)
			and isnull(pmt.Barcode_Cancelled,0)=0
			--AND (@LEVEL_NO=0 OR T2.APPROVEDLEVELNO =99)
			AND t2.location_code =@DEPTID and tmp.SP_ID =@csp_id
			
			)
			SELECT * into #tmprecbarcode FROM RECBARCODE WHERE SR <=REC_QTY 


			DELETE FROM JWI_BARCODE WHERE SP_ID=@CSP_ID
			INSERT INTO JWI_BARCODE(AGENCY_CODE,DEPT_ID,PRODUCT_CODE,QUANTITY,BIN_ID,JOB_CODE,DUE_DT,SP_ID)
			select AGENCY_CODE,DEPT_ID,PRODUCT_CODE,QUANTITY,BIN_ID,JOB_CODE,DUE_DT,@csp_id as SP_ID
			from #tmprecbarcode 
			
				if object_id ('tempdb..#tmpmismatchqty','U') is not null
				   drop table #tmpmismatchqty

				SELECT A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE ,A.REC_QTY,COUNT(*) AS BARCODE_QTY  
				into #tmpmismatchqty
				FROM #TMPRECBARCODE A
				GROUP BY A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE ,A.REC_QTY 
				having A.REC_QTY<>COUNT(*)  

				
				if exists (select top 1 'u' from #tmpmismatchqty)
				begin
     
					 declare @cstr varchar(1000)

					 select top 1 @cstr=' Article:'+ article_no +',Para1_Name:'+para1_name +',Para2_Name:'+para2_name +',Rec Qty:' +str(REC_QTY) +',Barcode Qty:'+str(BARCODE_QTY)
					 from #tmpmismatchqty a
					 join article b on a.ARTICLE_CODE =b.article_code 
					 join para1 p1 on p1.para1_code =a.PARA1_CODE 
					 join para2 p2 on p2.para2_code =a.PARA2_CODE 

					SET @CERRMSG = 'STEP- '  +@cstr+ ' Issue Details Not found Please check  '  
					goto end_proc

				end

		


		end
	


		--alter table JWR_MISSING_BARCODE_UPLOAD add jobcard_id varchar(50)


	SET @CERRMSG=''
		UPDATE A SET ARTICLE_CODE =SKU.ARTICLE_CODE,HSN_CODE=SKU.hsn_code ,PURCHASE_PRICE=isnull(pmt.BOM_VALUE,0)+isnull(pmt.FG_VALUE,0)
		FROM JWI_barcode (NOLOCK) A
		JOIN SKU (NOLOCK) ON A.PRODUCT_CODE =SKU.PRODUCT_CODE
		join JOBWORK_PMT pmt (nolock) on pmt.PRODUCT_CODE =a.PRODUCT_CODE 
		where a.sp_id=@csp_id
	
	
		UPDATE X SET JOB_RATE=A.RATE
		FROM JOB_RATE_DET A (NOLOCK)
		JOIN ARTICLE B (NOLOCK) ON B.ARTICLE_CODE=A.ARTICLE_CODE
		JOIN PRD_AGENCY_MST C (NOLOCK) ON C.AGENCY_CODE=A.AGENCY_CODE
		JOIN JWI_barcode X ON X.ARTICLE_CODE=A.ARTICLE_CODE AND C.AGENCY_CODE =X.AGENCY_CODE AND A.JOB_CODE=X.JOB_CODE 
		where x.sp_id=@csp_id
		
		IF EXISTS (SELECT TOP 1 'U' FROM JWI_barcode WHERE ISNULL(JOB_RATE,0)=0 and sp_id=@csp_id)
		BEGIN
			UPDATE X SET JOB_RATE=A.RATE
			FROM JOB_RATE_DET A(NOLOCK)
			JOIN ARTICLE B (NOLOCK) ON B.ARTICLE_CODE=A.ARTICLE_CODE
			JOIN JWI_barcode X ON X.ARTICLE_CODE=A.ARTICLE_CODE AND A.JOB_CODE=X.JOB_CODE	 
			WHERE ISNULL(A.AGENCY_CODE,'')='' 	AND ISNULL(X.JOB_RATE,0)=0 	
			and x.sp_id=@csp_id
		END
	



	
END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP3S_SYNCH_UPLOADDATA_ATD_OPT, STEP: MESSAGE:'+ERROR_MESSAGE()
END CATCH




  
	SELECT A.agency_code,a.dept_id, A.product_code,A.quantity,a.BIN_ID, a.JOB_CODE, due_dt,isnull(JOB_RATE,0) AS job_rate,CAST('' AS VARCHAR (1000)) AS remarks,'01' AS company_code,
            CAST('LATER'+CAST(NEWID() AS VARCHAR(40)) AS VARCHAR(40)) AS row_id,GETDATE() AS LAST_UPDATE,CAST('LATER' AS VARCHAR(40))  issue_id,0 AS no_hrs,
			CAST('' AS VARCHAR(40)) AS WIP_UID,'0000000' AS PREV_JOB_CODE,0 AS PREV_JOB_RATE,'' AS ref_no,'' AS design_code,A.hsn_code,
			CAST(0 AS NUMERIC(10,2)) AS gst_percentage,
			CAST(0 AS NUMERIC(10,2)) AS igst_amount,
			CAST(0 AS NUMERIC(10,2)) AS cgst_amount,
			CAST(0 AS NUMERIC(10,2)) AS sgst_amount,
			CAST(0 AS NUMERIC(10,2)) AS xn_value_without_gst,
			CAST(0 AS NUMERIC(10,2)) AS xn_value_with_gst,
			CAST(A.purchase_price AS NUMERIC(10,2)) AS PURCHASE_PRICE,
			CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT	,
			CAST(0 AS BIT) AS CHKBILL, '' as ISSUE_NO,      
			SKU_names.ARTICLE_NO, SKU_names.ARTICLE_NAME,      
		    PARA1_NAME,PARA2_NAME,PARA3_NAME,'PCS' as UOM_NAME,           
		    CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,SKU_names.SECTION_NAME, SKU_names.SUB_SECTION_NAME,           
		   PARA4_NAME,PARA5_NAME,PARA6_NAME,'' as BIN_NAME,'' AS PREV_JOB_NAME ,jobs.job_name 
		  ,SKU_names.attr1_key_name,SKU_names.attr2_key_name,SKU_names.attr3_key_name,SKU_names.attr4_key_name,SKU_names.attr5_key_name,SKU_names.attr6_key_name,
		   SKU_names.attr7_key_name,SKU_names.attr8_key_name,SKU_names.attr9_key_name,SKU_names.attr10_key_name,SKU_names.attr11_key_name,SKU_names.attr12_key_name,
		   SKU_names.attr13_key_name,SKU_names.attr14_key_name,SKU_names.attr15_key_name,SKU_names.attr16_key_name,SKU_names.attr17_key_name,SKU_names.attr18_key_name,
		   SKU_names.attr19_key_name,SKU_names.attr20_key_name,SKU_names.attr21_key_name,SKU_names.attr22_key_name,SKU_names.attr23_key_name,SKU_names.attr24_key_name,
		   SKU_names.attr25_key_name ,CAST(0 AS BIT) AS [PRINT],@CERRMSG as errmsg,a.buyer_name ,a.merchant_name 

	 FROM JWI_barcode  A
	 JOIN SKU_names  (NOLOCK) ON SKU_names.PRODUCT_CODE=a.PRODUCT_CODE      
	join jobs on jobs.job_code =a.job_code 
	where a.sp_id=@csp_id

	goto end_proc

   LBLSUMMARY:
       
	   UPDATE X SET RATE=A.RATE
		FROM JOB_RATE_DET A (NOLOCK)
		JOIN ARTICLE B (NOLOCK) ON B.ARTICLE_CODE=A.ARTICLE_CODE
		JOIN PRD_AGENCY_MST C (NOLOCK) ON C.AGENCY_CODE=A.AGENCY_CODE
		JOIN JWR_MISSING_BARCODE_UPLOAD X (NOLOCK) ON X.ARTICLE_CODE=A.ARTICLE_CODE AND C.AGENCY_CODE =X.AGENCY_CODE AND A.JOB_CODE=X.JOB_CODE 
		where x.sp_id=@csp_id
		
		IF EXISTS (SELECT TOP 1 'U' FROM JWR_MISSING_BARCODE_UPLOAD WHERE ISNULL(RATE,0)=0 and sp_id=@csp_id)
		BEGIN
			UPDATE X SET RATE =A.RATE
			FROM JOB_RATE_DET A(NOLOCK)
			JOIN ARTICLE B (NOLOCK) ON B.ARTICLE_CODE=A.ARTICLE_CODE
			JOIN JWR_MISSING_BARCODE_UPLOAD X (NOLOCK) ON X.ARTICLE_CODE=A.ARTICLE_CODE AND A.JOB_CODE=X.JOB_CODE	 
			WHERE --ISNULL(A.AGENCY_CODE,'')='' 	AND 
			ISNULL(X.RATE ,0)=0 	
			and x.sp_id=@csp_id
		END

		IF EXISTS (SELECT TOP 1 'U' FROM JWR_MISSING_BARCODE_UPLOAD WHERE ISNULL(RATE,0)=0 and sp_id=@csp_id)
		BEGIN
			UPDATE X SET RATE =A.Job_rate
			FROM art_jobs A(NOLOCK)
			JOIN ARTICLE B (NOLOCK) ON B.ARTICLE_CODE=A.ARTICLE_CODE
			JOIN JWR_MISSING_BARCODE_UPLOAD X (NOLOCK) ON X.ARTICLE_CODE=A.ARTICLE_CODE AND A.JOB_CODE=X.JOB_CODE	 
			WHERE --ISNULL(A.AGENCY_CODE,'')='' 	AND 
			ISNULL(X.RATE ,0)=0 	
			and x.sp_id=@csp_id
		END

		
	
	 
	SELECT A.agency_code,@DEPTID AS dept_id, '' AS product_code,REC_QTY quantity,'000' AS BIN_ID, a.JOB_CODE,cast('' as datetime ) AS  due_dt,isnull(rATE,0) AS job_rate,CAST('' AS VARCHAR (1000)) AS remarks,'01' AS company_code,
            a.ROW_ID,GETDATE() AS LAST_UPDATE,CAST('LATER' AS VARCHAR(40))  issue_id,0 AS no_hrs,
			CAST('' AS VARCHAR(40)) AS WIP_UID,'0000000' AS PREV_JOB_CODE,0 AS PREV_JOB_RATE,'' AS ref_no,'' AS design_code,Art.hsn_code,
			CAST(0 AS NUMERIC(10,2)) AS gst_percentage,
			CAST(0 AS NUMERIC(10,2)) AS igst_amount,
			CAST(0 AS NUMERIC(10,2)) AS cgst_amount,
			CAST(0 AS NUMERIC(10,2)) AS sgst_amount,
			CAST(0 AS NUMERIC(10,2)) AS xn_value_without_gst,
			CAST(0 AS NUMERIC(10,2)) AS xn_value_with_gst,
			CAST(art.purchase_price AS NUMERIC(10,2)) AS PURCHASE_PRICE,
			CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT	,
			CAST(0 AS BIT) AS CHKBILL, '' as ISSUE_NO,      
			art.ARTICLE_NO, art.ARTICLE_NAME,      
		    p1.PARA1_NAME,p2.PARA2_NAME,PARA3_NAME,'PCS' as UOM_NAME,           
		    CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,sm.SECTION_NAME, sd.SUB_SECTION_NAME,           
		   PARA4_NAME,PARA5_NAME,PARA6_NAME,'' as BIN_NAME,'' AS PREV_JOB_NAME ,jobs.job_name 
		  ,SKU_names.attr1_key_name,SKU_names.attr2_key_name,SKU_names.attr3_key_name,SKU_names.attr4_key_name,SKU_names.attr5_key_name,SKU_names.attr6_key_name,
		   SKU_names.attr7_key_name,SKU_names.attr8_key_name,SKU_names.attr9_key_name,SKU_names.attr10_key_name,SKU_names.attr11_key_name,SKU_names.attr12_key_name,
		   SKU_names.attr13_key_name,SKU_names.attr14_key_name,SKU_names.attr15_key_name,SKU_names.attr16_key_name,SKU_names.attr17_key_name,SKU_names.attr18_key_name,
		   SKU_names.attr19_key_name,SKU_names.attr20_key_name,SKU_names.attr21_key_name,SKU_names.attr22_key_name,SKU_names.attr23_key_name,SKU_names.attr24_key_name,
		   SKU_names.attr25_key_name ,CAST(0 AS BIT) AS [PRINT],@CERRMSG as errmsg,CAST('' AS VARCHAR(1000)) AS BUYER_NAME ,CAST('' AS VARCHAR(1000)) AS Merchant_NAME 

	 FROM JWR_MISSING_BARCODE_UPLOAD  A (NOLOCK)   
	 JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE =A.JOB_CODE 
	 JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =A.ARTICLE_CODE 
	 join sectionD sd (nolock) on sd.sub_section_code =ART.sub_section_code 
	 join sectionM sm (nolock) on sm.section_code =sd.section_code 
	 join para1 p1 (nolock) on p1.para1_code =A.PARA1_CODE 
	 join para2 p2 (nolock) on p2.para2_code =A.para2_code 
	 LEFT JOIN SKU_NAMES  (NOLOCK)  ON 1=2
	 WHERE A.SP_ID=@CSP_ID

	 
  end_proc:



end
