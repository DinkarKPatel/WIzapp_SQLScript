CREATE PROCEDURE SP_MERGE_MIRROR_BKT_DATA
(
	@CMEMOID VARCHAR(50)
   ,@CLOCID VARCHAR(3)
   ,@CSOURCEDB VARCHAR(300)
   ,@CMERGEDB VARCHAR(300)
   ,@BMSTINSERTONLY BIT
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS
SET NOCOUNT ON
BEGIN
	/*
		SP_MERGE_MIRROR_BKT_DATA_208_2014_02_05 : 
		THIS PROCEDURE WILL MERGE DATA FROM TEMPORARY TABLE TO ACTUAL TABLE.
		TABLE NAMES AND ITS MERGING ORDER WILL BE FIXED AND WILL BE DEFINED HERE.	
	*/
DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(1000),@CCURDEPTID VARCHAR(10),@CMIRRORINGENABLED VARCHAR(2)
	   ,@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200)
	   		    
DECLARE @TXNSSENDINFO TABLE (ORG_TABLENAME VARCHAR(50),TMP_TABLENAME VARCHAR(50),XN_ID VARCHAR(40))  	

BEGIN TRY
SET @CSTEP=00

	SET @CTABLE_SUFFIX=REPLACE(@CMEMOID,'-','_')
BEGIN TRANSACTION 

	 ---UPDATE POSTEDINAC MARK FOR THE BILLS POSTEDINTO ACCOUNTS & THERE IS SOME MISMATCH BETWEEN INCOMING DATA & EXISTING DATA
	SET @CSTEP=10
    
    SELECT TOP 1 @CCURDEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'

	SELECT TOP 1 @CMIRRORINGENABLED=VALUE FROM CONFIG WHERE CONFIG_OPTION='MIRRORING_ENABLED'
	
	IF ISNULL(@CMIRRORINGENABLED,'')='1'
		GOTO LBLMERGE
    
    SET @CSTEP=15
    DECLARE @CPOSTINGATHODEPTID VARCHAR(5)
    
	SET @DTSQL=N'SELECT TOP 1 @CPOSTINGATHODEPTID=ACCOUNTS_POSTING_DEPT_ID FROM 
				 LOCATION WHERE DEPT_ID='''+@CLOCID+''''
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL,N'@CPOSTINGATHODEPTID CHAR(2) OUTPUT',@CPOSTINGATHODEPTID OUTPUT
    
	SELECT @CTEMPMASTERTABLE=@CSOURCEDB+'TMP_BKT_TILL_LIFTS_'+LTRIM(RTRIM(@CTABLE_SUFFIX))

LBLMERGE:
  					  
    SET @CSTEP=300
	SET @CTABLENAME='TILL_BANK_TRANSFER'
	SET @CTMP_TABLENAME='TMP_BKT_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='MEMO_ID'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
  			  							  						  							  
	
	SET @CSTEP=320						  
	SET @CTABLESSTR='TILL_BANK_TRANSFER'

    EXEC SP3S_DROPTEMPTABLES_MIRRORDATA
    @CXNTYPE='BKT',
    @CTABLESUFFIX=@CTABLE_SUFFIX,
    @CTABLESSTR=@CTABLESSTR

END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP_MERGE_MIRROR_BKT_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
END CATCH
EXIT_PROC:
	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0
	BEGIN
		COMMIT
	END
	ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0
		ROLLBACK
END	
---END OF PROCEDURE - SP_MERGE_MIRROR_BKT_DATA
