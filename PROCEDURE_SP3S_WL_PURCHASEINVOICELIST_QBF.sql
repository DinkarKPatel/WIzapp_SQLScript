create PROCEDURE SP3S_WL_PURCHASEINVOICELIST_QBF
(
	@CMRRID VARCHAR(22),
	@Mode int=0  ,-- O- For Normal, 1 For  temp table
	@cTable  varchar(200)=''
)
AS           
BEGIN
SET NOCOUNT ON 



DECLARE @AC_CODE VARCHAR(20),@MTERMS VARCHAR(MAX),@TERMSNAME VARCHAR(MAX),@DTSQL nvarchar(max)

SET @AC_CODE=(SELECT AC_CODE FROM PIM01106(NOLOCK) WHERE MRR_ID=@CMRRID )


  IF OBJECT_ID('PID_PIM_TEMP','U') IS NOT NULL  
       DROP TABLE PID_PIM_TEMP  

SELECT  A.MRR_ID,A.PARTY_INV_AMOUNT,A.TAXFORM_STORAGE_MODE,A.BILL_LEVEL_TAX_METHOD
,A.FREIGHT,A.MEMO_TYPE,
C.TS,C.MRP,C.PURCHASE_PRICE,C.QUANTITY,C.PRODUCT_CODE,C.MP_PERCENTAGE,C.BOX_NO,C.AREA_UOM_CODE,
A.BILL_CHALLAN_MODE,A.INV_MODE,A.CHECKED_BY,A.RECEIVED_BY  ,C.FORM_ID,A.USER_CODE,A.SENT_TO_HO,A.FIN_YEAR,A.EDT_USER_CODE,A.CREDIT_DAYS,A.CR_DISCOUNT_PERCENTAGE,
A.INV_DT AS VANDOR_BILL_DT  
,A.POSTEDINAC,A.MRR_NO,A.INV_NO,A.INV_DT,A.BILL_NO,A.RECEIPT_DT,A.AC_CODE,A.TOTAL_AMOUNT,A.REMARKS,A.SUBTOTAL,A.DISCOUNT_PERCENTAGE  
,A.DISCOUNT_AMOUNT,A.OTHER_CHARGES,A.MEMO_PREFIX,A.TAX_PERCENTAGE,A.EMP_CODE,A.BIN_ID,A.TAX_AMOUNT,A.ROUND_OFF,A.CANCELLED,A.DEPT_ID,A.EXCISE_DUTY_AMOUNT,A.PIM_MODE 
,C.PARA4_CODE,C.PARA5_CODE,C.PARA6_CODE,C.PRINT_LABEL,C.ROW_ID,C.MD_PERCENTAGE,C.WD_PERCENTAGE,C.SRNO,C.WHOLESALE_PRICE  
,C.WSP_PERCENTAGE,C.GROSS_PURCHASE_PRICE,C.PO_ROW_ID,C.INVOICE_QUANTITY,C.SCHEME_QUANTITY ,C.Gst_Cess_Percentage ,C.Gst_Cess_Amount 
INTO PID_PIM_TEMP FROM PIM01106 A(NOLOCK) JOIN PID01106 C(NOLOCK) ON A.MRR_ID=C.MRR_ID WHERE A.MRR_ID = @CMRRID



