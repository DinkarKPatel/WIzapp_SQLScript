CREATE PROCEDURE SP3S_ARO_REFILL --(LocId 3 digit change only increased the parameter width by Sanjay:04-11-2024)
@nMode NUMERIC(1,0)=1,
@nQueryId NUMERIC(2,0),
@cWhere VARCHAR(500)='',
@cTargetLocId VARCHAR(4)=''
AS
BEGIN

	IF @nQueryId=1
		GOTO lblActivePlans
	ELSE
	IF @nQueryId=2
		GOTO lblGetROShortage
	ELSE
	IF @nQueryId=3
		GOTO lblGetROExcess		

lblActivePlans:
	IF @nMode=1
		SELECT convert(bit,0) as chk,plan_name,plan_id,FILTER_DISPLAY,from_dt,to_dt FROM aro_plan_mst WHERE CONVERT(DATE,GETDATE())<=to_dt and CANCELLED=0
		ORDER BY plan_name
	ELSE
		SELECT convert(bit,0) as chk,title_name plan_name,memo_id plan_id,FILTER_DISPLAY,
		Applicable_From_Dt from_dt,Applicable_To_Dt to_dt 
		FROM LOC_STOCK_LEVEL_MST (NOLOCK) WHERE CONVERT(DATE,GETDATE())<=Applicable_To_Dt 
		ORDER BY TITLE_NAME

	GOTO LAST

lblGetROShortage:
	IF @nMode=3
		EXEC SP3S_GET_REFILL_CutSize
		@nMode=1
	ELSE	
	IF @nMode=2
		EXEC SP3S_GET_REFILL_stklevel
		@nMode=1,
		@cPlanId=@cWhere
	ELSE	
	IF @nMode=1
		EXEC SP3S_GET_REFILL_ARODATA
		@nMode=1,
		@cPlanId=@cWhere

	GOTO LAST

lblGetROExcess:

	IF @nMode=3
		EXEC SP3S_GET_REFILL_CutSize
		@nMode=2,
		@cTargetLocId=@cTargetLocId
	ELSE	
		EXEC SP3S_GET_REFILL_ARODATA
		@nMode=2,
		@cPlanId=@cWhere,
		@cTargetLocId=@cTargetLocId

		
	GOTO LAST

LAST:
END
