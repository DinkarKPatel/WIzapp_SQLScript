create PROCEDURE SP3S_SYNCH_UPLOADDATA_MIS_OPT
(
    @nSpId VARCHAR(50)
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
AS
SET NOCOUNT ON
BEGIN


DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@CFILTERCONDITION2 VARCHAR(500),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(MAX),@CMIRRORINGENABLED VARCHAR(5)
	   ,@CCURDEPTID VARCHAR(5),@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE1 VARCHAR(200),@CTEMPDETAILTABLE2 VARCHAR(200)
	   ,@CTEMPPAYMODETABLE VARCHAR(200),@CTEMPTABLE VARCHAR(100),@CDONOTRESETPOSTEDINAC VARCHAR(1)
	   ,@BADDMODE BIT,@CCUTOFFDATE VARCHAR(20),@CWHERECLAUSE VARCHAR(2000),@CMEMONOLEN VARCHAR(5),@NMEMONOLEN INT
	   ,@DMINMEMODT DATETIME,@DMAXMEMODT DATETIME,@CFINYEAR VARCHAR(5),@CMEMOPREFIX VARCHAR(10)
	   ,@CMINMEMONO VARCHAR(20),@CMAXMEMONO VARCHAR(20),@CSOURCEDB VARCHAR(200),@CMERGEDB VARCHAR(200)
	   ,@BMSTINSERTONLY BIT,@BSERIESMISMATCHFOUND BIT,@CMEMOID VARCHAR(40),@CPREVMEMONO VARCHAR(20)
	   ,@NPREVMEMONO NUMERIC(5,0),@NLENVALUE INT,@CPREVMEMONOSEARCH VARCHAR(20),@CMEMOIDSEARCH VARCHAR(40)
	   ,@CRETPRODUCTCODE VARCHAR(50),@NVERSIONNO INT,@CJOINSTR VARCHAR(MAX),@CTEMPSKUTABLE VARCHAR(500)
	   ,@CPARTYDEPTID VARCHAR(5),@NINVMODE INT,@CTEMPIMPTABLE VARCHAR(200),@CFILTERCONDITION3 VARCHAR(500),
	   @CCMD NVARCHAR(MAX),@CTEMPDETAILTABLE3 VARCHAR(200),@BCANCELLED BIT ,
	   @cUpdatestr VARCHAR(MAX),@nUpdateMode numeric(1,0),@cLocId varchar(5)
	

BEGIN TRY
	
	
	SET @CSTEP=10

	SELECT @CSOURCEDB='',@CMERGEDB='',@BMSTINSERTONLY=1,@BSERIESMISMATCHFOUND=0
	
	SET @CSTEP=15
    	
    SELECT TOP 1 @CCURDEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'

	SELECT @CTEMPMASTERTABLE=@CSOURCEDB+'MIS_BOM_ISSUE_MST_UPLOAD',
		   @CTEMPDETAILTABLE1=@CSOURCEDB+'MIS_BOM_ISSUE_DET_UPLOAD' ,
		   @CTEMPDETAILTABLE2=@CSOURCEDB+'MIS_BOM_ISSUE_REF_UPLOAD' 
	
LBLSTART:
    
    BEGIN TRANSACTION
    
    SELECT @CMEMOID='',@NVERSIONNO=0
		
    SET @CSTEP=30
    SELECT TOP 1 @CMEMOID = B.ISSUE_ID ,@BCANCELLED=CANCELLED ,@cLocId= B.location_Code 
    FROM MIS_BOM_ISSUE_MST_UPLOAD B (NOLOCK)
	WHERE SP_ID=@nSpId
   
    IF ISNULL(@CMEMOID,'')=''
		GOTO EXIT_PROC
		
    SET @CFILTERCONDITION = 'B.ISSUE_ID='''+@CMEMOID+''' AND B.VERSION_NO='+LTRIM(RTRIM(STR(@NVERSIONNO)))
	

	SET @CSTEP=40
	SET @CMEMOIDSEARCH=''
	SELECT TOP 1 @CMEMOIDSEARCH=A.ISSUE_ID FROM BOM_ISSUE_MST A (NOLOCK) WHERE A.ISSUE_ID=@CMEMOID
	
	IF ISNULL(@CMEMOIDSEARCH,'')<>''
		SET @BADDMODE=0
	ELSE
		SET @BADDMODE=1


	SET @nUpdateMode=(CASE WHEN @BADDMODE=1 THEN 1 WHEN @bCancelled=1 THEN 3 ELSE 2 END)

	EXEC SP3S_upd_qty_lastupdate
	@nUpdateMode=@NUPDATEMODE,
	@cXnType='MIS',
	@nSpId=@nSpId,
	@cMasterTable='Bom_issue_mst',
	@cMemoIdCol='issue_id',
	@cXnDtCol='issue_dt',
	@cMemoId=@CMEMOIDSEARCH,
	@bCalledfromMerging=1,
	@CERRORMSG=@CERRMSG OUTPUT

	IF ISNULL(@cErrmsg,'')<>''
		GOTO EXIT_PROC

	IF @BADDMODE=0
	BEGIN	
		
		 IF @bCancelled=1 
		BEGIN
			UPDATE BOM_ISSUE_MST WITH (ROWLOCK) SET cancelled=1 WHERE ISSUE_ID=@cMemoid
			GOTO lblUpdatePmt
		END

		IF EXISTS (SELECT TOP 1 tablename FROM savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nSPID)
			DELETE FROM savetran_updcols_updatestr WITH (ROWLOCK) WHERE sp_id=@nSpId

		INSERT savetran_updcols_updatestr (sp_id,tablename,updatestr)
		SELECT @nSPId as sp_id,tablename,'' from mirrorxnsinfo (NOLOCK)
		WHERE tablename IN ('BOM_ISSUE_MST','BOM_ISSUE_DET','BOM_ISSUE_REF')


		EXEC SP3S_VERIFY_MISDATA_MERGE_CHANGES
		@cMemoId=@cMemoId,
		@nSpId=@nSpid


	END

	
	DECLARE @cMissingROW_ID VARCHAR(40)

	IF @BADDMODE=0
	BEGIN	

		SET @CSTEP=27

		SELECT TOP 1 @cMissingROW_ID=a.row_id FROM BOM_ISSUE_REF A (NOLOCK) 
		LEFT JOIN 
		(SELECT row_id FROM MIS_BOM_ISSUE_REF_UPLOAD B (NOLOCK) WHERE sp_id=@nSpId) b
		ON A.row_ID =B.row_ID WHERE A.BOM_ISSUE_ID =@CMEMOID AND b.row_id IS NULL

		IF ISNULL(@cMissingROW_ID,'')<>''
		BEGIN		
			SET @CSTEP=30


			DELETE A FROM BOM_ISSUE_REF A WITH (ROWLOCK) LEFT JOIN 
			(SELECT row_id FROM MIS_BOM_ISSUE_REF_UPLOAD B (NOLOCK) WHERE sp_id=@nSpId) b
			ON A.row_ID =B.row_ID WHERE A.BOM_ISSUE_ID =@CMEMOID AND b.row_id IS NULL
		END

		SET @CSTEP=32
	

		SELECT TOP 1 @cMissingROW_ID=a.ROW_ID FROM BOM_ISSUE_DET A (NOLOCK) 
		LEFT JOIN 
		(SELECT ROW_ID FROM MIS_BOM_ISSUE_DET_UPLOAD B (NOLOCK) WHERE sp_id=@nSpId) b
		ON A.ROW_ID =B.ROW_ID WHERE A.issue_id =@CMEMOID AND b.ROW_ID IS NULL
				
		IF ISNULL(@cMissingROW_ID,'')<>''
		BEGIN		
			SET @CSTEP=35
		  
			DELETE A FROM BOM_ISSUE_DET A WITH (ROWLOCK) LEFT JOIN 
			(SELECT ROW_ID FROM MIS_BOM_ISSUE_DET_upload B (NOLOCK) WHERE sp_id=@nSpId) b
			ON A.ROW_ID =B.ROW_ID WHERE A.issue_id =@CMEMOID AND b.ROW_ID IS NULL
		END

			SET @CSTEP=40
	

	END
	
	
LBLMERGE:

	

	SET @CFILTERCONDITION = 'B.BOM_ISSUE_ID='''+@CMEMOID+''' AND B.SP_ID='+LTRIM(RTRIM((@nSpId)))+''''			
	
    SET @CTABLENAME='BOM_ISSUE_MST'
	SET @CTMP_TABLENAME='MIS_BOM_ISSUE_MST_UPLOAD'
	SET @CKEYFIELD='ISSUE_ID'

	SET @CSTEP=70	 
	
    SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nspid and tablename='BOM_ISSUE_MST'
	SET @LUPDATEONLY = (CASE WHEN @BADDMODE=0 THEN 1 ELSE 0 END)	

	EXEC UPDATEMASTERXN_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@LUPDATEONLY
							  ,@BALWAYSUPDATE=1,@lUpdateXns=1,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1  
							  
				  
							  
							  
							  
    SET @CTABLENAME='BOM_ISSUE_DET'
	SET @CTMP_TABLENAME='MIS_BOM_ISSUE_DET_MIRROR'
	SET @CKEYFIELD='ROW_ID'

	
	SELECT @cMissingROW_ID='',@lUpdateonly=0
	IF @BADDMODE=0
	BEGIN
		SET @CSTEP=85
	
		SELECT TOP 1 @cMissingROW_ID=b.row_id FROM 
		(SELECT row_id  FROM MIS_BOM_ISSUE_DET_UPLOAD (NOLOCK) WHERE sp_id=(LEFT(@nSPId,38)+@cLocId )) A
		RIGHT OUTER JOIN 
		(SELECT row_id FROM MIS_BOM_ISSUE_DET_UPLOAD (NOLOCK) WHERE sp_id=@nSpId) b ON 
		a.row_id=b.row_id WHERE a.row_id IS NULL

		IF ISNULL(@cMissingROW_ID,'')='' 
			SET @lUpdateonly=1
	END

	SET @CSTEP=90
   

	SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nspid and tablename='BOM_ISSUE_DET'

	EXEC UPDATEMASTERXN_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@lUpdateonly
							  ,@BALWAYSUPDATE=1,@lUpdateXns=@BADDMODE,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1 





	SET @CFILTERCONDITION = 'B.BOM_ISSUE_ID='''+@CMEMOID+''' AND B.SP_ID='+LTRIM(RTRIM((@nSpId )))+''''

						  							  
	SET @CTABLENAME='BOM_ISSUE_REF'
	SET @CTMP_TABLENAME='MIS_BOM_ISSUE_REF_MIRROR'
	SET @CKEYFIELD='ROW_ID'

	
	
	SELECT @cMissingROW_ID='',@lUpdateonly=0
	IF @BADDMODE=0
	BEGIN
		SET @CSTEP=90
	
		SELECT TOP 1 @cMissingROW_ID=b.row_id FROM 
		(SELECT row_id  FROM MIS_BOM_ISSUE_REF_UPLOAD (NOLOCK) WHERE sp_id=(LEFT(@nSPId,38)+@cLocId )) A
		RIGHT OUTER JOIN 
		(SELECT row_id FROM MIS_BOM_ISSUE_REF_UPLOAD (NOLOCK) WHERE sp_id=@nSpId) b ON 
		a.row_id=b.row_id WHERE a.row_id IS NULL

		IF ISNULL(@cMissingROW_ID,'')='' 
			SET @lUpdateonly=1
	END

	SET @CSTEP=90
   

	SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nspid and tablename='BOM_ISSUE_REF'

	EXEC UPDATEMASTERXN_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@lUpdateonly
							  ,@BALWAYSUPDATE=1,@lUpdateXns=@BADDMODE,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1 

	SET @CSTEP=95 


	lblUpdatePmt:
	EXEC SP3S_MERGE_LOCPMT  
	@cTempTable='MIS_PMT01106_UPLOAD',  
	@cMemoIdCol='SP_ID',  
	@cMemoId =@nSpId

	SET @CSTEP=100    	
	
	DECLARE @nSpIdCopy VARCHaR(50)

	SET @nSpIdCopy=LEFT(@nSPId,38)+@cLocId 

	EXEC SP3S_DELETEupload_MISmerge_TABLES @nSpId

	IF @BADDMODE=0
	EXEC SP3S_DELETEupload_MISmerge_TABLES @nSpIdCopy	
	  		






END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP_SYNCH_MIRRORDATA_MIS_SINGLE, MEMO ID :'+@CMEMOID+' STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:

	
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRMSG,'')='' AND @BSERIESMISMATCHFOUND<>1
			COMMIT
		ELSE
			ROLLBACK
    END
	
END	
---END OF PROCEDURE - SP_SYNCH_MIRRORDATA_MIS_SINGLE
