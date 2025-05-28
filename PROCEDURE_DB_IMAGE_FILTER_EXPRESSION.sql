CREATE PROCEDURE DB_IMAGE_FILTER_EXPRESSION  
(    
 @nMODE INT =1,    
 @cFilterName varchar(MAX)='',    
 @cSetupName varchar(MAX)='',    
 @cExpression varchar(MAX) ='',    
 @cSetupID varchar(MAX)=''    
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
     
      
   IF @nMode=1--SAVE OTHEN THAN PRICE CATEGORY  
       BEGIN    
         BEGIN TRY    
   BEGIN TRAN    
      SET @cRawFilterExpression=@cExpression  
      SET @cRawPara=@cFilterName  
      DELETE Image_Dashboard_Setup  
      IF @cFilterName NOT LIKE '%SECTION%'   
      OR @cFilterName NOT LIKE '%ARTICLE%'   
      OR @cFilterName NOT LIKE 'DEPT%'   
      OR @cFilterName NOT LIKE 'SUPPLIER%'  
         OR @cFilterName NOT LIKE '%MRP%'  
         OR @cFilterName NOT LIKE '%IMAGE%'  
         OR @cFilterName NOT LIKE '%QTY'  
         SELECT TOP 1 @cFilterName=CONFIG_OPTION FROM CONFIG WHERE  CONFIG_OPTION LIKE 'PARA[1-6]'+'_caption' AND value=@cFilterName  
           
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
         WHEN @cFilterName='SUPPLIER' THEN 'LM01106'  
         WHEN @cFilterName='MRP' THEN 'SKU'  
         WHEN @cFilterName='IMAGE' THEN 'IMAGE_INFO'  
         WHEN @cFilterName='CBS QTY' THEN 'PMT01106'  
         WHEN @cFilterName='SLS QTY' THEN 'CMD01106'  
         WHEN @cFilterName LIKE 'PARA%' THEN REPLACE(@cFilterName,' ','')+'_NAME' ELSE @cFilterName END  
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
          WHEN @cFilterName='MRP' THEN 'MRP'  
          WHEN @cFilterName='IMAGE' THEN 'IMAGE_NAME'  
          WHEN @cFilterName='CBS QTY' THEN 'CBS_QTY'  
          WHEN @cFilterName='SLS QTY' THEN 'SLS_QTY'  
          WHEN @cFilterName LIKE 'PARA%' THEN REPLACE(@cFilterName,' ','')+'_NAME'   
          ELSE @cFilterName END  
    SET @FIELD=CASE WHEN @FIELD_DESC='SECTION' THEN 'SECTION_NAME'   
        WHEN @FIELD_DESC='SUB SECTION' THEN 'SUB_SECTION_NAME'   
        WHEN @FIELD_DESC='ARTICLE NO' THEN 'ARTICLE_NO'   
        WHEN @FIELD_DESC='ARTICLE NO' THEN 'ARTICLE_NO'   
        WHEN @FIELD_DESC='DEPT NAME' THEN 'DEPT_NAME'  
        WHEN @FIELD_DESC='DEPT ID' THEN 'DEPT_ID'  
        WHEN @FIELD_DESC='SUPPLIER' THEN 'AC_NAME'   
        WHEN @FIELD_DESC='MRP' THEN 'MRP'  
        WHEN @FIELD_DESC='IMAGE' THEN 'IMAGE_NAME'  
        WHEN @FIELD_DESC='CBS QTY' THEN 'CBS_QTY'  
        WHEN @FIELD_DESC='SLS QTY' THEN 'SLS_QTY'  
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
      SELECT @cSetupID='IMG0001'  
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
   INSERT Image_Dashboard_Setup(Image_FilterID,Filter_Criteria    ,Filter_Description  ,Image_FilterName   ,RawFilterExpr        ,LastUpdate)    
            SELECT       @cSetupID    ,@Filter_Criteria   ,@Filter_Description ,'ImageFilter'      ,@cRawFilterExpression,GETDATE()    
         END TRY    
             
         BEGIN CATCH    
           SET @ERR=ERROR_MESSAGE()    
         END CATCH    
             
         IF ISNULL(@ERR,'')=''    
            COMMIT TRAN    
         ELSE    
            ROLLBACK TRAN        
       END--@nMode=1    
   
    EXT:       
    SELECT @ERR ERROR_MSG,CASE ISNULL(@ERR,'') WHEN '' THEN 'SUCCESS' ELSE 'FAILED' END [STATUS]    
 SET NOCOUNT OFF    
END 