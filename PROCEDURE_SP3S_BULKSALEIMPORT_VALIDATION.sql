CREATE PROCEDURE SP3S_BULKSALEIMPORT_VALIDATION--(LocId 3 digit change by Sanjay:04-11-2024)
(                
 @cSPID   VARCHAR(20),                
 @iDateMode  INT  ,
 @CLOCID VARCHAR(10),                                                                  
 @NMODE INT=0      ,                                                            
 @CUSER_CODE CHAR(7)= '0000000',                                                        
 @CBINID VARCHAR(10)='000',                                                      
 @CMAPPING_NAME VARCHAR(1000)=''   ,        
 @cstoregroup varchar(100)=''      
)                
AS                
BEGIN                
                 
 DECLARE @cCOLUMN_NAME VARCHAR(100),@bMAPPED  BIT,@cCMD NVARCHAR(MAX),@cErrMsg NVARCHAR(MAX)                
 DECLARE @DtError TABLE(PRODUCT_CODE VARCHAR(100), ERR_MSG VARCHAR(MAX))                
 BEGIN TRY                 
                
                 
 SELECT COLUMN_NAME,CAST(0 AS BIT) AS MAPPED                 
 INTO #SP3S_PUMA_IMPORT_VALIDATE_EXCEL_SLS_NUMERICCOLS                
 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='SLS_IMPORT_DATA' AND DATA_TYPE='NUMERIC'                
                
 UPDATE A SET A.MAPPED=1                
 FROM #SP3S_PUMA_IMPORT_VALIDATE_EXCEL_SLS_NUMERICCOLS A                
 JOIN SLS_IMPORT_DATA_MAPPING   B ON B.MASTER_COL_EXPR=A.COLUMN_NAME                
 WHERE B.SP_ID=@cSPID AND ISNULL(MAPPED_COL,'')<>''                
                
 IF EXISTS(SELECT TOP 1 'U' FROM SLS_IMPORT_DATA_VALIDATE_2   WHERE SP_ID=@cSPID)                
 BEGIN                
  UPDATE A SET A.PRODUCT_CODE=B.PRODUCT_CODE                
  FROM SLS_IMPORT_DATA_VALIDATE_1 A                
  JOIN SLS_IMPORT_DATA_VALIDATE_2 B ON B.SSPL_IMPORT_SRNO=A.SSPL_IMPORT_SRNO AND A.SP_ID=B.SP_ID                
  WHERE A.SP_ID=@cSPID                
 END
 
 DELETE A 
 FROM SLS_IMPORT_DATA_VALIDATE_2 A
 LEFT OUTER JOIN SLS_IMPORT_DATA_VALIDATE_1 B ON B.SSPL_IMPORT_SRNO=A.SSPL_IMPORT_SRNO
 WHERE B.SSPL_IMPORT_SRNO IS NULL

 --  UPDATE  SLS_IMPORT_DATA_VALIDATE_1  SET PRODUCT_CODE=LEFT(PRODUCT_CODE,13) WHERE SP_ID=@cSPID AND LEN(ISNULL(PRODUCT_CODE,''))>13              
DELETE FROM SLS_IMPORT_DATA_VALIDATE_1  WHERE SP_ID=@cSPID AND ISNULL(PRODUCT_CODE,'')='' --OR ISNUMERIC(PRODUCT_CODE)=0                
DELETE A 
FROM SLS_IMPORT_DATA_VALIDATE_1 A (NOLOCK)                
LEFT OUTER JOIN SKU B (NOLOCK) ON B.PRODUCT_CODE=A.PRODUCT_CODE                
WHERE SP_ID=@cSPID AND B.PRODUCT_CODE IS NULL

DECLARE @cSTR NVARCHAR(MAX)
SELECT @cSTR=COALESCE(@cstr + ', ', 'Product Code of ') + A.memo_no          
FROM SLS_IMPORT_DATA_VALIDATE_2 A (NOLOCK)
LEFT OUTER JOIN SLS_IMPORT_DATA_VALIDATE_1 B (NOLOCK) ON B.SSPL_IMPORT_SRNO=A.SSPL_IMPORT_SRNO
WHERE A.SP_ID=@cSPID AND B.SSPL_IMPORT_SRNO IS NULL  
 
 INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)      
 SELECT '', COALESCE(@cstr + ' Not Found ', '')     
 
 SET @cstr=null

 SELECT @cSTR=COALESCE(@cstr + ', ', 'Payment Mode Name ') + A.PAYMODE_NAME          
