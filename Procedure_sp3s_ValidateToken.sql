create Procedure sp3s_ValidateToken
(
  @DeviceId varchar(50),
  @AuthToken varchar(40)
)
as
begin
      
	  Declare @CERRORMSG varchar(1000),@cuser_code varchar(10),@cstep varchar(10),
	          @PASSWORD varchar(1000),@USERNAME varchar(100)
	  Print 'Starting Proces'

	  BEGIN TRY        
     
	  
	   SET @CERRORMSG=''
	    set @cstep='10'
		
		               
   IF NOT EXISTS(SELECT TOP 1 'u'  FROM USERLOGINDETAILS (NOLOCK) WHERE DeviceId =@DeviceId and AuthToken=@AuthToken )                          
   BEGIN                          
      SET @CERRORMSG='Invalid Token'                          
      GOTO END_PROC                          
   END       

        select @cuser_code=USER_CODE 
		from UserLoginDetails a (nolock) where DeviceId =@DeviceId and AuthToken=@AuthToken

		SELECT  @USERNAME=USERNAME,@PASSWORD=passwd  FROM USERS WHERE USER_CODE=@CUSER_CODE
      
	  
	 END TRY        
	 BEGIN CATCH        
	  SET @CERRORMSG =' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) +@cstep + ERROR_MESSAGE()        
	  GOTO END_PROC        
	 END CATCH        
         
END_PROC:        

    
		SELECT isnull(@USERNAME,'')  USERNAME , @DEVICEID DEVICEID,@AUTHTOKEN AUTHTOKEN,
	       @CERRORMSG AS ERRMSG,CASE WHEN ISNULL(@CERRORMSG,'')<>'' THEN 'FAILED' ELSE 'SUCESS' END STATUS
		
	


end