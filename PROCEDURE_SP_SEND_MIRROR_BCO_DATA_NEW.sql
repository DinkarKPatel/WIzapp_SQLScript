CREATE PROCEDURE SP_SEND_MIRROR_BCO_DATA_NEW  
(   
  @CUPLOADEDXNID VARCHAR(50)  
 ,@CCURLOCID VARCHAR(5)   
  ,@BACKNOWLEDGE BIT =0   
 ,@CERRMSG VARCHAR(1000) OUTPUT  
)   
--WITH ENCRYPTION  
AS  
/*  
 SP_SEND_MIRROR_BCO_DATA_NEW_208_05_02_14 : THIS PROCEDURE WILL SEND APPROVAL RETURN DATA FROM LOCATION TO HO.  
*/  
BEGIN  
 DECLARE @DTSQL NVARCHAR(MAX),@CSPID VARCHAR(10),@CTEMPTABLE VARCHAR(500),@CMEMOID VARCHAR(50),  
 @CTEMPMASTERTABLE VARCHAR(200),@CTEMPLMTABLE VARCHAR(200),@CTEMPLMPTABLE VARCHAR(200)  
 ,@CTEMPAREATABLE VARCHAR(200),@CTEMPCITYTABLE VARCHAR(200),@CTEMPCUSTABLE VARCHAR(200),@CTEMPEMPTABLE VARCHAR(200)  
 ,@CTEMPPAYTABLE VARCHAR(200),@CTEMPPMSTTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200)  
 ,@DMEMOLASTUPDATE DATETIME,@CTABLENAME VARCHAR(100),@BRECFOUND BIT,@CSTEP VARCHAR(5),@CFILTERCONDITION VARCHAR(MAX)  
 ,@CKEYFIELD VARCHAR(100)  
  
BEGIN TRY    
 ---- CALL ACKNOWLEDGEMENT OF MEMO SUCCESSFUL MERGING AT MIRRORING SERVER  
   
   
 SET @CSTEP=5  
   
 DECLARE @CTEMPDBNAME VARCHAR(40)  
 SET @CTEMPDBNAME=''
   
 SET @CSTEP=10  
    
 --CHANGE BY BAIJNATH--  
 SET @CMEMOID=@CUPLOADEDXNID  
   
 SET @CSTEP=40  
 ---- IF NO MEMO FOUND , JUST END THE PROCESS  
 IF ISNULL(@CMEMOID,'')=''  
  GOTO END_PROC  
LBLTABLEINFO:  
 SET @CSTEP=50  
 ---- POPULATE LIST OF TABLES   

 SET @CSTEP=110  
    
	SELECT DISTINCT A. *,'BCO_FLOOR_ST_MST_UPLOAD' AS TARGET_TABLENAME FROM FLOOR_ST_MST A (NOLOCK) WHERE A.MEMO_ID =@CMEMOID
   
 SET @CSTEP=120  
 ---- SEND THE BCO MEMO DETAIL TABLE  
 
	SELECT DISTINCT A. *,'BCO_FLOOR_ST_DET_UPLOAD' AS TARGET_TABLENAME FROM FLOOR_ST_DET A (NOLOCK) WHERE A.MEMO_ID =@CMEMOID
    
   
 SET @CSTEP=130  
 ---- SEND THE LEDGERS RELATED TO BCO TABLE  
 
	SELECT DISTINCT A. *,'BCO_SKU_UPLOAD' AS TARGET_TABLENAME, @CMEMOID AS BCO_MEMO_ID FROM SKU A (NOLOCK)
	JOIN FLOOR_ST_DET B (NOLOCK) ON A.product_code=B.PRODUCT_CODE
	WHERE B.MEMO_ID=@CMEMOID
 
  SET @CSTEP=131  
 ---- SEND THE PMT01106 TABLE  
   SELECT DISTINCT 'BCO_PMT01106_UPLOAD' AS TARGET_TABLENAME, @CMEMOID AS BCO_MEMO_ID ,A.DEPT_ID,A.product_code,A.BIN_ID,A.quantity_in_stock  
	  FROM PMT01106 A (NOLOCK)  
	  JOIN FLOOR_ST_DET B (NOLOCK) ON B.product_code=A.product_code
	  WHERE B.MEMO_ID=@CMEMOID 

 GOTO END_PROC  
    
  
END TRY  
BEGIN CATCH  
 SET @CERRMSG='P: SP_SEND_MIRROR_BCO_DATA_NEW, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()  
 GOTO END_PROC  
END CATCH     
  
END_PROC:  
 
END  
---END OF PROCEDURE - SP_SEND_MIRROR_BCO_DATA_NEW  