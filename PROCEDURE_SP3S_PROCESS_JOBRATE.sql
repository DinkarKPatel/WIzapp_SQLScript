CREATE PROCEDURE SP3S_PROCESS_JOBRATE
(
	@CTABLENAME	VARCHAR(MAX),
	@CJOBCODE	VARCHAR(50)
)
AS
BEGIN
	DECLARE @CCMD	NVARCHAR(MAX),@CJOB_NAME	NVARCHAR(MAX)
	DECLARE @TERROR TABLE(ITEM_VALUE  VARCHAR(MAX),ERR_MSG  VARCHAR(MAX))
	
	
	SELECT @CJOB_NAME= JOB_NAME FROM JOBS WHERE ISNULL(JOB_NAME,'')<>'' AND JOB_CODE=@CJOBCODE
	
	IF ISNULL(@CJOB_NAME,'')=''
	BEGIN
		INSERT INTO @TERROR(ITEM_VALUE  ,ERR_MSG)			
		SELECT '','BLANK JOB NAME NOT ALLOWED'
		GOTO END_PROC
	END
	BEGIN TRANSACTION
	
	BEGIN TRY
		SET @CCMD=N'SELECT A.ARTICLE_NO AS [ITEM_VALUE],''ARTICLE NO NOT FOUND IN ARTICLE MASTER'' AS [ERR_MSG]
					FROM '+@CTABLENAME+' A (NOLOCK)
					LEFT OUTER JOIN ARTICLE B (NOLOCK) ON B.ARTICLE_NO=A.ARTICLE_NO
					WHERE B.ARTICLE_NO IS  NULL
					UNION 
					SELECT A.PARA1_NAME AS [ITEM_VALUE],''PARA1 NAME NOT FOUND IN PARA1 MASTER'' AS [ERR_MSG]
					FROM '+@CTABLENAME+' A (NOLOCK)
					LEFT OUTER JOIN PARA1 B  (NOLOCK) ON B.PARA1_NAME=A.PARA1_NAME
					WHERE ISNULL(A.PARA1_NAME,'''')<>'''' AND B.PARA1_NAME IS  NULL
					UNION 
					SELECT A.PARA2_NAME AS [ITEM_VALUE],''PARA2 NAME NOT FOUND IN PARA2 MASTER'' AS [ERR_MSG]
					FROM '+@CTABLENAME+' A (NOLOCK)
					LEFT OUTER JOIN PARA2 B  (NOLOCK) ON B.PARA2_NAME=A.PARA2_NAME
					WHERE ISNULL(A.PARA2_NAME,'''')<>'''' AND B.PARA2_NAME IS NULL
					UNION 
					SELECT A.RATE AS [ITEM_VALUE],''RATE SHOULD BE GREATER THAN ZERO(0)'' AS [ERR_MSG]
					FROM '+@CTABLENAME+' A (NOLOCK) 
					WHERE CAST(ISNULL(A.RATE,0) AS NUMERIC(10,2))<=0
					UNION 
					SELECT A.AGENCY_NAME AS [ITEM_VALUE],''JOB WORKER NAME NOT FOUND IN MASTER'' AS [ERR_MSG]
					FROM '+@CTABLENAME+' A (NOLOCK) 
					LEFT OUTER JOIN PRD_AGENCY_MST B (NOLOCK) ON B.AGENCY_NAME=A.AGENCY_NAME
					WHERE A.AGENCY_NAME<>'''' AND B.AGENCY_NAME IS NULL'
					
		PRINT @CCMD
		INSERT INTO @TERROR(ITEM_VALUE  ,ERR_MSG)			
		EXEC SP_EXECUTESQL @CCMD
		
		IF(@@ROWCOUNT=0)
		BEGIN
			SET @CCMD=N'SELECT ISNULL(A.ARTICLE_NO,'''')+ISNULL(A.PARA1_NAME,'''')+ISNULL(A.PARA2_NAME,'''') AS [ITEM_VALUE],''DUPLICATE RECORD FOUND'' AS [ERR_MSG]
						FROM '+@CTABLENAME+' A (NOLOCK)
						GROUP BY ISNULL(A.ARTICLE_NO,''''),ISNULL(A.PARA1_NAME,''''),ISNULL(A.PARA2_NAME,'''')
						HAVING COUNT(*)>1'
			
			PRINT @CCMD
			INSERT INTO @TERROR(ITEM_VALUE  ,ERR_MSG)			
			EXEC SP_EXECUTESQL @CCMD
		END
		
		IF(@@ROWCOUNT=0)
		BEGIN
			/*
				SELECT A1.ARTICLE_CODE,ART.ARTICLE_CODE,A1.PARA1_CODE,P1.PARA1_CODE,A1.PARA2_CODE,P2.PARA2_CODE
				,A1.MRP,ART.MRP,A1.WS_PRICE,ART.WHOLESALE_PRICE,A1.PURCHASE_PRICE,ART.PURCHASE_PRICE
			*/
			--BEGIN TRY
			DELETE FROM JOB_RATE_DET WHERE JOB_CODE=@CJOBCODE
			
			SET @CCMD=N'UPDATE A1 SET A1.ARTICLE_CODE=ART.ARTICLE_CODE,A1.PARA1_CODE=P1.PARA1_CODE,
						A1.PARA2_CODE=P2.PARA2_CODE,A1.AGENCY_CODE=JW.AGENCY_CODE
						FROM '+@CTABLENAME+' A1
						JOIN ARTICLE ART ON ART.ARTICLE_NO=A1.ARTICLE_NO
						LEFT OUTER JOIN PARA1 P1 ON P1.PARA1_NAME=A1.PARA1_NAME
						LEFT OUTER JOIN PARA2 P2 ON P2.PARA2_NAME=A1.PARA2_NAME
						LEFT OUTER JOIN PRD_AGENCY_MST JW ON JW.AGENCY_NAME=A1.AGENCY_NAME'
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CCMD=N'INSERT JOB_RATE_DET	( ROW_ID, PARA1_CODE, PARA2_CODE, PARA3_CODE, ARTICLE_CODE, RATE, AGENCY_CODE, JOB_CODE, LAST_UPDATE )  
			SELECT 	 NEWID() AS ROW_ID, ISNULL(PARA1_CODE,''0000000'') AS PARA1_CODE, ISNULL(PARA2_CODE,''0000000'') AS PARA2_CODE,''0000000'' PARA3_CODE, 
			ARTICLE_CODE, RATE, ISNULL(AGENCY_CODE,''''),'''+@CJOBCODE+''' AS JOB_CODE, GETDATE() LAST_UPDATE 
			FROM '+@CTABLENAME
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD
									
		END
		COMMIT TRANSACTION
	
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		INSERT INTO @TERROR(ITEM_VALUE  ,ERR_MSG)			
		SELECT 'ERROR WHILE EXECUTING QUERY SP3S_PROCESS_UPC',ERROR_MESSAGE()
	END CATCH
END_PROC:	
	SELECT * FROM @TERROR
	
	--SET @CCMD=N'SELECT * FROM '+@CTABLENAME
	--PRINT @CCMD
	--EXEC SP_EXECUTESQL @CCMD

END
