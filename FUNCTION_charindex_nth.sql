create FUNCTION DBO.CHARINDEX_NTH (
  @FINDTHIS VARCHAR(8000),
  @INTHIS VARCHAR(MAX),
  @STARTFROM INT,
  @NTHOCCURENCE TINYINT
)
RETURNS BIGINT
AS
BEGIN
	  /*
	  RECURSIVE HELPER USED BY DBO.CHARINDEX_NTH TO RETURN THE POSITION OF THE NTH OCCURANCE OF @FINDTHIS IN @INTHIS

	  WHO   WHEN    WHAT
	  PJR   160421  INITIAL   
	  */

	  DECLARE @POS BIGINT

	  IF ISNULL(@NTHOCCURENCE, 0) <= 0 OR ISNULL(@STARTFROM, 0) <= 0
	  BEGIN
		SELECT @POS = 0
	  END 
	  ELSE
	  BEGIN
		  IF @NTHOCCURENCE = 1
		  BEGIN
			  SELECT @POS = CHARINDEX(@FINDTHIS, @INTHIS, @STARTFROM)
		  END
		  ELSE
		  BEGIN
			  SELECT @POS = DBO.CHARINDEX_NTH(@FINDTHIS, @INTHIS, NULLIF(CHARINDEX(@FINDTHIS, @INTHIS, @STARTFROM), 0) + 1, @NTHOCCURENCE - 1)
		  END
	  END

	  RETURN @POS
END
