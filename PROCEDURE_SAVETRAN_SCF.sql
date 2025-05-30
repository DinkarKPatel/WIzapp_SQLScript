-- PROCEDURE TO SAVE SPLIT/COMBINE ENTRIES
create PROCEDURE SAVETRAN_SCF  
(  
 @NUPDATEMODE  NUMERIC(1,0),  
 @NSPID    varchar(50),  
 @CMEMONOPREFIX  VARCHAR(50),  
 @CFINYEAR   VARCHAR(10),  
 @LGENERATEBARCODES BIT=0,  
 @CMACHINENAME  VARCHAR(100)='',  
 @CWINDOWUSERNAME VARCHAR(100)='',  
 @CWIZAPPUSERCODE VARCHAR(10)='0000000',  
 @CMEMOID   VARCHAR(40)=''
 
)  
--WITH ENCRYPTION
AS  
BEGIN  
	--changes by Dinkar in location id varchar(4)..
 -- @NUPDATEMODE: 1- NEW MEMO ADDED,   
 --     2- CURRENT MEMO EDITED  
 --     3- CURRENT MEMO CANCELLED,   
 DECLARE @CTEMPDBNAME   VARCHAR(100),  
   @CMASTERTABLENAME  VARCHAR(100),  
   @CDETAILTABLENAME1  VARCHAR(100),  
   @CDETAILTABLENAME2  VARCHAR(100),  
   @CTEMPMASTERTABLENAME VARCHAR(100),  
   @CTEMPDETAILTABLENAME1 VARCHAR(100),  
   @CTEMPDETAILTABLENAME2 VARCHAR(100),  
   @CTEMPMASTERTABLE  VARCHAR(100),  
   @CTEMPDETAILTABLE1  VARCHAR(100),  
   @CTEMPDETAILTABLE2  VARCHAR(100),  
   @CERRORMSG    VARCHAR(500),  
   @LDONOTUPDATESTOCK  BIT,  
   @CKEYFIELD1    VARCHAR(50),  
   @CKEYFIELDVAL1   VARCHAR(50),  
   @CMEMONO    VARCHAR(20),  
   @NMEMONOLEN    NUMERIC(20,0),  
   @CMEMONOVAL    VARCHAR(50),  
   @CMEMODEPTID   VARCHAR(4),  
   @CLOCATIONID   VARCHAR(4),  
   @CHODEPTID    VARCHAR(4),  
   @CCMD     NVARCHAR(4000),  
   @CCMDOUTPUT    NVARCHAR(4000),  
   @NSAVETRANLOOP   BIT,  
   @NSTEP     INT,@NSUBTOTAL NUMERIC(10,2),  
   @BNEGSTOCKFOUND BIT,  
   @CWSLINVOICEID VARCHAR(22),  
   @BPURTHROUGHIMPORT BIT,@CMSG VARCHAR(200),@NTAX NUMERIC(10,2),@CLOCID	VARCHAR(4)  
  
 BEGIN TRY  
    
  BEGIN TRANSACTION  
    
  SET @BPURTHROUGHIMPORT=0  
    
  SET @NSTEP = 10  
  PRINT @NSTEP  

  SELECT @CTEMPDETAILTABLENAME1 = 'SCF_SCF01106_UPLOAD',  
      @CTEMPDETAILTABLENAME2 = 'SCF_SCC01106_UPLOAD'
    
  IF OBJECT_ID('TEMPDB..#TMPPMT','U') IS NOT NULL  
   DROP TABLE #TMPPMT  
    
  SELECT PRODUCT_CODE INTO #TMPPMT FROM SKU WHERE 1=2  
  
  IF OBJECT_ID('TEMPDB..#TMPXNSTK','U') IS NOT NULL  
   DROP TABLE #TMPXNSTK           
    
  SELECT PRODUCT_CODE,QUANTITY_IN_STOCK AS XN_STOCK INTO #TMPXNSTK FROM PMT01106 WHERE 1=2  
  IF @NUPDATEMODE=3  
  BEGIN  
	   SET @NSTEP = 25  
	   PRINT @NSTEP   
	   IF ISNULL(@CMEMOID,'') = ''  
	   BEGIN  
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID REQUIRED .....CANNOT PROCEED'  
		GOTO END_PROC      
	   END  
	     
	   SET @CKEYFIELDVAL1=@CMEMOID  
	     
	   EXEC UPDATEPMT   
		  @CXNTYPE   = 'SCF'    
		, @CXNNO   = @CMEMONOVAL  
		, @CXNID   = @CKEYFIELDVAL1  
		, @NREVERTFLAG  = 1  
		, @NALLOWNEGSTOCK = 0  
		, @NCHKDELBARCODES = 1  
		, @NUPDATEMODE  = @NUPDATEMODE      
		, @CCMD    = @CCMDOUTPUT OUTPUT  
	  
	   IF @CCMDOUTPUT = ''  
		EXEC UPDATEPMT   
		   @CXNTYPE   = 'SCC'    
		 , @CXNNO   = @CMEMONOVAL  
		 , @CXNID   = @CKEYFIELDVAL1  
		 , @NREVERTFLAG  = 1  
		 , @NALLOWNEGSTOCK = 0  
		 , @NCHKDELBARCODES = 1  
		 , @NUPDATEMODE  = @NUPDATEMODE      
		 , @CCMD    = @CCMDOUTPUT OUTPUT  
	     
	   IF @CCMDOUTPUT <> ''  
	   BEGIN  
		PRINT @CCMDOUTPUT  
	      
		SET @NSTEP = 35  
		PRINT @NSTEP   
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR REVERTING THE STOCK STATUS IN PMT....'  
		SET @BNEGSTOCKFOUND=1      
		EXEC SP_EXECUTESQL @CCMDOUTPUT  
		GOTO END_PROC  
	   END  
	     
	     
	   SET @NSTEP = 40  
	   -- UPDATING SENTTOHO FLAG  
	   SET @CCMD = N'UPDATE SCM01106 SET CANCELLED = 1,LAST_UPDATE=GETDATE() ' +   
		  N' WHERE MEMO_ID = ''' + @CMEMOID + '''' 
		  --SENT_TO_HO=0, 
	   EXEC SP_EXECUTESQL @CCMD  
	     
	   GOTO END_PROC  
  END  
    
  SET @NSTEP = 50  
  PRINT @NSTEP  
  SET @CCMD=N'DELETE FROM '+@CTEMPDETAILTABLENAME1+' WHERE ARTICLE_CODE IN ('''',''00000000'') and sp_id ='''+@NSPID +''' '  
  EXEC SP_EXECUTESQL @CCMD  
    
  SET @NSTEP = 55   
  PRINT @NSTEP  
  --EXEC SP_VALIDATEXN_BEFORESAVE 'SCF',@NSPID,'0000000',@NUPDATEMODE,@CCMDOUTPUT OUTPUT,@BNEGSTOCKFOUND OUTPUT  
    
  IF ISNULL(@CCMDOUTPUT,'') <> ''  
  BEGIN  
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION ON TEMP DATA FAILED : ' + @CCMDOUTPUT + '...'  
   GOTO END_PROC  
  END  
    
  DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))  
  
  SET @NSTEP = 60  -- SETTTING UP ENVIRONMENT  
  PRINT @NSTEP  
  -- TEMPORARY DATABASE Discarded now onwards as per Meeting on 30-10-2020 mentioned in Client issues List
  SET @CTEMPDBNAME = ''  
  
  SET @CMASTERTABLENAME = 'SCM01106'  
  SET @CDETAILTABLENAME1 = 'SCF01106'  
  SET @CDETAILTABLENAME2 = 'SCC01106'  
  
  SET @CTEMPMASTERTABLENAME = 'SCF_SCM01106_UPLOAD'
  SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME  
  SET @CTEMPDETAILTABLE1 = @CTEMPDBNAME + @CTEMPDETAILTABLENAME1  
  SET @CTEMPDETAILTABLE2 = @CTEMPDBNAME + @CTEMPDETAILTABLENAME2  
    
  SET @CERRORMSG   = ''  
  SET @LDONOTUPDATESTOCK = 0  
  SET @CKEYFIELD1   = 'MEMO_ID'  
  SET @CMEMONO   = 'MEMO_NO'  
  SET @NMEMONOLEN   = 10  
  
 SELECT @CLOCID=LOCATION_CODE FROM SCF_SCM01106_UPLOAD (nolock) WHERE SP_ID=@NSPID     
    
    
  IF ISNULL(@CLOCID,'')=''  
	SELECT @CLOCATIONID  =DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
  ELSE
	SELECT @CLOCATIONID=@CLOCID
  
  SELECT @CHODEPTID  = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'    
    
     IF ISNULL(@CLOCATIONID,'')=''
	 BEGIN
		SET @CERRORMSG =' LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	 END


  SET @NSTEP=70  
  PRINT @NSTEP  
    
  -- GETTING DEPT_ID FROM TEMP MASTER TABLE  
  SET @CCMD = 'SELECT @CMEMODEPTID = DEPT_ID, @CKEYFIELDVAL1 = MEMO_ID FROM '+@CTEMPMASTERTABLE  +' WHERE SP_ID='''+@NSPID +''' '
   
  EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(4) OUTPUT, @CKEYFIELDVAL1 VARCHAR(50) OUTPUT',   
          @CMEMODEPTID OUTPUT, @CKEYFIELDVAL1 OUTPUT  
  IF (@CMEMODEPTID IS NULL )  
  BEGIN  
     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED...'  
     --SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
     GOTO END_PROC      
  END  
  
  -- START UPDATING XN TABLES   
  IF @NUPDATEMODE = 1 -- ADDMODE   
  BEGIN   
	   SET @NSTEP = 80  -- GENERATING NEW KEY  
	   PRINT @NSTEP  
	   PRINT 'GENERATING NEW KEY... START'     
	   IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
	   BEGIN  
			-- GENERATING NEW MEMO_NO    
			SET @NSAVETRANLOOP=0  
			WHILE @NSAVETRANLOOP=0  
			BEGIN  
			 SET @NSTEP=90  
			 PRINT @NSTEP  
			 EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1, @CFINYEAR,0, @CMEMONOVAL OUTPUT     
		       
			 PRINT @CMEMONOVAL  
		       
			 SET @NSTEP=100  
			 PRINT @NSTEP  
			 SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM '+@CMASTERTABLENAME+'   
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
			   -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
			   GOTO END_PROC      
			END  
		  
			PRINT 'GENERATING NEW KEY... START'     
			SET @NSTEP = 110  -- GENERATING NEW ID  
		  
			-- GENERATING NEW MRR ID  
			SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
			
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
			BEGIN  
			   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
			   -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
			   GOTO END_PROC  
			END  
		      
			SET @NSTEP = 120  
		      
			-- RECHECKING IF ID IS STILL LATER  
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
			BEGIN  
			 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
			 GOTO END_PROC  
			END      
		  
		  
			SET @NSTEP = 130  -- UPDATING NEW ID INTO TEMP TABLES  
		  
			-- UPDATING NEWLY GENERATED MRR NO AND MRR ID IN PIM AND PID TEMP TABLES  
			SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' +   
			   @CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+@NSPID +''' '  
			EXEC SP_EXECUTESQL @CCMD  
		     
			SET @NSTEP = 135  -- UPDATING NEW ID INTO TEMP TABLES  
		      
			SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+@NSPID +''''  
			PRINT @CCMD  
			EXEC SP_EXECUTESQL @CCMD  
		  
			SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE2 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+@NSPID +''' '  
			PRINT @CCMD  
			EXEC SP_EXECUTESQL @CCMD  
	   END  
  
  END     -- END OF ADDMODE  
  ELSE    -- CALLED FROM EDITMODE  
  BEGIN    -- START OF EDITMODE  
    
	   SET @NSTEP = 150  -- GETTING ID INFO FROM TEMP TABLE  
	  
	   -- GETTING MEMO_ID WHICH IS BEING EDITED  
	   SET @CCMD = 'SELECT @CKEYFIELDVAL1 = MEMO_ID, @CMEMONOVAL = MEMO_NO FROM '+@CTEMPMASTERTABLE +' WHERE SP_ID='''+@NSPID +'''' 
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT',   
			  @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT  
	   IF (@CKEYFIELDVAL1 IS NULL ) OR (@CMEMONOVAL IS NULL )  
	   BEGIN  
		  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'  
		  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
	        
		  GOTO END_PROC      
	   END  
	   SET @NSTEP = 155  -- STORING OLD STATUS OF BARCODES   

	
	       
	   -- ENTRY IN AUDIT TRAIL (ONLY WHEN USER EXPLICITLY CLICKED ON EDIT BUTTON)  
	   SET @NSTEP = 160  -- AUDIT TRIAL ENTRY  
	  
	   EXEC AUDITLOGENTRY  
		  @CXNTYPE  = 'SCF'  
		, @CXNID  = @CKEYFIELDVAL1  
		, @CDEPTID  = @CMEMODEPTID  
		, @CCOMPUTERNAME= @CMACHINENAME  
		, @CWINUSERNAME = @CWINDOWUSERNAME  
		, @CWIZUSERCODE = @CWIZAPPUSERCODE  
	  
	   -- REVERTING BACK THE STOCK OF PMT W.R.T CURRENT PURCHASE  
	   SET @NSTEP = 170  -- REVERTING STOCK  
	     
	     
	   EXEC UPDATEPMT   
		  @CXNTYPE   = 'SCF'  
		, @CXNNO   = @CMEMONOVAL  
		, @CXNID   = @CKEYFIELDVAL1  
		, @NREVERTFLAG  = 1  
		, @NALLOWNEGSTOCK = 0  
		, @NCHKDELBARCODES = 1  
		, @NUPDATEMODE  = @NUPDATEMODE       
		, @CCMD    = @CCMDOUTPUT OUTPUT  
	     
	   IF @CCMDOUTPUT = ''  
		EXEC UPDATEPMT   
		   @CXNTYPE   = 'SCC'  
		 , @CXNNO   = @CMEMONOVAL  
		 , @CXNID   = @CKEYFIELDVAL1  
		 , @NREVERTFLAG  = 1  
		 , @NALLOWNEGSTOCK = 0  
		 , @NCHKDELBARCODES = 1  
		 , @NUPDATEMODE  = @NUPDATEMODE       
		 , @CCMD    = @CCMDOUTPUT OUTPUT     
	  
	   IF @CCMDOUTPUT <> ''  
	   BEGIN  
		PRINT @CCMDOUTPUT  
	      
		SET @NSTEP = 175  
	       
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR REVERTING THE STOCK STATUS IN PMT....'  
		SET @BNEGSTOCKFOUND=1      
		EXEC SP_EXECUTESQL @CCMDOUTPUT  
		GOTO END_PROC  
	   END  
	     
	   -- DELETING EXISTING ENTRIES FROM SCF01106 TABLE WHERE ROW_ID NOT FOUND IN TEMPTABLE  
	   SET @NSTEP = 230  -- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES  
	  
	   SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME1 + '   
		  WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
		  AND ROW_ID IN   
		  (  
		   SELECT A.ROW_ID   
		   FROM ' + @CDETAILTABLENAME1 + ' A   
		   LEFT OUTER JOIN ' + @CTEMPDETAILTABLE1 + ' B ON A.ROW_ID = B.ROW_ID  AND AND SP_ID='''+@NSPID +'''
		   WHERE  A.' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
		   AND B.ROW_ID IS NULL  
		  )'  
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD  
	  
	   SET @NSTEP = 232  -- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES  
	  
	   SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME2 + '   
		  WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
		  AND ROW_ID IN   
		  (  
		   SELECT A.ROW_ID   
		   FROM ' + @CDETAILTABLENAME2 + ' A   
		   LEFT OUTER JOIN ' + @CTEMPDETAILTABLE2 + ' B ON A.ROW_ID = B.ROW_ID   AND SP_ID='''+@NSPID +'''
		   WHERE A.' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''  
		   AND B.ROW_ID IS NULL  
		  )'  
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD  
   END  
   
   
   SET @NSTEP = 180  
  
   -- RECHECKING IF ID IS STILL LATER  
   IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
   BEGIN  
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
    GOTO END_PROC  
   END      
   
   DECLARE @nTotQty NUMERIC(10,2),@nTotConQty NUMERIC(10,2)

   SELECT @nTotQty=SUM(quantity) FROM SCF_SCF01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
   SELECT @nTotConQty=SUM(quantity) FROM SCF_SCC01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
   
   UPDATE SCF_SCM01106_UPLOAD SET total_quantity=@nTotQty,total_con_quantity=@nTotConQty
   WHERE sp_id=@nSpId

   SET @NSTEP=210    
   
     DECLARE @CWHERECLAUSE VARCHAR(1000)
  SET @CWHERECLAUSE = ' SP_ID='+LTRIM(RTRIM((@NSPID)))     
  
   EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
      @CSOURCEDB = @CTEMPDBNAME  
    , @CSOURCETABLE = @CTEMPMASTERTABLENAME  
    , @CDESTDB  = ''  
    , @CDESTTABLE = @CMASTERTABLENAME  
    , @CKEYFIELD1 = @CKEYFIELD1  
	,@CFILTERCONDITION=@CWHERECLAUSE
    -- , @LUPDATEXNS = 1  
  
   -- UPDATING TRANSACTION TABLE (SCF01106) FROM TEMP TABLE  
   SET @NSTEP = 220  -- UPDATING TRANSACTION TABLE  
  
   -- UPDATING ROW_ID IN TEMP TABLES  
   PRINT 'UPDATING TEMP TABLE'
   PRINT @CTEMPDETAILTABLE2
   SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE2 + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())  
        WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID ='''+@NSPID +''''  
   PRINT @CCMD
   EXEC SP_EXECUTESQL @CCMD  
     
   SET @NSTEP = 222  
   PRINT @CTEMPDETAILTABLE1
   SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())  
        WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID ='''+@NSPID +''' '  
   PRINT @CCMD
   EXEC SP_EXECUTESQL @CCMD  
  
     
     
   --PRINT 'ROHIT'  
   -- INSERTING/UPDATING THE ENTRIES IN SCF01106 TABLE FROM TEMPTABLE  
   SET @NSTEP = 240  -- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES  
  
  
   EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
      @CSOURCEDB = @CTEMPDBNAME  
    , @CSOURCETABLE = @CTEMPDETAILTABLENAME2  
    , @CDESTDB  = ''  
    , @CDESTTABLE = @CDETAILTABLENAME2  
    , @CKEYFIELD1 = 'ROW_ID'  
   ,@CFILTERCONDITION=@CWHERECLAUSE
    -- , @LUPDATEXNS = 1  
    
   SET @NSTEP = 245  -- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES  
   EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
      @CSOURCEDB = @CTEMPDBNAME  
    , @CSOURCETABLE = @CTEMPDETAILTABLENAME1  
    , @CDESTDB  = ''  
    , @CDESTTABLE = @CDETAILTABLENAME1  
    , @CKEYFIELD1 = 'ROW_ID'  
	,@CFILTERCONDITION=@CWHERECLAUSE
    -- , @LUPDATEXNS = 1  
  
   
  
  
    
   IF @LGENERATEBARCODES = 1  
   BEGIN  
		PRINT 'GENERATING BARCODES'  
		SET @NSTEP = 250  -- GENERATING BARCODES  
		--EXEC SAVETRAN_GENBARCODES  
		--   @CXNID  = @CKEYFIELDVAL1  
		-- , @CPREFIX  = ''  
		-- , @NMODE  = 4  
		-- , @CERRORMSG = @CERRORMSG OUTPUT  
		
		
		EXEC SAVETRAN_GENBARCODES
				  @CXNID		= @CKEYFIELDVAL1
				, @CPREFIX		= ''
				, @NMODE		= 4	
				, @LOCID		= @CLOCATIONID	
				, @CERRORMSG	= @CERRORMSG OUTPUT
		
	      
		IF ISNULL(@CERRORMSG,'')<>''  
		 GOTO END_PROC  
	       
		-- CHECK WHETHER BARCODE HAS SUCCESSFULLY GENERATED OR NOT  
		IF EXISTS ( SELECT TOP 1 PRODUCT_CODE FROM SCF01106   
		   WHERE MEMO_ID = @CKEYFIELDVAL1 AND PRODUCT_CODE = '' )  
		BEGIN  
		 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR GENERATING NEW BARCODES....'  
		 -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
	       
		 GOTO END_PROC  
		END  
	  
		-- CHECK ALL BARCODES INSERTED INTO PID  
		IF EXISTS ( SELECT TOP 1 A.PRODUCT_CODE FROM SCF01106 A  
		   LEFT OUTER JOIN SKU B ON A.PRODUCT_CODE = B.PRODUCT_CODE  
		   WHERE A.MEMO_ID = @CKEYFIELDVAL1   
		   AND B.PRODUCT_CODE IS NULL )  
		BEGIN  
		 SET @NSTEP=260  
		 SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR GENERATING NEW BARCODES... NEW CODES NOT GENERATED'  
		 -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
	       
		 GOTO END_PROC  
		END  
   END   
    
LBLUPDATESTOCK:        
  -- UPDATING STOCK OF PMT W.R.T. CURRENT PURCHASE  
  SET @NSTEP = 270  -- UPDATING PMT TABLE  
  
  
  EXEC UPDATEPMT   
     @CXNTYPE   = 'SCF'  
   , @CXNNO   = @CMEMONOVAL  
   , @CXNID   = @CKEYFIELDVAL1  
   , @NREVERTFLAG  = 0  
   , @NALLOWNEGSTOCK = 0  
   , @NCHKDELBARCODES = 1  
   , @NUPDATEMODE  = @NUPDATEMODE       
   , @CCMD    = @CCMDOUTPUT OUTPUT  
  
  
  
  IF @CCMDOUTPUT = ''  
	   EXEC UPDATEPMT   
		  @CXNTYPE   = 'SCC'  
		, @CXNNO   = @CMEMONOVAL  
		, @CXNID   = @CKEYFIELDVAL1  
		, @NREVERTFLAG  = 0  
		, @NALLOWNEGSTOCK = 0  
		, @NCHKDELBARCODES = 1  
		, @NUPDATEMODE  = @NUPDATEMODE       
		, @CCMD    = @CCMDOUTPUT OUTPUT  
  
  
        
  IF @CCMDOUTPUT <> ''  
  BEGIN  
	   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT... STOCK IS GOING NEGATIVE'  
	   -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
	     
	   EXEC SP_EXECUTESQL @CCMDOUTPUT  
	   SET @BNEGSTOCKFOUND=1  
	     
	   GOTO END_PROC  
  END  
  
  
  -- VALIDATING ENTRIES  
    
  SET @NSTEP = 350  
    
  EXEC VALIDATEXN  
     @CXNTYPE = 'SCF'  
   , @CXNID = @CKEYFIELDVAL1  
   , @NUPDATEMODE = @NUPDATEMODE     
   , @CCMD  = @CCMDOUTPUT OUTPUT  
   , @CUSERCODE = @CWIZAPPUSERCODE
   
  IF @CCMDOUTPUT <> ''  
  BEGIN  
	   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION FAILED : ' + @CCMDOUTPUT + '...'  
	   GOTO END_PROC  
  END  
    
 END TRY  
 BEGIN CATCH  
	  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
	  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG, '''' AS MEMO_ID'  
	     
	  GOTO END_PROC  
 END CATCH  
   
