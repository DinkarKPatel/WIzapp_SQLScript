CREATE PROCEDURE SPWOW_XPERT_GETCBS_DETAILS  
@DFROMDT DATETIME='',
@DTODT DATETIME,  
@CFILTERCRITERIA VARCHAR(MAX)='',  
@CJOINSTR VARCHAR(MAX)='',  
@nStkColsMode NUMERIC(1,0)=1,
@cErrormsg VARCHAR(MAX) output
--WITH ENCRYPTION
AS  
BEGIN  

 DECLARE @CCMD NVARCHAR(MAX),@CRFDBNAME VARCHAR(100),@CRFPREFIX VARCHAR(100),@CSLSMEMONO VARCHAR(20),  
 @NSLSDISC NUMERIC(6,2),@CBuyFILTER VARCHAR(MAX),@cGetFILTER VARCHAR(MAX),@BPENDING BIT,@CLOCFILTER VARCHAR(500)  ,
 @CCOL VARCHAR(40), @CRETCOLSTR NVARCHAR(MAX),@cSchRowId VARCHAR(40),@cStep VARCHAR(4),
 @nFiltermode NUMERIC(2,0),@CJOINSTRBUY VARCHAR(MAX),@CJOINSTRget varchar(max),
 @cSchName Varchar(500)
 
