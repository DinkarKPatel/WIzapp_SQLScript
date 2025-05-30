create PROCEDURE SAVETRAN_SLS_VOUCHER
(
 @NSPID VARCHAR(50),
  @CWIZAPPUSERCODE VARCHAR(10)='0000000'    
)
AS
BEGIN
	
				--changes by Dinkar in location id varchar(4)..
	 DECLARE  @CTEMPDBNAME			VARCHAR(100),@CERRVMID VARCHAR(40),    
     @CMASTERTABLENAME		VARCHAR(100),    
     @CDETAILTABLENAME		VARCHAR(100),    
     @CDETAILTABLENAME1		VARCHAR(100), 
     @CDETAILTABLENAME2		VARCHAR(100),
     @CDETAILTABLENAME3		VARCHAR(100),   
     @CTEMPMASTERTABLENAME	VARCHAR(100),    
     @CTEMPDETAILTABLENAME	VARCHAR(100),    
     @CTEMPDETAILTABLENAME1 VARCHAR(100),  
     @CTEMPDETAILTABLENAME2 VARCHAR(100),	       
     @CTEMPDETAILTABLENAME2ADJLINK VARCHAR(100),	       
     @CTEMPDETAILTABLENAME3 VARCHAR(100),	       
     @CTEMPMASTERTABLE		VARCHAR(100),    
     @CTEMPDETAILTABLE		VARCHAR(100),    
     @CTEMPDETAILTABLE1		VARCHAR(100),    
     @CTEMPDETAILTABLE2		VARCHAR(100),  
     @CTEMPDETAILTABLE2ADJLINK VARCHAR(100),
     @CTEMPDETAILTABLE3		VARCHAR(100),  
     @CERRORMSG				VARCHAR(500),      
     @CKEYFIELD1			VARCHAR(50),    
     @CKEYFIELDVAL1			VARCHAR(50),    
     @CMEMONO				VARCHAR(20),    
     @NMEMONOLEN			NUMERIC(20,0),    
     @CMEMONOVAL			VARCHAR(50),    
     @CMEMODEPTID			VARCHAR(4),    
     @CLOCATIONID			VARCHAR(4),    
     @CHODEPTID				VARCHAR(4),    
     @CCMD					NVARCHAR(4000),    
     @NSAVETRANLOOP			BIT,    
     @CSTEP					VARCHAR(10),       
     @CMSG                  VARCHAR(200),
     @CBOPINDENTTABLENAME   VARCHAR(100), 
     @CTEMPBOPINDENTTABLENAME VARCHAR(100),
     @CTEMPBOPINDENTTABLE     VARCHAR(100),
     @CFLAG		              BIT,
     @CVMID					VARCHAR(40),
     @CVMNO					VARCHAR(10),
     @CPREFIXVALUE			VARCHAR(3),
     @DTVOUCHERDATA			DATETIME,
     @NVOUCHORNO_MODE		INT,
     @CDEPT_ID  VARCHAR(5),
     @CXNTYPE  VARCHAR(10) ,@CVOUCHERCODE VARCHAR(10),
     @BEXISTS BIT,
     @CTEMPDB VARCHAR(500),
     @BBILLBYBILL BIT,@NCDPCT INT,@CFILTERCONDITION VARCHAR(500),
     @BCALLEDFROMDIRECTVOUCHERENTRY BIT,@NDRTOTAL NUMERIC(14,4),@NCRTOTAL NUMERIC(14,4),
     @CBILLTYPE VARCHAR(10),@DVMDT DATETIME,@COTHERVMID VARCHAR(50),@CVMLOCID VARCHAR(5),
     @CRETAILSALEACCODE CHAR(10),@CRETAILSALEACNAME VARCHAR(500),@BSALEACMISMATCHCREATED BIT,
     @CREFNO VARCHAR(100),@NADJAMT NUMERIC(10,2),@NBILLAMT NUMERIC(10,2),@BLOOP BIT,@CFINYEAR VARCHAR(10)
     ,@cHEAD_CODE VARCHAR(MAX)
	     