END_PROC:  
 UPDATE scm01106 WITH (ROWLOCk) SET last_update=getdate() WHERE memo_id=@CKEYFIELDVAL1
 
     
 IF @@TRANCOUNT>0  
 BEGIN  
	  IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''  
	  BEGIN
			
			UPDATE scm01106 SET reconciled=0,LAST_UPDATE=GETDATE() WHERE memo_id=@CKEYFIELDVAL1  
			UPDATE SCM01106 SET HO_SYNCH_LAST_UPDATE='' WHERE MEMO_ID=@CKEYFIELDVAL1
			 -- CHANGES MADE BY CHANDAN ON 18-06-2019
			COMMIT TRANSACTION
	  END	
	  ELSE  
	   ROLLBACK  
 END  
  
 IF ISNULL(@BNEGSTOCKFOUND,0)=0  
 BEGIN  
	  INSERT @OUTPUT ( ERRMSG, MEMO_ID)  
		VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,'') )  
	  
	  SELECT * FROM @OUTPUT   
 END   


 DELETE  A FROM SCF_SCF01106_UPLOAD A (NOLOCK)  WHERE SP_ID=@NSPID 
 DELETE  A FROM SCF_SCM01106_UPLOAD A (NOLOCK)  WHERE SP_ID=@NSPID 
 DELETE  A FROM SCF_SCC01106_UPLOAD A (NOLOCK)  WHERE SP_ID=@NSPID 
 
 
END  
------------------------------------------------------ END OF PROCEDURE SAVETRAN_SCF  
