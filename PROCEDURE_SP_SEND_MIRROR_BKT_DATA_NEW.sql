CREATE PROCEDURE SP_SEND_MIRROR_BKT_DATA_NEW
(	
	 @CUPLOADEDXNID VARCHAR(50)
	,@CCURLOCID VARCHAR(5)
	,@BACKNOWLEDGE BIT=0
	,@CERRMSG VARCHAR(1000) OUTPUT
)	
--WITH ENCRYPTION
AS
/*
	SP_SEND_MIRROR_BKT_DATA_NEW_208_05_02_14 : THIS PROCEDURE WILL SEND APPROVAL RETURN DATA FROM LOCATION TO HO.
*/
BEGIN
	DECLARE @DTSQL NVARCHAR(MAX),@CSPID VARCHAR(10),@CTEMPTABLE VARCHAR(500),@CMEMOID VARCHAR(50),
	@CTEMPMASTERTABLE VARCHAR(200),@CTEMPLMTABLE VARCHAR(200),@CTEMPLMPTABLE VARCHAR(200)
	,@CTEMPAREATABLE VARCHAR(200),@CTEMPCITYTABLE VARCHAR(200),@CTEMPCUSTABLE VARCHAR(200),@CTEMPEMPTABLE VARCHAR(200)
	,@CTEMPPAYTABLE VARCHAR(200),@CTEMPPMSTTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200)
	,@DMEMOLASTUPDATE DATETIME,@CTABLENAME VARCHAR(100),@BRECFOUND BIT,@CSTEP VARCHAR(5),@CFILTERCONDITION VARCHAR(MAX)
	,@CKEYFIELD VARCHAR(100),@CTEMPSHIFT_DET_TABLE VARCHAR(200)

BEGIN TRY 
	
	---- CALL ACKNOWLEDGEMENT OF MEMO SUCCESSFUL MERGING AT MIRRORING SERVER
	DECLARE @CTEMPDBNAME VARCHAR(40)
	
	SET @CTEMPDBNAME=''
	SET @CSTEP=30
	--CHNAGE BY BAIJNATH
	SET @CMEMOID=@CUPLOADEDXNID
	---- IF NO MEMO FOUND , JUST END THE PROCESS
	IF ISNULL(@CMEMOID,'')=''
		GOTO END_PROC
		
LBLTABLEINFO:
	SET @CSTEP=50
	---- POPULATE LIST OF TABLES 

	
	SET @CSTEP=110
	---- SEND THE BKT MEMO MASTER TABLE
	SELECT TILL_BANK_TRANSFER.*,'BKT_TILL_BANK_TRANSFER_UPLOAD' AS TARGET_TABLENAME FROM TILL_BANK_TRANSFER WHERE MEMO_ID=@CMEMOID


	GOTO END_PROC

END TRY
BEGIN CATCH
	SET @CERRMSG='P: SP_SEND_MIRROR_BKT_DATA_NEW, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC: 		

END
---END OF PROCEDURE - SP_SEND_MIRROR_BKT_DATA_NEW
