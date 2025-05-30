CREATE PROCEDURE SPSIS_SYNCH_UPLOADDATA_APR_OPT
(
    @NSPID VARCHAR(50),
	@CDEPTID VARCHAR(5)/*Rohit 01-11-2024*/,
   @CERRMSG VARCHAR(1000) OUTPUT
)
AS
SET NOCOUNT ON
BEGIN
	
DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(MAX),@CCMD NVARCHAR(MAX),@CSOURCEDB VARCHAR(10),
		@CMERGEDB VARCHAR(10),@BMSTINSERTONLY BIT,@CMEMOID VARCHAR(50),@BCANCELLED BIT,
		@BADDMODE BIT

BEGIN TRY

SET @CSTEP=20
	SET @CTABLE_SUFFIX='UPLOAD'
BEGIN TRANSACTION 
    
	SELECT @CSOURCEDB='',@CMERGEDB=''

	
	UPDATE A SET 
	             AC_CODE ='0000000000',
				 CUSTOMER_CODE='000000000000',
				 USER_CODE ='0000000',
				 BIN_ID='000',
				 MEMO_ID=@CDEPTID+SUBSTRING(MEMO_ID,LEN(@CDEPTID)+1,LEN(MEMO_ID))/*Rohit 01-11-2024*/ ,
				 MEMO_NO=@CDEPTID+SUBSTRING(MEMO_NO,LEN(@CDEPTID)+1,LEN(MEMO_NO))/*Rohit 01-11-2024*/,
				 MODE=1,
				 dept_id=@CDEPTID,
				 location_Code =@CDEPTID
	FROM APR_APPROVAL_RETURN_MST_UPLOAD A (NOLOCK)
	WHERE SP_ID =@nSpId

	UPDATE A SET BIN_ID ='000',
	          MEMO_ID=@CDEPTID++SUBSTRING(MEMO_ID,LEN(@CDEPTID)+1,LEN(MEMO_ID)) /*Rohit 01-11-2024*/,
			  emp_code ='0000000'
	FROM APR_APPROVAL_RETURN_DET_UPLOAD A (NOLOCK)
	WHERE SP_ID =@nSpId

	
	 UPDATE A SET APD_PRODUCT_CODE=LEFT(A.APD_PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.APD_PRODUCT_CODE)-1,-1),LEN(A.APD_PRODUCT_CODE )))  
	 FROM APR_APPROVAL_RETURN_DET_UPLOAD A (NOLOCK)	WHERE SP_ID=@NSPID
	 AND CHARINDEX('@',APD_PRODUCT_CODE)<>0

    
	SELECT TOP 1 @CMEMOID = B.MEMO_ID ,@BCANCELLED=CANCELLED 
    FROM APR_APPROVAL_RETURN_MST_UPLOAD B (NOLOCK)
	WHERE SP_ID=@nSpId
   
   
    IF ISNULL(@CMEMOID,'')=''
		GOTO EXIT_PROC
		

	DECLARE @CMEMOIDSEARCH VARCHAR(100)
	SELECT TOP 1 @CMEMOIDSEARCH=A.MEMO_ID FROM APPROVAL_RETURN_MST A (NOLOCK) WHERE A.MEMO_ID=@CMEMOID
	
	
	IF ISNULL(@CMEMOIDSEARCH,'')<>''
		SET @BADDMODE=0
	ELSE
		SET @BADDMODE=1

	IF @BADDMODE=1 AND NOT EXISTS (SELECT TOP 1 'U' FROM APR_APPROVAL_RETURN_DET_UPLOAD WHERE SP_ID =@NSPID)
	    GOTO EXIT_PROC
    IF @BADDMODE=0 AND NOT EXISTS (SELECT TOP 1 'U' FROM APR_APPROVAL_RETURN_DET_UPLOAD WHERE SP_ID =@NSPID)
		 SET @BCANCELLED=1
    
	IF @BADDMODE=0
	BEGIN	
		
		 INSERT SAVETRAN_BARCODE_NETQTY	( BIN_ID, DEPT_ID, PRODUCT_CODE, sp_id, XN_QTY ) 
		 SELECT 	'000'  BIN_ID,/*LEFT(A.memo_id,2)*//*Rohit 01-11-2024*/@CDEPTID DEPT_ID, apd_PRODUCT_CODE,@nSpId SP_ID,-1*A.quantity AS XN_QTY 
		 FROM approval_return_det A (NOLOCK)
		 WHERE A.memo_id =@CMEMOID


		 IF @bCancelled=1 
		BEGIN
			UPDATE approval_return_mst WITH (ROWLOCK) SET cancelled=1 WHERE MEMO_ID=@cMemoid
			GOTO lblupdatepmt
		END

		SET @CSTEP=30
		SET @CTABLENAME='APPROVAL_RETURN_DET'
		SET @CTMP_TABLENAME='APR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
		SET @CKEYFIELD='MEMO_ID'
		SET @CSTEP=90
		SET @DTSQL=N'DELETE '+@CMERGEDB+'['+@CTABLENAME+'] WITH (ROWLOCK) WHERE '+@CKEYFIELD+'='''+@CMEMOID+''''
		PRINT @DTSQL
		EXEC SP_EXECUTESQL @DTSQL

	END

   
	
	
    SET @CFILTERCONDITION = ' B.SP_ID='''+LTRIM(RTRIM((@NSPID )))+''''
	
							  
	SET @CSTEP=220
	SET @CTABLENAME='APPROVAL_RETURN_MST'
	SET @CTMP_TABLENAME='APR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='MEMO_ID'
	SET @CSTEP=230
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
      SELECT a.APD_product_code as new_product_code into #tmpbarcode FROM APR_APPROVAL_RETURN_DET_UPLOAD A (NOLOCK)
	  LEFT JOIN SKU B (nolock) ON A.APD_product_code =B.PRODUCT_CODE 
	  WHERE A.SP_ID=@nSpId AND B.PRODUCT_CODE IS NULL
	  group by a.APD_product_code

		IF EXISTS (SELECT TOP 1 'U' FROM #tmpbarcode)
		BEGIN
			SET @CSTEP=84.2
			EXEC SP_CHKXNSAVELOG 'apRMERGE',@CSTEP,0,@nSpId,'',1

			 EXEC SPSIS_INSERTSKUBARCODE @NSPID, 'apr',@CERRMSG OUTPUT

			 IF ISNULL(@CERRMSG,'')<>''
			    GOTO EXIT_PROC

          end



							  
    SET @CSTEP=240
	SET @CTABLENAME='APPROVAL_RETURN_DET'
	SET @CTMP_TABLENAME='APR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='ROW_ID'
	SET @CSTEP=250
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1,@BUPDATEXNS=1 							  							  						  							  
							  

	SET @CSTEP=260 


	   INSERT SAVETRAN_BARCODE_NETQTY	( BIN_ID, DEPT_ID, PRODUCT_CODE, sp_id, XN_QTY ) 
		 SELECT 	'000'  BIN_ID,/*LEFT(A.memo_id,2)*//*Rohit 01-11-2024*/@CDEPTID DEPT_ID, apd_PRODUCT_CODE,@nSpId SP_ID,A.quantity AS XN_QTY 
		 FROM approval_return_det A (NOLOCK)
		 WHERE A.memo_id =@CMEMOID

	lblupdatepmt:
	EXEC SPSIS_UPDATEPMT @NSPID



	

END TRY
BEGIN CATCH
	SET @CERRMSG='P:SPSIS_SYNCH_UPLOADDATA_APR_OPT, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
END CATCH
EXIT_PROC:
	

	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0
	BEGIN
		COMMIT
	END
	ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0
		ROLLBACK

	DELETE A FROM APR_APPROVAL_RETURN_DET_UPLOAD A WITH (ROWLOCK) WHERE A.SP_ID=@nSpId 
	DELETE A FROM APR_APPROVAL_RETURN_MST_UPLOAD A WITH  (ROWLOCK) WHERE A.SP_ID=@nSpId 
	

END	
---END OF PROCEDURE - SP_MERGE_MIRROR_APR_DATA
