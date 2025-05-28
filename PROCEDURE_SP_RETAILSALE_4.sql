CREATE PROCEDURE SP_RETAILSALE_4
(  
  @CQUERYID   NUMERIC(2)=4,    
  @CWHERE   VARCHAR(MAX)='',    
  @CFINYEAR   VARCHAR(5)='',    
  @CDEPTID   VARCHAR(4)='',    
  @NNAVMODE   NUMERIC(2)=1,    
  @CWIZAPPUSERCODE VARCHAR(10)='',    
  @CREFMEMOID  VARCHAR(40)='',    
  @CREFMEMODT  DATETIME='',    
  @BINCLUDEESTIMATE BIT=1,    
  @CFROMDT   DATETIME='',    
  @CTODT    VARCHAR(50)='',  
  @bCardDiscount  BIT=0,  
  @cCustCode   VARCHAR(15)='',  
  @nSpId VARCHAR(40)='',  
  @nTableSuffix VARCHAR(100)='' , 
  @bAllowPatchedView BIT=1
) 
AS  
BEGIN  
	  declare @bpatchup_run bit 
	  select @bpatchup_run=patchup_run  from cmm01106  (nolock) where cm_id =@cWhere

	  --SELECT b.customer_code,a.order_id, a.order_type,a.product_code,a.REF_PRODUCT_CODE 
	  --into #tmporder
	  --from  WSL_ORDER_DET a (NOLOCK) 
   --   JOIN WSL_ORDER_mst b (NOLOCK) ON A.order_id =B.order_id 
	  --join cmd01106 c (nolock) on c.PRODUCT_CODE =a.product_code 
	  --where a.PRODUCT_CODE <>'' and c.cm_id=@CCM_ID and b.customer_code =@CCUSTOMER_CODE
	  --union
	  --SELECT b.customer_code,a.order_id, a.order_type,a.product_code,a.REF_PRODUCT_CODE 
	  --from  WSL_ORDER_DET a (NOLOCK) 
   --   JOIN WSL_ORDER_mst b (NOLOCK) ON A.order_id =B.order_id 
	  --join cmd01106 c (nolock) on c.PRODUCT_CODE =a.ref_product_code 
	  --where a.PRODUCT_CODE <>'' and c.cm_id=@CCM_ID and b.customer_code =@CCUSTOMER_CODE

IF (@nSpId<>'')  
   Goto LblOLdCashmemo
