CREATE PROCEDURE SP3S_STOCKAGE  
(
	 @CLAYOUT	VARCHAR(500) 
	,@DPROCESS DATETIME 
	,@CFILTER	VARCHAR(MAX)=''
	,@NAGE1	NUMERIC(3)=0
	,@NAGE2	NUMERIC(3)=0
	,@NAGE3	NUMERIC(3)=0
	,@BREPROCESS BIT=0
	,@CDPROCESSID VARCHAR(50) OUTPUT	
	,@CERRMSG VARCHAR(500) OUTPUT	
)
--WITH ENCRYPTION
AS
/*
	THIS PROCEDURE CALCULATES AGE VALUES AT FOUR DEFINED LEVELS FOR A LAYOUT WITH DIFFERENT FILTER CONDITIONS
*/
BEGIN
	DECLARE @CTSQL NVARCHAR(MAX),@CSTEP VARCHAR(5),@CDPROCESS VARCHAR(15)
	,@CAGE1 VARCHAR(3),@CAGE2 VARCHAR(3),@CAGE3 VARCHAR(3),@CWHERECLAUSE VARCHAR(1000),@CRFDB VARCHAR(500),
	@CTSQL1 NVARCHAR(MAX)					
	
	BEGIN TRY
	SET @CSTEP=10
	IF ISNULL(@DPROCESS,'')=''
	BEGIN
		SET @CERRMSG='ERROR EXECUTING PROCEDURE - SP3S_STOCKAGE , MESSAGE - NO PROCESS DATE DEFINED'
		GOTO EXIT_PROC
	END	
	
	SET @CSTEP=20
	IF CHARINDEX('DEPT_ID',@CLAYOUT)<>0
		SET @CLAYOUT='LOCATION.MAJOR_DEPT_ID'
	
	SET @CSTEP=30
	SET @CDPROCESS=CONVERT(VARCHAR,@DPROCESS,110)
	--SET @CRFDB=DB_NAME()+'_RFOPT.DBO.RF_OPT'
	SET @CRFDB=DB_NAME()+'.DBO.VW_XNSREPS'
	
	SET @CSTEP=40
	IF (@NAGE1=0 OR @NAGE2=0 OR @NAGE3=0)
	BEGIN
		SELECT @NAGE1=DBO.FN3S_GETDBCONFIG('AGE1'),@NAGE2=DBO.FN3S_GETDBCONFIG('AGE2'),@NAGE3=DBO.FN3S_GETDBCONFIG('AGE3')
	END
	
	SET @CSTEP=50	
	IF ISNULL(@CLAYOUT,'')=''
	BEGIN
		SET @CERRMSG='ERROR EXECUTING PROCEDURE - SP3S_STOCKAGE , MESSAGE - NO LAYOUT SELECTED'
		GOTO EXIT_PROC
	END	
	
	SET @CAGE1=@NAGE1
	SET @CAGE2=@NAGE2
	SET @CAGE3=@NAGE3
	
	SELECT @CDPROCESSID=PROCESS_ID FROM AGE_MST WHERE PROCESS_DT=@CDPROCESS AND LAYOUT=@CLAYOUT AND FILTER=@CFILTER AND AGE1_PARA=@CAGE1 AND AGE2_PARA=@CAGE2 AND AGE3_PARA=@CAGE3
	
	IF @BREPROCESS=1 AND ISNULL(@CDPROCESSID,'')<>''
	BEGIN
		DELETE AGE_DET WHERE PROCESS_ID=@CDPROCESSID
		DELETE AGE_MST WHERE PROCESS_ID=@CDPROCESSID
		SET @CDPROCESSID=''
	END
	
	IF ISNULL(@CDPROCESSID,'')<>''
		RETURN
	ELSE 
		SET @CDPROCESSID='AGE'+CONVERT(VARCHAR(40),NEWID())
	
	IF OBJECT_ID('TEMPDB..#AGEING','U') IS NOT NULL
		DROP TABLE #AGEING
	
	CREATE TABLE #AGEING(LAYOUT_VALUE VARCHAR(500),AGE1 NUMERIC(18,4),AGE2 NUMERIC(18,4),AGE3 NUMERIC(18,4),AGE4 NUMERIC(18,4))
	
	SET @CWHERECLAUSE=' WHERE ARTICLE.STOCK_NA=0 AND LOCATION.INACTIVE=0 '+(CASE WHEN ISNULL(@CFILTER,'')='' THEN '' ELSE ' AND ' END)
					  +@CFILTER
	
	SET @CTSQL=N'SELECT '+@CLAYOUT+' AS DEPT_ID
					,CAST(SUM((CASE  WHEN DATEDIFF(DD,SKU.RECEIPT_DT,'''+@CDPROCESS+''')<='+@CAGE1+' THEN
					 (CASE WHEN A.XN_TYPE IN (''OPS'',''PUR'',''CHI'',''SLR'',''UNC'',''APR'',''WSR'',''PFI'',''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') 
										  THEN 1 WHEN A.XN_TYPE IN (''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
										  THEN -1 ELSE 0 END) ELSE 0 END)
					* (XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN FORM.POST_TAX_SEPARATELY=1 THEN 0
					  ELSE ISNULL(SKU_OH.TAX_AMOUNT,0) END)))) AS NUMERIC(14,2)) AS VALUE1
					,CAST(SUM((CASE  WHEN DATEDIFF(DD,SKU.RECEIPT_DT,'''+@CDPROCESS+''') BETWEEN '+LTRIM(RTRIM(STR(@CAGE1+1)))+' AND '+@CAGE2+' THEN
					 (CASE WHEN A.XN_TYPE IN (''OPS'',''PUR'',''CHI'',''SLR'',''UNC'',''APR'',''WSR'',''PFI'',''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') 
										  THEN 1 WHEN A.XN_TYPE IN (''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
										  THEN -1 ELSE 0 END) ELSE 0 END)
					* (XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN FORM.POST_TAX_SEPARATELY=1 THEN 0
					  ELSE ISNULL(SKU_OH.TAX_AMOUNT,0) END)))) AS NUMERIC(14,2)) AS VALUE2
					,CAST(SUM((CASE  WHEN DATEDIFF(DD,SKU.RECEIPT_DT,'''+@CDPROCESS+''') BETWEEN '+LTRIM(RTRIM(STR(@CAGE2+1)))+' AND '+@CAGE3+' THEN
					 (CASE WHEN A.XN_TYPE IN (''OPS'',''PUR'',''CHI'',''SLR'',''UNC'',''APR'',''WSR'',''PFI'',''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') 
										  THEN 1 WHEN A.XN_TYPE IN (''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
										  THEN -1 ELSE 0 END) ELSE 0 END)
					* (XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN FORM.POST_TAX_SEPARATELY=1 THEN 0
					  ELSE ISNULL(SKU_OH.TAX_AMOUNT,0) END)))) AS NUMERIC(14,2)) AS VALUE3
					,CAST(SUM((CASE  WHEN DATEDIFF(DD,SKU.RECEIPT_DT,'''+@CDPROCESS+''')>'+@CAGE3+' THEN
					 (CASE WHEN A.XN_TYPE IN (''OPS'',''PUR'',''CHI'',''SLR'',''UNC'',''APR'',''WSR'',''PFI'',''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') 
										  THEN 1 WHEN A.XN_TYPE IN (''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
										  THEN -1 ELSE 0 END) ELSE 0 END)
					* (XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN FORM.POST_TAX_SEPARATELY=1 THEN 0
					  ELSE ISNULL(SKU_OH.TAX_AMOUNT,0) END)))) AS NUMERIC(14,2)) AS VALUE4					  					    
        FROM '+@CRFDB+' A  (NOLOCK) 
        JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE 
        LEFT JOIN SKU_OH (NOLOCK) ON SKU.PRODUCT_CODE=SKU_OH.PRODUCT_CODE
        JOIN FORM (NOLOCK) ON SKU.FORM_ID=FORM.FORM_ID
        JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE=ARTICLE.ARTICLE_CODE
        JOIN LOCATION (NOLOCK) ON LOCATION.DEPT_ID=A.DEPT_ID
		JOIN PARA1 (NOLOCK) ON SKU.PARA1_CODE=PARA1.PARA1_CODE
		JOIN PARA2 (NOLOCK) ON SKU.PARA2_CODE=PARA2.PARA2_CODE
		JOIN PARA3 (NOLOCK) ON SKU.PARA3_CODE=PARA3.PARA3_CODE
		JOIN PARA4 (NOLOCK) ON SKU.PARA4_CODE=PARA4.PARA4_CODE
		JOIN PARA5 (NOLOCK) ON SKU.PARA5_CODE=PARA5.PARA5_CODE
		JOIN PARA6 (NOLOCK) ON SKU.PARA6_CODE=PARA6.PARA6_CODE '
	 SET @CTSQL1=N'	LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON ARTICLE.ARTICLE_CODE = ATTR.ARTICLE_CODE 
		LEFT OUTER JOIN ATTR1_MST AT1 (NOLOCK) ON AT1.ATTR1_KEY_CODE=ATTR.ATTR1_KEY_CODE
		LEFT OUTER JOIN ATTR2_MST AT2 (NOLOCK) ON AT2.ATTR2_KEY_CODE=ATTR.ATTR2_KEY_CODE
		LEFT OUTER JOIN ATTR3_MST AT3 (NOLOCK) ON AT3.ATTR3_KEY_CODE=ATTR.ATTR3_KEY_CODE
		LEFT OUTER JOIN ATTR4_MST AT4 (NOLOCK) ON AT4.ATTR4_KEY_CODE=ATTR.ATTR4_KEY_CODE
		LEFT OUTER JOIN ATTR5_MST AT5 (NOLOCK) ON AT5.ATTR5_KEY_CODE=ATTR.ATTR5_KEY_CODE
		LEFT OUTER JOIN ATTR6_MST AT6 (NOLOCK) ON AT6.ATTR6_KEY_CODE=ATTR.ATTR6_KEY_CODE
		LEFT OUTER JOIN ATTR7_MST AT7 (NOLOCK) ON AT7.ATTR7_KEY_CODE=ATTR.ATTR7_KEY_CODE
		LEFT OUTER JOIN ATTR8_MST AT8 (NOLOCK) ON AT8.ATTR8_KEY_CODE=ATTR.ATTR8_KEY_CODE
		LEFT OUTER JOIN ATTR9_MST AT9 (NOLOCK) ON AT9.ATTR9_KEY_CODE=ATTR.ATTR9_KEY_CODE
		LEFT OUTER JOIN ATTR10_MST AT10 (NOLOCK) ON AT10.ATTR10_KEY_CODE=ATTR.ATTR10_KEY_CODE
		LEFT OUTER JOIN ATTR11_MST AT11 (NOLOCK) ON AT11.ATTR11_KEY_CODE=ATTR.ATTR11_KEY_CODE
		LEFT OUTER JOIN ATTR12_MST AT12 (NOLOCK) ON AT12.ATTR12_KEY_CODE=ATTR.ATTR12_KEY_CODE
		LEFT OUTER JOIN ATTR13_MST AT13 (NOLOCK) ON AT13.ATTR13_KEY_CODE=ATTR.ATTR13_KEY_CODE
		LEFT OUTER JOIN ATTR14_MST AT14 (NOLOCK) ON AT14.ATTR14_KEY_CODE=ATTR.ATTR14_KEY_CODE
		LEFT OUTER JOIN ATTR15_MST AT15 (NOLOCK) ON AT15.ATTR15_KEY_CODE=ATTR.ATTR15_KEY_CODE
		LEFT OUTER JOIN ATTR16_MST AT16 (NOLOCK) ON AT16.ATTR16_KEY_CODE=ATTR.ATTR16_KEY_CODE
		LEFT OUTER JOIN ATTR17_MST AT17 (NOLOCK) ON AT17.ATTR17_KEY_CODE=ATTR.ATTR17_KEY_CODE
		LEFT OUTER JOIN ATTR18_MST AT18 (NOLOCK) ON AT18.ATTR18_KEY_CODE=ATTR.ATTR18_KEY_CODE
		LEFT OUTER JOIN ATTR19_MST AT19 (NOLOCK) ON AT19.ATTR19_KEY_CODE=ATTR.ATTR19_KEY_CODE
		LEFT OUTER JOIN ATTR20_MST AT20 (NOLOCK) ON AT20.ATTR20_KEY_CODE=ATTR.ATTR20_KEY_CODE
		LEFT OUTER JOIN ATTR21_MST AT21 (NOLOCK) ON AT21.ATTR21_KEY_CODE=ATTR.ATTR21_KEY_CODE
		LEFT OUTER JOIN ATTR22_MST AT22 (NOLOCK) ON AT22.ATTR22_KEY_CODE=ATTR.ATTR22_KEY_CODE
		LEFT OUTER JOIN ATTR23_MST AT23 (NOLOCK) ON AT23.ATTR23_KEY_CODE=ATTR.ATTR23_KEY_CODE
		LEFT OUTER JOIN ATTR24_MST AT24 (NOLOCK) ON AT24.ATTR24_KEY_CODE=ATTR.ATTR24_KEY_CODE
		LEFT OUTER JOIN ATTR25_MST AT25(NOLOCK) ON AT25.ATTR25_KEY_CODE=ATTR.ATTR25_KEY_CODE
		JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE=SECTIOND.SUB_SECTION_CODE
		JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE=SECTIONM.SECTION_CODE
		JOIN LMV01106 (NOLOCK) ON SKU.AC_CODE=LMV01106.AC_CODE
		'+@CWHERECLAUSE+'
        GROUP BY '+@CLAYOUT			
	
	PRINT ISNULL(@CTSQL+@CTSQL1,'NULL AGEING COMMAND')	               
    INSERT #AGEING(LAYOUT_VALUE,AGE1,AGE2,AGE3,AGE4) 
    EXEC  (@CTSQL+@CTSQL1)
    
    IF EXISTS(SELECT TOP 1 'U' FROM #AGEING)
	BEGIN
		 INSERT AGE_MST	( PROCESS_ID, PROCESS_DT, LAYOUT, FILTER, AGE1_PARA, AGE2_PARA, AGE3_PARA )  
		 SELECT @CDPROCESSID AS PROCESSID,@CDPROCESS AS PROCESSDT,@CLAYOUT AS LAYOUT,@CFILTER AS FILTER,@CAGE1 AS AGE1_PARA,@CAGE2 AS AGE2_PARA,@CAGE3 AS AGE3_PARA 
		
		 INSERT AGE_DET	( PROCESS_ID, LAYOUT_VALUE, AGE1, AGE2, AGE3, AGE4 )  
		 SELECT @CDPROCESSID AS PROCESSID,LAYOUT_VALUE, AGE1, AGE2, AGE3, AGE4 FROM #AGEING
		 WHERE AGE1<>0 OR AGE2<>0 OR AGE3<>0 OR AGE4<>0
	END	
        
END TRY
BEGIN CATCH
	SET @CERRMSG='ERROR EXECUTING PROCEDURE :  SP3S_STOCKAGE, AT STEP - '+@CSTEP+CHAR(13)+', MESSAGE : '+ERROR_MESSAGE() 
END CATCH

EXIT_PROC:
	
END	
----END OF PROCEDURE - SP3S_STOCKAGE
