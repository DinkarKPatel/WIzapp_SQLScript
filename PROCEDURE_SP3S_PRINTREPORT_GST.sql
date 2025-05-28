CREATE PROCEDURE SP3S_PRINTREPORT_GST              
(                        
  @CXN_TYPE VARCHAR(10)=''                        
  ,@CXN_ID VARCHAR(100)=''                        
  --16 AUG 2017 - BOX NO FILTER                        
  ,@BOX_NO VARCHAR(1000)=''                        
  --16 AUG 2017 - BOX NO FILTER                        
  ,@NMODE INT=0                      
)                        
AS                        
BEGIN              

 
              
 --IF EXISTS(SELECT TOP 1 'U' FROM SYS.procedures WHERE name='SP3S_PRINTREPORT_GST_CUSTOM')                  
 -- BEGIN                  
 --     EXEC SP3S_PRINTREPORT_GST_CUSTOM  @CXN_TYPE,@CXN_ID,@BOX_NO ,@NMODE                 
 --     RETURN                  
 -- END           
 --CHANGES MADE BY CHANDAN ON 16-07-2019 FOR TOTAL_PACKSLIP_NO,TOTAL_BOX_NO AND BILL OF SUPPLY IN SPECIAL GST CONDITION      
                       
SET NOCOUNT ON                             
--INSERT GST_REPORT_CONFIG(XN_TYPE,REPORT_NAME,[FILE_NAME],DEFAULT1,LBL,PRINTER_NAME)                      
--SELECT 'WSL','LASER/INKJET-A4-PORTRAIT-1 LINE PER ITEM (CROSSTAB)','GSTWSLA4P1SCGSTCROSS.RDLC',0,NULL,NULL                      
DECLARE @DTSQL VARCHAR(MAX),@CCOLNAME VARCHAR(MAX),@CERRMSG VARCHAR(1000),@NCALQTYSUM NUMERIC(10,3),                        
        @NSTOREDQTY NUMERIC(10,3),@CSTEP VARCHAR(10),@SET_BOX BIT=0                        
       ,@SNO BIT,@MRP_TOTAL VARCHAR(1000),@SHOW_MRP BIT=0 ,@UOM_WISE_TOTAL VARCHAR(1000),@GROUP_BOX BIT=0                           
       ,@REC INT  ,@cLocId varchar(5)            
              
SELECT TOP 1 E2.EMP_NAME INTO #EMP              
FROM              
(              
 SELECT DISTINCT EMP_CODE FROM INM01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
 UNION              
 SELECT DISTINCT EMP_CODE FROM IND01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
 UNION              
 SELECT DISTINCT EMP_CODE1 FROM IND01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
 UNION              
 SELECT DISTINCT EMP_CODE2 FROM IND01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
)E1              
JOIN EMPLOYEE E2 (NOLOCK) ON E1.emp_code=E2.EMP_CODE               
DELETE #EMP WHERE LTRIM(RTRIM(EMP_NAME))=''              
SELECT @REC=COUNT(*) FROM #EMP              
              
DECLARE @SALESMAN VARCHAR(1000)=''                    
IF @REC>0              
SELECT @SALESMAN=COALESCE(@SALESMAN,'')+E2.EMP_NAME+','               
FROM              
(SELECT DISTINCT EMP_CODE FROM INM01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
 UNION              
 SELECT DISTINCT EMP_CODE FROM IND01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
 UNION              
 SELECT DISTINCT EMP_CODE1 FROM IND01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
 UNION              
 SELECT DISTINCT EMP_CODE2 FROM IND01106 (NOLOCK) WHERE INV_ID=@cXn_Id              
)E1              
JOIN EMPLOYEE E2 (NOLOCK) ON E1.emp_code=E2.EMP_CODE              
WHERE ISNULL(E2.EMP_NAME,'')<>''              
              
SET @SALESMAN=RTRIM(ISNULL(@SALESMAN,''))              
IF @SALESMAN<>'' SET @SALESMAN=LEFT(@SALESMAN,LEN(@SALESMAN)-1)              
              
SELECT TOP 1 @GROUP_BOX=PRINT_WSL_BOX_NO FROM GST_COMPANY_CONFIG WHERE XN_TYPE='WSL'              

SELECT TOP 1 @cLocId =location_code FROM INM01106 (NOLOCK) WHERE INV_ID=@cXn_Id                 
            
	
--SET @SET_BOX=CASE @BOX_NO WHEN '' THEN 1 ELSE 0 END              
SET @GROUP_BOX=ISNULL(@GROUP_BOX,0)                       
                    
IF @BOX_NO='' AND @GROUP_BOX=1              
   BEGIN                
     SELECT @BOX_NO=COALESCE(@BOX_NO,'')+CAST(BOX_NO AS VARCHAR)+','                    
     FROM (SELECT DISTINCT BOX_NO FROM IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID)T                    
     SET @BOX_NO=LTRIM(RTRIM(@BOX_NO))                    
     IF RIGHT(@BOX_NO,1)=',' SET @BOX_NO=LEFT(@BOX_NO,LEN(@BOX_NO)-1)                    
     IF @BOX_NO<>'' SET @BOX_NO='IN ('+@BOX_NO+')'                    
   END                
PRINT @BOX_NO   
SET @SNO=0                        
IF EXISTS(SELECT * FROM GST_XN_DETAIL (NOLOCK) WHERE DISPLAYNAME='BARCODE' AND XN_TYPE='WSL' AND ISVISIBLE=1)                        
   SET @SNO=1                        
                           
SET @CERRMSG=''                        
SET @CSTEP=100       
BEGIN TRY                        
                                
 IF @CXN_TYPE='WSL'                        
    BEGIN                               
  SET @CSTEP=101                           
  IF OBJECT_ID ('TEMPDB..#TRANSPORTER','U') IS NOT NULL                        
     DROP TABLE #TRANSPORTER                        
                         
   SELECT @UOM_WISE_TOTAL=COALESCE(@UOM_WISE_TOTAL,'')+A                      
   FROM                      
   (                      
  SELECT CAST(SUM(I.QUANTITY) AS VARCHAR)+' '+U.UOM_NAME+',' A                      
  FROM IND01106 I(NOLOCK)                      
  JOIN SKU S (NOLOCK) ON I.PRODUCT_CODE=S.PRODUCT_CODE                      
  JOIN ARTICLE A (NOLOCK) ON A.ARTICLE_CODE=S.ARTICLE_CODE                      
  JOIN UOM U (NOLOCK) ON U.UOM_CODE=A.UOM_CODE                      
  WHERE INV_ID=@CXN_ID GROUP BY U.UOM_NAME                      
   )T               
   SET @UOM_WISE_TOTAL=RTRIM(@UOM_WISE_TOTAL)                      
   IF RIGHT(@UOM_WISE_TOTAL,1)=',' SET @UOM_WISE_TOTAL=LEFT(@UOM_WISE_TOTAL,LEN(@UOM_WISE_TOTAL)-1)                      
   SET @UOM_WISE_TOTAL=REPLACE(REPLACE(REPLACE(@UOM_WISE_TOTAL,'.000',''),'.00',''),'.0000','')                
                 
                 
   SELECT A.PARCEL_MEMO_ID,                        
   ANGM.ANGADIA_NAME AS TRANSPORTER_NAME,                        
   A.BILTY_NO AS BILTY_NO,                        
    CAST(A.RECEIPT_DT AS DATE) AS BILTY_DATE,                        
    SUM(B.BOX_NO) AS BOX_NO,                        
    SUM(QTY) AS WGHT,                       
    B.REF_MEMO_ID AS XN_ID,                        
    A.VEHICLE_NO ,
    CAST(A.Driver_name AS VARCHAR) AS DRIVER_NAME,
    CAST(A.REMARKS AS VARCHAR) AS TR_REMARKS,
    CAST(B.goods_desc AS VARCHAR) AS TR_DESC,
    CAST(B.REMARKS AS VARCHAR) AS TR_REMARKS1,
    CAST(A.TOT_QTY AS VARCHAR) AS DISP_WEIGHT,
    CAST(A.TOT_BOXES AS VARCHAR)AS  DISP_BOX_NO                       
   INTO #TRANSPORTER                        
   FROM PARCEL_MST A (NOLOCK)                        
   JOIN PARCEL_DET B (NOLOCK) ON A.PARCEL_MEMO_ID =B.PARCEL_MEMO_ID                                   
   LEFT OUTER JOIN ANGM (NOLOCK) ON ANGM.ANGADIA_CODE =A.ANGADIA_CODE                         
   WHERE A.XN_TYPE ='WSL' AND B.REF_MEMO_ID=@CXN_ID  and a.cancelled =0                      
   GROUP BY ANGM.ANGADIA_NAME ,A.PARCEL_MEMO_ID ,A.BILTY_NO ,B.REF_MEMO_ID,A.VEHICLE_NO,A.RECEIPT_DT ,A.TOT_QTY,A.TOT_BOXES,
   A.Driver_name,A.REMARKS ,B.goods_desc,B.REMARKS                    
                            
   ;WITH CTE AS                         
   (                        
     SELECT PARCEL_MEMO_ID,SR=ROW_NUMBER () OVER (ORDER BY PARCEL_MEMO_ID)                         
     FROM #TRANSPORTER                        
   )                        
                           
   DELETE FROM CTE WHERE SR>1    
   
   DECLARE @NPICKINGSHIPPINGADDRESS INT
   
