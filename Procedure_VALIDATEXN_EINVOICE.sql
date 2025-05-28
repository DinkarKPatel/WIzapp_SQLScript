create PROCEDURE VALIDATEXN_EINVOICE
 @CXNID VARCHAR(50)='JM01120JM19-20/W-000301' ,	
 @CDEPT_ID VARCHAR(5)='',
 @CXN_TYPE VARCHAR(10)='',
 @cerrmsg varchar(1000)  output
AS
BEGIN
	
	
	PRINT 'VALIDATE WSL-1'

	
	 DECLARE @CEINVOICE_EXPORT_GSTNO VARCHAR(25),@CEINVOICE_EXPORT_BUYER_STATE_CODE VARCHAR(10),
	 @CEINVOICE_EXPORT_BUYER_PIN_CODE VARCHAR(10), @CDONT_ASK_FOR_EWAY_BILL_GENERATION_DURING_EINVOICING varchar(5)

	 SELECT @CEINVOICE_EXPORT_GSTNO=value FROM CONFIG WHERE CONFIG_OPTION ='EINVOICE_EXPORT_GSTNO'
	 SELECT @CEINVOICE_EXPORT_BUYER_STATE_CODE=value FROM CONFIG WHERE CONFIG_OPTION ='EINVOICE_EXPORT_BUYER_STATE_CODE'
	 SELECT @CEINVOICE_EXPORT_BUYER_PIN_CODE=value FROM CONFIG WHERE CONFIG_OPTION ='EINVOICE_EXPORT_BUYER_PIN_CODE'
	 SELECT @CDONT_ASK_FOR_EWAY_BILL_GENERATION_DURING_EINVOICING=value FROM CONFIG WHERE CONFIG_OPTION ='DONT_ASK_FOR_EWAY_BILL_GENERATION_DURING_EINVOICING'

	 SET @CDONT_ASK_FOR_EWAY_BILL_GENERATION_DURING_EINVOICING=ISNULL(@CDONT_ASK_FOR_EWAY_BILL_GENERATION_DURING_EINVOICING,'')


	
        IF OBJECT_ID ('TEMPDB..#TRANSPORTER1','U') IS NOT NULL                              
           DROP TABLE #TRANSPORTER1 
		            
    SELECT b.REF_MEMO_ID, A.PARCEL_MEMO_ID, ANGM.ANGADIA_NAME AS TRANSPORTER_NAME , angm.Angadia_code ,     
           ANGADIA_ADD1 ,ANGADIA_ADD2  ,AR.AREA_NAME ,AR.PINCODE , lmp.ac_gst_state_code   AS STATE ,A.MODE ,
		   vehicle_no , parcel_memo_no , parcel_memo_dt                                       
    INTO #TRANSPORTER1                              
    FROM PARCEL_MST A (NOLOCK)                              
    JOIN PARCEL_DET B (NOLOCK) ON A.PARCEL_MEMO_ID =B.PARCEL_MEMO_ID                                         
    LEFT OUTER JOIN ANGM (NOLOCK) ON ANGM.ANGADIA_CODE =A.ANGADIA_CODE          
    LEFT JOIN AREA AR (NOLOCK) ON AR.AREA_CODE =ANGM.AREA_CODE       
	left join LMP01106 lmp on lmp.AC_CODE =angm.ac_code                
    WHERE A.XN_TYPE ='WSL' AND B.REF_MEMO_ID=@CXNID        
    AND A.CANCELLED =0      
    GROUP BY b.REF_MEMO_ID,A.PARCEL_MEMO_ID, ANGM.ANGADIA_NAME  ,      
    ANGADIA_ADD1 ,ANGADIA_ADD2  ,AR.AREA_NAME ,AR.PINCODE , lmp.ac_gst_state_code,A.MODE,vehicle_no ,parcel_memo_no, parcel_memo_dt ,
	angm.Angadia_code                       
   
        
    ;WITH CTE AS                               
    (                              
   SELECT REF_MEMO_ID,SR=ROW_NUMBER () OVER (ORDER BY REF_MEMO_ID)                               
   FROM #TRANSPORTER1                              
    )                              
                                 
    DELETE FROM CTE WHERE SR>1    


	 DECLARE @NPICKINGSHIPPINGADDRESS INT
