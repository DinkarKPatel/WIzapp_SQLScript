create PROCEDURE SP3S_VERIFY_PRTDATA_CHANGES
@cMemoId VARCHAR(40)='',
@nSpId VARCHAR(50)='',
@BBYPASSDETINSERT BIT
AS
BEGIN
	print 'enter verify_prtdata'
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200),@cSpIdCol VARCHAR(100),@CINSSPIDCol VARCHAR(200),
	@cSpId VARCHAR(50)

	SELECT @cSuffix='UPLOAD',
		   @cSpIdCol= 'sp_id' ,
		   @CINSSPIDCol='',
		   @cSpId= @nSpId 

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.rm_id='''+@cMemoId+''''

	
	set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)
	

	SELECT @cUploadTableName='prt_rmm01106_'+@cSuffix
	
	---Scenario mentioned as prt#1 in File doc_scenarios
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='rmm01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='rm_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='rmm01106',@cXnType='PRT'


	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='rmm01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='rm_id',
	@cSpIdCol=@cSpIdCol,
	@bUpdSavetranTable=1

	

	SELECT @cUploadTableName='prt_rmd01106_'+@cSuffix

	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='rmd01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='rm_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='PRT'
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='rmd01106'	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='rmd01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@cSpIdCol=@cSpIdCol,
	@bDonotChkLastUpdate=1,
	@bUpdSavetranTable=1

END