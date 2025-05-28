CREATE PROCEDURE SP3S_GETSLSTARGET_REP
@cMemoId varchar(40)='',  
@nMode NUMERIC(1,0)=1,  
@FromDT DATETIME,  
@ToDT DATETIME,  
@PNO VARCHAR(MAX)='1',  
@Show_Err INT =1  
AS  
BEGIN  
 SET NOCOUNT ON  
 DECLARE @cCmd NVARCHAR(MAX),@cLayoutCols VARCHAR(200),@cGroupCols VARCHAR(200),@cJoinStrIns VARCHAR(500),  
   @cJoinStrUpd  VARCHAR(500), @cJoinCols VARCHAR(500),@LOCS VARCHAR(MAX),@RCOUNT INT=0,@ExportToExcel bit=0,  
   @cStep VARCHAR(5),@cErrormsg varchar(1000),@SETUP_ID vArcHAR(100)='SKPI00'+CAST(@nMode AS vArcHaR),  
   @cLayoutColsMissing VARCHAR(400),@PAGE_SIZE INT,@cHoLocId VARCHAR(5),@DEF_SIZE INT=800  
   ,@SUB_TOTAL_REQ BIT=0,@SUB_TOTAL_REC INT=0  
      
    SET @nMode=RIGHT(@cMemoId,1)  
    PRINT @nMODE  
    PRINT 'PNO PASSED '+@PNO  
    IF @PNO ='' OR @PNO IS NULL OR @PNO='0'   
       SET @PNO='1;'  
    IF CHARINDEX(';',@PNO)=0  
       SET @PNO+=';'  
    PRINT 'PNO SET '+@PNO  
    SET @LOCS=SUBSTRING(@PNO,CHARINDEX(';',@PNO)+1,4000)  
    SET @PNO=LEFT(@PNO,CHARINDEX(';',@PNO)-1)  
    IF @LOCS<>''  
       SET @LOCS=''''+REPLACE(@LOCS,'+',''',''')+''''  
    PRINT 'LOC EXTRACTED '+@LOCS  
    PRINT 'PNO EXTRACTED '+@PNO  
 IF @PNO=-1 SET @ExportToExcel=1  
    SELECT TOP 1 @PAGE_SIZE=CAST(VALUE AS INT) FROM CONFIG WHERE  config_option='PAGING'     
    SET @PAGE_SIZE=CASE ISNULL(@PAGE_SIZE,0) WHEN 0 THEN @DEF_SIZE ELSE @PAGE_SIZE END  
    PRINT '@PAGE_SIZE '+CONVERT(VARCHAR,@PAGE_SIZE)  
    SELECT TOP 1 @cHoLocId=value FROM config WHERE config_option='ho_location_id'  
      
 IF NOT EXISTS(SELECT * FROM DBKPI_COLOR_SCHEMA WHERE SETUP_ID=@SETUP_ID)  
    SELECT TOP 1 @SETUP_ID=SETUP_ID FROM DBKPI_COLOR_SCHEMA    
   
