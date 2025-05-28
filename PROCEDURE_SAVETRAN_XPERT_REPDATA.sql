CREATE PROCEDURE SAVETRAN_XPERT_REPDATA
@nUpdatemode NUMERIC(1,0),
@cMemoIdPara VARCHAR(20)=''
AS
BEGIN
--changes by Dinkar in location id varchar(4)..
    DECLARE  @LENABLETEMPDATABASE	BIT,@CTEMPDBNAME VARCHAR(100),@NSTEP VARCHAR(5),
             @CMASTERTABLENAME VARCHAR(100),@CDETAILTABLENAME VARCHAR(100),@bInsertOnly BIT,
             @bUpdateOnly BIT,@bMstInsertOnly BIT,
             @bMstUpdateOnly BIT,@CTEMPMASTERTABLENAME VARCHAR(100),@CTEMPDETAILTABLENAME VARCHAR(100),
             @CTEMPMASTERTABLE VARCHAR(100),@CTEMPDETAILTABLE VARCHAR(100),
             @CKEYFIELD VARCHAR(100),@CMEMONO VARCHAR(10),@CERRORMSG varchar(max),
             @NMEMONOLEN INT,@CCMD NVARCHAR(MAX),@NSAVETRANLOOP INT,@CMEMONOVAL VARCHAR(20),
             @TMP_WXR_NO VARCHAR(100),@CKEYFIELDVAL VARCHAR(100),@CMEMONOPREFIX VARCHAR(20),
             @REP_ID_FIN_YEAR VARCHAR(2),@CHODEPT_ID VARCHAR(4),@CPREFIX VARCHAR(10),@cLocationId VARCHAR(5)
    
	SET @CERRORMSG=''
	SET	@NSTEP = 2

	IF @NUPDATEMODE=3 
	BEGIN
		SET	@NSTEP = 5
	     IF ISNULL(@cMemoIdPara,'')=''
		 BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + 'Report ID cannot be blank for deletion of Reports'
			GOTO END_PROC
		END

		SET	@NSTEP = 7
	    delete from wow_xpert_rep_det with (ROWLOCK) WHERE rep_id=@cMemoIdPara
		delete from wow_xpert_rep_mst with (ROWLOCK) WHERE rep_id=@cMemoIdPara

        GOTO END_PROC
	END

	SET @nStep=9

	SELECT * INTO #tblRepDetUpload FROM wow_xpert_rep_det (NOLOCK) WHERE 1=2

	SET @nStep=12
	IF @nUpdatemode=1
		INSERT #tblRepDetUpload	( col_header, col_order, col_width, column_id, decimal_place, dimension, grp_total,
							  Measurement_col, rep_id, row_id, xn_type, contr_per)  
		SELECT a.col_header, a.col_order, a.col_width, a.column_id, a.decimal_place, a.dimension, 
		a.grp_total, a.Measurement_col,a.rep_id, '' row_id, a.xn_type,contr_per FROM #tblRepDet a
	ELSE
		INSERT #tblRepDetUpload	( col_header, col_order, col_width, column_id, decimal_place, dimension, grp_total,
							  Measurement_col, rep_id, row_id, xn_type,contr_per )  
		SELECT a.col_header, a.col_order, a.col_width, a.column_id, a.decimal_place, a.dimension, 
		a.grp_total, a.Measurement_col,@cMemoIdPara rep_id,ISNULL(d.row_id,'') row_id, a.xn_type ,a.contr_per
		FROM #tblRepDet a
		LEFT JOIN wow_xpert_rep_det d (NOLOCK) ON d.rep_id=@cMemoIdPara AND d.column_id=a.column_id AND 
		d.xn_type=a.xn_type
	

	SET	@NSTEP = 14
	SET @CMASTERTABLENAME	= 'wow_xpert_rep_mst'
	SET @CDETAILTABLENAME	= 'wow_xpert_rep_det'
		
	SET @CTEMPMASTERTABLE	= '#tblRepMst'
	SET @CTEMPDETAILTABLE	= '#tblRepDetUpload'
			
	SET	@NSTEP = 16
	SET @CKEYFIELD			= 'rep_id'

	SELECT TOP 1 @CLOCATIONID = location_code from  #tblRepMst

	select @CHODEPT_ID=VALUE  from config where config_option ='HO_LOCATION_ID'
   
   
