CREATE PROCEDURE SP_RETAILSALE_36--(LocId 3 digit change only increased the parameter width by Sanjay:01-11-2024)
(  
	 @CQUERYID			NUMERIC(2),  
	 @CWHERE			VARCHAR(MAX)='',  
	 @CFINYEAR			VARCHAR(5)='',  
	 @CDEPTID			VARCHAR(4)='',  
	 @NNAVMODE			NUMERIC(2)=1,  
	 @CWIZAPPUSERCODE	VARCHAR(10)='',  
	 @CREFMEMOID		VARCHAR(40)='',  
	 @CREFMEMODT		DATETIME='',  
	 @BINCLUDEESTIMATE	BIT=1,  
	 @CFROMDT			DATETIME='',  
	 @CTODT				VARCHAR(50)='',
	 @bCardDiscount		BIT=0,
	 @cCustCode			VARCHAR(15)=''
) 
AS  
BEGIN  
	 
DECLARE @CCMD NVARCHAR(MAX),@CFLATDISC VARCHAR(10)  
SET @CCMD=''  
	DECLARE @cSchemesStr VARCHAR(2000),@cSchemeName VARCHAR(200),@bRetVal BIT
	
	IF OBJECT_ID('tempdb..#TmpTitles','U') IS NOT NULL
		DROP TABLE #TmpTitles
	
	SELECT DISTINCT sls_title INTO #TmpTitles FROM cmd_scheme_det a JOIN cmd01106 b ON a.cmd_row_id=b.row_id
	WHERE 1=2
	
	IF @nNavmode=1	
		SET @cCmd=N'SELECT DISTINCT sls_title FROM cmd_scheme_det a JOIN cmd01106 b ON a.cmd_row_id=b.row_id
		WHERE b.cm_id= '''+@cWhere+''''
	ELSE
		SET @cCmd=N'SELECT DISTINCT sls_title FROM sls_cmd_scheme_det_upload a 
					WHERE  ltrim(rtrim(str(a.sp_id))) = '+@cWhere
	
	INSERT #tmpTitles
	EXEC SP_EXECUTESQL @cCmd
	
	IF NOT EXISTS (SELECT TOP 1 sls_title FROM #TmpTitles)
	BEGIN
		SELECT '' AS sls_title
		RETURN
	END	
	
	SET @bRetVal = 1
	
	SET @cSchemesStr=''
	
	WHILE @bRetVal=1
	BEGIN
		SET @cSchemeName=''
		
		SELECT TOP 1 @cSchemeName=sls_title FROM #TmpTitles
		
		IF ISNULL(@cSchemeName,'')<>''
		BEGIN
			SET @cSchemesStr=@cSchemesStr+(CASE WHEN @cSchemesStr<>'' THEN ',' ELSE '' END)+@cSchemeName
			
			DELETE FROM #TmpTitles WHERE sls_title=@cSchemeName
		END
		ELSE
			BREAK	
    END
    
    SELECT @cSchemesStr as sls_title
    
end
