CREATE FUNCTION FN3S_GETFINYEAR_LASTPMTXNDT (@dXndt DATETIME)
returns VARCHAR(20)
AS
BEGIN
	DECLARE @tPmtTable varchar(300),@bFound BIT,@cDtSuffix VARCHAR(500),@dXnDtPara DATETIME
	
	SET @dXnDtPara=@dXnDt
	SET @bFound=0

	WHILE @bFound=0
	BEGIN
		SET @cDtSuffix=CONVERT(VARCHAR,@dXnDt,112)

		SET @tPmtTable=DB_NAME()+'_PMT.DBO.pmtlocs_'+@cDtSuffix
		
		IF OBJECT_ID(@tPmtTable,'u') IS NOT NULL
			BREAK

		SET @dXndt=@dXndt-1

		IF DATEDIFF(DD,@dXnDt,@dXnDtpara)>365
			BREAK
	END

	RETURN @cDtSuffix
END