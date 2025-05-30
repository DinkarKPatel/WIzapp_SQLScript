CREATE PROCEDURE SP3S_STOCK_LEVEL_CBS_REPORT
(
  @DASONDATE DATETIME='2018-06-30'
  ,@CLOC VARCHAR(5)=''
)
AS
BEGIN

	IF @CLOC=''
		SELECT SECTION_NAME ,SUB_SECTION_NAME ,PARA1_NAME  ,PARA2_NAME ,A.STOCK_LEVEL_QTY,ISNULL(A.STOCK_QTY,0)   AS CBS,0 AS GIT_QTY,
		A.STOCK_LEVEL_QTY-ISNULL(A.STOCK_QTY,0)  AS REQ_QTY
		FROM LOC_STOCK_LEVEL A (NOLOCK)
		JOIN SECTIOND (NOLOCK) ON A.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE 
		JOIN SECTIONM (NOLOCK) ON A.SECTION_CODE = SECTIONM.SECTION_CODE 
		JOIN PARA1 (NOLOCK) ON A.PARA1_CODE = PARA1.PARA1_CODE 
		JOIN PARA2 (NOLOCK) ON A.PARA2_CODE = PARA2.PARA2_CODE  
		WHERE --A.MEMO_ID='LU111900000LU00000003' AND
		A.STOCK_LEVEL_QTY-ISNULL(A.STOCK_QTY,0)>0
	ELSE	
		SELECT SECTION_NAME ,SUB_SECTION_NAME ,PARA1_NAME  ,PARA2_NAME ,A.STOCK_LEVEL_QTY,ISNULL(A.STOCK_QTY,0)   AS CBS,0 AS GIT_QTY,
		A.STOCK_LEVEL_QTY-ISNULL(A.STOCK_QTY,0)  AS REQ_QTY
		FROM LOC_STOCK_LEVEL A (NOLOCK)
		JOIN SECTIOND (NOLOCK) ON A.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE 
		JOIN SECTIONM (NOLOCK) ON A.SECTION_CODE = SECTIONM.SECTION_CODE 
		JOIN PARA1 (NOLOCK) ON A.PARA1_CODE = PARA1.PARA1_CODE 
		JOIN PARA2 (NOLOCK) ON A.PARA2_CODE = PARA2.PARA2_CODE  
		WHERE --A.MEMO_ID='LU111900000LU00000003' AND
		LEFT(A.MEMO_ID,2)=@CLOC AND
		A.STOCK_LEVEL_QTY-ISNULL(A.STOCK_QTY,0)>0


--             DECLARE @CCMD NVARCHAR(MAX),@COLNAME NVARCHAR(MAX),
--             @SHOW_ARTICLE BIT,@SHOW_SUB_SECTION BIT,@SHOW_SECTION BIT,
--             @SHOW_PARA1 BIT,@SHOW_PARA2 BIT,@SHOW_PARA3 BIT,@SHOW_PARA4 BIT,
--             @SHOW_PARA5 BIT,@SHOW_PARA6 BIT,@SHOWCOL VARCHAR(MAX),
--             @JOINSTR VARCHAR(MAX),@CFILTER VARCHAR(MAX),@CORDERCOL VARCHAR(MAX),
--             @CMEMOID VARCHAR(100),
--             @CCBSTABLENAME VARCHAR(100),
--             @CGITJOIN VARCHAR(MAX),
--             @CGITCOLUMN VARCHAR(MAX)
             
         
--         SELECT TOP 1 @CMEMOID=MEMO_ID 
--         FROM LOC_STOCK_LEVEL_MST
--         WHERE   MEMO_DT <=@DASONDATE
--         ORDER BY MEMO_DT DESC,MEMO_ID DESC  
         
       
             
--      PRINT'********2.PENDING GIT**********'
    
--      DECLARE @CCUTOFFDATE VARCHAR(100),@CHOLOCID VARCHAR(10),@CLOCID VARCHAR(10)  
      
--     SELECT TOP 1 @CCUTOFFDATE=VALUE FROM CONFIG WHERE CONFIG_OPTION='GIT_CUT_OFF_DATE'  
--	 SELECT TOP 1 @CHOLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID' 

--	 SET @CCUTOFFDATE=ISNULL(@CCUTOFFDATE,'')  
	 
