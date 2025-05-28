CREATE PROCEDURE SPWOW_GETBARCODE_FLATDISCOUNT
(  
     @CREFMEMODT DATETIME,
	 @cLocationId	VARCHAR(4),
	 @cProductCode VARCHAR(50),
	 @nQty NUMERIC(5,2)
) 
AS  
BEGIN  
	 DECLARE @CERRORMSG VARCHAR(MAX)

	 DECLARE @tSlsBc TABLE (DISCOUNT_PERCENTAGE NUMERIC(6,2),net NUMERIC(10,2),discount_amount NUMERIC(10,2),slsdet_row_id varchar(100),
	 scheme_Name varchar(100),happy_hours_applied BIT,happyHoursAapplicable bit)

	INSERT @tSlsBc (DISCOUNT_PERCENTAGE,net,discount_amount,slsdet_row_id ,scheme_Name,happyHoursAapplicable)
	SELECT TOP 1 a.discountPercentage ,a.netPrice*@Nqty as net,a.discountAmount*@Nqty as discount_amount,a.schemeRowId ,
	schemeName,b.happy_hours_applicable
	FROM wow_SchemeSetup_slsbc_flat a (NOLOCK)
	JOIN wow_SchemeSetup_Title_Det b (NOLOCK) on  a.schemeRowId=b.schemeRowId
	JOIN wow_schemesetup_mst c (NOLOCK) ON c.setupId=b.setupId
	left JOIN wow_SchemeSetup_locs d (NOLOCK) ON d.schemeRowId=b.schemeRowId AND d.locationId=@cLocationId
	WHERE (a.PRODUCT_CODE = @cProductCode or a.product_code=LEFT(@cProductCode, ISNULL(NULLIF(CHARINDEX ('@',@cProductCode)-1,-1),LEN(@cProductCode))))
	AND @CREFMEMODT BETWEEN d.applicableFromDt AND d.applicableToDt AND
	(b.locApplicableMode=1 OR d.schemeRowId IS NOT NULL) AND schememode=2 and b.buyFilterMode=2
	 

	 IF EXISTS (SELECT TOP 1 DISCOUNT_PERCENTAGE FROM @tSlsBc WHERE ISNULL(happyHoursAapplicable,0)=1)
	 BEGIN
		 --select * from   @tSlsbc
		 declare @CurTime DATETIME

		 SELECT @CurTime = CONVERT(DATETIME,'1900-01-01 '+LTRIM(RTRIM(STR(DATEPART(HH,GETDATE()))))+':'+
				LTRIM(RTRIM(STR(DATEPART(MI,GETDATE()))))+':00')

		 IF EXISTS (SELECT TOP 1 schemeRowId FROM  wow_schemesetup_happyhours a (NOLOCK)
					    JOIN @tSlsBc b ON a.schemeRowId=b.slsdet_row_id WHERE @CurTime BETWEEN a.from_time AND a.to_time)
			UPDATE  @tSlsBc SET happy_hours_applied=1
		ELSE
			DELETE FROM @tSlsbc
	 END

	 SELECT *,isnull(@cErrormsg,'') errmsg FROM @tSlsBc
end