--1 FOR  INM  SHIPPING AC_CODE DETAILS 2.INM SHPING ADDRESS STORED IN INM 3 FOR PARTY ADDRESS

 SELECT @NPICKINGSHIPPINGADDRESS=
      CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0 
	       THEN CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN 1 ELSE 2 END 
		   ELSE 3 END  
 FROM INM01106  WHERE INV_ID=@CXN_ID
 


                       
                           
   IF OBJECT_ID('TEMPDB..#DATASET1') IS NOT NULL                        
      DROP TABLE #DATASET1                        
                               
   SELECT @MRP_TOTAL='MRP TOTAL: '+CAST(CAST(SUM(MRP*QUANTITY) AS DECIMAL(18,2))AS VARCHAR)                        
   FROM IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID                        
                           
   SELECT top 1 l.Dept_Print_Name  as  COMPANY_NAME,l.ADDRESS1,l.ADDRESS2,slct.CITY                        
                  ,PHONES_FAX=CASE LEN(ISNULL(l.phone ,'')) WHEN 0 THEN '' ELSE 'TEL: '+l.phone END                        
                  ,TIN_NO=CASE LEN(ISNULL(l.TIN_NO,'')) WHEN 0 THEN '' ELSE 'TIN: '+l.TIN_NO END                    
                  ,TAN_NO=CASE LEN(ISNULL(l.TAN_NO,'')) WHEN 0 THEN '' ELSE 'TAN: '+l.TAN_NO END   
				                        
                  ,CIN=CASE LEN(ISNULL(CMP.CIN,'')) WHEN 0 THEN '' ELSE 'CIN: '+CMP.CIN END    
				                      
   ,CMP.LOGO_PATH                        
   ,LOC_GST_NO=CASE LEN(ISNULL(L.LOC_GST_NO,'')) WHEN 0 THEN '' ELSE 'GSTIN: '+L.LOC_GST_NO END                         
   ,CAST(0 AS NUMERIC(10,2)) AS REVERSE_CHARGES,                        
   CASE WHEN INM.INV_MODE=2 AND L.LOC_GST_NO=TL.LOC_GST_NO THEN 'CHALLAN NO: '                         
           ELSE 'INV NO: 'END+INM.INV_NO AS INV_NO,                       
   CASE WHEN INM.INV_MODE=2 AND L.LOC_GST_NO=TL.LOC_GST_NO THEN 'CHALLAN DT: '                         
           ELSE 'INV DT: 'END+CONVERT(VARCHAR,INM.INV_DT,105) AS INV_DT,                        
   ISNULL(LS.GST_STATE_NAME,'') AS LOC_GST_STATE_NAME,                        
      LS.GST_STATE_CODE AS LOC_GST_STATE_CODE,                        
      'RECEIVER:- '+CASE WHEN INV_MODE=1 THEN LM.AC_NAME ELSE TL.DEPT_NAME END                         
      +CASE ISNULL(COM.IS_PARTY_ALIAS,0) WHEN 0 THEN ''          
              ELSE CASE WHEN INV_MODE=1 THEN ISNULL('-'+LM.ALIAS,'') ELSE ISNULL('-'+TL.DEPT_ALIAS,'') END                  
             END                        
      AS PARTY_NAME,                        
                              
      L.LOC_GST_NO AS LOCGST_NO,--12 MAR 2018                        
      --TL.LOC_GST_NO AS PARTYGST_NO,--12 MAR 2018                        
      PCOUNTRY.AC_GST_NO AS PARTYGST_NO, --16 MAR 2018                      
      L.REGISTERED_GST AS REGISTERED_GST,--12 MAR 2018                        
                              
      CASE WHEN INV_MODE=1                        
           THEN CASE LEN(ISNULL(LMP.ADDRESS0,'')) WHEN 0 THEN '' ELSE RTRIM(LTRIM(ISNULL(LMP.ADDRESS0,''))) END                        
           ELSE CASE LEN(ISNULL(TL.ADDRESS1,'')) WHEN 0 THEN '' ELSE RTRIM(LTRIM(TL.ADDRESS1)) END                        
      END                        
      AS PARTY_ADDRESS1,                        
                              
      CASE WHEN INV_MODE=1                        
           THEN CASE LEN(ISNULL(LMP.ADDRESS1,'')) WHEN 0 THEN '' ELSE RTRIM(LTRIM(ISNULL(LMP.ADDRESS1,''))) END                        
           ELSE CASE LEN(ISNULL(TL.ADDRESS2,'')) WHEN 0 THEN '' ELSE RTRIM(LTRIM(TL.ADDRESS2)) END                        
      END                        
      AS PARTY_ADDRESS2,                        
                        
      CASE WHEN INV_MODE=1                        
           THEN CASE LEN(ISNULL(LMP.ADDRESS2,'')) WHEN 0 THEN '' ELSE RTRIM(LTRIM(ISNULL(LMP.ADDRESS2,''))) END                        
           ELSE ''--CASE LEN(ISNULL(TL.ADDRESS1,'')) WHEN 0 THEN '' ELSE 'RECEIVER: '+RTRIM(LTRIM(TL.ADDRESS1))                        
      END                        
      AS PARTY_ADDRESS3,                        
                                    
      CASE WHEN INV_MODE=1                        
           THEN RTRIM(LTRIM(CASE RIGHT(RTRIM(ISNULL(CUSAR.AREA_NAME,'')),1) WHEN ',' THEN LEFT(ISNULL(CUSAR.AREA_NAME,''),LEN(ISNULL(CUSAR.AREA_NAME,''))-1) ELSE ISNULL(CUSAR.AREA_NAME,'')END+CASE LEN(ISNULL(CUSCT.CITY,'')) WHEN 0 THEN '' ELSE ', ' END+ISNULL(CUSCT.CITY,'')+CASE LEN(ISNULL(CUSAR.PINCODE,'')) WHEN 0 THEN '' ELSE ', ' END+CUSAR.PINCODE))                        
           ELSE RTRIM(LTRIM(ISNULL(TLAR.AREA_NAME,'')+CASE LEN(ISNULL(TLCT.CITY,'')) WHEN 0 THEN '' ELSE ', ' END+ISNULL(TLCT.CITY,'')+CASE LEN(ISNULL(TLAR.PINCODE,''))  WHEN 0 THEN '' ELSE ', ' END+TLAR.PINCODE))                        
      END                        
      +CASE WHEN ISNULL(LMP.PHONES_O,'')<> '' THEN ' PHONE- '+ISNULL(LMP.PHONES_O,'')                        
            ELSE CASE WHEN ISNULL(LMP.PHONES_R,'')<> '' THEN ' PHONE- '+ISNULL(LMP.PHONES_R,'')                        
                      ELSE CASE WHEN ISNULL(LMP.MOBILE,'')<> '' THEN ' MOBILE- '+ISNULL(LMP.MOBILE,'') ELSE '' END                        
                 END                        
    END               
    --CASE ISNULL(' '+LMP.MOBILE,'') WHEN '' THEN '' ELSE ' PHONE- '+LMP.MOBILE END                        
