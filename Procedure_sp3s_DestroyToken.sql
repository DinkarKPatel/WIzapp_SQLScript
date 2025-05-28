create Procedure sp3s_DestroyToken
(
  @DeviceId varchar(50),
  @AuthToken varchar(40)
)
as
begin
      
	  Declare @CERRORMSG varchar(1000),@cstep varchar(100)
	  Print 'Starting Proces'

	  BEGIN TRY        
     
	  
	   SET @CERRORMSG=''
	    set @cstep='10'
		
		               
	   IF NOT EXISTS(SELECT TOP 1 'u'  FROM USERLOGINDETAILS (NOLOCK) WHERE DeviceId =@DeviceId and AuthToken=@AuthToken )                          
	   BEGIN                          
		  SET @CERRORMSG='Invalid Token'                          
		  GOTO END_PROC                          
	   END       

       DELETE A FROM   USERLOGINDETAILS A  (NOLOCK) WHERE DEVICEID =@DEVICEID AND AUTHTOKEN=@AUTHTOKEN
	  
	 END TRY        
	 BEGIN CATCH        
	  SET @CERRORMSG =' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) +@cstep + ERROR_MESSAGE()        
	  GOTO END_PROC        
	 END CATCH        
         
END_PROC:        

    SELECT ERRMSG=@CERRORMSG,[STATUS]=CASE ISNULL(@CERRORMSG,'') WHEN '' THEN 'SUCCESS' ELSE 'FAILED' END   

	


end