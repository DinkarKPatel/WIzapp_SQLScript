create PROCEDURE SAVETRAN_CUSTOMER  
 (    
  @nUpdatemode NUMERIC(1,0),  
  @nSpId   VARCHAR(40) ,
  @CLOCID varchar(4) -- Dept ID not removed due to api duplication
 
 )    
 AS    
 BEGIN    
 DECLARE @CNEWKEYVAL VARCHAR(100),@CLOCATIONID VARCHAR(5),@cErrormsg VARCHAR(MAX) ,@cStep varchar(4),  
   @CWHERECLAUSE VARCHAR(200),@lINSERTONLY BIT,@lUpdateONLY BIT,@cCustomerCode CHAR(12),  
   @bWizclipEnabled BIT,@cTreatMobileAsCustCode VARCHAR(2),@cMobile VARCHAR(50),@cUserCustCode VARCHAR(50),  
   @cCustName VARCHAR(500)  
   update  cus_custdym_upload set last_update=getdate() WHERE sp_id=@nSpId  
 BEGIN TRANSACTION     
BEGIN TRY    
    
    
    
  SET @cStep='5'  
  
  SELECT TOP 1 @cCustomerCode=customer_code,@cMobile=mobile,@cUserCustCode=user_customer_code,  
  @cCustName=customer_fname+customer_lname,@CLOCID=LOCATION_ID   FROM cus_custdym_upload (NOLOCK) WHERE sp_id=@nSpId  
  
  IF @cCustomerCode IS NULL  
  BEGIN  
  SET @cErrormsg='Blank data cannot be saved... Please check'  
  GOTO END_PROC  
  END    
  
  SET @cStep='8'  
  IF ISNULL(@cCustName,'')=''  
  BEGIN  
  SET @cErrormsg='Customer name cannot be blank... Please check'  
  GOTO END_PROC  
  END  
  
  SET @cStep='12'  
 
  SELECT @CLOCATIONID = @CLOCID    
    
  SELECT @bWizclipEnabled=isnull(wizclip,0) FROM location (NOLOCK) WHERE dept_id=@CLOCATIONID  
  
  CREATE TABLE #SLSIMPORT_CUSTDYM            
  (            
	 SR_NO    NUMERIC(18)         
	 ,USER_CUSTOMER_CODE  VARCHAR(MAX)         
	 ,customer_fname  VARCHAR(MAX)         
	 ,customer_lname  VARCHAR(MAX)         
	 ,address0   VARCHAR(MAX)         
	 ,address1   VARCHAR(MAX)         
	 ,address2   VARCHAR(MAX)         
	 ,address9   VARCHAR(MAX)      
	 ,area    VARCHAR(MAX)         
	 ,city    VARCHAR(MAX)         
	 ,state    VARCHAR(MAX)         
	 ,CUS_GST_NO  VARCHAR(MAX)         
	 ,CUSTOMER_CODE  VARCHAR(MAX)         
	 ,area_CODE    VARCHAR(MAX)         
	 ,city_Code    VARCHAR(MAX)         
	 ,state_CODE    VARCHAR(MAX)         
	 ,cus_gst_state  VARCHAR(MAX)        
	 ,EMAIL   VARCHAR(MAX) 
	 ,PIN   VARCHAR(MAX)
 )      
      
  SET @cStep='12.1'  
 INSERT INTO #SLSIMPORT_CUSTDYM(SR_NO,USER_CUSTOMER_CODE ,customer_fname,customer_lname,address0,address1,address2,address9,area,city,state,
 cus_gst_state,CUSTOMER_CODE,CUS_GST_NO,EMAIL,PIN,area_CODE,city_Code,state_CODE)      
 SELECT 1, A.USER_CUSTOMER_CODE ,A.customer_fname,A.customer_lname,A.address0,A.address1,A.address2,A.address9,ISNULL(A.area_name,A.AREA),A.city,A.state,  
 A.cus_gst_state_code,ISNULL(B.customer_code,'') AS CUSTOMER_CODE ,A.CUS_GST_NO,A.EMAIL,a.pin       ,a.area_code,a.CITY_CODE,a.STATE_CODE
 FROM cus_custdym_upload A  (NOLOCK)           
 LEFT OUTER JOIN CUSTDYM B (NOLOCK)  ON B.user_customer_code=A.USER_CUSTOMER_CODE      
 WHERE A.SP_ID=@nSpId AND ISNULL(A.USER_CUSTOMER_CODE,'')<>''  AND ISNULL(B.inactive,0)=0     
   --SELECT * FROM #SLSIMPORT_CUSTDYM  
 DECLARE @cState VARCHAR(50),@cCity VARCHAR(50),@cArea VARCHAR(50),@cState_Code VARCHAR(50),@cCity_Code VARCHAR(50),@cArea_Code VARCHAR(50)      
      
