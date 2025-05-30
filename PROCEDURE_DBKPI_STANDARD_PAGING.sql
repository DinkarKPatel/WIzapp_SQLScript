CREATE PROCEDURE DBKPI_STANDARD_PAGING (@SetupID VARCHAR(10),@FromDT VARCHAR(10),@ToDt VARCHAR(10))  
AS  
BEGIN  
SET NOCOUNT ON  
DECLARE @REC BIGINT,@PAGE_SIZE INT,@DEF_SIZE INT=1000  
IF OBJECT_ID('TEMPDB..#tmpRepFinal_tmp') IS NOT NULL DROP TABLE #tmpRepFinal_tmp  
CREATE TABLE #tmpRepFinal_tmp (DEPT_ID VARCHAR(10),ARTICLE_NO VARCHAR(400))  
  
IF RIGHT(@SetupID,1)='2'  
   EXEC SP3S_GETSLSTARGET_rep @cMemoId='2',@nMode=2,@FromDT=@FROMDT,@ToDt=@TODT,@show_err=2  
  
IF NOT EXISTS(SELECT * FROM CONFIG WHERE config_option='PAGING')
   INSERT CONFIG(config_option,value,row_id,last_update,REMARKS)
   SELECT 'PAGING',1000,NEWID(),GETDATE(),''
   
SELECT TOP 1 @PAGE_SIZE=CAST(VALUE AS INT) FROM CONFIG WHERE  config_option='PAGING'  
SET @PAGE_SIZE=CASE ISNULL(@PAGE_SIZE,0) WHEN 0 THEN @DEF_SIZE ELSE @PAGE_SIZE END  
  
SELECT @REC=COUNT(*) FROM #tmpRepFinal_tmp     
SET @REC=ISNULL(@REC,0)  
SET @REC=@REC/@PAGE_SIZE+CASE @REC%@PAGE_SIZE WHEN 0 THEN 0 ELSE 1 END  
  
IF OBJECT_ID('TEMPDB..#Paging') IS NOT NULL DROP TABLE #Paging  
CREATE TABLE #Paging(PageNo int)  
WHILE @REC>0  
 BEGIN  
    INSERT #Paging SELECT @REC  
    SET @REC-=1  
 END  
SELECT * FROM #Paging ORDER BY 1   
SET NOCOUNT OFF     
END