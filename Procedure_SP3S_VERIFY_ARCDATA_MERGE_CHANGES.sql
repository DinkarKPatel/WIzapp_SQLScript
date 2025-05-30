CREATE PROCEDURE SP3S_VERIFY_ARCDATA_MERGE_CHANGES
@nSpId VARCHAR(50),
@cMemoId VARCHAR(40)
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500),@cSuffix VARCHAR(20),
	@CDESTTABLE VARCHAR(200),@cUploadTableName VARCHAR(200),@nSpIdCol VARCHAR(100)

	SELECT @cSuffix='upload' ,@nSpIdCol='ADV_REC_ID'

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.ADV_REC_ID='''+@cMemoId+''''
	set @CINSSPID=LEFT(@nSPId,38)+LEFT(@cMemoId,2)

	SELECT @CUPLOADTABLENAME='ARC_ARC01106_'+@CSUFFIX
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='ARC01106',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='ADV_REC_ID',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='ARC01106',@cXnType='arc'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='ARC01106',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='ADV_REC_ID',
	@bDonotChkLastUpdate=0
	


	SELECT @CFILTERCONDITION=' b.memo_id='''+@cMemoId+''' AND xn_type=''arc''',
		   @cUploadTableName='ARC_PAYMODE_XN_DET_'+@cSuffix
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='paymode_xn_det',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='row_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID
								,@CSEARCHTABLE='paymode_xn_det',@cXnType='arc'	

	SET @nSpIdCol='memo_id'

	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='paymode_xn_det',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@bDonotChkLastUpdate=1
	
END