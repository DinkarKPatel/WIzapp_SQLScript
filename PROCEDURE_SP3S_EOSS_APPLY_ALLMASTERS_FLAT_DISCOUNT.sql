CREATE PROCEDURE SP3S_EOSS_APPLY_ALLMASTERS_FLAT_DISCOUNT--(LocId 3 digit change by Sanjay:05-11-2024)
(
 @SCHEME_SETUP_DET_ROW_ID VARCHAR(40)
,@ERRMSG VARCHAR(MAX) OUTPUT ,
@cLocationId VARCHAR(4)=''
)
AS
BEGIN
 ---DECLARE LOCAL VARIABLE
 DECLARE @NLOOP_START INT,@NLOOP_END INT,@PRODUCT_CODE VARCHAR(100)
        ,@CPICKSLRDISCMODE VARCHAR(5),@NCONFIG_LOOP_START INT
        ,@NCONFIG_LOOP_END INT,@CCONFIG_COLUMN VARCHAR(200)
        ,@DTSQLJOIN NVARCHAR(MAX),@DTSQL NVARCHAR(MAX),@DTSQLCOLUMN NVARCHAR(MAX)
        ,@DTSQLFROM NVARCHAR(MAX),@DISCOUNT_PERCENTAGE NUMERIC(15,2),@DISCOUNT_AMOUNT NUMERIC(15,2) 
        ,@NET NUMERIC(15,2),@MRP NUMERIC(15,2),@DISCOUNT_MODE INT,@DISCOUNT_FIGURE NUMERIC(15,2)
        ,@QUANTITY INT,@CSTEP VARCHAR(4)
        ,@CSCHEMENAME  VARCHAR(200),@cRowId VARCHAR(50)
 
 BEGIN TRY
	 
	 SET @ERRMSG=''
	 
	 SET @CSTEP=10
	        
	DECLARE @CPickDISCSLRMODE VARCHAR(4)
	IF @cLocationId=''
		select @cLocationId=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 


	SELECT TOP 1 @CPICKSLRDISCMODE=ISNULL(DISCOUNT_PICKMODE_SLR,1) from location WHERE dept_id=@cLocationId
	 
	--- This is done regarding asking for new option of applying Sale return discount with 2 options only now (1. Tolerance based 2.Max Discount)
	--- Previous options have beed discarded now as per Tickit#0523-00163 (Date : 16-05-2023)
	--- We have to manipulate the new option value as already reference of these value lies in multiple scheme procedures
	IF ISNULL(@CPICKSLRDISCMODE,0) IN (0,1) -- (1.Tolerance based(Default) 2.Max discount)
		SET @CPICKSLRDISCMODE= 3
	ELSE
		SET @CPICKSLRDISCMODE = 1

	 --SELECT SCYHEME NAME 
	 SELECT @CSCHEMENAME = SCHEME_NAME FROM DBO.SCHEME_SETUP_DET WITH(NOLOCK) 
	 WHERE ROW_ID = @SCHEME_SETUP_DET_ROW_ID
	 
	 PRINT 'ENTER PARA COMBINATION SCHEME :'+@CSCHEMENAME+'('+@SCHEME_SETUP_DET_ROW_ID+')'
	 
	 IF OBJECT_ID('TEMPDB..#TMP_PRODUCT_CODE') IS NOT NULL
		DROP TABLE #TMP_PRODUCT_CODE
	 CREATE TABLE #TMP_PRODUCT_CODE
	 (
	  ID INT IDENTITY(1,1)
	 ,PRODUCT_CODE VARCHAR(100)
	 ,PARA1_name VARCHAR(1000)
	 ,PARA2_name VARCHAR(1000)
	 ,PARA3_name VARCHAR(1000)
	 ,PARA4_name VARCHAR(1000)
	 ,PARA5_name VARCHAR(1000)
	 ,PARA6_name VARCHAR(1000)
	 ,ARTICLE_no VARCHAR(1000)
	 ,SECTION_name VARCHAR(500)
	 ,SUB_SECTION_name VARCHAR(500)
	 ,DISCOUNT_PERCENTAGE NUMERIC(15,2)
	 ,DISCOUNT_AMOUNT NUMERIC(15,2) 
	 ,NET NUMERIC(15,2)
	 ,MRP NUMERIC(15,2)
	 ,QUANTITY INT
	 ,cmd_row_id VARCHAR(50)
	 )
	 
	 SET @CSTEP=20
	 IF OBJECT_ID('TEMPDB..#TEMP_CONFIG') IS NOT NULL
		DROP TABLE #TEMP_CONFIG
	 CREATE TABLE #TEMP_CONFIG
	 (
	  ID INT IDENTITY(1,1)
	 ,COLUMN_NAME VARCHAR(200)
	 )
	 
	 
	 IF OBJECT_ID('TEMPDB..#TEMP_SCHALLCONFIG') IS NOT NULL
		DROP TABLE #TEMP_SCHALLCONFIG
	
	 SELECT * INTO #TEMP_SCHALLCONFIG FROM SCHEME_SETUP_ALLMASTERS_CONFIG
	 WHERE SCHEME_SETUP_DET_ROW_ID = @SCHEME_SETUP_DET_ROW_ID


	 
	 IF EXISTS (SELECT TOP 1 SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_COLUMN_NAME='ARTICLE' AND 
				SCHEME_SETUP_FLAG = 1)
		UPDATE #TEMP_SCHALLCONFIG SET SCHEME_SETUP_FLAG=0 WHERE SCHEME_SETUP_COLUMN_NAME='SUBSECTION'

	 IF EXISTS (SELECT TOP 1 SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_COLUMN_NAME='SUBSECTION' AND 
				SCHEME_SETUP_FLAG = 1) OR
				EXISTS (SELECT TOP 1 SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_COLUMN_NAME='ARTICLE' AND 
				SCHEME_SETUP_FLAG = 1)
		UPDATE #TEMP_SCHALLCONFIG SET SCHEME_SETUP_FLAG=0 WHERE SCHEME_SETUP_COLUMN_NAME='SECTION'
	 
	 	 
	 INSERT INTO DBO.#TEMP_CONFIG(COLUMN_NAME) 
	 SELECT SCHEME_SETUP_COLUMN_NAME FROM #TEMP_SCHALLCONFIG WHERE SCHEME_SETUP_FLAG = 1
	 
	 SET @NCONFIG_LOOP_END   = @@ROWCOUNT;
	 
	 SET @CSTEP=30
	 
	 IF OBJECT_ID('TEMPDB..#TEMP_SCHEME_SETUP_ALLMASTERS') IS NOT NULL
	    DROP TABLE #TEMP_SCHEME_SETUP_ALLMASTERS
	    
	 SELECT * INTO #TEMP_SCHEME_SETUP_ALLMASTERS FROM DBO.SCHEME_SETUP_ALLMASTERS WITH(NOLOCK) 
	 WHERE  SCHEME_SETUP_DET_ROW_ID = @SCHEME_SETUP_DET_ROW_ID
	 

	 --IF @@SPID=87
		--select 'check tmpcmd',* from #tmpcmd

	 SET @CSTEP=35
	 