SELECT @cState=state,@cCity =City,@cArea =area,@cState_Code=state_CODE,@cCity_Code=city_Code,@cArea_Code=area_CODE FROM #SLSIMPORT_CUSTDYM  
IF ISNULL(@cArea,'')='' AND ISNULL(@cCity,'')<>''
	SET @cArea= ISNULL(@cCity,'')

	SET @cStep='12.2'  
IF '' <>ISNULL(@CSTATE,'')   
BEGIN  
 IF NOT EXISTS(SELECT 'U' FROM STATE(NOLOCK) WHERE STATE_CODE =ISNULL(@cState_Code,'') AND ISNULL(@cState_Code,'')<>'')     
 BEGIN
	  INSERT INTO STATE(STATE_CODE,STATE,LAST_UPDATE,REGION_CODE,OCTROI_PERCENTAGE,INACTIVE,COMPANY_CODE,UPLOADED_TO_ACTIVSTREAM)      
	  SELECT TOP 1 ISNULL(@CSTATE_CODE,'') ,STATE,GETDATE(),'0000000', 0, 0,'01',0      
	  FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@CSTATE,'')<>''      
 END
 ELSE IF EXISTS(SELECT 'U' FROM STATE(NOLOCK) WHERE STATE =ISNULL(@CSTATE,''))     
 BEGIN      
  UPDATE A SET A.STATE_CODE =B.STATE_CODE       
  FROM #SLSIMPORT_CUSTDYM A      
  JOIN STATE B ON B.STATE=ISNULL(@CSTATE,'')      
  END      
  ELSE      
  BEGIN     
  
  LBL_STATE:
  EXEC GETNEXTKEY_OPT 'STATE', 'STATE_CODE', 7, @CLOCID, 1,'',0, 'KEYS',@CSTATE_CODE OUTPUT           
  
  IF EXISTS (SELECT TOP 1'U' FROM STATE WHERE STATE_CODE=@CSTATE_CODE)
     GOTO LBL_STATE

  INSERT INTO STATE(STATE_CODE,STATE,LAST_UPDATE,REGION_CODE,OCTROI_PERCENTAGE,INACTIVE,COMPANY_CODE,UPLOADED_TO_ACTIVSTREAM)      
  SELECT TOP 1 ISNULL(@CSTATE_CODE,'') ,STATE,GETDATE(),'0000000', 0, 0,'01',0      
  FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@CSTATE,'')<>''      
      
  UPDATE A SET A.STATE_CODE =@CSTATE_CODE      
  FROM #SLSIMPORT_CUSTDYM A      
  JOIN STATE B ON B.STATE=ISNULL(@CSTATE,'')      
 END      
END  
      
     --SELECT * FROM #SLSIMPORT_CUSTDYM  
	 SET @cStep='12.3'  