--1 FOR  INM  SHIPPING AC_CODE DETAILS 2.INM SHPING ADDRESS STORED IN INM 3 FOR PARTY ADDRESS

 SELECT @NPICKINGSHIPPINGADDRESS=
      CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0 
	       THEN CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN 1 ELSE 2 END 
		   ELSE 3 END  
 FROM INM01106  WHERE INV_ID=@CXNID

	

	IF OBJECT_ID ('TEMPDB..#TMPINM','U') IS NOT NULL
	   DROP TABLE #TMPINM

	SELECT A.INV_ID, A.AC_CODE, A.CREDIT_DAYS,A.SHIPPING_SAME_AS_BILLING_ADD,
           A.PARTY_STATE_CODE,A.INV_NO,A.INV_DT,A.SUBTOTAL,A.REF_INV_ID,A.ROUND_OFF,A.PAY_MODE,A.MEMO_TYPE,A.REMARKS,
		   L.DEPT_NAME,C.COMPANY_NAME ,L.ADDRESS1,L.ADDRESS2,AR.AREA_NAME,AR.PINCODE ,L.gst_state_code ,C.MOBILE,C.PHONES_FAX,c.email_id,
		  --buyer details--
		    CASE WHEN A.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_GSTNO ELSE  LM.AC_GST_NO END AS BGSTIN,
		   LM.AC_NAME AS BLGLNM,LM.AC_NAME AS BTRDNM,
		   CASE WHEN A.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_PIN_CODE ELSE   LM.ac_gst_state_code END  AS BPOS,
		   LM.ADDRESS0+' '+ LM.ADDRESS1 AS BADDR1,LM.ADDRESS2 AS BADDR2,
		   LM.AREA_NAME BLoc ,
		   CASE WHEN A.DOMESTIC_FOR_EXPORT IN(2,3) THEN @CEINVOICE_EXPORT_BUYER_STATE_CODE ELSE   lm.PINCODE END BPin ,
		   LM.ac_gst_state_code AS BStcd,case when isnull( LM.MOBILE,'')='' then lm.PHONES_O else lm.mobile end   AS BPH,LM.E_MAIL  AS BEm,
		   --dispatch deatils
		   tr.TRANSPORTER_NAME,tr.Angadia_Add1 ,tr.Angadia_Add2 ,tr.area_name as Dis_Area_name,tr.pincode as Dis_pin,tr.STATE as DIS_State,
		   --Shipping deatils

		    CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.Ac_gst_no  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLMP.AC_GST_NO
		   ELSE LM.Ac_gst_no  END SHIPPING_Gst_No,


		   CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHcs.gst_state_code   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(shp.gst_state_code ,'') 
		   ELSE lm.ac_gst_state_code     END SHIPPING_STATE_CODE,

        CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLM.AC_NAME   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN SHLM.AC_NAME 
		   ELSE LM.AC_NAME  END SHIPPINg_AC_NAME,

      

         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS0 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS 
		   ELSE LM.ADDRESS0 END SHIPPING_ADDRESS,

	    CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN  SHLMP.ADDRESS0+' '+ SHLMP.ADDRESS1 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS2 
		   ELSE  LM.ADDRESS0+' '+ LM.ADDRESS1 END SHIPPING_ADDRESS2,

         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHLMP.ADDRESS2 
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_ADDRESS3 
		   ELSE LM.ADDRESS2 END SHIPPING_ADDRESS3,

         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.area_code   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.shipping_area_code 
		   ELSE lm.AREA_CODE   END SHIPPING_AREA_CODE,
         

         CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.AREA_NAME  
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_AREA_NAME 
		   ELSE lm.AREA_NAME  END SHIPPING_AREA_NAME,

		  CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHct.CITY   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN a.SHIPPING_CITY_NAME 
		   ELSE lm.CITY    END SHIPPING_CITY_NAME,

		  CASE WHEN @NPICKINGSHIPPINGADDRESS=1 THEN SHAR.pincode   
	       WHEN @NPICKINGSHIPPINGADDRESS=2 THEN ISNULL(a.SHIPPING_PIN,'') 
		   ELSE lm.PINCODE    END SHIPPING_PIN,

		  IND.AUTO_SRNO,IND.HSN_CODE,PRODUCT_CODE ,IND.GST_PERCENTAGE ,
		  IND.NET_RATE ,A.NET_AMOUNT ,
		  Taxable_Value=(select sum(ind.xn_value_with_gst) from IND01106 ind (nolock) where inv_id=@CXNID),
          a.ewaydistance,
		  tr.vehicle_no,tr.mode ,A.DOMESTIC_FOR_EXPORT

  
	INTO #TMPINM
	FROM INM01106 A (NOLOCK)
	join ind01106 ind(nolock) on a.inv_id=ind.inv_id 
	JOIN LOCATION   L(NOLOCK) ON A.Location_code/*LEFT(A.INV_ID,2)*//*Rohit 06-11-2024*/=L.DEPT_ID 
	JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=L.AREA_CODE
	JOIN CITY CT  (NOLOCK) ON CT.CITY_CODE=AR.CITY_CODE 
	JOIN STATE ST (NOLOCK) ON CT.STATE_CODE =st.STATE_CODE 
	JOIN COMPANY C ON C.COMPANY_CODE='01'
	JOIN LMV01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
	left join #TRANSPORTER1 tr on tr.REF_MEMO_ID =a.inv_id 
	left join LM01106 shlm (nolock) on shlm.AC_CODE =a.SHIPPING_AC_CODE 
    left join LMP01106 shlmp (nolock) on shlmp.AC_CODE =shlm.AC_CODE 
    LEFT JOIN AREA shAR (NOLOCK) ON shlmp.AREA_CODE=shAR.AREA_CODE                        
    LEFT JOIN CITY shCT (NOLOCK) ON shAR.CITY_CODE=shCT.CITY_CODE  
    LEFT JOIN GST_STATE_MST shCS (NOLOCK) ON shCS.GST_STATE_CODE=shLMP.AC_GST_STATE_CODE      
    LEFT JOIN GST_STATE_MST SHP (NOLOCK) ON ISNULL(SHP.GST_STATE_NAME,'')=ISNULL(a.SHIPPING_STATE_NAME,'')    
	WHERE a.INV_ID=@CXNID and l.loc_gst_no<>lm.ac_gst_no
	and l.loc_gst_no<>'' and a.XN_ITEM_TYPE <>5



	 IF OBJECT_ID ('TEMPDB..#TMPERROR','U') IS NOT NULL  
     DROP TABLE #TMPERROR  
  
  CREATE TABLE #TMPERROR (Sr int,ColumnName varchar(1000),ERRMSG VARCHAR(1000))  

  --***************seller Details validation ************
  INSERT INTO #TMPERROR(Sr,COLUMNNAME,ERRMSG)  
  SELECT top 1 1,'Inv_no:-'+INV_NO,'Invoice No Should be  1 to 16 Charecter Length Please check' FROM #TMPINM WHERE LEN(INV_NO ) NOT BETWEEN 1 AND 16 union all
  SELECT top 1 2,'Inv_Dt:-','Invoice Date Can Not be Blank Please check' FROM #TMPINM WHERE isnull(inv_dt,'')='' union all
  SELECT top 1 3,'Dept_name:-'+DEPT_NAME,'Seller Legal Name Should be  3 to 100 Charecter Length Please Check' FROM #TMPINM WHERE LEN(DEPT_NAME ) NOT BETWEEN 3 AND 100 union all
  SELECT top 1 4,'Company_name:-'+COMPANY_NAME,'Seller Trade Name Should be  3 to 100 Charecter Length Please Check' FROM #TMPINM WHERE LEN(COMPANY_NAME ) NOT BETWEEN 3 AND 100 union all

  SELECT top 1 5,'ADDRESS1:-'+isnull(ADDRESS1,''),'Seller ADDRESS1  Can Not be Blank Please check' FROM #TMPINM WHERE isnull(ADDRESS1,'')='' union all
