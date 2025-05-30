create PROCEDURE SP3S_PENDINGORDER_FOR_JOBCARD_SUMMARY
(
	@CWHERE NVARCHAR(MAX),
	@cLocID varchar(5)=''
)
AS
BEGIN
    

	IF ISNULL(@cLocID,'')=''    
	SELECT @cLocID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 

	     DECLARE @LEVEL_NO INT
		SELECT TOP 1 @LEVEL_NO=LEVEL_NO  FROM XN_APPROVAL_CHECKLIST_LEVEL_USERS A  
		WHERE A.XN_TYPE ='WSLORD'	AND DEPT_ID =@cLocID

		SET @LEVEL_NO=ISNULL(@LEVEL_NO,0)


	DECLARE @CSIZE VARCHAR(MAX),@CSIZE_SUM VARCHAR(MAX),@CSIZE_SUM_TOTAL VARCHAR(MAX),@CCMD NVARCHAR(MAX)
	PRINT @CWHERE
	SET @CWHERE=REPLACE(@CWHERE,'`','''')
	IF OBJECT_ID('TEMPDB..#PENDINGBUYERORDER','U') IS NOT NULL
		DROP TABLE #PENDINGBUYERORDER

	IF OBJECT_ID('TEMPDB..##PENDINGORDER_PIVOT','U') IS NOT NULL
		DROP TABLE ##PENDINGORDER_PIVOT
		
	CREATE TABLE #PENDINGBUYERORDER
	(
		ARTICLE_NO		VARCHAR(MAX),
		ARTICLE_CODE	VARCHAR(MAX),
		PARA1_CODE		VARCHAR(MAX),
		PARA2_CODE		VARCHAR(MAX),
		PARA1_NAME		VARCHAR(MAX),
		PARA2_NAME		VARCHAR(MAX),
		QUANTITY		NUMERIC(14,2),
		EMP_NAME varchar(100),
		username	VARCHAR(100),
		para2_order numeric(5,0)
	)
	BEGIN TRY

		SET @CCMD=N'
		SELECT ARTICLE_NO,A.ARTICLE_CODE,A.PARA1_CODE,A.PARA2_CODE,PARA1.PARA1_NAME,PARA2.PARA2_NAME,
		(CASE WHEN (A.QUANTITY-ISNULL(B.QUANTITY,0))<=0 THEN NULL ELSE A.QUANTITY-ISNULL(B.QUANTITY,0) END) AS QUANTITY,
		ISNULL(EMPLOYEE.emp_name,'''') AS EMP_NAME,USERS.username,PARA2.para2_order
		--INTO #PENDINGBUYERORDER
		FROM BUYER_ORDER_DET A 
		LEFT OUTER JOIN
		(
			SELECT WOD_ROW_ID,SUM(QUANTITY) AS QUANTITY 
			FROM ORD_PLAN_DET  
			JOIN ORD_PLAN_MST ON ORD_PLAN_MST.MEMO_ID = ORD_PLAN_DET.MEMO_ID
			WHERE ORD_PLAN_MST.CANCELLED = 0  AND ISNULL(WOD_ROW_ID,'''') <> '''' 
			GROUP BY WOD_ROW_ID
		) B ON A.ROW_ID = B.WOD_ROW_ID
		--LEFT OUTER JOIN
		--(
		--	SELECT ORD_ROW_ID,SUM(QUANTITY) AS QUANTITY 
		--	FROM PLD01106  
		--	JOIN PLM01106 ON PLD01106.MEMO_ID = PLM01106.MEMO_ID
		--	WHERE PLM01106.CANCELLED = 0  AND ISNULL(ORD_ROW_ID,'''') <> '''' 
		--	GROUP BY ORD_ROW_ID
		--) B1 ON A.ROW_ID = B1.ORD_ROW_ID
		JOIN BUYER_ORDER_MST (NOLOCK) ON A.ORDER_ID = BUYER_ORDER_MST.ORDER_ID
		JOIN LMV01106 (NOLOCK) ON BUYER_ORDER_MST.AC_CODE = LMV01106.AC_CODE
		JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE = A.ARTICLE_CODE
		JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE = A.PARA1_CODE
		JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE = A.PARA2_CODE
		JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE = a.PARA3_CODE
		JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE = a.PARA4_CODE
		JOIN PARA5 (NOLOCK) ON PARA5.PARA5_CODE	= a.PARA5_CODE
		JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE = a.PARA6_CODE
		JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE = ARTICLE.SUB_SECTION_CODE
		JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE = SECTIOND.SECTION_CODE
		JOIN UOM (NOLOCK) ON UOM.UOM_CODE = ARTICLE.UOM_CODE
		LEFT JOIN EMPLOYEE  (NOLOCK) ON EMPLOYEE.EMP_CODE=A.ITEM_MERCHANT_CODE
		LEFT JOIN USERS  (NOLOCK) ON USERS.user_code=BUYER_ORDER_MST.user_code
		LEFT JOIN (SELECT DISTINCT ORDER_ID FROM JOBWORK_PMT (NOLOCK) WHERE ISNULL(ORDER_ID,'''')<>'''') PMT ON PMT.ORDER_ID=A.ORDER_ID
		WHERE PMT.ORDER_ID IS NULL 
		and ('+str(@LEVEL_NO)+'=0 OR BUYER_ORDER_MST.APPROVEDLEVELNO =99)  
		AND A.QUANTITY-ISNULL(B.QUANTITY,0) > 0  AND (A.QUANTITY-ISNULL(B.QUANTITY,0) > 0 OR  B.WOD_ROW_ID IS NULL) 
		AND BUYER_ORDER_MST.CANCELLED = 0 AND ISNULL(BUYER_ORDER_MST.Short_close,0) = 0 AND '
		+ 
		(CASE WHEN ISNULL(@CWHERE,'')='' THEN ' 1=1 ' ELSE ISNULL(@CWHERE,'') END)
		--BUYER_ORDER_MST.MEMO_TYPE=2 AND 
		PRINT 'STEP 1 :'+ @CCMD
		
		INSERT INTO  #PENDINGBUYERORDER
		EXEC SP_EXECUTESQL @CCMD
		
		--APPROVED
		

		IF (0= @@ROWCOUNT)
		BEGIN
			SELECT CONVERT(BIT,0) AS BCHK,ARTICLE_NO,ARTICLE_CODE,PARA1_CODE,PARA1_NAME,EMP_NAME,username FROM #PENDINGBUYERORDER
			RETURN
		END
		

		SELECT  
		@CSIZE=ISNULL(@CSIZE,'')+(CASE WHEN ISNULL(@CSIZE,'')='' THEN '' ELSE ',' END ) +'['+PARA2_NAME+']',
		@CSIZE_SUM=ISNULL(@CSIZE_SUM,'')+(CASE WHEN ISNULL(@CSIZE_SUM,'')='' THEN '' ELSE ',' END ) +'SUM(['+PARA2_NAME+']) AS ['+PARA2_NAME+']',
		@CSIZE_SUM_TOTAL=ISNULL(@CSIZE_SUM_TOTAL,'')+(CASE WHEN ISNULL(@CSIZE_SUM_TOTAL,'')='' THEN '' ELSE '+' END ) +'ISNULL(SUM(['+PARA2_NAME+']),0)'
		FROM #PENDINGBUYERORDER
		GROUP BY PARA2_NAME 
		order by max(para2_order )
		
		--SELECT @CSIZE ,@CSIZE_SUM,@CSIZE_SUM_TOTAL

		SET @CCMD=N'
		SELECT ARTICLE_NO,ARTICLE_CODE,PARA1_CODE,PARA1_NAME,EMP_NAME,username,'+@CSIZE+
		'INTO ##PENDINGORDER_PIVOT
		FROM 
		(
			SELECT * FROM #PENDINGBUYERORDER
			
		)X
		PIVOT
		(
			SUM(QUANTITY)
			FOR PARA2_NAME IN ('+@CSIZE+')
		)PVT'

		PRINT 'STEP 2 :'+ @CCMD
		
		EXEC SP_EXECUTESQL @CCMD
		
		
			
		SET @CCMD=N'
		SELECT CONVERT(BIT,0) AS BCHK,ARTICLE_NO,ARTICLE_CODE,PARA1_CODE,PARA1_NAME,EMP_NAME,username,'+
		@CSIZE_SUM+','+@CSIZE_SUM_TOTAL +' AS TOTAL,CONVERT(NUMERIC(14,2),0) AS ORD_QTY
		FROM ##PENDINGORDER_PIVOT
		GROUP BY ARTICLE_NO,ARTICLE_CODE,PARA1_CODE,PARA1_NAME,EMP_NAME,username'
		
		PRINT 'STEP 3 :'+ @CCMD
		
		EXEC SP_EXECUTESQL @CCMD
	END TRY
	BEGIN CATCH
		SELECT @@ERROR
	END CATCH
END
