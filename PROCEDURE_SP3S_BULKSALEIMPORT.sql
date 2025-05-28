CREATE PROCEDURE SP3S_BULKSALEIMPORT  --(LocId 3 digit change by Sanjay:06-11-2024)                                                       
(                                                                
 @iDateMode  INT,                                                            
 @CLOCID VARCHAR(10),                                                                      
 @NMODE INT=0      ,                                                                
 @CSPID VARCHAR(50) ,                                                            
 @CUSER_CODE CHAR(7)= '0000000',                                                            
 @CBINID VARCHAR(10)='000',                                                          
 @CMAPPING_NAME VARCHAR(1000)=''   ,            
 @cstoregroup varchar(100)=''            
)                                                                
AS                                                                      
BEGIN                                                                      
  DECLARE @DSEARCHXNDT DATETIME,@CSOURCEDB VARCHAR(200),@CTEMPTABLENAME VARCHAR(200),@CTEMPTABLE VARCHAR(200),                                                                      
  @CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CERRMSG VARCHAR(MAX),@DMEMODT DATETIME,                                                                      
  @CAPPLYSALESSETUP VARCHAR(4),@CBINSALES VARCHAR(10),@CGENVENDOREANCODES VARCHAR(4),@NIMPORTMODE INT,                                                                      
  @BSTOCKNOTFOUND BIT,@BLOOP BIT,@CEANNO VARCHAR(50),@CROWID VARCHAR(40),@NPENDINGQTY NUMERIC(10,2),@CBILLNO VARCHAR(50),                                                                      
  @CPRODUCTCODE VARCHAR(50),@CFINYEAR VARCHAR(10),@NQTY NUMERIC(10,2),@CAPPLYMINDISCOUNT VARCHAR(4)    ,                                                            
  @CheckEffectiveSaleSetup BIT  ,@cRETAIN_EXCEL_NRV_SISLOC_SALEIMP VARCHAR(1)  ,                                                          
  @CUSER_ALIAS VARCHAR(4) ,@TOTAL_QUANTITY  NUMERIC(28,2),@NEWTOTAL_QUANTITY  NUMERIC(28,2),@cacname varchar(20),                                      
  @CACCODE varchar(20),@Cloc_ID varchar(4) ,@cemail  varchar(1000) ,@CMEMO_NO VARCHAR(100),@Dcm_dt DateTime , @CDISPLAYERRORMSG VARCHAR(5000) ,                          
  @NREMOVEROWCOUNT NUMERIC(10,0),@CRemove_ERR_MSG Varchar(max)                          
                                                      
                                                                        
BEGIN TRY                                                           
--BEGIN TRAN                                
                          
 --if marvalue mapped then mrp column update                        
  IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='MRP' AND ISNULL(MAPPED_COL,'')='') and                        
    EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='MRPvalue' AND ISNULL(MAPPED_COL,'')<>'')                           
  begin                        
                           
    update a set mrp =isnull(MRPvalue,0)/abs(isnull(quantity,0) )                  
    FROM SLS_IMPORT_DATA A                        
    WHERE SP_ID=@CSPID and isnull(quantity,0)<>0                        
                        
  end                        
                             
 SELECT TOP 1  @CEMAIL=LOCATTR6_KEY_NAME FROM  LOC_NAMES WHERE LOCATTR6_KEY_NAME<>''AND @CMAPPING_NAME LIKE '%'+LOCATTR6_KEY_NAME +'%'                            
                                                      
      
                                                    
                                                      
if ISNULL(@CUSER_CODE,'0000000') ='0000000'                                                        
 SELECT @CUSER_CODE=B.user_code                                                            
 FROM NEW_APP_LOGIN_INFO A (nolock)                                                             
 JOIN USERS B (NOLOCK) ON B.username=A.LOGIN_NAME          
 WHERE SPID=@@SPID                                                       
 SET @CheckEffectiveSaleSetup=0                                                          
                                                            
 if ISNULL(@CUSER_CODE,'') =''                                                            
 SET @CUSER_CODE ='0000000'                                                         
                            
                                                     
                                                 
  SELECT @CUSER_ALIAS=USER_ALIAS  FROM USERS WHERE USER_CODE='0000000'                                                           
                                                                        
  DECLARE @TERRORDETAILS TABLE                                                                      
  (                                                  
   PRODUCT_CODE VARCHAR(50),                                                                      
   REF_NO VARCHAR(50),                             
   MEMO_DT DATEtIME,                            
   DEPT_ID VARCHAR(4),                                     
   ERROR_MSG VARCHAR(MAX)                                                                       
  )                                                                   
                                                                        
  SET @CSTEP=5                                                                   
                                                                  
                                                           
  IF OBJECT_ID('TEMPDB..#TERROR','U') IS NOT NULL                                                                      
   DROP TABLE #TERROR                                                                      
                                                                        
  SELECT PRODUCT_CODE,ERROR_MSG INTO #TERROR FROM SLS_MBODATA_ERROR_DETAILS WHERE 1=2                                                                      
                                                              
                                            
                                                                 
  SELECT @NIMPORTMODE=ISNULL(MBOSLS_IMPORT_MODE,0) FROM LOCATION WHERE DEPT_ID=@CLOCID                                                                   
                                              
  IF OBJECT_ID('TEMPDB..#SLSIMPORT','U') IS NOT NULL                                                                      
   DROP TABLE #SLSIMPORT                                                                      
                                                        
  IF OBJECT_ID('TEMPDB..#SLSTMP','U') IS NOT NULL                                                                      
   DROP TABLE #SLSTMP                                                                      
                                                                
                                                  
                                                                       
  SET @CSTEP=10                                                                      
                                                           
  CREATE TABLE #SLSIMPORT                                                                
  (                                                                      
  SR_NO   NUMERIC(18)                                                                     
 ,BILL_NO   VARCHAR(1000)                                                                      
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
 ,party_state_code VARCHAR(20)                                                            
 ,sisloc_eoss_discount_percentage NUMERIC(5,2)                                                            
 ,sisloc_eoss_discount_amount NUMERIC(10,2)                                                            
 ,sisloc_mrp NUMERIC(10,2)                                                            
 ,sis_net NUMERIC(10,2)                                                            
 ,sisloc_gst_percentage  NUMERIC(5,2)                                                            
 ,sisloc_taxable_value  NUMERIC(10,2)                                                            
 ,sisloc_lgst_amount  NUMERIC(10,2)                                                            
 ,sisloc_igst_amount  NUMERIC(10,2)                                                            
 ,xn_value_without_gst  numeric(10,2)                                                            
 ,CMD_DISCOUNT_PERCENTAGE  numeric(10,2)   
 ,weighted_avg_disc_pct	numeric(7,3)
,weighted_avg_disc_amt	numeric(10,2 )
,paymode_name VARCHAR(100)
,party_gst_no VARCHAR(20)
 
  )                              
                                                            
    --SELECT memo_no=@memo_no , memo_dt=@memo_dt                                                            
--if @CMAPPING_NAME like '%.csv%'                                                        
--begin                                                        
SET @CSTEP=11                                                       
  if(@iDateMode IN (1,6))                                
  BEGIN                                                          
                                             
   update SLS_IMPORT_DATA SET memo_dt=CONVERT(DATETIME,memo_dt,105)  where sp_id=@CSPID                                                            
                                                       
  END                                                            
  if(@iDateMode=5)                                                            
  BEGIN                                                          
  update SLS_IMPORT_DATA SET memo_dt=CONVERT(DATETIME,memo_dt,110)  where sp_id=@CSPID                              
  END                                                     
       
-- end                                                      
 SET @CSTEP=12                                                      
     update a set memo_no =  Replace(convert(varchar(10),  CONVERT(DATETIME,memo_dt,110) ,121) ,'-','')                                                      
  from SLS_IMPORT_DATA a (nolock) where memo_no in('empty','','PUMA')                                                      
  and sp_id=@CSPID                                                   
                                                      
                                         
  --update SLS_IMPORT_DATA_ERRORLOG set STORE_CODE=stuff(store_code,len(store_code)-1,1,'')                                            
  --WHERE SP_ID=@CSPID                                                 
                                                          
                               
                          
                       
                          
                                         
                                              
   update a SET DEPT_ID=@CLOCID                                                           
   FROM SLS_IMPORT_DATA a                                                             
   WHERE SP_ID=@CSPID and ISNULL(a.dept_id,'')  =''                                        
                                        
                                                    
--step 1 store code not available                                                           
declare @CIMPORT_ERR_MSG Varchar(max),@bfailedstatus bit ,@CIMPORT_ERR_value varchar(5000)                                                         
set @bfailedstatus=0                                  
set @CIMPORT_ERR_value=''                            
                                                           
                                    
 SET @CSTEP=13                                           
 --step 2 barcodee missing                                                          
 if exists (SELECT TOP 1 'U' FROM SLS_IMPORT_DATA A WITH (NOLOCK)                                                            
 JOIN                                                          
 (                                                          
 SELECT A.dept_id  FROM SLS_IMPORT_DATA A WITH (NOLOCK)                                                          
 LEFT JOIN SKU B (NOLOCK) ON A.product_code =B.product_code                                                          
 WHERE A.SP_ID=@CSPID AND B.product_code IS NULL                                                           
 GROUP BY A.dept_id                                                          
 ) B ON A.dept_id =B.DEPT_ID                                                           
 )                                                          
 begin                                                          
                                                               
  set @CIMPORT_ERR_MSG =null                                                           
                                                          
    select   @CIMPORT_ERR_MSG=ISNULL(@CIMPORT_ERR_MSG+',','')+QUOTENAME(a.product_code)                                                          
   FROM SLS_IMPORT_DATA A WITH (NOLOCK)                                                            
  JOIN                                                          
  (                            
   SELECT A.product_code  FROM SLS_IMPORT_DATA A WITH (NOLOCK)                                                     
   LEFT JOIN SKU B (NOLOCK) ON A.product_code =B.product_code                                                          
   WHERE A.SP_ID=@CSPID AND B.product_code IS NULL                                                           
   GROUP BY A.product_code                                                           
  ) B ON A.product_code =B.product_code                                                           
  group by a.product_code      
                               
                            
    SELECT TOP 1 @CMEMO_NO= MEMO_NO,@DCM_DT= MEMO_DT                             
    FROM SLS_IMPORT_DATA A WITH (NOLOCK)                              
 LEFT JOIN SKU B (NOLOCK) ON A.product_code =B.product_code      
    WHERE A.SP_ID=@CSPID AND B.product_code IS NULL                                                      
                               
  set @CIMPORT_ERR_value=isnull(@CIMPORT_ERR_MSG,'')                                                      
  set @CIMPORT_ERR_MSG='Barcode not found:'                                                          
                                                          
   update a set IMPORT_STATUS=2,IMPORT_END_TIME=getdate(),                                                          
                IMPORT_ERR_MSG=@CIMPORT_ERR_MSG ,                             
    ERR_value=@CIMPORT_ERR_value,                    
    Email =@CEMAIL ,                            
    memo_no=@CMEMO_NO,                            
       memo_DT =@DCM_DT                            
   from SLS_IMPORT_STATUS a (nolock)                                                     
   where IMPORT_FILE_NAME=@CMAPPING_NAME                                            
      
      
  UPDATE A SET A.errormsg='Barcode not found'                          
    FROM SLS_IMPORT_DATA A                         
 LEFT JOIN SKU B (NOLOCK) ON A.product_code =B.product_code                                                          
    WHERE A.SP_ID=@CSPID AND B.product_code IS NULL                                                
 end                                                          
                                                          
  SET @CSTEP=14                                                            
                                                   
 UPDATE A SET A.errormsg='Quantity should not be zero.'                                                                
 FROM SLS_IMPORT_DATA A                           
 WHERE A.SP_ID=@CSPID AND CONVERT(NUMERIC(10,2),ISNULL(A.quantity,0))=0                                                                
                                                           
                                                                
                                                        
  SET @CSTEP=17                                                      
 UPDATE A SET A.errormsg=(CASE WHEN B.HSN_CODE IS NULL  THEN 'HSN Code not found.' ELSE '' END)                                                          
 FROM SLS_IMPORT_DATA A                                                                 
 LEFT JOIN HSN_MST  B(nolock) On ISNULL(A.HSN_CODE,'')=B.HSN_CODE                                                                
 WHERE A.SP_ID=@CSPID AND ISNULL(A.HSN_CODE,'')<>'' AND B.HSN_CODE IS NULL                                                                                   
                             
                                    
                
                                                               
    INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG,MEMO_DT )                                                                       
    SELECT PRODUCT_CODE,MEMO_NO AS  REF_NO,DEPT_ID,errormsg ,A.memo_dt                                                                     
    FROM SLS_IMPORT_DATA A (NOLOCK)                                                         
    WHERE A.SP_ID=@CSPID AND ISNULL(A.errormsg,'') <>''                                                       
                                                           
                                                                