IF '' <>ISNULL(@cCity,'')  
BEGIN 
 IF NOT EXISTS(SELECT 'U' FROM CITY(NOLOCK) WHERE CITY_CODE =ISNULL(@cCity_Code,'') AND ISNULL(@cCity_Code,'') <>'')    
 BEGIN    
	  INSERT INTO CITY(CITY_CODE,CITY,LAST_UPDATE,state_code,inactive,distt_code,company_code,Uploaded_to_ActivStream)      
	  SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0      
	  FROM #SLSIMPORT_CUSTDYM where ISNULL(@cCity,'')<>''  
 END
 ELSE IF EXISTS(SELECT 'U' FROM CITY(NOLOCK) WHERE CITY =ISNULL(@cCity,'') )    
 BEGIN      
  UPDATE A SET A.city_Code =B.CITY_CODE       
  FROM #SLSIMPORT_CUSTDYM A      
  JOIN CITY B ON B.city=ISNULL(@cCity,'')      
 END      
 ELSE      
 BEGIN      
  
  LBL_CITY:
  EXEC GETNEXTKEY_opt 'CITY', 'CITY_CODE', 7, @CLOCID, 1,'',0 ,'keys',@cCity_Code OUTPUT           
  
  IF EXISTS (SELECT TOP 1 'U' FROM CITY WHERE CITY_CODE=@cCity_Code)
     GOTO LBL_CITY

  INSERT INTO CITY(CITY_CODE,CITY,LAST_UPDATE,state_code,inactive,distt_code,company_code,Uploaded_to_ActivStream)      
  SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0      
  FROM #SLSIMPORT_CUSTDYM where ISNULL(@cCity,'')<>''      
  --SELECT * FROM CITY      
  UPDATE A SET A.CITY_CODE =@cCity_Code      
  FROM #SLSIMPORT_CUSTDYM A      
  JOIN CITY B ON B.CITY=ISNULL(@cCity,'')      
 END    
END    
SET @cStep='12.4'  
--SELECT ISNULL(@cArea,'') 
IF '' <>ISNULL(@cArea,'')  
BEGIN
IF NOT EXISTS(SELECT 'U' FROM area(NOLOCK) WHERE area_code =ISNULL(@cArea_Code,'') AND ISNULL(@cArea_Code,'') <>'')         
 BEGIN
	 INSERT INTO AREA(CITY_CODE,last_update,inactive,company_code,area_code,area_name,pincode)      
	  SELECT TOP 1 isnull(city_Code,'0000000') ,GETDATE(),0,'01',@cArea_Code,@cArea,isnull(pin,'') as pin
	  FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@cArea,'')<>''    
 END
 ELSE IF NOT EXISTS(SELECT 'U' FROM area(NOLOCK) WHERE area_name =ISNULL(@cArea,'') )         
 BEGIN  
 --SELECT 'ROHIT'
  LBL_AREA:
  EXEC GETNEXTKEY_OPT 'AREA', 'AREA_CODE', 7, @CLOCID, 1,'',0, 'keys',@cArea_Code OUTPUT           
  
  IF EXISTS (SELECT TOP 1 'U' FROM AREA  WHERE area_code =@cArea_Code)
     GOTO LBL_AREA


	
	 -- SELECT TOP 1 city_Code ,GETDATE(),0,'01',@cArea_Code,@cArea,''      
  --FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@cArea,'')<>'' 
  INSERT INTO AREA(CITY_CODE,last_update,inactive,company_code,area_code,area_name,pincode)      
  SELECT TOP 1 isnull(city_Code,'0000000') ,GETDATE(),0,'01',@cArea_Code,@cArea,isnull(pin,'') as pin
  FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@cArea,'')<>''      
      --SELECT * FROM AREA (NOLOCK) WHERE AREA_CODE =@cArea_Code
  UPDATE A SET A.AREA_CODE =@cArea_Code      
  FROM #SLSIMPORT_CUSTDYM A      
  JOIN AREA B ON B.AREA_NAME=ISNULL(@cArea,'')  
   
  UPDATE A SET A.AREA_CODE =@cArea_Code      
  FROM CUS_custdym_UPLOAD A     
  WHERE SP_ID=@nSpId  
 END 
 ELSE
