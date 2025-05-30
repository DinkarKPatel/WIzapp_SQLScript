CREATE PROCEDURE SP3S_GETGVREDEMPTION_SCHEME_1
@CLOCID VARCHAR(5),
@NBILLAMT NUMERIC(10,2)
AS
BEGIN
	DECLARE @NGV1AMT NUMERIC(10,2),@NGV2AMT NUMERIC(10,2),@NGV3AMT NUMERIC(10,2),@CGVSRNO1 VARCHAR(50),
	@CGVSRNO2 VARCHAR(50),@CGVSRNO3 VARCHAR(50),@NREQGVCNT INT,@NVALIDGVCNT INT
	
	UPDATE #TMPGVREDEMPTION SET DENOMINATION=0
	
	SELECT @NREQGVCNT=COUNT(*) FROM #TMPGVREDEMPTION WHERE ISNULL(GV_SRNO,'')<>''
	
	SELECT TOP 1 @NGV1AMT=GV1_AMOUNT,@NGV2AMT=GV2_AMOUNT,@NGV3AMT=GV3_AMOUNT  FROM GV_SCHEME_1 A
	JOIN GV_SCHEME_LOCS B ON A.SCHEME_CODE=B.SCHEME_CODE
	JOIN GV_SCHEME_MST C ON C.SCHEME_CODE=B.SCHEME_CODE
	WHERE DEPT_ID=@CLOCID AND @NBILLAMT BETWEEN MRP_FROM AND MRP_TO
	AND CONVERT(VARCHAR,GETDATE(),110) BETWEEN APPLICABLE_FROM_DT AND APPLICABLE_TO_DT
	
	SET @NVALIDGVCNT=(CASE WHEN ISNULL(@NGV3AMT,0)<>0 THEN 3 WHEN ISNULL(@NGV2AMT,0)<>0 THEN 2 WHEN ISNULL(@NGV1AMT,0)<>0  THEN 1  ELSE 0 END)

	IF ISNULL(@NGV1AMT,0)=0 AND ISNULL(@NGV2AMT,0)=0 AND ISNULL(@NGV3AMT,0)=0
	BEGIN
		UPDATE #TMPGVREDEMPTION SET ERRMSG='THIS BILL AMOUNT/LOCATION DOES NOT QUALIFY FOR GV REDEMPTION' 		
		GOTO END_PROC
	END

	
	IF @NVALIDGVCNT<>ISNULL(@NREQGVCNT,0)
	BEGIN
		UPDATE #TMPGVREDEMPTION SET ERRMSG='VALID NO. OF GV(S) FOR REDEMPTION SHOULD BE : '+LTRIM(RTRIM(STR(@NVALIDGVCNT)))
		GOTO END_PROC
	END
	
		
	SELECT TOP 1 @CGVSRNO1=GV_SRNO FROM #TMPGVREDEMPTION
	 
	UPDATE #TMPGVREDEMPTION SET DENOMINATION=@NGV1AMT WHERE GV_SRNO=@CGVSRNO1
	 	
	IF ISNULL(@NGV2AMT,0)<>0 
	BEGIN
		SELECT TOP 1 @CGVSRNO2=GV_SRNO FROM #TMPGVREDEMPTION WHERE DENOMINATION=0
		 
		UPDATE #TMPGVREDEMPTION SET DENOMINATION=@NGV2AMT WHERE GV_SRNO=@CGVSRNO2
	END

	IF ISNULL(@NGV3AMT,0)<>0 
	BEGIN
		SELECT TOP 1 @CGVSRNO3=GV_SRNO FROM #TMPGVREDEMPTION WHERE DENOMINATION=0
		 
		UPDATE #TMPGVREDEMPTION SET DENOMINATION=@NGV3AMT WHERE GV_SRNO=@CGVSRNO3
	END
	
	UPDATE #TMPGVREDEMPTION SET ERRMSG='THIS GV IS NOT VALID FOR REDEMPTION' 		
	WHERE DENOMINATION=0 AND ISNULL(ERRMSG,'')=''
		
END_PROC:
	
END
----- END OF PROCEDURE SP3S_GETGVREDEMPTION_SCHEME_1
