CREATE PROCEDURE SP_MERGE_MIRROR_RPS_DATA
(
	@CMEMOID VARCHAR(50),
	@CLOCID CHAR(2),
	@CSOURCEDB VARCHAR(300),
	@CMERGEDB VARCHAR(300),
	@BMSTINSERTONLY BIT,
	@CERRMSG VARCHAR(MAX) OUTPUT
)
--WITH ENCRYPTION
AS
SET NOCOUNT ON
BEGIN
	/*
		SP_MERGE_MIRROR_RPS_DATA_208_2014_02_05 : 
		THIS PROCEDURE WILL MERGE DATA FROM TEMPORARY TABLE TO ACTUAL TABLE.
		TABLE NAMES AND ITS MERGING ORDER WILL BE FIXED AND WILL BE DEFINED HERE.	
	*/
DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(500),@CTEMPTABLE VARCHAR(200)
	   
BEGIN TRY
SET @CSTEP=00


SET @CSTEP=10
SET @CTABLE_SUFFIX=REPLACE(@CMEMOID,'-','_')
BEGIN TRANSACTION 

	SET @CSTEP=20

	SET @CTABLENAME='RPS_DET'
	SET @CTMP_TABLENAME='TMP_RPS_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CTEMPTABLE=@CSOURCEDB+@CTMP_TABLENAME
	SET @CKEYFIELD='CM_ID'
	SET @CSTEP=25

	SET @DTSQL=N'IF OBJECT_ID('''+@CTEMPTABLE+''',''U'') IS NOT NULL
					DELETE A FROM '+@CMERGEDB+'['+@CTABLENAME+'] A WITH (ROWLOCK) LEFT OUTER JOIN
					'+@CTEMPTABLE+' B (NOLOCK) ON A.ROW_ID=B.ROW_ID  WHERE A.'+@CKEYFIELD+'='''+@CMEMOID+'''
					AND B.ROW_ID IS NULL
				 ELSE
					DELETE FROM '+@CMERGEDB+'['+@CTABLENAME+'] WITH (ROWLOCK) WHERE '+@CKEYFIELD+'='''+@CMEMOID+''''   
				    
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	SET @CSTEP=30
	SET @CTABLENAME='SKU'
	SET @CTMP_TABLENAME='TMP_RPS_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PRODUCT_CODE'
	SET @CSTEP=35
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
							  	

	SET @CSTEP=35
	SET @CTABLENAME='EMPLOYEE'
	SET @CTMP_TABLENAME='TMP_RPS_EMPLOYEE_HEAD_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='EMP_CODE'
	SET @CSTEP=350
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=40
	SET @CTABLENAME='EMPLOYEE'
	SET @CTMP_TABLENAME='TMP_RPS_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='EMP_CODE'
	SET @CSTEP=370
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 

    SET @CSTEP=50
	SET @CTABLENAME='RPS_MST'
	SET @CTMP_TABLENAME='TMP_RPS_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='CM_ID'
	SET @CSTEP=55
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
							  
	SET @CSTEP=60
	SET @CTABLENAME='RPS_DET'
	SET @CTMP_TABLENAME='TMP_RPS_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='ROW_ID'
	SET @CSTEP=65
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 

	SET @CSTEP=70
	SET @CTABLESSTR='RPS_MST,RPS_DET,SKU,XNSTABLELIST'

    EXEC SP3S_DROPTEMPTABLES_MIRRORDATA
    @CXNTYPE='RPS',
    @CTABLESUFFIX=@CTABLE_SUFFIX,
    @CTABLESSTR=@CTABLESSTR


END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP_MERGE_MIRROR_RPS_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
END CATCH
EXIT_PROC:
	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0
	BEGIN
		COMMIT
	END
	ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0
		ROLLBACK
END	
---END OF PROCEDURE - SP_MERGE_MIRROR_RPS_DATA