IF EXISTS (SELECT PRODUCT_CODE FROM @TERRORDETAILS )                                                                
BEGIN                                                              
                             
   select top 1 @CMEMO_NO=REF_NO,@Dcm_dt=MEMO_DT,@CIMPORT_ERR_MSG=isnull(@CIMPORT_ERR_MSG,'')+ERROR_MSG                          
   from @TERRORDETAILS where isnull(ERROR_MSG,'')<>''                             
               if isnull(@CIMPORT_ERR_value,'')=''                          
    set @CIMPORT_ERR_value=@CIMPORT_ERR_MSG                         
                       
                      
 update a set IMPORT_STATUS=2,IMPORT_END_TIME=getdate(),                            
           IMPORT_ERR_MSG=@CIMPORT_ERR_MSG,                         
    ERR_value=@CIMPORT_ERR_value,                            
    Email =@CEMAIL   ,                            
    memo_no=@CMEMO_NO,                            
      memo_DT =@DCM_DT                            
   from SLS_IMPORT_STATUS a (nolock)                                                          
   where IMPORT_FILE_NAME=@CMAPPING_NAME                         
                          
 --   delete a FROM SLS_IMPORT_DATA A (NOLOCK)                            
 --join                          
 --(                          
 --   select DEPT_ID,memo_dt                           
 --   from @TERRORDETAILS                          
 --   group by DEPT_ID,memo_dt                          
 --) b  on a.DEPT_ID=b.DEPT_ID and a.memo_dt=b.memo_dt                          
 --   WHERE A.SP_ID=@CSPID                              
                             
 --  set @bfailedstatus=1                              
                          
END                                                             
                                             
     SET @CSTEP=18                                                       
                                                        
                                                       
select @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP= value from config where config_option='RETAIN_EXCEL_NRV_SISLOC_SALEIMP'                                                            
SET @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP=ISNULL(@cRETAIN_EXCEL_NRV_SISLOC_SALEIMP,'0')                                                            
                                                                       
--BEGIN TRANSACTION                                                                      
                                                            
 DECLARE @cCUSTOMER_CODE VARCHAR(50)='000000000000'                                                                
                                                         
                                                           
  PRINT 'UPDATE ROW ID OF ENTRIES'                                                                      
  UPDATE SLS_IMPORT_DATA SET ROW_ID=NEWID(),PROCESSED=0,ERRORMSG=''-- PENDING_QTY=QUANTITY,                                                                     
  WHERE DEPT_ID=@CLOCID      AND SP_ID=@CSPID                                                                
                                                           
 SET @cStep=20                                                       
 --UPDATE  SLS_IMPORT_DATA SET MEMO_DT= ((SUBSTRING(MEMO_DT,4,2) + '/' + SUBSTRING(MEMO_DT,1,2) + '/' +SUBSTRING(MEMO_DT,7,4)))                                                            
 -- WHERE ISNULL(MEMO_DT,'')<>''                                                             
                                                                
    SET @CCMD=N'SELECT 0 AS SR_NO,MEMO_NO AS BILL_NO,MEMO_DT AS CM_DT,DEPT_ID,A.PRODUCT_CODE,QUANTITY,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS AMOUNT,                                                                      
    CAST(ISNULL(CANCELLED,0) AS BIT) AS CANCELLED,'''' AS ERROR_MESSAGE,B.MRP AS MRP,                                                            
 CAST (0 AS NUMERIC(14,2)) AS DISCOUNT_AMT,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) CASH,0 CC_AMOUNT,'''' CC_NAME ,A.CMM_DISCOUNT_AMOUNT,A.CMM_OTHER_CHARGES,                                                            
 ISNULL(A.HSN_CODE  ,B.HSN_CODE) AS HSN_CODE ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount                                                     
 ,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS NET,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS NET_AMOUNT,CONVERT(NUMERIC(14,2),(B.MRP * QUANTITY)) AS NET_SALE,                                                            
 ISNULL(A.REMARKS,'''') AS REMARKS,ISNULL(cus_gst_state,'''') AS party_state_code,ISNULL(cus_gst_no,'''') AS party_gst_no                                          
 ,CAST (A.NET AS NUMERIC(14,2)) AS SIS_NET,CAST (0 AS NUMERIC(14,2)) AS SISLOC_EOSS_DISCOUNT_PERCENTAGE                                                            
 ,ISNULL(A.CMD_DISCOUNT_AMOUNT,0) AS SISLOC_EOSS_DISCOUNT_AMOUNT,ISNULL(A.MRP,0) AS SISLOC_MRP                                                            
 ,ISNULL(A.gst_percentage,0) sisloc_gst_percentage,A.xn_value_without_gst AS sisloc_taxable_value,ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0)  AS sisloc_lgst_amount    
 ,ISNULL(A.igst_amount,0) AS sisloc_igst_amount  ,CAST (0 AS NUMERIC(14,2)) AS xn_value_without_gst  ,ISNULL(A.CMD_DISCOUNT_PERCENTAGE,0) AS CMD_DISCOUNT_PERCENTAGE             
 ,ISNULL(A.weighted_avg_disc_pct,0) AS  weighted_avg_disc_pct
 ,ISNULL(A.weighted_avg_disc_amt,0) AS     weighted_avg_disc_amt  ,ISNULL(PAYMODE_NAME,'''') as PAYMODE_NAME
    FROM SLS_IMPORT_DATA A  (NOLOCK)                                                                     
    JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE                                                             
 WHERE A.SP_ID='''+@CSPID+''' '                                                            
                                        
 if @cRETAIN_EXCEL_NRV_SISLOC_SALEIMP='1'                                                            
 SET @CCMD=N'SELECT 0 AS SR_NO,MEMO_NO AS BILL_NO,MEMO_DT AS CM_DT,DEPT_ID,A.PRODUCT_CODE,QUANTITY,A.NET AS AMOUNT,                                                                      
    CAST(ISNULL(CANCELLED,0) AS BIT) AS CANCELLED,'''' AS ERROR_MESSAGE,ABS(ISNULL(A.MRP,0)) AS MRP,                                                            
 ISNULL(A.CMD_DISCOUNT_AMOUNT,0) AS DISCOUNT_AMT,A.NET CASH,0 CC_AMOUNT,'''' CC_NAME ,A.CMM_DISCOUNT_AMOUNT AS CMM_DISCOUNT_AMOUNT,A.CMM_OTHER_CHARGES,                                   
 ISNULL(A.HSN_CODE  ,B.HSN_CODE) AS HSN_CODE ,A.gst_percentage ,A.igst_amount ,A.cgst_amount,A.sgst_amount                                                                 
 ,A.NET,ISNULL(A.NET_AMOUNT,A.NET) AS NET_AMOUNT,A.NET AS NET_SALE,ISNULL(A.REMARKS,'''') AS REMARKS,ISNULL(cus_gst_state,'''') AS party_state_code  ,ISNULL(cus_gst_no,'''') AS party_gst_no                                                           
 ,ISNULL(A.NET_AMOUNT,A.NET) AS SIS_NET,ISNULL(A.CMD_DISCOUNT_PERCENTAGE,0)  AS SISLOC_EOSS_DISCOUNT_PERCENTAGE                                                            
 ,ISNULL(A.CMD_DISCOUNT_AMOUNT,0) AS SISLOC_EOSS_DISCOUNT_AMOUNT,ABS(ISNULL(A.MRP,0)) AS SISLOC_MRP                                                            
 ,ISNULL(A.gst_percentage,0) sisloc_gst_percentage,CAST (0 AS NUMERIC(14,2)) AS sisloc_taxable_value,ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0)  AS sisloc_lgst_amount,    
 ISNULL(A.igst_amount,0) AS sisloc_igst_amount                                         
 , A.xn_value_without_gst,ISNULL(A.CMD_DISCOUNT_PERCENTAGE,0) AS CMD_DISCOUNT_PERCENTAGE  ,ISNULL(A.weighted_avg_disc_pct,0) AS  weighted_avg_disc_pct
 ,ISNULL(A.weighted_avg_disc_amt,0) AS     weighted_avg_disc_amt     ,ISNULL(PAYMODE_NAME,'''') as PAYMODE_NAME                                         
    FROM SLS_IMPORT_DATA A  (NOLOCK)                                                                     
    JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE                                                         
 WHERE A.SP_ID='''+@CSPID+''' '                                                           
                                                            
    PRINT @CCMD                                                                      
                                                            
 --EXEC SP_EXECUTESQL @CCMD                                                             
                                                                        
    SET @CSTEP=25                                                                      
    INSERT #SLSIMPORT (SR_NO,BILL_NO,CM_DT,DEPT_ID,PRODUCT_CODE,QUANTITY,AMOUNT,CANCELLED,ERROR_MESSAGE ,MRP,DISCOUNT_AMT,                                                            
 CASH,CC_AMOUNT,CC_NAME,CMM_DISCOUNT_AMOUNT, CMM_OTHER_CHARGES, HSN_CODE   ,                                                            
 gst_percentage ,igst_amount ,cgst_amount,sgst_amount,                                         
 NET,NET_AMOUNT,NET_SALE,REMARKS,party_state_code,party_gst_no,                                                             
 sis_net,sisloc_eoss_discount_percentage,sisloc_eoss_discount_amount,sisloc_mrp ,                                                            
 sisloc_gst_percentage,sisloc_taxable_value,sisloc_lgst_amount,sisloc_igst_amount,xn_value_without_gst,CMD_DISCOUNT_PERCENTAGE,weighted_avg_disc_pct,weighted_avg_disc_amt
 ,PAYMODE_NAME)                                                      
    EXEC SP_EXECUTESQL @CCMD                                                                      
   --      SELECT * 
		 ----INTO ROHIT_SLSIMPORT 
		 --FROM #SLSIMPORT                                                        
                                                        
                                                      
    SET @CSTEP=30                                                                
    --UPDATE #SLSIMPORT SET CM_DT=CONVERT(VARCHAR(20),GETDATE(),111) WHERE ISNULL(CM_DT,'')=''                                                                     
                                
    UPDATE #SLSIMPORT SET FIN_YEAR='01'+DBO.FN_GETFINYEAR(CM_DT)                                  
                                 
          SET @CSTEP=30.0                                      
 --as Discuss with sanjiv sir ignore discount percentage as derived 22092022                                
                                           
 /* 1. MRP, DP and DA not mapped MRP = NRV/QS DP=0 DA=0 */                                          
 IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='MRP' AND ISNULL(MAPPED_COL,'')='') and                        
    EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='MRPvalue' AND ISNULL(MAPPED_COL,'')='')                         
 BEGIN                                          
