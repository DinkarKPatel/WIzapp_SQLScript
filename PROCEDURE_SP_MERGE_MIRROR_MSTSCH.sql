CREATE PROCEDURE DBO.SP_MERGE_MIRROR_MSTSCH
 (@NMODE INT,
  @XN_TYPE VARCHAR(50) ='MSTSCH'
 )
AS
 BEGIN 

       DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
              ,@CTEMPLOCTABLE VARCHAR(100),@CSTATECODEOUT CHAR(7),@CSTATECODE VARCHAR(10)
              ,@CCURDEPTID VARCHAR(10),@CHODEPTID VARCHAR(10),@BHOLOC BIT,@NLOCTYPE VARCHAR(50)
              ,@BPURLOC VARCHAR(10),@CTABLENAME VARCHAR(100),@CTMP_TABLENAME VARCHAR(100)
              ,@CKEYFIELD1 VARCHAR(100),@CTEMPLOCSSTTABLE VARCHAR(500),@CTEMPTABLE VARCHAR(500)
              ,@CTEMPLOCSSTMSTTABLE VARCHAR(500),@BPROCEED BIT,@CKEYFIELD2 VARCHAR(500),@CKEYFIELD3 VARCHAR(500) 
	          ,@CSOURCETABLE VARCHAR(1000),@NXNSMERGINGORDER INT,@CSOURCEDB VARCHAR(200),@CERRORMSG VARCHAR(MAX)	,
	          @CPRINTCONFIG INT,@BMAINTAINSERIESSETUPATHO BIT
BEGIN TRY
	  
	  SELECT @CSOURCEDB=DB_NAME()+'.DBO.',@CERRORMSG=''	
	  
	  --VALIDATE DATE 
	  IF ISNULL(@XN_TYPE,'')  = ''
	     BEGIN
	       SET @CERRORMSG ='XN_TYPE IS NOT NULL. PLEASE PASS XN TYPE INTO PARAMATER'
	       GOTO END_PROC;
	     END
			
	  IF ISNULL(@NMODE,0) = 1
         GOTO END_PROC;
     		
	  BEGIN TRANSACTION
      
      SET @CSTEP = 00  
               
	  SELECT @CCURDEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'  
	  SELECT @CHODEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'  
	  
	  IF @CCURDEPTID=@CHODEPTID
	  BEGIN
			SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTSCH, CANNOT CALL MERGING PROC AT HEAD OFFICE'
			GOTO END_PROC
  	  END					
	  SET @CSTEP = 10   

	  --DELETE ALREADY EXISTING RECORDS FOR [MASTER TABLE
	  DELETE FROM locslsset

	  DELETE FROM SLSART
	  DELETE FROM SLSBC
	  	  DELETE FROM SLSDET
	  	  DELETE FROM SLSMST

	  

	   SET @CKEYFIELD2 =''
	   SET @CKEYFIELD3 =''
	   
	   --INSERT DATA INTO CITY TABLE
	   SET @CSTEP = 50
	   SET @CTABLENAME = 'SLSMST'
	   SET @CSOURCETABLE ='MSTSCH_SLSMST_MIRROR'
	   SET @CKEYFIELD1='SLS_MEMO_NO'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	    --INSERT DATA INTO CITY TABLE
	   SET @CSTEP = 60

	    SET @CTABLENAME = 'LOCSLSSET'
	   SET @CSOURCETABLE ='MSTSCH_LOCSLSSET_MIRROR'
	   SET @CKEYFIELD1='SLS_MEMO_NO'
	   EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	   --INSERT DATA INTO CITY TABLE
	   SET @CSTEP = 70
	   SET @CTABLENAME = 'SLSDET'
	   SET @CSOURCETABLE ='MSTSCH_SLSDET_MIRROR'
	   SET @CKEYFIELD1='SLS_MEMO_NO'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
			   
	    --INSERT DATA INTO AREA TABLE
	   SET @CSTEP = 80
	   SET @CTABLENAME = 'SLSART'
	   SET @CSOURCETABLE ='MSTSCH_SLSART_MIRROR'
	   SET @CKEYFIELD1='SLS_MEMO_NO'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
						
	   
	   
	   --INSERT DATA INTO LM01106 TABLE
	   SET @CSTEP = 90
	   SET @CTABLENAME = 'SLSBC'
	   SET @CSOURCETABLE ='MSTSCH_SLSBC_MIRROR'
	   SET @CKEYFIELD1='SLS_MEMO_NO'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
						   
	 
	   
    GOTO END_PROC
END TRY

BEGIN CATCH
	SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTSCH, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' 
			COMMIT
		ELSE
			ROLLBACK	
	END
	
	IF ISNULL(@CERRORMSG,'')='' 
	BEGIN   
		--DROP TEMP TABLE 
		DELETE FROM MSTSCH_LOCSLSSET_MIRROR
	    DELETE FROM MSTSCH_SLSMST_MIRROR
	    DELETE FROM MSTSCH_SLSDET_MIRROR
	    DELETE FROM MSTSCH_SLSART_MIRROR
	    DELETE FROM MSTSCH_SLSBC_MIRROR

	   
	END
		
	SELECT @XN_TYPE AS MEMO_ID,@CERRORMSG AS ERRMSG   	  
END

--END PROCEDURE SP_MERGE_MIRROR_MSTSCH
