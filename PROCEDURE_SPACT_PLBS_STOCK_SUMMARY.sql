CREATE PROCEDURE SPACT_PLBS_STOCK_SUMMARY
(
@cXNDT DATETIME,
@bManualMode BIT=0,
@cFinYear VARCHAR(20)='',
@cSPID VARCHAR(100)=''
)
AS
BEGIN
	DECLARE @dt TABLE
	(
		[XN DT]				VARCHAR(20),
		[Pending Physical]	NUMERIC(20,2),
		[Depcn Value]		NUMERIC(20,2),
		[Pending Approval]	NUMERIC(20,2),
		[Pending Jobwork]	NUMERIC(20,2),
		[Pending Challan]	NUMERIC(20,2),
		[Pending Purchase]	NUMERIC(20,2),
		[Pending WIP]		NUMERIC(20,2),
		[Pending WPS]		NUMERIC(20,2),
		[Pending RPS]		NUMERIC(20,2),
		[Pending DNPS]		NUMERIC(20,2),
		[Pending CNPS]		NUMERIC(20,2),
		CBP					NUMERIC(20,2)
	)
	if ISNULL(@bManualMode,0)=1
	begin
		INSERT INTO @dt([XN DT] ,[Pending Physical] ,[Depcn Value] ,[Pending Approval],[Pending Jobwork],[Pending Challan],[Pending Purchase],
		[Pending WIP],[Pending WPS] ,[Pending RPS],	[Pending DNPS],[Pending CNPS] ,CBP )
		SELECT CONVERT(VARCHAR(50),@cXNDT ,105) AS [XN DT],SUM(closing_stock_value_pp) AS [Pending Physical],
		NULL [Depcn Value] ,NULL [Pending Approval],NULL[Pending Jobwork],
		NULL [Pending Challan],NULL [Pending Purchase],
		NULL [Pending WIP],NULL [Pending WPS] ,NULL [Pending RPS],NULL [Pending DNPS],
		NULL [Pending CNPS] ,NULL CBP 
		FROM  year_wise_act_cbsstk_det A(NOLOCK) 
		JOIN act_filter_loc b (NOLOCK) ON b.dept_id=A.dept_id and B.sp_id=@cSPID
		where fin_year=@cFinYear
		GROUP BY fin_year
		--SELECT CONVERT(VARCHAR(50),@cXNDT ,105) AS [XN DT],SUM(closing_stock_value_pp) AS [Pending Physical],
		--CAST(0 AS NUMERIC(20,2)) [Depcn Value] ,CAST(0 AS NUMERIC(20,2)) [Pending Approval],CAST(0 AS NUMERIC(20,2)) [Pending Jobwork],
		--CAST(0 AS NUMERIC(20,2)) [Pending Challan],CAST(0 AS NUMERIC(20,2)) [Pending Purchase],
		--CAST(0 AS NUMERIC(20,2)) [Pending WIP],CAST(0 AS NUMERIC(20,2)) [Pending WPS] ,CAST(0 AS NUMERIC(20,2)) [Pending RPS],CAST(0 AS NUMERIC(20,2)) [Pending DNPS],
		--CAST(0 AS NUMERIC(20,2)) [Pending CNPS] ,CAST(0 AS NUMERIC(20,2)) CBP 
		--FROM  year_wise_act_cbsstk_det(NOLOCK) where fin_year=@cFinYear
		--GROUP BY fin_year
		
	end
	ELSE
	BEGIN
		INSERT INTO @dt([XN DT] ,[Pending Physical] ,[Depcn Value] ,[Pending Approval],[Pending Jobwork],[Pending Challan],[Pending Purchase],
		[Pending WIP],[Pending WPS] ,[Pending RPS],	[Pending DNPS],[Pending CNPS] ,CBP )
		SELECT CONVERT(VARCHAR(50),XN_DT ,105) AS [XN DT],
		CBS_PHYSICAL AS [Pending Physical],
		depcn_val AS [Depcn Value],
		CBS_APPROVAL AS [Pending Approval],
		CBS_JWI AS [Pending Jobwork],
		CBS_CHGIT AS [Pending Challan],
		CBS_PURGIT AS [Pending Purchase],
		CBS_WIP AS [Pending WIP] ,
		CBS_WPS AS [Pending WPS],
		CBS_RPS AS [Pending RPS],
		CBS_DNPS AS [Pending DNPS],
		CBS_CNPS AS [Pending CNPS],
		CBP AS CBP
		FROM PLBS_STOCK_SUMMARY 
		WHERE xn_dt=@cXNDT
	END
	SELECT * FROM @Dt
END