--	 IF @CLOCID=@CHOLOCID
--	 SET @CCBSTABLENAME=DB_NAME()+'_RFOPT.DBO.RF_OPT'
--	 ELSE
--	 SET @CCBSTABLENAME='VW_XNSREPS'
	 
	 
--	 IF OBJECT_ID ('TEMPDB..#TMPGIT','U') IS NOT NULL
--	    DROP TABLE #TMPGIT
	 
	 
--	 SELECT  CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
--	        CAST(0 AS NUMERIC(10,3)) AS GIT_QTY
--	 INTO #TMPGIT  
--	 WHERE 1=2 
	 
	 
--	 IF @CLOCID=@CHOLOCID
--	 BEGIN

--		 IF OBJECT_ID('TEMPDB..#TMPCHGIT','U') IS NOT NULL  
--			DROP TABLE #TMPCHGIT  
		    
--		 SELECT 'WSL' AS XN_TYPE,A.INV_ID AS MEMO_ID INTO #TMPCHGIT FROM INM01106 A (NOLOCK)   
--		 LEFT OUTER JOIN PIM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID AND B.CANCELLED=0 
--		 WHERE A.INV_DT <= @DASONDATE AND A.INV_DT>=(CASE WHEN @CCUTOFFDATE<>'' THEN @CCUTOFFDATE ELSE A.INV_DT END)  
--		 AND (ISNULL(B.RECEIPT_DT,'')='' OR ISNULL(B.RECEIPT_DT,'')>@DASONDATE)  
--		 AND A.CANCELLED=0  AND A.INV_MODE=2
--		 UNION  
--		 SELECT 'PRT' AS XN_TYPE,A.RM_ID AS MEMO_ID FROM RMM01106 A (NOLOCK)   
--		 LEFT OUTER JOIN CNM01106 B (NOLOCK) ON A.RM_ID=B.RM_ID  AND B.CANCELLED=0 
--		 WHERE A.RM_DT <= @DASONDATE AND A.RM_DT>=(CASE WHEN @CCUTOFFDATE<>'' THEN @CCUTOFFDATE ELSE A.RM_DT END)  
--		 AND (ISNULL(B.RECEIPT_DT,'')='' OR ISNULL(B.RECEIPT_DT,'')>@DASONDATE)  
--		 AND A.CANCELLED=0   AND A.MODE =2
		   
		 
		 
--		 INSERT INTO #TMPGIT(PRODUCT_CODE,GIT_QTY)
--		 SELECT PRODUCT_CODE,SUM(QUANTITY) AS GIT_QTY
--		 FROM
--		 (
--		 SELECT  B.PRODUCT_CODE,B.QUANTITY   
--		 FROM #TMPCHGIT A
--		 JOIN IND01106 B ON A.MEMO_ID =B.INV_ID 
--		 WHERE A.XN_TYPE ='WSL' 
--		 UNION ALL
--		 SELECT  B.PRODUCT_CODE,B.QUANTITY 
--		 FROM #TMPCHGIT A
--		 JOIN RMD01106 B ON A.MEMO_ID =B.RM_ID 
--		 WHERE A.XN_TYPE ='PRT' 
--		 ) A
--		 GROUP BY PRODUCT_CODE

--	 END
	 
--	 ELSE
--	 IF @CLOCID<>@CHOLOCID
--	 BEGIN
	    
--	     IF OBJECT_ID('TEMPDB..#TMPCHGIT_LOC','U') IS NOT NULL  
--			DROP TABLE #TMPCHGIT_LOC  
		    
--		 SELECT 'WSL' AS XN_TYPE,A.INV_ID AS MEMO_ID,A.TOTAL_QUANTITY ,A.NET_AMOUNT INTO #TMPCHGIT_LOC FROM DOCWSL_INM01106_MIRROR  A (NOLOCK)   
--		 LEFT OUTER JOIN PIM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID AND B.CANCELLED=0 
--		 WHERE A.INV_DT <= @DASONDATE AND A.INV_DT>=(CASE WHEN @CCUTOFFDATE<>'' THEN @CCUTOFFDATE ELSE A.INV_DT END)  
--		 AND (ISNULL(B.RECEIPT_DT,'')='' OR ISNULL(B.RECEIPT_DT,'')>@DASONDATE)  
--		 AND A.CANCELLED=0  
--		 UNION  
--		 SELECT 'PRT' AS XN_TYPE,A.RM_ID AS MEMO_ID,A.TOTAL_QUANTITY ,A.TOTAL_AMOUNT  FROM DOCPRT_RMM01106_MIRROR  A (NOLOCK)   
--		 LEFT OUTER JOIN CNM01106 B (NOLOCK) ON A.RM_ID=B.RM_ID  AND B.CANCELLED=0 
--		 WHERE A.RM_DT <= @DASONDATE AND A.RM_DT>=(CASE WHEN @CCUTOFFDATE<>'' THEN @CCUTOFFDATE ELSE A.RM_DT END)    
--		 AND (ISNULL(B.RECEIPT_DT,'')='' OR ISNULL(B.RECEIPT_DT,'')>@DASONDATE)  
--		 AND A.CANCELLED=0 
		 
