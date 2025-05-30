CREATE PROCEDURE DBO.SP_MERGE_MIRROR_MSTREGINFO
 ( @NMODE INT
  ,@XN_TYPE VARCHAR(50) ='MSTREGINFO'
  )
AS
 BEGIN
       DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
              ,@CTEMPLOCTABLE VARCHAR(100),@CSTATECODEOUT CHAR(7),@CSTATECODE VARCHAR(10)
              ,@CCURDEPTID VARCHAR(10),@CHODEPTID VARCHAR(10),@BHOLOC BIT,@NLOCTYPE VARCHAR(50)
              ,@BPURLOC VARCHAR(10),@CTABLENAME VARCHAR(100),@CTMP_TABLENAME VARCHAR(100)
              ,@CKEYFIELD1 VARCHAR(100),@CTEMPLOCSSTTABLE VARCHAR(500),@CTEMPTABLE VARCHAR(500)
              ,@CTEMPLOCSSTMSTTABLE VARCHAR(500),@BPROCEED BIT,@CKEYFIELD2 VARCHAR(500),@CKEYFIELD3 VARCHAR(500) 
	          ,@CSOURCETABLE VARCHAR(1000),@NXNSMERGINGORDER INT,@CSOURCEDB VARCHAR(200),@CERRORMSG VARCHAR(MAX)	
BEGIN TRY
	  SELECT @CSOURCEDB=''	
	  
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
			SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTREGINFO, CANNOT CALL MERGING PROC AT HEAD OFFICE'
			GOTO END_PROC
  	  END					

	  SET @CSTEP = 05    
	    
	  SELECT @NLOCTYPE=LOC_TYPE,@BPURLOC=PUR_LOC FROM LOCATION WHERE DEPT_ID=@CCURDEPTID  
	       
           
	  SET @CSTEP = 10   

	  --DELETE ALREADY EXISTING RECORDS FOR [MASTER TABLE
	   	 DELETE FROM REG_HAND_SHAKE
	 
	
	   SET @CKEYFIELD2 =''
	   SET @CKEYFIELD3 =''
	 --INSERT DATA INTO LOCATION TABLE
	 
	   --INSERT AND UPDATE DATA INTO LICENSE_INFO_HO TABLE
	   SET @CSTEP = 40
	   SET @CTABLENAME = 'LICENSE_INFO_HO'
	   SET @CSOURCETABLE ='MSTREGINFO_LICENSE_INFO_HO_MIRROR'
	   SET @CKEYFIELD1 ='REG_KEY'
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
	   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	   
	    --INSERT AND UPDATE DATA INTO LICENSE_INFO_HO TABLE
	   SET @CSTEP = 50
	   SET @CTABLENAME = 'REG_HAND_SHAKE'
	   SET @CSOURCETABLE ='MSTREGINFO_REG_HAND_SHAKE_MIRROR'
	   SET @CKEYFIELD1 ='VERSION_NAME'
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
	   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	   
	   		 
    
    GOTO END_PROC
END TRY

BEGIN CATCH
	SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTREGINFO, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
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
		--DROP TEMP TABLE RELATED TO LICENSE_INFO_HO
	   DELETE FROM MSTREGINFO_LICENSE_INFO_HO_MIRROR
	   DELETE FROM MSTREGINFO_REG_HAND_SHAKE_MIRROR
	   
	END
		
	SELECT @XN_TYPE AS MEMO_ID,@CERRORMSG AS ERRMSG   	  
END

--END PROCEDURE SP_MERGE_MIRROR_MSTREGINFO