/* 4. DP and DA mapped but not MRP Retain abs(DP) and DA as such  MRP = NRV/QS */                                          
   --IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND (MASTER_COL_EXPR ='CMD_DISCOUNT_AMOUNT'AND ISNULL(MAPPED_COL,'')<>'') )                                          
   --AND EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND (MASTER_COL_EXPR= 'CMD_DISCOUNT_PERCENTAGE' AND ISNULL(MAPPED_COL,'')<>''))                                          
   --BEGIN                                         
   -- SET @CSTEP=31                          
   -- UPDATE #SLSIMPORT SET MRP=(ABS(NET)+ABS(DISCOUNT_AMT))/ABS(QUANTITY)                                 
   --END                                          
   /* 3. DA mapped but not DP and MRP "Retain DA as such MRP = NRV/QS DP = DA / (MRP * QS) * 100 */                         
             
   IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='CMD_DISCOUNT_AMOUNT' AND ISNULL(MAPPED_COL,'')<>'')                                          
   BEGIN                                        SET @CSTEP=32                                        
    UPDATE #SLSIMPORT SET MRP=(ABS(isnull(NET,0))+ABS(isnull(DISCOUNT_AMT,0)))/ABS(QUANTITY)                                           
    UPDATE #SLSIMPORT SET CMD_DISCOUNT_PERCENTAGE=(ABS(DISCOUNT_AMT)*100)/(MRP * ABS(QUANTITY))                                          
   END                                          
   /* 2. DP mapped but not DA and MRP Retain DP as such MRP = NRV/QS DA = (MRP * QS) * DP / 100 */                                          
   --ELSE IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='CMD_DISCOUNT_PERCENTAGE' AND ISNULL(MAPPED_COL,'')<>'')                                          
   --BEGIN                                          