BEGIN TRY    
			
 
    SET @CSTEP = 10         

    DECLARE @OUTPUT TABLE
	(
		XN_ID	VARCHAR(40),XN_TYPE VARCHAR(30),XN_NO VARCHAR(40),
		XN_DT DATETIME,XN_AMT NUMERIC(14,2),XN_AC VARCHAR(100),
		ERR_DESC VARCHAR(500),DEPT_ID VARCHAR(5)
	)   
	    
	DECLARE @CACCODE VARCHAR(20),@CVDID VARCHAR(10),@CXNID VARCHAR(100),@CBILLNO VARCHAR(100),
			@NAMOUNT NUMERIC(10,2),@NCRDAYS NUMERIC(5) 
	
	SET @CSTEP = 20 
	SELECT @NVOUCHORNO_MODE = ISNULL(VALUE,0) FROM CONFIG WHERE CONFIG_OPTION = 'VOUCHER_NO_SYSTEM' 
	
	SET @CSTEP = 25 
	SET @CKEYFIELD1   = 'VM_ID'    
	SET @CMEMONO   = 'VOUCHER_NO' 
			
LBLSTART:

	BEGIN TRANSACTION   
	
	SET @CSTEP = 30 
	/*
	   DEBIT AMOUNT MUST BE EQUAL TO CREDIT AMOUNT IN VM01106.
	*/
	
		UPDATE ACT_VM01106_UPLOAD SET USER_CODE=@CWIZAPPUSERCODE WHERE SP_ID=@NSPID
	
    IF EXISTS (SELECT TOP 1 VM_ID FROM ACT_VM01106_UPLOAD WHERE SP_ID=@NSPID AND CRTOTAL <> DRTOTAL)
    BEGIN
		INSERT @OUTPUT (XN_DT,DEPT_ID,ERR_DESC)
		SELECT VOUCHER_DT,DEPT_ID,'DEBIT AMOUNT ('+LTRIM(RTRIM(STR(DRTOTAL,10,2)))+') IS NOT EQUAL TO CREDIT AMOUNT('+LTRIM(RTRIM(STR(CRTOTAL,10,2)))+')'
		FROM ACT_VM01106_UPLOAD WHERE SP_ID=@NSPID AND CRTOTAL <> DRTOTAL
	END
	
		 	

	
	INSERT @OUTPUT (XN_DT,DEPT_ID,ERR_DESC)
	SELECT B.VOUCHER_DT,B.DEPT_ID,'DIFFERENCE IN DETAILED DEBIT AMOUNT :'+LTRIM(RTRIM(STR(SUM(DEBIT_AMOUNT),10,2)))+
	' AND CREDIT AMOUNT :'+LTRIM(RTRIM(STR(SUM(CREDIT_AMOUNT),10,2))) 
	FROM ACT_VD01106_UPLOAD A
	JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.VM_ID AND a.sp_id=b.sp_id
	WHERE B.SP_ID=@NSPID
	GROUP BY B.VOUCHER_DT,B.DEPT_ID HAVING ABS(SUM(DEBIT_AMOUNT)-SUM(CREDIT_AMOUNT))>0
	

	INSERT @OUTPUT (XN_DT,DEPT_ID,ERR_DESC)
	SELECT B.VOUCHER_DT,B.DEPT_ID,'BLANK A/C NAME NOT ALLOWED '
	FROM ACT_VD01106_UPLOAD A
	JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.VM_ID AND a.sp_id=b.sp_id
	WHERE B.SP_ID=@NSPID AND A.SP_ID=@NSPID AND ISNULL(A.AC_CODE,'') IN ('','0000000000')
	
	PRINT 'DELETE ERROR VOUCHERS'
	
	SET NOCOUNT OFF
	
	
	DELETE A FROM ACT_POSTACT_VOUCHER_LINK_UPLOAD A JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.VM_ID
	JOIN @OUTPUT C ON C.DEPT_ID=B.DEPT_ID AND B.VOUCHER_DT=C.XN_DT
	WHERE A.SP_ID=@NSPID 
	
	DELETE A FROM ACT_BILL_BY_BILL_REF_UPLOAD A JOIN ACT_VD01106_UPLOAD B ON A.VD_ID=B.VD_ID  AND A.VM_ID=B.VM_ID AND A.SP_ID=B.SP_ID
	JOIN ACT_VM01106_UPLOAD C ON C.VM_ID=B.VM_ID AND C.SP_ID=B.SP_ID
	JOIN @OUTPUT D ON D.DEPT_ID=C.DEPT_ID AND C.VOUCHER_DT=D.XN_DT
	WHERE A.SP_ID=@NSPID

	DELETE A FROM ACT_VD01106_UPLOAD A JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.VM_ID AND A.SP_ID=B.SP_ID
	JOIN @OUTPUT C ON C.DEPT_ID=B.DEPT_ID AND B.VOUCHER_DT=C.XN_DT
	WHERE A.SP_ID=@NSPID
		
	DELETE A FROM ACT_VM01106_UPLOAD A JOIN @OUTPUT B ON A.DEPT_ID=B.DEPT_ID AND A.VOUCHER_DT=B.XN_DT
	WHERE A.SP_ID=@NSPID
	
	
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT TOP 1 * FROM ACT_VM01106_UPLOAD WHERE SP_ID=@NSPID)
		GOTO END_PROC
	
	
	
	SET @CSTEP=55
	UPDATE ACT_VM01106_UPLOAD SET TEMP_VM_ID=VM_ID WHERE SP_ID=@NSPID													
	UPDATE ACT_VD01106_UPLOAD SET TEMP_VD_ID=VD_ID WHERE SP_ID=@NSPID
	
	SET @CSTEP=56
	UPDATE act_vd01106_upload WITH (ROWLOCK) SET X_TYPE='Dr' WHERE sp_id=@nSpid AND X_TYPE='DR'

	SET @CSTEP=58
	UPDATE act_vd01106_upload WITH (ROWLOCK)  SET X_TYPE='Cr' WHERE sp_id=@nSpid AND X_TYPE='CR'
			
	SET @CSTEP=60
	DELETE A FROM BILL_BY_BILL_REF A 
	JOIN VD01106 B ON A.VD_ID = B.VD_ID 
	JOIN VM01106 C ON B.VM_ID = C.VM_ID 
	JOIN ACT_VM01106_UPLOAD D ON D.VOUCHER_DT=C.VOUCHER_DT AND D.DEPT_ID=C.DEPT_ID 
	WHERE C.BILL_TYPE='SLS' AND C.CANCELLED=0 AND D.SP_ID=@NSPID
	
	SET @CSTEP=63
	DELETE A FROM POSTACT_VOUCHER_LINK A 
	JOIN VM01106 B ON B.VM_ID = A.VM_ID 
	JOIN ACT_VM01106_UPLOAD C ON C.VOUCHER_DT=B.VOUCHER_DT AND C.DEPT_ID=B.DEPT_ID 
	WHERE B.BILL_TYPE='SLS' AND B.CANCELLED=0 AND C.SP_ID=@NSPID
	
	SET @CSTEP=65
	
	IF OBJECT_ID('TEMPDB..#TMPBANKRECO','U') IS NOT NULL
		DROP TABLE #TMPBANKRECO
	
	SET @cHEAD_CODE = DBO.FN_ACT_TRAVTREE('0000000013') ----ADD VARIABLE BY GAURI ON 17/4/2019
	
	SELECT A.COST_CENTER_DEPT_ID,B.VOUCHER_DT,A.RECON_DT,A.AC_CODE INTO #TMPBANKRECO 
	FROM  VD01106 A JOIN VM01106 B ON A.VM_ID=B.VM_ID
	JOIN ACT_VM01106_UPLOAD C ON C.VOUCHER_DT=B.VOUCHER_DT AND C.DEPT_ID=B.DEPT_ID 
	JOIN LM01106 D ON D.AC_CODE=A.AC_CODE
	WHERE B.BILL_TYPE='SLS' AND B.CANCELLED=0 AND C.SP_ID=@NSPID 
	AND CHARINDEX(D.HEAD_CODE,@cHEAD_CODE)>0 AND RECON_DT<>''	----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019
	AND B.CANCELLED=0
	 
	SET @CSTEP=70
	DELETE A FROM  VD01106 A JOIN VM01106 B ON A.VM_ID=B.VM_ID
	JOIN ACT_VM01106_UPLOAD C ON C.VOUCHER_DT=B.VOUCHER_DT AND C.DEPT_ID=B.DEPT_ID 
	WHERE B.BILL_TYPE='SLS' AND B.CANCELLED=0 AND C.SP_ID=@NSPID
	
	SET @CSTEP=75
	DELETE A FROM  VM01106 A JOIN ACT_VM01106_UPLOAD B ON B.VOUCHER_DT=A.VOUCHER_DT 
	AND B.DEPT_ID=A.DEPT_ID 
	WHERE A.BILL_TYPE='SLS' AND A.CANCELLED=0 AND B.SP_ID=@NSPID

   	
   SET @CSTEP=80		
	
   --GENRATE VM_ID 
   UPDATE ACT_VM01106_UPLOAD SET VM_ID = DEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID())))
   WHERE SP_ID=@NSPID AND LEFT(VM_ID,5)='LATER'
     			       
   SET @CSTEP = 90
   --CHECK FOR GENRATE UNIQUE VM ID 
   SET @CFLAG = 0 
   WHILE @CFLAG=0
   BEGIN
		PRINT 'GENERATING VM_ID IN TEMP DATA'
		IF EXISTS (SELECT TOP 1 A.VM_ID FROM ACT_VM01106_UPLOAD A JOIN VM01106 B ON A.VM_ID=B.VM_ID
				   WHERE SP_ID=@NSPID)
		BEGIN
		   UPDATE A SET A.VM_ID = A.DEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))) 
		   FROM ACT_VM01106_UPLOAD A 
		   JOIN VM01106 B ON A.VM_ID = B.VM_ID 
		   WHERE SP_ID=@NSPID AND LEFT(A.VM_ID,5)='LATER'
		END
		ELSE
		BEGIN
			SET @CFLAG = 1
		END 
   END
   
   SET @CSTEP = 260
   SET @BLOOP=1
   
   WHILE @BLOOP=1
   BEGIN
	  PRINT 'GENERATING VOUCHER NO. IN TEMP DATA-1'
	  
	  SET @CVMID=''
	  
	  SELECT TOP 1 @CVMID=VM_ID,@CDEPT_ID=DEPT_ID,@CVOUCHERCODE= VOUCHER_CODE,
	               @DTVOUCHERDATA=VOUCHER_DT,@CFINYEAR=FIN_YEAR  FROM ACT_VM01106_UPLOAD
	  WHERE SP_ID=@NSPID AND LEFT(VOUCHER_NO,5)='LATER'             
	 
	  
	  IF ISNULL(@CVMID,'')=''
		BREAK
							  
	  SET @CPREFIXVALUE = @CDEPT_ID
	                            
	                            
	  SET @NSAVETRANLOOP=0
	  WHILE @NSAVETRANLOOP=0    
	  BEGIN					    
		 PRINT 'GENERATING VM_ID IN TEMP DATA-2' 
    	 SET @CSTEP=290    
		 EXEC GETNEXTVCHNO  
			@DVCHDT=@DTVOUCHERDATA,
			@CVCHCODE=@CVOUCHERCODE,
			@NMODE=@NVOUCHORNO_MODE,
			@NWIDTH=10,
			@CCOMPANYCODE='01',
			@CPREFIX=@CPREFIXVALUE,
			@CFINYEAR=@CFINYEAR,
			@CNEWKEYVAL=@CMEMONOVAL OUTPUT  
	     
	     IF ISNULL(@CMEMONOVAL,'')=''
		 BEGIN
			SET @CERRORMSG = 'P:SAVETRAN_SLS_VOUCHERENTRY, STEP: '+@CSTEP+', MESSAGE: ERROR GENERATING MEMO_NO...'    
			GOTO END_PROC
		 END
	     
		 SET @CSTEP=330   
		 SET @NSAVETRANLOOP=1
		 
	 END
		  
	 SET @CSTEP=360
	 
	 UPDATE ACT_VM01106_UPLOAD SET VOUCHER_NO = @CMEMONOVAL,VM_NO=@CMEMONOVAL WHERE SP_ID=@NSPID
	 AND dept_id=@CDEPT_ID 
	 	 
	 IF NOT EXISTS (SELECT TOP 1 VM_ID FROM ACT_VM01106_UPLOAD WHERE SP_ID=@NSPID AND LEFT(VOUCHER_NO,5)='LATER')
	 BEGIN
		SET @BLOOP=0
		BREAK
	 END	
  
   END	
   
   --GENRATE VD_ID 
   SET @CSTEP=430
   UPDATE A SET VD_ID = RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))) FROM ACT_VD01106_UPLOAD A
   WHERE A.SP_ID=@NSPID
   
   --CHECK FOR GENRATE UNIQUE VD_ID
   SET @CSTEP=450
   SET @CFLAG = 0 
   WHILE @CFLAG=0
   BEGIN
		PRINT 'GENERATING VD_ID IN TEMP DATA'
		IF EXISTS (SELECT TOP 1 A.VD_ID FROM ACT_VD01106_UPLOAD A JOIN VD01106 B ON A.VD_ID=B.VD_ID
				   WHERE A.SP_ID=@NSPID)
		BEGIN
			   UPDATE A SET A.VD_ID = @CDEPT_ID+RTRIM(LTRIM(CONVERT(VARCHAR(40),NEWID()))) 
			   FROM ACT_VD01106_UPLOAD A 
			   JOIN VD01106 B ON A.VD_ID = B.VD_ID
			   WHERE A.SP_ID=@NSPID 
		END
		ELSE
		BEGIN
			SET @CFLAG = 1
		END 
   END

  ---UPDATE VD_ID IN TEMP BILL_BY_BILL_REF TABLE 
  SET @CSTEP=470
  UPDATE A SET VD_ID=B.VD_ID,VM_ID=C.VM_ID FROM ACT_BILL_BY_BILL_REF_UPLOAD A 
  JOIN ACT_VD01106_UPLOAD B ON A.VD_ID=B.TEMP_VD_ID AND A.VM_ID=B.VM_ID AND A.SP_ID=B.SP_ID
  JOIN ACT_VM01106_UPLOAD C ON C.TEMP_VM_ID=A.VM_ID AND A.SP_ID=C.SP_ID
  WHERE A.SP_ID=@NSPID
   
  --UPDATE VM_ID IN TEMP VD01106 TABLE 

  SET @CSTEP=460
  UPDATE A SET VM_ID=B.VM_ID FROM ACT_VD01106_UPLOAD A 
  JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.TEMP_VM_ID AND A.SP_ID=B.SP_ID
  WHERE A.SP_ID=@NSPID 
  
  ---UPDATE VM_ID IN  POSTACT_VOUCHER_LINK  
  SET @CSTEP=470
  UPDATE A SET VM_ID=B.VM_ID FROM ACT_POSTACT_VOUCHER_LINK_UPLOAD A 
  JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.TEMP_VM_ID AND A.SP_ID=B.SP_ID
  WHERE A.SP_ID=@NSPID
   
  SET @CFILTERCONDITION=' B.SP_ID= '+LTRIM(RTRIM(STR(@NSPID)))
  
  SET @CSTEP=475
  
  UPDATE A SET COST_CENTER_DEPT_ID =B.DEPT_ID FROM ACT_VD01106_UPLOAD A 
  JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.VM_ID AND a.sp_id=b.sp_id
  WHERE A.SP_ID=@NSPID AND ISNULL(a.COST_CENTER_DEPT_ID,'')=''

  ---- RETAIN THE BANK RECO DATE FROM THE OLD VOUCHERS POSTED
  SET @CSTEP=480
  UPDATE A SET RECON_DT=C.RECON_DT FROM ACT_VD01106_UPLOAD A 
  JOIN ACT_VM01106_UPLOAD B ON A.VM_ID=B.VM_ID AND A.SP_ID=B.SP_ID
  JOIN #TMPBANKRECO C ON C.COST_CENTER_DEPT_ID=A.COST_CENTER_DEPT_ID AND C.VOUCHER_DT=B.VOUCHER_DT AND C.AC_CODE=A.AC_CODE
  WHERE A.SP_ID=@NSPID
   
  	          	      
  ---INSERT/UPDATE VM01106
  SET @CSTEP=490
  EXEC UPDATEMASTERXN_OPT
		 @CSOURCEDB = ''  
	   , @CSOURCETABLE = 'ACT_VM01106_UPLOAD'
	   , @CDESTDB  = ''    
	   , @CDESTTABLE = 'VM01106'
	   , @CKEYFIELD1 = 'VM_ID'    
	   , @LINSERTONLY=0
	   , @CFILTERCONDITION = @CFILTERCONDITION 
  
  ---INSERT/UPDATE VD01106
  SET @CSTEP = 500  
  EXEC UPDATEMASTERXN_OPT  
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'ACT_VD01106_UPLOAD'
	   , @CDESTDB  = ''    
	   , @CDESTTABLE = 'VD01106'    
	   , @CKEYFIELD1 = 'VD_ID' 
	   , @LINSERTONLY =1   
	   , @CFILTERCONDITION = @CFILTERCONDITION
	   	
  --INSERT/UPDATE POSTACT_VOUCHER_LINK
  SET @CSTEP = 510  
  EXEC UPDATEMASTERXN_OPT     
		 @CSOURCEDB = ''
	   , @CSOURCETABLE = 'ACT_POSTACT_VOUCHER_LINK_UPLOAD'
	   , @CDESTDB  = ''    
	   , @CDESTTABLE = 'POSTACT_VOUCHER_LINK'    
	   , @CKEYFIELD1 = 'VM_ID'
	   , @LINSERTONLY=1
	   , @CFILTERCONDITION = @CFILTERCONDITION
	
  SET @CSTEP = 513  
  UPDATE ACT_BILL_BY_BILL_REF_UPLOAD SET BB_ROW_ID=NEWID() WHERE SP_ID=@NSPID
  
  		
  --INSERT/UPDATE BILL_BY_BILL_REF
  SET @CSTEP = 516
  EXEC UPDATEMASTERXN_OPT    
	 @CSOURCEDB = ''    
   , @CSOURCETABLE = 'ACT_BILL_BY_BILL_REF_UPLOAD'
   , @CDESTDB  = ''    
   , @CDESTTABLE = 'BILL_BY_BILL_REF'
   , @CKEYFIELD1 = 'VD_ID'
   , @LINSERTONLY = 1
   , @CFILTERCONDITION = @CFILTERCONDITION
   
	/*
		VALIDATION THAT AMOUNT IN BILL_BY_BILL FOR A VD_ID SHOULD BE EQUAL TO 
		THAT OF AMOUNT IN VD01106
	*/
	
	SET @CSTEP = 520
		
	SELECT A.VOUCHER_DT AS XN_DT,C.COST_CENTER_DEPT_ID AS DEPT_ID,DBO.FN_CHECK_DUPBBREF('',VD_ID) AS ERR_DESC
	INTO #TMPERRDUPBBREF FROM VM01106 A JOIN ACT_VM01106_UPLOAD B ON A.VOUCHER_DT=B.VOUCHER_DT AND A.DEPT_ID=B.DEPT_ID
	JOIN VD01106 C ON C.VM_ID=A.VM_ID WHERE B.SP_ID=@NSPID AND A.BILL_TYPE='SLS' AND A.CANCELLED=0

	IF EXISTS (SELECT TOP 1 XN_DT FROM #TMPERRDUPBBREF WHERE ISNULL(ERR_DESC,'')<>'')
	BEGIN
		SELECT TOP 1 @CERRORMSG=ERR_DESC FROM #TMPERRDUPBBREF WHERE ISNULL(ERR_DESC,'')<>''
		
		INSERT @OUTPUT (XN_DT,DEPT_ID,ERR_DESC)	
		SELECT XN_DT,DEPT_ID,ERR_DESC FROM #TMPERRDUPBBREF WHERE ISNULL(ERR_DESC,'')<>''
	END
	
	SELECT vm_id,count(distinct cost_center_dept_id) cnt INTO #tmpVmcc FROM 
	ACT_VD01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
	GROUP BY vm_id HAVING count(distinct cost_center_dept_id)>1

	set nocount off
	SET @cVmId=''
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpVmcc)
	BEGIN
		SET @CSTEP=525

		SELECT TOP 1 @cVmId=vm_id FROM  #tmpVmCc

		--if @@spid=83
		--	select 'before check multicc',autoentry,cost_center_dept_id, @cVmId vmid,@CERRORMSG errmsg,* from vd01106 (nolock)
		--	where vm_id=@cVmId

		EXEC SP3S_VALIDATE_COSTCENTER_ENTRIES
		@NMODE=2,
		@cVmid=@cVmId,
		@CERRORMSG=@CERRORMSG OUTPUT
		
		
		--if @@spid=83
		--	select 'after check multicc',autoentry,cost_center_dept_id,@cVmId vmid,@CERRORMSG errmsg,* from vd01106 (nolock)
		--	where vm_id=@cVmId
				
		IF ISNULL(@CERRORMSG,'')<>''
			GOTO END_PROC		   	
		
		DELETE FROM  #tmpVmCC WHERE vm_id=@cVmId
	END 		

	SET @cStep=527


	INSERT @OUTPUT (XN_DT,DEPT_ID,ERR_DESC)
	SELECT B.VOUCHER_DT,DEPT_ID,'MISMATCH FOUND IN BILL BY BILL ENTRY AGST. BILL NO.: '+B.BILL_NO+' FOR LEDGER NAME :'+LM.AC_NAME+' LEDGER AMT : '+
	LTRIM(RTRIM(STR((A.CREDIT_AMOUNT-A.DEBIT_AMOUNT),10,2)))+' BILL BY BILL AMT:'+LTRIM(RTRIM(STR(ISNULL(C.AMOUNT,0),10,2)))+' .CANNOT PROCEED' 
	FROM VD01106 A (NOLOCK)
	JOIN ACT_VM01106_UPLOAD B (NOLOCK) ON A.VM_ID=B.VM_ID
	JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE=A.AC_CODE
	JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=LMP.AC_CODE
	LEFT OUTER JOIN 
	(
	 SELECT b.VM_ID,A.VD_ID,SUM(CASE WHEN A.X_TYPE='CR' THEN AMOUNT ELSE -AMOUNT END) AS AMOUNT
	 FROM BILL_BY_BILL_REF A   (NOLOCK)
	 JOIN VD01106 B (NOLOCK) ON A.VD_ID=B.VD_ID 
	 JOIN ACT_VM01106_UPLOAD C (NOLOCK) ON B.VM_ID=C.VM_ID
	 WHERE C.SP_ID=@NSPID 
	 GROUP BY A.VD_ID,b.VM_ID
	 )C ON A.VD_ID=C.VD_ID AND C.VM_ID=A.VM_ID
	 WHERE B.SP_ID=@NSPID  AND ABS((A.CREDIT_AMOUNT-A.DEBIT_AMOUNT)-ISNULL(C.AMOUNT,0))>.1		
	 AND LMP.BILL_BY_BILL=1

	SET @CSTEP = 530	
	DECLARE @dMinVchDt DATETIME

	SELECT @dMinVchDt=min(voucher_dt) FROM act_vm01106_upload (NOLOCK) WHERE sp_id=@nSpId

	IF NOT EXISTS (SELECT voucher_dt FROM vch_last_saved)
		INSERT vch_last_saved (voucher_dt)
		SELECT @dMinVchDt
	ELSE
		update vch_last_saved set voucher_dt=@dMinVchDt WHERE voucher_dt>@dMinVchDt
	
	 

	SET @CSTEP = 550	
	DELETE FROM ACT_VM01106_UPLOAD WHERE SP_ID=@NSPID
	DELETE FROM ACT_VD01106_UPLOAD WHERE SP_ID=@NSPID
	DELETE FROM ACT_BILL_BY_BILL_REF_UPLOAD WHERE SP_ID=@NSPID
	DELETE FROM ACT_POSTACT_VOUCHER_LINK_UPLOAD WHERE SP_ID=@NSPID
	
	GOTO END_PROC  
	 
