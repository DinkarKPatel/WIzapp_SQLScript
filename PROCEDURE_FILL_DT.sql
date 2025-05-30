
--*** PROCEDURE TO GET THE ALL THE DATES FOR A GIVEN PERIOD
CREATE PROCEDURE FILL_DT @DTFROM DATETIME,@DTTO DATETIME	
--WITH ENCRYPTION
AS
WHILE @DTFROM <= @DTTO	
BEGIN
	IF NOT EXISTS( SELECT DT FROM TIME_LINE WHERE DT=@DTFROM) 
	BEGIN
		INSERT INTO TIME_LINE (DT) VALUES(@DTFROM)
	END
	SET @DTFROM = DATEADD(DAY,1,@DTFROM)
END	
--END OF PROCEDURE - FILL_DT
