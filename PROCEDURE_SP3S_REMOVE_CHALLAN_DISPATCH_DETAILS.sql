CREATE PROCEDURE SP3S_REMOVE_CHALLAN_DISPATCH_DETAILS
@nMode NUMERIC(1,0),
@cXntype VARCHAR(20),
@cChallanId VARCHAR(50)
AS
BEGIN

DECLARE @cErrormsg VARCHAR(MAX),@cStep VARCHAR(5)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''
	IF @nMode=1
	BEGIN

		IF @cXntype='WSL'
		BEGIN
			SET @cStep='20'
			IF NOT EXISTS (SELECT TOP 1 inv_id FROM inm01106 (NOLOCK) WHERE inv_id=@cChallanId)
			BEGIN
				SET @cErrormsg='Challan details not found at Head Office..Cannot remove Dispatch details'
				GOTO END_PROC
			END


			IF NOT EXISTS (SELECT TOP 1 inv_id FROM inm01106 (NOLOCK) WHERE inv_id=@cChallanId and ISNULL(AllowTargetToRemoveGIT,0)=1)
			
			BEGIN
				SET @cErrormsg='You cannot remove this challan from GIT as admin at HO has not allowed it'
				GOTO END_PROC
			END

			SET @cStep='30'
			IF EXISTS (SELECT TOP 1 inv_id FROM inm01106 (NOLOCK) WHERE inv_id=@cChallanId AND isnull(removed_from_git,0)=0)
			BEGIN
				SET @cErrormsg='Challan is not removed from GIT at Target Location..Cannot remove Dispatch details'
				GOTO END_PROC
			END

		END
		ELSE
		IF @cXntype='PRT'
		BEGIN
			SET @cStep='40'

			IF NOT EXISTS (SELECT TOP 1 rm_id FROM rmm01106 (NOLOCK) WHERE rm_id=@cChallanId)
			BEGIN
				SET @cErrormsg='Challan details not found at Head Office..Cannot remove Dispatch details'
				GOTO END_PROC
			END

			IF NOT EXISTS (SELECT TOP 1 rm_id FROM rmm01106 (NOLOCK) WHERE rm_id=@cChallanId and ISNULL(AllowTargetToRemoveGIT,0)=1)
			
			BEGIN
				SET @cErrormsg='You cannot remove this challan from GIT as admin at HO has not allowed it'
				GOTO END_PROC
			END
			

			SET @cStep='50'
			IF EXISTS (SELECT TOP 1 rm_id FROM rmm01106 (NOLOCK) WHERE rm_id=@cChallanId AND isnull(removed_from_git,0)=0)
			BEGIN
				SET @cErrormsg='Challan is not removed from GIT at Target Location..Cannot remove Dispatch details'
				GOTO END_PROC
			END

		END

	END

	ELSE
	IF @nMode=2
	BEGIN
		SET @cStep='60'
		UPDATE a WITH (ROWLOCK) SET ref_memo_id='',PARTY_INV_NO='',REF_MEMO_NO='' FROM parcel_det a 
		JOIN parcel_mst b ON a.parcel_memo_id=b.parcel_memo_id
		WHERE ref_memo_id=@cChallanId AND xn_type=@cXnType

	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_REMOVE_CHALLAN_DISPATCH_DETAILS at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT @cErrormsg as errmsg
END