--		 INSERT INTO #TMPGIT(PRODUCT_CODE,GIT_QTY)
--		 SELECT  PRODUCT_CODE,SUM(QUANTITY) AS GIT_QTY
--		 FROM
--		 (
--		 SELECT B.PRODUCT_CODE,B.QUANTITY   
--		 FROM #TMPCHGIT A
--		 JOIN DOCWSL_IND01106_MIRROR  B ON A.MEMO_ID =B.INV_ID 
--		 WHERE A.XN_TYPE ='WSL' 
--		 UNION ALL
--		 SELECT B.PRODUCT_CODE,B.QUANTITY 
--		 FROM #TMPCHGIT A
--		 JOIN DOCPRT_RMD01106_MIRROR  B ON A.MEMO_ID =B.RM_ID 
--		 WHERE A.XN_TYPE ='PRT' 
--		 ) A
--		 GROUP BY PRODUCT_CODE

		
--	 END	 
    
--    -- END OF PENDING GIT************
    
----SELECT * INTO TMPGIT FROM #TMPGIT

----SELECT @CMEMOID
--             SELECT @SHOW_ARTICLE=SHOW_ARTICLE,@SHOW_SUB_SECTION=SHOW_SUB_SECTION,@SHOW_SECTION=SHOW_SECTION,
--                    @SHOW_PARA1=SHOW_PARA1,@SHOW_PARA2=SHOW_PARA2,@SHOW_PARA3=SHOW_PARA3,@SHOW_PARA4=SHOW_PARA4,
--                    @SHOW_PARA5=SHOW_PARA5,@SHOW_PARA6=SHOW_PARA6 FROM LOC_STOCK_LEVEL_COL_DET 
--                    WHERE MEMO_ID=@CMEMOID
                    
--             SET @CFILTER=''
           
--             SELECT @CFILTER=ISNULL(FILTER,'') FROM LOC_STOCK_LEVEL_MST WHERE MEMO_ID=@CMEMOID  
             
            
--            IF @SHOW_SECTION=1
--               SET @CORDERCOL='SECTION_NAME,'
--            IF @SHOW_SUB_SECTION=1
--                SET @CORDERCOL=@CORDERCOL+'SUB_SECTION_NAME,'
--            IF @SHOW_ARTICLE=1
--                 SET @CORDERCOL=@CORDERCOL+'ARTICLE_NO,'  
--            IF @SHOW_PARA1=1
--                 SET @CORDERCOL=@CORDERCOL+'PARA1_NAME,'  
--            IF @SHOW_PARA2=1
--              SET @CORDERCOL=@CORDERCOL+'PARA2_NAME,'
--            IF @SHOW_PARA3=1
--             SET @CORDERCOL=@CORDERCOL+'PARA3_NAME,'
--            IF @SHOW_PARA4=1
--               SET @CORDERCOL=@CORDERCOL+'PARA4_NAME,'
--            IF @SHOW_PARA5=1
--               SET @CORDERCOL=@CORDERCOL+'PARA5_NAME,'
--            IF @SHOW_PARA6=1
--               SET @CORDERCOL=@CORDERCOL+'PARA6_NAME,'
                    
--            SET @CGITJOIN=' 1=1 '
            
--            SET @COLNAME=''
--            SET @SHOWCOL=''
--            SET @JOINSTR=''
--            SET @CGITCOLUMN=''
           
           
--          SET @SHOW_ARTICLE=1
--            IF @SHOW_ARTICLE=1
--             BEGIN
--                SET @COLNAME='ARTICLE.[ARTICLE_CODE],ARTICLE.[ARTICLE_NO],'
--                SET @SHOWCOL='ARTICLE_CODE,ARTICLE_NO,'
--                SET @JOINSTR=' JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE = ARTICLE.ARTICLE_CODE
--                               JOIN LOC_STOCK_LEVEL (NOLOCK) AB ON AB.ARTICLE_CODE=ARTICLE.ARTICLE_CODE '
                               
