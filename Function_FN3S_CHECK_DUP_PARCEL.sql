create FUNCTION DBO.FN3S_CHECK_DUP_PARCEL
(
	 @Cangadia_code VARCHAR(40)
	,@Cbilty_no VARCHAR(50)
	,@Cfin_year VARCHAR(50)
	,@CPARCEL_MEMO_ID varchar(50)
)
RETURNS BIT
AS
BEGIN
	DECLARE @BDUPEXISTS BIT
	SET @BDUPEXISTS=0

	IF EXISTS(SELECT TOP 1 'U' FROM parcel_mst  A (NOLOCK) WHERE a.cancelled =0 and   angadia_code=@Cangadia_code AND isnull(bilty_no,'')<>'' 
	    and bilty_no=@Cbilty_no and fin_year=@Cfin_year and a.parcel_memo_id<>@CPARCEL_MEMO_ID)  
		SET @BDUPEXISTS=1

	RETURN @BDUPEXISTS
END



