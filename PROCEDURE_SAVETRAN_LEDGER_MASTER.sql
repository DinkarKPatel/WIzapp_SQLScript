create PROC SAVETRAN_LEDGER_MASTER
(
	@NSPID	INT,
	@NUPDATEMODE INT 
)
--WITH ENCRYPTION
AS
BEGIN
			
		DECLARE @CMASTERTABLENAME VARCHAR(100),
          @CTEMPMASTERTABLE VARCHAR(100),
          @CTEMPMASTERTABLENAME VARCHAR(100),
          @CLMPTABLENAME VARCHAR(100),
          @CTEMPLMPTABLE VARCHAR(100),
          @CTEMPLMPTABLENAME VARCHAR(100),
		  @CTEMPDBNAME VARCHAR(100),		
		  @NSTEP VARCHAR(10),
		  @BENABLETEMPDB BIT,
		  @CERRORMSG VARCHAR(500),
		  @CKEYFIELD VARCHAR(22),
		  @CMEMONOVAL VARCHAR(22),	
	      @CCMD NVARCHAR(MAX),
	      @NLOOPOUTPUT BIT,
	      @CHODEPT_ID VARCHAR(4),@BINSERTONLY BIT,@DTSQL NVARCHAR(MAX)
	      
	     SELECT TOP 1 @CHODEPT_ID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'
	      
		 DECLARE @OUTPUT TABLE(ERRMSG VARCHAR(2000),CAT_ID VARCHAR(22))
         SET @NSTEP = 0		-- SETTTING UP ENVIRONMENT		
		
		  
		 SET @NSTEP = 20 		 
		 set @cTempdbname=''

	     SET @CTEMPMASTERTABLENAME  ='TEMP_LMV01106_'+LTRIM(RTRIM(STR(@NSPID)))
	     		
	     SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME
		     
         SET @CKEYFIELD='AC_CODE'
	
	BEGIN TRY
	    
	     BEGIN TRANSACTION
	         
	     IF @NUPDATEMODE=1
	     BEGIN
			   SET @NSTEP = 30
			   	
			   EXEC  GETNEXTKEY 
			   @CTABLENAME='LM01106',
			   @CCOLNAME=@CKEYFIELD,
			   @NWIDTH=10,
			   @CPREFIX=@CHODEPT_ID,
			   @NLZEROS=1,
			   @CFINYEAR='',
			   @NROWCOUNT=1,
			   @CNEWKEYVAL=@CMEMONOVAL OUTPUT    
	       
			   PRINT @CMEMONOVAL  
			   
			   SET @NSTEP = 40	       
			   IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
			   BEGIN  
					SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'   
					GOTO END_PROC      
			   END 
			   
			   SET @NSTEP = 50
 			   SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CKEYFIELD+'=''' + @CMEMONOVAL+''',
 							MAJOR_AC_CODE=(CASE WHEN ISNULL(MAJOR_AC_CODE,'''') IN ('''',''0000000000'') THEN '''+@CMEMONOVAL+''' ELSE MAJOR_AC_CODE END)'  
               EXEC SP_EXECUTESQL @CCMD  
		 END   
   		 ELSE
   		 BEGIN
   			SET @NSTEP = 60
   			SET @CCMD=N'SELECT TOP 1 @CMEMONOVAL=AC_CODE FROM '+@CTEMPMASTERTABLE
   			EXEC SP_EXECUTESQL @CCMD,N'@CMEMONOVAL CHAR(10) OUTPUT',@CMEMONOVAL OUTPUT
   		 END
   		 
   		 SET @NSTEP = 70
   		 SET @CCMD=N'UPDATE '+@CTEMPMASTERTABLE+' SET  LAST_UPDATE=GETDATE(),COMPANY_CODE=''01'''
		 PRINT @CCMD 
		 EXEC SP_EXECUTESQL @CCMD 
		  
			  
	     SET @NSTEP = 80


	  --only use from online legdger creation
	  	 
		SET @DTSQL='  
		 INSERT STATE	( company_code, inactive, last_update, octroi_percentage, region_code, state, state_code, Uploaded_to_ActivStream ) 
			SELECT ''00'' company_code,0 inactive,getdate() last_update,0 octroi_percentage, 
			 a.region_code,  a.state, a.state_code, Uploaded_to_ActivStream 
			FROM '+@CTEMPMASTERTABLE+' A
			LEFT JOIN STATE B (NOLOCK) ON A.STATE_CODE=B.STATE_CODE 
			WHERE B.STATE_CODE IS NULL AND ISNULL(A.STATE_CODE,'''')<>'''' '
		print @DTSQL
		EXEC SP_EXECUTESQL @DTSQL



		SET @DTSQL='  
 			 INSERT city	( CITY, CITY_CODE, company_code, distt_code, inactive, LAST_UPDATE, state_code, Uploaded_to_ActivStream ) 
		  SELECT 	  a.CITY, a.CITY_CODE,''01'' company_code,''0000000'' distt_code,0 inactive,getdate() LAST_UPDATE, a.state_code,0 Uploaded_to_ActivStream 
		  FROM '+@CTEMPMASTERTABLE+' A
		   LEFT JOIN city B (NOLOCK) ON A.city_CODE=B.city_CODE 
			WHERE B.city_CODE IS NULL AND ISNULL(A.city_CODE,'''')<>'''' '
		print @DTSQL
		EXEC SP_EXECUTESQL @DTSQL



		SET @DTSQL='   INSERT area	( area_code, area_name, city_code, company_code, inactive, last_update, pincode )
		  SELECT 	  a.area_code, a.area_name, a.city_code,''01'' company_code, 0 inactive,getdate() last_update, a.pincode
		  FROM '+@CTEMPMASTERTABLE+' A
		   LEFT JOIN area B (NOLOCK) ON A.area_code=B.area_code 
			WHERE B.area_code IS NULL AND ISNULL(A.area_code,'''')<>'''' '
		print @DTSQL
		EXEC SP_EXECUTESQL @DTSQL

		 
	     
	     
	     --SELECT * FROM ARUNHO_TEMP..TEMP_LMV01106_104
		 EXEC UPDATEMASTERXN_MIRROR
				 @CSOURCEDB	=  @CTEMPDBNAME
				, @CSOURCETABLE = @CTEMPMASTERTABLENAME
				, @CDESTDB		= ''
				, @CDESTTABLE	= 'LMV01106'
				, @CKEYFIELD1	= @CKEYFIELD
				, @BALWAYSUPDATE = 1
				, @LINSERTONLY =  1
				, @CSEARCHTABLE = 'LMV01106_TABLE'
				, @BUPDATEXNS = 1
			
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

	IF ISNULL(@CERRORMSG,'')=''
	BEGIN
		SET @CCMD = N'IF OBJECT_ID('''+@CTEMPMASTERTABLE+''',''U'') IS NOT NULL
								DROP TABLE '+@CTEMPMASTERTABLE+''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD 
	END		
	  
	SELECT @CMEMONOVAL AS AC_CODE, ISNULL(@CERRORMSG,'') AS ERRMSG
 
END
--END OF PROCEDURE SAVETRAN_LEDGER_MASTER
