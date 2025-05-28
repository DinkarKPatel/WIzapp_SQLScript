create PROCEDURE SP3S_VERIFY_WSLORDDATA_CHANGES
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
		   @cSpIdCol=(CASE WHEN @bCalledfromSavetran=1 THEN 'sp_id' ELSE 'order_id' END),
		   @CINSSPIDCol=(CASE WHEN @bCalledfromSavetran=1 THEN '' ELSE 'order_id' END),
		   @cSpId=(CASE WHEN @bCalledfromSavetran=1 THEN @nSpId ELSE @cMemoId END)

	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.order_id='''+@cMemoId+''''

	IF @bCalledfromSavetran=1
		set @CINSSPID=LEFT(@nSpId,38)+LEFT(@cMemoId,2)
	ELSE
		set @CINSSPID=@cMemoId+LEFT(@cMemoId,2)

	SELECT @cUploadTableName='WSLORD_BUYER_ORDER_MST_'+@cSuffix
			
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='BUYER_ORDER_MST',@CDESTDB=''
								,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='ORDER_ID',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol
								,@CSEARCHTABLE='BUYER_ORDER_MST',@cXnType='WSLORD'
	
	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@cSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='BUYER_ORDER_MST',
	@cUploadTableName=@cUploadTableName,
	@cKeyfield='ORDER_ID',
	@cSpIdCol=@cSpIdCol,
	@bUpdSavetranTable=1
	
	SELECT @cUploadTableName='WSLORD_BUYER_ORDER_DET_'+@cSuffix
		
		---Do not change this code it handles Scenario mentioned as prt#1 in File doc_scenarios
		PRINT 'gen tempdata for 3'
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='BUYER_ORDER_DET',@CDESTDB=''
									,@CDESTTABLE=@cUploadTableName,@CKEYFIELD1='ORDER_ID',@CKEYFIELD2='',@CKEYFIELD3=''
									,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0,@cXnType='WSLORD'
									,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=@CINSSPIDCol,@CSEARCHTABLE='BUYER_ORDER_DET'	
	
		PRINT 'gen tempdata for 4'
		EXEC SP3S_GENFILTERED_UPDATESTR
		@cSpId=@cSpId ,
		@cInsSpId=@cInsSpId,
		@cTableName='BUYER_ORDER_DET',
		@cUploadTableName=@cUploadTableName,
		@cKeyfield='row_id',
		@cSpIdCol=@cSpIdCol,
		@bDonotChkLastUpdate=1,
		@bUpdSavetranTable=1



END