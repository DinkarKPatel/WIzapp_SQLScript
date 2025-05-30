CREATE PROCEDURE SP3S_LOGPROCESSTIME
(
	 @CXNTYPE VARCHAR(20)
	,@CPROCESSNAME VARCHAR(100)
	,@CXNID VARCHAR(50)
	,@NSPID varchar(40)
	,@BSTART BIT=0
	,@DDATETIME DATETIME=''
	,@NUPDATEMODE INT=0
)
--WITH ENCRYPTION
AS	
BEGIN
	RETURN
	SET @CPROCESSNAME=@CPROCESSNAME+'('+LTRIM(RTRIM(STR(@NUPDATEMODE)))+')'
	
	INSERT PROCESSLOG(XN_TYPE,PROCESS,XNID,STARTDT,ENDDT,SPID)			
	SELECT @CXNTYPE,@CPROCESSNAME,@CXNID,@DDATETIME,GETDATE(),@NSPID
END
---END OF PROCEDURE - SP3S_LOGPROCESSTIME
