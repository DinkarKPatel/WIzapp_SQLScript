CREATE PROCEDURE SP3S_MIRROR_GETMISSINGSERIES
@CXNTYPE VARCHAR(10),
@CLOCID VARCHAR(5),
@BRETSINGLECMD BIT=0,
@CFIRSTMEMONO VARCHAR(20)=''
--WITH ENCRYPTION
AS
BEGIN

	DECLARE @CCMD NVARCHAR(MAX),@CSOURCEDB VARCHAR(300),@NSTEP INT,@CWHERECLAUSE VARCHAR(200),
			@CCUTOFFDATE VARCHAR(20),@CMEMONOLEN VARCHAR(5),@NMEMONOLEN INT,@CMEMOID VARCHAR(50),
			@BLOOP BIT,@CDEPTIDLOOP VARCHAR(5),@CDEPTID VARCHAR(5),@BFIRST BIT,@CMEMOPREFIXEXPR VARCHAR(100),
			@CERRORMSG VARCHAR(MAX) 
	
	
	SELECT TOP 1 @CCUTOFFDATE=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='SERIESCHK_CUTOFF_DATE'
	
	SET @CCUTOFFDATE=ISNULL(@CCUTOFFDATE,'')
	
	SET @CERRORMSG=''

	
	IF OBJECT_ID('TEMPDB..#TMPMISSINGSERIES','U') IS NOT NULL
		DROP TABLE #TMPMISSINGSERIES

	IF OBJECT_ID('TEMPDB..#TMPMISSINGSERIESDUP','U') IS NOT NULL
		DROP TABLE #TMPMISSINGSERIESDUP

	IF OBJECT_ID('TEMPDB..#TMPRESENDCMD','U') IS NOT NULL
		DROP TABLE #TMPRESENDCMD
				
	SELECT DEPT_ID,XN_TYPE,MEMO_ID,LAST_UPDATE,CONVERT(VARCHAR(5),'') AS MEMO_PREFIX INTO #TMPMISSINGSERIES 
	FROM LOC_XNSRECON_REQ (NOLOCK) WHERE 1=2
	
	IF @CCUTOFFDATE='9999-99-99'
		GOTO LAST
		
	BEGIN TRY
		
		SET @NSTEP=10
		
		SET @CSOURCEDB=DB_NAME()+'_WIZCOM.DBO.'

		IF OBJECT_ID('TEMPDB..#TMPXNSMRY','U') IS NOT NULL
			DROP TABLE #TMPXNSMRY
		
		SELECT FIN_YEAR,CONVERT(VARCHAR(5),'') AS PREFIX,CONVERT(INT,0) AS BILLMAX,CONVERT(INT,0) AS BILLCNT
		INTO #TMPXNSMRY FROM CMM01106 WHERE 1=2
		
		SET @NSTEP=20
		
		IF OBJECT_ID('TEMPDB..#TMPMEMODET','U') IS NOT NULL
			DROP TABLE #TMPMEMODET
		
		SELECT A.CM_NO AS MEMO_NO,A.FIN_YEAR,A.CM_ID AS MEMO_ID,LEFT(CM_NO,6) AS MEMO_PREFIX INTO #TMPMEMODET 
		FROM CMM01106 A (NOLOCK) WHERE 1=2

		CREATE INDEX IND_TMPMEMODET ON #TMPMEMODET (MEMO_NO)	 
					
		SET @NSTEP=30
	
		SET @NMEMONOLEN=10	
		
		IF @CXNTYPE='SLS'
		BEGIN


			SET @CWHERECLAUSE=' WHERE A.location_code ='''+@CLOCID+''''
			
			IF @CCUTOFFDATE<>''
				SET @CWHERECLAUSE=@CWHERECLAUSE+' AND A.CM_DT>'''+@CCUTOFFDATE+''''	
				
			SET @NSTEP=35
			SET @CCMD=N'SELECT A.CM_NO,A.FIN_YEAR,A.CM_ID,LEFT(A.CM_NO,5) FROM CMM01106 A (NOLOCK)
						JOIN SLS_CMM01106_MIRROR B ON LEFT(A.CM_NO,5)=LEFT(B.CM_NO,5) AND A.FIN_YEAR=B.FIN_YEAR'+@CWHERECLAUSE+' AND SUBSTRING(B.CM_NO,5,1)<>''N''
						UNION
						SELECT A.CM_NO,A.FIN_YEAR,A.CM_ID,LEFT(A.CM_NO,6) FROM CMM01106 A (NOLOCK)
						JOIN SLS_CMM01106_MIRROR B ON LEFT(A.CM_NO,5)=LEFT(B.CM_NO,5) AND A.FIN_YEAR=B.FIN_YEAR'+@CWHERECLAUSE+' AND SUBSTRING(B.CM_NO,5,1)=''N''						
						UNION
						SELECT A.CM_NO,A.FIN_YEAR,A.CM_ID,LEFT(CM_NO,5) FROM SLS_CMM01106_MIRROR A (NOLOCK)'+@CWHERECLAUSE+' AND SUBSTRING(A.CM_NO,5,1)<>''N''
						UNION
						SELECT A.CM_NO,A.FIN_YEAR,A.CM_ID,LEFT(CM_NO,6) FROM SLS_CMM01106_MIRROR A (NOLOCK)'+@CWHERECLAUSE+' AND SUBSTRING(A.CM_NO,5,1)=''N'''						
			
			SET @CMEMOPREFIXEXPR='LEFT(MEMO_NO,5)'						

			--SELECT TOP 1 @CMEMONOLEN=VALUE FROM CONFIG WHERE CONFIG_OPTION='SLS_MEMO_LEN'
			
			

			PRINT @CCMD	+'DDD'				
			INSERT #TMPMEMODET
			EXEC SP_EXECUTESQL @CCMD
			
			--SELECT TOP 1 LEN(MEMO_NO),* FROM #TMPMEMODET
			
			
			SELECT TOP 1  @CMEMONOLEN=LEN(MEMO_NO) FROM #TMPMEMODET
			DELETE FROM #TMPMEMODET WHERE  LEN(MEMO_NO)<>@CMEMONOLEN
			IF ISNULL(@CMEMONOLEN,'')<>''
				SET @NMEMONOLEN=CONVERT(INT,@CMEMONOLEN)
		
			
			SET @NSTEP=40
			
			INSERT #TMPXNSMRY			
			SELECT FIN_YEAR,LEFT(MEMO_NO, 5), MAX(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5))) - MIN(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5)))+1, COUNT(*)
			FROM #TMPMEMODET (NOLOCK) 
			GROUP BY FIN_YEAR,LEFT(MEMO_NO, 5) 
			HAVING MAX(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5))) - MIN(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5)))+1 <> COUNT(*) 	
			UNION
			SELECT FIN_YEAR,LEFT(MEMO_NO, 5), MAX(CAST(RIGHT(RTRIM(MEMO_NO), 4) AS NUMERIC(4))) - MIN(CAST(RIGHT(RTRIM(MEMO_NO), 4) AS NUMERIC(4)))+1, COUNT(*)
			FROM #TMPMEMODET (NOLOCK) 
			GROUP BY FIN_YEAR,LEFT(MEMO_NO, 5) 
			HAVING MAX(CAST(RIGHT(RTRIM(MEMO_NO), 4) AS NUMERIC(4))) - MIN(CAST(RIGHT(RTRIM(MEMO_NO), 4) AS NUMERIC(4)))+1 <> COUNT(*) 	
			
							
		END				
		ELSE
		IF @CXNTYPE='ARC'
		BEGIN


			SET @CWHERECLAUSE=' WHERE A.location_code ='''+@CLOCID+''''
			
			IF @CCUTOFFDATE<>''
				SET @CWHERECLAUSE=@CWHERECLAUSE+' AND A.ADV_REC_DT>'''+@CCUTOFFDATE+''''	
				
			SET @NSTEP=45
			
			SET @CCMD=N'SELECT A.ADV_REC_NO,A.FIN_YEAR,A.ADV_REC_ID,LEFT(A.ADV_REC_NO,4) FROM ARC01106 A (NOLOCK)
					JOIN ARC_ARC01106_MIRROR B ON LEFT(A.ADV_REC_NO,4)=LEFT(B.ADV_REC_NO,4) AND A.FIN_YEAR=B.FIN_YEAR'+@CWHERECLAUSE+'
					UNION
					SELECT A.ADV_REC_NO,A.FIN_YEAR,A.ADV_REC_ID,LEFT(A.ADV_REC_NO,4) FROM ARC_ARC01106_MIRROR A (NOLOCK)'+@CWHERECLAUSE
			
			SET @CMEMOPREFIXEXPR='LEFT(MEMO_NO,4)'					
			
			PRINT @CCMD					
			INSERT #TMPMEMODET
			EXEC SP_EXECUTESQL @CCMD
			
			SET @NSTEP=50
					
			INSERT #TMPXNSMRY			
			SELECT FIN_YEAR,LEFT(MEMO_NO, 5), MAX(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5))) - MIN(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5)))+1, COUNT(*)
			FROM #TMPMEMODET (NOLOCK) 
			GROUP BY FIN_YEAR,LEFT(MEMO_NO, 5) 
			HAVING MAX(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5))) - MIN(CAST(RIGHT(RTRIM(MEMO_NO), 5) AS NUMERIC(5)))+1 <> COUNT(*) 	
			
		END
		

		SET @NSTEP=55
		
		SET @CWHERECLAUSE=' AND '+@CMEMOPREFIXEXPR+' IN (SELECT PREFIX FROM #TMPXNSMRY)'
		
		
		EXEC SP3S_MIRROR_CHKMISSINGSERIES
		@CXNTYPE=@CXNTYPE,
		@CTABLENAME='#TMPMEMODET',
		@CMEMONOCOL='MEMO_NO',
		@CMEMOIDCOL='MEMO_ID',
		@NMEMONOLEN=@NMEMONOLEN,
		@NMEMOIDLEN=22,
		@CWHERECLAUSE=@CWHERECLAUSE
		
		IF @BRETSINGLECMD=0
		BEGIN
			INSERT #TMISSINGDATA
			SELECT MEMO_ID,'' AS ERRMSG  FROM #TMPMISSINGSERIES
			
			RETURN
		END
		
		SELECT MEMO_ID INTO #TMPMISSINGSERIESDUP FROM #TMPMISSINGSERIES
		
		SELECT CONVERT(VARCHAR(MAX),'') AS CMDSTR INTO #TMPRESENDCMD FROM #TMPMISSINGSERIES WHERE 1=2
		
		SELECT @CDEPTID='',@CDEPTIDLOOP=''
		
		SET @BLOOP=1
		WHILE @BLOOP=1
		BEGIN
			
			SET @CDEPTID=''
			
			SELECT TOP 1 @CDEPTID=LEFT(MEMO_ID,2) FROM #TMPMISSINGSERIESDUP ORDER BY MEMO_ID
			
			IF ISNULL(@CDEPTID,'')=''
				BREAK
				
			IF @CDEPTIDLOOP<>@CDEPTID
			BEGIN
				SET @CCMD=N'UPDATE MIRRORLOG WITH (ROWLOCK) SET LAST_UPDATE=GETDATE() WHERE XN_TYPE='''+@CXNTYPE+''' AND MEMO_ID IN ('
				SET @CDEPTIDLOOP=@CDEPTID
				
				SET @BFIRST=1
			END	
			
			WHILE @CDEPTIDLOOP=@CDEPTID
			BEGIN	
				SET @CMEMOID=''
				
				SELECT TOP 1 @CMEMOID=MEMO_ID,@CDEPTID=LEFT(MEMO_ID,2) FROM #TMPMISSINGSERIESDUP ORDER BY MEMO_ID
				
				IF ISNULL(@CMEMOID,'')='' OR @CDEPTIDLOOP<>@CDEPTID
					BREAK
					
				SET @CCMD=@CCMD+(CASE WHEN @BFIRST=0 THEN ',' ELSE '' END)+''''+@CMEMOID+''''
				SET @BFIRST=0
				
				DELETE FROM #TMPMISSINGSERIESDUP WHERE MEMO_ID=@CMEMOID
			END
			
			SET @CCMD=@CCMD+')'
		END 		
		
		GOTO LAST
	END TRY
	
	BEGIN CATCH
		PRINT 'UNTRAPPED ERROR'		
		SELECT @CERRORMSG='PROCEDURE SP3S_MIRROR_GETMISSINGSERIES : STEP :'+STR(ISNULL(@NSTEP,0))+ ' LINE NO. :'+
		ISNULL(LTRIM(RTRIM(STR(ERROR_LINE()))),'NULL LINE')+'MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')
	END CATCH	
	
	
LAST:
	SELECT '' AS MEMO_ID,ISNULL(@CERRORMSG,'') AS ERRMSG
	
--	END OF PROCEDURE SP3S_MIRROR_GETMISSINGSERIES
END
