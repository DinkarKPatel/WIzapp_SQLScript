
create PROCEDURE SP3S_VERIFY_WSRDATA_CHANGES
@cMemoId VARCHAR(40)='',
@nSpId VARCHAR(50)='',
@BBYPASSDETINSERT BIT
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200),@cSpIdCol VARCHAR(100),@CINSSPIDCol VARCHAR(200),
	@cSpId VARCHAR(50)

	SELECT @cSuffix='UPLOAD',
		   @cSpIdCol= 'sp_id' ,
		   @CINSSPIDCol='',
		   @cSpId= @nSpId 

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.cn_id='''+@cMemoId+''''

	
	set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)
	

	SELECT @cUploadTableName='wsr_cnm01106_'+@cSuffix
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='cnm01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='cn_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='cnm01106',@cXnType='WSR'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='cnm01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='cn_id',
	@cSpIdCol=@cSpIdCol,
	@bUpdSavetranTable=1
	
	IF @BBYPASSDETINSERT=1
		RETURN

	SELECT @cUploadTableName='wsr_cnd01106_'+@cSuffix

	
	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='cnd01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='cn_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSR'
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='cnd01106'	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='cnd01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@cSpIdCol=@cSpIdCol,
	@bDonotChkLastUpdate=1,
	@bUpdSavetranTable=1




	SELECT @cUploadTableName='wsr_Paymode_xn_det_'+@cSuffix

	SET @CFILTERCONDITION=' b.memo_id='''+@cMemoId+''' and b.xn_type=''wsr'' '
	
	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='Paymode_xn_det',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='memo_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSR'
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='Paymode_xn_det'	
	
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

