create PROCEDURE SP3S_SYNCH_UPLOADDATA_JWI_OPT
(
    @CSPID VARCHAR(50)
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS
SET NOCOUNT ON
BEGIN
	/*
		208_2014_01_13 : THIS PROCEDURE WILL MERGE DATA FROM TEMPORARY TABLE TO ACTUAL TABLE.
						 TABLE NAMES AND ITS MERGING ORDER WILL BE FIXED AND WILL BE DEFINED HERE.	
						 
		NOTE : EMPLOYEE_HEAD WILL BE MERGED TO EMPLOYEE				 
	*/

DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@CFILTERCONDITION2 VARCHAR(500),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(MAX),@CMIRRORINGENABLED VARCHAR(5)
	   ,@CCURDEPTID VARCHAR(5),@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200)
	   ,@CTEMPPAYMODETABLE VARCHAR(200),@CTEMPTABLE VARCHAR(100),@CDONOTRESETPOSTEDINAC VARCHAR(1)
	   ,@BADDMODE BIT,@CCUTOFFDATE VARCHAR(20),@CWHERECLAUSE VARCHAR(2000),@CMEMONOLEN VARCHAR(5),@NMEMONOLEN INT
	   ,@DMINMEMODT DATETIME,@DMAXMEMODT DATETIME,@CFINYEAR VARCHAR(5),@CMEMOPREFIX VARCHAR(10)
	   ,@CMINMEMONO VARCHAR(20),@CMAXMEMONO VARCHAR(20),@CSOURCEDB VARCHAR(200),@CMERGEDB VARCHAR(200)
	   ,@BMSTINSERTONLY BIT,@BSERIESMISMATCHFOUND BIT,@CMEMOID VARCHAR(40),@CPREVMEMONO VARCHAR(20)
	   ,@NPREVMEMONO NUMERIC(5,0),@NLENVALUE INT,@CPREVMEMONOSEARCH VARCHAR(20),@CMEMOIDSEARCH VARCHAR(40)
	   ,@CRETPRODUCTCODE VARCHAR(50),@NVERSIONNO INT,@CJOINSTR VARCHAR(MAX),@CTEMPSKUTABLE VARCHAR(500),@CTEMPDETAILTABLE1 VARCHAR(100)
	   ,@nUpdateMode numeric(1,0),@bCancelled bit
	

BEGIN TRY
	
	
	SET @CSTEP=10

	SELECT @CSOURCEDB='',@CMERGEDB='',@BMSTINSERTONLY=1,@BSERIESMISMATCHFOUND=0
	
	SET @CSTEP=15
    	
    SELECT TOP 1 @CCURDEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'

	SELECT @CTEMPMASTERTABLE=@CSOURCEDB+'JWI_JOBWORK_ISSUE_MST_UPLOAD',
		   @CTEMPDETAILTABLE=@CSOURCEDB+'JWI_JOBWORK_ISSUE_DET_UPLOAD',
		   @CTEMPDETAILTABLE1=@CSOURCEDB+'JWI_PMT01106_UPLOAD'
	
