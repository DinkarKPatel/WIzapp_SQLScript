CREATE PROCEDURE SP_MERGE_MIRROR_XNSLMNEW_DATA
(
	@CspId VARCHAR(40),  
    @CERRMSG VARCHAR(MAX) OUTPUT  
)
AS
BEGIN
	DECLARE @CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CTABLE_SUFFIX VARCHAR(100),
	@CTABLENAME VARCHAR(100),@CTMP_TABLENAME VARCHAR(100),@CKEYFIELD VARCHAR(100),
	@CTABLESSTR VARCHAR(MAX),@cFiLterCondition VARCHAR(2000)
	
	DECLARE @TXNSSENDINFO TABLE (ORG_TABLENAME VARCHAR(50),TMP_TABLENAME VARCHAR(50),XN_ID VARCHAR(40))
	BEGIN TRY 
			
			SET @cFiLterCondition=' b.sp_id='''+@cSPId+''''

			SET @CSTEP = 20 
			SET @CTABLENAME='REGIONM'  
			SET @CTMP_TABLENAME='XNSLM_'+@CTABLENAME+'_upload'
			SET @CKEYFIELD='REGION_CODE'  
			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=''  
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
				 ,@LINSERTONLY=1,@CJOINSTR='',@LUPDATEONLY=0 ,@BALWAYSUPDATE=1,@CFILTERCONDITION=@CFILTERCONDITION 
				 
			SET @CSTEP = 30 
			SET @CTABLENAME='STATE'  
			SET @CTMP_TABLENAME='XNSLM_'+@CTABLENAME+'_upload'
			SET @CKEYFIELD='STATE_CODE'  
			SET @CSTEP=40 
			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=''  
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
				 ,@LINSERTONLY=1,@CJOINSTR='',@LUPDATEONLY=0  
				 ,@BALWAYSUPDATE=0,@CFILTERCONDITION=@CFILTERCONDITION 
		   
			SET @CSTEP = 60
			SET @CTABLENAME='CITY'  
			SET @CTMP_TABLENAME='XNSLM_'+@CTABLENAME+'_upload'
			SET @CKEYFIELD='CITY_CODE'  
			SET @CSTEP=80 
			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=''  
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
				 ,@LINSERTONLY=1,@CJOINSTR='',@LUPDATEONLY=0  
				 ,@BALWAYSUPDATE=0,@CFILTERCONDITION=@CFILTERCONDITION 
		    
			SET @CSTEP = 100
			SET @CTABLENAME='AREA'  
			SET @CTMP_TABLENAME='XNSLM_'+@CTABLENAME+'_upload'
			SET @CKEYFIELD='AREA_CODE'  
			SET @CSTEP= 120 
			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=''  
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
				 ,@LINSERTONLY=1,@CJOINSTR='',@LUPDATEONLY=0  
				 ,@BALWAYSUPDATE=0,@CFILTERCONDITION=@CFILTERCONDITION
		    
			SET @CSTEP= 130 
			SET @cCmd=N'UPDATE a SET ac_name=a.ac_name+''_''+a.ac_code from XNSLM_LM01106_UPLOAD b
						JOIN lm01106 a ON a.ac_name=b.ac_name
						WHERE '+@cFilterCondition+' AND a.ac_code<>b.ac_code'
			EXEC SP_EXECUTESQL @cCmd

			SET @CSTEP = 140
			SET @CTABLENAME='LM01106'  
			SET @CTMP_TABLENAME='XNSLM_'+@CTABLENAME+'_upload'
			SET @CKEYFIELD='AC_CODE'  
			SET @CSTEP= 160
			
			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=''  
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
				 ,@LINSERTONLY=1,@CJOINSTR='',@LUPDATEONLY=0  
				 ,@BALWAYSUPDATE=0,@CFILTERCONDITION=@CFILTERCONDITION                    

			SET @CSTEP = 170
			SET @CTABLENAME='LMP01106'  
			SET @CTMP_TABLENAME='XNSLM_'+@CTABLENAME+'_upload'
			SET @CKEYFIELD='AC_CODE'  
			
			EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=''  
				 ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
				 ,@LINSERTONLY=1,@CJOINSTR='',@LUPDATEONLY=0  
				 ,@BALWAYSUPDATE=0,@CFILTERCONDITION=@CFILTERCONDITION                    
				         
	END TRY
    
	BEGIN CATCH
	 SET @CERRMSG='P:SP_MERGE_MIRROR_XNSLM_DATA, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()
	END CATCH

EXIT_PROC:
	IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0  
		COMMIT  
	ELSE
	IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0  
		ROLLBACK  

	DELETE FROM xnslm_lm01106_upload WHERE sp_id=@cSpId		
	DELETE FROM xnslm_lmp01106_upload WHERE sp_id=@cSpId
	DELETE FROM xnslm_area_upload WHERE sp_id=@cSpId
	DELETE FROM xnslm_city_upload WHERE sp_id=@cSpId
	DELETE FROM xnslm_state_upload WHERE sp_id=@cSpId
	DELETE FROM xnslm_regionm_upload WHERE sp_id=@cSpId

END
--END OF THE PROCEDURES SP_MERGE_MIRROR_XNSLM_DATA