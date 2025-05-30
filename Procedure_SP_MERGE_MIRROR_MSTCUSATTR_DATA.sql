create PROCEDURE SP_MERGE_MIRROR_MSTCUSATTR_DATA
(
  @NMODE INT,
  @XN_TYPE VARCHAR(50) ='MSTLOC'
)
--WITH ENCRYPTION
AS
BEGIN
        
	         
      DECLARE @CSTEP  VARCHAR(10),@CERRMSG VARCHAR(1000),@CTABLENAME VARCHAR(100),@CTMP_TABLENAME VARCHAR(100),
	          @CKEYFIELD VARCHAR(50),@CSOURCEDB VARCHAR(100),@CMERGEDB VARCHAR(100),@CFILTERCONDITION VARCHAR(100)

	   DECLARE @NCOUNT INT,@BLOOP INT,@CCMD1 NVARCHAR(MAX)
      
	  SET @CERRMSG=''
	  SET @CSOURCEDB=''
	  SET @CMERGEDB=''


	 SET @CSTEP=10
	  IF ISNULL(@NMODE,0) = 1
         GOTO EXIT_PROC


    BEGIN TRY
	BEGIN TRANSACTION
	
	SET @CSTEP=20	
	      
		 
		SET @NCOUNT=25
		SET @BLOOP=1
		WHILE (@BLOOP <=@NCOUNT )
		BEGIN
	      


				SET @CTABLENAME='CUST_ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST'
				SET @CTMP_TABLENAME='MSTCUSATTR_CUST_ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST_MIRROR'
				SET @CKEYFIELD='CUST_ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_KEY_CODE'
					
			   SET @CSTEP=30	

				EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB        
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''        
				 ,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0        
				 ,@BALWAYSUPDATE=1,@CFILTERCONDITION=''
			
	       
			   SET @BLOOP=@BLOOP +1  			
		END
   
		SET @CSTEP=40	
		
		SET @CTABLENAME='CONFIG_CUST_ATTR'
		SET @CTMP_TABLENAME='MSTCUSATTR'+@CTABLENAME+'_MIRROR'
		SET @CKEYFIELD='table_name'
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB        
			 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''        
			 ,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0        
			 ,@BALWAYSUPDATE=1,@CFILTERCONDITION=''        
        
		
		
							  						  
	END TRY
	BEGIN CATCH
		SET @CERRMSG='P:SP_MERGE_MIRROR_MSTCUSATTR_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	END CATCH

	EXIT_PROC:
	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0
	BEGIN
		COMMIT
	END
	ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0
		ROLLBACK   

    IF ISNULL(@CERRMSG,'')='' 
	BEGIN   
	    
	PRINT 'CHAEK'
	TRUNCATE TABLE MSTCUSATTR_CONFIG_CUST_ATTR_MIRROR
	TRUNCATE TABLE MSTCUSATTR_customer_fix_attr_MIRROR
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR1_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR2_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR3_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR4_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR5_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR6_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR7_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR8_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR9_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR10_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR11_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR12_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR13_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR14_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR15_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR16_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR17_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR18_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR19_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR20_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR21_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR22_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR23_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR24_MST_mirror 
	TRUNCATE TABLE MSTCUSATTR_CUST_ATTR25_MST_mirror 
		
	   
	END


END
--- 'END OF PROCEDURE SP_MERGE_MIRROR_MSTCUS_DATA'
