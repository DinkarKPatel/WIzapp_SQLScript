CREATE PROCEDURE SP3S_SYNCH_UPLOADDATA_ARC_OPT
(
    @nSpId VARCHAR(50)
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
	   ,@CCURDEPTID VARCHAR(5),@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE1 VARCHAR(200)
	   ,@CTEMPDETAILTABLE2 VARCHAR(200),@CTEMPDETAILTABLE3 VARCHAR(200)
	   ,@CTEMPPAYMODETABLE VARCHAR(200),@CTEMPTABLE VARCHAR(100),@CDONOTRESETPOSTEDINAC VARCHAR(1)
	   ,@BADDMODE BIT,@CCUTOFFDATE VARCHAR(20),@CWHERECLAUSE VARCHAR(2000),@CMEMONOLEN VARCHAR(5),@NMEMONOLEN INT
	   ,@DMAXMEMODT DATETIME,@CFINYEAR VARCHAR(5),@CMEMOPREFIX VARCHAR(10)
	   ,@CMAXMEMONO VARCHAR(20),@CSOURCEDB VARCHAR(200),@CMERGEDB VARCHAR(200)
	   ,@BMSTINSERTONLY BIT,@BSERIESMISMATCHFOUND BIT,@CMEMOID VARCHAR(40),@CPREVMEMONO VARCHAR(20)
	   ,@NPREVMEMONO NUMERIC(5,0),@NLENVALUE INT,@CPREVMEMONOSEARCH VARCHAR(20),@CMEMOIDSEARCH VARCHAR(40)
	   ,@CRETPRODUCTCODE VARCHAR(50),@NVERSIONNO INT,@CJOINSTR VARCHAR(MAX),@CARCCUSTCODE CHAR(12)
	   ,@CSEARCHCUSTCODE CHAR(12),@CREQMEMOID VARCHAR(40),@CREQCUSTCODE CHAR(12),@BCUSTREQINSERTED BIT
	   ,@CMEMONO VARCHAR(15),@CFILTERCONDITIONCUS VARCHAR(500),@NARCT INT,@CLOCID VARCHAR(2),@cMissingRowId varchar(50)
	   ,@cUpdatestr VARCHAR(2000)
	

BEGIN TRY
	
	
	SET @CSTEP=10

	SELECT @CSOURCEDB='',@CMERGEDB='',@BMSTINSERTONLY=1,@BSERIESMISMATCHFOUND=0
	

	SET @CSTEP=20
	SET @NMEMONOLEN=10


	SELECT @CTEMPMASTERTABLE=@CSOURCEDB+'ARC_ARC01106_UPLOAD',
		   @CTEMPDETAILTABLE1=@CSOURCEDB+'ARC_WSL_ORDER_ADV_RECEIPT_UPLOAD',
		   @CTEMPDETAILTABLE2=@CSOURCEDB+'ARC_CMM_CREDIT_RECEIPT_UPLOAD',
		   @CTEMPDETAILTABLE3=@CSOURCEDB+'ARC_ARC_GVSALE_DETAILS_UPLOAD',
		   @CTEMPPAYMODETABLE=@CSOURCEDB+'ARC_PAYMODE_XN_DET_UPLOAD'
	
LBLSTART:

	BEGIN TRANSACTION	

LBLNEXTARC:    
    SELECT @CMEMOID='',@NVERSIONNO=0,@CARCCUSTCODE='',@CREQMEMOID='',@CSEARCHCUSTCODE=''
	
	SET @CSTEP=30
	DECLARE @DFREEZINGDATE DATETIME	
	EXEC SP3S_GETDATA_FREEZING_DATE 'ARC',@DFREEZINGDATE OUTPUT
	
	
	SET @CSTEP=35
	IF EXISTS (SELECT TOP 1 adv_rec_id FROM  ARC_ARC01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
			   AND arc_type=2 AND arct<>1)
		UPDATE ARC_ARC01106_UPLOAD WITH (ROWLOCK) SET arct=1 WHERE sp_id=@nSpId
		AND arc_type=2 AND arct<>1

	SET @CSTEP=40
    SELECT TOP 1 @CMEMOID = B.ADV_REC_ID ,@CARCCUSTCODE=B.CUSTOMER_CODE,@CMEMONO=ADV_REC_NO,
    @NARCT=ARCT,@CLOCID=B.location_Code 
    FROM ARC_ARC01106_UPLOAD B (NOLOCK)
    WHERE  ADV_REC_DT>@DFREEZINGDATE AND B.SP_id =@nSpId 
   

        
    IF ISNULL(@CMEMOID,'')=''
	BEGIN	
		
		SET @CSTEP=50
		SELECT TOP 1 @CREQCUSTCODE=CUSTOMER_CODE FROM CUST_REQ_FROM_LOC (NOLOCK) WHERE DEPT_ID=@CLOCID 
		AND SOURCE_XN_TYPE='ARC' AND ISNULL(PROCESSED,0)=0
	    
		IF ISNULL(@CREQCUSTCODE,'')<>''
		BEGIN
			SET @CERRMSG='SOME CUSTOMER REQUEST DATA FROM LOCATION IS PENDING....CANNOT MERGE'
		END

		GOTO EXIT_PROC
	END

		SET @CSTEP=15
    	
    SELECT TOP 1 @CCURDEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
    
    SELECT TOP 1 @CDONOTRESETPOSTEDINAC=VALUE FROM CONFIG WHERE CONFIG_OPTION='DONOT_RESET_ACCOUNTS_POSTEDINAC'
    
    SET @CDONOTRESETPOSTEDINAC=ISNULL(@CDONOTRESETPOSTEDINAC,'')
		
    DECLARE @CPOSTINGATHODEPTID VARCHAR(5)
    
	SET @DTSQL=N'SELECT TOP 1 @CPOSTINGATHODEPTID=ACCOUNTS_POSTING_DEPT_ID FROM 
				 LOCATION WHERE DEPT_ID='''+@CLOCID+''''
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL,N'@CPOSTINGATHODEPTID CHAR(2) OUTPUT',@CPOSTINGATHODEPTID OUTPUT


	SET @CSTEP=60
	SELECT TOP 1 @CSEARCHCUSTCODE=CUSTOMER_CODE FROM CUSTDYM (NOLOCK) WHERE CUSTOMER_CODE=@CARCCUSTCODE
	IF ISNULL(@CSEARCHCUSTCODE,'')=''
	BEGIN
		SET @CSTEP=65
		IF NOT EXISTS (SELECT TOP 1 CUSTOMER_CODE FROM CUST_REQ_FROM_LOC (NOLOCK) WHERE CUSTOMER_CODE=@CARCCUSTCODE
					   AND DEPT_ID=@CLOCID)	
			AND NOT EXISTS (SELECT TOP 1 CUSTOMER_CODE FROM CUSTDYM F (NOLOCK)
							WHERE CUSTOMER_CODE=@CARCCUSTCODE)							
			BEGIN				
				INSERT CUST_REQ_FROM_LOC ( DEPT_ID, CUSTOMER_CODE, SOURCE_XN_TYPE, PROCESSED, LAST_UPDATE ) 
				SELECT @CLOCID AS DEPT_ID,@CARCCUSTCODE AS CUSTOMER_CODE,'ARC' AS SOURCE_XN_TYPE,0 AS PROCESSED,
				GETDATE() AS LAST_UPDATE 

				SET @CERRMSG='SOME CUSTOMER REQUEST DATA FROM LOCATION IS INSERTED....CANNOT MERGE'

				SET @BCUSTREQINSERTED=1

				GOTO EXIT_PROC
	       END	
	END	
	
	SET @CSTEP=70		
    
    SET @CFILTERCONDITION = 'B.SP_ID='''+@nSpId+''''
	
	
	IF @NARCT<>5	
	BEGIN
		SET @CMEMOPREFIX= LEFT(@CMEMONO,CHARINDEX('-',@CMEMONO))
		SET @NLENVALUE=@NMEMONOLEN-LEN(@CMEMOPREFIX)
	END	
	ELSE
	BEGIN
		SET @CMEMOPREFIX= LEFT(@CMEMONO,4)
		SET @NLENVALUE=6
	END
	
	
	SET @NPREVMEMONO=0
	IF LEN(@CMEMONO)=10
	BEGIN
		SET @NPREVMEMONO=CONVERT(NUMERIC(5,0),RIGHT(@CMEMOID,@NMEMONOLEN-LEN(@CMEMOPREFIX)))
	END
	
	IF @NPREVMEMONO>1
	BEGIN
		SET @CSTEP=75
		SET @NPREVMEMONO=@NPREVMEMONO-1
		
		SELECT @CFINYEAR=FIN_YEAR FROM ARC_ARC01106_upload (NOLOCK) WHERE sp_id=@nSpId 
		
		SET @CPREVMEMONO=@CMEMOPREFIX+REPLICATE('0',@NLENVALUE-LEN(LTRIM(RTRIM(STR(@NPREVMEMONO)))))+LTRIM(RTRIM(STR(@NPREVMEMONO)))
		
		SET @CPREVMEMONOSEARCH=''
		
		SET @CSTEP=80
		SELECT TOP 1 @CPREVMEMONOSEARCH=ADV_REC_NO FROM ARC01106 (NOLOCK) WHERE ADV_REC_NO=@CPREVMEMONO AND FIN_YEAR=@CFINYEAR
		
		IF ISNULL(@CPREVMEMONOSEARCH,'')=''
		BEGIN
			SET @CERRMSG='PREVIOUS MEMO NO. :'+@CPREVMEMONO+' NOT FOUND...CANNOT MERGE'
			SET @BSERIESMISMATCHFOUND=1
			GOTO EXIT_PROC
		END	
	END
	

	SET @CSTEP=85
	SET @CMEMOIDSEARCH=''
	SELECT TOP 1 @CMEMOIDSEARCH=A.ADV_REC_ID FROM ARC01106 A (NOLOCK) WHERE A.ADV_REC_ID=@CMEMOID
	
	IF ISNULL(@CMEMOIDSEARCH,'')<>''
		SET @BADDMODE=0
	ELSE
		SET @BADDMODE=1

	
	IF ISNULL(@CPOSTINGATHODEPTID,'')=@CCURDEPTID AND @BADDMODE=0
	BEGIN
		
		SET @CSTEP=90
		SET @DTSQL=N'UPDATE A SET POSTEDINAC=B.POSTEDINAC FROM '+@CTEMPMASTERTABLE+' A  WITH (ROWLOCK) 
					 JOIN ARC01106 B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID WHERE B.ADV_REC_ID='''+@CMEMOID+''' AND A.SP_ID='''+@nSpId +''''
		PRINT @DTSQL  
		EXEC SP_EXECUTESQL @DTSQL
		
		SET @CSTEP=95
		SET @DTSQL=N'UPDATE B SET POSTEDINAC=0 FROM ARC01106 A (NOLOCK) 
					 JOIN '+@CTEMPMASTERTABLE+' B  WITH (ROWLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
				     WHERE B.ADV_REC_ID='''+@CMEMOID+''' AND A.NET_AMOUNT<>B.NET_AMOUNT OR A.CANCELLED<>B.CANCELLED AND B.SP_ID='''+@nSpId +''''
		PRINT @DTSQL  
		EXEC SP_EXECUTESQL @DTSQL
		
		
		
		IF  @CDONOTRESETPOSTEDINAC<>'1'
		BEGIN
			SET @CSTEP=100
			SET @DTSQL=N'UPDATE A SET POSTEDINAC=0 FROM '+@CTEMPMASTERTABLE+' A  WITH (ROWLOCK) 
						 JOIN (SELECT ISNULL(A.MEMO_ID,B.MEMO_ID) AS MEMO_ID FROM 
							  ( SELECT A.MEMO_ID,A.PAYMODE_CODE,SUM(A.AMOUNT) AS AMOUNT FROM PAYMODE_XN_DET A (NOLOCK)
								JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.MEMO_ID=B.ADV_REC_ID
								WHERE '+@CFILTERCONDITION+' AND A.XN_TYPE=''ARC'' GROUP BY A.MEMO_ID,A.PAYMODE_CODE) A
							   FULL OUTER JOIN 
							  ( SELECT A.MEMO_ID,A.PAYMODE_CODE,SUM(A.AMOUNT) AS AMOUNT FROM '+@CTEMPPAYMODETABLE+' A (NOLOCK)
								JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.MEMO_ID=B.ADV_REC_ID
								WHERE '+@CFILTERCONDITION+' AND A.XN_TYPE=''ARC'' GROUP BY A.MEMO_ID,A.PAYMODE_CODE) B ON A.MEMO_ID=B.MEMO_ID
							   AND A.PAYMODE_CODE=B.PAYMODE_CODE WHERE ISNULL(A.AMOUNT,0)<>ISNULL(B.AMOUNT,0))
							  C ON C.MEMO_ID=A.ADV_REC_ID 
							  WHERE A.SP_ID='''+@nSpId +''''
			PRINT @DTSQL  
			EXEC SP_EXECUTESQL @DTSQL
		END
		
    END

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

		IF EXISTS (SELECT TOP 1 tablename FROM savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nSPID)
			DELETE FROM savetran_updcols_updatestr WITH (ROWLOCK) WHERE sp_id=@nSpId

		INSERT savetran_updcols_updatestr (sp_id,tablename,updatestr)
		SELECT @nSPId as sp_id,tablename,'' from mirrorxnsinfo (NOLOCK)
		WHERE tablename IN ('ARC01106','PAYMODE_XN_DET')


		PRINT 'ADDMODE:N'
		EXEC SP3S_VERIFY_ARCDATA_MERGE_CHANGES
		@cMemoId=@cMemoId,
		@nSpId=@nSpid


		SET @CSTEP=120
		SET @DTSQL=N'DELETE A FROM ARC_GVSALE_DETAILS A  WITH (ROWLOCK) JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
					 WHERE '+@CFILTERCONDITION
		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL


		SET @CSTEP=125
		SET @DTSQL=N'DELETE A FROM CMM_CREDIT_RECEIPT A  WITH (ROWLOCK) JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
					 WHERE '+@CFILTERCONDITION
		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL
		
		
		SET @CSTEP=130
		SET @DTSQL=N'DELETE A FROM WSL_ORDER_ADV_RECEIPT  A  WITH (ROWLOCK) 
					 JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID 
					 where ' +@CFILTERCONDITION
		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL

			SET @CSTEP=130
		SET @DTSQL=N'DELETE A FROM HBD_RECEIPT  A  WITH (ROWLOCK) 
					 JOIN '+@CTEMPMASTERTABLE+' B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
					 where ' +@CFILTERCONDITION
		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL

		SET @CSTEP=30
		SELECT TOP 1 @cMissingRowId=a.row_id FROM PAYMODE_XN_DET A (NOLOCK) 
		LEFT JOIN 
		(SELECT row_id FROM ARC_PAYMODE_XN_DET_UPLOAD B (NOLOCK) WHERE SP_ID=@nSpId AND b.XN_TYPE='ARC') b
		 ON A.row_ID =B.row_ID WHERE A.memo_id =@CMEMOID AND A.XN_TYPE='ARC' AND b.row_id IS NULL


		  			
	
		IF ISNULL(@cMissingRowId,'')<>''
		BEGIN		
			SET @CSTEP=34
			EXEC SP_CHKXNSAVELOG 'WSLMERGE',@CSTEP,0,@CMEMOID,'',1
			
			DELETE A FROM PAYMODE_XN_DET A (NOLOCK) LEFT JOIN 
			(SELECT row_id FROM arc_PAYMODE_XN_DET_UPLOAD B (NOLOCK) WHERE SP_ID=@nSpId AND b.XN_TYPE='ARC') b
			ON A.row_ID =B.row_ID WHERE A.memo_id =@CMEMOID AND a.xn_type='arc' AND b.row_id IS NULL

	    END



	
	END
	
	
	UPDATE ARC_ARC01106_UPLOAD SET PARTY_STATE_CODE='00' WHERE ADV_REC_ID=@CMEMOID AND ISNULL(PARTY_STATE_CODE,'')=''  AND SP_ID=@nSpId
	UPDATE ARC_CUSTDYM_UPLOAD SET CUS_GST_STATE_CODE='00' WHERE ARC_MEMO_ID=@CMEMOID AND ISNULL(CUS_GST_STATE_CODE,'')='' AND SP_ID=@nSpId			 
	
	
	---UPDATING TRANSACTION TABLES
	SET @CSTEP=140
	IF @NARCT=5
	BEGIN
		UPDATE A SET CARD_CODE=(CASE WHEN ISNULL(B.CARD_CODE,'')='' AND ISNULL(A.CARD_CODE,'')<>'' 
								THEN A.CARD_CODE ELSE B.CARD_CODE END),
					 DT_CARD_ISSUE=(CASE WHEN B.DT_CARD_ISSUE='' AND A.DT_CARD_ISSUE<>'' 
								THEN A.DT_CARD_ISSUE ELSE B.DT_CARD_ISSUE END),	
	
					 DT_CARD_EXPIRY=(CASE WHEN B.DT_CARD_EXPIRY='' AND A.DT_CARD_EXPIRY<>'' 
								THEN A.DT_CARD_EXPIRY ELSE B.DT_CARD_EXPIRY END),	
					 CARD_NO=(CASE WHEN B.CARD_NO='' AND A.CARD_NO<>'' 
								THEN A.CARD_NO ELSE B.CARD_NO END)
		FROM CUSTDYM A
		JOIN ARC_custdym_UPLOAD B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE								
		WHERE ARC_MEMO_ID=@CMEMOID AND sp_id=@nSpId
	END
	
	SET @CSTEP=240
	SET @CTABLENAME='CUSTDYM'
	SET @CTMP_TABLENAME='ARC_CUSTDYM_upload'
	SET @CKEYFIELD='CUSTOMER_CODE'
	
	SET @CFILTERCONDITIONCUS=REPLACE(@CFILTERCONDITION,'ADV_REC_ID','ARC_MEMO_ID')
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITIONCUS,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=0,@BUPDATEXNS=0
					  	
	SET @CSTEP=250
	SET @CTABLENAME='ARC01106'
	SET @CTMP_TABLENAME='ARC_ARC01106_upload'
	SET @CKEYFIELD='ADV_REC_ID'
	
	SET @DTSQL = N'UPDATE '+@CSOURCEDB+@CTMP_TABLENAME+'  WITH (ROWLOCK) SET ADV_REC_DT = CONVERT(DATETIME,CONVERT(VARCHAR(10),ADV_REC_DT,120)),
				   SHIFT_ID=(CASE WHEN SHIFT_ID='''' THEN NULL ELSE SHIFT_ID END)
				    ,HSN_CODE=(CASE WHEN ISNULL(HSN_CODE,'''')='''' THEN ''0000000000'' ELSE HSN_CODE END)
				     WHERE ADV_REC_ID='''+@CMEMOID+''' and sp_id='''+@nSpId +''''
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL
	
	SET @CSTEP=260

	SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nspid and Tablename='arc01106'
	SET @LUPDATEONLY = (CASE WHEN @BADDMODE=0 THEN 1 ELSE 0 END)	
	
	
	
	EXEC UPDATEMASTERXN_OPT @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=@BADDMODE,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=@LUPDATEONLY
							  ,@BALWAYSUPDATE=1,@lUPDATEXNS=@bAddmode,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1 
	
	

	SET @CTABLENAME='CMM_CREDIT_RECEIPT'
	SET @CTMP_TABLENAME='ARC_CMM_CREDIT_RECEIPT_upload'
	SET @CKEYFIELD='ADV_REC_ID'
	 
	SET @CSTEP=280
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1,@BUPDATEXNS=1 


	IF EXISTS (SELECT TOP 1 memo_id FROM ARC_PAYMODE_XN_DET_UPLOAD (NOLOCK) WHERE sp_id=@nSpId)
	BEGIN
		SET @cStep=51


		SET @CTABLENAME='PAYMODE_XN_DET'
		SET @CTMP_TABLENAME='ARC_PAYMODE_XN_DET_UPLOAD'
		SET @CKEYFIELD='MEMO_ID'

		SELECT @CFILTERCONDITION2=REPLACE(@CFILTERCONDITION,'adv_rec_id','MEMO_ID')+' AND B.XN_TYPE=''arc'''
		   
		SELECT @cMissingRowId='',@lUpdateonly=0
		IF @BADDMODE=0
		BEGIN
			SET @CSTEP=55
			EXEC SP_CHKXNSAVELOG 'arcMERGE',@CSTEP,0,@CMEMOID,'',1

			SELECT TOP 1 @cMissingRowId=b.row_id FROM 
			(SELECT row_id  FROM arc_PAYMODE_XN_DET_UPLOAD (NOLOCK) WHERE SP_ID=(LEFT(@nSPId,38)+@CLOCID )) A
			RIGHT OUTER JOIN 
			(SELECT row_id FROM ARC_PAYMODE_XN_DET_UPLOAD (NOLOCK) WHERE SP_ID=@nSPId) b ON 
			a.row_id=b.row_id WHERE a.row_id IS NULL

			--SELECT 'check @cMissingRowId of pid',@cMissingRowId

			IF ISNULL(@cMissingRowId,'')='' 
				SET @lUpdateonly=1
		END

		SET @CSTEP=58

		SELECT @cUpdatestr=updatestr FROM  savetran_updcols_updatestr (NOLOCK) WHERE sp_id=@nspid and tablename='PAYMODE_XN_DET'	

		EXEC updatemasterxn_opt @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
								  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1='row_id',@CKEYFIELD2='',@CKEYFIELD3=''
								  ,@LINSERTONLY=@bAddmode,@CFILTERCONDITION=@CFILTERCONDITION2,@LUPDATEONLY=@lUpdateonly
								  ,@BALWAYSUPDATE=1,@lUPDATEXNS=@bAddmode,@cUpdatestrPara=@cUpdatestr,@bThruUpdatestrPara=1 	
	END						  
				

	SET @CSTEP=300	
	SET @CTABLENAME='WSL_ORDER_ADV_RECEIPT'
	SET @CTMP_TABLENAME='ARC_WSL_ORDER_ADV_RECEIPT_upload'
	SET @CKEYFIELD='ADV_REC_ID'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 					  
	
	SET @CSTEP=310
	SET @CTABLENAME='ARC_GVSALE_DETAILS'
	SET @CTMP_TABLENAME='ARC_ARC_GVSALE_DETAILS_upload'
	SET @CKEYFIELD='ADV_REC_ID'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=0 							  
	
	
	SET @CSTEP=320
	SET @CTABLENAME='hbd_receipt'
	SET @CTMP_TABLENAME='ARC_hbd_receipt_upload'
	SET @CKEYFIELD='ADV_REC_ID'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=0 	

	SET @CSTEP=320
	UPDATE A SET DT_EXPIRY=DATEADD(DD,A.VALIDITY_DAYS,C.ADV_REC_DT) FROM SKU_GV_MST A  WITH (ROWLOCK) 
	JOIN ARC_GVSALE_DETAILS B (NOLOCK)ON A.GV_SRNO=B.GV_SRNO 
	JOIN ARC01106 C (NOLOCK)ON C.ADV_REC_ID=B.ADV_REC_ID
	WHERE B.ADV_REC_ID=@CMEMOID
	
		 
	 INSERT MIRROR_SYNCH_LOG (XN_TYPE,DEPT_ID,MEMO_ID,ERRMSG,LAST_UPDATE)
	 SELECT 'ARC',@CLOCID  AS DEPT_ID,A.ADV_REC_ID,
	 'NET AMOUNT :'+LTRIM(RTRIM(STR(A.NET_AMOUNT,14,2)))+' SHOULD BE EQUAL TO THE SUM OF ALL PAYMENT MODES :'+LTRIM(RTRIM(STR(ISNULL(B.AMOUNT,0),14,2))),
	 GETDATE() AS LAST_UPDATE
	 FROM ARC01106 A (NOLOCK)
	 LEFT OUTER JOIN
	 (SELECT A.MEMO_ID,SUM(A.AMOUNT) AS AMOUNT   FROM PAYMODE_XN_DET A 
	    JOIN ARC01106 C ON C.ADV_REC_ID=A.MEMO_ID
	   WHERE MEMO_ID = @CMEMOID AND XN_TYPE = 'ARC' AND (ARC_TYPE<>2 OR ISNULL(A.ADJ_MEMO_ID,'')='')
	   GROUP BY A.MEMO_ID) B ON A.ADV_REC_ID=B.MEMO_ID
	   WHERE A.ADV_REC_ID=@CMEMOID AND A.NET_AMOUNT<>ISNULL(B.AMOUNT,0) 
	   and A.cancelled =0
	  
	 
    
    SET @CSTEP=330
    SELECT TOP 1 @CERRMSG=ERRMSG FROM MIRROR_SYNCH_LOG (NOLOCK) WHERE XN_TYPE='ARC' AND MEMO_ID=@CMEMOID
    
	
   

END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP3S_SYNCH_UPLOADDATA_ARC_OPT, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:

	IF @@TRANCOUNT>0
	BEGIN
		IF (ISNULL(@CERRMSG,'')='' AND @BSERIESMISMATCHFOUND<>1) OR (ISNULL(@CERRMSG,'')<>'' AND ISNULL(@BCUSTREQINSERTED,0)=1) 
			COMMIT
		ELSE
			ROLLBACK
    END


	DECLARE @nSpidCopy VARCHAR(50)
	SET @nSpIdCopy=LEFT(@nSPId,38)+@CLOCID 
	
	EXEC SP3S_DELETE_UPLOAD_ARCMERGE_TABLES @nSpId

	IF @bAddmode=0
		EXEC SP3S_DELETE_UPLOAD_ARCMERGE_TABLES @nSpIdCopy

	IF @BSERIESMISMATCHFOUND=1
	BEGIN

		IF OBJECT_ID('TEMPDB..#TMPXNSREQ','U') IS NOT NULL
			DROP TABLE #TMPXNSREQ
		
		SELECT XN_ID,XN_TYPE,DEPT_ID INTO #TMPXNSREQ FROM XNS_REQ_FROM_LOC WHERE 1=2	
		

		DECLARE @CPREVMEMOID VARCHAR(22)
		---- REMOVED THE CHECK OF COMPLETE SERIES AS TOLD BY SIR ON 22-07-2017
		---- WE SHOULD CHECK FOR LAST MEMO NO ONLY
		SET @CPREVMEMOID = @CLOCID+@CFINYEAR+REPLICATE('0',5)+@CPREVMEMONO

		INSERT #TMPXNSREQ (XN_ID,XN_TYPE,DEPT_ID)
		SELECT @CPREVMEMOID,'ARC' AS XN_TYPE,LEFT(@CPREVMEMOID,2) AS DEPT_ID			

		INSERT XNS_REQ_FROM_LOC ( XN_TYPE, XN_ID,MODE,DEPT_ID, REMARKS ) 
		SELECT  'ARC' AS XN_TYPE, @CPREVMEMOID AS XN_ID,0 AS MODE,@CLOCID  AS DEPT_ID,'' AS REMARKS
		FROM #TMPXNSREQ A 
		LEFT OUTER JOIN XNS_REQ_FROM_LOC B ON A.DEPT_ID=B.DEPT_ID AND A.XN_ID=B.XN_ID AND A.XN_TYPE=B.XN_TYPE 
		WHERE B.XN_ID IS NULL 
				
	END
	
END	
---END OF PROCEDURE - SP3S_SYNCH_UPLOADDATA_ARC_OPT