BEGIN TRY
	 SET @CRETCOLSTR = N''   
	 SET @BPENDING=1  
	 SET @cStep='10'
	 SET @cErrormsg=''


	 IF OBJECT_ID('TEMPDB..##tmpWowcbsstk','U') IS NOT NULL  
		DROP TABLE ##tmpWowcbsstk  
    
	
	print 'Create #tmpWowcbsstk for xpert	'
	 SET @cStep='20'
	 PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)

	 SELECT a.PRODUCT_CODE AS SLS_PRODUCT_CODE,B.DEPT_ID,A.DISCOUNT_PERCENTAGE as [Eoss_Discount_pct],
	 CONVERT(VARCHAR(10),'') AS [EOSS_CATEGORY],a.discount_amount AS [Eoss_Discount_amt],d.scheme_name as Eoss_scheme_name
	 --s.article_code,s.para1_code,s.para2_code,s.para3_code,s.para4_code,
	 --s.para5_code,s.para6_code,art.sub_section_code,sd.section_code,
	 --s.article_code sku_article_code,
	 INTO ##tmpWowcbsstk
	 FROM scheme_setup_slsbc  A (NOLOCK)  
	 join scheme_setup_det d on A.scheme_setup_det_row_id= d.row_id 
	 JOIN sku s (NOLOCK) ON s.product_code=a.product_code
	 JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
	 JOIN article art (NOLOCK) ON art.article_code=s.article_code
	 JOIN  sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
	 left outer join   scheme_setup_loc  B ON d.memo_no=B.memo_no WHERE 1=2  
 
   
	 CREATE INDEX IND_tmpWowcbsstk ON ##tmpWowcbsstk (SLS_PRODUCT_CODE,DEPT_ID)  
    
	DECLARE @nLoop NUMERIC(1,0),@nLoopCnt NUMERIC(1,0)
    
	SET @nLoopCnt=(CASE WHEN @nStkColsMode=3 THEN 2 ELSE 1 END)

	SET @nLoop=1

	WHILE @nLoop<=@nLoopCnt
	BEGIN
		SET @cStep='30'
		PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
		IF  convert(varchar(10),@DTODT,112)   = convert(varchar(10),getdate(),112) AND @nStkColsMode IN (1,3) AND @nLoop=1
		BEGIN
			SET @CRFPREFIX = 'PMT01106'
			SET @CFILTERCRITERIA=(CASE WHEN @CFILTERCRITERIA='' THEN ' WHERE ' ELSE ' AND ' END)+' quantity_in_stock>0'
		END
		ELSE		     
		BEGIN
			SET @CRFPREFIX = DB_NAME()+ '_PMT.DBO.PMTLOCS_'+(CASE WHEN (@nStkColsMode=2 AND @nLoop=1) OR (@nStkColsMode=3 AND @nLoop=2) 
			THEN convert(varchar(10),@DFromDt-1,112) ELSE convert(varchar(10),@DTODT,112) END)
		END
        
		SET @cStep='40'
		SET @CCMD=(CASE WHEN @nLoop=2 THEN @cCmd+' UNION ' ELSE '' END)+
					N'SELECT A.PRODUCT_CODE,LOC_RF.MAJOR_DEPT_ID,0,'''',0,''''
					  --sku.article_code,sku.article_code sku_article_code,sku.para1_code,sku.para2_code,sku.para3_code,sku.para4_code,sku.para5_code,
					  --sku.para6_code,art.sub_section_code,sd.section_code
					  FROM '+@CRFPREFIX+' A' +@CJOINSTR+  
					' JOIN  sku  (NOLOCK) ON sku.product_code=a.product_code
					  JOIN article art (NOLOCK) ON art.article_code=sku.article_code
					  JOIN sectiond sd (NOLOCK) ON sd.sub_section_code=art.sub_section_code
					  JOIN LOCATION LOC_RF ON LOC_RF.DEPT_ID=A.DEPT_ID '+ @CFILTERCRITERIA 

		SET @nLoop=@nLoop+1           
	END               

              
	PRINT  @CCMD          
    
	set @cStep='45'
	PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
	INSERT ##tmpWowcbsstk  (SLS_PRODUCT_CODE,DEPT_ID,Eoss_Discount_pct,[EOSS_CATEGORY],EOSS_DISCOUNT_AMT,Eoss_scheme_name)
	--article_code,sku_article_code,para1_code,para2_code,para3_code,para4_code,para5_code,para6_code,
	--sub_section_code,section_code)
	EXEC SP_EXECUTESQL @CCMD  


	 SET @cStep='50'
     PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)   
	 UPDATE A SET Eoss_Discount_pct=(CASE WHEN B.DISCOUNT_PERCENTAGE<>0 and b.discount_mode=1 THEN B.DISCOUNT_PERCENTAGE
											WHEN B.DISCOUNT_AMOUNT<>0 and b.discount_mode=2 THEN ((B.DISCOUNT_AMOUNT/E.MRP)*100)
											WHEN B.NET_PRICE<>0 and b.discount_mode=3 THEN (((E.MRP-B.NET_PRICE)/E.MRP)*100)
											ELSE 0 END),Eoss_scheme_name=c.scheme_name 
	 FROM ##tmpWowcbsstk A  
	 JOIN scheme_setup_slsbc  B (NOLOCK) ON  A.SLS_PRODUCT_CODE=B.PRODUCT_CODE     
	 join scheme_setup_det C (NOLOCK) on B.scheme_setup_det_row_id= C.row_id 
	 join scheme_setup_MST M (NOLOCK) on C.memo_no= M.memo_no 
	 left outer JOIN scheme_setup_loc  D (NOLOCK) ON d.memo_no=C.memo_no  
	 JOIN SKU E ON B.PRODUCT_CODE=E.PRODUCT_CODE
	 WHERE @DTODT BETWEEN CONVERT(DATETIME,CONVERT(VARCHAR,applicable_from_dt,110))  
	 AND CONVERT(DATETIME,CONVERT(VARCHAR,applicable_to_dt,110)) AND  
	 (D.DEPT_ID=A.DEPT_ID OR D.memo_no IS NULL)  AND c.scheme_mode=1 
   
     SET @cStep='70'
     PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)

	 IF NOT EXISTS (SELECT TOP 1 SLS_PRODUCT_CODE FROM ##tmpWowcbsstk WHERE isnull(Eoss_Discount_pct,0)=0)  
		GOTO LBLEND  

	 SELECT distinct b.scheme_setup_det_row_id row_id INTO #tmpSkuActiveTitles FROM ##tmpWowcbsstk a
	 LEFT JOIN sku_active_titles b (NOLOCK) ON b.product_Code=a.SLS_PRODUCT_CODE
	 LEFT JOIN sku_active_titles c (NOLOCK) ON LEFT(c.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',c.PRODUCT_CODE)-1,-1),
	 LEN(c.PRODUCT_CODE )))=LEFT(a.SLS_PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',a.SLS_PRODUCT_CODE)-1,-1),
	 LEN(a.SLS_PRODUCT_CODE )))
	 WHERE ISNULL(a.Eoss_Discount_pct,0)=0 and (b.product_Code IS NOT NULL OR c.product_Code IS NOT NULL)

	 SET @cStep='75'
	 PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
	 SELECT a.MEMO_NO,A.ROW_ID,a.discount_percentage,buy_filter_criteria,FILTER_MODE,
	 A.scheme_name,get_filter_criteria,
	 row_number() over (ORDER BY scheme_mode,MEMO_PROCESSING_ORDER,a.MEMO_NO 
	 DESC,PROCESSING_ORDER) rno
	 into #tmpSlsmst FROM scheme_setup_det A (NOLOCK)
	 JOIN scheme_setup_MST b (NOLOCK)  ON a.memo_no=b.memo_no
	 JOIN #tmpSkuActiveTitles c ON c.row_id=a.row_id
	 WHERE @DTODT  BETWEEN applicable_from_dt AND applicable_to_dt
	 
	 WHILE EXISTS (SELECT TOP 1 * FROM  #tmpSlsmst)
	 BEGIN  
		   SET @cStep='80'	   
		   PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
		   SELECT TOP 1 @CSLSMEMONO=memo_no,@cSchRowId=row_id,@cBuyFilter=buy_filter_criteria,
		   @cGetFILTER=get_filter_criteria,
		   @NSLSDISC=discount_percentage,@nFilterMode=filter_mode,@cSchName=scheme_name
		   FROM #tmpSlsmst 
		   order by RNO

		   Print 'Processing eoss schemes for scheme name:'+@cSchName

		   IF EXISTS (SELECT DEPT_ID FROM scheme_setup_loc (nolock) WHERE MEMO_NO=@CSLSMEMONO)
				SET @CLOCFILTER=' AND DEPT_ID IN (SELECT DEPT_ID FROM scheme_setup_loc WHERE MEMO_NO='''+@CSLSMEMONO+''')'
		   ELSE
				SET @CLOCFILTER=''

			IF @nFiltermode=6
			BEGIN
				SET @cStep='90'
				PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
 				EXEC SP3S_EOSS_GETSCHEMES_PARA_COMBINATION
				@SCHEME_SETUP_DET_ROW_ID=@CSCHROWID,
				@CJOINSTRBUY=@CJOINSTRBUY OUTPUT,
				@CJOINSTRGET=@CJOINSTRGET OUTPUT,
				@cErrormsg=@cErrormsg OUTPUT

				IF ISNULL(@cErrormsg,'')<>''
					GOTO END_PROC
		

		
				SET @cStep='100'
				PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
				SET @CCMD=N'UPDATE a SET eoss_scheme_name='''+@cSchName+''',
				Eoss_Discount_pct=(CASE WHEN sc.discount_mode=1 THEN sc.discount_figure
										WHEN sc.discount_mode=2 THEN ((sc.discount_figure/itv.MRP)*100)
											WHEN sc.discount_mode=3 THEN (((itv.MRP-sc.discount_figure)/itv.MRP)*100)
											ELSE 0 END)
				FROM ##tmpWowcbsstk a JOIN sku_names itv(NOLOCK) ON a.sls_product_code=itv.product_code '+@CJOINSTRBUY+'
				WHERE sc.scheme_Setup_det_row_id='''+@CSCHROWID+''''+@CLOCFILTER
				PRINT ISNULL(@CCMD  ,'null cmd')
				EXEC SP_EXECUTESQL @CCMD

			END
			ELSE
			IF @nFiltermode=1 
			BEGIN	
				SET @cStep='120'
				PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
				IF ISNULL(@cBuyFilter,'')<>''
				BEGIN

					SET @CCMD=N'UPDATE B SET eoss_scheme_name='''+@cSchName+''',Eoss_Discount_pct='+STR(@NSLSDISC)+'  
					FROM ##tmpWowcbsstk  B
					JOIN sku_active_titles sact (NOLOCK) ON sact.product_code=b.sls_product_code
					WHERE sact.scheme_Setup_det_row_id='''+@CSCHROWID+''''+@CLOCFILTER

					PRINT ISNULL(@CCMD  ,'null cmd')
					EXEC SP_EXECUTESQL @CCMD
				END

			END
	   
			SET @cStep='130'
			IF NOT EXISTS (SELECT TOP 1 SLS_PRODUCT_CODE FROM ##tmpWowcbsstk WHERE ISNULL(Eoss_Discount_pct,0)=0)  
			BEGIN  
				SET @BPENDING=0  
				BREAK  
			END  
		
			DELETE FROM #tmpSlsmst WHERE row_id=@cSchRowId 	   
	  END  

LBLEND:  

	SET @cStep='135'
	PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
	UPDATE a SET EOSS_CATEGORY=(CASE WHEN ISNULL(eoss_scheme_name,'')<>'' THEN 'Discounted' ELSE 'Fresh' END),
	Eoss_Discount_amt=(a.Eoss_Discount_pct*mrp/100) FROM ##tmpWowcbsstk a
	JOIN sku (NOLOCK) ON sku.product_code=a.SLS_PRODUCT_CODE

	SET @cStep='140'
	PRINT 'rUNNING EossSchemes STEP#'+@cStep+':'+convert(varchar,getdate(),113)
	UPDATE a SET EOSS_CATEGORY='Discounted',Eoss_scheme_name='Promotional' FROM ##tmpWowcbsstk a
	JOIN Sku_Active_Titles b ON b.product_code=a.sls_product_code
	JOIN scheme_setup_det c (NOLOCK) ON c.row_id=b.scheme_setup_det_row_id
	JOIN scheme_setup_MST d (NOLOCK)  ON d.memo_no=c.memo_no
	WHERE @DTODT  BETWEEN applicable_from_dt AND applicable_to_dt
	AND eoss_category='Fresh'


	--if @@spid=87
	--select 'check eoss stock',* from ##tmpWowcbsstk where EOSS_CATEGORY<>'fresh'
END TRY

BEGIN CATCH
print 'enter catch of SPwow_xpert_GETCBS_DETAILS'
	SET @cErrormsg='Error in  Procedure SPwow_xpert_GETCBS_DETAILS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
END