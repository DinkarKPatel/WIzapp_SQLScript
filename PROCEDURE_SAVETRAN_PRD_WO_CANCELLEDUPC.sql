CREATE PROCEDURE SAVETRAN_PRD_WO_CANCELLEDUPC
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				INT,
	@CMEMO_ID           VARCHAR(100)='',
	@DEPT_ID            VARCHAR(2)='',
	@CERRORMSG		    VARCHAR(500) OUTPUT
)
----WITH ENCRYPTION
AS
BEGIN
DECLARE @CTEMPDBNAME			VARCHAR(100),
			@LENABLETEMPDATABASE    INT,
			@CKEYFIELD1             VARCHAR (100),
			@CDETAILTABLENAME1		VARCHAR(100),
			@CTEMPDETAILTABLENAME1	VARCHAR(100),
			@CTEMPDETAILTABLE1		VARCHAR(100),
			@CTEMPDETAILTABLE3      VARCHAR(100),
			@LDONOTUPDATESTOCK		BIT,
			@CCMD					NVARCHAR(4000),
			@CCMDOUTPUT				NVARCHAR(4000),
			@NSTEP					INT
			
           SET @CERRORMSG=''
		

	SET @NSTEP = 0		-- SETTTING UP ENVIRONMENT
	SELECT @LENABLETEMPDATABASE = CAST([VALUE] AS BIT) FROM CONFIG WHERE CONFIG_OPTION = 'ENABLE_TEMP_DATABASE'
	IF @LENABLETEMPDATABASE IS NULL
		SET @LENABLETEMPDATABASE = 0
	-- CHECK TEMPORARY DATABASE TO HOLD TEMP TABLES 
	-- IF CONFIG SETTING SAYS TO DO SO
	IF @LENABLETEMPDATABASE = 1
		SET @CTEMPDBNAME = DB_NAME() + '_TEMP.DBO.'
	ELSE
		SET @CTEMPDBNAME = ''
	
	SET @CDETAILTABLENAME1	= 'PRD_WO_CNC_UPC'
	SET @CKEYFIELD1='MEMO_ID'
	
	--PRD_AGENCY_ISSUE_ROW_MATERIAL_DET
	
	SET @CTEMPDETAILTABLENAME1	= 'TEMP_'+@CDETAILTABLENAME1+'_'+LTRIM(RTRIM(STR(@NSPID)))
	SET @CTEMPDETAILTABLE1	= @CTEMPDBNAME + @CTEMPDETAILTABLENAME1
	SET @CTEMPDETAILTABLE3	= @CTEMPDBNAME + 'TEMP_PRD_WO_CNC_DET'+'_'+LTRIM(RTRIM(STR(@NSPID)))
	
	SET @CERRORMSG			= ''
	SET @LDONOTUPDATESTOCK	= 0
	SET @NSTEP = 10		-- GETTING DEPTID INFO FROM TEMP TABLE
	

		IF @NUPDATEMODE = 3
		BEGIN
		    
		    
		    UPDATE A SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK+1 
		    FROM PRD_UPCPMT A
		    JOIN PRD_WO_CNC_UPC B ON A.PRODUCT_CODE=B.PRODUCT_CODE
		    WHERE B.MEMO_ID=@CMEMO_ID
		    
	       IF EXISTS (SELECT TOP 1 'U' FROM PRD_UPCPMT A
		    JOIN PRD_WO_CNC_UPC B ON A.PRODUCT_CODE=B.PRODUCT_CODE WHERE B.MEMO_ID=@CMEMO_ID AND QUANTITY_IN_STOCK <0)
		    BEGIN
		       SET @CERRORMSG=' STOCK GOING NEGATIVE PLEASE CHECK'
		     
		    END
	
			GOTO END_PROC
		END	
		-- GETTING DEPT_ID FROM TEMP MASTER TABLE
		 
		 SET @CCMD = N'UPDATE B SET REF_ROW_ID=A.ROW_ID FROM ' + @CTEMPDETAILTABLE3 + ' A
		  JOIN ' + @CTEMPDETAILTABLENAME1 + ' B ON A.OLD_ROW_ID=B.REF_ROW_ID' 
		  PRINT @CCMD 
          EXEC SP_EXECUTESQL @CCMD  	
          
		 SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLENAME1 + ' SET ROW_ID = ''' + @DEPT_ID + ''' + CONVERT(VARCHAR(38), NEWID())  
         WHERE LEFT(ROW_ID,5) = ''LATER'''
         PRINT @CCMD  
         EXEC SP_EXECUTESQL @CCMD  
         
         
         SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLENAME1 + ' SET MEMO_ID = ''' + @CMEMO_ID + '''   
         WHERE LEFT(MEMO_ID,5) = ''LATER'''
         PRINT @CCMD  
         EXEC SP_EXECUTESQL @CCMD  
 			  
		
		EXEC UPDATEMASTERXN 
			  @CSOURCEDB	= @CTEMPDBNAME
			, @CSOURCETABLE = @CTEMPDETAILTABLENAME1
			, @CDESTDB		= ''
			, @CDESTTABLE	= @CDETAILTABLENAME1
			, @CKEYFIELD1	= @CKEYFIELD1
			, @BALWAYSUPDATE = 1
		
			
            UPDATE A SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-1
		    FROM PRD_UPCPMT A
		    JOIN PRD_WO_CNC_UPC B ON A.PRODUCT_CODE=B.PRODUCT_CODE
		    WHERE B.MEMO_ID=@CMEMO_ID
	    
 
	       IF EXISTS (SELECT TOP 1 'U' FROM PRD_UPCPMT A
		    JOIN PRD_WO_CNC_UPC B ON A.PRODUCT_CODE=B.PRODUCT_CODE WHERE B.MEMO_ID=@CMEMO_ID AND QUANTITY_IN_STOCK <0)
		    BEGIN
		       SET @CERRORMSG='STOCK GOING NEGATIVE PLEASE CHECK'
		     
		    END
	
	
GOTO END_PROC
	
END_PROC:
      	
     SET @CCMD = N'IF OBJECT_ID( ''' + @CTEMPDETAILTABLE1 + ''',''U'') IS NOT NULL
                  DROP TABLE ' + @CTEMPDETAILTABLE1
	EXEC SP_EXECUTESQL @CCMD


END		
-------- END OF PROCEDURE SAVETRAN_PRD_AGENCY_ISSUEUPC
