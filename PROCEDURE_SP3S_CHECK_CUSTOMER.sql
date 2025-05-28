CREATE PROCEDURE SP3S_CHECK_CUSTOMER  --(LocId 3 digit change by Sanjay:04-11-2024)
(  
 @CSPID VARCHAR(50),
 @CLOCID  VARCHAR(5)
)  
AS  
BEGIN  
  
DECLARE @CUSER_CODE CHAR(7),@ccustomer_code VARCHAR(20), @CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CERRMSG VARCHAR(MAX)  
     
   SET @CUSER_CODE = '0000000'            
SET @CSTEP='STRP - 10'              
  DECLARE @TERRORDETAILS TABLE            
  (            
   PRODUCT_CODE VARCHAR(50),            
   REF_NO VARCHAR(15),            
   DEPT_ID VARCHAR(4),            
   ERROR_MSG VARCHAR(1000)             
  )    
  
   
SET @CSTEP='STRP - 20'              
SELECT @ccustomer_code =A.customer_code   
FROM CUSTDYM a(NOLOCK)   
LEFT OUTER JOIN AREA AR(NOLOCK) ON AR.area_code=a.area_code
JOIN ONLINE_WSLORD_CUSTDYM_UPLOAD TMP ON a.user_customer_code=ISNULL(TMP.MOBILE,'') AND  a.MOBILE=ISNULL(TMP.MOBILE,'') AND    
ISNULL(a.customer_fname,'') =ISNULL(TMP.customer_fname,'') AND   
ISNULL(a.customer_lname,'')=isnull(TMP.customer_lname,'') AND  
ISNULL(a.address0,'') =ISNULL(TMP.address0,'') AND  
ISNULL(a.address1,'')=ISNULL(TMP.address1,'') AND  
ISNULL(a.address2,'')=ISNULL(TMP.address2,'') AND  
ISNULL(ar.area_name,'')=ISNULL( TMP.area,'') AND   
a.PIN=ISNULL( TMP.pin,'')  
WHERE TMP.SPID =@CSPID

