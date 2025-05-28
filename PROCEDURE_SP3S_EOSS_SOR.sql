CREATE PROCEDURE SP3S_EOSS_SOR   --(LocId 3 digit change by Sanjay:06-11-2024)
 @NQUERYID  NUMERIC(5),  
 @CWHERE  VARCHAR(MAX)='',  
 @CFINYEAR   VARCHAR(5)='',    
 @NNAVMODE   NUMERIC(2)=1,    
 @CWIZAPPUSERCODE VARCHAR(10)='',  
 @CREFMEMONO   VARCHAR(20)='',  
 @dLoginDt   DATETIME='',  
 @dFromDtPara DATETIME='',  
 @dToDtPara DATETIME=''  
AS  
BEGIN  
  
IF @NQUERYID=1   
GOTO NAV  
ELSE IF @NQUERYID=2   
GOTO MST  
ELSE IF @NQUERYID=3  
GOTO DET  
ELSE IF @NQUERYID=4  
GOTO lblExcelImp  
ELSE if @NQUERYID=5  
GOTO lblLIST  
ELSE if @NQUERYID=6  
GOTO lblPendingPayments  
ELSE if @NQUERYID=7  
GOTO lblPendingSorforFDNCN  
  
NAV:  
 EXECUTE SP_NAVIGATE 'EOSSSORM',@NNAVMODE,@CREFMEMONO,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID','',0    
 GOTO SSPL  
MST:  
 SELECT A.*,B.AC_NAME,C.USERNAME,X.DISCOUNT_AMOUNT,X.QUANTITY,X.VALUE_AT_MRP,  
 B1.ADDRESS1 ,B1.ADDRESS2 ,B1.ADDRESS0 AS [ADDRESS9] ,'' AS [ADDRESS]  
 ,isnull(lct.dept_id+'-','')+ISNULL(LCT.DEPT_NAME,'') AS DEPT_NAME,ISNULL(RMM.rm_id,CNM.cn_id) AS REFMEMOID ,  
 ISNULL(RMM.RM_NO,CNM.CN_NO) AS RM_NO,  
 ISNULL(RMM.RM_ID,CNM.CN_ID) AS RM_ID,  
 (CASE WHEN isnull(rmm.rm_id,'')<>'' THEN 'PRT' ELSE 'WSR' END) AS xn_type,  
 ISNULL(TE.NAME,'') AS T_NAME,TE.D_FILTER,CONVERT(NUMERIC(10,2),ROUND(x.RATE_DIFF,2)) RATE_DIFF,  
 CONVERT(NUMERIC(10,2),ROUND(x.RATE_DIFF_gst_amount,2)) RATE_DIFF_gst_amount  
 FROM EOSSSORM A  
 JOIN   
 (  
  SELECT MEMO_ID,SUM(QUANTITY) AS QUANTITY , SUM(MRP_value) AS [VALUE_AT_MRP],  
  SUM(DISCOUNT_AMOUNT) AS [DISCOUNT_AMOUNT],SUM(rate_diff) AS RATE_DIFF,sum(RATE_DIFF_gst_amount) RATE_DIFF_gst_amount  
  FROM EOSSSORD WHERE MEMO_ID=@CWHERE GROUP BY MEMO_ID  
 )X ON X.MEMO_ID=A.MEMO_ID  
 JOIN LM01106 B ON B.AC_CODE=A.AC_CODE  
 JOIN LMP01106 B1 ON B.AC_CODE=B1.AC_CODE  
 JOIN USERS C ON C.USER_CODE=B.USER_CODE  
 LEFT JOIN LOCATION LCT(NOLOCK) ON A.party_DEPT_ID=LCT.DEPT_ID  
 LEFT JOIN SOR_FDNFCN_LINK sl (NOLOCK) ON sl.sorMemoId=a.MEMO_ID
 LEFT OUTER JOIN RMM01106 RMM ON  sl.refFdnMemoId=rmm.rm_id  AND rmm.cancelled=0  
 LEFT OUTER JOIN CNM01106 CNM ON  sl.refFcnMemoId=cnm.cn_id   AND cnm.cancelled=0  
 LEFT OUTER JOIN TBL_EOSS_DISC_SHARE_MST TE ON TE.ID=A.ID  
 WHERE A.MEMO_ID=@CWHERE  
 GOTO SSPL
 