BEGIN
--SELECT cArea_Code=AREA_CODE FROM AREA B WHERE  B.AREA_NAME=ISNULL(@cArea,'') 
SELECT @cArea_Code=AREA_CODE FROM AREA B WHERE  B.AREA_NAME=ISNULL(@cArea,'') 
--SELECT @cArea_Code
   UPDATE A SET A.AREA_CODE =@cArea_Code     
   FROM #SLSIMPORT_CUSTDYM A      

   
   UPDATE A SET A.AREA_CODE =@cArea_Code         
   FROM CUS_custdym_UPLOAD A    
   WHERE A.SP_ID=@nSpId  

   --select * from Area A (nolock)
   --join CUS_custdym_UPLOAD b (nolock) on a.area_code =b.area_code 

END
END  

       
   --SELECT area_code,* FROM #SLSIMPORT_CUSTDYM  

   --SELECT area_code,* FROM CUS_custdym_UPLOAD WHERE SP_ID=@nSpId  
  
  
  
  
  
  SET @cStep='15'  
  SELECT TOP 1 @cTreatMobileAsCustCode=ISNULL(value,'') FROM config (NOLOCK) WHERE config_option='TREAT_CUSTID_AS_MOBILE'  
  
  SET @cTreatMobileAsCustCode=(CASE WHEN ISNULL(@cTreatMobileAsCustCode,'')<>'1' AND @bWizclipEnabled=1 THEN   
         '1' ELSE ISNULL(@cTreatMobileAsCustCode,'') END)  
  IF @nUpdatemode=1   
  BEGIN  
     
   IF @cTreatMobileAsCustCode<>'1'  
   BEGIN  
    SET @cStep='20'  
    EXEC GETNEXTKEY @CTABLENAME='CUSTDYM',    
     @CCOLNAME='CUSTOMER_CODE',    
     @NWIDTH=12,    
     @CPREFIX=@CLOCATIONID,    
     @NLZEROS=1,    
     @CFINYEAR='',    
     @NROWCOUNT=2,    
     @CNEWKEYVAL=@cCustomerCode OUTPUT    
     
   SET @cStep='22'  
   UPDATE cus_custdym_upload SET customer_code=@cCustomerCode WHERE sp_id=@nSpid  
  
   END  
  
   ELSE  
   BEGIN  
   SET @cStep='25'  
   SELECT @cCustomerCode=mobile FROM cus_custdym_upload (NOLOCK) WHERE sp_id=@nSpId  
     
   IF ISNULL(@cCustomerCode,'')=''   
   SELECT @cCustomerCode=ISNULL(user_customer_code,'')  FROM cus_custdym_upload (NOLOCK) WHERE sp_id=@nSpId    
     
   IF ISNULL(@cCustomerCode,'')=''   
   BEGIN  
   SET @cErrormsg='Atleast Customer Id/Mobile no. should be filled up ..... Please check'  
   GOTO END_PROC  
   END  
   SET @cStep='27'  
   IF LEN(@cCustomerCode)<>10   
   BEGIN  
   SET @cErrormsg='Customer Code should be purely 10 digit Mobile no. ..... Please check'  
   GOTO END_PROC  
   END  
   END  
   END  
  
   SET @cStep='30'  
   SET @CWHERECLAUSE = ' b.SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''  
  
   EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
   @CSOURCEDB = ''  
 , @CSOURCETABLE = 'cus_custdym_upload'  
 , @CDESTDB  = ''  
 , @CDESTTABLE = 'custdym'  
 , @CKEYFIELD1 = 'customer_code'  
 , @BALWAYSUPDATE = 1  
 , @CFILTERCONDITION=@cWhereClause  
 
 
 
   SET @cStep='40'  
  
   EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN   
   @CSOURCEDB = ''  
 , @CSOURCETABLE = 'Cus_customer_fix_attr_upload'  
 , @CDESTDB  = ''  
 , @CDESTTABLE = 'customer_fix_attr'  
 , @CKEYFIELD1 = 'customer_code'  
 , @BALWAYSUPDATE = 1  
 , @CFILTERCONDITION=@cWhereClause  
 
 
      
END TRY    
  
BEGIN CATCH     
 SET @cErrormsg='Error in Procedure Savetran_Customer at Step#'+@cStep+' '+error_message()  
 GOTO END_PROC  