--SET @CSTEP=33                                        
   -- UPDATE #SLSIMPORT SET MRP=(((ABS(NET))/ABS(QUANTITY))*100)/(100-ABS(CMD_DISCOUNT_PERCENTAGE))                                          
   -- UPDATE #SLSIMPORT SET  DISCOUNT_AMT= (MRP * QUANTITY) * ABS(CMD_DISCOUNT_PERCENTAGE) / 100                                          
   --END                                          
   /* 1. MRP, DP and DA not mapped MRP = NRV/QS DP=0 DA=0 */                                          
   ELSE                     
   BEGIN                                         
   SET @CSTEP=34                                     
                                   
    UPDATE #SLSIMPORT SET MRP=(ABS(isnull(NET,0)))/ABS(QUANTITY),DISCOUNT_AMT=0,CMD_DISCOUNT_PERCENTAGE=0                                
   END                                          
 end                                          
 ELSE                              BEGIN                                          
   /* 5. DP and MRP mapped but not DA Retain DP and MRP as such DA = MRP * QS * DP / 100 */                                          
   --IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='CMD_DISCOUNT_PERCENTAGE' AND ISNULL(MAPPED_COL,'')<>'') )                                          
   -- --AND EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='MRP' AND ISNULL(MAPPED_COL,'')<>''))                                          
   --BEGIN                                          
   --SET @CSTEP=35                                        
   -- --SELECT DISCOUNT_AMT AS DA,DISCOUNT_AMT= (MRP * QUANTITY) * ABS(CMD_DISCOUNT_PERCENTAGE) / 100 FROM #SLSIMPORT                                          
   -- UPDATE #SLSIMPORT SET  DISCOUNT_AMT= (MRP * QUANTITY) * ABS(CMD_DISCOUNT_PERCENTAGE) / 100                                          
   --END                                          
   /* 6. DA and MRP mapped but not DP Retain DA MRP as such DP = DA / (MRP * QS) / 100 */                                          
   IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='CMD_DISCOUNT_AMOUNT' AND ISNULL(MAPPED_COL,'')<>'') )                     
    --AND EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='MRP' AND ISNULL(MAPPED_COL,'')<>''))                                          
   BEGIN                                           
   SET @CSTEP=36                                        
    UPDATE #SLSIMPORT SET CMD_DISCOUNT_PERCENTAGE=ABS((ABS(isnull(DISCOUNT_AMT,0))*100)/(isnull(MRP,0) * ABS(QUANTITY)))  where (isnull(MRP,0) * ABS(QUANTITY))<>0                                        
   END                                          
                                          
   --IF NOT EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='CMD_DISCOUNT_PERCENTAGE' AND ISNULL(MAPPED_COL,'')<>'') )                                          
   -- AND NOT EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='CMD_DISCOUNT_AMOUNT' AND ISNULL(MAPPED_COL,'')<>''))                                          
   --BEGIN                                           
   --SET @CSTEP=37                                        
   -- --SELECT DISCOUNT_AMT AS DA,DISCOUNT_AMT= (MRP * QUANTITY) * ABS(CMD_DISCOUNT_PERCENTAGE) / 100 FROM #SLSIMPORT                                          
  -- UPDATE #SLSIMPORT SET  DISCOUNT_AMT= (MRP * QUANTITY) - NET                                          
   -- UPDATE #SLSIMPORT SET CMD_DISCOUNT_PERCENTAGE=ABS((ABS(DISCOUNT_AMT)*100)/(MRP * ABS(QUANTITY)))                                         
   -- where (MRP * ABS(QUANTITY))<>0                                        
   --END                                    
                                   
   IF     NOT EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND (MASTER_COL_EXPR='CMD_DISCOUNT_AMOUNT' AND ISNULL(MAPPED_COL,'')<>''))                                     
   BEGIN                                           
   SET @CSTEP=37                                --SELECT DISCOUNT_AMT AS DA,DISCOUNT_AMT= (MRP * QUANTITY) * ABS(CMD_DISCOUNT_PERCENTAGE) / 100 FROM #SLSIMPORT                                 
            
              
                                    
     UPDATE #SLSIMPORT SET  DISCOUNT_AMT= (isnull(MRP,0) * QUANTITY) - isnull(NET,0)                              
     UPDATE #SLSIMPORT SET CMD_DISCOUNT_PERCENTAGE=ABS((ABS(DISCOUNT_AMT)*100)/(isnull(MRP,0) * ABS(QUANTITY)))                                         
     where (isnull(MRP,0) * ABS(QUANTITY))<>0                                    
              
                  
            
   END                                     
                                  
 END                                          
                                                              
                                                            
   SET @CSTEP=38                                               
 UPDATE #SLSIMPORT SET  MRP=ABS(MRP),DISCOUNT_AMT= ABS(DISCOUNT_AMT),NET= ABS(NET) WHERE convert(numeric(10,3),QUANTITY)>0                                                          
 UPDATE #SLSIMPORT SET  MRP=ABS(MRP),DISCOUNT_AMT=-1* ABS(DISCOUNT_AMT),NET=-1* ABS(NET) WHERE convert(numeric(10,3),QUANTITY)<0                      
                   
 UPDATE #SLSIMPORT SET CMD_DISCOUNT_PERCENTAGE=ROUND(CMD_DISCOUNT_PERCENTAGE,0) WHERE CMD_DISCOUNT_PERCENTAGE>100                  
                              
   IF EXISTS (SELECT 'U' FROM #SLSIMPORT WHEre isnull(mrp,0) <=0)                                
  begin                                
                              
  SET @CIMPORT_ERR_MSG=isnull(@CIMPORT_ERR_MSG,'')+'mrp should not be less than or equal zero'                             


SET @CSTEP=39                             
   SELECT TOP 1 @CMEMO_NO=BILL_NO,@DCM_DT=CM_DT                            
   FROM #SLSIMPORT A  WHERE ISNULL(MRP,0) <=0                              
                          
 if isnull(@CIMPORT_ERR_value,'')=''                          
    set @CIMPORT_ERR_value=@CIMPORT_ERR_MSG                                                            
                          
SET @CSTEP=40                      
 update a set IMPORT_STATUS=2,IMPORT_END_TIME=getdate(),                            
                IMPORT_ERR_MSG=@CIMPORT_ERR_MSG,                            
    ERR_value=@CIMPORT_ERR_value,                            
    Email =@CEMAIL   ,                            
    memo_no=@CMEMO_NO,                            
      memo_DT =@DCM_DT                            
   from SLS_IMPORT_STATUS a (nolock)                                                          
   where IMPORT_FILE_NAME=@CMAPPING_NAME                         
                      
 --   DELETE A FROM #SLSIMPORT A (NOLOCK)                            
 --JOIN                          
 --(                          
 --   SELECT DEPT_ID,CM_DT                           
 --   FROM #SLSIMPORT                          
 --   WHERE ISNULL(MRP,0) <=0                              
 --   GROUP BY DEPT_ID,CM_DT                          
 --) B  ON A.DEPT_ID=B.DEPT_ID AND A.CM_DT=B.CM_DT                          
                        
 --    set @bfailedstatus=1                            
                           
                          
  end                  
              
                 
            
 --UPDATE A SET A.errormsg=ISNULL(A.errormsg,'')+CHAR(13)+ 'Memo No : '+ISNULL(memo_no,'') +' AND memo_dt : '+ISNULL(memo_dt,'')+' ' +  'MRP should not be less than NET.'                                                                
  IF EXISTS (SELECT TOP 1 'U'                               
  FROM #SLSIMPORT A                                                                
  WHERE  ABS(                             
    (ABS(CONVERT(NUMERIC(20,2),ISNULL(A.NET,0)))+                                
     ABS(CONVERT(NUMERIC(20,2),ISNULL(A.DISCOUNT_AMT,0))))-                                
     ABS(CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)))                                
    )>5                                   
    )                                
 BEGIN                                
                                      
                                
   INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG,MEMO_DT  )                                                     
  select a.PRODUCT_CODE,a.BILL_NO,a.DEPT_ID,                                
      'MRP SHOULD NOT BE LESS THAN NET.'  AS ERROR_MSG  ,A.CM_DT                            
  from #SLSIMPORT a         
   WHERE  ABS(                                
    (ABS(CONVERT(NUMERIC(20,2),ISNULL(A.NET,0)))+                                
     ABS(CONVERT(NUMERIC(20,2),ISNULL(A.DISCOUNT_AMT,0))))-                                
     ABS(CONVERT(NUMERIC(20,2),ISNULL(A.MRP,0))* CONVERT(NUMERIC(20,2),ISNULL(A.QUANTITY,0)))                                
    )>5                           
                                   
     select top 1 @CIMPORT_ERR_MSG=isnull(@CIMPORT_ERR_MSG,'')+isnull(ERROR_MSG,''),@CMEMO_NO=REF_NO,@DCM_DT=MEMO_DT from @TERRORDETAILS where isnull(ERROR_MSG,'')<>''                                
                       
 if isnull(@CIMPORT_ERR_value,'')=''                          
    set @CIMPORT_ERR_value=@CIMPORT_ERR_MSG                                                            
                          
 update a set IMPORT_STATUS=2,IMPORT_END_TIME=getdate(),                            
                IMPORT_ERR_MSG=@CIMPORT_ERR_MSG,                            
    ERR_value=@CIMPORT_ERR_value,                            
    Email =@CEMAIL   ,                            
    memo_no=@CMEMO_NO,                            
      memo_DT =@DCM_DT                            
   from SLS_IMPORT_STATUS a (nolock)                                                          
   where IMPORT_FILE_NAME=@CMAPPING_NAME                         
                      
 --   DELETE A FROM #SLSIMPORT A (NOLOCK)                            
 --JOIN                          
 --(                          
 --   SELECT DEPT_ID,memo_dt                           
 --   FROM @TERRORDETAILS                          
 --   GROUP BY DEPT_ID,memo_dt                          
 --) B  ON A.DEPT_ID=B.DEPT_ID AND A.CM_DT=B.memo_dt                          
                              
 --    set @bfailedstatus=1                             
                                
 END                                
                                                             
 /* 8. TV, GP and GA not mapped TV = NRV GP = 0 GA = 0 */                                              
 /* 8. TV, GP and GA not mapped TV = NRV GP = 0 GA = 0 */                                          
 IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='XN_VALUE_WITHOUT_GST' AND ISNULL(MAPPED_COL,'')='')                                          
 BEGIN                                          
                                
   /* 10. GP mapped but not GA and TV "Retain GP as such TV = NRV - ((NRV * GP) / (100 + GP)) GA = TV * GP / 100  */                                          
   --IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='GST_PERCENTAGE' AND ISNULL(MAPPED_COL,'')<>'')                                          
   --BEGIN                                           
   --SET @CSTEP=39                                        
   -- UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=NET-((NET * gst_percentage)/(100+gst_percentage))                                       
   -- UPDATE #SLSIMPORT SET igst_amount=XN_VALUE_WITHOUT_GST * gst_percentage/100                                          
   --END                                       
   /*  1. XN_VALUE_WITHOUT_GST ,IGST_AMOUNT,CGST_AMOUNT ,SGST_AMOUNT  NOT MAPPED 22092022 */                                
   IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='igst_amount' AND ISNULL(MAPPED_COL,'')='') and                                 
      EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='cgst_amount' AND ISNULL(MAPPED_COL,'')='') and                                          
      EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='sgst_amount' AND ISNULL(MAPPED_COL,'')='')                                 
   begin                                
        UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=isnull(NET,0),igst_amount =0,cgst_amount =0,sgst_amount= 0 ,gst_percentage =0                                    
   end                                
    /* 2. XN_VALUE_WITHOUT_GST NOT MAPPED , either (IGST_AMOUNT,CGST_AMOUNT ,SGST_AMOUNT   MAPPED) 22092022   */                                  
   else  IF( EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='igst_amount' AND ISNULL(MAPPED_COL,'')<>'') or                                 
             exists  (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='cgst_amount' AND ISNULL(MAPPED_COL,'')<>'') or                                
    exists   (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='sgst_amount' AND ISNULL(MAPPED_COL,'')<>'')                                 
   )                                
   BEGIN                                          
     SET @CSTEP=40                                        
     UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=NET-(isnull(IGST_AMOUNT,0)+isnull(CGST_AMOUNT,0) +isnull(SGST_AMOUNT,0))                                       
     UPDATE #SLSIMPORT SET  gst_percentage= abs((isnull(IGST_AMOUNT,0)+isnull(CGST_AMOUNT,0) +isnull(SGST_AMOUNT,0)) /isnull(XN_VALUE_WITHOUT_GST,0) *100)  WHERE XN_VALUE_WITHOUT_GST<>0                                          
   END                                          
   /* 11. GA mapped but not GP and TV Retain GA as such TV = NRV - GA GP = GA / TV * 100   */                                          
   --ELSE IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='cgst_amount' AND ISNULL(MAPPED_COL,'')<>'')                                          
   --AND EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='sgst_amount' AND ISNULL(MAPPED_COL,'')<>'')                                          
   --BEGIN                                          
   --SET @CSTEP=41                                        
   -- UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=NET-(cgst_amount +sgst_amount)                                          
   -- UPDATE #SLSIMPORT SET  gst_percentage= (cgst_amount +sgst_amount)/XN_VALUE_WITHOUT_GST *100                                          
   --END                                          
                                
   /* 8. TV, GP and GA not mapped TV = NRV GP = 0 GA = 0 */                                          
   --ELSE                                           
   --BEGIN                                          
   --SET @CSTEP=42                                        
   -- UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=NET,igst_amount=0,cgst_amount=0,sgst_amount=0,gst_percentage=0                                          
   --END                                          
 END                                          
 ELSE                                          
 BEGIN                                   
                                 
   /* 12. TV and GP mapped but not GA Retain TV and GP as such GA = TV * GP / 100   */                                          
   --IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE SP_ID=@CSPID AND MASTER_COL_EXPR='GST_PERCENTAGE' AND ISNULL(MAPPED_COL,'')<>'')                                         
   --BEGIN                                           
   --SET @CSTEP=43                                        
   -- UPDATE #SLSIMPORT SET igst_amount=XN_VALUE_WITHOUT_GST * gst_percentage/100                                          
   --END                                          
     /*  1. XN_VALUE_WITHOUT_GST mapped and IGST_AMOUNT,CGST_AMOUNT ,SGST_AMOUNT  NOT MAPPED 22092022 */                                
    IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='igst_amount' AND ISNULL(MAPPED_COL,'')='') and                                 
      EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='cgst_amount' AND ISNULL(MAPPED_COL,'')='') and                                          
      EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='sgst_amount' AND ISNULL(MAPPED_COL,'')='')                    
   begin                                
        UPDATE #SLSIMPORT SET IGST_AMOUNT =isnull(NET,0)-isnull(XN_VALUE_WITHOUT_GST,0)                              
     UPDATE #SLSIMPORT SET  gst_percentage= abs(isnull(igst_amount,0)/isnull(XN_VALUE_WITHOUT_GST,0) *100)  WHERE isnull(XN_VALUE_WITHOUT_GST,0)<>0                                  
   end                                
   else  IF( EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='igst_amount' AND ISNULL(MAPPED_COL,'')<>'') or                                 
             exists  (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='cgst_amount' AND ISNULL(MAPPED_COL,'')<>'') or                                
    exists   (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='sgst_amount' AND ISNULL(MAPPED_COL,'')<>'')                                 
   )                                
   BEGIN                                          
   SET @CSTEP=40                                                 
    UPDATE #SLSIMPORT SET  gst_percentage= abs((isnull(IGST_AMOUNT,0)+isnull(CGST_AMOUNT,0) +isnull(SGST_AMOUNT,0)) /isnull(XN_VALUE_WITHOUT_GST,0) *100)  WHERE isnull(XN_VALUE_WITHOUT_GST,0)<>0                                          
   END                                   
                           
   --/* 13. TV and GA mapped but not GP Retain TV and GA as such GP = GA / TV * 100 */                                          
   --ELSE IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR='igst_amount' AND ISNULL(MAPPED_COL,'')<>'')                                          
   --BEGIN                                          
   --SET @CSTEP=44                                        
   -- UPDATE #SLSIMPORT SET  gst_percentage= igst_amount/XN_VALUE_WITHOUT_GST *100  WHERE XN_VALUE_WITHOUT_GST<>0                                        
   --END                            
   --/* 13. TV and GA mapped but not GP Retain TV and GA as such GP = GA / TV * 100 */                                 
   --ELSE IF EXISTS (SELECT 'U' FROM SLS_IMPORT_DATA_MAPPING WHERE  SP_ID=@CSPID AND MASTER_COL_EXPR IN ('cgst_amount','sgst_amount') AND ISNULL(MAPPED_COL,'')<>'')                                          
   --BEGIN                                          
   --SET @CSTEP=45                                        
   -- UPDATE #SLSIMPORT SET  gst_percentage= (cgst_amount +sgst_amount)/XN_VALUE_WITHOUT_GST *100                                          
   --END                                          
   --/* 9. TV mapped but not GP and GA Retain TV as such GA = NRV - TV GP = GA / TV * 100 */                                          
   --ELSE                                           
   --BEGIN                                          
--SET @CSTEP=46                                        
                                          
   -- UPDATE #SLSIMPORT SET igst_amount=NET-XN_VALUE_WITHOUT_GST                    
   -- UPDATE #SLSIMPORT SET  gst_percentage= igst_amount/XN_VALUE_WITHOUT_GST *100                                          
   -- where XN_VALUE_WITHOUT_GST<>0                                        
   --END                                          
 END                                      
                                 
                                
                                                             
   SET @CSTEP=48                                                          
 UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=ABS(XN_VALUE_WITHOUT_GST),igst_amount=ABS(igst_amount),cgst_amount=ABS(cgst_amount),                                                            
 sgst_amount=ABS(sgst_amount),gst_percentage=ABS(gst_percentage) WHERE convert(numeric(10,3),QUANTITY)>0                                       
                                                            
 UPDATE #SLSIMPORT SET XN_VALUE_WITHOUT_GST=-1*ABS(XN_VALUE_WITHOUT_GST),igst_amount=-1*ABS(igst_amount),cgst_amount=-1*ABS(cgst_amount),                                                         
 sgst_amount=-1*ABS(sgst_amount),gst_percentage=ABS(gst_percentage) WHERE convert(numeric(10,3),QUANTITY)<0                                                            
                                  
   IF EXISTS (SELECT TOP 1 'U'                                
  FROM #SLSIMPORT A                                                                
  WHERE  ABS(                                
      (                                
      ABS(isnull(xn_value_without_gst,0)+isnull(cgst_amount,0) +isnull(sgst_amount,0)+isnull(igst_amount,0) ))-(ABS(net)                                
      )                                
     )>5                                   
    )                                
 BEGIN                                
                                      
                                
    INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG,MEMO_DT )                                          
  select a.PRODUCT_CODE,a.BILL_NO,a.DEPT_ID,                              
        'Taxable Value Plus Gst Amount should not be equal Net.'  AS ERROR_MSG,A.CM_DT                              
  from #SLSIMPORT a                                
   WHERE  ABS                                
     ((ABS(isnull(xn_value_without_gst,0)+isnull(cgst_amount,0) +isnull(sgst_amount,0)+isnull(igst_amount,0) ))-                                
   (ABS(net))                                
     )>5                                   
                                
                   
                           
  select top 1 @CIMPORT_ERR_MSG=isnull(@CIMPORT_ERR_MSG,'')+isnull(ERROR_MSG,''),@CMEMO_NO=REF_NO,@DCM_DT=MEMO_DT from @TERRORDETAILS where isnull(ERROR_MSG,'')<>''                                
                            
                              
 if isnull(@CIMPORT_ERR_value,'')=''                          
    set @CIMPORT_ERR_value=@CIMPORT_ERR_MSG                                     
    
