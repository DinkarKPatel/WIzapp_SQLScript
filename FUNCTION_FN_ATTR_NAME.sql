CREATE FUNCTION FN_ATTR_NAME ( @CATTRCODE CHAR(7), @CARTCODE VARCHAR(20), @NATTRTYPE INT = 1  )
RETURNS VARCHAR(50)
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CKEYNAME VARCHAR(50)

	IF @NATTRTYPE = 1				-- INVENTORY ATTRIBUTES
	BEGIN
			SELECT @CKEYNAME = KEY_NAME
			FROM ART_ATTR A JOIN ATTR_KEY B
			ON A.KEY_CODE = B.KEY_CODE
			WHERE ARTICLE_CODE = @CARTCODE
			AND A.ATTRIBUTE_CODE = @CATTRCODE
	END
	ELSE
	IF @NATTRTYPE = 3				-- CUSTOMER ATTRIBUTES
	BEGIN
			SELECT @CKEYNAME = 
			(CASE WHEN ISNULL(A.KEY_CODE,'')='' THEN A.KEY_NAME ELSE B.KEY_NAME END)
			FROM CUST_ATTR A LEFT JOIN ATTR_KEY B
			ON A.KEY_CODE = B.KEY_CODE
			WHERE CUSTOMER_CODE = @CARTCODE
			AND A.ATTRIBUTE_CODE = @CATTRCODE
	END
	
	SELECT @CKEYNAME = ISNULL(@CKEYNAME, '')
	RETURN @CKEYNAME
END
