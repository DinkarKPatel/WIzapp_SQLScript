CREATE PROCEDURE SPOLAP_SEND_MIRROR_PRT_DATA
(  
  @CUPLOADEDXNID VARCHAR(50)  
 ,@BACKNOWLEDGE BIT=0 
 ,@CERRMSG VARCHAR(1000) OUTPUT  
)  
--WITH ENCRYPTION  
AS  
BEGIN  
 DECLARE @CMEMOID VARCHAR(50),@CSTEP VARCHAR(5)  
BEGIN TRY   
 SET @CSTEP=00  
   SET @CERRMSG=''
PRINT 'ENTER PURCHASE RETURN SENDING'   
   
 SET @CSTEP=10     
 
   
  SET @CMEMOID=@CUPLOADEDXNID  
 ---- IF NO MEMO FOUND , JUST END THE PROCESS  
 IF ISNULL(@CMEMOID,'')=''  
  GOTO END_PROC  

  DECLARE @nInvMode NUMERIC(1,0),@cAC_Code VARCHAR(20)
  DECLARE @cCols NVARCHAR(MAX),@cnullableCols NVARCHAR(MAX), @cCmdCols NVARCHAR(MAX)
  
 IF @BACKNOWLEDGE=1  
  GOTO END_PROC  
    SET @CSTEP=50  
	  SELECT @cAC_Code=ac_code FROM rmm01106 (NOLOCK) WHERE rm_id=@CUPLOADEDXNID
	 SET @CSTEP=55  
	 ---- SEND THE PURCHASE MEMO MASTER TABLE  
	EXEC SP3S_GET_CURSOR_BASED_ON_OLAP_XNSSENDING_COLS @cXNTYPE='PRT',@cTABLENAME='RMM01106',@cKEYNAME='RM_ID',@cKEYVALUE=@CMEMOID,@bSKUNAMES=0,@CERRMSG=@CERRMSG OUTPUT 
	IF ISNULL(@CERRMSG,'')<>'' 
		GOTO END_PROC
	SET @CSTEP=65  
	---- SEND THE PURCHASE MEMO DETAIL TABLE  AND SKU_NAMES Details
	EXEC SP3S_GET_CURSOR_BASED_ON_OLAP_XNSSENDING_COLS @cXNTYPE='PRT',@cTABLENAME='RMD01106',@cKEYNAME='RM_ID',@cKEYVALUE=@CMEMOID,@bSKUNAMES=0,@bPMT=1,@CERRMSG=@CERRMSG OUTPUT 
	IF ISNULL(@CERRMSG,'')<>'' 
		GOTO END_PROC
	SET @CSTEP=75
	---- SEND THE LEDGER DETAIL TABLE 
	EXEC SPOLAP_SEND_MIRROR_XNSLM_DATA @CREQXNID=@cAC_Code,@CERRMSG=@CERRMSG OUTPUT 
	IF ISNULL(@CERRMSG,'')<>'' 
		GOTO END_PROC

END TRY  
BEGIN CATCH  
 SET @CERRMSG='P: SPOLAP_SEND_MIRROR_PRT_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()  
 GOTO END_PROC  
END CATCH   
   
END_PROC:  
  
END   
---END OF PROCEDURE - SP_SEND_MIRROR_PUR_DATA_NEW  

