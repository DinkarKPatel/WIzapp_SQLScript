CREATE PROCEDURE SPWOW_F2F4F6
@dXnDt DATETIME
AS
BEGIN
	DECLARE @dMonthFromDt DATETIME,@dFYFromDt DATETIME,@cFinYear VARCHAR(5),@cCmd NVARCHAR(MAX),
	@cPaymodeStr VARCHAR(MAX)

	SELECT A.USER_CODE,A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,loc.dept_alias,SECTION_NAME, U.USERNAME,
	SUM(B.QUANTITY) AS SALE_QTY,SUM((B.RFNET)) AS SALE_VALUE,LOCattr14_key_name
	INTO #tmpSlsF2
	FROM CMD01106 B (NOLOCK)
	JOIN CMM01106 A (NOLOCK) ON B.CM_ID=A.CM_ID
	JOIN SKU_names C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
	JOIN USERS U (NOLOCK) ON U.USER_CODE=A.USER_CODE
	JOIN location loc (NOLOCK) ON loc.dept_id=A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/
	join LOC_NAMES ln (NOLOCK) ON ln.dept_id=loc.dept_id
	WHERE cm_dt=@dXnDt AND  A.CANCELLED=0 
	GROUP BY A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/,A.USER_CODE,U.USERNAME,SECTION_NAME,loc.dept_alias,LOCattr14_key_name
	ORDER BY A.USER_CODE,A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/,SECTION_NAME,dept_alias

	SELECT A.location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/ dept_id ,user_code ,paymode_name,sum(amount)  pay_amount INTO #tmpPayF2 FROM 
	cmm01106 a (NOLOCK) 
	JOIN paymode_xn_det b (NOLOCK) on a.cm_id=b.memo_id
	JOIN paymode_mst c (NOLOCK) ON c.paymode_code=b.paymode_code
	WHERE cm_dt=@dXnDt AND  A.CANCELLED=0 
	GROUP BY A.location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/,user_code,paymode_name
	

	SELECT DISTINCT paymode_name INTO #tmpPaymodenamesF2 from #tmpPayF2

	SELECT @cPaymodeStr=coalesce(@cPaymodestr+',','')+quotename(paymode_name) FROM #tmpPaymodenamesF2


	SET @cCmd=N'SELECT dept_alias,SECTION_NAME, USERNAME,SALE_QTY,SALE_VALUE,b.* FROM #tmpSlsF2 a
	JOIN 
	(SELECT * from #tmpPayF2 a 	pivot
	(max( pay_amount) for paymode_name in ('+@cPaymodeStr+')) pvt
	) b ON a.dept_id=b.dept_id AND a.user_code=b.USER_CODE'
	
	EXEC SP_EXECUTESQL @cCmd

	
	SET @dMonthFromDt=ltrim(rtrim(str(month(@dXnDt))))+'-01-'+ltrim(rtrim(str(year(@dXnDt))))
	SET @cFinyear='01'+dbo.fn_getfinyear(@dXnDt)
	SET @dFYFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)


	SELECT A.USER_CODE,A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,dept_alias,SECTION_NAME, U.USERNAME,
	SUM(B.QUANTITY) AS SALE_QTY,SUM((B.RFNET)) AS SALE_VALUE
	INTO #tmpSlsF4
	FROM CMD01106 B (NOLOCK)
	JOIN CMM01106 A (NOLOCK) ON B.CM_ID=A.CM_ID
	JOIN SKU_names C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
	JOIN USERS U (NOLOCK) ON U.USER_CODE=A.USER_CODE
	JOIN location loc (NOLOCK) ON loc.dept_id=A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/
	WHERE cm_dt BETWEEN @dMonthFromDt AND @dXnDt AND   A.CANCELLED=0 
	GROUP BY A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/,A.USER_CODE,U.USERNAME,SECTION_NAME,dept_alias
	ORDER BY A.USER_CODE,A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/,SECTION_NAME,dept_alias

	
	SELECT A.location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/ dept_id,user_code,paymode_name,sum(amount) pay_amount INTO #tmpPayF4 FROM 
	cmm01106 a (NOLOCK) 
	JOIN paymode_xn_det b (NOLOCK) on a.cm_id=b.memo_id
	JOIN paymode_mst c (NOLOCK) ON c.paymode_code=b.paymode_code
	WHERE cm_dt BETWEEN @dMonthFromDt AND @dXnDt AND  A.CANCELLED=0 
	GROUP BY A.location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/,paymode_name,user_code

	set @cPaymodeStr=null
	SELECT DISTINCT paymode_name INTO #tmpPaymodenamesF4 from #tmpPayF4

	SELECT @cPaymodeStr=coalesce(@cPaymodestr+',','')+quotename(paymode_name) FROM #tmpPaymodenamesF4


	SET @cCmd=N'SELECT * FROM
	(SELECT a.*,b.paymode_name,b.pay_amount FROM #tmpSlsF4 a
	JOIN #tmpPayF4 b ON a.dept_id=b.dept_id AND a.user_code=b.USER_CODE
	) a 
	pivot
	(sum( pay_amount) for paymode_name in ('+@cPaymodeStr+')) pvt'

	EXEC SP_EXECUTESQL @cCmd

	SELECT A.USER_CODE,A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,dept_alias,SECTION_NAME, U.USERNAME,
	SUM(B.QUANTITY) AS SALE_QTY,SUM((B.RFNET)) AS SALE_VALUE
	INTO #tmpSlsF6
	FROM CMD01106 B (NOLOCK)
	JOIN CMM01106 A (NOLOCK) ON B.CM_ID=A.CM_ID
	JOIN SKU_names C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
	JOIN USERS U (NOLOCK) ON U.USER_CODE=A.USER_CODE
	JOIN location loc (NOLOCK) ON loc.dept_id=A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/
	WHERE cm_dt BETWEEN @dFYFromDt AND @dXnDt AND  A.CANCELLED=0 
	GROUP BY A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/,A.USER_CODE,U.USERNAME,SECTION_NAME,dept_alias
	ORDER BY A.USER_CODE,A.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/,SECTION_NAME,dept_alias
	

	SELECT A.location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/ dept_id,user_code ,paymode_name,sum(amount)  pay_amount INTO #tmpPayF6 FROM 
	cmm01106 a (NOLOCK) 
	JOIN paymode_xn_det b (NOLOCK) on a.cm_id=b.memo_id
	JOIN paymode_mst c (NOLOCK) ON c.paymode_code=b.paymode_code
	WHERE cm_dt BETWEEN @dFYFromDt AND @dXnDt AND  A.CANCELLED=0 
	GROUP BY A.location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/,paymode_name,user_code

	set @cPaymodeStr=null
	SELECT DISTINCT paymode_name INTO #tmpPaymodenamesF6 from #tmpPayF6
	SELECT @cPaymodeStr=coalesce(@cPaymodestr+',','')+quotename(paymode_name) FROM #tmpPaymodenamesF6


	SET @cCmd=N'SELECT * FROM
	(SELECT a.*,b.paymode_name,b.pay_amount FROM #tmpSlsF6 a
	JOIN #tmpPayF6 b ON a.dept_id=b.dept_id AND a.user_code=b.USER_CODE
	) a 
	pivot
	(sum( pay_amount) for paymode_name in ('+@cPaymodeStr+')) pvt'

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

END
