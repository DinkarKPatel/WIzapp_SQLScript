CREATE PROCEDURE SP_MERGE_MIRROR_PCI_DATA
(
    @CMEMOID VARCHAR(50)
   ,@CLOCID VARCHAR(3)
   ,@CSOURCEDB VARCHAR(200)
   ,@CMERGEDB VARCHAR(200)
   ,@BMSTINSERTONLY BIT
   ,@CERRMSG VARCHAR(1000) OUTPUT
)
--WITH ENCRYPTION
AS
BEGIN
      DECLARE @DTSQL NVARCHAR(MAX),@CTMP_TABLENAME VARCHAR(200),@CTABLE_SUFFIX VARCHAR(100),
      @CTABLESUFFIX VARCHAR(100),
      @CERRORMSG VARCHAR(MAX),@CSTEP VARCHAR(10),@CKEYFIELD  VARCHAR(50),@CTABLENAME VARCHAR(100),
      @CERRMSGOUT VARCHAR(500)
      
    BEGIN TRY	
      --SET @CSTEP = 10  
      --SET @CMERGEDB= DB_NAME()
      --SET @CERRORMSG=''   
      SET @CTABLESUFFIX=REPLACE(@CMEMOID,'-','_') 
	
	 BEGIN TRANSACTION
	  --SET @CSOURCEDB=DB_NAME()+'_TEMP.DBO.'
	  SET @CTABLE_SUFFIX=REPLACE(@CMEMOID,'-','_')   
	 
	    SET @CSTEP = 20  
        SET @CTABLENAME='PCI_MST'  
        SET @CTMP_TABLENAME='TMP_PCI_'+@CTABLENAME+'_'+LTRIM(RTRIM(@CTABLE_SUFFIX))  
        SET @CKEYFIELD='MEMO_ID'  
        SET @CSTEP=60 
         
        EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB=@CSOURCEDB,@CSOURCETABLE=@CTMP_TABLENAME,@CDESTDB=@CMERGEDB  
         ,@CDESTTABLE=@CTABLENAME,@CKEYFIELD1=@CKEYFIELD,@CKEYFIELD2='',@CKEYFIELD3=''  
         ,@LINSERTONLY=0,@CJOINSTR='',@LUPDATEONLY=0  
         ,@BALWAYSUPDATE=1   
	 
		 IF ISNULL(@CERRMSGOUT,'')<>''  
		 BEGIN  
		  SET @CERRMSG='P:SP_MERGE_MIRROR_PCI_DATA, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+N''+@CERRMSGOUT+''''  
		 END 
	   
	 END TRY
     BEGIN CATCH
     SET @CERRMSG='P:SP_MERGE_MIRROR_PCI_DATA, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()
     END CATCH
     
EXIT_PROC:
		 IF ISNULL(@CERRMSG,'')='' AND @@TRANCOUNT>0  
         BEGIN  
			 COMMIT  
			 SET @CSTEP=70  
			 SET @CTMP_TABLENAME='TMP_PCI_'+@CTABLENAME+'_'+LTRIM(RTRIM(REPLACE(@CMEMOID,'-','_')))  
			 SET @DTSQL=N'IF OBJECT_ID('''+@CSOURCEDB+@CTMP_TABLENAME+''',''U'') IS NOT NULL    
						DROP TABLE '+@CSOURCEDB+''+@CTMP_TABLENAME+''  
			 PRINT @DTSQL      
			 EXEC SP_EXECUTESQL @DTSQL    
         END  
         ELSE IF ISNULL(@CERRMSG,'')<>'' AND @@TRANCOUNT>0  
				ROLLBACK  

END
