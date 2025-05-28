CREATE FUNCTION FN_CONVERTAMOUNTINWORDS
(
@nAmount NUMERIC(14,2)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	--DECLARE @nAmount NUMERIC(14,2)
	--SET @nAmount =124.56

	--SELECT 999.99%999
	DECLARE @nBeforeDecimal NUMERIC(14) ,@nAfterDecimal NUMERIC(14),@nFindAfterDecimal NUMERIC(14,2)
	DECLARE @NumSeries TABLE (SRNO INT,NUM NUMERIC(14),NUM_STR NVARCHAR(100))
	INSERT INTO @NumSeries(SRNO,NUM,NUM_STR)
	VALUES(1,1,'One'),(2,2,'Two'),(3,3,'Three'),(4,4,'Four'),(5,5,'Five'),(6,6,'Six'),(7,7,'Seven'),(8,8,'Eight'),(9,9,'Nine'),(10,10,'Ten'),(11,11,'Eleven')
	,(12,12,'Twelve'),(13,13,'Thirteen'),(14,14,'Fourteen'),(15,15,'Fifteen'),(16,16,'Sixteen'),(17,17,'Seventeen'),(18,18,'Eighteen'),(19,19,'Nineteen')
	,(20,20,'Twenty'),(21,30,'Thirty'),(22,40,'Forty'),(23,50,'Fifty'),(24,60,'Sixty'),(25,70,'Seventy'),(26,80,'Eighty'),(27,90,'Ninety')
	,(28,100,'Hundred'),(29,1000,'Thousand'),(30,100000,'Lac'),(31,10000000,'Crore')


	SELECT  @nBeforeDecimal =FLOOR(@nAmount)
	SET @nFindAfterDecimal =(@nAmount -CONVERT(NUMERIC(14,2),FLOOR(@nAmount) ))
	SELECT @nAfterDecimal=@nFindAfterDecimal * POWER(10,LEN(@nFindAfterDecimal )-2)
	--SELECT @nBeforeDecimal ,@nAfterDecimal ,@nFindAfterDecimal 

	DECLARE @n1 NUMERIC(14),@n2 NUMERIC(14),@n3 NUMERIC(14),@n4 NUMERIC(14),@n5 NUMERIC(14),@cCMD_RS NVARCHAR(MAX)
	,@cCMD_PAISE NVARCHAR(MAX)
	SELECT @n1 =0,@n2 =0,@n3 =0,@n4 =0,@n5 =0,@cCMD_RS ='',@cCMD_PAISE =''
	WHILE @nBeforeDecimal >0
	BEGIN
		IF LEN(@nBeforeDecimal)>0
		BEGIN
			SET @n3=CASE WHEN LEN(@nBeforeDecimal)%2<>  0  AND LEN(@nBeforeDecimal)>3  THEN 2 ELSE 1 END

			SET @n1=CASE WHEN LEN(@nBeforeDecimal)>1 THEN POWER(10,LEN(@nBeforeDecimal)-@n3) ELSE 1 END
			
			SET @n2=FLOOR(@nBeforeDecimal/@n1)

			IF LEN(@nBeforeDecimal)=2
			BEGIN
				SET @n2=@nBeforeDecimal
				SET @nBeforeDecimal=0
			END
			IF LEN(@n2)=2 AND NOT EXISTS(SELECT NUM_STR FROM @NumSeries WHERE NUM=@n2)
			BEGIN
					--SELECT @n2,(@n2 -(@n2 %10)),(@n2 %10) 
					SELECT @cCMD_RS=@cCMD_RS+' '+NUM_STR FROM @NumSeries WHERE NUM=(@n2 -(@n2 %10))
					SELECT @cCMD_RS=@cCMD_RS+' '+NUM_STR FROM @NumSeries WHERE NUM=(@n2 %10) 
			END
			ELSE
			BEGIN
						SELECT @cCMD_RS=@cCMD_RS+' '+NUM_STR FROM @NumSeries WHERE NUM=@n2 --AND @n1>1 
			END
			SELECT @cCMD_RS=@cCMD_RS+' '+NUM_STR FROM @NumSeries WHERE NUM=@n1 AND @n1>10
			SET @nBeforeDecimal=@nBeforeDecimal%@n1
		END
	END
	--SELECT @cCMD_RS
	WHILE @nAfterDecimal >0
	BEGIN
		IF LEN(@nAfterDecimal)>0
		BEGIN
			SET @n3=CASE WHEN LEN(@nAfterDecimal)%2<>  0  AND LEN(@nAfterDecimal)>3  THEN 2 ELSE 1 END

			SET @n1=CASE WHEN LEN(@nAfterDecimal)>1 THEN POWER(10,LEN(@nAfterDecimal)-@n3) ELSE 1 END
			
			SET @n2=FLOOR(@nAfterDecimal/@n1)

			IF LEN(@nAfterDecimal)=2
			BEGIN
				SET @n2=@nAfterDecimal
				SET @nAfterDecimal=0
			END
			IF LEN(@n2)=2 AND NOT EXISTS(SELECT NUM_STR FROM @NumSeries WHERE NUM=@n2)
			BEGIN
					--SELECT @n2,(@n2 -(@n2 %10)),(@n2 %10) 
					SELECT @cCMD_PAISE=@cCMD_PAISE+' '+NUM_STR FROM @NumSeries WHERE NUM=(@n2 -(@n2 %10))
					SELECT @cCMD_PAISE=@cCMD_PAISE+' '+NUM_STR FROM @NumSeries WHERE NUM=(@n2 %10) 
			END
			ELSE
			BEGIN
				SELECT @cCMD_PAISE=@cCMD_PAISE+' '+NUM_STR FROM @NumSeries WHERE NUM=@n2 --AND @n1>1 
			END
			SELECT @cCMD_PAISE=@cCMD_PAISE+' '+NUM_STR FROM @NumSeries WHERE NUM=@n1 AND @n1>10
			SET @nAfterDecimal=@nAfterDecimal%@n1
		END
	END
	--SELECT @cCMD_PAISE
	RETURN (CASE WHEN ISNULL(@cCMD_RS,'')<>'' THEN 'Rupees'+ ISNULL(@cCMD_RS,'') ELSE '' END)+
	(CASE WHEN ISNULL(@cCMD_PAISE,'')<>'' AND ISNULL(@cCMD_RS,'')<>'' THEN  ' and ' ELSE '' END)+
				(CASE WHEN ISNULL(@cCMD_PAISE,'')<>'' THEN  ISNULL(@cCMD_PAISE,'') +' Paise ' ELSE '' END)+
				(CASE WHEN ISNULL(@cCMD_PAISE,'')<>'' OR ISNULL(@cCMD_RS,'')<>'' THEN  ' Only' ELSE '' END)
END			