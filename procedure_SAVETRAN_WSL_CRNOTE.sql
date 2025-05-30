create PROCEDURE SAVETRAN_WSL_CRNOTE
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				varchar(40)='',
	@CMEMONOPREFIX		VARCHAR(50)='',
	@CFINYEAR			VARCHAR(10)='',
	@CMACHINENAME		VARCHAR(100)='',
	@CWINDOWUSERNAME	VARCHAR(100)='',
	@CWIZAPPUSERCODE	VARCHAR(10)='0000000',
	@CMEMOID			VARCHAR(40)='',
	@BTHROUGHIMPORT		BIT = 0,
	@CRMID				VARCHAR(40)='',
	@DRECEIPTDT			DATETIME = '',
	@CENTRYREFNO		VARCHAR(100)='',
	@BCALLEDFROMPACKSLIP  BIT=0,
	@EDIT_CLICKED       BIT =0,
	@CPSNO		        VARCHAR(50)=''
)
AS
BEGIN
	--changes by Dinkar in location id varchar(4)..


	-- @NUPDATEMODE:	1- NEW STOCK ADJUSTMENT MEMO ADDED, 
	--					2- Memo Edited
	--					3- memo cancelled
	--					5- Memo Date changed

	
	DECLARE @CTEMPDBNAME			VARCHAR(100),
			@CMASTERTABLENAME		VARCHAR(100),
			@CDETAILTABLENAME		VARCHAR(100),
			@CTEMPMASTERTABLENAME	VARCHAR(100),
			@CTEMPDETAILTABLENAME	VARCHAR(100),
			@CTEMPMASTERTABLE		VARCHAR(100),
			@CTEMPDETAILTABLE		VARCHAR(100),
			@CERRORMSG				VARCHAR(2000),
			@LDONOTUPDATESTOCK		BIT,
			@CKEYFIELD1				VARCHAR(50),
			@CKEYFIELDVAL1			VARCHAR(50),
			@CMEMONO				VARCHAR(20),
			@NMEMONOLEN				NUMERIC(20,0),
			@CMEMONOVAL				VARCHAR(50),
			@CMEMODEPTID			VARCHAR(2),
			@CLOCATIONID			VARCHAR(4),@bREvertFlag BIT,@bReupdateAllCnd BIT,
			@CHODEPTID				VARCHAR(4),
			@CCMD					NVARCHAR(4000),
			@CCMDOUTPUT				NVARCHAR(4000),
			@NSAVETRANLOOP			BIT,@NENTRYMODE NUMERIC(1,0),
			@cStep					varchar(10),@cInsSpId VARCHAR(50),
			@LENABLETEMPDATABASE	BIT,@BNEGSTOCKFOUND BIT,
			@NcNtYPE                INT,@cWhereClause VARCHAR(300),
			@CTEMPPARCELADJTABLENAME VARCHAR(200),@bBlankBillDetails BIT,
			@BPREFIXLZEROS	BIT,
			@CPRIFIX				VARCHAR(10),
			@CMEMOPRI				VARCHAR(10),@DSTARTTIME DATETIME,
		    @BIS_BIN_TRANSFER BIT,@CMEMOPREFIXPROC VARCHAR(25),
	       @CMULTIPLECN VARCHAR(10),@CNEXTACCODE CHAR(10),@CTEMPMULTICNTABLENAME	VARCHAR(200),@CLASTCNNO VARCHAR(50),@NMULTICNCNT INT,
	      @CFILTERMULTICN VARCHAR(500),@CNEXTBILLNO VARCHAR(30),@NERFLAG INT,@NCN_TYPE INT,@CSTATUSMSG VARCHAR(1000),
	      @CFIRSTCNNO VARCHAR(50),@NCREATEMULTICN int,@bAllowNegStock BIT,@cErrProductCode VARCHAR(50),
		  @CDETAILTABLENAME2		VARCHAR(100),@CTEMPDETAILTABLENAME2	VARCHAR(100),@CTEMPDETAILTABLE2		VARCHAR(100),
		  @cMissingRowId VARCHAR(40),@cPsId varchar(50), @bDonotEnforceBill varchar(10),@CLOCID	VARCHAR(4)
	   
     SELECT @bAllowNegStock=0,@bBlankBillDetails=0

   SET @DSTARTTIME=GETDATE()

	DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100),STATUSMSG varchar(max))

	SET @cStep = 0		-- SETTTING UP ENVIRONMENT
	
	SET @CTEMPDBNAME = ''

	SET @CMASTERTABLENAME	= 'CNM01106'--MANISH
	SET @CDETAILTABLENAME	= 'CND01106'--MANISH
	SET @CDETAILTABLENAME2	= 'PAYMODE_XN_DET'
	--SET @CDETAILTABLENAME2	= 'PRD_JID_RM'


	
	SET @CTEMPMASTERTABLENAME	= 'WSR_CNM01106_UPLOAD'
	SET @CTEMPDETAILTABLENAME	= 'WSR_CND01106_UPLOAD'
	SET @CTEMPPARCELADJTABLENAME = 'WSR_PARCEL_DET_UPLOAD'
	SET @CTEMPDETAILTABLENAME2	= 'WSR_PAYMODE_XN_DET_UPLOAD'
	
	SET @CTEMPMASTERTABLE	= @CTEMPDBNAME + @CTEMPMASTERTABLENAME
	SET @CTEMPDETAILTABLE	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME

	SET @CTEMPDETAILTABLE2	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME2
	
	SET @CERRORMSG			= ''
	SET @LDONOTUPDATESTOCK	= 0
	SET @CKEYFIELD1			= 'CN_ID'--MANISH
	SET @CMEMONO			= 'CN_NO'--MANISH
	
	
	SELECT @CLOCID=LOCATION_CODE FROM WSR_CNM01106_UPLOAD (nolock) WHERE SP_ID=@NSPID  

	
	IF ISNULL(@CLOCID,'')=''
		SELECT @CLOCATIONID		= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
	ELSE
		SELECT @CLOCATIONID=@CLOCID
		
	SELECT @CHODEPTID		= [VALUE] FROM CONFIG (NOLOCK) WHERE  CONFIG_OPTION='HO_LOCATION_ID'		


	SELECT @bDonotEnforceBill	= [VALUE] FROM CONFIG (NOLOCK) WHERE  CONFIG_OPTION='DO_NOT_ENFORCE_BILL_SELECTION_WSR'		




	SET @cStep = 10		-- GETTING DEPTID INFO FROM TEMP TABLE
	BEGIN TRANSACTION

	IF @NUPDATEMODE<>1
	BEGIN
		IF @NUPDATEMODE=2
			SELECT TOP 1 @cMemoId=cn_id FROM  wsr_cnm01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
	
	END
	
	BEGIN TRY

	UPDATE wsr_cnm01106_UPLOAD SET FIN_YEAR=@CFINYEAR  WHERE sp_id=@nSpId AND ISNULL(FIN_YEAR	,'')=''
	UPDATE wsr_cnm01106_UPLOAD SET COMPANY_CODE='01'  WHERE sp_id=@nSpId AND ISNULL(COMPANY_CODE	,'')=''
        	
   	IF OBJECT_ID('TEMPDB..#BARCODE_NETQTY','U') IS NOT NULL
		DROP TABLE #BARCODE_NETQTY

	SELECT DEPT_ID,BIN_ID,PRODUCT_CODE,quantity_in_stock AS XN_QTY
	,CONVERT(BIT,0) AS new_entry,CONVERT(BIT,0) AS bin_transfer
	INTO #BARCODE_NETQTY FROM PMT01106 (NOLOCK) WHERE 1=2


	IF @EDIT_CLICKED=1	and @NUPDATEMODE IN (2,3)
	 BEGIN
		SET @cStep = 10.5
			DECLARE @COL VARCHAR(MAX)
			SET @COL='IF OBJECT_ID(''tempdb..[##CNM_'+@NSPID+'_'+@CMEMOID+']'',''U'') IS NOT NULL'+CHAR(13)+' DROP TABLE [##CNM_'+@NSPID+'_'+@CMEMOID+'];'+CHAR(13)+'SELECT CN_ID OLD_CN_ID,CN_ID NEW_CN_ID,'
			SELECT @COL=COALESCE(@COL,'')+FIELD_NAME+' OLD_'+FIELD_NAME+','+FIELD_NAME+' NEW_'+FIELD_NAME+',' FROM XN_AUDIT_TRIAL_MST (NOLOCK) WHERE TABLE_NAME='CNM01106' AND TRIG='UPDATE' ORDER BY ORDER_ID
			SET @COL=LEFT(@COL,LEN(@COL)-1)+CHAR(13)+'INTO [##CNM_'+@NSPID+'_'+@CMEMOID+']'+CHAR(13)+'FROM CNM01106 (NOLOCK) WHERE CN_ID='''+@CMEMOID+''';'
			PRINT @COL
			EXEC(@COL)
			SET @COL=''
			SET @COL='IF OBJECT_ID(''tempdb..[##CND_'+@NSPID+'_'+@CMEMOID+']'',''U'') IS NOT NULL'+CHAR(13)+' DROP TABLE [##CND_'+@NSPID+'_'+@CMEMOID+'];'+CHAR(13)+'SELECT CN_ID OLD_CN_ID,CN_ID NEW_CN_ID,'
			SELECT @COL=COALESCE(@COL,'')+FIELD_NAME+' OLD_'+FIELD_NAME+','+FIELD_NAME+' NEW_'+FIELD_NAME+',' FROM XN_AUDIT_TRIAL_MST (NOLOCK) WHERE TABLE_NAME='CND01106' AND TRIG='UPDATE' ORDER BY ORDER_ID
			SET @COL=LEFT(@COL,LEN(@COL)-1)+CHAR(13)+'INTO [##CND_'+@NSPID+'_'+@CMEMOID+']'+CHAR(13)+'FROM CND01106 (NOLOCK) WHERE CN_ID='''+@CMEMOID+''';'
			PRINT @COL
			EXEC(@COL)
		END

		if @NUPDATEMODE=7
		begin
		    SET @cStep = 10.8
			UPDATE B SET  through=a.through,
			             grlr_no=a.grlr_no,
			             grlr_date=a.grlr_date,
						 bandals=a.bandals,
						 SHIPPING_ADDRESS=a.through
			FROM WSR_CNM01106_UPLOAD A (NOLOCK)
			JOIN CNM01106 B ON A.CN_ID =B.CN_ID 
			WHERE a.SP_ID=@nSpId

		    GOTO END_PROC    
		end



	IF @NUPDATEMODE IN (1,2)
	BEGIN
	 
		 IF ISNULL(@CLOCATIONID,'')=''
		 BEGIN
			SET @CERRORMSG = ' LOCATION ID CAN NOT BE BLANK  '  
			GOTO END_PROC    
		 END

	

	    DECLARE @CAC_CODE VARCHAR(15)
		SELECT @CAC_CODE=AC_CODE FROM WSR_CNM01106_UPLOAD (NOLOCK) WHERE SP_ID=LTRIM(RTRIM((@NSPID)))

		if object_id ('tempdb..#TMPFIXCN','U') IS NOT NULL
		   DROP TABLE #TMPFIXCN

		SELECT a.PRODUCT_CODE ,A.ROW_ID ,B.ac_code ,CAST('' AS VARCHAR(100)) AS BATCH_PRODUCT_CODE
		INTO #TMPFIXCN
		FROM WSR_CND01106_UPLOAD  A
		JOIN WSR_CNM01106_UPLOAD B (NOLOCK) ON A.SP_ID=B.SP_ID 
		JOIN SKU  (NOLOCK) ON A.PRODUCT_CODE=SKU.PRODUCT_CODE
		JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE=SKU.ARTICLE_CODE
		WHERE A.SP_ID=LTRIM(RTRIM((@NSPID)))
		AND SKU.BARCODE_CODING_SCHEME=1 AND ISNULL(ART.STOCK_NA,0)=0
		AND CHARINDEX('@',A.PRODUCT_CODE)=0 and b.mode=1 
		and b.entry_mode<>2

		if @NUPDATEMODE<>1
		begin
		    
			DELETE A FROM #TMPFIXCN A WHERE LEFT(A.ROW_ID,5)<>'LATER'

		end
		
		IF EXISTS (SELECT TOP 1 'U' FROM #TMPFIXCN)
		BEGIN
        

				 UPDATE A SET BATCH_PRODUCT_CODE=B.BATCH_PRODUCT_CODE
				 FROM #TMPFIXCN A
				 JOIN
				 (
				   SELECT A.INV_NO,A.INV_DT ,
						  B.PRODUCT_CODE AS BATCH_PRODUCT_CODE,A.AC_CODE ,
						 LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE ))) AS PRODUCT_CODE, 
						 SR=ROW_NUMBER() OVER (PARTITION BY a.AC_CODE, LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))  ORDER BY A.INV_ID DESC)
				   FROM INM01106 A  (NOLOCK)
				   JOIN IND01106 B  (NOLOCK) ON A.INV_ID =B.INV_ID 
				   JOIN #TMPFIXCN TMP ON  LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))=TMP.PRODUCT_CODE
				   WHERE A.CANCELLED =0 AND A.INV_MODE =1
				   AND CHARINDEX('@',b.PRODUCT_CODE )<>0
				   AND A.AC_CODE=@CAC_CODE
				) B ON B.AC_CODE =B.AC_CODE AND  A.PRODUCT_CODE =B.PRODUCT_CODE AND B.SR =1

		

				IF EXISTS (SELECT TOP 1 'U' FROM #TMPFIXCN WHERE BATCH_PRODUCT_CODE='')
				BEGIN
		     

					  UPDATE A SET BATCH_PRODUCT_CODE=B.BATCH_PRODUCT_CODE
					  FROM #TMPFIXCN A
					  JOIN
						(
						  SELECT  B.AC_CODE,B.PRODUCT_CODE AS BATCH_PRODUCT_CODE,
								 LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE ))) AS PRODUCT_CODE, 
								 SR=ROW_NUMBER() OVER (PARTITION BY  LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))  ORDER BY INV_DT DESC)
						  FROM SKU B (NOLOCK)
						  JOIN #TMPFIXCN TMP ON  LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))=TMP.PRODUCT_CODE
						  WHERE CHARINDEX('@',B.PRODUCT_CODE )<>0 and tmp.BATCH_PRODUCT_CODE=''
						) B ON  A.PRODUCT_CODE =B.PRODUCT_CODE AND B.SR =1
						where  a.BATCH_PRODUCT_CODE=''

				END


				UPDATE A SET product_code =BATCH_PRODUCT_CODE
				FROM WSR_CND01106_UPLOAD A
				JOIN #TMPFIXCN TMP ON A.row_id =TMP.ROW_ID AND A.product_code =TMP.product_code
				WHERE A.SP_ID=LTRIM(RTRIM((@NSPID)))
				AND TMP.BATCH_PRODUCT_CODE <>''

		

		END
        
  --      IF EXISTS(SELECT TOP 1 A.cn_id  FROM WSR_CND01106_UPLOAD  A (nolock) JOIN SKU_names (nolock) ON SKU_names.PRODUCT_CODE=A.PRODUCT_CODE	
	 --         where a.SP_ID  =@NSPID and ISNULL(SKU_names.sn_barcode_coding_scheme,0) =1 AND ISNULL(SKU_names.STOCK_NA,0)=0 and a.PRODUCT_CODE not like '%@%')
		--begin
		--	SET @CERRORMSG='fix barcode saving without batch....PLEASE CHECK'
		--	GOTO END_PROC
		
		--end
			

		-- GETTING JOB ORDER ID WHICH IS BEING EDITED
		SELECT @CKEYFIELDVAL1 = CN_id,@NENTRYMODE=ENTRY_MODE,@BIS_BIN_TRANSFER=isnull(bin_transfer,0) from WSR_cnm01106_UPLOAD (NOLOCK) WHERE sp_id=@nSPId

		
		IF (@CKEYFIELDVAL1 IS NULL )
		BEGIN
				SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'
				GOTO END_PROC  		
		END

		SET @cStep = 10.2

	    IF ISNULL(@NENTRYMODE,0) <=0
		BEGIN
		     SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + 'INVALID ENTRY MODE'+str(@NENTRYMODE)
			 GOTO END_PROC  
		END        	

		SET @cStep = 10.4
		SELECT TOP 1 @cErrPRODUCTCODE=product_code from WSR_cnd01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId AND (inv_no='' or inv_dt='')
		
		IF ISNULL(@cErrProductCode,'')<>'' and isnull(@bDonotEnforceBill,'')  <> '1'
		BEGIN
			SELECT @cErrormsg='Blank Bill details not allowed'
			
			SELECT A.PRODUCT_CODE,0 QUANTITY_IN_STOCK,'Blank Bill details not allowed' AS ERRMSG
			FROM WSR_cnd01106_UPLOAD a (NOLOCK) WHERE sp_id=@nSpId AND (inv_no='' or inv_dt='')

			SET @bBlankBillDetails =1
			GOTO END_PROC
		END	

		SET @cStep = 10.7
        SET @CCMD='UPDATE '+@CTEMPDETAILTABLENAME+' SET BILL_LEVEL_TAX_METHOD=1 WHERE ISNULL(BILL_LEVEL_TAX_METHOD,0)=0
                   AND SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
		
		EXEC sp_executesql  @CCMD





		SET @cStep = 12
		EXEC SP_VALIDATEXN_BEFORESAVE 'WSR',@NSPID,'0000000',@NUPDATEMODE,@CCMDOUTPUT OUTPUT,@BNEGSTOCKFOUND OUTPUT
		IF ISNULL(@CCMDOUTPUT,'') <> ''
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' DATA VALIDATION ON TEMP DATA FAILED : ' + @CCMDOUTPUT + '...'
			GOTO END_PROC
		END
		
		INSERT #BARCODE_NETQTY(DEPT_ID,BIN_ID,PRODUCT_CODE,XN_QTY,new_entry,bin_transfer)	
		SELECT @CLOCATIONID as DEPT_ID,A.BIN_ID,A.PRODUCT_CODE,SUM(A.QUANTITY),1 as new_entry,0 as bin_transfer
		FROM WSR_cnd01106_UPLOAD A (NOLOCK)
		JOIN WSR_CNM01106_UPLOAD b (NOLOCK) ON a.sp_id=b.sp_id
		JOIN SKU_names c (NOLOCK) ON A.product_code=c.product_code
		WHERE A.SP_ID=@NSPID AND ISNULL(c.stock_na,0)=0 
		GROUP BY A.BIN_ID,A.PRODUCT_CODE

		IF @BIS_BIN_TRANSFER=1
			INSERT #BARCODE_NETQTY(DEPT_ID,BIN_ID,PRODUCT_CODE,XN_QTY,new_entry,bin_transfer)	
			SELECT @CLOCATIONID as DEPT_ID,b.SOURCE_BIN_ID as BIN_ID,A.PRODUCT_CODE,SUM(A.QUANTITY),
			1 as new_entry,1 as bin_transfer
			FROM WSR_cnd01106_UPLOAD A (NOLOCK)
			JOIN WSR_CNM01106_UPLOAD b (NOLOCK) ON a.sp_id=b.sp_id
			JOIN SKU_names c (NOLOCK) ON A.product_code=c.product_code
			WHERE A.SP_ID=@NSPID AND ISNULL(c.stock_na,0)=0 
			GROUP BY b.SOURCE_BIN_ID,A.PRODUCT_CODE	
	END ---- End of IF @NUPDATEMODE IN (1,2)


	IF @NUPDATEMODE IN (3,5) 
	BEGIN

	     	
			IF ISNULL(@CMEMOID,'') = ''
			BEGIN
				SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' MEMO ID REQUIRED IF CALLED FROM CANCELLATION'
				GOTO END_PROC  		
			END
			ELSE
			IF @NUPDATEMODE=5
			BEGIN
				IF ISNULL(@DRECEIPTDT,'')=''
				BEGIN
					SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@cStep)) + ' New Memo Date required to be changed .....CANNOT PROCEED'
					GOTO END_PROC  		
				END

				GOTO lblUpdatedate
			END						
		EXEC SP3S_CAPTURE_AUDIT_TRAIL 'WSR',@CMEMOID,@CTEMPMASTERTABLE,@CTEMPDETAILTABLE,@NSPID,@CMACHINENAME,@CWINDOWUSERNAME,@CWIZAPPUSERCODE,1,'1900-01-01',@EDIT_CLICKED

	END --- End of IF @NUPDATEMODE IN (3,5) 

	IF @NUPDATEMODE=6 AND ISNULL(@CPSNO,'')=''
	BEGIN
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@cStep)) + ' PACK SLIP NO. REQUIRED .....CANNOT PROCEED'
		GOTO END_PROC  		
	END
	

	IF @NUPDATEMODE IN (2,3,6)
	BEGIN	
	       
		  IF @nUpdatemode=6
	        SELECT TOP 1 @cPsId=ps_id FROM CNPS_mst (NOLOCK) where ps_no=@CPSNO AND fin_year=@CFINYEAR


			if @NUPDATEMODE=2
				select @cMemoId=cn_id,@BIS_BIN_TRANSFER=isnull(BIN_TRANSFER,0) from WSR_CNM01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpid
			else
				select @CKEYFIELDVAL1=cn_id, @BIS_BIN_TRANSFER=isnull(BIN_TRANSFER,0) from CNM01106 (NOLOCK) WHERE cn_id=@CMEMOID

			INSERT #BARCODE_NETQTY(DEPT_ID,BIN_ID,PRODUCT_CODE,XN_QTY,new_entry,bin_transfer)	
			SELECT b.location_Code  as DEPT_ID,A.BIN_ID,A.PRODUCT_CODE,SUM(A.QUANTITY)*-1,0 as new_entry,0 as bin_transfer
			FROM CNd01106 A (NOLOCK)
			JOIN CNm01106 b (NOLOCK) ON a.CN_id=b.CN_id
			JOIN SKU_names c (NOLOCK) ON A.product_code=c.product_code
			WHERE A.CN_ID=@cMemoid AND ISNULL(c.stock_na,0)=0 
			AND ISNULL(A.PS_ID,'')=(CASE WHEN @NUPDATEMODE=6 THEN @CPSID ELSE ISNULL(A.PS_ID,'') END )
			GROUP BY b.location_Code ,A.BIN_ID,A.PRODUCT_CODE

			IF @BIS_BIN_TRANSFER=1
				INSERT #BARCODE_NETQTY(DEPT_ID,BIN_ID,PRODUCT_CODE,XN_QTY,new_entry,bin_transfer)	
				SELECT b.location_Code  as DEPT_ID,b.SOURCE_BIN_ID as BIN_ID,A.PRODUCT_CODE,SUM(A.QUANTITY),
				0 as new_entry,1 as bin_transfer
				FROM CNd01106 A (NOLOCK)
				JOIN CNm01106 b (NOLOCK) ON a.CN_id=b.CN_id
				JOIN SKU_names c (NOLOCK) ON A.product_code=c.product_code
				WHERE A.CN_ID=@cMemoid AND ISNULL(c.stock_na,0)=0 
				AND ISNULL(A.PS_ID,'')=(CASE WHEN @NUPDATEMODE=6 THEN @CPSID ELSE ISNULL(A.PS_ID,'') END )
				GROUP BY b.location_Code ,b.SOURCE_BIN_ID,A.PRODUCT_CODE
	END --- End of IF @NUPDATEMODE IN (2,3)
	
	  --DELETE PACK SLIP 
	 IF  @NUPDATEMODE =6
	 BEGIN
	     DELETE A FROM CND01106 A (NOLOCK) WHERE A.PS_ID=@CPSID AND ISNULL(@CPSID,'')<>'' and cn_id=@cMemoId

	 END


	
	--- CREATE NEW MASTERS IF DETAILS IMPORTED THROUGH IMPORT FILE 				
		IF  @BTHROUGHIMPORT=1 AND OBJECT_ID('TEMPDB..##TMPMASTERS') IS NOT NULL
		BEGIN
			EXEC SP_GETMASTERS '01112',2,@CERRORMSG OUTPUT 
			
			DROP TABLE ##TMPMASTERS
		END	

	
	   	
	   SET @NCREATEMULTICN=0
	   SET @NMULTICNCNT=0
	   
	   IF @NUPDATEMODE=1
	   BEGIN
			SELECT TOP 1 @CMULTIPLECN=VALUE FROM CONFIG(NOLOCK) WHERE CONFIG_OPTION='MULTIPLE_CN'
			SET @CMULTIPLECN=ISNULL(@CMULTIPLECN,'')
		
		
		
			 DECLARE @NCREATEMULTICNCOUNT INT  
			 SELECT @NCREATEMULTICNCOUNT=COUNT (DISTINCT INV_NO) FROM WSR_CND01106_UPLOAD  (NOLOCK) WHERE SP_ID= LTRIM(RTRIM((@NSPID)))
		
			IF ISNULL(@NCREATEMULTICNCOUNT,0)>1
				SET @NCREATEMULTICN=1
		
		
			DECLARE @CFILTERCONDITIONmulti VARCHAR(200)
			--FOR MULTIPLE CREDIT NOTE
			LBLGENMULTICN:
		
		
			IF ISNULL(@CMULTIPLECN,'')='1' and isnull(@NCREATEMULTICN,0)=1
			BEGIN	
				IF ISNULL(@CNEXTBILLNO,'')=''
				BEGIN
					SET	@cStep = 29
				
					set @CFILTERCONDITIONmulti=' sp_id= '''+ltrim(rtrim(@nSpId))+''''
					SET @cInsSpId=ltrim(rtrim(@nSPId))+@CLOCATIONID
					EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='wsr_cnd01106_upload',@CDESTDB=''
									,@CDESTTABLE='wsr_cnd01106_upload',@CKEYFIELD1='sp_id',@CKEYFIELD2='',@CKEYFIELD3=''
									,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITIONmulti,@LUPDATEONLY=0
									,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CINSSPIDCol=''
									,@CSEARCHTABLE='cnd01106',@cXnType='PRT'
				
			
						SET	@cStep = 29.2
					DELETE FROM wsr_cnd01106_upload WITH (ROWLOCK) where sp_id=@nSpId
					
					

				END
				


				SET	@cStep = 12
			
				SET @CNEXTBILLNO=''
				
				SELECT TOP 1 @CNEXTBILLNO=a.INV_NO
				FROM wsr_cnd01106_upload A (NOLOCK) WHERE sp_id=@cInsSpId
			

				IF ISNULL(@CNEXTBILLNO,'')=''
				BEGIN
					SET @CLASTCNNO=@CMEMONOVAL
				
					-- AFTER SUCCESSFUL SAVING , JUST DROP THE TEMP TABLES CREATED BY APPLICATION
					SET @cStep = 14
					DELETE FROM wsr_cnM01106_UPLOAD with (rowlock)  WHERE SP_ID=LTRIM(RTRIM(@NSPID))
					DELETE FROM wsr_cnD01106_UPLOAD with (rowlock) WHERE SP_ID=LTRIM(RTRIM(@NSPID))
					--EXEC SP_DROPTEMPTABLES_XNS 'XNSPRT',@NSPID
				
					GOTO END_PROC
				END
	
				SET	@cStep = 15
			
				SET @NMULTICNCNT=@NMULTICNCNT+1
			
				DELETE FROM wsr_cnD01106_UPLOAD with (rowlock) WHERE SP_ID=LTRIM(RTRIM(@NSPID))	
	
				SET	@cStep = 17
			
				SET @CFILTERMULTICN=' AND b.INV_NO='''+@CNEXTBILLNO+''''
			
				SET @CWHERECLAUSE=' sp_id='''+@cInsSPId+''' '+@CFILTERMULTICN 

				EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='wsr_cnd01106_upload',@CDESTDB=''
									,@CDESTTABLE='wsr_cnd01106_upload',@CKEYFIELD1='sp_id',@CKEYFIELD2='',@CKEYFIELD3=''
									,@LINSERTONLY=1,@CFILTERCONDITION=@CWHERECLAUSE,@LUPDATEONLY=0
									,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@nSpId,@CINSSPIDCol=''
									,@CSEARCHTABLE='cnd01106',@cXnType='PRT'
			
				SET	@cStep = 19
				
					
			
				DELETE a FROM wsr_cnd01106_upload a WITH (ROWLOCK) 
				JOIN wsr_cnd01106_upload b (NOLOCK) ON a.product_code=b.product_code and a.inv_no =b.inv_no 
				WHERE a.sp_id=@cInsSpId AND b.sp_id=@nSpId
	

				SET	@cStep = 19.2
				DELETE FROM #BARCODE_NETQTY

				INSERT #BARCODE_NETQTY(DEPT_ID,BIN_ID,PRODUCT_CODE,XN_QTY,new_entry,bin_transfer)	
				SELECT @CLOCATIONID as DEPT_ID,BIN_ID,PRODUCT_CODE,SUM(quantity) as XN_QTY,1 as new_entry ,0 as bin_transfer
				FROM wsr_cnd01106_upload (NOLOCK) WHERE sp_id=@nSpId
				GROUP BY BIN_ID,PRODUCT_CODE
			END
			--END OF MULTIPLE CN
	
            
              
	
			SET @cStep = 15
			DECLARE @CXNTYPEPARA VARCHAR(10)
			SET @CXNTYPEPARA='WSR'
			SELECT @NCNTYPE = CN_TYPE FROM wsr_cnm01106_upload WHERE SP_ID=@nspid
			IF @NCNTYPE=2
			SET @CXNTYPEPARA='FCN'


			
			EXEC SAVETRAN_GETMEMOPREFIX
			@CXNTYPE=@CXNTYPEPARA,
			@CUSERCODE=@CWIZAPPUSERCODE,
			@CFINYEAR=@CFINYEAR,
			@CSOURCELOCID=@CLOCATIONID,
			@CTARGETLOCID='',
			@CMANUALPREFIX=@CMEMONOPREFIX,
			@NSPID=@NSPID,
			@CMEMOPREFIX=@CMEMOPREFIXPROC OUTPUT,
			@CERRORMSG=@CERRORMSG OUTPUT
					
				
			
			IF ISNULL(@CERRORMSG,'')<>''
				GOTO END_PROC
				
			SET @NMEMONOLEN			= LEN(@CMEMOPREFIXPROC)+6

			SET @cStep = 20		-- GENERATING NEW KEY
			
			-- GENERATING NEW JOB ORDER NO		
			SET @NSAVETRANLOOP=0
			WHILE @NSAVETRANLOOP=0
			BEGIN
				EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMOPREFIXPROC,1,
								@CFINYEAR,0, @CMEMONOVAL OUTPUT   
				
				PRINT @CMEMONOVAL
				SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM '+@CMASTERTABLENAME+'  (NOLOCK)
										WHERE '+@CMEMONO+'='''+@CMEMONOVAL+''' 
										AND FIN_YEAR = '''+@CFINYEAR+''' )
								SET @NLOOPOUTPUT=0
							ELSE
								SET @NLOOPOUTPUT=1'
				PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT
			END
			
			IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%' OR ISNUMERIC(RIGHT(@CMEMONOVAL,6))=0
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' ERROR CREATING NEXT MEMO NO....'	
				  GOTO END_PROC  		
			END
			
			SET @cStep = 30		-- GENERATING NEW ID
			-- GENERATING NEW JOB ORDER ID
			SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
			
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' ERROR CREATING NEXT MEMO ID....'
				  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'
				  GOTO END_PROC
			END

			SET @cStep = 40		-- UPDATING NEW ID INTO TEMP TABLES

			-- UPDATING NEWLY GENERATED JOB ORDER NO AND JOB ORDER ID IN PIM AND PID TEMP TABLES
			SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' + 
						@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''',RECEIPT_DT=CN_DT,Auto_prefix='''+@CMEMOPREFIXPROC+'''   WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD
			
			SET @cStep = 42
			SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+'''
			WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''
			
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD

								
			SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE2 + ' WITH (ROWLOCK)  SET MEMO_ID = '''+@CKEYFIELDVAL1+''' where  sp_id='''+LTRIM(RTRIM(@NSPID))+''' '
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD

			
			SET @cStep = 44
			-- GETTING DEPT_ID FROM TEMP MASTER TABLE
			SET @CCMD = 'SELECT @CMEMODEPTID = LEFT(CN_NO,2) FROM ' + @CTEMPMASTERTABLE +' (NOLOCK) WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''--MANISH
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(2) OUTPUT', 
							   @CMEMODEPTID OUTPUT
			IF (@CMEMODEPTID IS NULL )
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'
				  GOTO END_PROC  		
			END
			
			
			IF ISNULL(@CMULTIPLECN,'')='1' AND ISNULL(@CFIRSTCNNO,'')=''
				SET @CFIRSTCNNO=@CMEMONOVAL

			
		END					-- END OF ADDMODE
		ELSE				-- CALLED FROM EDITMODE
		BEGIN				-- START OF EDITMODE
		
							
			SET @cStep = 55		-- STORING OLD STATUS OF BARCODES 

			
			IF @NUPDATEMODE = 3			
			BEGIN
				SET @cStep = 57
				-- UPDATING SENTTOHO FLAG
				SET @CCMD = N'UPDATE cnm01106 SET CANCELLED = 1,LAST_UPDATE=GETDATE() ' + 
							N' WHERE cn_id = ''' +@cMemoId + ''''
				PRINT @cCmd
				EXEC SP_EXECUTESQL @CCMD

				SET @cStep = 57.5
				UPDATE A SET WSR_CN_ID='' FROM CNPS_MST A WITH (ROWLOCK)  JOIN 
				cnm01106 B WITH (NOLOCK)  ON A.WSR_CN_ID=B.CN_ID
				WHERE b.cn_id = @CMEMOID

			   SET @cStep=57.9
			   EXEC SP3S_CANCEL_AUTOVOUCHERS
			   @cXnType='WSR',
			   @CMEMOID=@CKEYFIELDVAL1     
				

			END
			
			SET @cStep=60  
				
			SET @CCMD=N'DELETE a FROM parcel_xns_link a  WITH (ROWLOCK) JOIN parcel_det b (NOLOCK) ON a.parcel_row_id=b.row_id
						JOIN parcel_mst c (NOLOCK) ON c.parcel_memo_id=b.parcel_memo_id
						WHERE a.memo_id='''+ @CKEYFIELDVAL1+''' AND c.XN_TYPE=''WSR'''  

			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD  
		    				
			SET @cStep=62
			SET @CCMD=N'UPDATE A SET REF_MEMO_ID='''',REF_MEMO_NO='''',closed=0 FROM PARCEL_DET A WITH (ROWLOCK)
			            JOIN PARCEL_MST B (NOLOCK) ON A.PARCEL_MEMO_ID=B.PARCEL_MEMO_ID
			            JOIN  CNM01106 C (NOLOCK) ON  C.CN_ID=A.REF_MEMO_ID
			            WHERE B.XN_TYPE=''WSR'' AND C.CN_ID='''+ @CKEYFIELDVAL1+''''  
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD  
			   	
				
			SET @cStep = 64
			SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET cn_id='''+@CKEYFIELDVAL1+'''
			WHERE SP_ID='''+LTRIM(RTRIM((@NSPID)))+''' AND (LEFT(cn_id,5)=''LATER'' OR CN_ID='''')'
			EXEC SP_EXECUTESQL @CCMD  

			-- REVERTING BACK THE STOCK OF PMT W.R.T CURRENT ISSUE
			SET @cStep = 80		-- REVERTING STOCK


			if @NUPDATEMODE<>3
			SELECT @NcNtYPE=  CN_TYPE  FROM WSR_CNM01106_UPLOAD (NOLOCK)  WHERE SP_ID=@NSPID
			else
			SELECT @NcNtYPE=  CN_TYPE,@NENTRYMODE=Entry_mode  FROM cnm01106 (NOLOCK)  WHERE cn_id=@cMemoId
			
			set @bAllowNegStock=(case when @NUPDATEMODE=2 THEN 1 else 0 end)

			

			IF ISNULL(@NcNtYPE,1) <> 2
			BEGIN	
				--SELECT * FROM #BARCODE_NETQTY
				SELECT @BALLOWNEGSTOCK =VALUE FROM USER_ROLE_DET A (NOLOCK)--ADDED
				JOIN USERS B (NOLOCK)--ADDED
				ON A.ROLE_ID=B.ROLE_ID 
				WHERE USER_CODE=@CWIZAPPUSERCODE 
				AND FORM_NAME='FRMSALE' 
				AND FORM_OPTION='ALLOW_NEG_STOCK'		
	
				SET @BALLOWNEGSTOCK =ISNULL(@BALLOWNEGSTOCK,0)

				
				SET @bREvertFlag=1--(CASE WHEN @nUpdatemode=3 THEN 0 ELSE 1 END)--in case of cancelled wrong Update

			
				EXEC SP3S_UPDATE_PMTSTOCK_WSR
				@cMemoId=@cMemoId,
				@bREvertFlag=@bREvertFlag,
				@NENTRYMODE=@NENTRYMODE,
				@nCnType=@nCnType ,
				@nSpId=@nSpId,
				@BIS_BIN_TRANSFER=@BIS_BIN_TRANSFER,
				@bAllowNegStock=@bAllowNegStock,
				@CERRORMSG=@CERRORMSG OUTPUT,
				@BNEGSTOCKFOUND=@BNEGSTOCKFOUND OUTPUT
				
				


				--SELECT @BNEGSTOCKFOUND
				IF @CERRORMSG<>''
					GOTO END_PROC
			END

			IF @NUPDATEMODE=3
				GOTO END_PROC



			SELECT TOP 1 @cMissingRowId=a.row_id FROM PAYMODE_XN_DET A (NOLOCK) 
			LEFT JOIN 
			(SELECT row_id FROM WSr_PAYMODE_XN_DET_UPLOAD B (NOLOCK) WHERE sp_id=@nSpId) b
			 ON A.row_ID =B.row_ID WHERE A.memo_id =@CMEMOID AND a.xn_type='wsr' AND b.row_id IS NULL

			IF ISNULL(@cMissingRowId,'')<>''
			BEGIN		
				
				DELETE A FROM PAYMODE_XN_DET A (NOLOCK) LEFT JOIN 
				(SELECT row_id FROM WSr_PAYMODE_XN_DET_UPLOAD B (NOLOCK) WHERE sp_id=@nSpId) b
				ON A.row_ID =B.row_ID WHERE A.memo_id =@CMEMOID AND a.xn_type='wsr' AND b.row_id IS NULL

			END




		END					-- END OF EDITMODE

		SET @cStep = 95
		
		-- RECHECKING IF ID IS STILL LATER
		IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' ERROR CREATING NEXT MEMO ID....'
			GOTO END_PROC
		END
        
		SET @cStep=100
		EXEC SP_CHKXNSAVELOG 'WSR',@cStep,1,@nSpId,'',1	 

		EXEC SP3S_CALTOTALS_wsr
		@nUpdatemode=@nUpdatemode,
		@nSpId = @nSpId,
		@cCnId = @ckEYFIELDVAL1 ,
		@nCnType = @nCnType,
		@BCALLEDFROMPACKSLIP=@BCALLEDFROMPACKSLIP,
		@CERRORMSG=@CERRORMSG OUTPUT,
		@CLOCID=@CLOCID

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC

		

       --AMOUNT DIFFERENCE SETTELED

		DECLARE @NPAYMODETOTAMT NUMERIC(10,2),@CNMNETAMOUNT NUMERIC(10,2),@CPAYMODEROW_ID VARCHAR(100)
		SELECT @NPAYMODETOTAMT = SUM(AMOUNT) FROM WSR_PAYMODE_XN_DET_UPLOAD A (NOLOCK)  WHERE SP_ID=@NSPID AND XN_TYPE='WSR'
		SELECT @CNMNETAMOUNT=TOTAL_AMOUNT FROM WSR_CNM01106_UPLOAD WHERE SP_ID=@NSPID
		SELECT TOP 1 @CPAYMODEROW_ID=ROW_ID FROM WSR_PAYMODE_XN_DET_UPLOAD A (NOLOCK)  WHERE SP_ID=@NSPID AND XN_TYPE='WSR' 

		
		IF ISNULL(@NPAYMODETOTAMT,0)  <>ISNULL(@CNMNETAMOUNT,0)
		BEGIN
		    
			IF ISNULL(@NPAYMODETOTAMT,0)=0
			BEGIN
			    UPDATE  WSR_CNM01106_UPLOAD SET PAY_MODE =4 WHERE SP_ID =@NSPID AND ISNULL(PAY_MODE,0)<>4
			    INSERT INTO WSR_PAYMODE_XN_DET_UPLOAD(memo_id,paymode_code,xn_type,last_update,amount,SP_ID,row_id)
				SELECT @CKEYFIELDVAL1 memo_id,'0000004' paymode_code,'WSR' xn_type,GETDATE() last_update,@CNMNETAMOUNT amount,
				        @NSPID SP_ID,NEWID() row_id

			END
			ELSE 
			BEGIN

				UPDATE A SET AMOUNT =AMOUNT+(ISNULL(@CNMNETAMOUNT,0)-ISNULL(@NPAYMODETOTAMT,0))  FROM WSR_PAYMODE_XN_DET_UPLOAD A (NOLOCK)  
				WHERE SP_ID=@NSPID AND XN_TYPE='WSR' AND ROW_ID=@CPAYMODEROW_ID

			END

		END

		 --END OF AMOUNT DIFFERENCE SETTELED

	
		
  		IF @NUPDATEMODE=2
		BEGIN
			SET @cStep = 195		-- SETTTING UP ENVIRONMENT
			EXEC SP_CHKXNSAVELOG 'WSR',@cStep,1,@nSpId,'',1	 	       
			update cnd01106 with (rowlock) SET cn_id='XXXXXXXXXX',row_id=@CLOCATIONID  + CONVERT(VARCHAR(40), NEWID()) WHERE cn_id=@CKEYFIELDVAL1
			update PAYMODE_XN_DET with (rowlock) SET memo_id='XXXXXXXXXX',row_id=@CLOCATIONID  + CONVERT(VARCHAR(40), NEWID()) 
			WHERE memo_id=@CKEYFIELDVAL1 and xn_type='WSR'
			
		END
		
		SET @cStep=125.6

		declare @lInsertonly bit

		SET @lInsertonly = (CASE WHEN @NUPDATEMODE=1 THEN 1 ELSE 0 END)


		IF @nEntrymode=2
		BEGIN
			SET @cStep=125.8
			UPDATE cnps_mst WITH  (ROWLOCK)  SET wsr_cn_id= @CKEYFIELDVAL1 FROM 
			(SELECT DISTINCT PS_ID FROM  WSR_cnd01106_upload a (NOLOCK)  
				WHere SP_ID=@nSpId) B WHERE B.PS_ID=cnps_MST.PS_ID
		END
				
		SET @CWHERECLAUSE=' sp_id='''+@nSPId+'''' 

		--select subtotal , * from WSR_CNM01106_UPLOAD where sp_id=@nSPId
		
		--select sum(net_rate*quantity) from WSR_CNd01106_UPLOAD where sp_id=@nSPId

    
		EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPMASTERTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CMASTERTABLENAME
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
			, @CFILTERCONDITION=@cWhereClause
			, @LINSERTONLY =  @lINSERTONLY
			, @LUPDATEXNS =  @lINSERTONLY   
   

 
 
		-- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE
		SET @cStep = 130		-- UPDATING TRANSACTION TABLE

		-- UPDATING ROW_ID IN TEMP TABLES
		SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
					  WHERE SP_ID='''+LTRIM(RTRIM(@NSPID))+''' and LEFT(ROW_ID,5) = ''LATER'''
		EXEC SP_EXECUTESQL @CCMD


		IF @NUPDATEMODE=1
		begin

			SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE2 + ' WITH (ROWLOCK) SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
			WHERE sp_id='''+LTRIM(RTRIM(@NSPID))+''' '
			EXEC SP_EXECUTESQL @CCMD

		end
		else
		begin
		     	SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE2 + ' WITH (ROWLOCK) SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
				WHERE sp_id='''+LTRIM(RTRIM(@NSPID))+''' AND LEFT(ROW_ID,5) = ''LATER'''
				EXEC SP_EXECUTESQL @CCMD
		end
		
		
		
		SET @cStep = 132		-- UPDATING TRANSACTION TABLE

		-- UPDATING RM_ID IN TEMP TABLES
		
	  --PRINT 'ROHIT'  
	
 
		-- INSERTING/UPDATING THE ENTRIES IN PRD_JID TABLE FROM TEMPTABLE
		SET @cStep = 140		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES


		SET @cStep = 272.6		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES
		EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@nSpId,'',1
		
		DECLARE @bInsertOnly bit
		
		set @bInsertOnly=0
		
		IF (@EDIT_CLICKED=0 AND @nEntrymode=2) OR @NUPDATEMODE=1
			SET @bInsertOnly=1
			

		SET @cStep = 272.7		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES
		EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@nSpId,'',1

	
			
		DECLARE @CWHERECLAUSECnd VARCHAR(500)

		SET @CWHERECLAUSECnd=@cWhereClause
		IF @bReupdateAllCnd=1
			SET @CWHERECLAUSECnd = ' (SP_ID='''+LTRIM(RTRIM(@NSPID))+''' OR SP_ID='''+left(LTRIM(RTRIM(@nSPID)),38)+@CLOCATIONID+''')'

		EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN
				@CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME
			, @CKEYFIELD1	= 'ROW_ID'
			, @BALWAYSUPDATE = 1
			, @LINSERTONLY =  @lINSERTONLY
			, @LUPDATEXNS =  1
			, @CFILTERCONDITION=@CWHERECLAUSECnd
	

		SET @cStep=142

			--CHANGE FOR PAYMODE XN DET

		select @bInsertOnly=0

		IF  @NUPDATEMODE=1
			SET @bInsertOnly=1
	
	SET @cStep=145

    

	
		EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME2
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME2
			, @CKEYFIELD1	= 'ROW_ID'
			, @BALWAYSUPDATE = 1
			, @CFILTERCONDITION=@cWhereClause
			, @lInsertOnly=1
			, @LUPDATEXNS = 1

		-- END OF PAYMODE XN_DET


		--WHOLE SALE MODULE USE FORM NAME FRMSALE
		  
		 SELECT @BALLOWNEGSTOCK =VALUE FROM USER_ROLE_DET A (NOLOCK)--ADDED
		JOIN USERS B (NOLOCK)--ADDED
		ON A.ROLE_ID=B.ROLE_ID 
		WHERE USER_CODE=@CWIZAPPUSERCODE 
		AND FORM_NAME='FRMSALE' 
		AND FORM_OPTION='ALLOW_NEG_STOCK'
			
		SET @BALLOWNEGSTOCK =ISNULL(@BALLOWNEGSTOCK,0)
		

		-- As per discuss with pankaj sir & sanjiv sir
		IF @NUPDATEMODE =1
		   SET @BALLOWNEGSTOCK=1

		-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
		EXEC SP3S_UPDATE_PMTSTOCK_WSR
		@cMemoId=@cMemoId,
		@bREvertFlag=0,
		@NENTRYMODE=@NENTRYMODE,
		@nCnType=@nCnType ,
		@nSpId=@nSpId,
		@BIS_BIN_TRANSFER=@BIS_BIN_TRANSFER,
		@bAllowNegStock=@bAllowNegStock,
		@CERRORMSG=@CERRORMSG OUTPUT,
		@BNEGSTOCKFOUND=@BNEGSTOCKFOUND OUTPUT


	

		IF  @BNEGSTOCKFOUND=1 OR @CERRORMSG<>''
			GOTO END_PROC


		
			
	   set @cStep=150
		  
	  -- EXEC SP3S_UPDATERFNET_PRT @nSpId
		
		
		SET @cStep = 172
		EXEC UPDATERFNET 'WSR',@CKEYFIELDVAL1

		SET @cStep=175
		DECLARE @CREF_MEMO_NO VARCHAR(10),@CParcelDetails  varchar(1000) 
	    SELECT @CREF_MEMO_NO=CN_ID FROM wsr_CNM01106_upload  (NOLOCK)  WHERE sp_id=@NSPID


      UPDATE PARCEL_DET WITH  (ROWLOCK) SET REF_MEMO_ID=@CKEYFIELDVAL1,REF_MEMO_NO=@CREF_MEMO_NO,closed=b.closed
	  FROM wsr_parcel_det_upload B  (NOLOCK)   
	  WHERE B.ROW_ID=PARCEL_DET.ROW_ID
	  AND B.SP_ID=@NSPID
	  	   
	   SET @cStep=177	
	   INSERT parcel_xns_link	( PARCEL_row_ID, memo_id, xn_type )  
	   SELECT DISTINCT row_id AS PARCEL_row_ID,@CKEYFIELDVAL1 AS memo_id,'WSR' AS xn_type 
	   FROM WSR_parcel_det_UPLOAD (NOLOCK) WHERE sp_id=@NSPID 
	   
	   IF EXISTS (SELECT TOP 1 'U' FROM WSR_PARCEL_DET_UPLOAD A (NOLOCK) WHERE SP_ID  =@NSPID)
	   BEGIN
		 ;WITH CTE_PARCEL AS
		 (
		 SELECT PARCEL_MEMO_ID  FROM WSR_PARCEL_DET_UPLOAD A (NOLOCK)
		 WHERE SP_ID  =@NSPID
		 GROUP BY PARCEL_MEMO_ID
		 )
		 SELECT @CPARCELDETAILS =  COALESCE(@CPARCELDETAILS +  ':', '' ) +ISNULL(C.ANGADIA_NAME  ,'')+','+A.BILTY_NO 
		 FROM PARCEL_MST A (NOLOCK)
		 JOIN CTE_PARCEL B ON A.PARCEL_MEMO_ID =B.PARCEL_MEMO_ID 
		 JOIN ANGM   C (NOLOCK) ON C.ANGADIA_CODE  =A.ANGADIA_CODE  
		 
		UPDATE CNM01106 WITH (ROWLOCK) SET ParcelDetails =@CPARCELDETAILS WHERE CN_ID=@CKEYFIELDVAL1
		
	   	
	   END			

		-- VALIDATING ENTRIES 
		SET @cStep = 180		-- VALIDATING ENTRIES

		EXEC VALIDATEXN
			  @CXNTYPE	= 'WSR' 
			, @CXNID	= @CKEYFIELDVAL1
			, @NUPDATEMODE = @NUPDATEMODE			
			, @CCMD		= @CCMDOUTPUT OUTPUT
			, @CUSERCODE = @CWIZAPPUSERCODE
			
		IF @CCMDOUTPUT <> ''
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' DATA VALIDATION FAILED : ' + @CCMDOUTPUT + '...'
			GOTO END_PROC
		END
		
		-- AFTER SUCCESSFUL SAVING , JUST DROP THE TEMP TABLES CREATED BY APPLICATION
		SET @cStep = 185
		
        
        if ISNULL(@CMULTIPLECN,'')='1' and @NCREATEMULTICN=1 AND @NUPDATEMODE=1
		BEGIN	
			GOTO LBLGENMULTICN
		END


LBLUPDATERECEIPTDATE:  
	----- This Code shifted to Direct call of Savetran_merge_mirrordocprt from APplication
 	   GOTO END_PROC
	   	

lblUPDATEDATE:
	IF @NUPDATEMODE = 5
	BEGIN
		  

		SET @cStep = 195
	
		DECLARE @DOLDMemoDT DATETIME
		SET @cStep = 200
			
		SELECT TOP 1 @DOLDMemoDT=CN_DT FROM CnM01106 (NOLOCK) WHERE cN_ID=@CMEMOID
			
		UPDATE CNM01106 WITH (ROWLOCK) SET CN_DT=@DRECEIPTDT,LAST_UPDATE=GETDATE() WHERE CN_ID=@CMEMOID
		SET @CKEYFIELDVAL1=@CMEMOID
			
		SET @CERRORMSG = ''
			
		SET @cStep = 210
			
		EXEC VALIDATE_XN_DATA_FREEZE  'WSR',@CWIZAPPUSERCODE,@CMEMOID ,@DRECEIPTDT,@CERRORMSG OUTPUT
		IF @CERRORMSG <> '' 
			GOTO END_PROC
			
			
			
		SET @cStep = 320
		EXEC SP_VALIDATE_MEMODATE_opt
		@CXNTYPE='WSR',
		@CXNID=@CMEMOID,
		@CERRORMSG=@CERRORMSG OUTPUT
			
		IF @CERRORMSG <> ''
			GOTO END_PROC

	END
    
END TRY
BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM(@cStep)) + ' SQL ERROR: #' + LTRIM(RTRIM(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		-- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG, '''' AS MEMO_ID'
		
		GOTO END_PROC
END CATCH
	
END_PROC:
	

	IF ISNULL(@CMULTIPLECN,'')='1' and isnull(@NCREATEMULTICN,0)=1
		SET @CSTATUSMSG=LTRIM(RTRIM(STR(@NMULTICNCNT)))+' NO. OF CREDIT NOTES ('+@CFIRSTCNNO+'-'+@CLASTCNNO+') GENERATED'
	

	IF @nUpdatemode=1 and @NCREATEMULTICN<>1
	BEGIN
		SET @cStep = 330
		DECLARE @DCNTIME DATETIME 
		SELECT @DCNTIME=CN_TIME FROM CNM01106 WHERE CN_ID=@CKEYFIELDVAL1

		IF EXISTS (SELECT TOP 1'U ' FROM CNM01106 (nolock) WHERE CN_ID<>@CKEYFIELDVAL1 AND CN_TIME=@DCNTIME)
		BEGIN
		   set @CERRORMSG='Duplicate Memo Save Please check'
		END
	END

	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''  
		BEGIN
		   --IF @EDIT_CLICKED=1 
     --           EXEC SP3S_CAPTURE_AUDIT_TRAIL 'WSR',@CMEMOID,'','',@NSPID,@CMACHINENAME,@CWINDOWUSERNAME,@CWIZAPPUSERCODE,0,'1900-01-01',@EDIT_CLICKED
	           
			  commit TRANSACTION
			  DELETE A  FROM XNTYPE_CHECKSUM_MST A  WITH (ROWLOCK)  WHERE SP_ID=@NSPID
			 UPDATE CNM01106 WITH (ROWLOCK) SET LAST_UPDATE=GETDATE(),reconciled=0 WHERE CN_ID=@CKEYFIELDVAL1

		END	
		ELSE
		begin
			ROLLBACK
			DELETE A  FROM XNTYPE_CHECKSUM_MST A  WITH (ROWLOCK)  WHERE SP_ID=@NSPID
		end
	END
	
	IF ISNULL(@BNEGSTOCKFOUND,0)=0 AND @bBlankBillDetails=0
	BEGIN
		INSERT @OUTPUT ( ERRMSG, MEMO_ID,STATUSMSG)
				VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,''),ISNULL(@CSTATUSMSG,'')  )

		SELECT * FROM @OUTPUT	
	END	
	
    EXEC SP_DELETEUPLOADTABLES 'WSR',@nSpId	
	set @CINSSPID=LEFT(@nSpId,38)+@CLOCATIONID 
	EXEC SP_DELETEUPLOADTABLES 'WSR',@CINSSPID	
	--LOG STARTTIME/ENDTIME	
	IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')='' AND ISNULL(@BNEGSTOCKFOUND,0)=0 AND @bBlankBillDetails=0
		EXEC SP3S_LOGPROCESSTIME 'WSR','SAVETRAN EXECUTION',@CKEYFIELDVAL1,@NSPID,1,@DSTARTTIME,@NUPDATEMODE

END						-- SAVETRAN_WSL_CRNOTE
------------------------------------------------------ END OF PROCEDURE SAVETRAN_WSL_CRNOTE