--SELECT isnull(@CIMPORT_ERR_value,'')    
                          
 update a set IMPORT_STATUS=2,IMPORT_END_TIME=getdate(),                            
                IMPORT_ERR_MSG=@CIMPORT_ERR_MSG,                            
    ERR_value=@CIMPORT_ERR_value,                            
    Email =@CEMAIL   ,                            
    memo_no=@CMEMO_NO,                     
      memo_DT =@DCM_DT                            
   from SLS_IMPORT_STATUS a (nolock)                                                          
   where IMPORT_FILE_NAME=@CMAPPING_NAME                         
                      
 --   DELETE A FROM #SLSIMPORT A (NOLOCK)                            
 --JOIN                          
 --(                          
 --   SELECT DEPT_ID,memo_dt                           
 --   FROM @TERRORDETAILS                          
 --   GROUP BY DEPT_ID,memo_dt                          
 --) B  ON A.DEPT_ID=B.DEPT_ID AND A.CM_DT=B.memo_dt      
                              
     --set @bfailedstatus=1                            
                                
 END                                
                                
 IF EXISTS ( SELECT TOP 1 'U' FROM #SLSIMPORT WHERE ABS(CGST_AMOUNT)-ABS(SGST_AMOUNT)>1)                                
 begin                                
                                
  INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG,MEMO_DT )                                                     
  select a.PRODUCT_CODE,a.BILL_NO,a.DEPT_ID,                             
         'cgst Amount and sgst Amount is not equal.' AS ERROR_MSG,A.CM_DT                                 
  from #SLSIMPORT a                                
  WHERE ABS(CGST_AMOUNT)-ABS(SGST_AMOUNT)>1                                
                                
  select top 1 @CIMPORT_ERR_MSG=isnull(@CIMPORT_ERR_MSG,'')+isnull(ERROR_MSG,''),@CMEMO_NO=REF_NO,@DCM_DT=MEMO_DT from @TERRORDETAILS where isnull(ERROR_MSG,'')<>''                                
                              
                          
 if isnull(@CIMPORT_ERR_value,'')=''                          
    set @CIMPORT_ERR_value=@CIMPORT_ERR_MSG                  
                          
 update a set IMPORT_STATUS=2,IMPORT_END_TIME=getdate(),                            
                IMPORT_ERR_MSG=@CIMPORT_ERR_MSG,                            
    ERR_value=@CIMPORT_ERR_value,                            
    Email =@CEMAIL   ,                            
    memo_no=@CMEMO_NO,                            
      memo_DT =@DCM_DT                            
   from SLS_IMPORT_STATUS a (nolock)                                                          
   where IMPORT_FILE_NAME=@CMAPPING_NAME                         
                      
 --   DELETE A FROM #SLSIMPORT A (NOLOCK)                            
 --JOIN                          
 --(                          
 --   SELECT DEPT_ID,memo_dt                           
 --   FROM @TERRORDETAILS                          
 --   GROUP BY DEPT_ID,memo_dt                          
 --) B  ON A.DEPT_ID=B.DEPT_ID AND A.CM_DT=B.memo_dt                          
                              
 --    set @bfailedstatus=1                            
                            
 end                                
                            
                           
    select @total_Quantity=sum(cast(isnull(QUANTITY,0) as numeric(10,3)))                                                      
    from #SLSIMPORT                          
                              
                                
  SET @CSTEP=70                                                                      
                                                               
 LBLIMPORTSLS:                       
                                                     
  PRINT 'START SALE IMPORT'                                                                      
  SET @CPRODUCTCODE=''                                                                      
                                                                       
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)             
                                                        
  IF OBJECT_ID('TEMPDB..#EXISTINGBILLS','U') IS NOT NULL                              
   DROP TABLE #EXISTINGBILLS                                                                      
                                                                       
  SET @CSTEP=40                                                                       
  IF OBJECT_ID('TEMPDB..#NEWBILLS','U') IS NOT NULL          
   DROP TABLE #NEWBILLS                                                                      
                                                                         
  SET @CSTEP=50                                  
  SELECT A.BILL_NO,SUM(CONVERT(NUMERIC(18,2),AMOUNT)) AS AMOUNT,                                                                      
   SUM(CONVERT(NUMERIC(18,2),CASH)) AS CASH,                                                                      
   SUM(CONVERT(NUMERIC(18,2),CC_AMOUNT)) AS CC_AMOUNT                                                                      
   INTO #SLSTMP                                                                      
   FROM #SLSIMPORT A                                                                     
   GROUP BY A.BILL_NO                                                                   
                                                                     
                                                                        
  SELECT TOP 1 @CERRMSG=ERROR_MESSAGE FROM #SLSIMPORT WHERE DEPT_ID=@CLOCID AND ISNULL(ERROR_MESSAGE,'')<>''                                                                      
  IF ISNULL(@CERRMSG,'')<>''                                                                      
  BEGIN                           
   INSERT @TERRORDETAILS ( PRODUCT_CODE, REF_NO, DEPT_ID, ERROR_MSG,MEMO_DT  )             
   SELECT PRODUCT_CODE,BILL_NO AS  REF_NO,DEPT_ID,ISNULL(@CERRMSG,''),A.CM_DT--'DIFFERENCE IN PAYMENT AMOUNT AND NET AMOUNT ,PAYMENT AMOUNT - '+STR(AMOUNT)+' AND NET AMOUNT '+STR((A.CASH+A.CC_AMOUNT))+''  AS ERROR_MSG         
                                
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
         
  --SeLECT ISNULL(@CERRMSG,''),* FROM #SLSIMPORT    
    
  IF ISNULL(@CERRMSG,'')<>''                                                                      
   GOTO END_PROC                                                                      
                                                                              
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)                                                               
                                                            
  CREATE INDEX IX_TMP_REF ON #SLSIMPORT (BILL_NO)                                                          
  include (fin_year,dept_id)                                                
    
    
    
  SET @CSTEP=70                                                                      
  --LIST OF EXISTING BILLS                                                                      
  SELECT B.CM_ID                                                                      
  ,B.CM_NO                                                                       
  ,A.DEPT_ID+'-'+ISNULL(A.BILL_NO,'') AS BILL_NO                                    
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
  ,A.REMARKS,A.NET,A.NET_AMOUNT    ,ISNULL(GST.gst_state_code,'') party_state_code           ,ISNULL(A.party_gst_no,'') party_gst_no                                                        
  ,A.sis_net,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp                                                            
  ,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst                                                  
  ,A.CMD_DISCOUNT_PERCENTAGE    ,A.weighted_avg_disc_pct,A.weighted_avg_disc_amt     
  ,A.paymode_name
  INTO #EXISTINGBILLS                                                                      
  FROM #SLSIMPORT A                                                                      
  JOIN CMM01106 B(NOLOCK) ON A.DEPT_ID=b.location_Code and  A.DEPT_ID+'-'+ISNULL(A.BILL_NO,'')=B.REF_NO --AND A.FIN_YEAR=B.FIN_YEAR                                                            
  AND CONVERT(DATETIME,A.CM_DT) =    B.CM_DT AND B.CANCELLED=0                                                   
  LEFT OUTER JOIN gst_state_mst GST (NOLOCK) ON GST.gst_state_code=A.party_state_code                                         
                                          
    --if @CSPID='1000'                                           
    -- select * from #EXISTINGBILLS                                          
                                               
UPDATE A SET PARTY_STATE_CODE =LEFT(ISNULL(A.party_gst_no,''),2)
FROM #EXISTINGBILLS  A (NOLOCK)                                                                   
WHERE ISNULL( A.party_gst_no,'')<>'' AND LEN(ISNULL( A.party_gst_no,''))>2
                                                            
 UPDATE A SET PARTY_STATE_CODE =CASE WHEN ISNULL(B.GST_STATE_CODE   ,'') ='' THEN '00' ELSE B.GST_STATE_CODE END                                                                   
   FROM #EXISTINGBILLS  A (NOLOCK)                                                  
   JOIN LOCATION   B ON A.DEPT_ID =B.DEPT_ID                                                                    
   AND  A.PARTY_STATE_CODE IN('','00')                                                             
                        
  SET @CSTEP=80                                                  
  --LIST OF NEW BILLS                                                                      
  SELECT CONVERT(VARCHAR(50),'') AS CM_NO                                                                      
  ,A.DEPT_ID+'-'+ISNULL(A.BILL_NO,'') AS BILL_NO                                                                      
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
  ,A.REMARKS,A.NET,A.NET_AMOUNT,ISNULL(GST.gst_state_code,'') AS  party_state_code             ,ISNULL(A.party_gst_no,'') party_gst_no                               
  ,A.sis_net,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp                                                    
  ,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst                                                            
  ,A.CMD_DISCOUNT_PERCENTAGE ,SRNO=CAST(0 AS NUMERIC(5,0))      , A.weighted_avg_disc_pct,A.weighted_avg_disc_amt   
  ,'LATER'+ISNULL(A.BILL_NO,'')+CONVERT(VARCHAR,CONVERT(DATETIME,A.CM_DT),105) AS CM_ID    
  ,A.paymode_name
  INTO #NEWBILLS                                            
  FROM #SLSIMPORT A                                       
  LEFT JOIN CMM01106 B(NOLOCK) ON A.DEPT_ID=b.location_code and  A.DEPT_ID+'-'+ISNULL(A.BILL_NO,'')=B.REF_NO --AND A.FIN_YEAR=B.FIN_YEAR                                                              
  AND CONVERT(DATETIME,A.CM_DT) =    B.CM_DT  AND B.cancelled=0                                                            
  LEFT OUTER JOIN gst_state_mst GST (NOLOCK) ON GST.gst_state_code=A.party_state_code                                                            
  WHERE B.CM_ID IS NULL                                                        
                                                        
                                                        

           
UPDATE A SET PARTY_STATE_CODE =LEFT(ISNULL(A.party_gst_no,''),2)
FROM #NEWBILLS  A (NOLOCK)                                                                   
WHERE  ISNULL( A.party_gst_no,'')<>'' AND LEN(ISNULL( A.party_gst_no,''))>2
           
 UPDATE A SET PARTY_STATE_CODE =CASE WHEN ISNULL(B.GST_STATE_CODE   ,'') ='' THEN '00' ELSE B.GST_STATE_CODE END                                                                   
