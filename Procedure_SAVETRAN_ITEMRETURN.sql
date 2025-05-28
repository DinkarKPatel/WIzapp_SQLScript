create PROCEDURE SAVETRAN_ITEMRETURN
(
  @CINV_ID varchar(30)='',
  @CPS_ID varchar(30)='',
  @CLOCID VARCHAR(4)='',
  @NRETURNINVOICE int=0, --1 FOR WSL 2 FOR PRT,
  @cUser_code varchar(7)='0000000'
)          
AS        
BEGIN 
     
     Declare @CERRORMSG varchar(1000),@cStep varchar(10),@CRETRUNID varchar(30)
     BEGIN TRY
     BEGIN TRANSACTION	
     
         set @cStep=10
          
         IF EXISTS (SELECT TOP 1 'U' from  XNS_GITBINITEM_UPLOAD WHERE inv_id=@CINV_ID and ps_Id=@CPS_ID)
         begin
              
              
             IF @NRETURNINVOICE=2
			BEGIN
			    
				PRINT 'GENERATE DEBITNOET'
				
				EXEC SP_Generate_GRPPrt
				     @CMEMOID=@CINV_ID,
                     @CLOCID=@CLOCID,
                     @CRETRUNID=@CRETRUNID output,
                     @cErrormsg=@CERRORMSG output,
                     @CPS_ID=@CPS_ID ,
                     @BDONOTCALLEDFROMGIT =1,
                     @cUser_code =@cUser_code
                     
                    
                     IF ISNULL(@CERRORMSG,'')<>''
                        GOTO EXIT_PROC

			END
			Else IF @NRETURNINVOICE=1
			BEGIN
			     
			     PRINT 'GENERATE WSL INVOICE'
			     
			     	EXEC SP_Generate_GRPWSL
				     @CMEMOID=@CINV_ID,
                     @CLOCID=@CLOCID,
                     @CRETRUNID=@CRETRUNID output,
                     @cErrormsg=@CERRORMSG output,
                     @CPS_ID=@CPS_ID ,
                     @DONOTCALLEDFROMGIT=1,
                     @cUser_code =@cUser_code
                     
                     IF ISNULL(@CERRORMSG,'')<>''
                        GOTO EXIT_PROC
			
			end
			
			if ISNULL(@CRETRUNID,'')=''
			begin
			    set @CERRORMSG='Error In Generating return Item'
			    GOTO EXIT_PROC
			end
         
         end
          
     
     
     END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'Error in Procedure SAVETRAN_ITEMRETURN at Step#'+@cStep+ ' ' + ERROR_MESSAGE()
		GOTO EXIT_PROC
	END CATCH
	
EXIT_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' 
		BEGIN
			commit TRANSACTION
		END	
		ELSE
			ROLLBACK
	END
	
	Delete a from  XNS_GITBINITEM_UPLOAD a (nolock) WHERE inv_id=@CINV_ID and ps_Id=@CPS_ID
	select @CERRORMSG as Errmsg,@CRETRUNID As memo_id
	
 
END 


