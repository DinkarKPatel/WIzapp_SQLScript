CREATE PROCEDURE SP3S_APIWSLUPLOAD_CLEARTAX--(LocId 3 digit change by Sanjay:04-11-2024)
(        
@CXNID VARCHAR(50)=''        
)        
AS        
BEGIN        
        
   
  
	DECLARE @Donot_Prefix_Year_while_Generating_Einvoice VARCHAR(5)
	SELECT @Donot_Prefix_Year_while_Generating_Einvoice=value  FROM CONFIG WHERE config_option ='Donot_Prefix_Year_while_Generating_Einvoice'

	set @Donot_Prefix_Year_while_Generating_Einvoice=isnull(@Donot_Prefix_Year_while_Generating_Einvoice,'')
     
        IF OBJECT_ID ('TEMPDB..#TRANSPORTER','U') IS NOT NULL                                
           DROP TABLE #TRANSPORTER            
    SELECT A.PARCEL_MEMO_ID, ANGM.ANGADIA_NAME AS TRANSPORTER_NAME , angm.Angadia_code ,       
           ANGADIA_ADD1 ,ANGADIA_ADD2  ,AR.AREA_NAME ,AR.PINCODE , lmp.ac_gst_state_code  AS STATE ,A.MODE ,  
     vehicle_no , parcel_memo_no , parcel_memo_dt ,bilty_no ,lmp.Ac_gst_no as TRANSPORTER_GST_NO ,TRST.GST_STATE_NAME                                       
    INTO #TRANSPORTER                                
    FROM PARCEL_MST A (NOLOCK)                                
    JOIN PARCEL_DET B (NOLOCK) ON A.PARCEL_MEMO_ID =B.PARCEL_MEMO_ID                                           
    LEFT OUTER JOIN ANGM (NOLOCK) ON ANGM.ANGADIA_CODE =A.ANGADIA_CODE            
    LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE =ANGM.AREA_CODE  
	left join lmp01106 lmp (nolock) on lmp.ac_code= angm.ac_code   
	LEFT JOIN GST_STATE_MST trST (NOLOCK) ON trST.GST_STATE_CODE=lmp.ac_gst_state_code                  
    WHERE A.XN_TYPE ='WSL' AND B.REF_MEMO_ID=@CXNID          
    AND A.CANCELLED =0        
    GROUP BY A.PARCEL_MEMO_ID, ANGM.ANGADIA_NAME  ,        
    ANGADIA_ADD1 ,ANGADIA_ADD2  ,AR.AREA_NAME ,AR.PINCODE ,  lmp.ac_gst_state_code,A.MODE,vehicle_no ,parcel_memo_no,bilty_no, parcel_memo_dt 
	,angm.Angadia_code ,lmp.Ac_gst_no  ,TRST.GST_STATE_NAME                        
     
           
    ;WITH CTE AS                                 
    (                                
   SELECT PARCEL_MEMO_ID,SR=ROW_NUMBER () OVER (ORDER BY PARCEL_MEMO_ID)                                 
   FROM #TRANSPORTER                                
    )                                
                                   
    DELETE FROM CTE WHERE SR>1      
   
        
        
    DECLARE @NIGSTVAL NUMERIC(10,2),@NCGSTVAL NUMERIC(10,2),@NSGSTVAL NUMERIC(10,2),@NCESSaMOUNT  NUMERIC(10,2)  ,@NTABLABLEVALUE NUMERIC(18,2)  , @NDISCOUNT_AMOUNT NUMERIC(10,2)  
        
  SELECT @NIGSTVAL=SUM(IGST_AMOUNT),@NCGSTVAL=SUM(CGST_AMOUNT),@NSGSTVAL=SUM(CGST_AMOUNT),@NCESSaMOUNT=SUM(CESS_AMOUNT),  
  @NTABLABLEVALUE= SUM(XN_VALUE_WITHOUT_GST ),-- SUM(XN_VALUE_WITHOUT_GST),
  @NDISCOUNT_AMOUNT =SUM(DISCOUNT_AMOUNT)  
  FROM IND01106         
  WHERE INV_ID =@CXNID      
  

   DECLARE @NPICKINGSHIPPINGADDRESS INT
