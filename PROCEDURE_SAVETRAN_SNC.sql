-- PROCEDURE TO SAVE A SPLIT AND COMBINE FROM TEMPORARY TABLES TO ACTUAL TABLES  
create PROCEDURE SAVETRAN_SNC  
(  
 @NUPDATEMODE    NUMERIC(1,0),  
 @NSPID      VARCHAR(50),  
 @CMEMONOPREFIX    VARCHAR(50),  
 @CFINYEAR     VARCHAR(10),  
 @CMACHINENAME    VARCHAR(100)='',  
 @CWINDOWUSERNAME   VARCHAR(100)='',  
 @CWIZAPPUSERCODE   VARCHAR(10)='0000000',  
 @CMEMOID     VARCHAR(40)='',  
 @CMEMODT     DATETIME='',  
 @LGENERATEBARCODES BIT=0,    
 @CBARCODEPREFIX  VARCHAR(20)='',
 @BcalledfromTTM bit =0,
 @bAllowNegative	BIT=0

)  
--WITH ENCRYPTION
AS  
BEGIN  
	--changes by Dinkar in location id varchar(4)..

 -- @NUPDATEMODE: 1- NEW RETAIL SALE ADDED,   
 --     2- NOT APPLICABLE,   
 --     3- CURRENT RETAIL SALE CANCELLED,   
 --     4- EXISTING RETAIL SALE EDITED  
   
 -- @CMEMOID:  MEMOID IS REQUIRED IF @NUPDATEMODE IS 3 (FROM CANCELLATION)  
 DECLARE @CTEMPDBNAME   VARCHAR(100),  
   @CMASTERTABLENAME  VARCHAR(100),  
   @CDETAILTABLENAME  VARCHAR(100),  
   @CDETAILTABLENAME2  VARCHAR(100),  
   @CTEMPMASTERTABLENAME VARCHAR(100),  
   @CTEMPDETAILTABLENAME VARCHAR(100),  
   @CTEMPDETAILTABLENAME2 VARCHAR(100),  
   @CTEMPMASTERTABLE  VARCHAR(100),  
   @CTEMPDETAILTABLE  VARCHAR(100),  
   @CTEMPDETAILTABLE2  VARCHAR(100),  
   @CERRORMSG    VARCHAR(500),  
   @LDONOTUPDATESTOCK  BIT,  
   @CKEYFIELD1    VARCHAR(50),  
   @CKEYFIELDVAL1   VARCHAR(50),  
   @CKEYFIELD1_DETAIL2  VARCHAR(50),  
   @CMEMONO    VARCHAR(20),  
   @NMEMONOLEN    NUMERIC(20,0),  
   @CMEMONOVAL    VARCHAR(50),  
   @CMEMODEPTID   VARCHAR(2),  
   @CLOCATIONID   VARCHAR(4),  
   @CHODEPTID    VARCHAR(4),  
   @CCMD     NVARCHAR(4000),  
   @CCMDOUTPUT    NVARCHAR(4000),  
   @NSAVETRANLOOP   BIT,  
   @CREFAPPMEMOID   VARCHAR(40),@CAPRMEMOID VARCHAR(40),  
   @NSTEP     INT,@BINSERTONLY BIT,  
   @LENABLETEMPDATABASE BIT,@BNEGSTOCKFOUND BIT,  
   @CKEYSTABLE VARCHAR(100),@CUSERALIAS VARCHAR(100),  
   @BESTIMATEMEMO NUMERIC(1),@CDEPT_ID CHAR(4),  
   @CMEMONOLEN VARCHAR(5),@CDONOTENFORCEDAYCLOSE VARCHAR(2),@DCURRENTDATE DATETIME,@CLOCID      VARCHAR(4)  
  

 SET @NSTEP = 5  -- DO VALIDATIONS ON INPUT DATA BY USER  
   
 DECLARE @CRETVAL VARCHAR(MAX)  
   
 DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))  
   
 SET @CREFAPPMEMOID = ''  
   
 SET @NSTEP = 7  -- SETTTING UP ENVIRONMENT  
  
  SET @CTEMPDBNAME = ''  
  --+LTRIM(RTRIM(STR(@NSPID)))  
 SET @CMASTERTABLENAME = 'SNC_MST'  
 SET @CDETAILTABLENAME = 'SNC_DET'  
 SET @CDETAILTABLENAME2 = 'SNC_CONSUMABLE_DET'  
 
 SET @CTEMPMASTERTABLENAME = 'SNC_SNC_MST_UPLOAD'
 SET @CTEMPDETAILTABLENAME = 'SNC_SNC_DET_UPLOAD'
 SET @CTEMPDETAILTABLENAME2 = 'SNC_SNC_CONSUMABLE_DET_UPLOAD'
   
 SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME  
 SET @CTEMPDETAILTABLE = @CTEMPDBNAME + @CTEMPDETAILTABLENAME  
 SET @CTEMPDETAILTABLE2 = @CTEMPDBNAME + @CTEMPDETAILTABLENAME2  
   
 SET @CERRORMSG   = ''  
 SET @LDONOTUPDATESTOCK = 0  
 SET @CKEYFIELD1   = 'MEMO_ID'  
 SET @CKEYFIELD1_DETAIL2 = 'MEMO_ID'  
  
 SET @CMEMONO   = 'MEMO_NO'  
 SET @NMEMONOLEN   = 10  
 
 SET @CCMD = N' DELETE FROM '+@CTEMPDETAILTABLE+' WHERE ISNULL(ARTICLE_CODE,'''') = '''' AND SP_ID='''+@NSPID+''''
 PRINT @CCMD
 EXEC SP_EXECUTESQL @CCMD
 
 SET @CCMD = N'DELETE FROM '+@CTEMPDETAILTABLE2+' WHERE ISNULL(PRODUCT_CODE,'''') = ''''  AND SP_ID='''+@NSPID+''''
 PRINT @CCMD
 EXEC SP_EXECUTESQL @CCMD
 
  SELECT @CLOCID=LOCATION_CODE FROM SNC_SNC_MST_UPLOAD (nolock) WHERE SP_ID=@NSPID  
  
 IF ISNULL(@CLOCID,'')=''  
	SELECT @CLOCATIONID = DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
 ELSE  
	SELECT @CLOCATIONID=@CLOCID  
    
 SELECT @CHODEPTID  = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'    
       

   IF ISNULL(@CLOCATIONID,'')=''
	 BEGIN
		SET @CERRORMSG ='1. LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	 END



 SET @NSTEP = 10  -- GETTING DEPTID INFO FROM TEMP TABLE  
  
    
 BEGIN TRY  
  
	  IF OBJECT_ID('TEMPDB..#TMPPMT','U') IS NOT NULL  
	   DROP TABLE #TMPPMT  
	    
	  SELECT PRODUCT_CODE INTO #TMPPMT FROM SKU WHERE 1=2  
	  
	  IF OBJECT_ID('TEMPDB..#TMPXNSTK','U') IS NOT NULL  
	   DROP TABLE #TMPXNSTK           
	    
	  SELECT PRODUCT_CODE,QUANTITY_IN_STOCK AS XN_STOCK INTO #TMPXNSTK FROM PMT01106 WHERE 1=2  
	  
	  IF @NUPDATEMODE=1  
		 SET @BINSERTONLY=1  
	  ELSE  
		 SET @BINSERTONLY=0  

	if @BcalledfromTTM=0
	  BEGIN TRANSACTION  
	      
	

		IF @NUPDATEMODE<>1
		BEGIN
			IF @NUPDATEMODE=2
				SELECT TOP 1 @cMEMOID=memo_id FROM  snc_snc_mst_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
		
		END
	  
	  EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,1,@NSPID  
	  
	    
	  IF @NUPDATEMODE<>3  
	  BEGIN  
		   SET @NSTEP = 15  
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,1,@NSPID  

		   --AS PER DISCUSS WITH SANJIV SIR NO ANY CHANGES IN QTY as on 25-11-2020 (problem arrise on ekaya)
          --UNIQUE BARCODE HAS MIN 1 QTY CONSUME
    --        SET @CCMD = ' UPDATE A SET QUANTITY=1  FROM ' + @CTEMPDETAILTABLE2 + ' A 
			 -- JOIN SKU B (nolock) ON A.PRODUCT_CODE =B.product_code 
    --          WHERE QUANTITY<>1 AND B.barcode_coding_scheme =3
			 --AND  A.SP_ID='''+@NSPID+''' '  
			 -- PRINT @CCMD  
			 -- EXEC SP_EXECUTESQL @CCMD  
          
		     
		   SELECT @CDONOTENFORCEDAYCLOSE=VALUE FROM CONFIG WHERE CONFIG_OPTION='DO_NOT_ENFORCE_LAST_RUN_DT'  
		  
		   SET @CDONOTENFORCEDAYCLOSE=ISNULL(@CDONOTENFORCEDAYCLOSE,'')  
		  
		   IF @CDONOTENFORCEDAYCLOSE<>'1'  
		   BEGIN  
				SELECT TOP 1 @DCURRENTDATE=dbo.fn_getlastrundate()
				SET @DCURRENTDATE=DATEADD(DD,1,@DCURRENTDATE)  
		   END   
		   ELSE  
		   BEGIN  
				SET @CCMD=N'SELECT @DCURRENTDATE=RECEIPT_DT FROM '+@CTEMPMASTERTABLE +' WHERE SP_ID ='''+@NSPID+''' ' 
				EXEC SP_EXECUTESQL @CCMD,N'@DCURRENTDATE DATETIME OUTPUT',@DCURRENTDATE OUTPUT  
		   END 
    
		  SET @NSTEP = 20  --UPDATING AC_CODE INTO TEMP TABLES  
		  EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		    
		  SET @CCMD = ' UPDATE ' + @CTEMPMASTERTABLE + ' SET AC_CODE=''0000000000'' WHERE ISNULL(AC_CODE,'''') ='''' AND SP_ID='''+@NSPID+''''  
		  PRINT @CCMD  
		  EXEC SP_EXECUTESQL @CCMD  
		  
		  SET @NSTEP = 25	
		  SET @CCMD = ' DELETE FROM ' + @CTEMPDETAILTABLE + ' WHERE ISNULL(ARTICLE_CODE,'''') IN ('''', ''000000000'') AND  SP_ID='''+@NSPID+''' ' 
		  PRINT @CCMD  
		  EXEC SP_EXECUTESQL @CCMD
		  
		  SET @NSTEP = 30
		  SET @CCMD = ' DELETE FROM ' + @CTEMPDETAILTABLE2 + ' WHERE ISNULL(PRODUCT_CODE,'''') = '''' AND SP_ID='''+@NSPID+''' '
		  PRINT @CCMD  
		  EXEC SP_EXECUTESQL @CCMD
		  
		  SET @NSTEP = 35
		  SET @CCMD = ' UPDATE ' + @CTEMPDETAILTABLE2 + ' SET REF_ROW_ID=NULL WHERE 1=(SELECT SNC_MST_MODE FROM  '+@CTEMPMASTERTABLE+' where SP_ID='''+@NSPID+''')  AND  SP_ID='''+@NSPID+''' '
		  PRINT @CCMD  
		  EXEC SP_EXECUTESQL @CCMD
		  
		  SET @NSTEP = 40  
		  EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		    
		  -- GETTING DEPT_ID FROM TEMP MASTER TABLE  
		  SET @CCMD = 'SELECT @CMEMODEPTID = LEFT(' + @CMEMONO + ',2) FROM '   
			 + (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME ELSE @CTEMPMASTERTABLE +' WHERE SP_ID='''+@NSPID+''' ' END )  
		  EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(2) OUTPUT',   
				 @CMEMODEPTID OUTPUT  
		  IF (@CMEMODEPTID IS NULL )  
		  BEGIN  
			 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'  
			 GOTO END_PROC      
		  END	 
	
		  
	 IF @NUPDATEMODE<>3
		BEGIN
		   
         IF EXISTS (SELECT TOP 1 'U' FROM SNC_SNC_CONSUMABLE_DET_UPLOAD WHERE SP_ID=@NSPID )
		 BEGIN

			  EXEC SP3S_NORMALIZE_FIX_PRODUCT_CODE 'SNC',@NSPID,@NUPDATEMODE,
			  @CTEMPDETAILTABLE2,@CMEMOID,@CERRORMSG OUTPUT,@CTEMPMASTERTABLE,@CLOCATIONID,@CWIZAPPUSERCODE,0,@bAllowNegative

			  IF ISNULL(@CERRORMSG,'')<>''
			  BEGIN
				   SET @CERRORMSG='ERROR IN NORMALIZATION'+@CERRORMSG
				   GOTO END_PROC
			  END

		  END
		END  
 
	  END
	  
	
	  		  
	  -- START UPDATING XN TABLES   
	  IF @NUPDATEMODE = 1 -- ADDMODE   
	  BEGIN   
	     
		   SET @NSTEP = 45  -- GENERATING NEW KEY  
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID     
		     
		   -- GENERATING NEW JOB ORDER NO    
		   SET @NSAVETRANLOOP=0  
		   WHILE @NSAVETRANLOOP=0  
		   BEGIN  
				SET @NSTEP = 50
      			SET @CCMD=N'SELECT TOP 1 @CUSERALIASOUT=USER_ALIAS FROM '+@CTEMPMASTERTABLE+' A JOIN USERS B ON A.USER_CODE=B.USER_CODE WHERE A.SP_ID='''+@NSPID+''' '  
				EXEC SP_EXECUTESQL @CCMD,N'@CUSERALIASOUT VARCHAR(5) OUTPUT',@CUSERALIASOUT=@CUSERALIAS OUTPUT  
			      
				SET @CKEYSTABLE='KEYS_SNM_'+LTRIM(RTRIM(@CUSERALIAS))  
			    
			    SET @NSTEP = 55  
				EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,  
					@CFINYEAR,0,@CMEMONOVAL OUTPUT     
			      
				PRINT @CMEMONOVAL  
				SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM '+ @CMASTERTABLENAME +'   
										  WHERE '+@CMEMONO+'='''+@CMEMONOVAL+'''   
										  AND FIN_YEAR = '''+@CFINYEAR+''' )  
								SET @NLOOPOUTPUT=0  
						    ELSE  
								SET @NLOOPOUTPUT=1'  
				PRINT @CCMD  
				EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT  
		   END  
		  
		   IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
		   BEGIN  
			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'   
			  GOTO END_PROC      
		   END  
		  
		   SET @NSTEP = 60  -- GENERATING NEW ID  
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		     
		   -- GENERATING NEW JOB ORDER ID  
		   SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
		   
		   IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
		   BEGIN  
			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
			  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
			  GOTO END_PROC  
		   END  
		  
		   SET @NSTEP = 65  -- UPDATING NEW ID INTO TEMP TABLES  
		     
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		     
		   -- UPDATING NEWLY GENERATED JOB ORDER NO AND JOB ORDER ID IN PIM AND PID TEMP TABLES  
		   SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' +   
			  @CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' where   SP_ID='''+@NSPID+''''  
		   PRINT @CCMD  
		   EXEC SP_EXECUTESQL @CCMD  
		       
		     
		   SET @NSTEP = 70  
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		     
		   SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+'''  where   SP_ID='''+@NSPID+''' '  
		   PRINT @CCMD  
		   EXEC SP_EXECUTESQL @CCMD  
		     
		   SET @NSTEP = 75  
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		     
		   SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE2 + ' SET '+@CKEYFIELD1_DETAIL2+' = '''+@CKEYFIELDVAL1+'''  where  SP_ID='''+@NSPID+''' '  
		   PRINT @CCMD  
		   EXEC SP_EXECUTESQL @CCMD  

		   --(due to error in merging unq row_id)
		   SET @CCMD = N'UPDATE '+@CTEMPDETAILTABLE2+' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())  +'''' where  SP_ID='''+@NSPID +'''  '
	       EXEC SP_EXECUTESQL @CCMD 

		   	  
		      
		   --EXEC SP_EXECUTESQL @CCMD  
	  END     -- END OF ADDMODE  
	  
	  ELSE    -- CALLED FROM EDITMODE  
	  BEGIN    -- START OF EDITMODE  
	    
		   SET @NSTEP = 80  -- GETTING ID INFO FROM TEMP TABLE  
		     
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		     
		   -- GETTING CM ID WHICH IS BEING EDITED  
		   SET @CCMD = 'SELECT @CKEYFIELDVAL1 = ' + @CKEYFIELD1 + ', @CMEMONOVAL = ' + @CMEMONO + ' FROM '  
			  + (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME + ' WHERE MEMO_ID = ''' + @CMEMOID + ''''   
				ELSE @CTEMPMASTERTABLE +' WHERE SP_ID='''+@NSPID+''' '  END )  
		     
		   EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT',   
				  @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT  
		   IF (@CKEYFIELDVAL1 IS NULL ) OR (@CMEMONOVAL IS NULL )  
		   BEGIN  
			  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'  
			  GOTO END_PROC      
		   END  
			
		
		   IF @NUPDATEMODE = 3     
		   BEGIN  
				SET @NSTEP=85  
				-- UPDATING SENTTOHO FLAG  
				SET @CCMD = N'UPDATE ' + @CMASTERTABLENAME + ' SET CANCELLED = 1,LAST_UPDATE=GETDATE() ' +   
				   N' WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''''  
				EXEC SP_EXECUTESQL @CCMD  
		   END  
		     
		   ELSE  
		   BEGIN  
  				SET @NSTEP = 90  -- UPDATING SENT_TO_HO FLAG TEMP TABLE  
			      
				EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
			      
				-- UPDATING SENTTOHO FLAG  
				SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET SENT_TO_HO = 0, LAST_UPDATE=GETDATE() WHERE SP_ID='''+@NSPID +''' '  
				EXEC SP_EXECUTESQL @CCMD  
		         
		   END  
		  
		   -- REVERTING BACK THE STOCK OF PMT W.R.T CURRENT ISSUE  
		   SET @NSTEP = 100  -- REVERTING STOCK  
		     
		   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  

		   
		   	 
			--SELECT * FROM PMT01106 WHERE PRODUCT_CODE='CRP80'
		    EXEC UPDATEPMT_SNC   
			   @CXNTYPE   = 'SNC'  
			 , @CXNNO   = @CMEMONOVAL  
			 , @CXNID   = @CKEYFIELDVAL1  
			 , @NREVERTFLAG  = 1  
			 , @NALLOWNEGSTOCK = @bAllowNegative  
			 , @NCHKDELBARCODES = 1  
			 , @NUPDATEMODE  = @NUPDATEMODE      
			 , @CCMD    = @CCMDOUTPUT OUTPUT  
		   -- SELECT @CCMDOUTPUT  
		   --SELECT * FROM PMT01106 WHERE PRODUCT_CODE='CRP80'
		   IF (@NUPDATEMODE = 3)   
		   BEGIN
				 SET @NSTEP = 105 
				 IF @CCMDOUTPUT <> ''  
				 BEGIN  
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT....'  
					  SET @BNEGSTOCKFOUND=1  
					  PRINT 'NEGATIVE STOCK FOUND-1'  
					  PRINT ISNULL(@CCMDOUTPUT,'@CCMDOUTPUT : NULL')  
					  EXEC SP_EXECUTESQL @CCMDOUTPUT  
    			  END   

				EXEC SP3S_upd_qty_lastupdate
				@nUpdateMode=3,
				@cXnType='SNC',
				@cMasterTable='SNC_MST',
				@cMemoIdCol='Memo_id',
				@cMemoId=@CKEYFIELDVAL1,
				@CERRORMSG=@CERRORMSG OUTPUT


				 GOTO END_PROC  
		   END  
		   ELSE  
		   IF (@NUPDATEMODE = 2)   
		   BEGIN  
				 SET @NSTEP = 110
				 IF OBJECT_ID('TEMPDB..#TEMPBARCODES','U') IS NOT NULL  
				  DROP TABLE #TEMPBARCODES  
			      
				 SELECT DISTINCT A.DEPT_ID,C.PRODUCT_CODE,B.BIN_ID INTO #TEMPBARCODES FROM SNC_MST A
				 JOIN SNC_DET B ON B.MEMO_ID=A.MEMO_ID  
				 JOIN SNC_BARCODE_DET C ON C.REFROW_ID=B.ROW_ID
				 WHERE A.MEMO_ID=@CKEYFIELDVAL1  
		   END  
	  END     -- END OF EDITMODE  
	  

	  SET @NSTEP = 115  
	    
	  -- RECHECKING IF ID IS STILL LATER  
	  IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
	  BEGIN  
	   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
	   GOTO END_PROC  
	  END  
	  
	  -- UPDATING MASTER TABLE (PIM01106) FROM TEMP TABLE  
	  SET @NSTEP = 120  -- UPDATING MASTER TABLE     
	     
	  EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
	   

		IF @NUPDATEMODE IN (1,2)
		BEGIN
			SET @nSTEP = 122
			UPDATE a SET total_quantity=b.total_quantity FROM snc_snc_MST_UPLOAD A WITH (ROWLOCK) 
			JOIN (SELECT sp_id,sum(quantity) as total_quantity FROM snc_snc_det_UPLOAD b (NOLOCK)  
					WHERE sp_id=@nSpId GROUP BY sp_id) b ON a.sp_id=b.sp_id
			
			SET @nSTEP = 123
			UPDATE a SET total_consumed_quantity=b.total_quantity FROM snc_snc_MST_UPLOAD A WITH (ROWLOCK) 
			JOIN (SELECT sp_id,sum(quantity) as total_quantity FROM snc_snc_consumable_det_UPLOAD b (NOLOCK)  
					WHERE sp_id=@nSpId GROUP BY sp_id) b ON a.sp_id=b.sp_id

           EXEC SP3S_upd_qty_lastupdate
			@nUpdateMode=@NUPDATEMODE,
			@nSpId=@nSpid,
			@cXnType='SNC',
			@cMasterTable='SNC_MST',
			@cMemoIdCol='Memo_id',
			@cMemoId=@CKEYFIELDVAL1,
			@cXnDtCol='RECEIPT_DT',
			@CERRORMSG=@CERRORMSG OUTPUT

			IF ISNULL(@CERRORMSG,'')<>''
		       GOTO END_PROC


		END			  

	  SET @nSTEP = 127
	  
	   

	  DECLARE @CWHERE VARCHAR(100)
	  SET @CWHERE =' B.SP_ID ='''+@NSPID +''' '
		   

	  EXEC UPDATEMASTERXN_OPT   
		  @CSOURCEDB = @CTEMPDBNAME  
		, @CSOURCETABLE = @CTEMPMASTERTABLENAME  
		, @CDESTDB  = ''  
		, @CDESTTABLE = @CMASTERTABLENAME  
		, @CKEYFIELD1 = @CKEYFIELD1  
		, @LINSERTONLY  = @BINSERTONLY  
		, @BALWAYSUPDATE = 1  
		,@CFILTERCONDITION=@CWHERE
	      
	  
	  -- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE  
	  SET @NSTEP = 130  -- UPDATING TRANSACTION TABLE  

	  DECLARE @CSNCDETROWID VARCHAR(50)
	  SET @CSNCDETROWID='TEMP_SNCDETROWID'
	  SET @CCMD = N'IF OBJECT_ID('''+@CSNCDETROWID+''',''U'') IS NOT NULL
						DROP TABLE '+@CSNCDETROWID
	   print @CCMD
	  EXEC SP_EXECUTESQL @CCMD 
	  
	 
	   
	  SET @NSTEP = 135 
	  SET @CCMD = N'SELECT ROW_ID,ROW_ID AS OLD_ROW_ID,SP_ID INTO '+@CSNCDETROWID+' FROM ' + @CTEMPDETAILTABLE + ' WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID='''+@NSPID +''' '  
	  EXEC SP_EXECUTESQL @CCMD  

	
	   
	  SET @NSTEP = 140
	  -- UPDATING ROW_ID IN TEMP TABLES - CMD01106  
	  SET @CCMD = N'UPDATE '+@CSNCDETROWID+' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())  +'''' where  SP_ID='''+@NSPID +''' '
	  EXEC SP_EXECUTESQL @CCMD 

	  SET @NSTEP = 145
	  -- UPDATING ROW_ID IN TEMP TABLES - CMD01106  
	  SET @CCMD = N'UPDATE A SET ROW_ID = B.ROW_ID
					FROM ' + @CTEMPDETAILTABLE + ' A
					JOIN  '+@CSNCDETROWID+' B ON B.OLD_ROW_ID=A.ROW_ID AND A.SP_ID=B.SP_ID 
					WHERE a.SP_ID='''+@NSPID +''' '
					          
	  EXEC SP_EXECUTESQL @CCMD 
  
	  SET @NSTEP = 155
	  -- UPDATING ROW_ID IN TEMP TABLES - CMD01106  
	  SET @CCMD = N'UPDATE A SET A.REF_ROW_ID = B.ROW_ID
					FROM ' + @CTEMPDETAILTABLE2 + ' A
					JOIN  '+@CSNCDETROWID+' B ON B.OLD_ROW_ID=A.REF_ROW_ID AND A.SP_ID=B.SP_ID 
					WHERE A.SP_ID='''+@NSPID +''' '
	          
	  EXEC SP_EXECUTESQL @CCMD 
	  print @CCMD

	   SET @CCMD = N'UPDATE A SET A.REFROW_ID = B.ROW_ID
					FROM snc_snc_barcode_det_upload A
					JOIN  '+@CSNCDETROWID+' B ON B.OLD_ROW_ID=A.REFROW_ID AND A.SP_ID=B.SP_ID 
					WHERE A.SP_ID='''+@NSPID +''' '
	          
	  EXEC SP_EXECUTESQL @CCMD 
	 
	  
	  IF @NUPDATEMODE=2  
	  BEGIN  
			-- DELETING EXISTING ENTRIES FROM PID01106 TABLE WHERE ROW_ID NOT FOUND IN TEMPTABLE  
			SET @NSTEP = 165  -- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES  
			EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
			SET @CCMD = N'DELETE a FROM snc_barcode_det a WITH (ROWLOCK)
			   JOIN snc_det b (NOLOCK) ON a.REFROW_ID=b.row_id	
			   WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
			   AND ROW_ID IN   
			   (  
				SELECT A.ROW_ID   
				FROM ' + @CDETAILTABLENAME + ' A   
				LEFT OUTER JOIN ' + @CTEMPDETAILTABLE + ' B ON A.ROW_ID = B.ROW_ID  
				WHERE A.' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
				AND   B.ROW_ID IS NULL  
			   )'  
			PRINT @CCMD     
			EXEC SP_EXECUTESQL @CCMD  
			
			SET @NSTEP = 167  -- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES  		      
			EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
			-- PAYMODE_XN_DET  
			SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME2 + '   
			   WHERE ' + @CKEYFIELD1_DETAIL2 + ' = ''' + @CKEYFIELDVAL1 + '''  
			   AND ROW_ID IN   
			   (  
				SELECT A.ROW_ID   
				FROM ' + @CDETAILTABLENAME2 + ' A   
				LEFT OUTER JOIN ' + @CTEMPDETAILTABLE2 + ' B ON A.ROW_ID = B.ROW_ID  
				WHERE A.' + @CKEYFIELD1_DETAIL2 + ' = ''' + @CKEYFIELDVAL1 + '''  
				AND   B.ROW_ID IS NULL  
			   )'  
			PRINT @CCMD        
			EXEC SP_EXECUTESQL @CCMD  

		      
			SET @NSTEP = 170  
		      
			EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  

			-- CMD01106  
			SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME + '   
			   WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
			   AND ROW_ID IN   
			   (  
				SELECT A.ROW_ID   
				FROM ' + @CDETAILTABLENAME + ' A   
				LEFT OUTER JOIN ' + @CTEMPDETAILTABLE + ' B ON A.ROW_ID = B.ROW_ID  
				WHERE A.' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
				AND   B.ROW_ID IS NULL  
			   )'  
			PRINT @CCMD     
			EXEC SP_EXECUTESQL @CCMD  

		      
	   END  
	   
	   
	   --gst Percentage Pick as per hsn and rate
	   ;WITH CTE AS
		(
		SELECT B.HSN_CODE,ISNULL(C.TAX_PERCENTAGE,0)  AS TAX_PERCENTAGE,ISNULL(C.RATE_CUTOFF,0) AS RATE_CUTOFF,
		       ISNULL(C.RATE_CUTOFF_TAX_PERCENTAGE,0) AS RATE_CUTOFF_TAX_PERCENTAGE,
		      ISNULL(C.WEF,'') AS WEF,
			  SR=ROW_NUMBER() OVER (PARTITION BY A.ROW_ID ORDER BY C.WEF DESC),a.ROW_ID 
		FROM SNC_SNC_DET_UPLOAD A (NOLOCK)
		join SNC_SNC_MST_UPLOAD mst (nolock) on a.SP_ID =mst.SP_ID 
		JOIN HSN_MST B (NOLOCK) ON A.HSN_CODE =B.HSN_CODE 
		LEFT JOIN HSN_DET C (NOLOCK) ON B.HSN_CODE =C.HSN_CODE AND C.WEF  <=mst.RECEIPT_DT 
		WHERE A.SP_ID =@NSPID  
		)
		
	    UPDATE TMP SET GST_PERCENTAGE=ISNULL(CASE WHEN HM.RATE_CUTOFF<ABS(TMP.PURCHASE_PRICE )
	    THEN HM.TAX_PERCENTAGE ELSE RATE_CUTOFF_TAX_PERCENTAGE END ,0)
	   FROM SNC_SNC_DET_UPLOAD TMP (NOLOCK)
	   JOIN CTE HM (NOLOCK) ON HM.HSN_CODE=TMP.HSN_CODE and tmp.ROW_ID =hm.ROW_ID 
	   WHERE TMP.SP_ID=@NSPID
       and hm.SR =1
	
	   
	   -- INSERTING/UPDATING THE ENTRIES IN PRD_JID TABLE FROM TEMPTABLE  
	   SET @NSTEP = 175  -- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES  
	     
	   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  

	

	   EXEC UPDATEMASTERXN_OPT   
		  @CSOURCEDB = @CTEMPDBNAME  
		, @CSOURCETABLE = @CTEMPDETAILTABLENAME  
		, @CDESTDB  = ''  
		, @CDESTTABLE = @CDETAILTABLENAME  
		, @CKEYFIELD1 = 'ROW_ID'  
		, @LINSERTONLY  = @BINSERTONLY      
		, @BALWAYSUPDATE = 1  
		,@CFILTERCONDITION=@CWHERE
  	   	     
	   SET @NSTEP = 180  
	     
	   EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
	     
	   -- SNC_CONSUMABLE_DET  
	   EXEC UPDATEMASTERXN_OPT   
		  @CSOURCEDB = @CTEMPDBNAME  
		, @CSOURCETABLE = @CTEMPDETAILTABLENAME2  
		, @CDESTDB  = ''  
		, @CDESTTABLE = @CDETAILTABLENAME2  
		, @CKEYFIELD1 = 'ROW_ID'  
		, @LINSERTONLY  = @BINSERTONLY      
		, @BALWAYSUPDATE = 1      
		,@CFILTERCONDITION=@CWHERE
	      

	   IF @LGENERATEBARCODES = 1    
	   BEGIN    
		   PRINT 'GENERATING BARCODES'    
		   SET @NSTEP = 185  
		       
		   
		   EXEC SAVETRAN_GENBARCODES_SNC    
			  @CXNID  = @CKEYFIELDVAL1    
			, @CPREFIX  = @CBARCODEPREFIX    
			, @NMODE  = 4     
			,@NSPID=@NSPID
			, @LOCID  = @CLOCATIONID     
			, @CERRORMSG = @CERRORMSG OUTPUT    

		   IF ISNULL(@CERRORMSG,'')<>''    
				GOTO END_PROC    
		       
		   -- CHECK WHETHER BARCODE HAS SUCCESSFULLY GENERATED OR NOT    
		   IF EXISTS ( SELECT TOP 1 B.PRODUCT_CODE FROM SNC_DET A JOIN SNC_BARCODE_DET B ON A.ROW_ID=B.REFROW_ID    
					  WHERE MEMO_ID = @CKEYFIELDVAL1 AND B.PRODUCT_CODE = '' )    
		   BEGIN
				SET @NSTEP = 190      
				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR GENERATING NEW BARCODES....'    
				-- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'            
				GOTO END_PROC    
		   END    
		    
		   -- CHECK ALL BARCODES INSERTED INTO PID    
		   IF EXISTS ( SELECT TOP 1 B.PRODUCT_CODE FROM SNC_DET A JOIN SNC_BARCODE_DET B ON A.ROW_ID=B.REFROW_ID        
					  LEFT OUTER JOIN SKU C ON B.PRODUCT_CODE = C.PRODUCT_CODE    
					  WHERE A.MEMO_ID = @CKEYFIELDVAL1     
					  AND B.PRODUCT_CODE IS NULL )    
		   BEGIN    
				SET @NSTEP=200    
				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR GENERATING NEW BARCODES... NEW CODES NOT GENERATED'    
				-- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'    
			        
				GOTO END_PROC    
		   END    
		   
		   IF EXISTS ( SELECT TOP 1 B.PRODUCT_CODE FROM SNC_DET A (NOLOCK) JOIN SNC_BARCODE_DET B (NOLOCK) ON A.ROW_ID=B.REFROW_ID        
					   JOIN SKU C (NOLOCK) ON B.PRODUCT_CODE = C.PRODUCT_CODE    
					   WHERE A.MEMO_ID = @CKEYFIELDVAL1     
					   AND ISNULL(C.hsn_code,'') IN('','0000000000') )    
		   BEGIN    
				SET @NSTEP=205    
				SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' HSN CODE CAN NOT BE BLANK IN NEW BARCODE '    
				GOTO END_PROC    
		   END    



		   IF NOT EXISTS (SELECT TOP 1 'U' FROM SNC_CONSUMABLE_DET a WITH (ROWLOCK) WHERE A.MEMO_ID = @CKEYFIELDVAL1 )
		   BEGIN
		      SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + 'New Barcode Generation Not Allowed Without Consuming Item'    
			  GOTO END_PROC    	
			        
		   END

		   IF EXISTS (SELECT TOP 1 'U' FROM SNC_MST (nolock) where memo_id=@CKEYFIELDVAL1 and wip=1) and @NUPDATEMODE <>1
		   begin
		        SET @NSTEP=205
				if exists ( SELECT Top 1'u' 
				 FROM SNC_BARCODE_DET A WITH (NOLOCK)
				 join SNC_DET b (Nolock) on a.REFROW_ID =b.ROW_ID 
				 JOIN JOBWORK_ISSUE_DET C (NOLOCK) ON A.PRODUCT_CODE=C.PRODUCT_CODE
				 join JOBWORK_ISSUE_mst d (nolock) on c.issue_id=d.issue_id
				 where b.MEMO_ID=@CKEYFIELDVAL1 and d.cancelled=0)
				begin
				      SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + 'Job work has been Issued Yoy can not edit or cancelled it'    
			          GOTO END_PROC  

				end

		   end
		  

		IF EXISTS (SELECT TOP 1 'U' FROM INV_SKU_COL_LIST A  (NOLOCK) WHERE FOR_SKU=1 )  
		   BEGIN  
		        
			  EXEC SP3S_INSERT_PARA7   
			  @CXNTYPE='SNC',  
			  @CSP_ID=@CKEYFIELDVAL1,  
			  @CLOCID=@CLOCATIONID,  
			  @CERRORMSG=@CERRORMSG OUTPUT   
		  
		         
			   IF ISNULL(@CERRORMSG,'')<>''  
				   GOTO END_PROC  
		  
		   END  
    

	   End 
	 
	   SET @NSTEP = 205
	    --SELECT * FROM PMT01106 WHERE PRODUCT_CODE='CRP80'
	   EXEC UPDATEPMT_SNC   
		  @CXNTYPE		= 'SNC'  
		, @CXNNO		= @CMEMONOVAL  
		, @CXNID		= @CKEYFIELDVAL1  
		, @NREVERTFLAG  = 0  
		, @NALLOWNEGSTOCK = @bAllowNegative  
		, @NCHKDELBARCODES = 1  
		, @NUPDATEMODE  = @NUPDATEMODE      
		, @CCMD    = @CCMDOUTPUT OUTPUT  
	     --SELECT @CCMDOUTPUT
	     --SELECT * FROM PMT01106 WHERE PRODUCT_CODE='CRP80'
	   IF @CCMDOUTPUT <> ''  
	   BEGIN  
			 SET @NSTEP = 210  
			 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT....'  
		       
			 SET @BNEGSTOCKFOUND=1      
		       
			 PRINT 'NEGATIVE STOCK FOUND-2-'+@CCMDOUTPUT  
		       
			 EXEC SP_EXECUTESQL @CCMDOUTPUT  
			 GOTO END_PROC  
	   END  
	    
	   SET @NSTEP = 215  

	   IF EXISTS (SELECT TOP 1 ERRMSG FROM @OUTPUT WHERE ISNULL(ERRMSG,'')<>'')  
			SELECT TOP 1 @CERRORMSG= ERRMSG FROM @OUTPUT WHERE ISNULL(ERRMSG,'')<>''  
	   ELSE  
			DELETE FROM @OUTPUT   
	   
	   IF @NUPDATEMODE<>3
	   begin

		   IF EXISTS (SELECT TOP 1 'U' FROM SNC_MST WHERE  MEMO_ID=@CKEYFIELDVAL1  AND ISNULL(WIP,0)=0)
			EXEC SAVETRAN_PUR_UPDSKU_SNC	@CMEMOID =@CKEYFIELDVAL1,	@NMODE =1,@BCANCELBILL =0,@CERRORMSG =@CERRORMSG OUTPUT
		   else
		   EXEC SAVETRAN_PUR_UPDSKU_SNC_wip	@CMEMOID =@CKEYFIELDVAL1,	@NMODE =1,@BCANCELBILL =0,@CERRORMSG =@CERRORMSG OUTPUT
	   end
	    
	SET @NSTEP = 220  	
	DECLARE @STR VARCHAR(MAX),@STR1 VARCHAR(MAX)
	SET @STR=NULL
	SET @STR1=NULL

	SELECT  @STR1=MEMO_ID,@STR =  COALESCE(@STR +  '/ ', ' ' ) + (''+C.UOM_NAME+': '+CAST(SUM(QUANTITY) AS VARCHAR) +' ')  
	 FROM SNC_DET A 
	 JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE
	JOIN UOM C ON C.UOM_CODE=B.UOM_CODE
	WHERE MEMO_ID=@CKEYFIELDVAL1 GROUP BY C.UOM_NAME ,MEMO_ID
	
	UPDATE SNC_MST SET TOTAL_QUANTITY_STR =@STR WHERE MEMO_ID =@STR1
	
   
	GOTO END_PROC  
   
END TRY  
BEGIN CATCH  
	  SET @CERRORMSG = 'PROCEDURE SAVETRAN_SNC: STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
	  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG, '''' AS MEMO_ID'  
	    
	  GOTO END_PROC  
