CREATE FUNCTION DBO.GET_PERIOD_DATE(@DATE DATE,@PERIOD VARCHAR(10))
RETURNS VARCHAR(10)
AS
BEGIN
DECLARE @DATED DATE,@FIN INT=1
SET @DATE=DATEADD(YY,CASE LEFT(@PERIOD,1) WHEN 'L' THEN -1 ELSE 0 END,@DATE)

SET @DATED= CASE WHEN @PERIOD LIKE '%[D,T]' THEN @DATE 
				 WHEN @PERIOD LIKE '%W%'    THEN DATEADD(DD,-DATEPART(DW,@DATE)+2,@DATE)--FROM MONDAY
				 WHEN @PERIOD LIKE '%M%'    THEN DATEADD(DD,-DAY(CONVERT(DATE,@DATE))+1,CONVERT(DATE,@DATE))
				 WHEN @PERIOD LIKE '%Q%'    THEN DATEADD(YY,YEAR(@DATE)-1900,DATEADD(QQ,CEILING(MONTH(@DATE)/3.0)-1,0))
				 WHEN @PERIOD LIKE '%Y%'    THEN DATEADD(QQ,@FIN,DATEADD(DD,-DATEPART(DAYOFYEAR,@DATE)+1,@DATE))
			END     
RETURN REPLACE(CONVERT(VARCHAR,@DATED,102),'.','-')
END
