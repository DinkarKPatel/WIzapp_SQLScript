CREATE PROC SAVETRAN_ARO_PLAN
(
	@NUPDATEMODE NUMERIC(1,0),  --@NUPDATEMODE 1 FOR ADD,2 FOR EDIT , 3 for Cancel
	@NSPID	varchar(40),                
	@CMEMOID VARCHAR(40)=''   --@CTEMPLATE_ID CODE REQUIRED FOR EDIT MODE
)
--WITH ENCRYPTION
AS
BEGIN
  DECLARE @CMASTERTABLENAME VARCHAR(100),
          @CTEMPMASTERTABLE VARCHAR(100),
          @CTEMPMASTERTABLENAME VARCHAR(100),
          @CDETAILTABLENAME VARCHAR(100),
          @CTEMPDETAILTABLE VARCHAR(100),
          @CTEMPDETAILTABLENAME VARCHAR(100),
		  @CTEMPDBNAME VARCHAR(100),		
		  @NSTEP VARCHAR(10),
		  @BENABLETEMPDB BIT,
		  @CERRORMSG VARCHAR(500),
		  @NSAVETRANLOOP	BIT,
		  @CCMD NVARCHAR(MAX),
		  @NMEMONOLEN VARCHAR(10),
		  @CKEYFIELD VARCHAR(100),
		  @CMEMONOVAL VARCHAR(100),
		  @CMEMONO VARCHAR(100),
		  @CKEYFIELDVAL VARCHAR(40)
          SET @NSTEP = 0		-- SETTTING UP ENVIRONMENT		
		
			
		SET @CERRORMSG			= ''
        BEGIN TRY
	    BEGIN TRANSACTION
	     
	    SET @NSTEP = 30		--CALL FROM ADD MODE
		IF @NUPDATEMODE = 1
		BEGIN
			SET @NSTEP = 30		-- GENERATING NEW ID
				-- GENERATING NEW ORDER ID
			
			SET @cKeyFieldval = CONVERT(VARCHAR(40),NEWID())
					
			SET @NSTEP = 40	-- UPDATING NEW ID INTO TEMP TABLES
			UPDATE aro_aro_plan_mst_upload SET plan_id=@cKeyFieldval where sp_id=@nSpid
			UPDATE aro_aro_plan_det_upload SET plan_id=@cKeyFieldval where sp_id=@nSpid
			UPDATE aro_aro_plan_link_loc_upload SET plan_id=@cKeyFieldval where sp_id=@nSpid
					
		END--END FROM ADD MODE
	    ELSE
		IF @nUpdatemode=2
		BEGIN
			SELECT @cKeyfieldVal = plan_id FROM aro_aro_plan_mst_upload (NOLOCK) WHERE sp_id=@nSpId
		END
		ELSE
		IF @nUpdatemode=3
		BEGIN
			IF @cMemoId=''
			BEGIN
				SET @cErrormsg='Memo Id required for Cancellation....'
				GOTO END_PROC
			END
			UPDATE aro_plan_mst SET cancelled=1 WHERE plan_id=@cMemoId
			SET @CKEYFIELDVAL=@cMemoId
			GOTO END_PROC
		END

		SET @NSTEP = 50
		UPDATE aro_aro_plan_mst_upload SET last_update=getdate() where sp_id=@nSpid
		UPDATE aro_aro_plan_det_upload SET row_id=newid() where sp_id=@nSpid
		
		IF @nUpdatemode=2
		BEGIN
			DELETE FROM ARO_PLAN_DET WITH (ROWLOCK) WHERE plan_id=@cKeyfieldVal
			DELETE FROM ARO_PLAN_LINK_LOC WITH (ROWLOCK) WHERE plan_id=@cKeyfieldVal
		END

		DECLARE @CFILTERCONDITION VARCHAR(200),@bAddmode BIT

		SET @bAddmode = (CASE WHEN @NUPDATEMODE=1 THEN 1 ELSE 0 END)

		SET @CFILTERCONDITION='b.sp_id='''+@nSpID+''''

		SET @NSTEP = 60 
		EXEC UPDATEMASTERXN_OPT 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = 'ARO_ARO_PLAN_MST_UPLOAD'
			, @CDESTDB		= ''
			, @CDESTTABLE	= 'ARO_PLAN_MST'
			, @CKEYFIELD1	= 'plan_id'
			, @BALWAYSUPDATE = 1
			, @LINSERTONLY = @bAddmode
			, @CFILTERCONDITION=@CFILTERCONDITION
			,@lUpdateXns = 1

		SET @NSTEP = 70 			
		EXEC UPDATEMASTERXN_OPT 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = 'ARO_ARO_PLAN_DET_UPLOAD'
			, @CDESTDB		= ''
			, @CDESTTABLE	= 'ARO_PLAN_DET'
			, @CKEYFIELD1	= 'plan_id'
			, @LINSERTONLY = 1
			, @CFILTERCONDITION=@CFILTERCONDITION
			, @lUpdateXns = 1
		SET @NSTEP = 80 			

		SET @NSTEP = 90 			
		EXEC UPDATEMASTERXN_OPT 
			  @CSOURCEDB	= ''
			, @CSOURCETABLE = 'ARO_ARO_PLAN_link_loc_UPLOAD'
			, @CDESTDB		= ''
			, @CDESTTABLE	= 'ARO_PLAN_link_loc'
			, @CKEYFIELD1	= 'plan_id'
			, @LINSERTONLY = 1
			, @CFILTERCONDITION=@CFILTERCONDITION					   
			, @lUpdateXns = 1
END TRY
BEGIN CATCH
	SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')=''
			COMMIT TRANSACTION
		ELSE
			ROLLBACK 	
	END 
	
	DELETE FROM aro_aro_plan_mst_upload WITH (ROWLOCK) WHERE sp_id=@nSpId
	DELETE FROM aro_aro_plan_det_upload WITH (ROWLOCK) WHERE sp_id=@nSpId
	DELETE FROM aro_aro_plan_link_loc_upload WITH (ROWLOCK) WHERE sp_id=@nSpId
		  		   		     
	SELECT ISNULL(@CERRORMSG,'') AS ERRMSG,@CKEYFIELDVAL AS MEMO_ID
END