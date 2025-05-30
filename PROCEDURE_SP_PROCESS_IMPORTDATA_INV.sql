create PROCEDURE SP_PROCESS_IMPORTDATA_INV        --(LocId 3 digit change by Sanjay:06-11-2024)
@CMASTERTABLE VARCHAR(30),        
@CATTRTABLE VARCHAR(30),  
@BUPDATESTOCK      BIT =0,  
@CFINYEAR   VARCHAR(10),  
@CXN_DT   VARCHAR(50)='',  
@CSD_ATTRTABLE VARCHAR(30)='' ,
@cLocationID VARCHAR(5)='' 
--WITH ENCRYPTION
AS        
BEGIN   


--SELECT * INTO TMPMASTERSENC FROM #TMPMASTERSENC

--SELECT * INTO TMPMASTERSATTRENC FROM #TMPMASTERSATTRENC
     
BEGIN TRANSACTION  
         
 BEGIN TRY        
   
   DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000), MEMO_ID VARCHAR(100))        
   DECLARE @DLASTUPDATE DATETIME,@CIMAGECONFIG BIT 
   DECLARE @CCMD NVARCHAR(MAX),@NSTEP INT,@CERRORMSG VARCHAR(MAX),@XN_DT DATETIME,@CERRORMSG1 VARCHAR(MAX) ,@BOVERWRITE BIT
   
   SELECT TOP 1 @BOVERWRITE = ISNULL(VALUE,0) FROM CONFIG WHERE CONFIG_OPTION = 'OVERWRITE_MASTERS_IN_FILE_IMPORT' 
      
   DECLARE @TABLE TABLE(PRODUCT_CODE VARCHAR(50),HSN_CODE  VARCHAR(15))

   SET @BOVERWRITE=ISNULL(@BOVERWRITE,0) 
   
    SET @CIMAGECONFIG=''
    SELECT @CIMAGECONFIG=VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLE_REMOTE_IMAGE_SYNCH'
    
    
  
   --SET @CCMD=N'SELECT A.PRODUCT_CODE,A.HSN_CODE FROM '+@CMASTERTABLE +' A 
   --             LEFT JOIN HSN_MST B ON A.HSN_CODE=B.HSN_CODE
   --             WHERE B.HSN_CODE IS NULL'
   -- PRINT @CCMD
   -- INSERT INTO @TABLE (PRODUCT_CODE,HSN_CODE)
   -- EXEC SP_EXECUTESQL @CCMD
    
    
   -- IF EXISTS(SELECT TOP 1 * FROM @TABLE)
   -- BEGIN
   --  SET @CERRORMSG='HSN CODE SHOULD BE EXISTS IN HSN MASTER' 
   --  GOTO END_PROC  
   -- END
    

  IF OBJECT_ID('TEMPDB..#TMPMASTERSENC','U') IS NOT NULL   
  BEGIN  
	 CREATE INDEX IX_#TMPMASTERSENC_ARTICLE_NO ON #TMPMASTERSENC(ARTICLE_NO)  
	 CREATE INDEX IX_#TMPMASTERSENC_PARA1_NAME ON #TMPMASTERSENC(PARA1_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_PARA2_NAME ON #TMPMASTERSENC(PARA2_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_PARA3_NAME ON #TMPMASTERSENC(PARA3_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_PARA4_NAME ON #TMPMASTERSENC(PARA4_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_PARA5_NAME ON #TMPMASTERSENC(PARA5_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_PARA6_NAME ON #TMPMASTERSENC(PARA6_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_AC_NAME ON #TMPMASTERSENC(AC_NAME)  
	 CREATE INDEX IX_#TMPMASTERSENC_PRODUCT_CODE ON #TMPMASTERSENC(PRODUCT_CODE)  
  END  
       
      IF @BOVERWRITE=1
      BEGIN 
		SET @CCMD=N'UPDATE A SET SECTION_NAME=E.SECTION_NAME,SUB_SECTION_NAME=D.SUB_SECTION_NAME,
			ARTICLE_NO=C.ARTICLE_NO,PARA1_NAME=P1.PARA1_NAME,PARA2_NAME=P2.PARA2_NAME,PARA3_NAME=P3.PARA3_NAME,        
			PARA4_NAME=P4.PARA4_NAME,PARA5_NAME=P5.PARA5_NAME,PARA6_NAME=P6.PARA6_NAME,     
			PURCHASE_PRICE=B.PURCHASE_PRICE,MRP=B.MRP,WHOLESALE_PRICE=B.WS_PRICE,        
			CODING_SCHEME=B.BARCODE_CODING_SCHEME,PRODUCT_CODE=B.PRODUCT_CODE,UOM_NAME=U.UOM_NAME,        
			ARTICLE_NAME=C.ARTICLE_NAME,FORM_NAME=FRM.FORM_NAME,ARTICLE_ALIAS=C.ALIAS,
			BATCH_NO=b.BATCH_NO,
			EXPIRY_DT=b.EXPIRY_DT,
			PERISHABLE=c.PERISHABLE,
			VENDOR_EAN_NO=B.VENDOR_EAN_NO,
			PARA1_ALIAS=P1.ALIAS,PARA2_ALIAS=P2.ALIAS,PARA3_ALIAS=P3.ALIAS,        
			PARA4_ALIAS=P4.ALIAS,PARA5_ALIAS=P5.ALIAS,PARA6_ALIAS=P6.ALIAS
			FROM '+@CMASTERTABLE +' A
			JOIN SKU B ON B.PRODUCT_CODE=A.PRODUCT_CODE
			JOIN ARTICLE C ON C.ARTICLE_CODE=B.ARTICLE_CODE
			JOIN SECTIOND D ON D.SUB_SECTION_CODE  =C.SUB_SECTION_CODE
			JOIN SECTIONM E ON E.SECTION_CODE=D.SECTION_CODE
			JOIN PARA1 P1 ON P1.PARA1_CODE=B.PARA1_CODE
			JOIN PARA2 P2 ON P2.PARA2_CODE=B.PARA2_CODE
			JOIN PARA3 P3 ON P3.PARA3_CODE=B.PARA3_CODE
			JOIN PARA4 P4 ON P4.PARA4_CODE=B.PARA4_CODE
			JOIN PARA5 P5 ON P5.PARA5_CODE=B.PARA5_CODE
			JOIN PARA6 P6 ON P6.PARA6_CODE=B.PARA6_CODE
			JOIN UOM	U ON U.UOM_CODE=C.UOM_CODE
			JOIN FORM FRM ON FRM.FORM_ID=B.FORM_ID'

		PRINT @CCMD                              
		EXEC SP_EXECUTESQL @CCMD 
      END 
       
       
          
  SET @NSTEP=120        
        
  SET @CCMD=N'  INSERT #TMPMASTERSENC (SECTION_NAME,SUB_SECTION_NAME,ARTICLE_NO,PARA1_NAME,PARA2_NAME,PARA3_NAME,        
    PARA4_NAME,PARA5_NAME,PARA6_NAME,PURCHASE_PRICE,MRP,WS_PRICE,CODING_SCHEME,PRODUCT_CODE,UOM_NAME  
    ,AC_NAME,ROW_ID,STOCK_NA,FIX_MRP,PRODUCT_NAME,GEN_EAN_CODES,BIN_ID,ARTICLE_NAME,FORM_NAME,ARTICLE_ALIAS,
    SECTION_ALIAS,SUB_SECTION_ALIAS,HSN_CODE,PARA1_SET,PARA2_SET,P1_SET,P2_SET,BATCH_NO,EXPIRY_DT,PERISHABLE,VENDOR_EAN_NO,
	PARA1_ALIAS,PARA2_ALIAS,PARA3_ALIAS,PARA4_ALIAS,PARA5_ALIAS,PARA6_ALIAS,EAN_PREFIX,REPLACEABLE_COLOR,
	article_type,PUR_BILL_NO,PUR_BILL_DATE,SEASON_NAME,MRP_Restriction ,MRP_RESTRICTION_FROM ,MRP_RESTRICTION_TO ,article_desc )  
	
    SELECT  LTRIM(RTRIM(ISNULL(SECTION_NAME,''''))),LTRIM(RTRIM(ISNULL(SUB_SECTION_NAME,'''')))
    ,LTRIM(RTRIM(ISNULL(ARTICLE_NO,''''))),        
    LTRIM(RTRIM(ISNULL(PARA1_NAME,''NA''))),LTRIM(RTRIM(ISNULL(PARA2_NAME,''NA''))),LTRIM(RTRIM(ISNULL(PARA3_NAME,''NA''))),        
    LTRIM(RTRIM(ISNULL(PARA4_NAME,''NA''))),LTRIM(RTRIM(ISNULL(PARA5_NAME,''NA'')))
    ,LTRIM(RTRIM(ISNULL(PARA6_NAME,''NA''))),        
    ISNULL(PURCHASE_PRICE,0),ISNULL(MRP,0),ISNULL(WHOLESALE_PRICE,0) AS WS_PRICE,        
    ISNULL(CODING_SCHEME,0),LTRIM(RTRIM(ISNULL(PRODUCT_CODE,''''))),LTRIM(RTRIM(ISNULL(UOM_NAME,''''))),        
    LTRIM(RTRIM(ISNULL(AC_NAME,''''))),NEWID(),0,ISNULL(FIX_MRP,0),LTRIM(RTRIM(ISNULL(PRODUCT_NAME,''''))),ISNULL(GEN_EAN_CODES,0),  
    ISNULL(BIN_ID,''000'')  ,LTRIM(RTRIM(ISNULL(ARTICLE_NAME,''''))),
      LTRIM(RTRIM(ISNULL(FORM_NAME,'''')))
    ,LTRIM(RTRIM(ISNULL(ARTICLE_ALIAS,''''))),LTRIM(RTRIM(ISNULL(SECTION_ALIAS,''''))) , 
    LTRIM(RTRIM(ISNULL(SUB_SECTION_ALIAS,''''))), LTRIM(RTRIM(ISNULL(HSN_CODE,'''')))
     ,LTRIM(RTRIM(ISNULL(PARA1_SET,''''))) ,LTRIM(RTRIM(ISNULL(PARA2_SET,''''))) 
      ,LTRIM(RTRIM(ISNULL(P1_SET,''''))) ,LTRIM(RTRIM(ISNULL(P2_SET,''''))) 
    ,BATCH_NO,EXPIRY_DT,PERISHABLE,VENDOR_EAN_NO,
	PARA1_ALIAS,PARA2_ALIAS,PARA3_ALIAS,PARA4_ALIAS,PARA5_ALIAS,PARA6_ALIAS,EAN_PREFIX,REPLACEABLE_COLOR,article_type,
	PUR_BILL_NO,PUR_BILL_DATE,SEASON_NAME,MRP_Restriction ,MRP_RESTRICTION_FROM ,MRP_RESTRICTION_TO ,article_desc
        
    FROM '+@CMASTERTABLE                
  PRINT @CCMD                              
  EXEC SP_EXECUTESQL @CCMD

  


       
 SET @NSTEP=130        
 EXEC SP_GETMASTERS @CFINYEAR,2,@CERRORMSG1 OUTPUT ,'',2 ,@cLocationID 


    IF ISNULL(@CERRORMSG1,'')<>''  
    BEGIN  
	    
	  SET @CERRORMSG=@CERRORMSG1  
	  GOTO END_PROC  
  
    END

    EXEC SP3S_VALIDATE_PARAS @CERRORMSG=@CERRORMSG OUTPUT
	IF ISNULL(@CERRORMSG,'')<>''  
	GOTO END_PROC  
   
    IF ISNULL(@CIMAGECONFIG,0)=1
     EXEC SP_INSERT_IMAGE_INFO  @CMASTERTABLE  
 
 
    EXEC SP_GETMASTERS_ATTR_NEW @CFINYEAR,@CMASTERTABLE,@CERRORMSG1 OUTPUT ,@cLocationID 
  
 
 
    IF ISNULL(@CERRORMSG1,'')<>''  
    BEGIN  
  SET @CERRORMSG=@CERRORMSG1  
  GOTO END_PROC  
 END   
  
 IF @BUPDATESTOCK=1  
 BEGIN  
  PRINT 'UPDATING STOCK'  
  SET @NSTEP=139  
    
  DECLARE @CLOCID VARCHAR(10)  
    IF @cLocationID=''
        SELECT TOP 1 @CLOCID = VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'    
  ELSE
      SELECT  @CLOCID= @cLocationID
 
  DECLARE @Ccurdept_id VARCHAR(10)  ,@CHO_DEPT_ID VARCHAR(10) ,@ncntloc int
  
  
  SELECT top 1  @CHO_DEPT_ID=value  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'
  SELECT  top 1  @Ccurdept_id=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
  
  IF NOT EXISTS(SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=REPLACE(REPLACE(@CMASTERTABLE,'[',''),']','') AND COLUMN_NAME='DEPT_ID')
  BEGIN
	  SET @CCMD=N' ALTER TABLE '+@CMASTERTABLE +' ADD DEPT_ID VARCHAR(5)'
	  EXEC SP_EXECUTESQL @CCMD
  END
  
  SET @CCMD=N' UPDATE '+@CMASTERTABLE +' SET DEPT_ID='''+@Ccurdept_id+''' WHERE DEPT_ID IS NULL'
  EXEC sp_executesql @CCMD


  IF ISNULL(@CHO_DEPT_ID,'')=ISNULL(@CCURDEPT_ID,'')
  BEGIN
     
     IF OBJECT_ID('TEMPDB..#TMPDEPT_ID','U') IS NOT NULL
        DROP TABLE #TMPDEPT_ID
      SELECT DEPT_ID INTO #TMPDEPT_ID FROM location WHERE 1=2
     
     SET @CCMD=N' SELECT DISTINCT DEPT_ID FROM '+@CMASTERTABLE +' '
     INSERT INTO #TMPDEPT_ID
     EXEC sp_executesql @CCMD
     
     IF EXISTS(SELECT TOP 1 'U' FROM #TMPDEPT_ID WHERE DEPT_ID='')
     BEGIN
        SET @CERRORMSG='DEPT ID CAN NOT BE BLANK' 
        GOTO END_PROC  
     END
     
     
     SELECT @NCNTLOC=COUNT(*) FROM #TMPDEPT_ID
     
     IF @NCNTLOC<>1
      BEGIN
        SET @CERRORMSG='MULTIPLE LOCATION NOT ALLOWED' 
        GOTO END_PROC  
     END
 
     select @CLOCID=dept_id from #TMPDEPT_ID
  
  END

 
 
 
  SET @NSTEP=138   
  EXEC UPDATEPMT  
   @CXNTYPE='OPS',  
   @CXNNO='',  
   @CXNID=@CLOCID,  
   @NREVERTFLAG=1,  
   @NALLOWNEGSTOCK=0,  
   @NCHKDELBARCODES=0,  
   @NUPDATEMODE=1,  
   @CCMD=@CCMD OUTPUT  
    
  SET @NSTEP=140  
  DELETE FROM OPS01106 WHERE DEPT_ID=@CLOCID  
  
 
  
  SET @NSTEP=142  
  SET @CCMD=N'  SELECT    PRODUCT_CODE,'''' AS LOT_NO,'''+@CLOCID+''' AS DEPT_ID,
      CONVERT(NUMERIC(14,2),ISNULL(INVOICE_QUANTITY,0))+CONVERT(NUMERIC(14,2),ISNULL(SCHEME_QUANTITY,0)) AS [QUANTITY_OB], ''01'' AS COMPANY_CODE,GETDATE() AS LAST_UPDATE,   
      0 AS PURCHASE_PRICE, 0 AS RFINSERTED,xn_dt AS XN_DT,0 AS  SENT_TO_HO,0 AS XFER_PRICE,0 AS XFER_PRICE_WOTAX,''000''  FROM '+@CMASTERTABLE     
  INSERT OPS01106 ( PRODUCT_CODE, LOT_NO, DEPT_ID, QUANTITY_OB, COMPANY_CODE, LAST_UPDATE,   
      PURCHASE_PRICE, RFINSERTED, XN_DT, SENT_TO_HO, XFER_PRICE, XFER_PRICE_WOTAX,BIN_ID )                                 
  EXEC SP_EXECUTESQL @CCMD   
  
  --SELECT * FROM #TMPMASTERSENC WHERE PRODUCT_CODE IN (SELECT PRODUCT_CODE FROM OPS01106)  
    
  --SELECT * FROM OPS01106 WHERE PRODUCT_CODE NOT IN (SELECT PRODUCT_CODE FROM SKU)  
    
  INSERT PMT01106 ( LAST_UPDATE, REP_ID, PRODUCT_CODE, QUANTITY_IN_STOCK, DEPT_ID,BIN_ID )  
  SELECT    GETDATE() AS LAST_UPDATE,'' AS REP_ID,A.PRODUCT_CODE,A.QUANTITY_OB AS QUANTITY_IN_STOCK,@CLOCID AS DEPT_ID ,'000'  
  FROM OPS01106 A  
  LEFT OUTER JOIN PMT01106 B ON B.PRODUCT_CODE=A.PRODUCT_CODE  
  WHERE B.PRODUCT_CODE IS NULL and a.dept_id =@CLOCID 
  
  SET @NSTEP=145  
  EXEC UPDATEPMT  
   @CXNTYPE='OPS',  
   @CXNNO='',  
   @CXNID=@CLOCID,  
   @NREVERTFLAG=0,  
   @NALLOWNEGSTOCK=0,  
   @NCHKDELBARCODES=0,  
   @NUPDATEMODE=1,  
   @CCMD=@CERRORMSG1 OUTPUT  
  
 END          
  GOTO END_PROC        
 END TRY        
 BEGIN CATCH     
 IF(ISNULL(@CERRORMSG1,'')='')  
  SET @CERRORMSG =ISNULL(@CERRORMSG1   ,'@CERRORMSG1')+ 'PROCEDURE SP_PROCESS_IMPORTDATA_INV : STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()        
    ELSE  
  SET @CERRORMSG=@CERRORMSG1  
      
  GOTO END_PROC        
 END CATCH        
        
END_PROC: 
 
 IF @@trancount>0
 BEGIN
	 IF(ISNULL(@CERRORMSG   ,'')='')  
	 BEGIN
	   SET @DLASTUPDATE=GETDATE()
	   IF @BUPDATESTOCK=1
			UPDATE OPS01106 SET LAST_UPDATE=@DLASTUPDATE,HO_SYNCH_LAST_UPDATE='' WHERE DEPT_ID=@CLOCID
   
	   commit TRANSACTION  
   
	 END 
	 ELSE  
		ROLLBACK TRANSACTION  
 END
          
 INSERT @OUTPUT ( ERRMSG, MEMO_ID)        
   VALUES ( ISNULL(@CERRORMSG,''), 'IMPORT' )        
        
 SELECT * FROM @OUTPUT         
END

