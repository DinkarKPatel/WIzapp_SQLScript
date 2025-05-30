CREATE PROCEDURE SP_MERGE_MIRROR_WPL_DATA
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
SET NOCOUNT ON
BEGIN
	/*
		SP_MERGE_MIRROR_WPL_DATA_208_2014_01_29 : THIS PROCEDURE WILL MERGE DATA FROM TEMPORARY TABLE TO ACTUAL TABLE.
												  TABLE NAMES AND ITS MERGING ORDER WILL BE FIXED AND WILL BE 
												  DEFINED HERE.	
						 
		NOTE : EMP_HEAD WILL BE MERGED TO EMPLOYEE				 
	*/
DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(MAX),@CTEMPTABLE VARCHAR(100)
		
BEGIN TRY

	SET @CSTEP=10
	SET @CTABLE_SUFFIX=REPLACE(@CMEMOID,'-','_')
	
	BEGIN TRANSACTION 
	
	SET @CSTEP=20
	

	
	SET @CSTEP=50
	SET @CTABLENAME='WSL_PICKLIST_DET'
	SET @CTMP_TABLENAME='TMP_WPL_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CTEMPTABLE=@CSOURCEDB+@CTMP_TABLENAME
	SET @CKEYFIELD='PICK_LIST_ID'
	SET @CSTEP=60

	SET @DTSQL=N'IF OBJECT_ID('''+@CTEMPTABLE+''',''U'') IS NOT NULL
						DELETE A FROM '+@CMERGEDB+'['+@CTABLENAME+'] A LEFT OUTER JOIN
					'+@CTEMPTABLE+' B ON A.ROW_ID=B.ROW_ID  WHERE A.'+@CKEYFIELD+'='''+@CMEMOID+'''
				    AND B.ROW_ID IS NULL
				 ELSE
					DELETE FROM '+@CMERGEDB+'['+@CTABLENAME+'] WHERE '+@CKEYFIELD+'='''+@CMEMOID+''''   
				    
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL
	
	SET @CSTEP=70
	SET @CTABLENAME='ARTICLE'
	SET @CTMP_TABLENAME='TMP_WPL_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='ARTICLE_CODE'
	SET @CSTEP=80
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BMSTINSERTONLY,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=110 	
	SET @CTABLENAME='PARA1'
	SET @CTMP_TABLENAME='TMP_WPL_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA1_CODE'
	SET @CSTEP=120
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BMSTINSERTONLY,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=130
	SET @CTABLENAME='PARA2'
	SET @CTMP_TABLENAME='TMP_WPL_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA2_CODE'
	SET @CSTEP=140
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BMSTINSERTONLY,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	
	
	SET @CSTEP=300
	SET @CTABLENAME='WSL_PICKLIST_MST'
	SET @CTMP_TABLENAME='TMP_WPL_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PICK_LIST_ID'
	SET @CSTEP=310
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1
							   
	SET @CSTEP=320
	SET @CTABLENAME='WSL_PICKLIST_DET'
	SET @CTMP_TABLENAME='TMP_WPL_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PICK_LIST_ID'
	SET @CSTEP=330
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 


	IF ISNULL(@CERRMSGOUT,'')<>''
	BEGIN
		SET @CERRMSG='P:SP_MERGE_MIRROR_WPL_DATA, STEP:'+@CSTEP+', MESSAGE:'+@CERRMSGOUT
	END	

	SET @CSTEP=450
	
	SET @CTABLESSTR='ARTICLE,PARA1,PARA2,WSL_PICKLIST_DET,WSL_PICKLIST_MST,XNSTABLELIST'

    EXEC SP3S_DROPTEMPTABLES_MIRRORDATA
    @CXNTYPE='WPL',
    @CTABLESUFFIX=@CTABLE_SUFFIX,
    @CTABLESSTR=@CTABLESSTR


END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP_MERGE_MIRROR_WPL_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
END CATCH

EXIT_PROC:
	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0
	BEGIN
		COMMIT
	END
	ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0
		ROLLBACK
END	
---END OF PROCEDURE - SP_MERGE_MIRROR_WPL_DATA
