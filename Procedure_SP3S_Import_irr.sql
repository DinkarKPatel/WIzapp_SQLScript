CREATE   PROCEDURE SP3S_Import_irr
(
 @NUPDATEMODE		NUMERIC(2,0),
 @CMEMONOPREFIX		VARCHAR(50),
 @CLOCID				VARCHAR(5)='',
 @CTABLENAME VARCHAR(100)='',
 @CFILENAME VARCHAR(1000)=''

)
AS
BEGIN
      
	  
	 DECLARE @CSTEP varchar(100),@CERRMSG varchar(100),@dirm_memo_dt datetime, @CFINYEAR	VARCHAR(10),
	         @CSPID VARCHAR(10),@bcallsavetran bit

	  
	  DECLARE @Error TABLE ( ERRMSG VARCHAR(2000), product_code VARCHAR(100))

	 BEGIN TRY

	      if @CMEMONOPREFIX=''
		    set @CMEMONOPREFIX= @CLOCID+'R'

			set @bcallsavetran=0
	      
		  IF EXISTS (SELECT TOP 1 'U' FROM  IRM01106 WHERE FILE_NAMES=@CFILENAME)
		  begin
		      SET @CERRMSG='FileName already exists'
			  GOTO END_PROC
		  end

	      SET @DIRM_MEMO_DT=CONVERT(VARCHAR(10),GETDATE(),121)
		  select @CFINYEAR='01'+dbo.FN_GETFINYEAR (getdate())
		  SET @CSPID=@@SPID 
	       
	      DELETE A FROM IRR_IRM01106_UPLOAD A (NOLOCK) WHERE A.SP_ID =@CSPID
		  DELETE A FROM IRR_IRD01106_UPLOAD A (NOLOCK) WHERE A.SP_ID =@CSPID

	       INSERT IRR_IRM01106_UPLOAD	( APPROVED, barcode_prefix, BIN_ID, company_code, dept_id, edt_user_code, fin_year, inc_Type, INS_MIS_PC_AT_LOC, irm_memo_dt, irm_memo_id, irm_memo_no, 
		      last_update, memo_time, rate_type, reconciled, REMARKS, revision_type, sent_for_recon, sent_to_ho, sent_to_loc, type, user_code,SP_ID,FILE_NAMES )  
		   SELECT 	0  APPROVED,'' BARCODE_PREFIX,'000' BIN_ID,'01' COMPANY_CODE,@CLOCID DEPT_ID,'0000000' EDT_USER_CODE,@CFINYEAR FIN_YEAR, 
		   0 INC_TYPE,0 INS_MIS_PC_AT_LOC,@DIRM_MEMO_DT IRM_MEMO_DT, 
		   'LATER' IRM_MEMO_ID,'LATER' IRM_MEMO_NO,GETDATE() LAST_UPDATE,GETDATE() MEMO_TIME,0 RATE_TYPE,0 RECONCILED,'' REMARKS,0 REVISION_TYPE,0 SENT_FOR_RECON,0 SENT_TO_HO,0 SENT_TO_LOC,
		   1 TYPE, '0000000' AS USER_CODE,@CSPID AS SP_ID ,@CFILENAME as FILE_NAMES




		   DECLARE @DTSQL NVARCHAR(MAX)
		   
			SET @DTSQL=N'SELECT 	  A.article_code,''000'' AS BIN_ID,''01'' company_code,'''+@CLOCID+''' dept_id,'''' fin_year,''LATER'' irm_memo_id,0 LABEL_COPIES,GETDATE() last_update,A.FIX_MRP  NEW_FIX_MRP, 
		    A.hsn_code 	NEW_HSN_CODE,tmp.mrp  new_mrp,''0000000'' new_mrp_fc_code,'''' new_product_code, 
		    ws_price new_wsp,A.article_code  old_article_code,A.FIX_MRP OLD_FIX_MRP,A.HSN_CODE  OLD_HSN_CODE,A.mrp old_mrp,''0000000'' old_mrp_fc_code,'''' old_online_product_Code, 
		    A.para1_code old_para1_code,A.para2_code  old_para2_code,A.para3_code  old_para3_code,A.para4_code  old_para4_code, 
			A.PARA5_CODE old_para5_code,A.PARA6_CODE  old_para6_code,ART.UOM_CODE old_uom_code,A.ws_price  old_wsp, online_product_code, A.para1_code, A.para2_code, 
			A.para3_code, A.para4_code, A.para5_code, A.para6_code,0 print_label, 
			TMP.product_code,1 quantity,NEWID() row_id,'''+@CSPID+''' SP_ID,
			ROW_NUMBER() OVER (ORDER BY A.PRODUCT_CODE ) srno,ART.UOM_CODE uom_code,'''' VENDOR_EAN_NO ,tmp.REFERENCE as Reference_No,CHANGE_DATE as Reference_DT
			FROM  '+@CTABLENAME+' TMP
			JOIN SKU A (NOLOCK) ON TMP.PRODUCT_CODE=A.PRODUCT_CODE
			JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =A.ARTICLE_CODE '
			PRINT @DTSQL
	
			 INSERT IRR_IRD01106_UPLOAD	( article_code, BIN_ID, company_code, dept_id, fin_year, irm_memo_id, LABEL_COPIES, last_update, NEW_FIX_MRP, NEW_HSN_CODE, new_mrp, new_mrp_fc_code, new_product_code, new_wsp, old_article_code, OLD_FIX_MRP, OLD_HSN_CODE, old_mrp, old_mrp_fc_code, old_online_product_Code, old_para1_code, old_para2_code, old_para3_code, old_para4_code, old_para5_code, old_para6_code, old_uom_code, old_wsp, online_product_code, para1_code, para2_code, para3_code, para4_code, para5_code, para6_code, print_label, product_code, quantity, row_id, 
			 SP_ID, srno, uom_code, VENDOR_EAN_NO ,Reference_No,Reference_DT)  
			 EXEC SP_EXECUTESQL @DTSQL

			 IF EXISTS (SELECT TOP 1 'U' FROM IRR_IRD01106_UPLOAD A (NOLOCK)
			 LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE 
			 WHERE B.PRODUCT_CODE IS NULL AND A.SP_ID=@CSPID)
			 BEGIN
			     SET @CERRMSG='BARCODE NOT FOUND'

				 SELECT A.PRODUCT_CODE ,'BARCODE NOT FOUND' AS ERRMSG 
				 FROM IRR_IRD01106_UPLOAD A (NOLOCK)
				 LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE 
				 WHERE B.PRODUCT_CODE IS NULL AND A.SP_ID=@CSPID

				 GOTO END_PROC
			 END

			  

			  IF EXISTS (SELECT TOP 1 'U' FROM IRR_IRD01106_UPLOAD WHERE SP_ID=@CSPID and isnull(product_code,'')='' )
			  BEGIN
			     SET @CERRMSG='BLANK BARCODE DETAILS PLEASE CHECK'
			      GOTO END_PROC

			  END
		     
		
			 set @bcallsavetran=1
			-- INSERT INTO @Error
			 EXEC SAVETRAN_IRR
			    @NUPDATEMODE=1,
				@NSPID=@CSPID,
				@CMEMONOPREFIX=@CMEMONOPREFIX,
				@CFINYEAR=@CFINYEAR,
				@CMACHINENAME='',
				@CWINDOWUSERNAME='',
				@CWIZAPPUSERCODE='',
				@CMEMOID='LATER',
				@CLOCID=@CLOCID,
				@BTHROUGHIMPORT=0,
				@BPASTE=0



			


		

     END TRY
	  
	  BEGIN CATCH
			PRINT 'ENTER CATCH BLOCK'
			SET @CERRMSG='ERROR IN PROCEDURE SP3S_GENERATE_INVOICE_AGAINSTPS : STEP #'+@CSTEP+' '+ERROR_MESSAGE()
			GOTO END_PROC 
	  END CATCH
   END_PROC:


   IF ISNULL(@CERRMSG,'')<>'' and isnull(@bcallsavetran,0)=0
         SELECT @CERRMSG AS ERRMSG,'' AS memo_id
	

	   DELETE FROM IRR_IRM01106_UPLOAD WHERE SP_ID=@CSPID
	
  



END




