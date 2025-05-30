create PROCEDURE SP3S_GETMISSING_STOCKDT_KAPSONS 
(
	@EndDate DATE
)
AS
BEGIN
	DECLARE @StartDate DATE 
	SET @StartDate = '2022-09-01'--, @EndDate = '2022-07-14'; 
	;WITH ListDates(AllDates) 
	AS
	(    
		SELECT @StartDate AS DATE
		UNION ALL
		SELECT DATEADD(DAY,1,AllDates)
		FROM ListDates 
		WHERE AllDates < @EndDate
	)
	,CMM_CMDT(STORE_CODE,DEPT_ID,CM_DT)
	AS
	(
		SELECT b.LOCattr5_key_name as STORE_CODE, B.DEPT_ID,MAX(CAST(ISNULL(A.STOCK_DT,'') AS DATE)) CM_DT 
		FROM LOC_NAMES B 
		LEFT OUTER JOIN KAPSON_STOCK_import_status A ON A.DEPT_ID=B.DEPT_ID AND B.LOCattr5_key_name=A.STORE_CODE
		 where locattr2_key_name='kapson'
		 GROUP BY  b.LOCattr5_key_name, B.DEPT_ID
	)
	SELECT DISTINCT b.STORE_CODE,b.dept_id,  AllDates, UPPER(REPLACE(CONVERT(VARCHAR(20),AllDates,106),' ','')) AS CM_DT,CONVERT(VARCHAR(20),AllDates,5) STOCK_DT
	FROM ListDates a ,CMM_CMDT b 
	WHERE B.CM_DT<A.AllDates
	ORDER BY 1,2
	option (maxrecursion 10000);
END
--GO
--EXEC SP3S_GETMISSING_STOCKDT_KAPSONS '2022-06-12'