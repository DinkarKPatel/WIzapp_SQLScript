CREATE PROCEDURE SPACT_GETCOMPANYLIST 
@cUserCode VARCHAR(10)='0000000',
@bIncludeAll BIT
AS
BEGIN
	select ROW_NUMBER() OVER (PARTITION BY company_name ORDER BY company_name) AS SR_NO,a.pan_no,a.company_name 
	from loc_accounting_company A
	JOIN 
	(
		SELECT A.PAN_NO
		FROM LOCATION A (NOLOCK) 
		JOIN locusers B (NOLOCK)  ON B.dept_id=A.dept_id
		WHERE A.DEPT_ID=A.MAJOR_DEPT_ID AND (A.LOC_TYPE=1) AND B.user_code=@cUserCode
		AND ISNULL(A.PAN_NO,'')<>''
		UNION
		SELECT SUBSTRING(A.LOC_GST_NO,3,10)
		FROM LOCATION A (NOLOCK) 
		JOIN locusers B (NOLOCK)  ON B.dept_id=A.dept_id
		WHERE A.DEPT_ID=A.MAJOR_DEPT_ID AND (A.LOC_TYPE=1) AND B.user_code=@cUserCode
		AND ISNULL(A.LOC_GST_NO,'')<>''
		UNION
		SELECT A.PAN_NO
		FROM LOCATION A (NOLOCK) 
		JOIN locusers B (NOLOCK)  ON B.dept_id=A.dept_id
		WHERE A.DEPT_ID=A.MAJOR_DEPT_ID AND (LOC_TYPE=2 AND enable_accounting_at_loc=1) AND B.user_code=@cUserCode
		AND ISNULL(A.PAN_NO,'')<>''
		UNION
		SELECT SUBSTRING(A.LOC_GST_NO,3,10)
		FROM LOCATION A (NOLOCK) 
		JOIN locusers B (NOLOCK)  ON B.dept_id=A.dept_id
		WHERE A.DEPT_ID=A.MAJOR_DEPT_ID AND (LOC_TYPE=2 AND enable_accounting_at_loc=1) AND B.user_code=@cUserCode
		AND ISNULL(A.LOC_GST_NO,'')<>''
	)X ON X.PAN_NO=A.pan_no
	UNION
	select 9999 AS SR_NO,'' pan_no,'ALL' company_name WHERE @bIncludeAll=1
	ORDER BY SR_NO,COMPANY_NAME
END