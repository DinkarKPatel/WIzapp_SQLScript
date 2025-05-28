CREATE PROCEDURE SP3S_VERIFY_PURDATA_MERGE_CHANGES
@nSpId VARCHAR(50),
@cMemoId VARCHAR(40)
AS
BEGIN
	
	DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(40),@CJOINSTR VARCHAR(500)
	PRINT 'gen tempdata for 1'
	SET @CFILTERCONDITION=' b.mrr_id='''+@cMemoId+''''
	set @CINSSPID=LEFT(@nSPId,38)+LEFT(@cMemoId,2)
	

	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='pim01106',@CDESTDB=''
								,@CDESTTABLE='pur_pim01106_upload',@CKEYFIELD1='mrr_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUpdateXns=1,@CINSSPID=@cInSSPId,@CSEARCHTABLE='PIm01106'

	PRINT 'gen tempdata for 2'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='pim01106',
	@cUploadTableName='pur_pim01106_upload',
	@cKeyfield='mrr_id',
	@bDonotChkLastUpdate=0
	


	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='pid01106',@CDESTDB=''
								,@CDESTTABLE='pur_pid01106_upload',@CKEYFIELD1='mrr_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUpdateXns=1,@CINSSPID=@cInsSPId,@CSEARCHTABLE='pid01106'
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='pid01106',
	@cUploadTableName='pur_pid01106_upload',
	@cKeyfield='row_id',
	@bDonotChkLastUpdate=1

	SELECT @CFILTERCONDITION=' c.mrr_id='''+@cMemoId+'''',
			@CJOINSTR=' JOIN pid01106 c ON c.product_code=b.product_code '
	PRINT 'gen tempdata for 3'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='sku',@CDESTDB=''
								,@CDESTTABLE='pur_sku_upload',@CKEYFIELD1='sp_id',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUpdateXns=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='sku',@CJOINSTR=@CJOINSTR	
	
	PRINT 'gen tempdata for 4'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId ,
	@cInsSpId=@cInsSpId,
	@cTableName='sku',
	@cUploadTableName='pur_sku_upload',
	@cKeyfield='product_code',
	@bDonotChkLastUpdate=1
	
PRINT 'gen tempdata for 13'
	SET @CFILTERCONDITION=' b.memono='''+@cMemoId+''' AND b.MODULENAME=''frmTranPurchaseInvoice'''

	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='DAILOGFILE',@CDESTDB=''
								,@CDESTTABLE='pur_DAILOGFILE_upload',@CKEYFIELD1='memono',@CKEYFIELD2='',@CKEYFIELD3=''
								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
								,@BALWAYSUPDATE=0,@bUpdateXns=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='DAILOGFILE'

								PRINT 'gen tempdata for 14'
	EXEC SP3S_GENFILTERED_UPDATESTR
	@cSpId=@nSpId,
	@cInsSpId=@cInsSpId,
	@cTableName='DAILOGFILE',
	@cUploadTableName='pur_DAILOGFILE_upload',
	@cKeyfield='ROWID',
	@bDonotChkLastUpdate=1
END