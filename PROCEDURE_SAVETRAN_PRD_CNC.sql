CREATE PROCEDURE SAVETRAN_PRD_CNC  
(  
 @NUPDATEMODE  NUMERIC(1,0),  
 @NSPID    INT,  
 @CMEMONOPREFIX  VARCHAR(50),  
 @CFINYEAR   VARCHAR(10),  
 @CMACHINENAME  VARCHAR(100)='',  
 @CWINDOWUSERNAME VARCHAR(100)='',  
 @CWIZAPPUSERCODE VARCHAR(10)='0000000',  
 @CMEMOID   VARCHAR(40)='',
 @CLOCID	VARCHAR(2)=''  
)  
--WITH ENCRYPTION
AS  
BEGIN  
 -- @NUPDATEMODE: 1- NEW STOCK ADJUSTMENT MEMO ADDED,   
 --     2- NOT APPLICABLE,   
 --     3- CURRENT STOCK ADJUSTMENT MEMO CANCELLED,   
 --     4- EXISTING STOCK ADJUSTMENT MEMO EDITED  
  
 DECLARE @CTEMPDBNAME   VARCHAR(100),  
   @CMASTERTABLENAME  VARCHAR(100),  
   @CDETAILTABLENAME  VARCHAR(100),  
   @CTEMPMASTERTABLENAME VARCHAR(100),  
   @CTEMPDETAILTABLENAME VARCHAR(100),  
   @CTEMPMASTERTABLE  VARCHAR(100),  
   @CTEMPDETAILTABLE  VARCHAR(100),  
   @CERRORMSG    VARCHAR(500),  
   @LDONOTUPDATESTOCK  BIT,  
   @CKEYFIELD1    VARCHAR(50),  
   @CKEYFIELDVAL1   VARCHAR(50),  
   @CMEMONO    VARCHAR(20),  
   @NMEMONOLEN    NUMERIC(20,0),  
   @CMEMONOVAL    VARCHAR(50),  
   @CMEMODEPTID   VARCHAR(2),  
   @CLOCATIONID   VARCHAR(2),  
   @CHODEPTID    VARCHAR(2),  
   @CCMD     NVARCHAR(4000),  
   @CCMDOUTPUT    NVARCHAR(4000),  
   @NSAVETRANLOOP   BIT,  
   @NSTEP     INT,  
   @LENABLETEMPDATABASE BIT,@BNEGSTOCKFOUND BIT,  
   @NCNCTYPE    INT,  
   @CXNTYPE    VARCHAR(10),
   @BREVERT BIT  
  
 DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))  
  
 SET @NSTEP = 0  -- SETTTING UP ENVIRONMENT  
  
 SELECT @LENABLETEMPDATABASE = CAST([VALUE] AS BIT) FROM CONFIG WHERE CONFIG_OPTION = 'ENABLE_TEMP_DATABASE'  
 IF @LENABLETEMPDATABASE IS NULL  
  SET @LENABLETEMPDATABASE = 0  
  
 -- CHECK TEMPORARY DATABASE TO HOLD TEMP TABLES   
 -- IF CONFIG SETTING SAYS TO DO SO  
 IF @LENABLETEMPDATABASE = 1  
  SET @CTEMPDBNAME = DB_NAME() + '_TEMP.DBO.'  
 ELSE  
  SET @CTEMPDBNAME = ''  
  
 SET @CMASTERTABLENAME = 'PRD_ICM01106'  
 SET @CDETAILTABLENAME = 'PRD_ICD01106'  
 --SET @CDETAILTABLENAME2 = 'PRD_JID_RM'  
  
 SET @CTEMPMASTERTABLENAME = 'TEMP_PRD_ICM01106_'+LTRIM(RTRIM(STR(@NSPID)))  
 SET @CTEMPDETAILTABLENAME = 'TEMP_PRD_ICD01106_'+LTRIM(RTRIM(STR(@NSPID)))  
  
 SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME  
 SET @CTEMPDETAILTABLE = @CTEMPDBNAME + @CTEMPDETAILTABLENAME  
   
 SET @CERRORMSG   = ''  
 SET @LDONOTUPDATESTOCK = 0  
 SET @CKEYFIELD1   = 'CNC_MEMO_ID'  
 SET @CMEMONO   = 'CNC_MEMO_NO'  
 SET @NMEMONOLEN   = 10  
 
 IF ISNULL(@CLOCID,'')='' 
	SELECT @CLOCATIONID  = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'  
 ELSE
	SELECT @CLOCATIONID=@CLOCID
 
 SELECT @CHODEPTID  = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'    
  
  
 SET @NSTEP = 10  -- GETTING DEPTID INFO FROM TEMP TABLE  
   
 BEGIN TRANSACTION  
   
 BEGIN TRY  
  
  IF OBJECT_ID('TEMPDB..#TMPPMT','U') IS NOT NULL  
   DROP TABLE #TMPPMT  
    
  SELECT PRODUCT_UID INTO #TMPPMT FROM PRD_SKU WHERE 1=2  
  
  IF OBJECT_ID('TEMPDB..#TMPXNSTK','U') IS NOT NULL  
   DROP TABLE #TMPXNSTK           
    
  SELECT PRODUCT_UID,QUANTITY_IN_STOCK AS XN_STOCK INTO #TMPXNSTK FROM PRD_PMT WHERE 1=2  
    
  IF @NUPDATEMODE<>3  
  BEGIN  
   EXEC SP_VALIDATEXN_BEFORESAVE 'PRDCNC',@NSPID,'0000000',@NUPDATEMODE,@CCMDOUTPUT OUTPUT,@BNEGSTOCKFOUND OUTPUT  
   IF ISNULL(@CCMDOUTPUT,'') <> ''  
   BEGIN  
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION ON TEMP DATA FAILED : ' + @CCMDOUTPUT + '...'  
    GOTO END_PROC  
   END  
  END  
  
  
  IF @NUPDATEMODE = 3 AND ISNULL(@CMEMOID,'') = ''  
  BEGIN  
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID REQUIRED IF CALLED FROM CANCELLATION'  
   GOTO END_PROC      
  END  
  -- GETTING DEPT_ID A FROM TEMP MASTER TABLE  
  SET @CCMD = 'SELECT @CMEMODEPTID = DEPT_ID, @NCNCTYPE = CNC_TYPE FROM '   
     + (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME ELSE @CTEMPMASTERTABLE END )  
    
  EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(2) OUTPUT, @NCNCTYPE INT OUTPUT',   
         @CMEMODEPTID OUTPUT, @NCNCTYPE OUTPUT  
  IF (@CMEMODEPTID IS NULL )  
  BEGIN  
     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'  
     GOTO END_PROC      
  END  
  
  SET @NSTEP = 11  
  
  IF (ISNULL(@NCNCTYPE,0) NOT IN (1,2) )  
  BEGIN  
     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'  
     GOTO END_PROC      
  END  
  
  SET @NSTEP = 12  
  
  SET @CXNTYPE = (CASE WHEN @NCNCTYPE=1 THEN 'PRDCNC' ELSE 'PRDUNC' END)  
  IF (ISNULL(@CXNTYPE,'') NOT IN ('PRDCNC','PRDUNC') )  
  BEGIN  
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'  
   GOTO END_PROC      
  END  
  
