create FUNCTION FN_CheckDUpParcel 
( @cRowId varchar(40)) 
 RETURNS bit 
 AS 
BEGIN  
	DECLARE @lRetVal bit,@cXnType VARCHAR(10),@cRefMemoId VARCHAR(50),@cParcelMemoId varchar(22),@cPartyInvNo VARCHAR(50),
			@cFinYear VARCHAR(5),@cAcCode CHAR(10)
			  
	SET @lRetVal = 1    

	SELECT @cRefMemoId=ref_memo_id,@cXnType=xn_type,@cPartyInvNo=party_inv_no,@cFinYear='01'+DBO.FN_GETFINYEAR(party_inv_dt),
	@cAcCode=ac_code,@cParcelMemoId=a.parcel_memo_id FROM parcel_det a (NOLOCK) JOIN parcel_mst b (NOLOCK) ON a.parcel_memo_id=b.parcel_memo_id
	WHERE row_id=@cRowId
	
	IF ISNULL(@cPartyInvNo,'')<>''
	BEGIN
		IF EXISTS ( SELECT TOP 1 ref_memo_id FROM parcel_det a JOIN parcel_mst b ON a.parcel_memo_id=b.parcel_memo_id
					WHERE a.party_inv_no= @cPartyInvNo AND '01'+DBO.FN_GETFINYEAR(party_inv_dt)=@cFinYear AND b.cancelled=0 
					AND b.xn_type=@cXnType AND a.AC_CODE=@cAcCode AND a.row_id<>@cRowId )
			SET @lRetVal=0
					
		IF ISNULL(@cRefMemoId,'')='' OR @lRetVal=0
			RETURN @lRetVal
	END
	
	IF ISNULL(@cRefMemoId,'')<>''
	BEGIN

		IF EXISTS ( SELECT TOP 1 ref_memo_id FROM parcel_det a (NOLOCK) JOIN parcel_mst b (NOLOCK) ON a.parcel_memo_id=b.parcel_memo_id
					WHERE REF_MEMO_ID=@cRefMemoId AND cancelled=0 AND B.XN_TYPE  IN ('PRT','WSL') AND b.xn_type=@cXnType AND a.parcel_memo_id<>@cParcelMemoId)
			SET @lRetVal=0
	
	end
	RETURN @lRetVal 
 END 




