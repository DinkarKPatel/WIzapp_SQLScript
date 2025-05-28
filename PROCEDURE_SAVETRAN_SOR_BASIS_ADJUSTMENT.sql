create PROCEDURE SAVETRAN_SOR_BASIS_ADJUSTMENT
(
	@NSPID				VARCHAR(40),
	@CLOCID				VARCHAR(4)=''
)
--WITH ENCRYPTION
AS
BEGIN
	--changes by Dinkar in location id varchar(4)..
	DECLARE @CERRORMSG				VARCHAR(500),
			@CKEYFIELDVAL1			VARCHAR(50),@CMEMONOVAL VARCHAR(10),
			@CLOCATIONID			VARCHAR(4),
			@CCMD					NVARCHAR(4000),@cProductCode VARCHAR(50),
			@CCMDOUTPUT				NVARCHAR(4000),@NSAVETRANLOOP BIT,
			@NSTEP varchar(10),@CMEMONOPREFIX VARCHAR(10),@cFinYear varchar(10)

	DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))



BEGIN TRY	

	SET @NSTEP = '5'		-- SETTTING UP ENVIRONMENT
	
	SET @CERRORMSG			= ''
	
	IF ISNULL(@CLOCID,'')=''
		SELECT @CLOCATIONID	= DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
	ELSE
		SELECT @CLOCATIONID=@CLOCID
	
	SET @NSTEP = '10'		

	IF ISNULL(@CLOCATIONID,'')=''
	BEGIN
		SET @CERRORMSG = 'STEP- ' + LTRIM(@NSTEP) + ' LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	END
	
    
	SET @NSTEP = 20  -- GENERATING NEW KEY  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
	-- GENERATING NEW MEMO NO    

	SELECT TOP 1 @cFinYear=FIN_YEAR FROM soradj_sor_basis_adjustment_mst_upload (NOLOCK)
	WHERE sp_id=@nSpId
		
	IF @cFinYear IS NULL
	BEGIN
		SET @CERRORMSG='No data found in master Upload table..Please check'
		GOTO END_PROC
	END

	IF NOT EXISTS (SELECT TOP 1 memo_id FROM soradj_sor_basis_adjustment_det_upload (NOLOCK) WHERE sp_id=@nSpId
					AND (ISNULL(old_sor_terms_code,'')<>isnull(new_sor_terms_code,'') AND
					isnull(new_sor_terms_code,'') NOT IN ('','000')))
	BEGIN
		SET @CERRORMSG='No Sor Terms Data changes found..Please check'
		GOTO END_PROC
	END

	SET @NSTEP = 25  -- UPDATING TRANSACTION TABLE  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
	
	UPDATE soradj_sor_basis_adjustment_det_upload WITH (ROWLOCK) SET old_sor_terms_code='000'
	WHERE sp_id=@nSpId AND ISNULL(old_sor_terms_code,'')=''

	IF EXISTS (SELECT TOP 1 memo_id FROM soradj_sor_basis_adjustment_det_upload (NOLOCK) WHERE sp_id=@nSpId
			   AND old_sor_terms_code=new_sor_terms_code)
	BEGIN
		SET @NSTEP = 30  -- UPDATING TRANSACTION TABLE  
		EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  

		SELECT TOP 1 @cProductCode=product_code FROM soradj_sor_basis_adjustment_det_upload a (NOLOCK)
		JOIN cmd01106 b (NOLOCK) ON a.cmd_row_id=b.row_id 
		WHERE sp_id=@nSpId AND old_sor_terms_code=new_sor_terms_code

		SET @CERRORMSG='Item Code :'+@cProductCode+' is not having any Sor Terms change...Please check'
		GOTO END_PROC
	END

	BEGIN TRAN
			 
	SET @NSAVETRANLOOP=0  
	WHILE @NSAVETRANLOOP=0  
	BEGIN  
		SET @NSTEP = 35
		EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  	
	    EXEC GETNEXTKEY  'sor_basis_adjustment_mst', 'memo_no', 10,@cLocationId, 1,  
			@CFINYEAR,0, @CMEMONOVAL OUTPUT     
			      
		PRINT @CMEMONOVAL  
		SET @NSTEP = 37
		EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  	
		IF EXISTS ( SELECT memo_no FROM sor_basis_adjustment_mst (NOLOCK)   
					WHERE memo_no=@cMemonoVal AND fin_year=@cFinYear)  
			SET @NSAVETRANLOOP=0  
		ELSE  
			SET @NSAVETRANLOOP=1

	END  
		  
	IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
	BEGIN  
		SET @CERRORMSG = ' ERROR CREATING NEXT MEMO NO....'   
		GOTO END_PROC      
	END  
		  
	SET @NSTEP = 40  -- GENERATING NEW ID  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
	-- GENERATING NEW JOB ORDER ID  
	SET @CKEYFIELDVAL1 = @CLOCATIONID+LTRIM(RTRIM(CONVERT(VARCHAR(38),NEWID())))
		  
	SET @NSTEP = 45  -- UPDATING NEW ID INTO TEMP TABLES  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
		     
	-- UPDATING NEWLY GENERATED JOB ORDER NO AND JOB ORDER ID IN PIM AND PID TEMP TABLES  
	UPDATE soradj_sor_basis_adjustment_mst_upload  WITH (ROWLOCK) SET memo_no=@CMEMONOVAL,memo_id=@CKEYFIELDVAL1
	WHERE sp_id=@nSpId
		     
	SET @NSTEP = 50
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
		        
	-- RECHECKING IF ID IS STILL LATER  
	IF @CKEYFIELDVAL1 IS NULL
	BEGIN  
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
		GOTO END_PROC  
	END  
	  

	 
	-- UPDATING MASTER TABLE (PIM01106) FROM TEMP TABLE  
	SET @NSTEP = 60
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  

	DECLARE @CFILTERCONDITION VARCHAR(100)
	SET @CFILTERCONDITION='  sp_id='''+@nSPId+''''
	  
	--SAVING MASTER TABLE
    EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
	  @CSOURCEDB = ''  
	, @CSOURCETABLE = 'soradj_sor_basis_adjustment_mst_upload'  
	, @CDESTDB  = ''  
	, @CDESTTABLE = 'sor_basis_adjustment_mst'
	, @CKEYFIELD1 = 'memo_id'  
	, @CFILTERCONDITION=@CFILTERCONDITION  
	, @lInsertonly=1
	, @lUpdatexns=1
		  
	-- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE  
	SET @NSTEP = 65  -- UPDATING TRANSACTION TABLE  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
	     
	-- UPDATING ROW_ID IN TEMP TABLES - CMD01106  
	UPDATE soradj_sor_basis_adjustment_det_upload WITH (ROWLOCK) SET 
	ROW_ID = @CLOCATIONID +CONVERT(VARCHAR(40), NEWID()),memo_id=@CKEYFIELDVAL1 WHERE sp_id=@nSpId

	SET @NSTEP = 70  -- UPDATING TRANSACTION TABLE  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
	--SAVING MASTER TABLE
    EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
	  @CSOURCEDB = ''  
	, @CSOURCETABLE = 'soradj_sor_basis_adjustment_det_upload'  
	, @CDESTDB  = ''  
	, @CDESTTABLE = 'sor_basis_adjustment_det'
	, @CKEYFIELD1 = 'memo_id'  
	, @CFILTERCONDITION=@CFILTERCONDITION  
	, @lInsertonly=1
	, @lUpdatexns=1

	-- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE  
	SET @NSTEP = 75  -- UPDATING TRANSACTION TABLE  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  

	UPDATE A  SET A.SOR_TERMS_CODE=B.new_SOR_TERMS_CODE	FROM CMD01106 A WITH (ROWLOCK)
	JOIN soradj_sor_basis_adjustment_det_upload B (NOLOCK) On B.cmd_ROW_ID=A.ROW_ID
	WHERE b.sp_id=@nSpId AND ISNULL(A.SOR_TERMS_CODE,'''')<>B.new_SOR_TERMS_CODE

	GOTO END_PROC
					
END TRY
	
BEGIN CATCH
	SET @CERRORMSG = 'Procedure SAVETRAN_SOR_BASIS_ADJUSTMENT STEP# ' + LTRIM(@NSTEP) + ' ' + ERROR_MESSAGE()
		
	GOTO END_PROC
END CATCH
	
END_PROC:
	
	SET @NSTEP = 80  -- UPDATING TRANSACTION TABLE  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  
		
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' --AND ISNULL(@CCMDOUTPUT,'')='' AND ISNULL(@BNEGSTOCKFOUND,0)=0
		BEGIN
			COMMIT TRANSACTION
		END
		ELSE
			ROLLBACK
	END
	
	SET @NSTEP = 85  -- UPDATING TRANSACTION TABLE  
	EXEC SP_CHKXNSAVELOG 'soradj',@nStep,0,@nSpid  

	DELETE FROM soradj_sor_basis_adjustment_mst_upload WITH (ROWLOCK) WHERE SP_ID= @NSPID
	DELETE FROM soradj_sor_basis_adjustment_det_upload WITH (ROWLOCK) WHERE SP_ID= @NSPID

	SELECT ISNULL(@cErrormsg,'') errmsg,isnull(@ckeyfieldval1,'') memo_id
END