--PRINT '@CXNTYPE ' + @CXNTYPE  
  
  -- START UPDATING XN TABLES   
  IF @NUPDATEMODE = 1 -- ADDMODE   
  BEGIN   
  
   SET @NSTEP = 20  -- GENERATING NEW KEY  
     
   -- GENERATING NEW JOB ORDER NO    
   SET @NSAVETRANLOOP=0  
   WHILE @NSAVETRANLOOP=0  
   BEGIN  
    EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,  
        @CFINYEAR,0, @CMEMONOVAL OUTPUT     
      
    PRINT @CMEMONOVAL  
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
      GOTO END_PROC      
   END  
  
   SET @NSTEP = 30  -- GENERATING NEW ID  
  
   -- GENERATING NEW JOB ORDER ID  
   SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))  
   IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
   BEGIN  
      SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
      -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
      GOTO END_PROC  
   END  
  
   SET @NSTEP = 40  -- UPDATING NEW ID INTO TEMP TABLES  
  
   SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' +   
      @CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''''  
   EXEC SP_EXECUTESQL @CCMD  
    
   SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''''  
   EXEC SP_EXECUTESQL @CCMD  
  
  END     -- END OF ADDMODE  
  ELSE    -- CALLED FROM EDITMODE  
  BEGIN    -- START OF EDITMODE  
    
   SET @NSTEP = 50  -- GETTING ID INFO FROM TEMP TABLE  
  
   SET @CCMD = 'SELECT @CKEYFIELDVAL1 = ' + @CKEYFIELD1 + ', @CMEMONOVAL = ' + @CMEMONO + ' FROM '   
      + (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME + ' WHERE CNC_MEMO_ID = ''' + @CMEMOID + ''''   
        ELSE @CTEMPMASTERTABLE END )  
        
   EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT',   
          @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT  
   IF (@CKEYFIELDVAL1 IS NULL ) OR (@CMEMONOVAL IS NULL )  
   BEGIN  
      SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'  
      GOTO END_PROC      
   END  
  
   SET @NSTEP = 55  -- STORING OLD STATUS OF BARCODES   
  
   IF @NUPDATEMODE = 3     
   BEGIN  
    SET @NSTEP = 60  
    -- UPDATING SENTTOHO FLAG  
    SET @CCMD = N'UPDATE ' + @CMASTERTABLENAME + ' SET CANCELLED = 1,LAST_UPDATE=GETDATE() ' +   
       N' WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''''  
    EXEC SP_EXECUTESQL @CCMD  
	   	
   END  
     
   ELSE 
    
   BEGIN  
  
    SET @NSTEP = 65  -- UPDATING SENT_TO_HO FLAG TEMP TABLE  
  
    -- UPDATING SENTTOHO FLAG  
    SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET SENT_TO_HO = 0,LAST_UPDATE=GETDATE() '  
    EXEC SP_EXECUTESQL @CCMD  
         
        
    -- ENTRY IN AUDIT TRAIL (ONLY WHEN USER EXPLICITLY CLICKED ON EDIT BUTTON)  
    SET @NSTEP = 70  -- AUDIT TRIAL ENTRY  
  
    EXEC AUDITLOGENTRY  
       @CXNTYPE  = @CXNTYPE  
     , @CXNID  = @CKEYFIELDVAL1  
     , @CDEPTID  = @CMEMODEPTID  
     , @CCOMPUTERNAME= @CMACHINENAME  
     , @CWINUSERNAME = @CWINDOWUSERNAME  
     , @CWIZUSERCODE = @CWIZAPPUSERCODE  
   END  
     
   -- REVERTING BACK THE STOCK OF JOBPMT W.R.T CURRENT ISSUE  
   SET @NSTEP = 85  -- REVERTING STOCK  
	SET @CCMD=N'SELECT @BREVERT=(CASE WHEN CNC_TYPE=1 THEN 0 ELSE 1 END) FROM '+ @CMASTERTABLENAME 
				+' WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''''  
	   EXEC SP_EXECUTESQL @CCMD,N'@BREVERT BIT OUTPUT',@BREVERT OUTPUT	
	   --SELECT 'CASE OF CANCEL FOR UNCANCEL'
	   --SELECT @NCNCTYPE,@BREVERT
	   		 
	   EXEC UPDATEPMT_PRD  
		  @CXNTYPE   = @CXNTYPE  
		, @CXNNO   = @CMEMONOVAL  
		, @CXNID   = @CKEYFIELDVAL1  
		, @NREVERTFLAG  = @BREVERT  
		, @NALLOWNEGSTOCK = 0  
		, @NCHKDELBARCODES = 1  
		, @NUPDATEMODE  = @NUPDATEMODE      
		, @CCMD    = @CCMDOUTPUT OUTPUT  
  
   IF (@NUPDATEMODE = 3)   
   BEGIN  
    IF @CCMDOUTPUT <> ''  
    BEGIN  
     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT....'  
     SET @BNEGSTOCKFOUND=1  
     EXEC SP_EXECUTESQL @CCMDOUTPUT  
    END   
    GOTO END_PROC  
   END  
  
     
   
  END     -- END OF EDITMODE  
  
  SET @NSTEP = 95  
    
  -- RECHECKING IF ID IS STILL LATER  
  IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
  BEGIN  
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
   GOTO END_PROC  
  END  
  
  
  IF @NUPDATEMODE <> 3  
  BEGIN  
   SET @NSTEP = 100  -- UPDATING MASTER TABLE  
    
     EXEC UPDATEMASTERXN   
      @CSOURCEDB = @CTEMPDBNAME  
    , @CSOURCETABLE = @CTEMPMASTERTABLENAME  
    , @CDESTDB  = ''  
    , @CDESTTABLE = @CMASTERTABLENAME  
    , @CKEYFIELD1 = @CKEYFIELD1  
    , @BALWAYSUPDATE = 1
  
   SET @NSTEP = 110  -- UPDATING TRANSACTION TABLE  
    
    -- UPDATING ROW_ID IN TEMP TABLES  
    SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())  
         WHERE LEFT(ROW_ID,5) = ''LATER'''  
    EXEC SP_EXECUTESQL @CCMD  
  
    -- DELETING EXISTING ENTRIES FROM PRD_ICD01106 TABLE WHERE ROW_ID NOT FOUND IN TEMPTABLE  
    SET @NSTEP = 114  -- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES  
  
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
    EXEC SP_EXECUTESQL @CCMD  
  
    -- INSERTING/UPDATING THE ENTRIES IN PRD_JID TABLE FROM TEMPTABLE  
    SET @NSTEP = 116  -- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES  
 
    EXEC UPDATEMASTERXN   
       @CSOURCEDB = @CTEMPDBNAME  
     , @CSOURCETABLE = @CTEMPDETAILTABLENAME  
     , @CDESTDB  = ''  
     , @CDESTTABLE = @CDETAILTABLENAME  
     , @CKEYFIELD1 = 'ROW_ID'  
     , @BALWAYSUPDATE = 1
     -- , @LUPDATEXNS = 1  
   -- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO  
   SET @NSTEP = 130  -- UPDATING PMT TABLE  
    
   
   PRINT 'CALLING UPDATEPMT'  
   --REVERT BIT
    SET @BREVERT=CASE WHEN @NCNCTYPE=1 THEN 1 ELSE 0 END
   EXEC UPDATEPMT_PRD   
      @CXNTYPE   = @CXNTYPE  
    , @CXNNO   = @CMEMONOVAL  
    , @CXNID   = @CKEYFIELDVAL1  
    , @NREVERTFLAG  = @BREVERT  
    , @NALLOWNEGSTOCK = 0  
    , @NCHKDELBARCODES = 1  
    , @NUPDATEMODE  = @NUPDATEMODE      
    , @CCMD    = @CCMDOUTPUT OUTPUT  
     
   IF @CCMDOUTPUT <> ''  
   BEGIN  
      
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR UPDATING THE STOCK STATUS IN PMT....'  
    -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG,'''' AS MEMO_ID'  
      
    SET @BNEGSTOCKFOUND=1  
    EXEC SP_EXECUTESQL @CCMDOUTPUT  
    GOTO END_PROC  
   END  
  END  
  
    
  -- VALIDATING ENTRIES   
  SET @NSTEP = 150  -- VALIDATING ENTRIES  
    
  EXEC VALIDATEXN  
     @CXNTYPE = 'PRDCNC'  
   , @CXNID = @CKEYFIELDVAL1  
   , @NUPDATEMODE = @NUPDATEMODE     
   , @CCMD  = @CCMDOUTPUT OUTPUT  
   , @CUSERCODE = @CWIZAPPUSERCODE
   
  IF @CCMDOUTPUT <> ''  
  BEGIN  
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION FAILED : ' + @CCMDOUTPUT + '...'  
   GOTO END_PROC  
  END  
  
  -- AFTER SUCCESSFUL SAVING , JUST DROP THE TEMP TABLES CREATED BY APPLICATION  
  SET @NSTEP = 160  
    
   
 END TRY  
 BEGIN CATCH  
  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
  -- SET @CRETCMD= N'SELECT '''+@CERRORMSG+''' AS ERRMSG, '''' AS MEMO_ID'  
    
  GOTO END_PROC  
 END CATCH  
   
END_PROC:  
  
 IF @@TRANCOUNT>0  
 BEGIN  
  IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')=''  
    COMMIT TRANSACTION   
  ELSE  
   ROLLBACK  
 END  
   
 IF ISNULL(@BNEGSTOCKFOUND,0)=0  
 BEGIN  
  INSERT @OUTPUT ( ERRMSG, MEMO_ID)  
    VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,'') )  
  
  SELECT * FROM @OUTPUT   
 END   
  
 EXEC SP_DROPTEMPTABLES_XNS 'XNSCNC',@NSPID    
END      -- SAVETRAN_CNC  
---------------------------------------- END OF PROCEDURE SAVETRAN_CNC
