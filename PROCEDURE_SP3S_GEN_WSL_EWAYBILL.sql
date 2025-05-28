create PROCEDURE SP3S_GEN_WSL_EWAYBILL(@INV_ID VARCHAR(50),@XnType varchar(10)='')--(LocId 3 digit change by Sanjay:06-11-2024)  
AS  
BEGIN  
  
     DECLARE @NPICKINGSHIPPINGADDRESS INT,@ntotalvalue numeric(18,2),
             @Ncgst_amount NUMERIC(14,2),@Nsgst_amount NUMERIC(14,2),@Nigst_amount NUMERIC(14,2)
	 DECLARE @NTABLABLEVALUE NUMERIC(14,2)
     DECLARE @CEINVOICE_EXPORT_BUYER_STATE_CODE VARCHAR(10),@EINVOICE_START_DATE varchar(10),@einvoicestdate datetime
	 SELECT @CEINVOICE_EXPORT_BUYER_STATE_CODE=value FROM CONFIG WHERE CONFIG_OPTION ='EINVOICE_EXPORT_BUYER_STATE_CODE'
	 
	 select @EINVOICE_START_DATE=value from config where config_option='EINVOICE_START_DATE'

	 
   DECLARE @CEINVOICE_PREFIX VARCHAR(10)
   select @CEINVOICE_PREFIX=value  from CONFIG where config_option ='EINVOICE_PREFIX'
   set @CEINVOICE_PREFIX=ISNULL(@CEINVOICE_PREFIX,'')

   set @einvoicestdate=''
   IF ISNULL(@EINVOICE_START_DATE,'')<>''
      SET @EINVOICESTDATE=@EINVOICE_START_DATE


	  IF OBJECT_ID ('TEMPDB..#TMPPARCEL','U') IS NOT NULL
	     DROP TABLE #TMPPARCEL
 

	  SELECT A.PARCEL_MEMO_NO ,B.REF_MEMO_ID ,A.vehicle_no ,LMVT.Ac_gst_no ,ANGM.Angadia_name,parcel_memo_dt,a.bilty_no
	  INTO #TMPPARCEL
	  FROM PARCEL_MST A (NOLOCK) 
	  JOIN PARCEL_DET B (NOLOCK) ON B.parcel_memo_id=A.parcel_memo_id   
	  JOIN ANGM (NOLOCK) ON A.angadia_code=ANGM.angadia_code  
	  LEFT JOIN LMV01106 LMVT (NOLOCK) ON LMVT.AC_CODE=ANGM.AC_CODE 
	  WHERE B.REF_MEMO_ID =@INV_ID AND A.xn_type =@XnType AND A.CANCELLED=0
	  GROUP BY A.PARCEL_MEMO_NO ,B.REF_MEMO_ID ,A.vehicle_no ,LMVT.Ac_gst_no ,ANGM.Angadia_name,parcel_memo_dt,a.bilty_no
   

IF @XnType='WSL'   
   GOTO LBLWSL  
ELSE IF @XnType='PRT'  
   GOTO LBLPRT  
ELSE IF @XnType='WSR'  
   GOTO LBLWSR
ELSE IF @XnType='JWI'  
   GOTO LBLJWI
ELSE IF @XnType='MIS'  
   GOTO LBLMIS
ELSE IF @XnType='JWR'  
   GOTO LBLJWR
ELSE IF @XnType='SLS'  
   GOTO LBLSLS
ELSE   
    GOTO END_PROC    
  
  
LBLWSL:  


    SELECT @NPICKINGSHIPPINGADDRESS=
		  CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0 
			   THEN CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN 1 ELSE 2 END 
			   ELSE 3 END  
	 FROM INM01106  WHERE INV_ID=@INV_ID



	 select TOP 1 A.INV_ID,
      CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		   ELSE LM.Ac_gst_no  END SHIP_GSTIN,

      CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLM.AC_NAME   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLM.AC_NAME 
		   ELSE LM.AC_NAME  END SHIP_LGLNM,

       CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLM.AC_NAME   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLM.AC_NAME 
		   ELSE LM.AC_NAME  END SHIP_TRDNM,

         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS0 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS 
		   ELSE LM.ADDRESS0 END SHIP_ADDR1,

	    CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS1 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS2 
		   ELSE LM.ADDRESS1 END SHIP_ADDR2,

     
	    CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS2 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS3 
		   ELSE LM.ADDRESS2 END SHIP_ADDR3,


         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.AREA_NAME  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_AREA_NAME 
		   ELSE lm.AREA_NAME   END SHIP_LOC,

		
         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHCT.CITY  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.shipping_city_name 
		   ELSE lm.CITY   END SHIP_CITY,
         
		  CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.pincode   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(a.SHIPPING_PIN,'') 
		   ELSE lm.PINCODE    END SHIP_PIN,

		   CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHcs.gst_state_code   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(shp.gst_state_code ,'') 
		   ELSE lm.ac_gst_state_code     END SHIP_STCD


   into #TMPSHIPPING            
   FROM INM01106 A (NOLOCK)           
   JOIN LMV01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE         
   left join LM01106 shlm (nolock) on shlm.AC_CODE =a.SHIPPING_AC_CODE 
   left join LMP01106 shlmp (nolock) on shlmp.AC_CODE =shlm.AC_CODE 
   LEFT JOIN AREA shAR (NOLOCK) ON shlmp.AREA_CODE=shAR.AREA_CODE                        
   LEFT JOIN CITY shCT (NOLOCK) ON shAR.CITY_CODE=shCT.CITY_CODE  
   LEFT JOIN GST_STATE_MST shCS (NOLOCK) ON shCS.GST_STATE_CODE=shLMP.AC_GST_STATE_CODE      
   LEFT JOIN GST_STATE_MST SHP (NOLOCK) ON ISNULL(SHP.GST_STATE_NAME,'')=ISNULL(a.SHIPPING_STATE_NAME,'')     
   where a.inv_id=@INV_ID

      
--CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN 'INV' ELSE 'CHL' END
-- as Discuss with Sir change (inv,dbn)
	
	  SELECT  @NTABLABLEVALUE= SUM(XN_VALUE_WITHOUT_GST )
	  FROM IND01106         
	  WHERE INV_ID =@INV_ID           
		   
		             
   SELECT   sr=row_number() over (order by id.hsn_code),  
  'O' SupplyType  
  ,CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN '1' ELSE '5' END AS subSupplyType  
  , '' subSupplyDesc  
  ,CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN 'INV' ELSE 'CHL' END AS docType
  --INV MST  
  ,CASE WHEN (@CEINVOICE_PREFIX<>''  AND LEFT(RTRIM(LTRIM(im.INV_NO)),1)='0' and im.inv_dt>=@EINVOICESTDATE) THEN @CEINVOICE_PREFIX ELSE '' END+IM.inv_no docNo  
  ,CONVERT(VARCHAR,IM.inv_dt,103) docDate  
  ,l.loc_gst_no fromGstin  
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END  FROMTRDNAME  
  ,l.ADDRESS1 fromAddr1  
  ,l.ADDRESS2 fromAddr2   
  ,CITY.CITY fromPlace  
  ,ar.pincode  fromPincode  
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actFromStateCode  
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) fromStateCode  
  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END toGstin  --Party
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END  toTrdName  --Party

  ,ISNULL(TMP.SHIP_ADDR1,'')toAddr1    
  ,ISNULL(TMP.SHIP_ADDR2,'')+ISNULL(' '+TMP.SHIP_ADDR3,'')toAddr2  

  ,ISNULL(TMP.SHIP_CITY,'') toPlace  
  ,ISNULL(TMP.SHIP_PIN,'') toPincode  

  ,CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE ELSE  tmp.SHIP_STCD END  AS VARCHAR(10) ) AS actToStateCode  
  ,CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE 

       WHEN isnull(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code 
       ELSE  LEFT(LMV.AC_GST_NO,2) END  AS VARCHAR(10) ) AS toStateCode   --party
  ,IM.NET_AMOUNT totInvValue  
  ,replace(cast((SELECT SUM(cgst_amount)igst_amount FROM IND01106 ID1 (NOLOCK) WHERE INV_ID=@INV_ID) as numeric(18,2)),'.00','') cgstValue  
  ,replace(cast((SELECT SUM(sgst_amount)igst_amount FROM IND01106 ID1 (NOLOCK) WHERE INV_ID=@INV_ID) as numeric(18,2)),'.00','') sgstValue  
  ,replace(cast((SELECT SUM(igst_amount)igst_amount FROM IND01106 ID1 (NOLOCK) WHERE INV_ID=@INV_ID) as numeric(18,2)),'.00','') igstValue  
  ,0 cessValue  
  ,@NTABLABLEVALUE+(im.gst_round_off+ROUND_OFF)  totalValue   
  ,SUM(isnull(id.xn_value_without_gst,0))+(im.gst_round_off+ROUND_OFF) taxableAmount  
  --INV DET  
  ,ID.hsn_code  PRODUCTNAME  
  ,ID.hsn_code PRODUCTDESC  
  ,ID.hsn_code hsnCode  
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END qtyUnit  
  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
  ,0 cessRate  
  ,0 cessAdvol  
  ,PRCL.Ac_gst_no AS  transporterId  
  ,PRCL.Angadia_name transporterName  
  ,(CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo  
  ,1 AS  transMode  
  ,(CASE WHEN ISNULL(AR.PINCODE,'')=ISNULL(TMP.SHIP_PIN,'') THEN 20 ELSE 0 END ) as transDistance  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType   

  ,case when CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE ELSE  tmp.SHIP_STCD END  AS VARCHAR(10) )=
   CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE WHEN isnull(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code 
       ELSE  LEFT(LMV.AC_GST_NO,2) END  AS VARCHAR(10) )  then 1 else 2 END as TransactionType
 


  FROM INM01106 IM (NOLOCK)   
  JOIN IND01106 ID (NOLOCK) ON IM.INV_ID=ID.INV_ID  
  join location  l (nolock) on l.dept_id =im.location_Code
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE  
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]  
  LEFT JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=IM.AC_CODE   
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]  
  LEFT JOIN #TMPSHIPPING TMP ON TMP.INV_ID=IM.INV_ID
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.INV_ID 
  WHERE IM.INV_ID = @INV_ID  
  AND IM.CANCELLED=0   

  group by IM.inv_no ,CONVERT(VARCHAR,IM.inv_dt,103) ,l.loc_gst_no
  ,CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN 'INV' ELSE 'CHL' END 
  ,CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN '1' ELSE '5' END
   ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END    
  ,l.ADDRESS1   ,l.ADDRESS2  ,CITY.CITY   ,ar.pincode
  ,CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE ELSE  tmp.SHIP_STCD END  AS VARCHAR(10) )
  ,CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE 
       WHEN isnull(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code 
       ELSE  LEFT(LMV.AC_GST_NO,2) END  AS VARCHAR(10) )

  ,CASE WHEN (@CEINVOICE_PREFIX<>''  AND LEFT(RTRIM(LTRIM(im.INV_NO)),1)='0' and im.inv_dt>=@EINVOICESTDATE) THEN @CEINVOICE_PREFIX ELSE '' END
  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END ,
  PRCL.Ac_gst_no,(im.gst_round_off+ROUND_OFF),
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END
  ,ISNULL(TMP.SHIP_ADDR1,'')    
  ,ISNULL(TMP.SHIP_ADDR2,'')+ISNULL(' '+TMP.SHIP_ADDR3,'')  
  ,ISNULL(TMP.SHIP_CITY,'') ,ISNULL(TMP.SHIP_PIN,'')  ,IM.ewaydistance,IM.NET_AMOUNT ,IM.SUBTOTAL ,IM.SUBTOTAL,IM.ROUND_OFF   
 -- ,ARTICLE.ARTICLE_NO    
  ,ID.hsn_code ,
  CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  
  ,CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END   
  ,PRCL.Angadia_name , 
  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) ,
  CONVERT(VARCHAR,PRCL.parcel_memo_dt,103)   
  ,PRCL.vehicle_no ,
  case when CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE ELSE  tmp.SHIP_STCD END  AS VARCHAR(10) )=
   CAST( CASE WHEN im.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE WHEN isnull(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code 
       ELSE  LEFT(LMV.AC_GST_NO,2) END  AS VARCHAR(10) )  then 1 else 2 END,
	   (CASE WHEN ISNULL(AR.PINCODE,'')=ISNULL(TMP.SHIP_PIN,'') THEN 20 ELSE 0 END )
  
  
 GOTO END_PROC   
  
  
LBLPRT:  
  


	 select TOP 1 A.rm_id,
      CASE WHEN SHIPPING_MODE=0 THEN shlm.Ac_gst_no  
	       WHEN SHIPPING_MODE=1 THEN shlm.AC_GST_NO
		   ELSE LM.Ac_gst_no  END SHIP_GSTIN,

      CASE WHEN SHIPPING_MODE=0 THEN SHLM.AC_NAME   
	       WHEN SHIPPING_MODE=1 THEN SHLM.AC_NAME 
		   ELSE LM.AC_NAME  END SHIP_LGLNM,

       CASE WHEN SHIPPING_MODE=0 THEN SHLM.AC_NAME   
	       WHEN SHIPPING_MODE=1 THEN SHLM.AC_NAME 
		   ELSE LM.AC_NAME  END SHIP_TRDNM,

         CASE WHEN SHIPPING_MODE=0 THEN shlm.ADDRESS0 --0 select shipping_ledger 
	       WHEN SHIPPING_MODE=1 THEN a.SHIPPING_ADDRESS --1 open ledger
		   ELSE LM.ADDRESS0 END SHIP_ADDR1, --2  same as billing 

	    CASE WHEN SHIPPING_MODE=0 THEN shlm.ADDRESS1 
	       WHEN SHIPPING_MODE=1 THEN a.SHIPPING_ADDRESS2 
		   ELSE LM.ADDRESS1 END SHIP_ADDR2,

     
	    CASE WHEN SHIPPING_MODE=0 THEN shlm.ADDRESS2 
	       WHEN SHIPPING_MODE=1 THEN a.SHIPPING_ADDRESS3 
		   ELSE LM.ADDRESS2 END SHIP_ADDR3,


         CASE WHEN SHIPPING_MODE=0 THEN shlm.AREA_NAME  
	       WHEN SHIPPING_MODE=1 THEN a.SHIPPING_AREA_NAME 
		   ELSE lm.AREA_NAME   END SHIP_LOC,

		
         CASE WHEN SHIPPING_MODE=0 THEN shlm.CITY  
	       WHEN SHIPPING_MODE=1 THEN a.shipping_city_name 
		   ELSE lm.CITY   END SHIP_CITY,
         
		  CASE WHEN SHIPPING_MODE=0 THEN shlm.pincode   
	       WHEN SHIPPING_MODE=1 THEN ISNULL(a.SHIPPING_PIN,'') 
		   ELSE lm.PINCODE    END SHIP_PIN,

		   CASE WHEN SHIPPING_MODE=0 THEN shlm.ac_gst_state_code   
	       WHEN SHIPPING_MODE=1 THEN ISNULL(shlm.ac_gst_state_code ,'') 
		   ELSE lm.ac_gst_state_code     END SHIP_STCD


   into #TMPSHIPPING_rmm            
   FROM rmm01106 A (NOLOCK)           
   JOIN LMV01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE         
   left join LMV01106 shlm (nolock) on shlm.AC_CODE =a.SHIPPING_AC_CODE 
   where a.rm_id=@INV_ID
  
 
 
	  DECLARE @NTABLABLEVALUERPT NUMERIC(14,2)
	  SELECT  @NTABLABLEVALUERPT= SUM(XN_VALUE_WITHOUT_GST )
	  FROM RMD01106         
	  WHERE rm_id =@INV_ID           
		   
		             
     SELECT --FIX VAL  
     sr=row_number() over (order by id.hsn_code),  
   cast('O' as varchar(1)) SupplyType  
  ,cast(CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN '8' ELSE '5' END as varchar(1)) AS subSupplyType  
  , 'PURCHASE RETURN' subSupplyDesc  
  , CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN 'OTH' ELSE 'CHL' END  AS docType
  --INV MST  
  ,CASE WHEN (@CEINVOICE_PREFIX<>''  AND LEFT(RTRIM(LTRIM(im.rm_no)),1)='0' and im.rm_dt>=@EINVOICESTDATE) THEN @CEINVOICE_PREFIX ELSE '' END+IM.rm_no docNo  
  ,CONVERT(VARCHAR,IM.rm_dt,103) docDate  
  ,l.loc_gst_no  fromGstin  
   ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END fromTrdName  
  ,l.ADDRESS1 fromAddr1  
  ,l.ADDRESS2 fromAddr2   
  ,city.CITY fromPlace  
  ,ar.PINcode  fromPincode  
  ,cast(left(l.loc_gst_no ,2) as INT) actFromStateCode  
  ,cast(left(l.loc_gst_no,2) as INT) fromStateCode  

  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END toGstin  
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END toTrdName  


  ,ISNULL(tmp.SHIP_ADDR1,'')toAddr1    
  ,ISNULL(TMP.SHIP_ADDR2,'')+ISNULL(' '+TMP.SHIP_ADDR3,'') toAddr2  
  ,ISNULL(TMP.SHIP_CITY,'') toPlace  
  ,ISNULL(TMP.SHIP_PIN,'') toPincode  
  ,cast( CASE WHEN ISNULL(LEFT(tmp.SHIP_GSTIN,2),'')='' THEN tmp.SHIP_STCD ELSE   LEFT(tmp.SHIP_GSTIN,2) END as INT) AS actToStateCode  
  ,cast(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code ELSE  LEFT(lmv.AC_GST_NO,2) END as INT) AS toStateCode  
  ,IM.total_amount  totInvValue  
  ,replace(cast((SELECT SUM(cgst_amount)igst_amount FROM RMD01106 ID1 (NOLOCK) WHERE rm_id=@INV_ID) as numeric(18,2)),'.00','') cgstValue  
  ,replace(cast((SELECT SUM(sgst_amount)igst_amount FROM RMD01106 ID1 (NOLOCK) WHERE rm_id=@INV_ID) as numeric(18,2)),'.00','') sgstValue  
  ,replace(cast((SELECT SUM(igst_amount)igst_amount FROM RMD01106 ID1 (NOLOCK) WHERE rm_id=@INV_ID) as numeric(18,2)),'.00','') igstValue  
  ,0 cessValue  
  ,@NTABLABLEVALUERPT  totalValue 
  ,SUM(isnull(id.xn_value_without_gst,0)) taxableAmount  
  ,ID.hsn_code  PRODUCTNAME  
  ,ID.hsn_code PRODUCTDESC  
  ,ID.hsn_code hsnCode  
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit  
  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
  ,0 cessRate  
  ,0 cessAdvol  
  ,PRCL.Ac_gst_no AS  transporterId  
  ,PRCL.Angadia_name transporterName  
  ,  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo  
  ,1 AS  transMode  
  ,(CASE WHEN ISNULL(AR.PINCODE,'')=ISNULL(tmp.SHIP_PIN,'') THEN 20 ELSE 0 END ) as transDistance  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo  

  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType 
  ,(case when cast( CASE WHEN ISNULL(LEFT(tmp.SHIP_GSTIN,2),'')='' THEN tmp.SHIP_STCD ELSE   LEFT(tmp.SHIP_GSTIN,2) END as INT)<>  
   cast(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code ELSE  LEFT(lmv.AC_GST_NO,2) END as INT)  then 2 
     else 1 end ) as TransactionType
  FROM RMM01106 IM (NOLOCK)   
  JOIN RMD01106 ID (NOLOCK) ON IM.rm_id=ID.rm_id  
  join location  l (nolock) on l.dept_id =im.location_Code
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE  
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]  
  LEFT JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=IM.AC_CODE   
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]  
  LEFT JOIN #TMPSHIPPING_rmm TMP ON TMP.rm_id=IM.rm_id
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.RM_ID 

  WHERE IM.rm_id = @INV_ID  
  AND IM.CANCELLED=0   
  group by CASE WHEN (@CEINVOICE_PREFIX<>''  AND LEFT(RTRIM(LTRIM(im.rm_no)),1)='0' and im.rm_dt>=@EINVOICESTDATE) THEN @CEINVOICE_PREFIX ELSE '' END+IM.rm_no ,CONVERT(VARCHAR,IM.rm_dt,103) ,l.loc_gst_no    
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END
  ,CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN '8' ELSE '5' END,
  CASE WHEN l.loc_gst_no<>LMV.AC_GST_NO THEN 'OTH' ELSE 'CHL' END 
  ,l.ADDRESS1 ,l.ADDRESS2  ,city.CITY ,ar.PINcode    
  ,left(l.loc_gst_no,2) ,
  CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END ,
  PRCL.Ac_gst_no,
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,

  ISNULL(tmp.SHIP_ADDR1,'')    
  ,ISNULL(tmp.SHIP_ADDR2,'')+ISNULL(' '+TMP.SHIP_ADDR3,'')  
  ,ISNULL(TMP.SHIP_CITY,'') ,ISNULL(TMP.SHIP_PIN,'') 
  ,cast( CASE WHEN ISNULL(LEFT(tmp.SHIP_GSTIN,2),'')='' THEN tmp.SHIP_STCD ELSE   LEFT(tmp.SHIP_GSTIN,2) END as INT) ,
  cast(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN lmv.ac_gst_state_code ELSE  LEFT(lmv.AC_GST_NO,2) END as INT),
  IM.total_amount ,IM.SUBTOTAL ,IM.SUBTOTAL,IM.ROUND_OFF   
  --,ARTICLE.ARTICLE_NO
  ,CN_AMOUNT    
  ,ID.hsn_code 
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END      
  ,CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END   
  ,PRCL.Angadia_name , 
  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END),
  CONVERT(VARCHAR,PRCL.parcel_memo_dt,103)   
  ,PRCL.vehicle_no  ,(CASE WHEN ISNULL(AR.PINCODE,'')=ISNULL(tmp.SHIP_PIN,'') THEN 20 ELSE 0 END )
  
  
 GOTO END_PROC   
  
  LBLWSR:
  SELECT --FIX VAL  
     sr=row_number() over (order by id.hsn_code),  
  'O' SupplyType  
  ,1 subSupplyType  
  ,'' subSupplyDesc  
  ,'oth' docType  
  --INV MST  
  ,IM.cn_no docNo  
  ,CONVERT(VARCHAR,IM.cn_dt,103) docDate  

  ,l.loc_gst_no fromGstin  
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END  FROMTRDNAME  
  ,l.ADDRESS1 fromAddr1  
  ,l.ADDRESS2 fromAddr2   
  ,l.ADDRESS2 fromAddr2   
  ,CITY.CITY  fromPlace  
  ,ar.pincode fromPincode  
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actFromStateCode  
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) fromStateCode  
  ,LMV.AC_GST_NO toGstin  
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END toTrdName  
  ,ISNULL(LMV.ADDRESS0,'')toAddr1    
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')toAddr2  
  ,LMV.CITY toPlace  
  ,LMV.PINCODE toPincode  
  ,LEFT(LMV.AC_GST_NO,2) AS actToStateCode  
  ,LEFT(LMV.AC_GST_NO,2) AS toStateCode  
  ,IM.total_amount totInvValue  
  ,replace(cast((SELECT SUM(cgst_amount)igst_amount FROM CND01106 ID1 (NOLOCK) WHERE cn_id=@INV_ID) as numeric(14,2)),'.00','') cgstValue  
  ,replace(cast((SELECT SUM(sgst_amount)igst_amount FROM CND01106 ID1 (NOLOCK) WHERE cn_id=@INV_ID) as numeric(14,2)),'.00','') sgstValue  
  ,replace(cast((SELECT SUM(igst_amount)igst_amount FROM CND01106 ID1 (NOLOCK) WHERE cn_id=@INV_ID) as numeric(14,2)),'.00','') igstValue  
  ,0 cessValue  
  ,IM.SUBTOTAL+IM.ROUND_OFF  totalValue   
  ,SUM(isnull(id.xn_value_without_gst,0))+IM.ROUND_OFF taxableAmount  
  --INV DET  
  ,ID.hsn_code  PRODUCTNAME  
  ,ID.hsn_code PRODUCTDESC  
  ,ID.hsn_code hsnCode  
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit  
  
  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
  
  ,0 cessRate  
  ,0 cessAdvol  
  ,'' AS  transporterId  
  ,ANGM.Angadia_name transporterName  
  ,A.parcel_memo_no transDocNo  
  ,2 AS  transMode  
  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance  
  ,CONVERT(VARCHAR,A.parcel_memo_dt,103) transDocDate  
  , A.vehicle_no vehicleNo  

  ,'R' vehicleType  
  FROM CNM01106 IM (NOLOCK)   
  JOIN CND01106 ID (NOLOCK) ON IM.cn_id=ID.cn_id  
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  join location  l (nolock) on l.dept_id =im.location_Code
--  LEFT JOIN COMPANY C (NOLOCK) ON IM.COMPANY_CODE=C.COMPANY_CODE  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE  
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]  
  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=IM.AC_CODE  
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]  
  LEFT JOIN PARCEL_MST A (NOLOCK) JOIN PARCEL_DET B (NOLOCK) ON B.parcel_memo_id=A.parcel_memo_id   AND A.CANCELLED=0  
  JOIN ANGM (NOLOCK) ON A.angadia_code=ANGM.angadia_code  
  ON IM.cn_id=B.REF_MEMO_ID  
  WHERE IM.cn_id = @INV_ID  
  AND IM.CANCELLED=0   
  AND A.XN_TYPE='WSR' 
  group by IM.cn_no ,CONVERT(VARCHAR,IM.cn_dt,103) ,
  l.loc_gst_no ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END ,
  l.ADDRESS1 ,l.ADDRESS2  ,CITY.CITY,ar.PINcode    
  ,left(l.loc_gst_no,2) ,LMV.AC_GST_NO ,
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,
  ISNULL(LMV.ADDRESS0,'')    
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')  
  ,LMV.CITY,LMV.PINCODE ,LEFT(LMV.AC_GST_NO,2) ,LEFT(LMV.AC_GST_NO,2)   
  ,LEFT(LMV.AC_GST_NO,2) ,IM.total_amount ,IM.SUBTOTAL ,IM.SUBTOTAL,IM.ROUND_OFF   
  --,ARTICLE.ARTICLE_NO    
  ,ID.hsn_code 
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END    
  ,CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END   
  ,ANGM.Angadia_name ,A.parcel_memo_no ,CONVERT(VARCHAR,A.parcel_memo_dt,103)   
  ,A.vehicle_no   ,(CASE WHEN ISNULL(ar.PINcode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END )
  
  
 GOTO END_PROC  
 LBLJWI:
     


IF EXISTS (SELECT TOP 1 'U' FROM jobwork_issue_mst WHERE ISSUE_ID=@INV_ID AND ISNULL(ISSUE_MODE,0)=0 AND WIP=1)
BEGIN


  select @ntotalvalue=SUM(xn_value_with_gst),@NTABLABLEVALUE=sum(xn_value_without_gst) FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID

  SELECT  sr=row_number() over (order by id.hsn_code),  
  'O' SupplyType  
  ,4 subSupplyType  
  ,''subSupplyDesc  
  ,'CHL' docType  
  ,IM.issue_no docNo  
  ,CONVERT(VARCHAR,IM.issue_dt,103) docDate  

  ,l.loc_gst_no fromGstin  
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END  FROMTRDNAME  
  ,l.ADDRESS1 fromAddr1  
  ,l.ADDRESS2 fromAddr2   
  ,l.ADDRESS2 fromAddr2   
  ,CITY.CITY  fromPlace  
  ,ar.pincode fromPincode  
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actFromStateCode  
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) fromStateCode  

  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END toGstin  
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END toTrdName  
  ,ISNULL(LMV.ADDRESS0,'')toAddr1    
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')toAddr2  
  ,LMV.CITY toPlace  
  ,LMV.PINCODE toPincode  
  ,( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END) AS actToStateCode  
  ,(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) AS toStateCode  
  ,@ntotalvalue totInvValue  
  ,replace(cast((SELECT SUM(cgst_amount)igst_amount FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') cgstValue  
  ,replace(cast((SELECT SUM(sgst_amount)igst_amount FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') sgstValue  
  ,replace(cast((SELECT SUM(igst_amount)igst_amount FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') igstValue  
  ,0 cessValue  
  ,@NTABLABLEVALUE  totalValue   
  ,SUM(isnull(id.xn_value_without_gst,0)) taxableAmount  
  --INV DET  
  ,ID.hsn_code  PRODUCTNAME  
  ,ID.hsn_code PRODUCTDESC  
  ,ID.hsn_code hsnCode  
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit  
  
  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
  
  ,0 cessRate  
  ,0 cessAdvol  
  ,PRCL.Ac_gst_no AS  transporterId  
  ,PRCL.Angadia_name transporterName  
  , (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo  
  ,1 AS  transMode  
  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType    
  FROM jobwork_issue_mst IM (NOLOCK)   
  JOIN jobwork_issue_det ID (NOLOCK) ON IM.issue_id=ID.issue_id  
  JOIN WIP_PMT SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  JOIN prd_agency_mst AMST (NOLOCK) ON AMST.agency_code=IM.agency_code
  join location  l (nolock) on l.dept_id =im.location_Code
  --LEFT JOIN COMPANY C (NOLOCK) ON IM.COMPANY_CODE=C.COMPANY_CODE  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE  
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]  
  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=AMST.AC_CODE  
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]  
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.issue_id 
  WHERE IM.issue_id = @INV_ID AND IM.CANCELLED=0   
  group by IM.issue_no ,CONVERT(VARCHAR,IM.issue_dt,103) ,
   l.loc_gst_no ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END ,
  l.ADDRESS1 ,l.ADDRESS2  ,CITY.CITY,ar.PINcode    
  ,left(l.loc_gst_no,2) ,
  CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END ,
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,
  ISNULL(LMV.ADDRESS0,'') ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'') ,LMV.CITY,LMV.PINCODE ,
  ( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) ,
  (CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END )  ,ID.hsn_code 
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END    
  ,CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END 
  ,PRCL.Ac_gst_no  ,PRCL.Angadia_name   
  ,(CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END)  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end      
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end ,
  (CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END )
 
  

  END 
  ELSE
  BEGIN
     
	 
   select @ntotalvalue=SUM(xn_value_with_gst),@NTABLABLEVALUE=sum(xn_value_without_gst) FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID

	 
  SELECT --FIX VAL  
     sr=row_number() over (order by id.hsn_code),  
  'O' SupplyType  
  ,4 subSupplyType  
  ,''subSupplyDesc  
  ,'CHL' docType  
  --INV MST  
  ,IM.issue_no docNo  
  ,CONVERT(VARCHAR,IM.issue_dt,103) docDate  

   ,l.loc_gst_no fromGstin  
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END  FROMTRDNAME  
  ,l.ADDRESS1 fromAddr1  
  ,l.ADDRESS2 fromAddr2   
  ,l.ADDRESS2 fromAddr2   
  ,CITY.CITY  fromPlace  
  ,ar.pincode fromPincode  
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actFromStateCode  
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) fromStateCode  

  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END toGstin  
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END toTrdName  
  ,ISNULL(LMV.ADDRESS0,'')toAddr1    
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')toAddr2  
  ,LMV.CITY toPlace  
  ,LMV.PINCODE toPincode  
  ,( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) AS actToStateCode  
  ,(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) AS toStateCode   
  ,@ntotalvalue totInvValue  
  ,replace(cast((SELECT SUM(cgst_amount)cgst_amount FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') cgstValue  
  ,replace(cast((SELECT SUM(sgst_amount)sgst_amount FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') sgstValue  
  ,replace(cast((SELECT SUM(igst_amount)igst_amount FROM jobwork_issue_det ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') igstValue  
  ,0 cessValue  
  ,@NTABLABLEVALUE  totalValue   
  ,SUM(isnull(id.xn_value_without_gst,0)) taxableAmount  
  --INV DET  
  ,ID.hsn_code  PRODUCTNAME  
  ,ID.hsn_code PRODUCTDESC  
  ,ID.hsn_code hsnCode  
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit  
  
  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
  
  ,0 cessRate  
  ,0 cessAdvol  
  ,PRCL.Ac_gst_no AS  transporterId  
  ,PRCL.Angadia_name transporterName  
  ,  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo  
  ,1 AS  transMode  
  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType    
  FROM jobwork_issue_mst IM (NOLOCK)   
  JOIN jobwork_issue_det ID (NOLOCK) ON IM.issue_id=ID.issue_id  
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  JOIN prd_agency_mst AMST (NOLOCK) ON AMST.agency_code=IM.agency_code
  join location  l (nolock) on l.dept_id =im.location_Code
 -- LEFT JOIN COMPANY C (NOLOCK) ON IM.COMPANY_CODE=C.COMPANY_CODE  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE  
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]  
  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=AMST.AC_CODE  
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]  
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.issue_id 
  WHERE IM.issue_id = @INV_ID  
  AND IM.CANCELLED=0   
  group by IM.issue_no ,CONVERT(VARCHAR,IM.issue_dt,103) ,l.loc_gst_no,
  CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END ,
  l.ADDRESS1 ,l.ADDRESS2  ,CITY.CITY,ar.PINcode    
  ,left(l.loc_gst_no,2) ,

  CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END ,
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,
  ISNULL(LMV.ADDRESS0,'') ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')  
  ,LMV.CITY,LMV.PINCODE ,
  ( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) ,
  (CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) , ID.hsn_code 
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END    
  ,CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END 
  ,PRCL.Ac_gst_no  ,PRCL.Angadia_name   
  ,(CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END)  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end      
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end   
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end    ,
  (CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END )


  END
  
 GOTO END_PROC   


 LBLmis:

  SELECT --FIX VAL  
     sr=row_number() over (order by id.hsn_code),  
  'O' SupplyType  
  ,4 subSupplyType  
  ,''subSupplyDesc  
  ,'CHL' docType  
  --INV MST  
  ,Rtrim(ltrim(IM.issue_no)) docNo  
  ,CONVERT(VARCHAR,IM.issue_dt,103) docDate  

   ,l.loc_gst_no fromGstin  
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END  FROMTRDNAME  
  ,l.ADDRESS1 fromAddr1  
  ,l.ADDRESS2 fromAddr2   
  ,l.ADDRESS2 fromAddr2   
  ,CITY.CITY  fromPlace  
  ,ar.pincode fromPincode  
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actFromStateCode  
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) fromStateCode  

  ,LMV.AC_GST_NO toGstin  
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END toTrdName  
  ,ISNULL(LMV.ADDRESS0,'')toAddr1    
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')toAddr2  
  ,LMV.CITY toPlace  
  ,LMV.PINCODE toPincode  
  ,LEFT(LMV.AC_GST_NO,2) AS actToStateCode  
  ,LEFT(LMV.AC_GST_NO,2) AS toStateCode  
  ,LEFT(LMV.AC_GST_NO,2) AS toStateCode  
  ,IM.total_amount totInvValue  
  --SUM(cgst_amount) cgstValue,  
  --SUM(sgst_amount) sgstValue,  
  --SUM(igst_amount) igstValue  
  ,replace(cast((SELECT SUM(cgst_amount)cgst_amount FROM BOM_ISSUE_DET ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') cgstValue  
  ,replace(cast((SELECT SUM(sgst_amount)sgst_amount FROM BOM_ISSUE_DET ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') sgstValue  
  ,replace(cast((SELECT SUM(igst_amount)igst_amount FROM BOM_ISSUE_DET ID1 (NOLOCK) WHERE issue_id=@INV_ID) as numeric(14,2)),'.00','') igstValue  
  ,0 cessValue  
  ,IM.SUBTOTAL+IM.ROUND_OFF  totalValue   
  ,SUM(isnull(id.xn_value_without_gst,0))+IM.ROUND_OFF taxableAmount  
  --INV DET  
  ,ID.hsn_code  PRODUCTNAME  
  ,ID.hsn_code PRODUCTDESC  
  ,ID.hsn_code hsnCode  
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit  
  
  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
  
  ,0 cessRate  
  ,0 cessAdvol  
  ,PRCL.Ac_gst_no AS  transporterId  
  ,PRCL.Angadia_name transporterName  
  ,  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo  
  ,1 AS  transMode  
  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo  
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType   
  FROM BOM_ISSUE_MST IM (NOLOCK)   
  JOIN BOM_ISSUE_DET ID (NOLOCK) ON IM.issue_id=ID.issue_id  
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  JOIN prd_agency_mst AMST (NOLOCK) ON AMST.agency_code=IM.agency_code
    join location  l (nolock) on l.dept_id =im.location_Code
  --LEFT JOIN COMPANY C (NOLOCK) ON IM.COMPANY_CODE=C.COMPANY_CODE  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE  
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]  
  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=AMST.AC_CODE  
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]  
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.issue_id 
  WHERE IM.issue_id = @INV_ID  
  AND IM.CANCELLED=0   
  group by Rtrim(ltrim(IM.issue_no)) ,CONVERT(VARCHAR,IM.issue_dt,103)  ,l.loc_gst_no,
  CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END ,
  l.ADDRESS1 ,l.ADDRESS2  ,CITY.CITY,ar.PINcode    
  ,left(l.loc_gst_no,2)  ,LMV.AC_GST_NO ,
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,
  ISNULL(LMV.ADDRESS0,'')    
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')  
  ,LMV.CITY,LMV.PINCODE ,LEFT(LMV.AC_GST_NO,2) ,LEFT(LMV.AC_GST_NO,2)   
  ,LEFT(LMV.AC_GST_NO,2) ,IM.total_amount ,IM.SUBTOTAL ,IM.SUBTOTAL,IM.ROUND_OFF   
  --,ARTICLE.ARTICLE_NO    
  ,ID.hsn_code 
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END    
  ,CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END   
  ,CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END ,
  PRCL.Ac_gst_no,PRCL.Angadia_name,PRCL.vehicle_no ,
   (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END), 
  case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end  ,    
  case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end    ,
  (CASE WHEN ISNULL(ar.PINcode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END )
   
  
 GOTO END_PROC   
 
 LBLJWR:
    
IF EXISTS (SELECT TOP 1 'U' FROM jobwork_receipt_mst WHERE receipt_id=@INV_ID AND WIP=1)  
BEGIN  
  
  
  select @ntotalvalue=SUM(JWr_XN_RATE_WITH_GST*QUANTITY)  FROM jobwork_receipt_det ID1 (NOLOCK) WHERE receipt_id=@INV_ID  
  
  SELECT  sr=row_number() over (order by id.hsn_code),    
  'I' SupplyType    
  ,6 subSupplyType    
  ,''subSupplyDesc    
  ,'CHL' docType    
  ,IM.challan_no  docNo    
  ,CONVERT(VARCHAR,IM.challan_dt ,103) docDate    

  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END fromGstin   
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END FROMTRDNAME     
  ,ISNULL(LMV.ADDRESS0,'') fromAddr1       
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'') fromAddr2   
  ,LMV.CITY fromPlace    
  ,LMV.PINCODE fromPincode 
  ,( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END) AS actFromStateCode  
  ,(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) AS fromStateCode     

  ,l.loc_gst_no  toGstin     
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END toTrdName     
  ,l.ADDRESS1 toAddr1    
  ,l.ADDRESS2 toAddr2           
  ,CITY.CITY  toPlace    
  ,ar.pincode toPincode       
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actToStateCode       
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) toStateCode    

  ,@ntotalvalue totInvValue    
  ,0 cgstValue    
  ,0 sgstValue    
  ,0 igstValue    
  ,0 cessValue    
  ,@ntotalvalue  totalValue     
  ,@ntotalvalue taxableAmount    
  --INV DET    
  ,ID.hsn_code  PRODUCTNAME    
  ,ID.hsn_code PRODUCTDESC    
  ,ID.hsn_code hsnCode    
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity    
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit      
  ,0 cgstRate    
  ,0 sgstRate    
  ,0 igstRate    
    
  ,0 cessRate    
  ,0 cessAdvol    
  ,PRCL.Ac_gst_no AS  transporterId    
  ,PRCL.Angadia_name transporterName    
  , (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN ''   
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo    
  ,1 AS  transMode    
  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate      
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType ,
  1 as Transaction_type
  FROM jobwork_receipt_mst IM (NOLOCK)     
  JOIN jobwork_receipt_det ID (NOLOCK) ON IM.receipt_id=ID.receipt_id    
  JOIN WIP_PMT SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE    
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE    
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code    
  JOIN prd_agency_mst AMST (NOLOCK) ON AMST.agency_code=IM.agency_code  
  join location  l (nolock) on l.dept_id =im.location_Code  
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE    
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE    
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE    
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]    
  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=AMST.AC_CODE    
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]    
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.receipt_id   
  WHERE IM.receipt_id = @INV_ID AND IM.CANCELLED=0     
  group by IM.challan_no  ,CONVERT(VARCHAR,IM.challan_dt ,103) ,  
   l.loc_gst_no ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END ,  
  l.ADDRESS1 ,l.ADDRESS2  ,CITY.CITY,ar.PINcode      
  ,left(l.loc_gst_no,2) ,  
  CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END ,  
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,  
  ISNULL(LMV.ADDRESS0,'') ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'') ,LMV.CITY,LMV.PINCODE ,  
  ( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) ,  
  (CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END )  ,ID.hsn_code   
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END        
  ,PRCL.Ac_gst_no  ,PRCL.Angadia_name     
  ,(CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN ''   
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END)    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end        
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end      
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end ,  
  (CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END )  
   
    
  
  END   
  ELSE  
  BEGIN  
       
    
   select @NTOTALVALUE=SUM(JWr_XN_RATE_WITH_GST*QUANTITY) FROM jobwork_receipt_det ID1 (NOLOCK) WHERE receipt_id=@INV_ID  
  
    
  SELECT --FIX VAL    
     sr=row_number() over (order by id.hsn_code),    
  'I' SupplyType    
  ,6 subSupplyType    
  ,''subSupplyDesc    
  ,'CHL' docType    
  --INV MST    
  ,IM.challan_no  docNo    
  ,CONVERT(VARCHAR,IM.challan_dt ,103) docDate    

  ,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END fromGstin   
  ,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END FROMTRDNAME     
  ,ISNULL(LMV.ADDRESS0,'') fromAddr1       
  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'') fromAddr2   
  ,LMV.CITY fromPlace    
  ,LMV.PINCODE fromPincode 
  ,( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END) AS actFromStateCode  
  ,(CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) AS fromStateCode     

  ,l.loc_gst_no  toGstin     
  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END toTrdName     
  ,l.ADDRESS1 toAddr1    
  ,l.ADDRESS2 toAddr2           
  ,CITY.CITY  toPlace    
  ,ar.pincode toPincode       
  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actToStateCode       
  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) toStateCode    
  ,@ntotalvalue totInvValue    
  ,0 cgstValue    
  ,0 sgstValue    
  ,0 igstValue    
  ,0 cessValue    
  ,@NTOTALVALUE  totalValue     
  ,@NTOTALVALUE taxableAmount    
  --INV DET    
  ,ID.hsn_code  PRODUCTNAME    
  ,ID.hsn_code PRODUCTDESC    
  ,ID.hsn_code hsnCode    
  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity    
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit    
    
  ,0 cgstRate    
  ,0 sgstRate    
  ,0 igstRate    
    
  ,0 cessRate    
  ,0 cessAdvol    
  ,PRCL.Ac_gst_no AS  transporterId    
  ,PRCL.Angadia_name transporterName    
  ,  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN ''   
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo    
  ,1 AS  transMode    
  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate      
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType ,
  1 as Trasaction_type
  FROM jobwork_receipt_mst IM (NOLOCK)     
  JOIN jobwork_receipt_det ID (NOLOCK) ON IM.receipt_id=ID.receipt_id
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE    
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE    
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code    
  JOIN prd_agency_mst AMST (NOLOCK) ON AMST.agency_code=IM.agency_code  
  join location  l (nolock) on l.dept_id =im.location_Code 
 -- LEFT JOIN COMPANY C (NOLOCK) ON IM.COMPANY_CODE=C.COMPANY_CODE    
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE    
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE    
  LEFT JOIN [STATE] (NOLOCK) ON [STATE].STATE_CODE=CITY.STATE_CODE    
  LEFT JOIN GST_STATE_MST (NOLOCK) ON GST_STATE_MST.GST_STATE_NAME=[STATE].[STATE]    
  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=AMST.AC_CODE    
  LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_NAME=LMV.[STATE]    
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.receipt_id   
  WHERE IM.receipt_id = @INV_ID    
  AND IM.CANCELLED=0     
  group by IM.challan_no  ,CONVERT(VARCHAR,IM.challan_dt ,103) ,l.loc_gst_no,  
  CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END ,  
  l.ADDRESS1 ,l.ADDRESS2  ,CITY.CITY,ar.PINcode      
  ,left(l.loc_gst_no,2) ,  
  CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.AC_GST_NO END ,  
  CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END ,  
  ISNULL(LMV.ADDRESS0,'') ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')    
  ,LMV.CITY,LMV.PINCODE ,  
  ( CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) ,  
  (CASE WHEN ISNULL(LEFT(LMV.AC_GST_NO,2),'')='' THEN LMV.AC_GST_STATE_CODE ELSE   LEFT(LMV.AC_GST_NO,2) END ) , ID.hsn_code   
  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END      
  ,PRCL.Ac_gst_no  ,PRCL.Angadia_name     
  ,(CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN ''   
         ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END)    
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end        
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end     
  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end    ,  
  (CASE WHEN ISNULL(ar.pincode,'')=ISNULL(lmv.PINCODE,'') THEN 20 ELSE 0 END )  
  
  
  END  
  
 
 GOTO END_PROC  
 
 LBLSLS:
      
      
      
   select @ntotalvalue=SUM(xn_value_with_gst),@NTABLABLEVALUE=sum(xn_value_without_gst) ,
          @Ncgst_amount=SUM(ISNULL(cgst_amount,0)),
          @Nsgst_amount=SUM(ISNULL(sgst_amount,0)),
          @Nigst_amount=SUM(ISNULL(igst_amount,0))
          
   FROM CMD01106 ID1 (NOLOCK) WHERE cm_id =@INV_ID

	 
  SELECT  sr=row_number() over (order by id.hsn_code),  
		  'O' SupplyType  
		  ,4 subSupplyType  
		  ,''subSupplyDesc  
		  ,'CHL' docType  
		  ,IM.cm_no  docNo  
		  ,CONVERT(VARCHAR,IM.cm_dt,103) docDate  
		   ,l.loc_gst_no fromGstin  
		  ,CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END  FROMTRDNAME  
		  ,l.ADDRESS1 fromAddr1  
		  ,l.ADDRESS2 fromAddr2   
		  ,CITY.CITY  fromPlace  
		  ,ar.pincode fromPincode  
		  ,cast(left(l.loc_gst_no,2) as VARCHAR(4)) actFromStateCode  
		  ,cast(left(l.loc_gst_no,2)  as VARCHAR(4)) fromStateCode  
		  ,ISNULL(LMV.CUS_GST_NO,'') toGstin  
		  ,LTRIM(RTRIM(ISNULL(LMV.customer_fname,'') + ' '+ISNULL(LMV.customer_lname,''))) toTrdName  
		  --,CASE WHEN ISNULL(LMV.REGISTERED_GST_DEALER,0)=0 THEN 'URP' ELSE   LMV.CUS_GST_NO END toGstin  
		  --,CASE WHEN ISNULL(LMV.PRINT_NAME,'')<>'' THEN LMV.PRINT_NAME ELSE  LMV.AC_NAME END toTrdName  
		  ,ISNULL(LMV.ADDRESS0,'')toAddr1    
		  ,ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'')toAddr2  
		  ,city_cust.CITY toPlace  
		  ,ar_cust.PINCODE toPincode  
		  ,( CASE WHEN ISNULL(LEFT(LMV.CUS_GST_NO,2),'')='' THEN LMV.CUS_GST_STATE_CODE ELSE   LEFT(LMV.CUS_GST_NO,2) END ) AS actToStateCode  
		  ,(CASE WHEN ISNULL(LEFT(LMV.CUS_GST_NO,2),'')='' THEN LMV.CUS_GST_STATE_CODE ELSE   LEFT(LMV.CUS_GST_NO,2) END ) AS toStateCode   
		  ,@ntotalvalue totInvValue  
		  ,replace(cast(ISNULL(@Ncgst_amount,0) as numeric(14,2)),'.00','') cgstValue  
		  ,replace(cast(ISNULL(@Nsgst_amount,0) as numeric(14,2)),'.00','') sgstValue  
		  ,replace(cast(ISNULL(@Nigst_amount,0) as numeric(14,2)),'.00','') igstValue  
		  ,0 cessValue  
		  ,@NTABLABLEVALUE  totalValue   
		  ,SUM(isnull(id.xn_value_without_gst,0)) taxableAmount  
		  --INV DET  
		  ,ID.hsn_code  PRODUCTNAME  
		  ,ID.hsn_code PRODUCTDESC  
		  ,ID.hsn_code hsnCode  
		  ,replace(cast(sum(ID.QUANTITY) as numeric(14,2)),'.00','') quantity  
		  ,CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END  qtyUnit  
		  
		  ,replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') cgstRate  
		  ,replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') sgstRate  
		  ,replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') igstRate  
		  
		  ,0 cessRate  
		  ,0 cessAdvol  
		  ,PRCL.Ac_gst_no AS  transporterId  
		  ,PRCL.Angadia_name transporterName  
		  ,  (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
				 ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) as transDocNo  
		  ,1 AS  transMode  
		  ,(CASE WHEN ISNULL(ar.pincode,'')=ISNULL(AR_cust.PINCODE,'') THEN 20 ELSE 0 END ) as transDistance  
		  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end as transDocDate    
		  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end as vehicleNo  
		  ,case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end as vehicleType    
  FROM cmm01106 IM (NOLOCK)   
  JOIN cmd01106  ID (NOLOCK) ON IM.cm_id =ID.cm_id
  join location  l (nolock) on l.dept_id =im.location_Code
  LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=l.AREA_CODE  
  LEFT JOIN CITY (NOLOCK) ON AR.CITY_CODE=CITY.CITY_CODE  
  JOIN custdym LMV (NOLOCK) ON LMV.customer_code=IM.CUSTOMER_CODE
  LEFT JOIN AREA AR_CUST (NOLOCK) ON AR_CUST.AREA_CODE=lmv.AREA_CODE  
  LEFT JOIN CITY CITY_CUST (NOLOCK) ON AR_CUST.CITY_CODE=CITY_CUST.CITY_CODE  
--  JOIN LMV01106 LMV (NOLOCK) ON LMV.AC_CODE=AMST.AC_CODE  
  JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=ID.PRODUCT_CODE  
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE  
  JOIN UOM (NOLOCK) ON ARTICLE.uom_code=UOM.uom_code  
  LEFT JOIN #TMPPARCEL PRCL (NOLOCK) ON PRCL.REF_MEMO_ID =IM.cm_id  
  WHERE IM.cm_id = @INV_ID  
  AND IM.CANCELLED=0   
  GROUP BY  IM.cm_no ,CONVERT(VARCHAR,IM.cm_dt,103),l.loc_gst_no,   
  CASE WHEN ISNULL(L.DEPT_PRINT_NAME,'')<>'' THEN L.DEPT_PRINT_NAME ELSE L.DEPT_NAME END,    
  l.ADDRESS1 ,l.ADDRESS2 ,CITY.CITY ,ar.pincode ,cast(left(l.loc_gst_no,2) as VARCHAR(4)),    
  ISNULL(LMV.CUS_GST_NO,'') ,  
  LTRIM(RTRIM(ISNULL(LMV.customer_fname,'') + ' '+ISNULL(LMV.customer_lname,''))) ,  
  ISNULL(LMV.ADDRESS0,''),    
  ISNULL(LMV.ADDRESS1,'')+ISNULL(' '+LMV.ADDRESS2,'') ,CITY_CUST.CITY   ,AR_CUST.PINCODE,   
  ( CASE WHEN ISNULL(LEFT(LMV.cus_gst_no,2),'')='' THEN LMV.cus_gst_state_code ELSE   LEFT(LMV.CUS_GST_NO,2) END ) ,  
  (CASE WHEN ISNULL(LEFT(LMV.cus_GST_NO,2),'')='' THEN LMV.cus_gst_state_code ELSE   LEFT(LMV.CUS_GST_NO,2) END ) ,   
   ID.hsn_code,ID.hsn_code ,ID.hsn_code ,
  CASE WHEN ISNULL(UOM.GST_UOM_NAME,'')<>'' THEN LEFT(UOM.GST_UOM_NAME,3) ELSE UOM.UOM_NAME END,    
  replace(cast(CASE WHEN ISNULL(cgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') ,  
  replace(cast(CASE WHEN ISNULL(sgst_amount,0)>0 THEN ID.gst_percentage/2 ELSE 0 END as numeric(10,2)),'.00','') ,  
  replace(cast(CASE WHEN ISNULL(igst_amount,0)>0 THEN ID.gst_percentage ELSE 0 END as numeric(10,2)),'.00','') ,  
  PRCL.Ac_gst_no ,PRCL.Angadia_name ,
 (CASE WHEN  ISNULL(PRCL.VEHICLE_NO,'')='' THEN '' 
        ELSE  (CASE WHEN ISNULL(PRCL.BILTY_NO,'')<>'' THEN  BILTY_NO ELSE  PRCL.PARCEL_MEMO_NO END )   END) ,  
 (CASE WHEN ISNULL(ar.pincode,'')=ISNULL(AR_CUST.pincode,'') THEN 20 ELSE 0 END )   ,
  case when ISNULL(PRCL.vehicle_no,'')='' then '' else CONVERT(VARCHAR,PRCL.parcel_memo_dt,103) end ,  
  case when ISNULL(PRCL.vehicle_no,'')='' then '' else PRCL.vehicle_no end ,  
  case when ISNULL(PRCL.vehicle_no,'')='' then '' else 'R' end     
  
 
 GOTO END_PROC 
 
   
END_PROC:  
  
  
END  
  



