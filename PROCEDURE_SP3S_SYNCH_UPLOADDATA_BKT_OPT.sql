CREATE PROCEDURE SP3S_SYNCH_UPLOADDATA_BKT_OPT
(
	@CspId VARCHAR(50),  
    @CERRMSG VARCHAR(MAX) OUTPUT  
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
	   ,@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200),@CSOURCEDB VARCHAR(100),@CMERGEDB VARCHAR(100)
	   		    
DECLARE @TXNSSENDINFO TABLE (ORG_TABLENAME VARCHAR(50),TMP_TABLENAME VARCHAR(50),XN_ID VARCHAR(40))  	

BEGIN TRY
SET @CSTEP=00
    
	SET @CSOURCEDB=''
	SET @CMERGEDB=''
	SET @CTABLE_SUFFIX='UPLOAD'
BEGIN TRANSACTION 

	 ---UPDATE POSTEDINAC MARK FOR THE BILLS POSTEDINTO ACCOUNTS & THERE IS SOME MISMATCH BETWEEN INCOMING DATA & EXISTING DATA
	SET @CSTEP=10
    
  
LBLMERGE:
  	
	
	SET @cFiLterCondition=' b.sp_id='''+@cSPId+''''
	   				  
    SET @CSTEP=300
	SET @CTABLENAME='TILL_BANK_TRANSFER'
	SET @CTMP_TABLENAME='BKT_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='MEMO_ID'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION=@cFiLterCondition,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
  			  						  						  							  
	DELETE FROM  BKT_TILL_BANK_TRANSFER_UPLOAD WHERE SP_ID=@CspId					  
	
END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP3S_SYNCH_UPLOADDATA_TEX_OPT, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
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
