CREATE PROCEDURE SP3S_VERIFY_PODATA_CHANGES
@cMemoId VARCHAR(40),
@nSpId VARCHAR(50),
@bCalledfromSavetran BIT=0
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200)

	SET @cSuffix=(CASE WHEN @bCalledfromSavetran=1 THEN 'UPLOAD' ELSE 'MIRROR' END)

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.po_id='''+@cMemoId+''''
	set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)

	SELECT @cUploadTableName='po_pom01106_'+@cSuffix
	

	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='pom01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='po_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='pom01106'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='pom01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='po_id',
	@bDonotChkLastUpdate=1
	

	SELECT @cUploadTableName='po_pod01106_'+@cSuffix
	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='pod01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='po_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='pod01106'	
	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='pod01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@bDonotChkLastUpdate=1,
	@cSkipCols='auto_srno'

	
END