--  SELECT top 1 6,'Area_Name:-'+isnull(AREA_NAME,''),'Location Area Can Not be Blank Please check' FROM #TMPINM WHERE isnull(AREA_NAME,'')='' union all
  SELECT top 1 7,'PIN:-'+isnull(PINCODE,''),'Location Pin Can Not be Blank Please check' FROM #TMPINM WHERE isnull(PINCODE,'')='' union all
  SELECT top 1 8,'state_code:-'+isnull(gst_state_code,''),'Location State Can Not be Blank Please check' FROM #TMPINM WHERE isnull(gst_state_code,'') in('','00') --union all


  --***************buyer Details validation ************
  INSERT INTO #TMPERROR(Sr,COLUMNNAME,ERRMSG)  
  SELECT top 1 9,'AC_GST_NO:-','Party Gst No Should be  3 to 15 Charecter Length Please Check' FROM #TMPINM WHERE ISNULL(BGSTIN,'') <>'' AND LEN(BGSTIN ) NOT BETWEEN 3 AND 15 union all
  SELECT top 1 10,'AC_NAME:-','Party Name Can Not be Blank' FROM #TMPINM WHERE isnull(BLGLNM,'')='' union all
  SELECT top 1 11,'POS:-','Party Location Can Not be Blank' FROM #TMPINM WHERE isnull(BPOS,'')='' union all
  SELECT top 1 12,'ADDRESS1:-'+isnull(BADDR1,''),'Buyer ADDRESS1  Can Not be Blank Please check' FROM #TMPINM WHERE isnull(BADDR1,'')='' union all

  SELECT top 1 13,'Area_Name:-'+isnull(BLoc,''),'Buyer Area Name Can Not be Blank Please check' FROM #TMPINM WHERE isnull(BLoc,'')='' union all
  SELECT top 1 14,'state_code:-'+isnull(BStcd,''),'Buyer State Can Not be Blank Please check' FROM #TMPINM WHERE isnull(BStcd,'') in('','00') 
  --
   --SELECT top 1 11,'Buyer Email:-','Party Email Can Not be Blank' FROM #TMPINM WHERE isnull(BEm,'')='' union all
   --SELECT top 1 11,'Buyer Phone:-','Party Phone Can Not be Blank' FROM #TMPINM WHERE isnull(BPH,'')='' 

  --BPH

	--***************Dispatch Details validation ************
	IF @CDONT_ASK_FOR_EWAY_BILL_GENERATION_DURING_EINVOICING<>'1'
	BEGIN
		INSERT INTO #TMPERROR(Sr,COLUMNNAME,ERRMSG)  
		SELECT top 1 15,'Angadia Name:-','Dispatched Company Name Can Not be Blank' FROM #TMPINM WHERE isnull(TRANSPORTER_NAME,'')='' union all
		SELECT top 1 16,'Angadia Address1:-','Dispatched Company Address1 Can Not be Blank' FROM #TMPINM WHERE isnull(Angadia_Add1,'')='' union all

		SELECT top 1 16,'Angadia Address2:-','Dispatched Company Address2 Can Not be Blank' FROM #TMPINM WHERE isnull(Angadia_Add2,'')='' union all

		--SELECT top 1 17,'Angadia Area (Location):-','Dispatched Area Name Can Not be Blank ' FROM #TMPINM WHERE isnull(Dis_Area_name,'')=''  union all
		SELECT top 1 18,'Angadia Pin:-','Dispatched PinCode Can Not be Blank ' FROM #TMPINM WHERE isnull(Dis_pin,'')=''  union all
		SELECT top 1 19,'Angadia State:-','Dispatched State Code  Can Not be Blank ' FROM #TMPINM WHERE isnull(DIS_State,'') in('','00')
	END
 

  --***************Shipping Details validation ************
  INSERT INTO #TMPERROR(Sr,COLUMNNAME,ERRMSG)   
   -- SELECT top 1 20,'Shipping GstNo :-','Shipping GstNo Can Not be Blank' FROM #TMPINM WHERE isnull(SHIPPING_Gst_No,'')='' and party_state_code not in('96') union all
	SELECT top 1 21,'Shipping Party Name :-','Shipping Party Name Can Not be Blank' FROM #TMPINM WHERE isnull(SHIPPINg_AC_NAME,'')='' and party_state_code not in('96') union all 
	SELECT top 1 22,'Shipping Address1 :-','Shipping Address1 Can Not be Blank' FROM #TMPINM WHERE isnull(SHIPPING_ADDRESS,'')='' union all 
	--SELECT top 1 23,'Shipping AreaName :-','Shipping Area Can Not be Blank' FROM #TMPINM WHERE isnull(SHIPPING_AREA_NAME,'')='' union all 
	SELECT top 1 24,'Shipping PinCode :-','Shipping PinCode Can Not be Blank' FROM #TMPINM WHERE isnull(SHIPPING_PIN,'')='' union all 
	SELECT top 1 25,'Shipping StateCode :-','Shipping StateCode Can Not be Blank' FROM #TMPINM WHERE isnull(SHIPPING_STATE_CODE,'') in('','00')

	 --***************Item Details validation ************
   INSERT INTO #TMPERROR(Sr,COLUMNNAME,ERRMSG)  
  -- SELECT top 1 26,'Item SRNo  :-','Item SrNo Can Not be Blank' FROM #TMPINM WHERE isnull(AUTO_SRNO,0)=0 union all
   SELECT top 1 27,'Item Hsn Code  :-','Item Hsn Code Can Not be Blank' FROM #TMPINM WHERE isnull(hsn_code,'') in('','0000000000') union all
  -- SELECT top 1 28,'Item Gst Percentage  :-','Item Gst Percentage Can Not be Blank' FROM #TMPINM WHERE isnull(gst_percentage ,0)=0 and isnull(DOMESTIC_FOR_EXPORT,0)<>3 union all
   SELECT top 1 29,'Item Net Rate  :-','Item Net Rate Can Not be Blank' FROM #TMPINM WHERE isnull(net_rate ,0)=0 union all
   SELECT top 1 30,'Item Code  :-','Item Code Can Not be Blank' FROM #TMPINM WHERE isnull(PRODUCT_CODE,'') ='' union all
   SELECT top 1 31,'Item Net Amount  :-','Item Net Amount Can Not be Blank' FROM #TMPINM WHERE isnull(NET_AMOUNT ,0)=0 union all
   SELECT top 1 32,'Taxable Value  :-','Taxable Value Can Not be Blank' FROM #TMPINM WHERE isnull(Taxable_Value  ,0)=0 
--   SELECT top 1 32,'DIstance  :-','Distance Between Source & destination Can Not be Blank' FROM #TMPINM WHERE isnull(ewaydistance  ,0)=0 

    --***************eway details Details validation ************
	 INSERT INTO #TMPERROR(Sr,COLUMNNAME,ERRMSG)  
	 SELECT top 1 33,'vehicle_no :-','vehicle_no Should be Length of 4 and 20 ' FROM #TMPINM WHERE len(isnull(vehicle_no,'')) NOT between 4 and 20  and mode =1 and 1=2
   --


  if exists (select top 1'u' from #TMPERROR)
  begin
  select @CXNID as memo_id,'EINVOICE' as PRODUCT_CODE,0 as QUANTITY_IN_STOCK, COLUMNNAME,ERRMSG from #TMPERROR
  order by sr 
  set @cerrmsg='data validation Failed'

  end


   
  


END 
-- 'END OF CREATING PROCEDURE VALIDATEXN_EINVOICE'


