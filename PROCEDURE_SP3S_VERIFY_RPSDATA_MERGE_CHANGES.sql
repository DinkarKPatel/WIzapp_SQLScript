CREATE PROCEDURE SP3S_VERIFY_RPSDATA_MERGE_CHANGES
@NSPID VARCHAR(50),
@cMemoId VARCHAR(40)
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500)
	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.cm_id='''+@cMemoId+''''
	set @CINSSPID=LEFT(@nSPId,38)+LEFT(@cMemoId,2)
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='RPS_MST',@CDESTDB=''
								,@CDESTTABLE='RPS_RPS_MST_UPLOAD',@CKEYFIELD1='CM_ID',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUpdateXns=1,@CINSSPID=@cInSSPId,@CSEARCHTABLE='RPS_MST'

	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='RPS_MST',
	@cUploadTableName='RPS_RPS_MST_UPLOAD',
	@cKeyfield='CM_ID'


	PRINT 'g en tempdata for 3'
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='RPS_DET',@CDESTDB=''
								,@CDESTTABLE='rps_rps_DET_UPLOAD',@CKEYFIELD1='CM_ID',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='RPS_DET',@cXnType='RPS'
	


	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='rps_det',
	@cUploadTableName='rps_rps_det_UPLOAD',
	@cKeyfield='row_id',
	@bDonotChkLastUpdate=1

END