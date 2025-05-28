CREATE FUNCTION DBO.FN3S_NTHINDEX
               (@INPUT     VARCHAR(8000),
                @DELIMITER CHAR(1),
                @ORDINAL   INT)
RETURNS INT
--WITH ENCRYPTION
AS
BEGIN
    DECLARE  @POINTER INT,
             @LAST    INT,
             @COUNT   INT
    SET @POINTER = 1
    SET @LAST = 0
    SET @COUNT = 1
    WHILE (2 > 1)
      BEGIN
        SET @POINTER = CHARINDEX(@DELIMITER,@INPUT,@POINTER)
        IF @POINTER = 0
          BREAK
        IF @COUNT = @ORDINAL
          BEGIN
            SET @LAST = @POINTER
            BREAK
          END
        SET @COUNT = @COUNT + 1
        SET @POINTER = @POINTER + 1
      END
    RETURN @LAST
END
