
CREATE PROCEDURE SP_PRODUCT_STATUS_REPORT_9
(
 @nQueryID	INT,  
 @DFM_DT DATETIME='',  
 @DTO_DT DATETIME='',  
 @REF_NO VARCHAR(100)='',  
 @BUYER_NAME VARCHAR(100)='',  
 @CORDER_NO VARCHAR(100)='',  
 @JOBCARD_NO VARCHAR(100)=''  
)  
AS  
BEGIN
            
		 	IF OBJECT_ID ('TEMPDB..#TMPDETAILS','U') IS NOT NULL  
			DROP TABLE #TMPDETAILS  

	  
	   ;with buyer as
	   (
		SELECT LEFT(OM.MEMO_ID,2) as DEPT_ID ,ISNULL(LM.AC_NAME,'') AS BUYER_NAME,  
		ISNULL(BM.ORDER_NO,'') AS ORDER_NO,  
		ISNULL(CONVERT(VARCHAR,BM.ORDER_DT,105),'') AS ORDER_DT, 
		ISNULL(BD.ORDER_ID,'') AS ORDER_ID, 
		ISNULL(BD.QUANTITY ,0) AS BO_QTY,
		ISNULL(BM.REF_NO,'') AS REF_NO,  
		ISNULL(CONVERT(VARCHAR,BM.DELIVERY_DT,105),'') AS DELIVERY_DT,  
		ISNULL(OM.MEMO_NO,'') AS JOBCARD_NO,  
		ISNULL(CONVERT(VARCHAR,OM.MEMO_DT,105) ,'') AS JOBCARD_DT,  
		ISNULL(OM.MEMO_ID ,'') AS MEMO_ID,  
		obd.PRODUCT_CODE ,  ART.ARTICLE_NO,  ART.ARTICLE_NAME ,  ART.ARTICLE_CODE,  P1.PARA1_NAME ,  
		P1.PARA1_CODE , A1.attr1_key_name AS [BRAND]
	   FROM ORD_PLAN_MST OM (NOLOCK)
	   JOIN ORD_PLAN_DET OD (NOLOCK) ON OM.MEMO_ID =OD.MEMO_ID 
	   JOIN ORD_PLAN_BARCODE_DET OBD (NOLOCK) ON OBD.REFROW_ID =OD.ROW_ID 
	   LEFT JOIN BUYER_ORDER_DET BD (NOLOCK) ON BD.row_id =OD.WOD_ROW_ID  
	   LEFT JOIN BUYER_ORDER_MST BM (NOLOCK ) ON BM.ORDER_ID=BD.ORDER_ID   
	   LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =isnull(BM.AC_CODE ,om.AC_CODE)
	   JOIN SKU (NOLOCK) ON SKU.product_code =obd.PRODUCT_CODE   
	   JOIN ARTICLE ART (NOLOCK) ON ART.article_code =SKU.article_code   
	   JOIN para1 P1 (NOLOCK) ON P1.para1_code =SKU.para1_code   
	   LEFT OUTER JOIN ARTICLE_FIX_ATTR FIX_ATTR (NOLOCK) ON FIX_ATTR.ARTICLE_CODE=ART.ARTICLE_CODE
	   LEFT OUTER JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=FIX_ATTR.ATTR1_KEY_CODE
	   WHERE ISNULL(BM.CANCELLED,0)=0  AND ISNULL(OM.CANCELLED,0)=0 
	   AND (@REF_NO='' OR ISNULL(BM.REF_NO,'')=@REF_NO)  
	   AND (@BUYER_NAME='' OR ISNULL(LM.AC_CODE ,'')=@BUYER_NAME)  
	   AND (@CORDER_NO='' OR ISNULL(BM.ORDER_ID,'')=@CORDER_NO)  
	   AND (@JOBCARD_NO='' OR ISNULL(OM.MEMO_ID,'')=@JOBCARD_NO)  
	   AND (@DFM_DT='' or ISNULL(BM.ORDER_DT,ISNULL(OM.MEMO_DT ,'')) BETWEEN @DFM_DT AND @DTO_DT  )
	   
	   )
	 
       SELECT obd.*,A.XN_TYPE,JOBWORK_NAME ,  JOBWORKER_NAME,  A.XN_DT ,A.XN_QTY  ,A.ShortCloseQty
	   into #TMPDETAILS
	   FROM BUYER OBD
	   JOIN  
	   (  
		 SELECT LEFT (A.MEMO_ID,2) AS DEPT_ID,  
		  CAST('JCC' AS VARCHAR(10)) AS XN_TYPE,  
		  CAST('' AS VARCHAR(100)) AS JOBWORK_NAME,  
		  CAST('' AS VARCHAR(20)) AC_CODE ,  
		  CAST('' AS VARCHAR(100)) AS JOBWORKER_NAME ,  
		  A.MEMO_DT AS XN_DT ,C.PRODUCT_CODE ,  
		  CAST(1 AS NUMERIC(1,0)) AS  XN_QTY  ,
		  CAST((CASE WHEN ISNULL(pmt.Barcode_SHORT_CLOSE,0)=1  THEN 1 ELSE 0 END)  AS NUMERIC(1,0)) AS  ShortCloseQty  
		 FROM ORD_PLAN_MST A (NOLOCK)  
		 JOIN ORD_PLAN_DET B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID   
		 JOIN ORD_PLAN_BARCODE_DET C (NOLOCK) ON C.REFROW_ID =B.ROW_ID  
		 JOIN BUYER ON C.PRODUCT_CODE =BUYER .PRODUCT_CODE
		 JOIN JOBWORK_PMT PMT (NOLOCK) ON C.PRODUCT_CODE =PMT.PRODUCT_CODE
		 WHERE A.CANCELLED =0  
		 UNION ALL  
		 SELECT LEFT (A.ISSUE_ID ,2) AS DEPT_ID,  
		  CAST('JWI' AS VARCHAR(10)) AS XN_TYPE,  
		  JOBS.JOB_NAME  AS JOBWORK_NAME,  
		  B.AGENCY_CODE ,AM.AGENCY_NAME  AS  JOBWORKER_NAME ,  
		  B.ISSUE_DT AS XN_DT ,A.PRODUCT_CODE ,  
		  A.QUANTITY  AS  XN_QTY  ,
		  0 AS ShortCloseQty
		 FROM JOBWORK_ISSUE_DET A (NOLOCK)  
		 JOIN BUYER ON a.PRODUCT_CODE =BUYER .PRODUCT_CODE
		 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID =B.ISSUE_ID   
		 JOIN PRD_AGENCY_MST AM (NOLOCK) ON AM.AGENCY_CODE =B.AGENCY_CODE   
		 JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE=A.JOB_CODE  
		 WHERE B.CANCELLED =0 AND ISNULL(B.ISSUE_MODE ,0)=1  
		 UNION ALL  
		 SELECT LEFT (A.RECEIPT_ID  ,2) AS DEPT_ID,  
		  CAST('JWR' AS VARCHAR(10)) AS XN_TYPE,  
		  JOBS.JOB_NAME AS JOBWORK_NAME,  
		  B.AGENCY_CODE ,AM.AGENCY_NAME AS JOBWORKER_NAME  ,  
		  B.RECEIPT_DT AS XN_DT ,A.PRODUCT_CODE ,  
		  A.QUANTITY  AS  XN_QTY  ,
		  0 AS ShortCloseQty
		 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
		  JOIN BUYER ON a.PRODUCT_CODE =BUYER .PRODUCT_CODE
		 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID  =B.RECEIPT_ID   
		 JOIN PRD_AGENCY_MST AM (NOLOCK) ON AM.AGENCY_CODE =B.AGENCY_CODE   
		 JOIN JOBS (NOLOCK) ON JOBS.JOB_CODE=A.JOB_CODE  
		 WHERE B.CANCELLED =0 AND ISNULL(B.RECEIVE_MODE ,0)=1  
		 UNION ALL  
		 SELECT LEFT (A.MEMO_ID  ,2) AS DEPT_ID,  
		   CAST('TTT' AS VARCHAR(10)) AS XN_TYPE,  
		   CAST('' AS VARCHAR(100)) AS JOBWORK_NAME,  
		   '' AS AC_CODE ,'' AS JOBWORKER_NAME  ,  
		   B.MEMO_DT AS XN_DT ,A.PRODUCT_CODE ,  
		   A.QUANTITY  AS  XN_QTY,
		   0 AS ShortCloseQty
		 FROM TRANSFER_TO_TRADING_DET A (NOLOCK)  
		 JOIN BUYER ON a.PRODUCT_CODE =BUYER .PRODUCT_CODE
		 JOIN TRANSFER_TO_TRADING_MST  B (NOLOCK) ON A.MEMO_ID=B.MEMO_ID  
		 WHERE B.CANCELLED=0  
	   ) A  ON OBD.PRODUCT_CODE =A.PRODUCT_CODE 
	   

	   
	   
	   ALTER TABLE #TMPDETAILS ADD DISPATCH_QTY NUMERIC(10,2)  
	   
	   UPDATE A SET DISPATCH_QTY=B.INV_QTY  
	   FROM #TMPDETAILS A
	   JOIN
	   (
	     SELECT A.PRODUCT_CODE ,SUM(A.QUANTITY) AS INV_QTY 
	     FROM IND01106 A (NOLOCK)
	     JOIN INM01106 B (NOLOCK) ON A.INV_ID =B.INV_ID 
	     WHERE B.CANCELLED=0
	     GROUP BY A.PRODUCT_CODE 
	   )  B ON A.PRODUCT_CODE =B.PRODUCT_CODE 
	     
	     
	   DECLARE @DTSQL NVARCHAR(MAX),  
	   @JWINAME VARCHAR(MAX),@JWRNAME VARCHAR(MAX),  
	   @CCOLUMN_NAME VARCHAR(MAX),  
	   @CDISPLAYCOLUMNNAMELIST VARCHAR(MAX),  
	   @CWIP_QTY VARCHAR(MAX)  ,@CTOTALCOLUMNNAME VARCHAR(MAX),@CTOTALVALUE VARCHAR(MAX)
	     
	   
	   SELECT @JWINAME=ISNULL(@JWINAME+',','')+QUOTENAME(JOBWORK_NAME)   
			  ,@JWRNAME=ISNULL(@JWRNAME+',','')+QUOTENAME(JOBWORK_NAME+'1')   
	            
			  ,@CCOLUMN_NAME=ISNULL(@CCOLUMN_NAME+',','')+'SUM(ISNULL('+QUOTENAME(JOBWORK_NAME)+',0))'+' AS '+QUOTENAME('JWI'+JOBWORK_NAME)  
			   +','+'SUM(ISNULL('+QUOTENAME(JOBWORK_NAME+'1')+',0))'+' AS '+QUOTENAME('JWR'+JOBWORK_NAME)  
	            
			  ,@CDISPLAYCOLUMNNAMELIST=ISNULL(@CDISPLAYCOLUMNNAMELIST+',','')+QUOTENAME('JWI'+JOBWORK_NAME)+QUOTENAME(JOBWORK_NAME +' Issue')  
			  +','+QUOTENAME('JWR'+JOBWORK_NAME)+QUOTENAME(JOBWORK_NAME +' Receive')  
			  +','+QUOTENAME('JWI'+JOBWORK_NAME)+'-'+QUOTENAME('JWR'+JOBWORK_NAME)+QUOTENAME(JOBWORK_NAME+' Balance'),  
			  @CWIP_QTY=ISNULL(@CWIP_QTY+'+','')+QUOTENAME('JWI'+JOBWORK_NAME)+'-'+QUOTENAME('JWR'+JOBWORK_NAME) ,
			  
			    
			  @CTOTALCOLUMNNAME=ISNULL(@CTOTALCOLUMNNAME+',','')+QUOTENAME(JOBWORK_NAME+' Issue' )
			  +',' +QUOTENAME(JOBWORK_NAME+' Receive' )
			  +',' +QUOTENAME(JOBWORK_NAME+' Balance' ),
			  
			 
			  
			  @CTOTALVALUE=ISNULL(@CTOTALVALUE+',','')+ 'SUM(ISNULL('+QUOTENAME(JOBWORK_NAME+' Issue')+',0))'+QUOTENAME(JOBWORK_NAME+' Issue' )
			  +',' +'SUM(ISNULL('+QUOTENAME(JOBWORK_NAME+' Receive')+',0))'+QUOTENAME(JOBWORK_NAME+' Receive' )
			  +',' +'SUM(ISNULL('+QUOTENAME(JOBWORK_NAME+' Balance')+',0))'+QUOTENAME(JOBWORK_NAME+' Balance' )
			  --+',' +QUOTENAME(JOBWORK_NAME+' Receive' )
			  --+',' +QUOTENAME(JOBWORK_NAME+' Balance' ) 
	            
	   FROM  
	   (  
	   SELECT  A.JOBWORK_NAME ,ISNULL(B.JOB_SR,0) AS JOB_SR   
	   FROM #TMPDETAILS  A
	   JOIN jobs B (NOLOCK) ON A.JOBWORK_NAME =B.job_name 
	   WHERE A.XN_TYPE ='JWI'  AND B.INACTIVE=0
	   GROUP BY  A.JOBWORK_NAME,ISNULL(B.JOB_SR,0)
	   ) A  
		ORDER BY ISNULL(A.JOB_SR,0)
	    
	    IF OBJECT_ID ('TEMPDB..##TMPDETAILS','U') IS  NOT NULL
	      DROP TABLE ##TMPDETAILS
	         
	        
	   if isnull(@CDISPLAYCOLUMNNAMELIST,'')=''
	   begin
	       
			SELECT A.DEPT_ID as [Location Name], A.BUYER_NAME as [Party] ,A.ORDER_NO as [Order No] ,
			   A.ORDER_DT as [Order Date] ,
			   A.DELIVERY_DT as [Delivery Date],
			   A.REF_NO AS [Buyer Ref No], 
			   a.BO_QTY AS  [Buyer Order Qty],
			   A.JOBCARD_NO as [JobCard No] ,A.JOBCARD_DT as [JobCard Date] ,  
			   A.ARTICLE_NO [Article],A.ARTICLE_NAME AS [Article Name] ,  
			  -- A.PARA1_NAME as [Color],
			   --,A.PARA2_NAME as [Size] ,  
			   --SUM(A.XN_QTY) AS [Buyer Order Qty] ,
			   A.BRAND,
			   SUM(A.XN_QTY) AS [JobCard Qty] ,
	           sum(a.ShortCloseQty) as ShortCloseQty
	   FROM #TMPDETAILS A  
	   WHERE XN_TYPE ='JCC'  
	   GROUP BY A.DEPT_ID, A.BUYER_NAME ,A.ORDER_NO ,A.ORDER_DT,a.BO_QTY ,A.DELIVERY_DT,A.REF_NO,  
	   A.memo_id,A.JOBCARD_NO ,A.JOBCARD_DT, A.ARTICLE_NO,A.ARTICLE_NAME,A.ARTICLE_CODE ,A.BRAND,  
	   a.MEMO_ID ,A.ORDER_ID 
	   
	   end
	   else
	   begin
	        
		  --SELECT @JOBWORKNAME,@CCOLUMN_NAME,@CDISPLAYCOLUMNNAMELIST  
	     
		 SET @DTSQL=N'SELECT A.DEPT_ID as [Location Name], A.BUYER_NAME as [Party] ,A.ORDER_NO as [Order No] ,  
				  A.ORDER_DT as [Order Date],DELIVERY_DT as [Delivery Date],  
				  A.REF_NO as [Buyer Ref No],  
				  A.BO_QTY as [Buyer Order Qty] ,
				  A.JOBCARD_NO as [JobCard No],A.JOBCARD_DT as [JobCard Date] ,  
				  A.ARTICLE_NO [Article],A.ARTICLE_NAME as [Article Name] ,  
				  A.BRAND,
				  A.ORDER_QTY AS [JobCard Qty] ,  
				  '+@CDISPLAYCOLUMNNAMELIST+',  
				  A.ORDER_QTY-(isnull(('+@CWIP_QTY+'),0)+ISNULL(TTM.TTM_QTY,0)) AS [WIP Qty]  ,
				  ISNULL(TTM.TTM_QTY,0) AS [Transfer To Trading Qty],
				  ISNULL(A.DISPATCH_QTY,0) AS [Dispatch Qty],
				  isnull(a.ShortCloseQty,0) as ShortCloseQty
		   INTO ##TMPDETAILS
		   FROM  
		   (  
			SELECT A.DEPT_ID, A.BUYER_NAME ,A.ORDER_NO ,
				   A.ORDER_ID,A.ORDER_DT,0 as BO_QTY ,
				   A.DELIVERY_DT,A.REF_NO,  
				   A.JOBCARD_NO ,A.JOBCARD_DT ,  
				   A.MEMO_ID,  
				   A.ARTICLE_NO,A.ARTICLE_NAME,A.ARTICLE_CODE ,  
				   A.BRAND,
				   SUM(A.XN_QTY) AS ORDER_QTY  ,
				   SUM(ISNULL(A.DISPATCH_QTY,0)) AS DISPATCH_QTY,
				   SUM(A.ShortCloseQty) AS ShortCloseQty  
		   FROM #TMPDETAILS A  
		   WHERE XN_TYPE =''JCC''  
		   GROUP BY A.DEPT_ID, A.BUYER_NAME ,A.ORDER_NO ,A.ORDER_DT,A.DELIVERY_DT,A.REF_NO,  
		   A.memo_id,A.JOBCARD_NO ,A.JOBCARD_DT, A.ARTICLE_NO,A.ARTICLE_NAME,A.ARTICLE_CODE , A.BRAND, 
		   a.MEMO_ID ,A.ORDER_ID 
		   ) A  
		   LEFT JOIN  
		   (  
		     
			SELECT MEMO_ID,ARTICLE_CODE,'+@CCOLUMN_NAME+'  
			FROM  
			(  
			 SELECT A.MEMO_ID,A.ARTICLE_CODE,  
					JOBWORK_NAME,  
					JOBWORK_NAME+''1'' AS JOBWORK_NAME1,  
					SUM(CASE WHEN  XN_TYPE=''JWI'' THEN XN_QTY ELSE 0 END) AS JWI_QTY,  
					SUM(CASE WHEN  XN_TYPE=''JWR'' THEN XN_QTY ELSE 0 END) AS JWR_QTY  
			 FROM #TMPDETAILS A  
			 WHERE XN_TYPE IN(''JWI'',''JWR'')  
			 GROUP BY A.MEMO_ID,A.ARTICLE_CODE, 
			 JOBWORK_NAME,JOBWORK_NAME+''1''  
			 ) A  
			  PIVOT  
				 (  
				  SUM(JWI_QTY) FOR JOBWORK_NAME IN ('+@JWINAME+')  
				 ) AS PV1  
				 PIVOT  
				 (  
				  SUM(JWR_QTY) FOR JOBWORK_NAME1 IN ('+@JWRNAME+')  
				 ) AS PV2  
		       
			 GROUP BY MEMO_ID,ARTICLE_CODE  
		     
		   ) B ON A.ARTICLE_CODE=B.ARTICLE_CODE 
		   AND A.MEMO_ID=B.MEMO_ID  
		   LEFT JOIN  
		   (  
			SELECT A.MEMO_ID,A.ARTICLE_CODE, 
				   SUM(XN_QTY) AS TTM_QTY  
			FROM #TMPDETAILS A  
			WHERE XN_TYPE IN(''TTT'')  
			GROUP BY A.MEMO_ID,A.ARTICLE_CODE
		   ) TTM ON A.ARTICLE_CODE=TTM.ARTICLE_CODE 
		   AND A.MEMO_ID=TTM.MEMO_ID  
		   order by A.JOBCARD_NO ,A.JOBCARD_DT ,  
				  A.ARTICLE_NO  '  
		   PRINT @DTSQL  
		   EXEC (@DTSQL)  

	  SELECT * FROM ##TMPDETAILS A
	  ORDER BY [JobCard No] ,[JobCard Date] ,  
	  [Article] 
	  
	 
	  
	   SET @DTSQL=N'SELECT '''' as [Location Name], '''' as [Party] ,'''' as [Order No] ,  
				  '''' as [Order Date],'''' as [Delivery Date],  
				  '''' as [Buyer Ref No],  
				   sum([Buyer Order Qty]) as [Buyer Order Qty] ,
				  ''TOTAL'' as [JobCard No],'''' as [JobCard Date] ,  
				  '''' [Article],'''' as [Article Name] ,  
				  sum([JobCard Qty]) AS [JobCard Qty],
	   '+@CTOTALVALUE+',
	   sum([WIP Qty]) as [WIP Qty],
	    sum([Transfer To Trading Qty]) as [Transfer To Trading Qty],
	   SUM(ISNULL([DISPATCH QTY],0)) [Dispatch Qty],
	   SUM(ISNULL([ShortCloseQty],0)) [ShortCloseQty]
	  FROM ##TMPDETAILS'
	  
	  PRINT @DTSQL
	  EXEC SP_EXECUTESQL @DTSQL
	  
	   
	     IF OBJECT_ID ('TEMPDB..##TMPDETAILS','U') IS  NOT NULL
	      DROP TABLE ##TMPDETAILS
	   
	   
	END  

END