FROM #NEWBILLS  A (NOLOCK)                                                                   
JOIN LOCATION   B ON A.DEPT_ID =B.DEPT_ID                                                                    
AND  A.PARTY_STATE_CODE IN('','00')                                                             
                                                                  
    
update #NEWBILLS SET CM_NO='LATER'    
                                                                
  if object_id ('tempdb..#tmpcm_id','u') is not null                                                                
     drop table #tmpcm_id                                                                
  SELECT DISTINCT dept_id, CM_ID INTO #TMPCM_ID FROM #EXISTINGBILLS                                                              
                                                                  
--select * from    #NEWBILLS                                   
--SELECT * FROM #EXISTINGBILLS      
                                                          
  SET @CSTEP=410                                      
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)                                                   
                                                                                                       
                                                                       
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
                                         
  ;WITH CTE AS                                                          
  (                                                          
    SELECT *, SR=DENSE_RANK () OVER(ORDER BY A.DEPT_ID,ISNULL(A.BILL_NO,''),A.FIN_YEAR)                                                          
FROM #NEWBILLS a where DEPT_ID =@CDEPT_ID                                                          
  )                              
  UPDATE CTE SET SRNO =SR                                                          
                                                          
                                                          
   SET @CMEMOPREFIX=LTRIM(RTRIM(@CDEPT_ID))+ISNULL(@CUSER_ALIAS,'')+'-'                                                                      
                                                                 
  LBLGENKEY:                                                                      
                                                              
                                                              
SET @CSTEP=500                                  
   --EXEC GETNEXTKEY_OPT 'CMM01106', 'CM_NO', @NMEMONOLEN, @CMEMOPREFIX, 1,@CFINYEAR,0, @CKEYSTABLE,@CMEMONOVAL OUTPUT                                                                     
                                                            
   --SET @CSTEP=510                                                                
   --IF EXISTS(SELECT TOP 1 'U' FROM CMM01106 WHERE CM_NO=@CMEMONOVAL AND FIN_YEAR=@CFINYEAR)                                                                      
   -- GOTO LBLGENKEY                                                              
                                                    
                                                                      
 SET @CSTEP=520                                                                      
   IF ISNULL(@CMEMONOVAL,'')=''                                                                      
   BEGIN                                                          
                                                             
    SET @CERRMSG='ERROR GENERATING CM NO.'                                                                      
    GOTO END_PROC                                
   END                                                                      
                                                                    
   SET @CSTEP=500                                                                      
                                                                      
   SET @CSTEP=530                                                                       
   UPDATE #NEWBILLS SET CM_NO=rtrim(ltrim(@CMEMOPREFIX+replicate('0',12-len(ltrim(rtrim(@CMEMOPREFIX+CAST(RIGHT(@CMEMONOVAL,6)+SRNO-1 AS VARCHAR(10))))))+CAST(RIGHT(@CMEMONOVAL,6)+SRNO-1 AS VARCHAR(10))))                                                  
  
    
      
        
   WHERE DEPT_ID=@CDEPT_ID                                                            
                                                             
   UPDATE A SET CM_NO='' FROM #NEWBILLS A                                                          
   JOIN CMM01106 B ON A.CM_NO =B.CM_NO  AND A.FIN_YEAR =B.FIN_YEAR                                                           
                                                          
                                                                     
  END                                                                      
   SET @CSTEP=540                                                                      
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)                                      
 --UPDATE #NEWBILLS SET CM_ID=LTRIM(RTRIM(DEPT_ID))+FIN_YEAR+REPLICATE('0',15-LEN(LTRIM(RTRIM(CM_NO))))+LTRIM(RTRIM(CM_NO))                                                    
