CREATE PROCEDURE DBKPI_FILTER_EXPRESSION  
(  
 @nMODE INT =1,  
 @cFilterName varchar(MAX)='',  
 @cSetupName varchar(MAX)='',  
 @cExpression varchar(MAX) ='',  
 @cSetupID varchar(MAX)='',
 @cDashBoardMode INT=1 
)  
AS  
BEGIN  
   SET NOCOUNT ON    
   DECLARE @ERR VARCHAR(MAX)='',@SUB VARCHAR(MAX),@Filter_Criteria VARCHAR(MAX)='(',@Filter_Description VARCHAR(MAX)='('
   ,@TMP VARCHAR(MAX),@IN BIT=0,@CTR INT=0
   ,@FIELD VARCHAR(MAX)='',@FIELD_DESC VARCHAR(MAX)=''
   ,@OPERATOR VARCHAR(100),@OPERATOR2 VARCHAR(100)
   ,@VAL VARCHAR(MAX)='',@V1 INT=0,@V2 INT=0
   ,@CONNECT VARCHAR(100)='',@cRawFilterExpression VARCHAR(MAX)
   ,@cRawPara VARCHAR(MAX)
    
    IF @nMode=11--SAVE PRICE CATEGORY
       BEGIN
         BEGIN TRY  
		 BEGIN TRAN
		    SET @cFilterName='POS_DB_PRICECATEGORY'
            IF ISNULL(@cSetupName,'')='' SET @ERR='No setup name provided'
            IF @ERR!=''
               BEGIN
                 ROLLBACK TRAN
                 GOTO EXT
               END  
		   	--PICK EXISTING SETUP_ID
		   	SELECT TOP 1 @cSetupID=setup_id FROM POS_DYNAMIC_DASHBOARD_SETUP (NOLOCK) WHERE REPLACE(RAW_PARA,'PRICE_CATEGORY;','')='PRICE_CATEGORY'
		   	--OTHERWISE GENERATE SETUP_ID
		   	IF LTRIM(RTRIM(UPPER(ISNULL(@cSetupID,'')))) IN ('','LATER')
	           BEGIN  
			      SELECT @cSetupID=MAX(setup_id) FROM POS_DYNAMIC_DASHBOARD_SETUP (NOLOCK) WHERE setup_id LIKE 'KPI%'  
			      IF ISNULL(@cSetupID,'')=''  
			         SET @cSetupID='KPI0000'       
			      SET @cSetupID='KPI'+RIGHT('0000'+CONVERT(VARCHAR,CONVERT(INT,RIGHT(@cSetupID,4))+1),4)   
		       END  
            IF LTRIM(RTRIM(UPPER(ISNULL(@cSetupID,'')))) IN ('','LATER')
               BEGIN
                 SET @ERR='SetupID not generated'
                 ROLLBACK TRAN
                 GOTO EXT
               END  
       		--
			SET @cRawFilterExpression=@cExpression
		    SET @cRawPara='PRICE_CATEGORY;'+@cFilterName
		    PRINT 'Setup ID '+@cSetupID
		    DELETE POS_DYNAMIC_DASHBOARD_SETUP WHERE SETUP_ID=@cSetupID
       		INSERT POS_DYNAMIC_DASHBOARD_SETUP(SETUP_ID,PARA_NAME,FILTER_CRITERIA,FILTER_DESCRIPTION,SETUP_NAME,RAW_FILTER_EXPR,RAW_PARA,LAST_UPDATE)  
            SELECT @cSetupID,@cFilterName,'N.A.','N.A.',UPPER(@cSetupName),@cRawFilterExpression,@cRawPara,GETDATE()  
            DELETE POS_DB_PRICECATEGORY WHERE SETUP_ID=@cSetupID
            SET @cExpression=LTRIM(RTRIM(@cExpression))
            IF RIGHT(@cExpression,1)<>';' SET @cExpression+=';'
            --PRINT '0='+@cExpression
            WHILE CHARINDEX(';',@cExpression)>0
               BEGIN
                 SET @SUB=LEFT(@cExpression,CHARINDEX(';',@cExpression)-1)
                 SET @FIELD=LEFT(@SUB,CHARINDEX(',',@SUB)-1)--CATEGORY_NAME
                 SET @SUB=SUBSTRING(@SUB,CHARINDEX(',',@SUB)+1,4000)
                 SET @FIELD_DESC=LEFT(@SUB,CHARINDEX(',',@SUB)-1)--MRP_FROM
                 SET @SUB=SUBSTRING(@SUB,CHARINDEX(',',@SUB)+1,4000)--MRP_TO(LEFT)
                 IF EXISTS(SELECT TOP 1 * FROM POS_DB_PRICECATEGORY WHERE SETUP_ID=@cSetupID AND (@FIELD_DESC BETWEEN mrp_from AND mrp_to OR @SUB BETWEEN mrp_from AND mrp_to))
                    BEGIN
					  DELETE POS_DB_PRICECATEGORY WHERE SETUP_ID=@cSetupID
					  SET @ERR='One of range is overlapping'
					  BREAK
					END 
                 INSERT POS_DB_PRICECATEGORY(SETUP_ID,CATEGORY_NAME,MRP_FROM,MRP_TO) 
                 SELECT @cSetupID,@FIELD,@FIELD_DESC,@SUB
                 --REST OF Expression
                 SET @cExpression=SUBSTRING(@cExpression,CHARINDEX(';',@cExpression)+1,4000)
               END
            IF NOT EXISTS(SELECT * FROM POS_DB_PRICECATEGORY WHERE SETUP_ID=@cSetupID)   
               DELETE POS_DYNAMIC_DASHBOARD_SETUP WHERE SETUP_ID=@cSetupID
         END TRY  
           
         BEGIN CATCH  
           SET @ERR=ERROR_MESSAGE()  
         END CATCH  
           
         IF ISNULL(@ERR,'')=''  
            COMMIT TRAN  
         ELSE  
            ROLLBACK TRAN      
       END--@nMode=11
       
       
    IF @nMode=1--SAVE OTHEN THAN PRICE CATEGORY
       BEGIN  
         BEGIN TRY  
		 BEGIN TRAN  
		    SET @cRawFilterExpression=@cExpression
		    SET @cRawPara=@cFilterName
		    IF EXISTS(SELECT TOP 1 * FROM POS_DYNAMIC_DASHBOARD_SETUP (NOLOCK) WHERE SETUP_NAME=@cSetupName)
		       BEGIN
		         SELECT TOP 1 @cSetupID=Setup_ID FROM POS_DYNAMIC_DASHBOARD_SETUP (NOLOCK) WHERE SETUP_NAME=@cSetupName
		         DELETE POS_DYNAMIC_DASHBOARD_SETUP WHERE SETUP_NAME=@cSetupName
		       END  
		    IF @cFilterName NOT LIKE '%SECTION%' OR @cFilterName NOT LIKE '%ARTICLE%'
		       SELECT TOP 1 @cFilterName=CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION LIKE 'PARA[1-6]_caption' AND value=@cFilterName
		    --SELECT @cFilterName cFilterName   ,@cRawFilterExpression XPRESS
			IF @cExpression=''  
               BEGIN
                 SELECT @Filter_Criteria=''
                 ,@Filter_Description=''
                 ,@cFilterName=CASE WHEN @cFilterName='SECTION' THEN 'SECTION_NAME' 
									WHEN @cFilterName='SUB SECTION' THEN 'SUB_SECTION_NAME' 
									WHEN @cFilterName='SUPPLIER' THEN 'AC_NAME' 
									WHEN @cFilterName='DEPT ID' THEN 'DEPT_ID' 
									WHEN @cFilterName='DEPT NAME' THEN 'DEPT_NAME' 
									WHEN @cFilterName='ARTICLE NO' THEN 'ARTICLE_NO' 
									WHEN @cFilterName LIKE 'PARA%' THEN REPLACE(@cFilterName,'_caption','')+'_NAME' ELSE @cFilterName END
                 GOTO SAV
               END   
			SET @V1=CHARINDEX(',',@cExpression,CHARINDEX(',',@cExpression)+1)  
			SET @V2=CHARINDEX(',',@cExpression,@V1+1)      
			SET @VAL=SUBSTRING(@cExpression,@V1+1,@V2-@V1-1)  
			SET @V1=0  
 
			IF @cExpression<>'' AND RIGHT(RTRIM(@cExpression),1)<>';'  
			   SET @cExpression=RTRIM(@cExpression)+';'  
			--PRINT 'PARAM = '+@cExpression+CHAR(13)+REPLICATE('*',100)+CHAR(13)  
		    WHILE CHARINDEX(';',@cExpression)>0  
			 BEGIN  
				SET @V1=CHARINDEX(',',@cExpression,CHARINDEX(',',@cExpression)+1)  
				SET @V2=CHARINDEX(',',@cExpression,@V1+1)      
				SET @VAL=SUBSTRING(@cExpression,@V1+1,@V2-@V1-1)  
				SET @VAL=''''+REPLACE(@VAL,'+',''',''')+''''
				SET @V1=0  
				SET @SUB=REPLACE(LEFT(@cExpression,CHARINDEX(';',@cExpression)),';',',')  
				SET @FIELD_DESC=LEFT(@SUB,CHARINDEX(',',@SUB)-1)
				SET @SUB=SUBSTRING(@SUB,LEN(@FIELD_DESC)+2,8000)
				SET @cFilterName=CASE WHEN @cFilterName='SECTION' THEN 'SECTION_NAME' 
										WHEN @cFilterName='SUB SECTION' THEN 'SUB_SECTION_NAME' 
										WHEN @cFilterName='ARTICLE NO' THEN 'ARTICLE_NO' 
										WHEN @cFilterName='SUPPLIER' THEN 'AC_NAME' 
									    WHEN @cFilterName='DEPT NAME' THEN 'DEPT_NAME' 
									    WHEN @cFilterName='DEPT ID' THEN 'DEPT_ID' 
										WHEN @cFilterName LIKE 'PARA%' THEN REPLACE(@cFilterName,'_caption','')+'_NAME' 
										ELSE @cFilterName END
				SET @FIELD=CASE WHEN @FIELD_DESC='SECTION' THEN 'SECTION_NAME' 
								WHEN @FIELD_DESC='SUB SECTION' THEN 'SUB_SECTION_NAME' 
								WHEN @FIELD_DESC='ARTICLE NO' THEN 'ARTICLE_NO' 
								WHEN @FIELD_DESC='ARTICLE NO' THEN 'ARTICLE_NO' 
								WHEN @FIELD_DESC='DEPT NAME' THEN 'DEPT_NAME'
								WHEN @FIELD_DESC='DEPT ID' THEN 'DEPT_ID'
								WHEN @FIELD_DESC='SUPPLIER' THEN 'AC_NAME' 
								WHEN @FIELD_DESC LIKE 'PARA%' THEN REPLACE(@FIELD_DESC,' ','')+'_NAME' ELSE @FIELD_DESC END
				PRINT @FIELD
				PRINT @FIELD_DESC
				SET @OPERATOR=LEFT(@SUB,CHARINDEX(',',@SUB)-1)
				SET @OPERATOR2=@OPERATOR
				SET @SUB=SUBSTRING(@SUB,LEN(@OPERATOR)+2,8000)
				SET @OPERATOR=CASE @OPERATOR WHEN '=' THEN ' IN (' WHEN '<>' THEN ' NOT IN (' ELSE @OPERATOR END
				SET @TMP=LEFT(@SUB,CHARINDEX(',',@SUB)-1)
				SET @SUB=SUBSTRING(@SUB,LEN(@TMP)+2,8000)
				SET @TMP=''''+REPLACE(@TMP,'+',''',''')+''''
				SET @CONNECT=REPLACE(@SUB,',','')
				SET @CONNECT=CASE @CONNECT WHEN 0 THEN ' OR ' WHEN 1 THEN ' AND ' END
				SET @VAL=UPPER(@VAL)
				SET @Filter_Criteria+=@FIELD+@OPERATOR+@VAL+CASE @OPERATOR WHEN ' IN (' THEN ')' ELSE '' END
				SET @Filter_Description+=@FIELD_DESC+@OPERATOR2+REPLACE(REPLACE(@VAL,'''',''),',',' OR ')+CASE @OPERATOR WHEN ' IN (' THEN ')' ELSE '' END
				
				--NEXT
				SET @cExpression=SUBSTRING(@cExpression,CHARINDEX(';',@cExpression)+1,8000)
				IF @Filter_Criteria<>'' 
					IF @cExpression<>'' 
						SET @Filter_Criteria+=CASE LTRIM(RTRIM(@CONNECT)) WHEN 'AND' THEN @CONNECT WHEN 'OR' THEN ') OR (' END 
					ELSE
						SET @Filter_Criteria+=')'
				IF @Filter_Description<>'' 
					IF @cExpression<>'' 
						SET @Filter_Description+=CASE LTRIM(RTRIM(@CONNECT)) WHEN 'AND' THEN @CONNECT WHEN 'OR' THEN ' OR ((' END 
					ELSE
						SET @Filter_Description+=')'
				--SELECT @Filter_Criteria Filter_Criteria,@cExpression cExpression 
			 END--WHILE		
		    SAV:
		    SELECT @cSetupID=SETUP_ID FROM POS_DYNAMIC_DASHBOARD_SETUP(NOLOCK) WHERE SETUP_NAME=@cSetupName  
		    IF LTRIM(RTRIM(UPPER(ISNULL(@cSetupID,'')))) IN ('','LATER')  
	           BEGIN  
			      SELECT @cSetupID=MAX(setup_id) FROM POS_DYNAMIC_DASHBOARD_SETUP (NOLOCK) WHERE setup_id LIKE 'KPI%'  
			      IF ISNULL(@cSetupID,'')=''  
			         SET @cSetupID='KPI0000'       
			      SET @cSetupID='KPI'+RIGHT('0000'+CONVERT(VARCHAR,CONVERT(INT,RIGHT(@cSetupID,4))+1),4)   
		       END  
            IF ISNULL(@cSetupName,'')=''  
               SET @ERR='No setup name provided'  
            IF @ERR!=''  
               BEGIN
                 ROLLBACK TRAN
                 GOTO EXT  
               END  
            IF @Filter_Criteria LIKE '%SYSTEM.COLLECTIONS%' OR @Filter_Criteria LIKE '%WIZMD.MODELS.%'        
               SET @ERR='Rejected! Invalid value being saving'  
			IF @ERR!=''  
               BEGIN
                 ROLLBACK TRAN
                 GOTO EXT  
               END  
			IF @Filter_Criteria<>''
			   SET @Filter_Criteria='('+@Filter_Criteria+')'  
			SET @cFilterName=REPLACE(@cFilterName,'_NAME_NAME','_NAME')   
			INSERT POS_DYNAMIC_DASHBOARD_SETUP(SETUP_ID,PARA_NAME,FILTER_CRITERIA,FILTER_DESCRIPTION,SETUP_NAME,RAW_FILTER_EXPR,RAW_PARA,LAST_UPDATE,Dashboard_Mode)  
            SELECT @cSetupID,UPPER(@cFilterName),@Filter_Criteria,@Filter_Description,UPPER(@cSetupName),@cRawFilterExpression,@cRawPara,GETDATE() ,@cDashBoardMode 
         END TRY  
           
         BEGIN CATCH  
           SET @ERR=ERROR_MESSAGE()  
         END CATCH  
           
         IF ISNULL(@ERR,'')=''  
            COMMIT TRAN  
         ELSE  
            ROLLBACK TRAN      
       END--@nMode=1  
        
    IF @nMode=2  --FETCH
       BEGIN  
         SET @ERR=''
         IF @cSetupID=''  
            SET @ERR=''--'No SetupID passed to get the filter'  
         IF @ERR!=''  
            GOTO EXT  
		 SELECT SETUP_ID,PARA_NAME,FILTER_CRITERIA,FILTER_DESCRIPTION,SETUP_NAME 
		 FROM POS_DYNAMIC_DASHBOARD_SETUP S(NOLOCK)
		 WHERE (ISNULL(Setup_ID,'')=@cSetupName OR @cSetupName='') AND Dashboard_Mode=@cDashBoardMode 
       END  
         
    IF @nMode=3 --DELETE 
       BEGIN  
         SET @ERR=''
         IF ISNULL(@cSetupID,'')=''  
            SET @ERR='No SetupID provided to delete'  
         IF @ERR!=''  
            GOTO EXT  
		 DELETE FROM POS_DYNAMIC_DASHBOARD_SETUP WHERE Setup_ID=@cSetupID
		 DELETE FROM POS_DB_PRICECATEGORY WHERE Setup_ID=@cSetupID
       END  

    IF @nMode=4  --FETCH RAW FILTER
       BEGIN  
         SET @ERR=''
         IF ISNULL(@cSetupID,'')=''  
            SET @ERR='No SetupID provided'  
         IF @ERR!=''  
            GOTO EXT  
         IF OBJECT_ID('tempdb..#SETUP') IS NOT NULL DROP TABLE #SETUP
         CREATE TABLE #SETUP(SNo int,SetupID varchar(100),SetupName varchar(999),Para varchar(999),Filter varchar(999),FilterOp varchar(999),FilterVal varchar(999),FilterJoin varchar(100))
		 SELECT TOP 1 @V1=0
		 ,@cRawFilterExpression=ISNULL(RAW_FILTER_EXPR,'')
		 ,@cFilterName=setup_name
		 ,@cRawPara=ISNULL(Raw_Para,'') 
		 FROM POS_DYNAMIC_DASHBOARD_SETUP WHERE Setup_ID=@cSetupID
		 
		 IF EXISTS(SELECT TOP 1 * FROM POS_DB_PRICECATEGORY (NOLOCK) WHERE Setup_ID=@cSetupID)
		    GOTO PC
		       
		 IF CHARINDEX(';',@cRawFilterExpression)=0
		    INSERT #SETUP
		    SELECT 1,@cSetupID,@cFilterName,@cRawPara,ISNULL(@FIELD_DESC,''),ISNULL(@OPERATOR,''),ISNULL(@VAL,''),ISNULL(@CONNECT,'')
		 
		 WHILE CHARINDEX(';',@cRawFilterExpression)>0
		   BEGIN
		      SET @TMP=LEFT(@cRawFilterExpression,CHARINDEX(';',@cRawFilterExpression)-1)
		      SET @FIELD_DESC=LEFT(@TMP,CHARINDEX(',',@TMP)-1)
		      SET @TMP=SUBSTRING(@TMP,CHARINDEX(',',@TMP)+1,4000)
			  SET @OPERATOR=LEFT(@TMP,CHARINDEX(',',@TMP)-1)
		      SET @TMP=SUBSTRING(@TMP,CHARINDEX(',',@TMP)+1,4000)
			  SET @VAL=REPLACE(LEFT(@TMP,CHARINDEX(',',@TMP)-1),'+',',')
		      SET @TMP=SUBSTRING(@TMP,CHARINDEX(',',@TMP)+1,4000)
			  SET @CONNECT=CASE @TMP WHEN 1 THEN 'AND' WHEN 0 THEN 'OR' ELSE '' END
			  SET @V1+=1
		      INSERT #SETUP
		      SELECT @V1,@cSetupID,@cFilterName,@cRawPara,@FIELD_DESC,@OPERATOR,@VAL,@CONNECT
		      SET @cRawFilterExpression=SUBSTRING(@cRawFilterExpression,CHARINDEX(';',@cRawFilterExpression)+1,4000)
		   END
		 PC:  
		 SELECT SetupID,SetupName,Para,Filter,FilterOp,FilterVal,FilterJoin FROM #SETUP ORDER BY SNo
       END  


    IF @nMode=21  --FETCH:PRICE_CATEGORY
       BEGIN  
         SET @ERR=''
         IF @cSetupID=''  
            SET @ERR=''--'No SetupID passed to get the filter'
         IF @ERR!=''  
            GOTO EXT  
		 
		 SELECT PC.SETUP_ID,S.PARA_NAME,S.FILTER_CRITERIA,S.FILTER_DESCRIPTION,S.SETUP_NAME,PC.MRP_FROM,PC.MRP_TO,PC.CATEGORY_NAME 
		 FROM POS_DB_PRICECATEGORY PC (NOLOCK)
		 JOIN POS_DYNAMIC_DASHBOARD_SETUP S (NOLOCK) ON S.Setup_ID=PC.Setup_ID
		 WHERE ISNULL(S.Setup_ID,'')=@cSetupName
       END  

    IF @nMode=22  --FETCH Standard
       BEGIN  
         SET @ERR=''
         IF @cSetupID='' SET @ERR=''
         IF @ERR!=''  
            GOTO EXT  
		 SELECT SETUP_ID,PARA_NAME,FILTER_CRITERIA,FILTER_DESCRIPTION,SETUP_NAME 
		 FROM POS_DYNAMIC_DASHBOARD_SETUP
		 WHERE (ISNULL(SETUP_ID,'')=@cSetupName OR @cSetupName='') AND SETUP_ID LIKE 'SKPI%'
       END  

    EXT:     
    SELECT @ERR ERROR_MSG,CASE ISNULL(@ERR,'') WHEN '' THEN 'SUCCESS' ELSE 'FAILED' END [STATUS]  
 SET NOCOUNT OFF  
END 