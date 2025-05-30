CREATE PROCEDURE SPACT_LOC_FILTER_NEW
(
	@nMode	INT=1,
	@SPID	VARCHAR(50),
	@USERCODE	VARCHAR(10),
	@cDeptID	VARCHAR(5),
	@PANNO		VARCHAR(20)=''
)
AS
BEGIN
	DECLARE @DTUSERLOC TABLE(DEPT_ID VARCHAR(10))
	DECLARE @DTLOC TABLE(DEPT_ID VARCHAR(10),DEPT_NAME VARCHAR(MAX),AREA_CODE VARCHAR(20),ADDRESS VARCHAR(MAX),LOC_GST_NO VARCHAR(20),LOC_TYPE INT,COMPANY_NAME VARCHAR(100))
	DECLARE @bAllLocation BIT=1
	DECLARE @bHO BIT=0

	IF EXISTS(SELECT VALUE FROM CONFIG WHERE config_option='HO_LOCATION_ID' AND value=@cDeptID)
		SET @bHO=1

	INSERT INTO @DTUSERLOC (DEPT_ID)
	SELECT DEPT_ID FROM LOCUSERS (NOLOCK)
	WHERE user_code=@USERCODE
	
	INSERT INTO @DTLOC(DEPT_ID ,DEPT_NAME ,AREA_CODE ,ADDRESS,LOC_GST_NO,LOC_TYPE,COMPANY_NAME)
	SELECT A.DEPT_ID,A.DEPT_NAME,A.AREA_CODE,ISNULL(A.ADDRESS1,'')+ISNULL(A.ADDRESS1,'') AS ADDRESS,SUBSTRING(A.LOC_GST_NO,3,10) AS LOC_GST_NO,A.loc_type,C.company_name
	FROM LOCATION A (NOLOCK)
	JOIN @DTUSERLOC b ON b.DEPT_ID=A.DEPT_ID
	JOIN loc_accounting_company C ON C.pan_no=SUBSTRING(LOC_GST_NO,3,10)
	WHERE  (((A.DEPT_ID=A.MAJOR_DEPT_ID AND (A.loc_type=1 OR A.Account_posting_at_ho=1))) )
	AND ISNULL(LOC_GST_NO,'')<>'' AND ISNULL(@PANNO,'')=C.pan_no AND ISNULL(@PANNO,'')<>''
	UNION 
	SELECT A.DEPT_ID,A.DEPT_NAME,A.AREA_CODE,ISNULL(A.ADDRESS1,'')+ISNULL(A.ADDRESS1,'') AS ADDRESS,A.PAN_NO AS LOC_GST_NO,A.loc_type,C.company_name
	FROM LOCATION  A (NOLOCK)
	JOIN @DTUSERLOC b ON b.DEPT_ID=A.DEPT_ID
	JOIN loc_accounting_company C ON C.pan_no=A.PAN_NO
	WHERE  (((A.DEPT_ID=A.MAJOR_DEPT_ID AND (A.loc_type=1 OR A.Account_posting_at_ho=1))) )
	AND ISNULL(A.PAN_NO,'')<>'' AND ISNULL(A.LOC_GST_NO,'')='' AND ISNULL(@PANNO,'')=C.pan_no AND ISNULL(@PANNO,'')<>''
	UNION
	SELECT A.DEPT_ID,A.DEPT_NAME,A.AREA_CODE,ISNULL(A.ADDRESS1,'')+ISNULL(A.ADDRESS1,'') AS ADDRESS,SUBSTRING(A.LOC_GST_NO,3,10) AS LOC_GST_NO,A.loc_type,A.DEPT_NAME company_name
	FROM LOCATION A (NOLOCK)
	LEFT OUTER JOIN @DTUSERLOC b ON b.DEPT_ID=A.DEPT_ID
	WHERE  (((A.DEPT_ID=A.MAJOR_DEPT_ID AND (A.loc_type=1 OR A.Account_posting_at_ho=1))) )
	AND ISNULL(LOC_GST_NO,'')<>'' AND ISNULL(@PANNO,'')=''
	UNION 
	SELECT A.DEPT_ID,A.DEPT_NAME,A.AREA_CODE,ISNULL(A.ADDRESS1,'')+ISNULL(A.ADDRESS1,'') AS ADDRESS,A.PAN_NO AS LOC_GST_NO,A.loc_type,A.DEPT_NAME company_name
	FROM LOCATION  A (NOLOCK)
	LEFT OUTER JOIN @DTUSERLOC b ON b.DEPT_ID=A.DEPT_ID
	WHERE  (((A.DEPT_ID=A.MAJOR_DEPT_ID AND (A.loc_type=1 OR A.Account_posting_at_ho=1))) )
	AND ISNULL(A.PAN_NO,'')<>'' AND ISNULL(A.LOC_GST_NO,'')='' AND ISNULL(@PANNO,'')=''
	

	
	--select * from @DTUSERLOC
	--select * from @DTLOC

	--SELECT @bAllLocation=0
	--FROM @DTLOC a
	--LEFT OUTER JOIN @DTUSERLOC b ON b.DEPT_ID=A.DEPT_ID
	--where b.DEPT_ID is null
	--SELECT LOC_GST_NO AS PAN_NO, LOC_GST_NO, DEPT_NAME,COMPANY_NAME
	--			FROM @DTLOC 
	
		;WITH ALL_LOC
		AS
		(
			SELECT A.DEPT_ID,A.DEPT_NAME,A.AREA_CODE,ISNULL(A.ADDRESS1,'')+ISNULL(A.ADDRESS1,'') AS ADDRESS,A.LOC_GST_NO AS LOC_GST_NO,ISNULL(A.PAN_NO,'') AS PAN_NO
			,(CASE WHEN A.loc_type=2 THEN 'Franchisee' ELSE 'Company Owned' END ) AS [Loc_Type]
			FROM LOCATION  A (NOLOCK)
			JOIN @DTUSERLOC B ON B.DEPT_ID=A.dept_id
			WHERE A.DEPT_ID=A.MAJOR_DEPT_ID AND (ISNULL(A.LOC_GST_NO,'')<>'' OR ISNULL(A.PAN_NO,'')<>'')
		)
		,GROUP_COMPANY
		AS
		(
			SELECT ROW_NUMBER() OVER (PARTITION BY PAN_NO ORDER BY PAN_NO) AS SRNO,X.PAN_NO, LOC_GST_NO, DEPT_NAME,COMPANY_NAME
			FROM 
			(
				SELECT LOC_GST_NO AS PAN_NO, LOC_GST_NO, DEPT_NAME,COMPANY_NAME
				FROM @DTLOC 
			)X
		)
		--SELECT * FROM GROUP_COMPANY--,ALL_LOC
		SELECT CAST( 1 AS BIT) AS CHK, upper(A.DEPT_ID)AS DEPT_ID,
		upper(A.DEPT_NAME) AS DEPT_NAME,UPPER(b.area_name)as [Area], UPPER(c.city)as City, 
		upper(d.state)as [State], upper(e.region_name)as [Region] ,A.ADDRESS AS [Address],
		ISNULL(GP.COMPANY_NAME,'') AS [Group_Name],A.Loc_Type AS [Loc Type],A.LOC_GST_NO
		FROM ALL_LOC A
		LEFT OUTER JOIN AREA B (NOLOCK) ON A.AREA_CODE=B.AREA_CODE 
		LEFT OUTER JOIN CITY C  (NOLOCK) ON B.CITY_CODE=C.CITY_CODE 
		LEFT OUTER JOIN STATE D (NOLOCK) ON C.STATE_CODE=D.STATE_CODE 
		LEFT OUTER JOIN REGIONM E (NOLOCK) ON D.REGION_CODE=E.REGION_CODE
		LEFT OUTER JOIN
		(
			SELECT DEPT_ID FROM act_filter_loc (NOLOCK) WHERE SP_ID=@SPID
		)ACT ON ACT.dept_id=A.dept_id
		JOIN 
		(
			SELECT * FROM GROUP_COMPANY WHERE SRNO=1
		)GP ON (GP.PAN_NO=SUBSTRING(A.LOC_GST_NO,3,10) OR GP.PAN_NO=A.PAN_NO)
	
END