--                SET @CGITJOIN=@CGITJOIN+' AND B.ARTICLE_CODE=GIT.GIT_ARTICLE_CODE ' 
--                SET @CGITCOLUMN=' ARTICLE.ARTICLE_CODE AS GIT_ARTICLE_CODE,'
--             END
              
--            IF @SHOW_SECTION=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'SECTIONM.[SECTION_CODE],SECTIONM.[SECTION_NAME], '
--              SET @SHOWCOL=@SHOWCOL+ 'SECTION_CODE,SECTION_NAME,'
--              SET @JOINSTR=@JOINSTR+' JOIN SECTIONM (NOLOCK) ON AB.SECTION_CODE = SECTIONM.SECTION_CODE' 
               
--              SET @CGITJOIN=@CGITJOIN+' AND B.SECTION_CODE=GIT.GIT_SECTION_CODE ' 
--              SET @CGITCOLUMN=@CGITCOLUMN+' SECTIONM.SECTION_CODE AS GIT_SECTION_CODE,'
              
--            --  SELECT @SHOWCOL
--            END
             
--            IF @SHOW_SUB_SECTION=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'SECTIOND.[SUB_SECTION_CODE],SECTIOND.[SUB_SECTION_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'SUB_SECTION_CODE,SUB_SECTION_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN SECTIOND (NOLOCK) ON AB.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE'
              
--              SET @CGITJOIN=@CGITJOIN+' AND B.SUB_SECTION_CODE=GIT.GIT_SUB_SECTION_CODE ' 
--              SET @CGITCOLUMN=@CGITCOLUMN+' SECTIOND.SUB_SECTION_CODE AS GIT_SUB_SECTION_CODE,'
--            END
              
--            IF @SHOW_PARA1=1
--            BEGIN
            
--              SET @COLNAME=@COLNAME+'PARA1.[PARA1_CODE],PARA1.[PARA1_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'PARA1_CODE,PARA1_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN PARA1 (NOLOCK) ON AB.PARA1_CODE = PARA1.PARA1_CODE' 
     
--              SET @CGITJOIN=@CGITJOIN+' AND B.PARA1_CODE=GIT.GIT_PARA1_CODE ' 
--              SET @CGITCOLUMN=@CGITCOLUMN+' PARA1.PARA1_CODE AS GIT_PARA1_CODE,'
--            END
             
--            IF @SHOW_PARA2=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'PARA2.[PARA2_CODE],PARA2.[PARA2_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'PARA2_CODE,PARA2_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN PARA2 (NOLOCK) ON AB.PARA2_CODE = PARA2.PARA2_CODE'
              
--              SET @CGITJOIN=@CGITJOIN+' AND B.PARA2_CODE=GIT.GIT_PARA2_CODE '
--              SET @CGITCOLUMN=@CGITCOLUMN+' PARA2.PARA2_CODE AS GIT_PARA2_CODE,'
--            END
              
--            IF @SHOW_PARA3=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'PARA3.[PARA3_CODE],PARA3.[PARA3_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'PARA3_CODE,PARA3_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN PARA3 (NOLOCK) ON AB.PARA3_CODE = PARA3.PARA3_CODE'
              
--              SET @CGITJOIN=@CGITJOIN+' AND B.PARA3_CODE=GIT.GIT_PARA3_CODE '
--              SET @CGITCOLUMN=@CGITCOLUMN+' PARA3.PARA3_CODE AS GIT_PARA3_CODE,'
--            END
             
--            IF @SHOW_PARA4=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'PARA4.[PARA4_CODE],PARA4.[PARA4_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'PARA4_CODE,PARA4_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN PARA4 (NOLOCK) ON AB.PARA4_CODE = PARA4.PARA4_CODE'
              
--              SET @CGITJOIN=@CGITJOIN+' AND B.PARA4_CODE=GIT.GIT_PARA4_CODE '
--              SET @CGITCOLUMN=@CGITCOLUMN+' PARA4.PARA4_CODE AS GIT_PARA4_CODE,'
--            END
               
--            IF @SHOW_PARA5=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'PARA5.[PARA5_CODE],PARA5.[PARA5_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'PARA5_CODE,PARA5_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN PARA5 (NOLOCK) ON AB.PARA5_CODE = PARA5.PARA5_CODE'
              