Else 
   Goto LblNEwCashmemo
          

   LblOLdCashmemo:
         
		 DECLARE @cCmd NVARCHAR(MAX),@cMastertable VARCHAR(MAX),@cDetailTable VARCHAR(MAX),@cKeyField varchar(MAX),@cWhereclause VARCHAR(MAX)  
  
		 IF OBJECT_ID('TEMPDB..#TMPCMD_PATCH','U') IS NOT NULL  
		  DROP TABLE #TMPCMD_PATCH  
  
		 SELECT convert(varchar(4),'') location_code, CM_ID,ROW_ID,mrp,NET,discount_percentage,discount_amount,cmm_discount_amount,gst_percentage,CAST(0 AS NUMERIC(14,2)) AS gst_Amount,xn_value_without_gst,  
		 xn_value_with_gst ,igst_amount,cgst_amount,sgst_amount ,basic_discount_amount,basic_discount_percentage,product_code,  
		 convert(varchar(200),'') buyer_order_no,convert(varchar(20),'') customer_code,REF_ORDER_ID,bin_id,convert(numeric(10,2),0) quantity_in_stock  
		 INTO #TMPCMD_PATCH FROM CMD01106 WHERE 1=2  
  
        
		 SELECT @cMastertable=(CASE WHEN @nSpId<>'' THEN 'SLS_CMM01106_UPLOAD'ELSE 'CMM01106' END),  
			 @cDetailtable=(CASE WHEN @nSpId<>'' THEN 'SLS_CMD01106_UPLOAD' ELSE 'CMD01106' END),  
			 @cKeyField=(CASE WHEN @nSpId<>'' THEN 'sp_id' ELSE 'cm_id' END),  
			 @cWhereclause=(CASE WHEN @nSpId<>'' THEN 'cmm.Sp_id='''+@nSpId+'''' ELSE 'cmm.cm_id='''+@cWhere+'''' END)  
  
		 IF @nTableSuffix<>''  
		  SELECT  @cMastertable=@cMastertable+@nTableSuffix,  
		  @cDetailtable=@cDetailtable+@nTableSuffix  

		   TRUNCATE TABLE  #TMPCMD_PATCH  
  
		 SET @cCmd=N'SELECT cmm.location_code, customer_code,product_code,cmd.bin_id,cmd.REF_ORDER_ID,cmd.SP_ID as cm_id,cmd.ROW_ID ,cmd.mrp,cmd.NET,cmd.discount_percentage,cmd.discount_amount,cmd.cmm_discount_amount,cmd.gst_percentage,  
		 cmd.xn_value_without_gst,cmd.xn_value_with_gst ,cmd.igst_amount,cmd.cgst_amount,cmd.sgst_amount,cmd.basic_discount_amount,cmd.basic_discount_percentage  
		 FROM '+@cDetailTable+'  CMD  (NOLOCK)  
		 JOIN '+@cMasterTable+' cmm (NOLOCK) ON cmm.sp_id=cmd.sp_id  
		 WHERE '+@cWhereclause  

  
		  PRINT @ccmd  
		 INSERT INTO #TMPCMD_PATCH (location_code,customer_code,product_code,bin_id,REF_ORDER_ID,cm_ID,ROW_ID ,mrp,NET,discount_percentage,discount_amount,cmm_discount_amount,gst_percentage,  
		 xn_value_without_gst,xn_value_with_gst ,igst_amount,cgst_amount,sgst_amount,basic_discount_amount,basic_discount_percentage)  
		 EXEC SP_EXECUTESQL @cCmd  


		   update a SET buyer_order_no=(CASE WHEN ORD.product_code IS NULL THEN '''' ELSE RIGHT(ORD.order_id,10) END),  
		   quantity_in_stock=isnull(p.quantity_in_stock,0)  
		   FROM #TMPCMD_PATCH a   
		   JOIN (SELECT b.customer_code,a.order_id, a.order_type,a.product_code,a.REF_PRODUCT_CODE from  WSL_ORDER_DET a (NOLOCK)   
				  JOIN WSL_ORDER_mst b (NOLOCK) ON A.order_id =B.order_id   
			left join #TMPCMD_PATCH c ON c.product_code=a.product_code  
			left join #TMPCMD_PATCH d ON d.product_code=a.ref_product_code  
				   WHERE b.CANCELLED =0 AND ISNULL(a.CANCELLED ,0)=0 and (isnull(a.product_code,'')<>'' or isnull(a.rEF_PRODUCT_CODE,'')<>'')  
			 and (c.PRODUCT_CODE is not null or d.PRODUCT_CODE is not null)  
				 ) ORD ON A.PRODUCT_CODE=(CASE WHEN ORD.ORDER_TYPE=1 THEN ORD.REF_PRODUCT_CODE ELSE ORD.PRODUCT_CODE END)  
		  AND a.CUSTOMER_CODE=ORD.CUSTOMER_CODE  
		  LEFT OUTER JOIN PMT01106 P  (NOLOCK) ON P.PRODUCT_CODE=A.PRODUCT_CODE   
		  AND P.BIN_ID=A.BIN_ID AND P.DEPT_ID = a.location_code and isnull(a.REF_ORDER_ID,'''')=isnull(p.bo_order_id,'')   
		  AND isnull(p.Pick_list_id,'') =''  
   
               
		 SET @cCmd=N'SELECT R1.mrp,R1.NET,R1.discount_percentage,R1.discount_amount,R1.cmm_discount_amount,R1.gst_percentage,R1.gst_Amount,R1.xn_value_without_gst,  
		 R1.xn_value_with_gst ,R1.igst_amount,R1.cgst_amount,R1.sgst_amount,R1.basic_discount_amount,R1.basic_discount_percentage,A.*,  
		 (CASE WHEN a.quantity>0 THEN 0 ELSE a.basic_discount_percentage END) as last_sls_discount_percentage,  
		 (CASE WHEN a.quantity>0 THEN '''' ELSE a.scheme_name END) as last_applied_scheme_name,A.SR_NO AS SRNO,    
			EMP.EMP_NAME, A.PRODUCT_CODE, SKU.ARTICLE_CODE,  SKU.PARA1_CODE,  SKU.PARA2_CODE, SKU.PARA3_CODE, SN.UOM AS UOM_NAME,         
			cmm.location_code DEPT_ID, sku.barcode_CODING_SCHEME as CODING_SCHEME,  CAST(0 AS BIT) AS INACTIVE,r1.QUANTITY_IN_STOCK,     
			SKU.PURCHASE_PRICE,  SKU.MRP,SKU.WS_PRICE,       SKU.PARA4_CODE,SKU.PARA5_CODE,SKU.PARA6_CODE,      
			CAST('''' AS VARCHAR(10)) AS UOM_CODE,ISNULL(SN.SN_UOM_TYPE,0) AS [UOM_TYPE],  
			  CONVERT (BIT,(CASE WHEN A.QUANTITY <0 THEN 1 ELSE 0 END)) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,    
		  '''' AS HOLD_ID,'''' AS CMD_HOLD_ROW_ID, A.MRP AS [LOCSKU_MRP],SKU.PRODUCT_NAME,    
		   EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_NAME AS EMP_NAME2  ,(CASE WHEN ISNULL(SKU.FIX_MRP,0)=0 THEN SKU.mrp ELSE SKU.FIX_MRP END) AS [FIX_MRP],  
		   (CASE WHEN ISNULL(A.hold_for_alter,0)=0 THEN ''N'' ELSE ''Y'' END) AS [HOLD_FOR_ALTER_TXT],  
		   (CASE WHEN ISNULL(A.PACK_SLIP_ID,'''')='''' THEN '''' ELSE RIGHT(A.PACK_SLIP_ID,10 ) END) AS [PACK_SLIP_NO]  
		   ,ISNULL(BIN.BIN_NAME,'''') AS [BIN_NAME],'''' AS ARTICLE_ALIAS ,'''' sub_section_code,'''' section_code,  
		   CONVERT(BIT,0 ) as [BRANDWISE_DISC],dbo.Fn_GetSlsTitle(1,a.row_id) as SLS_TITLE,ISNULL(N.narration,'''') AS [NARRATION],  
		   (case when tax_method= 2 then ''Exclusive'' Else ''Inclusive'' End) As Tax_method_type,  
		   SKU.ONLINE_PRODUCT_CODE AS ONLINE_BAR_CODE ,CAST('''' AS varchar(40)) AS SP_ID,'''' AS TEMP_ROW_ID,SN.sku_item_type AS  ITEM_TYPE ,  
		   A.PRODUCT_CODE AS ORG_PRODUCT_CODE, r1.buyer_order_no,  a.REF_ORDER_ID,
		   CAST(CASE WHEN CHARINDEX(''@'',A.PRODUCT_CODE)=0 THEN '''' ELSE   
		   (SUBSTRING(A.PRODUCT_CODE,CHARINDEX(''@'',A.PRODUCT_CODE)+1,15)) END AS VARCHAR(100))  AS BATCH_LOT_NO,  
		   SKU.BATCH_NO,SKU.EXPIRY_DT,ISNULL(JOBS.job_name,'''') AS [JOB_NAME],CAST('''' AS DATETIME) AS [rps_last_update],SKU.er_flag  
		 ,CAST(0 AS BIT) AS barcodebased_flatdisc_applied,CAST(0 AS BIT) AS bngn_not_applied,CAST(0 AS BIT) AS happy_hours_applied,ISNULL(sn.SN_ARTICLE_PACK_SIZE,0) AS ARTICLE_PACK_SIZE,
		 A.weighted_avg_disc_amt,A.weighted_avg_disc_pct,SN.*  
		 FROM '+@cDetailTable+'  A  (NOLOCK)   
		  JOIN '+@cMastertable+'  CMM (NOLOCK) ON CMM.'+@cKeyField+'=A.'+@cKeyField+'  
		  JOIN #TMPCMD_PATCH  R1 (NOLOCK) ON R1.CM_ID=A.'+@cKeyField+' AND R1.ROW_ID=A.ROW_ID  
		  JOIN SKU  (NOLOCK) ON SKU.PRODUCT_CODE=A.PRODUCT_CODE    
		  LEFT JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code  
		  LEFT OUTER JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID    
		   LEFT OUTER JOIN NRM N (NOLOCK) ON N.NRM_ID=ISNULL(A.NRM_ID  ,''0000000'')  
		  LEFT OUTER JOIN EMPLOYEE EMP  (NOLOCK) ON A.EMP_CODE = EMP.EMP_CODE     
		  LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON A.EMP_CODE1 = EMP1.EMP_CODE       
		  LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON A.EMP_CODE2 = EMP2.EMP_CODE      
		 LEFT OUTER JOIN JOBS JOBS(NOLOCK) ON JOBS.job_code=A.ALT_JOB_CODE  
		 WHERE '+@cWhereclause+'  ORDER BY  A.SR_NO'  
		 PRINT @cCmd  
		 EXEC SP_EXECUTESQL @cCmd  

   goto End_proc

   LblNEwCashmemo:


	SELECT @bAllowPatchedView =VALUE FROM USER_ROLE_DET A (NOLOCK)--ADDED
				JOIN USERS B (NOLOCK)--ADDED
				ON A.ROLE_ID=B.ROLE_ID 
				WHERE USER_CODE=@CWIZAPPUSERCODE 
				AND FORM_NAME='FRMSALE' 
				AND FORM_OPTION='ALLOW_VIEW_PATCH_DATA'

	 IF @bAllowPatchedView=0 AND  isnull(@bpatchup_run,0) =1
	 BEGIN
        
	
		   select a.cm_id, A.SR_NO srno,a.product_code,a.quantity,sn.uom uom_name,a.FIX_MRP,ISNULL(a.old_mrp,0) MRP,ISNULL(A.old_discount_percentage,0) discount_percentage,
		         ISNULL(A.old_discount_amount,0) discount_amount,'' Tax_status,(CASE WHEN a.quantity>0 THEN 0 ELSE a.basic_discount_percentage END) as last_sls_discount_percentage,  
		        a.tax_percentage,a.Tax_amount,ISNULL(a.OLD_NET,0) net,EMP.emp_name,EMP1.emp_name emp_name1,EMP2.emp_name emp_name2,item_desc,Article_no,sub_section_name,
				section_name,row_id,cmm.location_Code dept_id,a.emp_code,emp_code1,emp_code2,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
				(CASE WHEN ISNULL(A.hold_for_alter,0)=0 THEN 'N' ELSE 'Y' END) AS hold_for_alter_txt,hold_for_alter,
				(CASE WHEN ISNULL(A.PACK_SLIP_ID,'')='' THEN '' ELSE RIGHT(A.PACK_SLIP_ID,10 ) END) pack_slip_no,pack_slip_id,
				xn_type,FOC_QUANTITY,Article_Alias,repeat_pur_order,n.nrm_id,ISNULL(N.narration,'')  narration,'' buyer_order_no,item_round_off,
				(case when tax_method= 2 then 'Exclusive' Else 'Inclusive' End) Tax_method_type,tax_method,
				A.old_discount_percentage basic_discount_percentage,card_discount_percentage,a.old_discount_amount basic_discount_amount,card_discount_amount,
				a.hsn_code,ISNULL(old_gst_percentage,0) gst_percentage,a.OLD_igst_amount igst_amount,a.OLD_cgst_amount cgst_amount,a.OLD_Sgst_amount sgst_amount,ref_sls_memo_no,ref_sls_memo_dt,'' ATTR1_NAME,bin_name,0 as quantity_in_stock,manual_tax_method,
				a.manual_discount,manual_dp,manual_mrp,scheme_name,   CAST(CASE WHEN CHARINDEX('@',A.PRODUCT_CODE)=0 THEN '' ELSE (SUBSTRING(A.PRODUCT_CODE,CHARINDEX('@',A.PRODUCT_CODE)+1,15)) END AS VARCHAR(100))  AS BATCH_LOT_NO,  
				sn.batch_no BATCH_NO,sn.expiry_dt Expiry_dt,attr1_key_name,attr2_key_name,attr3_key_name,
				attr4_key_name,attr5_key_name,attr6_key_name,attr7_key_name,attr8_key_name,attr9_key_name,attr10_key_name,attr11_key_name,attr12_key_name,
				attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,attr19_key_name,attr20_key_name,
				attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,attr25_key_name,gst_cess_percentage,gst_cess_amount,ARTICLE_NAME,PARA7_NAME,
				pcs_quantity,mtr_quantity,MANUAL_DISCOUNT_PERCENTAGE,MANUAL_DISCOUNT_AMOUNT,ManualDA_changed,cmd_remarks,ISNULL(old_cmm_discount_amount,0) CMM_DISCOUNT_AMOUNT,
				a.old_xn_value_with_gst xn_value_with_gst ,a.old_xn_value_without_gst  xn_value_without_gst ,sn.sku_item_type as ITEM_TYPE,A.bin_id,sn.SN_Uom_type as UOM_TYPE
				,ISNULL(sn.SN_ARTICLE_PACK_SIZE,0) AS ARTICLE_PACK_SIZE,A.pack_slip_row_id,sn.stock_na,a.REF_ORDER_ID,A.weighted_avg_disc_amt,A.weighted_avg_disc_pct,sn.*
		from cmd01106 A (nolock)
		join cmm01106 cmm (nolock) on a.cm_id =cmm.cm_id 
		join sku_names sn (Nolock) on a.PRODUCT_CODE =sn.product_Code 
		JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID  
		LEFT OUTER JOIN EMPLOYEE EMP  (NOLOCK) ON A.EMP_CODE = EMP.EMP_CODE   
		LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON A.EMP_CODE1 = EMP1.EMP_CODE     
		LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON A.EMP_CODE2 = EMP2.EMP_CODE   
		LEFT OUTER JOIN NRM N (NOLOCK) ON N.NRM_ID=ISNULL(A.NRM_ID  ,'0000000')
		where a.cm_id=@cWhere
		  ORDER BY  A.SR_NO



	 END
	 else 
	 begin
	     
		 select a.cm_id, A.SR_NO srno,a.product_code,a.quantity,sn.uom uom_name,a.FIX_MRP,a.MRP,a.discount_percentage,a.discount_amount,'' Tax_status,
		        a.tax_percentage,a.Tax_amount,net,EMP.emp_name,EMP1.emp_name emp_name1,EMP2.emp_name emp_name2,item_desc,Article_no,sub_section_name,
				section_name,row_id,cmm.location_Code dept_id,a.emp_code,emp_code1,emp_code2,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
				(CASE WHEN ISNULL(A.hold_for_alter,0)=0 THEN 'N' ELSE 'Y' END) AS hold_for_alter_txt,hold_for_alter,
				(CASE WHEN ISNULL(A.PACK_SLIP_ID,'')='' THEN '' ELSE RIGHT(A.PACK_SLIP_ID,10 ) END) pack_slip_no,pack_slip_id,
				xn_type,FOC_QUANTITY,Article_Alias,repeat_pur_order,n.nrm_id,ISNULL(N.narration,'')  narration,'' buyer_order_no,item_round_off,
				(case when tax_method= 2 then 'Exclusive' Else 'Inclusive' End) Tax_method_type,tax_method,
				basic_discount_percentage,card_discount_percentage,basic_discount_amount,card_discount_amount,
				a.hsn_code,a.gst_percentage,igst_amount,cgst_amount,sgst_amount,ref_sls_memo_no,ref_sls_memo_dt,'' ATTR1_NAME,bin_name,0 as quantity_in_stock,manual_tax_method,
				a.manual_discount,manual_dp,manual_mrp,scheme_name,   CAST(CASE WHEN CHARINDEX('@',A.PRODUCT_CODE)=0 THEN '' ELSE (SUBSTRING(A.PRODUCT_CODE,CHARINDEX('@',A.PRODUCT_CODE)+1,15)) END AS VARCHAR(100))  AS BATCH_LOT_NO,  
				sn.batch_no  BATCH_NO,sn.expiry_dt Expiry_dt,attr1_key_name,attr2_key_name,attr3_key_name,a.REF_ORDER_ID,
				attr4_key_name,attr5_key_name,attr6_key_name,attr7_key_name,attr8_key_name,attr9_key_name,attr10_key_name,attr11_key_name,attr12_key_name,
				attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,attr19_key_name,attr20_key_name,
				attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,attr25_key_name,gst_cess_percentage,gst_cess_amount,ARTICLE_NAME,PARA7_NAME,
				pcs_quantity,mtr_quantity,MANUAL_DISCOUNT_PERCENTAGE,MANUAL_DISCOUNT_AMOUNT,ManualDA_changed,cmd_remarks,CMM_DISCOUNT_AMOUNT,
				A.xn_value_with_gst ,A.xn_value_without_gst  ,sn.sku_item_type as ITEM_TYPE,A.BIN_ID,sn.SN_Uom_type as UOM_TYPE,ISNULL(sn.SN_ARTICLE_PACK_SIZE,0) AS ARTICLE_PACK_SIZE
				,A.pack_slip_row_id,(CASE WHEN a.quantity>0 THEN 0 ELSE a.basic_discount_percentage END) as last_sls_discount_percentage ,SN.stock_na,A.weighted_avg_disc_amt,A.weighted_avg_disc_pct,sn.*
		from cmd01106 A (nolock)
		join cmm01106 cmm (nolock) on a.cm_id =cmm.cm_id 
		join sku_names sn (Nolock) on a.PRODUCT_CODE =sn.product_Code 
		JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID  
		LEFT OUTER JOIN EMPLOYEE EMP  (NOLOCK) ON A.EMP_CODE = EMP.EMP_CODE   
		LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON A.EMP_CODE1 = EMP1.EMP_CODE     
		LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON A.EMP_CODE2 = EMP2.EMP_CODE   
		LEFT OUTER JOIN NRM N (NOLOCK) ON N.NRM_ID=ISNULL(A.NRM_ID  ,'0000000')
		where a.cm_id=@cWhere
		  ORDER BY  A.SR_NO

	 end

	 

END_PROC:

end