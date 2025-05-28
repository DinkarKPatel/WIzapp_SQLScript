CREATE  PROCEDURE sp3s_ValidateLogin  
(  
  @Username varchar(100),   
  @Password varchar(max),  
  @DeviceId varchar(50),  
  @cLocid varchar(10)=''  
)  
as  
begin  
        
   Declare @CERRORMSG varchar(1000),@cuser_code varchar(10),@cstep varchar(10),  
           @AUTHTOKEN VARCHAR(100),@cWizclipGrpCode VARCHAR(5)  
   Print 'Starting Proces'  
  
   BEGIN TRY          
      BEGIN TRANSACTION    
     
    SET @CERRORMSG=''  
     set @cstep='10'  
  select top 1 @cuser_code=user_code from users (Nolock) WHERE username =@Username and passwd =@Password  
  
  if isnull(@cuser_code,'')=''  
  begin  
        set @CERRORMSG=' Invaild UserId & Password'  
     GOTO END_PROC  
  end  
  --if isnull(@DeviceId,'')=''  
  --begin  
  --      set @CERRORMSG='Blank DeviceId Not Accepted'  
  --   GOTO END_PROC  
  --end  
  
  
  set @cstep='20'  

  set @AuthToken=newid()
  ----if  exists (select top 1 'u' from UserLoginDetails (nolock) where user_code=@cuser_code )  --and DeviceId =@DeviceId
  ----begin  
  ----      update a set AuthToken=newid()  
  ----   from UserLoginDetails a (nolock) where user_code=@cuser_code --and DeviceId =@DeviceId  
  ----end  
  ----else  
  ----begin  
         
    INSERT INTO USERLOGINDETAILS(USER_CODE,DEVICEID,AUTHTOKEN)  
    select @cuser_code as USER_CODE,@DeviceId as DeviceId,@AuthToken as AuthToken  
  
 -- end  
   
   SELECT TOP 1 @cWizclipGrpCode=value FROM config (NOLOCK) WHERE config_option='campaign_grp_code'
    
  --select @AUTHTOKEN=AUTHTOKEN  
  --from UserLoginDetails a (nolock) where user_code=@cuser_code --and DeviceId =@DeviceId  
     
  END TRY          
  BEGIN CATCH          
   SET @CERRORMSG =' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) +@cstep + ERROR_MESSAGE()          
   GOTO END_PROC          
  END CATCH          
           
END_PROC:          
 IF @@TRANCOUNT>0          
 BEGIN          
  IF ISNULL(@CERRORMSG,'')=''           
  BEGIN          
   commit TRANSACTION          
  END           
  ELSE          
   ROLLBACK          
 END      
      
   
  
 SELECT @USERNAME USERNAME , @DEVICEID DEVICEID,@AUTHTOKEN AUTHTOKEN,  
        @CERRORMSG as ERRMSG ,(CASE WHEN ISNULL(@CERRORMSG,'')<>'' THEN 'FAILED' ELSE 'SUCCESS' END) STATUS,
		ISNULL(@cWizclipGrpCode,'') WizclipGrpCode
   
  
  
  
end



