CREATE FUNCTION fn3s_getgmttime (@cLocId CHAR(2))
RETURNS DATETIME
AS
BEGIN
	DECLARE @nGmt NUMERIC(10,2),@dLastUpd DATETIME,@nHrs NUMERIC(2,0),@nMins NUMERIC(2,0)
	SELECT TOP 1 @nGmt=timezonediff FROM location WHERE dept_id=@cLocId AND ISNULL(fc_code,'') NOT IN ('','0000000')
	
	
	SET @dLastUpd=GETDATE()
	
	IF ISNULL(@nGmt,0)=0
		RETURN @dLastUpd
	
		
	SET @dLastUpd=DATEADD(HH,ROUND(@nGmt,0),@dLastUpd)
	
	SET @dLastUpd=DATEADD(MI,CONVERT(NUMERIC,PARSENAME(@nGmt,1)),@dLastUpd)
	
	RETURN @dLastUpd
END