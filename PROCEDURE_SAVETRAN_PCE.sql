create PROCEDURE SAVETRAN_PCE  --(LocId 3 digit change by Sanjay:06-11-2024)
(  
	 @NUPDATEMODE  NUMERIC(1,0),  
	 @NSPID    INT,  
	 @CMEMONOPREFIX  VARCHAR(50),  
	 @CFINYEAR   VARCHAR(10),  
	 @CMACHINENAME  VARCHAR(100)='',  
	 @CWINDOWUSERNAME VARCHAR(100)='',  
	 @CWIZAPPUSERCODE VARCHAR(10)='0000000',  
	 @CMEMOID   VARCHAR(40)='' ,
	 @BCALLEDFROMSAVETRAN_LIFT BIT=0
	 --ADDED STARTS 03-APR-2018	 
	 ,@DMEMODTPARA DATETIME =''
	 --ADDED ENDS 03-APR-2018	 
)  
AS  
BEGIN  
 DECLARE @CTEMPDBNAME   VARCHAR(100),  
   @CMASTERTABLENAME  VARCHAR(100),  
   @CDETAILTABLENAME  VARCHAR(100),  
   @CTEMPMASTERTABLENAME VARCHAR(100),  
   @CTEMPDETAILTABLENAME VARCHAR(100),  
   @CTEMPMASTERTABLE  VARCHAR(100),  
   @CTEMPDETAILTABLE  VARCHAR(100),  
   @CERRORMSG    VARCHAR(500),  
   @CKEYFIELD1    VARCHAR(50),  
   @CKEYFIELDVAL1   VARCHAR(50),  
   @CMEMONO    VARCHAR(20),  
   @NMEMONOLEN    NUMERIC(20,0),  
   @CMEMONOVAL    VARCHAR(50),  
   @CCMD     NVARCHAR(4000),  
   @CCMDOUTPUT    NVARCHAR(4000),  
   @NSAVETRANLOOP   BIT,  
   @NSTEP    INT,  
   @CLOCATIONID   VARCHAR(4),  
   @CHODEPTID    VARCHAR(4),  
   @CMEMODEPTID   VARCHAR(4),
   @CPETYENABLE	  BIT,
   @CDEPTID		  VARCHAR(4),
   @CPETTYTYPE    VARCHAR(4)  ,
    @CALLCASHREC VARCHAR(10)
  
  DECLARE @NTOTALPETTYDISC NUMERIC(14,2),
  @NPETTYDISC NUMERIC(14,2),@NMAXPETDISC NUMERIC(14,2),@NMONTHBUZ INT,@CAC_CODE VARCHAR(10),@BNEGSTOCKFOUND BIT
  
  DECLARE @TERROR TABLE (TYPE VARCHAR(10),MESSAGE VARCHAR(1000),MEMO_ID VARCHAR(40)) 
        
  DECLARE @TOPENING_BALANCE TABLE(AMOUNT NUMERIC(18,2))
  DECLARE @NMONTH NUMERIC(2),@BMONTHLY_BUDGET_ENABLED BIT,@BENABLED_HEAD_LEVEL BIT,@DTSQL NVARCHAR(MAX)
		 ,@CFIN_YEAR VARCHAR(5),@DMEMO_DT DATETIME,@CBUDGET_COL VARCHAR(10),@CAC_NAME VARCHAR(300),@NBUDGET NUMERIC(18,2)
		 ,@NEXPENSE NUMERIC(18,2),@DTLOCOPENDT DATETIME,@DTMEMODT DATETIME
  
 SET @NSTEP = 0  -- SETTTING UP ENVIRONMENT  
  
  
 
 -- TEMPORARY DATABASE Discarded now onwards as per Meeting on 30-10-2020 mentioned in Client issues List
 SET @CTEMPDBNAME = ''  
  
 SET @CMASTERTABLENAME = 'PEM01106'  
 SET @CDETAILTABLENAME = 'PED01106'  
  
 SET @CTEMPMASTERTABLENAME = 'TEMP_PEM01106_'+LTRIM(RTRIM(STR(@NSPID)))  
 SET @CTEMPDETAILTABLENAME = 'TEMP_PED01106_'+LTRIM(RTRIM(STR(@NSPID)))  
   
 SET @CTEMPMASTERTABLE = @CTEMPDBNAME + @CTEMPMASTERTABLENAME  
 SET @CTEMPDETAILTABLE = @CTEMPDBNAME + @CTEMPDETAILTABLENAME  
   
 SET @CERRORMSG   = ''  
 SET @CKEYFIELD1   = 'PEM_MEMO_ID'  
  
 SET @CMEMONO   = 'PEM_MEMO_NO'  
 SET @NMEMONOLEN   = 10  
		
    IF @NUPDATEMODE IN (1,2)
	BEGIN
		SET @cCmd=N'SELECT TOP 1 @cLocationId=location_code FROM '+@CTEMPMASTERTABLE
		EXEC SP_EXECUTESQL @cCmd,N'@cLocationId varchar(4) output',@cLocationId OUTPUT
	END
	ELSE
	BEGIN
		SELECT TOP 1 @cLocationId=location_code FROM PEM01106 (NOLOCK) WHERE pem_memo_id=@CMEMOID
	END

 	IF ISNULL(@CLOCATIONID,'')=''
	 BEGIN
		SET @CERRORMSG =' LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	 END
 
 SELECT @CPETYENABLE = ISNULL(ALLOW_MONTHLY_BUDGET_PC,0) FROM LOCATION WHERE DEPT_ID = @CLOCATIONID
	SELECT @CHODEPTID		= [VALUE] FROM CONFIG WHERE  CONFIG_OPTION='HO_LOCATION_ID'		

	SELECT @CALLCASHREC		= [VALUE] FROM CONFIG WHERE  CONFIG_OPTION='CONSIDER_ALL_CASH_RECEIPTS'	
   
 BEGIN TRY  
  IF @BCALLEDFROMSAVETRAN_LIFT=0
  BEGIN
	BEGIN TRANSACTION   
  END
    
    --ADDED STARTS 03-APR-2018	 
    IF @NUPDATEMODE = 5	
	   GOTO MEMODATE_UPDATE	 
    --ADDED ENDS 03-APR-2018	 
    
	IF @NUPDATEMODE<>3
	BEGIN
		EXEC SP_VALIDATEXN_BEFORESAVE 'PTC',@NSPID,'0000000',@NUPDATEMODE,@CCMDOUTPUT OUTPUT,@BNEGSTOCKFOUND OUTPUT
		IF ISNULL(@CCMDOUTPUT,'') <> ''
		BEGIN
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' DATA VALIDATION ON TEMP DATA FAILED : ' + @CCMDOUTPUT + '...'
			GOTO END_PROC
		END
	END

   IF @NUPDATEMODE = 3			
		BEGIN
			SET @NSTEP = 10
			
			IF @CMEMOID=''
			BEGIN
				SET @CERRORMSG='MEMO ID REQUIRED FOR CANCELLATION........CANNOT PROCEED'
				GOTO END_PROC
			END
			
			SET @NSTEP = 13
			-- UPDATING SENTTOHO FLAG
			SET @CCMD = N' UPDATE ' + @CMASTERTABLENAME + ' SET CANCELLED = 1,SENT_TO_HO=0,LAST_UPDATE=GETDATE(),POSTEDINAC=0 ' + 
						N' WHERE ' + @CKEYFIELD1 + ' = ''' + @CMEMOID + ''''
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CKEYFIELDVAL1=@CMEMOID
			
			GOTO END_PROC
	END 
    
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
	  
	   SET @NSTEP = 30    
	  
	   SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))  
	   
	   IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
	   BEGIN  
		  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
		  GOTO END_PROC  
	   END  
	  
	   SET @NSTEP = 40  -- UPDATING NEW ID INTO TEMP TABLES  
	  
	   SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' + @CMEMONO+'=''' + @CMEMONOVAL+''',' +   
		  @CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''''  
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD  
	    
	   SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE+ ' SET '+@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+''''  
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD  
	   
	   
	   SET @CCMD = 'UPDATE ' + @CTEMPDETAILTABLE+ ' SET ROW_ID = NEWID()'  
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD
	   
  END     -- END OF ADDMODE  
  ELSE    -- CALLED FROM EDITMODE  
  BEGIN    -- START OF EDITMODE  
    
	   SET @NSTEP = 50  -- GETTING ID INFO FROM TEMP TABLE  
	   -- GETTING JOB ORDER ID WHICH IS BEING EDITED  
	   SET @CCMD = 'SELECT @CKEYFIELDVAL1 = ' + @CKEYFIELD1 + ', @CMEMONOVAL = ' + @CMEMONO + ' FROM '  
		  +@CMASTERTABLENAME + ' WHERE PEM_MEMO_ID= '''+@CMEMOID+''''   
	     
	   EXEC SP_EXECUTESQL @CCMD, N'@CKEYFIELDVAL1 VARCHAR(50) OUTPUT, @CMEMONOVAL VARCHAR(50) OUTPUT',   
			  @CKEYFIELDVAL1 OUTPUT, @CMEMONOVAL OUTPUT  
	   IF (@CKEYFIELDVAL1 IS NULL) OR (@CMEMONOVAL IS NULL )  
	   BEGIN  
		  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR ACCESSING THE RECORD TO BE MODIFIED...'  
		  GOTO END_PROC      
	   END  
	     
	   SET @NSTEP = 55  -- STORING OLD STATUS OF BARCODES   

	   SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET LAST_UPDATE=GETDATE()'  
	   PRINT @CCMD  
	   EXEC SP_EXECUTESQL @CCMD    
		-- ENTRY IN AUDIT TRAIL (ONLY WHEN USER EXPLICITLY CLICKED ON EDIT BUTTON)  
		SET @NSTEP = 70  -- AUDIT TRIAL ENTRY  
	  
		--EXEC AUDITLOGENTRY  
		--   @CXNTYPE  = 'PCE'  
		-- , @CXNID  = @CKEYFIELDVAL1  
		-- , @CDEPTID  = @CMEMODEPTID  
		-- , @CCOMPUTERNAME= @CMACHINENAME  
		-- , @CWINUSERNAME = @CWINDOWUSERNAME  
		-- , @CWIZUSERCODE = @CWIZAPPUSERCODE  
  
  END     -- END OF EDITMODE  
  
  SET @NSTEP = 95  
    
  -- RECHECKING IF ID IS STILL LATER  
  IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
  BEGIN  
   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
   GOTO END_PROC  
  END
  
  -- UPDATING MASTER TABLE (PIM01106) FROM TEMP TABLE  
  SET @NSTEP = 100  -- UPDATING MASTER TABLE  
    
  BEGIN  
   
   EXEC UPDATEMASTERXN   
      @CSOURCEDB = @CTEMPDBNAME  
    , @CSOURCETABLE = @CTEMPMASTERTABLENAME  
    , @CDESTDB  = ''  
    , @CDESTTABLE = @CMASTERTABLENAME  
    , @CKEYFIELD1 = @CKEYFIELD1  
    , @BALWAYSUPDATE = 1
    -- , @LUPDATEXNS = 1  
  
   -- UPDATING TRANSACTION TABLE (PID01106) FROM TEMP TABLE  
   SET @NSTEP = 110  -- UPDATING TRANSACTION TABLE  
  
   -- UPDATING ROW_ID IN TEMP TABLES - PAYMODE_XN_DET  
   SET @CCMD = N'UPDATE ' + @CTEMPDETAILTABLE + ' SET ROW_ID = ''' + @CLOCATIONID + ''' + CONVERT(VARCHAR(40), NEWID())  
        WHERE LEFT(ROW_ID,5) = ''LATER'''  
   EXEC SP_EXECUTESQL @CCMD  
  
   SET @NSTEP = 115  
  
   SET @CCMD = N'DELETE FROM ' + @CDETAILTABLENAME + '   
      WHERE ' + @CKEYFIELD1 + ' = ''' + @CKEYFIELDVAL1 + ''''  
   EXEC SP_EXECUTESQL @CCMD  
  
   -- INSERTING/UPDATING THE ENTRIES IN PRD_JID TABLE FROM TEMPTABLE  
   SET @NSTEP = 117  -- UPDATING TRANSACTION TABLE - INSERTING NEW ENTRIES  
   EXEC UPDATEMASTERXN   
      @CSOURCEDB = @CTEMPDBNAME  
    , @CSOURCETABLE = @CTEMPDETAILTABLENAME  
    , @CDESTDB  = ''  
    , @CDESTTABLE = @CDETAILTABLENAME  
    , @CKEYFIELD1 = 'ROW_ID'  
    , @BALWAYSUPDATE = 1
  
  END  
  
    SET @NSTEP = 120
	--VALIDATION FOR DAILY EXPENSE GREATER THAN THE OPENING BALANCE
	--GETTING MONTH FOR THE MEMO BEGIN SAVED...
	SELECT @NMONTH=MONTH(PEM_MEMO_DT),@DMEMO_DT=PEM_MEMO_DT,@CFIN_YEAR=FIN_YEAR
	FROM PEM01106 WHERE PEM_MEMO_ID = @CKEYFIELDVAL1
	
	SET @NSTEP = 130
	INSERT @TOPENING_BALANCE
	EXEC SP_CASHXN   @CLOCATIONID
					,''
					,@DMEMO_DT
					,1,0,1
					
	
	SET @NSTEP = 140
	IF EXISTS(SELECT TOP 1 'U' FROM @TOPENING_BALANCE WHERE ISNULL(AMOUNT,0)<0 AND ISNULL(@CALLCASHREC,'') <> '1')
	BEGIN
		SET @NSTEP = 150
		SET @CERRORMSG='EXPENSE IS EXCEEDING AVAILABLE CASH BALANCE BY '
				   +(SELECT TOP 1 LTRIM(RTRIM(STR(ISNULL(AMOUNT,0)))) FROM @TOPENING_BALANCE)+'..CANNOT SAVE'
		GOTO END_PROC
	END
	
	--VALIDATION FOR EXPENSES GREATER THAN DEFINED MONTHLY BUDGET
	--GETTING MONTHLY BUDGET DETAILS FOR THIS LOCATION
	SET @NSTEP = 160
	SELECT TOP 1 @BMONTHLY_BUDGET_ENABLED=ISNULL(ALLOW_MONTHLY_BUDGET_PC,0)
				,@BENABLED_HEAD_LEVEL=ISNULL(BUDGET_AT_EXPENSE_HEADS,0)
	FROM LOCATION WHERE DEPT_ID=@CLOCATIONID
	
	SET @NSTEP = 170
	IF @BMONTHLY_BUDGET_ENABLED=1
	BEGIN
			/*NOTE : MONTH1 COLUMN IN MONTHLYBUDGET AND MONTHLYBUDGET_HEAD IS EQUIVALENT TO APRIL(4)*/
					   
			SET @CBUDGET_COL=(CASE WHEN @NMONTH BETWEEN 4 AND 12 THEN 'MONTH'+LTRIM(RTRIM(STR(@NMONTH-3)))
								   WHEN @NMONTH=1 THEN 'MONTH10'
								   WHEN @NMONTH=2 THEN 'MONTH11'
								   WHEN @NMONTH=3 THEN 'MONTH12' END)
									
			--VALIDATION FOR EXPENSES GREATER THAN THE DEFINED BUDGET
			IF @BENABLED_HEAD_LEVEL=0 /*BUDGET IS DEFINED AT LOCATION LEVEL*/
			BEGIN
					--GETTING THE BUDGET FOR THIS MONTH
					SET @DTSQL=N'SELECT @NBUDGET='+@CBUDGET_COL+' FROM MONTHLYBUDGET_HEAD 
								 WHERE DEPT_ID='''+@CLOCATIONID+''' AND FIN_YEAR='''+@CFIN_YEAR+''''
					PRINT @DTSQL			 
					EXEC SP_EXECUTESQL @DTSQL,N'@NBUDGET NUMERIC(18,2) OUTPUT',@NBUDGET OUTPUT
					SET @NBUDGET=ISNULL(@NBUDGET,0) 
					
					SELECT @NEXPENSE=SUM(CASE WHEN A.XN_TYPE='DR' THEN A.XN_AMOUNT ELSE -A.XN_AMOUNT END)
					FROM PED01106 A  
					JOIN PEM01106 B ON A.PEM_MEMO_ID = B.PEM_MEMO_ID  
					WHERE B.FIN_YEAR=@CFIN_YEAR AND MONTH(B.PEM_MEMO_DT)=@NMONTH
					AND b.location_Code=@CLOCATIONID
					AND B.CANCELLED=0
					
					IF @NEXPENSE>@NBUDGET
					BEGIN
						SET @CERRORMSG='EXPENSE FOR THIS MONTH ('+LTRIM(RTRIM(STR(@NEXPENSE)))
								  +') IS GREATER THAN THE ASSIGNED BUDGET ('+LTRIM(RTRIM(STR(@NBUDGET)))+')
								  .CANNNOT SAVE.'
						GOTO END_PROC								  
					END
			END
			ELSE /*BUDGET IS DEFINED AT EXPENSE HEAD LEVEL*/
			BEGIN
					--GETTING THE BUDGET FOR THIS MONTH 
					DECLARE @TBUDGET_HEADS TABLE(AC_CODE CHAR(10),AMOUNT NUMERIC(18,2))
					DECLARE @TEXPENSE_HEADS TABLE(AC_CODE CHAR(10),AMOUNT NUMERIC(18,2))
					
					SET @DTSQL=N'SELECT AC_CODE,'+@CBUDGET_COL+' FROM MONTHLYBUDGET_HEAD 
								 WHERE DEPT_ID='''+@CLOCATIONID+''' AND FIN_YEAR='''+@CFIN_YEAR+''''
					PRINT @DTSQL
					INSERT @TBUDGET_HEADS(AC_CODE,AMOUNT)
					EXEC SP_EXECUTESQL @DTSQL
					
					INSERT @TEXPENSE_HEADS(AC_CODE,AMOUNT)
					SELECT AC_CODE,SUM(CASE WHEN A.XN_TYPE='DR' THEN A.XN_AMOUNT ELSE -A.XN_AMOUNT END)
					FROM PED01106 A  
					JOIN PEM01106 B ON A.PEM_MEMO_ID = B.PEM_MEMO_ID  
					WHERE B.FIN_YEAR=@CFIN_YEAR AND MONTH(B.PEM_MEMO_DT)=@NMONTH AND B.CANCELLED=0
					AND b.location_code=@CLOCATIONID
					GROUP BY AC_CODE
					
					IF EXISTS(SELECT TOP 1 'U' FROM @TEXPENSE_HEADS B
							  LEFT JOIN @TBUDGET_HEADS A  ON A.AC_CODE=B.AC_CODE WHERE B.AMOUNT>ISNULL(A.AMOUNT,0))
					BEGIN
						SELECT TOP 1 @NEXPENSE=B.AMOUNT,@NBUDGET=ISNULL(A.AMOUNT,0),@CAC_NAME=LM.AC_NAME
						FROM @TEXPENSE_HEADS B
					    LEFT JOIN @TBUDGET_HEADS A ON A.AC_CODE=B.AC_CODE 
					    JOIN LM01106 LM(NOLOCK) ON B.AC_CODE=LM.AC_CODE
					    WHERE B.AMOUNT>ISNULL(A.AMOUNT,0)
						
						SET @CERRORMSG='EXPENSE FOR ACCOUNT ('+@CAC_NAME+') THIS MONTH ('+LTRIM(RTRIM(STR(@NEXPENSE)))
								  +') IS GREATER THAN THE ASSIGNED BUDGET ('+LTRIM(RTRIM(STR(@NBUDGET)))+')
								  .CANNNOT SAVE.'
						GOTO END_PROC		  
					END
			END
	END
	
	----VALIDATE PEM01106 (PEM_MEMO_DT) MEMO DATE NOT BE GREATE HAN LOCATION OPENING DATE
	SELECT @DTLOCOPENDT=LAST_REQ_DATE FROM LOC_REQ WHERE DEPT_ID = @CLOCATIONID
	SELECT @DTMEMODT =PEM_MEMO_DT FROM PEM01106 WHERE PEM_MEMO_ID=@CKEYFIELDVAL1
	
	IF (@DTMEMODT<@DTLOCOPENDT)
	BEGIN
			SET @CERRORMSG = 'CAN NOT ACCEPT A MEMO DATE LESS THAN OPENING DATA. 
			                  MEMO DATE '+CONVERT (VARCHAR(10),@DTMEMODT,105)+' AND OPENING DATE '+CONVERT (VARCHAR(10),@DTLOCOPENDT,105)
            GOTO END_PROC			                 
	END
	
