CREATE PROCEDURE SP3S_APPROVE_TERMS
 (
	@NQUEYID	NUMERIC(5),	
	@CXNTYPE    VARCHAR(50)='',
	@CWHERE		VARCHAR(100)	
	
 )AS
 
 BEGIN
 
 IF @NQUEYID=1
	GOTO SSPL1
 ELSE IF	@NQUEYID=2
	GOTO SSPL2
 ELSE IF	@NQUEYID=3
	GOTO SSPL3
	

SSPL1:	

     IF @CXNTYPE= 'SOR'
     BEGIN
		 SELECT  DISTINCT TOP 50 A.AC_CODE,A.AC_NAME
		 FROM LM01106 A
		 JOIN LMP01106 B ON B.AC_CODE=A.AC_CODE
		 JOIN TBL_EOSS_DISC_SHARE_MST C ON C.AC_CODE=A.AC_CODE
		 WHERE A.AC_NAME  LIKE @CWHERE
		 ORDER BY A.AC_NAME
	 END
	 
	 IF @CXNTYPE= 'LMT'
     BEGIN
		 SELECT  DISTINCT TOP 50 A.AC_CODE,A.AC_NAME
		 FROM LM01106 A
		 JOIN LMP01106 B ON B.AC_CODE=A.AC_CODE
		 JOIN LM_TERMS C ON C.AC_CODE=A.AC_CODE
		 WHERE A.AC_NAME  LIKE @CWHERE
		 ORDER BY A.AC_NAME
	 END
	 
	
	 
	 
	 
	GOTO SSPL99
SSPL2:


	IF @CXNTYPE= 'LMT'
	BEGIN
		SELECT  A.AC_CODE,A.AC_NAME,D.TERMS ,
		D.EOSS_DISCOUNT_PER,D.EOSS_DISCOUNT_SHARE,C.APPROVED,C.ROW_ID,D.REMARKS,
		C.TERMS_CODE,D.TERMS_NAME
		FROM LM01106 A
		JOIN LMP01106 B ON B.AC_CODE=A.AC_CODE
		JOIN LM_TERMS C ON C.AC_CODE=A.AC_CODE
		JOIN LEDGER_TERMS D ON D.TERMS_CODE=C.TERMS_CODE
		WHERE A.AC_CODE=@CWHERE
		ORDER BY D.TERMS_NAME

	END
	
	IF @CXNTYPE= 'SOR'
	BEGIN
		SELECT  A.AC_CODE,A.AC_NAME,C.NAME AS TERMS_NAME ,
		C.APPROVED,C.ID AS ROW_ID		
		FROM LM01106 A
		JOIN LMP01106 B ON B.AC_CODE=A.AC_CODE
		JOIN TBL_EOSS_DISC_SHARE_MST C ON C.AC_CODE=A.AC_CODE		
		WHERE A.AC_CODE=@CWHERE
		ORDER BY C.NAME

	END
	
	GOTO SSPL99
SSPL3:

	IF @CXNTYPE= 'LMT'
	BEGIN
		SELECT A.AC_CODE,A.AC_NAME,D.TERMS ,
		D.EOSS_DISCOUNT_PER,D.EOSS_DISCOUNT_SHARE,C.APPROVED,C.ROW_ID,D.REMARKS,
		C.TERMS_CODE,D.TERMS_NAME
		FROM LM01106 A
		JOIN LMP01106 B ON B.AC_CODE=A.AC_CODE
		JOIN LM_TERMS C ON C.AC_CODE=A.AC_CODE
		JOIN LEDGER_TERMS D ON D.TERMS_CODE=C.TERMS_CODE
		WHERE APPROVED=0
		ORDER BY A.AC_NAME,D.TERMS

	END
	
	
	
	IF @CXNTYPE= 'SOR'
	BEGIN
		SELECT A.AC_CODE,A.AC_NAME,C.NAME AS TERMS_NAME,
		C.APPROVED,C.ID AS ROW_ID		
		FROM LM01106 A
		JOIN LMP01106 B ON B.AC_CODE=A.AC_CODE
		JOIN TBL_EOSS_DISC_SHARE_MST C ON C.AC_CODE=A.AC_CODE		
		WHERE APPROVED=0
		ORDER BY A.AC_NAME,C.NAME

	END
	
	GOTO SSPL99	
SSPL99:
END
