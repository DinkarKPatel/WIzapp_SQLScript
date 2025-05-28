CREATE PROCEDURE SP3S_WHOLESALEPACKSLIP_REPORT    
@cMemoId varchar(40),    
@cWhere VARCHAR(3000)=''    
AS             
BEGIN    
 DECLARE @cCmd NVARCHAR(MAX)    
    
 IF OBJECt_ID('tempdb..#tmpBoxes','u') is not null    
  dROP TaBLE #tmpBoxes    
    
 CrEaTE tABlE #tmpBoxes (ps_id varchar(40),total_box numeric(4,0))    
    
 Set @cCMd=N'SELECT PS_ID,COUNT(DISTINCT BOX_NO) AS TOTAL_BOX FROM WPS_DET (NOLOCK)    
  WHERE ps_id='''+@cMemoId+''''+(CASE WHEN @cWhere<>'' THEN ' AND box_no IN ('+@cWhere+')' ELSE '' END)+'     
  GROUP BY PS_ID'    
    
 iNsERT #tmpBoxes    
    exec sp_executesql @CCmd    
    
 IF OBJECt_ID('tempdb..#tmpOrdPlan','u') is not null    
  dROP TaBLE #tmpOrdPlan    
     
 SELECT BAR_DET.PRODUCT_CODE, A.ORDER_NO AS BUYER_ORDER_NO,A.ORDER_DT AS BUYER_ORDER_DT,A.REF_NO AS BUYER_ORDER_REF_NO    
  ,BMST.MEMO_NO AS JOB_CARD_NO,BMST.MEMO_DT AS JOB_CARD_DT    
  iNTO #tmpOrdPlan FROM ORD_PLAN_BARCODE_DET BAR_DET (NOLOCK)     
  JOIN ORD_PLAN_DET BDET (NOLOCK) ON BDET.ROW_ID=BAR_DET.REFROW_ID    
  JOIN ORD_PLAN_MST BMST (NOLOCK) ON BDET.MEMO_ID=BMST.MEMO_ID    
  LEFT JOIN BUYER_ORDER_DET A1 (NOLOCK) ON BDET.WOD_ROW_ID=A1.ROW_ID    
  LEFT JOIN BUYER_ORDER_MST A (NOLOCK) ON A1.ORDER_ID=A.ORDER_ID    
  JOIN wps_det wpd (nolock) on wpd.product_code=bar_det.product_code    
  WHERE wpd.ps_id=@cMemoId AND BMST.CANCELLED=0 AND A.CANCELLED=0    
  GROUP BY BAR_DET.PRODUCT_CODE, A.ORDER_ID,A.ORDER_NO,A.ORDER_DT,A.REF_NO,BMST.MEMO_ID ,BMST.MEMO_NO,BMST.MEMO_DT    
    
 SET @cCmd=N'SELECT           
 T1.PS_ID,          
 T1.AC_CODE            
 ,T1.PS_NO            
 ,T1.PS_DT            
 ,T1.SUBTOTAL            
 ,T1.REMARKS            
 ,T1.CANCELLED            
 ,T1.CHECKED_BY            
 ,T1.USER_CODE            
 ,T1.LAST_UPDATE            
 ,T1.TS            
 ,T1.FIN_YEAR            
 ,T1.PARTY_DEPT_ID            
 ,T1.WAY_BILL      
 ,T1.PAY_TYPE      
 ,T1.SHIPPING_ADDRESS      
 ,T1.SHIPPING_ADDRESS2      
 ,T1.SHIPPING_ADDRESS3      
 ,T1.SHIPPING_AREA_NAME      
 ,T1.SHIPPING_PIN      
 ,T1.SHIPPING_CITY_NAME      
 ,T1.SHIPPING_STATE_NAME      
 ,t2.PRODUCT_CODE    
 ,T2.QUANTITY            
 ,T2.RATE            
 ,T2.ROW_ID      
 ,RIGHT(T2.ORDER_ID,10) AS ORDER_NO            
 ,T3.AC_NAME            
 ,T3.ALIAS            
 ,T3.HEAD_CODE            
 ,T3.CLOSING_BALANCE            
 ,T3.CLOSING_BALANCE_CR_DR            
 ,T3.PRINT_LEDGER            
 ,T3.PRINT_NAME            
 ,T3.CREDIT_DAYS            
 ,T3.BILL_BY_BILL            
 ,T3.ON_HOLD            
 ,T3.THROUGH_BROKER            
 ,T3.BROKER_COMM_PERCENT            
 ,T3.CREDIT_LIMIT            
 ,T3.ALLOW_CREDITOR_DEBTOR            
 ,T3.DPWEF_DT            
 ,T3.CST_PERCENTAGE            
 ,T3.PAN_NO            
 ,T3.GLN_NO            
 ,T3.MP_PERCENTAGE            
 ,T3.MRP_CALC_MODE            
 ,T3.TDS_CODE            
 ,T3.INV_RATE_TYPE            
 ,T3.OUTSTATION_PARTY            
 ,T3.SALES_AC_CODE            
 ,T7.USERNAME            
 ,T8.USERNAME AS EDT_USERNAME           
 ,T3.ADDRESS0          
 ,T3.ADDRESS1          
 ,T3.ADDRESS2     
 ,T3.AREA_NAME          
 ,T3.CITY          
 ,T3.STATE          
 ,T3.CST_NO          
 ,T3.SST_NO          
 ,T3.TIN_NO          
 ,T3.PHONES_R          
 ,T3.PHONES_O          
 ,T3.PHONES_FAX          
 ,T3.MOBILE          
 ,T3.E_MAIL    
 ,T3.AC_GST_NO      
 ,T3.PINCODE        
 ,T4.FORM_NAME            
 ,T4.PURCHASE_AC_CODE            
 ,T4.SALE_AC_CODE            
 ,T4.TAX_AC_CODE            
 ,T4.POST_TAX_SEPARATELY            
 ,T4.PUR_RETURN_AC_CODE            
 ,T4.SALE_RETURN_AC_CODE            
 ,T4.PHYSICAL_FORM            
 ,T4.SERIES            
 ,T4.EXCISE_EDU_CESS_AC_CODE            
 ,T4.EXCISE_HEDU_CESS_AC_CODE            
 ,T4.EXCISE_DUTY_AC_CODE            
 ,T5.EMP_NAME            
 ,T5.EMP_ALIAS            
 ,T5.EMP_HEAD            
 ,PARA1_NAME            
 ,PARA2_NAME          
 ,PARA3_NAME          
 ,PARA4_NAME          
 ,PARA6_NAME          
 ,T6.WS_PRICE            
 ,T6.WS_PRICE  AS WPS_WS_PRICE          
 ,COM.COMPANY_CODE          
 ,COM.EMAIL_ID AS COMP_EMAILID     
 ,COM.PWD AS COMP_PWD      
 ,COM.CONTACT_NAME AS COMP_CONTACTNAME              
 ,COM.TDS_AC_NO AS COMP_TDSACNO          
 ,COM.COMPANY_NAME AS COMP_COMPANYNAME      
 ,com.PHONES_FAX AS COMP_PHONES_FAX          
 ,COM.LOGO_PATH AS COMP_LOGOPATH     
 ,COM.WEB_ADDRESS AS COMP_WEBADDRESS       
 ,COM.SSPL_FIRST_HDSR AS COMP_SSPLFIRSTHDSR          
 ,COM.POLICY_NO AS COMP_POLICYNO          
 ,COM.GRP_NAME AS COMP_GRPNAME           
 ,COM.CIN AS COMP_CIN     
 ,com.SST_NO AS COMP_SSTNO          
 ,com.SST_DT AS COMP_SSTDT     
 ,com.PRINT_ADDRESS AS COMP_PRINTADDRESS          
 ,com.WORKABLE AS COMP_WORKABLE     
 ,com.GRP_CODE AS COMP_GRPCODE          
 ,loc.PAN_NO AS COMP_PANNO          
 ,loc.STATE AS COMP_STATE           
 ,loc.COUNTRY_NAME AS COMP_CONTRY          
 ,loc.phone AS COMP_MOBILE        
 ,loc.DEPT_ALIAS AS COMP_ALIAS          
 ,loc.ADDRESS1 AS COMP_ADDRESS1          
 ,loc.ADDRESS2 AS COMP_ADDRESS2           
 ,loc.CITY AS COMP_CITY          
 ,loc.TAN_NO AS COMP_TANNO          
 ,loc.CST_DT AS COMP_CST_DT               
 ,CAST('''' AS VARCHAR(100)) AS COMP_ADDRESS9        
 ,loc.AREA_CODE AS COMP_AREACODE               
 ,loc.PINCODE  AS COMP_PIN          
    ,BRD.AC_NAME AS BROKER_NAME        
 ,BIN.BIN_NAME       
 ,BIN.BIN_ID      
 ,ANG.ANGADIA_NAME AS TRANSPORT_NAME ,ANG.INSURANCE_PERCENTAGE AS TSPRT_INS_PERCENT,T1.ANGADIA_CODE             
 ,sku.PRODUCT_NAME,ARTICLE_NO,ARTICLE_NAME,          
 (T2.QUANTITY * T2.RATE) AS CAL_AMOUNT,T6.MRP AS CAL_MRP,          
 T2.MRP  AS WPS_MRP,          
 T1.SUBTOTAL AS MST_NET_AMOUNT,          
 SUB_SECTION_NAME,SECTION_NAME,ISNULL(T2.BOX_NO,0)AS BOX_NO, T2.BOX_DT,T2.SRNO           
 ,T2.MRP AS MRP    
 ,Z.TOTAL_BOX     
 ,X.BUYER_ORDER_NO,X.BUYER_ORDER_DT,X.BUYER_ORDER_REF_NO,X.JOB_CARD_NO,X.JOB_CARD_DT    
 ,T6.PARA5_NAME,T6.PARA1_ALIAS,T6.PARA2_ALIAS,T6.PARA3_ALIAS,T6.PARA4_ALIAS,T6.PARA5_ALIAS,T6.PARA6_ALIAS    
 ,COM.GST_NO AS COMP_GSTNO     
    ,LOC.LOC_GST_NO AS COMP_LOC_GSTNO   ,T1.TOTAL_QUANTITY_STR, T6.para2_set
 FROM WPS_MST T1     (NOLOCK)       
 JOIN WPS_DET T2 (NOLOCK) ON T1.PS_ID = T2.PS_ID            
 JOIN LMV01106 T3 (NOLOCK) ON T3.AC_CODE = T1.AC_CODE            
 JOIN FORM   T4 (NOLOCK) ON T4.FORM_ID = T2.ITEM_FORM_ID            
 JOIN EMPLOYEE T5 (NOLOCK) ON T5.EMP_CODE = T2.EMP_CODE            
 JOIN USERS T7 (NOLOCK) ON T7.USER_CODE = T1.USER_CODE  
 JOIN USERS T8 (NOLOCK) ON T8.USER_CODE = T1.EDT_USER_CODE  
 jOiN Sku (noLoCk) On sku.product_code=t2.product_code    
 JOIN SKU_names T6 (NOLOCK) ON T6.PRODUCT_CODE = T2.PRODUCT_CODE            
 JOIN BIN BIN (NOLOCK) ON T2.BIN_ID=BIN.BIN_ID      
 left join LOC_VIEW loc (nolock) on loc.dept_id =LEFT (T1.PS_ID,2)    
 JOIN #tmpBoxes Z ON Z.PS_ID=T2.PS_ID    
 LEFT OUTER JOIN LMV01106 BRD (NOLOCK) ON T1.BROKER_AC_CODE = BRD.AC_CODE          
 LEFT OUTER JOIN ANGM ANG (NOLOCK) ON T1.ANGADIA_CODE =ANG.ANGADIA_CODE             
 LEFT OUTER JOIN COMPANY COM (NOLOCK) ON 1=1 AND COM.COMPANY_CODE=''01''    
 LEFT OUTER JOIN #tmpOrdPlan X ON X.PRODUCT_CODE=T2.PRODUCT_CODE    
 WHERE t1.ps_id='''+@cMemoId+''' AND T1.CANCELLED=0 '+    
 (CASE WHEN @cWhere<>'' THEN ' AND box_no IN ('+@cWhere+')' ELSE '' END) +    
 ' ORDER BY ARTICLE_NO,PARA1_NAME,PARA2_NAME'    
    
     
 PRINT @cCmd    
 EXEC SP_EXECUTESQL @cCmd    

 -- as per SHREE KRISHNA ENTERPRISES (WZHO000344)  order by
END