--              SET @CGITJOIN=@CGITJOIN+' AND B.PARA5_CODE=GIT.GIT_PARA5_CODE '
--              SET @CGITCOLUMN=@CGITCOLUMN+' PARA5.PARA5_CODE AS GIT_PARA5_CODE,'
--            END
             
--            IF @SHOW_PARA6=1
--            BEGIN
--              SET @COLNAME=@COLNAME+'PARA6.[PARA6_CODE],PARA6.[PARA6_NAME], ' 
--              SET @SHOWCOL=@SHOWCOL+ 'PARA6_CODE,PARA6_NAME,'
--              SET @JOINSTR=@JOINSTR+ ' JOIN PARA6 (NOLOCK) ON AB.PARA6_CODE = PARA6.PARA6_CODE'
--              SET @CGITJOIN=@CGITJOIN+' AND B.PARA6_CODE=GIT.GIT_PARA6_CODE '
--              SET @CGITCOLUMN=@CGITCOLUMN+' PARA6.PARA6_CODE AS GIT_PARA6_CODE,'
--            END
               
              
--              SET @COLNAME=LEFT(@COLNAME,LEN(@COLNAME)-1)
--              SET @SHOWCOL=LEFT(@SHOWCOL,LEN(@SHOWCOL)-1)
--              SET @CORDERCOL=LEFT(@CORDERCOL,LEN(@CORDERCOL)-1)
--              SET @CGITCOLUMN=LEFT(@CGITCOLUMN,LEN(@CGITCOLUMN)-1)
              
              
           
--              --SELECT @SHOWCOL,@COLNAME,@CCBSTABLENAME,@JOINSTR,@CFILTER,@CGITCOLUMN
              
--            SET @CCMD=N'SELECT '+@SHOWCOL+',SUM(ISNULL(CBS , 0)) AS CBS,STOCK_LEVEL_QTY,SUM(ISNULL(GIT_QTY,0)) AS GIT_QTY,
--                 (STOCK_LEVEL_QTY-(SUM(ISNULL(CBS , 0))+SUM(ISNULL(GIT_QTY,0))) ) AS REQ_QTY
--                 FROM 
--					  (
--				SELECT '+@COLNAME+'
--					  , CAST(SUM( (CASE WHEN A.XN_TYPE=''OPS'' OR (A.XN_TYPE IN (''JWR'',''DNPR'',''WPR'',''TTM'',''API'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') AND XN_DT<='''+CONVERT(VARCHAR(11),@DASONDATE ,120)+''' AND ARTICLE.STOCK_NA=0 ) THEN 1 WHEN A.XN_TYPE IN (''APO'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'',''PRD_SCC'',''WPI'',''DNPI'') AND XN_DT<='''+CONVERT(VARCHAR(11),@DASONDATE ,120)+''' AND ARTICLE.STOCK_NA=0 THEN -1 ELSE 0 END) * (XN_QTY)) AS NUMERIC(14,3)) AS CBS
--					   ,STOCK_LEVEL_QTY
--				FROM SKU (NOLOCK) 
--			    LEFT JOIN '+@CCBSTABLENAME+' A (NOLOCK) ON A.PRODUCT_CODE=SKU.PRODUCT_CODE
--				'+@JOINSTR+'
--				WHERE '+@CFILTER+'
--				GROUP BY '+@COLNAME+',STOCK_LEVEL_QTY

--	          ) B 
--			 LEFT JOIN
--			 (
			   
--			   SELECT '+@CGITCOLUMN+'
--			          ,SUM(ISNULL(TMP.GIT_QTY,0)) AS GIT_QTY
--				FROM SKU (NOLOCK) 
--				LEFT JOIN #TMPGIT TMP ON TMP.PRODUCT_CODE=SKU.PRODUCT_CODE 
--				'+@JOINSTR+'
--				WHERE '+@CFILTER+'
--				GROUP BY '+@COLNAME+'
--			 ) GIT ON '+@CGITJOIN+'

--	 GROUP BY '+@SHOWCOL+',STOCK_LEVEL_QTY
--	 ORDER BY '+@CORDERCOL+''
--	 PRINT @CCMD
--	EXEC SP_EXECUTESQL @CCMD        
	
	--SELECT * INTO TMPGIT FROM #TMPGIT  
                    
END