DET:   
 
 print 'step-1:'+convert(varchar(40),getdate(),113)
 

 declare @chodept_id varchar(4)
 select @chodept_id=value from CONFIG where config_option ='Ho_location_id'

 select memo_id into #tmpSorMemos from eosssorm
 WHERE (@cWhere<>'' AND MEMO_ID=@CWHERE)  
 OR (@cWhere='' AND memo_dt BETWEEN @dFromDtPara AND @dToDtPara and cancelled=0)  

 print 'step-1.5:'+convert(varchar(40),getdate(),113)
 
 ;with cte as
 (
 select a.Inv_no  as INVNOHO ,a.inv_id,b.net_rate as INVRATERHO, Mst.MEMO_ID ,det.product_code,
 convert(varchar,a.inv_dt,105) as INVHODT,
        Sr=row_number () over (partition by det.product_code order by a.inv_dt desc )
 FROM EOSSSORD DET (NOLOCK)  
 JOIN EOSSSORM MST (NOLOCK) ON MST.MEMO_ID=DET.MEMO_ID  
 join ind01106 b (NOLOCK) on det.product_code= b.product_code
 join inm01106 a (NOLOCK) on b.inv_id= a.inv_id and mst.party_dept_id=a.party_dept_id
 JOIN #tmpSorMemos m ON m.MEMO_ID=mst.MEMO_ID
 where a.CANCELLED=0 
 )

 select * into #tmpInvdetails from cte where sr=1 
 
  print 'step-2:'+convert(varchar(40),getdate(),113)

 SELECT CONVERT(BIT,0) AS SUBTOTAL,det.product_code,DET.cm_no,convert(varchar,DET.cm_dt,105) DISPLAY_cm_dt,  
 DET.cm_dt,DET.quantity,DET.scheme_discount,DET.Card_discount_amount,DET.discount_amount,DET.Discount_percentage,  
   item_net,gm_per,DET.net_payable,ARTICLE_NO,sub_section_name,section_name,para1_name,para2_name,para3_name,para4_name,  
   para5_name,para6_name,Article_Alias,output_gst,Input_gst,claimed_base_value,  
   eoss_scheme_name,Taxable_value,ISNULL(LCT.DEPT_NAME,'') AS DEPT_NAME,  
 (det.purchase_price*DET.quantity) AS PUR_VALUE,input_gst,det.purCHASE_bill_no,det.purCHASE_bill_dt,  
 CONVERT(VARCHAR,det.purCHASE_bill_dt,105) DISPLAY_purCHASE_bill_dt,  
 st.sor_terms_name AS sor_terms_DESC ,mrp_value AS MRP,  
 '' as discount_sharing_base_desc,(input_gst-output_gst) gst_diff,  
 ROUND(claimed_base_value*gm_per/100,2) claimed_base_gm_value,DET.weighted_avg_disc_amt,det.hsn_code,det.bill_remarks,  
 lcs.dept_alias,LCT.dept_id,det.rate_diff,det.rate_diff_gst_percentage,det.rate_diff_gst_amount,det.purchase_price,  
 det.dt_name,company_share,company_share_with_outputgst,CMM.ref_no,((det.purchase_price*Det.quantity) +(input_gst)) As Invoice_Amount,  
 la.LOCattr2_key_name as [PARTYNAME],  
 CONVERT(NUMERIC(14,2),mrp_value*50/100) Puma_billing_price,(ROUND(mrp_value*50/100,2)+INPUT_GST) puma_invoice_price,  
 ((taxable_value-claimed_base_gm_value)-ROUND(mrp_value*50/100,2)) sum_cn_dn  ,INVNOHO,INVRATERHO ,INVHODT
 FROM EOSSSORD DET (NOLOCK)  
 JOIN EOSSSORM MST (NOLOCK) ON MST.MEMO_ID=DET.MEMO_ID  
 JOIN #tmpSorMemos m ON m.MEMO_ID=mst.MEMO_ID
 JOIN SKU  (NOLOCK) ON SKU.PRODUCT_CODE=DET.PRODUCT_CODE    
 JOIN sku_names sn (NOLOCK) ON sn.product_Code=sku.product_code  
 LEFT JOIN LOCATION LCT(NOLOCK) ON MST.party_DEPT_ID=LCT.DEPT_ID  
 LEFT JOIN LOCATION LCS(NOLOCK) ON MST.location_Code=LCS.DEPT_ID  ---It's unclear so I am not replacing this code w.r.t 3 digit locid changes for now (Sanjay : 05-11-2024)
 LEFT OUTER JOIN CMD01106 CMD ON DET.CMD_ROW_ID =  CMD.ROW_ID   
 LEFT OUTER JOIN CMM01106 CMM ON CMD.CM_ID= CMM.CM_ID  
 Left outer join LOC_NAMES lA on  LCT.dept_id = lA.Dept_ID   
 Left Outer join #tmpInvdetails Inv  on det.MEMO_ID= inv.MEMO_ID and inv.PRODUCT_CODE =det.PRODUCT_CODE 

 left join sor_terms_mst st (nolock) on st.sor_terms_code=det.sor_terms_code  
   
   
 UNION ALL   
 SELECT CONVERT(BIT,1) AS SUBTOTAL,'' product_code,'' cm_no,'' cm_dt,''DISPLAY_CM_DT,SUM(DET.quantity) quantity,SUM(DET.scheme_discount) scheme_discount,  
   SUM(DET.Card_discount_amount) Card_discount_amount,SUM(DET.discount_amount) discount_amount,0 Discount_percentage,  
   SUM(item_net) item_net,0 gm_per,SUM(DET.net_payable) net_payable,'' ARTICLE_NO,'' sub_section_name,'' section_name,'' para1_name,  
   '' para2_name,'' para3_name,'' para4_name,'' para5_name,'' para6_name,'' Article_Alias,  
   SUM(output_gst) output_gst,SUM(Input_gst) Input_gst,SUM(claimed_base_value) claimed_base_value,  
   eoss_scheme_name+' Total ',SUM(Taxable_value) Taxable_value,''  DEPT_NAME,  
 SUM(det.purchase_price*DET.quantity) AS PUR_VALUE,SUM(input_gst) input_gst,'' purCHASE_bill_no,  
 ''  purCHASE_bill_dt,''  DISPLAY_purCHASE_bill_dt,  
 '' AS sor_terms_DESC,SUM(mrp_value) AS MRP,'' as discount_sharing_base_desc,  
 SUM(input_gst-output_gst) gst_diff,ROUND(SUM(claimed_base_value*gm_per/100),2) claimed_base_gm_value,  
 sum(DET.weighted_avg_disc_amt) weighted_avg_disc_amt,'' hsn_code,'' bill_remarks,'' dept_alias,'' as dept_id,  
 SUM(rate_diff) rate_diff,0 rate_diff_gst_percentage,SUM(rate_diff_gst_amount) rate_diff_gst_amount,0 purchase_price,'' dt_name,  
 SUM(company_share) company_share ,SUM(company_share_with_outputgst) company_share_with_outputgst,'' as ref_no,  
 (sum(det.purchase_price*quantity) +sum(input_gst)) As Invoice_Amount,'' as [PUMAPARTYNAME],  
 CONVERT(NUMERIC(14,2),SUM(mrp_value)*50/100) Puma_billing_price,(ROUND(SUM(mrp_value)*50/100,2)+SUM(INPUT_GST)) puma_invoice_price,  
 (sum(taxable_value-claimed_base_gm_value)-ROUND(SUM(mrp_value)*50/100,2)) sum_cn_dn , 
 '' as  INVNOHO, cast(0 as numeric(10,2))  as INVRATERHO ,'' as INVHODT
 FROM EOSSSORD DET (NOLOCK)   
 JOIN #tmpSorMemos m ON m.MEMO_ID=det.MEMO_ID
 GROUP BY eoss_scheme_name  
 order BY eoss_scheme_name,SUBTOTAL,dept_name,CM_DT,DET.CM_NO  


  
  print 'step-3:'+convert(varchar(40),getdate(),113)
 SELECT 1 srno,det.product_code,cm_no,cm_dt,quantity,scheme_discount,Card_discount_amount,  
 discount_amount,Discount_percentage,item_net,gm_per,net_payable,output_gst,Input_gst,  
 claimed_base_value,eoss_scheme_name,Taxable_value,ISNULL(LCT.DEPT_NAME,'') AS DEPT_NAME,  
 (det.purchase_price*quantity) AS PUR_VALUE,input_gst,det.purchase_bill_no,det.purchase_bill_dt,  
 st.sor_terms_name AS sor_terms_DESC,'' as discount_sharing_base_desc,det.memo_id,  
 det.row_id,det.CMD_ROW_ID,mrp_value,gst_diff,claimed_base_gm_value,weighted_avg_disc_amt,st.sor_terms_code,  
 det.hsn_code,det.bill_remarks,lcs.dept_alias,lct.dept_id,det.rate_diff, det.rate_diff_gst_percentage,det.rate_diff_gst_amount,  
 det.purchase_price,det.dt_name,company_share,company_share_with_outputgst,(det.purchase_price*quantity +input_gst) As Invoice_Amount,  
 CONVERT(NUMERIC(14,2),mrp_value*50/100) Puma_billing_price,(ROUND(mrp_value*50/100,2)+INPUT_GST) puma_invoice_price,  
 ((taxable_value-claimed_base_gm_value)-ROUND(mrp_value*50/100,2)) sum_cn_dn  
    FROM EOSSSORD DET  
 JOIN EOSSSORM MST ON MST.MEMO_ID=DET.MEMO_ID  
 JOIN SKU  (NOLOCK) ON SKU.PRODUCT_CODE=DET.PRODUCT_CODE    
 JOIN sku_names sn (NOLOCK) ON sn.product_Code=sku.product_code  
 LEFT JOIN LOCATION LCT(NOLOCK) ON MST.party_DEPT_ID=LCT.DEPT_ID  
 LEFT JOIN LOCATION LCS(NOLOCK) ON MST.location_Code=LCS.DEPT_ID  
 left join sor_terms_mst st (nolock) on st.sor_terms_code=det.sor_terms_code  
 JOIN #tmpSorMemos m ON m.MEMO_ID=mst.MEMO_ID
  

  print 'step-4:'+convert(varchar(40),getdate(),113)
 SELECT  st.sor_terms_name AS sor_terms_DESC,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,  
    (CASE WHEN SUM(taxable_value)<>0 THEN convert(numeric(6,2),ROUND((SUM(claimed_base_value*gm_per/100)/  
    SUM(taxable_value))*100 ,2)) ELSE 0 END) margin_pct_taxable,  
    gm_per,sum(claimed_base_value) claimed_base_value,  
    SUM(claimed_base_value*gm_per/100) claimed_base_gm_value,SUM(output_gst) output_gst,  
    SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,  
    (CASE WHEN SUM(taxable_value)<>0 THEN convert(numeric(6,2),  
    ROUND((SUM(claimed_base_value*gm_per/100)/SUM(taxable_value+output_gst))*100,2)) ELSE 0 END) final_margin_pct,  
    SUM(purchase_price*quantity) AS PUR_VALUE,1 as disp_order ,  
    sum(a.QUANTITY) as total_qty, sum(a.ITEM_NET) as total_Amount,   
    sum(discount_amount) as total_discamt ,sum(Mrp_value) as  TOTOL_MRP,(SUM(purchase_price*quantity) +SUM(input_gst) ) As Invoice_Amount  
 FROM eosssord a (NOLOCK)  
 JOIN #tmpSorMemos m ON m.MEMO_ID=a.MEMO_ID
 left join sor_terms_mst st (nolock) on st.sor_terms_code=a.sor_terms_code  
 GROUP BY st.sor_terms_name,gm_per  
   
 UNION ALL  
 SELECT  'Totals:' AS sor_terms_DESC,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,  
    (CASE WHEN SUM(taxable_value)<>0 THEN convert(numeric(6,2),ROUND((SUM(claimed_base_value*gm_per/100)/SUM(taxable_value))*100 ,2))  
       ELSE 0 END) margin_pct_taxable,  
    0 gm_per,sum(claimed_base_value) claimed_base_value,  
    SUM(claimed_base_value*gm_per/100) claimed_base_gm_value,SUM(output_gst) output_gst,  
    SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,  
    (CASE WHEN SUM(taxable_value)<>0 THEN convert(numeric(6,2),  
    ROUND((SUM(claimed_base_value*gm_per/100)/SUM(taxable_value+output_gst))*100,2)) else 0 end) final_margin_pct,  
    SUM(purchase_price*quantity) AS PUR_VALUE,2 as disp_order ,  
    sum(a.QUANTITY) as total_qty, sum(a.ITEM_NET) as total_Amount, sum(discount_amount) as total_discamt ,  
    sum(Mrp_value) as  TOTOL_MRP,(SUM(purchase_price*quantity) +SUM(input_gst) ) As Invoice_Amount  
 FROM eosssord a (NOLOCK)  
 left join sor_terms_mst st (nolock) on st.sor_terms_code=a.sor_terms_code  
 JOIN #tmpSorMemos m ON m.MEMO_ID=a.MEMO_ID
 ORDER BY disp_order,sor_terms_DESC  
  

  print 'step-5:'+convert(varchar(40),getdate(),113)
 GOTO SSPL   
  
