CREATE PROCEDURE SP3S_VERIFY_RPSDATA_CHANGES
@cMemoId VARCHAR(40)='',
@nSpId VARCHAR(50)=''
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
	SET @CFILTERCONDITION=' b.cm_id='''+@cMemoId+''''

	
	set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)
	

	SELECT @cUploadTableName='rps_rps_mst_'+@cSuffix
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='rps_mst',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='cm_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='rps_mst',@cXnType='RPS'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='rps_mst',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='cm_id',
	@cSpIdCol=@cSpIdCol
	
	SELECT @cUploadTableName='rps_RPS_DET_'+@cSuffix

	
	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='rps_det',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='cM_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WPS'
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='rps_det'	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='rps_det',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='row_id',
	@cSpIdCol=@cSpIdCol,
	@bDonotChkLastUpdate=1
END