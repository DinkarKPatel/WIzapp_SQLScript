CREATE PROCEDURE SP3S_VERIFY_WSLDATA_CHANGES
@cMemoId VARCHAR(40)='',
@nSpId VARCHAR(50)='',
@BBYPASSDETINSERT BIT=0,
@bCalledfromSavetran BIT=0
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200),@cSpIdCol VARCHAR(100),@CINSSPIDCol VARCHAR(200),
	@cSpId VARCHAR(50)

	SELECT @cSuffix=(CASE WHEN @bCalledfromSavetran=1 THEN 'UPLOAD' ELSE 'MIRROR' END),
		   @cSpIdCol=(CASE WHEN @bCalledfromSavetran=1 THEN 'sp_id' ELSE 'inv_id' END),
		   @CINSSPIDCol=(CASE WHEN @bCalledfromSavetran=1 THEN '' ELSE 'inv_id' END),
		   @cSpId=(CASE WHEN @bCalledfromSavetran=1 THEN @nSpId ELSE @cMemoId END)

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.inv_id='''+@cMemoId+''''

	IF @bCalledfromSavetran=1
		set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)
	ELSE
		set @CINSSPID=@cMemoId+LEFT(@cMemoId,2)

	SELECT @cUploadTableName='wsl_inm01106_'+@cSuffix
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='inm01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='inv_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='inm01106',@cXnType='WSL'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='inm01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='inv_id',
	@cSpIdCol=@cSpIdCol,
	@bUpdSavetranTable=1
	
	SELECT @cUploadTableName='wsl_ind01106_'+@cSuffix
		
		---Do not change this code it handles Scenario mentioned as prt#1 in File doc_scenarios
		PRINT 'gen tempdata for 3'
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='ind01106',@CDESTDB=''
									,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='inv_id',@CKEYFIELD2='',@CKEYFIELD3=''
									,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSL'
									,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='ind01106'	
	
		PRINT 'gen tempdata for 4'
		EXEC SP3S_GENFILTERED_UPDATESTR
		@cSpId=@cSpId ,
		@cInsSpId=@cInsSpId,
		@cTableName='ind01106',
		@cUploadTableName=@cUploadTableName,
		@cKeyfield='row_id',
		@cSpIdCol=@cSpIdCol,
		@bDonotChkLastUpdate=1,
		@bUpdSavetranTable=1



	SELECT @CFILTERCONDITION=' b.memo_id='''+@cMemoId+''' AND xn_type=''WSL''',
		   @cUploadTableName='wsl_paymode_xn_det_'+@cSuffix,
		   @CINSSPIDCol=(CASE WHEN @bCalledfromSavetran=1 THEN '' ELSE 'memo_id' END)
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='paymode_xn_det',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='row_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='paymode_xn_det',@cXnType='WSL'	

	SET @cSpIdCol=(CASE WHEN @bCalledfromSavetran=1 THEN 'sp_id' ELSE 'memo_id' END)

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