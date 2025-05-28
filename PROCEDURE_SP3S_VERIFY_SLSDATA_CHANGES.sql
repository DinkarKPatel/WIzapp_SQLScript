CREATE PROCEDURE SP3S_VERIFY_SLsDATA_CHANGES
@cMemoId VARCHAR(40),
@nSpId VARCHAR(50)=''
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200),@cSpIdCol VARCHAR(100),@CINSSPIDCol VARCHAR(200),
	@cSpId VARCHAR(50)

	SELECT @cSuffix='UPLOAD',@cSpIdCol='sp_id',@CINSSPIDCol='',@cSpId= @nSpId

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.cm_id='''+@cMemoId+''''

	set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)

	SELECT @cUploadTableName='sls_cmm01106_'+@cSuffix
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='cmm01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='cm_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='cmm01106',@cXnType='SLS'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='cmm01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='cm_id',
	@cSpIdCol=@cSpIdCol,
	@bUpdSavetranTable=1
	
	SELECT @cUploadTableName='sls_cmd01106_'+@cSuffix
	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='cmd01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='cm_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='SLS'
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='cmd01106'	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='CMd01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@cSpIdCol=@cSpIdCol,
	@bDonotChkLastUpdate=1,
	@bUpdSavetranTable=1


	SELECT @CFILTERCONDITION=' b.memo_id='''+@cMemoId+''' AND xn_type=''SLS''',
		   @cUploadTableName='sls_paymode_xn_det_'+@cSuffix,
		   @CINSSPIDCol=''
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='paymode_xn_det',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='row_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='paymode_xn_det',@cXnType='SLS'	

	SET @cSpIdCol='sp_id'

	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='paymode_xn_det',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@cSpIdCol=@cSpIdCol,
	@bDonotChkLastUpdate=1,
	@bUpdSavetranTable=1
	
END