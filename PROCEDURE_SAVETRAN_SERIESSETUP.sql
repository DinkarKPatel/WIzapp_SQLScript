CREATE PROC SAVETRAN_SERIESSETUP
(
  @NUPDATEMODE NUMERIC(1,0),	
  @CDEPTID VARCHAR(5),
  @CFINYEAR VARCHAR(5),	
  @NSPID INT
)
AS
BEGIN
   SET NOCOUNT ON
   DECLARE @CSTEP VARCHAR(5),@CCMD NVARCHAR(MAX),@BPREFIXAPPLICABLE BIT,@BPREFIXUSERALIAS BIT,
		   @BPREFIXDESTLOCID BIT,@BPREFIXFINYEAR BIT,@CIGSTXNPREFIX VARCHAR(25),@CERRORMSG VARCHAR(MAX),
		   @CCGSTXNPREFIX VARCHAR(25),@CDELIVERYCHALLANPREFIX VARCHAR(25),@CUSERALIAS VARCHAR(2),
		   @CFINALPREFIX VARCHAR(50),@CWHERECLAUSE VARCHAR(200),@CXNTYPE VARCHAR(10),@CKEYSTABLE VARCHAR(500),
		   @CTABLENAME VARCHAR(300),@CMEMOPREFIX VARCHAR(25),@CLASTKEYVAL VARCHAR(6),@CCOLUMNNAME VARCHAR(100),
		   @NSTARTFROM NUMERIC(6,0),@CSTARTFROM VARCHAR(10)
   
BEGIN TRY

     BEGIN TRANSACTION
	 DECLARE @CNEWID VARCHAR(40)
	 IF @NUPDATEMODE=1
	 BEGIN
		SET @CSTEP='10'
		
			
		SELECT @CNEWID=CONVERT(VARCHAR(38),NEWID())
		
		IF EXISTS (SELECT TOP 1 A.XN_TYPE FROM SERIES_SETUP_MST A 
				   JOIN SERIES_SETUP_MST_UPLOAD B ON A.XN_TYPE=B.XN_TYPE AND A.DEPT_ID=B.DEPT_ID 
				   AND  A.XN_ITEM_TYPE=B.XN_ITEM_TYPE
				   WHERE B.SP_ID=@NSPID)
		BEGIN
			SET @CERRORMSG='DUPLICATE ENTRY OF SERIES MASTER NOT ALLOWED'
			GOTO END_PROC
		END		   	
		
		SET @CSTEP='20'
		UPDATE SERIES_SETUP_MST_UPLOAD SET MEMO_ID=@CNEWID WHERE SP_ID=@NSPID
		
		UPDATE SERIES_SETUP_MANUAL_DET_UPLOAD SET MEMO_ID=@CNEWID WHERE SP_ID=@NSPID
	 END 	
	 ELSE
	 BEGIN
		SELECT @CNEWID =MEMO_ID FROM SERIES_SETUP_MST_UPLOAD WHERE SP_ID=@NSPID
	 END
	 SET @CSTEP='30'
	 UPDATE SERIES_SETUP_MANUAL_DET_UPLOAD SET ROW_ID=CONVERT(VARCHAR(38),NEWID())
	 WHERE SP_ID=@NSPID and left(row_id,5)='later'
	  
	 SET @CSTEP='35'
	 SET @CWHERECLAUSE = ' SP_ID='+LTRIM(RTRIM(STR(@NSPID)))
	 
	 SET @CSTEP='40'
	 EXEC UPDATEMASTERXN
      @CSOURCEDB = ''
    , @CSOURCETABLE = 'SERIES_SETUP_MST_UPLOAD'
    , @CDESTDB  = ''  
    , @CDESTTABLE = 'SERIES_SETUP_MST'
    , @CKEYFIELD1 = 'MEMO_ID'
    , @CKEYFIELD2 = ''
    , @CKEYFIELD3 = ''
    , @BALWAYSUPDATE = 1  
    ,@CFILTERCONDITION=@CWHERECLAUSE

	 SET @CSTEP='45'
	 EXEC UPDATEMASTERXN
      @CSOURCEDB = ''
    , @CSOURCETABLE = 'SERIES_SETUP_MANUAL_DET_UPLOAD'
    , @CDESTDB  = ''  
    , @CDESTTABLE = 'SERIES_SETUP_MANUAL_DET'
    , @CKEYFIELD1 = 'ROW_ID'
    , @LINSERTONLY = 0  
    ,@CFILTERCONDITION=@CWHERECLAUSE
	,@BALWAYSUPDATE=1
	
	
	
      
END TRY
   
   BEGIN CATCH
	  SET @CERRORMSG = 'ERROR IN PROCEDURE SAVETRAN_SERIESSETUP AT STEP#' + @CSTEP + ' '  + ERROR_MESSAGE()
	  GOTO END_PROC
   END CATCH
   
END_PROC:
   IF @@TRANCOUNT>0
	  BEGIN
		IF ISNULL(@CERRORMSG,'')=''
		    COMMIT TRANSACTION
		ELSE
			ROLLBACK 	
	  END 
   
   --IF ISNULL(@CERRORMSG,'')=''
   --BEGIN
   --     DELETE FROM SERIES_SETUP_MST_UPLOAD WHERE SP_ID=@NSPID
   --     DELETE FROM SERIES_SETUP_MANUAL_DET_UPLOAD WHERE SP_ID=@NSPID
   --END		

   SELECT ISNULL(@CERRORMSG,'') AS ERRMSG,ISNULL(@CNEWID,'') as MEMO_ID
END
--END OF PROCEDURE SAVETRAN_SERIESSETUP
