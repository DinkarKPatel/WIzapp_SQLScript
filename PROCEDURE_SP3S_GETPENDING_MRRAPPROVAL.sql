CREATE PROCEDURE SP3S_GETPENDING_MRRAPPROVAL
@CACCODE CHAR(10)='',
@CLOC VARCHAR(5)=''
AS
BEGIN
	IF @CLOC=''
		SELECT 'PUR' AS XN_TYPE,A.MRR_NO AS MEMO_NO,A.AC_CODE,BILL_NO,INV_DT,AC_NAME,TOTAL_AMOUNT,'LEVEL-'+LTRIM(RTRIM(STR(APPROVEDLEVELNO))) AS LEVELNO,
		A.APPROVEDLEVELNO
		FROM PIM01106 A (NOLOCK) JOIN LM01106 B (NOLOCK) ON A.AC_CODE=B.AC_CODE
		JOIN LOC_XNSAPPROVAL C ON C.DEPT_ID=LEFT(A.MRR_ID,2)
		WHERE INV_MODE=1 AND (@CACCODE='' OR A.AC_CODE=@CACCODE) AND C.XN_TYPE='PUR' AND A.RECEIPT_DT>=C.CUTOFFDATE
		AND APPROVEDLEVELNO<>99	AND BILL_CHALLAN_MODE=0
	ELSE
		SELECT 'PUR' AS XN_TYPE,A.MRR_NO AS MEMO_NO,A.AC_CODE,BILL_NO,INV_DT,AC_NAME,TOTAL_AMOUNT,'LEVEL-'+LTRIM(RTRIM(STR(APPROVEDLEVELNO))) AS LEVELNO,
		A.APPROVEDLEVELNO
		FROM PIM01106 A (NOLOCK) JOIN LM01106 B (NOLOCK) ON A.AC_CODE=B.AC_CODE
		JOIN LOC_XNSAPPROVAL C ON C.DEPT_ID=A.location_code
		WHERE INV_MODE=1 AND (@CACCODE='' OR A.AC_CODE=@CACCODE) AND C.XN_TYPE='PUR' AND A.RECEIPT_DT>=C.CUTOFFDATE
		AND APPROVEDLEVELNO<>99	AND BILL_CHALLAN_MODE=0
		AND A.location_code=@CLOC
END
