CREATE PROCEDURE SP3S_IMPORT_SLS_DATA_UPLOAD_NEW
(    
 @iDateMode		INT,
 @CLOCID VARCHAR(10),          
 @NMODE INT=0      ,    
 @CSPID VARCHAR(50) ,
 @CUSER_CODE CHAR(7)= '0000000',
 @memo_no	VARCHAR(50)='',
 @memo_dt	VARCHAR(50)='',
 @CBINID	VARCHAR(10)='000'
)    
AS          
BEGIN          
  DECLARE @DSEARCHXNDT DATETIME,@CSOURCEDB VARCHAR(200),@CTEMPTABLENAME VARCHAR(200),@CTEMPTABLE VARCHAR(200),          
  @CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CERRMSG VARCHAR(MAX),@DMEMODT DATETIME,          
  @CAPPLYSALESSETUP VARCHAR(2),@CBINSALES VARCHAR(10),@CGENVENDOREANCODES VARCHAR(2),@NIMPORTMODE INT,          
  @BSTOCKNOTFOUND BIT,@BLOOP BIT,@CEANNO VARCHAR(50),@CROWID VARCHAR(40),@NPENDINGQTY NUMERIC(10,2),@CBILLNO VARCHAR(50),          
  @CPRODUCTCODE VARCHAR(50),@CFINYEAR VARCHAR(10),@NQTY NUMERIC(10,2),@CAPPLYMINDISCOUNT VARCHAR(2)    ,
  @CheckEffectiveSaleSetup BIT  ,@cRETAIN_EXCEL_NRV_SISLOC_SALEIMP VARCHAR(1)     
            
BEGIN TRY          
  if ISNULL(@CUSER_CODE,'0000000') ='0000000'
	SELECT @CUSER_CODE=B.user_code
	FROM NEW_APP_LOGIN_INFO A (nolock) 
	JOIN USERS B (NOLOCK) ON B.username=A.LOGIN_NAME
	WHERE SPID=@@SPID 

	if ISNULL(@CUSER_CODE,'') =''
	SET @CUSER_CODE ='0000000'

            
  DECLARE @TERRORDETAILS TABLE          
  (          
   PRODUCT_CODE VARCHAR(50),          
   REF_NO VARCHAR(50),          
   DEPT_ID VARCHAR(5),          
   ERROR_MSG VARCHAR(MAX)           
  )       
            
  SET @CSTEP=5       
      
  -- delete from  PRODUCT_CODE_NOT_FOUND    
      
  --INSERT INTO PRODUCT_CODE_NOT_FOUND     
  --SELECT DISTINCt  A.PRODUCT_CODE,@CLOCID     
  --FROM SLS_IMPORT_DATA A(nolock)     
  --LEFT JOIN SKU  B(nolock) On A.PRODUCT_CODE=B.PRoDUCT_COdE    
  --WHERE A.SP_ID=@CSPID AND B.PRODUCt_CODE IS NULL      
  --AND A.PRODUCT_CoDE NOT IN (SElECT PRODUCT_CoDE FROm PRODUCT_CODE_NOT_FOUND(nolock))    
      
  --DELETE FROM SLS_IMPORT_DATA WHERE SP_ID=@CSPID AND PRODUCT_CODE NOT IN (SELECT PRODUCT_CODE FROM SKU)    
    
	 IF OBJECT_ID('TEMPDB..#CheckEffectiveSaleSetup','U') IS NOT NULL            
		DROP TABLE #CheckEffectiveSaleSetup  

	CREATE TABLE #CheckEffectiveSaleSetup(EffectiveSaleSetup BIT)


  IF OBJECT_ID('TEMPDB..#VEAN_PMT','U') IS NOT NULL          
   DROP TABLE #VEAN_PMT          
           
  IF OBJECT_ID('TEMPDB..#TERROR','U') IS NOT NULL          
   DROP TABLE #TERROR          
            
  SELECT PRODUCT_CODE,ERROR_MSG INTO #TERROR FROM SLS_MBODATA_ERROR_DETAILS WHERE 1=2          
           
  SELECT VENDOR_EAN_NO AS EAN_NO,A.PRODUCT_CODE,QUANTITY_IN_STOCK AS STOCK_QTY,QUANTITY_IN_STOCK AS SOLD_QTY          
  INTO #VEAN_PMT     
  FROM PMT01106 A (NOLOCK)          
  JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE WHERE 1=2          
              
         
            
  SELECT @NIMPORTMODE=ISNULL(MBOSLS_IMPORT_MODE,0) FROM LOCATION WHERE DEPT_ID=@CLOCID           
  --IF @NIMPORTMODE>1          
  --BEGIN          
  --  EXEC SP3S_GETMBO_BARCODEWISESTK @CLOCID,@NIMPORTMODE          
              
  --  INSERT @TERRORDETAILS ( PRODUCT_CODE,ERROR_MSG )           
  --  SELECT PRODUCT_CODE,ERROR_MSG  FROM #TERROR          
            
  --  SELECT TOP 1 @CERRMSG=ISNULL(ERROR_MSG,'') FROM @TERRORDETAILS          
  --  IF ISNULL(@CERRMSG,'')<>''          
  --GOTO END_PROC          
                 
  --  DELETE FROM @TERRORDETAILS           
  --END          
        
  --SELECT * FROM #VEAN_PMT WHERE EAN_NO='8907559343355'      
      
                 
  IF OBJECT_ID('TEMPDB..#SLSIMPORT','U') IS NOT NULL          
   DROP TABLE #SLSIMPORT          
             
  IF OBJECT_ID('TEMPDB..#SLSTMP','U') IS NOT NULL          
   DROP TABLE #SLSTMP          
    
 IF OBJECT_ID('TEMPDB..#SLSIMPORT_CUSTDYM','U') IS NOT NULL          
   DROP TABLE #SLSIMPORT_CUSTDYM      
           
  SET @CSTEP=10          
            
  CREATE TABLE #SLSIMPORT          
  (          
 SR_NO   NUMERIC(18)          
 ,BILL_NO   VARCHAR(MAX)          
 ,CM_DT   VARCHAR(MAX)          
 ,DEPT_ID   VARCHAR(MAX)          
 ,PRODUCT_CODE VARCHAR(MAX)          
 ,QUANTITY  VARCHAR(MAX)          
 ,AMOUNT   VARCHAR(MAX)          
 ,CANCELLED  BIT          
 ,MRP             NUMERIC(14,2)          
 ,DISCOUNT_AMT    NUMERIC(14,2)          
 ,ERROR_MESSAGE   VARCHAR(MAX)          
 ,FIN_YEAR  VARCHAR(10)          
 ,CASH            NUMERIC(12,2)          
 ,CC_AMOUNT       NUMERIC(12,2)          
 ,CC_NAME         VARCHAR(MAX)          
 ,BIN_ID   VARCHAR(5)          
 ,CMM_DISCOUNT_AMOUNT NUMERIC(14,2)    
 ,CMM_OTHER_CHARGES NUMERIC(14,2)    
 ,HSN_CODE   VARCHAR(50)          
 ,gst_percentage NUMERIC(14,2)    
 ,igst_amount NUMERIC(14,2)    
,cgst_amount NUMERIC(14,2)    
 ,sgst_amount NUMERIC(14,2)    
 ,REMARKS VARCHAR(200)    
 ,NET NUMERIC(14,2)    
 ,NET_AMOUNT NUMERIC(14,2) 
 ,NET_SALE  NUMERIC(14,2)
 ,party_state_code	VARCHAR(20)
 ,sisloc_eoss_discount_percentage NUMERIC(5,2)
 ,sisloc_eoss_discount_amount NUMERIC(10,2)
 ,sisloc_mrp NUMERIC(10,2)
 ,sis_net NUMERIC(10,2)
 ,sisloc_gst_percentage		NUMERIC(5,2)
 ,sisloc_taxable_value		NUMERIC(10,2)
 ,sisloc_lgst_amount		NUMERIC(10,2)
 ,sisloc_igst_amount		NUMERIC(10,2)
 ,xn_value_without_gst		numeric(10,2)
 ,PAYMODE_NAME			VARCHAR(100)
	)          
  CREATE TABLE #SLSIMPORT_CUSTDYM          
  (          
 SR_NO    NUMERIC(18)       
 ,USER_CUSTOMER_CODE  VARCHAR(MAX)       
 ,customer_fname  VARCHAR(MAX)       
 ,customer_lname  VARCHAR(MAX)       
 ,address0   VARCHAR(MAX)       
 ,address1   VARCHAR(MAX)       
 ,address2   VARCHAR(MAX)       
 ,address9   VARCHAR(MAX)    
 ,area    VARCHAR(MAX)       
 ,city    VARCHAR(MAX)       
 ,state    VARCHAR(MAX)       
 ,CUS_GST_NO  VARCHAR(MAX)       
 ,CUSTOMER_CODE  VARCHAR(MAX)       
 ,area_CODE    VARCHAR(MAX)       
 ,city_Code    VARCHAR(MAX)       
 ,state_CODE    VARCHAR(MAX)       
 ,cus_gst_state  VARCHAR(MAX)      
 ,EMAIL   VARCHAR(MAX)     
 )    
    
    DELETE FROM SLS_IMPORT_DATA WHERE  sp_id=@CSPID AND PRODUCT_CODE NOT IN (SELECT PRODUCT_CODE FROM SKU)

	if(@iDateMode=1)
	BEGIN
		update SLS_IMPORT_DATA SET memo_dt=CONVERT(DATETIME,memo_dt,105)  where sp_id=@CSPID AND memo_no=@memo_no AND memo_dt=@memo_dt
		SET @memo_dt=CONVERT(DATETIME,@memo_dt,105) 
	END
	if(@iDateMode=5)
	BEGIN
		update SLS_IMPORT_DATA SET memo_dt=CONVERT(DATETIME,memo_dt,110)  where sp_id=@CSPID AND memo_no=@memo_no AND memo_dt=@memo_dt
		SET @memo_dt=CONVERT(DATETIME,@memo_dt,105) 
	END

	UPDATE A SET A.errormsg=ISNULL(A.errormsg,'')+CHAR(13)+ 'Memo No : '+ ISNULL(@memo_no,'') +' AND memo_dt : '+ISNULL(@memo_dt,'')+' ' +'Quantity should not be zero.'    
	FROM SLS_IMPORT_DATA A  
	WHERE A.SP_ID=@CSPID AND CONVERT(NUMERIC(5,2),ISNULL(A.quantity,0))=0    
	 AND memo_no=@memo_no AND memo_dt=@memo_dt

	UPDATE A SET A.errormsg=ISNULL(A.errormsg,'')+CHAR(13)+ 'Memo No : '+ISNULL(@memo_no,'') +' AND memo_dt : '+ISNULL(@memo_dt,'')+' ' +  'MRP should not be less than NET.'    
	FROM SLS_IMPORT_DATA A    
	WHERE A.SP_ID=@CSPID AND (ABS(CONVERT(NUMERIC(20,2),ISNULL(A.NET,0)))+ABS(CONVERT(NUMERIC(20,2),ISNULL(A.CMD_DISCOUNT_AMOUNT,0))))-ABS(CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)))>5
	AND CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))<>0
	 AND memo_no=@memo_no AND memo_dt=@memo_dt

	 
    
	--SELECT product_code,CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0)), CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)),CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)),CONVERT(NUMERIC(20,2),ISNULL(A.NET,0))
	--FROM SLS_IMPORT_DATA A    
	--WHERE A.SP_ID=@CSPID --AND CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0))<CONVERT(NUMERIC(20,2),ISNULL(A.NET,0))
	----AND CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))<>0
	-- AND memo_no=@memo_no AND memo_dt=@memo_dt

    
	UPDATE A SET A.errormsg=ISNULL(A.errormsg,'')+CHAR(13)+'Memo No : '+ISNULL(@memo_no,'') +' AND memo_dt : '+ISNULL(@memo_dt,'')+' ' +(CASE WHEN B.PRODUCt_CODE IS NULL  THEN 'Product Code not found.' ELSE '' END)    
	FROM SLS_IMPORT_DATA A  
	LEFT JOIN SKU  B(nolock) On A.PRODUCT_CODE=B.PRODUCT_CODE    
	WHERE A.SP_ID=@CSPID AND B.PRODUCt_CODE IS NULL    
	AND memo_no=@memo_no AND memo_dt=@memo_dt
    
	UPDATE A SET A.errormsg=ISNULL(A.errormsg,'')+CHAR(13)+'Memo No : '+ ISNULL(@memo_no,'') +' AND memo_dt : '+ISNULL(@memo_dt,'')+' ' +(CASE WHEN B.HSN_CODE IS NULL  THEN 'HSN Code not found.' ELSE '' END)    
	FROM SLS_IMPORT_DATA A     
	LEFT JOIN HSN_MST  B(nolock) On ISNULL(A.HSN_CODE,'')=B.HSN_CODE    
	WHERE A.SP_ID=@CSPID AND ISNULL(A.HSN_CODE,'')<>'' AND B.HSN_CODE IS NULL
	AND memo_no=@memo_no AND memo_dt=@memo_dt

	UPDATE A SET A.errormsg=ISNULL(A.errormsg,'')+CHAR(13)+'Memo No : '+ ISNULL(@memo_no,'') +' AND memo_dt : '+ISNULL(@memo_dt,'')+' ' +(CASE WHEN B.AC_CODE IS NULL  THEN 'Ledger('+A.ac_name+') not found.' ELSE '' END)    
	FROM SLS_IMPORT_DATA A     
	LEFT JOIN lm01106  B(nolock) On ISNULL(A.AC_NAME,'')=B.AC_NAME    
	WHERE A.SP_ID=@CSPID AND ISNULL(A.AC_NAME,'')<>'' AND B.AC_CODE IS NULL
	AND memo_no=@memo_no AND memo_dt=@memo_dt

       
  INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG )           
    SELECT PRODUCT_CODE,MEMO_NO AS  REF_NO,DEPT_ID,errormsg          
    FROM SLS_IMPORT_DATA A (NOLOCK)          
    WHERE A.SP_ID=@CSPID AND ISNULL(A.errormsg,'') <>''    
	AND memo_no=@memo_no AND memo_dt=@memo_dt
    
    
