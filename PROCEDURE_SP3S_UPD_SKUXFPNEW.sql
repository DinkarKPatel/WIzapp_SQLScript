create PROCEDURE SP3S_UPD_SKUXFPNEW  
(   
  @CXN_TYPE VARCHAR(50)  
 ,@CXN_ID VARCHAR(50)  
 ,@BCALLEDFROMREBUILD BIT=0  
)   
--WITH ENCRYPTION  
AS  
BEGIN  
  
  
 DECLARE @CPRODUCT_CODE VARCHAR(50),@DRECEIPT_DT DATETIME,@CPRE_XN_ID VARCHAR(50),@BCANCELLED BIT,  
 @CHODEPTID VARCHAR(5),@CLOCATIONID VARCHAR(5)  
  
 SELECT TOP 1  @CLOCATIONID=VALUE FROM config WHERE config_option='LOCATION_ID'  
 SELECT TOP 1  @CHODEPTID=VALUE FROM config WHERE config_option='HO_LOCATION_ID'  
  
  IF OBJECT_ID ('TEMPDB..#TMPSKUXFP','U') IS NOT NULL  
     DROP TABLE #TMPSKUXFP  
  
     SELECT CAST('' as varchar(5)) AS DEPT_ID ,PRODUCT_CODE,ROW_ID   
     into #TMPSKUXFP  
     FROM PID01106 WHERE 1=2  
  
 IF @CXN_TYPE='PUR'  
 BEGIN  
  --INSERTING NEW PRODUCT_CODES PRICE SENT TO THIS LOCATION.  
  
  IF @CHODEPTID<>@CLOCATIONID  
  BEGIN  
  
    ;WITH CTE AS  
    (  
     SELECT D.location_Code  AS DEPT_ID ,C.PRODUCT_CODE,C.ROW_ID,  
     SR=ROW_NUMBER () OVER (PARTITION BY D.location_Code  ,C.PRODUCT_CODE ORDER BY RECEIPT_DT DESC)  
     FROM PID01106 C (NOLOCK)   
     JOIN PIM01106 D (NOLOCK) ON C.MRR_ID=D.MRR_ID  
     WHERE D.INV_MODE=2 AND D.CANCELLED=0  
     and c.MRR_ID=@CXN_ID  
    )  
    INSERT INTO #TMPSKUXFP(DEPT_ID,PRODUCT_CODE,ROW_ID)  
    SELECT DEPT_ID,PRODUCT_CODE,ROW_ID  FROM CTE WHERE SR=1  
  
    
	 SELECT A.DEPT_ID ,B.PRODUCT_CODE ,a.Receipt_dt,a.inv_no,a.inv_dt,
	        XFER_PRICE= (B.PURCHASE_PRICE-(B.PURCHASE_PRICE*A.DISCOUNT_PERCENTAGE/100)  
           +(CASE WHEN A.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.TAX_AMOUNT ,0))/B.INVOICE_QUANTITY) ELSE 0 END))   ,
		    xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,
			xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,
			xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,
			xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,
		    xfer_gst_cess_amount=b.Gst_Cess_Amount,
			Party_Pan_No=(case when  SUBSTRING (LM.AC_GST_NO,3,10)<>'' THEN  SUBSTRING (LM.AC_GST_NO,3,10) ELSE LM.PAN_NO  END ),
		    Loc_Pan_No=(case when  SUBSTRING (loc.loc_gst_no ,3,10)<>'' THEN  SUBSTRING (loc.loc_gst_no,3,10) ELSE loc.PAN_NO  END),
			loc_pp=CAST(0 AS NUMERIC(18,2)),a.challan_source_location_code
     into #tmpskuxfp_PURloc 
    FROM PIM01106 A (NOLOCK)  
    JOIN PID01106 B (NOLOCK) ON A.MRR_ID=B.MRR_ID  
    JOIN #TMPSKUXFP TMP ON TMP.ROW_ID =B.ROW_ID  
	JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID =A.DEPT_ID 
	JOIN LMP01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
    WHERE A.CANCELLED=0  AND ISNULL(A.RECEIPT_DT,'')<>'' AND A.INV_MODE=2   
    AND ISNULL(B.PRODUCT_CODE,'')<>'' 
	
	UPDATE A  SET loc_pp=a.xfer_price_without_gst
	FROM #tmpskuxfp_PURloc A 
	WHERE ISNULL(PARTY_PAN_NO,'')<>ISNULL(LOC_PAN_NO,'')

	UPDATE A  SET loc_pp=B.PURCHASE_PRICE
	FROM #tmpskuxfp_PURloc A 
	JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE
	WHERE ISNULL(PARTY_PAN_NO,'')=ISNULL(LOC_PAN_NO,'')


    UPDATE a SET XFER_PRICE=b.XFER_PRICE ,  
                  CURRENT_XFER_PRICE= b.XFER_PRICE ,  
                  RECEIPT_DT=b.RECEIPT_DT  ,
	              GROUP_INV_NO=b.INV_NO,
				  GROUP_INV_DT=b.INV_DT,
				  xfer_price_without_gst =b.xfer_price_without_gst ,
				  xfer_price_igst_amount =b.xfer_price_igst_amount,
				  xfer_price_cgst_amount =b.xfer_price_cgst_amount ,
				  xfer_price_sgst_amount =b.xfer_price_sgst_amount ,
	              loc_pp=b.loc_pp
    FROM SKU_XFP A (NOLOCK)  
	JOIN #tmpskuxfp_PURloc B ON  A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID=B.DEPT_ID
    
  
  
    INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,GROUP_INV_NO,GROUP_INV_DT,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,
	      xfer_discount_amount,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp, challan_source_location_code )    
    SELECT distinct  A.PRODUCT_CODE,A.DEPT_ID,A.XFER_PRICE,A.XFER_PRICE CURRENT_XFER_PRICE,A.RECEIPT_DT,
	                 0 AS DISCOUNT_PERCENTAGE,A.RECEIPT_DT FIRST_RECEIPT_DT,A.Inv_no GROUP_INV_NO,A.inv_dt GROUP_INV_DT,
					 a.xfer_price_without_gst,a.xfer_price_igst_amount,a.xfer_price_cgst_amount,a.xfer_price_sgst_amount,
	                 0 as xfer_discount_amount,0 as xfer_freight_amount,0 as xfer_other_charges,0 as xfer_round_off,a.xfer_gst_cess_amount,a.loc_pp,
	                 a.challan_source_location_code

    FROM #tmpskuxfp_PURloc A (NOLOCK)  
    LEFT OUTER JOIN sku_xfp b (NOLOCK) ON a.product_code=b.product_code AND a.dept_id=b.DEPT_ID   
    WHERE b.product_code is null  
  
   GOTO END_PROC  
   END  
   ELSE   
   BEGIN  
  
     ;WITH CTE AS  
    (  
     SELECT D.location_Code  AS DEPT_ID ,C.PRODUCT_CODE,C.ROW_ID,  
     SR=ROW_NUMBER () OVER (PARTITION BY D.location_Code  ,C.PRODUCT_CODE ORDER BY RECEIPT_DT DESC)  
     FROM IND01106  C (NOLOCK)   
	 join inm01106 inm (nolock) on c.inv_id =inm.inv_id 
     JOIN PIM01106 D (NOLOCK) ON C.INV_ID =D.INV_ID  
     WHERE D.INV_MODE=2 AND D.CANCELLED=0 and inm.CANCELLED =0  
     and d.MRR_ID=@CXN_ID  
    )  
    INSERT INTO #TMPSKUXFP(DEPT_ID,PRODUCT_CODE,ROW_ID)  
    SELECT DEPT_ID,PRODUCT_CODE,ROW_ID  FROM CTE WHERE SR=1  


	
  
    SELECT A.DEPT_ID ,B.PRODUCT_CODE ,a.Receipt_dt,a.inv_no,a.inv_dt,
	        XFER_PRICE= (B.net_rate -(B.net_rate*A.DISCOUNT_PERCENTAGE/100)  
          +(CASE WHEN A.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.item_TAX_AMOUNT ,0))/B.INVOICE_QUANTITY) ELSE 0 END))    ,
		    xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,
			xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,
			xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,
			xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,
		    xfer_gst_cess_amount=b.Gst_Cess_Amount,
			Party_Pan_No=(case when  SUBSTRING (LM.AC_GST_NO,3,10)<>'' THEN  SUBSTRING (LM.AC_GST_NO,3,10) ELSE LM.PAN_NO  END ),
		    Loc_Pan_No=(case when  SUBSTRING (loc.loc_gst_no ,3,10)<>'' THEN  SUBSTRING (loc.loc_gst_no,3,10) ELSE loc.PAN_NO  END),
			loc_pp=CAST(0 AS NUMERIC(18,2)),a.challan_source_location_code
     into #tmpskuxfp_PURHo 
    FROM PIM01106 A (NOLOCK)  
    JOIN IND01106  B (NOLOCK) ON A.INV_ID=B.INV_ID 
	JOIN INM01106 INM (NOLOCK) ON INM.INV_ID =A.INV_ID  
    JOIN #TMPSKUXFP TMP ON TMP.ROW_ID =B.ROW_ID  
	join location loc (nolock) on loc.dept_id =a.DEPT_ID 
	join LMp01106 lm (nolock) on lm.AC_CODE =a.ac_code 
    WHERE A.CANCELLED=0  AND ISNULL(A.RECEIPT_DT,'')<>'' AND A.INV_MODE=2   
    AND ISNULL(B.PRODUCT_CODE,'')<>''   AND INM.CANCELLED=0
  

   	UPDATE A  SET loc_pp=a.xfer_price_without_gst
	FROM #tmpskuxfp_PURHO A 
	WHERE ISNULL(PARTY_PAN_NO,'')<>ISNULL(LOC_PAN_NO,'')

	UPDATE A  SET loc_pp=B.PURCHASE_PRICE
	FROM #tmpskuxfp_PURHO A 
	JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE
	WHERE ISNULL(PARTY_PAN_NO,'')=ISNULL(LOC_PAN_NO,'')


    UPDATE a SET XFER_PRICE=b.XFER_PRICE ,  
                  CURRENT_XFER_PRICE= b.XFER_PRICE ,  
                  RECEIPT_DT=b.RECEIPT_DT  ,
	              GROUP_INV_NO=b.INV_NO,
				  GROUP_INV_DT=b.INV_DT,
				  xfer_price_without_gst =b.xfer_price_without_gst ,
				  xfer_price_igst_amount =b.xfer_price_igst_amount,
				  xfer_price_cgst_amount =b.xfer_price_cgst_amount ,
				  xfer_price_sgst_amount =b.xfer_price_sgst_amount ,
	              loc_pp=b.loc_pp
    FROM SKU_XFP A (NOLOCK)  
	JOIN #tmpskuxfp_PURHO B ON  A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID=B.DEPT_ID
    
  
    INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,GROUP_INV_NO,GROUP_INV_DT,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,
	      xfer_discount_amount,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp,challan_source_location_code)    
    SELECT distinct  A.PRODUCT_CODE,A.DEPT_ID,A.XFER_PRICE,A.XFER_PRICE CURRENT_XFER_PRICE,A.RECEIPT_DT,
	                 0 AS DISCOUNT_PERCENTAGE,A.RECEIPT_DT FIRST_RECEIPT_DT,A.Inv_no GROUP_INV_NO,A.inv_dt GROUP_INV_DT,
					 a.xfer_price_without_gst,a.xfer_price_igst_amount,a.xfer_price_cgst_amount,a.xfer_price_sgst_amount,
	                 0 as xfer_discount_amount,0 as xfer_freight_amount,0 as xfer_other_charges,0 as xfer_round_off,a.xfer_gst_cess_amount,a.loc_pp,
                     a.challan_source_location_code
    FROM #tmpskuxfp_PURHO A (NOLOCK)  
    LEFT OUTER JOIN sku_xfp b (NOLOCK) ON a.product_code=b.product_code AND a.dept_id=b.DEPT_ID   
    WHERE b.product_code is null  
  
   goto end_proc  
  END  
   
 END  
 
 ELSE IF @CXN_TYPE='SNC'
 BEGIN
      
      
  
   ;WITH CTE AS
	(
	SELECT c.DEPT_ID,A.PRODUCT_CODE,c.RECEIPT_DT  AS RECEIPT_DT,c.MEMO_NO  AS XN_NO,
	       sr =ROW_NUMBER () over (partition by A.PRODUCT_CODE, c.DEPT_ID order by c.RECEIPT_DT desc)
	FROM snc_barcode_det  A
	JOIN snc_det  B ON A.REFROW_ID  =B.ROW_ID 
	join SNC_MST c (nolock) on B.MEMO_ID =c.MEMO_ID 
	LEFT OUTER JOIN sku_xfp d (NOLOCK) ON d.product_code=A.product_code AND c.dept_id=d.dept_id
	WHERE c.CANCELLED =0 AND isnull(c.wip,0)=0 AND d.product_code IS NULL
	and c.MEMO_ID  =@CXN_ID
	)

	INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,
	              challan_source_location_code)  
	SELECT 	DISTINCT  a.PRODUCT_CODE, A.DEPT_ID,B.PURCHASE_PRICE AS XFER_PRICE,B.PURCHASE_PRICE AS CURRENT_XFER_PRICE
			,case when isnull(A.RECEIPT_DT,'')='' then  b.RECEIPT_DT
			 else A.RECEIPT_DT END AS RECEIPT_DT
			,0 AS DISCOUNT_PERCENTAGE ,b.RECEIPT_DT As FIRST_RECEIPT_DT
			,xn_no as group_inv_no,
			A.RECEIPT_DT as group_inv_dt,
			SKU.purchase_price  loc_pp,a.DEPT_ID
	FROM CTE A (NOLOCK)
	JOIN sku b (NOLOCK)	ON a.product_code=b.product_code
	join location loc (nolock) on loc.dept_id =a.DEPT_ID 
	left join LMp01106 lm (nolock) on lm.AC_CODE =b.ac_code 
	join SKU  (nolock) on SKU.product_Code =a.product_code
	WHERE SR=1
 
 end
 ELSE IF @CXN_TYPE='CNC'
 BEGIN
   
   DECLARE @cHoPanNo VARCHAR(10)

   SELECT TOP 1 @cHoPanNo=(CASE WHEN ISNULL(loc_gst_no,'')<>'' THEN SUBSTRING (loc_gst_no ,3,10) 
	else pan_no END) FROM  location (NOLOCK) WHERE dept_id=@CHODEPTID

   ;WITH CTE AS
	(
	SELECT B.DEPT_ID,A.PRODUCT_CODE,CNC_MEMO_DT AS RECEIPT_DT,B.cnc_memo_no AS XN_NO,
	       sr =ROW_NUMBER () over (partition by A.PRODUCT_CODE, B.DEPT_ID order by B.CNC_MEMO_DT desc)
	FROM ICD01106 A
	JOIN ICM01106 B ON A.CNC_MEMO_ID =B.CNC_MEMO_ID
	LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=A.product_code AND c.dept_id=a.dept_id
	WHERE B.CANCELLED =0 AND B.CNC_TYPE=2 AND C.product_code IS NULL
	and b.cnc_memo_id =@CXN_ID
	)

	INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,
	              challan_source_location_code)  
	SELECT 	DISTINCT  a.PRODUCT_CODE, A.DEPT_ID,B.PURCHASE_PRICE AS XFER_PRICE,B.PURCHASE_PRICE AS CURRENT_XFER_PRICE
			,case when isnull(A.RECEIPT_DT,'')='' then  b.RECEIPT_DT
			 else A.RECEIPT_DT END AS RECEIPT_DT
			,0 AS DISCOUNT_PERCENTAGE ,b.RECEIPT_DT As FIRST_RECEIPT_DT
			,xn_no as group_inv_no,
			A.RECEIPT_DT as group_inv_dt,
			SKU.purchase_price  loc_pp,a.DEPT_ID
	FROM CTE A (NOLOCK)
	JOIN sku b (NOLOCK)	ON a.product_code=b.product_code
	join location loc (nolock) on loc.dept_id =a.DEPT_ID 
	left join LMp01106 lm (nolock) on lm.AC_CODE =b.ac_code 
	join SKU  (nolock) on SKU.product_Code =a.product_code
	WHERE SR=1

 END
 ELSE IF @CXN_TYPE='WSR'
 BEGIN
      
	  ;WITH CTE AS
		(
			SELECT D.location_Code  AS DEPT_ID ,C.PRODUCT_CODE,C.ROW_ID,
			SR=ROW_NUMBER () OVER (PARTITION BY D.location_Code ,C.PRODUCT_CODE ORDER BY RECEIPT_DT DESC)
			FROM cnd01106 C (NOLOCK) 
			JOIN cnm01106 D (NOLOCK) ON C.cn_id=D.cn_id
			WHERE D.mode=2 AND D.CANCELLED=0 and isnull(c.invoice_quantity,0)<>0
			and c.cn_id =@CXN_ID
		)
		INSERT INTO #TMPSKUXFP(DEPT_ID,PRODUCT_CODE,ROW_ID)
		SELECT a.DEPT_ID,a.PRODUCT_CODE,a.ROW_ID  FROM CTE a
		left join SKU_XFP b on a.DEPT_ID =b.dept_id and a.product_code=b.product_code
		WHERE SR=1 and b.product_code is null

        IF OBJECT_ID ('TEMPDB..#TMPSKUXFP_wsr','U') IS NOT NULL
		   drop table #TMPSKUXFP_wsr
		
		if exists (select top 1 'u' from #TMPSKUXFP)
		begin
		
				SELECT 	DISTINCT  B.PRODUCT_CODE, tmp.DEPT_ID
						,(B.net_rate
  					   +(CASE WHEN b.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.item_tax_amount ,0))/B.INVOICE_QUANTITY) ELSE 0 END)) AS XFER_PRICE
						, (B.net_rate
  					   +(CASE WHEN b.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.item_tax_amount ,0))/B.INVOICE_QUANTITY) ELSE 0 END)) AS CURRENT_XFER_PRICE
						,A.RECEIPT_DT,
						case when (((b.rate*invoice_quantity ) +b.discount_amount )*invoice_quantity )=0 then 0 else 
						(isnull(b.discount_amount,0)+isnull(b.CNMDISCOUNTAMOUNT,0))*100/(((b.rate*invoice_quantity ) +b.discount_amount )*invoice_quantity ) end AS DISCOUNT_PERCENTAGE ,
						A.RECEIPT_DT as FIRST_RECEIPT_DT,
						a.manual_dn_no as group_inv_no,
						a.manual_dn_dt as group_inv_dt,
						xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,
						xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,
						xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,
						xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,
						isnull(b.discount_amount,0)+isnull(b.CNMDISCOUNTAMOUNT,0) xfer_discount_amount,
						0 as xfer_depreciation,
						0 as xfer_freight_amount,
						0 xfer_other_charges,
						0 xfer_round_off,
						b.Gst_Cess_Amount  xfer_gst_cess_amount,
						sr =ROW_NUMBER () over (partition by B.PRODUCT_CODE, tmp.DEPT_ID order by a.receipt_dt desc),
						a.ac_code ,a.challan_source_location_code
				into #TMPSKUXFP_wsr
				FROM cnm01106 A (NOLOCK)
				JOIN cnd01106 B (NOLOCK) ON A.cn_id=B.cn_id
				JOIN #TMPSKUXFP TMP ON TMP.ROW_ID =B.ROW_ID
				WHERE A.CANCELLED=0  AND ISNULL(A.RECEIPT_DT,'')<>'' AND A.mode=2 
				AND ISNULL(B.PRODUCT_CODE,'')<>'' 
		
				INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,
				xfer_discount_amount,xfer_depreciation,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp,
				challan_source_location_code)  
        
				SELECT a.PRODUCT_CODE,a.DEPT_ID,a.XFER_PRICE,a.CURRENT_XFER_PRICE,a.RECEIPT_DT,a.DISCOUNT_PERCENTAGE,a.FIRST_RECEIPT_DT,a.group_inv_no,a.group_inv_dt,a.xfer_price_without_gst,a.xfer_price_igst_amount,a.xfer_price_cgst_amount,a.xfer_price_sgst_amount,
				a.xfer_discount_amount,a.xfer_depreciation,xfer_freight_amount,a.xfer_other_charges,a.xfer_round_off,a.xfer_gst_cess_amount ,
				case when 
				case when  SUBSTRING (LM.AC_GST_NO,3,10)<>'' THEN  SUBSTRING (LM.AC_GST_NO,3,10) ELSE LM.PAN_NO  END=
				case when  SUBSTRING (loc.loc_gst_no ,3,10)<>'' THEN  SUBSTRING (loc.loc_gst_no,3,10) ELSE loc.PAN_NO  END then SKU.purchase_price 
				else a.xfer_price_without_gst end loc_pp,a.challan_source_location_code

				FROM #TMPSKUXFP_wsr A
				join location loc (nolock) on loc.dept_id =a.DEPT_ID 
				join LMp01106 lm (nolock) on lm.AC_CODE =a.ac_code 
				join SKU  (nolock) on SKU.product_Code =a.product_code 
				WHERE SR=1


		end

 END


	ELSE IF @CXN_TYPE='SLR'
	BEGIN

			;WITH CTE AS
			(
			SELECT  B.location_Code  as DEPT_ID,A.PRODUCT_CODE,cm_dt AS RECEIPT_DT,B.cm_no AS XN_NO,
					sr =ROW_NUMBER () over (partition by A.PRODUCT_CODE, B.location_Code  order by B.cm_dt desc),
					a.row_id 
			FROM sls_cmd01106_UPLOAD A (NOLOCK)
			JOIN sls_cmm01106_upload B (NOLOCK) ON A.sp_id =B.sp_id
			LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=A.product_code AND c.dept_id=B.location_Code 
			WHERE a.sp_id =@CXN_ID AND B.CANCELLED =0  AND C.product_code IS NULL and a.QUANTITY<0
			)

		INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,
		xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,xfer_discount_amount,xfer_depreciation,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp,
		             challan_source_location_code)  
		SELECT 	B.PRODUCT_CODE, cte.DEPT_ID
						,abs((B.net
  						+(CASE WHEN b.tax_method=2 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.tax_amount ,0))/B.QUANTITY) ELSE 0 END))) AS XFER_PRICE
						,abs( (B.net
  						+(CASE WHEN b.tax_method=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.tax_amount ,0))/B.QUANTITY) ELSE 0 END))) AS CURRENT_XFER_PRICE
						,A.cm_dt  RECEIPT_DT,
						abs(case when (((b.mrp*QUANTITY ) +b.discount_amount )*QUANTITY )=0 then 0 else 
						(isnull(b.discount_amount,0)+isnull(b.cmm_discount_amount ,0))*100/(((b.mrp*QUANTITY ) +b.discount_amount )*QUANTITY ) end) AS DISCOUNT_PERCENTAGE ,
						A.cm_dt   FIRST_RECEIPT_DT,
						b.ref_sls_memo_no as group_inv_no,
						b.ref_sls_memo_dt as group_inv_dt,
						xfer_price_without_gst =abs(round(b.xn_value_without_gst/b.QUANTITY,2))  ,
						xfer_price_igst_amount =abs(round(b.igst_amount/b.QUANTITY,2)) ,
						xfer_price_cgst_amount =abs(round(b.cgst_amount/b.QUANTITY,2)) ,
						xfer_price_sgst_amount =abs(round(b.sgst_amount/b.QUANTITY,2)) ,
						0 xfer_discount_amount,
						0 as xfer_depreciation,
						0 as xfer_freight_amount,
						0 xfer_other_charges,
						0 xfer_round_off,
						abs(b.Gst_Cess_Amount)  xfer_gst_cess_amount,
						SKU.purchase_price loc_pp,cte.DEPT_ID
		FROM sls_cmm01106_upload A (NOLOCK)
		JOIN sls_cmd01106_upload b (NOLOCK)	ON a.sp_id=b.sp_id
		join CTE  on b.ROW_ID =cte.row_id 
		join location loc (nolock) on loc.dept_id =cte.DEPT_ID 
		join SKU  (nolock) on SKU.product_Code =b.product_code
		WHERE a.sp_id=@cXn_Id AND SR=1


end    
  
END_PROC:  
  
END  
--END OF PROCEDURE - SP3S_UPD_SKUXFPNEW  