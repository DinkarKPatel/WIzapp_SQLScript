CREATE PROCEDURE SP_MERGE_MIRROR_MSTEMP
  (@NMODE INT
  ,@XN_TYPE VARCHAR(50) ='MSTEMP'
  )
----WITH ENCRYPTION
AS
BEGIN
       DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
              ,@CTEMPLOCTABLE VARCHAR(100),@CSTATECODEOUT CHAR(7),@CSTATECODE VARCHAR(10)
              ,@CCURDEPTID VARCHAR(10),@CHODEPTID VARCHAR(10),@BHOLOC BIT,@NLOCTYPE VARCHAR(50)
              ,@BPURLOC VARCHAR(10),@CTABLENAME VARCHAR(100),@CTMP_TABLENAME VARCHAR(100)
              ,@CKEYFIELD1 VARCHAR(100),@CTEMPLOCSSTTABLE VARCHAR(500),@CTEMPTABLE VARCHAR(500)
              ,@CTEMPLOCSSTMSTTABLE VARCHAR(500),@BPROCEED BIT,@CKEYFIELD2 VARCHAR(500),@CKEYFIELD3 VARCHAR(500) 
	          ,@CSOURCETABLE VARCHAR(1000),@NXNSMERGINGORDER INT,@CSOURCEDB VARCHAR(200),@CERRORMSG VARCHAR(MAX)	
	         -- ,@XN_TYPE VARCHAR(50)
      DECLARE @TXNSMERGEINFO TABLE (ORG_TABLENAME VARCHAR(50),TMP_TABLENAME VARCHAR(50),XN_ID VARCHAR(40))
       
BEGIN TRY

	  SELECT @CSOURCEDB=''	
	  			
	  IF ISNULL(@NMODE,0) = 1
         GOTO END_PROC;			
	  					
	  BEGIN TRANSACTION
      
      SET @CSTEP = 00  
  
	  SELECT @CCURDEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'  
	  SELECT @CHODEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'  
	  
	  IF @CCURDEPTID=@CHODEPTID
	  BEGIN
			SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTEMP, CANNOT CALL MERGING PROC AT HEAD OFFICE'
			GOTO END_PROC
  	  END					

	  SET @CSTEP = 05    
	    
	  SELECT @NLOCTYPE=LOC_TYPE,@BPURLOC=PUR_LOC FROM LOCATION WHERE DEPT_ID=@CCURDEPTID  
	       
       --DELETE EXISTING TABLE 
        DELETE FROM  EMP_GRP_LINK	
        
       SET @CKEYFIELD2 =''
	   SET @CKEYFIELD3 =''
        
        
       SET @CSTEP = 10
	   SET @CTABLENAME ='EMPCATEGORY'
	   SET @CKEYFIELD1='CATEGORY_CODE'
	   SET @CSOURCETABLE='MSTEMP_EMPCATEGORY_MIRROR'
	   SET @CTEMPTABLE=@CSOURCEDB+@CSOURCETABLE
	   PRINT 'MERGE MASTER :'+@CTABLENAME+'  '+@CSOURCETABLE
	   
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB,
	   @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',
	   @CDESTTABLE=@CTABLENAME,
	   @CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2=@CKEYFIELD2,
	   @CKEYFIELD3=@CKEYFIELD3,
	   @LINSERTONLY=0,
	   @CFILTERCONDITION='',
	   @LUPDATEONLY=0,
	   @BALWAYSUPDATE=1 
	  
	   SET @CSTEP = 20   
	   SET @CTABLENAME ='EMPLOYEE_GRP'
	   SET @CKEYFIELD1='EMP_GRP_CODE'
	   SET @CSOURCETABLE='MSTEMP_EMPLOYEE_GRP_MIRROR'
	   SET @CTEMPTABLE=@CSOURCEDB+@CSOURCETABLE
	   PRINT 'MERGE MASTER :'+@CTABLENAME+'  '+@CSOURCETABLE
	   
	
	   
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB,
	   @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',
	   @CDESTTABLE=@CTABLENAME,
	   @CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2=@CKEYFIELD2,
	   @CKEYFIELD3=@CKEYFIELD3,
	   @LINSERTONLY=0,
	   @CFILTERCONDITION='',
	   @LUPDATEONLY=0,
	   @BALWAYSUPDATE=1
	   
	   
	  
	   
	    SET @CSTEP = 30  
	   SET @CTABLENAME ='EMPLOYEE'
	   SET @CKEYFIELD1='EMP_CODE'
	   SET @CSOURCETABLE='MSTEMP_EMPLOYEE_MIRROR'
	   SET @CTEMPTABLE=@CSOURCEDB+@CSOURCETABLE
	   PRINT 'MERGE MASTER :'+@CTABLENAME+'  '+@CSOURCETABLE
	   
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB,
	   @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',
	   @CDESTTABLE=@CTABLENAME,
	   @CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2=@CKEYFIELD2,
	   @CKEYFIELD3=@CKEYFIELD3,
	   @LINSERTONLY=0,
	   @CFILTERCONDITION='',
	   @LUPDATEONLY=0,
	   @BALWAYSUPDATE=1
	   
	   
	   
	   SET @CSTEP = 40   
	   SET @CTABLENAME ='EMP_GRP_LINK'
	   SET @CKEYFIELD1='EMP_GRP_CODE'
	   SET @CSOURCETABLE='MSTEMP_EMP_GRP_LINK_MIRROR'
	   SET @CTEMPTABLE=@CSOURCEDB+@CSOURCETABLE
	   PRINT 'MERGE MASTER :'+@CTABLENAME+'  '+@CSOURCETABLE
	   
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB,
	   @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',
	   @CDESTTABLE=@CTABLENAME,
	   @CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2=@CKEYFIELD2,
	   @CKEYFIELD3=@CKEYFIELD3,
	   @LINSERTONLY=0,
	   @CFILTERCONDITION='',
	   @LUPDATEONLY=0,
	   @BALWAYSUPDATE=1
	   

    
    GOTO END_PROC
END TRY

BEGIN CATCH
	SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTEMP, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
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
		
	   DELETE FROM MSTEMP_EMPCATEGORY_MIRROR
	   DELETE FROM MSTEMP_EMPLOYEE_GRP_MIRROR
	   DELETE FROM MSTEMP_EMPLOYEE_MIRROR
	   DELETE FROM MSTEMP_EMP_GRP_LINK_MIRROR
	   
	END
	SELECT 'MSTEMP' AS MEMO_ID,@CERRORMSG AS ERRMSG   	  
END
----- END OF PROCEDURE SP_MERGE_MIRROR_MSTEMP