END TRY
BEGIN CATCH
		 SET @CERRORMSG = 'P:SAVETRAN_SLS_VOUCHER, SPIDVC :'+LTRIM(RTRIM(STR(@NSPID)))+' STEP: '+@CSTEP+', MESSAGE: '+ ERROR_MESSAGE()    
		 GOTO END_PROC
END CATCH

END_PROC:
	
	IF ISNULL(@CERRORMSG,'')<>'' AND NOT EXISTS (SELECT TOP 1 * FROM @OUTPUT)
		INSERT @OUTPUT (XN_DT,DEPT_ID,ERR_DESC)
		SELECT '' AS XN_DT,'' AS DEPT_ID,@CERRORMSG
	
					
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')=''
		BEGIN
			COMMIT

			PRINT 'COMMIT POSTING SAVE SLS'
		END	
		ELSE
		BEGIN
			PRINT 'ROLLBACK POSTING SAVE SLS'
			ROLLBACK	
		END	
	END	

	SELECT ERR_DESC AS ERRMSG,ISNULL(XN_ID,'') AS MEMO_ID,ISNULL(XN_NO,'') AS VOUCHER_NO FROM @OUTPUT ORDER BY XN_DT
END 	
--END OF PROCEDURE - SAVETRAN_SLS_VOUCHER