LBLSTART:

	BEGIN TRANSACTION	
	
    SELECT @CMEMOID=''

	DECLARE @DFREEZINGDATE DATETIME	
	EXEC SP3S_GETDATA_FREEZING_DATE 'JWI',@DFREEZINGDATE OUTPUT
	
    SELECT TOP 1 @CMEMOID = B.ISSUE_ID ,@bCancelled=cancelled 
    FROM JWI_JOBWORK_ISSUE_MST_UPLOAD  B (NOLOCK)
    WHERE ISSUE_DT>=@DFREEZINGDATE 
    AND SP_ID=@CSPID
        
    IF ISNULL(@CMEMOID,'')=''
		GOTO EXIT_PROC
		
    SET @CFILTERCONDITION = 'B.ISSUE_ID='''+@CMEMOID+''' AND B.SP_ID='''+LTRIM(RTRIM((@CSPID)))+''''
	
	
	SET @CMEMOPREFIX=LEFT(RIGHT(@CMEMOID,@NMEMONOLEN),4)
	
	SET @NLENVALUE=@NMEMONOLEN-LEN(@CMEMOPREFIX)
	
	SET @NPREVMEMONO=CONVERT(NUMERIC(5,0),RIGHT(@CMEMOID,@NMEMONOLEN-LEN(@CMEMOPREFIX)))
	
	IF @NPREVMEMONO>1
	BEGIN
		SET @NPREVMEMONO=@NPREVMEMONO-1
		
		SELECT @CFINYEAR=FIN_YEAR FROM JWI_JOBWORK_ISSUE_MST_UPLOAD (NOLOCK) WHERE ISSUE_ID=@CMEMOID
		
		SET @CPREVMEMONO=@CMEMOPREFIX+REPLICATE('0',@NLENVALUE-LEN(LTRIM(RTRIM(STR(@NPREVMEMONO)))))+LTRIM(RTRIM(STR(@NPREVMEMONO)))
		
		SET @CPREVMEMONOSEARCH=''
		SELECT TOP 1 @CPREVMEMONOSEARCH=ISSUE_NO FROM JOBWORK_ISSUE_MST (NOLOCK) WHERE ISSUE_NO=@CPREVMEMONO AND FIN_YEAR=@CFINYEAR
		
		IF ISNULL(@CPREVMEMONOSEARCH,'')=''
		BEGIN
			SET @CERRMSG='PREVIOUS MEMO NO. :'+@CPREVMEMONO+' NOT FOUND...CANNOT MERGE'
			SET @BSERIESMISMATCHFOUND=1
			GOTO EXIT_PROC
		END	
	END
	

	SET @CSTEP=110
	SET @CMEMOIDSEARCH=''
	SELECT TOP 1 @CMEMOIDSEARCH=A.ISSUE_ID FROM JOBWORK_ISSUE_MST A (NOLOCK) WHERE A.ISSUE_ID=@CMEMOID
	
	IF ISNULL(@CMEMOIDSEARCH,'')<>''
		SET @BADDMODE=0
	ELSE
		SET @BADDMODE=1

	
LBLMERGE:
	---DELETING EXISTING RECORD IF BILL COMES AGAIN FOR MERGING
	
	--SELECT @CTEMPMASTERTABLE,@CFILTERCONDITION
	IF @BADDMODE=0
		PRINT 'ADDMODE:N'
	ELSE
		PRINT 'ADDMODE:Y'	
	


	SET @nUpdateMode=(CASE WHEN @BADDMODE=1 THEN 1 WHEN @bCancelled=1 THEN 3 ELSE 2 END)

	EXEC SP3S_upd_qty_lastupdate
	@nUpdateMode=@NUPDATEMODE,
	@cXnType='JWI',
	@nSpId=@CSPID,
	@cMasterTable='JOBWORK_ISSUE_MST',
	@cMemoIdCol='ISSUE_ID',
	@cXnDtCol='issue_dt',
	@cMemoId=@CMEMOIDSEARCH,
	@bCalledfromMerging=1,
	@CERRORMSG=@CERRMSG OUTPUT

	IF ISNULL(@cErrmsg,'')<>''
		GOTO EXIT_PROC
	IF @BADDMODE=0
	BEGIN	
		SET @CSTEP=115
		SET @DTSQL=N'DELETE A FROM JOBWORK_ISSUE_DET A JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.ISSUE_ID=B.ISSUE_ID
					 LEFT OUTER JOIN 
					 (SELECT ROW_ID FROM '+@CTEMPDETAILTABLE+' B WHERE '+@CFILTERCONDITION+') C ON A.ROW_ID = C.ROW_ID 
					 WHERE C.ROW_ID IS NULL AND '+@CFILTERCONDITION

		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL
	
	END
	
	---UPDATING TRANSACTION TABLES
	SET @CSTEP=250
	SET @CTABLENAME='JOBWORK_ISSUE_MST'
	SET @CTMP_TABLENAME='JWI_JOBWORK_ISSUE_MST_UPLOAD'
	SET @CKEYFIELD='ISSUE_ID'
	
	SET @DTSQL = N'UPDATE '+@CSOURCEDB+@CTMP_TABLENAME+'  WITH (ROWLOCK) SET ISSUE_DT = CONVERT(DATETIME,CONVERT(VARCHAR(10),ISSUE_DT,120))'
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	
							  
	SET @CTABLENAME='JOBWORK_ISSUE_MST'
	SET @CTMP_TABLENAME='JWI_JOBWORK_ISSUE_MST_UPLOAD'
	SET @CKEYFIELD='ISSUE_ID'

	
	SET @CSTEP=270
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@LUPDATEONLY
							  ,@BALWAYSUPDATE=1,@BUPDATEXNS=1 
							  
	SET @CTABLENAME='JOBWORK_ISSUE_DET'
	SET @CTMP_TABLENAME='JWI_JOBWORK_ISSUE_DET_UPLOAD'
	SET @CKEYFIELD='ROW_ID'
	 
	SET @CSTEP=280
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1,@BUPDATEXNS=1 

	  

	SET @CSTEP=290 

	EXEC SP3S_MERGE_LOCPMT  
	@cTempTable='JWI_PMT01106_UPLOAD',  
	@cMemoIdCol='SP_ID',  
	@cMemoId =@CSPID

    
 
		DELETE A FROM JWI_JOBWORK_ISSUE_MST_UPLOAD A WHERE A.ISSUE_ID=@CMEMOID 

		DELETE A FROM JWI_JOBWORK_ISSUE_DET_UPLOAD A WHERE A.ISSUE_ID=@CMEMOID 
		DELETE A FROM JWI_PMT01106_UPLOAD A WHERE A.JWI_MEMO_ID=@CMEMOID
		
	

	

END TRY

BEGIN CATCH
	SET @CERRMSG='P:SP3S_SYNCH_UPLOADDATA_JWI_OPT, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
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
---END OF PROCEDURE - SP_SYNCH_MIRRORDATA_JWI_SINGLE
