CREATE PROCEDURE SPWOW_REPORTING    
      
@NQUERYID NUMERIC(2,0),           
@CUSERCODE  NVARCHAR(MAX),      
@CLOCID VARCHAR(100)=''   ,
@ReportingDate Datetime

AS      
BEGIN      
        
IF @NQUERYID = 1      
GOTO LBLLISTOFLOGIN      
      
ELSE IF @NQUERYID = 2      
GOTO LBLISTOFLOCATION 

ELSE IF @NQUERYID = 3     
GOTO LBLISTOFMENU

ELSE IF @NQUERYID = 4     
GOTO LBLFTDMTDYTD


                 
ELSE      
GOTO LAST      

LBLLISTOFLOGIN:   

 SELECT  USERNAME,USER_CODE FROM  USERS (NOLOCK) WHERE INACTIVE=0 ORDER BY USERNAME    
       
        
 GOTO LAST      
      
LBLISTOFLOCATION:  

 SELECT  A.DEPT_ID,A.DEPT_NAME,A.DEPT_ALIAS 
 FROM LOCATION A  (NOLOCK)
 JOIN LOCUSERS  B  (NOLOCK) ON  A.DEPT_ID= B.DEPT_ID
 WHERE B.USER_CODE =  @CUSERCODE

          
 GOTO LAST          
 

 LBLISTOFMENU:  

 SELECT b.* FROM  WOW_MENU_AUTH A  (NOLOCK)
 JOIN  WOW_MENU_ITEMS B (NOLOCK) ON A.MENU_ID = B.MENU_ID 
 JOIN USERS C (NOLOCK) ON  A.ROLE_ID = C.ROLE_ID
 WHERE C.USER_CODE= @CUSERCODE

  GOTO LAST   

  LBLFTDMTDYTD:


    Declare  @cTablewow varchar(200),@cTableWowPrevYear VARCHAR(200),@bPrevYearDatafound BIT
	Declare @cCMD NVARCHAR(MAX)
	
	SET @bPrevYearDatafound=0



	SELECT @cTablewow = db_name()+'_pmt.dbo.wow_ftdmtdytd_sales_'+CONVERT(VARCHAR,@ReportingDate,112)
	SET @cTablewowPrevYear = db_name()+'_pmt.dbo.wow_ftdmtdytd_sales_'+CONVERT(VARCHAR,DATEADD(YY,-1,@ReportingDate),112)


	if object_id(@cTablewowPrevYear,'u') IS NOT NULL
		SET @bPrevYearDatafound=1
	
	CREATE TABLE #temp_wow (dept_alias VARCHAR(100),ftd_value_cy numeric(12,2),mtd_value_cy numeric(20,2),mtd_cntr_cy numeric(6,2),ytd_value_cy numeric(20,2),
	ytd_cntr_cy numeric(6,2),ftd_value_ly numeric(12,2),mtd_value_ly numeric(20,2),mtd_cntr_ly numeric(6,2),ytd_value_ly numeric(20,2),ytd_cntr_ly numeric(6,2),
	ftd_variance numeric(20,2),mtd_variance numeric(20,2),ytd_variance numeric(20,2))

	IF @ReportingDate=CONVERT(DATE,GETDATE())
	BEGIN
		CREATE TABLE #tmpFTDMTDYTDBuild (dept_id VARCHAR(5)/*Rohit 06-11-2024*/, ftd_value numeric(12,2),mtd_value numeric(12,2),ytd_value numeric(12,2))		
		
		EXEC SPWOW_BUILD_FTDMTDYTD_SALES
		@dFromDtPara=@ReportingDate,
		@dToDtPara=@ReportingDate,
		@bCalledfromReporting=1

		SET @cTablewow='#tmpFTDMTDYTDBuild'
	END

	SET @cCMD = N'SELECT  B.DEPT_ALIAS,ftd_value ftd_value_cy,mtd_value mtd_value_cy,
		0 mtd_cntr_cy,ytd_value ytd_value_cy,0 ytd_cntr_cy,0 ftd_value_ly,0 mtd_value_ly,0 mtd_cntr_ly,
		0 ytd_value_ly,0 ytd_cntr_ly,0 ftd_variance,0 mtd_variance,0 ytd_variance
		FROM '+@cTablewow+' A 
		JOIN LOCATION  B (NOLOCK) ON A.DEPT_ID= B.DEPT_ID
		JOIN LOCUSERS C  (NOLOCK) ON  B.DEPT_ID = C.DEPT_ID 
		WHERE C.USER_CODE = '''+@CUSERCODE+''''

	IF @bPrevYearDatafound=1
	BEGIN
		SET @cCmd=@cCmd+N'UNION ALL
		SELECT  B.DEPT_ALIAS,0 ftd_value_cy ,0 mtd_value_cy,0 mtd_cntr_cy,0 ytd_value_cy,0 ytd_cntr_cy,
		ftd_value ftd_value_ly,mtd_value mtd_value_ly,0 mtd_cntr_ly,ytd_value ytd_value_ly,0 ytd_cntr_ly,0 ftd_variance,
		0 mtd_variance,0 ytd_variance
		FROM '+@cTablewowPrevYear+' A 
		JOIN LOCATION  B (NOLOCK) ON A.DEPT_ID= B.DEPT_ID
		JOIN LOCUSERS C  (NOLOCK) ON  B.DEPT_ID = C.DEPT_ID 
		WHERE C.USER_CODE = '''+@CUSERCODE+''''  
    END

	SET @cCmd=N'SELECT dept_alias,SUM(ftd_value_cy) ftd_value_cy,SUM(mtd_value_cy) mtd_value_cy,0 mtd_cntr_cy,SUM(ytd_value_cy) ytd_value_cy,0 ytd_cntr_cy,
		SUM(ftd_value_ly) ftd_value_ly ,sum(mtd_value_ly) mtd_value_ly,0 mtd_cntr_ly,sum(ytd_value_ly) ytd_value_ly,0 ytd_cntr_ly,
		0 ftd_variance,0 mtd_variance,0 ytd_variance FROM ('+@cCmd+') a
		GROUP BY dept_alias '

    PRINT @cCMD  
	insert into #temp_wow (dept_alias,ftd_value_cy,mtd_value_cy,mtd_cntr_cy,ytd_value_cy,ytd_cntr_cy,ftd_value_ly ,
	mtd_value_ly,mtd_cntr_ly,ytd_value_ly,ytd_cntr_ly,ftd_variance,mtd_variance,ytd_variance)
    EXEC SP_EXECUTESQL @cCMD  

	UPDATE #temp_wow SET ftd_variance=(CASE WHEN ftd_value_ly=0 THEN 100 ELSE ((ftd_value_cy-ftd_value_ly)/ftd_value_ly)*100 END),
	mtd_variance=(CASE WHEN mtd_value_ly=0 THEN 100 ELSE ((mtd_value_cy-mtd_value_ly)/mtd_value_ly)*100 END),
	ytd_variance=(CASE WHEN ytd_value_ly=0 THEN 100 ELSE ((ytd_value_cy-ytd_value_ly)/ytd_value_ly)*100 END)

	UPDATE a SET mtd_cntr_cy=(mtd_value_cy/b.mtd_value_cy_total)*100,ytd_cntr_cy=(ytd_value_cy/b.ytd_value_cy_total)*100
	FROM #temp_wow a JOIN (SELECT sum(mtd_value_cy) mtd_value_cy_total,sum(ytd_value_cy) ytd_value_cy_total FROM #temp_wow) b
	ON 1=1


	UPDATE a SET mtd_cntr_ly=(CASE WHEN mtd_value_ly_total=0 THEN 0 ELSE (mtd_value_ly/b.mtd_value_ly_total)*100 END),
	ytd_cntr_ly=(CASE WHEN Ytd_value_ly_total=0 THEN 0 ELSE (ytd_value_ly/b.ytd_value_ly_total)*100 END)
	FROM #temp_wow a JOIN (SELECT sum(mtd_value_ly) mtd_value_ly_total,sum(ytd_value_ly) ytd_value_ly_total FROM #temp_wow) b
	ON 1=1 

	SELECT  DEPT_ALIAS As [Alias],ftd_value_cy AS [FTD_Current year] ,ftd_value_ly as [FTD_Last year],
	ftd_variance as [FTD_Variance] FROM #temp_wow
	ORDER BY 1

	SELECT  DEPT_ALIAS As [Alias],mtd_value_cy AS [MTD_Current year],mtd_cntr_cy as [MTD_Current year Contr %],
	mtd_value_ly as [MTD_Last year],mtd_cntr_ly as [MTD_Last year Contr %],mtd_variance as [MTD_Variance]
	FROM #temp_wow
	ORDER BY 1

	SELECT  DEPT_ALIAS As [Alias],ytd_value_cy as [YTD_Current year],ytd_cntr_cy As [YTD_Current year Contr %],
	ytd_value_ly as [YTD_Last year],ytd_cntr_ly as [YTD_Last year Contr %],	ytd_variance as [YTD_Variance] 
	FROM #temp_wow
	ORDER BY 1

  GOTO LAST  


  
              
LAST:   
    	
END
