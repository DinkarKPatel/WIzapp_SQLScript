CREATE PROCEDURE SP_SLSMST_HOLD_QBF   
@cWHERE  NVARCHAR(50),  
@cTPay  NVARCHAR(100),  
@cTargetTableName NVARCHAR(100)  
--WITH ENCRYPTION

AS    
BEGIN  
 DECLARE @cCMD NVARCHAR(MAX),@cCMD1 NVARCHAR(MAX),@cCMD2 NVARCHAR(MAX),@cCMD3 NVARCHAR(MAX)  
  
 IF ISNULL(@cTPay,'')='' OR ISNULL(@cTargetTableName,'')='' return  
  
 SET @ccmd= N'IF OBJECT_ID('''+@cTargetTableName+N''',''U'') IS NOT NULL DROP TABLE '+@cTargetTableName+N'   
 SELECT  D.USER_CUSTOMER_CODE AS  MST_USER_CUSTOMER_CODE,MST.HOLD_ID AS  [CM_ID],MST.CM_NO AS MST_CM_NO,MST.CANCELLED AS MST_CANCELLED,   
   MST.CM_DT AS MST_CM_DT,MST.ATD_CHARGES AS MST_ATD_CHARGES,  
   MST.SUBTOTAL AS MST_SUBTOTAL,MST.DISCOUNT_PERCENTAGE AS MST_DISCOUNT_PERCENTAGE,MST.DISCOUNT_AMOUNT AS MST_DISCOUNT_AMOUNT ,    
   MST.NET_AMOUNT AS MST_NET_AMOUNT ,MST.REMARKS AS MST_REMARKS,E.USERNAME AS MST_USERNAME,  
   B.QUANTITY AS QUANTITY,B.DISCOUNT_PERCENTAGE ,B.DISCOUNT_AMOUNT ,EMP1.EMP_NAME AS MST_EMP_NAME,EMP1.EMP_ALIAS,    
   B.NET,B.MRP ,  
  D.CUSTOMER_TITLE+'' ''+D.CUSTOMER_FNAME +'' ''+ D.CUSTOMER_LNAME AS MST_CUST_NAME,D.ADDRESS1 +'' ''+D.ADDRESS2   AS MST_ADDRESS0,  
    X.ADDRESS  AS MST_ADDRESS1,mst.fc_rate,mst.CM_NO,mst.CM_DT,mst.CM_MODE,mst.SUBTOTAL  
 ,mst.DT_CODE,mst.NET_AMOUNT,mst.CUSTOMER_CODE,mst.CANCELLED,mst.REMARKS,mst.USER_CODE,mst.LAST_UPDATE 
 ,mst.sent_to_ho,mst.atd_charges
 ,b.emp_code,d.dt_anniversary,d.area_code,d.LOCATION_ID,d.address9  
 ,d.user_customer_code,d.customer_title,d.customer_fname,d.customer_lname,d.address1,d.address2,d.phone1,d.phone2,d.mobile  
 ,d.email,d.OPENING_BALANCE,d.dt_birth,d.ref_customer_code,d.prefix_code,d.flat_disc_customer,d.flat_disc_percentage  
 ,d.privilege_customer,d.dt_card_issue,d.dt_card_expiry,d.card_no,d.card_name,d.flat_disc_percentage_during_sales  
 ,e.username,e.major_user_code,e.user_alias,e.DISCOUNT_PERCENTAGE_LEVEL,e.VIEW_DATA_AFTER_DFM,emp1.emp_name,emp1.emp_head  
 ,dtm.dt_name,dtm.update_ac,sku.image_name,sku.challan_no,lm.opening_balance_cr_dr,lm.tds_code,lm.AC_NAME,lm.ALIAS,lm.HEAD_CODE  
 ,lm.CLOSING_BALANCE,lm.CLOSING_BALANCE_CR_DR,lm.PRINT_LEDGER,lm.Uploaded_to_ActivStream,form.form_name,form.purchase_ac_code  
 ,form.sale_ac_code,form.tax_ac_code,form.Post_Tax_Separately,form.pur_return_ac_code,form.sale_return_ac_code,form.physical_form  
 ,form.series,form.excise_accessible_percentage,form.excise_duty_percentage,form.excise_edu_cess_percentage,form.excise_hedu_cess_percentage  
 ,form.excise_edu_cess_ac_code,form.excise_hedu_cess_ac_code,form.excise_duty_ac_code,hd.HEAD_NAME,hd.MAJOR_HEAD_CODE  
 ,hd.PHYSICAL,hd.PRINT_HEAD'
  PRINT @ccmd  
  
 SET @ccmd1=N',hd.CREDITOR_DEBTOR_CODE,cmp.WORKABLE,cmp.PIN,cmp.LOGO_PATH,cmp.WEB_ADDRESS,cmp.sspl_first_hdsr,cmp.policy_no  
 ,cmp.PAN_NO,cmp.email_id,cmp.state,cmp.country,cmp.mobile AS Company_Mobile,cmp.contact_name,cmp.tds_ac_no,cmp.COMPANY_NAME  
 ,cmp.ADDRESS1 AS Company_Address1,cmp.ADDRESS2 AS Company_Address2,cmp.CITY,cmp.PHONES_FAX,cmp.CST_NO,cmp.CST_DT,cmp.SST_NO  
 ,cmp.SST_DT,cmp.grp_code,cmp.address9 AS Company_Address9,cmp.area_code AS Company_Area_Code,dlm.AC_NAME AS excise_duty_ac_name  
 ,elm.AC_NAME AS excise_edu_cess_ac_name,hlm.AC_NAME AS excise_hedu_cess_ac_name,prlm.AC_NAME AS pur_return_ac_name  
 ,srlm.ac_name AS sale_return_ac_name,plm.AC_NAME AS purchase_ac_name,slm.AC_NAME AS sale_ac_name,tlm.ac_code AS tax_ac_name  
 ,ca.area_name AS Customer_Area,cc.CITY AS Customer_City,cs.state AS Customer_State,crg.region_name AS Customer_Region  
 ,cpx.prefix_name,dc.customer_fname+ '' ''+dc.customer_lname AS Ref_Cusotmer,eu.username AS Major_User,emp2.emp_name AS Major_emp_name,  
  sku.ARTICLE_CODE, ARTICLE_NO, ARTICLE_NAME, sku.PARA1_CODE,PARA1_NAME, sku.PARA2_CODE,PARA2_NAME, sku.PARA3_CODE,PARA3_NAME, UOM_NAME,       
  CODING_SCHEME,  art.INACTIVE,sku.PURCHASE_PRICE,sku.WS_PRICE,SM.SECTION_NAME, SD.SUB_SECTION_NAME,    
  sku.PARA4_CODE,sku.PARA5_CODE,sku.PARA6_CODE,PARA4_NAME,PARA5_NAME,PARA6_NAME,art.UOM_CODE,ISNULL(UOM_TYPE,0) AS [UOM_TYPE],    
  art.DT_CREATED AS [ART_DT_CREATED],p3.DT_CREATED AS [PARA3_DT_CREATED],sku.DT_CREATED AS [SKU_DT_CREATED],    
  art.STOCK_Na,sku.PRODUCT_NAME,sku.AC_CODE,sku.INV_NO,sku.INV_DT,sku.RECEIPT_DT,sku.FORM_ID,mp_percentage,art.para1_set  
 ,art.para2_set,sku_code,article_desc,sd.sub_section_code,discon,wholesale_price,wsp_percentage,min_price,article_type  
 ,created_on,article_group_code,generate_barcodes_withArticle_Prefix,article_gen_mode,article_prd_mode,article_set_code  
 ,oh_percentage,oh_amount,sku.FIX_MRP,sd.section_code,sd.mfg_category,sku.product_code,T10.EMP_NAME AS MST_EMP_NAME1,    
 T11.EMP_NAME AS MST_EMP_NAME2,T10.EMP_NAME AS EMP_NAME1,  T11.EMP_NAME AS EMP_NAME2,B.TS  
 ,P4.ALIAS AS P4_ALIAS  '  
  PRINT @ccmd1

 SET @ccmd2=N' INTO '+ @cTargetTableName+ '  
 FROM CMM_HOLD MST (NOLOCK)   
 JOIN CMD_HOLD B (NOLOCK) ON B.HOLD_ID=MST.HOLD_ID    
 LEFT OUTER JOIN  sku (NOLOCK) ON sku.product_code=b.product_code  
 LEFT OUTER JOIN ARTICLE art (NOLOCK) ON sku.ARTICLE_CODE = art.ARTICLE_CODE      
 LEFT OUTER JOIN SECTIOND SD (NOLOCK) ON art.SUB_SECTION_CODE = SD.SUB_SECTION_CODE    
 LEFT OUTER JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE    
 LEFT OUTER JOIN PARA1 p1 (NOLOCK) ON sku.PARA1_CODE = p1.PARA1_CODE      
 LEFT OUTER JOIN PARA2 p2 (NOLOCK) ON sku.PARA2_CODE = p2.PARA2_CODE      
 LEFT OUTER JOIN PARA3 p3 (NOLOCK) ON sku.PARA3_CODE = p3.PARA3_CODE      
 LEFT OUTER JOIN PARA4 p4 (NOLOCK) ON sku.PARA4_CODE = p4.PARA4_CODE      
 LEFT OUTER JOIN PARA5 p5 (NOLOCK) ON sku.PARA5_CODE = p5.PARA5_CODE      
 LEFT OUTER JOIN PARA6 p6 (NOLOCK) ON sku.PARA6_CODE = p6.PARA6_CODE      
 LEFT OUTER JOIN UOM  (NOLOCK) ON art.UOM_CODE = UOM.UOM_CODE  
 LEFT OUTER JOIN CUSTDYM D (NOLOCK) ON D.CUSTOMER_CODE=MST.CUSTOMER_CODE     
 LEFT OUTER JOIN USERS E (NOLOCK) ON E.USER_CODE = MST.USER_CODE    
 LEFT OUTER JOIN EMPLOYEE EMP1 (NOLOCK) ON EMP1.EMP_CODE= B.EMP_CODE    
 LEFT OUTER JOIN    
 (  
  SELECT AREA_CODE ,AD1 .AREA_NAME +'' ''+AD2 .CITY +CHAR(10)+AD3 .STATE+'''' +AD1 .PINCODE AS ADDRESS  FROM AREA AD1   
  LEFT OUTER JOIN CITY AD2 (NOLOCK) ON AD2.CITY_CODE=AD1.CITY_CODE  
  LEFT OUTER JOIN STATE AD3 (NOLOCK) ON AD3.STATE_CODE =AD2.STATE_CODE  
  LEFT OUTER JOIN REGIONM AD4 (NOLOCK) ON AD4.REGION_CODE=AD3.REGION_CODE  
 )X ON X.AREA_CODE=D.AREA_CODE  
 LEFT OUTER JOIN dtm (NOLOCK) ON mst.DT_CODE=dtm.dt_code  
 LEFT OUTER JOIN LM01106 lm (NOLOCK) ON sku.ac_code=lm.AC_CODE  
 LEFT OUTER JOIN form (NOLOCK) ON sku.form_id=form.form_id  
 LEFT OUTER JOIN HD01106 hd (NOLOCK) ON lm.HEAD_CODE=hd.HEAD_CODE  
 LEFT OUTER JOIN COMPANY cmp (NOLOCK) ON hd.company_code=cmp.COMPANY_CODE  '  
  PRINT @ccmd2  

 SET @ccmd3=N' 
 LEFT OUTER JOIN LM01106 dlm (NOLOCK) ON form.excise_duty_ac_code=dlm.AC_CODE  
 LEFT OUTER JOIN LM01106 elm (NOLOCK) ON form.excise_edu_cess_ac_code=elm.AC_CODE  
 LEFT OUTER JOIN LM01106 hlm (NOLOCK) ON form.excise_hedu_cess_ac_code=hlm.AC_CODE  
 LEFT OUTER JOIN LM01106 prlm (NOLOCK) ON form.pur_return_ac_code=prlm.AC_CODE  
 LEFT OUTER JOIN LM01106 srlm (NOLOCK) ON form.sale_return_ac_code=srlm.AC_CODE  
 LEFT OUTER JOIN LM01106 plm (NOLOCK) ON form.purchase_ac_code=plm.AC_CODE  
 LEFT OUTER JOIN LM01106 slm (NOLOCK) ON form.sale_ac_code=slm.AC_CODE  
 LEFT OUTER JOIN LM01106 tlm (NOLOCK) ON form.tax_ac_code=tlm.AC_CODE  
 LEFT OUTER JOIN area ca (NOLOCK) ON d.area_code=ca.area_code  
 LEFT OUTER JOIN CITY cc (NOLOCK) ON ca.city_code=cc.CITY_CODE  
 LEFT OUTER JOIN state cs (NOLOCK) ON cc.state_code=cs.state_code  
 LEFT OUTER JOIN regionM crg (NOLOCK) ON cs.region_code=crg.region_code  
 left outer JOIN prefix cpx (NOLOCK) ON d.prefix_code=cpx.prefix_code  
 left outer JOIN custdym dc (NOLOCK) ON d.ref_customer_code=dc.customer_code  
 LEFT OUTER JOIN users eu (NOLOCK) ON e.major_user_code=eu.user_code  
 LEFT OUTER JOIN  employee emp2  (NOLOCK) ON emp1.emp_head=emp2.emp_code  
 LEFT OUTER JOIN EMPLOYEE T10 (NOLOCK) ON T10.EMP_CODE = B.EMP_CODE1  
 LEFT OUTER JOIN EMPLOYEE T11 (NOLOCK) ON T11.EMP_CODE = B.EMP_CODE2   
 LEFT OUTER JOIN ' + @cTPay + ' b123 on  mst.hold_id= b123.memo_id  
 WHERE mst.hold_id='''+@cwhere+''' order by B.ts'  
  PRINT @ccmd3  

 set @ccmd=@ccmd+@ccmd1+@ccmd2+@ccmd3  
 PRINT @ccmd  
  
 EXEC SP_EXECUTESQL @ccmd  
END  

