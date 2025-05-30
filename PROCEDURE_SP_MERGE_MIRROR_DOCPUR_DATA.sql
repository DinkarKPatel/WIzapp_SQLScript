create PROCEDURE SP_MERGE_MIRROR_DOCPUR_DATA
(
	@CMEMOID VARCHAR(50)
   ,@CLOCID VARCHAR(4)
   ,@CSOURCEDB VARCHAR(200)
   ,@CMERGEDB VARCHAR(200)
   ,@BMSTINSERTONLY BIT
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS


SET NOCOUNT ON
BEGIN
	/*
		SP_MERGE_MIRROR_POADJ_DATA_208_2014_02_04 : 
		THIS PROCEDURE WILL MERGE DATA FROM TEMPORARY TABLE TO ACTUAL TABLE.
		TABLE NAMES AND ITS MERGING ORDER WILL BE FIXED AND WILL BE DEFINED HERE.	
	*/
DECLARE @CSTEP VARCHAR(100),@DTSQL NVARCHAR(MAX),@NMERGE_ORDER NUMERIC(5)
	   ,@CTABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(50),@CKEYFIELD VARCHAR(200),@CDEL_ID VARCHAR(50),@CTMP_TABLENAME VARCHAR(200),@LINSERTONLY VARCHAR(1)
	   ,@CFILTERCONDITION VARCHAR(200),@LUPDATEONLY VARCHAR(1),@BALWAYSUPDATE VARCHAR(1),@FDEL CHAR(1)
	   ,@CERRMSGOUT VARCHAR(1000),@CTABLESSTR VARCHAR(MAX),@CMRRIDSEARCH VARCHAR(100),@CERRORUPDPMT VARCHAR(MAX)
BEGIN TRY
SET @CSTEP=20
	SET @CTABLE_SUFFIX='upload'
	
	SET @CSOURCEDB=''
	BEGIN TRANSACTION 

	DECLARE @cSENDPURINFOLOCMRRDT BIT,@BSENDPURINFOLOC BIT
	SET @CSTEP=30
	
	SELECT TOP 1 @CMRRIDSEARCH=MRR_ID FROM PIM01106 (NOLOCK) WHERE MRR_ID=@CMEMOID
	
	SELECT TOP 1 @cSENDPURINFOLOCMRRDT = value FROM DOCPUR_config_UPLOAD where config_option='SEND_ALL_PURCHASE_TO_TARGET' 
	
	---  Start of Maintainance steps for incoming data
	IF isnull(@cSENDPURINFOLOCMRRDT,'')='1'
	BEGIN
	    SET @CSTEP=40
		UPDATE docpur_pim01106_upload WITH(ROWLOCK)  SET MRR_DT=DBO.FN_GETFINYEARDATE(FIN_YEAR,1),
		RECEIPT_DT=DBO.FN_GETFINYEARDATE(FIN_YEAR,1)
	END


	IF OBJECT_ID ('TEMPDB..#TMPSTOCK','U') IS NOT NULL
	   DROP TABLE #TMPSTOCK

	SELECT DEPT_ID,BIN_ID,PRODUCT_CODE,QUANTITY_IN_STOCK 
	INTO #TMPSTOCK
	FROM PMT01106 WHERE 1=2

	IF EXISTS (SELECT TOP 1 'U' FROM PIM01106 WHERE MRR_ID=@CMEMOID )
	BEGIN
	    INSERT INTO #TMPSTOCK(DEPT_ID,BIN_ID,PRODUCT_CODE,QUANTITY_IN_STOCK )
		SELECT B.DEPT_ID,B.BIN_ID,A.PRODUCT_CODE,-1*A.QUANTITY QUANTITY_IN_STOCK 
		FROM PID01106 A (NOLOCK)
		JOIN PIM01106 B (NOLOCK) ON A.MRR_ID=B.MRR_ID 
		WHERE A.MRR_ID=@CMEMOID

	END 

	---  End of Maintainance steps for incoming data
			
    SET @CSTEP=210
	SET @CTABLENAME='LM01106'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='AC_CODE'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
    SET @CSTEP=220
	SET @CTABLENAME='LMP01106'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='AC_CODE'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=230
	SET @CTABLENAME='SECTIONM'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='SECTION_CODE'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
	SET @CSTEP=240
	SET @CTABLENAME='SECTIOND'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='SUB_SECTION_CODE'
	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=250
	SET @CTABLENAME='PARA1'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA1_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=260
	SET @CTABLENAME='PARA2'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA2_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	SET @CSTEP=270
	SET @CTABLENAME='PARA3'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA3_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
							  						
	SET @CSTEP=280
	SET @CTABLENAME='PARA4'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA4_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
	SET @CSTEP=290
	SET @CTABLENAME='PARA5'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA5_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
							  
	SET @CSTEP=300
	SET @CTABLENAME='PARA6'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PARA6_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
							  
     --Start Hsn 
	SET @CSTEP=302
	SET @CTABLENAME='HSN_MST'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='HSN_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 

      
	SET @CSTEP=304
	SET @CTABLENAME='HSN_DET'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='HSN_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='WEF',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 

	 --END Hsn 

	SET @CSTEP=305
	SET @CTABLENAME='UOM'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='UOM_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
	SET @CSTEP=310
	SET @CTABLENAME='ARTICLE'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='ARTICLE_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
         
	SET @CSTEP=312
	SET @CTABLENAME='SKU'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PRODUCT_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	

	SET @CSTEP=315
	SET @CTABLENAME='SKU_OH'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='PRODUCT_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
	--add all attributes 
	
	SET @CSTEP=320
	SET @CTABLENAME='SD_ATTR_AVATAR'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='SUB_SECTION_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
							  
	
	
	 
	 
	   DECLARE @NCOUNT INT,@BLOOP INT,@CCMD1 NVARCHAR(MAX)
		SET @NCOUNT=25
		SET @BLOOP=1
		WHILE (@BLOOP <=@NCOUNT )
		BEGIN
	      
			   DECLARE @CATTR_KEY_NAME VARCHAR(100)
				SET @CTABLENAME='ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST'

			   SET @CSTEP=325	
			 
				SET @CTMP_TABLENAME='DOCPUR_ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST_UPLOAD'
				SET @CKEYFIELD='ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_KEY_CODE'
				SET @CATTR_KEY_NAME ='ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_KEY_NAME'
					
	

			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
			
	       
			   SET @BLOOP=@BLOOP +1  			
		END
		
		SET @CSTEP=330
		SET @CTABLENAME='ARTICLE_FIX_ATTR'
		SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
		SET @CKEYFIELD='ARTICLE_CODE'
		EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
								  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
								  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
								  ,@BALWAYSUPDATE=1 	
								  
   
   
   --new user master insert only donot Update super in user & edit user code 
   
    UPDATE DOCPUR_USERS_UPLOAD SET MAJOR_USER_CODE='0000000' WHERE USER_CODE <>MAJOR_USER_CODE 
    
    UPDATE A SET ROLE_ID='0000000' FROM DOCPUR_USERS_UPLOAD A (NOLOCK)
    LEFT JOIN USER_ROLE_MST B ON A.ROLE_ID =B.ROLE_ID 
    WHERE B.ROLE_ID IS NULL
    
	
	SET @CSTEP=340
	SET @CTABLENAME='Users'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='USER_CODE'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 						  
							  
	--end of Article  attributes 						  
							  

	SET @CSTEP=350
	SET @CTABLENAME='PIM01106'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='MRR_ID'
	
	
	
	SET @DTSQL=N'UPDATE  '+@CSOURCEDB+'['+@CTMP_TABLENAME+'] WITH (ROWLOCK) set  ho_synch_last_update=last_update'
	PRINT @DTSQL
	EXEC SP_EXECUTESQL @DTSQL

	SET @CSTEP=360	
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	
	SET @CSTEP=370
	SET @CTABLENAME='PID01106'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='row_id'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
							  
	SET @CSTEP=375
	
	SET @CTABLENAME='PURCHASEORDERPROCESSINGNEW'
	SET @CTMP_TABLENAME='DOCPUR_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))
	SET @CKEYFIELD='ROWID'
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''
							  ,@LINSERTONLY=0,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 	
	
	
	SET @CSTEP=380
	
	
	SET @CTABLENAME='IMAGE_INFO_DOC'
	SET @CTMP_TABLENAME='DOCPUR_IMAGE_INFO_DOC_UPLOAD'
	SET @CKEYFIELD='MEMO_ID'
	SET @CMERGEDB=DB_NAME()+'_IMAGE.DBO.'

	SET @CSTEP=230
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB
							  ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2= 'IMG_ID',@CKEYFIELD3=''
							  ,@LINSERTONLY=1,@CFILTERCONDITION='',@LUPDATEONLY=0
							  ,@BALWAYSUPDATE=1 
	
	
							  
	SET @CSTEP=390
	
	
	
	    INSERT INTO #TMPSTOCK(DEPT_ID,BIN_ID,PRODUCT_CODE,QUANTITY_IN_STOCK )
		SELECT B.DEPT_ID,B.BIN_ID,A.PRODUCT_CODE,A.QUANTITY QUANTITY_IN_STOCK 
		FROM PID01106 A (NOLOCK)
		JOIN PIM01106 B (NOLOCK) ON A.MRR_ID=B.MRR_ID 
		WHERE A.MRR_ID=@CMEMOID AND CANCELLED=0

		
	 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
	 SELECT  DISTINCT 	 A. BIN_ID,A. DEPT_ID, '' AS DEPT_ID_NOT_STUFFED,GETDATE() last_update,
	 a.product_code,0 AS quantity_in_stock,'' rep_id, 0 STOCK_RECO_QUANTITY_IN_STOCK 
	 FROM #TMPSTOCK A
	 LEFT JOIN PMT01106 B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
	 WHERE B.BIN_ID IS NULL

	 UPDATE A SET QUANTITY_IN_STOCK=A.QUANTITY_IN_STOCK+ISNULL(B.QUANTITY_IN_STOCK,0) 
	 FROM PMT01106 A
	 JOIN
	 (
	  SELECT DEPT_ID,PRODUCT_CODE,BIN_ID,SUM(QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK
	  FROM #TMPSTOCK
	  GROUP BY DEPT_ID,PRODUCT_CODE,BIN_ID
	 ) B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID =B.BIN_ID 



	
	
	SET @CSTEP=400
	
END TRY
BEGIN CATCH
	SET @CERRMSG='P:SP_MERGE_MIRROR_DOCPUR_OPT_DATA, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
END CATCH

EXIT_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRMSG,'')=''
			COMMIT
		ELSE 
			ROLLBACK
	END

	truncate table DOCPUR_PIM01106_UPLOAD 
	truncate table DOCPUR_PID01106_UPLOAD 
	truncate table DOCPUR_LM01106_UPLOAD 
	truncate table DOCPUR_LMP01106_UPLOAD
	truncate table DOCPUR_SECTIONM_UPLOAD
	truncate table DOCPUR_SECTIOND_UPLOAD
	truncate table DOCPUR_ARTICLE_UPLOAD
	truncate table DOCPUR_PARA1_UPLOAD
	truncate table DOCPUR_PARA2_UPLOAD
	truncate table DOCPUR_PARA3_UPLOAD
	truncate table DOCPUR_PARA4_UPLOAD
	truncate table DOCPUR_PARA5_UPLOAD
	truncate table DOCPUR_PARA6_UPLOAD
	truncate table DOCPUR_sku_UPLOAD
	truncate table DOCPUR_sku_oh_UPLOAD
	truncate table DOCPUR_config_UPLOAD
	truncate table DOCPUR_UOM_UPLOAD 

	truncate table DOCPUR_hsn_det_UPLOAD
	truncate table DOCPUR_hsn_mst_UPLOAD 
	truncate table DOCPUR_PURCHASEORDERPROCESSINGNEW_UPLOAD
	truncate table DOCPUR_IMAGE_INFO_DOC_UPLOAD
	
	
    truncate table DOCPUR_ARTICLE_FIX_ATTR_Upload
	truncate table DOCPUR_SD_ATTR_AVATAR_Upload
	truncate table DOCPUR_ATTR1_MST_Upload
	truncate table DOCPUR_ATTR2_MST_Upload
	truncate table DOCPUR_ATTR3_MST_Upload
	truncate table DOCPUR_ATTR4_MST_Upload
	truncate table DOCPUR_ATTR5_MST_Upload
	truncate table DOCPUR_ATTR6_MST_Upload
	truncate table DOCPUR_ATTR7_MST_Upload
	truncate table DOCPUR_ATTR8_MST_Upload
	truncate table DOCPUR_ATTR9_MST_Upload
	truncate table DOCPUR_ATTR10_MST_Upload
	truncate table DOCPUR_ATTR11_MST_Upload
	truncate table DOCPUR_ATTR12_MST_Upload
	truncate table DOCPUR_ATTR13_MST_Upload
	truncate table DOCPUR_ATTR14_MST_Upload
	truncate table DOCPUR_ATTR15_MST_Upload
	truncate table DOCPUR_ATTR16_MST_Upload
	truncate table DOCPUR_ATTR17_MST_Upload
	truncate table DOCPUR_ATTR18_MST_Upload
	truncate table DOCPUR_ATTR19_MST_Upload
	truncate table DOCPUR_ATTR20_MST_Upload
	truncate table DOCPUR_ATTR21_MST_Upload
	truncate table DOCPUR_ATTR22_MST_Upload
	truncate table DOCPUR_ATTR23_MST_Upload
	truncate table DOCPUR_ATTR24_MST_Upload
	truncate table DOCPUR_ATTR25_MST_Upload
	truncate table DOCPUR_users_Upload

END	
---END OF PROCEDURE - SP_MERGE_MIRROR_DOCPUR_DATA

 