SET @DTSQL=N'SELECT   
A.MRR_ID,A.MEMO_TYPE,  
A.PARTY_INV_AMOUNT AS MST_PARTY_INV_AMOUNT,
A.TAXFORM_STORAGE_MODE AS MST_TAXFORM_STORAGE_MODE,
A.BILL_LEVEL_TAX_METHOD AS MST_BILL_LEVEL_TAX_METHOD,
'''' AS MST_FORM_NAME,
A.RECEIPT_DT AS MST_XN_DT,   
A.MRR_NO AS MST_MRR_NO,   
A.INV_NO AS MST_INV_NO,   
A.BILL_NO AS MST_BILL_NO,  
A.VANDOR_BILL_DT AS MST_VANDOR_BILL_DT,  
A.CHECKED_BY AS MST_CHECKED_BY,  
A.TOTAL_AMOUNT AS MST_TOTAL_AMOUNT,          
A.INV_DT AS MST_INV_DT,   
A.DISCOUNT_AMOUNT AS MST_DISCOUNT_AMOUNT,  
A.DISCOUNT_PERCENTAGE AS MST_DISCOUNT_PERCENTAGE,  
A.FREIGHT AS MST_FREIGHT,  
A.OTHER_CHARGES AS MST_OTHER_CHARGES,  
A.ROUND_OFF AS MST_ROUND_OFF,  
A.RECEIVED_BY AS MST_RECEIVED_BY,  
A.MEMO_TYPE AS MST_MEMO_TYPE,  
A.REMARKS AS MST_REMARKS,  
A.SUBTOTAL AS MST_SUBTOTAL,  
A.TAX_AMOUNT AS MST_TAX_AMOUNT,  
A.TAX_PERCENTAGE AS MST_TAX_PERCENTAGE,  
A.FIN_YEAR AS MST_FIN_YEAR,  
B.AC_NAME AS MST_SUPP_NAME,  
B.ADDRESS0 AS MST_ADDRESS0,  
B.ADDRESS1 AS MST_ADDRESS1,  
B.ADDRESS2 AS MST_ADDRESS2,  
B.AREA_NAME AS MST_AREA_NAME,  
B.CITY AS MST_CITY,  
B.PINCODE AS MST_PINCODE,  
B.STATE AS MST_STATE,  
H.USERNAME AS MST_CREATED_USERNAME,  
A.TS AS TS,  
A.QUANTITY AS QUANTITY,   
A.PURCHASE_PRICE AS PURCHASE_PRICE,  
A.MRP AS MRP,
SKU.MRP AS SKU_MRP,  
CAST((CASE WHEN A.PURCHASE_PRICE>0 THEN (SKU.MRP - A.PURCHASE_PRICE) * 100 / A.PURCHASE_PRICE ELSE 0 END  ) AS NUMERIC(10,2))AS SKU_MP ,  
CAST((CASE WHEN SKU.MRP>0 THEN (SKU.MRP - A.PURCHASE_PRICE) * 100 / SKU.MRP ELSE 0 END  ) AS NUMERIC(10,2))AS SKU_MD ,
 
A.PURCHASE_PRICE * A.QUANTITY AS AMOUNT,  
A.PRODUCT_CODE AS PRODUCT_CODE,  
A.MP_PERCENTAGE AS MP_PERCENTAGE,  
P1.PARA1_NAME AS PARA1_NAME,   
P2.PARA2_NAME AS PARA2_NAME,   
P3.PARA3_NAME AS PARA3_NAME,         
P4.PARA4_NAME AS PARA4_NAME,   
P5.PARA5_NAME AS PARA5_NAME,   
P6.PARA6_NAME AS PARA6_NAME,         
D.ARTICLE_NO AS ARTICLE_NO,   
D.ARTICLE_NAME AS ARTICLE_NAME,  
D.ARTICLE_DESC AS ARTICLE_DESC,  
E.SUB_SECTION_NAME AS SUB_SECTION_NAME,   
F.SECTION_NAME AS SECTION_NAME,        
U.UOM_NAME AS UOM_NAME,  
A.EXCISE_DUTY_AMOUNT AS MST_EXCISE_DUTY_AMOUNT,  
A.BOX_NO,  
A.BILL_CHALLAN_MODE,  
A.INV_MODE AS PURCHASE_TYPE  
,A.CHECKED_BY  
,A.RECEIVED_BY  
,A.FORM_ID  
,A.USER_CODE  
,A.SENT_TO_HO  
,A.FIN_YEAR  
,A.EDT_USER_CODE  
,A.CREDIT_DAYS  AS MST_CREDIT_DAYS 
,A.CR_DISCOUNT_PERCENTAGE  
,A.VANDOR_BILL_DT  
,A.POSTEDINAC  
,A.MRR_NO  
,A.INV_NO  
,A.INV_DT  
,A.BILL_NO  
,A.RECEIPT_DT  
,A.AC_CODE  
,A.TOTAL_AMOUNT  
,A.REMARKS  
,A.SUBTOTAL  
,A.DISCOUNT_PERCENTAGE  
,A.DISCOUNT_AMOUNT  
,A.OTHER_CHARGES  
,A.FREIGHT  
,A.TAX_PERCENTAGE  
,A.TAX_AMOUNT  
,A.ROUND_OFF  
,A.CANCELLED  
,A.DEPT_ID  
,A.EXCISE_DUTY_AMOUNT  
,A.PIM_MODE  
,B.AC_NAME  
,B.ALIAS  
,B.HEAD_CODE  
,B.CLOSING_BALANCE  
,B.CLOSING_BALANCE_CR_DR  
,B.PRINT_LEDGER  
,B.PRINT_NAME  
,B.ADDRESS0  
,B.ADDRESS1  
,B.ADDRESS2  
,B.AREA_CODE  
,B.AREA_NAME  
,B.PINCODE  
,B.CITY_CODE  
,B.CITY  
,B.STATE_CODE  
,B.STATE  
,B.CST_NO  
,B.CST_DT  
,B.SST_NO  
,B.SST_DT  
,B.TIN_NO  
,B.TIN_DT  
,B.PHONES_R  
,B.PHONES_O  
,B.PHONES_FAX  
,B.MOBILE  
,B.E_MAIL  
,B.TAX_CODE  
,B.BILL_BY_BILL  
,B.ON_HOLD  
,B.THROUGH_BROKER  
,B.BROKER_AC_CODE  
,B.BROKER_COMM_PERCENT  
,B.CREDIT_LIMIT  
,B.ALLOW_CREDITOR_DEBTOR  
,B.DPWEF_DT  
,B.CST_PERCENTAGE  
,B.PAN_NO  
,B.CUSTOMER_CODE  
,B.GLN_NO  
,B.MRP_CALC_MODE  
,B.TDS_CODE  
,B.INV_RATE_TYPE  
,B.OUTSTATION_PARTY  
,B.SALES_AC_CODE  
,B.USERNAME  
,B.EDT_USERNAME  
,A.PARA4_CODE  
,A.PARA5_CODE  
,A.PARA6_CODE  
,SKU.ARTICLE_CODE  
,SKU.PARA1_CODE  
,SKU.PARA2_CODE  
,A.PRINT_LABEL  
,A.ROW_ID  
,SKU.PARA3_CODE  
,A.SRNO  
,A.WHOLESALE_PRICE  
,A.WSP_PERCENTAGE  
,A.GROSS_PURCHASE_PRICE  
,A.PO_ROW_ID  
,A.INVOICE_QUANTITY  
,A.SCHEME_QUANTITY  
,D.CODING_SCHEME  
,D.UOM_CODE  
,COM.COMPANY_CODE
,D.PARA1_SET  
,D.PARA2_SET  
,D.INACTIVE  
,D.SKU_CODE  
,D.DT_CREATED  
,D.SUB_SECTION_CODE  
,D.DISCON  
,D.MIN_PRICE  
,D.STOCK_NA  
,D.ARTICLE_TYPE  
,D.CREATED_ON  
,D.ARTICLE_GROUP_CODE   
,D.GENERATE_BARCODES_WITHARTICLE_PREFIX  
,D.ARTICLE_GEN_MODE  
,D.ARTICLE_PRD_MODE  
,D.ARTICLE_SET_CODE  
,D.OH_PERCENTAGE  
,D.OH_AMOUNT  
,D.FIX_MRP  
,E.SECTION_CODE  
,E.MFG_CATEGORY  
,H.MAJOR_USER_CODE  
,H.USER_ALIAS  
,H.DISCOUNT_PERCENTAGE_LEVEL  
,H.VIEW_DATA_AFTER_DFM  
,H.EMAIL  
,U.UOM_TYPE  
,LCT.DEPT_ID AS LOCATION_DEPT_ID  
,LCT.DEPT_NAME AS LOCATION_DEPT_NAME  
,LCT.MAJOR_DEPT_ID AS LOCATION_MAJOR_DEPT_ID  
,LCT.AREA_CODE AS LOCATION_AREA_CODE  
,LCT.PRIMARY_EMAIL AS LOCATION_PRIMARY_EMAIL  
,LCT.PRIMARY_EMAIL_SMTP AS LOCATION_PRIMARY_EMAIL_SMTP  
,LCT.PRIMARY_EMAIL_PWD AS LOCATION_PRIMARY_EMAIL_PWD  
,LCT.PRIMARY_EMAIL_SSL AS LOCATION_PRIMARY_EMAIL_SSL  
,LCT.SSPL_GRP_CODE AS LOCATION_SSPL_GRP_CODE  
,LCT.PUR_LOC AS LOCATION_PUR_LOC  
,LCT.ADDRESS1 AS LOCATION_ADDRESS1  
,LCT.ADDRESS2 AS LOCATION_ADDRESS2  
,LCT.DEPT_AC_CODE AS LOCATION_DEPT_AC_CODE  
,LCT.CST_NO AS LOCATION_CST_NO  
,LCT.CST_DT AS LOCATION_CST_DT  
,LCT.LST_NO AS LOCATION_LST_NO  
,LCT.LST_DT AS LOCATION_LST_DT  
,LCT.DEPT_ALIAS AS LOCATION_DEPT_ALIAS  
,LCT.PHONE AS LOCATION_PHONE  
,LCT.DATE_OF_OPENING AS LOCATION_DATE_OF_OPENING  
,LCT.REPORT_BLOCKED AS LOCATION_REPORT_BLOCKED  
,LCT.INACTIVE AS LOCATION_INACTIVE  
,LCT.LOC_TYPE AS LOCATION_LOC_TYPE  
,LCT.ACCOUNTS_POSTING_DEPT_ID AS LOCATION_ACCOUNTS_POSTING_DEPT_ID  
,LCT.CONTROL_AC_CODE AS LOCATION_CONTROL_AC_CODE  
,LCT.UPD_PURINFO AS LOCATION_UPD_PURINFO  
,LCT.SSPL_REG_KEY AS LOCATION_SSPL_REG_KEY  
,LCT.WIZCOM_ENABLED AS LOCATION_WIZCOM_ENABLED  
,LCT.EXCISABLE AS LOCATION_EXCISABLE  
,LCT.TIN_NO AS LOCATION_TIN_NO  
,LCT.FR_TYPE AS LOCATION_FR_TYPE  
,LCT.PRIMARY_EMAIL_PORT AS LOCATION_PRIMARY_EMAIL_PORT  
,LA.AREA_NAME AS LOCATION_AREA  
,LC.CITY AS LOCATION_CITY  
,LS.STATE AS LOCATION_STATE  
,LRG.REGION_NAME AS LOCATION_REGION  
,EU.USERNAME AS EDIT_USERNAME  
,G.FORM_NAME AS FORM_NAME 
,G.FORM_NAME AS ITEM_TAX_PERCENTAGE     
,DLM.AC_NAME AS EXCISE_DUTY_AC_NAME  
,ELM.AC_NAME AS EXCISE_EDU_CESS_AC_NAME  
,HLM.AC_NAME AS EXCISE_HEDU_CESS_AC_NAME  
,PRLM.AC_NAME AS PUR_RETURN_AC_NAME  
,SRLM.AC_NAME AS SALE_RETURN_AC_NAME  
,PLM.AC_NAME AS PURCHASE_AC_NAME  
,SLM.AC_NAME AS SALE_AC_NAME  
,TLM.AC_CODE AS TAX_AC_NAME  
,MU.USERNAME AS MAJOR_USERNAME,SKU.PRODUCT_NAME  
,POM.PO_NO ,POM.PO_DT ,A.MEMO_PREFIX AS MST_MEMO_PREFIX,  
A.MD_PERCENTAGE,A.WD_PERCENTAGE,
EMP.EMP_NAME AS MST_EMP_NAME  
,ISNULL(ANGM.ANGADIA_NAME,'''') AS ANGADIA_NAME  
,ISNULL(ANGM.ANGADIA_ALIAS,'''') AS ANGADIA_ALIAS  
,ISNULL(ANGM.ANGADIA_ADD1,'''') AS ANGADIA_ADD1  
,ISNULL(ANGM.ANGADIA_ADD2,'''') AS ANGADIA_ADD2  
,ISNULL(ANGM.ANGADIA_PHONE,'''') AS ANGADIA_PHONE  
,ISNULL(PMST.PARCEL_MEMO_NO,'''') AS PARCEL_MEMO_NO  
,ISNULL(PMST.PARCEL_MEMO_DT,'''') AS PARCEL_MEMO_DT  
,ISNULL(PMST.TOTAL_AMOUNT,0) AS PARCEL_TOTAL_AMOUNT  
,ISNULL(PMST.DEPT_ID,'''') AS PARCEL_DEPT_ID  
,ISNULL(PMST.PARCEL_MEMO_ID,'''') AS PARCEL_MEMO_ID  
,ISNULL(PMST.PAY_TYPE,0) AS PAY_TYPE  
,ISNULL(PMST.CASH_RECEIPT_NO,'''') AS CASH_RECEIPT_NO  
,ISNULL(PMST.BILTY_NO,'''') AS BILTY_NO
,BIN.BIN_NAME  
,BIN.BIN_NAME AS MST_BIN_NAME
,LT.PAYMENT_TYPE
,LT.GROSS_MARGIN
,LT.CREDIT_DAYS
,LT.CD
,LT.TD
,LT.REIMUBURSE_PURCHASE_TAX
,LT.REIMUBURSE_FREIGHT
,LT.REIMUBURSE_INSURANCE
,LT.REIMUBURSE_OUTPUT_VAT
,LT.TERMS AS TERMS_OLD
,LT.LAST_UPDATE
,LT.REMARKS AS LEDGERREMARKS
,LT.CASHDISCOUNT
,COM.PAN_NO AS COMP_PANNO
,COM.EMAIL_ID AS COMP_EMAILID
,COM.PWD AS COMP_PWD
,COM.STATE AS COMP_STATE 
,COM.COUNTRY AS COMP_CONTRY
,COM.MOBILE AS COMP_MOBILE
,COM.CONTACT_NAME AS COMP_CONTACTNAME
,COM.TDS_AC_NO AS COMP_TDSACNO
,COM.COMPANY_NAME AS COMP_COMPANYNAME
,COM.ALIAS AS COMP_ALIAS
,COM.ADDRESS1 AS COMP_ADDRESS1
,COM.ADDRESS2 AS COMP_ADDRESS2 
,COM.CITY AS COMP_CITY
,COM.TAN_NO AS COMP_TANNO
,COM.PHONES_FAX AS COMP_PHONES_FAX
,COM.CST_DT AS COMP_CST_DT
,COM.SST_NO AS COMP_SSTNO
,COM.SST_DT AS COMP_SSTDT
,COM.GRP_CODE AS COMP_GRPCODE
,COM.ADDRESS9 AS COMP_ADDRESS9
,COM.AREA_CODE AS COMP_AREACODE
,COM.PRINT_ADDRESS AS COMP_PRINTADDRESS
,COM.WORKABLE AS COMP_WORKABLE
,COM.PIN AS COMP_PIN
,COM.LOGO_PATH AS COMP_LOGOPATH
,COM.WEB_ADDRESS AS COMP_WEBADDRESS
,COM.SSPL_FIRST_HDSR AS COMP_SSPLFIRSTHDSR
,COM.POLICY_NO AS COMP_POLICYNO
,COM.GRP_NAME AS COMP_GRPNAME 
,COM.CIN AS COMP_CIN
,COM.TIN_NO AS COMP_TIN_NO
,LCT.DEPT_NAME AS MST_ACCOUNTS_DEPT_NAME
,LT.PAYMENT_TYPE AS LM_PAYMENT_TYPE
,LT.PURCHASE_TYPE AS LM_PURCHASE_TYPE
,LT.GROSS_MARGIN AS LM_GROSS_MARGIN
,LT.CREDIT_DAYS AS LM_CREDIT_DAYS
,LT.REIMUBURSE_PURCHASE_TAX AS LM_REIMUBURSE_PURCHASE_TAX
,LT.REIMUBURSE_FREIGHT AS LM_REIMUBURSE_FREIGHT
,LT.REIMUBURSE_INSURANCE AS LM_REIMUBURSE_INSURANCE
,LT.REIMUBURSE_OUTPUT_VAT AS LM_REIMUBURSE_OUTPUT_VAT
,LT.TERMS AS LM_TERMS
,LT.REMARKS AS LM_REMARKS
,LT.TERMS_NAME AS LM_TERMS_NAME,A.Gst_Cess_Percentage ,A.Gst_Cess_Amount '+
case when @Mode=1 then ' into '+ @cTable else '' end +
' FROM COMPANY COM(NOLOCK) 
JOIN PID_PIM_TEMP (NOLOCK) A  ON COM.COMPANY_CODE =''01''
LEFT JOIN LEDGER_TERMS LT (NOLOCK) ON 1=2
LEFT JOIN PARCEL_det PB (NOLOCK) ON A.MRR_ID=PB.REF_MEMO_ID 
LEFT JOIN PARCEL_MST PMST (NOLOCK) ON PMST.PARCEL_MEMO_ID=PB.REF_MEMO_ID AND PMST.XN_TYPE=''PUR'' 
LEFT JOIN ANGM (NOLOCK) ON PMST.ANGADIA_CODE=ANGM.ANGADIA_CODE  
JOIN LMV01106 (NOLOCK) B ON A.AC_CODE = B.AC_CODE          
JOIN SKU (NOLOCK)  ON SKU.PRODUCT_CODE = A.PRODUCT_CODE  
JOIN ARTICLE (NOLOCK) D ON SKU.ARTICLE_CODE = D.ARTICLE_CODE          
JOIN SECTIOND (NOLOCK) E ON D.SUB_SECTION_CODE = E.SUB_SECTION_CODE           
JOIN SECTIONM (NOLOCK) F ON E.SECTION_CODE = F.SECTION_CODE           
JOIN PARA1 (NOLOCK) P1 ON SKU.PARA1_CODE = P1.PARA1_CODE          
JOIN PARA2 (NOLOCK) P2 ON SKU.PARA2_CODE = P2.PARA2_CODE          
JOIN PARA3 (NOLOCK) P3 ON SKU.PARA3_CODE = P3.PARA3_CODE          
JOIN PARA4 (NOLOCK) P4 ON SKU.PARA4_CODE = P4.PARA4_CODE          
JOIN PARA5 (NOLOCK) P5 ON SKU.PARA5_CODE = P5.PARA5_CODE          
JOIN PARA6 (NOLOCK) P6 ON SKU.PARA6_CODE = P6.PARA6_CODE          
JOIN USERS (NOLOCK) H ON A.USER_CODE = H.USER_CODE 
JOIN BIN  (NOLOCK) ON BIN.BIN_ID = A.BIN_ID  
JOIN UOM (NOLOCK) U ON D.UOM_CODE = U.UOM_CODE  
JOIN LOCATION LCT(NOLOCK) ON A.DEPT_ID=LCT.DEPT_ID  
JOIN USERS EU(NOLOCK) ON A.EDT_USER_CODE=EU.USER_CODE  
JOIN AREA LA(NOLOCK) ON LCT.AREA_CODE=LA.AREA_CODE  
JOIN CITY LC(NOLOCK) ON LC.CITY_CODE=LA.CITY_CODE  
JOIN STATE LS(NOLOCK) ON LC.STATE_CODE=LS.STATE_CODE 
JOIN REGIONM LRG(NOLOCK) ON LS.REGION_CODE=LRG.REGION_CODE  
LEFT OUTER JOIN FORM G(NOLOCK) ON G.FORM_ID=A.FORM_ID  
JOIN LM01106 DLM ON G.EXCISE_DUTY_AC_CODE=DLM.AC_CODE  
JOIN LM01106 ELM(NOLOCK) ON G.EXCISE_EDU_CESS_AC_CODE=ELM.AC_CODE  
JOIN LM01106 HLM(NOLOCK) ON G.EXCISE_HEDU_CESS_AC_CODE=HLM.AC_CODE  
JOIN LM01106 PRLM(NOLOCK) ON G.PUR_RETURN_AC_CODE=PRLM.AC_CODE  
JOIN LM01106 SRLM(NOLOCK) ON G.SALE_RETURN_AC_CODE=SRLM.AC_CODE  
JOIN LM01106 PLM(NOLOCK) ON G.PURCHASE_AC_CODE=PLM.AC_CODE  
JOIN LM01106 SLM(NOLOCK) ON G.SALE_AC_CODE=SLM.AC_CODE  
JOIN LM01106 TLM(NOLOCK) ON G.TAX_AC_CODE=TLM.AC_CODE  
JOIN USERS MU(NOLOCK) ON H.MAJOR_USER_CODE=MU.USER_CODE  
LEFT OUTER JOIN EMPLOYEE EMP(NOLOCK) ON A.EMP_CODE = EMP.EMP_CODE   
LEFT OUTER JOIN POD01106 (NOLOCK) POD ON POD.ROW_ID = A.PO_ROW_ID   
LEFT OUTER JOIN POM01106 (NOLOCK) POM ON POM.PO_ID = POD.PO_ID 
LEFT OUTER JOIN UOM AR_U (NOLOCK) ON AR_U.UOM_CODE=A.AREA_UOM_CODE '

print @DTSQL
exec sp_executesql @DTSQL






END
