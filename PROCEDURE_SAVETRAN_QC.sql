create PROCEDURE SAVETRAN_QC        
(        
 @NUPDATEMODE  NUMERIC(1,0),        
 @NSPID    VARCHAR(40),        
 @CFINYEAR   VARCHAR(10),        
 @CXNMEMOID   VARCHAR(40)=''
)        
----WITH ENCRYPTION      
AS        
BEGIN        
         
 DECLARE @NSTEP INT ,@BALLOWNEGSTOCK BIT        
       
BEGIN TRY        
       --changes by Dinkar in location id varchar(4)..
  -- @NUPDATEMODE: 1- NEW RETAIL SALE ADDED,         
  --     2- NOT APPLICABLE,         
  --     3- CURRENT RETAIL SALE CANCELLED,         
  --     4- EXISTING RETAIL SALE EDITED        
          
  -- @CMEMOID:  MEMOID IS REQUIRED IF @NUPDATEMODE IS 3 (FROM CANCELLATION)        
  DECLARE @CTEMPDBNAME   VARCHAR(100),        
    @CMASTERTABLENAME  VARCHAR(100),        
    @CDETAILTABLENAME  VARCHAR(100),       
    @CDETAILTABLENAME1  VARCHAR(100),        
    @CTEMPMASTERTABLENAME VARCHAR(100),        
    @CTEMPDETAILTABLENAME VARCHAR(100),      
    @CTEMPDETAILTABLENAME1 VARCHAR(100),        
    @CTEMPMASTERTABLE  VARCHAR(100),        
    @CTEMPDETAILTABLE  VARCHAR(100),        
    @CTEMPDETAILTABLE1  VARCHAR(100),        
    @CERRORMSG    VARCHAR(500),        
    @LDONOTUPDATESTOCK  BIT,        
    @CKEYFIELD1    VARCHAR(50),        
    @CKEYFIELDVAL1   VARCHAR(50),        
    @CKEYFIELD1_DETAIL2  VARCHAR(50),        
    @CMEMONO    VARCHAR(20),        
    @NMEMONOLEN    NUMERIC(20,0),        
    @CMEMONOVAL    VARCHAR(50),        
    @CMEMODEPTID   VARCHAR(4),        
    @CLOCATIONID   VARCHAR(4),        
    @CHODEPTID    VARCHAR(4),        
    @CCMD     NVARCHAR(4000),        
    @CCMDOUTPUT    NVARCHAR(4000),        
    @NSAVETRANLOOP   BIT,        
    @CREFAPPMEMOID   VARCHAR(40),        
    @LENABLETEMPDATABASE BIT,@BNEGSTOCKFOUND BIT  ,@CMEMOPREFIXPROC VARCHAR(25),      
    @CWIZAPPUSERCODE VARCHAR(10),@CMEMONOPREFIX  VARCHAR(50) ,@CLOCID VARCHAR(4)     
         
          
 SET @NSTEP = 5  -- DO VALIDATIONS ON INPUT DATA BY USER        
          
 DECLARE @CRETVAL VARCHAR(MAX)        
          
          
          
 DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100),MEMO_NO VARCHAR(100))        
         
          
 SET @CREFAPPMEMOID = ''        
          
 SET @NSTEP = 7  -- SETTTING UP ENVIRONMENT        
         
      
 SET @CTEMPDBNAME = ''        
         
 SET @CMASTERTABLENAME  = 'QC_XN_MST'        
 SET @CDETAILTABLENAME  = 'QC_XN_DET_1'        
 SET @CDETAILTABLENAME1 = 'QC_XN_DET_2'        
      
         
 SET @CTEMPMASTERTABLENAME  = 'QC_QC_XN_MST_UPLOAD'      
 SET @CTEMPDETAILTABLENAME  = 'QC_QC_XN_DET_1_UPLOAD'      
 SET @CTEMPDETAILTABLENAME1 = 'QC_QC_XN_DET_2_UPLOAD'      
         
         
 SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME        
 SET @CTEMPDETAILTABLE = @CTEMPDBNAME + @CTEMPDETAILTABLENAME        
 SET @CTEMPDETAILTABLE1 = @CTEMPDBNAME + @CTEMPDETAILTABLENAME1        
          
 SET @CERRORMSG   = ''        
 SET @LDONOTUPDATESTOCK = 0        
 SET @CKEYFIELD1   = 'MEMO_ID'        
   SET @CMEMONO       = 'MEMO_NO'        
 SET @NMEMONOLEN   = 10        
 