INSERT INTO #TMP_PRODUCT_CODE(PRODUCT_CODE,CMD_ROW_ID,PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME,PARA5_NAME
								   ,PARA6_NAME,ARTICLE_NO,SECTION_NAME,SUB_SECTION_NAME,DISCOUNT_PERCENTAGE
								   ,DISCOUNT_AMOUNT,NET,MRP,QUANTITY)
	 
	 SELECT T.PRODUCT_CODE,T.CMD_ROW_ID,SK.PARA1_NAME,SK.PARA2_NAME,SK.PARA3_NAME,SK.PARA4_NAME
			,SK.PARA5_NAME,SK.PARA6_NAME,SK.ARTICLE_NO,sk.SECTION_NAME,Sk.SUB_SECTION_NAME
			,T.DISCOUNT_PERCENTAGE,T.DISCOUNT_AMOUNT,T.NET,T.MRP,T.QUANTITY
	 FROM #TMPCMD T
	 JOIN DBO.SKU_NAMES SK WITH(NOLOCK) ON T.PRODUCT_CODE = SK.PRODUCT_CODE
	 WHERE (T.QUANTITY-T.SCHEME_APPLIED_QTY > 0 OR (ISNULL(@CPICKSLRDISCMODE,'')<>'3' 
	 AND T.QUANTITY<0 AND ABS(T.QUANTITY)-T.SCHEME_APPLIED_QTY>0)) AND T.DISCOUNT_PERCENTAGE=0
	 AND T.SCHEME_SETUP_DET_ROW_ID='' 	
	 SET @NLOOP_END   = @@ROWCOUNT;
	 SET @NLOOP_START = 1
	 
	 
	 SET @CSTEP=40
	 
	 WHILE @NLOOP_END >= @NLOOP_START
	 BEGIN
		 SELECT @PRODUCT_CODE= PRODUCT_CODE,@cRowId=cmd_row_id FROM #TMP_PRODUCT_CODE WHERE ID= @NLOOP_START
		 ---SET VALE OF FOLLOWING VARIABLE FOR FURTHER USED
		 SET @NCONFIG_LOOP_START = 1
		 SET @DTSQL = N'SELECT @MRP = P.MRP,@DISCOUNT_FIGURE = SC.DISCOUNT_FIGURE
						   ,@DISCOUNT_MODE = SC.DISCOUNT_MODE,@QUANTITY = P.QUANTITY
						   FROM #TMP_PRODUCT_CODE P JOIN #TEMP_SCHEME_SETUP_ALLMASTERS SC WITH(NOLOCK) ON 1=1'
		 SET @DTSQLJOIN= N''
	     
		 SET @CSTEP=50
		 --USING LOOP FOR MAKE JOIN CONDATION
		 WHILE @NCONFIG_LOOP_END >= @NCONFIG_LOOP_START
		 BEGIN
			  SELECT @CCONFIG_COLUMN = COLUMN_NAME FROM #TEMP_CONFIG WHERE ID= @NCONFIG_LOOP_START
			  IF @CCONFIG_COLUMN ='SECTION'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN sectionm (NOLOCK) ON sectionm.section_code=sc.section_code'+
								  ' AND P.SECTION_name = Sectionm.SECTION_name'
			  IF @CCONFIG_COLUMN ='SUBSECTION'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN sectiond (NOLOCK) ON sectiond.sub_section_code=sc.sub_section_code'+
								' JOIN sectionm (NOLOCK) ON sectionm.section_code=sectiond.section_code'+
								' AND p.SECTION_name = SECTIONM.section_name and p.sub_Section_name=sectiond.SUB_SECTION_name'
			  IF @CCONFIG_COLUMN ='ARTICLE'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN article (NOLOCK) ON article.article_code=sc.article_code'+
										    ' AND p.ARTICLE_no = article.article_no'
			  IF @CCONFIG_COLUMN ='PARA1'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para1 (NOLOCK) ON para1.para1_code=sc.para1_code'+
										    ' AND p.PARA1_name = para1.para1_name'
			  IF @CCONFIG_COLUMN ='PARA2'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para2 (NOLOCK) ON para2.para2_code=sc.para2_code'+
											' AND p.PARA2_name = para2.PARA2_name'
			  IF @CCONFIG_COLUMN ='PARA3'
				 SET @DTSQLJOIN =@DTSQLJOIN+' JOIN para3 (NOLOCK) ON para3.para3_code=sc.para3_code'+
										   ' AND p.PARA3_name = para3.PARA3_name'
			  IF @CCONFIG_COLUMN ='PARA4'
				 SET @DTSQLJOIN =@DTSQLJOIN+' JOIN para4 (NOLOCK) ON para4.para4_code=sc.para4_code'+
										   ' AND p.PARA4_name = para4.PARA4_name'
			  IF @CCONFIG_COLUMN ='PARA5'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para5 (NOLOCK) ON para5.para5_code=sc.para5_code'+
										    ' AND p.PARA5_name = para5.PARA5_name'
			  IF @CCONFIG_COLUMN ='PARA6'
				 SET @DTSQLJOIN = @DTSQLJOIN+' JOIN para6 (NOLOCK) ON para6.para6_code=sc.para6_code'+
										    ' AND p.PARA6_name = para6.PARA6_name'
		      
			  SET @NCONFIG_LOOP_START = @NCONFIG_LOOP_START + 1;
		 END
	     
		 SET @CSTEP=60
		 SET @DTSQL = @DTSQL+@DTSQLJOIN + ' WHERE P.PRODUCT_CODE = '''+@PRODUCT_CODE+''''
		 
		 PRINT @DTSQL
		 EXEC SP_EXECUTESQL @DTSQL ,N'@MRP NUMERIC(15,2) OUTPUT,@DISCOUNT_FIGURE NUMERIC(15,2) OUTPUT,@DISCOUNT_MODE INT OUTPUT,@QUANTITY INT OUTPUT'
								   ,@MRP OUTPUT,@DISCOUNT_FIGURE OUTPUT,@DISCOUNT_MODE OUTPUT,@QUANTITY OUTPUT
	     
		 --IF DATA ARE MATCH FROM BOTH TABLE THEN CALCULATE NET AMOUNT, DISCOUNT PERCENTAGE AND DISCOUNT AMOUNT
		 IF ISNULL(@MRP,'0') <> '0'
		 BEGIN
			 SET @CSTEP=70
			 SET @NET = (CASE WHEN ISNULL(@DISCOUNT_MODE,0)=1 THEN @MRP-(@MRP*@DISCOUNT_FIGURE/100)
						 WHEN ISNULL(@DISCOUNT_MODE,0)= 2 THEN 
						 (CASE WHEN ISNULL(@DISCOUNT_FIGURE,0)>@MRP THEN @MRP ELSE ISNULL(@DISCOUNT_FIGURE,0) END)
						 ELSE (CASE WHEN ISNULL(@DISCOUNT_FIGURE,0)>@MRP THEN 0 ELSE @MRP-ISNULL(@DISCOUNT_FIGURE,0) END) END)*@QUANTITY

			 SET @DISCOUNT_AMOUNT = (@MRP*@QUANTITY)- @NET
	         
			 IF @DISCOUNT_MODE=1
			   SET @DISCOUNT_PERCENTAGE=@DISCOUNT_FIGURE
			 ELSE
			   SET @DISCOUNT_PERCENTAGE = (@DISCOUNT_AMOUNT/(@MRP*@QUANTITY))*100
	      
		  SET @CSTEP=80
		  --UPDATE NET, DISCOUNT PERCENTAGE AND DISCOUNT AMOUNT INTO #TEMP TABLE
		  IF ISNULL(@DISCOUNT_PERCENTAGE,0) <> 0
		     BEGIN
		       UPDATE #TMPCMD SET NET =@NET
							,DISCOUNT_AMOUNT     = @DISCOUNT_AMOUNT
							,DISCOUNT_PERCENTAGE = @DISCOUNT_PERCENTAGE
							,SCHEME_SETUP_DET_ROW_ID = @SCHEME_SETUP_DET_ROW_ID
							,SLS_TITLE = CASE WHEN ISNULL(SLS_TITLE,'') = '' THEN @CSCHEMENAME ELSE SLS_TITLE + ',' + @CSCHEMENAME END
							,SCHEME_APPLIED_QTY=1
		        WHERE cmd_row_id = @cRowId
		     END
		  ELSE
		     BEGIN
		        UPDATE #TMPCMD SET NET =@NET
							,DISCOUNT_AMOUNT     = @DISCOUNT_AMOUNT
							,DISCOUNT_PERCENTAGE = @DISCOUNT_PERCENTAGE
							,SCHEME_SETUP_DET_ROW_ID = @SCHEME_SETUP_DET_ROW_ID
							,SLS_TITLE = CASE WHEN ISNULL(SLS_TITLE,'') = '' THEN @CSCHEMENAME ELSE SLS_TITLE + ',' + @CSCHEMENAME END
		       WHERE cmd_row_id = @cRowId
		     END
		  
		  SET @MRP             = 0;
		  SET @DISCOUNT_FIGURE = 0;
		  SET @DISCOUNT_MODE   = 0;
		  SET @QUANTITY        = 0;
	      
	      --UPDATE SCHEME NAME
	      --UPDATE #TMPCMD SET SLS_TITLE = CASE WHEN ISNULL(SLS_TITLE,'') = '' THEN @CSCHEMENAME ELSE SLS_TITLE + ',' + @CSCHEMENAME END
	      
		END
		SET @NLOOP_START = @NLOOP_START +1;
	 END
  END TRY
  
  BEGIN CATCH
		
		SET @ERRMSG='ERROR AT STEP#'+@CSTEP+' '+ERROR_MESSAGE()
		PRINT 'ENTER CATCH BLOCK OF SP3S_EOSS_APPLY_ALLMASTERS_FLAT_DISCOUNT'+@ERRMSG
  END CATCH
END