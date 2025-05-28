CREATE PROCEDURE SP3S_REMOVE_CHALLAN_FROM_GIT
@nMode NUMERIC(1,0),
@cXntype VARCHAR(20),
@cChallanId VARCHAR(50)
AS
BEGIN

DECLARE @cErrormsg VARCHAR(MAX),@cStep VARCHAR(5),@cHoLocId VARCHAR(5),@cPartyLocId VARCHAR(5),@bServerLoc BIT,
		@bRemoveFromGit BIT

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''
	
	SET @bRemoveFromGit=0

	BEGIN TRAN

	SELECT @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
	
	IF @nMode=1
	BEGIN


	IF @cXntype='WSL'
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 inv_id FROM inm01106 (NOLOCK) WHERE inv_id=@cChallanId and ISNULL(AllowTargetToRemoveGIT,0)=1)
			
		BEGIN
			SET @cErrormsg='You cannot remove this challan from GIT as admin at HO has not allowed it'
			GOTO END_PROC
		END
	END

	IF @cXntype='PRT'
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 rm_id FROM rmm01106 (NOLOCK) WHERE rm_id=@cChallanId and ISNULL(AllowTargetToRemoveGIT,0)=1)
			
		BEGIN
			SET @cErrormsg='You cannot remove this challan from GIT as admin at HO has not allowed it'
			GOTO END_PROC
		END



		
	IF @cXntype='RND'
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 inv_id FROM inm01106 (NOLOCK) WHERE inv_id=@cChallanId and ISNULL(AllowTargetToRemoveGIT,0)=1 and XN_ITEM_TYPE =5)
			
		BEGIN
			SET @cErrormsg='You cannot remove this challan from GIT as admin at HO has not allowed it'
			GOTO END_PROC
		END
	END



	END


		IF @cXntype in ('WSL','RND') 
			SELECT TOP 1 @cPartyLocId=party_dept_id FROM DOCWSL_INM01106_MIRROR (NOLOCK) WHERE inv_id=@cChallanId
		ELSE
			SELECT TOP 1 @cPartyLocId=party_dept_id FROM DOCPRT_RMM01106_MIRROR (NOLOCK) WHERE rm_id=@cChallanId
		
		IF EXISTS (SELECT TOP 1 dept_id FROM  location (NOLOCK) WHERE dept_id=@cPartyLocId 
				   AND (dept_id=@cHoLocId OR isnulL(server_loc,0)=1))
			SET @bRemoveFromGit=1
	END

	IF @nMode=1 
	BEGIN
		SET @cStep='20'
		UPDATE a WITH (ROWLOCK) SET ref_memo_id='',PARTY_INV_NO='',REF_MEMO_NO='' FROM parcel_det a 
		JOIN parcel_mst b ON a.parcel_memo_id=b.parcel_memo_id
		WHERE ref_memo_id=@cChallanId AND xn_type=@cXnType

		SET @cStep='30'
		IF	 @cXntype in ('WSL','RND') 
			UPDATE inm01106 WITH (ROWLOCK) SET removed_from_git=1 WHERE inv_id=@cChallanId
		ELSE
			UPDATE rmm01106 WITH (ROWLOCK) SET removed_from_git=1 WHERE rm_id=@cChallanId
	END


	IF @nMode=2 OR @bRemoveFromGit=1
	BEGIN
		SET @cStep='40'
		SET @cXntype='DOC'+@cXnType
		EXEC SP3S_DEL_FROM_MIRROR_TABLES @cChallanId,@CXNTYPE
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_REMOVE_CHGIT at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
	
	IF @@TRANCOUNT>0
	BEGIN
		IF @cErrormsg=''
			COMMIT
		ELSE
			ROLLBACK	
	END

	SELECT @cErrormsg AS errmsg
END



