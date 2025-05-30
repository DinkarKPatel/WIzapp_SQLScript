CREATE PROCEDURE SP_MERGE_MIRROR_DEND_DATA
(
	@CMEMOID VARCHAR(50)
   ,@CLOCID VARCHAR(3)
   ,@CSOURCEDB VARCHAR(200)
   ,@CMERGEDB VARCHAR(200)
   ,@BMSTINSERTONLY BIT
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS
BEGIN
  DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD1 VARCHAR(200),@CKEYFIELD2 VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(MAX),@CKEYFIELD3  VARCHAR(200)
	   
   DECLARE @TXNSSENDINFO TABLE (ORG_TABLENAME VARCHAR(50),TMP_TABLENAME VARCHAR(50),XN_ID VARCHAR(40))  	
   
   BEGIN TRY
	   SET @CSTEP=20
	   SET @CTABLE_SUFFIX=REPLACE(@CMEMOID,'-','_')
	   BEGIN TRANSACTION 
	   
	     SET @BMSTINSERTONLY=0
	   --
		SET @CSTEP=100
		SET @CTABLENAME='DAYCLOSE_LOG'
		SET @CTMP_TABLENAME='TMP_DEND_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
		SET @CKEYFIELD1='LOG_DATE'
		SET @CKEYFIELD2='DEPT_ID'
		SET @CSTEP=110
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
								  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,@CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=''
								  ,@LINSERTONLY=@BMSTINSERTONLY,@CFILTERCONDITION='',@LUPDATEONLY=0
								  ,@BALWAYSUPDATE=1 
								  
					  
		SET @CSTEP=120
		SET @CTABLENAME='CC_BATCH_COLLECTION'
		SET @CTMP_TABLENAME='TMP_DEND_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
		SET @CKEYFIELD1='BATCH_DT'
		SET @CKEYFIELD2='DEPT_ID'
		SET @CKEYFIELD3='paymode_code'
		SET @CSTEP=140
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
								  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,@CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3
								  ,@LINSERTONLY=@BMSTINSERTONLY,@CFILTERCONDITION='',@LUPDATEONLY=0
								  ,@BALWAYSUPDATE=1 
								  
		SET @CSTEP=150
		SET @CTABLENAME='SALEPERSON_WISE_CUSTWALKIN'
		SET @CTMP_TABLENAME='TMP_DEND_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
		SET @CKEYFIELD1='LOG_DATE'
		SET @CKEYFIELD2='EMP_CODE'
		SET @CKEYFIELD3='DEPT_ID'
		SET @CSTEP=160
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
								  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,@CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3
								  ,@LINSERTONLY=@BMSTINSERTONLY,@CFILTERCONDITION='',@LUPDATEONLY=0
								  ,@BALWAYSUPDATE=1 
								  						  
		IF ISNULL(@CERRMSGOUT,'')<>''
		BEGIN
			SET @CERRMSG='P:SP_MERGE_MIRROR_DEND_DATA, STEP:'+@CSTEP+', MESSAGE:'+@CERRMSGOUT
		END							  
		
		SET @CTABLESSTR='DAYCLOSE_LOG,CC_BATCH_COLLECTION,saleperson_wise_custwalkin,XNSTABLELIST'
		
		EXEC SP3S_DROPTEMPTABLES_MIRRORDATA
		@CXNTYPE='DEND',
		@CTABLESUFFIX=@CTABLE_SUFFIX,
		@CTABLESSTR=@CTABLESSTR
	END TRY
	BEGIN CATCH
		SET @CERRMSG='P:SP_MERGE_MIRROR_DEND_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	END CATCH
	EXIT_PROC:
	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0
	BEGIN
		COMMIT
	END
	ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0
		ROLLBACK
END
