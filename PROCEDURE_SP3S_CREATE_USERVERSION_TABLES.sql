CREATE PROCEDURE SP3S_CREATE_USERVERSION_TABLES   
@nMode INT,
@cUserCodePara CHAR(7)
AS  
BEGIN  
 DECLARE @cCmd NVARCHAR(MAX),@cTableName VARCHAR(200),@cUserTableName VARCHAR(200),  
 @cModuleName VARCHAR(200),@cErrormsg VARCHAR(MAX),@cStep VARCHAR(5),@bCreateUserProc BIT 
  
BEGIN TRY  
	   
	 SET @cStep='10'  
	 SET @bCreateUserProc=0

     IF EXISTS (SELECT TOP 1 user_code from xntype_userprocversion_log WHERE user_code=@cUserCodePara)
		GOTO END_PROC
	 
	 IF @nMode=2
		GOTO END_PROC

	 EXEC SP3S_DEFINE_MODULESPROC

	 SET @cStep='15'  

	 SELECT module_name,table_name INTO  #modules_tables FROM modules_tables (NOLOCK) 
  
	 SET @cStep='20'  
	 SELECT user_code INTO #users FROM users (NOLOCK) WHERE 1=2   
 
	 WHILE EXISTS (SELECT TOP 1 * FROM #modules_tables)  
	 BEGIN  
		SET @cStep='30'  
  
		SELECT TOP 1 @cTableName=TABLE_NAME,@cModuleName=module_name from #modules_tables  
		SET @cStep='40'  
		
  
		SET @cUserTableName=UPPER(@cTableName+'_'+@cModuleName+'_'+@cUserCodePara ) 
		SET @cStep='50'  
		SET @cCmd=N'IF OBJECT_ID('''+@cUserTableName+''',''u'') IS NOT NULL  
			DROP TABLE '+@cUserTableName  
		PRINT @cCmd   
		EXEC SP_EXECUTESQL @cCmd  

		SET @cStep='60'  
		SET @cCmd=N'SELECT * INTO '+@cUserTableName+' FROM '+@cTableName+' WHERE 1=2'  
		PRINT @cCmd  
		EXEC SP_EXECUTESQL @cCmd  
  
		  SET @cStep='90'  
		  DELETE FROM #modules_tables WHERE TABLE_NAME=@cTableName AND module_name=@cModuleName  
	 END  
     
	 SET @bCreateUserProc=1

	 GOTO END_PROC  
END TRY  
  
BEGIN CATCH  
	 SET @cErrormsg='Error in Procedure  SP3S_CREATE_USERVERSION_TABLES at Step#'+@cStep+' '+ERROR_MESSAGE()  
	 GOTO END_PROC  
END CATCH  
  
END_PROC:
	 IF @nMode=2
		INSERT INTO xntype_userprocversion_log (xn_type,user_code,last_update)
		SELECT 'All' xn_type,@cUserCodePara,getdate() last_update

     print 'last step:'+@cStep
	 SELECT ISNULL(@cErrormsg,'') errmsg,@bCreateUserProc CreateUserProc
END 