lblExcelImp:  
   
 GOTO SSPL  
  
lblLIST:  
  
 SELECT memo_id,B.Ac_name,memo_no,memo_dt,A.PERIOD_FROM ,A.PERIOD_TO ,ISNULL(TE.NAME,'') AS T_NAME,TE.D_FILTER,  
 A.remarks,A.cancelled,C.USERNAME,  
 ISNULL(LCT.DEPT_NAME,'') AS DEPT_NAME,  
 ISNULL(RMM.RM_NO,CNM.CN_NO) AS REF_NO,   
 (CASE WHEN isnull(rmm.rm_id,'')<>'' THEN 'PRT' ELSE 'WSR' END) AS xn_type   
 FROM EOSSSORM A   
 JOIN LM01106 B ON B.AC_CODE=A.AC_CODE  
 JOIN LMP01106 B1 ON B.AC_CODE=B1.AC_CODE  
 JOIN USERS C ON C.USER_CODE=B.USER_CODE  
 LEFT JOIN LOCATION LCT(NOLOCK) ON A.party_DEPT_ID=LCT.DEPT_ID  
 LEFT JOIN SOR_FDNFCN_LINK sl (NOLOCK) ON sl.sorMemoId=a.MEMO_ID
 LEFT OUTER JOIN RMM01106 RMM ON  sl.refFdnMemoId=rmm.rm_id  AND rmm.cancelled=0  
 LEFT OUTER JOIN CNM01106 CNM ON  sl.refFcnMemoId=cnm.cn_id   AND cnm.cancelled=0  
 LEFT OUTER JOIN TBL_EOSS_DISC_SHARE_MST TE ON TE.ID=A.ID  
  
  