END CATCH  
   
END_PROC:  

	 UPDATE snc_mst WITH (ROWLOCk) SET last_update=getdate() WHERE memo_id=@CKEYFIELDVAL1  	

	 IF @@TRANCOUNT>0  and @BcalledfromTTM=0
	 BEGIN  
		  EXEC SP_CHKXNSAVELOG 'SNC',@NSTEP,0,@NSPID  
		  IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')='' AND ISNULL(@BNEGSTOCKFOUND,0)=0  
		  BEGIN
			commit TRANSACTION
			DELETE A  FROM XNTYPE_CHECKSUM_MST A  WITH (ROWLOCK)  WHERE SP_ID=@NSPID
			
			UPDATE SNC_MST WITH (ROWLOCK) SET LAST_UPDATE=GETDATE(),reconciled =0,HO_SYNCH_LAST_UPDATE=''
			WHERE MEMO_ID=@CKEYFIELDVAL1

		  END	
		  ELSE
		  BEGIN  
				ROLLBACK  
				DELETE A  FROM XNTYPE_CHECKSUM_MST A  WITH (ROWLOCK)  WHERE SP_ID=@NSPID
		  END	
	 END  

  
	 IF ISNULL(@BNEGSTOCKFOUND,0)=0  and @BcalledfromTTM=0
	 BEGIN  
		  INSERT @OUTPUT ( ERRMSG, MEMO_ID)  
		   VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,''))  
		  
		  SELECT * FROM @OUTPUT   
	 END   

	  --Fix or lot code Auto generate split & combined chnages as discuss with sanjiv sir (20230620)
	 IF @BCALLEDFROMTTM=1 and ISNULL(@CERRORMSG,'')<>''
	 begin
	     
		 declare @cproductList varchar(max)
		  select product_code=cast('' as varchar(100)) ,
		         Quantity_in_stock =cast(0 as numeric(10,3))
			into #tmpnegativeBarcode
			where 1=2

		  IF ISNULL(@BNEGSTOCKFOUND,0)=1 
		  begin
		     
		      INSERT INTO #tmpnegativeBarcode(PRODUCT_CODE,Quantity_in_stock)
			  EXEC SP_EXECUTESQL @CCMDOUTPUT  

			  select @cproductList=isnull(@cproductList+'',',')+QUOTENAME(PRODUCT_CODE) 
			  from #tmpnegativeBarcode
			
		  end

		   insert into #tmpError(ERRMSG)
		   select ISNULL(@CERRORMSG,'')

		 

	 end

	 --end of split & combined

    IF ISNULL(@CERRORMSG,'')='' 
    BEGIN


		IF @NUPDATEMODE=2 AND ISNULL(@CERRORMSG,'')=''	
		BEGIN
		   
		   EXEC SP3S_UPDATE_SKUNAMES @CKEYFIELDVAL1,'SNC'

		END

	END
	
	DELETE FROM SNC_SNC_MST_UPLOAD WHERE SP_ID =@NSPID 
	DELETE FROM SNC_SNC_DET_UPLOAD WHERE SP_ID =@NSPID 
	DELETE FROM SNC_SNC_CONSUMABLE_DET_UPLOAD WHERE SP_ID =@NSPID 
	DELETE FROM SNC_SNC_BARCODE_DET_UPLOAD WHERE SP_ID =@NSPID 

------------------------------------------------------ END OF PROCEDURE SAVETRAN_SNC  
END