--ADDED STARTS 03-APR-2018	 
MEMODATE_UPDATE:
	IF @NUPDATEMODE = 5	
	BEGIN
	
		UPDATE PEM01106 SET PEM_MEMO_DT=@DMEMODTPARA WHERE PEM_MEMO_ID=@CMEMOID
	    SET @CKEYFIELDVAL1=@CMEMOID
		
		SET @CERRORMSG=''
	    EXEC VALIDATE_XN_DATA_FREEZE  'PCE',@CWIZAPPUSERCODE,@CMEMOID ,@DMEMODTPARA,@CERRORMSG OUTPUT
    
    	IF ISNULL(@CERRORMSG,'')<>''
			GOTO END_PROC
    END			
--ADDED ENDS 03-APR-2018
  
 END TRY  
 BEGIN CATCH  
    SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
 END CATCH 
   
END_PROC:  

IF ISNULL(@CERRORMSG,'') = ''
    --INSERT INTO @TERROR(TYPE,MESSAGE,MEMO_ID) SELECT 'SUCCESS',@CKEYFIELDVAL1,@CKEYFIELDVAL1
    --ADDED STARTS 03-APR-2018
	IF @NUPDATEMODE<>5
	   INSERT INTO @TERROR(TYPE,MESSAGE,MEMO_ID)
	   SELECT 'SUCCESS',@CKEYFIELDVAL1,@CKEYFIELDVAL1
	ELSE   
	   INSERT INTO @TERROR(TYPE,MESSAGE,MEMO_ID)
	   SELECT 'SUCCESS','',@CKEYFIELDVAL1
	--ADDED ENDS 03-APR-2018   
 ELSE 
	INSERT INTO @TERROR(TYPE,MESSAGE,MEMO_ID)
	SELECT 'ERROR',@CERRORMSG,@CKEYFIELDVAL1 
  
IF @@TRANCOUNT>0 AND @BCALLEDFROMSAVETRAN_LIFT=0 
 BEGIN  
  IF EXISTS(SELECT TOP 1 * FROM @TERROR WHERE TYPE = 'SUCCESS')
  BEGIN
    
     UPDATE pem01106 WITH (ROWLOCk) SET last_update=getdate() WHERE pem_memo_id=@CKEYFIELDVAL1
	 UPDATE pem01106 WITH (ROWLOCk) SET HO_SYNCH_LAST_UPDATE='' WHERE pem_memo_id=@CKEYFIELDVAL1 
	COMMIT TRANSACTION 
	EXEC SP_DROPTEMPTABLES_XNS 'XNSPTC',@NSPID
  END
  ELSE  
	ROLLBACK  
  END 


IF @BCALLEDFROMSAVETRAN_LIFT=0
BEGIN   
	SELECT * FROM @TERROR
END
ELSE 
BEGIN
	INSERT #PROCOUTPUT(MEMOID,ERRMSG)
	SELECT MEMO_ID,(CASE WHEN TYPE='ERROR' THEN MESSAGE ELSE '' END) AS ERRMSG
	FROM @TERROR
END	
END        
---------- END OF PROCEDURE SAVETRAN_PCE
