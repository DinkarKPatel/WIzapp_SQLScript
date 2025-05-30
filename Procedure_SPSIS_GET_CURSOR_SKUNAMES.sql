create PROCEDURE SPSIS_GET_CURSOR_SKUNAMES
(
	@cXNTYPE	VARCHAR(100),
	@cTABLENAME	VARCHAR(100),
	@cKEYNAME	VARCHAR(100),
	@cKEYVALUE	VARCHAR(100),
	@CERRMSG VARCHAR(MAX) OUTPUT
)
AS
BEGIN
	DECLARE @cCols NVARCHAR(MAX),@cnullableCols NVARCHAR(MAX), @cCmdCols NVARCHAR(MAX),@cTARGET_TABLENAME VARCHAR(100),@CSTEP VARCHAR(5) ,
	        @colname varchar(max) 
	BEGIN TRY
	
	   SET @CSTEP=40  

	 if @cXNTYPE='apr'
	begin
	     
		  SET @COLNAME=' LEFT(A.APD_PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.APD_PRODUCT_CODE)-1,-1),LEN(A.APD_PRODUCT_CODE )))AS PRODUCT_CODE,B.ARTICLE_NO,B.PARA3_NAME,B.PARA2_NAME'  
     
		  SET @CTARGET_TABLENAME='SIS_SKUNAMES_UPLOAD'  
		  SET @CCMDCOLS=N' SELECT DISTINCT '''+@CTARGET_TABLENAME+''' AS TARGET_TABLENAME,'+@COLNAME+', '''+@CKEYVALUE +''' AS '+@CXNTYPE+'_MEMO_ID       
			FROM '+@CTABLENAME+' (NOLOCK) A    
			JOIN SKU_NAMES (NOLOCK) B ON  A.APD_PRODUCT_CODE =B.PRODUCT_CODE    
			WHERE A.'+@CKEYNAME+'='''+@CKEYVALUE +'''  
			'  

	end
    else 
	begin

	    SET @COLNAME=' LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))AS PRODUCT_CODE,B.ARTICLE_NO,B.PARA3_NAME,B.PARA2_NAME'
			
		SET @CTARGET_TABLENAME='SIS_SKUNAMES_UPLOAD'
		SET @CCMDCOLS=N' SELECT DISTINCT '''+@CTARGET_TABLENAME+''' AS TARGET_TABLENAME,'+@COLNAME+', '''+@CKEYVALUE +''' AS '+@CXNTYPE+'_MEMO_ID     
			 FROM '+@CTABLENAME+' (NOLOCK) A  
			 JOIN SKU_NAMES (NOLOCK) B ON  A.PRODUCT_CODE =B.PRODUCT_CODE  
			 WHERE A.'+@CKEYNAME+'='''+@CKEYVALUE +'''
		'
     end

		PRINT @cCmdCols
		SET @CSTEP=50     
		EXEC SP_EXECUTESQL @cCmdCols

	
END TRY  
BEGIN CATCH  
 SET @CERRMSG='P: SPSIS_GET_CURSOR_SKUNAMES, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()  
END CATCH   

	
END
