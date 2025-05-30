create PROCEDURE SP_GETMASTERS_ATTR_NEW
(      
 @CFINYEAR VARCHAR(10),       
 @CTABLENAME VARCHAR(50),
 @CERRORMSG VARCHAR(MAX) OUTPUT    ,
 @CDEPT_ID VARCHAR(4)=''
)      
AS      
BEGIN      
  --(dinkar) Replace  left(memoid,2) to Location_code      
    
     DECLARE @CCOLUMN_NAME VARCHAR(100),@CMSTTABLENAME VARCHAR(100),@CCOLUMN_CODE VARCHAR(100),
     @DTSQL NVARCHAR(MAX),@UPDATEVALUE NUMERIC(10,0),@UPDATEVALUE1 NUMERIC(10,0),@UPDATEVALUE2 NUMERIC(10,0),
     @BLOOP INT,@CLOCID VARCHAR(2),@DO_NOT_CREATE_ARTICLE VARCHAR(10) ,@DO_NOT_CREATE_ATTRMST varchar(100),
	  @CNEWATTR VARCHAR(100)

	 
	 SELECT TOP 1 @DO_NOT_CREATE_ARTICLE= VALUE  FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION ='DO_NOT_CREATE_ARTICLE_MASTERS_IN_FILE_IMPORT'  

    
	if @CDEPT_ID=''
    SELECT TOP 1 @CLOCID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
	else
	set @CLOCID=@CDEPT_ID
     
	 IF ISNULL(@CLOCID,'')=''
	 BEGIN
		SET @CERRORMSG =' LOCATION ID CAN NOT BE BLANK  '  
		RETURN  
	 END


    DECLARE @NSTEP NUMERIC(10,0)
   INSERT IMPORT_INFO VALUES (0,GETDATE())  
     
     SET @NSTEP=00
   PRINT 'IMPORT MASTERS-START0'  
   BEGIN TRY    
    
    --HANDLE NULL VALUE IN EXCEL IMPORT TABLE
    SET @DTSQL=''
    SELECT @DTSQL=COALESCE(@DTSQL,'')+'UPDATE '+@CTABLENAME+' SET '+LTRIM(RTRIM(COLUMN_NAME))+'='''' WHERE '+LTRIM(RTRIM(COLUMN_NAME))+' IS NULL;'+CHAR(13) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME=@CTABLENAME AND COLUMN_NAME LIKE 'ATTR%KEY_NAME'
    SET @DTSQL=ISNULL(@DTSQL,'')
    IF @DTSQL<>'' EXEC(@DTSQL)
    --HANDLE NULL VALUE IN EXCEL IMPORT TABLE
    
    SET @NSTEP=01
    --   article_fix_attr
    SET @DTSQL=' INSERT article_fix_attr ( article_code, attr1_key_code, attr2_key_code, attr3_key_code, attr4_key_code, attr5_key_code, attr6_key_code, attr7_key_code, attr8_key_code, attr9_key_code, attr10_key_code, attr11_key_code, attr12_key_code, attr13_key_code, attr14_key_code, attr15_key_code, attr16_key_code, attr17_key_code, attr18_key_code, attr19_key_code, attr20_key_code, attr21_key_code, attr22_key_code, attr23_key_code, attr24_key_code, attr25_key_code ) 
     SELECT DISTINCT  ART.article_code,''0000000'' AS  attr1_key_code,''0000000'' AS  attr2_key_code, 
     ''0000000'' AS attr3_key_code,''0000000'' AS  attr4_key_code,''0000000'' AS  attr5_key_code,''0000000'' AS  attr6_key_code, 
     ''0000000'' AS attr7_key_code,''0000000'' AS  attr8_key_code,''0000000'' AS  attr9_key_code,''0000000'' AS  attr10_key_code,''0000000'' AS  attr11_key_code,''0000000'' AS  attr12_key_code,''0000000'' AS  attr13_key_code, 
     ''0000000'' AS attr14_key_code,''0000000'' AS  attr15_key_code,''0000000'' AS  attr16_key_code,''0000000'' AS  attr17_key_code,
     ''0000000'' AS  attr18_key_code,''0000000'' AS  attr19_key_code,''0000000'' AS  attr20_key_code, ''0000000'' AS attr21_key_code, 
     ''0000000'' AS attr22_key_code,''0000000'' AS  attr23_key_code,''0000000'' AS  attr24_key_code,''0000000'' AS  attr25_key_code 
     FROM '+@CTABLENAME+' A
     JOIN ARTICLE ART ON A.ARTICLE_NO=ART.ARTICLE_NO
     LEFT JOIN article_fix_attr B ON ART.ARTICLE_CODE=B.ARTICLE_CODE
     WHERE B.ARTICLE_CODE IS NULL
     '
     PRINT @DTSQL
     EXEC SP_EXECUTESQL @DTSQL
     
     
       
       SET @NSTEP=10
       IF OBJECT_ID ('TEMPDB..#TMPTABLEDET','U') IS NOT NULL
        DROP TABLE #TMPTABLEDET
    
     PRINT 'IMPORT TABLE WITH COLUMN NAME 1'  
         
      SELECT DISTINCT  a.COLUMN_NAME,REPLACE(a.COLUMN_NAME,'KEY_NAME','MST') AS TABLE_NAME,  
     REPLACE(a.COLUMN_NAME,'KEY_NAME','KEY_CODE') AS COLUMN_CODE  
     INTO #TMPTABLEDET  
     FROM INFORMATION_SCHEMA .COLUMNS A with (NOLOCK) 
     JOIN config_attr B (nolock) on REPLACE(a.COLUMN_NAME,'KEY_NAME','MST') =b.table_name 
     WHERE LEFT(a.COLUMN_NAME,4)='ATTR'  
     AND RIGHT(a.COLUMN_NAME,8)='KEY_NAME'   
     AND (a.TABLE_NAME  =@CTABLENAME or '['+a.TABLE_NAME+']'=@CTABLENAME)  
     and  ISNULL( b.table_caption,'') <>''
     
	

      SET @NSTEP=20
      IF OBJECT_ID ('TEMPDB..#TMPKEYSNAME','U') IS NOT NULL
		 DROP TABLE #TMPKEYSNAME
      
      
      SELECT ARTICLE_NO=CAST('' AS VARCHAR(300)),ARTICLE_CODE=CAST('' AS VARCHAR(100)) ,
      KEY_NAME=CAST('' AS VARCHAR(500)) ,KEY_CODE =CAST('' AS VARCHAR(100)) 
      INTO #TMPKEYSNAME
      WHERE 1=2
  
  
 
     SET @NSTEP=30
     WHILE EXISTS(SELECT TOP 1 'U' FROM #TMPTABLEDET)
     BEGIN
     
		 SELECT TOP 1 @CCOLUMN_NAME=COLUMN_NAME,@CMSTTABLENAME=TABLE_NAME ,@CCOLUMN_CODE=COLUMN_CODE  
		 FROM #TMPTABLEDET
		 ORDER BY COLUMN_NAME
		 
		  
		 DELETE FROM #TMPKEYSNAME
		
		SET @NSTEP=40
        SET @DTSQL=' INSERT INTO #TMPKEYSNAME(ARTICLE_NO,ARTICLE_CODE,KEY_NAME,KEY_CODE)
        SELECT DISTINCT  A.ARTICLE_NO ,ART.ARTICLE_CODE,'+@CCOLUMN_NAME+','''' AS KEY_CODE
        FROM '+@CTABLENAME+' A 
        JOIN ARTICLE ART ON ART.ARTICLE_NO=A.ARTICLE_NO'
        PRINT '40 '+@DTSQL
        EXEC SP_EXECUTESQL @DTSQL
        
  
      
     
        SET @NSTEP=50
        PRINT 'UPDATE KEY CODE ALREADY AVAILABLE NAME 2' 
     
        SET @DTSQL='UPDATE A SET KEY_CODE=B.'+@CCOLUMN_CODE+'
        FROM #TMPKEYSNAME A
        JOIN '+@CMSTTABLENAME +' B ON isnull(A.KEY_NAME,'''')=B.'+@CCOLUMN_NAME+''
        PRINT '50 '+@DTSQL
        EXEC SP_EXECUTESQL @DTSQL
         
       
   
        --SET @NSTEP=60
        --SET @DTSQL='UPDATE A SET '+@CCOLUMN_CODE+'=B.KEY_CODE  FROM article_fix_attr A
        --JOIN #TMPKEYSNAME B ON A.ARTICLE_CODE=B.ARTICLE_CODE
        --WHERE ISNULL(B.KEY_CODE,'''')<>''''  '
        --PRINT '60 '+@DTSQL
		
        --EXEC SP_EXECUTESQL @DTSQL
        
        
        
        
        PRINT 'GENRATE NEW KEY CODE 3' 
        
        IF OBJECT_ID('TEMPDB..#TMPATTR_KEY','U') IS NOT NULL      
         DROP TABLE #TMPATTR_KEY  
         
         SELECT DISTINCT  KEY_NAME ,KEY_CODE  
         INTO #TMPATTR_KEY
         FROM #TMPKEYSNAME A  
         WHERE ISNULL(KEY_CODE,'')=''



		 IF ISNULL(@DO_NOT_CREATE_ARTICLE,'')='1'  
		 BEGIN  

		     IF EXISTS (SELECT TOP 1'U' FROM #TMPKEYSNAME A  WHERE ISNULL(KEY_CODE,'')='')
			 begin
				
				   select @CNEWATTR=key_name from #TMPKEYSNAME   WHERE ISNULL(KEY_CODE,'')=''
				   SET @CERRORMSG='You can not create new attribute :'+@CNEWATTR+': in,'  +@CMSTTABLENAME +' due to donot create article is Active in config  '
			       RETURN 
			  
			 end
			
		 END  

		  SET @DO_NOT_CREATE_ATTRMST=''
		  IF EXISTS (SELECT TOP 1'U' FROM #TMPKEYSNAME A  WHERE ISNULL(KEY_CODE,'')='')
		  begin
		       
               SELECT @DO_NOT_CREATE_ATTRMST=VALUE FROM CONFIG WHERE CONFIG_OPTION='DO_NOT_CREATE_'+RTRIM(LTRIM(@CMSTTABLENAME))+'_MASTERS_IN_FILE_IMPORT'

			   IF ISNULL(@DO_NOT_CREATE_ATTRMST,'')='1'
			   BEGIN
			         select top 1 @CNEWATTR=key_name from #TMPKEYSNAME   WHERE ISNULL(KEY_CODE,'')='' 
					  SET @CERRORMSG='You can not create new attribute :'+@CNEWATTR+': in,'  +@CMSTTABLENAME +' due to donot create' +RTRIM(LTRIM(@CMSTTABLENAME))+' is Active in config  '
			       RETURN 
			   END

			  
		  end
		

         
         
     IF EXISTS (SELECT TOP 1 'U' FROM #TMPATTR_KEY)
     BEGIN    
         
         SET @NSTEP=70
         
          SELECT @UPDATEVALUE = 0,@UPDATEVALUE1 = 0,@UPDATEVALUE2 = 0   
            
          SELECT @UPDATEVALUE1 = ISNULL(MAX(CONVERT(NUMERIC,SUBSTRING(LASTKEYVAL,3,LEN(LASTKEYVAL)))),0) FROM       
          KEYS WHERE TABLENAME=@CMSTTABLENAME  AND COLUMNNAME=@CCOLUMN_CODE      
          AND LEN(LASTKEYVAL)=7  
          
          SET @DTSQL=' SELECT @UPDATEVALUE2 = MAX(ISNULL(CONVERT(NUMERIC,SUBSTRING('+@CCOLUMN_CODE+',3,LEN(LTRIM(RTRIM('+@CCOLUMN_CODE+'))))),0))       
           FROM  '+@CMSTTABLENAME +'  WHERE LEN('+@CCOLUMN_CODE+')=7  
          '
          EXEC SP_EXECUTESQL @DTSQL,N'@UPDATEVALUE2 NUMERIC(10,0) OUTPUT',@UPDATEVALUE2=@UPDATEVALUE2 OUTPUT
          PRINT @DTSQL
            
           IF ISNULL(@UPDATEVALUE1,0)>ISNULL(@UPDATEVALUE2,0)      
			 SET @UPDATEVALUE=ISNULL(@UPDATEVALUE1,0)      
		   ELSE      
			 SET @UPDATEVALUE=ISNULL(@UPDATEVALUE2,0)   
		
		   SET @NSTEP=80
		   SET @BLOOP=0  
		   WHILE @BLOOP=0  
		   BEGIN    
	 
				UPDATE #TMPATTR_KEY SET KEY_CODE = @CLOCID+REPLICATE('0',5-LEN(LTRIM(STR(@UPDATEVALUE))))+LTRIM(STR(@UPDATEVALUE)),      
				@UPDATEVALUE = @UPDATEVALUE + 1   
				   
				IF NOT EXISTS (SELECT TOP 1 A.KEY_CODE FROM #TMPATTR_KEY A WHERE KEY_CODE='')  
				SET @BLOOP=1             
		   END  
		   
		 
             
             SET @NSTEP=90
             
             
             SET @DTSQL=' INSERT INTO '+@CMSTTABLENAME+'('+@CCOLUMN_NAME+','+@CCOLUMN_CODE +')
             SELECT DISTINCT  A.KEY_NAME AS KEY_NAME,A.KEY_CODE AS  KEY_CODE
             FROM #TMPATTR_KEY A 
             LEFT JOIN '+@CMSTTABLENAME+' B  ON A.KEY_CODE=B.'+@CCOLUMN_CODE+'
             WHERE B.'+@CCOLUMN_CODE+' IS NULL and isnull(A.KEY_NAME,'''')<>'''' '
             PRINT @DTSQL
             EXEC SP_EXECUTESQL @DTSQL
            --MOVE OUTSIDE FROM HERE 
			
			--SELECT @CMSTTABLENAME
             
     END
     
     
     
     UPDATE A SET KEY_CODE =B.KEY_CODE  FROM #TMPKEYSNAME A
     JOIN #TMPATTR_KEY B ON A.KEY_NAME =B.KEY_NAME 
     WHERE ISNULL(A.KEY_CODE,'') =''
     
     
     --MOVE OUTSIDE FROM ABOVE
	 --THIS WAS IN CREATE MODE FOR EXISTING ATTR CODE THE TABLE WAS NOT UPDATING 5 FEB 2018
	 SET @DTSQL='UPDATE A SET '+@CCOLUMN_CODE+'=B.KEY_CODE  FROM article_fix_attr A
	      JOIN #TMPKEYSNAME B ON A.ARTICLE_CODE=B.ARTICLE_CODE
	   	  WHERE ISNULL(B.KEY_CODE,'''')<>''''  '
	 PRINT @DTSQL
	 EXEC SP_EXECUTESQL @DTSQL

     DELETE FROM #TMPTABLEDET WHERE COLUMN_NAME =@CCOLUMN_NAME
     
   END
 

  END TRY    
     
 BEGIN CATCH    
  SET @CERRORMSG = 'ERROR IN UPDATING MASTERS (SP_GETMASTERS_ATTR_NEW) AT STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()    
    SELECT @CERRORMSG errmsg
 END CATCH      
END

