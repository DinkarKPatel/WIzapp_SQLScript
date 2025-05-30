create PROCEDURE SP3S_SYNCH_UPLOADDATA_PSHBD_OPT
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
	   ,@CRETPRODUCTCODE VARCHAR(50),@CJOINSTR VARCHAR(MAX),@CTEMPSKUTABLE VARCHAR(500)
	

BEGIN TRY
	
	
	SET @CSTEP=10

	SELECT @CSOURCEDB='',@CMERGEDB='',@BMSTINSERTONLY=1,@BSERIESMISMATCHFOUND=0
	
	SET @CSTEP=15
    	
    SELECT TOP 1 @CCURDEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'

	SELECT @CTEMPMASTERTABLE=@CSOURCEDB+'PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD',
		   @CTEMPDETAILTABLE=@CSOURCEDB+'PSHBD_HOLD_BACK_DELIVER_DET_UPLOAD'
	
LBLSTART:

	BEGIN TRANSACTION	
	
    SELECT @CMEMOID=''

	DECLARE @DFREEZINGDATE DATETIME	
	EXEC SP3S_GETDATA_FREEZING_DATE 'PSHBD',@DFREEZINGDATE OUTPUT
	
    SELECT TOP 1 @CMEMOID = B.MEMO_ID 
    FROM PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD B (NOLOCK)
    WHERE B.SP_ID=@CSPID AND B.memo_dt >=@DFREEZINGDATE
        
    
    IF ISNULL(@CMEMOID,'')=''
		GOTO EXIT_PROC
		
    SET @CFILTERCONDITION = 'B.MEMO_ID='''+@CMEMOID+''' AND B.SP_ID='''+LTRIM(RTRIM((@CSPID )))+''''

	SET @CSTEP=110
	SET @CMEMOIDSEARCH=''
	SELECT TOP 1 @CMEMOIDSEARCH=A.MEMO_ID FROM HOLD_BACK_DELIVER_MST A (NOLOCK) WHERE A.MEMO_ID=@CMEMOID
	
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
	
	IF @BADDMODE=0
	BEGIN	
		SET @CSTEP=115
		SET @DTSQL=N'DELETE A FROM HOLD_BACK_DELIVER_DET A JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.MEMO_ID=B.MEMO_ID
					 LEFT OUTER JOIN 
					 (SELECT ROW_ID FROM '+@CTEMPDETAILTABLE+' B WHERE '+@CFILTERCONDITION+') C ON A.ROW_ID = C.ROW_ID 
					 WHERE C.ROW_ID IS NULL AND '+@CFILTERCONDITION

		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL
	
	END
	
	---UPDATING TRANSACTION TABLES
	SET @CSTEP=250
	SET @CTABLENAME='HOLD_BACK_DELIVER_MST'
	SET @CTMP_TABLENAME='PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD'
	SET @CKEYFIELD='MEMO_ID'
	
	SET @DTSQL = N'UPDATE '+@CSOURCEDB+@CTMP_TABLENAME+'  WITH (ROWLOCK) SET MEMO_DT = CONVERT(DATETIME,CONVERT(VARCHAR(10),MEMO_DT,120))'
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	SET @CTABLENAME='SKU'
	SET @CTMP_TABLENAME='PSHBD_SKU_UPLOAD'
	SET @CKEYFIELD='PRODUCT_CODE'

    SET @CFILTERCONDITION2 = 'B.PSHBD_MEMO_ID='''+@CMEMOID+''' AND B.SP_ID='''+LTRIM(RTRIM((@CSPID )))+''''
	   
	SET @CSTEP=260

	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION2,@LUPDATEONLY=@LUPDATEONLY
							  ,@BALWAYSUPDATE=1
	  
	SET @CTABLENAME='HOLD_BACK_DELIVER_MST'
	SET @CTMP_TABLENAME='PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD'
	SET @CKEYFIELD='MEMO_ID'

	
	SET @CSTEP=270
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@LUPDATEONLY
							  ,@BALWAYSUPDATE=1,@BUPDATEXNS=1 
							  
	SET @CTABLENAME='HOLD_BACK_DELIVER_DET'
	SET @CTMP_TABLENAME='PSHBD_HOLD_BACK_DELIVER_DET_UPLOAD'
	SET @CKEYFIELD='ROW_ID'
	 
	SET @CSTEP=280
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1,@BUPDATEXNS=1 

	  
	  declare @cimagedbname varchar(100)
	  set @cimagedbname=DB_NAME ()+'_image.dbo.'

	SET @CTABLENAME='IMAGE_INFO'
	SET @CTMP_TABLENAME='PSHBD_IMAGE_INFO_UPLOAD'
	SET @CKEYFIELD='PRODUCT_CODE'
	 
	SET @CSTEP=280

	 SET @CFILTERCONDITION = ' B.SP_ID='''+LTRIM(RTRIM((@CSPID )))+''''

	EXEC UPDATEMASTERXN @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@cimagedbname
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION
							  ,@LUPDATEONLY=0,@BALWAYSUPDATE=1

	  

	  --item status table not in use
	-- EXEC SP3S_INSUPDATE_ITEM_STATUS 'PSHBD',@CMEMOID	 
    
    SET @CSTEP=330
   
    		
		

END TRY

BEGIN CATCH
	SET @CERRMSG='P:SP3S_SYNCH_UPLOADDATA_PSHBD_OPT, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:

	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRMSG,'')='' 
			COMMIT
		ELSE
			ROLLBACK
    END

	DELETE A FROM PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD A with (rowlock) WHERE  A.SP_ID=@CSPID
		
	DELETE A FROM PSHBD_SKU_UPLOAD A with (rowlock) WHERE  A.SP_ID=@CSPID
		
	DELETE A FROM PSHBD_HOLD_BACK_DELIVER_DET_UPLOAD A with (rowlock) WHERE  A.SP_ID=@CSPID
		
	
END	
---END OF PROCEDURE - SP_SYNCH_MIRRORDATA_PSHBD_SINGLE