BEGIN TRY  
   
 SET @cErrormsg=''  
  
 SET @cStep='10'  
 IF @nMode=1  
  SELECT @cLayoutCols='a.DEPT_ID,'''' as article_code,'''' as article_no,'''' as para2_code,'''' as para2_name,',  
      @cGroupCols='a.dept_id',  
      @cJoinCols=' a.target_dt=b.target_dt AND  a.DEPT_ID=B.DEPT_ID',  
      @cLayoutColsMissing='a.DEPT_ID,'''' as article_code,'''' as article_no,'''' as para2_code,'''' as para2_name,'  
 ELSE  
 IF @nMode=2  
  SELECT @cLayoutCols='a.DEPT_ID,sku.article_Code,ARTICLE_NO,'''' as para2_code,'''' as para2_name,',  
      @cGroupCols='a.dept_id,sku.article_Code,ARTICLE_NO',  
      @cJoinCols='  a.target_dt=b.target_dt AND  a.DEPT_ID=B.DEPT_ID AND a.article_code=b.article_code ',  
      @cLayoutColsMissing='a.DEPT_ID,c.article_Code,c.ARTICLE_NO,'''' as para2_code,'''' as para2_name,'        
 ELSE  
 IF @nMode=3  
  SELECT @cLayoutCols='a.DEPT_ID,a.article_Code,ARTICLE_NO,a.para2_Code,PARA2_NAME,',  
      @cGroupCols='a.DEPT_ID,a.article_Code,ARTICLE_NO,a.para2_Code,PARA2_NAME,',  
      @cJoinCols=' a.target_dt=b.target_dt AND a.DEPT_ID=B.DEPT_ID AND a.article_code=b.article_code AND a.para2_code=b.para2_code ',  
      @cLayoutColsMissing='a.DEPT_ID,c.article_Code,c.ARTICLE_NO,d.para2_Code,d.PARA2_NAME,'         
   
 SET @cStep='20'  
 IF OBJECT_ID('tempdb..#tmpRep','U') IS NOT NULL  
  DROP TABLE #tmpRep  
  
 IF OBJECT_ID('tempdb..#tmpRepFinal','U') IS NOT NULL  
  DROP TABLE #tmpRepFinal  
   
 SET @cStep='30'  
 --SET @cJoinStr='JOIN slstarget_det b  ON '+@cJoinCols    
 --CORRECTION  
 --If @NModE!=2  
    SELECT @cJoinStrIns='JOIN #tmpRep b  ON '+@cJoinCols,  
     @cJoinStrUpd='JOIN (SELECT target_Dt,'+REPLACE(@cLayoutCols,'sku.','a.')+'SUM(target_value) as target_value,  
          SUM(target_qty) as target_qty FROM slstarget_det a  
          JOIN article b (NOLOCK) ON a.article_code=b.article_code  
          JOIN para2 c (NOLOCK) ON a.para2_code=c.para2_code  
          GROUP BY target_Dt,'+REPLACE(@cGroupCols,'sku.','a.')+') b  ON '+@cJoinCols    
 --ELSE   
   -- SET @cJoinStr='JOIN slstarget_det b  ON ArTIcLE Art (NOLOCK) On B.ARtIClE_CoDE=aRT.ArTICLE_CODE ON '+rePLaCE(@cJoinCols,'b.ARTICLE_NO','ArT.ARTICLE_no')       
 --CORRECTION  
   
 CREATE TABLE #tmpRep (DEPT_ID CHAR(2),target_Dt datetime,article_Code varchar(10),ARTICLE_NO VARCHAR(400),  
 para2_Code varchar(10),para2_name VARCHAR(400),actual_sale_value NUMERIC(10,2),actual_sale_qty NUMERIC(10,2),  
 planned_sale_value numeric(10,2),planned_sale_qty numeric(10,2))  
  
 CREATE TABLE #tmpRepFinal (DEPT_ID CHAR(2),ARTICLE_NO VARCHAR(400),para2_name VARCHAR(400),  
 actual_sale_value NUMERIC(10,2),actual_sale_value_per_day NUMERIC(10,2),planned_sale_value numeric(10,2),planned_sale_value_per_day numeric(10,2),  
 actual_sale_qty NUMERIC(10,2),actual_sale_qty_per_day NUMERIC(10,2),planned_sale_qty numeric(10,2),planned_sale_qty_per_day numeric(10,2),  
 current_stock numeric(10,2),days_of_stock_actual numeric(10,0),days_of_stock_planned numeric(10,0),SNO INT,SUB_TOTAL_REC INT)  
  
 SET @cStep='40'       
 SET @cCmd=N'SELECT cm_Dt,'+@cLayoutCols+'SUM(net-cmm_discount_amount) AS actual_sale_value,  
    SUM(quantity) AS actual_sale_qty,0 as planned_sale_value,0 as planned_sale_qty  
    FROM cmd01106 a (NOLOCK)  
    JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id  
    JOIN sku_names c (NOLOCK) ON c.product_code=a.product_code  
    JOIN sku (NOLOCK) ON sku.product_code=a.product_code  
    JOIN location loc (NOLOCK) ON loc.dept_id=b.location_code 
    WHERE cm_dt BETWEEN '''+CONVERT(VARCHAR,@FromDT,110)+''' AND  '''+CONVERT(VARCHAR,@ToDT,110)+'''  
    AND Loc.inactive=0 AND loc.dept_id<>'''+@cHoLocId+'''  
    GROUP BY cm_dt,'+@cGroupCols  
   
 PRINT @cCmd  
    
 insert #tmpRep (target_dt,DEPT_ID,article_code,ARTICLE_NO,para2_Code,PARA2_NAME,actual_sale_value,actual_sale_qty,planned_sale_value,planned_sale_qty)  
 EXEC SP_EXECUTESQL @cCmd  
   
 SET @cStep='45'  
   
 SET @cCmd=N'UPDATE a SET planned_sale_value=b.target_value,planned_sale_qty=b.target_qty  
 FROM #tmpRep a '+@cJoinStrUpd  
 PRINT @cCmd  
 EXEC SP_EXECUTESQL @cCmd  
   
 SET @cStep='47'  
 --select 'check #tmpRep before insert',* from #tmpRep where DEPT_ID='64'  
   
 SET @cCmd=N'SELECT a.target_Dt,'+@cLayoutColsMissing+'0 as actual_sale_value,a.TARGET_VALUE  
 ,0 as actual_sale_qty,a.TARGET_qty  
 FROM slstarget_det a   
 LEFT OUTER '+@cJoinStrIns+'  
 JOIN article c (NOLOCK) ON c.article_code=a.article_code  
 JOIN para2 d (NOLOCK) ON d.para2_code=a.para2_code  
 JOIN location loc (NOLOCK) ON loc.dept_id=a.dept_id  
 WHERE a.target_dt BETWEEN '''+CONVERT(VARCHAR,@FromDT,110)+''' AND  '''+CONVERT(VARCHAR,@ToDT,110)+'''  
 AND loc.inactive=0 AND b.dept_id IS NULL  AND loc.dept_id<>'''+@cHoLocId+''''  
   
 PRINT @cCmd  
 SET @cStep='50'  
 insert #tmpRep (target_dt,DEPT_ID,article_code,ARTICLE_NO,para2_code,PARA2_NAME,actual_sale_value,planned_sale_value,actual_sale_qty,planned_sale_qty)  
 EXEC SP_EXECUTESQL @cCmd  
   
 --select 'check #tmpRep after insert',* from #tmpRep where DEPT_ID='64'  
    
 --select sum(planned_sale_value) from #tmpRep where DEPT_ID='64'  
   
 SET @cStep='60'  
 IF OBJECT_ID('tempdb..#tmpDates','u') IS NOT NULL  
  DROP TABLE #tmpDates  
   
 SELECT DISTINCT target_Dt into #tmpDates FROM #tmpRep  
  
 DECLARE @cPmtLocs varchar(400),@dXnDt datetime  
  
 SET @cStep='70'  
 INSERT #tmpRepFinal (dept_id,article_no,para2_name,current_stock,actual_sale_value,planned_sale_value,  
 planned_sale_value_per_day,actual_sale_value_per_day,actual_sale_qty,planned_sale_qty,  
 planned_sale_qty_per_day,actual_sale_qty_per_day)  
 SELECT DEPT_ID  
 ,ARTICLE_NO  
 ,para2_name  
 ,0 as current_stock  
 ,sum(actual_sale_Value) as actual_sale_Value  
 ,sum(planned_sale_value) as planned_sale_value  
 ,0 as planned_sale_value_per_day  
 ,0 as actual_sale_value_per_day  
 ,sum(actual_sale_qty) as actual_sale_qty  
 ,sum(planned_sale_qty) as planned_sale_qty  
 ,0 as planned_sale_qty_per_day  
 ,0 as actual_sale_qty_per_day  
 FROM #tmpRep   
 GROUP BY DEPT_ID,ARTICLE_NO,para2_name  
    
   
 SET @cStep='75'  
 SET @cPmtLocs=DB_NAME()+'_PMT..PMTLOCS_'+convert(varchar,getdate()-1,112)  
 SET @cJoinCols=REPLACE(@cJoinCols,'a.target_dt=b.target_dt AND ','')  
 SET @cJoinCols=REPLACE(@cJoinCols,'article_code','article_no')  
 SET @cJoinCols=REPLACE(@cJoinCols,'para2_code','para2_name')  
   
 SET @cCmd=N'UPDATE a SET current_stock=b.cbs_qty FROM #tmpRepFinal a   
    JOIN (SELECT '+@cLayoutCols+'SUM(cbs_qty) as cbs_qty FROM '+@cPmtLocs+' a  
      JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code  
      JOIN sku (NOLOCK) ON sku.product_code=sn.product_code  
      GROUP BY '+@cGroupCols+') b ON '+@cJoinCols  
 --PRINT @cCmd  
 EXEC SP_EXECUTESQL @cCmd  
  
 SET @cStep='80'  
 --CORRECTION  
 --UPDATE #tmpRepFinal SET PLANNED_sale_per_day=PLANNED_sale/DATEDIFF(DD,@FromDT,@ToDT)  
 UPDATE #tmpRepFinal SET PLANNED_sale_value_per_day=PLANNED_sale_Value/(CASE DATEDIFF(DD,@FromDT,@ToDT) WHEN 0 THEN 1 ELSE DATEDIFF(DD,@FromDT,@ToDT) END),  
 PLANNED_sale_qty_per_day=PLANNED_sale_qty/(CASE DATEDIFF(DD,@FromDT,@ToDT) WHEN 0 THEN 1 ELSE DATEDIFF(DD,@FromDT,@ToDT) END)  
   
 IF OBJECT_ID('tempdb..#tmpDays','u') IS NOT NULL  
  DROP TABLE #tmpDays  
   
 SELECT location_code as dept_id,min(cm_dt) as from_dt,MAX(cm_dt) as to_dt  
 INTO #tmpDays   
 FROM cmm01106 (NOLOCK)  
 WHERE CM_DT BETWEEN @FromDT AND @ToDT   
 GROUP BY location_Code   
    
 SET @cStep='85'  
 --CORRECTION  
 --UPDATE #tmpRepFinal SET actual_sale_per_day=actual_sale/DATEDIFF(DD,@FromDT,@ToDT)  
 UPDATE A SET actual_sale_value_per_day=actual_sale_Value/(CASE DATEDIFF(DD,B.FROM_dT,B.TO_dT) WHEN 0 THEN 1 ELSE DATEDIFF(DD,B.FROM_dT,B.TO_dT) END),  
    actual_sale_qty_per_day=actual_sale_qty/(CASE DATEDIFF(DD,B.FROM_dT,B.TO_dT) WHEN 0 THEN 1 ELSE DATEDIFF(DD,B.FROM_dT,B.TO_dT) END)   
 from #tmpRepFinal A JOIN #tmpDays B ON A.dept_id=B.dept_id  
    
 UPDATE #tmpRepFinal SET days_of_stock_actual=current_stock/actual_sale_qty_per_day WHERE actual_sale_qty_per_day<>0  
 UPDATE #tmpRepFinal SET days_of_stock_planned=current_stock/planned_sale_qty_per_day WHERE planned_sale_qty_per_day<>0  
    
 SET @cStep='87'  
 IF @LOCS<>''  
    BEGIN  
      SET @cCmd='DELETE #tmpRepFinal WHERE DEPT_ID NOT IN ('+@LOCS+')'  
      EXEC SP_EXECUTESQL @cCmd  
      PRINT CAST(@@ROWCOUNT AS VARCHAR)+' deleted'  
    END     
 IF (SELECT COUNT(*) FROM #tmpRepFinal)<@PAGE_SIZE  
     SET @PNO='1'  
   
 SET @cStep='88'  
 --IF NOT EXISTS(SELECT * FROM tempdb.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%#tmpRepFinal%' AND COLUMN_NAME LIKE 'SNo')  
    --ALTER TABLE #tmpRepFinal ADD SNO INT  
   
 SET @cStep='89'  
 SELECT TOP 1 @SUB_TOTAL_REQ=CAST(VALUE AS BIT) FROM CONFIG WHERE  config_option='SUBT'  
   
 IF @Show_Err IN (0,1) AND @SUB_TOTAL_REQ=1 AND @nMode!=1  
  BEGIN  
   IF OBJECT_ID('tempdb..#Grouped') IS NOT NULL DROP TABLE #Grouped  
   SELECT DEPT_ID,ARTICLE_NO,'' PARA2_NAME,0 SNO,@SUB_TOTAL_REC SUB_TOTAL_REC  
   ,SUM(actual_sale_value)actual_sale_value  
   ,SUM(actual_sale_value_per_day)actual_sale_value_per_day  
   ,SUM(planned_sale_value)planned_sale_value  
   ,SUM(planned_sale_value_per_day)planned_sale_value_per_day  
   ,SUM(actual_sale_qty)actual_sale_qty  
   ,SUM(actual_sale_qty_per_day)actual_sale_qty_per_day  
   ,SUM(planned_sale_qty)planned_sale_qty  
   ,SUM(planned_sale_qty_per_day)planned_sale_qty_per_day  
   ,SUM(current_stock)current_stock  
   ,SUM(days_of_stock_actual)days_of_stock_actual  
   ,SUM(days_of_stock_planned)days_of_stock_planned  
   INTO #Grouped  
   FROM #tmpRepFinal   
   GROUP BY DEPT_ID,ARTICLE_NO WITH ROLLUP  
   ORDER BY 1  
   
   DELETE #tmpRepFinal  
   
   INSERT #tmpRepFinal(DEPT_ID,ARTICLE_NO,PARA2_NAME,SNO,SUB_TOTAL_REC  
   ,actual_sale_value,actual_sale_value_per_day,planned_sale_value,planned_sale_value_per_day,actual_sale_qty  
   ,actual_sale_qty_per_day,planned_sale_qty,planned_sale_qty_per_day,current_stock,days_of_stock_actual,days_of_stock_planned)  
   SELECT DEPT_ID,ISNULL(ARTICLE_NO,'Total'),PARA2_NAME,SNO,SUB_TOTAL_REC  
   ,actual_sale_value,actual_sale_value_per_day,planned_sale_value,planned_sale_value_per_day,actual_sale_qty  
   ,actual_sale_qty_per_day,planned_sale_qty,planned_sale_qty_per_day,current_stock,days_of_stock_actual,days_of_stock_planned  
   FROM #Grouped WHERE DEPT_ID IS NOT NULL  
  END  
   
 ;WITH CTE AS (SELECT T.DEPT_ID,ARTICLE_NO,R=ROW_NUMBER()OVER(ORDER BY LEFT(L.DEPT_ALIAS,20),ARTICLE_NO)   
      FROM #tmpRepFinal T  
      JOIN LOCATION L (NOLOCK) ON T.DEPT_ID=L.DEPT_ID)  
 UPDATE T SET T.SNO=C.R FROM #tmpRepFinal T JOIN CTE C ON T.DEPT_ID=C.DEPT_ID AND T.ARTICLE_NO=C.ARTICLE_NO;  
   
 IF @Show_Err!=1 AND @nMode!=1  
    BEGIN  
      IF @Show_Err=2  
   INSERT INTO #tmpRepFinal_tmp (DEPT_ID,ARTICLE_NO)  
   SELECT DEPT_ID,ARTICLE_NO  
   FROM #tmpRepFinal t  
   WHERE @PNO=-1  
   OR  
   (  
     (t.SNO BETWEEN CASE @PNO WHEN 1 THEN 1 ELSE (@PNO-1)*@PAGE_SIZE+1+@SUB_TOTAL_REC END AND (@PNO*@PAGE_SIZE)+@SUB_TOTAL_REC AND @Show_Err=0)  
     OR   
     (@Show_Err=2)  
   )  
         ORDER BY SNO  
      ELSE  
         INSERT INTO #tmpRepFinal_tmp (DEPT_ID,ARTICLE_NO,SNO,SUB_TOTAL_REC)  
   SELECT DEPT_ID,ARTICLE_NO,T.SNO,SUB_TOTAL_REC  
   FROM #tmpRepFinal t  
   WHERE @PNO=-1  
   OR  
   (  
    (t.SNO BETWEEN CASE @PNO WHEN 1 THEN 1 ELSE (@PNO-1)*@PAGE_SIZE+1+@SUB_TOTAL_REC END AND (@PNO*@PAGE_SIZE)+@SUB_TOTAL_REC AND @Show_Err=0)  
    OR   
    (@Show_Err=2)  
   )  
   ORDER BY SNO  
      RETURN  
    END  
  
 IF OBJECT_ID('tempdb..#Report','U') IS NOT NULL DROP TABLE Report  
    
 SELECT L.DEPT_ID,left(LTRIM(RTRIM(L.dept_alias)),20) Location  
 ,[Planned_Sale_value]=CAST(ISNULL(planned_sale_value,0) AS FLOAT)  
 ,[Actual_Total_Sale_value]=CAST(ISNULL(actual_sale_value,0) AS FLOAT)   
 ,[Period_value_Shortfall]=CAST(ISNULL(actual_sale_value,0)-ISNULL(planned_sale_value,0) AS FLOAT)  
 ,[Period_value_Variance]=CAST((ISNULL(actual_sale_value,0)-ISNULL(planned_sale_value,0))/CASE ISNULL(planned_sale_value,0) WHEN 0 THEN 1 ELSE ISNuLL(planned_sale_value,0) END*100 as int)   
 ,[Planned_Sale_value_PD]=CAST(ISNULL(planned_sale_value_per_day,0) AS FLOAT)  
 ,[Actual_Sale_value_PD]=CAST(ISNULL(actual_sale_value_per_day,0) AS FLOAT)   
 ,[PD_value_Shortfall]=CAST(ISNULL(actual_sale_value_per_day,0)-ISNULL(planned_sale_value_per_day,0) AS FLOAT)  
 ,[PD_value_Variance]=CAST((ISNULL(actual_sale_value_per_day,0)-ISNULL(planned_sale_value_per_day,0))/case ISNULL(planned_sale_value_per_day,0) WHEN 0 THEN 1 ELSE ISNULL(planned_sale_value_per_day,0) end*100 as int)  
 ,[Stock]=CAST(ISNULL(current_stock,0) AS FLOAT)  
 ,[Days_of_Stock_AsPer_PlannedSale]=CAST(ISNULL(days_of_stock_planned,0) AS FLOAT)  
 ,[Color_Days_of_Stock_AsPer_PlannedSale]=(SELECT tOp 1 COLOR_CODE fRoM DBKPI_COLOR_SCHEMA WHerE SEtUP_iD=@SEtUP_iD aND abs(ISNuLL(days_of_stock_planned,0)) BETWEEN RaNGEFROM AnD RANGEtO)  
 ,[Days_of_Stock_AsPer_ActualSale]=CAST(ISNULL(days_of_stock_actual,0) AS FLOAT)  
 ,[Color_Days_of_Stock_AsPer_ActualSale]=(SELECT tOp 1 COLOR_CODE fRoM DBKPI_COLOR_SCHEMA WHerE SEtUP_iD=@SEtUP_iD aND abs(ISNuLL(days_of_stock_actual,0))  BETWEEN RaNGEFROM AnD RANGEtO)  
 ,ARTICLE_NO  
 ,para2_name  
 ,T.SNO  
 ,[Planned_Sale_Qty]=CAST(ISNuLL(planned_sale_qty,0) AS FLOAT)  
 ,[Actual_Total_Sale_qty]=CAST(ISNuLL(actual_sale_qty,0) AS FLOAT)   
 ,[Period_qty_Shortfall]=CAST(ISNuLL(actual_sale_qty,0)-ISNuLL(planned_sale_qty,0) AS FLOAT)  
 ,[Period_qty_Variance]=cast((ISNuLL(actual_sale_qty,0)-ISNuLL(planned_sale_qty,0))/case ISNuLL(planned_sale_qty,0) when 0 then 1 else ISNuLL(planned_sale_qty,0) end*100 as int)   
 ,[Planned_Sale_qty_PD]=CAST(ISNuLL(planned_sale_qty_per_day,0) AS FLOAT)  
 ,[Actual_Sale_qty_PD]=CAST(ISNuLL(actual_sale_qty_per_day,0) AS FLOAT)   
 ,[PD_qty_Shortfall]=CAST(ISNuLL(actual_sale_qty_per_day,0)-ISNuLL(planned_sale_qty_per_day,0) AS FLOAT)  
 ,[PD_qty_Variance]=cast((ISNuLL(actual_sale_qty_per_day,0)-ISNuLL(planned_sale_qty_per_day,0))/ case ISNuLL(planned_sale_qty_per_day,0) when 0 then 1 else ISNuLL(planned_sale_qty_per_day,0) end*100 as int)    
 INTO #Report  
 FROM #tmpRepFinal T  
 JOIN LOCATION L (NOLOCK) ON T.DEPT_ID=L.DEPT_ID  
 WHERE @PNO=-1 OR (@PNO>0 AND T.SNO BETWEEN CASE @PNO WHEN 1 THEN 1 ELSE (@PNO-1)*@PAGE_SIZE+1 END AND @PNO*@PAGE_SIZE)  
 SET @RCOUNT=@@ROWCOUNT  
   
 IF @nMode=1 OR @PNO=-1 SET @PAGE_SIZE=(SELECT MAX(SNO)+1 FROM #Report)--Old:@RCOUNT+1  
 PRINT @PAGE_SIZE  
   
 IF @nMode=1 AND 1=1  
    INSERT #Report  
    SELECT ''DEPT_ID,'Total'Location  
  ,SUM([Planned_Sale_value]) ,SUM([Actual_Total_Sale_value]) ,SUM([Period_value_Shortfall])  
    ,SUM([Period_value_Variance]) ,SUM([Planned_Sale_value_PD]) ,SUM([Actual_Sale_value_PD])  
    ,SUM([PD_value_Shortfall]) ,SUM([PD_value_Variance]) ,SUM([Stock]) ,SUM([Days_of_Stock_AsPer_PlannedSale])  
    ,'' ,SUM([Days_of_Stock_AsPer_ActualSale]),'','','',@PAGE_SIZE AS SNO  
    ,SUM([Planned_Sale_qty]),SUM([Actual_Total_Sale_qty]),SUM([Period_qty_Shortfall])  
    ,SUM([Period_qty_Variance]),SUM([Planned_Sale_qty_PD]),SUM([Actual_Sale_qty_PD])   
    ,SUM([PD_qty_Shortfall]),SUM([PD_qty_Variance])  
    FROM #Report  
    
 IF @ExportToExcel=1  
  SELECT ARTICLE_NO [Article],Location  
  ,Planned_Sale_qty AS [Period Planned Qty]  
  ,Actual_Total_Sale_qty AS [Period Actual Qty]  
  ,Period_qty_Shortfall AS [Period Shortfall Qty]   
  ,Period_qty_Variance  AS [Period Variance Qty]    
  ,Planned_Sale_value AS [Period Planned NRV]  
  ,Actual_Total_Sale_value AS [Period Actual NRV]  
  ,Period_value_Shortfall AS [Period Shortfall NRV]  
  ,Period_value_Variance AS [Period Variance NRV]  
  ,Planned_Sale_qty_PD AS [PerDay Planned Qty]   
  ,Actual_Sale_qty_PD AS [PerDay Actual Qty]   
  ,PD_qty_Shortfall AS [PerDay Shortfall Qty]    
  ,PD_qty_Variance AS [PerDay Variance Qty]  
  ,Planned_Sale_value_PD AS [PerDay Planned NRV]  
  ,Actual_Sale_value_PD  AS [PerDay Actual NRV]  
  ,PD_value_Shortfall  AS [PerDay Shortfall NRV]  
  ,PD_value_Variance  AS [PerDay Variance NRV]  
  ,Stock AS Stock  
  ,Days_of_Stock_AsPer_PlannedSale AS [Days of Stock AsPer Planned Sale]  
  ,Days_of_Stock_AsPer_ActualSale AS [Days of Stock AsPer Actual Sale]  
  FROM #Report   
   ORDER BY SNO   
 ELSE  
  SELECT DEPT_ID,Location  
  ,DBO.processs_val(Planned_Sale_value,2)Planned_Sale_value  
  ,DBO.processs_val(Actual_Total_Sale_value,2)Actual_Total_Sale_value  
  ,DBO.processs_val(Period_value_Shortfall,2)Period_value_Shortfall  
  ,DBO.processs_val(Period_value_Variance,0)Period_value_Variance  
  ,DBO.processs_val(Planned_Sale_value_PD,2)Planned_Sale_value_PD  
  ,DBO.processs_val(Actual_Sale_value_PD,2)Actual_Sale_value_PD  
  ,DBO.processs_val(PD_value_Shortfall,2)PD_value_Shortfall  
  ,DBO.processs_val(PD_value_Variance,0)PD_value_Variance  
  ,DBO.processs_val(Stock,2)Stock  
  ,DBO.processs_val(Days_of_Stock_AsPer_PlannedSale,2)Days_of_Stock_AsPer_PlannedSale  
  ,Color_Days_of_Stock_AsPer_PlannedSale  
  ,DBO.processs_val(Days_of_Stock_AsPer_ActualSale,2)Days_of_Stock_AsPer_ActualSale  
  ,Color_Days_of_Stock_AsPer_ActualSale  
  ,ARTICLE_NO  
  ,para2_name  
  ,SNO  
  ,DBO.processs_val(Planned_Sale_qty,2)Planned_Sale_qty  
  ,DBO.processs_val(Actual_Total_Sale_qty,2)Actual_Total_Sale_qty  
  ,DBO.processs_val(Period_qty_Shortfall,2)Period_qty_Shortfall   
  ,DBO.processs_val(Period_qty_Variance,0)Period_qty_Variance   
  ,DBO.processs_val(Planned_Sale_qty_PD,2)Planned_Sale_qty_PD   
  ,DBO.processs_val(Actual_Sale_qty_PD,2)Actual_Sale_qty_PD   
  ,DBO.processs_val(PD_qty_Shortfall,2)PD_qty_Shortfall   
  ,DBO.processs_val(PD_qty_Variance,0)PD_qty_Variance  
   FROM #Report   
   ORDER BY SNO  
 GOTO end_proc  
END TRY  
  
BEGIN CATCH  
 SET @cErrormsg='Error in Procedure at Step#'+@cStep+' '+ERROR_MESSAGE()  
 PRINT 'REP FROM GR : CATCH '+@cErrormsg  
 GOTO end_proc  
END CATCH   
  
END_PROC:  
IF @Show_Err=1 AND ISNULL(@cErrormsg,'')<>''  
   SELECT @cErrormsg AS ERROR_MSG  
SET NOCOUNT OFF     
END  