SELECT @CLOCID=LOCATION_CODE FROM QC_QC_XN_MST_UPLOAD (nolock) WHERE SP_ID=@NSPID  
 
 IF ISNULL(@CLOCID,'')=''       
  SELECT @CLOCATIONID  =value from config where config_option ='location_id'
 ELSE       
  SET @CLOCATIONID=@CLOCID      
        
 SELECT @CHODEPTID  = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'          
             
           
    BEGIN TRANSACTION        
 IF ISNULL(@CLOCATIONID,'')=''
 BEGIN
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' LOCATION ID CAN NOT BE BLANK  '  
	GOTO END_PROC    
 END
          
 IF @NUPDATEMODE=3 AND ISNULL(@CXNMEMOID,'') = ''        
 BEGIN        
     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' MEMO ID REQUIRED IF CALLED FROM CANCELLATION'        
     GOTO END_PROC            
 END        
         
         
       
           
 SET @NSTEP=15        
         
      
 -- GETTING DEPT_ID FROM TEMP MASTER TABLE        
 SET @CCMD = 'SELECT @CMEMODEPTID = location_code FROM '         
   + (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME ELSE @CTEMPMASTERTABLE +' WHERE SP_ID='''+LTRIM(RTRIM((@NSPID))) +''' ' END )        
   EXEC SP_EXECUTESQL @CCMD, N'@CMEMODEPTID VARCHAR(4) OUTPUT',         
    @CMEMODEPTID OUTPUT        
 IF (@CMEMODEPTID IS NULL )        
 BEGIN        
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE SAVED... INCORRECT PARAMETER'        
   GOTO END_PROC            
 END        
         
 -- START UPDATING XN TABLES         
 IF @NUPDATEMODE = 1 -- ADDMODE         
 BEGIN         
       
            SELECT @CWIZAPPUSERCODE=USER_CODE,@CMEMONOPREFIX=MEMO_PREFIX FROM QC_QC_XN_MST_UPLOAD      
      
    EXEC SAVETRAN_GETMEMOPREFIX      
    @CXNTYPE='QC',      
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
         
          
            
   SET @NMEMONOLEN   = LEN(@CMEMOPREFIXPROC)+6     
     
       
            
     SET @NSTEP = 20  -- GENERATING NEW KEY        
             
     -- GENERATING NEW MEMO NO          
     SET @NSAVETRANLOOP=0        
     WHILE @NSAVETRANLOOP=0        
     BEGIN        
         EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMOPREFIXPROC, 1,        
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
     SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
           
     IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'      
     BEGIN        
     SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'        
     GOTO END_PROC        
     END        
          
     SET @NSTEP = 32  -- UPDATING NEW ID INTO TEMP TABLES        
             
     -- UPDATING NEWLY GENERATED JOB ORDER NO AND JOB ORDER ID IN PIM AND PID TEMP TABLES        
     SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' +         
     @CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+LTRIM(RTRIM((@NSPID))) +''''        
     PRINT @CCMD        
     EXEC SP_EXECUTESQL @CCMD        
             
     SET @NSTEP = 34        
             
     SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+LTRIM(RTRIM((@NSPID))) +''''        
     PRINT @CCMD        
     EXEC SP_EXECUTESQL @CCMD        
           
     SET @NSTEP = 34        
             
     SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE1 + ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''' WHERE SP_ID='''+LTRIM(RTRIM((@NSPID))) +''''        
     PRINT @CCMD        
     EXEC SP_EXECUTESQL @CCMD       
                
 END     -- END OF ADDMODE        
 ELSE    -- CALLED FROM EDITMODE        
 BEGIN    -- START OF EDITMODE        
           
     SET @NSTEP = 50  -- GETTING ID INFO FROM TEMP TABLE        
     -- GETTING CM ID WHICH IS BEING EDITED        
     SET @CCMD = 'SELECT @CKEYFIELDVAL1 = ' + @CKEYFIELD1 + ', @CMEMONOVAL = ' + @CMEMONO + ' FROM '        
     + (CASE WHEN @NUPDATEMODE=3 THEN @CMASTERTABLENAME + ' WHERE MEMO_ID = ''' + @CXNMEMOID + ''''         
    ELSE @CTEMPMASTERTABLE +' WHERE SP_ID='''+LTRIM(RTRIM((@NSPID))) +'''' END )        
             
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
			SET @NSTEP=60  
			SET @CCMD = N'UPDATE ' + @CMASTERTABLENAME + ' SET CANCELLED = 1,LAST_UPDATE=GETDATE() ' +         
			   N' WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''''
			        
			EXEC SP_EXECUTESQL @CCMD        
     END        
       
   SET @CCMD = N'UPDATE ' + @CTEMPMASTERTABLE + ' SET LAST_UPDATE=GETDATE() WHERE SP_ID='''+LTRIM(RTRIM((@NSPID))) +''' '        
   EXEC SP_EXECUTESQL @CCMD        
                 
                
         
            
 END     -- END OF EDITMODE        
         
 SET @NSTEP = 95        
           
 -- RECHECKING IF ID IS STILL LATER        
 IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'      
 BEGIN        
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'        
    GOTO END_PROC        
 END        
         
 -- UPDATING MASTER TABLE (PIM01106) FROM TEMP TABLE        
        
         
       
 SET @NSTEP = 105      
       
 DECLARE @FILTER VARCHAR(100)      
    SET @FILTER=' SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''      
                              
    EXEC UPDATEMASTERXN_MIRROR--UPDATEMASTERXN         
    @CSOURCEDB = @CTEMPDBNAME        
  , @CSOURCETABLE = @CTEMPMASTERTABLENAME        
  , @CDESTDB  = ''        
  , @CDESTTABLE = @CMASTERTABLENAME        
  , @CKEYFIELD1 = @CKEYFIELD1        
  , @BALWAYSUPDATE = 1       
  ,@CFILTERCONDITION=@FILTER       
         
 SET @NSTEP = 110  -- UPDATING TRANSACTION TABLE        
            
            
 SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())        
   WHERE LEFT(ROW_ID,5) = ''LATER'' AND SP_ID='''+LTRIM(RTRIM((@NSPID))) +''''        
 EXEC SP_EXECUTESQL @CCMD        
         
 SET @NSTEP = 111  -- UPDATING TRANSACTION TABLE - PAYMODE_XN_DET        
            
 -- DELETING EXISTING ENTRIES FROM PID01106 TABLE WHERE ROW_ID NOT FOUND IN TEMPTABLE        
 SET @NSTEP = 114  -- UPDATING TRANSACTION TABLE - DELETING EXISTING ENTRIES        
            
 -- CMD01106        
 SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME + '         
    WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''        
    AND ROW_ID IN         
    (        
     SELECT A.ROW_ID         
     FROM ' + @CDETAILTABLENAME + ' A         
     LEFT OUTER JOIN ' + @CTEMPDETAILTABLE + ' B ON A.ROW_ID = B.ROW_ID  AND B.SP_ID='''+LTRIM(RTRIM((@NSPID))) +'''       
     WHERE A.' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + '''        
     AND   B.ROW_ID IS NULL        
    )'        
 EXEC SP_EXECUTESQL @CCMD        
            
 SET @NSTEP = 117  -- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES        
            
        
 EXEC UPDATEMASTERXN_MIRROR--UPDATEMASTERXN         
    @CSOURCEDB = @CTEMPDBNAME        
  , @CSOURCETABLE = @CTEMPDETAILTABLENAME        
  , @CDESTDB  = ''        
  , @CDESTTABLE = @CDETAILTABLENAME        
  , @CKEYFIELD1 = 'ROW_ID'        
, @BALWAYSUPDATE = 1       
  ,@CFILTERCONDITION=@FILTER       
            
 SET @NSTEP = 119        
      
    -- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO        
 SET @NSTEP = 130        
   EXEC UPDATEMASTERXN_MIRROR--UPDATEMASTERXN         
    @CSOURCEDB = @CTEMPDBNAME        
  , @CSOURCETABLE = @CTEMPDETAILTABLENAME1        
  , @CDESTDB  = ''        
  , @CDESTTABLE = @CDETAILTABLENAME1        
  , @CKEYFIELD1 = 'MEMO_ID'        
  , @BALWAYSUPDATE = 1       
  ,@CFILTERCONDITION=@FILTER        
   
    SET @NSTEP = 140        
   
   IF EXISTS (SELECT TOP 1 'U' FROM QC_XN_DET_1 WHERE ISNULL(PENDING_PO_QUANTITY,0) <ISNULL(QC_QUANTITY,0) 
   AND MEMO_ID =@CKEYFIELDVAL1 )
   BEGIN
        
        SET @CERRORMSG = 'QC QUANTITY CAN NOT BE GREATER THEN PENDING QTY....'        
        GOTO END_PROC    
   
   END
         
       
            
       
END TRY        
      
BEGIN CATCH        
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()        
           
   GOTO END_PROC        
END CATCH        
          
END_PROC:        
      
     PRINT 'ERROR AT LAT : '+ISNULL(@CERRORMSG,'') + ISNULL(@CCMDOUTPUT,'') + STR(ISNULL(@BNEGSTOCKFOUND,0))      
          
  IF @@TRANCOUNT>0        
  BEGIN        
    IF ISNULL(@CERRORMSG,'')='' AND ISNULL(@CCMDOUTPUT,'')='' AND ISNULL(@BNEGSTOCKFOUND,0)=0        
    BEGIN      
    COMMIT TRANSACTION      
    END       
    ELSE        
   ROLLBACK        
  END        
          
  IF ISNULL(@BNEGSTOCKFOUND,0)=0        
  BEGIN        
    INSERT @OUTPUT ( ERRMSG, MEMO_ID,MEMO_NO)      
     VALUES ( ISNULL(@CERRORMSG,''), ISNULL(@CKEYFIELDVAL1,'') ,ISNULL(@CMEMONOVAL,''))        
          
    SELECT * FROM @OUTPUT         
  END         
          
       
            
          
 -- EXEC SP_DROPTEMPTABLES_XNS 'XNSRPS',@NSPID         
          
END           
------------------------------------------------------ END OF PROCEDURE SAVETRAN_QC