FROM SLS_IMPORT_DATA_VALIDATE_2 A (NOLOCK)
LEFT OUTER JOIN paymode_mst B (NOLOCK) ON B.paymode_name=ISNULL(A.PAYMODE_NAME,'')
WHERE ISNULL(A.PAYMODE_NAME,'')<>'' AND A.SP_ID=@cSPID AND B.paymode_code IS NULL  
 
 INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)      
 SELECT '', COALESCE(@cstr + ' Not Found ', '')    

 --INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)                
 --SELECT A.PRODUCT_CODE, A.PRODUCT_CODE +' Not Found' AS ERR_MSG                
 --FROM SLS_IMPORT_DATA_VALIDATE_1 A (NOLOCK)                
 --LEFT OUTER JOIN SKU B (NOLOCK) ON B.PRODUCT_CODE=A.PRODUCT_CODE                
 --WHERE SP_ID=@cSPID AND B.PRODUCT_CODE IS NULL                
                
 DECLARE ABC CURSOR                 
 FOR                 
 SELECT COLUMN_NAME,MAPPED                
 FROM #SP3S_PUMA_IMPORT_VALIDATE_EXCEL_SLS_NUMERICCOLS                
 WHERE MAPPED=1                
 OPEN ABC                
 FETCH NEXT FROM ABC INTO @cCOLUMN_NAME,@bMAPPED                
 WHILE @@FETCH_STATUS=0                
 BEGIN                
  IF EXISTS(SELECT TOP 1 * FROM SLS_IMPORT_DATA_MAPPING   WHERE SP_ID=@cSPID AND MASTER_COL_EXPR=@cCOLUMN_NAME AND ISNULL(MAPPED_COL,'')<>'')                
  BEGIN                
  SET @cCMD=N'UPDATE SLS_IMPORT_DATA_VALIDATE_1  SET '+@cCOLUMN_NAME+'=0  WHERE SP_ID='''+@cSPID +'''  AND ISNULL('+@cCOLUMN_NAME+','''')='''''              
  PRINT @cCMD                
   EXEC SP_EXECUTESQL @cCMD                
   SET @cCMD=N'UPDATE SLS_IMPORT_DATA_VALIDATE_1  SET '+@cCOLUMN_NAME+'=REPLACE('+@cCOLUMN_NAME+','','','''')  WHERE SP_ID='''+@cSPID +'''  AND ISNULL('+@cCOLUMN_NAME+','''') LIKE ''%,%'''              
  PRINT @cCMD                
   EXEC SP_EXECUTESQL @cCMD               
   SET @cCMD=N'UPDATE SLS_IMPORT_DATA_VALIDATE_1  SET '+@cCOLUMN_NAME+'=REPLACE('+@cCOLUMN_NAME+',''('','''')   WHERE SP_ID='''+@cSPID +'''  AND ISNULL('+@cCOLUMN_NAME+','''') LIKE ''%(%'''              
  PRINT @cCMD                
   EXEC SP_EXECUTESQL @cCMD             
   SET @cCMD=N'UPDATE SLS_IMPORT_DATA_VALIDATE_1  SET '+@cCOLUMN_NAME+'=REPLACE('+@cCOLUMN_NAME+','')'','''')   WHERE SP_ID='''+@cSPID +'''  AND ISNULL('+@cCOLUMN_NAME+','''') LIKE ''%)%'''              
  PRINT @cCMD                
   EXEC SP_EXECUTESQL @cCMD             
  
   SET @cCMD=N'UPDATE SLS_IMPORT_DATA_VALIDATE_1  SET '+@cCOLUMN_NAME+'=REPLACE('+@cCOLUMN_NAME+','')'','''')   WHERE SP_ID='''+@cSPID +'''  AND ISNULL('+@cCOLUMN_NAME+','''') LIKE ''%)%'''              
  PRINT @cCMD                
   EXEC SP_EXECUTESQL @cCMD   
  
   SET @cCMD=N'SELECT PRODUCT_CODE,'''+@cCOLUMN_NAME+' SHOULD BE NUMERIC'' AS ERR_MST   FROM SLS_IMPORT_DATA_VALIDATE_1  WHERE SP_ID='''+@cSPID +'''  AND ISNULL('+@cCOLUMN_NAME+','''')<>'''' AND ISNUMERIC('+@cCOLUMN_NAME+')=0'                
   PRINT @cCMD                
   INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)                
   EXEC SP_EXECUTESQL @cCMD                
  END                
  FETCH NEXT FROM ABC INTO @cCOLUMN_NAME,@bMAPPED                
 END     
 CLOSE ABC                
 DEALLOCATE ABC 
 
 --SELECT 'ROHIT'
 if EXISTS(SELECT TOP 1 'U' FROM SLS_IMPORT_DATA_VALIDATE_1 WHERE  sp_id=@CSPID AND ISNUMERIC(memo_dt)=1)            
 BEGIN            
 UPDATE SLS_IMPORT_DATA_VALIDATE_1 SET MEMO_DT= CAST(CAST(MEMO_DT AS NUMERIC(20)) AS DATETIME)-2 WHERE  sp_id=@CSPID AND ISNUMERIC(memo_dt)=1            
 END                    
 else if(@iDateMode IN (1,6))                
 BEGIN                
  update SLS_IMPORT_DATA_VALIDATE_1 SET memo_dt=CONVERT(DATETIME,memo_dt,105)  where sp_id=@CSPID                 
 END                
 else if(@iDateMode=5)                
 BEGIN             
  update SLS_IMPORT_DATA_VALIDATE_1 SET memo_dt=CONVERT(DATETIME,memo_dt,110)  where sp_id=@CSPID                  
 END                
  
 
 SET @cstr=null

 SELECT @cSTR=COALESCE(@cstr + ', ', 'GST No ') + A.CUS_GST_NO          
FROM SLS_IMPORT_DATA_VALIDATE_2 A (NOLOCK)
LEFT OUTER JOIN gst_state_mst GST (NOLOCK) ON GST.gst_state_code=LEFT(A.cus_gst_no,2)
WHERE  ISNULL( A.cus_gst_no,'')<>'' AND GST.gst_state_code IS NULL
 
 INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)      
 SELECT '', COALESCE(@cstr + ' Invalid ', '')    


  SET @cstr=null

 SELECT @cSTR=COALESCE(@cstr + ', ', 'GST State ') + A.cus_gst_state         
FROM SLS_IMPORT_DATA_VALIDATE_2 A (NOLOCK)
LEFT OUTER JOIN gst_state_mst GST (NOLOCK) ON GST.gst_state_code=A.cus_gst_state
WHERE  ISNULL( A.cus_gst_state,'')<>'' AND GST.gst_state_code IS NULL
 
 INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)      
 SELECT '', COALESCE(@cstr + ' Not Found ', '')    

 END TRY                
 BEGIN CATCH                 
  INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)                 
  SELECT 'Try Catch',ERROR_MESSAGE()                
 END CATCH           
 --select * FROM @dtError 
 SELECT @cErrMsg=ISNULL (@cErrMsg,'')+' ' + ISNULL(PRODUCT_CODE,'') +':'+ ISNULL(ERR_MSG,'') FROM @dtError where  ISNULL(ERR_MSG,'')<>''               
 --IF ISNULL(@cErrMsg,'')=''                
 --BEGIN              
 --BEGIN TRY          
 ---- DELETE from SLS_IMPORT_DATA_VALIDATE_1 where sp_id=@CSPID AND ISNULL(product_code,'')<>'' AND CAST(QUANTITY AS NUMERIC(14,2))=0 AND CAST(NET AS NUMERIC(14,2))=0          
          
 --DELETE FROM SLS_IMPORT_DATA   where sp_id=@CSPID                 
                
  INSERT SLS_IMPORT_DATA (weighted_avg_disc_pct,weighted_avg_disc_amt, address0, address1, address2, ADDRESS9, area, BIN_ID, cancelled, cgst_amount, city, CMD_DISCOUNT_AMOUNT, CMD_DISCOUNT_PERCENTAGE, CMM_DISCOUNT_AMOUNT, CMM_OTHER_CHARGES,                 
  CUS_GST_NO, cus_gst_state, CUSTOMER_FNAME, CUSTOMER_LNAME, customer_name, dept_id, EMAIL, EMP_NAME, errormsg, GST_CESS_AMOUNT, GST_CESS_PERCENTAGE, gst_percentage, hsn_code, igst_amount, memo_dt,                 
  memo_no, MRP, MrpValue, net, net_amount, PAYMODE_NAME, processed, product_code, quantity, REMARKS, row_id, sgst_amount, SP_ID, state, STORE_CODE, USER_CUSTOMER_CODE, XN_VALUE_WITH_GST, xn_value_without_gst )                  
  SELECT  CMD_DISCOUNT_PERCENTAGE as weighted_avg_disc_pct,CMD_DISCOUNT_AMOUNT as weighted_avg_disc_amt,  address0, address1, address2, ADDRESS9, area, BIN_ID, cancelled, cgst_amount, city, CMD_DISCOUNT_AMOUNT, CMD_DISCOUNT_PERCENTAGE, CMM_DISCOUNT_AMOUNT, CMM_OTHER_CHARGES,                 
  CUS_GST_NO, cus_gst_state, CUSTOMER_FNAME, CUSTOMER_LNAME, customer_name, dept_id, EMAIL, EMP_NAME, errormsg, GST_CESS_AMOUNT, GST_CESS_PERCENTAGE, gst_percentage, hsn_code, igst_amount, memo_dt,                 
  memo_no, MRP, MrpValue, net, net_amount, PAYMODE_NAME, processed, product_code, quantity, REMARKS, row_id, sgst_amount, SP_ID, state, STORE_CODE, USER_CUSTOMER_CODE, XN_VALUE_WITH_GST, xn_value_without_gst                 
  FROM SLS_IMPORT_DATA_VALIDATE_1 (NOLOCK)   where sp_id=@CSPID                  
 --SELECT * FROM SLS_IMPORT_DATA WHERE SP_ID=@CSPID               
 -- ----DELETE from SLS_IMPORT_DATA_VALIDATE_1 where sp_id=@CSPID                
 -- ----DELETE from SLS_IMPORT_DATA_VALIDATE_2 where sp_id=@CSPID     
    
 -- ----update SLS_IMPORT_DATA SET net=ABS(NET)*-1 WHERE quantity<0 AND net>0  
 -- ----update SLS_IMPORT_DATA SET net=ABS(NET) WHERE quantity>0 AND net<0  
  
 -- ----update SLS_IMPORT_DATA SET net_amount=ABS(net_amount)*-1 WHERE quantity<0 AND net_amount>0  
 -- ----update SLS_IMPORT_DATA SET net_amount=ABS(net_amount) WHERE quantity>0 AND net_amount<0  
  
 -- ----update SLS_IMPORT_DATA SET CMD_DISCOUNT_AMOUNT=ABS(CMD_DISCOUNT_AMOUNT)*-1 WHERE quantity<0 AND CMD_DISCOUNT_AMOUNT>0  
 -- ----update SLS_IMPORT_DATA SET CMD_DISCOUNT_AMOUNT=ABS(CMD_DISCOUNT_AMOUNT) WHERE quantity>0 AND CMD_DISCOUNT_AMOUNT<0  
  
 -- update SLS_IMPORT_DATA SET net=ABS(NET)*-1 ,net_amount=ABS(net_amount)*-1,CMD_DISCOUNT_AMOUNT=ABS(CMD_DISCOUNT_AMOUNT)*-1,sgst_amount=ABS(sgst_amount)*-1,cgst_amount=ABS(cgst_amount)*-1,igst_amount=ABS(igst_amount)*-1 ,  
 -- XN_VALUE_WITH_GST=ABS(XN_VALUE_WITH_GST)*-1,xn_value_without_gst=ABS(xn_value_without_gst)*-1   
 -- WHERE quantity<0 --AND sgst_amount>0  
 -- update SLS_IMPORT_DATA SET net=ABS(NET) ,net_amount=ABS(net_amount),CMD_DISCOUNT_AMOUNT=ABS(CMD_DISCOUNT_AMOUNT),sgst_amount=ABS(sgst_amount),cgst_amount=ABS(cgst_amount),igst_amount=ABS(igst_amount),  
 -- XN_VALUE_WITH_GST=ABS(XN_VALUE_WITH_GST),xn_value_without_gst=ABS(xn_value_without_gst)  
 -- WHERE quantity>0 --AND sgst_amount<0  
  
 -- END TRY                
 --BEGIN CATCH                 
 -- INSERT INTO @DtError(PRODUCT_CODE,ERR_MSG)                 
 -- SELECT 'Try Catch (SP3S_PUMA_IMPORT_VALIDATE_EXCEL_SLS) : ',ERROR_MESSAGE()                
 --END CATCH                
 --SELECT @cErrMsg=ISNULL (@cErrMsg,'')+' ' + ISNULL(PRODUCT_CODE,'') +':'+ ISNULL(ERR_MSG,'') FROM @dtError                
 --END                
                
--DELETE from SLS_IMPORT_DATA_VALIDATE_1 where sp_id=@CSPID                
--DELETE from SLS_IMPORT_DATA_VALIDATE_2 where sp_id=@CSPID         
IF ISNULL(@cErrMsg,'')<>''      
 SELECT ISNULL(@cErrMsg,'') AS ERR_MSG         
ELSE  IF EXISTS(SELECT top 1  SP_ID FROM SLS_IMPORT_DATA   where sp_id=@CSPID    )      
 SELECT ISNULL(@cErrMsg,'') AS ERR_MSG         
ELSE  
BEGIN
SELECT @cErrMsg='Given Data not valid. Failed by SP3S_PUMA_IMPORT_VALIDATE_EXCEL_SLS'
SELECT ISNULL(@cErrMsg,'') AS ERR_MSG
END

 --SELECT    address0, address1, address2, ADDRESS9, area, BIN_ID, cancelled, cgst_amount, city, CMD_DISCOUNT_AMOUNT, CMD_DISCOUNT_PERCENTAGE, CMM_DISCOUNT_AMOUNT, CMM_OTHER_CHARGES,                 
 -- CUS_GST_NO, cus_gst_state, CUSTOMER_FNAME, CUSTOMER_LNAME, customer_name, dept_id, EMAIL, EMP_NAME, errormsg, GST_CESS_AMOUNT, GST_CESS_PERCENTAGE, gst_percentage, hsn_code, igst_amount, memo_dt,                 
 -- memo_no, MRP, MrpValue, net, net_amount, PAYMODE_NAME, processed, product_code, quantity, REMARKS, row_id, sgst_amount, SP_ID, state, STORE_CODE, USER_CUSTOMER_CODE, XN_VALUE_WITH_GST, xn_value_without_gst                 
 -- FROM SLS_IMPORT_DATA_VALIDATE_1 (NOLOCK)   where sp_id=@CSPID  AND ISNULL(@cErrMsg,'')=''   
 if ISNULL(@cErrMsg,'')=''
 BEGIN
	 EXEC  SP3S_BULKSALEIMPORT--SP3S_IMPORT_SLS_DATA_MICROSOFT                                                      
	 @iDateMode  =@iDateMode,                                                        
	 @CLOCID =@CLOCID,                                                                  
	 @NMODE =@NMODE      ,                                                            
	 @CSPID =@cSPID ,                                                        
	 @CUSER_CODE = @CUSER_CODE,                                                        
	 @CBINID =@CBINID,                                                      
	 @CMAPPING_NAME =@CMAPPING_NAME,        
	 @cstoregroup =@cstoregroup        
 END
 ELSE
 BEGIN
	UPDATE A SET IMPORT_STATUS=2,IMPORT_END_TIME=GETDATE(),                                                      
                IMPORT_ERR_MSG=@CERRMSG
				
    FROM SLS_IMPORT_STATUS A (NOLOCK)                                                      
    WHERE IMPORT_FILE_NAME=@CMAPPING_NAME  
 END

END 