IF EXISTS (SELECT PRODUCT_CODE FROM @TERRORDETAILS )    
BEGIN    
   GOTO END_PROC       
END   

	
	UPDATE A SET A.net=(ABS(CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0)))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)))-CONVERT(NUMERIC(20,2),ISNULL(A.CMD_DISCOUNT_AMOUNT,0))
	FROM SLS_IMPORT_DATA A    
	WHERE A.SP_ID=@CSPID AND (ABS(CONVERT(NUMERIC(20,2),ISNULL(A.NET,0)))+ABS(CONVERT(NUMERIC(20,2),ISNULL(A.CMD_DISCOUNT_AMOUNT,0))))-ABS(CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)))>0
	AND CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))<>0
	 AND memo_no=@memo_no AND memo_dt=@memo_dt


select @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP= value from config where config_option='RETAIN_EXCEL_NRV_SISLOC_SALEIMP'

SET @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP=ISNULL(@cRETAIN_EXCEL_NRV_SISLOC_SALEIMP,'0')

  SET @CSTEP=10.1            
--BEGIN TRANSACTION          

 INSERT INTO #SLSIMPORT_CUSTDYM(SR_NO,USER_CUSTOMER_CODE ,customer_fname,customer_lname,address0,address1,address2,address9,area,city,state,cus_gst_state,CUSTOMER_CODE,CUS_GST_NO,EMAIL)    
 SELECT 1, A.USER_CUSTOMER_CODE ,A.customer_fname,A.customer_lname,A.address0,A.address1,A.address2,A.address9,A.area,A.city,A.state,A.cus_gst_state,ISNULL(B.customer_code,'') AS CUSTOMER_CODE    
 ,A.CUS_GST_NO,A.EMAIL    
 FROM SLS_IMPORT_DATA A  (NOLOCK)         
 LEFT OUTER JOIN CUSTDYM B (NOLOCK)  ON B.user_customer_code=A.USER_CUSTOMER_CODE    
 WHERE A.SP_ID=@CSPID AND ISNULL(A.USER_CUSTOMER_CODE,'')<>''  
 AND memo_no=@memo_no AND memo_dt=@memo_dt
    
 DECLARE @cState VARCHAR(50),@cCity VARCHAR(50),@cArea VARCHAR(50),@cState_Code VARCHAR(50),@cCity_Code VARCHAR(50),@cArea_Code VARCHAR(50)    
    
 SELECT @cState=state,@cCity =City,@cArea =area FROM #SLSIMPORT_CUSTDYM    
    
    
 IF EXISTS(SELECT 'U' FROM STATE(NOLOCK) WHERE state =ISNULL(@cstate,''))  AND  ISNULL(@cstate,'')<>''
 BEGIN    
 UPDATE A SET A.STATE_CODE =B.state_CODE     
 FROM #SLSIMPORT_CUSTDYM A    
 JOIN STATE B ON B.state=ISNULL(@cstate,'')    
 END    
 ELSE   IF   ISNULL(@cstate,'')<>''
 BEGIN    
 EXEC GETNEXTKEY_OPT 'STATE', 'STATE_CODE', 7, @CLOCID, 1,'',0, 'KEYS',@cstate_code OUTPUT         
    
 INSERT INTO STATE(state_code,state,last_update,region_code,octroi_percentage,inactive,company_code,Uploaded_to_ActivStream)    
 SELECT TOP 1 ISNULL(@cstate_code,'') ,state,GETDATE(),'0000000', 0, 0,'01',0    
 FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@cstate,'')<>''    
    
 UPDATE A SET A.STATE_CODE =@cState_Code    
 FROM #SLSIMPORT_CUSTDYM A    
 JOIN STATE B ON B.state=ISNULL(@cstate,'')    
    
 END    
 ELSE
 BEGIN
	UPDATE #SLSIMPORT_CUSTDYM SET STATE_CODE ='0000000' WHERE ISNULL(STATE_CODE,'')=''
 END
    
 SET @CSTEP=10.2       
 IF EXISTS(SELECT 'U' FROM CITY(NOLOCK) WHERE CITY =ISNULL(@cCity,'')) AND    ISNULL(@cCity,'')<>''
 BEGIN    
 UPDATE A SET A.city_Code =B.CITY_CODE     
 FROM #SLSIMPORT_CUSTDYM A    
 JOIN CITY B ON B.city=ISNULL(@cCity,'')    
 END    
 ELSE    IF ISNULL(@cCity,'')<>''
 BEGIN    
 --DECLARE @cCity_Code VARCHAR(MAX)    
 EXEC GETNEXTKEY_OPT 'CITY', 'CITY_CODE', 7, 'JM', 1,'',0,'KEYS',@cCity_Code OUTPUT         
 ----select @cCity_Code as city    
 --SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0    
 --FROM #SLSIMPORT_CUSTDYM    
 INSERT INTO CITY(CITY_CODE,CITY,LAST_UPDATE,state_code,inactive,distt_code,company_code,Uploaded_to_ActivStream)    
 SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0    
 FROM #SLSIMPORT_CUSTDYM where ISNULL(@cCity,'')<>''    
 --SELECT * FROM CITY    
 UPDATE A SET A.CITY_CODE =@cCity_Code    
 FROM #SLSIMPORT_CUSTDYM A    
 JOIN CITY B ON B.CITY=ISNULL(@cCity,'')    
    
 END    
 ELSE
 BEGIN
	UPDATE #SLSIMPORT_CUSTDYM SET CITY_CODE ='0000000' WHERE ISNULL(CITY_CODE,'')=''
 END
    
  SET @CSTEP=10.3              
 IF EXISTS(SELECT 'U' FROM area(NOLOCK) WHERE area_name =ISNULL(@cArea,''))    AND ISNULL(@cArea,'')<>''
 BEGIN    
 UPDATE A SET A.area_CODE =B.area_code     
 FROM #SLSIMPORT_CUSTDYM A    
 JOIN AREA B ON B.area_name=ISNULL(@cArea,'')    
 END    
 ELSE    IF ISNULL(@cArea,'')<>''
 BEGIN    
 EXEC GETNEXTKEY_OPT 'AREA', 'AREA_CODE', 7, @CLOCID, 1,'',0, 'KEYS',@cArea_Code OUTPUT         
    
 INSERT INTO AREA(CITY_CODE,last_update,inactive,company_code,area_code,area_name,pincode)    
 SELECT TOP 1 city_Code ,GETDATE(),0,'01',@cArea_Code, area,''    
 FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@cArea,'')<>''    
    
 UPDATE A SET A.AREA_CODE =@cArea_Code    
 FROM #SLSIMPORT_CUSTDYM A    
 JOIN AREA B ON B.AREA_NAME=ISNULL(@cArea,'')    
 END 
 ELSE
 BEGIN
	--IF EXISTS (SELECT 'U' FROM #SLSIMPORT_CUSTDYM  WHERE ISNULL(AREA_CODE,'')='')
	UPDATE #SLSIMPORT_CUSTDYM SET AREA_CODE ='0000000' WHERE ISNULL(AREA_CODE,'')=''
 END

     
 DECLARE @cCUSTOMER_CODE VARCHAR(50)='000000000000'    
 DECLARE @cAC_CODE VARCHAR(50)='0000000000'    

 SET @CSTEP=10.4
 IF EXISTS(SELECT 'U' FROM #SLSIMPORT_CUSTDYM(NOLOCK) WHERE ISNULL(USER_CUSTOMER_CODE,'')<>'' AND ISNULL(CUSTOMER_CODE,'') ='')    
 BEGIN    
 --DECLARE @cCUSTOMER_CODE VARCHAR(50)    
 EXEC GETNEXTKEY_OPT 'CUSTDYM', 'CUSTOMER_CODE', 12, @CLOCID, 1,'',0,'KEYS', @cCUSTOMER_CODE OUTPUT        
    
 INSERT custdym ( ac_code, address0, address1, address2, address9, area_code, BILL_BY_BILL, card_code, card_name, card_no, company_name,     
cus_gst_no, cus_gst_state_code, customer_code, customer_fname, customer_lname, customer_title, dt_anniversary, dt_birth, dt_card_expiry,     
dt_card_issue, dt_created, email, email2, FirstCardIssueDt, flat_disc_customer, flat_disc_percentage, flat_disc_percentage_during_sales,     
form_no, HO_LAST_UPDATE, HO_SYNCH_LAST_UPDATE, inactive, International_customer, LAST_UPDATE, LOCATION_ID, manager_card, mobile, not_downloaded_from_wizclip,     
old_discount_card_type, OPENING_BALANCE, phone1, phone2, pin, prefix_code, privilege_customer, ref_customer_code, sent_to_ho, Tin_No, uploaded_to_ho,     
user_customer_code, wizclip_last_update )      
SELECT  TOP 1  ''ac_code, ISNULL(address0,''), ISNULL(address1,''), ISNULL(address2,''),ISNULL(address9,'') address9, area_code, 0 BILL_BY_BILL, ''card_code,''card_name, '' card_no, ''company_name, cus_gst_no,     
cus_gst_state cus_gst_state_code,@cCUSTOMER_CODE customer_code, ISNULL(customer_fname,'') customer_fname, ISNULL(customer_lname,'')  customer_lname, ''customer_title, ''dt_anniversary, ''dt_birth, ''dt_card_expiry, ''dt_card_issue,     
''dt_created, ISNULL(email,'') AS EMAIL, ''email2, '' FirstCardIssueDt, 0 flat_disc_customer, 0 flat_disc_percentage, 0 flat_disc_percentage_during_sales, ''form_no, ''HO_LAST_UPDATE,     
'' HO_SYNCH_LAST_UPDATE, 0 inactive,0 International_customer, GETDATE() LAST_UPDATE, @CLOCID LOCATION_ID,0 manager_card,user_customer_code mobile, 0 not_downloaded_from_wizclip, '' old_discount_card_type,     
0 OPENING_BALANCE, '' phone1,'' phone2, '' pin, '' prefix_code, 0 privilege_customer,'000000000000' ref_customer_code,0 sent_to_ho, '' Tin_No, 0 uploaded_to_ho, user_customer_code,     
'' wizclip_last_update     
FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(USER_CUSTOMER_CODE,'')<>''    
    
    
    
     
 UPDATE A SET A.CUSTOMER_CODE =@cCUSTOMER_CODE    
 FROM #SLSIMPORT_CUSTDYM A    
 END    
 ELSE IF EXISTS(SELECT TOP 1 'U' FROM #SLSIMPORT_CUSTDYM(NOLOCK))    
 BEGIN    
 SELECT @cCUSTOMER_CODE =CUSTOMER_CODE FROM #SLSIMPORT_CUSTDYM WHERE  ISNULL(USER_CUSTOMER_CODE,'')<>''    
 END    

 DECLARE @cAC_NAME VARCHAR(200),@nPartyType INT
 SET @nPartyType=1
 SELECT @cAC_NAME=ISNULL(AC_NAME,'') FROM SLS_IMPORT_DATA(NOLOCK) WHERE 	SP_ID=@CSPID AND ISNULL(AC_NAME,'')<>'' AND memo_no=@memo_no AND memo_dt=@memo_dt
 IF ISNULL(@cAC_NAME,'')<>''
 BEGIN    
 SELECT @cAC_CODE =AC_CODE FROM LM01106(NOLOCK) WHERE  ISNULL(AC_NAME,'')=ISNULL(@cAC_NAME,'')
 SET @nPartyType=2
 END    
 ELSE 
 BEGIN    
 SELECT @cAC_CODE ='0000000000'    
 END    

       
  IF OBJECT_ID('TEMPDB..#TMPSLSDISCTAXOPT','U') IS NOT NULL          
   DROP TABLE #TMPSLSDISCTAXOPT           
                   
  SELECT A.PRODUCT_CODE,SUB_SECTION_CODE,A.MRP*A.QUANTITY AS MRPVAL ,A.DISCOUNT_PERCENTAGE,          
  ((A.MRP*A.QUANTITY)-A.NET) AS DISCOUNT_AMOUNT,A.NET,A.ROW_ID AS CMD_ROW_ID,B.USER_CODE,          
  C.SCHEME_NAME AS SLS_TITLE,CONVERT(VARCHAR(MAX),'') AS ERRMSG,CONVERT(VARCHAR(10),'') AS SCHEME_ID,          
  A.ROW_ID,A.TAX_PERCENTAGE,A.TAX_AMOUNT,A.TAX_METHOD,'0000000000' AS TAX_AC_CODE,'0000000000' AS SALE_AC_CODE,          
  B.DISCOUNT_PERCENTAGE AS BILL_LEVEL_DISCOUNT_PERCENTAGE,B.DISCOUNT_AMOUNT AS CMM_DISCOUNT_AMOUNT,          
  A.WEIGHTED_AVG_DISC_PCT,A.WEIGHTED_AVG_DISC_AMT,A.ITEM_ROUND_OFF,          
  B.DISCOUNT_AMOUNT AS BILL_LEVEL_DISCOUNT_AMOUNT,A.BASIC_DISCOUNT_PERCENTAGE,A.BASIC_DISCOUNT_AMOUNT,      
  A.CARD_DISCOUNT_PERCENTAGE,A.CARD_DISCOUNT_AMOUNT ,      
  A.HSN_CODE, A.GST_PERCENTAGE, A.IGST_AMOUNT,       
    A.CGST_AMOUNT,A.SGST_AMOUNT,A.XN_VALUE_WITHOUT_GST,A.XN_VALUE_WITH_GST      
  INTO #TMPSLSDISCTAXOPT     
  FROM CMD01106 A (NOLOCK)          
  JOIN CMM01106 B (NOLOCK) ON A.CM_ID=B.CM_ID          
  JOIN SCHEME_SETUP_DET C ON 1=1          
  JOIN SECTIOND D ON 1=1          
  WHERE 1=2          
                  
  SELECT TOP 1 @CAPPLYSALESSETUP=VALUE FROM CONFIG WHERE CONFIG_OPTION='APPLY_SLSSET_MBOSLS'          
  SET @CAPPLYSALESSETUP=''    
        
  PRINT 'UPDATE ROW ID OF ENTRIES'          
  UPDATE SLS_IMPORT_DATA SET ROW_ID=NEWID(),PROCESSED=0,ERRORMSG=''-- PENDING_QTY=QUANTITY,         
  WHERE DEPT_ID=@CLOCID      AND SP_ID=@CSPID    
  AND memo_no=@memo_no AND memo_dt=@memo_dt
        --SELECT * FROM SLS_IMPORT_DATA   WHERE DEPT_ID=@CLOCID      AND SP_ID=@CSPID    
  --IF @NIMPORTMODE<=1           
  --BEGIN       
  --SELECT '1'    
  --UPDATE SLS_IMPORT_DATA SET MEMO_DT=CONVERT(VARCHAR(20),GETDATE(),111) WHERE ISNULL(MEMO_DT,'')=''         
	--UPDATE  SLS_IMPORT_DATA SET MEMO_DT=CASE WHEN TRY_PARSE(MEMO_DT AS smalldatetime) IS NULL 
	--THEN TRY_PARSE((SUBSTRING(MEMO_DT,4,2) + '/' + SUBSTRING(MEMO_DT,1,2) + '/' +SUBSTRING(MEMO_DT,7,4)) AS smalldatetime)
	--ELSE TRY_PARSE(MEMO_DT AS smalldatetime) END WHERE ISNULL(MEMO_DT,'')<> ''
	--UPDATE  SLS_IMPORT_DATA SET MEMO_DT=CASE WHEN ISDATE(MEMO_DT)=0 
	--THEN CAST((SUBSTRING(MEMO_DT,4,2) + '/' + SUBSTRING(MEMO_DT,1,2) + '/' +SUBSTRING(MEMO_DT,7,4)) AS smalldatetime)
	--ELSE CAST(MEMO_DT AS smalldatetime) END 
	SET @cStep=10.9
	--UPDATE  SLS_IMPORT_DATA SET MEMO_DT= ((SUBSTRING(MEMO_DT,4,2) + '/' + SUBSTRING(MEMO_DT,1,2) + '/' +SUBSTRING(MEMO_DT,7,4)))
	-- WHERE ISNULL(MEMO_DT,'')<>'' 
    
    SET @CCMD=N'SELECT 0 AS SR_NO,MEMO_NO AS BILL_NO,MEMO_DT AS CM_DT,DEPT_ID,A.PRODUCT_CODE,QUANTITY,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS AMOUNT,          
    CAST(ISNULL(CANCELLED,0) AS BIT) AS CANCELLED,'''' AS ERROR_MESSAGE,B.MRP AS MRP,
	CAST (0 AS NUMERIC(14,2)) AS DISCOUNT_AMT,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) CASH,0 CC_AMOUNT,'''' CC_NAME ,A.CMM_DISCOUNT_AMOUNT,A.CMM_OTHER_CHARGES,
	ISNULL(A.HSN_CODE  ,B.HSN_CODE) AS HSN_CODE ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount     
	,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS NET,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS NET_AMOUNT,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS NET_SALE,
	ISNULL(A.REMARKS,'''') AS REMARKS,ISNULL(cus_gst_state,'''') AS party_state_code
	,CAST (A.NET AS NUMERIC(14,2)) AS SIS_NET,CAST (0 AS NUMERIC(14,2)) AS SISLOC_EOSS_DISCOUNT_PERCENTAGE
	,ISNULL(A.CMD_DISCOUNT_AMOUNT,0) AS SISLOC_EOSS_DISCOUNT_AMOUNT,ISNULL(A.MRP,0) AS SISLOC_MRP
	,ISNULL(A.gst_percentage,0) sisloc_gst_percentage,A.xn_value_without_gst AS sisloc_taxable_value,ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0)  AS sisloc_lgst_amount,ISNULL(A.igst_amount,0) AS sisloc_igst_amount
	 ,CAST (0 AS NUMERIC(14,2)) AS xn_value_without_gst,ISNULL(A.PAYMODE_NAME,'''') AS PAYMODE_NAME
    FROM SLS_IMPORT_DATA A  (NOLOCK)         
    JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE 
	WHERE A.SP_ID='''+@CSPID+''' AND memo_no='''+@memo_no + ''' AND memo_dt='''+ @memo_dt+''''
	--AND DEPT_ID='''+@CLOCID+''''          
	/*
   if @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP='1'
	SET @CCMD=N'SELECT 0 AS SR_NO,MEMO_NO AS BILL_NO,MEMO_DT AS CM_DT,DEPT_ID,A.PRODUCT_CODE,QUANTITY,A.NET AS AMOUNT,          
    CAST(ISNULL(CANCELLED,0) AS BIT) AS CANCELLED,'''' AS ERROR_MESSAGE,ISNULL(A.MRP,(ISNULL(A.CMD_DISCOUNT_AMOUNT,0)+A.NET)/QUANTITY) AS MRP,
	ISNULL(A.CMD_DISCOUNT_AMOUNT,0) AS DISCOUNT_AMT,A.NET CASH,0 CC_AMOUNT,'''' CC_NAME ,A.CMM_DISCOUNT_AMOUNT,A.CMM_OTHER_CHARGES,
	ISNULL(A.HSN_CODE  ,B.HSN_CODE) AS HSN_CODE ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount     
	,A.NET,ISNULL(A.NET_AMOUNT,A.NET) AS NET_AMOUNT,A.NET AS NET_SALE,ISNULL(A.REMARKS,'''') AS REMARKS,ISNULL(cus_gst_state,'''') AS party_state_code
	,CAST (B.MRP  * A.quantity AS NUMERIC(14,2)) AS SIS_NET,CAST (0 AS NUMERIC(14,2)) AS SISLOC_EOSS_DISCOUNT_PERCENTAGE
	,CAST (0 AS NUMERIC(14,2)) AS SISLOC_EOSS_DISCOUNT_AMOUNT,ISNULL(B.MRP,0) AS SISLOC_MRP
    FROM SLS_IMPORT_DATA A  (NOLOCK)         
    JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE WHERE A.SP_ID='''+@CSPID+'''' --AND DEPT_ID='''+@CLOCID+''''    
	*/
	if @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP='1'
	SET @CCMD=N'SELECT 0 AS SR_NO,MEMO_NO AS BILL_NO,MEMO_DT AS CM_DT,DEPT_ID,A.PRODUCT_CODE,QUANTITY,A.NET AS AMOUNT,          
    CAST(ISNULL(CANCELLED,0) AS BIT) AS CANCELLED,'''' AS ERROR_MESSAGE,ABS(ISNULL(A.MRP,(CASE WHEN QUANTITY<0 THEN -1 * ABS(ISNULL(A.CMD_DISCOUNT_AMOUNT,0)) ELSE ABS(ISNULL(A.CMD_DISCOUNT_AMOUNT,0)) END)+A.NET)/QUANTITY) AS MRP,
	(CASE WHEN QUANTITY<0 THEN -1 * ABS(ISNULL(A.CMD_DISCOUNT_AMOUNT,0)) ELSE ABS(ISNULL(A.CMD_DISCOUNT_AMOUNT,0)) END) AS DISCOUNT_AMT,A.NET CASH,0 CC_AMOUNT,'''' CC_NAME ,ABS(A.CMM_DISCOUNT_AMOUNT) AS CMM_DISCOUNT_AMOUNT,A.CMM_OTHER_CHARGES,
	ISNULL(A.HSN_CODE  ,B.HSN_CODE) AS HSN_CODE ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount     
	,A.NET,ISNULL(A.NET_AMOUNT,A.NET) AS NET_AMOUNT,A.NET AS NET_SALE,ISNULL(A.REMARKS,'''') AS REMARKS,ISNULL(cus_gst_state,'''') AS party_state_code
	,CAST (B.MRP  * A.quantity AS NUMERIC(14,2)) AS SIS_NET,CAST (0 AS NUMERIC(14,2)) AS SISLOC_EOSS_DISCOUNT_PERCENTAGE
	,CAST (0 AS NUMERIC(14,2)) AS SISLOC_EOSS_DISCOUNT_AMOUNT,ISNULL(B.MRP,0) AS SISLOC_MRP
	,ISNULL(A.gst_percentage,0) sisloc_gst_percentage,CAST (0 AS NUMERIC(14,2)) AS sisloc_taxable_value,ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0)  AS sisloc_lgst_amount,ISNULL(A.igst_amount,0) AS sisloc_igst_amount
	,CASE WHEN A.xn_value_without_gst IS NOT NULL THEN A.xn_value_without_gst
	WHEN A.gst_percentage IS NOT NULL THEN CONVERT(NUMERIC(14,2), (A.NET * A.GST_PERCENTAGE)/(100+A.GST_PERCENTAGE))
	ELSE A.NET-(ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0)+ISNULL(A.igst_amount,0)) END xn_value_without_gst,ISNULL(A.PAYMODE_NAME,'''') AS PAYMODE_NAME
    FROM SLS_IMPORT_DATA A  (NOLOCK)         
    JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE 
	WHERE A.SP_ID='''+@CSPID+''' AND memo_no='''+@memo_no + ''' AND memo_dt='''+ @memo_dt+'''' --AND DEPT_ID='''+@CLOCID+''''    

    PRINT @CCMD          

	--EXEC SP_EXECUTESQL @CCMD 
            
    SET @CSTEP=25          
    INSERT #SLSIMPORT (SR_NO,BILL_NO,CM_DT,DEPT_ID,PRODUCT_CODE,QUANTITY,AMOUNT,CANCELLED,ERROR_MESSAGE ,MRP,DISCOUNT_AMT,CASH,CC_AMOUNT,CC_NAME,CMM_DISCOUNT_AMOUNT,
	CMM_OTHER_CHARGES, HSN_CODE   ,gst_percentage ,igst_amount ,cgst_amount,sgst_amount,NET,NET_AMOUNT,NET_SALE,REMARKS,party_state_code, sis_net,
	sisloc_eoss_discount_percentage,sisloc_eoss_discount_amount,sisloc_mrp ,sisloc_gst_percentage,sisloc_taxable_value,sisloc_lgst_amount,sisloc_igst_amount,xn_value_without_gst,PAYMODE_NAME)            
    EXEC SP_EXECUTESQL @CCMD          
            --SELECT * FROM #SLSIMPORT
    SET @CSTEP=30    
          UPDATE #SLSIMPORT SET CM_DT=CONVERT(VARCHAR(20),GETDATE(),111) WHERE ISNULL(CM_DT,'')=''         
                  
    UPDATE #SLSIMPORT SET FIN_YEAR='01'+DBO.FN_GETFINYEAR(CM_DT)     
	
	--UPDATE #SLSIMPORT SET CM_DT=CONVERT(VARCHAR(20),cm_dt,111) --WHERE ISNULL(CM_DT,'')='' 
--select * from       #SLSIMPORT     
--return     
  --  UPDATE SLS_IMPORT_DATA SET PROCESSED = 1 WHERE DEPT_ID=@CLOCID AND   SP_ID=@CSPID    
  --  GOTO LBLIMPORTSLS          
  --END          
        --select CONVERT(VARCHAR(20),GETDATE(),111)
  --SET @BLOOP=0          
         --SELECT CONVERT(VARCHAR(20),GETDATE(),111)  
  --SET @CSTEP=35          
  --WHILE @BLOOP=0          
  --BEGIN          
              
  --  SET @CEANNO=''          
              
  --  SET @CSTEP=40           
  --  SELECT TOP 1 @CEANNO=PRODUCT_CODE,@CROWID=A.ROW_ID,@NQTY=QUANTITY,@CBILLNO=A.MEMO_NO,-- ,@NPENDINGQTY=ABS(A.PENDING_QTY)         
  --  @CFINYEAR='01'+DBO.FN_GETFINYEAR(A.MEMO_DT)          
  --  FROM SLS_IMPORT_DATA A WHERE DEPT_ID=@CLOCID AND PROCESSED=0     AND   SP_ID=@CSPID      
              
  --  IF ISNULL(@CEANNO,'')=''          
  -- GOTO LBLIMPORTSLS          
              
  --  WHILE @NPENDINGQTY>0          
  --  BEGIN          
  --  SET @CPRODUCTCODE=''          
                 
  --  SET @CSTEP=45          
  --  IF @NQTY>0          
  --  BEGIN          
  --  SELECT TOP 1 @CPRODUCTCODE=A.PRODUCT_CODE FROM #VEAN_PMT A          
  --  JOIN CMD01106 B ON A.PRODUCT_CODE=B.PRODUCT_CODE          
  --  JOIN CMM01106 C ON C.CM_ID=B.CM_ID          
  --  JOIN SKU D ON D.PRODUCT_CODE=A.PRODUCT_CODE          
  --  WHERE A.EAN_NO=@CEANNO AND STOCK_QTY>=1          
  --  AND C.REF_NO=@CLOCID+'-'+@CBILLNO AND C.FIN_YEAR=@CFINYEAR          
                    
  --  IF ISNULL(@CPRODUCTCODE,'')=''          
  --  BEGIN          
  --   SELECT TOP 1 @CPRODUCTCODE=PRODUCT_CODE FROM #VEAN_PMT A          
  --   WHERE EAN_NO=@CEANNO AND STOCK_QTY>=1          
  --  END          
  --  END          
  --  ELSE          
  --  BEGIN          
  --  SELECT TOP 1 @CPRODUCTCODE=A.PRODUCT_CODE FROM #VEAN_PMT A          
  --  WHERE A.EAN_NO=@CEANNO AND SOLD_QTY>0 AND STOCK_QTY=0      
            
  --  END          
                  
  --  IF ISNULL(@CPRODUCTCODE,'')=''          
  --  BREAK           
                      
  --  SET @CSTEP=50          
  --  SET @CCMD=N'SELECT 0 AS SR_NO, MEMO_NO AS BILL_NO, MEMO_DT AS CM_DT,DEPT_ID,'''+@CPRODUCTCODE+''' AS PRODUCT_CODE,          
  --  1*'+(CASE WHEN @NQTY<0 THEN '-1' ELSE '1' END)+' AS QUANTITY,NET AS AMOUNT,CANCELLED,'''' AS ERROR_MESSAGE,0 AS MRP,DISCOUNT_AMOUNT,CASH,CC_AMOUNT,CC_NAME,          
  --  ''000'' AS BIN_ID,'''+@CFINYEAR+''' AS FIN_YEAR FROM SLS_IMPORT_DATA A WHERE ROW_ID='''+@CROWID+''''          
  --  PRINT @CCMD          
              
  --  SET @CSTEP=55          
  --  INSERT #SLSIMPORT (SR_NO,BILL_NO,CM_DT,DEPT_ID,PRODUCT_CODE,QUANTITY,AMOUNT,CANCELLED,ERROR_MESSAGE          
  --  ,MRP,DISCOUNT_AMT,CASH,CC_AMOUNT,CC_NAME,BIN_ID,FIN_YEAR)            
  --  EXEC SP_EXECUTESQL @CCMD        
     
       
                 
  --  SET @CSTEP=60          
  --  UPDATE #VEAN_PMT SET STOCK_QTY=STOCK_QTY-1 WHERE  PRODUCT_CODE=@CPRODUCTCODE          
                 
  --  --UPDATE SLS_IMPORT_DATA SET PENDING_QTY=ABS(PENDING_QTY)-1 WHERE ROW_ID=@CROWID          
                   
  --  SET @NPENDINGQTY=@NPENDINGQTY-1          
  --  END          
         
  --  SET @CSTEP=65          
              
  --  UPDATE SLS_IMPORT_DATA SET PROCESSED=1 WHERE ROW_ID=@CROWID       AND   SP_ID=@CSPID       
              
  --END          
           
            
  SET @CSTEP=70          
  --IF EXISTS (SELECT TOP 1 * FROM SLS_IMPORT_DATA WHERE DEPT_ID=@CLOCID     AND   SP_ID=@CSPID AND PENDING_QTY>0)          
  --BEGIN          
  --  SET @CERRMSG='BAR CODES STOCK NOT AVAILABLE FOR SOME BILLS'          
  --  GOTO END_PROC          
  --END          
            
 LBLIMPORTSLS:          
        
  --SELECT * FROM #SLSIMPORT WHERE BILL_NO IN ('Q900-4057','Q900-4058','Q900-4078','Q900-4111')          
           
            
  PRINT 'START SALE IMPORT'          
  SET @CPRODUCTCODE=''          
            
  --SELECT TOP 1 @CPRODUCTCODE=PRODUCT_CODE FROM SLS_IMPORT_DATA WHERE DEPT_ID=@CLOCID AND ISNULL(PROCESSED,0)=0     AND   SP_ID=@CSPID         
  --IF ISNULL(@CPRODUCTCODE,'')<>''          
  --BEGIN          
  -- SET @CERRMSG='SOME ENTRIES NOT PROCESSED'          
  -- GOTO END_PROC          
  --END          
            
 -- SELECT * FROM #SLSIMPORT           
            
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)          
      
  --GETTING LIST OF EXISTING BILLS.          
  IF OBJECT_ID('TEMPDB..#EXISTINGBILLS','U') IS NOT NULL          
   DROP TABLE #EXISTINGBILLS          
           
  SET @CSTEP=40           
  IF OBJECT_ID('TEMPDB..#NEWBILLS','U') IS NOT NULL          
   DROP TABLE #NEWBILLS          
             
             
  -- SET @CSTEP=50          
  -- UPDATE A SET ERROR_MESSAGE='DIFFERENCE IN PAYMENT AMOUNT AND NET AMOUNT' FROM  #SLSIMPORT A          
  --JOIN           
  --(          
  -- SELECT A.BILL_NO,SUM(CONVERT(NUMERIC(18,2),AMOUNT)) AS AMOUNT,          
  -- SUM(CONVERT(NUMERIC(18,2),CASH)) AS CASH,          
  -- SUM(CONVERT(NUMERIC(18,2),CC_AMOUNT)) AS CC_AMOUNT          
  -- FROM #SLSIMPORT A          
  -- GROUP BY A.BILL_NO          
  -- ) B ON A.BILL_NO=B.BILL_NO           
  --WHERE A.AMOUNT<>(CASE WHEN (A.CASH+A.CC_AMOUNT)=0 THEN A.AMOUNT ELSE  (A.CASH+A.CC_AMOUNT) END)          
           
           
               
  SET @CSTEP=50          
  SELECT A.BILL_NO,SUM(CONVERT(NUMERIC(18,2),AMOUNT)) AS AMOUNT,          
   SUM(CONVERT(NUMERIC(18,2),CASH)) AS CASH,          
   SUM(CONVERT(NUMERIC(18,2),CC_AMOUNT)) AS CC_AMOUNT          
   INTO #SLSTMP          
   FROM #SLSIMPORT A          
   GROUP BY A.BILL_NO       
         
      
             
  --UPDATE A SET ERROR_MESSAGE='DIFFERENCE IN PAYMENT AMOUNT AND NET AMOUNT '     
  --FROM  #SLSIMPORT A          
  --JOIN #SLSTMP  B ON A.BILL_NO=B.BILL_NO           
  --WHERE B.AMOUNT<>(CASE WHEN (B.CASH+B.CC_AMOUNT)=0 THEN B.AMOUNT ELSE  (B.CASH+B.CC_AMOUNT) END)          
            
            
  SELECT TOP 1 @CERRMSG=ERROR_MESSAGE FROM #SLSIMPORT WHERE DEPT_ID=@CLOCID AND ISNULL(ERROR_MESSAGE,'')<>''          
  IF ISNULL(@CERRMSG,'')<>''          
  BEGIN          
   INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG )           
   SELECT PRODUCT_CODE,BILL_NO AS  REF_NO,DEPT_ID,ISNULL(@CERRMSG,'')--'DIFFERENCE IN PAYMENT AMOUNT AND NET AMOUNT ,PAYMENT AMOUNT - '+STR(AMOUNT)+' AND NET AMOUNT '+STR((A.CASH+A.CC_AMOUNT))+''  AS ERROR_MSG           
   FROM #SLSIMPORT A           
   WHERE DEPT_ID=@CLOCID           
   GOTO END_PROC          
  END          
            
  /**INVALID CARD NAME.**/           
  SET @CSTEP=55          
  UPDATE A SET ERROR_MESSAGE=ISNULL(ERROR_MESSAGE+';','')+B.MSG          
  FROM #SLSIMPORT A          
  JOIN           
  (          
    SELECT A.SR_NO,'INVALID CARD NAME.' AS MSG          
    FROM #SLSIMPORT A          
    LEFT JOIN PAYMODE_MST B ON A.CC_NAME =B.PAYMODE_NAME           
    WHERE CC_AMOUNT<>0 AND  B.PAYMODE_NAME  IS NULL          
  )B ON A.SR_NO=B.SR_NO          
           
  SET @CSTEP=60          
  UPDATE A SET ERROR_MESSAGE=ISNULL(ERROR_MESSAGE+';','')+B.MSG          
  FROM #SLSIMPORT A          
  JOIN           
  (          
    SELECT A.SR_NO,A.PRODUCT_CODE+'BARCODE NOT FOUND.' AS MSG          
    FROM #SLSIMPORT A          
    LEFT JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE WHERE DEPT_ID=@CLOCID          
    AND B.PRODUCT_CODE IS NULL          
  )B ON A.SR_NO=B.SR_NO          
           
           
   IF ISNULL(@CERRMSG,'')=''          
   SELECT TOP 1 @CERRMSG=ERROR_MESSAGE FROM #SLSIMPORT WHERE ISNULL(ERROR_MESSAGE,'')<>''          
             
  IF ISNULL(@CERRMSG,'')<>''          
   GOTO END_PROC          
                  
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)          
                   
  SET @CSTEP=70          
  --LIST OF EXISTING BILLS          
  SELECT B.CM_ID          
  ,B.CM_NO           
  ,ISNULL(A.BILL_NO,'') AS BILL_NO     
  ,CONVERT(DATETIME,A.CM_DT) AS CM_DT          
  ,A.DEPT_ID          
  ,A.PRODUCT_CODE          
  ,CONVERT(NUMERIC(10,3),QUANTITY) AS QUANTITY          
  ,CONVERT(NUMERIC(18,2),A.AMOUNT) AS AMOUNT          
  ,A.CANCELLED    
  --,CONVERT(BIT,CASE WHEN A.CANCELLED IN ('T','Y','1') THEN 1 ELSE 0 END)) AS CANCELLED          
  ,A.FIN_YEAR          
  ,A.CASH          
     ,A.CC_NAME          
     ,A.CC_AMOUNT     
  ,A.MRP        
  ,A.CMM_DISCOUNT_AMOUNT    
  ,A.CMM_OTHER_CHARGES    
  ,A.DISCOUNT_AMT    
  ,A.HSN_CODE   ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount     
  ,A.REMARKS,A.NET,A.NET_AMOUNT    ,ISNULL(A.party_state_code,'') party_state_code
  ,A.sis_net,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp
  ,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst
  ,A.PAYMODE_NAME
  INTO #EXISTINGBILLS          
  FROM #SLSIMPORT A          
  JOIN CMM01106 B(NOLOCK) ON A.DEPT_ID+'-'+ISNULL(A.BILL_NO,'')=B.REF_NO AND A.FIN_YEAR=B.FIN_YEAR          AND CONVERT(DATETIME,A.CM_DT) =    B.CM_DT        
  LEFT OUTER JOIN gst_state_mst GST (NOLOCK) ON GST.gst_state_name=A.party_state_code
  --WHERE B.CANCELLED=0

  --SELECT * FROM #EXISTINGBILLS


 UPDATE A SET PARTY_STATE_CODE =CASE WHEN ISNULL(B.GST_STATE_CODE   ,'') ='' THEN '00' ELSE B.GST_STATE_CODE END       
   FROM #EXISTINGBILLS  A (NOLOCK)       
   JOIN LOCATION   B ON A.DEPT_ID =B.DEPT_ID        
   AND  A.PARTY_STATE_CODE IN('','00') 
           
  SET @CSTEP=80          
  --LIST OF NEW BILLS          
  SELECT CONVERT(VARCHAR(50),'') AS CM_ID,CONVERT(VARCHAR(50),'') AS CM_NO          
  ,ISNULL(A.BILL_NO,'') AS BILL_NO          
  ,CONVERT(DATETIME,A.CM_DT) AS CM_DT          
  ,A.DEPT_ID          
  ,A.PRODUCT_CODE          
  ,CONVERT(NUMERIC(10,3),QUANTITY) AS QUANTITY          
  ,CONVERT(NUMERIC(18,2),A.AMOUNT) AS AMOUNT        
  ,A.CANCELLED      
  --,CONVERT(BIT, (CASE WHEN A.CANCELLED IN ('T','Y','1') THEN 1 ELSE 0 END)) AS CANCELLED          
  ,A.FIN_YEAR          
  ,A.CASH          
     ,A.CC_NAME          
     ,A.CC_AMOUNT        
  ,A.MRP       
  ,A.CMM_DISCOUNT_AMOUNT    
  ,A.CMM_OTHER_CHARGES    
  ,A.DISCOUNT_AMT    
  ,A.HSN_CODE   ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount     
  ,A.REMARKS,A.NET,A.NET_AMOUNT,ISNULL(A.party_state_code,'') AS  party_state_code
  ,A.sis_net,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp
  ,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst
  ,A.PAYMODE_NAME
  INTO #NEWBILLS          
  FROM #SLSIMPORT A          
  LEFT JOIN CMM01106 B(NOLOCK) ON A.DEPT_ID+'-'+ISNULL(A.BILL_NO,'')=B.REF_NO AND A.FIN_YEAR=B.FIN_YEAR       AND CONVERT(DATETIME,A.CM_DT) =    B.CM_DT  
  LEFT OUTER JOIN gst_state_mst GST (NOLOCK) ON GST.gst_state_name=A.party_state_code
  WHERE B.CM_ID IS NULL         

  --SELECT * FROM #NEWBILLS

 UPDATE A SET PARTY_STATE_CODE =CASE WHEN ISNULL(B.GST_STATE_CODE   ,'') ='' THEN '00' ELSE B.GST_STATE_CODE END       
   FROM #NEWBILLS  A (NOLOCK)       
   JOIN LOCATION   B ON A.DEPT_ID =B.DEPT_ID        
   AND  A.PARTY_STATE_CODE IN('','00') 
      
    
  if object_id ('tempdb..#tmpcm_id','u') is not null    
     drop table #tmpcm_id    
  SELECT DISTINCT dept_id, CM_ID INTO #TMPCM_ID FROM #EXISTINGBILLS    
      
      
   IF OBJECT_ID('TEMPDB..#TMPSTOCK','U') IS NOT NULL    
     DROP TABLE #TMPSTOCK    
    
  SELECT B.PRODUCT_CODE,A.DEPT_ID ,B.BIN_ID ,    
         SUM(B.QUANTITY) AS STOCK_QTY      
  INTO #TMPSTOCK    
  FROM #TMPCM_ID A    
  JOIN CMD01106 B ON A.CM_ID  =B.CM_ID     
  join cmm01106 cmm on cmm.cm_id =b.cm_id     
  --where cmm.CANCELLED =0    
  GROUP BY B.PRODUCT_CODE,A.DEPT_ID ,B.BIN_ID     
       
           
  SET @CSTEP=410          
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)          
            
  --STOCK IS NOT FOUND NEGATIVE, SO LETS PROCEED FOR CREATING ENTRY IN CMM01106,CMD01106 AND PAYMODE_XN_DET          
  --DELETE PAYMODE_XN_DET WHERE XN_TYPE='SLS' AND MEMO_ID IN           
  --(SELECT DISTINCT CM_ID FROM #EXISTINGBILLS)          
           
  --SET @CSTEP=420          
  --DELETE CMD01106 WHERE CM_ID IN           
  --(SELECT DISTINCT CM_ID FROM #EXISTINGBILLS)          
           
  --SET @CSTEP=430          
  --DELETE CMM01106 WHERE CM_ID IN           
  --(SELECT DISTINCT CM_ID FROM #EXISTINGBILLS)          
           
  SET @CSTEP=440          
  DECLARE @CDEPT_ID VARCHAR(10),@CBILL_NO VARCHAR(40)          
   ,@CMEMOPREFIX VARCHAR(10),@NMEMONOLEN NUMERIC(3),@CMEMONOLEN VARCHAR(5)           
   ,@CMEMONOVAL VARCHAR(50),@CKEYSTABLE VARCHAR(100)          
           
  SET @CSTEP=450          
  SET @NMEMONOLEN=12           
           
  SET @CSTEP=470          
           
  SET @CKEYSTABLE='KEYS_CMM'          
           
  SET @CSTEP=480          
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)          
  ---GENERATING CM_NO AND CM_ID FOR NEW_MEMO          
  WHILE EXISTS(SELECT TOP 1 'U' FROM #NEWBILLS WHERE ISNULL(CM_NO,'')='')          
  BEGIN          
   SET @CDEPT_ID=''          
   SET @CBILL_NO=''          
   SET @CFINYEAR=''          
   SET @CMEMONOVAL=''           
   SET @CSTEP=490           
             
   SELECT TOP 1 @CDEPT_ID=A.DEPT_ID,@CBILL_NO=BILL_NO,@CFINYEAR=FIN_YEAR,@DMEMODT=A.CM_DT          
   FROM #NEWBILLS A WHERE ISNULL(CM_NO,'')='' ORDER BY CM_DT,BILL_NO ASC          
             
   SET @CMEMOPREFIX=LTRIM(RTRIM(@CDEPT_ID))+LTRIM(RTRIM(@CDEPT_ID))+'-'          
            
  LBLGENKEY:          
             
             
   SET @CSTEP=500          
   --EXEC GETNEXTKEY_OPT 'CMM01106', 'CM_NO', @NMEMONOLEN, @CMEMOPREFIX, 1,@CFINYEAR,0, @CKEYSTABLE,@CMEMONOVAL OUTPUT         
    
    
            
-- SET @CMEMONOVAL=@CLOCID+@CLOCID+'-'+@CBILL_NO        
          
   --SET @CSTEP=510          
   --IF EXISTS(SELECT TOP 1 'U' FROM CMM01106 WHERE CM_NO=@CMEMONOVAL AND FIN_YEAR=@CFINYEAR)          
   -- GOTO LBLGENKEY          
             
   --SET @CSTEP=520          
   --IF ISNULL(@CMEMONOVAL,'')=''          
   --BEGIN          
   -- SET @CERRMSG='ERROR GENERATING CM NO.'          
   -- GOTO END_PROC          
   --END          
             
   SET @CSTEP=530           
   UPDATE #NEWBILLS SET CM_NO='LATER'          
   WHERE DEPT_ID=@CDEPT_ID AND BILL_NO=@CBILL_NO AND FIN_YEAR=@CFINYEAR AND CM_DT=@DMEMODT          
               
  END          
    
     
          
  SET @CSTEP=540          
  --PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)          
  --UPDATE #NEWBILLS SET CM_ID=LTRIM(RTRIM(DEPT_ID))+FIN_YEAR+REPLICATE('0',15-LEN(LTRIM(RTRIM(CM_NO))))+LTRIM(RTRIM(CM_NO))          
           
        
      
  --SET @CSTEP=550          
  --IF EXISTS(SELECT TOP 1 'U' FROM #NEWBILLS WHERE ISNULL(CM_ID,'')='' OR ISNULL(CM_NO,'')='')          
  --BEGIN          
  -- SET @CERRMSG='ERROR GENERATING CM NO.'          
  -- GOTO END_PROC          
  --END 
  DECLARE  @CM_DT DATETIME,@DEPT_ID VARCHAR(5)
  SELECT @CM_DT=CM_DT,@DEPT_ID=DEPT_ID
  FROM
  (
	  SELECT DISTINCT CM_DT,DEPT_ID
	  FROM #EXISTINGBILLS
	  UNION 
	  SELECT DISTINCT CM_DT,DEPT_ID
	  FROM #NEWBILLS
  )X

  INSERT INTO #CheckEffectiveSaleSetup(EffectiveSaleSetup)
  EXEC SP_WL_CheckEffectiveSaleSetup @CM_DT,@DEPT_ID 


  SELECT @CheckEffectiveSaleSetup=EffectiveSaleSetup FROM #CheckEffectiveSaleSetup
  SET @CheckEffectiveSaleSetup=ISNULL(@CheckEffectiveSaleSetup,0)
      
  SET @CSTEP=560          
  INSERT SLS_CMM01106_UPLOAD (SP_ID, REMARKS, SENT_FOR_RECON, PARTY_TYPE, AC_CODE, MANUAL_DISCOUNT, MANUAL_ROUNDOFF          
   , BIN_ID, PATCHUP_RUN, SUBTOTAL_R, PASSPORT_NO, TICKET_NO, FLIGHT_NO, MRP_WSP          
   , MANUAL_BILL, FC_RATE, POSTEDINAC, CM_NO, CM_DT, CM_MODE, SUBTOTAL, DT_CODE          
   , DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, NET_AMOUNT, CUSTOMER_CODE, CANCELLED, USER_CODE          
   , LAST_UPDATE, EXEMPTED,  SENT_TO_HO, CM_TIME, CM_ID, REF_CM_ID, FIN_YEAR          
   , ATD_CHARGES, COPIES_PTD, ROUND_OFF, MEMO_TYPE, PAY_MODE, SMS_SENT, AUTOENTRY, CASH_TENDERED          
   , PAYBACK, ECOUPON_ID, CAMPAIGN_GC_OTP, SALESSETUPINEFFECT, EDT_USER_CODE, GV_AMOUNT, REF_NO          
   , SENT_FOR_GR,xn_item_type,oh_tax_method ,party_state_code )            
  SELECT DISTINCT @CSPID,'IMPORTED SALE.' +ISNULL(REMARKS,'') AS REMARKS,0 AS SENT_FOR_RECON,@npartytype AS PARTY_TYPE,@cAC_CODE AS AC_CODE          
    ,0 AS MANUAL_DISCOUNT,0 AS MANUAL_ROUNDOFF,@CBINID AS BIN_ID,0 AS PATCHUP_RUN          
    ,SUM(CASE WHEN NET<0 THEN NET ELSE 0 END) AS SUBTOTAL_R,'' AS PASSPORT_NO,'' AS TICKET_NO,'' AS FLIGHT_NO,          
    0 AS MRP_WSP,0 AS MANUAL_BILL,0 AS FC_RATE          
    ,0 AS POSTEDINAC, CM_NO          
    ,CM_DT,1 AS CM_MODE          
    ,SUM(CASE WHEN NET>0 THEN NET  ELSE 0 END) AS SUBTOTAL          
    ,'0000000' AS DT_CODE,0 AS DISCOUNT_PERCENTAGE,SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS DISCOUNT_AMOUNT          
    ,SUM(NET) AS NET_AMOUNT     
    ,@cCUSTOMER_CODE AS CUSTOMER_CODE, CANCELLED,@CUSER_CODE AS USER_CODE,GETDATE() AS LAST_UPDATE          
    ,0 AS EXEMPTED,0 AS SENT_TO_HO,GETDATE() AS CM_TIME, CM_ID,'' AS REF_CM_ID          
    , FIN_YEAR,SUM(ISNULL(CMM_OTHER_CHARGES,0)) AS ATD_CHARGES,0 AS COPIES_PTD,0 AS ROUND_OFF,1 AS MEMO_TYPE,1 AS PAY_MODE,0 AS SMS_SENT          
    ,1 AS AUTOENTRY,0 AS CASH_TENDERED          
    ,0 AS PAYBACK,'' AS ECOUPON_ID,'' AS CAMPAIGN_GC_OTP          
    ,@CheckEffectiveSaleSetup AS SALESSETUPINEFFECT,@CUSER_CODE AS EDT_USER_CODE,0 AS GV_AMOUNT          
    ,DEPT_ID+'-'+BILL_NO AS REF_NO,0 AS SENT_FOR_GR  , 1 as xn_item_type         ,1 as oh_tax_method,party_state_code
  FROM #EXISTINGBILLS          
  GROUP BY DEPT_ID,CM_NO,CM_DT,CANCELLED,CM_ID,FIN_YEAR,BILL_NO ,REMARKS   ,party_state_code  
  UNION           
  SELECT DISTINCT @CSPID,'IMPORTED SALE.'+ ISNULL(REMARKS,'') AS REMARKS,0 AS SENT_FOR_RECON,@npartytype AS PARTY_TYPE,@cAC_CODE AS AC_CODE          
    ,0 AS MANUAL_DISCOUNT,0 AS MANUAL_ROUNDOFF,@CBINID AS BIN_ID,0 AS PATCHUP_RUN          
    ,SUM(CASE WHEN NET<0 THEN NET ELSE 0 END) AS SUBTOTAL_R,'' AS PASSPORT_NO,'' AS TICKET_NO,'' AS FLIGHT_NO,0 AS MRP_WSP,0 AS MANUAL_BILL,0 AS FC_RATE          
    ,0 AS POSTEDINAC, CM_NO          
    ,CM_DT,1 AS CM_MODE          
    ,SUM(CASE WHEN NET>0 THEN NET ELSE 0 END) AS SUBTOTAL          
    ,'0000000' AS DT_CODE,0 AS DISCOUNT_PERCENTAGE,SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS DISCOUNT_AMOUNT          
    , SUM(NET) AS NET_AMOUNT     
    ,@cCUSTOMER_CODE AS CUSTOMER_CODE, CANCELLED,@CUSER_CODE AS USER_CODE,GETDATE() AS LAST_UPDATE          
    ,0 AS EXEMPTED,0 AS SENT_TO_HO,GETDATE() AS CM_TIME, CM_ID,'' AS REF_CM_ID          
    , FIN_YEAR,SUM(ISNULL(CMM_OTHER_CHARGES,0)) AS ATD_CHARGES,0 AS COPIES_PTD,0 AS ROUND_OFF,1 AS MEMO_TYPE,1 AS PAY_MODE,0 AS SMS_SENT          
    ,1 AS AUTOENTRY,0 AS CASH_TENDERED          
    ,0 AS PAYBACK,'' AS ECOUPON_ID,'' AS CAMPAIGN_GC_OTP          
    ,@CheckEffectiveSaleSetup AS SALESSETUPINEFFECT,@CUSER_CODE AS EDT_USER_CODE,0 AS GV_AMOUNT          
    ,DEPT_ID+'-'+BILL_NO AS REF_NO,0 AS SENT_FOR_GR , 1 as xn_item_type            ,1 as oh_tax_method    ,party_state_code   
  FROM #NEWBILLS          
  GROUP BY DEPT_ID,CM_NO,CM_DT,CANCELLED,CM_ID,FIN_YEAR,BILL_NO ,REMARKS   ,party_state_code   
    
    
--select * from #EXISTINGBILLS    
--select * from #NEWBILLS       
--SELECT * FROM CMM01106(NOLOCK) WHERE CM_ID IN (SELECT CM_ID FROM #NEWBILLS)           
  SET @CSTEP=570          
  /*          
  TAX_METHOD : 1 FOR INCLUSIVE AND 2 FOR EXCLUSIVE          
  */          
  INSERT SLS_CMD01106_UPLOAD (SP_ID, PRODUCT_CODE, QUANTITY, MRP, NET, BASIC_DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE,BASIC_DISCOUNT_AMOUNT, DISCOUNT_AMOUNT, ROW_ID, LAST_UPDATE          
   , TAX_PERCENTAGE, TAX_AMOUNT, EMP_CODE, SLSDET_ROW_ID, BIN_ID, OLD_MRP, REF_SLS_MEMO_ID          
   , REALIZE_SALE, CM_ID, RFNET, TAX_TYPE, TAX_METHOD, EAN, EMP_CODE1, EMP_CODE2, ITEM_DESC          
   , WEIGHTED_AVG_DISC_PCT, WEIGHTED_AVG_DISC_AMT, MANUAL_DISCOUNT, FIX_MRP, SR_NO, HOLD_FOR_ALTER          
   , PACK_SLIP_ID, XN_TYPE, REPEAT_PUR_ORDER, DEPT_ID, REF_ORDER_ID, FOC_QUANTITY, CMM_DISCOUNT_AMOUNT          
   , NRM_ID ,HSN_CODE   ,gst_percentage ,igst_amount ,cgst_amount,sgst_amount ,NET_SALE,pack_slip_row_id,SIS_NET,sisloc_eoss_discount_percentage,sisloc_eoss_discount_amount,
   sisloc_mrp,sisloc_gst_percentage,sisloc_taxable_value,sisloc_lgst_amount,sisloc_igst_amount,xn_value_without_gst)            
  SELECT  @CSPID,  A.PRODUCT_CODE, A.QUANTITY, A.MRP,A.NET AS NET,    
  --(CASE WHEN ABS(A.MRP)<ABS(A.QUANTITY*B.MRP) THEN           
  --  ((ABS(A.QUANTITY*B.MRP)-ABS(A.MRP))/ABS(A.QUANTITY*A.MRP))*100           
  --  ELSE 0 END) AS DISCOUNT_PERCENTAGE          
  --  ,(CASE WHEN A.QUANTITY>0 THEN 1 ELSE -1 END)*          
  --  (CASE WHEN ABS(A.MRP)<ABS(A.QUANTITY*B.MRP) THEN           
  --(ABS(A.QUANTITY*B.MRP)-ABS(A.MRP*A.QUANTITY))           
  --ELSE 0 END)          
  --  AS DISCOUNT_AMOUNT          
  (((CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END)*100)/(A.MRP*A.QUANTITY)) AS BASIC_DISCOUNT_PERCENTAGE
  ,(((CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END)*100)/(A.MRP*A.QUANTITY)) AS DISCOUNT_PERCENTAGE
  ,(CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END) AS BASIC_DISCOUNT_AMOUNT
  ,(CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END) AS DISCOUNT_AMOUNT    
    ,CONVERT(VARCHAR(45),'LATER'+convert(varchar(38),newid())) AS ROW_ID,GETDATE() AS LAST_UPDATE          
    ,0 AS TAX_PERCENTAGE,0 AS TAX_AMOUNT,'0000000' AS EMP_CODE,'' AS SLSDET_ROW_ID,          
    @CBINID AS BIN_ID,0 AS OLD_MRP,'' AS REF_SLS_MEMO_ID,0 AS REALIZE_SALE          
    ,A.CM_ID AS CM_ID,0 AS RFNET,1 AS TAX_TYPE,1 AS TAX_METHOD,'' AS EAN,'0000000' AS EMP_CODE1          
    ,'0000000' AS EMP_CODE2,'' AS ITEM_DESC,0 AS WEIGHTED_AVG_DISC_PCT          
    ,0 AS WEIGHTED_AVG_DISC_AMT,
	(CASE WHEN ISNULL(DISCOUNT_AMT,0)<> 0 AND ((A.MRP*A.QUANTITY)-A.NET)<>0 THEN 1 ELSE 0 END) AS MANUAL_DISCOUNT,0 AS FIX_MRP,0 AS SR_NO,0 AS HOLD_FOR_ALTER,'' AS PACK_SLIP_ID          
    ,'' AS XN_TYPE          
    ,0 AS REPEAT_PUR_ORDER,A.DEPT_ID,'' AS REF_ORDER_ID          
    ,0 AS FOC_QUANTITY,0 AS CMM_DISCOUNT_AMOUNT,'' AS NRM_ID,A.HSN_CODE   ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount       
	,A.NET AS NET_SALE,'',A.SIS_NET,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp
	,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst
  FROM #EXISTINGBILLS A          
  JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE          
  UNION           
  SELECT  @CSPID,  A.PRODUCT_CODE, A.QUANTITY, A.MRP,A.NET AS NET          
  --,(CASE WHEN ABS(A.QUANTITY*A.MRP)<ABS(A.QUANTITY*B.MRP) THEN           
  --  ((ABS(A.QUANTITY*B.MRP)-ABS(A.QUANTITY*A.MRP))/ABS(A.QUANTITY*B.MRP))*100           
  --  ELSE 0 END)          
  --AS DISCOUNT_PERCENTAGE          
  --  ,(CASE WHEN A.QUANTITY>0 THEN 1 ELSE -1 END)*          
  --(CASE WHEN ABS(A.QUANTITY*A.MRP)<ABS(A.QUANTITY*B.MRP) THEN           
  --(ABS(A.QUANTITY*B.MRP)-ABS(A.QUANTITY*A.MRP))           
  --ELSE 0 END)          
  --  AS DISCOUNT_AMOUNT          
  ,(((CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END)*100)/(A.MRP*A.QUANTITY)) AS BASIC_DISCOUNT_PERCENTAGE,
  (((CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END)*100)/(A.MRP*A.QUANTITY)) AS DISCOUNT_PERCENTAGE,
  (CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END) AS BASIC_DISCOUNT_AMOUNT,
  (CASE WHEN ISNULL(DISCOUNT_AMT,0)= 0 THEN ((A.MRP*A.QUANTITY)-A.NET) ELSE ISNULL(DISCOUNT_AMT,0) END) AS DISCOUNT_AMOUNT    
    ,CONVERT(VARCHAR(45),'LATER'+convert(varchar(38),newid())) AS ROW_ID,GETDATE() AS LAST_UPDATE          
    ,0 AS TAX_PERCENTAGE,0 AS TAX_AMOUNT,'0000000' AS EMP_CODE,'' AS SLSDET_ROW_ID          
    ,@CBINID AS BIN_ID,0 AS OLD_MRP,'' AS REF_SLS_MEMO_ID,0 AS REALIZE_SALE          
    ,A.CM_ID AS CM_ID,0 AS RFNET,1 AS TAX_TYPE,1 AS TAX_METHOD,'' AS EAN,'0000000' AS EMP_CODE1          
    ,'0000000' AS EMP_CODE2,'' AS ITEM_DESC,0 AS WEIGHTED_AVG_DISC_PCT          
    ,0 AS WEIGHTED_AVG_DISC_AMT,(CASE WHEN ISNULL(DISCOUNT_AMT,0)<> 0 AND ((A.MRP*A.QUANTITY)-A.NET)<>0 THEN 1 ELSE 0 END) AS MANUAL_DISCOUNT,0 AS FIX_MRP,0 AS SR_NO,0 AS HOLD_FOR_ALTER,'' AS PACK_SLIP_ID          
    ,'' AS XN_TYPE          
    ,0 AS REPEAT_PUR_ORDER,A.DEPT_ID,'' AS REF_ORDER_ID,0 AS FOC_QUANTITY          
    ,0 AS CMM_DISCOUNT_AMOUNT,'' AS NRM_ID       ,A.HSN_CODE   ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount 
	,A.NET AS NET_SALE,'',A.SIS_NET,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp
	,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst
  FROM #NEWBILLS A          
  JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE          


--  SELECT cm_id, * FROM SLS_CMM01106_UPLOAD WHERE SP_ID=@CSPID           
--SELECT cm_id,* FROM SLS_CMD01106_UPLOAD WHERE SP_ID=@CSPID           
  SET @CSTEP=580          
           
 PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)          
  
  INSERT SLS_paymode_xn_det_UPLOAD(SP_ID,MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO,          
    ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)            
   SELECT  @CSPID,A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
   ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,SUM(NET) AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
   ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #EXISTINGBILLS A          
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME=A.PAYMODE_NAME         
   WHERE ISNULL(A.PAYMODE_NAME,'')<>''          
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE          
   UNION           
   SELECT  @CSPID,A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
    ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID          
    ,SUM(NET) AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
    ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #NEWBILLS A          
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME=A.PAYMODE_NAME         
   WHERE ISNULL(A.PAYMODE_NAME,'')<>''        
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE  

           
   INSERT SLS_paymode_xn_det_UPLOAD(SP_ID,MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO,          
    ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)            
   SELECT  @CSPID,A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
   ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,SUM(CASH) AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
   ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #EXISTINGBILLS A          
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME='INR'          
   WHERE CASH<>0 AND ISNULL(A.PAYMODE_NAME,'')=''     
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE          
   UNION           
   SELECT  @CSPID,A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
    ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID          
    ,SUM(AMOUNT) AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
    ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #NEWBILLS A          
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME='INR'          
   WHERE CASH<>0         AND ISNULL(A.PAYMODE_NAME,'')=''    
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE         
            
            
   INSERT SLS_paymode_xn_det_UPLOAD(SP_ID, MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO          
   , ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)            
   SELECT @CSPID, A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
   ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,SUM(CC_AMOUNT) AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
   ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #EXISTINGBILLS A          
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME=A.CC_NAME          
   WHERE CC_AMOUNT<>0     AND ISNULL(A.PAYMODE_NAME,'')=''        
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE          
   UNION           
   SELECT @CSPID, A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
    ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID          
    ,SUM(AMOUNT) AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
    ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #NEWBILLS A          
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME=A.CC_NAME          
   WHERE CC_AMOUNT<>0      AND ISNULL(A.PAYMODE_NAME,'')=''       
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE          
         
         
         
         
   INSERT SLS_paymode_xn_det_UPLOAD(SP_ID, MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO          
   , ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)            
   SELECT DISTINCT @CSPID,  A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
   ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,C.NET_AMOUNT AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
   ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #EXISTINGBILLS A          
   JOIN PAYMODE_MST B ON 1=1        
   JOIN CMM01106 C ON C.CM_ID=A.CM_ID        
   LEFT OUTER JOIN PAYMODE_XN_DET D ON D.MEMO_ID=A.CM_ID AND D.XN_TYPE='SLS'        
   WHERE B.PAYMODE_CODE='0000000' AND  D.MEMO_ID IS NULL    AND ISNULL(A.PAYMODE_NAME,'')=''       
    GROUP BY A.CM_ID,DEPT_ID,B.PAYMODE_CODE ,C.NET_AMOUNT        
           
   UNION ALL        
           
   SELECT DISTINCT @CSPID, A.CM_ID AS MEMO_ID,'SLS' AS XN_TYPE,B.PAYMODE_CODE  AS PAYMODE_CODE          
   ,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,C.NET_AMOUNT AS AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID          
   ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO           
   FROM #NEWBILLS  A          
   JOIN PAYMODE_MST B ON 1=1        
   JOIN CMM01106 C ON C.CM_ID=A.CM_ID        
   LEFT OUTER JOIN PAYMODE_XN_DET D ON D.MEMO_ID=A.CM_ID AND D.XN_TYPE='SLS'        
   WHERE B.PAYMODE_CODE='0000000' AND  D.MEMO_ID IS NULL      AND ISNULL(A.PAYMODE_NAME,'')=''     
    GROUP BY A.CM_ID,DEPT_ID,B.PAYMODE_CODE,C.NET_AMOUNT         
           
              
  SET @CSTEP=590          
        
  GOTO END_PROC          
            
END TRY          
           
BEGIN CATCH         
  PRINT 'ENTER CATCH BLOCK'       
  SET @CERRMSG='SP3S_IMPORT_SLS_DATA_UPLOAD_NEW  : AT STEP - '+@CSTEP+', MESSAGE - '+ERROR_MESSAGE()    
  PRINT       @CERRMSG    
  GOTO END_PROC           
END CATCH          
           
END_PROC:          
           
    
    --SELECT 'ROHIT'    
  IF ISNULL(@CERRMSG,'')=''          
   SELECT TOP 1 @CERRMSG=ERRORMSG FROM SLS_IMPORT_DATA WHERE DEPT_ID=@CLOCID AND ISNULL(ERRORMSG,'')<>'' AND SP_ID=@CSPID         
             AND memo_no=@memo_no  AND memo_dt= @memo_dt
  IF ISNULL(@CERRMSG,'')=''           
   SELECT TOP 1 @CERRMSG=ERROR_MESSAGE FROM #SLSIMPORT WHERE ISNULL(ERROR_MESSAGE,'')<>''          
            
  --IF @@TRANCOUNT>0          
  --BEGIN          
  -- IF ISNULL(@CERRMSG,'')<>''            
  -- BEGIN          
  --  PRINT 'ROLLBACK TRANSACTION'          
  --  ROLLBACK          
  -- END           
  -- ELSE          
  -- BEGIN          
  --  PRINT 'COMMIT'          
  --  COMMIT            
  -- END           
             
  --END       
  --SELECT * FROM @TERRORDETAILS
  CREATE TABLE #SP3S_IMPORT_SLS_DATA_UPLOAD_NEW (PRODUCT_CODE VARCHAR(100), REF_NO  VARCHAR(100),DEPT_ID  VARCHAR(100), ERRMSG  VARCHAR(MAX))
 IF EXISTS (SELECT PRODUCT_CODE FROM @TERRORDETAILS )    
 BEGIN 
	--select 'rohit'
	INSERT INTO #SP3S_IMPORT_SLS_DATA_UPLOAD_NEW (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG  )
    SELECT PRODUCT_CODE,  REF_NO,DEPT_ID, ERROR_MSG AS ERRMSG  FROM @TERRORDETAILS        
 END    
 ELSE IF ISNULL(@CERRMSG,'')=''          
	BEGIN
	--select 'raman'
	INSERT INTO #SP3S_IMPORT_SLS_DATA_UPLOAD_NEW (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG  )
    SELECT  '' PRODUCT_CODE, '' REF_NO,'' DEPT_ID,ISNULL(@CERRMSG,'') AS ERRMSG    
	END
 ELSE 
 BEGIN
	INSERT INTO #SP3S_IMPORT_SLS_DATA_UPLOAD_NEW (PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG  )
	SELECT PRODUCT_CODE, MEMO_NO AS REF_NO,@CLOCID AS  DEPT_ID, ISNULL(@CERRMSG,'') ERRMSG 
	FROM SLS_IMPORT_DATA  WHERE SP_ID=@CSPID   
	AND memo_no=@memo_no  AND memo_dt= @memo_dt
END
IF OBJECT_ID('TEMPDB..#SAVETRAN_SLS_BULK','U') IS NOT NULL
BEGIN
	INSERT INTO #SAVETRAN_SLS_BULK(PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG)
	SELECT PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG FROM #SP3S_IMPORT_SLS_DATA_UPLOAD_NEW
END
ELSE
	SELECT PRODUCT_CODE , REF_NO  ,DEPT_ID  , ERRMSG FROM #SP3S_IMPORT_SLS_DATA_UPLOAD_NEW

	--select * from #SAVETRAN_SLS_BULK

END