AS PARTY_CITY                        
    --31 JUL 2017                        
                              
    ,CASE WHEN INV_MODE=1 THEN LMP.AC_GST_NO ELSE TL.LOC_GST_NO END AS PARTY_GST_NO,                        
                              
     --01 MAY 2018                        
      --ISNULL(CASE WHEN INV_MODE=1 THEN CS.GST_STATE_NAME ELSE TS.GST_STATE_NAME END,'') AS PARTY_STATE_NAME,                        
      'PLACE OF SUPPLY: '+ISNULL(CASE WHEN INV_MODE=1 THEN CS.GST_STATE_CODE ELSE TS.GST_STATE_CODE END,'')+' - '+ISNULL(CASE WHEN INV_MODE=1 THEN CS.GST_STATE_NAME ELSE TS.GST_STATE_NAME END,'') AS PARTY_STATE_NAME,                        
      --01 MAY 2018                        
                              
      ISNULL(CASE WHEN INV_MODE=1 THEN CS.GST_STATE_CODE ELSE TS.GST_STATE_CODE END,'') AS PARTY_STATE_CODE,                        
      ISNULL(TR.TRANSPORTER_NAME,'') AS TRANSPORTER_NAME,                        
      ISNULL(TR.BILTY_NO,'') AS BILTY_NO,                        
       ISNULL(TR.BILTY_DATE,'') AS BILTY_DATE,                        
      ISNULL(inm.TOTAL_BOX_NO ,0) AS BOX_NO,         
      --CASE LEN(ISNULL(@BOX_NO,'')) WHEN 0 THEN 0 ELSE 1 END                             
      ISNULL(WGHT,0) AS WGHT,
      ISNULL(TR.DRIVER_NAME,'') AS DRIVER_NAME,                        
      ISNULL(TR.TR_REMARKS,'') AS TR_REMARKS,                        
      ISNULL(TR.TR_DESC,'') AS TR_DESC,                        
      ISNULL(TR.TR_REMARKS1,'') AS TR_REMARKS1,                        
      ISNULL(TR.VEHICLE_NO,'') AS VEHICLE_NO,     
      ISNULL(TR.DISP_BOX_NO,'') AS DISP_BOX_NO,
      ISNULL(TR.DISP_WEIGHT,'') AS DISP_WEIGHT,
                         
      CASE WHEN INM.CANCELLED =1 THEN 'CANCELLED' ELSE '' END AS CANCELLED,                        
                         
      --CASE WHEN INM.INV_MODE=2 AND L.LOC_GST_NO=TL.LOC_GST_NO THEN 'DELIVERY CHALLAN'                         
      --     WHEN INM.INV_MODE=2 AND L.LOC_GST_NO!=TL.LOC_GST_NO AND TL.REGISTERED_GST=2 THEN 'BILL OF SUPPLY' --12 MAR 2018                        
      --     ELSE 'TAX INVOICE'                         
      --END AS INVOICE_TYPE,  
      --A.TOT_QTY AS DISP_BOX_NO,
      --A.TOT_BOXES AS DISP_WEIGHT,                        
                              
   CASE --LOCATION UNREGISTERED                        
        WHEN ISNULL(L.REGISTERED_GST,0)=0 THEN 'BILL OF SUPPLY'                        
        --LOCATION COMPOSITE                        
        WHEN L.REGISTERED_GST=2 /*AND L.LOC_GST_NO!=PCOUNTRY.AC_GST_NO*/ THEN 'BILL OF SUPPLY'                        
        --LOCATION REGISTERED                        
        WHEN L.REGISTERED_GST=1 AND L.LOC_GST_NO=PCOUNTRY.AC_GST_NO THEN 'DELIVERY CHALLAN'                        
        WHEN L.REGISTERED_GST=1 AND L.LOC_GST_NO!=PCOUNTRY.AC_GST_NO AND ISNULL(LCOUNTRY.COUNTRY_NAME,'') <> ISNULL(PCOUNTRY.COUNTRY_NAME,'')  THEN 'BILL OF SUPPLY'                        
        WHEN L.REGISTERED_GST=1 AND L.LOC_GST_NO!=PCOUNTRY.AC_GST_NO AND ISNULL(LCOUNTRY.COUNTRY_NAME,'') =  ISNULL(PCOUNTRY.COUNTRY_NAME,'')  THEN 'TAX INVOICE'       
        WHEN L.loc_type=2  OR (L.LOC_GST_NO!=PCOUNTRY.AC_GST_NO AND ISNULL(LCOUNTRY.AC_GST_NO,'')=ISNULL(LCOUNTRY.AC_GST_NO,''))  THEN 'TAX INVOICE' --FOR MEENA BAZAR ON 07-08-2019                        
        WHEN INM.INV_MODE=2 AND L.LOC_GST_NO=PCOUNTRY.AC_GST_NO THEN 'DELIVERY CHALLAN'                        
        ELSE '' 
      END AS INVOICE_TYPE,                        
                              
      ISNULL(LS.UT,0) AS UT,                        
      (SELECT TOP 1 ISNULL(IS_ENABLED,0) FROM GST_TNC WHERE XN_TYPE=@CXN_TYPE) AS PRINT_TERM,                        
      --31 JUL 2017   
	  CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS0  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN INM.SHIPPING_ADDRESS 
		   ELSE LMP.ADDRESS0 END SHIPPING_ADDRESS,

	    CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS1  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN INM.SHIPPING_ADDRESS2 
		   ELSE LMP.ADDRESS1 END SHIPPING_ADDRESS2,

	     CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS2  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN INM.SHIPPING_ADDRESS3 
		   ELSE LMP.ADDRESS2 END SHIPPING_ADDRESS3,
        
		  CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.AREA_CODE 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN INM.SHIPPING_AREA_CODE 
		   ELSE LMP.AREA_CODE END SHIPPING_AREA_CODE,

           CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.AREA_NAME  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN INM.SHIPPING_AREA_NAME 
		   ELSE CUSAR.AREA_NAME  END SHIPPING_AREA_NAME,

		   CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHCT.CITY  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN INM.SHIPPING_CITY_NAME 
		   ELSE CUSCT.CITY  END SHIPPING_CITY_NAME,

		   'PLACE OF SUPPLY '+ CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN ISNULL('('+shCS.GST_STATE_CODE+')','')+ISNULL(' '+shCS.gst_state_name,'') 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL('('+SHP.GST_STATE_CODE+')','')+ISNULL(' '+INM.SHIPPING_STATE_NAME,'')
		   ELSE ISNULL('('+cs.GST_STATE_CODE+')','')+ISNULL(' '+cs.gst_state_name,'') END SHIPPING_STATE_NAME,

		  
           CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.pincode   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(INM.SHIPPING_PIN,'') 
		   ELSE CUSAR.pincode   END SHIPPING_PIN

                
      --CASE ISNULL(INM.SHIPPING_ADDRESS,'') WHEN '' THEN '' ELSE 'SHIP TO:- '+ISNULL(INM.SHIPPING_ADDRESS,'') END AS SHIPPING_ADDRESS,                        
      ----31 JUL 2017                        
      --ISNULL(INM.SHIPPING_ADDRESS2,'') AS SHIPPING_ADDRESS2,                        
      --ISNULL(INM.SHIPPING_ADDRESS3,'') AS SHIPPING_ADDRESS3,                        
      --ISNULL(INM.SHIPPING_AREA_CODE,'') AS SHIPPING_AREA_CODE,                        
      --ISNULL(INM.SHIPPING_AREA_NAME,'') AS SHIPPING_AREA_NAME  ,                        
      --ISNULL(INM.SHIPPING_CITY_NAME,'') AS SHIPPING_CITY_NAME,                        
      --'PLACE OF SUPPLY '+ISNULL('('+SHP.GST_STATE_CODE+')','')+ISNULL(' '+INM.SHIPPING_STATE_NAME,'') AS SHIPPING_STATE_NAME,                        
      --ISNULL(INM.SHIPPING_PIN,'') AS SHIPPING_PIN      
	                    
      --,(SELECT TOP 1 ISNULL(REGISTERED_ADD,'') FROM LOCATION L (NOLOCK) WHERE DEPT_ID=LEFT(@CXN_ID,2))REGISTERED_ADDRESS               
      ,ISNULL(L.REGISTERED_ADD,'')REGISTERED_ADDRESS                        
      ,ISNULL(INM.REMARKS,'')REMARKS                        
      ,BUYER_ORDER_NO=CASE ISNULL(BUYER_ORDER_NO,'') WHEN '' THEN '' ELSE 'P.O.NO: '+BUYER_ORDER_NO END                        
      --,BUYER_ORDER_NO=CASE ISNULL(REF_INV_ID,'') WHEN '' THEN '' ELSE 'P.O.NO: '+REF_INV_ID END                        
                 
      --14 JUL 2017                        
      ,COM.LOGO AS LOGO                        
      ,COM.NAME AS NAME                        
      ,COM.ADDRESS1 AS PRINT_ADDRESS1                        
      ,COM.TELEPHONE1 AS TELEPHONE1                        
      ,COM.CIN_NO AS CIN_NO                        
      ,COM.DATE_WITH_TIME AS DATE_WITH_TIME                        
      ,COM.PRINT_WSL_MRP AS PRINT_WSL_MRP                        
      ,COM.PRINT_BROKER_NAME AS PRINT_BROKER_NAME       
                       
        
      --15 JUL 2017                        
      ,ISNULL((SELECT SUM(XN_VALUE_WITHOUT_GST) FROM IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID),0)                        
       +ISNULL(INM.FREIGHT,0)+ISNULL(INM.INSURANCE,0)+ISNULL(INM.PACKING,0)+ISNULL(INM.OTHER_CHARGES,0)                        
       AS [TAXABLEVALUE]                        
      ,ISNULL((SELECT SUM(CGST_AMOUNT) FROM IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID),0)                        
       +ISNULL(INM.OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(INM.FREIGHT_CGST_AMOUNT,0)+ISNULL(INM.INSURANCE_CGST_AMOUNT,0)+ISNULL(INM.PACKING_CGST_AMOUNT,0)                        
       AS [CGSTAMOUNT]                         
                                           
      ,ISNULL((SELECT SUM(SGST_AMOUNT) FROM IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID),0)                        
       +ISNULL(INM.OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(INM.FREIGHT_SGST_AMOUNT,0)+ISNULL(INM.INSURANCE_SGST_AMOUNT,0)+ISNULL(INM.PACKING_SGST_AMOUNT,0)                        
       AS [SGSTAMOUNT]                        
                                           
      ,ISNULL((SELECT SUM(IGST_AMOUNT) FROM IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID),0)                        
       +ISNULL(INM.OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(INM.FREIGHT_IGST_AMOUNT,0)+ISNULL(INM.INSURANCE_IGST_AMOUNT,0)+ISNULL(INM.PACKING_IGST_AMOUNT,0)                        
       AS [IGSTAMOUNT]                                                           
      ,ISNULL(INM.FREIGHT,0) AS FREIGHT                        
      ,ISNULL(INM.INSURANCE,0) AS INSURANCE_AMOUNT                        
      ,ISNULL(INM.PACKING,0) AS PACKING                        
      ,ISNULL(INM.OTHER_CHARGES,0) AS OTHER_CHARGE                        
      ,ISNULL(INM.NET_AMOUNT,0) AS NETAMOUNT                        
      ,ISNULL(INM.ROUND_OFF,0) AS ROUND_OFF                        
      ,ISNULL((SELECT SUM(CGST_AMOUNT+SGST_AMOUNT+IGST_AMOUNT) FROM IND01106(NOLOCK) WHERE INV_ID=@CXN_ID),0)                        
      +ISNULL(INM.OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(INM.FREIGHT_CGST_AMOUNT,0)+ISNULL(INM.INSURANCE_CGST_AMOUNT,0)+ISNULL(INM.PACKING_CGST_AMOUNT,0)                        
      +ISNULL(INM.OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(INM.FREIGHT_SGST_AMOUNT,0)+ISNULL(INM.INSURANCE_SGST_AMOUNT,0)+ISNULL(INM.PACKING_SGST_AMOUNT,0)                        
      +ISNULL(INM.OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(INM.FREIGHT_IGST_AMOUNT,0)+ISNULL(INM.INSURANCE_IGST_AMOUNT,0)+ISNULL(INM.PACKING_IGST_AMOUNT,0)      
      AS [GSTCOLLECTION]                        
      --25 JUL 2017                        
      ,(SELECT TOP 1 PHONES_O   FROM LMV01106 LMV (NOLOCK) WHERE LMV.AC_CODE=INM.AC_CODE)LANDLINE_OFFICE                        
      ,(SELECT TOP 1 PHONES_R   FROM LMV01106 LMV (NOLOCK) WHERE LMV.AC_CODE=INM.AC_CODE)LANDLINE_RES                        
      ,(SELECT TOP 1 PHONES_FAX FROM LMV01106 LMV (NOLOCK) WHERE LMV.AC_CODE=INM.AC_CODE)FAX                        
      ,(SELECT TOP 1 MOBILE     FROM LMV01106 LMV (NOLOCK) WHERE LMV.AC_CODE=INM.AC_CODE)MOBILE                        
     --01 AUG 2017                        
       --12 APR 2018                        
       --,ROUTE_FORM1 AS R0                        
       ,ISNULL(ROUTE_FORM1,'')+CASE ISNULL(ROUTE_FORM2,'') WHEN '' THEN '' ELSE ','+ROUTE_FORM2 END AS ROUTE_FORM1                        
       --12 APR 2018                        
      ,ROUTE_FORM2                        
     --10 AUG 2017                        
      ,CASE ISNULL(BN.AC_NAME,'') WHEN '' THEN '' ELSE 'BROKER NAME: '+ISNULL(BN.AC_NAME,'') END AS BROKER_NAME         
     --22 AUG 2017                        
      ,ISNULL(COM.PRINT_REF_NO,0) AS PRINT_REF_NO                        
      ,CASE ISNULL(INM.MANUAL_INV_NO,'') WHEN '' THEN '' ELSE 'REF NO: '+INM.MANUAL_INV_NO END AS REF_NO                        
      ,@MRP_TOTAL AS TOTAL_MRP                        
      ,COMPANY_PAN_NO=CASE LTRIM(RTRIM(ISNULL(l.PAN_NO,''))) WHEN '' THEN '' ELSE 'PAN: '+LTRIM(RTRIM(ISNULL(l.PAN_NO,''))) END                        
              
     --10 NOV 2017                 
     ,COM.PRINT_WSL_ITEM_MRP AS PRINT_WSL_ITEM_MRP                        
      ,COM.PRINT_WSL_ITEM_DISPER AS PRINT_WSL_ITEM_DISPER                        
      ,COM.PRINT_WSL_ITEM_DISAMT AS PRINT_WSL_ITEM_DISAMT                        
                              
							  
     --01 FEB 2018                        
      ,ISNULL((SELECT TOP 1 PRINT_COPIES FROM GST_SLS_CUSTOMER_CONFIG (NOLOCK) WHERE XN_TYPE='WSL'),1)AS PRINT_COPIES                        
     --03 FEB 2018                        
     ,ISNULL(COM.PRINT_AUTHORIZED_SIGNATURE,0) AS PRINT_AUTHORIZED_SIGNATURE                          
                 --06 FEB 2018                        
     ,ISNULL(COM.TOP_MARGIN,0.01) AS TOP_MARGIN                        
     ,ISNULL(COM.BOTTOM_MARGIN,0.25) AS BOTTOM_MARGIN                        
     ,ISNULL(COM.LEFT_MARGIN,0.30) AS LEFT_MARGIN                        
     ,ISNULL(COM.RIGHT_MARGIN,0.25) AS RIGHT_MARGIN                        
     ,ISNULL(COM.MRP,0)AS PRINT_WSL_SHOW_MRP                        
     --23 FEB 2017                        
     ,ISNULL(COM.PRINT_WSL_BOX_NO,0)AS PRINT_WSL_BOX_NO                        
     --16 MAR 2018                        
     ,'COUNTRY: '+ISNULL(PCOUNTRY.COUNTRY_NAME,'') PARTY_COUNTRY                             
     ,ISNULL(LCOUNTRY.COUNTRY_NAME,'') AS LOC_COUNTRY                        
     --05 APR 2018                        
     ,ISNULL(COM.PRINT_HSN_SUMMARY,0) AS PRINT_HSN_SUMMARY                        
     --09 APR 2018                        
     ,CAST(CASE ISNULL(INM.OTHER_CHARGES,0)+ISNULL(INM.FREIGHT,0) WHEN 0 THEN 0 ELSE 1 END AS BIT)AS PRINT_OH                        
     --12 APR 2018                        
     ,ISNULL(COM.PRINT_ITEM_PACKSLIP_NO,0)PRINT_ITEM_PACKSLIP_NO                        
     ,@UOM_WISE_TOTAL TOTAL_UOM              
     --04 Feb 2019              
     ,slar.pincode  AS CMP_PIN
	 ,SLAR.AREA_NAME AS LOCATION_AREA 
     ,slst.[STATE] AS CMP_STATE
     ,INM.TOTAL_BOX_NO AS TOTAL_BOX_NO
     ,INM.TOTAL_PACKSLIP_NO AS  TOTAL_PACKSLIP_NO 
	 ,INM.PARTY_DEPT_ID 

	 ,CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		   ELSE LMP.Ac_gst_no  END SHIPPING_GST_NO,

     CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLM.AC_NAME   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLM.AC_NAME 
		   ELSE LM .AC_NAME   END Shipping_Party_Name,
		   INM.IRN_QR_CODE,INM.EINV_IRN_NO
	,INM.Tcs_Percentage,INM.Tcs_Amount ,INM.AUTO_EWAYBILL_NO,INM.AUTO_EWAYBILL_DT
	,INM.BROKER_COMM_PERCENTAGE, INM.BROKER_COMM_AMOUNT
              
   INTO #DATASET1              
   FROM INM01106 INM (NOLOCK)              
   JOIN GST_COMPANY_CONFIG COM(NOLOCK) ON 1=1 AND XN_TYPE=@CXN_TYPE                        
   LEFT JOIN GST_STATE_MST SHP (NOLOCK) ON ISNULL(SHP.GST_STATE_NAME,'')=ISNULL(INM.SHIPPING_STATE_NAME,'')              
   LEFT JOIN COMPANY CMP (NOLOCK) ON CMP.COMPANY_CODE='01'                        
   LEFT OUTER JOIN LOCATION L (NOLOCK) ON L.DEPT_ID =INM.location_Code                        
   LEFT JOIN LMV01106 LCOUNTRY (NOLOCK) ON L.DEPT_AC_CODE=LCOUNTRY.AC_CODE--16 MAR 2018                        
   LEFT JOIN GST_STATE_MST LS (NOLOCK) ON LS.GST_STATE_CODE=L.GST_STATE_CODE                        
   LEFT JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE=INM.AC_CODE                        
   LEFT JOIN GST_STATE_MST CS (NOLOCK) ON CS.GST_STATE_CODE=LMP.AC_GST_STATE_CODE                        
   LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=LMP.AC_CODE                        
   LEFT JOIN LMV01106 PCOUNTRY (NOLOCK) ON LM.AC_CODE=PCOUNTRY.AC_CODE--16 MAR 2018                        
   LEFT JOIN AREA CUSAR (NOLOCK) ON LMP.AREA_CODE=CUSAR.AREA_CODE                        
   LEFT JOIN CITY CUSCT (NOLOCK) ON CUSAR.CITY_CODE=CUSCT.CITY_CODE                        
   LEFT OUTER JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID=INM.PARTY_DEPT_ID                        
   LEFT JOIN AREA TLAR (NOLOCK) ON TL.AREA_CODE=TLAR.AREA_CODE                        
   LEFT JOIN CITY TLCT (NOLOCK) ON TLAR.CITY_CODE=TLCT.CITY_CODE                        
   LEFT JOIN GST_STATE_MST TS (NOLOCK) ON TS.GST_STATE_CODE=TL.GST_STATE_CODE                        
   LEFT OUTER JOIN #TRANSPORTER TR ON TR.XN_ID=INM.INV_ID                   
   LEFT OUTER JOIN LM01106 BN (NOLOCK) ON INM.BROKER_AC_CODE=BN.AC_CODE      
   --LEFT OUTER JOIN IND01106 IND (NOLOCK) ON INM.INV_ID=IND.INV_ID       
   LEFT JOIN AREA sLAR (NOLOCK) ON sLAR.AREA_CODE=l.AREA_CODE                        
   LEFT JOIN CITY slCT (NOLOCK) ON SLAR.CITY_CODE=slCT.CITY_CODE  
   left join state slst (nolock) on slst.state_code =slct.state_code 
   left join LM01106 shlm (nolock) on shlm.AC_CODE =inm.SHIPPING_AC_CODE 
   left join LMP01106 shlmp (nolock) on shlmp.AC_CODE =shlm.AC_CODE 
   LEFT JOIN AREA shAR (NOLOCK) ON shlmp.AREA_CODE=shAR.AREA_CODE                        
   LEFT JOIN CITY shCT (NOLOCK) ON shAR.CITY_CODE=shCT.CITY_CODE  
   LEFT JOIN GST_STATE_MST shCS (NOLOCK) ON shCS.GST_STATE_CODE=shLMP.AC_GST_STATE_CODE  
   WHERE INM.INV_ID=@CXN_ID       
   
   
            
                        
   UPDATE #DATASET1 SET ADDRESS1=REPLACE(ADDRESS1,'(WC)','')                        
      ,ADDRESS2=REPLACE(ADDRESS2,'(WC)','')                        
      ,CITY=REPLACE(CITY,'(WC)','')                        
      ,PARTY_ADDRESS1=REPLACE(PARTY_ADDRESS1,'(WC)','')                        
      ,PARTY_ADDRESS2=REPLACE(PARTY_ADDRESS2,'(WC)','')                        
      ,PARTY_ADDRESS3=REPLACE(PARTY_ADDRESS3,'(WC)','')                        
      ,PARTY_CITY=REPLACE(PARTY_CITY,'(WC)','')  
	   
	   ,SHIPPING_ADDRESS=REPLACE(SHIPPING_ADDRESS,'(WC)','')
	   ,SHIPPING_ADDRESS2=REPLACE(SHIPPING_ADDRESS2,'(WC)','')   
	   ,SHIPPING_ADDRESS3=REPLACE(SHIPPING_ADDRESS3,'(WC)','')     
	   ,SHIPPING_CITY_NAME=REPLACE(SHIPPING_CITY_NAME,'(WC)','')     


	    UPDATE #DATASET1 SET SHIPPING_ADDRESS =case when ISNULL(SHIPPING_ADDRESS,'')='' then '' ELSE  'SHIP TO:- '+SHIPPING_ADDRESS END 
	
	              
      --CASE ISNULL(INM.SHIPPING_ADDRESS,'') WHEN '' THEN '' ELSE 'SHIP TO:- '+ISNULL(INM.SHIPPING_ADDRESS,'') END AS SHIPPING_ADDRESS,                        
      ----31 JUL 2017                        
      --ISNULL(INM.SHIPPING_ADDRESS2,'') AS SHIPPING_ADDRESS2,                        
      --ISNULL(INM.SHIPPING_ADDRESS3,'') AS SHIPPING_ADDRESS3,                        
      --ISNULL(INM.SHIPPING_AREA_CODE,'') AS SHIPPING_AREA_CODE,                        
      --ISNULL(INM.SHIPPING_AREA_NAME,'') AS SHIPPING_AREA_NAME  ,                        
      --ISNULL(INM.SHIPPING_CITY_NAME,'') AS SHIPPING_CITY_NAME,                        
      --'PLACE OF SUPPLY '+ISNULL('('+SHP.GST_STATE_CODE+')','')+ISNULL(' '+INM.SHIPPING_STATE_NAME,'') AS SHIPPING_STATE_NAME,                        
      --ISNULL(INM.SHIPPING_PIN,'') AS SHIPPING_PIN                        
                              
     -- SELECT * FROM #DATASET1   SHIFTED TO BELOW AFTER CHANGES GST CALCULATION IN PRINT                      
                              
                             
    --04 AUG 2017                        
   SET @CCOLNAME=''                        
   IF NOT EXISTS(SELECT TOP 1 XN_TYPE FROM GST_XN_DETAIL WHERE XN_TYPE ='WSL' AND ISVISIBLE=1)              
      SET @CCOLNAME='LEFT(sku.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',sku.PRODUCT_CODE)-1,-1),LEN(sku.PRODUCT_CODE )))'                        
   ELSE                        
      BEGIN                        
         SELECT @CCOLNAME=ISNULL(@CCOLNAME+'+','  ')+CASE WHEN SOURCENAME='IND01106' AND COLUMNNAME='BOX_NO' THEN 'ISNULL(CAST('+SOURCENAME+'.'+QUOTENAME(COLUMNNAME) +' AS VARCHAR),'''')+'+''''+COLUMNSEPARATOR+'''' ELSE 'ISNULL('+SOURCENAME+'.'+QUOTENAME
 (      
COLUMNNAME) +','''')+'+''''+COLUMNSEPARATOR+'''' END+' '                        
         FROM GST_XN_DETAIL WHERE XN_TYPE ='WSL' AND ISVISIBLE=1                        
         ORDER BY DISPLAYORDER                
                       
        
    IF EXISTS (SELECT TOP 1 'U'  FROM GST_XN_DETAIL WHERE XN_TYPE ='WSL' AND ISVISIBLE=1 AND COLUMNNAME ='PRODUCT_CODE')             
    BEGIN              
     SET @CCOLNAME=REPLACE (@CCOLNAME,'SKU.[PRODUCT_CODE]','LEFT(SKU.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',SKU.[PRODUCT_CODE])-1,-1),LEN(SKU.[PRODUCT_CODE] )))')              
                  
    END     
	
                               
         --04 AUG 2017                        
         SET @CCOLNAME=RTRIM(@CCOLNAME)                        
         IF RIGHT(@CCOLNAME,4)='+'''+(SELECT TOP 1 COLUMNSEPARATOR FROM GST_XN_DETAIL WHERE XN_TYPE ='WSL' AND ISVISIBLE=1)+''''                        
            SET @CCOLNAME=LEFT(@CCOLNAME,LEN(@CCOLNAME)-4)                        
         IF LEFT(@CCOLNAME,1)='+'                        
            SET @CCOLNAME=SUBSTRING(@CCOLNAME,2,LEN(@CCOLNAME)-1)                           
      END   
	  
	--FOR ATTRIBUTE PRINT 
	 DECLARE @CATTR_DISPLAY_FILTER VARCHAR(20)
	 SET @CATTR_DISPLAY_FILTER=' AND 1=2'
	  IF EXISTS (SELECT TOP 1 'U'  FROM GST_XN_DETAIL WHERE XN_TYPE ='WSL' AND ISVISIBLE=1 AND COLUMNNAME IN('PRODUCT_CODE','ARTICLE_NO')) 
	  BEGIN
	        SET @CATTR_DISPLAY_FILTER=' AND 1=1'

	  END                          
                 
   SELECT TOP 1 @SHOW_MRP=ISNULL(MRP,0) FROM GST_COMPANY_CONFIG WHERE XN_TYPE ='WSL'                        
   SET @SHOW_MRP=1                      
   IF OBJECT_ID ('TEMPDB..#TMPDETAILS','U') IS NOT NULL                        
         DROP TABLE #TMPDETAILS                        
   SELECT ROW_NUMBER() OVER (ORDER BY AUTO_SRNO) AS SR_NO,  CAST('' AS VARCHAR(MAX)) AS PARTICULARS ,                      
   CAST('' AS VARCHAR(MAX)) AS IND_REMARKS ,                        
   IND01106.HSN_CODE,UOM.UOM_NAME,                        
   CAST(IND01106.QUANTITY AS NUMERIC(10,2)) AS QUANTITY,                        
   IND01106.RATE,                        
   IND01106.MRP,                        
   CAST(IND01106.QUANTITY*IND01106.RATE AS NUMERIC(12,2)) AS AMOUNT,                        
   CAST((IND01106.QUANTITY*IND01106.RATE )-ISNULL(XN_VALUE_WITHOUT_GST,0) AS NUMERIC(12,2))                         
   AS LESS_DISCOUNT,                        
   CAST((IND01106.QUANTITY*IND01106.RATE )-ISNULL(XN_VALUE_WITHOUT_GST,0) AS NUMERIC(12,2))                         
   AS DISCOUNT_AMOUNT,                        
   CAST(ISNULL(XN_VALUE_WITHOUT_GST,0) AS NUMERIC(12,2)) AS TAXABLE_VALUE,                        
   CAST(CASE WHEN IND01106.IGST_AMOUNT<>0 THEN IND01106.GST_PERCENTAGE ELSE 0 END AS NUMERIC(12,2)) AS IGST_RATE,  --0/2                      
   IND01106.IGST_AMOUNT,                        
   CAST(CASE WHEN IND01106.CGST_AMOUNT<>0 THEN (IND01106.GST_PERCENTAGE)/2 ELSE 0 END AS NUMERIC(12,2)) AS CGST_RATE ,  --1/2                      
   IND01106.CGST_AMOUNT,                        
   CAST(CASE WHEN IND01106.SGST_AMOUNT<>0 THEN (IND01106.GST_PERCENTAGE)/2 ELSE 0 END AS NUMERIC(12,2)) AS SGST_RATE ,  --1/2                      
   IND01106.SGST_AMOUNT,                        
   IND01106.XN_VALUE_WITH_GST AS TOTAL,             
   IND01106.remarks AS REMARKS,       
   INM01106.TOTAL_BOX_NO AS TOTAL_BOX_NO ,      
   INM01106.TOTAL_PACKSLIP_NO AS TOTAL_PACKSLIP_NO,                      
   INM01106.NET_AMOUNT ,INM01106.ROUND_OFF  --MORE CHANGES IN REPORT URGENT REQUIRED FOR UPDATE CHANGES IN MASTER                        
   ,IND01106.BOX_NO AS ITEM_BOX_NO                       
   ,CAST('' AS VARCHAR(100)) AS ITEM_PACKSLIP_NO                        
   ,CAST('' AS VARCHAR(100)) PARA1_NAME 
   ,INM01106.DISCOUNT_PERCENTAGE AS BILL_DISCOUNT_PERCENTAGE
   ,IND01106.INMDISCOUNTAMOUNT AS  BILL_DISCOUNT_AMOUNT  
   ,IND01106.DISCOUNT_PERCENTAGE AS  ITEM_DISCOUNT_PERCENTAGE
   ,IND01106.DISCOUNT_AMOUNT AS  ITEM_DISCOUNT_AMOUNT                        
   ,CAST(0 AS INT)SIZE1,CAST(0 AS INT)SIZE2,CAST(0 AS INT)SIZE3,CAST(0 AS INT)SIZE4,CAST(0 AS INT)SIZE5,CAST(0 AS INT)SIZE6              
   ,CAST(0 AS INT)SIZE7,CAST(0 AS INT)SIZE8,CAST(0 AS INT)SIZE9,CAST(0 AS INT)SIZE10,CAST(0 AS INT)SIZE11,CAST(0 AS INT)SIZE12                      
   ,CAST('' AS VARCHAR(100))ATTR1_KEY_NAME,CAST('' AS VARCHAR(100))ATTR2_KEY_NAME,CAST('' AS VARCHAR(100))ATTR3_KEY_NAME,CAST('' AS VARCHAR(100))ATTR4_KEY_NAME,CAST('' AS VARCHAR(100))ATTR5_KEY_NAME              
   ,CAST('' AS VARCHAR(100))ATTR6_KEY_NAME,CAST('' AS VARCHAR(100))ATTR7_KEY_NAME,CAST('' AS VARCHAR(100))ATTR8_KEY_NAME,CAST('' AS VARCHAR(100))ATTR9_KEY_NAME,CAST('' AS VARCHAR(100))ATTR10_KEY_NAME              
   ,CAST('' AS VARCHAR(100))ATTR11_KEY_NAME,CAST('' AS VARCHAR(100))ATTR12_KEY_NAME,CAST('' AS VARCHAR(100))ATTR13_KEY_NAME,CAST('' AS VARCHAR(100))ATTR14_KEY_NAME,CAST('' AS VARCHAR(100))ATTR15_KEY_NAME              
   ,CAST('' AS VARCHAR(100))ATTR16_KEY_NAME,CAST('' AS VARCHAR(100))ATTR17_KEY_NAME,CAST('' AS VARCHAR(100))ATTR18_KEY_NAME,CAST('' AS VARCHAR(100))ATTR19_KEY_NAME,CAST('' AS VARCHAR(100))ATTR20_KEY_NAME              
   ,CAST('' AS VARCHAR(100))ATTR21_KEY_NAME,CAST('' AS VARCHAR(100))ATTR22_KEY_NAME,CAST('' AS VARCHAR(100))ATTR23_KEY_NAME,CAST('' AS VARCHAR(100))ATTR24_KEY_NAME,CAST('' AS VARCHAR(100))ATTR25_KEY_NAME              
   INTO #TMPDETAILS                                  
   FROM IND01106 (NOLOCK)                        
   JOIN INM01106 (NOLOCK) ON  IND01106.INV_ID=INM01106.INV_ID                        
   LEFT JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =IND01106.PRODUCT_CODE                           
   LEFT JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE =SKU.ARTICLE_CODE                            
   LEFT JOIN UOM UOM (NOLOCK) ON UOM.UOM_CODE=ARTICLE.UOM_CODE                        
   LEFT OUTER JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE                        
   WHERE 1=2                        
   SET @CSTEP=20                         
   IF OBJECT_ID ('TEMPDB..#TMPIND','U') IS NOT NULL                      
      DROP TABLE #TMPIND                      
                               
   SELECT * INTO #TMPIND FROM IND01106 WITH (NOLOCK,INDEX=IND_IND01106_INVID) WHERE INV_ID =@CXN_ID                       
                          
   --CALCULATE GST FOR DELIVERY CHALLAN                       
   DECLARE @GST_CAL_DELIVERY_CHALLAN VARCHAR(5),@NSPID INT,@CDELIVERY_CHALLAN VARCHAR(20),        
            @CPARTYSTATE_CODE VARCHAR(2),@CCURSTATE_CODE VARCHAR(2)                      
    SET @NSPID=@@SPID                       
 SELECT TOP 1 @GST_CAL_DELIVERY_CHALLAN=VALUE FROM CONFIG WHERE CONFIG_OPTION='GST_CAL_DELIVERY_CHALLAN_PRINT'                      
 SELECT @CDELIVERY_CHALLAN=INVOICE_TYPE FROM #DATASET1                      
  set  @CDELIVERY_CHALLAN=0              
                      
 IF ISNULL(@GST_CAL_DELIVERY_CHALLAN,'')='1' AND @CDELIVERY_CHALLAN='DELIVERY CHALLAN'                      
 BEGIN                      
         DELETE FROM GST_TAXINFO_CALC   WHERE SP_ID =RTRIM(LTRIM(STR(@NSPID)))                      
                               
       INSERT GST_TAXINFO_CALC WITH (ROWLOCK) ( PRODUCT_CODE, SP_ID ,NET_VALUE,TAX_METHOD,ROW_ID,QUANTITY,TARGET_DEPT_ID,SOURCE_DEPT_ID,MRP,MEMO_DT )                        
   SELECT LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE ))) as PRODUCT_CODE,@NSPID AS SP_ID,                      
   ROUND(((A.NET_RATE*A.INVOICE_QUANTITY)                      
   -(ISNULL(A.INMDISCOUNTAMOUNT,0) )),2) AS NET_VALUE                      
            ,2 AS TAX_METHOD,                      
   ROW_ID,INVOICE_QUANTITY,B.PARTY_DEPT_ID,B.DEPT_ID,A.MRP ,B.INV_DT                       
   FROM IND01106 A                      
   JOIN INM01106 B ON A.INV_ID=B.INV_ID WHERE A.INV_ID=@CXN_ID                       
                       
                         
   SELECT @CPARTYSTATE_CODE=A.PARTY_STATE_CODE ,@CCURSTATE_CODE=GST_STATE_CODE                      
   FROM INM01106 A                       
   JOIN LOCATION B ON A.location_Code =B.DEPT_ID                       
   WHERE A.INV_ID =@CXN_ID                      
                         
   EXEC SP3S_GST_DELIVERYCHALLAN_PRINT 'WSL',@NSPID,@CPARTYSTATE_CODE,@CCURSTATE_CODE,''                      
                                 
   UPDATE A SET HSN_CODE =B.HSN_CODE  ,                      
   XN_VALUE_WITHOUT_GST =B.XN_VALUE_WITHOUT_GST ,                      
   GST_PERCENTAGE =B.GST_PERCENTAGE,                      
   IGST_AMOUNT =B.IGST_AMOUNT ,                      
   CGST_AMOUNT =B.CGST_AMOUNT ,                      
   SGST_AMOUNT =B.SGST_AMOUNT                       
                                              
           FROM #TMPIND A                      
           JOIN GST_TAXINFO_CALC B ON A.ROW_ID  =B.ROW_ID                       
      WHERE B.SP_ID =RTRIM(LTRIM(STR(@NSPID)))                       
                                 
                                 
           UPDATE A SET TAXABLEVALUE =B.XN_VALUE_WITHOUT_GST  ,                      
      IGSTAMOUNT=B.IGST_AMOUNT,                      
                        CGSTAMOUNT=B.CGST_AMOUNT,                      
                        SGSTAMOUNT=B.SGST_AMOUNT                      
           FROM #DATASET1 A                      
           JOIN                      
           (                      
            SELECT SUM(IGST_AMOUNT ) AS IGST_AMOUNT,                      
                   SUM(CGST_AMOUNT ) AS CGST_AMOUNT,                      
                   SUM(SGST_AMOUNT ) AS SGST_AMOUNT,                      
                   SUM(XN_VALUE_WITHOUT_GST  ) AS XN_VALUE_WITHOUT_GST                      
            FROM #TMPIND                      
           ) B ON 1=1                      
                                 
                      
                       
                         
 END  
 SET @CSTEP=40                      
   -- END OF GST CALCULATION PRINT                      
   SELECT DS1.*                      
   ,OH_TAX_METHOD=CASE I.OH_TAX_METHOD WHEN 2 THEN 'INCL' ELSE 'EXCL' END                      
   ,@SALESMAN SALESMAN              
   ,V.DEPT_ID LOC_COMP_ID              
   ,V.ADDRESS1 LOC_COMP_ADD1              
   ,V.ADDRESS2 LOC_COMP_ADD2              
   ,V.TAN_NO LOC_COMP_TANNO              
   ,V.PAN_NO LOC_COMP_PANNO              
   ,V.TIN_NO LOC_COMP_TINNO              
   ,V.CITY LOC_COMP_CITY               
   ,V.PINCODE LOC_COMP_PINCODE              
   ,V.[STATE] LOC_COMP_STATE              
   ,V.PHONE LOC_COMP_PHONE              
   ,V.dept_name LOC_COMP_NAME 
   ,DS1.PARTY_DEPT_ID 
   FROM #DATASET1 DS1,INM01106 I (NOLOCK)                       
   JOIN (              
      SELECT L.DEPT_ID,ADDRESS1,ADDRESS2,TAN_NO,PAN_NO,TIN_NO,C.CITY,A.PINCODE,S.STATE,L.PHONE,l.dept_name                
   FROM LOCATION L                
   LEFT JOIN AREA A ON A.AREA_CODE=L.AREA_CODE                
   LEFT JOIN CITY C ON A.CITY_CODE=C.CITY_CODE                
   LEFT JOIN STATE S ON S.STATE_CODE=C.STATE_CODE                
    )V ON V.dept_id=@cLocId              
   WHERE I.INV_ID=@CXN_ID                      
                         
                           
      SET @CSTEP=50                      
                           
   DECLARE @MRP VARCHAR(1000)                        
   IF @SHOW_MRP=1                        
      SET @MRP=',ISNULL(IND01106.MRP,0) AS MRP'                        
   ELSE                         
      SET @MRP=',0 AS MRP'                    
                         
   SET @SNO=0--ASKED BY SANJIV SIR ON 19 JAN 2018 TO ORDER ONLY ON PARTICULARS                             
   --SET @DTSQL=N' SELECT ROW_NUMBER() OVER (ORDER BY '+ @CCOLNAME+' ) AS SR_NO, '+ @CCOLNAME+' AS PARTICULARS ,                        
   SET @DTSQL=' SELECT ROW_NUMBER() OVER (ORDER BY '+CASE @SNO WHEN 0 THEN @CCOLNAME ELSE 'IND01106.AUTO_SRNO' END+' ) AS SR_NO, '+ @CCOLNAME+' AS PARTICULARS ,                      
                 IND01106.REMARKS AS IND_REMARKS,                          
                 IND01106.HSN_CODE,UOM.UOM_NAME,                        
                 SUM(IND01106.QUANTITY) AS QUANTITY,                        
                 IND01106.RATE'                    
                 +@MRP                        
                 +',CAST(SUM(IND01106.QUANTITY*IND01106.RATE) AS NUMERIC(12,2)) AS AMOUNT,                        
     --CAST((SUM(IND01106.QUANTITY)*IND01106.RATE)-SUM(ISNULL(XN_VALUE_WITHOUT_GST,0)) AS NUMERIC(12,2))                        
                 CAST(SUM(IND01106.DISCOUNT_AMOUNT+ CASE WHEN INM01106.SUBTOTAL>0 THEN ((INM01106.DISCOUNT_AMOUNT/INM01106.SUBTOTAL)*IND01106.NET_RATE*IND01106.INVOICE_QUANTITY) ELSE 0 END )   AS NUMERIC(12,2)) AS LESS_DISCOUNT,                        
                 0 AS DISCOUNT_AMOUNT,                        
                 CAST(SUM(ISNULL(XN_VALUE_WITHOUT_GST,0)) AS NUMERIC(12,2)) AS TAXABLE_VALUE,                        
                 CAST(CASE WHEN SUM(IND01106.IGST_AMOUNT)<>0 THEN  IND01106.GST_PERCENTAGE ELSE 0 END AS NUMERIC(12,2)) AS IGST_RATE,          --23 Feb 2019              
                 CAST(SUM(IND01106.IGST_AMOUNT) AS NUMERIC(12,2)) AS IGST_AMOUNT,                        
                 CAST(CASE WHEN SUM(IND01106.CGST_AMOUNT)<>0 THEN  (IND01106.GST_PERCENTAGE)/2 ELSE 0 END AS NUMERIC(12,2)) AS CGST_RATE,                        
                 CAST(SUM(IND01106.CGST_AMOUNT) AS NUMERIC(12,2)) AS CGST_AMOUNT,                        
                 CAST(CASE WHEN SUM(IND01106.SGST_AMOUNT)<>0 THEN  (IND01106.GST_PERCENTAGE)/2 ELSE 0 END AS NUMERIC(12,2)) AS SGST_RATE,                        
                 CAST(SUM(IND01106.SGST_AMOUNT) AS NUMERIC(12,2)) AS SGST_AMOUNT,                        
                 CAST(SUM(IND01106.XN_VALUE_WITH_GST) AS NUMERIC(12,2)) AS TOTAL,                        
                 INM01106.NET_AMOUNT,                        
                 INM01106.ROUND_OFF,      
                 ISNULL(inm01106.total_box_NO,0) AS total_box_no,      
                 ISNULL(inm01106.total_packslip_NO,0) AS total_packslip_no,    
                  '                        
                 +CASE ISNULL(@BOX_NO,'') WHEN '' THEN '0 BOX_NO' ELSE 'IND01106.BOX_NO' END                        
                 +',ISNULL(WPS_MST.PS_NO,'''') AS ITEM_PACKSLIP_NO
                    ,INM01106.DISCOUNT_PERCENTAGE AS BILL_DISCOUNT_PERCENTAGE
                    ,IND01106.INMDISCOUNTAMOUNT AS  BILL_DISCOUNT_AMOUNT  
                    ,IND01106.DISCOUNT_PERCENTAGE AS  ITEM_DISCOUNT_PERCENTAGE
                    ,IND01106.DISCOUNT_AMOUNT AS  ITEM_DISCOUNT_AMOUNT                 
                 ,ISNULL(A1.ATTR1_KEY_NAME,'''')  ,ISNULL(A2.ATTR2_KEY_NAME,'''')  ,ISNULL(A3.ATTR3_KEY_NAME,'''')  ,ISNULL(A4.ATTR4_KEY_NAME,'''')  ,ISNULL(A5.ATTR5_KEY_NAME,'''')              
                 ,ISNULL(A6.ATTR6_KEY_NAME,'''')  ,ISNULL(A7.ATTR7_KEY_NAME,'''')  ,ISNULL(A8.ATTR8_KEY_NAME,'''')  ,ISNULL(A9.ATTR9_KEY_NAME,'''')  ,ISNULL(A10.ATTR10_KEY_NAME,'''')              
                 ,ISNULL(A11.ATTR11_KEY_NAME,''''),ISNULL(A12.ATTR12_KEY_NAME,''''),ISNULL(A13.ATTR13_KEY_NAME,''''),ISNULL(A14.ATTR14_KEY_NAME,''''),ISNULL(A15.ATTR15_KEY_NAME,'''')              
                 ,ISNULL(A16.ATTR16_KEY_NAME,''''),ISNULL(A17.ATTR17_KEY_NAME,''''),ISNULL(A18.ATTR18_KEY_NAME,''''),ISNULL(A19.ATTR19_KEY_NAME,''''),ISNULL(A20.ATTR20_KEY_NAME,'''')              
                 ,ISNULL(A21.ATTR21_KEY_NAME,''''),ISNULL(A22.ATTR22_KEY_NAME,''''),ISNULL(A23.ATTR23_KEY_NAME,''''),ISNULL(A24.ATTR24_KEY_NAME,''''),ISNULL(A25.ATTR25_KEY_NAME,'''')'              
                -- +CASE @NMODE WHEN 0 THEN '' ELSE ','''' AS PARA1_NAME' END              
                 +CHAR(13)+                                
       ' FROM #TMPIND IND01106 (NOLOCK)                        
       JOIN INM01106 (NOLOCK) ON IND01106.INV_ID=INM01106.INV_ID                        
       LEFT JOIN SKU (NOLOCK)               
       JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE=SKU.ARTICLE_CODE              
       LEFT JOIN ARTICLE_FIX_ATTR AF (NOLOCK)               
       LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=AF.ATTR1_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=AF.ATTR2_KEY_CODE '+@CATTR_DISPLAY_FILTER+'              
       LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=AF.ATTR3_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=AF.ATTR4_KEY_CODE '+@CATTR_DISPLAY_FILTER+'              
       LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=AF.ATTR5_KEY_CODE '+@CATTR_DISPLAY_FILTER+'              
       LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=AF.ATTR6_KEY_CODE '+@CATTR_DISPLAY_FILTER+'              
       LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=AF.ATTR7_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=AF.ATTR8_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=AF.ATTR9_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=AF.ATTR10_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=AF.ATTR11_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=AF.ATTR12_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=AF.ATTR13_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=AF.ATTR14_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=AF.ATTR15_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=AF.ATTR16_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=AF.ATTR17_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=AF.ATTR18_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=AF.ATTR19_KEY_CODE '+@CATTR_DISPLAY_FILTER+'              
       LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=AF.ATTR20_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=AF.ATTR21_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=AF.ATTR22_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'            
       LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=AF.ATTR23_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=AF.ATTR24_KEY_CODE '+@CATTR_DISPLAY_FILTER+'             
       LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=AF.ATTR25_KEY_CODE  '+@CATTR_DISPLAY_FILTER+'            
       ON AF.ARTICLE_CODE=ARTICLE.ARTICLE_CODE              
       ON SKU.PRODUCT_CODE =IND01106.PRODUCT_CODE                               
       LEFT JOIN UOM UOM (NOLOCK) ON UOM.UOM_CODE=ARTICLE.UOM_CODE                        
       LEFT OUTER JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE                        
       LEFT OUTER JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE=SECTIOND.SECTION_CODE                        
       LEFT OUTER JOIN PARA1 ON PARA1.PARA1_CODE=SKU.PARA1_CODE                        
       LEFT OUTER JOIN PARA2 ON PARA2.PARA2_CODE=SKU.PARA2_CODE                        
       LEFT OUTER JOIN PARA3 ON PARA3.PARA3_CODE=SKU.PARA3_CODE                        
       LEFT OUTER JOIN PARA4 ON PARA4.PARA4_CODE=SKU.PARA4_CODE                        
       LEFT OUTER JOIN PARA5 ON PARA5.PARA5_CODE=SKU.PARA5_CODE                        
       LEFT OUTER JOIN PARA6 ON PARA6.PARA6_CODE=SKU.PARA6_CODE                        
       LEFT OUTER JOIN WPS_MST (NOLOCK) ON ISNULL(WPS_MST.PS_ID,'''')=ISNULL(IND01106.PS_ID,'''')                        
       LEFT OUTER JOIN (SELECT DISTINCT PS_ID, LEFT(PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',PRODUCT_CODE)-1,-1),LEN(PRODUCT_CODE ))) as PRODUCT_CODE              
      FROM WPS_DET (NOLOCK)               
      WHERE PS_ID IN (SELECT DISTINCT PS_ID FROM IND01106 (NOLOCK) WHERE IND01106.INV_ID='''+@CXN_ID+''')              
        )WPS_DET ON WPS_DET.PS_ID=IND01106.PS_ID AND WPS_DET.PRODUCT_CODE=IND01106.PRODUCT_CODE                        
       WHERE IND01106.INV_ID='''+@CXN_ID+'''  '                        
       +CASE ISNULL(@BOX_NO,'') WHEN '' THEN '' ELSE ' AND IND01106.BOX_NO '+@BOX_NO END+                        
       'GROUP BY '                        
       +CASE @SNO WHEN 0 THEN '' ELSE 'IND01106.AUTO_SRNO,' END                      
       + @CCOLNAME+',IND01106.HSN_CODE,UOM.UOM_NAME,IND01106.RATE '                        
       +CASE @SHOW_MRP WHEN 1 THEN REPLACE(@MRP,' AS MRP','') ELSE ''END                       
       +' ,IND01106.GST_PERCENTAGE ,INM01106.NET_AMOUNT ,IND01106.REMARKS,INM01106.ROUND_OFF,'                    
       +CASE ISNULL(@BOX_NO,'') WHEN '' THEN '' ELSE 'IND01106.BOX_NO,' END                    
       +'ISNULL(WPS_MST.PS_NO,'''')      
       ,ISNULL(inm01106.total_box_NO,0)       
       ,ISNULL(inm01106.total_packslip_NO,0)     
       ,INM01106.DISCOUNT_PERCENTAGE
       ,IND01106.INMDISCOUNTAMOUNT
       ,IND01106.DISCOUNT_PERCENTAGE
       ,IND01106.DISCOUNT_AMOUNT              
       ,ISNULL(A1.ATTR1_KEY_NAME,'''')  ,ISNULL(A2.ATTR2_KEY_NAME,'''')  ,ISNULL(A3.ATTR3_KEY_NAME,'''')  ,ISNULL(A4.ATTR4_KEY_NAME,'''')  ,ISNULL(A5.ATTR5_KEY_NAME,'''')              
       ,ISNULL(A6.ATTR6_KEY_NAME,'''')  ,ISNULL(A7.ATTR7_KEY_NAME,'''')  ,ISNULL(A8.ATTR8_KEY_NAME,'''')  ,ISNULL(A9.ATTR9_KEY_NAME,'''')  ,ISNULL(A10.ATTR10_KEY_NAME,'''')              
       ,ISNULL(A11.ATTR11_KEY_NAME,''''),ISNULL(A12.ATTR12_KEY_NAME,''''),ISNULL(A13.ATTR13_KEY_NAME,''''),ISNULL(A14.ATTR14_KEY_NAME,''''),ISNULL(A15.ATTR15_KEY_NAME,'''')              
       ,ISNULL(A16.ATTR16_KEY_NAME,''''),ISNULL(A17.ATTR17_KEY_NAME,''''),ISNULL(A18.ATTR18_KEY_NAME,''''),ISNULL(A19.ATTR19_KEY_NAME,''''),ISNULL(A20.ATTR20_KEY_NAME,'''')              
       ,ISNULL(A21.ATTR21_KEY_NAME,''''),ISNULL(A22.ATTR22_KEY_NAME,''''),ISNULL(A23.ATTR23_KEY_NAME,''''),ISNULL(A24.ATTR24_KEY_NAME,''''),ISNULL(A25.ATTR25_KEY_NAME,'''')              
       ORDER BY 1'                      
   PRINT '--'+REPLICATE('$',100)+CHAR(13)+@DTSQL+CHAR(13)+'--'+REPLICATE('$',100)                    

   SET @CSTEP=60                    
   INSERT INTO #TMPDETAILS(SR_NO,PARTICULARS,IND_REMARKS,HSN_CODE,UOM_NAME,QUANTITY,RATE,MRP,AMOUNT,LESS_DISCOUNT,      
   DISCOUNT_AMOUNT,TAXABLE_VALUE,IGST_RATE,IGST_AMOUNT,CGST_RATE,CGST_AMOUNT,SGST_RATE,SGST_AMOUNT,TOTAL,NET_AMOUNT,      
   ROUND_OFF,total_box_no,total_packslip_no,ITEM_BOX_NO,ITEM_PACKSLIP_NO,BILL_DISCOUNT_PERCENTAGE,BILL_DISCOUNT_AMOUNT,ITEM_DISCOUNT_PERCENTAGE,ITEM_DISCOUNT_AMOUNT,ATTR1_KEY_NAME,ATTR2_KEY_NAME,ATTR3_KEY_NAME,ATTR4_KEY_NAME,ATTR5_KEY_NAME,ATTR6_KEY_NAME 
   ,ATTR7_KEY_NAME,ATTR8_KEY_NAME,ATTR9_KEY_NAME,ATTR10_KEY_NAME,ATTR11_KEY_NAME,ATTR12_KEY_NAME    
   ,ATTR13_KEY_NAME,ATTR14_KEY_NAME,ATTR15_KEY_NAME,ATTR16_KEY_NAME,ATTR17_KEY_NAME,ATTR18_KEY_NAME,ATTR19_KEY_NAME,ATTR20_KEY_NAME,ATTR21_KEY_NAME,ATTR22_KEY_NAME,ATTR23_KEY_NAME,ATTR24_KEY_NAME,ATTR25_KEY_NAME)                    
   EXEC(@DTSQL)  
   
   --IF @NMODE=1
   --ALTER TABLE #TMPDETAILS ADD PARA1_NAME VARCHAR(30)
   --ELSE                         
   --   INSERT INTO #TMPDETAILS(SR_NO,PARTICULARS,IND_REMARKS,HSN_CODE,UOM_NAME,QUANTITY,RATE,MRP,AMOUNT,LESS_DISCOUNT,DISCOUNT_AMOUNT,TAXABLE_VALUE,IGST_RATE,IGST_AMOUNT,CGST_RATE,CGST_AMOUNT,SGST_RATE,SGST_AMOUNT,TOTAL,NET_AMOUNT,      
   --   ROUND_OFF,total_box_no,total_packslip_no,ITEM_BOX_NO,ITEM_PACKSLIP_NO,ATTR1_KEY_NAME,ATTR2_KEY_NAME,ATTR3_KEY_NAME,ATTR4_KEY_NAME,ATTR5_KEY_NAME,ATTR6_KEY_NAME,ATTR7_KEY_NAME,ATTR8_KEY_NAME,ATTR9_KEY_NAME,ATTR10_KEY_NAME,ATTR11_KEY_NAME,ATTR12_KEY_NAME,ATTR13_KEY_NAME,ATTR14_KEY_NAME,ATTR15_KEY_NAME,ATTR16_KEY_NAME,ATTR17_KEY_NAME,ATTR18_KEY_NAME,ATTR19_KEY_NAME,ATTR20_KEY_NAME,ATTR21_KEY_NAME,ATTR22_KEY_NAME,ATTR23_KEY_NAME,ATTR24_KEY_NAME,ATTR25_KEY_NAME,PARA1_NAME)                       
   --   EXEC(@DTSQL)                      
                            
   UPDATE #TMPDETAILS SET PARTICULARS=DBO.FN_INTRIM(PARTICULARS)                       
   --31 JUL 2017                        
   UPDATE #TMPDETAILS SET DISCOUNT_AMOUNT=LESS_DISCOUNT                        
   UPDATE #TMPDETAILS SET LESS_DISCOUNT=0                        
   UPDATE #TMPDETAILS SET LESS_DISCOUNT=case when AMOUNT=0 then 0 else ROUND(DISCOUNT_AMOUNT/AMOUNT*100.0,2) end                       
   --31 JUL 2017                        
                       
                       
   --PARA2 SIZE SET CHEANGES*******************************                      
                         
   IF OBJECT_ID('TEMPDB..#TMPSIZESET','U') IS NOT NULL                      
    DROP TABLE  #TMPSIZESET                      
                          
 SELECT  P2.PARA2_SET ,ISNULL(PRINTCOLUMNNO,0) AS PRINTCOLUMNNO,                       
 P2.PARA2_NAME,P2.PARA2_CODE,                      
 CAST(SUM(QUANTITY) AS VARCHAR(100)) AS PARA2_QTY,                      
 ROW_NUMBER()  OVER (ORDER BY   P2.PARA2_NAME) AS SNO                         
 INTO #TMPSIZESET                      
 FROM IND01106 A                      
 JOIN SKU B ON A.PRODUCT_CODE =B.PRODUCT_CODE                       
 JOIN PARA2 P2 ON P2.PARA2_CODE =B.PARA2_CODE                       
 WHERE INV_ID=@CXN_ID                      
 GROUP BY P2.PARA2_SET ,ISNULL(PRINTCOLUMNNO,0),                      
 P2.PARA2_NAME ,P2.PARA2_CODE                      
  SET @CSTEP=70                     
 IF OBJECT_ID('TEMPDB..#TMPALLSIZE','U') IS NOT NULL                      
    DROP TABLE  #TMPALLSIZE                      
                       
  SELECT  A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) AS PRINTCOLUMNNO, A.PARA2_NAME ,        
  SNO =ROW_NUMBER () OVER (ORDER BY A.PARA2_SET,ISNULL(A.PRINTCOLUMNNO,0),A.PARA2_NAME)                
  INTO #TMPALLSIZE                      
  FROM PARA2 A                      
  JOIN #TMPSIZESET B ON A.PARA2_SET =B.PARA2_SET                       
  GROUP BY A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) , A.PARA2_NAME                       
                      
   DECLARE @CUPDATECOLNAME VARCHAR(10),@NSRNO INT                      
                       
   SET @NSRNO=1                      
   WHILE @NSRNO <=36                      
   BEGIN                      
     SET @DTSQL=' ALTER TABLE #TMPDETAILS ADD HEADER'+RTRIM(LTRIM(STR(@NSRNO)))+' VARCHAR(100) '                      
     PRINT @DTSQL                      
     EXEC(@DTSQL)                       
                           
     SET @DTSQL=' IF EXISTS(SELECT TOP 1 ''U'' FROM #TMPALLSIZE WHERE SNO='+RTRIM(LTRIM(STR(@NSRNO)))+')                      
     BEGIN                      
   UPDATE #TMPDETAILS SET HEADER'+RTRIM(LTRIM(STR(@NSRNO)))+                      
   ' =(SELECT TOP 1  PARA2_NAME FROM #TMPALLSIZE WHERE SNO='+RTRIM(LTRIM(STR(@NSRNO)))+')                      
   END '                      
     PRINT @DTSQL                      
     EXEC(@DTSQL)                       
     SET @NSRNO=@NSRNO+1                      
   END                       
  SET @CSTEP=80                    
 DECLARE @CALLPARA2_NAME VARCHAR(MAX)                       
                      
 SELECT  @CALLPARA2_NAME=ISNULL(@CALLPARA2_NAME+'','')+                      
 CASE WHEN LEN(A.PARA2_NAME) =1 THEN ' '                      
      WHEN LEN(A.PARA2_NAME) =2 THEN ' '                      
       ELSE ' ' END+                      
  LEFT((A.PARA2_NAME ),3)                      
 FROM                      
 (                      
  SELECT  A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) AS PRINTCOLUMNNO, A.PARA2_NAME                       
  FROM PARA2 A                    
  JOIN #TMPSIZESET B ON A.PARA2_SET =B.PARA2_SET                       
  GROUP BY A.PARA2_SET ,ISNULL(A.PRINTCOLUMNNO,0) , A.PARA2_NAME                       
                      
 ) A                      
                          
              
              
    SET @CSTEP=90                  
 IF OBJECT_ID('TEMPDB..#TMPPARTICULAR','U') IS NOT NULL                      
    DROP TABLE  #TMPPARTICULAR                      
                         
   SELECT A.SR_NO,A.PARTICULARS,A.IND_REMARKS, A.HSN_CODE,A.UOM_NAME,                      
         A.MRP,A.RATE,A.ITEM_BOX_NO,A.ITEM_PACKSLIP_NO,A.PARA1_NAME,                      
   CAST('' AS VARCHAR(1000)) AS PARA2_NAME,                      
   CAST('' AS VARCHAR(1000)) AS PARA2_CODE,                      
   CAST('' AS NUMERIC(10,0)) AS PARA2_QTY,                      
   CAST(0 AS INT ) AS SNO,                      
   CAST(0 AS INT ) AS PRINTCOLUMNNO      
  --CAST('' AS NUMERIC(10,0)) AS TOTAL_BOX_NO,      
   --CAST('' AS NUMERIC(10,0)) AS TOTAL_PACKSLIP_NO                     
   INTO #TMPPARTICULAR                      
   FROM #TMPDETAILS A                      
   WHERE 1=2                      
    SET @CSTEP=10                   
  SET @DTSQL=' SELECT ROW_NUMBER() OVER (ORDER BY '+CASE @SNO WHEN 0 THEN @CCOLNAME ELSE 'IND01106.AUTO_SRNO' END+' ) AS SR_NO,                      
  '+ @CCOLNAME+' AS PARTICULARS ,IND01106.REMARKS AS IND_REMARKS,                       
  IND01106.HSN_CODE,UOM.UOM_NAME,                        
     IND01106.RATE'           
     +@MRP                       
     +CASE @GROUP_BOX WHEN 0 THEN ',0 BOX_NO' ELSE ',IND01106.BOX_NO' END                       
     +',ISNULL(WPS_MST.PS_NO,'''') AS ITEM_PACKSLIP_NO                      
     ,'''' AS PARA1_NAME                      
     ,PARA2.PARA2_CODE               
     ,PARA2.PARA2_NAME                      
     ,SUM(IND01106.QUANTITY) AS PARA2_QTY                      
     ,0 AS SNO                       
     ,ISNULL(PARA2.PRINTCOLUMNNO,0) AS PRINTCOLUMNNO     
               
     FROM #TMPIND IND01106 (NOLOCK)                        
     JOIN INM01106 (NOLOCK) ON IND01106.INV_ID=INM01106.INV_ID                        
     LEFT JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =IND01106.PRODUCT_CODE                           
     LEFT JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE =SKU.ARTICLE_CODE                            
     LEFT JOIN UOM UOM (NOLOCK) ON UOM.UOM_CODE=ARTICLE.UOM_CODE                        
     LEFT OUTER JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=ARTICLE.SUB_SECTION_CODE                        
     LEFT OUTER JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE=SECTIOND.SECTION_CODE                        
     LEFT OUTER JOIN PARA1 ON PARA1.PARA1_CODE=SKU.PARA1_CODE                        
     LEFT OUTER JOIN PARA2 ON PARA2.PARA2_CODE=SKU.PARA2_CODE                        
     LEFT OUTER JOIN PARA3 ON PARA3.PARA3_CODE=SKU.PARA3_CODE                        
     LEFT OUTER JOIN PARA4 ON PARA4.PARA4_CODE=SKU.PARA4_CODE                        
     LEFT OUTER JOIN PARA5 ON PARA5.PARA5_CODE=SKU.PARA5_CODE                        
     LEFT OUTER JOIN PARA6 ON PARA6.PARA6_CODE=SKU.PARA6_CODE                        
     LEFT OUTER JOIN WPS_MST (NOLOCK) ON ISNULL(WPS_MST.PS_ID,'''')=ISNULL(IND01106.PS_ID,'''')                        
     LEFT OUTER JOIN (SELECT DISTINCT PS_ID,              
     (CASE WHEN  CHARINDEX(''@'',PRODUCT_CODE)>0 THEN SUBSTRING(PRODUCT_CODE,1,CHARINDEX(''@'',PRODUCT_CODE)-1)              
         ELSE product_code END) as PRODUCT_CODE FROM WPS_DET (NOLOCK) WHERE PS_ID IN (SELECT DISTINCT PS_ID FROM IND01106 (NOLOCK) WHERE IND01106.INV_ID='''+@CXN_ID+'''))WPS_DET                        
     ON WPS_DET.PS_ID=IND01106.PS_ID AND WPS_DET.PRODUCT_CODE=IND01106.PRODUCT_CODE                       
     WHERE IND01106.INV_ID='''+@CXN_ID+''''                        
     +CASE ISNULL(@BOX_NO,'') WHEN '' THEN '' ELSE ' AND IND01106.BOX_NO '+@BOX_NO END+                        
     'GROUP BY '                        
     +CASE @SNO WHEN 0 THEN '' ELSE 'IND01106.AUTO_SRNO,' END                      
     + @CCOLNAME+',IND01106.HSN_CODE,UOM.UOM_NAME,IND01106.RATE '                        
     +CASE @SHOW_MRP WHEN 1 THEN REPLACE(@MRP,' AS MRP','') ELSE ''END                       
     +'  ,IND01106.GST_PERCENTAGE,PARA2.PRINTCOLUMNNO, IND01106.REMARKS ,PARA2.PARA2_NAME,PARA2.PARA2_CODE ,INM01106.NET_AMOUNT ,INM01106.ROUND_OFF'                      
     +CASE @GROUP_BOX WHEN 0 THEN '' ELSE ',IND01106.BOX_NO' END                      
     +',ISNULL(WPS_MST.PS_NO,'''')'                      
     +CASE @NMODE WHEN 0 THEN '' ELSE ',PARA1.PARA1_NAME' END+                        
     ' ORDER BY 1'              
   PRINT REPLICATE('*',150)+CHAR(13)+@DTSQL+CHAR(13)+REPLICATE('*',150)                      
                 
   INSERT INTO #TMPPARTICULAR(SR_NO,PARTICULARS,IND_REMARKS,HSN_CODE,UOM_NAME,                 
         RATE,MRP,ITEM_BOX_NO,ITEM_PACKSLIP_NO,PARA1_NAME,PARA2_CODE,PARA2_NAME,PARA2_QTY,SNO,PRINTCOLUMNNO)      
               
   EXEC(@DTSQL)                        
                         
   UPDATE #TMPPARTICULAR SET PARTICULARS=DBO.FN_INTRIM(PARTICULARS)                       
                         
   UPDATE D SET D.ITEM_BOX_NO=P.ITEM_BOX_NO              
   FROM #TMPDETAILS D JOIN #TMPPARTICULAR P              
   ON D.PARTICULARS=P.PARTICULARS                  
        
                         
DECLARE @CPARTICULARS VARCHAR(MAX),@CHSN_CODE VARCHAR(20),                      
        @CUOM_NAME VARCHAR(100),@NMRP NUMERIC(10,2),@NRATE NUMERIC(10,2),                      
        @NITEMBOXNO INT ,@CITEMPACKSPLINO VARCHAR(100),@PRINTCOLUMNNO INT,                      
        @NPARA2_QTY NUMERIC(10,0)                      
                      
  WHILE EXISTS (SELECT TOP 1 'U' FROM  #TMPPARTICULAR)                      
   BEGIN                      
                           
  SELECT TOP 1 @CPARTICULARS=PARTICULARS,@CHSN_CODE=HSN_CODE,@CUOM_NAME=UOM_NAME,         
  @NMRP=MRP,@NRATE=RATE,@NITEMBOXNO=ITEM_BOX_NO,@CITEMPACKSPLINO=ITEM_PACKSLIP_NO,                      
  @PRINTCOLUMNNO=PRINTCOLUMNNO,@NPARA2_QTY=PARA2_QTY      
  FROM #TMPPARTICULAR                      
                              
        IF @PRINTCOLUMNNO BETWEEN 1 AND 12                      
        BEGIN                      
                                  
		SET @DTSQL=' UPDATE #TMPDETAILS SET SIZE'+RTRIM(LTRIM(STR(@PRINTCOLUMNNO)))+'                      
		= '+RTRIM(LTRIM(STR(@NPARA2_QTY)))+'                      
		WHERE                       
		PARTICULARS='''+@CPARTICULARS+'''             
		AND HSN_CODE='''+@CHSN_CODE+'''                      
		AND UOM_NAME='''+@CUOM_NAME+'''                      
		AND MRP='+RTRIM(LTRIM(STR(@NMRP)))+'                      
		AND RATE='+RTRIM(LTRIM(STR(@NRATE)))+'   
		AND ITEM_BOX_NO='+RTRIM(LTRIM(STR(@NITEMBOXNO)))+'                                      
		AND ITEM_PACKSLIP_NO='''+@CITEMPACKSPLINO+'''      
                 
		'                      
		PRINT @DTSQL                      
		EXEC(@DTSQL)                      
                           
        END                      
                              
    DELETE FROM #TMPPARTICULAR                      
    WHERE PARTICULARS=@CPARTICULARS                      
    AND HSN_CODE=@CHSN_CODE                      
    AND UOM_NAME=@CUOM_NAME                      
 AND MRP=@NMRP                      
 AND RATE=@NRATE                      
 AND ITEM_BOX_NO=@NITEMBOXNO                      
 AND ITEM_PACKSLIP_NO=@CITEMPACKSPLINO                      
 AND PRINTCOLUMNNO=@PRINTCOLUMNNO        
            
                  
                         
   END                      
                        
   --DATASET 2                    
   SELECT SR_NO,PARTICULARS,IND_REMARKS AS REMARKS,HSN_CODE,UOM_NAME,QUANTITY,RATE,MRP,AMOUNT,LESS_DISCOUNT,DISCOUNT_AMOUNT,TAXABLE_VALUE,IGST_RATE,          
        IGST_AMOUNT,CGST_RATE,CGST_AMOUNT,SGST_RATE,SGST_AMOUNT,TOTAL ,NET_AMOUNT,ROUND_OFF,ITEM_BOX_NO,ITEM_PACKSLIP_NO ,BILL_DISCOUNT_PERCENTAGE,BILL_DISCOUNT_AMOUNT,ITEM_DISCOUNT_PERCENTAGE,ITEM_DISCOUNT_AMOUNT,TOTAL_BOX_NO,TOTAL_PACKSLIP_NO,             
       @CALLPARA2_NAME AS ALLPARA2_NAME,                     
        SIZE1,SIZE2 ,SIZE3,SIZE4,SIZE5,SIZE6,SIZE7,SIZE8,SIZE9,SIZE10,SIZE11,SIZE12,                      
        HEADER1,HEADER2,HEADER3,HEADER4,HEADER5,HEADER6,HEADER7,HEADER8,HEADER9,HEADER10,                      
        HEADER11,HEADER12,HEADER13,HEADER14,HEADER15,HEADER16,HEADER17,HEADER18,HEADER19,HEADER20,                      
        HEADER21,HEADER22,HEADER23,HEADER24,HEADER25,HEADER26,HEADER27,HEADER28,HEADER29,HEADER30,                      
        HEADER31,HEADER32              
        ,ATTR1_KEY_NAME,ATTR2_KEY_NAME,ATTR3_KEY_NAME,ATTR4_KEY_NAME,ATTR5_KEY_NAME,ATTR6_KEY_NAME,ATTR7_KEY_NAME,ATTR8_KEY_NAME,ATTR9_KEY_NAME,ATTR10_KEY_NAME,ATTR11_KEY_NAME,ATTR12_KEY_NAME,ATTR13_KEY_NAME,ATTR14_KEY_NAME,ATTR15_KEY_NAME,ATTR16_KEY_NAME
       ,ATTR17_KEY_NAME,ATTR18_KEY_NAME,ATTR19_KEY_NAME,ATTR20_KEY_NAME,ATTR21_KEY_NAME,ATTR22_KEY_NAME,ATTR23_KEY_NAME,ATTR24_KEY_NAME,ATTR25_KEY_NAME                      
   FROM #TMPDETAILS A                      
   ORDER BY A.SR_NO                         
                        
                          
   SELECT TNC_1,TNC_2,TNC_3,TNC_4,TNC_5,TNC_6,TNC_7,TNC_8                  
   FROM GST_TNC WHERE XN_TYPE='WSL'                   
                          
   SELECT B.PAYMODE_NAME+' '+CAST(SUM(A.AMOUNT) AS VARCHAR) AS PAYMODE_NAME                        
   FROM PAYMODE_XN_DET A (NOLOCK)                        
   JOIN PAYMODE_MST B (NOLOCK) ON A.PAYMODE_CODE=B.PAYMODE_CODE                        
   WHERE A.XN_TYPE ='WSL' AND A.MEMO_ID=@CXN_ID                        
   GROUP BY B.PAYMODE_NAME                        
                           
   SELECT @NCALQTYSUM=SUM(QUANTITY) FROM #TMPDETAILS                        
   SELECT @NSTOREDQTY=SUM(QUANTITY) FROM IND01106 WHERE INV_ID=@CXN_ID                         
                           
   --ADD NEW AS BLOCK FOR GST PERCENTAGE                        
   SELECT *                
   ,[IGST_PER]=CASE ISNULL([IGST_AMOUNT],0) WHEN 0 THEN '0%' WHEN [GST_COLLECTION] THEN GST ELSE GST END                        
   ,[CGST_PER]=CASE ISNULL([CGST_AMOUNT],0) WHEN 0 THEN '0%' ELSE DBO.CURR_GROUPING(ROUND(CAST(REPLACE([GST],'%','') AS DECIMAL(10,2))/2,2),'')+'%' END                        
   ,[SGST_PER]=CASE ISNULL([SGST_AMOUNT],0) WHEN 0 THEN '0%' ELSE DBO.CURR_GROUPING(ROUND(CAST(REPLACE([GST],'%','') AS DECIMAL(10,2))/2,2),'')+'%' END                        
   FROM                        
   (                        
    SELECT CAST(DBO.CURR_GROUPING(GST_PERCENTAGE,'') AS VARCHAR)+'%'[GST]                        
    ,SUM(XN_VALUE_WITHOUT_GST)[TAXABLE_VALUES]                        
    ,SUM(CGST_AMOUNT)[CGST_AMOUNT]                         
    ,SUM(SGST_AMOUNT)[SGST_AMOUNT]                 
    ,SUM(IGST_AMOUNT)[IGST_AMOUNT]                        
    ,SUM(CGST_AMOUNT+SGST_AMOUNT+IGST_AMOUNT)[GST_COLLECTION]                  
    FROM #TMPIND IND01106 (NOLOCK) WHERE INV_ID=@CXN_ID                        
    GROUP BY CAST(DBO.CURR_GROUPING(GST_PERCENTAGE,'') AS VARCHAR)                        
    )GST                        
                              
                           
   --GST_OH_CONFIG ON 15 JUL 2017                        
   SELECT *                         
   FROM                        
   (                        
    SELECT CASE OH_NAME WHEN 'OC' THEN 'OTHER CHARGES' ELSE OH_NAME END AS OH_NAME                        
    ,HSN_CODE AS HSNSAC_CODE                        
    ,OH_GST_PER=CASE OH_NAME WHEN 'FREIGHT' THEN FREIGHT_GST_PERCENTAGE WHEN 'OC' THEN OTHER_CHARGES_GST_PERCENTAGE  WHEN 'INSURANCE' THEN INSURANCE_GST_PERCENTAGE WHEN 'PACKING' THEN PACKING_GST_PERCENTAGE END                        
    ,OH_SGST_AMOUNT=CASE OH_NAME WHEN 'OC' THEN ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) WHEN 'FREIGHT' THEN ISNULL(FREIGHT_SGST_AMOUNT,0) WHEN 'INSURANCE' THEN ISNULL(INSURANCE_SGST_AMOUNT,0) WHEN 'PACKING' THEN ISNULL(PACKING_SGST_AMOUNT,0) END                  
    ,OH_CGST_AMOUNT=CASE OH_NAME WHEN 'OC' THEN ISNULL(OTHER_CHARGES_CGST_AMOUNT,0) WHEN 'FREIGHT' THEN ISNULL(FREIGHT_CGST_AMOUNT,0) WHEN 'INSURANCE' THEN ISNULL(INSURANCE_CGST_AMOUNT,0) WHEN 'PACKING' THEN ISNULL(PACKING_CGST_AMOUNT,0) END                   
    ,OH_IGST_AMOUNT=CASE OH_NAME WHEN 'OC' THEN ISNULL(OTHER_CHARGES_IGST_AMOUNT,0) WHEN 'FREIGHT' THEN ISNULL(FREIGHT_IGST_AMOUNT,0) WHEN 'INSURANCE' THEN ISNULL(INSURANCE_IGST_AMOUNT,0) WHEN 'PACKING' THEN ISNULL(PACKING_IGST_AMOUNT,0) END              
    ,OH_TAXABLE_VALUE=CASE OH_NAME WHEN 'FREIGHT' THEN FREIGHT_TAXABLE_VALUE  WHEN 'OC' THEN OTHER_CHARGES_TAXABLE_VALUE   WHEN 'INSURANCE' THEN INSURANCE_TAXABLE_VALUE  WHEN 'PACKING' THEN PACKING_TAXABLE_VALUE  END                       
    FROM GST_OH_CONFIG,INM01106 (NOLOCK)                        
    WHERE INV_ID=@CXN_ID                        
   )T                        
   WHERE ISNULL(OH_GST_PER,0)<>0                        
                           
   --STARTS: GST_HSNSASCODE ON 05 APR 2018                
   --SELECT HSN_CODE AS HSNSACCODE                        
   --,CAST(AVG(IGST_RATE)AS DECIMAL(10,2))HSNIGSTPER ,SUM(IGST_AMOUNT)HSNIGSTAMOUNT                        
   --,CAST(AVG(CGST_RATE)AS DECIMAL(10,2))HSNCGSTPER ,SUM(CGST_AMOUNT)HSNCGSTAMOUNT                        
   --,CAST(AVG(SGST_RATE)AS DECIMAL(10,2))HSNSCGSTPER,SUM(SGST_AMOUNT)HSNSCGSTAMOUNT                        
   --,SUM(TOTAL)HSNTOTALAMOUNT                        
   --,SUM(QUANTITY)HSNQUANTITY                        
   --FROM #TMPDETAILS                        
   --GROUP BY HSN_CODE                        
                         
   SELECT HSN_CODE HSNSACCODE,SUM(TAXABLE_VALUE)TAXABLEVALUE                      
   ,CAST(IGST_RATE AS DECIMAL(10,2))HSNIGSTPER,SUM(IGST_AMOUNT)HSNIGSTAMOUNT                      
   ,CAST(CGST_RATE AS DECIMAL(10,2))HSNCGSTPER,SUM(CGST_AMOUNT)HSNCGSTAMOUNT                      
   ,CAST(SGST_RATE AS DECIMAL(10,2))HSNSCGSTPER,SUM(SGST_AMOUNT)HSNSCGSTAMOUNT                      
   ,SUM(TOTAL)HSNTOTALAMOUNT                        
   ,SUM(QUANTITY)HSNQUANTITY                        
   FROM #TMPDETAILS                      
   GROUP BY HSN_CODE,IGST_RATE,CGST_RATE,SGST_RATE   
   


   --FOR PRODUCTION REFERENCE NO
           
	 SELECT  A.ORDER_NO AS BUYER_ORDER_NO,A.ORDER_DT AS BUYER_ORDER_DT,A.REF_NO AS BUYER_ORDER_REF_NO              
	 ,BMST.MEMO_NO AS JOB_CARD_NO,BMST.MEMO_DT AS JOB_CARD_DT              
	 FROM IND01106 IND (NOLOCK)
	 left JOIN ORD_PLAN_BARCODE_DET BAR_DET (NOLOCK) ON IND.PRODUCT_CODE= BAR_DET.PRODUCT_CODE  
	 left JOIN ORD_PLAN_DET BDET (NOLOCK) ON BDET.ROW_ID=BAR_DET.REFROW_ID              
	 left JOIN ORD_PLAN_MST BMST (NOLOCK) ON BDET.MEMO_ID=BMST.MEMO_ID 
	 LEFT JOIN WPS_DET WD ON WD .ps_id =IND.ps_id 
	 LEFT JOIN WPS_MST WM ON WM.ps_id =WD.ps_id AND WM.CANCELLED=0 
	 LEFT JOIN BUYER_ORDER_DET A1 (NOLOCK) ON ISNULL(BDET.WOD_ROW_ID,CASE WHEN ISNULL(IND.ps_id,'') ='' THEN  IND.BO_DET_ROW_ID ELSE WD.BO_DET_ROW_ID END )=A1.ROW_ID              
	 LEFT JOIN BUYER_ORDER_MST A (NOLOCK) ON A1.ORDER_ID=A.ORDER_ID 
	 WHERE ISNULL(BMST.CANCELLED,0)=0 AND A.CANCELLED=0          
	 AND   INV_ID=@CXN_ID    AND 1=2 ---- Currently this query taking time Lyalpur emporium ,Need to be optimized by Dinkar (Sanjay:19-02-2021)
	 GROUP BY  A.ORDER_ID,A.ORDER_NO,A.ORDER_DT,A.REF_NO,BMST.MEMO_ID ,BMST.MEMO_NO,BMST.MEMO_DT              
   

 
      

   --ENDS: GST_HSNSASCODE ON 05 APR 2018                        
                        
   IF ABS(@NCALQTYSUM-@NSTOREDQTY)>0                 
      BEGIN                        
        SET @CERRMSG='CALCULATED & STORED QTY DIFFERENCE PLEASE CHECK'                        
      END                        
         GOTO END_PROC                        
      END --END OF WSL                        
  END TRY                          
                        
  BEGIN CATCH                          
  BEGIN                        
 print 'catch entered'+@CSTEP      
   SELECT @CERRMSG='ERROR MESSAGE IN PROCEDURE SP3S_PRINTREPORT_GST STEP#'+@CSTEP+' '+      
   CAST(ERROR_MESSAGE() AS VARCHAR(500))      
   GOTO END_PROC                        
  END                       
  END CATCH                           
                           
END_PROC:                        
  SELECT @CERRMSG AS ERRMSG                        
  SET NOCOUNT OFF                        
END              
              
/*              
LEFT OUTER JOIN              
(              
 SELECT BAR_DET.PRODUCT_CODE, A.ORDER_NO AS BUYER_ORDER_NO,A.ORDER_DT AS BUYER_ORDER_DT,A.REF_NO AS BUYER_ORDER_REF_NO              
 ,BMST.MEMO_NO AS JOB_CARD_NO,BMST.MEMO_DT AS JOB_CARD_DT              
 FROM ORD_PLAN_BARCODE_DET BAR_DET (NOLOCK)               
 JOIN ORD_PLAN_DET BDET (NOLOCK) ON BDET.ROW_ID=BAR_DET.REFROW_ID              
 JOIN ORD_PLAN_MST BMST (NOLOCK) ON BDET.MEMO_ID=BMST.MEMO_ID              
 LEFT JOIN BUYER_ORDER_DET A1 (NOLOCK) ON BDET.WOD_ROW_ID=A1.ROW_ID              
 LEFT JOIN BUYER_ORDER_MST A (NOLOCK) ON A1.ORDER_ID=A.ORDER_ID              
 WHERE BMST.CANCELLED=0 AND A.CANCELLED=0              
 GROUP BY BAR_DET.PRODUCT_CODE, A.ORDER_ID,A.ORDER_NO,A.ORDER_DT,A.REF_NO,BMST.MEMO_ID ,BMST.MEMO_NO,BMST.MEMO_DT              
)X ON X.PRODUCT_CODE=T2.PRODUCT_CODE              
      
exec SP3S_PRINTREPORT_GST @cXn_Type='WSL',@cXn_Id='JM01120JM/19-20/L-000017', @NMODE ='0'      
*/ 

-- new