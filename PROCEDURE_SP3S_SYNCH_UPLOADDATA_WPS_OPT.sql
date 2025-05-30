create PROCEDURE SP3S_SYNCH_UPLOADDATA_WPS_OPT
(
    @NSPID VARCHAR(50)
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
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
	   ,@CCURDEPTID VARCHAR(5),@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE1 VARCHAR(200)
	   ,@CTEMPDETAILTABLE2 VARCHAR(200),@CTEMPDETAILTABLE3 VARCHAR(200)
	   ,@CTEMPPAYMODETABLE VARCHAR(200),@CTEMPTABLE VARCHAR(100),@CDONOTRESETPOSTEDINAC VARCHAR(1)
	   ,@BADDMODE BIT,@CCUTOFFDATE VARCHAR(20),@CWHERECLAUSE VARCHAR(2000),@CMEMONOLEN VARCHAR(5),@NMEMONOLEN INT
	   ,@DMINMEMODT DATETIME,@DMAXMEMODT DATETIME,@CFINYEAR VARCHAR(5),@CMEMOPREFIX VARCHAR(10)
	   ,@CMINMEMONO VARCHAR(20),@CMAXMEMONO VARCHAR(20),@CSOURCEDB VARCHAR(200),@CMERGEDB VARCHAR(200)
	   ,@BMSTINSERTONLY BIT,@BSERIESMISMATCHFOUND BIT,@CMEMOID VARCHAR(40),@CPREVMEMONO VARCHAR(20)
	   ,@NPREVMEMONO NUMERIC(5,0),@NLENVALUE INT,@CPREVMEMONOSEARCH VARCHAR(20),@CMEMOIDSEARCH VARCHAR(40)
	   ,@CRETPRODUCTCODE VARCHAR(50),@NVERSIONNO INT,@CJOINSTR VARCHAR(MAX),@cMissingRowId VARCHAR(50)
	   ,@cUpdatestr VARCHAR(2000),@CLOCID VARCHAR(5),@bCancelled bit,@nUpdateMode numeric(1,0)
	

BEGIN TRY
	
	
	SET @CSTEP=10
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1
	SELECT @CSOURCEDB='',@CMERGEDB='',@BMSTINSERTONLY=1,@BSERIESMISMATCHFOUND=0


	SELECT @CTEMPMASTERTABLE=@CSOURCEDB+'WPS_WPS_MST_UPLOAD',
		   @CTEMPDETAILTABLE1=@CSOURCEDB+'WPS_WPS_DET_UPLOAD',
		   @CTEMPDETAILTABLE2=@CSOURCEDB+'WPS_PMT01106_UPLOAD'
		
	IF EXISTS (SELECT TOP 1 tablename FROM savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@NSPID)
		DELETE FROM savetran_updcols_updatestr WITH (ROWLOCK) WHERE sp_id=@NSPID

	INSERT savetran_updcols_updatestr (sp_id,tablename,updatestr)
	SELECT @NSPID as sp_id,tablename,'' from mirrorxnsinfo (NOLOCK)
	WHERE tablename IN ('wps_mst','wps_det')


	SET @CSTEP=14
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1


	SET @CSTEP=16
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1
	DECLARE @DFREEZINGDATE DATETIME	
	EXEC SP3S_GETDATA_FREEZING_DATE 'WPS',@DFREEZINGDATE OUTPUT


LBLSTART:
    BEGIN TRANSACTION 	
	SET @CSTEP=18
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

    SELECT @CMEMOID='',@NVERSIONNO=0

    SELECT TOP 1 @CMEMOID = B.PS_ID ,@CCURDEPTID=B.location_Code,@bCancelled=CANCELLED
    FROM WPS_WPS_MST_UPLOAD  B (NOLOCK)
    WHERE  PS_DT>@DFREEZINGDATE
	AND SP_ID =@NSPID 
  
   
    IF ISNULL(@CMEMOID,'')=''
		GOTO EXIT_PROC

    SET @CLOCID=@CCURDEPTID
    SELECT TOP 1 @CDONOTRESETPOSTEDINAC=VALUE FROM CONFIG WHERE CONFIG_OPTION='DONOT_RESET_ACCOUNTS_POSTEDINAC'
    
    SET @CDONOTRESETPOSTEDINAC=ISNULL(@CDONOTRESETPOSTEDINAC,'')
		
    DECLARE @CPOSTINGATHODEPTID VARCHAR(5)
    
	SET @DTSQL=N'SELECT TOP 1 @CPOSTINGATHODEPTID=ACCOUNTS_POSTING_DEPT_ID FROM 
				 LOCATION WHERE DEPT_ID='''+@CLOCID+''''
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL,N'@CPOSTINGATHODEPTID CHAR(2) OUTPUT',@CPOSTINGATHODEPTID OUTPUT

		
    SET @CFILTERCONDITION = 'B.Sp_ID='''+@nSpId+''''

	SET @CSTEP=20
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

	SET @CMEMOIDSEARCH=''
	SELECT TOP 1 @CMEMOIDSEARCH=A.PS_ID FROM WPS_MST A (NOLOCK) WHERE A.PS_ID=@CMEMOID
	
	IF ISNULL(@CMEMOIDSEARCH,'')<>''
		SET @BADDMODE=0
	ELSE
		SET @BADDMODE=1
  
  DECLARE @CBO_DET_ROW_ID VARCHAR(100) 
  SELECT @CBO_DET_ROW_ID=BO_DET_ROW_ID   FROM WPS_WPS_DET_UPLOAD (NOLOCK) WHERE ps_id =	@cMemoId
			

--LBLMERGE:
	---DELETING EXISTING RECORD IF BILL COMES AGAIN FOR MERGING
	
	--SELECT @CTEMPMASTERTABLE,@CFILTERCONDITION
	IF @BADDMODE=0
		PRINT 'ADDMODE:N'
	ELSE
		PRINT 'ADDMODE:Y'	
	
	SET @nUpdateMode=(CASE WHEN @BADDMODE=1 THEN 1 WHEN @bCancelled=1 THEN 3 ELSE 2 END)

	EXEC SP3S_upd_qty_lastupdate
	@nUpdateMode=@NUPDATEMODE,
	@cXnType='WPS',
	@nSpId=@nSpId,
	@cMasterTable='WPS_mst',
	@cMemoIdCol='PS_id',
	@cXnDtCol='Ps_dt',
	@cMemoId=@CMEMOIDSEARCH,
	@bCalledfromMerging=1,
	@CERRORMSG=@CERRMSG OUTPUT

	IF ISNULL(@cErrmsg,'')<>''
		GOTO EXIT_PROC

	IF @BADDMODE=0
	BEGIN	
		SET @CSTEP=30
		EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

		EXEC SP3S_VERIFY_WPSDATA_merge_CHANGES
		@nSpId=@nSpId,
		@cMemoId=@cMemoId
		
		SET @CSTEP=35
		EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1
		SELECT TOP 1 @cMissingRowId=a.row_id FROM wps_det A (NOLOCK) 
		LEFT JOIN 
		(SELECT row_id FROM WPS_wps_det_upload  B (NOLOCK) WHERE sp_id=@NSPID ) b
		ON A.row_ID =B.row_ID WHERE A.ps_id =@CMEMOID AND b.row_id IS NULL

		IF ISNULL(@CBO_DET_ROW_ID,'')<>'' 
		    BEGIN

			    EXEC SP3S_PROCESS_INV_QTY @cMemoId,1,@CERRMSG OUTPUT,'WPS' 
				IF ISNULL(@CERRMSG,'')<>''
				GOTO EXIT_PROC

		        DELETE A  FROM BUYER_ORDER_WPS_LINK A (nolock)
				JOIN WPS_DET B (nolock) ON A.WPS_DET_ROW_ID =B.ROW_ID 
				WHERE B.PS_ID =@CMEMOID

		     END


		IF ISNULL(@cMissingRowId,'')<>''
		BEGIN		
			SET @CSTEP=40
			EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

			DELETE A FROM WPS_DET A (NOLOCK) LEFT JOIN 
			(SELECT row_id FROM WPS_wps_det_UPLOAD  B (NOLOCK) WHERE sp_id=@NSPID ) b
			ON A.row_ID =B.row_ID WHERE A.ps_id =@CMEMOID AND b.row_id IS NULL

		END
	
	END


	SET @CSTEP=45
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

	SET @CTABLENAME='WPS_MST'
	SET @CTMP_TABLENAME='WPS_WPS_MST_upload'
	SET @CKEYFIELD='PS_ID'

	SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@NSPID  AND tablename='wps_mst'
	SET @LUPDATEONLY = (CASE WHEN @BADDMODE=0 THEN 1 ELSE 0 END)	
	
	SET @CSTEP=50
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

	
	EXEC UPDATEMASTERXN_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@LUPDATEONLY
							  ,@BALWAYSUPDATE=1,@lUpdateXns=1,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1  
							  
	 
	SELECT @cMissingRowId='',@lUpdateonly=0
	IF @BADDMODE=0
	BEGIN
		SET @CSTEP=55
		EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

		SELECT TOP 1 @cMissingRowId=b.row_id FROM 
		(SELECT row_id  FROM WPS_wps_det_upload (NOLOCK) WHERE sp_id=(@nSpId+@CLOCID )) A
		RIGHT OUTER JOIN 
		(SELECT row_id FROM WPS_WPS_DET_UPLOAD (NOLOCK) WHERE sp_id=@NSPID) b ON 
		a.row_id=b.row_id WHERE a.row_id IS NULL

		--SELECT 'check @cMissingRowId of pid',@cMissingRowId
		

		IF ISNULL(@cMissingRowId,'')='' 
			SET @lUpdateonly=1
	END

	SET @CSTEP=60
    EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

	SET @CTABLENAME='WPS_DET'
	SET @CTMP_TABLENAME='WPS_WPS_DET_upload'
	SET @CKEYFIELD='ROW_ID'

	SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@NSPID AND tablename='wps_det'

	EXEC UPDATEMASTERXN_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@lUpdateonly
							  ,@BALWAYSUPDATE=1,@lUpdateXns=@BADDMODE,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1 



	SET @CSTEP=71
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

	


	IF ISNULL(@CBO_DET_ROW_ID ,'')<>'' 
	BEGIN
	    
		SET @CTABLENAME='BUYER_ORDER_WPS_LINK'
		SET @CTMP_TABLENAME='WPS_BUYER_ORDER_WPS_LINK_UPLOAD'
		SET @CKEYFIELD='WPS_DET_ROW_ID'


		  EXEC UPDATEMASTERXN_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
								  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
								  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION



		EXEC SP3S_PROCESS_INV_QTY @CMEMOID ,0,@CERRMSG OUTPUT,'WPS' 
		IF ISNULL(@CERRMSG,'')<>''
		GOTO EXIT_PROC
				   
	END
			

   	EXEC SP3S_MERGE_LOCPMT  
	@cTempTable='WPS_PMT01106_upload',  
	@cMemoIdCol='sp_id',  
	@cMemoId =@nSpId
	
	IF ISNULL(@cErrmsg,'')=''
	BEGIN
		SET @CSTEP=80
		EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CMEMOID,'',1

		EXEC SP3S_VALIDATE_DATAMERGED_SINGLECHANNEL
		@cMasterTable='wps_mst',
		@cDetTable='wps_det',
		@cMemoIdCol='ps_id',
		@cMemoId=@cMemoId,
		@cUploadTable='wps_wps_mst_upload',
		@nSpId=@nSpId,
		@cErrormsg=@CERRMSG OUTPUT

		IF ISNULL(@cErrmsg,'')=''
			GOTO EXIT_PROC
    END

	
	

END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP3S_SYNCH_UPLOADDATA_WPS_OPT, MEMO ID :'+@CMEMOID+' STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
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

    EXEC SP3S_DELETE_UPLOAD_wpsMERGE_TABLES @nspid, @cMemoId
	
END	
