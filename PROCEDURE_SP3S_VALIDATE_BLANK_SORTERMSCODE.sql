CREATE PROCEDURE SP3S_VALIDATE_BLANK_SORTERMSCODE
@dFromDt DATETIME,
@dToDt DATETIME,
@cErrormsg varchar(max) OUTPUT
AS
BEGIN
	DECLARE @cCmdRowId VARCHAR(40),@cAcname VARCHAR(500)

	SET @cErrormsg=''

	
	SELECT top 1 @cCmdRowId=a.row_id,@cAcname=AC_NAME from cmd01106 a (NOLOCK)
	JOIN sku b (NOLOCK) ON a.product_code=b.product_code
	JOIN cmm01106 c (NOLOCK) ON c.cm_id=a.cm_id
	JOIN dtm d (NOLOCK) ON d.dt_code=c.DT_CODE
	JOIN lm01106 e (NOLOCK) ON e.ac_code=b.ac_code
	JOIN #tSorLm sorlm ON sorlm.ac_code=b.ac_code
	WHERE  (a.BASIC_DISCOUNT_AMOUNT<>0 OR 
	(ISNULL(a.cmm_discount_amount,0)<>0 and ISNULL(d.dtm_type,0)=2))
	AND isnull(a.sor_terms_code,'') IN('' ,'000')
	AND c.cm_dt between @DFROMDT AND @dToDt AND cancelled=0
	AND e.sor_party=1

	SET @cErrormsg='Some items for Supplier:('+@cAcName+') found not having SOR Terms defined...Please get it checked...'
		

END

