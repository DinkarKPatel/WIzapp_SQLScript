CREATE FUNCTION DBO.DBKPI_SLAB(@MIN FLOAT,@MAX FLOAT,@VAL FLOAT,@MODE INT)
RETURNS VARCHAR(100)
AS
BEGIN
DECLARE @COLOR VARCHAR(100)
--CHANGES STARTS 09 OCT 2019
/*
SELECT @COLOR=CASE WHEN @VAL BETWEEN @MIN				  AND (@MIN+@MAX-1)*.25 THEN '#FF0000'--RED--1
			       WHEN @VAL BETWEEN ((@MIN+@MAX-1)*0.25) AND (@MIN+@MAX-1)*.50 THEN '#F2BA49'--RED YELLOW--2
				   WHEN @VAL BETWEEN ((@MIN+@MAX-1)*0.50) AND (@MIN+@MAX-1)*.75 THEN '#9ACD32'--GREEN YELLOW--3
				   WHEN @VAL BETWEEN ((@MIN+@MAX-1)*0.75) AND  @MAX			    THEN '#00FF00'--GREEN--4
			  END		
*/
SELECT @COLOR=CASE WHEN @VAL=4 THEN '#FF0000'--RED
			       WHEN @VAL=3 THEN '#2E2EFE'--RED YELLOW (#F2BA49) /BLUE (#2E2EFE)
				   WHEN @VAL=2 THEN '#F7FE2E'--GREEN YELLOW(#9ACD32) / YELLOW (#F7FE2E)
				   WHEN @VAL=1 THEN '#00FF00'--GREEN
			  END		
--CHANGES ENDS 09 OCT 2019
IF @MODE=1
   SET @COLOR=CASE @COLOR WHEN '#FF0000' THEN 'RED'	  --1
						  WHEN '#F2BA49' THEN 'RED YELLOW' --2/RED YELLOW (#F2BA49) TO BLUE (#2E2EFE)
						  WHEN '#00FF00' THEN 'GREEN' --3
						  WHEN '#9ACD32' THEN 'GREEN YELLOW'--4/GREEN YELLOW (#9ACD32) TO YELLOW (#F7FE2E)
			  END 			  
RETURN ISNULL(@COLOR,'#FFFFFF')
END