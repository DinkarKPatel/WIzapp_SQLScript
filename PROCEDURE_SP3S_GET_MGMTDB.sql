CREATE PROCEDURE SP3S_GET_MGMTDB
(
	 @DTODATE DATETIME 
	,@CREPID VARCHAR(20)
	,@CREPORT_TYPE VARCHAR(4)
	,@BREPROCESS BIT
)
--WITH ENCRYPTION
AS
BEGIN
/*
	THIS PROCEDURE WILL BE CALLED BY APPLICATION TO FETCH RECORDS FOR A REPORT
*/
	DECLARE  @CTODATE VARCHAR(20)
			,@CPROCESSID VARCHAR(50)
			,@NDAYS NUMERIC(4)
			,@NCNTRPCT NUMERIC(10,2)
	
	SELECT @NCNTRPCT=VALUE FROM CONFIG WHERE CONFIG_OPTION='CONTR_PER'
	
	SET @NCNTRPCT=ISNULL(@NCNTRPCT,0)
	
	SET @DTODATE=DATEADD(DD,0,DATEDIFF(DD,0,@DTODATE))
	SET @CTODATE=CONVERT(VARCHAR,@DTODATE,110)
	
	---IF THE REPORT NEEDS TO BE REPROCESSED
	IF @BREPROCESS=1
	BEGIN
		EXEC SP3S_PROCESSDBREPORTS @DTODATE,@CREPID,@CREPORT_TYPE
	END
	
	SELECT @CPROCESSID=PROCESSID,@NDAYS=DAYS FROM MGMT_DB_MST 
		WHERE PROCESSDT=@DTODATE AND REP_ID=@CREPID AND REPORT_TYPE=@CREPORT_TYPE
		
	IF ISNULL(@CPROCESSID,'')=''
	BEGIN
		SELECT 'REPORT FOR THE DATE '+ CONVERT(VARCHAR(10),@DTODATE,105) +' HAS NOT BEEN PROCESSED!'+CHAR(13)+'WOULD YOU LIKE TO PROCESS IT NOW?' AS ALERT
	END	
	ELSE
	BEGIN
		IF OBJECT_ID('#INVDASHBOARD','U') IS NOT NULL
			DROP TABLE #INVDASHBOARD
		
	SELECT   2 AS SNO
		    ,LAYOUTCOL
			,CONVERT(NUMERIC(18,0),(PURCHASE_VALUE)) AS PURCHASE_VALUE
			,CONVERT(NUMERIC(10,2),PUR_CNTR) AS PUR_CNTR
			,CONVERT(NUMERIC(18,0),(SALE_VALUE)) AS SALE_VALUE
			,CONVERT(NUMERIC(10,2),SALE_CNTR) AS SALE_CNTR
			,CONVERT(NUMERIC(18,0),(SOLD_PURCHASE_VALUE)) AS SOLD_PURCHASE_VALUE
			,CONVERT(NUMERIC(18,0),(GROSS_MARGIN)) AS GROSS_MARGIN
			,CONVERT(NUMERIC(10,2),GM_CNTR) AS GM_CNTR
			,CONVERT(NUMERIC(18,2),TPY) AS TPY
			,CONVERT(NUMERIC(18,2),PSPD) AS PSPD
			,CONVERT(NUMERIC(18,0),(ADI)) AS ADI
			,CONVERT(NUMERIC(18,2),(GMROI)) AS GMROI
			,CONVERT(NUMERIC(18,0),(ASD)) AS ASD
			,CONVERT(NUMERIC(18,0),(AGE1)) AS AGE1
			,CONVERT(NUMERIC(18,0),(AGE2)) AS AGE2
			,CONVERT(NUMERIC(18,0),(AGE3)) AS AGE3
			,CONVERT(NUMERIC(18,0),(AGE4)) AS AGE4 
			,CONVERT(NUMERIC(18,0),(DIH)) AS DIH
			INTO #INVDASHBOARD
			FROM MGMT_DB_DET
			WHERE PROCESSID=@CPROCESSID AND PUR_CNTR>=@NCNTRPCT AND ADI>0 AND AGE1>=0 AND AGE2>=0 AND AGE3>=0 AND AGE4>=0 
	UNION ALL
	SELECT   3 AS SNO
			,'OTHERS' AS LAYOUTCOL
			,CONVERT(NUMERIC(18,0),(SUM(PURCHASE_VALUE))) AS PURCHASE_VALUE
			,CONVERT(NUMERIC(10,2),SUM(PUR_CNTR)) AS PUR_CNTR
			,CONVERT(NUMERIC(18,0),(SUM(SALE_VALUE))) AS SALE_VALUE
			,CONVERT(NUMERIC(10,2),SUM(SALE_CNTR)) AS SALE_CNTR
			,CONVERT(NUMERIC(18,0),(SUM(SOLD_PURCHASE_VALUE))) AS SOLD_PURCHASE_VALUE
			,CONVERT(NUMERIC(18,0),(SUM(GROSS_MARGIN))) AS GROSS_MARGIN
			,CONVERT(NUMERIC(10,2),SUM(GM_CNTR)) AS GM_CNTR
			,CONVERT(NUMERIC(18,2),SUM(TPY)) AS TPY
			,CONVERT(NUMERIC(18,2),SUM(PSPD)) AS PSPD
			,CONVERT(NUMERIC(18,0),(SUM(ADI))) AS ADI
			,CONVERT(NUMERIC(18,2),(SUM(GROSS_MARGIN)*365*100/(SUM(ADI)*@NDAYS))) AS GMROI
			,CONVERT(NUMERIC(18,0),(SUM(ASD))) AS ASD
			,CONVERT(NUMERIC(18,0),(SUM(AGE1))) AS AGE1
			,CONVERT(NUMERIC(18,0),(SUM(AGE2))) AS AGE2
			,CONVERT(NUMERIC(18,0),(SUM(AGE3))) AS AGE3
			,CONVERT(NUMERIC(18,0),(SUM(AGE4))) AS AGE4 
			,CONVERT(NUMERIC(18,0),(SUM(DIH))) AS DIH 
			FROM MGMT_DB_DET
			WHERE PROCESSID=@CPROCESSID AND PUR_CNTR<@NCNTRPCT
			HAVING SUM(ADI)>0 AND SUM(AGE1)>=0 AND SUM(AGE2)>=0 AND SUM(AGE3)>=0 
			AND SUM(AGE4)>=0 
			ORDER BY SNO,SALE_VALUE DESC
	
	SELECT 1 AS SNO,CONVERT(VARCHAR(500),'OVERALL') AS LAYOUTCOL
	,CONVERT(NUMERIC(18,0),AVG(PURCHASE_VALUE)) AS PURCHASE_VALUE
	,NULL AS PUR_CNTR
	,CONVERT(NUMERIC(18,0),AVG(SALE_VALUE)) AS SALE_VALUE
	,NULL AS SALE_CNTR
	,NULL AS SOLD_PURCHASE_VALUE
	,CONVERT(NUMERIC(18,0),AVG(GROSS_MARGIN)) AS GROSS_MARGIN
	,NULL AS GM_CNTR
	,CONVERT(NUMERIC(18,0),AVG(TPY)) AS TPY
	,CONVERT(NUMERIC(18,0),AVG(PSPD)) AS PSPD
	,CONVERT(NUMERIC(18,0),AVG(ADI)) AS ADI
	,CONVERT(NUMERIC(18,0),(SUM(GROSS_MARGIN)*365*100/(SUM(ADI)*@NDAYS))) AS GMROI
	,CONVERT(NUMERIC(18,0),AVG(ASD)) AS ASD
	,CONVERT(NUMERIC(18,0),AVG(AGE1)) AS AGE1
	,CONVERT(NUMERIC(18,0),AVG(AGE2)) AS AGE2
	,CONVERT(NUMERIC(18,0),AVG(AGE3)) AS AGE3
	,CONVERT(NUMERIC(18,0),AVG(AGE4)) AS AGE4 
	,CONVERT(NUMERIC(18,0),AVG(DIH)) AS DIH
	FROM #INVDASHBOARD
	HAVING SUM(ADI)>0 AND SUM(AGE1)>=0 AND SUM(AGE2)>=0 AND SUM(AGE3)>=0 AND SUM(AGE4)>=0 
	UNION ALL
	SELECT
	SNO,LAYOUTCOL,PURCHASE_VALUE,PUR_CNTR,SALE_VALUE,SALE_CNTR
	,SOLD_PURCHASE_VALUE,GROSS_MARGIN,GM_CNTR,TPY,PSPD,ADI
	,GMROI,ASD,AGE1,AGE2,AGE3,AGE4,DIH 
	FROM #INVDASHBOARD
	ORDER BY SNO
	END
END
--END OF PROCEDURE - SP3S_GET_MGMTDB
