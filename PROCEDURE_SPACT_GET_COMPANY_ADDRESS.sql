CREATE PROCEDURE SPACT_GET_COMPANY_ADDRESS
(
	@nSPID VARCHAR(50)='',
	@dFromDt DATETIME='',  
	@dToDt DATETIME='',
	@cpanno varchar(10)=''
)
AS
BEGIN

  
	--DECLARE @nSPID NUMERIC(5)
	if ISNULL(@nSPID,'')='' SET @nSPID=CAST(@@SPID AS VARCHAR(50))

	DECLARE @CALLDEPT_ID VARCHAR(max),@CALLDEPTALIAS VARCHAR(max)--,@cpanno varchar(10)=''

	IF ISNULL(@cpanno,'')=''
	BEGIN
		SELECT @CALLDEPT_ID=ISNULL(@CALLDEPT_ID+',','')+(A.DEPT_ID ) ,
			   @CALLDEPTALIAS=ISNULL(@CALLDEPTALIAS+',','')+(A.dept_alias  ) 
		FROM LOCATION A (NOLOCK)
		JOIN  act_filter_loc B (NOLOCK) ON A.dept_id =B.dept_id 
		WHERE B.sp_id=@nSPID
		ORDER BY A.DEPT_ID 


		SELECT TOP 1 @cpanno=PAN_NO 
		FROM LOCATION A (NOLOCK)
		JOIN act_filter_loc B (nolock) ON A.dept_id =B.dept_id 
		WHERE B.SP_ID=@nSPID AND ISNULL(A.PAN_NO ,'')<>''
	END

	SET  @CALLDEPT_ID=ISNULL( @CALLDEPT_ID,'')
	SET @CALLDEPTALIAS =ISNULL(@CALLDEPTALIAS,'')


	--SELECT @nCount,@cDeptID
	;WITH COMP_DETAILS
	AS
	(
	
		SELECT  registered_ADDRESS1	  address1,registered_ADDRESS2 address2,'' AS  address9 ,registered_area_code area_code,A.CIN_NO AS CIN,
		'01' AS COMPANY_CODE,company_name AS COMPANY_NAME,
		'' AS COUNTRY,'' cst_no,A.EMAIL_ID,  a.GST_NO AS gst_no,''  MOBILE,   A.PAN_NO, A.PHONE AS PHONES_FAX, 
		'' AS PIN, '' AS PRINT_ADDRESS,'' SST_NO,'' tan_no,'' tin_no,'' AS WEB_ADDRESS,A.company_logo
		FROM loc_accounting_company A (nolock)
		WHERE A.pan_no=@cpanno
		
	)
	SELECT TOP 1 @CALLDEPT_ID as Dept_id,@CALLDEPTALIAS as Dept_alias, 
	       A1.area_name,A1.pincode,A2.CITY,A3.state, a.* ,@dFromDt AS FROM_DT,@dToDt AS TO_DT 
	INTO #TempCompanyDetails
	FROM COMP_DETAILS A
	LEFT OUTER JOIN AREA A1 (NOLOCK) ON A1.area_code=A.area_code
	LEFT OUTER JOIN CITY A2 (NOLOCK) ON A2.CITY_CODE=A1.city_code
	LEFT OUTER JOIN state A3 (NOLOCK) ON A2.state_code=A3.state_code

  IF  EXISTS(select name from sys.tables  WHERE name='ACT_COMPANY_DETAILS' AND datediff(d,create_date,getdate())>0) OR OBJECT_ID('ACT_COMPANY_DETAILS','U') IS NULL
  BEGIN
	IF OBJECT_ID('ACT_COMPANY_DETAILS','U') IS NOT NULL 
		DROP TABLE ACT_COMPANY_DETAILS
	
	SELECT * INTO ACT_COMPANY_DETAILS FROM #TempCompanyDetails 
  END
	SELECT * FROM #TempCompanyDetails 
END

