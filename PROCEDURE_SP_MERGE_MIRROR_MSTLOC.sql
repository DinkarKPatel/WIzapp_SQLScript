create PROCEDURE DBO.SP_MERGE_MIRROR_MSTLOC
 (@NMODE INT,
  @XN_TYPE VARCHAR(50) ='MSTLOC'
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
	          @bPRINTCONFIG BIT,@BMAINTAINSERIESSETUPATHO BIT , @BwIZclip BIT 
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
             
	  SELECT @CCURDEPTID = VALUE FROM CONFIG (NOLOCK) WHERE  CONFIG_OPTION='LOCATION_ID'  
	  SELECT @CHODEPTID = VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'  
	  SELECT @bPRINTCONFIG= ISNULL(ENABLEGSTREPORTCONFIG,0) FROM LOCATION WHERE DEPT_ID=@CCURDEPTID
	  
	  IF @CCURDEPTID=@CHODEPTID
	  BEGIN
			SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTLOC, CANNOT CALL MERGING PROC AT HEAD OFFICE'
			GOTO END_PROC
  	  END					

	  SET @CSTEP = 05    
	    
	  SELECT @NLOCTYPE=LOC_TYPE,@BPURLOC=PUR_LOC FROM LOCATION WHERE DEPT_ID=@CCURDEPTID  
	       
          
	  SET @CSTEP = 10   

	  --DELETE ALREADY EXISTING RECORDS FOR [MASTER TABLE
	  DELETE FROM BIN_LOC
	  
       
      IF @bPRINTCONFIG<>1
      BEGIN
		 DELETE FROM GST_TNC
		 DELETE FROM GST_QUOTATION_MST
		 DELETE FROM GST_XN_FORMAT
		 DELETE FROM GST_XN_DETAIL		
		 DELETE FROM GST_COMPANY_CONFIG
		 DELETE FROM GST_SLS_CUSTOMER_CONFIG
	  END	 
	   
	  DELETE FROM CONFIG_ATTR
	  DELETE FROM config_buyerorder
	 DELETE FROM FRANCHISE_LOC_LEDGER_SETUP
	   
	  DELETE FROM LUCKY_DRAW_SETUP
	  DELETE FROM LUCKY_DRAW_LOC

	  DELETE FROM ALTERATIONSETUP
	  
	  DELETE a FROM prefix a JOIN MSTLOC_PREFIX_MIRROR B ON a.prefix_code=b.prefix_code
	  DELETE a FROM prefix a JOIN MSTLOC_PREFIX_MIRROR B ON a.prefix_name=b.prefix_name
	  

	  DELETE  FROM LM_BANK_DETAIL
	  DELETE from POSCATEGORYSTKRESTRICTIONS
	  DELETE FROM MSTPOSCATEGORY
	  DELETE FROM TILL_DENO_MST
	  
	  
	  DELETE FROM  LOC_BILLING_RULES
	  DELETE FROM  LOC_BILLING_RULES_ALLLOC 
	  DELETE FROM  LOC_BILLING_RULES_FORM
	  DELETE FROM  LOC_BILLING_RULES_SERIES
	  DELETE FROM  shipping_mode
	  
	  
	  UPDATE A SET DEFAULT1=B.DEFAULT1,PRINTER_NAME=B.PRINTER_NAME 
	  FROM  MSTLOC_GST_REPORT_CONFIG_MIRROR  A WITH (ROWLOCK) 
	  JOIN GST_REPORT_CONFIG  B (NOLOCK) ON A.XN_TYPE=B.XN_TYPE 
	  AND A.REPORT_NAME=B.REPORT_NAME AND  A.FILE_NAME=B.FILE_NAME 
		
	--as per alok ji GST_REPORT_CONFIG can not be Remove
	 -- DELETE FROM GST_REPORT_CONFIG WHERE ISNULL(OPEN_FORMAT,0)<>1
	  
	  SET @CSTEP = 20
	  
	   UPDATE MSTLOC_LM01106_MIRROR WITH (ROWLOCK)  SET COMPANY_CODE='01'

	 
	  UPDATE MSTLOC_LMP01106_MIRROR WITH (ROWLOCK)  SET COMPANY_CODE='01'
	  
	  
			SET @CSTEP = 35
			SET @DTSQL=N'UPDATE A SET PRIMARY_EMAIL_PORT=B.PRIMARY_EMAIL_PORT,
						 PRIMARY_EMAIL=B.PRIMARY_EMAIL,
						 PRIMARY_EMAIL_SMTP=B.PRIMARY_EMAIL_SMTP,
						 PRIMARY_EMAIL_PWD=B.PRIMARY_EMAIL_PWD,
						 PRIMARY_EMAIL_SSL=B.PRIMARY_EMAIL_SSL
						 FROM MSTLOC_LOCATION_MIRROR A  WITH (ROWLOCK) JOIN LOCATION B (NOLOCK) ON A.DEPT_ID=B.DEPT_ID
						 WHERE B.DEPT_ID='''+@CCURDEPTID+''' AND ISNULL(A.PRIMARY_EMAIL,'''')='''''
		    PRINT(@DTSQL)	 
			EXEC SP_EXECUTESQL @DTSQL
			
			
			
			SET @CSTEP = 40
			SET @DTSQL=N'SELECT TOP 1 @BMAINTAINSERIESSETUPATHO=ISNULL(MAINTAIN_SERIES_SETUP_AT_HO,0) FROM MSTLOC_LOCATION_MIRROR
						 WHERE DEPT_ID='''+@CCURDEPTID+''''
			EXEC SP_EXECUTESQL @DTSQL,N'@BMAINTAINSERIESSETUPATHO BIT OUTPUT',@BMAINTAINSERIESSETUPATHO OUTPUT
						
			IF ISNULL(@BMAINTAINSERIESSETUPATHO,0)=1
			BEGIN
				SET @CSTEP = 45
				DELETE FROM SERIES_SETUP_MANUAL_DET
				DELETE FROM SERIES_SETUP_MST
			END
			
			
	--  END
	

	   SET @CKEYFIELD2 =''
	   SET @CKEYFIELD3 =''
	   
	   --INSERT DATA INTO CITY TABLE
	   SET @CSTEP = 50
	   SET @CTABLENAME = 'REGIONM'
	   SET @CSOURCETABLE ='MSTLOC_REGIONM_MIRROR'
	   SET @CKEYFIELD1='REGION_CODE'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	    --INSERT DATA INTO CITY TABLE
	   SET @CSTEP = 60
	   SET @CTABLENAME = 'STATE'
	   SET @CSOURCETABLE ='MSTLOC_STATE_MIRROR'
	   SET @CKEYFIELD1='STATE_CODE'
	   EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	   --INSERT DATA INTO CITY TABLE
	   SET @CSTEP = 70
	   SET @CTABLENAME = 'CITY'
	   SET @CSOURCETABLE ='MSTLOC_CITY_MIRROR'
	   SET @CKEYFIELD1='CITY_CODE'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
			   
	    --INSERT DATA INTO AREA TABLE
	   SET @CSTEP = 80
	   SET @CTABLENAME = 'AREA'
	   SET @CSOURCETABLE ='MSTLOC_AREA_MIRROR'
	   SET @CKEYFIELD1='AREA_CODE'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
						
	   
	   

	   --DUE TO MUTI LEVEL HEAD HEAD FIRST INSERT ONLY AFTER INSERT ONLY AGAIN HEAD UPDATE
	     SET @CSTEP = 110
	   SET @CTABLENAME = 'HD01106'
	   SET @CSOURCETABLE ='MSTLOC_HD01106_MIRROR'
	   SET @CKEYFIELD1='HEAD_CODE'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   

	    SET @CSTEP = 110
	   SET @CTABLENAME = 'HD01106'
	   SET @CSOURCETABLE ='MSTLOC_HD01106_MIRROR'
	   SET @CKEYFIELD1='HEAD_CODE'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=1,@BALWAYSUPDATE=1
	   

	   --INSERT DATA INTO LM01106 TABLE
	   SET @CSTEP = 90
	   SET @CTABLENAME = 'LM01106'
	   SET @CSOURCETABLE ='MSTLOC_LM01106_MIRROR'
	   SET @CKEYFIELD1='AC_CODE'
	   
	   
		Update a set MAJOR_AC_CODE =a.AC_CODE  
		FROM MSTLOC_LM01106_MIRROR A
		LEFT JOIN LM01106 B ON A.MAJOR_AC_CODE  =B.AC_CODE
		WHERE B.AC_CODE IS NULL
		and A.AC_CODE <>a.MAJOR_AC_CODE

		SET @CSTEP = 95  

		EXEC SP3S_INACTIVE_MASTERS @CTEMPTABLE=@CSOURCETABLE,@CTABLENAME=@CTABLENAME,@CCOLNAME='AC_NAME',@CCOLKEYNAME=@CKEYFIELD1
      

	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
		
		
						   
	   --INSERT DATA INTO LMP01106 TABLE
	   SET @CSTEP = 101
	   SET @CTABLENAME = 'LMP01106'
	   SET @CSOURCETABLE ='MSTLOC_LMP01106_MIRROR'
	   
	   SET @CKEYFIELD1='AC_CODE'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
								   
	    --INSERT DATA INTO HD01106 TABLE
	 

	   UPDATE MSTLOC_LOCATION_MIRROR SET REPORT_BLOCKED =0
	    --INSERT DATA INTO LOCATION TABLE
	   SET @CSTEP = 120
	   SET @CTABLENAME = 'LOCATION'
	   SET @CSOURCETABLE ='MSTLOC_LOCATION_MIRROR'
	   SET @CKEYFIELD1 ='DEPT_ID'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
			  
	   SET @CSTEP = 125
	   UPDATE a SET bin_name=a.bin_name+'_'+a.bin_id FROM MSTLOC_BIN_MIRROR a
	   JOIN bin b ON a.bin_name=b.bin_name
	   WHERE a.bin_id<>b.bin_id

	   --INSERT DATA INTO BIN TABLE
	   SET @CSTEP = 130
	   SET @CTABLENAME = 'BIN'
	   SET @CSOURCETABLE ='MSTLOC_BIN_MIRROR'
	   SET @CKEYFIELD1='BIN_ID'
	   
	   SET @CSTEP = 133
	    EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=1,
								   @CFILTERCONDITION='B.BIN_ID=B.MAJOR_BIN_ID',@LUPDATEONLY=0,@BALWAYSUPDATE=0
	   
	   
	   SET @CSTEP = 135
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
						   
	   --INSERT DATA INTO BIN_LOC TABLE
	   SET @CSTEP = 140
	   SET @CTABLENAME = 'BIN_LOC'
	   SET @CSOURCETABLE ='MSTLOC_BIN_LOC_MIRROR'
	   SET @CKEYFIELD1='BIN_ID'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
								   
	   
			
	

	   --INSERT DATA INTO CONFIG TABLE
	   SET @CSTEP = 150
	   SET @CTABLENAME = 'CONFIG'
	   SET @CSOURCETABLE ='MSTLOC_CONFIG_MIRROR'
	   SET @CKEYFIELD1='CONFIG_OPTION'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

								   
	   
     IF @bPRINTCONFIG<>1 --RESTRICTED TNC
     BEGIN
		   SET @CSTEP = 160
		   SET @CTABLENAME = 'GST_TNC'
		   SET @CSOURCETABLE ='MSTLOC_GST_TNC_MIRROR'
		   SET @CKEYFIELD1 ='XN_TYPE'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
		   SET @CSTEP = 170
		   SET @CTABLENAME = 'GST_QUOTATION_MST'
		   SET @CSOURCETABLE ='MSTLOC_GST_QUOTATION_MST_MIRROR'
		   SET @CKEYFIELD1 ='XN_TYPE'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
									   
									   
		   SET @CSTEP = 180
		   SET @CTABLENAME = 'GST_XN_FORMAT'
		   SET @CSOURCETABLE ='MSTLOC_GST_XN_FORMAT_MIRROR'
		   SET @CKEYFIELD1 ='XN_TYPE'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1	
									   
									   

		   SET @CSTEP = 200
		   SET @CTABLENAME = 'GST_XN_FORMAT'
		   SET @CSOURCETABLE ='MSTLOC_GST_XN_FORMAT_MIRROR'
		   
		   SET @DTSQL=N'INSERT INTO GST_XN_FORMAT (XN_TYPE) SELECT XN_TYPE FROM MSTLOC_GST_XN_FORMAT_MIRROR'

		   
		   SET @CSTEP = 210
		   SET @CTABLENAME = 'GST_XN_DETAIL'
		   SET @CSOURCETABLE ='MSTLOC_GST_XN_DETAIL_MIRROR'
		   SET @CKEYFIELD1 ='XN_TYPE'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
										@CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
										@CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
										@CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1    

		   SET @CSTEP = 215
		   SET @CTABLENAME = 'GST_COMPANY_CONFIG'
		   SET @CSOURCETABLE ='MSTLOC_GST_COMPANY_CONFIG_MIRROR'
		   SET @CKEYFIELD1 ='XN_TYPE'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1    
									   
	   
		   SET @CSTEP = 220
		   SET @CTABLENAME = 'GST_SLS_CUSTOMER_CONFIG'
		   SET @CSOURCETABLE ='MSTLOC_GST_SLS_CUSTOMER_CONFIG_MIRROR'
		   SET @CKEYFIELD1 ='XN_TYPE'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1 
								   
	   END

	   SET @CSTEP = 230
	   SET @CTABLENAME = 'GST_REPORT_CONFIG'
	   SET @CSOURCETABLE ='MSTLOC_GST_REPORT_CONFIG_MIRROR'
	   SET @CKEYFIELD1 ='XN_TYPE'
	   SET @CKEYFIELD2='ROW_ID'
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1


	   SET @CSTEP = 240
	   SET @CTABLENAME = 'FRANCHISE_LOC_LEDGER_SETUP'
	   SET @CSOURCETABLE ='MSTLOC_FRANCHISE_LOC_LEDGER_SETUP_MIRROR'
	   SET @CKEYFIELD1 ='XN_TYPE'
	   SET @CKEYFIELD2=''
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1									   							   

		   
     	   
	   
	   
	    SET @CSTEP = 355
	   SET @CTABLENAME = 'LUCKY_DRAW_LOC'
	   SET @CSOURCETABLE ='MSTLOC_LUCKY_DRAW_LOC_MIRROR'
	   SET @CKEYFIELD1 ='DEPT_ID'
	   SET @CKEYFIELD2=''
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1  
	   
	    SET @CSTEP = 360
	   SET @CTABLENAME = 'LUCKY_DRAW_SETUP'
	   SET @CSOURCETABLE ='MSTLOC_LUCKY_DRAW_SETUP_MIRROR'
	   SET @CKEYFIELD1 ='MODE'
	   SET @CKEYFIELD2=''
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	   
	   SET @CSTEP = 365
	   SET @CTABLENAME = 'CONFIG_ATTR'
	   SET @CSOURCETABLE ='MSTLOC_CONFIG_ATTR_MIRROR'
	   SET @CKEYFIELD1 ='table_name'
	   SET @CKEYFIELD2=''
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1       
	   							   

	   SET @CSTEP = 368
	   SET @CTABLENAME = 'CONFIG_BUYERORDER'
	   SET @CSOURCETABLE ='MSTLOC_CONFIG_BUYERORDER_MIRROR'
	   SET @CKEYFIELD1 ='column_name'
	   SET @CKEYFIELD2=''
	   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1       
	  
	   IF ISNULL(@BMAINTAINSERIESSETUPATHO,0)=1
	   BEGIN
		   SET @CSTEP = 372
		   SET @CTABLENAME = 'SERIES_SETUP_MST'
		   SET @CSOURCETABLE ='MSTLOC_SERIES_SETUP_MST_MIRROR'
		   SET @CKEYFIELD1 ='MEMO_ID'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=1,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1     

		   SET @CSTEP = 380
		   SET @CTABLENAME = 'SERIES_SETUP_MANUAL_DET'
		   SET @CSOURCETABLE ='MSTLOC_SERIES_SETUP_MANUAL_DET_MIRROR'
		   SET @CKEYFIELD1 ='MEMO_ID'
		   SET @CKEYFIELD2=''
		   EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
									   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
									   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=1,
									   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1  
		
	   END 	
	   
	   
	   Update a set USER_CODE ='0000000'
	    from MSTLOC_MEASUREMENT_MST_MIRROR A (nolock)
	   left join users b (nolock) on a.USER_CODE =b.user_code 
	   where b.user_code is null

	  SET @CSTEP = 381
	  SET @CTABLENAME = 'MEASUREMENT_MST'
	  SET @CSOURCETABLE ='MSTLOC_MEASUREMENT_MST_MIRROR'
	  SET @CKEYFIELD1 ='M_CODE'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1


   --FOR ALTERATIONSETUP
      SET @CSTEP = 385
	  SET @CTABLENAME = 'JOBS'
	  SET @CSOURCETABLE ='MSTLOC_JOBS_MIRROR'
	  SET @CKEYFIELD1 ='JOB_CODE'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	 
	 SET @CSTEP = 390
	  SET @CTABLENAME = 'SECTIONM'
	  SET @CSOURCETABLE ='MSTLOC_SECTIONM_MIRROR'
	  SET @CKEYFIELD1 ='SECTION_CODE'

	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1



	  SET @CSTEP = 395
	  SET @CTABLENAME = 'SECTIOND'
	  SET @CSOURCETABLE ='MSTLOC_SECTIOND_MIRROR'
	  SET @CKEYFIELD1 ='SUB_SECTION_CODE'


	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

								   
	  

	  SET @CSTEP = 400
	  SET @CTABLENAME = 'ALTERATIONSETUP'
	  SET @CSOURCETABLE ='MSTLOC_ALTERATIONSETUP_MIRROR'
	  SET @CKEYFIELD1 ='SUB_SECTION_CODE'
	  SET @CKEYFIELD2 ='JOB_CODE'
	  SET @CKEYFIELD3 ='DEPT_ID'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2=@CKEYFIELD2,@CKEYFIELD3=@CKEYFIELD3,@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
 	  SET @CSTEP = 405
	  SET @CTABLENAME = 'PREFIX'
	  SET @CSOURCETABLE ='MSTLOC_PREFIX_MIRROR'
	  SET @CKEYFIELD1 ='prefix_code'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	 


	 SET @CSTEP = 420
	  SET @CTABLENAME = 'LM_BANK_DETAIL'
	  SET @CSOURCETABLE ='MSTLOC_LM_BANK_DETAIL_MIRROR'
	  SET @CKEYFIELD1 ='AC_CODE'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

      SET @CSTEP = 450
	  SET @CTABLENAME = 'UOM'
	  SET @CSOURCETABLE ='MSTLOC_UOM_MIRROR'
	  SET @CKEYFIELD1 ='UOM_CODE'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1


      SET @CSTEP = 460
	  SET @CTABLENAME = 'MSTPOSCATEGORY'
	  SET @CSOURCETABLE ='MSTLOC_MSTPOSCATEGORY_MIRROR'
	  SET @CKEYFIELD1 ='CategoryCode'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1


	  SET @CSTEP = 470
	  SET @CTABLENAME = 'POSCATEGORYSTKRESTRICTIONS'
	  SET @CSOURCETABLE ='MSTLOC_POSCATEGORYSTKRESTRICTIONS_MIRROR'
	  SET @CKEYFIELD1 ='CategoryCode'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	  SET @CSTEP = 470
	  SET @CTABLENAME = 'TILL_DENO_MST'
	  SET @CSOURCETABLE ='MSTLOC_TILL_DENO_MST_MIRROR'
	  SET @CKEYFIELD1 ='deno_id'
	  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
								   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
								   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=1,
								   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1


	   
	   --INSERT AND UPDATE DATA INTO LICENSE_INFO_HO TABLE
	   SET @CSTEP = 40
	   SET @CTABLENAME = 'LOC_BILLING_RULES'
	   SET @CSOURCETABLE ='MSTLOC_LOC_BILLING_RULES_MIRROR'
	   SET @CKEYFIELD1 ='ROW_ID'
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
	   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	   
	    --INSERT AND UPDATE DATA INTO LOC_BILLING_RULES_ALLLOC TABLE
	   SET @CSTEP = 45
	   SET @CTABLENAME = 'LOC_BILLING_RULES_ALLLOC'
	   SET @CSOURCETABLE ='MSTLOC_LOC_BILLING_RULES_ALLLOC_MIRROR'
	   SET @CKEYFIELD1 ='ROW_ID'
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
	   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	   
	    --INSERT AND UPDATE DATA INTO LICENSE_INFO_HO TABLE
	   SET @CSTEP = 50
	   SET @CTABLENAME = 'LOC_BILLING_RULES_FORM'
	   SET @CSOURCETABLE ='MSTLOC_LOC_BILLING_RULES_FORM_MIRROR'
	   SET @CKEYFIELD1 ='REF_ROW_ID'
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
	   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1
	   
	   --INSERT AND UPDATE DATA INTO LICENSE_INFO_HO TABLE
	   SET @CSTEP = 60
	   SET @CTABLENAME = 'LOC_BILLING_RULES_SERIES'
	   SET @CSOURCETABLE ='MSTLOC_LOC_BILLING_RULES_SERIES_MIRROR'
	   SET @CKEYFIELD1 ='REF_ROW_ID'
	   EXEC UPDATEMASTERXN
	   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
	   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
	   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
	   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1

	  
	 
	   SET @CSTEP = 65
	   SET @CTABLENAME = 'IMAGE_INFO_CONFIG'
	   SET @CSOURCETABLE ='MSTLOC_IMAGE_INFO_CONFIG_MIRROR'
	        
		
		   IF EXISTS (SELECT TOP 1 'U'  FROM MSTLOC_IMAGE_INFO_CONFIG_MIRROR A (NOLOCK)
		   LEFT JOIN  IMAGE_INFO_CONFIG B (NOLOCK) ON 1=1
		   WHERE (A.SECTION<>ISNULL(B.SECTION,0) OR A.SUB_SECTION<>ISNULL(B.SUB_SECTION,0) OR A.ARTICLE<>ISNULL(B.ARTICLE,0)
		          OR A.PARA1<>ISNULL(B.PARA1,0) OR A.PARA2<>ISNULL(B.PARA2,0) OR A.PARA3<>ISNULL(B.PARA3,0) 
				  OR A.PARA4<>ISNULL(B.PARA4,0) OR A.PARA5<>ISNULL(B.PARA5,0) OR A.PARA6<>ISNULL(B.PARA6,0) 
				  OR A.PRODUCT<>ISNULL(B.PRODUCT,0)) 
				  )
	       BEGIN

			   SET @CKEYFIELD1 ='PRODUCT'
			   EXEC UPDATEMASTERXN
			   @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
			   @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
			   @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=0,
			   @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1,@cKeyFieldJoin=' on 1=1'
			 

		   END
		   
		  SET @CSTEP = 500
		  SET @CTABLENAME = 'SHIPPING_MODE'
		  SET @CSOURCETABLE ='MSTLOC_SHIPPING_MODE_MIRROR'
		  SET @CKEYFIELD1 ='SHIPPING_CODE'
		  EXEC UPDATEMASTERXN_MIRROR  @CSOURCEDB=@CSOURCEDB, @CSOURCETABLE=@CSOURCETABLE,
		  @CDESTDB='',@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD1,
		  @CKEYFIELD2='',@CKEYFIELD3='',@LINSERTONLY=1,
		  @CFILTERCONDITION='',@LUPDATEONLY=0,@BALWAYSUPDATE=1




		   UPDATE location with (rowlock) set hsn_last_updated_on=GETDATE() WHERE dept_id=@CCURDEPTID
		   

	-- END OF ALTERATIONSETUP
    GOTO END_PROC
END TRY

BEGIN CATCH
	SET @CERRORMSG='P:SP_MERGE_MIRROR_MSTLOC, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
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
	
   
    SELECT @BwIZclip=WIZCLIP FROM location WHERE DEPT_ID=@CCURDEPTID 
    IF ISNULL(@BwIZclip,'')<>1
	   UPDATE CONFIG SET value=0 WHERE config_option ='ENABLE_CAMPAIGN_SYSTEM'
	ELSE
	   UPDATE CONFIG SET value=1 WHERE config_option ='ENABLE_CAMPAIGN_SYSTEM' 
	   
	   
		--DROP TEMP TABLE 
		DELETE FROM MSTLOC_location_MIRROR
	    DELETE FROM MSTLOC_CONFIG_MIRROR
	    DELETE FROM MSTLOC_CONFIG_ATTR_MIRROR
	    DELETE FROM MSTLOC_LM01106_MIRROR
	    DELETE FROM MSTLOC_LMP01106_MIRROR
	    DELETE FROM MSTLOC_HD01106_MIRROR
	    DELETE FROM MSTLOC_AREA_MIRROR
	    DELETE FROM MSTLOC_CITY_MIRROR
	    DELETE FROM MSTLOC_STATE_MIRROR
	    DELETE FROM MSTLOC_REGIONM_MIRROR
	    DELETE FROM MSTLOC_BIN_MIRROR
	    DELETE FROM MSTLOC_BIN_LOC_MIRROR
	    DELETE FROM MSTLOC_GST_TNC_MIRROR
	    DELETE FROM MSTLOC_GST_REPORT_CONFIG_MIRROR
	    DELETE FROM MSTLOC_GST_COMPANY_CONFIG_MIRROR
	    DELETE FROM MSTLOC_GST_XN_FORMAT_MIRROR
	    DELETE FROM MSTLOC_GST_XN_DETAIL_MIRROR
	    DELETE FROM MSTLOC_GST_QUOTATION_MST_MIRROR
	    DELETE FROM MSTLOC_GST_SLS_CUSTOMER_CONFIG_MIRROR
	    DELETE FROM MSTLOC_LUCKY_DRAW_LOC_MIRROR
	    DELETE FROM MSTLOC_LUCKY_DRAW_SETUP_MIRROR
	    DELETE FROM MSTLOC_SERIES_SETUP_MST_MIRROR
	    DELETE FROM MSTLOC_SERIES_SETUP_MANUAL_DET_MIRROR
	    DELETE FROM MSTLOC_FRANCHISE_LOC_LEDGER_SETUP_MIRROR
		DELETE FROM MSTLOC_MEASUREMENT_MST_MIRROR
		DELETE FROM MSTLOC_SECTIONM_MIRROR
		DELETE FROM MSTLOC_JOBS_MIRROR
		DELETE FROM MSTLOC_SECTIOND_MIRROR
		DELETE FROM MSTLOC_ALTERATIONSETUP_MIRROR
		DELETE FROM mstloc_prefix_mirror
		DELETE from MSTLOC_LM_BANK_DETAIL_MIRROR
		DELETE from MSTLOC_UOM_MIRROR
		DELETE FROM MSTLOC_CONFIG_BUYERORDER_MIRROR
		DELETE FROM MSTLOC_MSTPOSCATEGORY_MIRROR
		DELETE from MSTLOC_POSCATEGORYSTKRESTRICTIONS_MIRROR
		DELETE FROM MSTLOC_TILL_DENO_MST_MIRROR

		DELETE  FROM MSTLOC_LOC_BILLING_RULES_MIRROR
		DELETE  FROM MSTLOC_LOC_BILLING_RULES_ALLLOC_MIRROR
		DELETE  FROM MSTLOC_LOC_BILLING_RULES_FORM_MIRROR
		DELETE  FROM MSTLOC_LOC_BILLING_RULES_SERIES_MIRROR
		DELETE  FROM MSTLOC_IMAGE_INFO_CONFIG_MIRROR
		DELETE  FROM MSTLOC_SHIPPING_MODE_MIRROR
		
		
				
	SELECT @XN_TYPE AS MEMO_ID,@CERRORMSG AS ERRMSG   	  
END

--END PROCEDURE SP_MERGE_MIRROR_MSTLOC