GOTO SSPL   
  
lblPendingPayments:  
 DECLARE @IMAXLEVEL NUMERIC(3,0)  
  
 SELECT @IMAXLEVEL=MAX(LEVEL_NO)   
 FROM XN_APPROVAL_CHECKLIST_LEVELS   
 WHERE XN_TYPE='EOSSSOR' AND INACTIVE=0  
    
 IF EXISTS(SELECT TOP 1 'U' FROM XN_APPROVAL_CHECKLIST_LEVELS  WHERE XN_TYPE='EOSSSOR' AND INACTIVE=0 AND ISNULL(AC_POSTING,0)<>0)  
 BEGIN  
  SELECT @IMAXLEVEL=LEVEL_NO  
  FROM XN_APPROVAL_CHECKLIST_LEVELS   
  WHERE XN_TYPE='EOSSSOR' AND INACTIVE=0 AND ISNULL(AC_POSTING,0)<>0  
 END  
        
 SET @IMAXLEVEL=ISNULL(@IMAXLEVEL,0)  
  
 SELECT convert(bit,1) as chk,a.memo_id,memo_dt,bank_name,ACCOUNT_NO,IFSC_CODE,'''02' NEFT_CODE,  
 vendor_amount,a.ac_code,ac_name,a.memo_no+convert(varchar,memo_dt,112) AS ref_no,  
 convert(varchar(50),'') as chq_no,'0000000000' as bank_ac_code,1 as payment_mode,  
 @dLoginDt as payment_date,BF_AC_NAME,a.remarks payment_remarks,convert(varchar(50),'') as chqbook_row_id,  
 a.payment_advice_amount,a.advance_adjusted  
 FROM eosssorm a (NOLOCK)  
 LEFT OUTER JOIN   
 (SELECT a.memo_id FROM postact_voucher_link a (NOLOCK)  
  JOIN  vm01106 b (NOLOCK) ON a.vm_id=b.vm_id  
  WHERE xn_type='EOSSSOR' AND cancelled=0  
 ) b ON a.memo_id=b.memo_id  
 LEFT OUTER JOIN location c (NOLOCK) ON c.dept_id=a.party_dept_id  
 LEFT OUTER JOIN lm_bank_detail d (NOLOCK) ON d.ac_code=ISNULL(a.ac_code,c.dept_ac_code)  
 JOIN lm01106 lm (NOLOCK) ON lm.ac_code=a.ac_code  
 WHERE a.approvedlevelno>=@IMAXLEVEL AND a.cancelled=0 AND   
 b.memo_id IS NULL AND payment_advice_amount>advance_adjusted  
 AND a.AgnstSupplier=1  
  
 select a.* from chqbook_d a left outer join   
 (SELECT chqbook_row_id FROM vd_chqbook a (NOLOCK)  
  JOIN vd01106 b (NOLOCK) ON  b.VD_ID=a.vd_id  
  JOIN vm01106 c (NOLOCK) ON c.vm_id=b.vm_id  
  WHERE c.cancelled=0) b on a.row_id=b.chqbook_row_id  
 where b.chqbook_row_id is null  
 and a.cancelled=0   
  
 declare @cBankHeads VARCHAR(2000)  
 SET @cBankHeads=DBO.FN_ACT_TRAVTREE('0000000013')  
  
 select ac_code,ac_name from lm01106 where charindex(head_code,@cBankHeads)>0  
  
 GOTO SSPL    
  
lblPendingSorforFDNCN:  
  
 SELECT a.memo_id,B.Ac_name,memo_no,memo_dt,  
 ISNULL(LCT.DEPT_NAME,'') AS DEPT_NAME,convert(bit,0) chk  
 FROM EOSSSORM A   
 JOIN LM01106 B ON B.AC_CODE=A.AC_CODE  
 JOIN LMP01106 B1 ON B.AC_CODE=B1.AC_CODE  
 JOIN USERS C ON C.USER_CODE=B.USER_CODE  
 LEFT JOIN LOCATION LCT(NOLOCK) ON A.party_DEPT_ID=LCT.DEPT_ID  
 LEFT JOIN SOR_FDNFCN_LINK sl (NOLOCK) ON sl.sorMemoId=a.MEMO_ID
 LEFT OUTER JOIN RMM01106 RMM ON  sl.refFdnMemoId=rmm.rm_id  AND rmm.cancelled=0  
 LEFT OUTER JOIN CNM01106 CNM ON  sl.refFcnMemoId=cnm.cn_id   AND cnm.cancelled=0  
 LEFT OUTER JOIN TBL_EOSS_DISC_SHARE_MST TE ON TE.ID=A.ID  
 WHERE rmm.rm_id IS NULL AND cnm.cn_id IS NULL AND (a.ac_code=@CWHERE OR a.party_dept_id=@cWhere)  
   
 GOTO SSPL  
  
SSPL:   
  
END 