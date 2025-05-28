create PROCEDURE SP3S_PROCESS_IMPORT_PARTY_RATE    
(
	@cTempTableName  VARCHAR(MAX),    
	@cDEPT_ID   VARCHAR(MAX) ,
	@cFilter	VARCHAR(MAX)
)    
AS    
BEGIN    
DECLARE @cCMD nVARCHAR(MAX) ,@CRETMSG NVARCHAR(MAX),@cErrMsg NVARCHAR(MAX)
DECLARE @dtError TABLE (FILTER_NAME VARCHAR(100),ERR_MSG VARCHAR(MAX))

		SET @CCMD=N'SELECT DISTINCT ''BASE_PRICE_NAME'' ,''Base Price should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(BASE_PRICE_NAME,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.BASE_PRICE_NAME ,''Base Price not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN 
					(
						SELECT ''MRP'' AS BASE_PRICE_NAME,2 as base_price
						UNION
						SELECT ''WSP'' AS BASE_PRICE_NAME, 1 as base_price
						UNION
						SELECT ''PURCHASE PRICE'' AS BASE_PRICE_NAME,3 as base_price
					) B ON B.BASE_PRICE_NAME=A.BASE_PRICE_NAME 
					WHERE B.BASE_PRICE_NAME IS NULL AND isnull(A.BASE_PRICE_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.BASE_PRICE=B.BASE_PRICE,A.BASE_PRICE_VAT_CREDIT=B.BASE_PRICE,GIVE_CREDIT_VAT=0
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN 
					(
						SELECT ''MRP'' AS BASE_PRICE_NAME,2 as base_price
						UNION
						SELECT ''WSP'' AS BASE_PRICE_NAME, 1 as base_price
						UNION
						SELECT ''PURCHASE PRICE'' AS BASE_PRICE_NAME,3 as base_price
					) B ON B.BASE_PRICE_NAME=A.BASE_PRICE_NAME 
					WHERE isnull(A.BASE_PRICE_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD


		SET @CCMD=N'SELECT DISTINCT ''CAL_MODE_NAME'',''Disc Calc Mode should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(CAL_MODE_NAME,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.CAL_MODE_NAME ,''Disc Calc Mode not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN 
					(
						SELECT ''ADD'' AS CAL_MODE_NAME,1 as cal_mode
						UNION
						SELECT ''LESS'' AS CAL_MODE_NAME,2 as cal_mode
						UNION
						SELECT ''FLAT'' AS CAL_MODE_NAME,3 as cal_mode
					) B ON B.CAL_MODE_NAME=A.CAL_MODE_NAME 
					WHERE B.CAL_MODE_NAME IS NULL AND isnull(A.CAL_MODE_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.CAL_MODE=B.CAL_MODE
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN 
					(
						SELECT ''ADD'' AS CAL_MODE_NAME,1 as cal_mode
						UNION
						SELECT ''LESS'' AS CAL_MODE_NAME,2 as cal_mode
						UNION
						SELECT ''FLAT'' AS CAL_MODE_NAME,3 as cal_mode
					) B ON B.CAL_MODE_NAME=A.CAL_MODE_NAME 
					WHERE isnull(A.CAL_MODE_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD


		SET @CCMD=N'SELECT DISTINCT ''VALUE'' ,''Value should not be negative'' FROM '+@CTEMPTABLENAME+' WHERE  isnull(convert(numeric(10,2),VALUE) ,0)<0  '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT


if(@cFilter LIKE '%SEC%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT SECTION_NAME ,''SECTION NAME Should not be Blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(SECTION_NAME,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.SECTION_NAME ,''SECTION NAME not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN SECTIONM B ON B.section_name=A.SECTION_NAME 
					WHERE B.SECTION_NAME IS NULL AND isnull(A.SECTION_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.SECTION_CODE=B.SECTION_CODE
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN SECTIONM B ON B.section_name=A.SECTION_NAME 
					WHERE isnull(A.SECTION_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET SECTION_NAME='''' ,SECTION_CODE=''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%SEC%'''    
	PRINT @ccmd     
	EXEC SP_EXECUTESQL @cCMD 
END

if(@cFilter LIKE '%SUB%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT SUB_SECTION_NAME ,''SUB SECTION NAME Should not be Blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(SUB_SECTION_NAME,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.SUB_SECTION_NAME ,''SUB SECTION NAME not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN SECTIOND B ON B.sub_section_name=A.SUB_SECTION_NAME 
					WHERE B.SUB_SECTION_NAME IS NULL AND isnull(A.SUB_SECTION_NAME,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.SUB_SECTION_CODE=C.SUB_SECTION_CODE 
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN SECTIONM b ON b.SECTION_name=A.SECTION_NAME 
					JOIN SECTIOND c ON c.sub_section_name=A.SUB_SECTION_NAME  AND c.section_code=b.section_code
					where isnull(A.SUB_SECTION_NAME,'''')<>'''''
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET SUB_SECTION_NAME='''',SUB_SECTION_CODE=''0000000'''-- WHERE '''+@cFilter +''' NOT  LIKE ''%SUB%'''    
	PRINT @ccmd     
	EXEC SP_EXECUTESQL @cCMD 
END

if(@cFilter LIKE '%ART%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT ARTICLE_NO ,''Article No should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(ARTICLE_NO,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.ARTICLE_NO ,''Article No not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN ARTICLE B ON B.ARTICLE_NO=A.ARTICLE_NO 
					WHERE B.ARTICLE_NO IS NULL AND isnull(A.ARTICLE_NO,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET  A.ARTICLE_CODE=B.ARTICLE_CODE
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN ARTICLE B ON B.ARTICLE_NO=A.ARTICLE_NO 
					WHERE isnull(A.ARTICLE_NO,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET ARTICLE_NO='''',ARTICLE_CODE='''''-- WHERE '''+@cFilter +''' NOT  LIKE ''%ART%'''    
	PRINT @ccmd     
	EXEC SP_EXECUTESQL @cCMD 

END

if(@cFilter LIKE '%P1%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT Para1_name ,''Para1 Name should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(Para1_name,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(1000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.Para1_name ,''Para1 not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN Para1 B ON B.para1_name=A.Para1_name 
					WHERE B.para1_name IS NULL AND isnull(A.para1_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD


		SET @CCMD=N'UPDATE A SET A.Para1_code=B.para1_code
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN Para1 B ON B.para1_name=A.Para1_name 
					WHERE isnull(A.para1_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET PARA1_NAME='''' ,PARA1_CODE =''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%P1%'''    
PRINT @ccmd     
EXEC SP_EXECUTESQL @cCMD  
END

if(@cFilter LIKE '%P2%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT Para2_name ,''Para2 Name should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(Para2_name,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(2000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.Para2_name ,''Para2 not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN Para2 B ON B.para2_name=A.Para2_name 
					WHERE B.para2_name IS NULL AND isnull(A.para2_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.Para2_code=B.para2_code
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN Para2 B ON B.para2_name=A.Para2_name 
					WHERE isnull(A.para2_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET PARA2_NAME='''' ,PARA2_CODE =''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%P2%'''    
PRINT @ccmd     
EXEC SP_EXECUTESQL @cCMD  
END


if(@cFilter LIKE '%P3%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT Para3_name ,''Para3 Name should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(Para3_name,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(3000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.Para3_name ,''Para3 not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN Para3 B ON B.para3_name=A.Para3_name 
					WHERE B.para3_name IS NULL AND isnull(A.para3_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.Para3_code=B.para3_code
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN Para3 B ON B.para3_name=A.Para3_name 
					WHERE isnull(A.para3_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET PARA3_NAME='''' ,PARA3_CODE =''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%P3%'''    
PRINT @ccmd     
EXEC SP_EXECUTESQL @cCMD  
END

if(@cFilter LIKE '%P4%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT Para4_name ,''Para4 Name should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(Para4_name,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(4000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.Para4_name ,''Para4 not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN Para4 B ON B.para4_name=A.Para4_name 
					WHERE B.para4_name IS NULL AND isnull(A.para4_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.Para4_code=B.para4_code
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN Para4 B ON B.para4_name=A.Para4_name 
					WHERE isnull(A.para4_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET PARA4_NAME='''' ,PARA4_CODE =''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%P4%'''    
PRINT @ccmd     
EXEC SP_EXECUTESQL @cCMD  
END

if(@cFilter LIKE '%P5%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT Para5_name ,''Para5 Name should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(Para5_name,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(5000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.Para5_name ,''Para5 not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN Para5 B ON B.para5_name=A.Para5_name 
					WHERE B.para5_name IS NULL AND isnull(A.para5_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.Para5_code=B.para5_code
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN Para5 B ON B.para5_name=A.Para5_name 
					WHERE isnull(A.para5_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
		SET @cCMD=N'update '+@cTempTableName+' SET PARA5_NAME='''' ,PARA5_CODE =''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%P5%'''    
		PRINT @ccmd     
		EXEC SP_EXECUTESQL @cCMD  
END

if(@cFilter LIKE '%P6%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT Para6_name ,''Para6 Name should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(Para6_name,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(6000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.Para6_name ,''Para6 not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN Para6 B ON B.para6_name=A.Para6_name 
					WHERE B.para6_name IS NULL AND isnull(A.para6_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CCMD=N'UPDATE A SET A.Para6_code=B.para6_code
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN Para6 B ON B.para6_name=A.Para6_name 
					WHERE isnull(A.para6_name,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
ELSE
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET PARA6_NAME='''' ,PARA6_CODE =''0000000'''--WHERE '''+@cFilter +''' NOT  LIKE ''%P6%'''    
	PRINT @ccmd     
	EXEC SP_EXECUTESQL @cCMD  
END

if(@cFilter LIKE '%HSN%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT  HSN_CODE ,''HSN CODE should not be blank'' FROM '+@CTEMPTABLENAME+' WHERE isnull(HSN_CODE,'''')='''' '
		PRINT @CCMD		
		INSERT INTO @dtError

		EXEC SP_EXECUTESQL @CCMD--,N'@CERRMSG VARCHAR(6000) OUTPUT',@CERRMSG OUTPUT
		
		SET @CCMD=N'SELECT DISTINCT A.HSN_CODE ,''HSN not found'' 
					FROM '+@CTEMPTABLENAME+ ' A 
					LEFT OUTER JOIN HSN_MST B ON B.HSN_CODE=A.HSN_CODE
					WHERE B.HSN_CODE IS NULL AND isnull(A.HSN_CODE,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'UPDATE A SET A.HSN_CODE=B.HSN_CODE
					FROM '+@CTEMPTABLENAME+ ' A 
					JOIN HSN_MST B ON B.HSN_CODE=A.HSN_CODE
					WHERE isnull(A.HSN_CODE,'''')<>'''' '
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD
END
BEGIN
	SET @cCMD=N'update '+@cTempTableName+' SET HSN_CODE='''' '--WHERE '''+@cFilter +''' NOT  LIKE ''%HSN%'''    
	PRINT @ccmd     
	EXEC SP_EXECUTESQL @cCMD 
END

if(@cFilter LIKE '%MRP%')
BEGIN
		SET @CCMD=N'SELECT DISTINCT  Rtrim(LTRIM(STR(FROM_MRP)))+'':'' +Rtrim(LTRIM(STR(TO_MRP)))  ,''[From MRP] should not be greater than [To MRP]'' FROM '+@CTEMPTABLENAME+' WHERE isnull(FROM_MRP,0)>isnull(TO_MRP,0)'
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD

		SET @CCMD=N'SELECT DISTINCT Rtrim(LTRIM(STR(FROM_MRP)))+'':'' +Rtrim(LTRIM(STR(TO_MRP))) ,''[From MRP] and  [To MRP] should not be ZERO'' FROM '+@CTEMPTABLENAME+' WHERE isnull(FROM_MRP,0)=0 AND isnull(TO_MRP,0)=0'
		PRINT @CCMD		
		INSERT INTO @dtError
		EXEC SP_EXECUTESQL @CCMD	
END
ELSE
BEGIN
		SET @cCMD=N'update '+@cTempTableName+' SET FROM_MRP=0 ,TO_MRP=0'    
		PRINT @ccmd     
		EXEC SP_EXECUTESQL @cCMD 
END
    
 SET @cCMD=N'update '+@cTempTableName+' SET ROW_ID='''' '    
PRINT @ccmd     
EXEC SP_EXECUTESQL @cCMD 
 
IF EXISTS (SELECT 'U' FROM @dtError WHERE ISNULL(ERR_MSG,'')<>'')
	SELECT * FROM @dtError
ELSE    
BEGIN    
	SET @cCMD=N'SELECT NEWID() AS ROW_ID, * FROM
	(SELECT DISTINCT *,'''' AS err_msg FROM '+@cTempTableName + ')X'
	PRINT @ccmd     
	EXEC SP_EXECUTESQL @cCMD    
END
END  