--1 FOR  INM  SHIPPING AC_CODE DETAILS 2.INM SHPING ADDRESS STORED IN INM 3 FOR PARTY ADDRESS

 SELECT @NPICKINGSHIPPINGADDRESS=
      CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0 
	       THEN CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN 1 ELSE 2 END 
		   ELSE 3 END  
 FROM INM01106  WHERE INV_ID=@CXNID

    
 IF OBJECT_ID('TEMPDB..#TMPINVOICE','U') IS NOT NULL  
    DROP TABLE #TMPINVOICE  
           
   SELECT 
     ID=RTRIM(LTRIM(A.INV_NO)),TRANSACTION_DATE=CONVERT(VARCHAR,A.INV_DT,103),RETURN_PERIOD='NULL',SOURCE='USER',
     TOTAL_TAXABLE_VAL=cast(@NTABLABLEVALUE+isnull(a.other_charges_taxable_value,0)+isnull(a.freight_taxable_value,0)+isnull(a.insurance_taxable_value,0)+isnull(a.packing_taxable_value,0)  as numeric(18,2)),
	 TOTAL_IGST_VAL=cast(@NIGSTVAL+isnull(a.other_charges_Igst_amount ,0)+isnull(a.freight_igst_amount ,0)+isnull(a.insurance_igst_amount ,0)+isnull(a.packing_igst_amount ,0) as numeric(18,2)),
	 TOTAL_CGST_VAL=cast(@NCGSTVAL+isnull(a.other_charges_cgst_amount ,0)+isnull(a.freight_cgst_amount ,0)+isnull(a.insurance_cgst_amount ,0)+isnull(a.packing_cgst_amount ,0) as numeric(18,2)),
	 TOTAL_SGST_VAL=cast(@NSGSTVAL+isnull(a.other_charges_sgst_amount ,0)+isnull(a.freight_sgst_amount ,0)+isnull(a.insurance_sgst_amount ,0)+isnull(a.packing_sgst_amount ,0) as numeric(18,2)),
     TOTAL_VAL=A.NET_AMOUNT ,
	 PLACE_OF_SUPPLY=L.STATE,IS_CANCELED=CASE WHEN CANCELLED=0 THEN 'false' ELSE 'true' END  ,
     BRANCH_ID=L.BRANCH_ID ,DOCUMENT_NUMBER=RTRIM(LTRIM(A.INV_NO)),TYP='SALE',
      --*******SELLER******
      GSTIN=L.LOC_GST_NO,SELLER_NAME=L.dept_name,ADDRESS1=L.ADDRESS1,ADDRESS2=L.ADDRESS2,CITY=L.CITY,L_STATE=LST.GST_STATE_NAME,ZIP_CODE=L.PINCODE,
      COUNTRY= ISNULL(NULLIF(L.COUNTRY_NAME,''),'NULL') ,PHONE_NUMBER= ISNULL(NULLIF(L.PHONE ,''),'NULL'),

	   --*******RECEIVER******
       RNAME=LM.AC_NAME,R_GSTIN=LM.AC_GST_NO,R_ADDRESS1=LM.ADDRESS1,R_ADDRESS2 =CASE WHEN ISNULL(LM.ADDRESS2,'')='' THEN '...' ELSE LM.ADDRESS2 END ,
       R_CITY=LM.CITY ,R_STATE=LMST.GST_STATE_NAME,R_ZIP_CODE=LM.PINCODE,R_COUNTRY='NULL',
       R_PHONE_NUMBER=ISNULL(NULLIF(CASE WHEN ISNULL( LM.MOBILE,'')='' THEN LM.PHONES_O ELSE LM.MOBILE END,''),'NULL') ,

	    --*******consignee******
     
       SH_NAME= CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	                 WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		         ELSE LM.Ac_gst_no end,

       SH_GSTIN= CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	                  WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		              ELSE LM.Ac_gst_no  END,

       sh_address1 = CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS0 
	                      WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS 
		             ELSE LM.ADDRESS0 END,

       sh_address2= CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS1 
	                     WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS2 
		             ELSE LM.ADDRESS1 END,

       sh_city =   CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHCT.CITY  
	                     WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_city_NAME 
		             ELSE lm.city  END,

       sh_state=   CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHcs.GST_STATE_NAME   
	                    WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(shp.GST_STATE_NAME ,'') 
		           ELSE LMSTATE.GST_STATE_NAME     END,

       sh_zip_code=  CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.pincode   
	                      WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(a.SHIPPING_PIN,'') 
		            ELSE lm.PINCODE    END,

       SH_COUNTRY='NULL',
      SH_PHONE_NUMBER= case when isnull('','')='' then '' else '' end ,

	    --*******Transporter******

	  TRANSPORT_MODE='road',TRANSPORTER_GSTIN=CASE WHEN ISNULL(TR.TRANSPORTER_GST_NO,'')='' THEN '' ELSE TR.TRANSPORTER_GST_NO END,
      TRANSPORTER_FROM_PLACE=ISNULL(NULLIF(TR.AREA_NAME ,''),'NULL'),TRANSPORTER_FROM_STATE=ISNULL(NULLIF(TR.  GST_STATE_NAME ,''),'NULL'),
      DISPATCH_FROM_STATE=LST.GST_STATE_NAME,SUB_SUPPLY=CASE WHEN L.LOC_GST_NO<>LM.AC_GST_NO THEN 'SUPPLY' ELSE 'Own_Use' END,

     --*******line_items******
    
         item_code=SN.ARTICLE_NO,gst_code=IND.HSN_CODE,gst_type='GOODS',descr=SN.ARTICLE_NAME,notes='null',
         unit_price= CAST(XN_VALUE_WITHOUT_GST /INVOICE_QUANTITY  AS NUMERIC(14,2)),
         unit_price_including_tax=CAST(XN_VALUE_WITH_GST /INVOICE_QUANTITY  AS NUMERIC(14,2)),
         unit_of_measurement=uom.uom_name ,
         item_id=SN.ARTICLE_NO,serial_number= ROW_NUMBER () OVER (ORDER BY sn.ARTICLE_NO ) ,
         quantity=sum(quantity),
         discount_rate='null',discount='null',
         taxable_val=CAST(SUM(XN_VALUE_WITHOUT_GST) AS NUMERIC(14,2)),
         cgst_rate=replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN IND.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
         cgst_val=CAST(SUM(IND.CGST_AMOUNT) AS NUMERIC(14,2)),
         sgst_rate=replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN IND.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
         sgst_val=CAST(SUM(IND.SGST_AMOUNT) AS NUMERIC(14,2)),
         igst_rate=replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN IND.gst_percentage ELSE 0 END as numeric(10,2)),'.00','')  ,
         igst_val=CAST(SUM(IND.IGST_AMOUNT) AS NUMERIC(14,2)),
         cess_rate=ISNULL(gd.CESS_PERCENTAGE,0),
		 cess_val=SUM(isnull(IND.gst_CESS_AMOUNT,0)),
         ITEM_total_val=CAST(SUM(ISNULL(XN_VALUE_WITHOUT_GST,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(IGST_AMOUNT,0)) aS nUMERIC(18,2)),
         tags='null',
         
		  DISTANCE=0,
          VEHICLE_NUMBER=CASE WHEN ISNULL(VEHICLE_NO,'')='' THEN '' ELSE VEHICLE_NO END,
          DOCUMENT_TYPE= CASE WHEN L.LOC_GST_NO<>LM.AC_GST_NO THEN 'INV' ELSE 'CHL' END,OVERRIDE_EWB_STATUS='false',ACTIVE='true'
  
   INTO #TMPINVOICE            
   FROM INM01106 A (NOLOCK)        
   JOIN IND01106 IND (NOLOCK) ON A.INV_ID =IND.INV_ID         
   JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =IND.PRODUCT_CODE         
   JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE         
   JOIN UOM (NOLOCK) ON UOM.UOM_CODE =ART.UOM_CODE         
   JOIN SKU_NAMES SN (NOLOCK) ON SN.PRODUCT_CODE =IND.PRODUCT_CODE         
   JOIN LOC_VIEW L (NOLOCK) ON L.DEPT_ID =A.location_Code        
   LEFT JOIN GST_STATE_DET GD (NOLOCK) ON GD.GST_STATE_CODE =L.GST_STATE_CODE AND A.INV_DT BETWEEN GD.FM_DT AND GD.TO_DT         
   JOIN COMPANY C (NOLOCK) ON C.COMPANY_CODE ='01'        
   JOIN LMV01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE         
   LEFT JOIN #TRANSPORTER TR ON 1=1          
   LEFT JOIN LM01106 SHLM (NOLOCK) ON SHLM.AC_CODE =A.SHIPPING_AC_CODE 
   LEFT JOIN LMP01106 SHLMP (NOLOCK) ON SHLMP.AC_CODE =SHLM.AC_CODE 
   LEFT JOIN AREA SHAR (NOLOCK) ON SHLMP.AREA_CODE=SHAR.AREA_CODE                        
   LEFT JOIN CITY SHCT (NOLOCK) ON SHAR.CITY_CODE=SHCT.CITY_CODE  
   LEFT JOIN GST_STATE_MST SHCS (NOLOCK) ON SHCS.GST_STATE_CODE=SHLMP.AC_GST_STATE_CODE      
   LEFT JOIN GST_STATE_MST SHP (NOLOCK) ON ISNULL(SHP.GST_STATE_NAME,'')=ISNULL(A.SHIPPING_STATE_NAME,'')   
   LEFT JOIN GST_STATE_MST LST (NOLOCK) ON LST.GST_STATE_CODE=L.GST_STATE_CODE   
   LEFT JOIN GST_STATE_MST LMST (NOLOCK) ON LMST.GST_STATE_CODE=A.PARTY_STATE_CODE   
   LEFT JOIN GST_STATE_MST LMSTATE (NOLOCK) ON LMSTATE.GST_STATE_CODE=LM.ac_gst_state_code    
      
   LEFT JOIN LM_BANK_DETAIL BD (NOLOCK) ON BD.AC_CODE =L.CONTROL_AC_CODE   
   WHERE A.INV_ID=@CXNID 
   GROUP BY  RTRIM(LTRIM(A.INV_NO)),CONVERT(VARCHAR,A.INV_DT,103),
   isnull(a.other_charges_taxable_value,0),isnull(a.freight_taxable_value,0),isnull(a.insurance_taxable_value,0),isnull(a.packing_taxable_value,0) ,
   isnull(a.other_charges_Igst_amount ,0),isnull(a.freight_igst_amount ,0),isnull(a.insurance_igst_amount ,0),isnull(a.packing_igst_amount ,0) ,
   isnull(a.other_charges_cgst_amount ,0),isnull(a.freight_cgst_amount ,0),isnull(a.insurance_cgst_amount ,0),isnull(a.packing_cgst_amount ,0) ,
   isnull(a.other_charges_sgst_amount ,0),isnull(a.freight_sgst_amount ,0),isnull(a.insurance_sgst_amount ,0),isnull(a.packing_sgst_amount ,0) ,

   A.NET_AMOUNT ,L.AREA_NAME,CASE WHEN CANCELLED=0 THEN 'false' ELSE 'true' END  ,L.BRANCH_ID ,
      --*******SELLER******
   L.LOC_GST_NO,l.dept_name,L.ADDRESS1,L.ADDRESS2,L.STATE,L.CITY,LST.GST_STATE_NAME,L.PINCODE,
   ISNULL(NULLIF(L.COUNTRY_NAME,''),'NULL') , ISNULL(NULLIF(L.PHONE ,''),'NULL'),
	   --*******RECEIVER******
   LM.AC_NAME,LM.AC_GST_NO,LM.ADDRESS1,CASE WHEN ISNULL(LM.ADDRESS2,'')='' THEN '...' ELSE LM.ADDRESS2 END ,
   LM.CITY ,LMST.GST_STATE_NAME,LM.PINCODE,
   ISNULL(NULLIF(CASE WHEN ISNULL( LM.MOBILE,'')='' THEN LM.PHONES_O ELSE LM.MOBILE END,''),'NULL') ,
	    --*******consignee******
     CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	                 WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		         ELSE LM.Ac_gst_no end,

     CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	                  WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		              ELSE LM.Ac_gst_no  END,

     CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS0 
	                      WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS 
		             ELSE LM.ADDRESS0 END,

      CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS1 
	                     WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS2 
		             ELSE LM.ADDRESS1 END,

      CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHCT.CITY  
	                     WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_city_NAME 
		             ELSE lm.city  END,

      CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHcs.GST_STATE_NAME   
	                    WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(shp.GST_STATE_NAME ,'') 
		           ELSE LMSTATE.GST_STATE_NAME     END,

      CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.pincode   
	                      WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(a.SHIPPING_PIN,'') 
		            ELSE lm.PINCODE    END,
	    --*******Transporter******

	  TR.MODE,CASE WHEN ISNULL(TR.TRANSPORTER_GST_NO,'')='' THEN '' ELSE TR.TRANSPORTER_GST_NO END,
      ISNULL(NULLIF(TR.AREA_NAME ,''),'NULL'),ISNULL(NULLIF(TR.  GST_STATE_NAME ,''),'NULL'),LST.GST_STATE_NAME,

     --*******line_items******
    
         SN.ARTICLE_NO,IND.HSN_CODE,SN.ARTICLE_NAME,
         CAST(XN_VALUE_WITHOUT_GST /INVOICE_QUANTITY  AS NUMERIC(14,2)),
         CAST(XN_VALUE_WITH_GST /INVOICE_QUANTITY  AS NUMERIC(14,2)),uom.uom_name ,
         replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN IND.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
         replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN IND.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
         replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN IND.gst_percentage ELSE 0 END as numeric(10,2)),'.00','')  ,
         ISNULL(gd.CESS_PERCENTAGE,0),ISNULL(A.EWAYDISTANCE,0),CASE WHEN ISNULL(VEHICLE_NO,'')='' THEN '' ELSE VEHICLE_NO END
     

   


   
   
  IF OBJECT_ID ('TEMPDB..#TMPOVERHEAD','U') IS NOT NULL
     drop table #TMPOVERHEAD

	 SELECT TOP 1 * INTO #TMPOVERHEAD FROM #TMPINVOICE



	  INSERT #TMPOVERHEAD	(   ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,item_code,gst_code,gst_type,descr,notes,unit_price,unit_price_including_tax,unit_of_measurement,item_id,serial_number,
	  quantity,discount_rate,discount,taxable_val,cgst_rate,cgst_val,sgst_rate,sgst_val,igst_rate,igst_val,cess_rate,cess_val,ITEM_total_val,tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE)  

	  SELECT 	  ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,
	  'Other Charges' item_code,other_charges_hsn_code  gst_code,gst_type,'Other Charges'  descr,notes,
	  ISNULL(OTHER_CHARGES_TAXABLE_VALUE ,0) as unit_price,
	   ISNULL(OTHER_CHARGES_TAXABLE_VALUE ,0)+ISNULL(other_charges_CGST_AMOUNT,0)+ISNULL(other_charges_SGST_AMOUNT,0)+ISNULL(other_charges_IGST_AMOUNT,0)  as unit_price_including_tax,
	  'null' unit_of_measurement,
	  item_id='Other Charges',
	  serial_number,1 quantity,discount_rate,discount,
	  taxable_val=OTHER_CHARGES_TAXABLE_VALUE,
	  cgst_rate=replace(cast(CASE WHEN ISNULL(OTHER_CHARGES_cgst_amount,0)>0 THEN b.OTHER_CHARGES_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      cgst_val=CAST((b.OTHER_CHARGES_CGST_AMOUNT) AS NUMERIC(14,2)),
      sgst_rate=replace(cast(CASE WHEN ISNULL(OTHER_CHARGES_sgst_amount,0)>0 THEN b.OTHER_CHARGES_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      sgst_val=CAST((b.OTHER_CHARGES_SGST_AMOUNT) AS NUMERIC(14,2)),
      igst_rate=replace(cast(CASE WHEN ISNULL(OTHER_CHARGES_igst_amount,0)>0 THEN b.OTHER_CHARGES_gst_percentage ELSE 0 END as numeric(10,2)),'.00','')  ,
      igst_val=CAST((b.OTHER_CHARGES_IGST_AMOUNT) AS NUMERIC(14,2)),
      cess_rate=0,
	  cess_val=0,
      ITEM_total_val=CAST((ISNULL(OTHER_CHARGES_TAXABLE_VALUE,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)) aS nUMERIC(18,2)),

	  tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE
	  FROM  #TMPOVERHEAD A
	  JOIN INM01106 B ON 1=1
	  WHERE B.INV_ID=@CXNID
	  AND B.OTHER_CHARGES <>0


	    INSERT #TMPOVERHEAD	(   ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,item_code,gst_code,gst_type,descr,notes,unit_price,unit_price_including_tax,unit_of_measurement,item_id,serial_number,
	  quantity,discount_rate,discount,taxable_val,cgst_rate,cgst_val,sgst_rate,sgst_val,igst_rate,igst_val,cess_rate,cess_val,ITEM_total_val,tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE)  

	  SELECT 	  ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,
	  'Freight' item_code,Freight_hsn_code  gst_code,gst_type,'Freight'  descr,notes,
	  ISNULL(Freight_TAXABLE_VALUE ,0) as unit_price,
	   ISNULL(Freight_TAXABLE_VALUE ,0)+ISNULL(Freight_CGST_AMOUNT,0)+ISNULL(Freight_SGST_AMOUNT,0)+ISNULL(Freight_IGST_AMOUNT,0)  as unit_price_including_tax,
	  'null' unit_of_measurement,
	  item_id='Freight',
	  serial_number,1 quantity,discount_rate,discount,
	  taxable_val=Freight_TAXABLE_VALUE,
	  cgst_rate=replace(cast(CASE WHEN ISNULL(Freight_cgst_amount,0)>0 THEN b.Freight_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      cgst_val=CAST((b.Freight_CGST_AMOUNT) AS NUMERIC(14,2)),
      sgst_rate=replace(cast(CASE WHEN ISNULL(Freight_sgst_amount,0)>0 THEN b.Freight_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      sgst_val=CAST((b.Freight_SGST_AMOUNT) AS NUMERIC(14,2)),
      igst_rate=replace(cast(CASE WHEN ISNULL(Freight_igst_amount,0)>0 THEN b.Freight_gst_percentage ELSE 0 END as numeric(10,2)),'.00','')  ,
      igst_val=CAST((b.Freight_IGST_AMOUNT) AS NUMERIC(14,2)),
      cess_rate=0,
	  cess_val=0,
      ITEM_total_val=CAST((ISNULL(Freight_TAXABLE_VALUE,0)+ISNULL(Freight_CGST_AMOUNT,0)+ISNULL(Freight_SGST_AMOUNT,0)+ISNULL(Freight_IGST_AMOUNT,0)) aS nUMERIC(18,2)),

	  tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE
	  FROM  #TMPOVERHEAD A
	  JOIN INM01106 B ON 1=1
	  WHERE B.INV_ID=@CXNID
	  AND B.freight <>0


	  
	   INSERT #TMPOVERHEAD	(   ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,item_code,gst_code,gst_type,descr,notes,unit_price,unit_price_including_tax,unit_of_measurement,item_id,serial_number,
	  quantity,discount_rate,discount,taxable_val,cgst_rate,cgst_val,sgst_rate,sgst_val,igst_rate,igst_val,cess_rate,cess_val,ITEM_total_val,tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE)  

	  SELECT 	  ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,
	  'Insurance' item_code,Insurance_hsn_code  gst_code,gst_type,'Insurance'  descr,notes,
	  ISNULL(Insurance_TAXABLE_VALUE ,0) as unit_price,
	   ISNULL(Insurance_TAXABLE_VALUE ,0)+ISNULL(Insurance_CGST_AMOUNT,0)+ISNULL(Insurance_SGST_AMOUNT,0)+ISNULL(Insurance_IGST_AMOUNT,0)  as unit_price_including_tax,
	  'null' unit_of_measurement,
	  item_id='Insurance',
	  serial_number,1 quantity,discount_rate,discount,
	  taxable_val=Insurance_TAXABLE_VALUE,
	  cgst_rate=replace(cast(CASE WHEN ISNULL(Insurance_cgst_amount,0)>0 THEN b.Insurance_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      cgst_val=CAST((b.Insurance_CGST_AMOUNT) AS NUMERIC(14,2)),
      sgst_rate=replace(cast(CASE WHEN ISNULL(Insurance_sgst_amount,0)>0 THEN b.Insurance_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      sgst_val=CAST((b.Insurance_SGST_AMOUNT) AS NUMERIC(14,2)),
      igst_rate=replace(cast(CASE WHEN ISNULL(Insurance_igst_amount,0)>0 THEN b.Insurance_gst_percentage ELSE 0 END as numeric(10,2)),'.00','')  ,
      igst_val=CAST((b.Insurance_IGST_AMOUNT) AS NUMERIC(14,2)),
      cess_rate=0,
	  cess_val=0,
      ITEM_total_val=CAST((ISNULL(Insurance_TAXABLE_VALUE,0)+ISNULL(Insurance_CGST_AMOUNT,0)+ISNULL(Insurance_SGST_AMOUNT,0)+ISNULL(Insurance_IGST_AMOUNT,0)) aS nUMERIC(18,2)),

	  tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE
	  FROM  #TMPOVERHEAD A
	  JOIN INM01106 B ON 1=1
	  WHERE B.INV_ID=@CXNID
	  AND B.Insurance <>0

	   INSERT #TMPOVERHEAD	(   ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,item_code,gst_code,gst_type,descr,notes,unit_price,unit_price_including_tax,unit_of_measurement,item_id,serial_number,
	  quantity,discount_rate,discount,taxable_val,cgst_rate,cgst_val,sgst_rate,sgst_val,igst_rate,igst_val,cess_rate,cess_val,ITEM_total_val,tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE)  

	  SELECT 	  ID,TRANSACTION_DATE,RETURN_PERIOD,SOURCE,TOTAL_TAXABLE_VAL,TOTAL_IGST_VAL,TOTAL_CGST_VAL,TOTAL_SGST_VAL,TOTAL_VAL,PLACE_OF_SUPPLY,IS_CANCELED,BRANCH_ID,DOCUMENT_NUMBER,TYP,GSTIN,ADDRESS1,ADDRESS2,CITY,L_STATE,ZIP_CODE,
	  COUNTRY,PHONE_NUMBER,RNAME,R_GSTIN,R_ADDRESS1,R_ADDRESS2,R_CITY,R_STATE,R_ZIP_CODE,R_COUNTRY,R_PHONE_NUMBER,SH_NAME,SH_GSTIN,sh_address1,sh_address2,sh_city,sh_state,sh_zip_code,SH_COUNTRY,SH_PHONE_NUMBER,TRANSPORT_MODE,
	  TRANSPORTER_GSTIN,TRANSPORTER_FROM_PLACE,TRANSPORTER_FROM_STATE,DISPATCH_FROM_STATE,SUB_SUPPLY,
	  'packing' item_code,packing_hsn_code  gst_code,gst_type,'packing'  descr,notes,
	  ISNULL(packing_TAXABLE_VALUE ,0) as unit_price,
	   ISNULL(packing_TAXABLE_VALUE ,0)+ISNULL(packing_CGST_AMOUNT,0)+ISNULL(packing_SGST_AMOUNT,0)+ISNULL(packing_IGST_AMOUNT,0)  as unit_price_including_tax,
	  'null' unit_of_measurement,
	  item_id='packing',
	  serial_number,1 quantity,discount_rate,discount,
	  taxable_val=packing_TAXABLE_VALUE,
	  cgst_rate=replace(cast(CASE WHEN ISNULL(packing_cgst_amount,0)>0 THEN b.packing_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      cgst_val=CAST((b.packing_CGST_AMOUNT) AS NUMERIC(14,2)),
      sgst_rate=replace(cast(CASE WHEN ISNULL(packing_sgst_amount,0)>0 THEN b.packing_gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00',''),
      sgst_val=CAST((b.packing_SGST_AMOUNT) AS NUMERIC(14,2)),
      igst_rate=replace(cast(CASE WHEN ISNULL(packing_igst_amount,0)>0 THEN b.packing_gst_percentage ELSE 0 END as numeric(10,2)),'.00','')  ,
      igst_val=CAST((b.packing_IGST_AMOUNT) AS NUMERIC(14,2)),
      cess_rate=0,
	  cess_val=0,
      ITEM_total_val=CAST((ISNULL(packing_TAXABLE_VALUE,0)+ISNULL(packing_CGST_AMOUNT,0)+ISNULL(packing_SGST_AMOUNT,0)+ISNULL(packing_IGST_AMOUNT,0)) aS nUMERIC(18,2)),

	  tags,DISTANCE,VEHICLE_NUMBER,DOCUMENT_TYPE,OVERRIDE_EWB_STATUS,ACTIVE
	  FROM  #TMPOVERHEAD A
	  JOIN INM01106 B ON 1=1
	  WHERE B.INV_ID=@CXNID
	  AND B.packing <>0


	 ;with CTE as 
	 (
			select NEWSRNO =ROW_NUMBER () OVER (ORDER BY CASE WHEN item_code IN('OTHER CHARGES','FREIGHT','INSURANCE','PACKING') THEN 1 ELSE 0 END ,serial_number ),* from  #TMPINVOICE a
	 )

	UPDATE CTE SET serial_number  =NEWSRNO

  select *   
  from #TMPINVOICE  
   ORDER BY serial_number  
  
  DECLARE @CLOCID VARCHAR(4),@CERRORMSG VARCHAR(1000)
  SElecT top 1 @CLOCID=location_code from inm01106 (nolock) where inv_id=@CXNID
    
 -- EXEC VALIDATEXN_EINVOICE @CXNID=@CXNID,@CDEPT_ID=@CLOCID,@CXN_TYPE='wsl',@CERRMSG= @CERRORMSG OUTPUT
   
   
   SELECT '' AS ERRMSG WHERE 1=2
		
  --select shipping_state_name, * from INM01106  where FIN_YEAR ='01121'   
  
 return  
  
        
END  
  

  --new



