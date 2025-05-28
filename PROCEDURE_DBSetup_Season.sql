CREATE PROCEDURE [dbo].[DBSetup_Season](@nMode int,@Value varchar(MAX)='')  
AS  
BEGIN  
SET NOCOUNT ON  
DECLARE @Season VARCHAR(100),@FROMDATE DATETIME,@TODATE DATETIME,@VAL VARCHAR(MAX),@ERR BIT=0,@YR INT=0,@TMP VARCHAR(200)  
  
IF @nMode=1--SAVE/EDIT  
   BEGIN  
      BEGIN TRY  
   BEGIN TRAN  
      IF @Value='' SELECT @ERR=1,@VAL='No set of value(s) specified'  
      IF @ERR=1   
         BEGIN  
           ROLLBACK   
           GOTO EXT     
         END  
      IF RIGHT(@Value,1)<>';' SET @Value+=';'  
      SET @VAL=@Value  
      --PRINT 'SUPER SET '+@val  
      DELETE POS_DB_SEASONS  
      WHILE CHARINDEX(';',@Val)>0  
         BEGIN  
            SET @Value=LEFT(@VAL,CHARINDEX(';',@VAL)-1)  
            --PRINT 'SUB SET '+@value  
   SET @FROMDATE=LEFT(@Value,CHARINDEX(',',@Value)-1)  
   SET @Value=SUBSTRING(@Value,CHARINDEX(',',@Value)+1,4000)  
   SET @TODATE=LEFT(@Value,CHARINDEX(',',@Value)-1)  
   SET @Value=SUBSTRING(@Value,CHARINDEX(',',@Value)+1,4000)  
   SET @Season=@Value  
   IF ISNULL(@Season,'')=''  
      SELECT @ERR=1,@VAL='Season name can not be blank'  
   IF @ERR=1   
      BEGIN  
                 ROLLBACK   
                 GOTO EXT     
               END  
   IF @TODATE<@FROMDATE  
      SELECT @ERR=1,@VAL='To Date can not be less than From Date for season '''+@Season+''''  
   IF @ERR=1   
      BEGIN  
                 ROLLBACK   
                 GOTO EXT     
               END  
   --START: SAVE NEUTRAL YEAR(ONLY DATE AND MONTH)  
   --IF @TODATE<@FROMDATE SET @TODATE=DATEADD(MM,12,@TODATE)  
   --SET @YR=YEAR(@TODATE)-YEAR(@FROMDATE)  
   --SET @FROMDATE=DATEADD(YY,1900-YEAR(@FROMDATE),@FROMDATE)  
   --SET @TODATE=DATEADD(YY,1900+@YR-YEAR(@TODATE),@TODATE)  
   --ENDS: SAVE NEUTRAL YEAR(ONLY DATE AND MONTH)  
   SET @TMP=''  
   SELECT TOP 1 @TMP=season_name FROM POS_DB_SEASONS (NOLOCK) WHERE @FROMDATE BETWEEN from_dt AND to_dt  
   IF ISNULL(@TMP,'')<>''  
      SELECT @ERR=1,@VAL='From Date of season '''+@Season+''' already exists for another season '''+@TMP+''''  
   IF @ERR=1   
      BEGIN  
                 ROLLBACK   
                 GOTO EXT     
               END  
   SET @TMP=''  
   SELECT TOP 1 @TMP=season_name FROM POS_DB_SEASONS (NOLOCK) WHERE @TODATE BETWEEN from_dt AND to_dt  
   IF ISNULL(@TMP,'')<>''  
      SELECT @ERR=1,@VAL='To Date of season '''+@Season+''' already exists for another season '''+@TMP+''''  
   IF @ERR=1   
      BEGIN  
                 ROLLBACK   
                 GOTO EXT     
               END  
   MERGE POS_DB_SEASONS D  
   USING (SELECT @Season season_name,@FROMDATE from_dt,@TODATE to_dt)S ON S.Season_Name=D.Season_Name  
   WHEN MATCHED THEN UPDATE SET D.FROM_DT=@FROMDATE,D.TO_DT=@TODATE  
   WHEN NOT MATCHED THEN INSERT(Season_Name,FROM_DT,TO_DT) VALUES(@Season,@FROMDATE,@TODATE);  
   --REST OF @VAL  
   SET @VAL=SUBSTRING(@VAL,CHARINDEX(';',@VAL)+1,4000)  
   END   
     END TRY  
       
     BEGIN CATCH  
        SELECT @ERR=1,@VAL=ERROR_MESSAGE()  
     END CATCH     
       
     IF @VAL=''  
        COMMIT  
     ELSE  
        ROLLBACK     
   END  
     
ELSE IF @nMode=2  
   SELECT * FROM POS_DB_SEASONS (NOLOCK)  
     
EXT:  
IF @ERR=0 SET @VAL=''   
SELECT @VAL ERROR_MSG     
SET NOCOUNT OFF  
END 