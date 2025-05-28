create PROCEDURE SP3S_VERIFY_WSLDATA_MERGE_CHANGES
@nSpId VARCHAR(50),
@cMemoId VARCHAR(40)
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200),@nSpIdCol VARCHAR(100)

	SELECT @cSuffix='upload' ,@nSpIdCol='inv_id'

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.inv_id='''+@cMemoId+''''
	set @CINSSPID=LEFT(@nSPId,38)+LEFT(@cMemoId,2)

	SELECT @cUploadTableName='wsl_inm01106_'+@cSuffix
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='inm01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='inv_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='inm01106',@cXnType='WSL'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='inm01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='inv_id',
	@bDonotChkLastUpdate=0
	
	
	SELECT @cUploadTableName='wsl_ind01106_'+@cSuffix

	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='ind01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='inv_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSL'
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='ind01106'	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='ind01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@bDonotChkLastUpdate=1
	
	DECLARE @cParcelMemoId VARCHAR(50)
	SELECT @cParcelMemoId=parcel_memo_id FROM wsl_parcel_det_upload (NOLOCK) WHERE sp_id=@nSpId
	
	set @cParcelMemoId=ISNULL(@cParcelMemoId,'')

	SET @CFILTERCONDITION=' b.parcel_memo_id='''+@cParcelMemoId+''''

	SELECT @cUploadTableName='WSL_PARCEL_MST_'+@cSuffix,@nSpIdCol='parcel_memo_id'

	PRINT 'gen tempdata for 3:'+@cParcelMemoId
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='PARCEL_MST',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='PARCEL_MEMO_ID',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSL'
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='PARCEL_mst'	
	
	PRINT 'gen tempdata for 4:'+@cParcelMemoId
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='PARCEL_MST',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='PARCEL_MEMO_ID',
	@bDonotChkLastUpdate=1


	
	SELECT @cUploadTableName='WSL_PARCEL_DET_'+@cSuffix

	PRINT 'gen tempdata for 5:'+@cParcelMemoId
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='PARCEL_DET',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='PARCEL_MEMO_ID',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSL'
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='PARCEL_det'	
	
	PRINT 'gen tempdata for 6:'+@cParcelMemoId
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='PARCEL_DET',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='ROW_ID',
	@bDonotChkLastUpdate=1		
	

	SELECT @CFILTERCONDITION=' b.memo_id='''+@cMemoId+''' AND xn_type=''WSL''',
		   @cUploadTableName='wsl_paymode_xn_det_'+@cSuffix
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='paymode_xn_det',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='row_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID
								,@CSEARCHTABLE='paymode_xn_det',@cXnType='WSL'	

	SET @nSpIdCol='memo_id'

	PRINT 'gen tempdata for 7'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='paymode_xn_det',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@bDonotChkLastUpdate=1

END