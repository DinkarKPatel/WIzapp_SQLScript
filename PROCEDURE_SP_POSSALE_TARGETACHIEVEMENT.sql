create PROCEDURE SP_POSSALE_TARGETACHIEVEMENT
 (
	  @DTODATE  VARCHAR(50),
	  @MCONVERSIONFACTOR   INT=1,
	  @YCONVERSIONFACTOR   INT=1
 )
--WITH ENCRYPTION
AS
BEGIN
  --(dinkar) Replace  left(memoid,2) to Location_code 
  DECLARE @CCMD NVARCHAR(MAX),@DAYAMOUNT NUMERIC(18,0),@DEPT_NAME VARCHAR(100),
          @CURRENTYEAR VARCHAR(10),@PREVIOUSYEAR VARCHAR(10),@DFDAY VARCHAR(100),
          @FINYEARSTART VARCHAR(100),@LFINYEAREND VARCHAR(100), @DPREV_TODATE  VARCHAR(20),
          @TMPTARGETAMOUNT NUMERIC(12,2)
          
  
    --------MONTH DIVISION FACTOR---- 
	  IF @MCONVERSIONFACTOR=1  
		  SET @MCONVERSIONFACTOR=1000  
	  ELSE IF @MCONVERSIONFACTOR=2  
		  SET @MCONVERSIONFACTOR=100000  
	  ELSE IF @MCONVERSIONFACTOR=3  
		  SET @MCONVERSIONFACTOR=10000000   
   
 --------YEAR DIVISION FACTOR----      
      IF @YCONVERSIONFACTOR=1  
	     SET @YCONVERSIONFACTOR=1000  
      ELSE IF @YCONVERSIONFACTOR=2  
	     SET @YCONVERSIONFACTOR=100000  
     ELSE IF @YCONVERSIONFACTOR=3  
	     SET @YCONVERSIONFACTOR=10000000           
	          
 
   SET @CURRENTYEAR  =  (SELECT '01'+ DBO.FN_GETFINYEAR(@DTODATE)) 
   SET @DPREV_TODATE =  (SELECT DATEADD(YEAR,-1,@DTODATE)) ----SET PREV YEAR DATE
   SET @PREVIOUSYEAR =  (SELECT '01'+ DBO.FN_GETFINYEAR(@DPREV_TODATE))    
	    
	  DECLARE @TMPTABLE TABLE(DEPT_ID VARCHAR(5),MTRGT NUMERIC(12,2) DEFAULT 0,MSALE NUMERIC(12,2),MACH NUMERIC(10,2),
											     MLY  NUMERIC(12,2),MINC NUMERIC(10,0),
											     YTRGT NUMERIC(12,2) DEFAULT 0,YSALE NUMERIC(12,2),YACH NUMERIC(10,2),
	                                             YLY  NUMERIC(12,2),YINC NUMERIC(10,0))  
	                            
	           
	  SET @CCMD=N'SELECT DEPT_ID,SUM(MSALE) AS MSALE,SUM(MLY) AS MLY,SUM(YSALE)AS YSALE,SUM(YLY)AS YLY 
				   FROM 
				   (SELECT Location_code AS DEPT_ID,
				    SUM(CASE WHEN MONTH(A.CM_DT)=MONTH('''+@DTODATE+''') AND A.FIN_YEAR='''+ @CURRENTYEAR +''' AND A.CM_DT <='''+CONVERT(VARCHAR(11),@DTODATE,120)+''' THEN A.NET_AMOUNT ELSE 0 END) AS MSALE,
				    0 AS MLY,
				    SUM(CASE WHEN A.FIN_YEAR='''+@CURRENTYEAR+''' AND A.CM_DT<='''+CONVERT(VARCHAR(11),@DTODATE,120)+''' THEN A.NET_AMOUNT ELSE 0 END) AS YSALE,
				    0 AS YLY
				 FROM CMM01106 A
				 WHERE A.CANCELLED=0 AND A.FIN_YEAR='''+@CURRENTYEAR+''' AND A.CM_DT <='''+CONVERT(VARCHAR(11),@DTODATE,120)+'''
				 GROUP BY Location_code
			     UNION 
				   SELECT Location_code AS DEPT_ID,
				   0 AS MSALE,
				   SUM(CASE WHEN MONTH(A.CM_DT)=MONTH('''+@DPREV_TODATE+''') AND A.FIN_YEAR='''+@PREVIOUSYEAR+''' AND A.CM_DT <='''+ CONVERT(VARCHAR(11),@DPREV_TODATE,120) +''' THEN A.NET_AMOUNT ELSE 0 END) AS MLY,
				   0 AS YSALE,
				   SUM(CASE WHEN A.FIN_YEAR='''+ @PREVIOUSYEAR +''' AND A.CM_DT <='''+ CONVERT(VARCHAR(11),@DPREV_TODATE,120) +''' THEN A.NET_AMOUNT ELSE 0 END) AS YLY
				 FROM CMM01106 A
				 WHERE A.CANCELLED=0 AND A.FIN_YEAR='''+ @PREVIOUSYEAR +''' AND A.CM_DT<='''+ CONVERT(VARCHAR(11),@DPREV_TODATE,120) +'''
			  GROUP BY Location_code ) B
			  GROUP BY DEPT_ID'
               
      PRINT @CCMD
      INSERT INTO @TMPTABLE(DEPT_ID,MSALE,MLY,YSALE,YLY)
      EXEC SP_EXECUTESQL  @CCMD

	                        
	                        
	                        
	   UPDATE @TMPTABLE SET MINC= CASE WHEN MSALE = 0  AND MLY = 0 THEN 0
	                                   WHEN MSALE = 0  AND MLY <>0 THEN -100
	                                   WHEN MSALE <>0  AND MLY = 0 THEN 100
	                                   ELSE (((MSALE-MLY)*100)/MSALE)END,
	                        YINC = CASE WHEN YSALE = 0 AND YLY =0 THEN 0
	                                   WHEN YSALE = 0 AND YLY <>0 THEN -100
	                                   WHEN YSALE <>0 AND YLY = 0 THEN 100
	                                   ELSE(((YSALE-YLY)*100)/YSALE) END                                   
	 
      UPDATE @TMPTABLE SET MSALE = MSALE/@MCONVERSIONFACTOR,
	                       MLY   = MLY/@MCONVERSIONFACTOR,
	                       YSALE = YSALE/@YCONVERSIONFACTOR ,
	                       YLY   = YLY/@YCONVERSIONFACTOR
        
               
	                      
	  UPDATE A SET MTRGT = B.TARGET_AMOUNT/@MCONVERSIONFACTOR , 
	               YTRGT = B.TARGET_AMOUNT/@YCONVERSIONFACTOR
	                        FROM @TMPTABLE A 
	                        JOIN LOC_SALE_TARGET B ON A.DEPT_ID=B.DEPT_ID                                   
	                       AND B.TARGET_MONTH =MONTH(''+@DTODATE+'')
	                       AND B.FIN_YEAR =''+@CURRENTYEAR+'' 
	  


	 
	 UPDATE @TMPTABLE SET MACH = ISNULL((CASE WHEN MSALE =  0 AND MTRGT <> 0 THEN 100  
	                                  WHEN MSALE <> 0 AND MTRGT =  0 THEN 0    
	                                  WHEN MSALE =  0 AND MTRGT =  0 THEN 0   
	                                  ELSE ((MSALE/MTRGT)*100) END),0),
                           YACH =ISNULL((CASE WHEN YSALE =  0 AND YTRGT <> 0 THEN 100  
                                      WHEN YSALE <> 0 AND YTRGT =  0 THEN 0    
                                      WHEN YSALE =  0 AND YTRGT =  0 THEN 0   
                                      ELSE ((YSALE/YTRGT)*100) END),0)    
	                               
	 
	 SELECT B.DEPT_ALIAS , A.* FROM @TMPTABLE A
	 JOIN LOCATION B (NOLOCK)  ON A.DEPT_ID=B.DEPT_ID      

END