END CATCH    
  
END_PROC:    
 IF ISNULL(@cErrormsg,'')=''  
  COMMIT  
 ELSE  
  ROLLBACK  
   
 --DELETE FROM CUS_custdym_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId  
  
 SELECT @cCustomerCode as customer_code,ISNULL(@cErrormsg,'') AS [ERRMSG]    
END 
/*
CREATE PROCEDURE SAVETRAN_CUSTOMER
 (  
	 @nUpdatemode	NUMERIC(1,0),
	 @nSpId			VARCHAR(40),
	 @CLOCID		VARCHAR(5)
 )  
 AS  
 BEGIN  
 DECLARE @CNEWKEYVAL VARCHAR(100),@CLOCATIONID VARCHAR(5),@cErrormsg VARCHAR(MAX) ,@cStep varchar(4),
		 @CWHERECLAUSE VARCHAR(200),@lINSERTONLY BIT,@lUpdateONLY BIT,@cCustomerCode CHAR(12),
		 @bWizclipEnabled BIT,@cTreatMobileAsCustCode VARCHAR(2),@cMobile VARCHAR(50),@cUserCustCode VARCHAR(50),
		 @cCustName VARCHAR(500)
		 update  cus_custdym_upload set last_update=getdate() WHERE sp_id=@nSpId
 BEGIN TRANSACTION   
BEGIN TRY  
  
  SET @cStep='5'

  SELECT TOP 1 @cCustomerCode=customer_code,@cMobile=mobile,@cUserCustCode=user_customer_code,
  @cCustName=customer_fname+customer_lname FROM cus_custdym_upload (NOLOCK) WHERE sp_id=@nSpId

  IF @cCustomerCode IS NULL
  BEGIN
	 SET @cErrormsg='Blank data cannot be saved... Please check'
	 GOTO END_PROC
  END 	

  SET @cStep='8'
  IF ISNULL(@cCustName,'')=''
  BEGIN
	 SET @cErrormsg='Customer name cannot be blank... Please check'
	 GOTO END_PROC
  END

  SET @cStep='12'
  IF ISNULL(@CLOCID,'')=''  
		SELECT @CLOCATIONID =DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
  ELSE  
		SELECT @CLOCATIONID = @CLOCID  
  
  SELECT @bWizclipEnabled=isnull(wizclip,0) FROM location (NOLOCK) WHERE dept_id=@CLOCATIONID

  CREATE TABLE #SLSIMPORT_CUSTDYM          
  (          
	SR_NO    NUMERIC(18)       
	,USER_CUSTOMER_CODE  VARCHAR(MAX)       
	,customer_fname  VARCHAR(MAX)       
	,customer_lname  VARCHAR(MAX)       
	,address0   VARCHAR(MAX)       
	,address1   VARCHAR(MAX)       
	,address2   VARCHAR(MAX)       
	,address9   VARCHAR(MAX)    
	,area    VARCHAR(MAX)       
	,city    VARCHAR(MAX)       
	,state    VARCHAR(MAX)       
	,CUS_GST_NO  VARCHAR(MAX)       
	,CUSTOMER_CODE  VARCHAR(MAX)       
	,area_CODE    VARCHAR(MAX)       
	,city_Code    VARCHAR(MAX)       
	,state_CODE    VARCHAR(MAX)       
	,cus_gst_state  VARCHAR(MAX)      
	,EMAIL   VARCHAR(MAX)     
 )    
    

 INSERT INTO #SLSIMPORT_CUSTDYM(SR_NO,USER_CUSTOMER_CODE ,customer_fname,customer_lname,address0,address1,address2,address9,area,city,state,cus_gst_state,CUSTOMER_CODE,CUS_GST_NO,EMAIL)    
 SELECT 1, A.USER_CUSTOMER_CODE ,A.customer_fname,A.customer_lname,A.address0,A.address1,A.address2,A.address9,A.area_name,A.city,A.state,
 A.cus_gst_state_code,ISNULL(B.customer_code,'') AS CUSTOMER_CODE ,A.CUS_GST_NO,A.EMAIL    
 FROM cus_custdym_upload A  (NOLOCK)         
 LEFT OUTER JOIN CUSTDYM B (NOLOCK)  ON B.user_customer_code=A.USER_CUSTOMER_CODE    
 WHERE A.SP_ID=@nSpId AND ISNULL(A.USER_CUSTOMER_CODE,'')<>''  AND ISNULL(B.inactive,0)=0   
   --SELECT * FROM #SLSIMPORT_CUSTDYM
 DECLARE @cState VARCHAR(50),@cCity VARCHAR(50),@cArea VARCHAR(50),@cState_Code VARCHAR(50),@cCity_Code VARCHAR(50),@cArea_Code VARCHAR(50)    
    
SELECT @cState=state,@cCity =City,@cArea =area FROM #SLSIMPORT_CUSTDYM
IF '' <>ISNULL(@CSTATE,'') 
BEGIN
	IF EXISTS(SELECT 'U' FROM STATE(NOLOCK) WHERE STATE =ISNULL(@CSTATE,''))   
	BEGIN    
		UPDATE A SET A.STATE_CODE =B.STATE_CODE     
		FROM #SLSIMPORT_CUSTDYM A    
		JOIN STATE B ON B.STATE=ISNULL(@CSTATE,'')    
		END    
		ELSE    
		BEGIN    
		EXEC GETNEXTKEY_OPT 'STATE', 'STATE_CODE', 7, @CLOCID, 1,'',0, 'KEYS',@CSTATE_CODE OUTPUT         
    
		INSERT INTO STATE(STATE_CODE,STATE,LAST_UPDATE,REGION_CODE,OCTROI_PERCENTAGE,INACTIVE,COMPANY_CODE,UPLOADED_TO_ACTIVSTREAM)    
		SELECT TOP 1 ISNULL(@CSTATE_CODE,'') ,STATE,GETDATE(),'0000000', 0, 0,'01',0    
		FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@CSTATE,'')<>''    
    
		UPDATE A SET A.STATE_CODE =@CSTATE_CODE    
		FROM #SLSIMPORT_CUSTDYM A    
		JOIN STATE B ON B.STATE=ISNULL(@CSTATE,'')    
	END    
END
    
     --SELECT * FROM #SLSIMPORT_CUSTDYM
IF '' <>ISNULL(@cCity,'')
BEGIN
	IF EXISTS(SELECT 'U' FROM CITY(NOLOCK) WHERE CITY =ISNULL(@cCity,'') )  
	BEGIN    
		UPDATE A SET A.city_Code =B.CITY_CODE     
		FROM #SLSIMPORT_CUSTDYM A    
		JOIN CITY B ON B.city=ISNULL(@cCity,'')    
	END    
	ELSE    
	BEGIN    
		--DECLARE @cCity_Code VARCHAR(MAX)    
		EXEC GETNEXTKEY_opt 'CITY', 'CITY_CODE', 7, 'JM', 1,'',0 ,'keys',@cCity_Code OUTPUT         
		----select @cCity_Code as city    
		--SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0    
		--FROM #SLSIMPORT_CUSTDYM    
		INSERT INTO CITY(CITY_CODE,CITY,LAST_UPDATE,state_code,inactive,distt_code,company_code,Uploaded_to_ActivStream)    
		SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0    
		FROM #SLSIMPORT_CUSTDYM where ISNULL(@cCity,'')<>''    
		--SELECT * FROM CITY    
		UPDATE A SET A.CITY_CODE =@cCity_Code    
		FROM #SLSIMPORT_CUSTDYM A    
		JOIN CITY B ON B.CITY=ISNULL(@cCity,'')    
	END  
END    
IF '' <>ISNULL(@cArea,'')
BEGIN
	IF NOT EXISTS(SELECT 'U' FROM area(NOLOCK) WHERE area_code =ISNULL(@cArea,'') )       
	BEGIN    
		EXEC GETNEXTKEY_OPT 'AREA', 'AREA_CODE', 7, @CLOCID, 1,'',0, 'keys',@cArea_Code OUTPUT         
    
		INSERT INTO AREA(CITY_CODE,last_update,inactive,company_code,area_code,area_name,pincode)    
		SELECT TOP 1 city_Code ,GETDATE(),0,'01',@cArea_Code, area,''    
		FROM #SLSIMPORT_CUSTDYM WHERE ISNULL(@cArea,'')<>''    
    
		UPDATE A SET A.AREA_CODE =@cArea_Code    
		FROM #SLSIMPORT_CUSTDYM A    
		JOIN AREA B ON B.AREA_NAME=ISNULL(@cArea,'')
 
		UPDATE A SET A.AREA_CODE =@cArea_Code    
		FROM CUS_custdym_UPLOAD A   
		WHERE SP_ID=@@spid
	END    
END
     
   --SELECT * FROM #SLSIMPORT_CUSTDYM





  SET @cStep='15'
  SELECT TOP 1 @cTreatMobileAsCustCode=ISNULL(value,'') FROM config (NOLOCK) WHERE config_option='TREAT_CUSTID_AS_MOBILE'

  SET @cTreatMobileAsCustCode=(CASE WHEN ISNULL(@cTreatMobileAsCustCode,'')<>'1' AND @bWizclipEnabled=1 THEN 
									'1' ELSE ISNULL(@cTreatMobileAsCustCode,'') END)
  IF @nUpdatemode=1 
  BEGIN
	  
	  IF @cTreatMobileAsCustCode<>'1'
	  BEGIN
		  SET @cStep='20'
		  EXEC GETNEXTKEY @CTABLENAME='CUSTDYM',  
			  @CCOLNAME='CUSTOMER_CODE',  
			  @NWIDTH=12,  
			  @CPREFIX=@CLOCATIONID,  
			  @NLZEROS=1,  
			  @CFINYEAR='',  
			  @NROWCOUNT=2,  
			  @CNEWKEYVAL=@cCustomerCode OUTPUT  
		 
		 SET @cStep='22'
		 UPDATE cus_custdym_upload SET customer_code=@cCustomerCode WHERE sp_id=@nSpid

	  END

	  ELSE
	  BEGIN
		 SET @cStep='25'
		 SELECT @cCustomerCode=mobile FROM cus_custdym_upload (NOLOCK) WHERE sp_id=@nSpId
		 
		 IF ISNULL(@cCustomerCode,'')='' 
			SELECT @cCustomerCode=ISNULL(user_customer_code,'')  FROM cus_custdym_upload (NOLOCK) WHERE sp_id=@nSpId 	
		 
		 IF ISNULL(@cCustomerCode,'')='' 
		 BEGIN
			SET @cErrormsg='Atleast Customer Id/Mobile no. should be filled up ..... Please check'
			GOTO END_PROC
		 END
		 SET @cStep='27'
		 IF LEN(@cCustomerCode)<>10 
		 BEGIN
			SET @cErrormsg='Customer Code should be purely 10 digit Mobile no. ..... Please check'
			GOTO END_PROC
		 END
	  END
   END

   SET @cStep='30'
   SET @CWHERECLAUSE = ' b.SP_ID='''+LTRIM(RTRIM((@NSPID)))+''''

   EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
	  @CSOURCEDB	= ''
	, @CSOURCETABLE = 'cus_custdym_upload'
	, @CDESTDB		= ''
	, @CDESTTABLE	= 'custdym'
	, @CKEYFIELD1	= 'customer_code'
	, @BALWAYSUPDATE = 1
	, @CFILTERCONDITION=@cWhereClause
     
    
END TRY  

BEGIN CATCH   
	SET @cErrormsg='Error in Procedure Savetran_Customer at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH  

END_PROC:  
	IF ISNULL(@cErrormsg,'')=''
		COMMIT
	ELSE
		ROLLBACK
	
	--DELETE FROM CUS_custdym_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId

	SELECT @cCustomerCode as customer_code,ISNULL(@cErrormsg,'') AS [ERRMSG]  
END 
*/