SET @CSTEP='STRP - 30'              
BEGIN TRANSACTION      
BEGIN TRY  
SET @CSTEP='STRP - 40'     


 IF ISNULL(@ccustomer_code ,'')=''  
 BEGIN  
    
   
      
   DECLARE @cState VARCHAR(50),@cCity VARCHAR(50),@cArea VARCHAR(50),@cState_Code VARCHAR(50),@cCity_Code VARCHAR(50),@cArea_Code VARCHAR(50)      
      
   SELECT @cState=state,@cCity =City,@cArea =area FROM ONLINE_WSLORD_CUSTDYM_UPLOAD WHERE SPID=@CSPID      
      
    SET @CSTEP='STRP - 50'         
  IF ISNULL(@cstate,'')=''  
   BEGIN  

	   SET @cstate_code='0000000'  
	   UPDATE ONLINE_WSLORD_CUSTDYM_UPLOAD SET STATE_CODE =@cstate_code WHERE SPID=@CSPID          
	   END  
	   ELSE IF EXISTS(SELECT 'U' FROM STATE(NOLOCK) WHERE state =ISNULL(@cstate,''))      
	   BEGIN      
		UPDATE A SET A.STATE_CODE =B.state_CODE       
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A      
		JOIN STATE B ON B.state=ISNULL(@cstate,'')    
		WHERE SPID=@CSPID   
	
   END      
   ELSE      
   BEGIN      
        lblState:
		EXEC GETNEXTKEY_OPT 'STATE', 'STATE_CODE', 7, @CLOCID, 1,'',0, 'Keys',@cstate_code OUTPUT 
		
		IF EXISTS(SELECT TOP 1 'U' FROM STATE (NOLOCK) WHERE STATE_CODE =@cstate_code)
        GOTO lblState 
      
		INSERT INTO STATE(state_code,state,last_update,region_code,octroi_percentage,inactive,company_code,Uploaded_to_ActivStream)      
		SELECT TOP 1 ISNULL(@cstate_code,'') ,state,GETDATE(),'0000000', 0, 0,'01',0      
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD WHERE ISNULL(@cstate,'')<>''   
		AND SPID=@CSPID     
      
		UPDATE A SET A.STATE_CODE =@cState_Code      
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A      
		JOIN STATE B ON B.state=ISNULL(@cstate,'')    
		WHERE SPID=@CSPID     

   END      
   SET @CSTEP='STRP - 60'              
   IF ISNULL(@cCity,'')=''  
   BEGIN  

	   SET @cCity_Code='0000000'  
	   UPDATE A SET A.CITY_CODE =@cCity_Code      
	   FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A    
	   WHERE SPID=@CSPID    
   
   END  
   ELSE IF EXISTS(SELECT 'U' FROM CITY(NOLOCK) WHERE CITY =ISNULL(@cCity,''))      
   BEGIN     
   
		UPDATE A SET A.city_Code =B.CITY_CODE       
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A      
		JOIN CITY B ON B.city=ISNULL(@cCity,'')     
		WHERE SPID=@CSPID   
	
   END      
   ELSE      
   BEGIN    
   
    lblcity:  
    EXEC GETNEXTKEY'CITY', 'CITY_CODE', 7, @CLOCID, 1,'',0 ,@cCity_Code OUTPUT  
    
    IF EXISTS(SELECT TOP 1 'U' FROM CITY (NOLOCK) WHERE CITY_CODE =@cCity_Code)
      GOTO lblcity 
    
    
      
		INSERT INTO CITY(CITY_CODE,CITY,LAST_UPDATE,state_code,inactive,distt_code,company_code,Uploaded_to_ActivStream)      
		SELECT TOP 1 ISNULL(@cCity_Code,'') ,city,GETDATE(),state_CODE, 0, '0000000','01',0      
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD where ISNULL(@cCity,'')<>''   
		AND SPID=@CSPID     
      
		UPDATE A SET A.CITY_CODE =@cCity_Code      
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A      
		JOIN CITY B ON B.CITY=ISNULL(@cCity,'')  
		WHERE SPID=@CSPID    
	
   END      
      
   SET @CSTEP='STRP - 70'              
   IF EXISTS(SELECT 'U' FROM area(NOLOCK) WHERE area_name =ISNULL(@cArea,''))      
   BEGIN      
		UPDATE A SET A.area_CODE =B.area_code       
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A      
		JOIN AREA B ON B.area_name=ISNULL(@cArea,'')  
		WHERE SPID=@CSPID     
   END      
   ELSE      
   BEGIN      
        lblArea:
		EXEC GETNEXTKEY_OPT 'AREA', 'AREA_CODE', 7, @CLOCID, 1,'',0, 'Keys',@cArea_Code OUTPUT           
	    
		IF EXISTS(SELECT TOP 1 'U' FROM AREA (NOLOCK) WHERE AREA_CODE =@cArea_Code)
        GOTO lblArea 

		
		INSERT INTO AREA(CITY_CODE,last_update,inactive,company_code,area_code,area_name,pincode)      
		SELECT TOP 1 city_Code ,GETDATE(),0,'01',@cArea_Code, area,''      
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD WHERE ISNULL(@cArea,'')<>''    
		AND SPID=@CSPID     
	      
		UPDATE A SET A.AREA_CODE =@cArea_Code      
		FROM ONLINE_WSLORD_CUSTDYM_UPLOAD A      
		JOIN AREA B ON B.AREA_NAME=ISNULL(@cArea,'')   
		WHERE SPID=@CSPID     
   END      
  SET @CSTEP='STRP - 80'              
  SET @cCUSTOMER_CODE =''  
  
   IF EXISTS(SELECT 'U' FROM ONLINE_WSLORD_CUSTDYM_UPLOAD(NOLOCK) WHERE ISNULL(USER_CUSTOMER_CODE,'')<>'' AND ISNULL(CUSTOMER_CODE,'') in('','000000000000') AND  SPID=@CSPID     )      
   BEGIN  
   
   LBLGENCUST:
 
   --DECLARE @cCUSTOMER_CODE VARCHAR(50)      
   EXEC GETNEXTKEY 'CUSTDYM', 'CUSTOMER_CODE', 12, @CLOCID, 1,'',0, @cCUSTOMER_CODE OUTPUT 
   
   IF EXISTS(SELECT TOP 1 'U' FROM CUSTDYM (NOLOCK) WHERE CUSTOMER_CODE=@cCUSTOMER_CODE)
      GOTO LBLGENCUST
      
   INSERT custdym ( ac_code, address0, address1, address2, address9, area_code, BILL_BY_BILL, card_code, card_name, card_no, company_name,       
  cus_gst_no, cus_gst_state_code, customer_code, customer_fname, customer_lname, customer_title, dt_anniversary, dt_birth, dt_card_expiry,       
  dt_card_issue, dt_created, email, email2, FirstCardIssueDt, flat_disc_customer, flat_disc_percentage, flat_disc_percentage_during_sales,       
  form_no, HO_LAST_UPDATE, HO_SYNCH_LAST_UPDATE, inactive, International_customer, LAST_UPDATE, LOCATION_ID, manager_card, mobile, not_downloaded_from_wizclip,       
  old_discount_card_type, OPENING_BALANCE, phone1, phone2, pin, prefix_code, privilege_customer, ref_customer_code, sent_to_ho, Tin_No, uploaded_to_ho,       
  user_customer_code, wizclip_last_update )        
  SELECT  TOP 1  ''ac_code, ISNULL(address0,''), ISNULL(address1,''), ISNULL(address2,''),ISNULL(address9,'') address9, area_code, 0 BILL_BY_BILL, ''card_code,''card_name, '' card_no, company_name company_name,cus_gst_no cus_gst_no,       
  cus_gst_state cus_gst_state_code,@cCUSTOMER_CODE customer_code, ISNULL(customer_fname,'') customer_fname, ISNULL(customer_lname,'')  customer_lname, ''customer_title, ''dt_anniversary, ''dt_birth, ''dt_card_expiry, ''dt_card_issue,       
  ''dt_created, ISNULL(email,'') AS EMAIL, ''email2, '' FirstCardIssueDt, 0 flat_disc_customer, 0 flat_disc_percentage, 0 flat_disc_percentage_during_sales, ''form_no, ''HO_LAST_UPDATE,       
  '' HO_SYNCH_LAST_UPDATE, 0 inactive,0 International_customer, GETDATE() LAST_UPDATE, @CLOCID LOCATION_ID,0 manager_card,user_customer_code mobile, 0 not_downloaded_from_wizclip, '' old_discount_card_type,       
  0 OPENING_BALANCE, '' phone1,'' phone2,  pin, '' prefix_code, 0 privilege_customer,'000000000000' ref_customer_code,0 sent_to_ho, '' Tin_No, 0 uploaded_to_ho, user_customer_code,       
  '' wizclip_last_update       
  FROM ONLINE_WSLORD_CUSTDYM_UPLOAD WHERE ISNULL(USER_CUSTOMER_CODE,'')<>''      
  AND SPID=@CSPID     

 
      
  END  
  SET @CSTEP='STRP - 90'     
 END  
            
 GOTO END_PROC            
              
