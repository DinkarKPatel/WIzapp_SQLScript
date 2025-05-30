create PROCEDURE SP3S_UPLOAD_SLSEINVOICE    
(        
@CXNID VARCHAR(50)=''        
)        
AS        
BEGIN        


        
     DECLARE @CEINVOICE_PREFIX VARCHAR(10)
     select @CEINVOICE_PREFIX=value  from CONFIG where config_option ='EINVOICE_PREFIX'
    set @CEINVOICE_PREFIX=ISNULL(@CEINVOICE_PREFIX,'')

	DECLARE @Auto_Einvoice_Api VARCHAR(5) --1 FOR tAXPRO,2.CLEARTAX
	SELECT @Auto_Einvoice_Api=value  FROM CONFIG WHERE config_option ='Auto_Einvoice_Api_Configuration'
     
	IF ISNULL(@Auto_Einvoice_Api,'')in('','0')
	   SET @Auto_Einvoice_Api='1'

	 DECLARE @CERRMSG VARCHAR(100)
	 SET @CERRMSG=''



   DECLARE @NPAYMENTMODE VARCHAR(50),@CNT INT
   SET @NPAYMENTMODE='CREDIT'
    
    DECLARE @NIGSTVAL NUMERIC(10,2),@NCGSTVAL NUMERIC(10,2),@NSGSTVAL NUMERIC(10,2),@NCESSaMOUNT  NUMERIC(10,2)  ,@NTABLABLEVALUE NUMERIC(18,2)  ,  
             @NDISCOUNT_AMOUNT NUMERIC(10,2)  
        
  SELECT @NIGSTVAL=SUM(IGST_AMOUNT),@NCGSTVAL=SUM(CGST_AMOUNT),@NSGSTVAL=SUM(CGST_AMOUNT),@NCESSaMOUNT=SUM(CESS_AMOUNT),  
  @NTABLABLEVALUE= SUM(XN_VALUE_WITHOUT_GST ),-- SUM(XN_VALUE_WITHOUT_GST),
  @NDISCOUNT_AMOUNT =SUM(DISCOUNT_AMOUNT)  
  FROM cmd01106         
  WHERE cm_id  =@CXNID      
  

    
 IF OBJECT_ID('TEMPDB..#TMPINVOICE','U') IS NOT NULL  
    DROP TABLE #TMPINVOICE  
           
   SELECT 'GST' AS TAXSCH,SUPPLY_TYPE_CODE AS SUPTYP,'N' AS REGREV,UPPER(L.LOC_GST_NO) AS ECMGSTIN,'N' AS IGSTONINTRA,        
   CASE WHEN A.NET_AMOUNT >=0 THEN   'INV' ELSE 'CRN' END AS TYP,  
   --******SellerDtls******  
   NO=CASE WHEN (@CEINVOICE_PREFIX<>'' AND LEFT(RTRIM(LTRIM(A.CM_NO)),1)='0') THEN @CEINVOICE_PREFIX ELSE '' END+RTRIM(LTRIM(A.CM_NO)),   
   
   --cast(RIGHT(A.FIN_YEAR,2) as varchar(2))+RTRIM(LTRIM(A.CM_NO)) ,--A.INV_NO ,
   -- a.INV_NO  AS NO,---- EVERY  NO CAHNE NOT MATCH INV_NO BOTH ARE DIFFERENT      
   convert(varchar,A.CM_DT,103) AS INV_DT,  -- CONVERT INVDT NOT TIME      
   UPPER(L.LOC_GST_NO) AS GSTIN,L.DEPT_NAME AS LGLNM,L.DEPT_NAME AS TRDNM,-- L.DEPT_ALIAS TRADE NAME SHOULD BE MIN 3 CHARCATER   
   
   LEFT( ISNULL(L.ADDRESS1,'')+' '+ISNULL(L.ADDRESS2,''),100) as ADDRESS1 ,
   SUBSTRING( ISNULL(L.ADDRESS1,'')+' '+ISNULL(L.ADDRESS2,''),101,100) as  ADDRESS2,   
   
   isnull(NULLIF(L.AREA_NAME,''),'null') LOC ,isnull(NULLIF(l.PINCODE,''),'null')  PIN,-- PIN NO SHOULD NOT BE BLANK MOUST BE 6 CHARACTER      
   isnull(NULLIF(l.gst_state_code,''),'null')  STCD,---L.gst_state_code      
   isnull(NULLIF(l.phone,''),'null')  PH,--L.PHONE MUST BE NOT BLANK SHOULD BE MIN 6 CHARCTAER      
   isnull(NULLIF(C.EMAIL_ID,''),'null')  AS EM ,     
  
   --******BuyerDtls******  
    CASE WHEN A.party_state_code IN('96') THEN 'URP' ELSE   UPPER(isnull(a .Party_gst_no,''))  END   AS B_GSTIN,--LM.AC_GST_NO  
	
   isnull(NULLIF(SHLM.CUSTOMER_FNAME +' '+SHLM.CUSTOMER_LNAME,''),'null') AS B_LGLNM ,      
   CASE WHEN ISNULL(SHLM.COMPANY_NAME,'')<>'' THEN ISNULL(SHLM.COMPANY_NAME,'') ELSE  ISNULL(NULLIF(SHLM.CUSTOMER_FNAME +' '+SHLM.CUSTOMER_LNAME,''),'NULL') END AS B_TRDNM  ,--LM.ALIAS NOT SHOULD BE BLANK  
   a.party_state_code AS POS,
   

   LEFT( ISNULL(SHLM.ADDRESS0,'') +' '+ISNULL(SHLM.ADDRESS1,'')+' '+ISNULL(SHLM.ADDRESS2,'')+' '+ISNULL(SHLM.ADDRESS9,''),100)  AS ADDR1 ,-- LM.ADDRESS1 SHOULD NOT BE BLANK   
   substring( ISNULL(SHLM.ADDRESS0,'') +' '+ISNULL(SHLM.ADDRESS1,'')+' '+ISNULL(SHLM.ADDRESS2,'')+' '+ISNULL(SHLM.ADDRESS9,''),101,100) AS ADDR2,  --LM.ADDRESS2 SHOULD NOT BE BLANK   

   isnull(NULLIF(shar.AREA_NAME +' '+shct.CITY,''),'null')  B_LOC ,
   case when LEN(RTRIM(LTRIM(isnull(shlm.pin,''))))<6 then shar.pincode else shlm.pin end AS B_PIN,-- LM.PINCODE PIN CODE MATCH ADDRESS        
   a.party_state_code AS B_STCD--LM.AC_GST_STATE_CODE  STCD IS NOT SAME STATECODE FOR b_STCd      
   ,isnull(NULLIF(case when isnull( SHLM.MOBILE,'')='' then SHLM.PHONE1 else SHLM.mobile end,''),'null') AS B_PH,isnull(NULLIF(SHLM.email,''),'null')  AS B_EM ,  
  
 --******DispDtls******   
  
   L.DEPT_NAME AS DIS_NM,

   LEFT( ISNULL(L.ADDRESS1,'')+' '+ISNULL(L.ADDRESS2,''),100) AS DIS_ADDR1,  
   SUBSTRING( ISNULL(L.ADDRESS1,'')+' '+ISNULL(L.ADDRESS2,''),101,100) AS DIS_ADDR2,      
   
   isnull(NULLIF(L.AREA_NAME,''),'null') AS DIS_LOC ,--mANADATORY disc loc TR.AREA_NAME    
   l.PINCODE  AS DIS_PIN,--mANADATORY PINCODE TR.PINCODE      
    isnull(NULLIF(l.gst_state_code,''),'null')  AS DIS_STCD,  --mANADATORY STCD SENDER GSTNO     
  
  
    --******ShipDtls******   

     UPPER(isnull(NULLIF(a .Party_gst_no,''),'null'))  SHIP_GSTIN,
     isnull(NULLIF(SHLM.CUSTOMER_FNAME +' '+SHLM.CUSTOMER_LNAME,''),'null')  SHIP_LGLNM,
     isnull(NULLIF(SHLM.CUSTOMER_FNAME +' '+SHLM.CUSTOMER_LNAME,''),'null')  SHIP_TRDNM,

     LEFT( ISNULL(SHLM.ADDRESS0,'') +' '+ISNULL(SHLM.ADDRESS1,'')+' '+ISNULL(SHLM.ADDRESS2,'')+' '+ISNULL(SHLM.ADDRESS9,''),100)  SHIP_ADDR1,
	 substring( ISNULL(SHLM.ADDRESS0,'') +' '+ISNULL(SHLM.ADDRESS1,'')+' '+ISNULL(SHLM.ADDRESS2,'')+' '+ISNULL(SHLM.ADDRESS9,''),101,100) SHIP_ADDR2,

     isnull(NULLIF(SHAR.AREA_NAME,''),'null')  SHIP_LOC,
	isnull(NULLIF(SHAR.pincode,''),shlm.pin )  SHIP_PIN,
	 isnull(NULLIF(SHcs.gst_state_code ,''),'null')   SHIP_STCD,

    ROW_NUMBER () OVER (ORDER BY (CASE WHEN  @Auto_Einvoice_Api=1 THEN   RTRIM(LTRIM(cmd.HSN_CODE)) ELSE left(RTRIM(LTRIM(SN.section_name))+'-'+RTRIM(LTRIM(SN.SUB_section_name)),10) END) )  AS SLNO,
	(CASE WHEN  @Auto_Einvoice_Api=1 THEN   RTRIM(LTRIM(cmd.HSN_CODE)) ELSE left( RTRIM(LTRIM(SN.section_name))+'-'+RTRIM(LTRIM(SN.SUB_section_name)),10) END) AS PRDDESC,     
	
   CASE WHEN XN_ITEM_TYPE=4 THEN   'Y' ELSE 'N' END AS ISSERVC,
   CMD.HSN_CODE AS HSNCD,
   (CASE WHEN  @Auto_Einvoice_Api=1 THEN   RTRIM(LTRIM(cmd.HSN_CODE)) ELSE left(RTRIM(LTRIM(SN.section_name))+'-'+RTRIM(LTRIM(SN.SUB_section_name)),10) END) AS BARCDE,        
   abs(CMD.QUANTITY)  AS QTY,isnull(abs(CMD.FOC_QUANTITY),0)  AS FREEQTY,
    CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END AS UNIT,        
   ABS( CAST(CMD.MRP  
   -(CASE WHEN tax_method =1 THEN ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(IGST_AMOUNT,0) ELSE 0 END)/QUANTITY  
   AS NUMERIC(18,2))) AS UNITPRICE,
   
  ABS( CAST(ISNULL(CMD.MRP ,0)*ISNULL(QUANTITY   ,0) 
   -CASE WHEN tax_method =1 THEN ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(IGST_AMOUNT,0) ELSE 0 END
   AS NUMERIC(10,2))) AS TOTAMT, --SUBT
    
   cast(ABS(CMD.DISCOUNT_AMOUNT+CMD.cmm_discount_amount ) as numeric(10,2)) AS DISCOUNT,
   ABS(XN_VALUE_WITHOUT_GST) AS PRETAXVAL, 
   ABS(XN_VALUE_WITHOUT_GST)  AS ASSAMT,-- ASSAMT IS SAME TOTAMT  -SUBT  

   CMD.GST_PERCENTAGE AS GSTRT,ABS(CMD.IGST_AMOUNT) AS IGSTAMT,abs(CMD.CGST_AMOUNT) AS CGSTAMT,        
   ABS(CMD.CGST_AMOUNT) AS SGSTAMT,ABS(ISNULL(CMD.GST_CESS_PERCENTAGE,0)) AS CESRT,ABS(isnull(CMD.gst_CESS_AMOUNT,0)) AS  CESAMT,        
   0 AS CESNONADVLAMT,0 AS STATECESRT,0 AS STATECESAMT,0 AS STATECESNONADVLAMT,0  AS OTHCHRG,   
  
   ABS(ISNULL(XN_VALUE_WITHOUT_GST,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(IGST_AMOUNT,0)) AS TOTITEMVAL,

   0 AS ORDLINEREF,'IN' AS ORGCNTRY,CMD.SR_NO  AS PRDSLNO,        
   'null' AS  NM,'null' AS EXPDT,'null' AS WRDT,'null' AS ATTR_NM,0 AS ATTR_VAL ,     
    
  --*******ValDtls***********  
       
   ASSVAL= ABS(cast(@NTABLABLEVALUE+isnull(a.other_charges_taxable_value,0) as numeric(18,2))),--+ISNULL(@NDISCOUNT_AMOUNT,0)+A.DISCOUNT_AMOUNT ,--net_rate,---ASSVAL WITHOUT TAX VALE  --SUBT
   CGSTVAL=ABS(cast(@NCGSTVAL+isnull(a.other_charges_cgst_amount ,0) as numeric(12,2))),-- cgst_amount, ----@NCGSTVAL,    
   SGSTVAL=ABS(cast(@NSGSTVAL+isnull(a.other_charges_sgst_amount ,0) as numeric(12,2))),--sgst_amount,-- , 
   IGSTVAL=ABS(cast(@NIGSTVAL+isnull(a.other_charges_igst_amount ,0) as numeric(12,2))),--IND.IGST_AMOUNT , --- ,   
   CESVAL=isnull(@NCESSaMOUNT,0),---IND.CESS_AMOUNT ,         
   STCESVAL=0,    
   DISCOUNTVAL=0,  ---IND.DISCOUNT_AMOUNT TWO DISCOUNT COLUMN THEN THIS COLMN NAME CHANGE,        
   OTHCHRGVAL=0,
   RNDOFFAMT=(CASE WHEN A.NET_AMOUNT >0 THEN  A.ROUND_OFF ELSE  -1*A.ROUND_OFF END)+A.GST_ROUND_OFF   ,  --A.ROUND_OFF,        
   TOTINVVAL=ABS(A.NET_AMOUNT),   --A.NET_AMOUNT,    ---TOTINVVALUE  ASSVALUE+TAX VALE    
   TOTINVVALFC=isnull(ABS(CAST((@NTABLABLEVALUE+@NCGSTVAL+@NSGSTVAL+@NIGSTVAL+@NCESSaMOUNT+a.atd_charges +
      CASE WHEN A.OH_TAX_METHOD =1 THEN ISNULL(A.OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(A.OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(A.OTHER_CHARGES_CGST_AMOUNT,0) ELSE 0 END
   ) AS NUMERIC(18,2))),0), --A.NET_AMOUNT+ROUND_OFF ,    --A.NET_AMOUNT+ROUND_OFF,    ---TOTINVVALFC  ASSVALUE+TAX VALE    
  
      
   PAY_NM=isnull(NULLIF(bd.BF_AC_NAME ,''),'null'),--MANADTORT MUST BE 11 CHARACTER    
   -- dm ACCDET='000705019105', ---bank ac number of payee      (mandetory) 
   ACCDET=isnull(bd.ACCOUNT_NO,'-')  , ---bank ac number of payee      (mandetory) 
    MODE='CREDIT'  ,        
   -- dm FININSBR='ICIC0000007',--bd.IFSC_CODE,---IFSC code      (mandetory) 
   FININSBR=isnull(bd.IFSC_CODE,'-') ,--bd.IFSC_CODE,---IFSC code      (mandetory) 
   PAYTERM=0,    
   PAYINSTR='PI',--payment instruction mandatory should be 1 character    
   CRTRN='CT',--CREDIT TRANSFER MANADATORY MIN 1CHARCTER    
   DIRDR='RR',----direct debit  MANADATORY MIN 1CHARCTER   
   CRDAY=0 ,        
   PAIDAMT=ABS(A.NET_AMOUNT),
   PAYMTDUE=0,
   INVRM='invrm',-- MANADATORY,    
   INVSTDT=convert(varchar(10),GETDATE(),103), -- MANADATORY,    
   INVENDDT= convert(varchar(10),GETDATE()+1,103), -- MANADATORY,      
     
    --*******RefDtls***********  
  
   -- INVNO= 'IN-'+LEFT(A.INV_ID,2)+RIGHT(FIN_YEAR,2)+RIGHT(A.INV_NO,6),--A.INV_NO ,    
   INVNO=CASE WHEN (@CEINVOICE_PREFIX<>'' AND  LEFT(RTRIM(LTRIM(A.CM_NO)),1)='0') THEN @CEINVOICE_PREFIX ELSE '' END+ rtrim(ltrim(CM_NO)),  
   INVDT= convert(varchar(10),A.CM_dt ,103),  --A.INV_DT ,        
   OTHREFNO=CASE WHEN isnull(CMD.REF_SLS_MEMO_NO,'') <>'' THEN CMD.REF_SLS_MEMO_NO ELSE 'OTH-'+CM_NO END ,
   RECADVREFR='null',--MANADTORY    
   RECADVDT=convert(varchar(10),GETDATE(),103),--MANADTORY    
   TENDREFR='null',--MANADTORY    
   CONTRREFR='null',--MANADTORY    
   EXTREFR='null',--MANADTORY    
   PROJREFR='null',--MANADTORY    
   POREFR='null',--MANADTORY    
   POREFDT=convert(varchar(10),A.CM_dt ,103),  --MANADTORY      
  
   --ExpDtls--  
   SHIPBNO='null',--MANADTORY    5 CHARCETER  ---NOT STORE
   SHIPBDT=convert(varchar(10),GETDATE(),103),--MANADTORY      
   PORT='null',--MANADTORY   FIX  
   REFCLM='null',--MANADTORY  only one charcter FIX  
   FORCUR='null',--MANADTORY  THIS VALUE IS FIX 3 CHARCTER   
   CNTCODE='null',--MANADTORY   THIS VALUE IS FIX 2 CHARACTER  
  
   --EwbDtls--  
   TRANSID=case when ISNULL('','')='' then '' else '' end ,
   TRANSNAME=case when ISNULL('','')='' then '' else '' end ,
   DISTANCE=0,
   TRANSDOCNO=case when ISNULL('','')='' then '' else '' end ,       
   TRANSDOCDT=convert(varchar(10),GETDATE(),103),  
   VEHNO=case when ISNULL('','')='' then '' else '' end ,  --case when ISNULL(vehicle_no,'')='' then null else vehicle_no end ,--vehicle_no ,--MANADTORY   
   VEHTYPE='R',--MANADTORY   
   TRANSMODE=1  --MANADTORY  nUMERIC VALUE,  
   into #TMPINVOICE            
   FROM cmm01106  A (NOLOCK)        
   JOIN cmd01106  CMD (NOLOCK) ON A.CM_ID =CMD.CM_ID         
   JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =CMD.PRODUCT_CODE         
   JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE         
   JOIN UOM (NOLOCK) ON UOM.UOM_CODE =ART.UOM_CODE         
   JOIN SKU_NAMES SN (NOLOCK) ON SN.PRODUCT_CODE =CMD.PRODUCT_CODE         
   JOIN LOC_VIEW L (NOLOCK) ON L.DEPT_ID =LEFT(A.CM_ID,2)        
   LEFT JOIN GST_STATE_DET GD (NOLOCK) ON GD.GST_STATE_CODE =L.GST_STATE_CODE AND A.CM_DT BETWEEN GD.FM_DT AND GD.TO_DT         
   JOIN COMPANY C (NOLOCK) ON C.COMPANY_CODE ='01'               
  --LEFT JOIN #TRANSPORTER TR ON 1=1          
  left join CUSTDYM shlm (nolock) on shlm.customer_code  =a.CUSTOMER_CODE  
  LEFT JOIN AREA shAR (NOLOCK) ON shlm.AREA_CODE=shAR.AREA_CODE                        
  LEFT JOIN CITY shCT (NOLOCK) ON shAR.CITY_CODE=shCT.CITY_CODE  
  LEFT JOIN GST_STATE_MST shCS (NOLOCK) ON shCS.GST_STATE_CODE=shLM.cus_gst_state_code          
  left join LM_BANK_DETAIL bd (nolock) on bd.AC_CODE =L.control_ac_code   
  WHERE A.cm_id =@CXNID   and ISNULL(a.IRN_QR_CODE,'')='' AND A.CANCELLED=0
    
 Update #TMPINVOICE set SUPTYP='B2B' where isnull(SUPTYP,'')=''

 UPDATE A SET ADDR1 =(CASE WHEN  ADDR1='' THEN 'null' ELSE ADDR1 END) ,
              ADDR2 =(CASE WHEN  ADDR2='' THEN 'null' ELSE ADDR2 END) ,
			  ADDRESS1 =(CASE WHEN  ADDRESS1='' THEN 'null' ELSE ADDRESS1 END) ,
			  ADDRESS2 =(CASE WHEN  ADDRESS2='' THEN 'null' ELSE ADDRESS2 END) ,
			  DIS_ADDR1=(CASE WHEN  DIS_ADDR1='' THEN 'null' ELSE DIS_ADDR1 END),
			  DIS_ADDR2=(CASE WHEN  DIS_ADDR2='' THEN 'null' ELSE DIS_ADDR2 END),
			  SHIP_ADDR1=(CASE WHEN  SHIP_ADDR1='' THEN 'null' ELSE SHIP_ADDR1 END),
			  SHIP_ADDR2=(CASE WHEN  SHIP_ADDR2='' THEN 'null' ELSE SHIP_ADDR2 END)
 FROM #TMPINVOICE A




  IF OBJECT_ID ('TEMPDB..#TMPOVERHEAD','U') IS NOT NULL
     drop table #TMPOVERHEAD

	 SELECT TOP 1 * INTO #TMPOVERHEAD FROM #TMPINVOICE

	 
		 INSERT #TMPINVOICE	( TAXSCH, SUPTYP, REGREV, ECMGSTIN, IGSTONINTRA, TYP, NO, INV_DT, GSTIN, LGLNM, TRDNM, ADDRESS1, ADDRESS2, LOC, PIN, STCD, PH, EM, B_GSTIN, B_LGLNM, B_TRDNM,
		  POS, ADDR1, ADDR2, B_LOC, B_PIN, B_STCD, B_PH, B_EM, DIS_NM, DIS_ADDR1, DIS_ADDR2, DIS_LOC, DIS_PIN, DIS_STCD, SHIP_GSTIN, SHIP_LGLNM, SHIP_TRDNM, SHIP_ADDR1, SHIP_ADDR2, SHIP_LOC, 
		  SHIP_PIN, SHIP_STCD, SLNO, PRDDESC, ISSERVC, HSNCD, BARCDE, QTY, FREEQTY, UNIT, UNITPRICE, TOTAMT, DISCOUNT, PRETAXVAL, ASSAMT, GSTRT, IGSTAMT, CGSTAMT, SGSTAMT, CESRT, CESAMT, 
		  CESNONADVLAMT, STATECESRT, STATECESAMT, STATECESNONADVLAMT, OTHCHRG, TOTITEMVAL, ORDLINEREF, ORGCNTRY, PRDSLNO, NM, EXPDT, WRDT, ATTR_NM, ATTR_VAL, ASSVAL, CGSTVAL, SGSTVAL, 
		  IGSTVAL, CESVAL, STCESVAL, DISCOUNTVAL, OTHCHRGVAL, RNDOFFAMT, TOTINVVAL, TOTINVVALFC, PAY_NM, ACCDET, MODE, FININSBR, PAYTERM, PAYINSTR, CRTRN, DIRDR, CRDAY, PAIDAMT, PAYMTDUE, 
		  INVRM, INVSTDT, INVENDDT, INVNO, INVDT, OTHREFNO, RECADVREFR, RECADVDT, TENDREFR, CONTRREFR, EXTREFR, PROJREFR, POREFR, POREFDT, SHIPBNO, SHIPBDT, PORT, REFCLM, FORCUR, CNTCODE, 
		  TRANSID, TRANSNAME, DISTANCE, TRANSDOCNO, TRANSDOCDT, VEHNO, VEHTYPE, TRANSMODE )  

		 SELECT 	TOP 1  TAXSCH, SUPTYP, REGREV, ECMGSTIN, IGSTONINTRA, TYP, NO, A.INV_DT, GSTIN, LGLNM, TRDNM, ADDRESS1, ADDRESS2, LOC, PIN, STCD, PH, EM, B_GSTIN, B_LGLNM, B_TRDNM, 
		 POS, ADDR1, ADDR2, B_LOC, B_PIN, B_STCD, B_PH, B_EM, DIS_NM, DIS_ADDR1, DIS_ADDR2, DIS_LOC, DIS_PIN, DIS_STCD, SHIP_GSTIN, SHIP_LGLNM, SHIP_TRDNM, SHIP_ADDR1, SHIP_ADDR2, SHIP_LOC, 
		 SHIP_PIN, SHIP_STCD, SLNO,'Other Charges' PRDDESC, 'Y', other_charges_hsn_code  HSNCD,'Other Charges' BARCDE,1 QTY,0 FREEQTY, UNIT, 
		 UNITPRICE= abs(CAST(b.atd_charges   
		   -(CASE WHEN B.OH_TAX_METHOD =2 THEN ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_IGST_AMOUNT,0) ELSE 0 END)
		   AS NUMERIC(18,2))), 
		 TOTAMT=abs(CAST(b.atd_charges   
		   -(CASE WHEN B.OH_TAX_METHOD =2 THEN ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_IGST_AMOUNT,0) ELSE 0 END)
		   AS NUMERIC(18,2))), 
		 DISCOUNT=0, 
		 PRETAXVAL=abs(OTHER_CHARGES_TAXABLE_VALUE) , 
		 ASSAMT=abs(OTHER_CHARGES_TAXABLE_VALUE), 
		 GSTRT=other_charges_gst_percentage , 
		 IGSTAMT=abs(isnull(other_charges_igst_amount,0)) , 
		 CGSTAMT=abs(isnull(other_charges_cgst_amount,0)) , 
		 SGSTAMT=abs(isnull(other_charges_sgst_amount,0)) , 
		 0 CESRT,0 CESAMT, 
		 0 CESNONADVLAMT,0  STATECESRT,0 STATECESAMT,0 STATECESNONADVLAMT, OTHCHRG, 
		 TOTITEMVAL=   abs(ISNULL(OTHER_CHARGES_TAXABLE_VALUE ,0)+ISNULL(other_charges_CGST_AMOUNT,0)+ISNULL(other_charges_SGST_AMOUNT,0)+ISNULL(other_charges_IGST_AMOUNT,0)) ,
		  ORDLINEREF, ORGCNTRY, PRDSLNO, NM, EXPDT, WRDT, ATTR_NM, ATTR_VAL, 
		  ASSVAL, CGSTVAL, SGSTVAL,  IGSTVAL,0 CESVAL,0 STCESVAL,0 DISCOUNTVAL,0 OTHCHRGVAL, RNDOFFAMT, TOTINVVAL, TOTINVVALFC, PAY_NM, ACCDET, MODE, FININSBR, PAYTERM, PAYINSTR, CRTRN, DIRDR, CRDAY, PAIDAMT, PAYMTDUE, 
		 INVRM, INVSTDT, INVENDDT, INVNO, INVDT, OTHREFNO, RECADVREFR, RECADVDT, TENDREFR, CONTRREFR, EXTREFR, PROJREFR, POREFR, POREFDT, SHIPBNO, SHIPBDT, PORT, REFCLM, FORCUR, CNTCODE, 
		 TRANSID, TRANSNAME, DISTANCE, TRANSDOCNO, TRANSDOCDT, VEHNO, VEHTYPE, TRANSMODE 
		 FROM #TMPOVERHEAD A
		 JOIN cmm01106  B ON 1=1
		 WHERE B.cm_id =@CXNID
		 AND B.atd_charges  <>0


		 ;with CTE as 
		 (
			select NEWSRNO =ROW_NUMBER () OVER (ORDER BY CASE WHEN BARCDE IN('OTHER CHARGES') THEN 1 ELSE 0 END ,SLNO ),* from  #TMPINVOICE a
		 )

		 UPDATE CTE SET SLNO  =NEWSRNO

  
  SELECT *   
  FROM #TMPINVOICE    
  
  DECLARE @CLOCID VARCHAR(2),@CERRORMSG VARCHAR(1000)
  SET  @CLOCID=LEFT(@CXNID,2)
    
  	--EXEC VALIDATEXN_EINVOICE @CXNID=@CXNID,@CDEPT_ID=@CLOCID,@CXN_TYPE='wsl',@CERRMSG= @CERRORMSG OUTPUT
	DECLARE @CDONOT_GENERATE_RETAIL_EINVOICE_AFTER_24_HOURS VARCHAR(10)

	SELECT @CDONOT_GENERATE_RETAIL_EINVOICE_AFTER_24_HOURS=VALUE  FROM CONFIG WHERE CONFIG_OPTION='DONOT_GENERATE_RETAIL_EINVOICE_AFTER_24_HOURS'
   
   
	IF EXISTS (SELECT TOP 1 'U'  FROM CMM01106 A (NOLOCK) WHERE CM_ID =@CXNID AND  DATEDIFF(hour, cm_time, getdate()) >24) AND ISNULL(@CDONOT_GENERATE_RETAIL_EINVOICE_AFTER_24_HOURS,'')='1'
	BEGIN
	     SET  @CERRMSG='Einvoice Generation Time Only  24 hours : Your EInvoice Time Is over of this Invoice '
		 GOTO END_PROC
   	END
	IF EXISTS (SELECT TOP 1'U' FROM #TMPINVOICE where isnull(B_GSTIN,'')='' )
	BEGIN
	   SET  @CERRMSG='Customer GstNo can not be Blank '
	   GOTO END_PROC

	END


	IF EXISTS (SELECT TOP 1'U' FROM #TMPINVOICE where isnull(PIN,'')='' )
	BEGIN
	   SET  @CERRMSG='Location Pin can not be blank Please check '
	   GOTO END_PROC

	END
	IF EXISTS (SELECT TOP 1'U' FROM #TMPINVOICE where isnull(B_PIN,'')='' )
	BEGIN
	   SET  @CERRMSG='Customer Pin can not be blank Please check '
	   GOTO END_PROC

	END
	IF EXISTS (SELECT TOP 1'U' FROM #TMPINVOICE where isnull(DIS_PIN,'')='' )
	BEGIN
	   SET  @CERRMSG='Dispatch Pin can not be blank Please check '
	   GOTO END_PROC

	END
	IF EXISTS (SELECT TOP 1'U' FROM #TMPINVOICE where isnull(SHIP_PIN,'')='' )
	BEGIN
	   SET  @CERRMSG='Shipping Pin can not be blank Please check '
	   GOTO END_PROC

	END



	IF EXISTS (SELECT TOP 1 'U'  FROM CMM01106 A (NOLOCK) WHERE CM_ID =@CXNID AND isnull(EINV_IRN_NO,'')<>'' )
	BEGIN
	     SET  @CERRMSG='Irn No Already Generated of  this memo Please Check '
		 GOTO END_PROC
   	END



   END_PROC:
   SELECT @CERRMSG AS ERRMSG 
		
   
  
 
END  

--new