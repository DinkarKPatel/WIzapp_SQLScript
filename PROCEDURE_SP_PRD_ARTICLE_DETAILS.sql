CREATE PROCEDURE DBO.SP_PRD_ARTICLE_DETAILS
(@ORDER_ID VARCHAR(200)='')
AS
 BEGIN
  --DECLARE LOCAL VARIABLE
    DECLARE @LOOPSTART INT
           ,@LOOPEND INT
           ,@ARTICLE_NO VARCHAR(100)
           ,@AC_NAME VARCHAR(200)
           ,@ORDER_DT DATETIME
           ,@ORDER_NO VARCHAR(100)
           ,@DT_CREATED VARCHAR(200)
           ,@FIXEDNOOFROW INT
           ,@INCREASEROW INT
           ,@UPDATEID INT
           ,@ORDERID VARCHAR(100)
           ,@FILEPATH  VARCHAR(500)
  IF OBJECT_ID('TEMPDB..#ROW_ARTICLE') IS NOT NULL
     DROP TABLE #ROW_ARTICLE
  CREATE TABLE #ROW_ARTICLE
	 (
	   ID INT IDENTITY(1,1) 
	  ,AC_NAME VARCHAR(500)
	  ,ORDERID VARCHAR(100)
	  ,ORDER_NO VARCHAR(100)
	  ,ORDERDATE DATETIME
	  ,ARTICLE_NO VARCHAR(200)
	  ,DT_CREATED VARCHAR(200)
	 )
	 --SELECT FILE PATH FROM CONFIG
	 SELECT TOP 1 @FILEPATH='FILE:\\\'+REPLACE(VALUE,'\','/') FROM DBO.CONFIG WITH(NOLOCK)
     WHERE CONFIG_OPTION = 'ART_PICT_PATH'
	 
   INSERT INTO #ROW_ARTICLE(AC_NAME,ORDERID,ORDER_NO,ORDERDATE,ARTICLE_NO,DT_CREATED)
   SELECT DISTINCT LM.AC_NAME,BOD.ORDER_ID ,BOM.ORDER_NO,BOM.ORDER_DT, 
		  AC.ARTICLE_NO,AC.DT_CREATED 
	FROM DBO.BUYER_ORDER_DET BOD WITH(NOLOCK)
	JOIN BUYER_ORDER_MST BOM WITH(NOLOCK) ON BOD.ORDER_ID=BOM.ORDER_ID
	JOIN LM01106 LM WITH(NOLOCK) ON BOM.AC_CODE=LM.AC_CODE
	JOIN DBO.ARTICLE AC WITH(NOLOCK) ON BOD.ARTICLE_CODE=AC.ARTICLE_CODE
	WHERE (BOM.ORDER_ID=@ORDER_ID)
	
	SET @LOOPEND=@@ROWCOUNT;
	
	--SELECT * FROM #ROW_ARTICLE
	--GROUP BY LM.AC_NAME,BOD.ORDER_ID,BOM.ORDER_DT,AC.ARTICLE_NO
	 
	IF OBJECT_ID('TEMPDB..#ARTICLE_DETAILS') IS NOT NULL
     DROP TABLE #ARTICLE_DETAILS
	CREATE TABLE #ARTICLE_DETAILS
	(
	   ID INT IDENTITY(1,1)
	  ,AC_NAME VARCHAR(200)
	  ,ORDER_ID VARCHAR(100)
	  ,ORDER_NO VARCHAR(100)
	  ,ORDER_DT DATETIME
	  ,ARTICLE1 VARCHAR(200)
	  ,ARTICLE2 VARCHAR(200)
	  ,ARTICLE3 VARCHAR(200)
	  ,DT_CREATED1 VARCHAR(200)
	  ,DT_CREATED2 VARCHAR(200)
	  ,DT_CREATED3 VARCHAR(200)
	)
	
	SET @FIXEDNOOFROW=3
	SET @INCREASEROW=1
	SET @LOOPSTART=1
	WHILE @LOOPEND >=@LOOPSTART
	  BEGIN
	  SELECT @ARTICLE_NO=ARTICLE_NO,@ORDER_DT=ORDERDATE
	        ,@ORDER_NO=ORDER_NO ,@AC_NAME=AC_NAME
	        ,@ARTICLE_NO=ARTICLE_NO,@DT_CREATED=DT_CREATED
	        ,@ORDERID=ORDERID
	  FROM #ROW_ARTICLE WHERE ID=@LOOPSTART
	   
	   SET @DT_CREATED=@FILEPATH+@DT_CREATED+'/'+@ARTICLE_NO+'.JPG'
	   
	     IF @INCREASEROW = 1
	      BEGIN
			 INSERT INTO #ARTICLE_DETAILS(AC_NAME,ORDER_ID,ORDER_NO,ORDER_DT,ARTICLE1,DT_CREATED1)
			 SELECT @AC_NAME,@ORDERID,@ORDER_NO,@ORDER_DT,@ARTICLE_NO,@DT_CREATED
			 SET @UPDATEID=SCOPE_IDENTITY();
	      END
	    IF @INCREASEROW = 2
	      BEGIN
			 UPDATE #ARTICLE_DETAILS SET ARTICLE2=@ARTICLE_NO,DT_CREATED2=@DT_CREATED
			 WHERE  ORDER_ID=@ORDER_ID AND ID=@UPDATEID
	       END
	    IF @INCREASEROW = 3
	    BEGIN
	     UPDATE #ARTICLE_DETAILS SET ARTICLE3=@ARTICLE_NO,DT_CREATED3=@DT_CREATED
	     WHERE  ORDER_ID=@ORDER_ID  AND ID=@UPDATEID
	    END

	     IF @FIXEDNOOFROW = @INCREASEROW
	     BEGIN
	      SET @FIXEDNOOFROW=3
	      SET @INCREASEROW=0
	      SET @UPDATEID=0
	     END
	     
	    SET @INCREASEROW=@INCREASEROW+1;
	     	     	  
	  SET @LOOPSTART=@LOOPSTART+1;
	  
	  
	 END
	 
	 SELECT AC_NAME,ORDER_NO ,ORDER_DT ,ARTICLE1,ARTICLE2,ARTICLE3,DT_CREATED1 ,DT_CREATED2,DT_CREATED3  
	 FROM #ARTICLE_DETAILS
END