--select left (cm_no,5) as prefix ,max(cm_no) as maxcm_no,fin_year                                                           
 --into #tmpkeys                                                          
 --from #NEWBILLS a                        
 --group by left (cm_no,5),fin_year                                                          
                                                          
 --update a set LastKeyVal =b.maxcm_no                                                           
 --from keys_cmm  a                                                          
 --join #tmpkeys b on a.prefix=b.prefix and a.FinYear=b.fin_year                                                          
                                               
                                                          
  --GOTO END_PROC                                                           
                                              
  SET @CSTEP=550                                                   
  IF EXISTS(SELECT TOP 1 'U' FROM #NEWBILLS WHERE ISNULL(CM_ID,'')='' OR ISNULL(CM_NO,'')='')                                                                      
  BEGIN                                                            
                                                             
   SET @CERRMSG='ERROR GENERATING CM ID.'                                                                      
   GOTO END_PROC                                                                      
  END                                                                    
                                                                 
                                 
  SET @CSTEP=540                      
                                                            
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
                                                            
   --delete a  from Paymode_xn_det a with(nolock)                                        
   --join #EXISTINGBILLS b on a.memo_id =b.cm_id                                                           
   --where a.xn_type ='sls'                                                          
                                                    
   --delete a  from cmd01106 a with(nolock)                                                          
   --join #EXISTINGBILLS b on a.cm_id =b.cm_id                                                           
                                                             
            
   --delete a  from cmm01106 a with(nolock)                                                          
   --join #EXISTINGBILLS b on a.cm_id =b.cm_id                                                          
                                                         
                                                      
  -- if @CSPID ='1000'                                          
                                                        
                                                      
                                                          
  SET @CSTEP=560                                                                      
  --INSERT cmm01106 ( REMARKS, SENT_FOR_RECON, PARTY_TYPE, AC_CODE, MANUAL_DISCOUNT, MANUAL_ROUNDOFF         
  -- , BIN_ID, PATCHUP_RUN, SUBTOTAL_R, PASSPORT_NO, TICKET_NO, FLIGHT_NO, MRP_WSP                                                                      
  -- , MANUAL_BILL, FC_RATE, POSTEDINAC, CM_NO, CM_DT, CM_MODE, SUBTOTAL, DT_CODE                                                                      
  -- , DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, NET_AMOUNT, CUSTOMER_CODE, CANCELLED, USER_CODE                                                                      
  -- , LAST_UPDATE, EXEMPTED,  SENT_TO_HO, CM_TIME, CM_ID, REF_CM_ID, FIN_YEAR                                  
  -- , ATD_CHARGES, COPIES_PTD, ROUND_OFF, MEMO_TYPE, PAY_MODE, SMS_SENT, AUTOENTRY, CASH_TENDERED                                                                      
  -- , PAYBACK, ECOUPON_ID, CAMPAIGN_GC_OTP, SALESSETUPINEFFECT, EDT_USER_CODE, GV_AMOUNT, REF_NO                                              
  -- , SENT_FOR_GR,xn_item_type,oh_tax_method ,party_state_code,TOTAL_QUANTITY ,TOTAL_GST_AMOUNT ) 
  
  SELECT 'IMPORTED SALE.' +@CMAPPING_NAME+'_'+ISNULL(REMARKS,'') AS REMARKS,0 AS SENT_FOR_RECON,1 AS PARTY_TYPE,'0000000000' AS AC_CODE                                                            
    ,0 AS MANUAL_DISCOUNT,0 AS MANUAL_ROUNDOFF,@CBINID AS BIN_ID,0 AS PATCHUP_RUN                                                                      
    ,SUM(CASE WHEN NET<0 THEN NET ELSE 0 END) AS SUBTOTAL_R,'' AS PASSPORT_NO,'' AS TICKET_NO,'' AS FLIGHT_NO,                                                                   
    0 AS MRP_WSP,0 AS MANUAL_BILL,0 AS FC_RATE                                                                      
    ,0 AS POSTEDINAC, CM_NO                                                          
    ,CM_DT,1 AS CM_MODE                                                                      
    ,SUM(CASE WHEN NET>0 THEN NET  ELSE 0 END) AS SUBTOTAL                                                                      
    ,'0000000' AS DT_CODE,0 AS DISCOUNT_PERCENTAGE,SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS DISCOUNT_AMOUNT                                                                      
    ,isnull(SUM(NET),0) AS NET_AMOUNT                                                                 
    ,@cCUSTOMER_CODE AS CUSTOMER_CODE, CANCELLED,@CUSER_CODE AS USER_CODE,GETDATE() AS LAST_UPDATE                                                                      
    ,0 AS EXEMPTED,0 AS SENT_TO_HO,GETDATE() AS CM_TIME, CM_ID,'' AS REF_CM_ID                                                        
    , FIN_YEAR,SUM(ISNULL(CMM_OTHER_CHARGES,0)) AS ATD_CHARGES,0 AS COPIES_PTD,0 AS ROUND_OFF,1 AS MEMO_TYPE,1 AS PAY_MODE,0 AS SMS_SENT                                            
    ,1 AS AUTOENTRY,0 AS CASH_TENDERED                                                                      
    ,0 AS PAYBACK,'' AS ECOUPON_ID,'' AS CAMPAIGN_GC_OTP                                             
    ,@CheckEffectiveSaleSetup AS SALESSETUPINEFFECT,@CUSER_CODE AS EDT_USER_CODE,0 AS GV_AMOUNT                                                                      
    ,BILL_NO AS REF_NO,0 AS SENT_FOR_GR  , 1 as xn_item_type         ,1 as oh_tax_method,party_state_code     ,party_gst_no  
 ,sum(QUANTITY) as Total_Quantity         
    ,sum( isnull(igst_amount,0)+isnull(Cgst_amount,0) +isnull(sgst_amount,0)  ) as TOTAL_GST_AMOUNT  ,CAST(1 AS BIT) AS EXISTINGBILLS     
  FROM #EXISTINGBILLS                                                                      
  GROUP BY CM_NO,CM_DT,CANCELLED,CM_ID,FIN_YEAR,BILL_NO ,REMARKS   ,party_state_code     ,party_gst_no                   
  UNION                                                                       
  SELECT 'IMPORTED SALE.'+@CMAPPING_NAME +'_'+ISNULL(REMARKS,'') AS REMARKS,0 AS SENT_FOR_RECON,1 AS PARTY_TYPE,'0000000000' AS AC_CODE                                                                      
    ,0 AS MANUAL_DISCOUNT,0 AS MANUAL_ROUNDOFF,@CBINID AS BIN_ID,0 AS PATCHUP_RUN                                                                     
    ,SUM(CASE WHEN NET<0 THEN NET ELSE 0 END) AS SUBTOTAL_R,'' AS PASSPORT_NO,'' AS TICKET_NO,'' AS FLIGHT_NO,0 AS MRP_WSP,0 AS MANUAL_BILL,0 AS FC_RATE                                 
    ,0 AS POSTEDINAC, CM_NO                                     
    ,CM_DT,1 AS CM_MODE                                                                      
    ,SUM(CASE WHEN NET>0 THEN NET ELSE 0 END) AS SUBTOTAL                                                                      
    ,'0000000' AS DT_CODE,0 AS DISCOUNT_PERCENTAGE,SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS DISCOUNT_AMOUNT         
    , isnull(SUM(NET),0) AS NET_AMOUNT                                                                 
    ,@cCUSTOMER_CODE AS CUSTOMER_CODE, CANCELLED,@CUSER_CODE AS USER_CODE,GETDATE() AS LAST_UPDATE                                                 
    ,0 AS EXEMPTED,0 AS SENT_TO_HO,GETDATE() AS CM_TIME, CM_ID,'' AS REF_CM_ID                                                                      
    , FIN_YEAR,SUM(ISNULL(CMM_OTHER_CHARGES,0)) AS ATD_CHARGES,0 AS COPIES_PTD,0 AS ROUND_OFF,1 AS MEMO_TYPE,1 AS PAY_MODE,0 AS SMS_SENT                                                                      
    ,1 AS AUTOENTRY,0 AS CASH_TENDERED                                      
    ,0 AS PAYBACK,'' AS ECOUPON_ID,'' AS CAMPAIGN_GC_OTP                                               
    ,@CheckEffectiveSaleSetup AS SALESSETUPINEFFECT,@CUSER_CODE AS EDT_USER_CODE,0 AS GV_AMOUNT                                                                      
    ,BILL_NO AS REF_NO,0 AS SENT_FOR_GR , 1 as xn_item_type            ,1 as oh_tax_method    ,party_state_code ,party_gst_no         
 ,sum(QUANTITY) as Total_Quantity         
    ,sum( isnull(igst_amount,0)+isnull(Cgst_amount,0) +isnull(sgst_amount,0)  ) as TOTAL_GST_AMOUNT  ,CAST(0 AS BIT) AS EXISTINGBILLS     
  FROM #NEWBILLS                                                                      
  GROUP BY CM_NO,CM_DT,CANCELLED,CM_ID,FIN_YEAR,BILL_NO ,REMARKS   ,party_state_code       ,party_gst_no                                                        
                                                                
                                                            
 SET @CSTEP=570                                                                
  /*                                                                 
  TAX_METHOD : 1 FOR INCLUSIVE AND 2 FOR EXCLUSIVE                                          
  */                                                                      
  --INSERT cmd01106 ( PRODUCT_CODE, QUANTITY, MRP, NET, BASIC_DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE,BASIC_DISCOUNT_AMOUNT, DISCOUNT_AMOUNT, ROW_ID, LAST_UPDATE                                                                      
  -- , TAX_PERCENTAGE, TAX_AMOUNT, EMP_CODE, SLSDET_ROW_ID, BIN_ID, OLD_MRP, REF_SLS_MEMO_ID                                                                      
  -- , REALIZE_SALE, CM_ID, RFNET, TAX_TYPE, TAX_METHOD, EAN, EMP_CODE1, EMP_CODE2, ITEM_DESC                                                                      
  -- , WEIGHTED_AVG_DISC_PCT, WEIGHTED_AVG_DISC_AMT, MANUAL_DISCOUNT, FIX_MRP, SR_NO, HOLD_FOR_ALTER                                                                      
  -- , PACK_SLIP_ID, XN_TYPE, REPEAT_PUR_ORDER, DEPT_ID, REF_ORDER_ID, FOC_QUANTITY, CMM_DISCOUNT_AMOUNT                                                  
  -- , NRM_ID ,HSN_CODE   ,gst_percentage ,igst_amount ,cgst_amount,sgst_amount ,NET_SALE,pack_slip_row_id,SIS_NET,sisloc_eoss_discount_percentage,sisloc_eoss_discount_amount,                                
  -- sisloc_mrp,sisloc_gst_percentage,sisloc_taxable_value,sisloc_lgst_amount,sisloc_igst_amount,xn_value_without_gst,xn_value_with_gst)                                                                   
  SELECT    A.PRODUCT_CODE, A.QUANTITY, ISNULL(A.MRP,0) AS MRP,isnull(A.NET,0) AS NET,              
  ISNULL(A.CMD_DISCOUNT_PERCENTAGE,0) AS BASIC_DISCOUNT_PERCENTAGE                                                            
  ,ISNULL(a.CMD_DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE                                                            
  ,ISNULL(a.DISCOUNT_AMT,0) AS BASIC_DISCOUNT_AMOUNT                                                            
  , ISNULL(A.DISCOUNT_AMT,0)  AS DISCOUNT_AMOUNT                                                                
    ,A.DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,GETDATE() AS LAST_UPDATE                                     
    ,0 AS TAX_PERCENTAGE,0 AS TAX_AMOUNT,'0000000' AS EMP_CODE,'' AS SLSDET_ROW_ID,                                                                      
    @CBINID AS BIN_ID,0 AS OLD_MRP,'' AS REF_SLS_MEMO_ID,0 AS REALIZE_SALE                                                                      
    ,A.CM_ID AS CM_ID,A.NET AS RFNET,1 AS TAX_TYPE,1 AS TAX_METHOD,'' AS EAN,'0000000' AS EMP_CODE1                                                                      
    ,'0000000' AS EMP_CODE2,'' AS ITEM_DESC,0 AS WEIGHTED_AVG_DISC_PCT                                                                      
    ,0 AS WEIGHTED_AVG_DISC_AMT,                                                            
 (CASE WHEN ISNULL(DISCOUNT_AMT,0)<> 0 AND ((A.MRP*A.QUANTITY)-A.NET)<>0 THEN 0 ELSE 0 END) AS MANUAL_DISCOUNT,0 AS FIX_MRP,0 AS SR_NO,0 AS HOLD_FOR_ALTER,'' AS PACK_SLIP_ID                                                                      
    ,'' AS XN_TYPE                                                                      
    ,0 AS REPEAT_PUR_ORDER,A.DEPT_ID,'' AS REF_ORDER_ID                                                                      
    ,0 AS FOC_QUANTITY,0 AS CMM_DISCOUNT_AMOUNT,'' AS NRM_ID,A.HSN_CODE   ,A.gst_percentage ,                         
 isnull(A.igst_amount,0) as igst_amount ,isnull(A.cgst_amount,0) as cgst_amount,isnull(A.sgst_amount,0) as  sgst_amount                                                                  
 ,A.NET AS NET_SALE,'' pack_slip_row_id,A.SIS_NET,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp                                                            
 ,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst ,                                                      
 ISNULL(A.xn_value_without_gst,0)+ISNULL(A.igst_amount,0) +ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0),SN.sn_barcode_coding_scheme as coding_scheme,sn.sn_uom_type as UOM_TYPE, sn.*                                                    
 ,sn.mrp AS SKU_MRP ,A.weighted_avg_disc_pct,A.weighted_avg_disc_amt   ,sn.uom as UOM_NAME,ISNULL(ART.FIX_MRP_Applicable,0) AS FIX_MRP_Applicable
 ,sn.ac_name,sn.ATTR1_KEY_NAME,sn.ATTR2_KEY_NAME,sn.ATTR3_KEY_NAME,sn.ATTR4_KEY_NAME,sn.ATTR5_KEY_NAME,sn.ATTR6_KEY_NAME,sn.ATTR7_KEY_NAME,sn.ATTR8_KEY_NAME,
sn.ATTR9_KEY_NAME,sn.ATTR10_KEY_NAME,sn.ATTR11_KEY_NAME,sn.ATTR12_KEY_NAME,sn.ATTR13_KEY_NAME,sn.ATTR14_KEY_NAME,sn.ATTR15_KEY_NAME,sn.ATTR16_KEY_NAME,sn.ATTR17_KEY_NAME,
sn.ATTR18_KEY_NAME,sn.ATTR19_KEY_NAME,sn.ATTR20_KEY_NAME,sn.ATTR21_KEY_NAME,sn.ATTR22_KEY_NAME,sn.ATTR23_KEY_NAME,sn.ATTR24_KEY_NAME,sn.ATTR25_KEY_NAME
  FROM #EXISTINGBILLS A                                                                      
  JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE   
  JOIN ARTICLE ART ON ART.article_code=B.article_code
  LEFT JOIN sku_names sn (NOLOCK) ON sn.product_code=b.product_code    
  UNION                                   
  SELECT   A.PRODUCT_CODE, A.QUANTITY, ISNULL(A.MRP,0) as MRP,isnull(A.NET,0) AS NET                                                                                 
  ,ISNULL(A.CMD_DISCOUNT_PERCENTAGE ,0) AS BASIC_DISCOUNT_PERCENTAGE,                                                            
  ISNULL(A.CMD_DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE,                                            
  ISNULL(A.DISCOUNT_AMT,0) AS BASIC_DISCOUNT_AMOUNT,                                         
  ISNULL(A.DISCOUNT_AMT,0) AS DISCOUNT_AMOUNT                                                                
    ,A.DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,GETDATE() AS LAST_UPDATE                                         
    ,0 AS TAX_PERCENTAGE,0 AS TAX_AMOUNT,'0000000' AS EMP_CODE,'' AS SLSDET_ROW_ID                                                                      
    ,@CBINID AS BIN_ID,0 AS OLD_MRP,'' AS REF_SLS_MEMO_ID,0 AS REALIZE_SALE                                                                      
    ,A.CM_ID AS CM_ID,A.NET AS RFNET,1 AS TAX_TYPE,1 AS TAX_METHOD,'' AS EAN,'0000000' AS EMP_CODE1                                                                      
   ,'0000000' AS EMP_CODE2,'' AS ITEM_DESC,0 AS WEIGHTED_AVG_DISC_PCT                                                                      
    ,0 AS WEIGHTED_AVG_DISC_AMT,(CASE WHEN ISNULL(DISCOUNT_AMT,0)<> 0 AND ((A.MRP*A.QUANTITY)-A.NET)<>0 THEN 0 ELSE 0 END) AS MANUAL_DISCOUNT,0 AS FIX_MRP,0 AS SR_NO,0 AS HOLD_FOR_ALTER,'' AS PACK_SLIP_ID                                      
    ,'' AS XN_TYPE                                                                      
    ,0 AS REPEAT_PUR_ORDER,A.DEPT_ID,'' AS REF_ORDER_ID,0 AS FOC_QUANTITY                                                 
    ,0 AS CMM_DISCOUNT_AMOUNT,'' AS NRM_ID       ,A.HSN_CODE   ,A.gst_percentage ,                                            
 isnull(A.igst_amount,0) as igst_amount ,isnull(A.cgst_amount,0) as cgst_amount,isnull(A.sgst_amount,0) as  sgst_amount                                                 
 ,A.NET AS NET_SALE,'' pack_slip_row_id,A.SIS_NET,A.sisloc_eoss_discount_percentage,A.sisloc_eoss_discount_amount,A.sisloc_mrp                                               
 ,A.sisloc_gst_percentage,A.sisloc_taxable_value,A.sisloc_lgst_amount,A.sisloc_igst_amount,A.xn_value_without_gst ,                                                      
 ISNULL(A.xn_value_without_gst,0)+ISNULL(A.igst_amount,0) +ISNULL(A.cgst_amount,0)+ISNULL(A.sgst_amount,0),SN.sn_barcode_coding_scheme as coding_scheme,sn.sn_uom_type as UOM_TYPE, sn.*
 ,sn.mrp AS SKU_MRP ,A.weighted_avg_disc_pct,A.weighted_avg_disc_amt   ,sn.uom as UOM_NAME,ISNULL(ART.FIX_MRP_Applicable,0) AS FIX_MRP_Applicable
 ,sn.ac_name,sn.ATTR1_KEY_NAME,sn.ATTR2_KEY_NAME,sn.ATTR3_KEY_NAME,sn.ATTR4_KEY_NAME,sn.ATTR5_KEY_NAME,sn.ATTR6_KEY_NAME,sn.ATTR7_KEY_NAME,sn.ATTR8_KEY_NAME,
sn.ATTR9_KEY_NAME,sn.ATTR10_KEY_NAME,sn.ATTR11_KEY_NAME,sn.ATTR12_KEY_NAME,sn.ATTR13_KEY_NAME,sn.ATTR14_KEY_NAME,sn.ATTR15_KEY_NAME,sn.ATTR16_KEY_NAME,sn.ATTR17_KEY_NAME,
sn.ATTR18_KEY_NAME,sn.ATTR19_KEY_NAME,sn.ATTR20_KEY_NAME,sn.ATTR21_KEY_NAME,sn.ATTR22_KEY_NAME,sn.ATTR23_KEY_NAME,sn.ATTR24_KEY_NAME,sn.ATTR25_KEY_NAME
  FROM #NEWBILLS A                                                                      
  JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE  
  JOIN ARTICLE ART ON ART.article_code=B.article_code
  LEFT JOIN sku_names sn (NOLOCK) ON sn.product_code=B.product_code    
                                                               
  SET @CSTEP=580                                                                      
                                                                       
 PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)         
                                                                     
                                                                       
   --INSERT paymode_xn_det (MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO,                                                                      
   -- ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)                             
   SELECT DISTINCT MEMO_ID,'SLS' AS XN_TYPE,PAYMODE_CODE,DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,AMOUNT,GETDATE() AS LAST_UPDATE,'' AS REF_NO,'' AS ADJ_MEMO_ID                                                                      
   ,1 AS CURRENCY_CONVERSION_RATE,'SALE IMPORTED' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO   ,paymode_grp_code          
   FROM
   (
   SELECT A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                                          
   ,DEPT_ID,SUM(CASH) AS AMOUNT,B.paymode_grp_code                                                                    
   FROM #EXISTINGBILLS A                                                                      
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME='INR'                                                    
   WHERE CASH<>0        AND   ISNULL(A.PAYMODE_NAME,'') =''
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE                  ,B.paymode_grp_code                                                    
   UNION                                                                       
   SELECT  A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                                      
    ,DEPT_ID,SUM(AMOUNT) AS AMOUNT,B.paymode_grp_code                                                              
   FROM #NEWBILLS A                                                                      
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME='INR'      
   WHERE CASH<>0             AND   ISNULL(A.PAYMODE_NAME,'') =''                               
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE         ,B.paymode_grp_code                               
        UNION          
                                                                        
   --INSERT paymode_xn_det( MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO                                                                      
   --, ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)                                                                        
   SELECT  A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                         
   ,DEPT_ID,SUM(CC_AMOUNT) AS AMOUNT,B.paymode_grp_code                                                                 
   FROM #EXISTINGBILLS A                                                              
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME=A.CC_NAME                                                                 
   WHERE CC_AMOUNT<>0            AND   ISNULL(A.PAYMODE_NAME,'') =''                                                                 
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE                 ,B.paymode_grp_code                             
   UNION                                                  
   SELECT  A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                                                      
    ,DEPT_ID,SUM(AMOUNT) AS AMOUNT,B.paymode_grp_code                                                                     
   FROM #NEWBILLS A                                                                      
   JOIN PAYMODE_MST B ON B.PAYMODE_NAME=A.CC_NAME                                                               
  WHERE CC_AMOUNT<>0                      AND   ISNULL(A.PAYMODE_NAME,'') =''                                                     
   GROUP BY CM_ID,DEPT_ID,B.PAYMODE_CODE             ,B.paymode_grp_code                                                         
                                                                     
     UNION                                                            
                                                       
                                                                     
   --INSERT paymode_xn_det( MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO                                                                      
   --, ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)                                                                        
   SELECT DISTINCT   A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                                                      
   ,DEPT_ID,SUM(A.NET_AMOUNT) AS AMOUNT,B.paymode_grp_code                                                           
   FROM #EXISTINGBILLS A                                                                      
   JOIN PAYMODE_MST B ON 1=1                                                                    
   --JOIN CMM01106 C ON C.CM_ID=A.CM_ID                                                                    
   --LEFT OUTER JOIN PAYMODE_XN_DET D ON D.MEMO_ID=A.CM_ID AND D.XN_TYPE='SLS'                                                                    
   WHERE B.PAYMODE_CODE='0000000'        AND   ISNULL(A.PAYMODE_NAME,'') ='' --AND  D.MEMO_ID IS NULL                                                                    
    GROUP BY A.CM_ID,DEPT_ID,B.PAYMODE_CODE       ,B.paymode_grp_code                                                             
                                                                       
   UNION                                                                  
                                                                       
   SELECT  A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                         
   ,DEPT_ID,SUM(A.NET_AMOUNT) AS AMOUNT,B.paymode_grp_code                                                            
   FROM #NEWBILLS  A                                            
   JOIN PAYMODE_MST B ON 1=1                                                          
   --JOIN CMM01106 C ON C.CM_ID=A.CM_ID                                         
   --LEFT OUTER JOIN PAYMODE_XN_DET D ON D.MEMO_ID=A.CM_ID AND D.XN_TYPE='SLS'                                                                    
   WHERE B.PAYMODE_CODE='0000000'        AND   ISNULL(A.PAYMODE_NAME,'') ='' --AND  D.MEMO_ID IS NULL                                                                    
    GROUP BY A.CM_ID,DEPT_ID,B.PAYMODE_CODE      ,B.paymode_grp_code        
	UNION
	--INSERT paymode_xn_det( MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO                                                                      
   --, ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)                                                                        
   SELECT DISTINCT   A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                                                      
   ,DEPT_ID,SUM(A.NET_AMOUNT) AS AMOUNT,B.paymode_grp_code                                                            
   FROM #EXISTINGBILLS A                                                                      
   JOIN PAYMODE_MST B ON b.paymode_name=A.paymode_name                                                                          
   --JOIN CMM01106 C ON C.CM_ID=A.CM_ID                                                                    
   --LEFT OUTER JOIN PAYMODE_XN_DET D ON D.MEMO_ID=A.CM_ID AND D.XN_TYPE='SLS'                                                                    
   WHERE ISNULL(A.PAYMODE_NAME,'') <> '' --AND  D.MEMO_ID IS NULL                                                                    
    GROUP BY A.CM_ID,DEPT_ID,B.PAYMODE_CODE,B.paymode_grp_code --,C.NET_AMOUNT                                                                    
                                                                       
   UNION                                                                  
                                                                       
   SELECT  A.CM_ID AS MEMO_ID,B.PAYMODE_CODE  AS PAYMODE_CODE                                         
   ,DEPT_ID,SUM(A.NET_AMOUNT) AS AMOUNT,B.paymode_grp_code                                                                   
   FROM #NEWBILLS  A                                            
   JOIN PAYMODE_MST B ON b.paymode_name=A.paymode_name                                                          
   --JOIN CMM01106 C ON C.CM_ID=A.CM_ID                                         
   --LEFT OUTER JOIN PAYMODE_XN_DET D ON D.MEMO_ID=A.CM_ID AND D.XN_TYPE='SLS'                                                                    
   WHERE  ISNULL(A.PAYMODE_NAME,'') <> '' --AND  D.MEMO_ID IS NULL                                                                    
    GROUP BY A.CM_ID,DEPT_ID,B.PAYMODE_CODE,B.paymode_grp_code--,A.NET_AMOUNT      
	)X                 
                                                                             
                                                        
  declare @ntotalrows numeric(10,0)                                                        
                                                                   
                                                         
                                                                   
  GOTO END_PROC                                                        
                                                        
END TRY                                                                      
                                                                       
BEGIN CATCH                                
  PRINT 'ENTER CATCH BLOCK'                      
   SET @CERRMSG='SP3S_IMPORT_SLS_DATA_MICROSOFT  : AT STEP - '+@CSTEP+', MESSAGE - '+ERROR_MESSAGE()                              
   set @CDISPLAYERRORMSG=ERROR_MESSAGE()                             
  PRINT       @CERRMSG                                                       
  GOTO END_PROC                                                                       
END CATCH                                                                      
                                                                       
END_PROC:        
                                                                       
                                                                
    --SELECT 'ROHIT'                                                                
  IF ISNULL(@CERRMSG,'')=''                                                                      
   SELECT TOP 1 @CERRMSG=ERRORMSG FROM SLS_IMPORT_DATA WHERE DEPT_ID=@CLOCID AND ISNULL(ERRORMSG,'')<>'' AND SP_ID=@CSPID                        
                                                                      
  IF ISNULL(@CERRMSG,'')='' and object_id('tempdb..#SLSIMPORT','u') is not null                                                                        
   SELECT TOP 1 @CERRMSG=ERROR_MESSAGE FROM #SLSIMPORT WHERE ISNULL(ERROR_MESSAGE,'')<>''                                                                      
                                                                      
  IF @@TRANCOUNT>0                                                                      
  BEGIN                                             
                                                            
   IF ISNULL(@CERRMSG,'')<>''                                                                        
   BEGIN                                                 
                                                           
   PRINT 'ROLLBACK TRANSACTION SLS_DATA_MICROSOFT'                                                                      
   --ROLLBACK                                                           
    UPDATE A SET IMPORT_STATUS=2,IMPORT_END_TIME=GETDATE(),                                                          
                IMPORT_ERR_MSG=@CERRMSG ,                            
    memo_no=@CMEMO_NO,                            
    memo_DT=@DCM_DT,                            
    Email=@cemail,                            
    ERR_value=case when isnull(ERR_value,'')='' then isnull(@CDISPLAYERRORMSG,@CERRMSG) else ERR_value end                         
    FROM SLS_IMPORT_STATUS A (NOLOCK)                                                          
    WHERE IMPORT_FILE_NAME=@CMAPPING_NAME                                                          
                                                           
   END                                                       
   ELSE                                                                     
   BEGIN                                
                               
    update a set IMPORT_STATUS=1,IMPORT_END_TIME=getdate(),                                                          
                IMPORT_ERR_MSG=''                                                          
    from SLS_IMPORT_STATUS a (nolock)                                        
    where IMPORT_FILE_NAME=@CMAPPING_NAME and isnull(@bfailedstatus,0)=0                                                          
                                                          
    update a set TOTAL_RECORD_IMPORTED=isnull(@ntotalrows,0)                                                      
     from SLS_IMPORT_STATUS a (nolock)                                                          
    where IMPORT_FILE_NAME=@CMAPPING_NAME                                                           
                                                          
   PRINT 'COMMIT SLS_DATA_MICROSOFT'                                                                      
   --commit                                                            
                                                           
   END                                                     
                                                                         
 END                                            
   --SELECT '' PRODUCT_CODE ,'' REF_NO  ,'' DEPT_ID  ,@CERRMSG ERRMSG                                                       
                   
 --Delete  a from SLS_IMPORT_DATA_MAPPING a with (nolock)  where SP_ID   =@CSPID                     
 --truncate table SLS_IMPORT_DATA                                                       
                                     
                                
END