BEGIN TRY	
	
	SET	@NSTEP = 20
	IF ISNULL(@CLOCATIONID,'')=''
	BEGIN
	   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + 'LOCATION IS CAN NOT BE BLANK'
	    GOTO END_PROC

	END
	
	BEGIN TRAN
	IF @NUPDATEMODE = 1 -- ADDMODE	
	BEGIN	
		SET @NSTEP = 25		-- GENERATING NEW KEY
		SET @CMEMONOPREFIX=@CLOCATIONID+'W'

		SET @NMEMONOLEN			= 10
			
		SET @NSAVETRANLOOP=0
		WHILE @NSAVETRANLOOP=0
		BEGIN
			EXEC GETNEXTKEY @CMASTERTABLENAME, @CKeyField, @NMEMONOLEN, @CMEMONOPREFIX, 1,
							'',0, @CMEMONOVAL OUTPUT   
				
			SET @NSTEP = 30
				
			PRINT @CMEMONOVAL
			IF EXISTS ( SELECT rep_id FROM wow_xpert_rep_mst (NOLOCK) WHERE rep_id=@CMEMONOVAL)
				SET @NSAVETRANLOOP=0
			ELSE
				SET @NSAVETRANLOOP=1
		END
            
              
        SET @NSTEP = 40
        SET @CKEYFIELDVAL = @CMEMONOVAL  
        IF @CKEYFIELDVAL IS NULL OR @CKEYFIELDVAL LIKE '%LATER%'  
		BEGIN
				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
				GOTO END_PROC
		END
        
		SET	@NSTEP = 45
		-- UPDATING NEWLY GENERATED JOB ORDER NO AND JOB ORDER ID IN PIM AND PID TEMP TABLES
		SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CKEYFIELD+'=''' + @CKEYFIELDVAL+''' '
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
		
		-- RECHECKING IF ID IS STILL LATER
		IF @CKEYFIELDVAL IS NULL OR @CKEYFIELDVAL LIKE '%LATER%'
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
			GOTO END_PROC
		END
	END					-- END OF ADDMODE

	ELSE
	BEGIN
		SET @CKEYFIELDVAL=@cMemoIdPara
	END

	--if @@spid=83
	--	select 'before', * from #tblRepDet
	SET @NSTEP = 50
	UPDATE #tblRepMst SET last_update=GETDATE()

	SET @NSTEP = 55
	-- UPDATING ROW_ID IN TEMP TABLES - PAYMODE_XN_DET
	SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())
					WHERE LEFT(ISNULL(ROW_ID,''''),5) IN (''LATER'','''')'
	EXEC SP_EXECUTESQL @CCMD
		
	--if @@spid=83
	--	select 'after', * from #tblRepDet

	IF @nUpdatemode=1 OR EXISTS (SELECT TOP 1 columnname FROM  #tblEditCols WHERE tablename='wow_xpert_rep_mst')
	BEGIN
		SET @NSTEP = 100		-- UPDATING MASTER TABLE
		 
		 SET @bMstInsertOnly=(CASE WHEN @nUpdatemode=1 THEN 1 ELSE 0 END)
		 SET @bMstUpdateOnly=(CASE WHEN @nUpdatemode=1 THEN 0 ELSE 1 END)

		 EXEC spwow_updatemasterxn        
		 @cSourceTable=@CTEMPMASTERTABLE,        
		 @cDestTable=@CMASTERTABLENAME,        
		 @cKeyField1=@CKEYFIELD,        
		 @lInsertOnly=@bMstInsertOnly,        
		 @lUpdateOnly=@bMstUpdateOnly  
	END

	IF @nUpdatemode=1 OR EXISTS (SELECT TOP 1 columnname FROM  #tblEditCols WHERE tablename='wow_xpert_rep_det')
	OR EXISTS (SELECT TOP 1 a.rep_id FROM #tblRepDetUpload a  LEFT JOIN wow_xpert_rep_det b (NOLOCK) on a.row_id=b.row_id
			   WHERE b.row_id IS NULL) 
	BEGIN
		-- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE
		SET @NSTEP = 110		-- UPDATING TRANSACTION TABLE

		SET @bInsertOnly=(CASE WHEN @nUpdatemode=1 THEN 1 ELSE 0 END)


		SET @NSTEP = 112                                                                                                                     
			
		SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET ' + @CKEYFIELD+'=''' + @CKEYFIELDVAL+''''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	
		IF @nUpdatemode=2
		BEGIN
			SET @NSTEP = 112.5
			
			SELECT @bInsertOnly=0,@bUpdateOnly=0

			IF EXISTS (SELECT TOP 1 a.rep_id FROM #tblRepDetUpload a
					   LEFT JOIN wow_xpert_rep_det b (NOLOCK) on a.row_id=b.row_id
					   WHERE b.row_id IS NULL) 
			  AND NOT EXISTS (SELECT TOP 1 columnname FROM #tblEditCols WHERE tablename='wow_xpert_rep_det')
			  SET @bInsertOnly=1
			
			IF NOT EXISTS (SELECT TOP 1 a.rep_id FROM #tblRepDetUpload a
					   LEFT JOIN wow_xpert_rep_det b (NOLOCK) on a.row_id=b.row_id
					   WHERE b.row_id IS NULL) 
			  AND  EXISTS (SELECT TOP 1 columnname FROM #tblEditCols WHERE tablename='wow_xpert_rep_det')
				SET @bUpdateOnly=1

			DELETE a FROM wow_xpert_rep_det a LEFT JOIN #tblRepDetUpload b ON a.row_id=b.row_id
			WHERE a.rep_id=@cMemoIdPara AND b.rep_id IS NULL
		END
		-- INSERTING/UPDATING THE ENTRIES IN PRD_JID TABLE FROM TEMPTABLE
		SET @NSTEP = 117		-- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES

		
		EXEC spwow_updatemasterxn        
		@cSourceTable='#tblRepDetUpload',
		@cDestTable='wow_xpert_rep_det',
		@cKeyField1='row_id',        
		@lInsertOnly=@bInsertOnly,        
		@lUpdateOnly=@bUpdateOnly  
	END

	IF @nUpdatemode=1 OR EXISTS (SELECT TOP 1 columnname FROM  #tblEditCols WHERE tablename='WOW_Xpert_Rep_Mst_Linked_Filter')
	OR EXISTS (SELECT TOP 1 a.rep_id FROM #tblLinkedFilter a  LEFT JOIN WOW_Xpert_Rep_Mst_Linked_Filter b (NOLOCK) 
			   on a.rep_id=b.rep_id AND a.Filter_id=b.Filter_id WHERE b.rep_id IS NULL) 

	BEGIN
		SET @NSTEP = 120		-- UPDATING MASTER TABLE
		 
		 UPDATE #tblLinkedFilter SET rep_id=@CKEYFIELDVAL

		 SET @bInsertOnly=(CASE WHEN @nUpdatemode=1 THEN 1 ELSE 0 END)
		 SET @bUpdateOnly=(CASE WHEN @nUpdatemode=1 THEN 0 ELSE 1 END)

		 IF @nUpdatemode=2
		 BEGIN
			 SET @NSTEP = 122	
			 IF EXISTS (SELECT TOP 1 a.rep_id FROM #tblLinkedFilter a  LEFT JOIN WOW_Xpert_Rep_Mst_Linked_Filter b (NOLOCK) 
				   on a.rep_id=b.rep_id AND a.Filter_id=b.Filter_id WHERE b.rep_id IS NULL)
					SET @bUpdateOnly=0
		 END
		 
		 SET @NSTEP = 125
		 EXEC spwow_updatemasterxn        
		 @cSourceTable='#tblLinkedFilter',        
		 @cDestTable='WOW_Xpert_Rep_Mst_Linked_Filter',        
		 @cKeyField1='rep_id',        
		 @lInsertOnly=@bInsertOnly,        
		 @lUpdateOnly=@bUpdateOnly  
	END

END TRY
BEGIN CATCH
	SET @CERRORMSG = 'Error in Procedure SAVETRAN_XPERT_REPDATA at Step#' + LTRIM(@NSTEP) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

	
END_PROC:
    
    IF @@TRANCOUNT>0 
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' 
		BEGIN
			commit TRANSACTION
		END	
		ELSE
		    ROLLBACK	
	END	

    SELECT @CERRORMSG AS ERRMSG,@CKEYFIELDVAL AS MEMO_ID

END