END TRY            
             
BEGIN CATCH           
  PRINT 'ENTER CATCH BLOCK'         
  SET @CERRMSG='SP3S_CHECK_CUSTOMER  : AT STEP - '+@CSTEP+', MESSAGE - '+ERROR_MESSAGE()      
  PRINT       @CERRMSG      
  GOTO END_PROC             
END CATCH            
             
END_PROC:            
  --IF @@TRANCOUNT>0            
  BEGIN            
   IF ISNULL(@CERRMSG,'')<>''              
   BEGIN            
    PRINT 'ROLLBACK TRANSACTION'            
    ROLLBACK            
   END             
   ELSE            
   BEGIN            
    PRINT 'COMMIT'            
    COMMIT              
   END             
               
  END       
  if ISNULL(@cCUSTOMER_CODE,'')='' OR ISNULL(@cCUSTOMER_CODE,'')='000000000000'
  SET @CERRMSG='Customer not found'

   --SELECT TOP 1 @cCUSTOMER_CODE=USER_CUSTOMER_CODE FROM CUSTDYM WHERE CUSTOMER_CODE =@CCUSTOMER_CODE

 SELECT ISNULL(@cCUSTOMER_CODE,'') AS CUSTOMER_CODE ,
        (SELECT TOP 1 USER_CUSTOMER_CODE FROM CUSTDYM WHERE CUSTOMER_CODE =@CCUSTOMER_CODE) AS USER_CUSTOMER_CODE,
        ISNULL(@CERRMSG,'') AS ERRMSG  


 DELETE FROM ONLINE_WSLORD_CUSTDYM_UPLOAD WHERE SPID=@CSPID 

END